CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A05R (body)
 * Description      : 納品書チェックリスト
 * MD.050           : 納品書チェックリスト MD050_COS_002_A05
 * Version          : 1.21
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  sales_per_data_entry   販売実績データ抽出(A-3)、納品データ登録（販売実績）(A-4)
 *  money_data_entry       入金データ抽出(A-5)、納品データ登録（入金データ）(A-6)
 *  execute_svf            SVF起動(A-7)
 *  delete_rpt_wrk_data    帳票ワークテーブルデータ削除(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   S.Miyakoshi      新規作成
 *  2009/02/17    1.1   S.Miyakoshi      get_msgのパッケージ名修正
 *  2009/02/26    1.2   S.Miyakoshi      従業員の履歴管理対応(xxcos_rs_info_v)
 *  2009/02/26    1.3   S.Miyakoshi      帳票コンカレント起動後のワークテーブル削除処理のコメント化を解除
 *  2009/02/27    1.4   S.Miyakoshi      [COS_150]販売実績データ抽出条件修正
 *  2009/03/04    1.5   N.Maeda          帳票出力時の納品日マッピング項目の変更
 *                                       ・修正前
 *                                          ⇒販売実績.納品日を使用
 *                                       ・修正後
 *                                          ⇒販売実績.検収日を使用
 *                                       卸単価、売価のマッピング項目の変更
 *                                       ・修正前
 *                                          ⇒卸単価:定価単価
 *                                          ⇒売価:納品単価×数量
 *                                       ・修正後
 *                                          ⇒卸単価:納品単価（売上単)
 *                                          ⇒売価:定価単価
 *  2009/05/01    1.6   N.Maeda          [T1_0885]抽出対象に｢上様顧客｣を追加
 *  2009/05/18    1.7   Kin              障害[T1_0434],[T1_0435],[T1_0930]対応
 *  2009/05/27    1.8   Kin              障害[T1_0433]対応
 *  2009/06/05    1.9   T.Tominaga       障害[T1_1148]対応
 *                                       メインカーソルの変更
 *                                       "確認"の判定条件変更
 *                                         ・（定価(新)）定価適用開始 >= 納品日⇒定価適用開始 <= 納品日
 *                                         ・（旧定価）定価適用開始 < 納品日   ⇒定価適用開始 > 納品日
 *                                       障害[T1_1361]対応
 *                                       delete_rpt_wrk_dataコール部分のコメント削除
 *  2009/06/10    1.10  T.Tominaga       障害[T1_1404]対応
 *                                       メインカーソルの変更（端数処理区分の取得先変更）
 *  2009/06/11    1.11  T.Tominaga       障害[T1_1420]対応
 *                                       税処理において、消費税区分が"2","3"以外の場合の条件を"3"以外に変更
 *  2009/06/19    1.12  K.Kiriu          障害[T1_1437]対応
 *                                       データパージの不具合を修正
 *  2009/07/13    1.13  T.Tominaga       障害[0000651]対応
 *                                       税処理を行う対象を変更（VD以外⇒VD）、確認項目の処理をVD,VD以外の両方で行うように変更
 *  2009/08/24    1.14  M.Sano           障害[0001162]対応
 *                                       従業員マスタの抽出条件の追加
 *  2009/09/01    1.15  M.Sano           障害[0000900]対応
 *                                       MainSQL,INSERT文にヒント句の追加、検索条件の最適化
 *  2009/09/30    1.16  S.Miyakoshi      障害[0001378]帳票テーブルの桁あふれ対応
 *  2009/11/27    1.17  K.Atsushiba      [E_本稼動_00128]営業員を指定時に他営業員のデータが出力されないように変更
 *  2009/12/12    1.18  N.Maeda          [E_本稼動_00140]ソート順修正に伴う取得項目、設定項目の追加
 *  2009/12/17    1.19  K.Atsushiba      [E_本稼動_00521]入金データが納品実績の入金欄に表示されない対応
 *                                       [E_本稼動_00522]売上値引きが表示されない対応
 *                                       [E_本稼動_00532]納品実績データの重複表示対応
 *  2010/01/07    1.20  N.Maeda          [E_本稼動_00849] 値引のみデータ対応
 *  2011/03/07    1.21  S.Ochiai         [E_本稼動_06590]オーダー№追加連携対応
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
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  data_get_err EXCEPTION;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS002A05R';       -- パッケージ名
--
  -- 帳票関連
  cv_conc_name                  CONSTANT VARCHAR2(100) := 'XXCOS002A05R';       -- コンカレント名
  cv_file_id                    CONSTANT VARCHAR2(100) := 'XXCOS002A05R';       -- 帳票ＩＤ
  cv_extension_pdf              CONSTANT VARCHAR2(100) := '.pdf';               -- 拡張子（ＰＤＦ）
  cv_frm_file                   CONSTANT VARCHAR2(100) := 'XXCOS002A05S.xml';   -- フォーム様式ファイル名
  cv_vrq_file                   CONSTANT VARCHAR2(100) := 'XXCOS002A05S.vrq';   -- クエリー様式ファイル名
  cv_output_mode_pdf            CONSTANT VARCHAR2(1)   := '1';                  -- 出力区分（ＰＤＦ）
--
  -- アプリケーション短縮名
  cv_application                CONSTANT VARCHAR2(5)   := 'XXCOS';
--
  -- メッセージ
  cv_msg_lock_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';   -- ロックエラー
  cv_msg_get_profile_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';   -- プロファイル取得エラー
  cv_msg_in_param_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';   -- 必須入力パラメータ未設定エラー
  cv_msg_insert_data_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';   -- データ登録エラーメッセージ
  cv_msg_delete_data_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';   -- データ削除エラーメッセージ
  cv_msg_get_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';   -- データ抽出エラーメッセージ
  cv_msg_call_api_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00017';   -- API呼出エラーメッセージ
  cv_msg_nodata_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00018';   -- 明細0件用メッセージ
  cv_msg_svf_api                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00041';   -- SVF起動API
  cv_msg_mst_qck                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';   -- クイックコードマスタ
  cv_msg_request_id             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00088';   -- 要求ID
  cv_msg_form_error             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10601';   -- 納品日の型違いメッセージ
  cv_msg_in_parameter           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10602';   -- 入力パラメータ
  cv_msg_check_list_work_table  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10603';   -- 納品書チェックリスト帳票テーブル
  cv_msg_dlv_date               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10604';   -- 納品日
  cv_msg_base                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10605';   -- 拠点
  cv_msg_type                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10606';   -- タイプ
  cv_msg_check_mark             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10607';   -- チェックマーク
  cv_msg_dlv_by_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10608';   -- 営業員
  cv_msg_hht_invoice_no         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10609';   -- HHT伝票No
  cv_msg_sale_header_table      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10610';   -- 販売実績ヘッダテーブル
-- 2009/12/17 Ver.1.19 Add Start
  cv_msg_payment_update_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10611';   -- 入金データ更新
-- 2009/12/17 Ver.1.19 Add End
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  cv_msg_name_lookup            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00075';
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
--
  -- トークン
  cv_tkn_in_param               CONSTANT VARCHAR2(100) := 'IN_PARAM';           -- 入力パラメータ
  cv_tkn_table                  CONSTANT VARCHAR2(100) := 'TABLE_NAME';         -- テーブル名
  cv_tkn_key_data               CONSTANT VARCHAR2(100) := 'KEY_DATA';           -- キー情報
  cv_tkn_profile                CONSTANT VARCHAR2(100) := 'PROFILE';            -- プロファイル名
  cv_tkn_api_name               CONSTANT VARCHAR2(100) := 'API_NAME';           -- API名称
  cv_tkn_para_delivery_date     CONSTANT VARCHAR2(100) := 'PARAM1';             -- 納品日
  cv_tkn_para_delivery_base     CONSTANT VARCHAR2(100) := 'PARAM2';             -- 拠点
  cv_tkn_para_dlv_by_code       CONSTANT VARCHAR2(100) := 'PARAM3';             -- 営業員
  cv_tkn_para_hht_invoice       CONSTANT VARCHAR2(100) := 'PARAM4';             -- HHT伝票No
-- 2009/12/17 Ver.1.19 Add Start
  cv_tkn_hht_invoice_no         CONSTANT VARCHAR2(100) := 'HHT_INVOICE_NO';     -- 納品伝票番号
  cv_tkn_customer_number        CONSTANT VARCHAR2(100) := 'CUSTOMER_NUMBER';    -- 顧客
  cv_tkn_payment_date           CONSTANT VARCHAR2(100) := 'PAYMENT_DATE';       -- 入金日
-- 2009/12/17 Ver.1.19 Add End

--
  -- クイックコード（作成元区分）
  ct_qck_org_cls_type           CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_MK_ORG_CLS_MST_002_A05';
--
  -- クイックコード（値引品目）
  ct_qck_discount_item_type     CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_DISCOUNT_ITEM_CODE';
--
  -- クイックコード（入力区分）
  ct_qck_input_class            CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_INPUT_CLASS';
--
  -- クイックコード（カード売区分）
  ct_qck_card_sale_class        CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_CARD_SALE_CLASS';
--
  -- クイックコード（売上区分）
  ct_qck_sale_class             CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';
--
  -- クイックコード（HHT消費税区分）
  ct_qck_tax_class              CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_CONSUMPTION_TAX_CLASS';
--
  -- クイックコード（入金区分）
  ct_qck_money_class            CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_RECEIPT_MONEY_CLASS';
--
  -- クイックコード（H/C区分）
  ct_qck_hc_class               CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_HC_CLASS';
--
  -- クイックコード（業態小分類特定マスタ）
  ct_qck_gyotai_sho_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_GYOTAI_SHO_MST_002_A03';
  ct_qck_gyotai_sho_mst1        CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_GYOTAI_SHO_MST_002_A05';
--
  -- Yes/No
  cv_yes                        CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                         CONSTANT VARCHAR2(1)   := 'N';
--
  -- NULL回避定数
  cv_x                          CONSTANT VARCHAR2(1)   := 'X';
--
  -- デフォルト値
  cn_zero                       CONSTANT NUMBER        := 0;
  cn_one                        CONSTANT NUMBER        := 1;
  cn_two                        CONSTANT NUMBER        := 2;
  cn_thr                        CONSTANT NUMBER        := 3;
--
  -- カード売り区分
  ct_cash                       CONSTANT xxcos_sales_exp_headers.card_sale_class%TYPE := '0';   -- 現金
  ct_card                       CONSTANT xxcos_sales_exp_headers.card_sale_class%TYPE := '1';   -- カード
--
  -- パラメータ日付指定書式
  cv_fmt_date_default           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_date                   CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
--
  -- 顧客区分
  ct_cust_class_base            CONSTANT hz_cust_accounts.customer_class_code%TYPE    := '1';   -- 拠点
  ct_cust_class_customer        CONSTANT hz_cust_accounts.customer_class_code%TYPE    := '10';  -- 顧客
-- ******************** 2009/05/01 Var.1.6 N.Maeda ADD START  ******************************************
  ct_cust_class_customer_u      CONSTANT hz_cust_accounts.customer_class_code%TYPE    := '12';  -- 上様顧客
-- ******************** 2009/05/01 Var.1.6 N.Maeda ADD  END   ******************************************
-- ******************** 2009/05/27 Var.1.7 K.KIN ADD START  ******************************************
  cv_round_rule_up         CONSTANT  VARCHAR2(10)  := 'UP';                             -- 切り上げ
  cv_round_rule_down       CONSTANT  VARCHAR2(10)  := 'DOWN';                           -- 切り下げ
  cv_round_rule_nearest    CONSTANT  VARCHAR2(10)  := 'NEAREST';                        -- 四捨五入
-- ******************** 2009/05/27 Var.1.7 K.KIN ADD START  ******************************************
-- ******************** 2009/06/05 Var.1.9 T.Tominaga ADD START  ******************************************
  cv_obsolete_class_one         CONSTANT VARCHAR2(1)   := '1';
-- ******************** 2009/06/05 Var.1.9 T.Tominaga ADD END    ******************************************
-- 2009/09/01 Ver.1.15 M.Sano Add Start
  -- 言語コード
  ct_lang                       CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- 2009/09/01 Ver.1.15 M.Sano Add End
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
  cv_fmt_time_default           CONSTANT  VARCHAR2(7)                                     :=  'HH24:MI';
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 販売実績データ登録
  TYPE g_dlv_chk_list_tab       IS TABLE OF xxcos_rep_dlv_chk_list%ROWTYPE
    INDEX BY PLS_INTEGER;
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  TYPE disc_item          IS RECORD(  disc_item_code fnd_lookup_values.lookup_code%TYPE );    -- 値引品目コード
  TYPE g_disc_item_work_ttype  IS TABLE OF disc_item INDEX BY BINARY_INTEGER;
  TYPE g_disc_item_ttype  IS TABLE OF disc_item INDEX BY fnd_lookup_values.lookup_code%TYPE;
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 販売実績データ登録
  gt_dlv_chk_list               g_dlv_chk_list_tab;             -- 販売実績データ登録
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  gt_disc_item_work_tab         g_disc_item_work_ttype;         -- 値引品目コード一時格納用
  gt_disc_item_tab              g_disc_item_ttype;              -- 値引品目コード格納用
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  
--
  gv_tkn1                       VARCHAR2(5000);                 -- エラーメッセージ用トークン１
  gv_tkn2                       VARCHAR2(5000);                 -- エラーメッセージ用トークン２
  gv_tkn3                       VARCHAR2(5000);                 -- エラーメッセージ用トークン３
  gv_tkn4                       VARCHAR2(5000);                 -- エラーメッセージ用トークン４
  gv_key_info                   VARCHAR2(5000);                 -- キー情報
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_delivery_date      IN      VARCHAR2,         -- 納品日
    iv_delivery_base_code IN      VARCHAR2,         -- 拠点
    iv_dlv_by_code        IN      VARCHAR2,         -- 営業員
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT伝票No
    ov_errbuf             OUT     VARCHAR2,         -- エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         -- リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ        --# 固定 #
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
    -- キー情報
    lv_key_info                 VARCHAR2(5000);
    --パラメータ出力用
    lv_para_msg                 VARCHAR2(5000);
--
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --  パラメータ出力
    lv_para_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_in_parameter,
                     iv_token_name1  => cv_tkn_para_delivery_date,
                     iv_token_value1 => iv_delivery_date,
                     iv_token_name2  => cv_tkn_para_delivery_base,
                     iv_token_value2 => iv_delivery_base_code,
                     iv_token_name3  => cv_tkn_para_dlv_by_code,
                     iv_token_value3 => iv_dlv_by_code,
                     iv_token_name4  => cv_tkn_para_hht_invoice,
                     iv_token_value4 => iv_hht_invoice_no
                     );
--
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => lv_para_msg
    );
--
    --  1行空白
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => NULL
    );
--
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
    BEGIN
      SELECT  look_val.lookup_code        lookup_code
      BULK COLLECT INTO
              gt_disc_item_work_tab
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
      AND     look_val.enabled_flag      = cv_yes                     -- Y
      AND     TO_DATE(iv_delivery_date,cv_fmt_date_default)
                >= NVL( look_val.start_date_active, TO_DATE(iv_delivery_date,cv_fmt_date_default) )
      AND     TO_DATE(iv_delivery_date,cv_fmt_date_default)
                <= NVL( look_val.end_date_active, TO_DATE(iv_delivery_date,cv_fmt_date_default) )
      AND     look_val.language          = ct_lang;
      --
      IF ( gt_disc_item_work_tab.COUNT = 0 ) THEN
        RAISE data_get_err;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE data_get_err;
    END;
    --
    FOR d IN 1..gt_disc_item_work_tab.COUNT LOOP
      gt_disc_item_tab(gt_disc_item_work_tab(d).disc_item_code) := gt_disc_item_work_tab(d);
    END LOOP;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
--
  EXCEPTION
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
    WHEN data_get_err THEN
      -- テーブル名:クイックコードマスタ
      gv_tkn1 := xxccp_common_pkg.get_msg( iv_application  => cv_application
                                          ,iv_name         => cv_msg_mst_qck  );
      -- 項目名:クイックコード
      gv_tkn2 := xxccp_common_pkg.get_msg( iv_application  => cv_application
                                          ,iv_name         => cv_msg_name_lookup  );
      -- キー情報編集
      xxcos_common_pkg.makeup_key_info(
                                   ov_errbuf      => lv_errbuf           -- エラー・メッセージ
                                  ,ov_retcode     => lv_retcode          -- リターン・コード
                                  ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
                                  ,ov_key_info    => gv_key_info         -- キー情報
                                  ,iv_item_name1  => gv_tkn1             -- 要求ID
                                  ,iv_data_value1 => ct_qck_discount_item_type
                                  );
      --
      lv_errbuf := xxccp_common_pkg.get_msg( iv_application  => cv_application
                                            ,iv_name         => cv_msg_get_err
                                            ,iv_token_name1  => cv_tkn_table
                                            ,iv_token_value1 => gv_tkn1
                                            ,iv_token_name2  => cv_tkn_key_data
                                            ,iv_token_value2 => gv_key_info
                                              );
      -- ログ出力
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
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
   * Procedure Name   : sales_per_data_entry
   * Description      : 販売実績データ抽出(A-3)、納品データ登録（販売実績）(A-4)
   ***********************************************************************************/
  PROCEDURE sales_per_data_entry(
    iv_delivery_date      IN      VARCHAR2,         -- 納品日
    iv_delivery_base_code IN      VARCHAR2,         -- 拠点
    iv_dlv_by_code        IN      VARCHAR2,         -- 営業員
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT伝票No
    ov_errbuf             OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_per_data_entry'; -- プログラム名
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
    ld_delivery_date       DATE;                                            -- パラメータ変換後の納品日
    lv_check_mark          VARCHAR2(2);                                     -- チェックマーク
    ln_target_cnt          NUMBER;                                          -- 対象件数
    lt_enabled_flag        fnd_lookup_values.enabled_flag%TYPE;             -- 業態小分類使用可
    lt_standard_unit_price xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- 基準単価
    lt_business_cost       xxcos_sales_exp_lines.business_cost%TYPE;        -- 営業原価
    lt_st_date             ic_item_mst_b.attribute6%TYPE;                   -- 定価適用開始
    lt_plice_new           ic_item_mst_b.attribute5%TYPE;                   -- 定価(新)
    lt_plice_old           ic_item_mst_b.attribute4%TYPE;                   -- 旧定価
    lt_plice_new_no_tax    ic_item_mst_b.attribute5%TYPE;                   -- 定価(新)
    lt_plice_old_no_tax    ic_item_mst_b.attribute4%TYPE;                   -- 旧定価
    lt_confirmation        xxcos_rep_dlv_chk_list.confirmation%TYPE;        -- 確認
    lt_set_plice           xxcos_rep_dlv_chk_list.ploce%TYPE;               -- 売値
    lt_tax_amount          NUMBER;                                          -- 税金
    lt_tax_rate            xxcos_sales_exp_headers.tax_rate%TYPE;           -- 消費税税率
--
    -- *** ローカル・カーソル ***
-- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
--    -- 販売実績データ抽出
--    CURSOR get_sale_data_cur(
--                               icp_delivery_date       DATE       -- 納品日
--                              ,icp_delivery_base_code  VARCHAR2   -- 拠点
--                              ,icp_dlv_by_code         VARCHAR2   -- 営業員
--                              ,icp_hht_invoice_no      VARCHAR2   -- HHT伝票No
--                            )
--    IS
--      SELECT
--         infh.delivery_date                     AS target_date                     -- 対象日付
--        ,infh.sales_base_code                   AS base_code                       -- 拠点コード
--        ,MIN( SUBSTRB( parb.party_name, 1, 40 ) )
--                                                AS base_name                       -- 拠点名称
--        ,riv.employee_number                    AS employee_num                    -- 納品者コード
--        ,MIN( riv.employee_name )               AS employee_name                   -- 営業員氏名
--        ,MIN( riv.group_code )                  AS group_code                      -- グループ番号
--        ,MIN( riv.group_in_sequence )           AS group_in_sequence               -- グループ内順序
--        ,infh.dlv_invoice_number                AS invoice_no                      -- 伝票番号
--        ,infh.inspect_date                      AS dlv_date                        -- 納品日
--        ,infh.ship_to_customer_code             AS party_num                       -- 顧客コード
--        ,MIN( SUBSTRB( parc.party_name, 1, 40 ) )
--                                                AS customer_name                   -- 顧客名
--        ,incl.meaning                           AS input_class                     -- 入力区分
--        ,infh.results_employee_code             AS performance_by_code             -- 成績計上者コード
--        ,MIN( ppf.per_information18 || ' ' || ppf.per_information19 )
--                                                AS performance_by_name             -- 成績者名
--        ,CASE gysm1.vd_gyotai
--           WHEN  cv_yes  THEN MIN( cscl.meaning )
--           ELSE  NULL
--         END                                    AS card_sale_class                 -- カード売り区分
--        ,MIN( infh.sale_amount_sum )            AS sudstance_total_amount          -- 売上額
--        ,MIN( disc.sale_discount_amount )       AS sale_discount_amount            -- 売上値引額
--        ,MIN( infh.tax_amount_sum )             AS consumption_tax_total_amount    -- 消費税金額合計
--        ,MIN( tacl.meaning )                    AS consumption_tax_class_mst       -- 消費税区分（マスタ）
--        ,infh.invoice_classification_code       AS invoice_classification_code     -- 伝票分類コード
--        ,infh.invoice_class                     AS invoice_class                   -- 伝票区分
--        ,MIN( sacl.meaning )                    AS sale_class                      -- 売上区分
--        ,sel.item_code                          AS item_code                       -- 品目コード
--        ,MIN( ximb.item_short_name )            AS item_name                       -- 商品名
--        ,SUM( sel.standard_qty )                AS quantity                        -- 数量
--        ,sel.standard_unit_price                AS wholesale_unit_ploce            -- 卸単価
--        ,MIN( gysm.enabled_flag )               AS enabled_flag                    -- 業態小分類使用可
--        ,MIN( sel.standard_unit_price )         AS standard_unit_price             -- 基準単価
--        ,MIN( sel.business_cost )               AS business_cost                   -- 営業原価
--        ,MIN( iimb.attribute6 )                 AS st_date                         -- 定価適用開始
--        ,MIN( iimb.attribute5 )                 AS plice_new                       -- 定価(新)
--        ,MIN( iimb.attribute4 )                 AS plice_old                       -- 旧定価
--        ,htcl.meaning                           AS consum_tax_calss_entered        -- 消費税区分（入力）
--        ,CASE infh.card_sale_class
--           WHEN  ct_cash  THEN MIN( sel.cash_and_card )
--           WHEN  ct_card  THEN MIN( sel.sale_amount )
--           ELSE  cn_zero
--         END                                    AS card_amount                     -- カード金額
--        ,sel.column_no                          AS column_no                       -- コラム
--        ,hccl.meaning                           AS h_and_c                         -- H/C
--        ,pacl.meaning                           AS payment_class                   -- 入金区分
----        ,pay.payment_amount                     AS payment_amount                  -- 入金額
--        ,CASE gysm1.vd_gyotai
--           WHEN  cv_yes  THEN SUM( sel.standard_qty ) * sel.standard_unit_price 
--                                              -DECODE( infh.card_sale_class
--                                                , ct_cash, MIN( sel.cash_and_card )
--                                                , ct_card, MIN( sel.sale_amount )
--                                                , cn_zero )
--           ELSE  NULL
--         END                                    AS payment_amount                  -- 入金額
--        ,MIN( cust.tax_rounding_rule )          AS tax_rounding_rule
--        ,MIN( infh.tax_rate )                   AS tax_rate                        -- 消費税税率
--        ,MIN( infh.consumption_tax_class )      AS consumption_tax_class           -- 消費税区分
--      FROM
--         xxcos_sales_exp_lines    sel           -- 販売実績明細テーブル
--        ,hz_cust_accounts         base          -- 顧客マスタ_拠点
--        ,hz_cust_accounts         cust          -- 顧客マスタ_顧客
--        ,xxcmm_cust_accounts      cuac          -- 顧客追加情報
--        ,hz_parties               parb          -- パーティ_拠点
--        ,hz_parties               parc          -- パーティ_顧客
--        ,xxcos_payment            pay           -- 入金テーブル
--        ,ic_item_mst_b            iimb          -- OPM品目
--        ,xxcmn_item_mst_b         ximb          -- OPM品目アドオン
--        ,per_people_f             ppf           -- 従業員マスタ_納品
--        ,xxcos_rs_info_v          riv           -- 営業員情報view
--        ,(
--           SELECT
--              seh.delivery_date               AS delivery_date                -- 対象日付
--             ,seh.sales_base_code             AS sales_base_code              -- 拠点コード
--             ,seh.dlv_by_code                 AS dlv_by_code                  -- 納品者コード
--             ,seh.dlv_invoice_number          AS dlv_invoice_number           -- 伝票番号
--             ,seh.delivery_date               AS dlv_date                     -- 納品日
--             ,seh.ship_to_customer_code       AS ship_to_customer_code        -- 顧客コード
--             ,seh.input_class                 AS input_class                  -- 入力区分
--             ,seh.results_employee_code       AS results_employee_code        -- 成績計上者コード
--             ,seh.card_sale_class             AS card_sale_class              -- カード売り区分
--             ,seh.consumption_tax_class       AS consumption_tax_class        -- 消費税区分
--             ,seh.invoice_classification_code AS invoice_classification_code  -- 伝票分類コード
--             ,seh.invoice_class               AS invoice_class                -- 伝票区分
--             ,SUM(
--               CASE sel.item_code
--                 WHEN diit.lookup_code THEN sel.sale_amount
--                 ELSE cn_zero
--               END
--              )                               AS sale_discount_amount         -- 売上値引額
--           FROM
--              xxcos_sales_exp_headers   seh           -- 販売実績ヘッダテーブル
--             ,xxcos_sales_exp_lines     sel           -- 販売実績明細テーブル
--             ,(
--                SELECT  look_val.lookup_code        lookup_code
--                       ,look_val.meaning            meaning
--                FROM    fnd_lookup_values     look_val
--                       ,fnd_lookup_types_tl   types_tl
--                       ,fnd_lookup_types      types
--                       ,fnd_application_tl    appl
--                       ,fnd_application       app
--                WHERE   app.application_short_name = cv_application             -- XXCOS
--                AND     look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
--                AND     look_val.enabled_flag      = cv_yes                     -- Y
--                AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--                AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--                AND     types_tl.language          = USERENV( 'LANG' )
--                AND     look_val.language          = USERENV( 'LANG' )
--                AND     appl.language              = USERENV( 'LANG' )
--                AND     appl.application_id        = types.application_id
--                AND     app.application_id         = appl.application_id
--                AND     types_tl.lookup_type       = look_val.lookup_type
--                AND     types.lookup_type          = types_tl.lookup_type
--                AND     types.security_group_id    = types_tl.security_group_id
--                AND     types.view_application_id  = types_tl.view_application_id
--              ) diit    -- 値引品目
--           WHERE
--             seh.delivery_date           = icp_delivery_date                        -- パラメータの納品日
--           AND seh.sales_base_code       = icp_delivery_base_code                   -- パラメータの拠点
--           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )  -- パラメータの営業員
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )
--                                                                                  -- パラメータの伝票番号
--           AND seh.sales_exp_header_id   = sel.sales_exp_header_id
--           AND sel.item_code             = diit.lookup_code(+)
--           GROUP BY
--              seh.delivery_date                      -- 納品日
--             ,seh.sales_base_code                    -- 拠点コード
--             ,seh.dlv_by_code                        -- 納品者コード
--             ,seh.dlv_invoice_number                 -- 伝票番号
--             ,seh.ship_to_customer_code              -- 顧客コード
--             ,seh.input_class                        -- 入力区分
--             ,seh.results_employee_code              -- 成績計上者コード
--             ,seh.card_sale_class                    -- カード売り区分
--             ,seh.consumption_tax_class              -- 消費税区分
--             ,seh.invoice_classification_code        -- 伝票分類コード
--             ,seh.invoice_class                      -- 伝票区分
--         ) disc         -- 売上値引額
--        ,(
--           SELECT
--              MIN( seh.sales_exp_header_id )         AS sales_exp_header_id             -- 販売実績ヘッダID
--             ,seh.delivery_date                      AS delivery_date                   -- 対象日付
--             ,seh.sales_base_code                    AS sales_base_code                 -- 拠点コード
--             ,seh.dlv_by_code                        AS dlv_by_code                     -- 納品者コード
--             ,seh.dlv_invoice_number                 AS dlv_invoice_number              -- 伝票番号
--             ,seh.delivery_date                      AS dlv_date                        -- 納品日
--             ,seh.inspect_date                       AS inspect_date                    -- 検収日
--             ,seh.ship_to_customer_code              AS ship_to_customer_code           -- 顧客コード
--             ,seh.input_class                        AS input_class                     -- 入力区分
--             ,MIN( seh.cust_gyotai_sho )             AS cust_gyotai_sho                 -- 業態小分類
--             ,seh.results_employee_code              AS results_employee_code           -- 成績計上者コード
--             ,seh.card_sale_class                    AS card_sale_class                 -- カード売り区分
--             ,SUM( seh.sale_amount_sum )             AS sale_amount_sum                 -- 売上額
--             ,SUM( seh.tax_amount_sum  )             AS tax_amount_sum                  -- 消費税金額合計
--             ,seh.consumption_tax_class              AS consumption_tax_class           -- 消費税区分
--             ,seh.invoice_classification_code        AS invoice_classification_code     -- 伝票分類コード
--             ,seh.invoice_class                      AS invoice_class                   -- 伝票区分
--             ,MIN( seh.create_class )                AS create_class                    -- 作成元区分
--             ,MIN( seh.tax_rate )                    AS tax_rate                        -- 消費税税率
--           FROM
--             xxcos_sales_exp_headers   seh           -- 販売実績ヘッダテーブル
--           WHERE
--             seh.delivery_date           = icp_delivery_date                        -- パラメータの納品日
--           AND seh.sales_base_code       = icp_delivery_base_code                   -- パラメータの拠点
--           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )  -- パラメータの営業員
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )
--                                                                                  -- パラメータの伝票番号
--           GROUP BY
--              seh.delivery_date                      -- 納品日
--             ,seh.sales_base_code                    -- 拠点コード
--             ,seh.dlv_by_code                        -- 納品者コード
--             ,seh.inspect_date                       -- 検収日
--             ,seh.dlv_invoice_number                 -- 伝票番号
--             ,seh.ship_to_customer_code              -- 顧客コード
--             ,seh.input_class                        -- 入力区分
--             ,seh.results_employee_code              -- 成績計上者コード
--             ,seh.card_sale_class                    -- カード売り区分
--             ,seh.consumption_tax_class              -- 消費税区分
--             ,seh.invoice_classification_code        -- 伝票分類コード
--             ,seh.invoice_class                      -- 伝票区分
--         ) infh         -- ヘッダ情報
--        ,(
--            SELECT  look_val.meaning      meaning 
--            FROM    fnd_lookup_values     look_val
--                   ,fnd_lookup_types_tl   types_tl
--                   ,fnd_lookup_types      types
--                   ,fnd_application_tl    appl
--                   ,fnd_application       app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_org_cls_type     -- XXCOS1_MK_ORG_CLS_MST_002_A05
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  orct    -- 作成元区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_input_class      -- XXCOS1_INPUT_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  incl    -- 入力区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_card_sale_class  -- XXCOS1_CARD_SALE_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  cscl    -- カード売区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_sale_class       -- XXCOS1_SALE_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  sacl    -- 売上区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--                   ,look_val.attribute3         attribute3
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_tax_class        -- XXCOS1_CONSUMPTION_TAX_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  htcl    -- HHT消費税区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_money_class      -- XXCOS1_RECEIPT_MONEY_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  pacl    -- 入金区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_hc_class         -- XXCOS1_HC_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  hccl    -- H/C区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--                   ,look_val.attribute3         attribute3
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_tax_class        -- XXCOS1_CONSUMPTION_TAX_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  tacl    -- 消費税区分
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--                   ,look_val.enabled_flag       enabled_flag
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_gyotai_sho_mst   -- XXCOS1_GYOTAI_SHO_MST_002_A03
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  gysm    -- 業態小分類特定マスタ
--        ,(
--            SELECT  look_val.meaning            meaning
--                   ,look_val.attribute1         vd_gyotai
--            FROM    fnd_lookup_values           look_val
--            WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1   -- XXCOS1_GYOTAI_SHO_MST_002_A05
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     look_val.language          = USERENV( 'LANG' )
--         )  gysm1    -- 業態小分類特定マスタ
--      WHERE
--        infh.delivery_date           = icp_delivery_date               -- パラメータの納品日
--      AND infh.sales_base_code       = icp_delivery_base_code          -- パラメータの拠点
--      AND infh.sales_exp_header_id   = sel.sales_exp_header_id          -- 販売実績ヘッダ＆明細.販売実績ヘッダID
--      AND base.customer_class_code   = ct_cust_class_base              -- 顧客区分＝拠点
--      AND infh.sales_base_code       = base.account_number             -- 販売実績ヘッダ＝顧客マスタ_拠点
--      AND base.party_id              = parb.party_id                   -- 顧客マスタ_拠点＝パーティ_拠点
---- ******************** 2009/05/01 Var.1.6 N.Maeda MOD START  ******************************************
----      AND cust.customer_class_code   = ct_cust_class_customer          -- 顧客区分＝顧客
--      AND cust.customer_class_code   IN ( ct_cust_class_customer , ct_cust_class_customer_u ) -- 顧客区分IN 顧客,上様顧客
---- ******************** 2009/05/01 Var.1.6 N.Maeda MOD  END   ******************************************
--      AND infh.ship_to_customer_code = cust.account_number             -- 販売実績ヘッダ＝顧客マスタ_顧客
--      AND cust.cust_account_id       = cuac.customer_id                -- 顧客マスタ_顧客＝顧客追加情報
--      AND cust.party_id              = parc.party_id                   -- 顧客マスタ_顧客＝パーティ_顧客
--      AND infh.create_class IN ( orct.meaning )                        -- 作成元区分＝クイックコード
--      AND infh.results_employee_code = ppf.employee_number(+)
--      AND sel.item_code              = iimb.item_no
--      AND iimb.item_id               = ximb.item_id
--      AND infh.sales_base_code       = riv.base_code
--      AND riv.employee_number        = NVL( icp_dlv_by_code, riv.employee_number )
--      AND infh.delivery_date        >= NVL( riv.effective_start_date, infh.delivery_date )
--      AND infh.delivery_date        <= NVL( riv.effective_end_date, infh.delivery_date )
--      AND infh.delivery_date        >= riv.per_effective_start_date
--      AND infh.delivery_date        <= riv.per_effective_end_date
--      AND infh.delivery_date        >= riv.paa_effective_start_date
--      AND infh.delivery_date        <= riv.paa_effective_end_date
--      AND infh.dlv_invoice_number    = NVL( icp_hht_invoice_no, infh.dlv_invoice_number )
--      AND infh.dlv_invoice_number    = pay.hht_invoice_no(+)
--      AND incl.lookup_code           = infh.input_class
--      AND cscl.lookup_code           = NVL( infh.card_sale_class, cv_x )
--      AND sacl.lookup_code           = sel.sales_class
--      AND htcl.attribute3            = infh.consumption_tax_class
--      AND pacl.lookup_code(+)        = pay.payment_class
--      AND hccl.lookup_code(+)        = NVL( sel.hot_cold_class, cv_x )
--      AND tacl.attribute3            = cuac.tax_div
--      AND gysm.meaning(+)            = infh.cust_gyotai_sho
--      AND infh.delivery_date         = disc.delivery_date                -- ヘッダ情報、売上値引額.納品日
--      AND infh.sales_base_code       = disc.sales_base_code              -- ヘッダ情報、売上値引額.拠点コード
--      AND riv.employee_number        = infh.dlv_by_code                  -- 営業員情報、ヘッダ情報.納品者コード
--      AND infh.dlv_invoice_number    = disc.dlv_invoice_number           -- ヘッダ情報、売上値引額.伝票番号
--      AND infh.dlv_date              = disc.dlv_date                     -- ヘッダ情報、売上値引額.納品日
--      AND infh.ship_to_customer_code = disc.ship_to_customer_code        -- ヘッダ情報、売上値引額.顧客コード
--      AND infh.results_employee_code = disc.results_employee_code        -- ヘッダ情報、売上値引額.成績計上者コード
--      AND NVL( infh.invoice_classification_code, cv_x )
--            = NVL( disc.invoice_classification_code, cv_x )              -- ヘッダ情報、売上値引額.伝票分類コード
--      AND NVL( infh.invoice_class, cv_x )
--                                     = NVL( disc.invoice_class, cv_x )   -- ヘッダ情報、売上値引額.伝票区分
--      AND NVL( infh.card_sale_class, cv_x )
--                                     = NVL( disc.card_sale_class, cv_x ) -- ヘッダ情報、売上値引額.カード売り区分
--      AND cuac.business_low_type     = gysm1.meaning( + )
--      GROUP BY
--         infh.delivery_date                      -- 対象日付
--        ,infh.sales_base_code                    -- 拠点コード
--        ,riv.employee_number                     -- 納品者コード
--        ,infh.dlv_invoice_number                 -- 伝票番号
--        ,infh.dlv_date                           -- 納品日
--        ,infh.inspect_date                       -- 検収日(納品日)
--        ,infh.ship_to_customer_code              -- 顧客コード
--        ,incl.meaning                            -- 入力区分
--        ,infh.results_employee_code              -- 成績計上者コード
--        ,infh.card_sale_class                    -- カード売り区分
--        ,htcl.meaning                            -- 消費税区分
--        ,infh.invoice_classification_code        -- 伝票分類コード
--        ,infh.invoice_class                      -- 伝票区分
--        ,sel.item_code                           -- 品目コード
--        ,sel.standard_unit_price                 -- 卸単価
--        ,sel.column_no                           -- コラム
--        ,sel.red_black_flag                      -- 赤黒フラグ
--        ,hccl.meaning                            -- H/C
--        ,pacl.meaning                            -- 入金区分
----        ,pay.payment_amount                      -- 入金額
--        ,gysm1.vd_gyotai
--      HAVING
--        ( SUM( sel.sale_amount )  != 0           -- 売上金額
--          OR
--          SUM( sel.standard_qty ) != 0 )         -- 納品数量
--      ;
--
    -- 販売実績データ抽出
    CURSOR get_sale_data_cur(
                               icp_delivery_date       DATE       -- 納品日
                              ,icp_delivery_base_code  VARCHAR2   -- 拠点
                              ,icp_dlv_by_code         VARCHAR2   -- 営業員
                              ,icp_hht_invoice_no      VARCHAR2   -- HHT伝票No
                            )
    IS
      SELECT
-- 2009/09/01 Ver.1.15 M.Sano Add Start
         /*+
           LEADING ( riv.jrrx_n )
           INDEX   ( riv.jrgm_n jtf_rs_group_members_n2)
           INDEX   ( riv.jrgb_n jtf_rs_groups_b_u1 )
           INDEX   ( riv.jrrx_n xxcso_jrre_n02 )
           USE_NL  ( riv.papf_n )
           USE_NL  ( riv.pept_n )
           USE_NL  ( riv.paaf_n )
           USE_NL  ( riv.jrgm_n )
           USE_NL  ( riv.jrgb_n )
           LEADING ( riv.jrrx_o )
           INDEX   ( riv.jrrx_o xxcso_jrre_n02 )
           INDEX   ( riv.jrgm_o jtf_rs_group_members_n2)
           INDEX   ( riv.jrgb_o jtf_rs_groups_b_u1 )
           USE_NL  ( riv.papf_o )
           USE_NL  ( riv.pept_o )
           USE_NL  ( riv.paaf_o )
           USE_NL  ( riv.jrgm_o )
           USE_NL  ( riv.jrgb_o )
           USE_NL  ( riv )
           USE_NL  ( disc )
           USE_NL  ( infd )
         */
-- 2009/09/01 Ver.1.15 M.Sano Add End
         infh.delivery_date                        AS target_date                     -- 対象日付
        ,infh.sales_base_code                      AS base_code                       -- 拠点コード
        ,SUBSTRB( parb.party_name, 1, 40 )         AS base_name                       -- 拠点名称
        ,riv.employee_number                       AS employee_num                    -- 納品者コード
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD START ************************ --
--        ,riv.employee_name                         AS employee_name                   -- 営業員氏名
        ,SUBSTRB( riv.employee_name, 1, 40 )       AS employee_name                   -- 営業員氏名
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD  END  ************************ --
        ,riv.group_code                            AS group_code                      -- グループ番号
        ,riv.group_in_sequence                     AS group_in_sequence               -- グループ内順序
        ,infh.dlv_invoice_number                   AS invoice_no                      -- 伝票番号
        ,infh.inspect_date                         AS dlv_date                        -- 検収日
        ,infh.ship_to_customer_code                AS party_num                       -- 顧客コード
        ,SUBSTRB( parc.party_name, 1, 40 )         AS customer_name                   -- 顧客名
        ,incl.meaning                              AS input_class                     -- 入力区分
        ,infh.results_employee_code                AS performance_by_code             -- 成績計上者コード
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD START ************************ --
--        ,ppf.per_information18 || ' ' || ppf.per_information19
        ,SUBSTRB( ppf.per_information18 || ' ' || ppf.per_information19, 1, 40 )
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD  END  ************************ --
                                                   AS performance_by_name             -- 成績者名
        ,CASE gysm1.vd_gyotai
           WHEN  cv_yes  THEN cscl.meaning
           ELSE  NULL
         END                                       AS card_sale_class                 -- カード売り区分
        ,infh.sale_amount_sum                      AS sudstance_total_amount          -- 売上額
        ,disc.sale_discount_amount                 AS sale_discount_amount            -- 売上値引額
        ,infh.tax_amount_sum                       AS consumption_tax_total_amount    -- 消費税金額合計
        ,tacl.meaning                              AS consumption_tax_class_mst       -- 消費税区分（マスタ）
        ,infh.invoice_classification_code          AS invoice_classification_code     -- 伝票分類コード
        ,infh.invoice_class                        AS invoice_class                   -- 伝票区分
        ,sacl.meaning                              AS sale_class                      -- 売上区分
        ,infd.item_code                            AS item_code                       -- 品目コード
        ,ximb.item_short_name                      AS item_name                       -- 商品名
        ,infd.quantity                             AS quantity                        -- 数量
        ,infd.wholesale_unit_ploce                 AS wholesale_unit_ploce            -- 卸単価
        ,gysm.enabled_flag                         AS enabled_flag                    -- 業態小分類使用可
        ,infd.standard_unit_price                  AS standard_unit_price             -- 基準単価
        ,infd.business_cost                        AS business_cost                   -- 営業原価
        ,iimb.attribute6                           AS st_date                         -- 定価適用開始
        ,iimb.attribute5                           AS plice_new                       -- 定価(新)
        ,iimb.attribute4                           AS plice_old                       -- 旧定価
        ,htcl.meaning                              AS consum_tax_calss_entered        -- 消費税区分（入力）
        ,infd.card_amount                          AS card_amount                     -- カード金額
        ,infd.column_no                            AS column_no                       -- コラム
        ,hccl.meaning                              AS h_and_c                         -- H/C
        ,infd.payment_class                        AS payment_class                   -- 入金区分
        ,infd.payment_amount                       AS payment_amount                  -- 入金額
        ,infd.tax_rounding_rule                    AS tax_rounding_rule               -- 端数処理区分
        ,infd.tax_rate                             AS tax_rate                        -- 消費税税率
        ,infd.consumption_tax_class                AS consumption_tax_class           -- 消費税区分
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
        ,infh.hht_dlv_input_date                   AS hht_dlv_input_date              -- HHT納品入力日時
        ,infd.dlv_invoice_line_number              AS dlv_invoice_line_number         -- 納品明細番号
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
        ,infh.order_invoice_number                 AS order_number                    -- オーダーNo
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
      FROM
         hz_cust_accounts         base          -- 顧客マスタ_拠点
        ,hz_cust_accounts         cust          -- 顧客マスタ_顧客
        ,xxcmm_cust_accounts      cuac          -- 顧客追加情報
        ,hz_parties               parb          -- パーティ_拠点
        ,hz_parties               parc          -- パーティ_顧客
-- 2009/08/24 Ver.1.14 M.Sano Mod Start
--        ,per_people_f             ppf           -- 従業員マスタ_成績者名
        ,per_all_people_f         ppf           -- 従業員マスタ_成績者名
-- 2009/08/24 Ver.1.14 M.Sano Mod End
        ,ic_item_mst_b            iimb          -- OPM品目
        ,xxcmn_item_mst_b         ximb          -- OPM品目アドオン
        ,xxcos_rs_info_v          riv           -- 営業員情報view
        ,(
           SELECT
              seh.delivery_date               AS delivery_date                -- 対象日付
             ,seh.sales_base_code             AS sales_base_code              -- 拠点コード
             ,seh.dlv_by_code                 AS dlv_by_code                  -- 納品者コード
             ,seh.dlv_invoice_number          AS dlv_invoice_number           -- 伝票番号
             ,seh.delivery_date               AS dlv_date                     -- 納品日
             ,seh.inspect_date                AS inspect_date                 -- 検収日
             ,seh.ship_to_customer_code       AS ship_to_customer_code        -- 顧客コード
             ,seh.input_class                 AS input_class                  -- 入力区分
             ,seh.results_employee_code       AS results_employee_code        -- 成績計上者コード
             ,seh.card_sale_class             AS card_sale_class              -- カード売り区分
             ,seh.invoice_classification_code AS invoice_classification_code  -- 伝票分類コード
             ,seh.consumption_tax_class       AS consumption_tax_class        -- 消費税区分
             ,seh.invoice_class               AS invoice_class                -- 伝票区分
             ,seh.create_class                AS create_class                 -- 作成元区分
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date          AS hht_dlv_input_date           -- HHT納品入力日時
-- 2009/12/17 Ver.1.19 Del Start
--             ,sel.dlv_invoice_line_number     AS dlv_invoice_line_number      -- 納品明細番号
-- 2009/12/17 Ver.1.19 Del End
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
             ,SUM(
               CASE sel.item_code
                 WHEN diit.lookup_code THEN sel.sale_amount
                 ELSE cn_zero
               END
              )                               AS sale_discount_amount         -- 売上値引額
           FROM
              xxcos_sales_exp_headers   seh           -- 販売実績ヘッダテーブル
             ,xxcos_sales_exp_lines     sel           -- 販売実績明細テーブル
             ,(
                SELECT  look_val.lookup_code        lookup_code
                       ,look_val.meaning            meaning
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
                AND     look_val.enabled_flag      = cv_yes                     -- Y
                AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
                AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--                AND     look_val.language          = USERENV( 'LANG' )
                AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
              ) diit    -- 値引品目
           WHERE
               seh.delivery_date         = icp_delivery_date                                    -- パラメータの納品日
           AND seh.sales_base_code       = icp_delivery_base_code                               -- パラメータの拠点
           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )              -- パラメータの営業員
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )    -- パラメータの伝票番号
           AND (   (    icp_hht_invoice_no    IS NOT NULL
                    AND seh.dlv_invoice_number = icp_hht_invoice_no )
                OR (    icp_hht_invoice_no    IS NULL ) )                                       -- パラメータの伝票番号
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           AND seh.sales_exp_header_id   = sel.sales_exp_header_id
           AND sel.item_code             = diit.lookup_code(+)
           GROUP BY
              seh.delivery_date                      -- 納品日
             ,seh.sales_base_code                    -- 拠点コード
             ,seh.dlv_by_code                        -- 納品者コード
             ,seh.dlv_invoice_number                 -- 伝票番号
             ,seh.inspect_date                       -- 検収日
             ,seh.ship_to_customer_code              -- 顧客コード
             ,seh.input_class                        -- 入力区分
             ,seh.results_employee_code              -- 成績計上者コード
             ,seh.card_sale_class                    -- カード売り区分
             ,seh.invoice_classification_code        -- 伝票分類コード
             ,seh.consumption_tax_class              -- 消費税区分
             ,seh.invoice_class                      -- 伝票区分
             ,seh.create_class                       -- 作成元区分
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date                 -- HHT納品入力日時
-- 2009/12/17 Ver.1.19 Del Start
--             ,sel.dlv_invoice_line_number            -- 納品明細番号
-- 2009/12/17 Ver.1.19 Del End
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
         ) disc         -- 売上値引額
        ,(
           SELECT
              seh.delivery_date               AS delivery_date                -- 対象日付
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
             ,seh.order_invoice_number        AS order_invoice_number         -- 注文伝票番号
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
             ,seh.sales_base_code             AS sales_base_code              -- 拠点コード
             ,seh.dlv_by_code                 AS dlv_by_code                  -- 納品者コード
             ,seh.dlv_invoice_number          AS dlv_invoice_number           -- 伝票番号
             ,seh.delivery_date               AS dlv_date                     -- 納品日
             ,seh.inspect_date                AS inspect_date                 -- 検収日
             ,seh.ship_to_customer_code       AS ship_to_customer_code        -- 顧客コード
             ,seh.input_class                 AS input_class                  -- 入力区分
             ,seh.results_employee_code       AS results_employee_code        -- 成績計上者コード
             ,seh.card_sale_class             AS card_sale_class              -- カード売り区分
             ,seh.invoice_classification_code AS invoice_classification_code  -- 伝票分類コード
             ,seh.consumption_tax_class       AS consumption_tax_class        -- 消費税区分
             ,seh.invoice_class               AS invoice_class                -- 伝票区分
             ,seh.create_class                AS create_class                 -- 作成元区分
             ,SUM( seh.sale_amount_sum )      AS sale_amount_sum              -- 売上額
             ,SUM( seh.tax_amount_sum  )      AS tax_amount_sum               -- 消費税金額合計
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date          AS hht_dlv_input_date           -- HHT納品入力日時
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
           FROM
              xxcos_sales_exp_headers   seh          -- 販売実績ヘッダテーブル
           WHERE
               seh.delivery_date         = icp_delivery_date                                   -- パラメータの納品日
           AND seh.sales_base_code       = icp_delivery_base_code                              -- パラメータの拠点
           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )             -- パラメータの営業員
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )   -- パラメータの伝票番号
           AND (   (    icp_hht_invoice_no    IS NOT NULL
                    AND seh.dlv_invoice_number = icp_hht_invoice_no )
                OR (    icp_hht_invoice_no    IS NULL ) )                                      -- パラメータの伝票番号
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           GROUP BY
              seh.delivery_date                      -- 納品日
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
             ,seh.order_invoice_number               -- 注文伝票番号
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
             ,seh.sales_base_code                    -- 拠点コード
             ,seh.dlv_by_code                        -- 納品者コード
             ,seh.dlv_invoice_number                 -- 伝票番号
             ,seh.inspect_date                       -- 検収日
             ,seh.ship_to_customer_code              -- 顧客コード
             ,seh.input_class                        -- 入力区分
             ,seh.results_employee_code              -- 成績計上者コード
             ,seh.card_sale_class                    -- カード売り区分
             ,seh.invoice_classification_code        -- 伝票分類コード
             ,seh.consumption_tax_class              -- 消費税区分
             ,seh.invoice_class                      -- 伝票区分
             ,seh.create_class                       -- 作成元区分
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date                 -- HHT納品入力日時
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
         ) infh         -- ヘッダ情報
        ,(
           SELECT
              seh.delivery_date                      AS delivery_date                   -- 対象日付
             ,seh.sales_base_code                    AS sales_base_code                 -- 拠点コード
             ,seh.dlv_by_code                        AS dlv_by_code                     -- 納品者コード
             ,seh.dlv_invoice_number                 AS dlv_invoice_number              -- 伝票番号
             ,seh.delivery_date                      AS dlv_date                        -- 納品日
             ,seh.inspect_date                       AS inspect_date                    -- 検収日
             ,seh.ship_to_customer_code              AS ship_to_customer_code           -- 顧客コード
             ,seh.input_class                        AS input_class                     -- 入力区分
             ,seh.results_employee_code              AS results_employee_code           -- 成績計上者コード
             ,seh.card_sale_class                    AS card_sale_class                 -- カード売り区分
             ,seh.invoice_classification_code        AS invoice_classification_code     -- 伝票分類コード
             ,seh.consumption_tax_class              AS consumption_tax_class           -- 消費税区分
             ,seh.invoice_class                      AS invoice_class                   -- 伝票区分
             ,seh.create_class                       AS create_class                    -- 作成元区分
-- 2009/12/17 Ver.1.19 Mod Start
             ,sel.sales_class                        AS sale_class                      -- 売上区分
--             ,MAX( sel.sales_class )                 AS sale_class                      -- 売上区分
-- 2009/12/17 Ver.1.19 Mod End
             ,sel.item_code                          AS item_code                       -- 品目コード
             ,SUM( sel.standard_qty )                AS quantity                        -- 数量
             ,sel.standard_unit_price                AS wholesale_unit_ploce            -- 卸単価
             ,MAX( sel.standard_unit_price )         AS standard_unit_price             -- 基準単価
             ,MAX( sel.business_cost )               AS business_cost                   -- 営業原価
             ,CASE seh.card_sale_class
                WHEN  ct_cash  THEN SUM( sel.cash_and_card )
                WHEN  ct_card  THEN SUM( sel.sale_amount )
                ELSE  cn_zero
              END                                    AS card_amount                     -- カード金額
             ,sel.column_no                          AS column_no                       -- コラム
             ,sel.hot_cold_class                     AS h_and_c                         -- H/C区分
             ,NULL                                   AS payment_class                   -- 入金区分
             ,CASE MAX(gysm.vd_gyotai)
                WHEN  cv_yes  THEN SUM( sel.standard_qty ) * MAX( sel.standard_unit_price )
                                                   -DECODE( seh.card_sale_class
                                                     , ct_cash, SUM( sel.cash_and_card )
                                                     , ct_card, SUM( sel.sale_amount )
                                                     , cn_zero )
                ELSE  NULL
              END                                    AS payment_amount                  -- 入金額
-- ******************** 2009/06/10 Var.1.10 T.Tominaga MOD START  *****************************************
--             ,MAX( cust.tax_rounding_rule )          AS tax_rounding_rule
             ,MAX( xchv.bill_tax_round_rule )          AS tax_rounding_rule             -- 端数処理区分
-- ******************** 2009/06/10 Var.1.10 T.Tominaga MOD END    *****************************************
             ,MAX( seh.tax_rate )                    AS tax_rate                        -- 消費税税率
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date          AS hht_dlv_input_date           -- HHT納品入力日時
             ,sel.dlv_invoice_line_number     AS dlv_invoice_line_number      -- 納品明細番号
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- **************** 2010/01/07 1.20 N.Maeda MOL START **************** --
             ,SUM(sel.sale_amount)             AS line_sale_amount
-- **************** 2010/01/07 1.20 N.Maeda MOL  END  **************** --
           FROM
               xxcos_sales_exp_lines     sel           -- 販売実績明細テーブル
              ,xxcos_sales_exp_headers   seh           -- 販売実績ヘッダテーブル
              ,hz_cust_accounts          cust          -- 顧客マスタ_顧客
              ,xxcmm_cust_accounts       cuac          -- 顧客追加情報
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD START  *****************************************
              ,xxcos_cust_hierarchy_v    xchv          -- 顧客ビュー
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD END    *****************************************
              ,hz_parties                parc          -- パーティ_顧客
              ,(
                  SELECT  look_val.meaning            meaning
                         ,look_val.attribute1         vd_gyotai
                  FROM    fnd_lookup_values           look_val
                  WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1       -- XXCOS1_GYOTAI_SHO_MST_002_A05
                  AND     look_val.enabled_flag      = cv_yes                       -- Y
                  AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
                  AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--                  AND     look_val.language          = USERENV( 'LANG' )
                  AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
               )  gysm     -- 業態小分類特定マスタ
           WHERE
               seh.sales_exp_header_id   = sel.sales_exp_header_id                  -- 販売実績ヘッダ＆明細.販売実績ヘッダID
           AND seh.delivery_date         = icp_delivery_date                        -- パラメータの納品日
           AND seh.sales_base_code       = icp_delivery_base_code                   -- パラメータの拠点
           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )  -- パラメータの営業員
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )   -- パラメータの伝票番号
           AND (   (    icp_hht_invoice_no    IS NOT NULL
                    AND seh.dlv_invoice_number = icp_hht_invoice_no )
                OR (    icp_hht_invoice_no    IS NULL ) )                           -- パラメータの伝票番号
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           AND seh.ship_to_customer_code = cust.account_number                      -- 販売実績ヘッダ＝顧客マスタ_顧客
           AND cust.customer_class_code  IN ( ct_cust_class_customer , ct_cust_class_customer_u )  
                                                                                    -- 顧客区分IN 顧客,上様顧客
           AND cust.cust_account_id      = cuac.customer_id                         -- 顧客マスタ_顧客＝顧客追加情報
           AND cust.party_id             = parc.party_id                            -- 顧客マスタ_顧客＝パーティ_顧客
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD START  *****************************************
           AND xchv.ship_account_number  = seh.ship_to_customer_code
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD END    *****************************************
           AND cuac.business_low_type    = gysm.meaning( + )                        -- 業態小分類
           GROUP BY
              seh.delivery_date                      -- 納品日
             ,seh.sales_base_code                    -- 拠点コード
             ,seh.dlv_by_code                        -- 納品者コード
             ,seh.dlv_invoice_number                 -- 伝票番号
             ,seh.inspect_date                       -- 検収日
             ,seh.ship_to_customer_code              -- 顧客コード
             ,seh.input_class                        -- 入力区分
             ,seh.results_employee_code              -- 成績計上者コード
             ,seh.card_sale_class                    -- カード売り区分
             ,seh.invoice_classification_code        -- 伝票分類コード
             ,seh.consumption_tax_class              -- 消費税区分
             ,seh.invoice_class                      -- 伝票区分
             ,seh.create_class                       -- 作成元区分
             ,sel.item_code                          -- 品目コード
             ,sel.standard_unit_price                -- 卸単価
             ,sel.column_no                          -- コラム
             ,sel.hot_cold_class                     -- H/C区分
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date                 -- HHT納品入力日時
             ,sel.dlv_invoice_line_number            -- 納品明細番号
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- 2009/12/17 Ver.1.19 Add Start
             ,sel.sales_class
-- 2009/12/17 Ver.1.19 Add End
         ) infd     -- 明細情報
        ,(
            SELECT  look_val.meaning      meaning 
            FROM    fnd_lookup_values     look_val
            WHERE   look_val.lookup_type       = ct_qck_org_cls_type      -- XXCOS1_MK_ORG_CLS_MST_002_A05
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  orct    -- 作成元区分
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_input_class       -- XXCOS1_INPUT_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  incl    -- 入力区分
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_card_sale_class   -- XXCOS1_CARD_SALE_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  cscl    -- カード売区分
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_sale_class        -- XXCOS1_SALE_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  sacl    -- 売上区分
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
                   ,look_val.attribute3         attribute3
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_tax_class         -- XXCOS1_CONSUMPTION_TAX_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  htcl    -- HHT消費税区分
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_hc_class          -- XXCOS1_HC_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  hccl    -- H/C区分
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
                   ,look_val.attribute3         attribute3
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_tax_class         -- XXCOS1_CONSUMPTION_TAX_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  tacl    -- 消費税区分
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
                   ,look_val.enabled_flag       enabled_flag
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst    -- XXCOS1_GYOTAI_SHO_MST_002_A03
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  gysm    -- 業態小分類特定マスタ
        ,(
            SELECT  look_val.meaning            meaning
                   ,look_val.attribute1         vd_gyotai
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1   -- XXCOS1_GYOTAI_SHO_MST_002_A05
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  gysm1   -- 業態小分類特定マスタ
      WHERE
          infh.delivery_date                            = disc.delivery_date                             -- [ヘッダ=値引] 対象日付
      AND infh.sales_base_code                          = disc.sales_base_code                           --               拠点コード
      AND infh.dlv_by_code                              = disc.dlv_by_code                               --               納品者コード
      AND infh.dlv_invoice_number                       = disc.dlv_invoice_number                        --               伝票番号
      AND infh.dlv_date                                 = disc.dlv_date                                  --               納品日
      AND infh.inspect_date                             = disc.inspect_date                              --               検収日
      AND infh.ship_to_customer_code                    = disc.ship_to_customer_code                     --               顧客コード
      AND infh.input_class                              = disc.input_class                               --               入力区分
      AND infh.results_employee_code                    = disc.results_employee_code                     --               成績計上者コード
      AND NVL( infh.card_sale_class            , cv_x ) = NVL( disc.card_sale_class            , cv_x )  --               カード売り区分
      AND NVL( infh.invoice_classification_code, cv_x ) = NVL( disc.invoice_classification_code, cv_x )  --               伝票分類コード
      AND infh.consumption_tax_class                    = disc.consumption_tax_class                     --               消費税区分
      AND NVL( infh.invoice_class              , cv_x ) = NVL( disc.invoice_class              , cv_x )  --               伝票区分
      AND infh.create_class                             = disc.create_class                              --               作成元区分
      AND infh.delivery_date                            = infd.delivery_date                             -- [ヘッダ=明細] 対象日付
      AND infh.sales_base_code                          = infd.sales_base_code                           --               拠点コード
      AND infh.dlv_by_code                              = infd.dlv_by_code                               --               納品者コード
      AND infh.dlv_invoice_number                       = infd.dlv_invoice_number                        --               伝票番号
      AND infh.dlv_date                                 = infd.dlv_date                                  --               納品日
      AND infh.inspect_date                             = infd.inspect_date                              --               検収日
      AND infh.ship_to_customer_code                    = infd.ship_to_customer_code                     --               顧客コード
      AND infh.input_class                              = infd.input_class                               --               入力区分
      AND infh.results_employee_code                    = infd.results_employee_code                     --               成績計上者コード
      AND NVL( infh.card_sale_class            , cv_x ) = NVL( infd.card_sale_class            , cv_x )  --               カード売り区分
      AND NVL( infh.invoice_classification_code, cv_x ) = NVL( infd.invoice_classification_code, cv_x )  --               伝票分類コード
      AND infh.consumption_tax_class                    = infd.consumption_tax_class                     --               消費税区分
      AND NVL( infh.invoice_class              , cv_x ) = NVL( infd.invoice_class              , cv_x )  --               伝票区分
      AND infh.create_class                             = infd.create_class                              --               作成元区分
      AND base.customer_class_code   = ct_cust_class_base                                                -- 顧客区分＝拠点
      AND infh.sales_base_code       = base.account_number                                               -- 販売実績ヘッダ＝顧客マスタ_拠点
      AND base.party_id              = parb.party_id                                                     -- 顧客マスタ_拠点＝パーティ_拠点
      AND cust.customer_class_code   IN ( ct_cust_class_customer , ct_cust_class_customer_u )            -- 顧客区分IN 顧客,上様顧客
      AND infh.ship_to_customer_code = cust.account_number                                               -- 販売実績ヘッダ＝顧客マスタ_顧客
      AND cust.cust_account_id       = cuac.customer_id                                                  -- 顧客マスタ_顧客＝顧客追加情報
      AND cust.party_id              = parc.party_id                                                     -- 顧客マスタ_顧客＝パーティ_顧客
      AND infh.create_class IN ( orct.meaning )                                                          -- 作成元区分＝クイックコード
      AND infh.results_employee_code = ppf.employee_number(+)
-- 2009/12/17 Ver.1.19 Add Start
      AND infh.hht_dlv_input_date    = disc.hht_dlv_input_date                                           -- ヘッダ.HHT納品入力日時 = 値引.HHT納品入力日時
      AND infh.hht_dlv_input_date    = infd.hht_dlv_input_date                                           -- ヘッダ.HHT納品入力日時 = 明細.HHT納品入力日時
-- 2009/12/17 Ver.1.19 Add End
-- 2009/08/24 Ver.1.14 M.Sano Mod Start
      AND infh.delivery_date        >= ppf.effective_start_date(+)
      AND infh.delivery_date        <= ppf.effective_end_date(+)
-- 2009/08/24 Ver.1.14 M.Sano Mod End
      AND infd.item_code             = iimb.item_no
      AND iimb.item_id               = ximb.item_id
      AND ximb.obsolete_class       <> cv_obsolete_class_one
      AND ximb.start_date_active    <= infh.delivery_date
      AND ximb.end_date_active      >= infh.delivery_date
      AND infh.sales_base_code       = riv.base_code
      AND riv.employee_number        = infh.dlv_by_code
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--      AND riv.employee_number        = NVL( icp_dlv_by_code, riv.employee_number )
      AND (   (    icp_dlv_by_code     IS NOT NULL
               AND riv.employee_number = icp_dlv_by_code )
           OR (    icp_dlv_by_code     IS NULL )
          )
-- 2009/09/01 Ver.1.15 M.Sano Mod End
      AND infh.delivery_date        >= NVL( riv.effective_start_date, infh.delivery_date )
      AND infh.delivery_date        <= NVL( riv.effective_end_date, infh.delivery_date )
      AND infh.delivery_date        >= riv.per_effective_start_date
      AND infh.delivery_date        <= riv.per_effective_end_date
      AND infh.delivery_date        >= riv.paa_effective_start_date
      AND infh.delivery_date        <= riv.paa_effective_end_date
      AND infh.dlv_invoice_number    = NVL( icp_hht_invoice_no, infh.dlv_invoice_number )
      AND incl.lookup_code           = infh.input_class
      AND cscl.lookup_code(+)        = NVL( infh.card_sale_class, cv_x )
      AND sacl.lookup_code           = infd.sale_class
      AND htcl.attribute3            = infh.consumption_tax_class
      AND hccl.lookup_code(+)        = NVL( infd.h_and_c, cv_x )
      AND tacl.attribute3            = cuac.tax_div
      AND cuac.business_low_type     = gysm.meaning(+)                                                   -- 業態小分類
      AND cuac.business_low_type     = gysm1.meaning(+)
-- **************** 2010/01/07 1.20 N.Maeda MOL START **************** --
--      AND infd.quantity             != cn_zero                                                           -- 納品数量 != 0
      AND ( (infd.quantity            = cn_zero
               AND infd.line_sale_amount   != cn_zero          -- 明細売上額合計 != 0 
               AND EXISTS (  SELECT  cv_yes
                             FROM    fnd_lookup_values     look_val
                             WHERE   look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
                             AND     look_val.enabled_flag      = cv_yes                     -- Y
                             AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
                             AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
                             AND     look_val.language          = ct_lang
                             AND     look_val.lookup_code       = infd.item_code )
            )
        OR  ( infd.quantity         != cn_zero )
          )
-- **************** 2010/01/07 1.20 N.Maeda MOL  END  **************** --
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
-- 2009/12/17 Ver.1.19 Del Start
--      AND disc.dlv_invoice_line_number = infd.dlv_invoice_line_number                -- 納品明細番号
-- 2009/12/17 Ver.1.19 Del End
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
      ;
-- ******************** 2009/06/02 Var.1.9 T.Tominaga MOD END    ******************************************
--
--
    -- *** ローカル・レコード ***
    -- 販売実績データ抽出 テーブル型
    TYPE l_get_sale_data_tab      IS TABLE OF get_sale_data_cur%ROWTYPE
      INDEX BY PLS_INTEGER;
    -- 伝票番号格納用 テーブル型
    TYPE l_invoice_num_tab        IS TABLE OF NUMBER
      INDEX BY xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
--
    -- 販売実績データ抽出
    lt_get_sale_data              l_get_sale_data_tab;            -- 販売実績データ抽出
    -- 伝票番号格納用
    lt_invoice_num                l_invoice_num_tab;              -- 伝票番号格納用
    -- 配列番号
    ln_num                        NUMBER DEFAULT 0;               -- 伝票番号格納用
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
    --==========================================================
    --販売実績データ抽出(A-3)
    --==========================================================
    BEGIN
      ld_delivery_date  :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
--
      -- チェックマーク取得
      lv_check_mark := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_mark );
--
      -- カーソルOPEN
      OPEN  get_sale_data_cur(
                                ld_delivery_date        -- 納品日
                               ,iv_delivery_base_code   -- 拠点
                               ,iv_dlv_by_code          -- 営業員
                               ,iv_hht_invoice_no       -- HHT伝票No
                             );
      -- バルクフェッチ
      FETCH get_sale_data_cur BULK COLLECT INTO lt_get_sale_data;
      -- 対象件数取得
      ln_target_cnt := get_sale_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_sale_data_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE
        IF ( get_sale_data_cur%ISOPEN ) THEN
          CLOSE get_sale_data_cur;
        END IF;
--
        -- キー情報編集
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_date );
        gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_base );
        gv_tkn3   := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_by_code );
        gv_tkn4   := xxccp_common_pkg.get_msg( cv_application, cv_msg_hht_invoice_no );
        xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      => lv_errbuf           -- エラー・メッセージ
                                        ,ov_retcode     => lv_retcode          -- リターン・コード
                                        ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
                                        ,ov_key_info    => gv_key_info         -- キー情報
                                        ,iv_item_name1  => gv_tkn1             -- 納品日
                                        ,iv_data_value1 => iv_delivery_date
                                        ,iv_item_name2  => gv_tkn2             -- 拠点
                                        ,iv_data_value2 => iv_delivery_base_code
                                        ,iv_item_name3  => gv_tkn3             -- 営業員
                                        ,iv_data_value3 => iv_dlv_by_code
                                        ,iv_item_name4  => gv_tkn4             -- HHT伝票No
                                        ,iv_data_value4 => iv_hht_invoice_no
                                        );
--
        -- データ抽出エラーメッセージ
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale_header_table );
        lv_errmsg := xxccp_common_pkg.get_msg(
                                               cv_application
                                              ,cv_msg_get_err
                                              ,cv_tkn_table
                                              ,gv_tkn1
                                              ,cv_tkn_key_data
                                              ,NULL
                                             );
        lv_errbuf  := lv_errmsg;
--
        RAISE global_api_expt;
    END;
--
    -- 対象件数セット
    gn_target_cnt := ln_target_cnt;
--
    --==========================================================
    --納品データ登録（販売実績）(A-4)
    --==========================================================
    --  対象件数が0件の場合登録処理をスキップ
    IF ( ln_target_cnt != 0 ) THEN
--
      FOR in_no IN 1..ln_target_cnt LOOP
--
        -- 配列番号取得
        ln_num := ln_num + 1;
--
        --  レコードID取得
        SELECT
          xxcos_rep_dlv_chk_list_s01.nextval
        INTO
          gt_dlv_chk_list(ln_num).record_id
        FROM
          DUAL;
--
        -- データ取得
        lt_enabled_flag        := lt_get_sale_data(in_no).enabled_flag;          -- 業態小分類使用可
        lt_standard_unit_price := lt_get_sale_data(in_no).standard_unit_price;   -- 基準単価--卸単価
        lt_business_cost       := lt_get_sale_data(in_no).business_cost;         -- 営業原価
        lt_st_date             := lt_get_sale_data(in_no).st_date;               -- 定価適用開始
        lt_plice_new           := lt_get_sale_data(in_no).plice_new;             -- 定価(新)
        lt_plice_old           := lt_get_sale_data(in_no).plice_old;             -- 旧定価
        lt_plice_new_no_tax    := lt_get_sale_data(in_no).plice_new;             -- 定価(新)
        lt_plice_old_no_tax    := lt_get_sale_data(in_no).plice_old;             -- 旧定価
        lt_tax_rate            := lt_get_sale_data(in_no).tax_rate;              --税率
--
        -- 判定
        IF ( lt_enabled_flag = cv_yes ) THEN
-- ******************** 2009/07/13 Var.1.13 T.Tominaga DEL START  *****************************************
--          lt_confirmation := NULL;
----
--        ELSE
-- ******************** 2009/07/13 Var.1.13 T.Tominaga DEL START  *****************************************
          --営業原価の税処理
          lt_tax_amount          := lt_business_cost * lt_tax_rate / 100;
          -- 端数処理
          IF ( lt_get_sale_data(in_no).tax_rounding_rule    = cv_round_rule_up ) THEN
            -- 切り上げの場合
            IF ( lt_tax_amount - TRUNC( lt_tax_amount ) <> 0 ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount ) + 1;
            END IF;
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_down ) THEN
            -- 切り下げの場合
            lt_tax_amount := TRUNC( lt_tax_amount );
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_nearest ) THEN
            -- 四捨五入の場合
            lt_tax_amount := ROUND( lt_tax_amount );
          END IF;
          IF ( lt_get_sale_data(in_no).consumption_tax_class IS NULL
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD START  *****************************************
--             OR ( lt_get_sale_data(in_no).consumption_tax_class <> cn_two 
--             AND lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) ) THEN
            OR lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) THEN
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD END    *****************************************
            lt_tax_amount := 0;
          END IF;
          lt_business_cost  := lt_business_cost + lt_tax_amount;
--
          --定価（新）の税処理
          lt_tax_amount          := lt_plice_new * lt_tax_rate / 100;
          -- 端数処理
          IF ( lt_get_sale_data(in_no).tax_rounding_rule    = cv_round_rule_up ) THEN
            -- 切り上げの場合
            IF ( lt_tax_amount - TRUNC( lt_tax_amount ) <> 0 ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount ) + 1;
            END IF;
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_down ) THEN
            -- 切り下げの場合
            lt_tax_amount := TRUNC( lt_tax_amount );
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_nearest ) THEN
            -- 四捨五入の場合
            lt_tax_amount := ROUND( lt_tax_amount );
          END IF;
          IF ( lt_get_sale_data(in_no).consumption_tax_class IS NULL
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD START  *****************************************
--             OR ( lt_get_sale_data(in_no).consumption_tax_class <> cn_two 
--             AND lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) ) THEN
            OR lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) THEN
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD END    *****************************************
              lt_tax_amount := 0;
          END IF;
          lt_plice_new  := lt_plice_new + lt_tax_amount;
--
          --定価（旧）の税処理
          lt_tax_amount          := lt_plice_old * lt_tax_rate / 100;
          -- 端数処理
          IF ( lt_get_sale_data(in_no).tax_rounding_rule    = cv_round_rule_up ) THEN
            -- 切り上げの場合
            IF ( lt_tax_amount - TRUNC( lt_tax_amount ) <> 0 ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount ) + 1;
            END IF;
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_down ) THEN
            -- 切り下げの場合
            lt_tax_amount := TRUNC( lt_tax_amount );
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_nearest ) THEN
            -- 四捨五入の場合
            lt_tax_amount := ROUND( lt_tax_amount );
          END IF;
          IF ( lt_get_sale_data(in_no).consumption_tax_class IS NULL
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD START  *****************************************
--             OR ( lt_get_sale_data(in_no).consumption_tax_class <> cn_two 
--             AND lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) ) THEN
            OR lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) THEN
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD END    *****************************************
              lt_tax_amount := 0;
          END IF;
          lt_plice_old  := lt_plice_old + lt_tax_amount;
--
-- ******************** 2009/07/13 Var.1.13 T.Tominaga MOD START  *****************************************
--          IF ( lt_standard_unit_price < lt_business_cost ) THEN    -- 基準単価 < 営業原価
--            lt_confirmation := lv_check_mark;
----
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
----          ELSIF ( lt_st_date >= iv_delivery_date ) THEN            -- 定価適用開始 >= 納品日
--          ELSIF ( lt_st_date <= iv_delivery_date ) THEN            -- 定価適用開始 <= 納品日
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
--            IF ( lt_plice_new < lt_standard_unit_price ) THEN      -- 定価(新) < 基準単価
--              lt_confirmation := lv_check_mark;
--            ELSE
--              lt_confirmation := NULL;
--            END IF;
----
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
----          ELSIF ( lt_st_date < iv_delivery_date ) THEN             -- 定価適用開始 < 納品日
--          ELSIF ( lt_st_date > iv_delivery_date ) THEN             -- 定価適用開始 > 納品日
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
--            IF ( lt_plice_old < lt_standard_unit_price ) THEN      -- 旧定価 < 基準単価
--              lt_confirmation := lv_check_mark;
--            ELSE
--              lt_confirmation := NULL;
--            END IF;
----
--          ELSE
--            lt_confirmation := NULL;
--          END IF;
--
        ELSE
          NULL;
-- ******************** 2009/07/13 Var.1.13 T.Tominaga MOD END    *****************************************
        END IF;
--
-- ******************** 2009/07/13 Var.1.13 T.Tominaga ADD START  *****************************************
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
        IF ( gt_disc_item_tab.EXISTS(lt_get_sale_data(in_no).item_code) ) THEN
        -- 対象データが値引き品目の場合
          lt_confirmation := NULL;
        ELSE
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
          -- 確認項目の編集
          IF ( lt_standard_unit_price < lt_business_cost ) THEN    -- 基準単価 < 営業原価
            lt_confirmation := lv_check_mark;
--
          ELSIF ( lt_st_date <= iv_delivery_date ) THEN            -- 定価適用開始 <= 納品日
            IF ( lt_plice_new < lt_standard_unit_price ) THEN      -- 定価(新) < 基準単価
              lt_confirmation := lv_check_mark;
            ELSE
              lt_confirmation := NULL;
            END IF;
--
          ELSIF ( lt_st_date > iv_delivery_date ) THEN             -- 定価適用開始 > 納品日
            IF ( lt_plice_old < lt_standard_unit_price ) THEN      -- 旧定価 < 基準単価
              lt_confirmation := lv_check_mark;
            ELSE
              lt_confirmation := NULL;
            END IF;
--
          ELSE
            lt_confirmation := NULL;
          END IF;
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
        END IF;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
-- ******************** 2009/07/13 Var.1.13 T.Tominaga ADD END    *****************************************
--
        -- 売値判定
        IF ( lt_st_date <= iv_delivery_date ) THEN
          lt_set_plice := lt_plice_new_no_tax;
        ELSE
          lt_set_plice := lt_plice_old_no_tax;
        END IF;
--
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
        IF ( gt_disc_item_tab.EXISTS(lt_get_sale_data(in_no).item_code) ) THEN
        -- 対象データが値引き品目の場合
          -- 数量
          gt_dlv_chk_list(ln_num).quantity                     := NULL;
          -- 売価
          gt_dlv_chk_list(ln_num).ploce                        := NULL;
          -- カード金額
          gt_dlv_chk_list(ln_num).card_amount                  := NULL;
        ELSE
          -- 数量
          gt_dlv_chk_list(ln_num).quantity                     := lt_get_sale_data(in_no).quantity;
          -- 売価
          gt_dlv_chk_list(ln_num).ploce                        := lt_set_plice;
          -- カード金額
          gt_dlv_chk_list(ln_num).card_amount                  := lt_get_sale_data(in_no).card_amount;
        END IF;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
        -- 対象日付
        gt_dlv_chk_list(ln_num).target_date                  := lt_get_sale_data(in_no).target_date;
        -- 拠点コード
        gt_dlv_chk_list(ln_num).base_code                    := lt_get_sale_data(in_no).base_code;
        -- 拠点名称
        gt_dlv_chk_list(ln_num).base_name                    := lt_get_sale_data(in_no).base_name;
        -- 営業員コード
        gt_dlv_chk_list(ln_num).employee_num                 := lt_get_sale_data(in_no).employee_num;
        -- 営業員氏名
        gt_dlv_chk_list(ln_num).employee_name                := lt_get_sale_data(in_no).employee_name;
        -- グループ番号
        gt_dlv_chk_list(ln_num).group_code                   := lt_get_sale_data(in_no).group_code;
        -- グループ内順序
        gt_dlv_chk_list(ln_num).group_in_sequence            := lt_get_sale_data(in_no).group_in_sequence;
        -- 伝票番号
        gt_dlv_chk_list(ln_num).entry_number                 := lt_get_sale_data(in_no).invoice_no;
        -- 納品日
        gt_dlv_chk_list(ln_num).dlv_date                     := lt_get_sale_data(in_no).dlv_date;
        -- 顧客コード
        gt_dlv_chk_list(ln_num).party_num                    := lt_get_sale_data(in_no).party_num;
        -- 顧客名
        gt_dlv_chk_list(ln_num).customer_name                := lt_get_sale_data(in_no).customer_name;
        -- 入力区分
        gt_dlv_chk_list(ln_num).input_class                  := lt_get_sale_data(in_no).input_class;
        -- 成績者コード
        gt_dlv_chk_list(ln_num).performance_by_code          := lt_get_sale_data(in_no).performance_by_code;
        -- 成績者名
        gt_dlv_chk_list(ln_num).performance_by_name          := lt_get_sale_data(in_no).performance_by_name;
        -- カード売り区分
        gt_dlv_chk_list(ln_num).card_sale_class              := lt_get_sale_data(in_no).card_sale_class;
        -- 売上額
        gt_dlv_chk_list(ln_num).sudstance_total_amount       := lt_get_sale_data(in_no).sudstance_total_amount;
        -- 売上値引額
        gt_dlv_chk_list(ln_num).sale_discount_amount         := lt_get_sale_data(in_no).sale_discount_amount;
        -- 消費税金額合計
        gt_dlv_chk_list(ln_num).consumption_tax_total_amount := lt_get_sale_data(in_no).consumption_tax_total_amount;
        -- 消費税区分（マスタ)
        gt_dlv_chk_list(ln_num).consumption_tax_class_mst    := lt_get_sale_data(in_no).consumption_tax_class_mst;
        -- 伝票分類コード
        gt_dlv_chk_list(ln_num).invoice_classification_code  := lt_get_sale_data(in_no).invoice_classification_code;
        -- 伝票区分
        gt_dlv_chk_list(ln_num).invoice_class                := lt_get_sale_data(in_no).invoice_class;
        -- 売上区分
        gt_dlv_chk_list(ln_num).sale_class                   := lt_get_sale_data(in_no).sale_class;
        -- 品目コード
        gt_dlv_chk_list(ln_num).item_code                    := lt_get_sale_data(in_no).item_code;
        -- 商品名
        gt_dlv_chk_list(ln_num).item_name                    := lt_get_sale_data(in_no).item_name;
-- ******* 2010/01/07 1.20 N.Maeda DEL START ****** --
--        -- 数量
--        gt_dlv_chk_list(ln_num).quantity                     := lt_get_sale_data(in_no).quantity;
-- ******* 2010/01/07 1.20 N.Maeda DEL  END  ****** --
        -- 卸単価
        gt_dlv_chk_list(ln_num).wholesale_unit_ploce         := lt_get_sale_data(in_no).wholesale_unit_ploce;
-- **
        -- 確認
        gt_dlv_chk_list(ln_num).confirmation                 := lt_confirmation;
        -- 消費税区分（入力)
        gt_dlv_chk_list(ln_num).consum_tax_calss_entered     := lt_get_sale_data(in_no).consum_tax_calss_entered;
-- ******* 2010/01/07 1.20 N.Maeda DEL START ****** --
--        -- 売価
--        gt_dlv_chk_list(ln_num).ploce                        := lt_set_plice;
----        gt_dlv_chk_list(ln_num).ploce                        := lt_get_sale_data(in_no).ploce;
--        -- カード金額
--        gt_dlv_chk_list(ln_num).card_amount                  := lt_get_sale_data(in_no).card_amount;
-- ******* 2010/01/07 1.20 N.Maeda DEL  END  ****** --
        -- コラム
        gt_dlv_chk_list(ln_num).column_no                    := lt_get_sale_data(in_no).column_no;
        -- HC
        gt_dlv_chk_list(ln_num).h_and_c                      := lt_get_sale_data(in_no).h_and_c;
        -- 入金区分
        gt_dlv_chk_list(ln_num).payment_class                := lt_get_sale_data(in_no).payment_class;
        -- 入金額
        gt_dlv_chk_list(ln_num).payment_amount               := lt_get_sale_data(in_no).payment_amount;
        -- 作成者
        gt_dlv_chk_list(ln_num).created_by                   := cn_created_by;
        -- 作成日
        gt_dlv_chk_list(ln_num).creation_date                := cd_creation_date;
        -- 最終更新者
        gt_dlv_chk_list(ln_num).last_updated_by              := cn_last_updated_by;
        -- 最終更新日
        gt_dlv_chk_list(ln_num).last_update_date             := cd_last_update_date;
        -- 最終更新ログイン
        gt_dlv_chk_list(ln_num).last_update_login            := cn_last_update_login;
        -- 要求ＩＤ
        gt_dlv_chk_list(ln_num).request_id                   := cn_request_id;
        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        gt_dlv_chk_list(ln_num).program_application_id       := cn_program_application_id;
        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        gt_dlv_chk_list(ln_num).program_id                   := cn_program_id;
        -- ﾌﾟﾛｸﾞﾗﾑ更新日
        gt_dlv_chk_list(ln_num).program_update_date          := cd_program_update_date;
--
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
        -- 訪問時間
        gt_dlv_chk_list(ln_num).visit_time                := TO_CHAR(lt_get_sale_data(in_no).hht_dlv_input_date,cv_fmt_time_default);
        -- 明細番号
        gt_dlv_chk_list(ln_num).dlv_invoice_line_number   := lt_get_sale_data(in_no).dlv_invoice_line_number;
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
        gt_dlv_chk_list(ln_num).order_number              := lt_get_sale_data(in_no).order_number;
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
/*        IF ( lt_get_sale_data(in_no).payment_amount IS NOT NULL
          AND
             lt_invoice_num.EXISTS( lt_get_sale_data(in_no).invoice_no ) = FALSE ) THEN
--
          -- 配列番号取得
          ln_num := ln_num + 1;
--
          --  レコードID取得
          SELECT
            xxcos_rep_dlv_chk_list_s01.nextval
          INTO
            gt_dlv_chk_list(ln_num).record_id
          FROM
            DUAL;
--
          -- 対象日付
          gt_dlv_chk_list(ln_num).target_date                  := lt_get_sale_data(in_no).target_date;
          -- 拠点コード
          gt_dlv_chk_list(ln_num).base_code                    := lt_get_sale_data(in_no).base_code;
          -- 拠点名称
          gt_dlv_chk_list(ln_num).base_name                    := lt_get_sale_data(in_no).base_name;
          -- 営業員コード
          gt_dlv_chk_list(ln_num).employee_num                 := lt_get_sale_data(in_no).employee_num;
          -- 営業員氏名
          gt_dlv_chk_list(ln_num).employee_name                := lt_get_sale_data(in_no).employee_name;
          -- グループ番号
          gt_dlv_chk_list(ln_num).group_code                   := lt_get_sale_data(in_no).group_code;
          -- グループ内順序
          gt_dlv_chk_list(ln_num).group_in_sequence            := lt_get_sale_data(in_no).group_in_sequence;
          -- 伝票番号
          gt_dlv_chk_list(ln_num).entry_number                 := lt_get_sale_data(in_no).invoice_no;
          -- 納品日
          gt_dlv_chk_list(ln_num).dlv_date                     := lt_get_sale_data(in_no).dlv_date;
          -- 顧客コード
          gt_dlv_chk_list(ln_num).party_num                    := lt_get_sale_data(in_no).party_num;
          -- 顧客名
          gt_dlv_chk_list(ln_num).customer_name                := lt_get_sale_data(in_no).customer_name;
          -- 入力区分
          gt_dlv_chk_list(ln_num).input_class                  := lt_get_sale_data(in_no).input_class;
          -- 成績者コード
          gt_dlv_chk_list(ln_num).performance_by_code          := lt_get_sale_data(in_no).performance_by_code;
          -- 成績者名
          gt_dlv_chk_list(ln_num).performance_by_name          := lt_get_sale_data(in_no).performance_by_name;
          -- カード売り区分
          gt_dlv_chk_list(ln_num).card_sale_class              := lt_get_sale_data(in_no).card_sale_class;
          -- 売上額
          gt_dlv_chk_list(ln_num).sudstance_total_amount       := lt_get_sale_data(in_no).sudstance_total_amount;
          -- 売上値引額
          gt_dlv_chk_list(ln_num).sale_discount_amount         := lt_get_sale_data(in_no).sale_discount_amount;
          -- 消費税金額合計
          gt_dlv_chk_list(ln_num).consumption_tax_total_amount := lt_get_sale_data(in_no).consumption_tax_total_amount;
          -- 消費税区分（マスタ)
          gt_dlv_chk_list(ln_num).consumption_tax_class_mst    := lt_get_sale_data(in_no).consumption_tax_class_mst;
          -- 伝票分類コード
          gt_dlv_chk_list(ln_num).invoice_classification_code  := lt_get_sale_data(in_no).invoice_classification_code;
          -- 伝票区分
          gt_dlv_chk_list(ln_num).invoice_class                := lt_get_sale_data(in_no).invoice_class;
          -- 売上区分
          gt_dlv_chk_list(ln_num).sale_class                   := NULL;
          -- 品目コード
          gt_dlv_chk_list(ln_num).item_code                    := NULL;
          -- 商品名
          gt_dlv_chk_list(ln_num).item_name                    := NULL;
          -- 数量
          gt_dlv_chk_list(ln_num).quantity                     := 0;
          -- 卸単価
          gt_dlv_chk_list(ln_num).wholesale_unit_ploce         := 0;
          -- 確認
          gt_dlv_chk_list(ln_num).confirmation                 := NULL;
          -- 消費税区分（入力)
          gt_dlv_chk_list(ln_num).consum_tax_calss_entered     := lt_get_sale_data(in_no).consum_tax_calss_entered;
          -- 売価
          gt_dlv_chk_list(ln_num).ploce                        := 0;
          -- カード金額
          gt_dlv_chk_list(ln_num).card_amount                  := 0;
          -- コラム
          gt_dlv_chk_list(ln_num).column_no                    := NULL;
          -- HC
          gt_dlv_chk_list(ln_num).h_and_c                      := NULL;
          -- 入金区分
          gt_dlv_chk_list(ln_num).payment_class                := lt_get_sale_data(in_no).payment_class;
          -- 入金額
          gt_dlv_chk_list(ln_num).payment_amount               := lt_get_sale_data(in_no).payment_amount;
          -- 作成者
          gt_dlv_chk_list(ln_num).created_by                   := cn_created_by;
          -- 作成日
          gt_dlv_chk_list(ln_num).creation_date                := cd_creation_date;
          -- 最終更新者
          gt_dlv_chk_list(ln_num).last_updated_by              := cn_last_updated_by;
          -- 最終更新日
          gt_dlv_chk_list(ln_num).last_update_date             := cd_last_update_date;
          -- 最終更新ログイン
          gt_dlv_chk_list(ln_num).last_update_login            := cn_last_update_login;
          -- 要求ＩＤ
          gt_dlv_chk_list(ln_num).request_id                   := cn_request_id;
          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          gt_dlv_chk_list(ln_num).program_application_id       := cn_program_application_id;
          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          gt_dlv_chk_list(ln_num).program_id                   := cn_program_id;
          -- ﾌﾟﾛｸﾞﾗﾑ更新日
          gt_dlv_chk_list(ln_num).program_update_date          := cd_program_update_date;
--
          -- 伝票番号格納
          lt_invoice_num( lt_get_sale_data(in_no).invoice_no ) := in_no;
--
        END IF;*/
--
      END LOOP;
--
      -- 対象件数セット
      gn_target_cnt := ln_target_cnt + lt_invoice_num.COUNT;
--
      -- 納品書チェックリストワークテーブルへ登録
      BEGIN
        FORALL into_no IN INDICES OF gt_dlv_chk_list SAVE EXCEPTIONS
          INSERT INTO
            xxcos_rep_dlv_chk_list
          VALUES
            gt_dlv_chk_list(into_no);
--
      EXCEPTION
        WHEN OTHERS THEN
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
          gv_tkn2   := NULL;
          lv_errmsg := xxccp_common_pkg.get_msg(
                                                 cv_application
                                                ,cv_msg_insert_data_err
                                                ,cv_tkn_table
                                                ,gv_tkn1
                                                ,cv_tkn_key_data
                                                ,gv_tkn2
                                               );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
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
  END sales_per_data_entry;
--
  /**********************************************************************************
   * Procedure Name   : money_data_entry
   * Description      : 入金データ抽出(A-5)、納品データ登録（入金データ）(A-6)
   ***********************************************************************************/
  PROCEDURE money_data_entry(
    iv_delivery_date      IN      VARCHAR2,         -- 納品日
    iv_delivery_base_code IN      VARCHAR2,         -- 拠点
    iv_dlv_by_code        IN      VARCHAR2,         -- 営業員
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT伝票No
    ov_errbuf             OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'money_data_entry'; -- プログラム名
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
    ld_delivery_date  DATE;       -- パラメータ変換後の納品日
-- 2009/12/17 Ver.1.19 Add Start
    ln_payment_cnt         NUMBER;    -- 取得入金件数
    ln_no_dlv_data         NUMBER;    -- 納品データ有無フラグ
-- 2009/12/17 Ver.1.19 Add End
--
    -- *** ローカル・カーソル ***
-- 2009/12/17 Ver.1.19 Add Start
    -- 入金データ抽出
    CURSOR get_payment_cur (
      id_delivery_date  IN  DATE        -- 納品日
    )
    IS
      SELECT  xrdcl.rowid         row_id
             ,xrdcl.employee_num  employee_num                        -- 営業員コード
             ,xrdcl.dlv_date      dlv_date                            -- 納品日
             ,xrdcl.party_num     party_num                           -- 顧客コード
             ,xrdcl.entry_number  entry_number                        -- 伝票番号
             ,xrdcl.base_code     base_code                           -- 拠点コード
             ,xrdcl.target_date   target_date                         -- 対象日時
             ,NULL                dlv_card_sale_class                 -- カード売り区分
             ,NULL                dlv_input_class                     -- 入力区分
             ,NULL                dlv_invoice_class                   -- 伝票区分
             ,NULL                dlv_invoice_class_code              -- 伝票区分コード
             ,NULL                dlv_visit_time                      -- 訪問日時
             ,NULL                dlv_dlv_date                        -- 納品日
      FROM    xxcos_rep_dlv_chk_list    xrdcl           -- 納品書チェックリスト帳票ワークテーブル
             ,fnd_lookup_values         flv             -- ルックアップ
      WHERE  xrdcl.request_id      = cn_request_id
      AND    xrdcl.payment_class   = flv.meaning
      AND    flv.lookup_type       = ct_qck_money_class
      AND    flv.enabled_flag      = cv_yes
      AND    flv.language          = ct_lang
      AND    id_delivery_date      >= NVL( flv.start_date_active, id_delivery_date )
      AND    id_delivery_date      <= NVL( flv.end_date_active, id_delivery_date )
      ;
      --
-- 2009/12/17 Ver.1.19 Add Start
--
    -- *** ローカル・レコード ***
-- 2009/12/17 Ver.1.19 Add Start
    TYPE g_payment_data_ttype IS TABLE OF get_payment_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_payment_tbl            g_payment_data_ttype;
-- 2009/12/17 Ver.1.19 Add End
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
    --========================================================
    --入金データ抽出(A-5)、納品データ登録（入金データ）(A-6)
    --========================================================
    ld_delivery_date  :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
--
    BEGIN
      INSERT INTO
        xxcos_rep_dlv_chk_list
          (
              record_id                           -- レコードID
             ,target_date                         -- 対象日付
             ,base_code                           -- 拠点コード
             ,base_name                           -- 拠点名称
             ,employee_num                        -- 営業員コード
             ,employee_name                       -- 営業員氏名
             ,group_code                          -- グループ番号
             ,group_in_sequence                   -- グループ内順序
             ,entry_number                        -- 伝票番号
             ,dlv_date                            -- 納品日
             ,party_num                           -- 顧客コード
             ,customer_name                       -- 顧客名
             ,input_class                         -- 入力区分
             ,performance_by_code                 -- 成績者コード
             ,performance_by_name                 -- 成績者名
             ,card_sale_class                     -- カード売り区分
             ,sudstance_total_amount              -- 売上額
             ,sale_discount_amount                -- 売上値引額
             ,consumption_tax_total_amount        -- 消費税金額合計
             ,consumption_tax_class_mst           -- 消費税区分（マスタ）
             ,invoice_classification_code         -- 伝票分類コード
             ,invoice_class                       -- 伝票区分
             ,sale_class                          -- 売上区分
             ,item_code                           -- 品目コード
             ,item_name                           -- 商品名
             ,quantity                            -- 数量
             ,wholesale_unit_ploce                -- 卸単価
             ,confirmation                        -- 確認
             ,consum_tax_calss_entered            -- 消費税区分（入力）
             ,ploce                               -- 売価
             ,card_amount                         -- カード金額
             ,column_no                           -- コラム
             ,h_and_c                             -- H/C
             ,payment_class                       -- 入金区分
             ,payment_amount                      -- 入金額
             ,created_by                          -- 作成者
             ,creation_date                       -- 作成日
             ,last_updated_by                     -- 最終更新者
             ,last_update_date                    -- 最終更新日
             ,last_update_login                   -- 最終更新ログイン
             ,request_id                          -- 要求ＩＤ
             ,program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
             ,program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
             ,program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
          )
        SELECT
-- 2009/09/01 Ver.1.15 M.Sano Add Start
           /*+
             leading ( riv.jrrx_n )
             index   ( riv.jrgm_n jtf_rs_group_members_n2)
             index   ( riv.jrgb_n jtf_rs_groups_b_u1 )
             index   ( riv.jrrx_n xxcso_jrre_n02 )
             use_nl  ( riv.papf_n )
             use_nl  ( riv.pept_n )
             use_nl  ( riv.paaf_n )
             use_nl  ( riv.jrgm_n )
             use_nl  ( riv.jrgb_n )
             leading ( riv.jrrx_o )
             index   ( riv.jrrx_o xxcso_jrre_n02 )
             index   ( riv.jrgm_o jtf_rs_group_members_n2)
             index   ( riv.jrgb_o jtf_rs_groups_b_u1 )
             use_nl  ( riv.papf_o )
             use_nl  ( riv.pept_o )
             use_nl  ( riv.paaf_o )
             use_nl  ( riv.jrgm_o )
             use_nl  ( riv.jrgb_o )
           */
-- 2009/09/01 Ver.1.15 M.Sano Add End
           xxcos_rep_dlv_chk_list_s01.nextval   -- レコードID
          ,pay.payment_date                       -- 対象日付
          ,pay.base_code                          -- 拠点コード
          ,SUBSTRB( parb.party_name, 1, 40 )      -- 拠点名称
          ,riv.employee_number                    -- 営業員コード
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD START ************************ --
--          ,riv.employee_name                      -- 営業員氏名
          ,SUBSTRB( riv.employee_name, 1, 40 )    -- 営業員氏名
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD  END  ************************ --
          ,riv.group_code                         -- グループ番号
          ,riv.group_in_sequence                  -- グループ内順序
          ,pay.hht_invoice_no                     -- 伝票番号
          ,pay.payment_date                       -- 納品日
          ,pay.customer_number                    -- 顧客コード
          ,SUBSTRB( parc.party_name, 1, 40 )      -- 顧客名
          ,NULL                                   -- 入力区分
          ,NULL                                   -- 成績者コード
          ,NULL                                   -- 成績者名
          ,NULL                                   -- カード売り区分
          ,0                                      -- 売上額
          ,0                                      -- 売上値引額
          ,0                                      -- 消費税金額合計
          ,NULL                                   -- 消費税区分（マスタ）
          ,NULL                                   -- 伝票分類コード
          ,NULL                                   -- 伝票区分
          ,NULL                                   -- 売上区分
          ,NULL                                   -- 品目コード
          ,NULL                                   -- 商品名
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
--          ,0                                      -- 数量
          ,NULL                                      -- 数量
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
          ,0                                      -- 卸単価
          ,NULL                                   -- 確認
          ,NULL                                   -- 消費税区分（入力）
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
--          ,0                                      -- 売価
          ,NULL                                      -- 売価
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
--          ,0                                      -- カード金額----
          ,NULL                                      -- カード金額
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
          ,NULL                                   -- コラム
          ,NULL                                   -- H/C
          ,pacl.meaning                           -- 入金区分
          ,pay.payment_amount                     -- 入金額
          ,cn_created_by                          -- 作成者
          ,cd_creation_date                       -- 作成日
          ,cn_last_updated_by                     -- 最終更新者
          ,cd_last_update_date                    -- 最終更新日
          ,cn_last_update_login                   -- 最終更新ログイン
          ,cn_request_id                          -- 要求ＩＤ
          ,cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          ,cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          ,cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
        FROM
           xxcos_payment            pay           -- 入金テーブル
          ,hz_cust_accounts         base          -- 顧客マスタ_拠点
          ,hz_cust_accounts         cust          -- 顧客マスタ_顧客
          ,hz_parties               parb          -- パーティ_拠点
          ,hz_parties               parc          -- パーティ_顧客
          ,xxcos_rs_info_v          riv           -- 営業員情報view
          ,xxcos_salesreps_v        salv          -- 担当営業員view
          ,xxcmm_cust_accounts      cuac          -- 顧客追加情報
          ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_money_class      -- XXCOS1_RECEIPT_MONEY_CLASS
            WHERE   look_val.lookup_type       = ct_qck_money_class      -- XXCOS1_RECEIPT_MONEY_CLASS
-- 2009/09/01 Ver.1.15 M.Sano Mod End
            AND     look_val.enabled_flag      = cv_yes                  -- Y
            AND     ld_delivery_date          >= NVL( look_val.start_date_active, ld_delivery_date )
            AND     ld_delivery_date          <= NVL( look_val.end_date_active, ld_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           )  pacl   -- 入金区分
        WHERE
          pay.payment_date       = ld_delivery_date
        AND pay.base_code        = iv_delivery_base_code
        AND salv.account_number  = pay.customer_number
        AND pay.payment_date    >= NVL( salv.effective_start_date, pay.payment_date )
        AND pay.payment_date    <= NVL( salv.effective_end_date, pay.payment_date )
        AND riv.base_code        = pay.base_code
        AND riv.employee_number  = NVL( iv_dlv_by_code, salv.employee_number )
-- 2009/11/27 Ver.1.17 K.Atsushiba Add Start
        AND ( iv_dlv_by_code IS NULL OR iv_dlv_by_code  = salv.employee_number )
-- 2009/11/27 Ver.1.17 K.Atsushiba Add End
        AND pay.payment_date    >= NVL( riv.effective_start_date, pay.payment_date )
        AND pay.payment_date    <= NVL( riv.effective_end_date, pay.payment_date )
        AND pay.payment_date    >= riv.per_effective_start_date
        AND pay.payment_date    <= riv.per_effective_end_date
        AND pay.payment_date    >= riv.paa_effective_start_date
        AND pay.payment_date    <= riv.paa_effective_end_date
        AND pay.hht_invoice_no   = NVL( iv_hht_invoice_no, pay.hht_invoice_no )
        AND pay.payment_class    = pacl.lookup_code
--        AND NOT EXISTS
--          (
--            SELECT
--              ROWID
--            FROM
--              xxcos_sales_exp_headers  sale       -- 販売実績ヘッダテーブル
--            WHERE
--              sale.dlv_invoice_number      = pay.hht_invoice_no
--            AND sale.delivery_date         = pay.payment_date
--            AND sale.ship_to_customer_code = pay.customer_number
--            AND sale.sales_base_code       = pay.base_code
--            AND ROWNUM = 1
--          )
        AND pay.base_code            = base.account_number
        AND base.customer_class_code = ct_cust_class_base
        AND base.party_id            = parb.party_id
        AND pay.customer_number      = cust.account_number
-- ******************** 2009/05/01 Var.1.6 N.Maeda MOD START  ******************************************
--      AND cust.customer_class_code = ct_cust_class_customer
        AND cust.customer_class_code   IN ( ct_cust_class_customer , ct_cust_class_customer_u )
-- ******************** 2009/05/01 Var.1.6 N.Maeda MOD  END   ******************************************
        AND cust.party_id            = parc.party_id
        AND cust.cust_account_id     = cuac.customer_id                -- 顧客マスタ_顧客＝顧客追加情報
        AND NOT EXISTS
          (
             SELECT  look_val.attribute1         vd_gyotai
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1   -- XXCOS1_GYOTAI_SHO_MST_002_A05
             AND     look_val.enabled_flag      = cv_yes                  -- Y
             AND     ld_delivery_date          >= NVL( look_val.start_date_active, ld_delivery_date )
             AND     ld_delivery_date          <= NVL( look_val.end_date_active, ld_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--             AND     look_val.language          = USERENV( 'LANG' )
             AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
             AND     look_val.meaning           = cuac.business_low_type
          )  -- 業態小分類特定マスタ
        ;
--
      -- 対象件数取得
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
        gv_tkn2   := NULL;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                cv_application
                                               ,cv_msg_insert_data_err
                                               ,cv_tkn_table
                                               ,gv_tkn1
                                               ,cv_tkn_key_data
                                               ,gv_tkn2
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2009/12/17 Ver.1.19 Add Start
  -- 登録した入金データ抽出
  -- カーソル・オープン
  OPEN get_payment_cur (
           id_delivery_date  => ld_delivery_date             -- 納品日
       );
  --
  -- レコード読込
  FETCH get_payment_cur BULK COLLECT INTO gt_payment_tbl;
  --
  -- レコード件数取得
  ln_payment_cnt := gt_payment_tbl.COUNT;
  --
  IF ( ln_payment_cnt > 0 ) THEN
    <<payment_loop>>
    FOR ln_idx IN 1..ln_payment_cnt LOOP
      ln_no_dlv_data := 0;
      -- 入金データがある場合
      BEGIN
        -- 同一顧客、納品伝票番号で、上記で取得した検収日内で最小の訪問日時を取得
        SELECT MIN(xrdcl.visit_time)
        INTO   gt_payment_tbl(ln_idx).dlv_visit_time
        FROM   xxcos_rep_dlv_chk_list    xrdcl                -- 納品書チェックリスト帳票ワークテーブル
        WHERE  xrdcl.request_id      = cn_request_id
        AND    xrdcl.target_date     = gt_payment_tbl(ln_idx).target_date       -- 対象日付
        AND    xrdcl.base_code       = gt_payment_tbl(ln_idx).base_code         -- 拠点コード
        AND    xrdcl.employee_num    = gt_payment_tbl(ln_idx).employee_num      -- 営業員コード
        AND    xrdcl.entry_number    = gt_payment_tbl(ln_idx).entry_number      -- 伝票番号
        AND    xrdcl.party_num       = gt_payment_tbl(ln_idx).party_num         -- 顧客コード
        AND    xrdcl.visit_time      IS NOT NULL
        ;
        -- 同一顧客、納品伝票番号で最小の検収日を取得
        SELECT MIN(xrdcl.dlv_date)
        INTO   gt_payment_tbl(ln_idx).dlv_dlv_date
        FROM   xxcos_rep_dlv_chk_list    xrdcl                -- 納品書チェックリスト帳票ワークテーブル
        WHERE  xrdcl.request_id      = cn_request_id
        AND    xrdcl.target_date     = gt_payment_tbl(ln_idx).target_date       -- 対象日付
        AND    xrdcl.base_code       = gt_payment_tbl(ln_idx).base_code         -- 拠点コード
        AND    xrdcl.employee_num    = gt_payment_tbl(ln_idx).employee_num      -- 営業員コード
        AND    xrdcl.entry_number    = gt_payment_tbl(ln_idx).entry_number      -- 伝票番号
        AND    xrdcl.party_num       = gt_payment_tbl(ln_idx).party_num         -- 顧客コード
        AND    xrdcl.visit_time      = gt_payment_tbl(ln_idx).dlv_visit_time    -- 訪問日時
        AND    xrdcl.visit_time      IS NOT NULL
        AND    rownum  = 1
        ;
        --
        SELECT   xrdcl.card_sale_class                          -- カード売り区分
                ,xrdcl.input_class                              -- 入力区分
                ,xrdcl.invoice_class                            -- 伝票区分
                ,xrdcl.invoice_classification_code              -- 伝票分類コード
        INTO     gt_payment_tbl(ln_idx).dlv_card_sale_class
                ,gt_payment_tbl(ln_idx).dlv_input_class
                ,gt_payment_tbl(ln_idx).dlv_invoice_class
                ,gt_payment_tbl(ln_idx).dlv_invoice_class_code
        FROM   xxcos_rep_dlv_chk_list    xrdcl           -- 納品書チェックリスト帳票ワークテーブル
        WHERE  xrdcl.request_id      = cn_request_id                            -- 要求ID
        AND    xrdcl.target_date     = gt_payment_tbl(ln_idx).target_date       -- 対象日付
        AND    xrdcl.base_code       = gt_payment_tbl(ln_idx).base_code         -- 拠点コード
        AND    xrdcl.employee_num    = gt_payment_tbl(ln_idx).employee_num      -- 営業員コード
        AND    xrdcl.entry_number    = gt_payment_tbl(ln_idx).entry_number      -- 伝票番号
        AND    xrdcl.party_num       = gt_payment_tbl(ln_idx).party_num         -- 顧客コード
        AND    xrdcl.visit_time      = gt_payment_tbl(ln_idx).dlv_visit_time    -- 訪問日時
        AND    xrdcl.dlv_date        = gt_payment_tbl(ln_idx).dlv_dlv_date      -- 検収日
        AND    rownum  = 1
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ln_no_dlv_data := 1;
      END;
      --
      IF ( ln_no_dlv_data = 0 ) THEN
        BEGIN
          UPDATE  xxcos_rep_dlv_chk_list   xrdcl
          SET     xrdcl.card_sale_class              = gt_payment_tbl(ln_idx).dlv_card_sale_class                -- カード売り区分
                 ,xrdcl.input_class                  = gt_payment_tbl(ln_idx).dlv_input_class                    -- 入力区分
                 ,xrdcl.invoice_class                = gt_payment_tbl(ln_idx).dlv_invoice_class                  -- 伝票区分
                 ,xrdcl.invoice_classification_code  = gt_payment_tbl(ln_idx).dlv_invoice_class_code             -- 伝票分類コード
                 ,xrdcl.visit_time                   = gt_payment_tbl(ln_idx).dlv_visit_time                     -- 訪問日時
                 ,xrdcl.dlv_date                     = gt_payment_tbl(ln_idx).dlv_dlv_date                       -- 納品日
          WHERE  xrdcl.rowid                         = gt_payment_tbl(ln_idx).row_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_application
              ,iv_name         => cv_msg_payment_update_err
              ,iv_token_name1  => cv_tkn_hht_invoice_no                          -- 納品伝票番号
              ,iv_token_value1 => gt_payment_tbl(ln_idx).entry_number
              ,iv_token_name2  => cv_tkn_customer_number                              -- 顧客
              ,iv_token_value2 => gt_payment_tbl(ln_idx).party_num
              ,iv_token_name3  => cv_tkn_payment_date                               -- 入金日
              ,iv_token_value3 => TO_CHAR(gt_payment_tbl(ln_idx).dlv_date,cv_fmt_date_default)
            );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END;
      END IF;
    END LOOP payment_loop;
  END IF;
-- 2009/12/17 Ver.1.19 Add End
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
  END money_data_entry;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF起動(A-7)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_api_name      VARCHAR2(5000);
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
    -- 1.明細0件用メッセージ取得
    --==================================
    lv_nodata_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata_err );
--
    --出力ファイル編集
    lv_file_name  := cv_file_id || TO_CHAR( SYSDATE, cv_fmt_date )
                                || TO_CHAR( cn_request_id )
                                || cv_extension_pdf
                                ;
    --==================================
    -- 2.SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
                                          ov_retcode      => lv_retcode,
                                          ov_errbuf       => lv_errbuf,
                                          ov_errmsg       => lv_errmsg,
                                          iv_conc_name    => cv_conc_name,
                                          iv_file_name    => lv_file_name,
                                          iv_file_id      => cv_file_id,
                                          iv_output_mode  => cv_output_mode_pdf,
                                          iv_frm_file     => cv_frm_file,
                                          iv_vrq_file     => cv_vrq_file,
                                          iv_org_id       => NULL,
                                          iv_user_name    => NULL,
                                          iv_resp_name    => NULL,
                                          iv_doc_name     => NULL,
                                          iv_printer_name => NULL,
                                          iv_request_id   => TO_CHAR( cn_request_id ),
                                          iv_nodata_msg   => lv_nodata_msg,
                                          iv_svf_param1   => NULL,
                                          iv_svf_param2   => NULL,
                                          iv_svf_param3   => NULL,
                                          iv_svf_param4   => NULL,
                                          iv_svf_param5   => NULL,
                                          iv_svf_param6   => NULL,
                                          iv_svf_param7   => NULL,
                                          iv_svf_param8   => NULL,
                                          iv_svf_param9   => NULL,
                                          iv_svf_param10  => NULL,
                                          iv_svf_param11  => NULL,
                                          iv_svf_param12  => NULL,
                                          iv_svf_param13  => NULL,
                                          iv_svf_param14  => NULL,
                                          iv_svf_param15  => NULL
                                          );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      --  管理者用メッセージ退避
      lv_errbuf := SUBSTRB( lv_errmsg || lv_errbuf, 5000 );
--
      --  ユーザー用メッセージ取得
      lv_api_name := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_application,
                                             iv_name         => cv_msg_svf_api
                                             );
      lv_errmsg   := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_application,
                                             iv_name         => cv_msg_call_api_err,
                                             iv_token_name1  => cv_tkn_api_name,
                                             iv_token_value1 => lv_api_name
                                             );
      RAISE global_api_expt;
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブルデータ削除(A-8)
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
--
    -- *** ローカル・カーソル ***
    --  ロック取得用
    CURSOR  lock_cur
    IS
      SELECT  rdcl.ROWID
      FROM    xxcos_rep_dlv_chk_list   rdcl
      WHERE   rdcl.request_id = cn_request_id
      FOR UPDATE NOWAIT;
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
    --== 帳票ワークテーブルデータロック ==--
    --  ロック用カーソルオープン
    OPEN  lock_cur;
    --  ロック用カーソルクローズ
    CLOSE lock_cur;
--
    --== 帳票ワークテーブルデータ削除 ==--
    BEGIN
--
      DELETE FROM
        xxcos_rep_dlv_chk_list  dcl         -- 納品書チェックリスト帳票ワークテーブル
      WHERE
        dcl.request_id = cn_request_id;     -- 要求ID
--
    EXCEPTION
      WHEN OTHERS THEN
        -- データ削除エラーメッセージ
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_request_id );
        xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      => lv_errbuf           -- エラー・メッセージ
                                        ,ov_retcode     => lv_retcode          -- リターン・コード
                                        ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
                                        ,ov_key_info    => gv_key_info         -- キー情報
                                        ,iv_item_name1  => gv_tkn1             -- 要求ID
                                        ,iv_data_value1 => cn_request_id
                                        );
--
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
        lv_errmsg := xxccp_common_pkg.get_msg(
                                               cv_application
                                              ,cv_msg_delete_data_err
                                              ,cv_tkn_table
                                              ,gv_tkn1
                                              ,cv_tkn_key_data
                                              ,gv_key_info
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock_err, cv_tkn_table, gv_tkn1 );
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
  END delete_rpt_wrk_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_delivery_date      IN      VARCHAR2,         -- 納品日
    iv_delivery_base_code IN      VARCHAR2,         -- 拠点
    iv_dlv_by_code        IN      VARCHAR2,         -- 営業員
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT伝票No
    ov_errbuf             OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
/* 2009/06/19 Ver1.12 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
/* 2009/06/19 Ver1.12 Add End   */
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    --  ===============================
    --  初期処理(A-0)
    --  ===============================
    init(
       iv_delivery_date        -- 納品日
      ,iv_delivery_base_code   -- 拠点
      ,iv_dlv_by_code          -- 営業員
      ,iv_hht_invoice_no       -- HHT伝票No
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
--
    --  ===============================
    --  販売実績データ抽出(A-3)、納品データ登録（販売実績）(A-4)
    --  ===============================
    sales_per_data_entry(
       iv_delivery_date        -- 納品日
      ,iv_delivery_base_code   -- 拠点
      ,iv_dlv_by_code          -- 営業員
      ,iv_hht_invoice_no       -- HHT伝票No
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  入金データ抽出(A-5)、納品データ登録（入金データ）(A-6)
    --  ===============================
    money_data_entry(
       iv_delivery_date        -- 納品日
      ,iv_delivery_base_code   -- 拠点
      ,iv_dlv_by_code          -- 営業員
      ,iv_hht_invoice_no       -- HHT伝票No
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数が0件であった場合、「明細0件用メッセージ」を出力します。
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata_err );
      FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
      ov_retcode := cv_status_warn;
    END IF;
--
    --  コミット発行
    COMMIT;
--
    --  ===============================
    --  SVF起動(A-7)
    --  ===============================
    execute_svf(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
/* 2009/06/19 Ver1.12 Mod Start */
--    -- エラー処理
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/19 Ver1.12 Mod End   */
--
    --  ===============================
    --  帳票ワークテーブルデータ削除(A-8)
    --  ===============================
    delete_rpt_wrk_data(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
/* 2009/06/19 Ver1.12 Add Start */
    --エラーの場合、ロールバックするのでここでコミット
    COMMIT;
--
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/19 Ver1.12 Add End   */
--
    -- 帳票は対象件数＝正常件数とする
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
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
    errbuf                OUT VARCHAR2,         --  エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,         --  リターン・コード    --# 固定 #
    iv_delivery_date      IN  VARCHAR2,         --  納品日
    iv_delivery_base_code IN  VARCHAR2,         --  拠点
    iv_dlv_by_code        IN  VARCHAR2,         --  営業員
    iv_hht_invoice_no     IN  VARCHAR2          --  HHT伝票No
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票)
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
       iv_delivery_date        -- 納品日
      ,iv_delivery_base_code   -- 拠点
      ,iv_dlv_by_code          -- 営業員
      ,iv_hht_invoice_no       -- HHT伝票No
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --*** エラー出力は要件によって使い分けてください ***--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
       which  => FND_FILE.LOG
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
END XXCOS002A05R;
/
