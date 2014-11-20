CREATE OR REPLACE PACKAGE BODY XXCFR003A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A02C(body)
 * Description      : 請求ヘッダデータ作成
 * MD.050           : MD050_CFR_003_A02_請求ヘッダデータ作成
 * MD.070           : MD050_CFR_003_A02_請求ヘッダデータ作成
 * Version          : 1.08
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  ins_inv_info_trans     p 請求情報引渡テーブル登録処理            (A-2)
 *  ins_target_bill_acct_n p 対象請求先顧客取得処理(夜間)            (A-3)
 *  ins_target_bill_acct_o p 対象請求先顧客取得処理(手動)            (A-4)
 *  get_target_bill_acct   p 請求締対象顧客情報抽出処理              (A-5)
 *  delete_last_data       p 前回処理データ削除処理                  (A-6)
 *  get_bill_info          p 請求対象取引データ取得処理              (A-7)
 *  ins_invoice_header     p 請求ヘッダ情報登録処理                  (A-8)
-- Modify 2009.09.29 Ver1.06 start
-- *  update_tax_gap         p 税差額算出処理                          (A-9)
-- Modify 2009.09.29 Ver1.06 End
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/11    1.00 SCS 松尾 泰生    初回作成
 *  2009/04/20    1.01 SCS 萱原 伸哉    障害T1_0564対応 税差額計算処理
 *  2009/07/13    1.02 SCS 廣瀬 真佐人  障害0000344対応 パフォーマンス改善
 *  2009/07/21    1.03 SCS 松尾 泰生    障害0000819対応 一意制約エラー対応
 *  2009/07/22    1.04 SCS 廣瀬 真佐人  障害0000827対応 パフォーマンス改善
 *  2009/08/03    1.05 SCS 廣瀬 真佐人  障害0000913対応 パフォーマンス改善
 *  2009/09/29    1.06 SCS 廣瀬 真佐人  共通課題IE535対応 請求書問題
 *  2009/12/11    1.07 SCS 安川 智博    障害「E_本稼動_00424」暫定対応
 *  2009/12/28    1.08 SCS 安川 智博    障害「E_本稼動_00606」対応
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
--
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  dml_expt              EXCEPTION;      -- ＤＭＬエラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  PRAGMA EXCEPTION_INIT(dml_expt, -24381);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A02C'; -- パッケージ名
  
  -- プロファイルオプション
  ct_prof_name_itoen_name  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_GENERAL_INVOICE_ITOEN_NAME';   -- 汎用請求書取引先名
  cv_org_id                CONSTANT VARCHAR2(6)  := 'ORG_ID';                   -- 組織ID
  cv_set_of_books_id       CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';         -- 会計帳簿ID
  -- アプリケーション短縮名
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';     -- アプリケーション短縮名(XXCFR)
--
  -- メッセージ番号
  cv_msg_ccp_90000  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --対象件数メッセージ
  cv_msg_ccp_90001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --成功件数メッセージ
  cv_msg_ccp_90002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --エラー件数メッセージ
  cv_msg_ccp_90003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; --スキップ件数メッセージ
  cv_msg_ccp_90004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; --正常終了メッセージ
  cv_msg_ccp_90005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; --警告終了メッセージ
  cv_msg_ccp_90006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; --エラー終了全ロールバックメッセージ
  cv_msg_ccp_90007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; --エラー終了一部処理メッセージ
--
  cv_msg_cfr_00003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --ロックエラーメッセージ
  cv_msg_cfr_00004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_cfr_00006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --業務処理日付エラーメッセージ
  cv_msg_cfr_00007  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --データ削除エラーメッセージ
  cv_msg_cfr_00010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; --共通関数エラーメッセージ
  cv_msg_cfr_00015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --取得エラーメッセージ  
  cv_msg_cfr_00016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --データ挿入エラーメッセージ
  cv_msg_cfr_00017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; --データ更新エラーメッセージ
  cv_msg_cfr_00031  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00031'; --顧客マスタ登録不備エラーメッセージ
  cv_msg_cfr_00065  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00065'; --請求先顧客コードメッセージ
-- Modify 2009.07.21 Ver1.03 start
  cv_msg_cfr_00077  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00077'; --一意制約エラーメッセージ
-- Modify 2009.07.21 Ver1.03 end
--
  -- 日本語辞書参照コード
  cv_dict_cfr_00000002  CONSTANT VARCHAR2(20) := 'CFR000A00002'; -- 営業日付取得関数
  cv_dict_cfr_00000003  CONSTANT VARCHAR2(20) := 'CFR000A00003'; -- 日付パラメータ変換関数
  cv_dict_cfr_00302001  CONSTANT VARCHAR2(20) := 'CFR003A02001'; -- 消費税区分
  cv_dict_cfr_00302002  CONSTANT VARCHAR2(20) := 'CFR003A02002'; -- 請求書出力形式
  cv_dict_cfr_00302003  CONSTANT VARCHAR2(20) := 'CFR003A02003'; -- 売掛コード1(請求先)
  cv_dict_cfr_00302004  CONSTANT VARCHAR2(20) := 'CFR003A02004'; -- 請求拠点コード
  cv_dict_cfr_00302005  CONSTANT VARCHAR2(20) := 'CFR003A02005'; -- 税金－端数処理
  cv_dict_cfr_00302006  CONSTANT VARCHAR2(20) := 'CFR003A02006'; -- 与信関連
  cv_dict_cfr_00302007  CONSTANT VARCHAR2(20) := 'CFR003A02007'; -- 売掛管理先
  cv_dict_cfr_00302008  CONSTANT VARCHAR2(20) := 'CFR003A02008'; -- 税差額
  cv_dict_cfr_00302009  CONSTANT VARCHAR2(20) := 'CFR003A02009'; -- 対象取引データ件数
  cv_dict_cfr_00302010  CONSTANT VARCHAR2(20) := 'CFR003A02010'; -- 請求金額
  cv_dict_cfr_00302011  CONSTANT VARCHAR2(20) := 'CFR003A02011'; -- サイト月数、月限、支払日
  cv_dict_cfr_00302012  CONSTANT VARCHAR2(20) := 'CFR003A02012'; -- 請求顧客情報
  cv_dict_cfr_00302013  CONSTANT VARCHAR2(20) := 'CFR003A02013'; -- 対象期間(自)
  cv_dict_cfr_00302014  CONSTANT VARCHAR2(20) := 'CFR003A02014'; -- 勘定科目・補助科目
--
  -- メッセージトークン
  cv_tkn_prof_name  CONSTANT VARCHAR2(30)  := 'PROF_NAME';       -- プロファイルオプション名
  cv_tkn_func_name  CONSTANT VARCHAR2(30)  := 'FUNC_NAME';       -- ファンクション名
  cv_tkn_table      CONSTANT VARCHAR2(30)  := 'TABLE';           -- テーブル名
  cv_tkn_cust_code  CONSTANT VARCHAR2(30)  := 'CUST_CODE';       -- 顧客コード
  cv_tkn_cust_name  CONSTANT VARCHAR2(30)  := 'CUST_NAME';       -- 顧客名
  cv_tkn_column     CONSTANT VARCHAR2(30)  := 'COLUMN';          -- カラム名
  cv_tkn_data       CONSTANT VARCHAR2(30)  := 'DATA';            -- データ
-- Modify 2009.07.21 Ver1.03 start
  cv_tkn_cut_date   CONSTANT VARCHAR2(30)  := 'CUTOFF_DATE';     -- 締日
-- Modify 2009.07.21 Ver1.03 end
--
  -- 使用DB名
  cv_table_xiit       CONSTANT VARCHAR2(100) := 'XXCFR_INV_INFO_TRANSFER';     -- 請求情報引渡テーブル
  cv_table_xtcl       CONSTANT VARCHAR2(100) := 'XXCFR_INV_TARGET_CUST_LIST';  -- 請求締対象顧客ワークテーブル
  cv_table_xxih       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_HEADERS';       -- 請求ヘッダ情報テーブル
  cv_table_xxil       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_LINES';         -- 請求明細情報テーブル
  cv_table_xxgt       CONSTANT VARCHAR2(100) := 'XXCFR_TAX_GAP_TRX_LIST';      -- 税差額取引作成テーブル
--
  -- 参照タイプ
  cv_look_type_ar_cd  CONSTANT VARCHAR2(100) := 'XXCMM_INVOICE_GRP_CODE';     -- 売掛コード1(請求書)
--
  -- ファイル出力
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_judge_type_batch   CONSTANT VARCHAR2(1)  := '2';         -- 夜間手動判断区分(2:夜間)
  cv_inv_hold_status_o  CONSTANT VARCHAR2(4)  := 'OPEN';      -- 請求書保留ステータス(オープン)
  cv_inv_hold_status_r  CONSTANT VARCHAR2(7)  := 'REPRINT';   -- 請求書保留ステータス(再請求)
  cv_tax_div_outtax     CONSTANT VARCHAR2(1)  := '1';         -- 消費税区分(外税)
  cv_get_acct_name_f    CONSTANT VARCHAR2(1)  := '0';         -- 顧客名称取得関数パラメータ(全角)
  cv_get_acct_name_k    CONSTANT VARCHAR2(1)  := '1';         -- 顧客名称取得関数パラメータ(カナ)
  cv_account_class_rec  CONSTANT VARCHAR2(3)  := 'REC';       -- 勘定区分(売掛/未収金)
  cv_line_type_tax      CONSTANT VARCHAR2(3)  := 'TAX';       -- 取引明細タイプ(税金)
  cv_line_type_line     CONSTANT VARCHAR2(4)  := 'LINE';      -- 取引明細タイプ(明細)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
    -- 請求締対象顧客情報抽出カーソル用
    TYPE get_acct_code_ttype          IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_code%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cutoff_date_ttype        IS TABLE OF xxcfr_inv_target_cust_list.cutoff_date%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cust_name_ttype          IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_name%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cust_acct_id_ttype       IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_account_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cust_acct_site_id_ttype  IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_acct_site_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_term_name_ttype          IS TABLE OF xxcfr_inv_target_cust_list.term_name%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_term_id_ttype            IS TABLE OF xxcfr_inv_target_cust_list.term_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_tax_div_ttype            IS TABLE OF xxcfr_inv_target_cust_list.tax_div%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_bill_pub_cycle_ttype     IS TABLE OF xxcfr_inv_target_cust_list.bill_pub_cycle%TYPE
                                                  INDEX BY PLS_INTEGER;
    gt_get_acct_code_tab            get_acct_code_ttype;
    gt_get_cutoff_date_tab          get_cutoff_date_ttype;
    gt_get_cust_name_tab            get_cust_name_ttype;
    gt_get_cust_acct_id_tab         get_cust_acct_id_ttype;
    gt_get_cust_acct_site_id_tab    get_cust_acct_site_id_ttype;
    gt_get_term_name_tab            get_term_name_ttype;
    gt_get_term_id_tab              get_term_id_ttype;
    gt_get_tax_div_tab              get_tax_div_ttype;
    gt_get_bill_pub_cycle_tab       get_bill_pub_cycle_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_itoen_name              fnd_profile_option_values.profile_option_value%TYPE;  -- 汎用請求書取引先名
  gd_target_date             DATE;                                                 -- 締日(日付型)
  gn_org_id                  NUMBER;                                               -- 組織ID
  gn_set_book_id             NUMBER;                                               -- 会計帳簿ID
  gn_request_id              NUMBER;                                               -- コンカレント要求ID
  gd_process_date            DATE;                                                 -- 業務処理日付
  gd_work_day_ago1           DATE;                                                 -- 1営業日前日
  gd_work_day_ago2           DATE;                                                 -- 2営業日前日
  gt_warning_flag            VARCHAR2(1);                                          -- 警告フラグ
--
  gt_invoice_id              xxcfr_invoice_headers.invoice_id%TYPE;                -- 一括請求書ID
  gt_amount_no_tax           xxcfr_invoice_headers.inv_amount_no_tax%TYPE;         -- 税抜請求金額合計
  gt_tax_amount_sum          xxcfr_invoice_headers.tax_amount_sum%TYPE;            -- 税額合計
  gt_amount_includ_tax       xxcfr_invoice_headers.inv_amount_includ_tax%TYPE;     -- 税込請求金額合計
  gt_due_months_forword      xxcfr_invoice_headers.due_months_forword%TYPE;        -- サイト月数
  gt_month_remit             xxcfr_invoice_headers.month_remit%TYPE;               -- 月限
  gt_payment_date            xxcfr_invoice_headers.payment_date%TYPE;              -- 支払日
  gt_tax_type                xxcfr_invoice_headers.tax_type%TYPE;                  -- 消費税区分
  gt_tax_gap_trx_id          xxcfr_invoice_headers.tax_gap_trx_id%TYPE;            -- 税差額取引ID
  gt_tax_gap_amount          xxcfr_invoice_headers.tax_gap_amount%TYPE;            -- 税差額
  gt_postal_code             xxcfr_invoice_headers.postal_code%TYPE;               -- 送付先郵便番号
  gt_send_address1           xxcfr_invoice_headers.send_address1%TYPE;             -- 送付先住所1
  gt_send_address2           xxcfr_invoice_headers.send_address2%TYPE;             -- 送付先住所2
  gt_send_address3           xxcfr_invoice_headers.send_address3%TYPE;             -- 送付先住所3
  gt_object_date_from        xxcfr_invoice_headers.object_date_from%TYPE;          -- 対象期間（自）
  gt_vender_code             xxcfr_invoice_headers.vender_code%TYPE;               -- 仕入先コード
  gt_receipt_location_code   xxcfr_invoice_headers.receipt_location_code%TYPE;     -- 入金拠点コード
  gt_bill_location_code      xxcfr_invoice_headers.bill_location_code%TYPE;        -- 請求拠点コード
  gt_bill_location_name      xxcfr_invoice_headers.bill_location_name%TYPE;        -- 請求拠点名
  gt_agent_tel_num           xxcfr_invoice_headers.agent_tel_num%TYPE;             -- 担当電話番号
  gt_credit_cust_code        xxcfr_invoice_headers.credit_cust_code%TYPE;          -- 与信先顧客コード
  gt_credit_cust_name        xxcfr_invoice_headers.credit_cust_name%TYPE;          -- 与信先顧客名
  gt_receipt_cust_code       xxcfr_invoice_headers.receipt_cust_code%TYPE;         -- 入金先顧客コード
  gt_receipt_cust_name       xxcfr_invoice_headers.receipt_cust_name%TYPE;         -- 入金先顧客名
  gt_payment_cust_code       xxcfr_invoice_headers.payment_cust_code%TYPE;         -- 親請求先顧客コード
  gt_payment_cust_name       xxcfr_invoice_headers.payment_cust_name%TYPE;         -- 親請求先顧客名
  gt_bill_cust_kana_name     xxcfr_invoice_headers.bill_cust_kana_name%TYPE;       -- 請求先顧客カナ名
  gt_bill_shop_code          xxcfr_invoice_headers.bill_shop_code%TYPE;            -- 請求先店舗コード
  gt_bill_shop_name          xxcfr_invoice_headers.bill_shop_name%TYPE;            -- 請求先店名
  gt_credit_receiv_code2     xxcfr_invoice_headers.credit_receiv_code2%TYPE;       -- 売掛コード2（事業所）
  gt_credit_receiv_name2     xxcfr_invoice_headers.credit_receiv_name2%TYPE;       -- 売掛コード2（事業所）名称
  gt_credit_receiv_code3     xxcfr_invoice_headers.credit_receiv_code3%TYPE;       -- 売掛コード3（その他）
  gt_credit_receiv_name3     xxcfr_invoice_headers.credit_receiv_name3%TYPE;       -- 売掛コード3（その他）名称
  gt_invoice_output_form     xxcfr_invoice_headers.invoice_output_form%TYPE;       -- 請求書出力形式
  gt_tax_round_rule          hz_cust_site_uses_all.tax_rounding_rule%TYPE;         -- 税金－端数処理
  gv_party_ref_type          VARCHAR2(50);                                         -- パーティ関連タイプ(与信関連)
  gv_party_rev_code          VARCHAR2(50);                                         -- パーティ関連(売掛管理先)
-- Modify 2009.07.13 Ver1.02 start
  gt_bill_payment_term_id    hz_cust_site_uses_all.payment_term_id%TYPE;           -- 支払条件1
  gt_bill_payment_term2      hz_cust_site_uses_all.attribute2%TYPE;                -- 支払条件2
  gt_bill_payment_term3      hz_cust_site_uses_all.attribute3%TYPE;                -- 支払条件3
-- Modify 2009.07.13 Ver1.02 end
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date          IN VARCHAR2,      -- 締日
    iv_bill_acct_code       IN VARCHAR2,      -- 請求先顧客コード
    iv_batch_on_judge_type  IN VARCHAR2,      -- 夜間手動判断区分
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
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
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
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
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out        -- メッセージ出力
      ,iv_conc_param1  => iv_target_date          -- 締日
      ,iv_conc_param2  => iv_bill_acct_code       -- 請求先顧客コード
      ,iv_conc_param3  => iv_batch_on_judge_type  -- 夜間手動判断区分
      ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log        -- ログ出力
      ,iv_conc_param1  => iv_target_date          -- 締日
      ,iv_conc_param2  => iv_bill_acct_code       -- 請求先顧客コード
      ,iv_conc_param3  => iv_batch_on_judge_type  -- 夜間手動判断区分
      ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイル取得処理
    --==============================================================
    --汎用請求書取引先名
    gt_itoen_name := FND_PROFILE.VALUE(ct_prof_name_itoen_name);
    IF (gt_itoen_name IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(ct_prof_name_itoen_name);
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_cfr_00004
                                                    ,iv_token_name1  => cv_tkn_prof_name
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --組織ID
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    IF (gn_org_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_org_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --会計帳簿ID
    gn_set_book_id := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_books_id));
    IF (gn_set_book_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_set_of_books_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --業務処理日付取得処理
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date());
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00006  )
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --営業日付取得処理
    --==============================================================
    --1営業日前
    gd_work_day_ago1 := TRUNC(xxccp_common_pkg2.get_working_day(
                                id_date        => gd_process_date
                               ,in_working_day => -1));
    IF (gd_work_day_ago1 IS NULL) THEN
      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                             iv_loopup_type_prefix => cv_msg_kbn_cfr
                            ,iv_keyword            => cv_dict_cfr_00000002);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cfr    
                            ,iv_name         => cv_msg_cfr_00010  
                            ,iv_token_name1  => cv_tkn_func_name  
                            ,iv_token_value1 => lt_look_dict_word)
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    --2営業日前
    gd_work_day_ago2 := TRUNC(xxccp_common_pkg2.get_working_day(
                                id_date        => gd_process_date
                               ,in_working_day => -2));
    IF (gd_work_day_ago2 IS NULL) THEN
      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                             iv_loopup_type_prefix => cv_msg_kbn_cfr
                            ,iv_keyword            => cv_dict_cfr_00000002);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cfr    
                            ,iv_name         => cv_msg_cfr_00010  
                            ,iv_token_name1  => cv_tkn_func_name  
                            ,iv_token_value1 => lt_look_dict_word)
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --入力パラメータ日付型変換処理
    --==============================================================
--
    IF (iv_target_date IS NOT NULL) AND
       (iv_batch_on_judge_type != cv_judge_type_batch)
    THEN
      gd_target_date := xxcfr_common_pkg.get_date_param_trans(iv_target_date);
      -- 業務処理日付に入力パラメータ．締日を設定
      gd_process_date := gd_target_date;
      IF (gd_target_date IS NULL) THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr
                              ,iv_keyword            => cv_dict_cfr_00000003);
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr    
                              ,iv_name         => cv_msg_cfr_00010  
                              ,iv_token_name1  => cv_tkn_func_name  
                              ,iv_token_value1 => lt_look_dict_word)
                            ,1
                            ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --与信関連条件取得処理
    --==============================================================
    -- パーティ関連タイプ(与信関連)取得
    gv_party_ref_type := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_msg_kbn_cfr
                          ,iv_keyword            => cv_dict_cfr_00302006);
--
    -- パーティ関連(売掛管理先)取得
    gv_party_rev_code := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_msg_kbn_cfr
                          ,iv_keyword            => cv_dict_cfr_00302007);
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Procedure Name   : ins_inv_info_trans
   * Description      : 請求情報引渡テーブル登録処理(A-2)
   ***********************************************************************************/
  PROCEDURE ins_inv_info_trans(
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_info_trans'; -- プログラム名
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
    ln_target_cnt       NUMBER;         -- 対象件数
--
    -- *** ローカル・カーソル ***
--
    -- 削除対象データ抽出
    CURSOR del_inv_info_trans_cur
    IS
      SELECT xiit.ROWID    row_id
      FROM   xxcfr_inv_info_transfer xiit
      WHERE  xiit.org_id = gn_org_id
      AND    xiit.set_of_books_id = gn_set_book_id
      FOR UPDATE NOWAIT
    ;
--
    TYPE del_inv_info_trans_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_inv_info_trans_tab    del_inv_info_trans_ttype;
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
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
--
    --==============================================================
    --請求情報引渡テーブルデータ削除処理
    --==============================================================
    -- 請求情報引渡テーブルロック
--
    -- カーソルオープン
    OPEN del_inv_info_trans_cur;
--
    -- データの一括取得
    FETCH del_inv_info_trans_cur BULK COLLECT INTO lt_del_inv_info_trans_tab;
--
    -- 処理件数のセット
    ln_target_cnt := lt_del_inv_info_trans_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE del_inv_info_trans_cur;
--
    -- 対象データが存在する場合レコードを削除する
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<transfer_data_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_inv_info_transfer
          WHERE ROWID = lt_del_inv_info_trans_tab(ln_loop_cnt);
      END IF;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00007      -- テーブル削除エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xiit))
                                                                         -- 請求情報引渡テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --請求情報引渡テーブルデータ登録処理
    --==============================================================
    BEGIN
      INSERT INTO xxcfr_inv_info_transfer (
         target_request_id     
        ,set_of_books_id
        ,org_id
        ,created_by            
        ,creation_date         
        ,last_updated_by       
        ,last_update_date      
        ,last_update_login     
        ,request_id            
        ,program_application_id
        ,program_id            
        ,program_update_date   
      )
      VALUES
      (
         cn_request_id
        ,gn_set_book_id
        ,gn_org_id
        ,cn_created_by             
        ,cd_creation_date          
        ,cn_last_updated_by        
        ,cd_last_update_date       
        ,cn_last_update_login      
        ,cn_request_id             
        ,cn_program_application_id 
        ,cn_program_id             
        ,cd_program_update_date    
      );
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xiit))
                                                                         -- 請求情報引渡テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** テーブルロックエラーハンドラ ***
    WHEN lock_expt THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( 
                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                             ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xiit))
                                                    -- 請求情報引渡テーブル
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
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
  END ins_inv_info_trans;
--
  /**********************************************************************************
   * Procedure Name   : ins_target_bill_acct_n
   * Description      : 対象請求先顧客取得処理(夜間)(A-3)
   ***********************************************************************************/
  PROCEDURE ins_target_bill_acct_n(
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_target_bill_acct_n'; -- プログラム名
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
    ln_target_cnt       NUMBER;         -- 対象件数
--
    -- *** ローカル・カーソル ***
--
    -- 支払条件抽出(1)カーソル
    CURSOR get_target_term_info1_cur
    IS
      SELECT inlv.name        name
           , inlv.cut_date    cut_date
           , inlv.term_id     term_id
      FROM (
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(gd_process_date, -1)), 'DD')) THEN
                             LAST_DAY(ADD_MONTHS(gd_process_date, -1))
                    ELSE TO_DATE(TO_CHAR(ADD_MONTHS(gd_process_date, -1), 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --締開始日or最終月日付が未設定は対象外
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
        UNION ALL
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(gd_process_date), 'DD')) THEN
                             LAST_DAY(gd_process_date)
                    ELSE TO_DATE(TO_CHAR(gd_process_date, 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --締開始日or最終月日付が未設定は対象外
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
      ) inlv
      WHERE  inlv.cut_date >= gd_work_day_ago1
      AND    inlv.cut_date <  gd_process_date
      ORDER BY inlv.cut_date DESC
      ;
--
    -- 支払条件抽出(2)カーソル
    CURSOR get_target_term_info2_cur
    IS
      SELECT inlv.name        name
           , inlv.cut_date    cut_date
           , inlv.term_id     term_id
      FROM (
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(gd_process_date, -1)), 'DD')) THEN
                             LAST_DAY(ADD_MONTHS(gd_process_date, -1))
                    ELSE TO_DATE(TO_CHAR(ADD_MONTHS(gd_process_date, -1), 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --締開始日or最終月日付が未設定は対象外
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
        UNION ALL
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(gd_process_date), 'DD')) THEN
                             LAST_DAY(gd_process_date)
                    ELSE TO_DATE(TO_CHAR(gd_process_date, 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --締開始日or最終月日付が未設定は対象外
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
      ) inlv
      WHERE  inlv.cut_date >= gd_work_day_ago2
      AND    inlv.cut_date <  gd_work_day_ago1
      ORDER BY inlv.cut_date DESC
      ;
--
    TYPE get_target_term_name_ttype     IS TABLE OF ra_terms_vl.name%TYPE INDEX BY PLS_INTEGER;
    TYPE get_target_term_cut_date_ttype IS TABLE OF DATE INDEX BY PLS_INTEGER;
    TYPE get_target_term_term_id_ttype  IS TABLE OF ra_terms_vl.term_id%TYPE INDEX BY PLS_INTEGER;
    lt_get1_term_name_tab               get_target_term_name_ttype;
    lt_get1_term_cut_date_tab           get_target_term_cut_date_ttype;
    lt_get1_term_term_id_tab            get_target_term_term_id_ttype;
    lt_get2_term_name_tab               get_target_term_name_ttype;
    lt_get2_term_cut_date_tab           get_target_term_cut_date_ttype;
    lt_get2_term_term_id_tab            get_target_term_term_id_ttype;
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
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
--
    --==============================================================
    --請求締対象顧客ワークテーブル登録処理(締日が1営業日後の顧客)
    --==============================================================
    -- 支払条件抽出(1)カーソルオープン
    OPEN get_target_term_info1_cur;
--
    -- データの一括取得
    FETCH get_target_term_info1_cur 
    BULK COLLECT INTO  lt_get1_term_name_tab    
                     , lt_get1_term_cut_date_tab
                     , lt_get1_term_term_id_tab 
    ;
--
    -- 処理件数のセット
    ln_target_cnt := lt_get1_term_name_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE get_target_term_info1_cur;
--
    -- 対象データが存在時,請求締対象顧客ワークテーブル登録
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<target_term_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
--
          -- 請求締対象顧客ワークテーブル登録
          INSERT INTO xxcfr_inv_target_cust_list(
              bill_cust_code
            , cutoff_date
            , bill_cust_name
            , bill_cust_account_id
            , bill_cust_acct_site_id
            , term_name
            , term_id
            , tax_div
            , bill_pub_cycle
          )
-- Modify 2009.07.22 Ver1.04 start
--            SELECT  hzca.account_number                        bill_cust_code          -- 請求先顧客コード
-- Modify 2009.08.03 Ver1.05 start
--            SELECT  /*+ USE_CONCAT */
            SELECT  /*+ USE_CONCAT 
                        ORDERED
                    */
-- Modify 2009.08.03 Ver1.05 End
                    hzca.account_number                        bill_cust_code          -- 請求先顧客コード
-- Modify 2009.07.22 Ver1.04 start
                  , lt_get1_term_cut_date_tab(ln_loop_cnt)     cutoff_date             -- 締日
                  , xxcfr_common_pkg.get_cust_account_name(
                                       hzca.account_number,
                                       cv_get_acct_name_f)     bill_cust_name          -- 請求先顧客名
                  , hzca.cust_account_id                       bill_cust_account_id    -- 請求先顧客ID
                  , hzsa.cust_acct_site_id                     bill_cust_acct_site_id  -- 請求先顧客所在地ID
                  , lt_get1_term_name_tab(ln_loop_cnt)         term_name               -- 支払条件
                  , lt_get1_term_term_id_tab(ln_loop_cnt)      term_id                 -- 支払条件ID
                  , xxca.tax_div                               tax_div                 -- 消費税区分
                  , hzsu.attribute8                            bill_pub_cycle          -- 請求書発行サイクル
            FROM
-- Modify 2009.08.03 Ver1.05 start
--                   hz_cust_accounts          hzca              -- 顧客マスタ
--                  ,hz_cust_acct_sites_all    hzsa              -- 顧客所在地
--                  ,hz_cust_site_uses_all     hzsu              -- 顧客使用目的
                   hz_cust_site_uses_all     hzsu              -- 顧客使用目的
                  ,hz_cust_acct_sites_all    hzsa              -- 顧客所在地
                  ,hz_cust_accounts          hzca              -- 顧客マスタ
-- Modify 2009.08.03 Ver1.05 End
                  ,xxcmm_cust_accounts       xxca              -- 顧客追加情報
                  ,hz_customer_profiles      hzcp              -- 顧客プロファイル
            WHERE
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND  ( hzsu.payment_term_id = lt_get1_term_term_id_tab(ln_loop_cnt)
            OR     hzsu.attribute2 = TO_CHAR(lt_get1_term_term_id_tab(ln_loop_cnt))
            OR     hzsu.attribute3 = TO_CHAR(lt_get1_term_term_id_tab(ln_loop_cnt)) )  --支払条件
            AND    hzsu.site_use_code = 'BILL_TO'                     -- 使用目的コード(請求先)
            AND    hzcp.cons_inv_flag = 'Y'                           -- 一括請求書式使用可能FLAG('Y')
            AND    hzsa.org_id = gn_org_id                            -- 組織ID
            AND    hzsu.org_id = gn_org_id                            -- 組織ID
            AND    hzsu.attribute8 = '1'                              -- 請求書発行サイクル(第一営業日)
-- Modify 2009.12.28 Ver1.08 start
--            AND EXISTS (
--              SELECT 'X'
--              FROM   hz_cust_site_uses_all   shsu
--              WHERE  shsu.bill_to_site_use_id = hzsu.site_use_id
--              AND    shsu.site_use_code = 'SHIP_TO'                   -- 使用目的コード(出荷先)
--              AND    shsu.org_id = gn_org_id
--              AND    ROWNUM = 1
--              )
-- Modify 2009.12.28 Ver1.08 end
            AND NOT EXISTS (
              SELECT 'X'
              FROM   xxcfr_inv_target_cust_list xxcl
              WHERE  xxcl.bill_cust_code = hzca.account_number
              )
          ;
--
      END IF;
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xtcl))
                                                                         -- 請求締対象顧客ワークテーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --ローカル変数初期化
    ln_target_cnt := 0;
--
    --==============================================================
    --請求締対象顧客ワークテーブル登録処理(締日が2営業日後の顧客)
    --==============================================================
    -- 支払条件抽出(2)カーソルオープン
    OPEN get_target_term_info2_cur;
--
    -- データの一括取得
    FETCH get_target_term_info2_cur 
    BULK COLLECT INTO  lt_get2_term_name_tab    
                     , lt_get2_term_cut_date_tab
                     , lt_get2_term_term_id_tab 
    ;
--
    -- 処理件数のセット
    ln_target_cnt := lt_get2_term_name_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE get_target_term_info2_cur;
--
    -- 対象データが存在時,請求締対象顧客ワークテーブル登録
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<target_term_loop2>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
--
          -- 請求締対象顧客ワークテーブル登録
          INSERT INTO xxcfr_inv_target_cust_list(
              bill_cust_code
            , cutoff_date
            , bill_cust_name
            , bill_cust_account_id
            , bill_cust_acct_site_id
            , term_name
            , term_id
            , tax_div
            , bill_pub_cycle
          )
-- Modify 2009.07.22 Ver1.04 start
--            SELECT  hzca.account_number                       bill_cust_code          -- 請求先顧客コード
-- Modify 2009.08.03 Ver1.05 start
--            SELECT  /*+ USE_CONCAT */
            SELECT  /*+ USE_CONCAT 
                        ORDERED
                    */
-- Modify 2009.08.03 Ver1.05 End
                    hzca.account_number                       bill_cust_code          -- 請求先顧客コード
-- Modify 2009.07.22 Ver1.04 start
                  , lt_get2_term_cut_date_tab(ln_loop_cnt)    cutoff_date             -- 締日
                  , xxcfr_common_pkg.get_cust_account_name(
                                       hzca.account_number,
                                       cv_get_acct_name_f)    bill_cust_name          -- 請求先顧客名
                  , hzca.cust_account_id                      bill_cust_account_id    -- 請求先顧客ID
                  , hzsa.cust_acct_site_id                    bill_cust_acct_site_id  -- 請求先顧客所在地ID
                  , lt_get2_term_name_tab(ln_loop_cnt)        term_name               -- 支払条件
                  , lt_get2_term_term_id_tab(ln_loop_cnt)     term_id                 -- 支払条件ID
                  , xxca.tax_div                              tax_div                 -- 消費税区分
                  , hzsu.attribute8                           bill_pub_cycle          -- 請求書発行サイクル
            FROM
-- Modify 2009.08.03 Ver1.05 start
--                   hz_cust_accounts          hzca              -- 顧客マスタ
--                  ,hz_cust_acct_sites_all    hzsa              -- 顧客所在地
--                  ,hz_cust_site_uses_all     hzsu              -- 顧客使用目的
                   hz_cust_site_uses_all     hzsu              -- 顧客使用目的
                  ,hz_cust_acct_sites_all    hzsa              -- 顧客所在地
                  ,hz_cust_accounts          hzca              -- 顧客マスタ
-- Modify 2009.08.03 Ver1.05 End
                  ,xxcmm_cust_accounts       xxca              -- 顧客追加情報
                  ,hz_customer_profiles      hzcp              -- 顧客プロファイル
            WHERE
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND  ( hzsu.payment_term_id = lt_get2_term_term_id_tab(ln_loop_cnt)
            OR     hzsu.attribute2      = TO_CHAR(lt_get2_term_term_id_tab(ln_loop_cnt))
            OR     hzsu.attribute3      = TO_CHAR(lt_get2_term_term_id_tab(ln_loop_cnt)) )--支払条件
            AND    hzsu.site_use_code = 'BILL_TO'                    -- 使用目的コード(請求先)
            AND    hzcp.cons_inv_flag = 'Y'                          -- 一括請求書式使用可能FLAG('Y')
            AND    hzsa.org_id = gn_org_id                           -- 組織ID
            AND    hzsu.org_id = gn_org_id                           -- 組織ID
            AND    hzsu.attribute8 = '2'                             -- 請求書発行サイクル(第二営業日)
-- Modify 2009.12.28 Ver1.08 start
--            AND EXISTS (
--              SELECT 'X'
--              FROM   hz_cust_site_uses_all   shsu
--              WHERE  shsu.bill_to_site_use_id = hzsu.site_use_id
--              AND    shsu.site_use_code = 'SHIP_TO'                    -- 使用目的コード(出荷先)
--              AND    shsu.org_id = gn_org_id
--              AND    ROWNUM = 1
--              )
-- Modify 2009.12.28 Ver1.08 end
            AND NOT EXISTS (
              SELECT 'X'
              FROM   xxcfr_inv_target_cust_list xxcl
              WHERE  xxcl.bill_cust_code = hzca.account_number
              )
          ;
--
      END IF;
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xtcl))
                                                                         -- 請求締対象顧客ワークテーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
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
  END ins_target_bill_acct_n;
--
  /**********************************************************************************
   * Procedure Name   : ins_target_bill_acct_o
   * Description      : 対象請求先顧客取得処理(手動)(A-4)
   ***********************************************************************************/
  PROCEDURE ins_target_bill_acct_o(
    iv_bill_acct_code       IN  VARCHAR2,     -- 請求先顧客コード
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_target_bill_acct_o'; -- プログラム名
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
    ln_target_cnt       NUMBER;         -- 対象件数
--
    -- *** ローカル・カーソル ***
--
    -- 支払条件抽出(手動)カーソル
    CURSOR get_target_term_info_cur
    IS
      SELECT inlv.name        name
           , inlv.cut_date    cut_date
           , inlv.term_id     term_id
      FROM (
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(gd_process_date), 'DD')) THEN
                             LAST_DAY(gd_process_date)
                    ELSE TO_DATE(TO_CHAR(gd_process_date, 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --締開始日or最終月日付が未設定は対象外
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
      ) inlv
      WHERE  inlv.cut_date = gd_target_date
      ;
--
    TYPE get_target_term_name_ttype     IS TABLE OF ra_terms_vl.name%TYPE INDEX BY PLS_INTEGER;
    TYPE get_target_term_cut_date_ttype IS TABLE OF DATE INDEX BY PLS_INTEGER;
    TYPE get_target_term_term_id_ttype  IS TABLE OF ra_terms_vl.term_id%TYPE INDEX BY PLS_INTEGER;
    lt_get_term_name_tab                get_target_term_name_ttype;
    lt_get_term_cut_date_tab            get_target_term_cut_date_ttype;
    lt_get_term_term_id_tab             get_target_term_term_id_ttype;
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
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
--
    --==============================================================
    --請求締対象顧客ワークテーブル登録処理
    --==============================================================
    -- 支払条件抽出カーソルオープン
    OPEN get_target_term_info_cur;
--
    -- データの一括取得
    FETCH get_target_term_info_cur 
    BULK COLLECT INTO  lt_get_term_name_tab    
                     , lt_get_term_cut_date_tab
                     , lt_get_term_term_id_tab 
    ;
--
    -- 処理件数のセット
    ln_target_cnt := lt_get_term_name_tab.COUNT;
    -- カーソルクローズ
    CLOSE get_target_term_info_cur;
--
    -- 対象データが存在時,請求締対象顧客ワークテーブル登録
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<target_term_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
--
          -- 請求締対象顧客ワークテーブル登録
          INSERT INTO xxcfr_inv_target_cust_list(
              bill_cust_code
            , cutoff_date
            , bill_cust_name
            , bill_cust_account_id
            , bill_cust_acct_site_id
            , term_name
            , term_id
            , tax_div
            , bill_pub_cycle
          )
-- Modify 2009.07.22 Ver1.04 start
--            SELECT  hzca.account_number                      bill_cust_code          -- 請求先顧客コード
-- Modify 2009.08.03 Ver1.05 start
--            SELECT  /*+ USE_CONCAT */
            SELECT  /*+ USE_CONCAT 
                        ORDERED
                    */
-- Modify 2009.08.03 Ver1.05 End
                    hzca.account_number                      bill_cust_code          -- 請求先顧客コード
-- Modify 2009.07.22 Ver1.04 start
                  , lt_get_term_cut_date_tab(ln_loop_cnt)    cutoff_date             -- 締日
                  , xxcfr_common_pkg.get_cust_account_name(
                                       hzca.account_number,
                                       cv_get_acct_name_f)   bill_cust_name          -- 請求先顧客名
                  , hzca.cust_account_id                     bill_cust_account_id    -- 請求先顧客ID
                  , hzsa.cust_acct_site_id                   bill_cust_acct_site_id  -- 請求先顧客所在地ID
                  , lt_get_term_name_tab(ln_loop_cnt)        term_name               -- 支払条件
                  , lt_get_term_term_id_tab(ln_loop_cnt)     term_id                 -- 支払条件ID
                  , xxca.tax_div                             tax_div                 -- 消費税区分
                  , hzsu.attribute8                          bill_pub_cycle          -- 請求書発行サイクル
            FROM
-- Modify 2009.08.03 Ver1.05 start
--                   hz_cust_accounts          hzca              -- 顧客マスタ
--                  ,hz_cust_acct_sites_all    hzsa              -- 顧客所在地
--                  ,hz_cust_site_uses_all     hzsu              -- 顧客使用目的
                   hz_cust_site_uses_all     hzsu              -- 顧客使用目的
                  ,hz_cust_acct_sites_all    hzsa              -- 顧客所在地
                  ,hz_cust_accounts          hzca              -- 顧客マスタ
-- Modify 2009.08.03 Ver1.05 start
                  ,xxcmm_cust_accounts       xxca              -- 顧客追加情報
                  ,hz_customer_profiles      hzcp              -- 顧客プロファイル
            WHERE
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND  ( hzsu.payment_term_id = lt_get_term_term_id_tab(ln_loop_cnt)
            OR     hzsu.attribute2      = TO_CHAR(lt_get_term_term_id_tab(ln_loop_cnt))
            OR     hzsu.attribute3      = TO_CHAR(lt_get_term_term_id_tab(ln_loop_cnt)) )--支払条件
            AND    hzsu.site_use_code = 'BILL_TO'                    -- 使用目的コード(請求先)
            AND    hzcp.cons_inv_flag = 'Y'                          -- 一括請求書式使用可能FLAG('Y')
            AND    hzsa.org_id = gn_org_id                           -- 組織ID
            AND    hzsu.org_id = gn_org_id                           -- 組織ID
-- Modify 2009.07.13 Ver1.02 start
--            AND    hzsu.attribute8 IS NOT NULL                       -- 請求書発行サイクル
            AND    hzsu.attribute8 IN('1','2')                       -- 請求書発行サイクル
-- Modify 2009.07.13 Ver1.02 end
            AND    hzca.account_number = NVL(iv_bill_acct_code, hzca.account_number)
-- Modify 2009.12.28 Ver1.08 start
--            AND EXISTS (
--              SELECT 'X'
--              FROM   hz_cust_site_uses_all   shsu
--              WHERE  shsu.bill_to_site_use_id = hzsu.site_use_id
--              AND    shsu.site_use_code = 'SHIP_TO'                    -- 使用目的コード(出荷先)
--              AND    shsu.org_id = gn_org_id
--              AND    ROWNUM = 1
--              )
-- Modify 2009.12.28 Ver1.08 end
            AND NOT EXISTS (
              SELECT 'X'
              FROM   xxcfr_inv_target_cust_list xxcl
              WHERE  xxcl.bill_cust_code = hzca.account_number
              )
          ;
--
      END IF;
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xtcl))
                                                                         -- 請求締対象顧客ワークテーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
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
  END ins_target_bill_acct_o;
--
  /**********************************************************************************
   * Procedure Name   : get_target_bill_acct
   * Description      : 請求締対象顧客情報抽出処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_target_bill_acct(
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_bill_acct'; -- プログラム名
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
    ln_target_cnt       NUMBER;         -- 対象件数
--
    -- *** ローカル・カーソル ***
--
    -- 請求締対象顧客情報抽出カーソル
    CURSOR get_target_acct_info_cur
    IS
      SELECT bill_cust_code             bill_cust_code        
           , cutoff_date                cutoff_date
           , bill_cust_name             bill_cust_name
           , bill_cust_account_id       bill_cust_account_id
           , bill_cust_acct_site_id     bill_cust_acct_site_id
           , term_name                  term_name
           , term_id                    term_id
           , tax_div                    tax_div
           , bill_pub_cycle             bill_pub_cycle
      FROM   xxcfr_inv_target_cust_list
      ;
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
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
--
    --==============================================================
    --請求締対象顧客ワークテーブル登録処理
    --==============================================================
    -- 請求締対象顧客情報抽出カーソルオープン
    OPEN get_target_acct_info_cur;
--
    -- データの一括取得
    FETCH get_target_acct_info_cur 
    BULK COLLECT INTO gt_get_acct_code_tab,
                      gt_get_cutoff_date_tab,
                      gt_get_cust_name_tab,
                      gt_get_cust_acct_id_tab,
                      gt_get_cust_acct_site_id_tab,
                      gt_get_term_name_tab,
                      gt_get_term_id_tab,
                      gt_get_tax_div_tab,
                      gt_get_bill_pub_cycle_tab   
    ;
--
    -- 処理件数のセット
    gn_target_cnt := gt_get_acct_code_tab.COUNT;
    -- カーソルクローズ
    CLOSE get_target_acct_info_cur;
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_target_bill_acct;
--
  /**********************************************************************************
   * Procedure Name   : delete_last_data
   * Description      : 前回処理データ削除処理(A-6)
   ***********************************************************************************/
  PROCEDURE delete_last_data(
    iv_account_code         IN  VARCHAR2,     -- 請求先顧客コード
    id_cutoff_date          IN  DATE,         -- 締日
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_last_data'; -- プログラム名
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
    ln_target_cnt       NUMBER;         -- 対象件数
--
    -- *** ローカル・カーソル ***
--
    -- 前回処理データ抽出(ヘッダ)
    CURSOR del_target_inv_data_cur(
      id_cutoff_date    VARCHAR2,
      iv_customer_code  VARCHAR2
    )
    IS
      SELECT xxih.invoice_id    invoice_id
      FROM   xxcfr_invoice_headers xxih
      WHERE  xxih.cutoff_date = id_cutoff_date
      AND    xxih.bill_cust_code = iv_customer_code
      AND    xxih.org_id = gn_org_id
      AND    xxih.set_of_books_id = gn_set_book_id
      FOR UPDATE NOWAIT
    ;
--
    -- 前回処理データ抽出(明細)ロック用
    -- ※請求ヘッダテーブルにのみデータが存在するケースを想定し
    --   請求明細テーブルのロックを別で作成
    CURSOR del_target_inv_line_data_cur(
      id_cutoff_date    VARCHAR2,
      iv_customer_code  VARCHAR2
    )
    IS
      SELECT xxil.invoice_id    invoice_id
      FROM   xxcfr_invoice_lines   xxil
      WHERE  xxil.invoice_id IN (
               SELECT xxih.invoice_id    invoice_id
               FROM   xxcfr_invoice_headers xxih
               WHERE  xxih.cutoff_date = id_cutoff_date
               AND    xxih.bill_cust_code = iv_customer_code
               AND    xxih.org_id = gn_org_id
               )
      FOR UPDATE NOWAIT
    ;
--
    TYPE del_target_inv_id_ttype IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE INDEX BY PLS_INTEGER;
    lt_del_target_inv_id_tab     del_target_inv_id_ttype;
    lt_inv_line_id_tab           del_target_inv_id_ttype;
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
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
--
    --==============================================================
    --請求テーブルロック情報取得処理
    --==============================================================
    -- カーソルオープン(ヘッダ)
    BEGIN
      OPEN del_target_inv_data_cur( id_cutoff_date,
                                    iv_account_code)
      ;
--
      -- データの一括取得
      FETCH del_target_inv_data_cur BULK COLLECT INTO lt_del_target_inv_id_tab;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_target_inv_id_tab.COUNT;
--
      -- カーソルクローズ
      CLOSE del_target_inv_data_cur;
--
    EXCEPTION
      -- *** テーブルロックエラーハンドラ ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- 請求ヘッダ情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    -- カーソルオープン(明細)
    BEGIN
      OPEN del_target_inv_line_data_cur( id_cutoff_date,
                                         iv_account_code)
      ;
--
      -- データの一括取得
      FETCH del_target_inv_line_data_cur BULK COLLECT INTO lt_inv_line_id_tab;
--
      -- カーソルクローズ
      CLOSE del_target_inv_line_data_cur;
--
    EXCEPTION
      -- *** テーブルロックエラーハンドラ ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                                         -- 請求明細情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    -- 対象データが存在する場合レコードを削除する
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<del_invoice_lines_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_invoice_lines
          WHERE invoice_id = lt_del_target_inv_id_tab(ln_loop_cnt);
--
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00007      -- テーブル削除エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                                         -- 請求明細情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
      END;
--
      BEGIN
        <<del_invoice_header_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_invoice_headers
          WHERE invoice_id = lt_del_target_inv_id_tab(ln_loop_cnt);
--
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00007      -- テーブル削除エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                      -- 請求ヘッダ情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
      END;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_last_data;
--
  /**********************************************************************************
   * Procedure Name   : get_bill_info
   * Description      : 請求対象取引データ取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_bill_info(
    iv_cust_acct_id         IN  NUMBER,       -- 請求先顧客ID
    id_cutoff_date          IN  DATE,         -- 締日
    ov_target_trx_cnt       OUT NUMBER,       -- 対象取引件数
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bill_info'; -- プログラム名
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
    ln_target_cnt       NUMBER;         -- 対象件数
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
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
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
    lt_look_dict_word := NULL;
--
    -- グローバル変数初期化
    gt_amount_no_tax     := 0;
    gt_tax_amount_sum    := 0;
    gt_amount_includ_tax := 0;
--
-- Modify 2009.12.28 Ver1.08 start
    --==============================================================
    --対象データ件数取得処理
    --==============================================================
--    BEGIN
--      SELECT COUNT(rcta.customer_trx_id)    cnt
--      INTO   ln_target_cnt
--      FROM   ra_customer_trx_all        rcta
--           , ra_customer_trx_lines_all  rcla
--      WHERE  rcta.trx_date <= id_cutoff_date                                  -- 締日
--      AND    rcta.attribute7 IN (cv_inv_hold_status_o, cv_inv_hold_status_r)  -- 請求書保留ステータス
--      AND    rcta.bill_to_customer_id = iv_cust_acct_id                       -- 請求先顧客ID
--      AND    rcta.org_id          = gn_org_id                                 -- 組織ID
--      AND    rcta.set_of_books_id = gn_set_book_id                            -- 会計帳簿ID
--      AND    rcta.customer_trx_id = rcla.customer_trx_id
--      ;
--    EXCEPTION
--      -- *** OTHERS例外ハンドラ ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                               iv_keyword            => cv_dict_cfr_00302009);    -- 対象取引データ件数
--        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cfr,
--                               iv_name         => cv_msg_cfr_00015,  
--                               iv_token_name1  => cv_tkn_data,  
--                               iv_token_value1 => lt_look_dict_word),
--                             1,
--                             5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
--
--    -- 対象取引データ件数をセット
--    ov_target_trx_cnt := ln_target_cnt;
--
--    IF (ln_target_cnt > 0) THEN
      --==============================================================
      --請求金額取得処理
      --==============================================================
      BEGIN
        SELECT SUM( DECODE( rcla.line_type, cv_line_type_line, rcla.extended_amount
                                          , 0))   amount_no_tax             -- 税抜請求金額合計
             , SUM( DECODE( rcla.line_type, cv_line_type_tax , rcla.extended_amount
                                          , 0))   tax_amount_sum            -- 税額合計
             , SUM( rcla.extended_amount)         amount_includ_tax         -- 税込請求金額合計
             , COUNT('X')                         cnt                       -- レコード件数
        INTO   gt_amount_no_tax
             , gt_tax_amount_sum
             , gt_amount_includ_tax
             , ln_target_cnt
        FROM   ra_customer_trx_all        rcta
             , ra_customer_trx_lines_all  rcla
        WHERE  rcta.trx_date <= id_cutoff_date                                  -- 締日
        AND    rcta.attribute7 IN (cv_inv_hold_status_o, cv_inv_hold_status_r)  -- 請求書保留ステータス
        AND    rcta.bill_to_customer_id = iv_cust_acct_id                       -- 請求先顧客ID
        AND    rcta.org_id          = gn_org_id                                 -- 組織ID
        AND    rcta.set_of_books_id = gn_set_book_id                            -- 会計帳簿ID
        AND    rcta.customer_trx_id = rcla.customer_trx_id
        ;
        -- 対象取引データ件数をセット
        ov_target_trx_cnt := ln_target_cnt;
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00302010);    -- 請求金額
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
--    END IF;
-- Modify 2009.12.28 Ver1.08 end
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_bill_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_invoice_header
   * Description      : 請求ヘッダ情報登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_invoice_header(
    iv_cust_acct_code       IN  VARCHAR2,     -- 請求先顧客コード
    id_cutoff_date          IN  DATE,         -- 締日
    iv_cust_acct_name       IN  VARCHAR2,     -- 請求先顧客名
    iv_cust_acct_id         IN  VARCHAR2,     -- 請求先顧客ID
    iv_cust_acct_site_id    IN  VARCHAR2,     -- 請求先顧客所在地ID
    iv_term_name            IN  VARCHAR2,     -- 支払条件
    iv_term_id              IN  NUMBER,       -- 支払条件ID
    iv_tax_div              IN  VARCHAR2,     -- 消費税区分
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_invoice_header'; -- プログラム名
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
    ln_target_cnt       NUMBER;                             -- 対象件数
    lv_dict_err_code    VARCHAR2(20);                       -- 日本語辞書参照コード
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;  -- 日本語辞書ワード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    acct_info_required_expt  EXCEPTION;      -- 顧客情報必須エラー
-- Modify 2009.07.21 Ver1.03 start
    uniq_expt                EXCEPTION;      -- 一意制約エラー
--
    PRAGMA EXCEPTION_INIT(uniq_expt, -1);    -- 一意制約エラー
-- Modify 2009.07.21 Ver1.03 end
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
    lv_dict_err_code  := NULL;
    lt_look_dict_word := NULL;
--
    -- グローバル変数初期化
    gt_invoice_id            := NULL;      -- 一括請求書ID
    gt_due_months_forword    := NULL;      -- サイト月数
    gt_month_remit           := NULL;      -- 月限
    gt_payment_date          := NULL;      -- 支払日
    gt_tax_type              := NULL;      -- 消費税区分
    gt_tax_gap_trx_id        := NULL;      -- 税差額取引ID
    gt_tax_gap_amount        := NULL;      -- 税差額
    gt_postal_code           := NULL;      -- 送付先郵便番号
    gt_send_address1         := NULL;      -- 送付先住所1
    gt_send_address2         := NULL;      -- 送付先住所2
    gt_send_address3         := NULL;      -- 送付先住所3
    gt_vender_code           := NULL;      -- 仕入先コード
    gt_receipt_location_code := NULL;      -- 入金拠点コード
    gt_bill_location_code    := NULL;      -- 請求拠点コード
    gt_bill_location_name    := NULL;      -- 請求拠点名
    gt_agent_tel_num         := NULL;      -- 担当電話番号
    gt_credit_cust_code      := NULL;      -- 与信先顧客コード
    gt_credit_cust_name      := NULL;      -- 与信先顧客名
    gt_receipt_cust_code     := NULL;      -- 入金先顧客コード
    gt_receipt_cust_name     := NULL;      -- 入金先顧客名
    gt_payment_cust_code     := NULL;      -- 親請求先顧客コード
    gt_payment_cust_name     := NULL;      -- 親請求先顧客名
    gt_bill_cust_kana_name   := NULL;      -- 請求先顧客カナ名
    gt_bill_shop_code        := NULL;      -- 請求先店舗コード
    gt_bill_shop_name        := NULL;      -- 請求先店名
    gt_credit_receiv_code2   := NULL;      -- 売掛コード2（事業所）
    gt_credit_receiv_name2   := NULL;      -- 売掛コード2（事業所）名称
    gt_credit_receiv_code3   := NULL;      -- 売掛コード3（その他）
    gt_credit_receiv_name3   := NULL;      -- 売掛コード3（その他）名称
    gt_invoice_output_form   := NULL;      -- 請求書出力形式
    gt_tax_round_rule        := NULL;      -- 税金－端数処理
    gt_object_date_from      := NULL;      -- 対象期間（自）
-- Modify 2009.07.13 Ver1.02 start
    gt_bill_payment_term_id  := NULL;      -- 支払条件1
    gt_bill_payment_term2    := NULL;      -- 支払条件2
    gt_bill_payment_term3    := NULL;      -- 支払条件3
-- Modify 2009.07.13 Ver1.02 end
--
    --==============================================================
    --ヘッダデータ取得処理
    --==============================================================
    --サイト月数、月限、支払日の取得
    BEGIN
      SELECT ratl.due_months_forward       due_months_forward, -- サイト月数
             TO_CHAR(ADD_MONTHS(id_cutoff_date + 1,
                                - 1 + ratl.due_months_forward),
                     'YYYYMMDD')           month_remit,        -- 月限
             CASE WHEN ratl.due_day_of_month 
                         >= TO_NUMBER(
                              TO_CHAR(
                                LAST_DAY( ADD_MONTHS( id_cutoff_date,
                                                      ratl.due_months_forward)),
                                'DD'))
                  THEN LAST_DAY( ADD_MONTHS( id_cutoff_date, ratl.due_months_forward))
                  ELSE TO_DATE( TO_CHAR( ADD_MONTHS( id_cutoff_date,
                                                     ratl.due_months_forward),
                                         'YYYY/MM/') || 
                                TO_CHAR(ratl.due_day_of_month), 'YYYY/MM/DD')
             END                           payment_date        -- 支払日
      INTO   gt_due_months_forword,
             gt_month_remit,
             gt_payment_date
      FROM   ra_terms_b        ratb,
             ra_terms_lines    ratl
      WHERE  ratb.term_id = ratl.term_id
      AND    ratb.term_id = iv_term_id
      AND    ROWNUM = 1
      ;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00302011);    -- サイト月数、月限、支払日
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00015,  
                               iv_token_name1  => cv_tkn_data,  
                               iv_token_value1 => lt_look_dict_word),
                             1,
                             5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --顧客情報の取得
    BEGIN
-- Modify 2009.08.03 Ver1.05 start
--      SELECT xxhv.bill_tax_div                        tax_type,               -- 消費税区分
      SELECT /*+ LEADING(xxhv.temp.bill_hzca_1 xxhv.temp.bill_hzca_2 xxhv.temp.ship_hzca_3 xxhv.temp.ship_hzca_4) 
                 USE_NL(xxhv.temp.bill_hasa_1 xxhv.temp.bill_hsua_1 xxhv.temp.bill_hzad_1 
                        xxhv.temp.bill_hzps_1 xxhv.temp.bill_hzlo_1 xxhv.temp.bill_hzcp_1 
                        xxhv.temp.ship_hzca_1 xxhv.temp.ship_hasa_1 xxhv.temp.ship_hsua_1 
                        xxhv.temp.ship_hzad_1 xxhv.temp.bill_hcar_1)
                 USE_NL(xxhv.temp.cash_hasa_2 xxhv.temp.cash_hzad_2 xxhv.temp.bill_hasa_2 
                        xxhv.temp.bill_hsua_2 xxhv.temp.bill_hzad_2 xxhv.temp.bill_hzps_2 
                        xxhv.temp.bill_hzlo_2 xxhv.temp.bill_hzcp_2 xxhv.temp.ship_hzca_2 
                        xxhv.temp.ship_hasa_2 xxhv.temp.ship_hsua_2 xxhv.temp.ship_hzad_2 
                        xxhv.temp.cash_hcar_2 xxhv.temp.bill_hcar_2)
                 USE_NL(xxhv.temp.cash_hzca_3 xxhv.temp.cash_hasa_3 xxhv.temp.cash_hzad_3 
                        xxhv.temp.bill_hasa_3 xxhv.temp.bill_hsua_3 
                        xxhv.temp.ship_hsua_3 xxhv.temp.bill_hzad_3 xxhv.temp.bill_hzps_3
                        xxhv.temp.bill_hzlo_3 xxhv.temp.bill_hzcp_3 xxhv.temp.cash_hcar_3)
                 USE_NL(xxhv.temp.bill_hasa_4 xxhv.temp.bill_hsua_4 xxhv.temp.ship_hsua_4
                        xxhv.temp.bill_hzad_4 xxhv.temp.bill_hzps_4 xxhv.temp.bill_hzlo_4
                        xxhv.temp.bill_hzcp_4)
              */
             xxhv.bill_tax_div                        tax_type,               -- 消費税区分
-- Modify 2009.08.03 Ver1.05 End
             NULL                                     tax_gap_trx_id,         -- 税差額取引ID
             0                                        tax_gap_amount,         -- 税差額
             xxhv.bill_postal_code                    postal_code,            -- 送付先郵便番号
             xxhv.bill_state || xxhv.bill_city        send_address1,          -- 送付先住所1
             xxhv.bill_address1                       send_address2,          -- 送付先住所2
             xxhv.bill_address2                       send_address3,          -- 送付先住所3
             xxhv.bill_torihikisaki_code              vender_code,            -- 仕入先コード
             xxhv.cash_receiv_base_code               receipt_location_code,  -- 入金拠点コード
             xxhv.bill_bill_base_code                 bill_location_code,     -- 請求拠点コード
             xxcfr_common_pkg.get_cust_account_name(
               xxhv.bill_bill_base_code,
               cv_get_acct_name_f)                    bill_location_name,     -- 請求拠点名
             xxcfr_common_pkg.get_base_target_tel_num(
               iv_cust_acct_code)                     agent_tel_num,          -- 担当電話番号
             hzca.account_number                      credit_cust_code,       -- 与信先顧客コード
             xxcfr_common_pkg.get_cust_account_name(
               hzca.account_number,
               cv_get_acct_name_f)                    credit_cust_name,       -- 与信先顧客名
             xxhv.cash_account_number                 receipt_cust_code,      -- 入金先顧客コード
             xxcfr_common_pkg.get_cust_account_name(
               xxhv.cash_account_number,
               cv_get_acct_name_f)                    receipt_cust_name,      -- 入金先顧客名
             fnlv.lookup_code                         payment_cust_code,      -- 親請求先顧客コード
             fnlv.meaning                             payment_cust_name,      -- 親請求先顧客名
             xxcfr_common_pkg.get_cust_account_name(
               iv_cust_acct_code,
               cv_get_acct_name_k)                    bill_cust_kana_name,    -- 請求先顧客カナ名
             xxhv.bill_store_code                     bill_shop_code,         -- 請求先店舗コード
             xxhv.bill_cust_store_name                bill_shop_name,         -- 請求先店名
             xxhv.bill_cred_rec_code2                 credit_receiv_code2,    -- 売掛コード2（事業所）
             NULL                                     credit_receiv_name2,    -- 売掛コード2（事業所）名称
             xxhv.bill_cred_rec_code3                 credit_receiv_code3,    -- 売掛コード3（その他）
             NULL                                     credit_receiv_name3,    -- 売掛コード3（その他）名称
             xxhv.bill_invoice_type                   invoice_output_form,    -- 請求書出力形式
             xxhv.bill_tax_round_rule                         -- 税金－端数処理
-- Modify 2009.07.13 Ver1.02 start
            ,xxhv.bill_payment_term_id                bill_payment_term_id    -- 支払条件1
            ,xxhv.bill_payment_term2                  bill_payment_term2      -- 支払条件2
            ,xxhv.bill_payment_term3                  bill_payment_term3      -- 支払条件3
-- Modify 2009.07.13 Ver1.02 end
      INTO   gt_tax_type,               -- 消費税区分
             gt_tax_gap_trx_id,         -- 税差額取引ID
             gt_tax_gap_amount,         -- 税差額
             gt_postal_code,            -- 送付先郵便番号
             gt_send_address1,          -- 送付先住所1
             gt_send_address2,          -- 送付先住所2
             gt_send_address3,          -- 送付先住所3
             gt_vender_code,            -- 仕入先コード
             gt_receipt_location_code,  -- 入金拠点コード
             gt_bill_location_code,     -- 請求拠点コード
             gt_bill_location_name,     -- 請求拠点名
             gt_agent_tel_num,          -- 担当電話番号
             gt_credit_cust_code,       -- 与信先顧客コード
             gt_credit_cust_name,       -- 与信先顧客名
             gt_receipt_cust_code,      -- 入金先顧客コード
             gt_receipt_cust_name,      -- 入金先顧客名
             gt_payment_cust_code,      -- 親請求先顧客コード
             gt_payment_cust_name,      -- 親請求先顧客名
             gt_bill_cust_kana_name,    -- 請求先顧客カナ名
             gt_bill_shop_code,         -- 請求先店舗コード
             gt_bill_shop_name,         -- 請求先店名
             gt_credit_receiv_code2,    -- 売掛コード2（事業所）
             gt_credit_receiv_name2,    -- 売掛コード2（事業所）名称
             gt_credit_receiv_code3,    -- 売掛コード3（その他）
             gt_credit_receiv_name3,    -- 売掛コード3（その他）名称
             gt_invoice_output_form,    -- 請求書出力形式
             gt_tax_round_rule          -- 税金－端数処理
-- Modify 2009.07.13 Ver1.02 start
            ,gt_bill_payment_term_id    -- 支払条件1
            ,gt_bill_payment_term2      -- 支払条件2
            ,gt_bill_payment_term3      -- 支払条件3
-- Modify 2009.07.13 Ver1.02 end
      FROM   xxcfr_cust_hierarchy_v    xxhv,       -- 顧客階層ビュー
             hz_relationships          hzrl,       -- パーティ関連
             hz_cust_accounts          hzca,       -- (与信先)顧客マスタ
             fnd_lookup_values         fnlv        -- クイックコード
      WHERE  xxhv.bill_account_id = iv_cust_acct_id
      AND    xxhv.bill_party_id = hzrl.object_id(+)
      AND    hzrl.status(+) = 'A'
      AND    hzrl.relationship_type(+) = gv_party_ref_type
      AND    hzrl.relationship_code(+) = gv_party_rev_code
      AND    gd_process_date BETWEEN TRUNC( NVL( hzrl.start_date(+), gd_process_date ) )
                                 AND TRUNC( NVL( hzrl.end_date(+),   gd_process_date ) )
      AND    hzrl.subject_id = hzca.party_id(+)
      AND    xxhv.bill_cred_rec_code1 = fnlv.lookup_code(+)
      AND    fnlv.lookup_type(+)  = cv_look_type_ar_cd
      AND    fnlv.language(+)     = USERENV( 'LANG' )
      AND    fnlv.enabled_flag(+) = 'Y'
      AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                 AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
      AND    ROWNUM = 1
      ;
    EXCEPTION
-- Modify 2009.12.28 Ver1.08 start
      -- *** NO_DATA_FOUND例外ハンドラ ***
      WHEN NO_DATA_FOUND THEN
        SELECT xxca.tax_div                             tax_type,               -- 消費税区分
               NULL                                     tax_gap_trx_id,         -- 税差額取引ID
               0                                        tax_gap_amount,         -- 税差額
               hzlo_bill.postal_code                    postal_code,            -- 送付先郵便番号
               hzlo_bill.state || hzlo_bill.city        send_address1,          -- 送付先住所1
               hzlo_bill.address1                       send_address2,          -- 送付先住所2
               hzlo_bill.address2                       send_address3,          -- 送付先住所3
               xxca.torihikisaki_code                   vender_code,            -- 仕入先コード
               xxca.receiv_base_code                    receipt_location_code,  -- 入金拠点コード
               xxca.bill_base_code                      bill_location_code,     -- 請求拠点コード
               xxcfr_common_pkg.get_cust_account_name(
                 xxca.bill_base_code,
                 cv_get_acct_name_f)                    bill_location_name,     -- 請求拠点名
               xxcfr_common_pkg.get_base_target_tel_num(
                 iv_cust_acct_code)                     agent_tel_num,          -- 担当電話番号
               hzca.account_number                      credit_cust_code,       -- 与信先顧客コード
               xxcfr_common_pkg.get_cust_account_name(
                 hzca.account_number,
                 cv_get_acct_name_f)                    credit_cust_name,       -- 与信先顧客名
               iv_cust_acct_code                        receipt_cust_code,      -- 入金先顧客コード
               iv_cust_acct_name                        receipt_cust_name,      -- 入金先顧客名
               fnlv.lookup_code                         payment_cust_code,      -- 親請求先顧客コード
               fnlv.meaning                             payment_cust_name,      -- 親請求先顧客名
               xxcfr_common_pkg.get_cust_account_name(
                 iv_cust_acct_code,
                 cv_get_acct_name_k)                    bill_cust_kana_name,    -- 請求先顧客カナ名
               xxca.store_code                          bill_shop_code,         -- 請求先店舗コード
               xxca.cust_store_name                     bill_shop_name,         -- 請求先店名
               hsua_bill.attribute5                     credit_receiv_code2,    -- 売掛コード2（事業所）
               NULL                                     credit_receiv_name2,    -- 売掛コード2（事業所）名称
               hsua_bill.attribute6                     credit_receiv_code3,    -- 売掛コード3（その他）
               NULL                                     credit_receiv_name3,    -- 売掛コード3（その他）名称
               hsua_bill.attribute7                     invoice_output_form,    -- 請求書出力形式
               hsua_bill.tax_rounding_rule              bill_tax_round_rule,    -- 税金－端数処理
               hsua_bill.payment_term_id                bill_payment_term_id,   -- 支払条件1
               hsua_bill.attribute2                     bill_payment_term2,     -- 支払条件2
               hsua_bill.attribute3                     bill_payment_term3      -- 支払条件3
        INTO   gt_tax_type,               -- 消費税区分
               gt_tax_gap_trx_id,         -- 税差額取引ID
               gt_tax_gap_amount,         -- 税差額
               gt_postal_code,            -- 送付先郵便番号
               gt_send_address1,          -- 送付先住所1
               gt_send_address2,          -- 送付先住所2
               gt_send_address3,          -- 送付先住所3
               gt_vender_code,            -- 仕入先コード
               gt_receipt_location_code,  -- 入金拠点コード
               gt_bill_location_code,     -- 請求拠点コード
               gt_bill_location_name,     -- 請求拠点名
               gt_agent_tel_num,          -- 担当電話番号
               gt_credit_cust_code,       -- 与信先顧客コード
               gt_credit_cust_name,       -- 与信先顧客名
               gt_receipt_cust_code,      -- 入金先顧客コード
               gt_receipt_cust_name,      -- 入金先顧客名
               gt_payment_cust_code,      -- 親請求先顧客コード
               gt_payment_cust_name,      -- 親請求先顧客名
               gt_bill_cust_kana_name,    -- 請求先顧客カナ名
               gt_bill_shop_code,         -- 請求先店舗コード
               gt_bill_shop_name,         -- 請求先店名
               gt_credit_receiv_code2,    -- 売掛コード2（事業所）
               gt_credit_receiv_name2,    -- 売掛コード2（事業所）名称
               gt_credit_receiv_code3,    -- 売掛コード3（その他）
               gt_credit_receiv_name3,    -- 売掛コード3（その他）名称
               gt_invoice_output_form,    -- 請求書出力形式
               gt_tax_round_rule          -- 税金－端数処理
              ,gt_bill_payment_term_id    -- 支払条件1
              ,gt_bill_payment_term2      -- 支払条件2
              ,gt_bill_payment_term3      -- 支払条件3
        FROM  xxcmm_cust_accounts       xxca,       -- 顧客追加情報
              hz_cust_accounts          hzca_bill,  -- 顧客マスタ
              hz_cust_acct_sites        hasa_bill,  -- 顧客所在地
              hz_cust_site_uses         hsua_bill,  -- 顧客使用目的
              hz_party_sites            hzps_bill,  -- 顧客パーティサイト
              hz_locations              hzlo_bill,  -- 顧客事業所
              hz_parties                hzpa,       -- パーティ
              hz_relationships          hzrl,       -- パーティ関連
              hz_cust_accounts          hzca,       -- (与信先)顧客マスタ
              fnd_lookup_values         fnlv        -- クイックコード
        WHERE xxca.customer_id = iv_cust_acct_id
        AND   hzca_bill.cust_account_id = xxca.customer_id
        AND   hzpa.party_id = hzca_bill.party_id
        AND   hzpa.party_id = hzrl.object_id(+)
        AND   hzrl.status(+) = 'A'
        AND   hzrl.relationship_type(+) = gv_party_ref_type
        AND   hzrl.relationship_code(+) = gv_party_rev_code
        AND   gd_process_date BETWEEN TRUNC( NVL( hzrl.start_date(+), gd_process_date ) )
                                  AND TRUNC( NVL( hzrl.end_date(+),   gd_process_date ) )
        AND   hzrl.subject_id = hzca.party_id(+)
        AND   hasa_bill.cust_account_id = hzca_bill.cust_account_id
        AND   hsua_bill.cust_acct_site_id = hasa_bill.cust_acct_site_id
        AND   hsua_bill.site_use_code = 'BILL_TO'
        AND   hsua_bill.attribute4 = fnlv.lookup_code(+)     -- 売掛コード１
        AND   fnlv.lookup_type(+)  = cv_look_type_ar_cd
        AND   fnlv.language(+)     = USERENV( 'LANG' )
        AND   fnlv.enabled_flag(+) = 'Y'
        AND   gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                 AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
        AND   hzps_bill.party_site_id = hasa_bill.party_site_id
        AND   hzlo_bill.location_id = hzps_bill.location_id
        AND   ROWNUM = 1
        ;
-- Modify 2009.12.28 Ver1.08 end
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00302012);    -- 請求顧客情報
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00015,  
                               iv_token_name1  => cv_tkn_data,  
                               iv_token_value1 => lt_look_dict_word),
                             1,
                             5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --取得項目のNULLチェック
    --==============================================================
    BEGIN
      --消費税区分
      IF (gt_tax_type IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302001;
        RAISE acct_info_required_expt;
      END IF;
--
      --請求書出力形式
      IF (gt_invoice_output_form IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302002;
        RAISE acct_info_required_expt;
      END IF;
--
      --売掛コード1(請求先)
      IF (gt_payment_cust_code IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302003;
        RAISE acct_info_required_expt;
      END IF;
--
      --請求拠点コード
      IF (gt_bill_location_code IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302004;
        RAISE acct_info_required_expt;
      END IF;
--
      --税金－端数処理
      IF (gt_tax_round_rule IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302005;
        RAISE acct_info_required_expt;
      END IF;
--
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => lv_dict_err_code);
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                      ,iv_name         => cv_msg_cfr_00031  
                                                      ,iv_token_name1  => cv_tkn_cust_code  
                                                      ,iv_token_value1 => iv_cust_acct_code
                                                      ,iv_token_name2  => cv_tkn_cust_name  
                                                      ,iv_token_value2 => iv_cust_acct_name
                                                      ,iv_token_name3  => cv_tkn_column  
                                                      ,iv_token_value3 => lt_look_dict_word)
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := cv_status_warn;
        RETURN;
    END;
--
    --対象期間（自）情報
    BEGIN
      SELECT MAX(inlv.cutoff_date) + 1   object_date -- 直近締日の翌日
      INTO   gt_object_date_from
      FROM   (
              --第1支払条件(前月)
              SELECT CASE WHEN DECODE(rv11.due_cutoff_day - 1, 0, 31, rv11.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)), 'DD')) 
                          THEN LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(ADD_MONTHS(id_cutoff_date, -1), 'YYYY/MM/') || 
                                   DECODE(rv11.due_cutoff_day - 1, 0, 31, rv11.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- 顧客階層ビュー
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv11           -- 支払条件マスタ
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id      = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term_id = rv11.term_id
              WHERE  rv11.term_id              = gt_bill_payment_term_id
-- Modify 2009.07.13 Ver1.02 start
              AND    rv11.due_cutoff_day IS NOT NULL        --締開始日or最終月日付が未設定は対象外
              AND    gd_process_date BETWEEN NVL(rv11.start_date_active, gd_process_date)
                                         AND NVL(rv11.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --第1支払条件(当月)
              SELECT CASE WHEN DECODE(rv12.due_cutoff_day - 1, 0, 31, rv12.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(id_cutoff_date), 'DD')) 
                          THEN LAST_DAY(id_cutoff_date) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(id_cutoff_date, 'YYYY/MM/') || 
                                   DECODE(rv12.due_cutoff_day - 1, 0, 31, rv12.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- 顧客階層ビュー
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv12           -- 支払条件マスタ
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id      = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term_id = rv12.term_id
              WHERE  rv12.term_id              = gt_bill_payment_term_id
-- Modify 2009.07.13 Ver1.02 start
              AND    rv12.due_cutoff_day IS NOT NULL        --締開始日or最終月日付が未設定は対象外
              AND    gd_process_date BETWEEN NVL(rv12.start_date_active, gd_process_date)
                                         AND NVL(rv12.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --第2支払条件(前月)
              SELECT CASE WHEN DECODE(rv21.due_cutoff_day - 1, 0, 31, rv21.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)), 'DD')) 
                          THEN LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(ADD_MONTHS(id_cutoff_date, -1), 'YYYY/MM/') || 
                                   DECODE(rv21.due_cutoff_day - 1, 0, 31, rv21.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- 顧客階層ビュー
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv21           -- 支払条件マスタ
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term2 = rv21.term_id
              WHERE  rv21.term_id              = gt_bill_payment_term2
-- Modify 2009.07.13 Ver1.02 start
              AND    rv21.due_cutoff_day IS NOT NULL        --締開始日or最終月日付が未設定は対象外
              AND    gd_process_date BETWEEN NVL(rv21.start_date_active, gd_process_date)
                                         AND NVL(rv21.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --第2支払条件(当月)
              SELECT CASE WHEN DECODE(rv22.due_cutoff_day - 1, 0, 31, rv22.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(id_cutoff_date), 'DD')) 
                          THEN LAST_DAY(id_cutoff_date) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(id_cutoff_date, 'YYYY/MM/') || 
                                   DECODE(rv22.due_cutoff_day - 1, 0, 31, rv22.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- 顧客階層ビュー
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv22           -- 支払条件マスタ
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term2 = rv22.term_id
              WHERE  rv22.term_id              = gt_bill_payment_term2
-- Modify 2009.07.13 Ver1.02 start
              AND    rv22.due_cutoff_day IS NOT NULL        --締開始日or最終月日付が未設定は対象外
              AND    gd_process_date BETWEEN NVL(rv22.start_date_active, gd_process_date)
                                         AND NVL(rv22.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --第3支払条件(前月)
              SELECT CASE WHEN DECODE(rv31.due_cutoff_day - 1, 0, 31, rv31.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)), 'DD')) 
                          THEN LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(ADD_MONTHS(id_cutoff_date, -1), 'YYYY/MM/') || 
                                   DECODE(rv31.due_cutoff_day - 1, 0, 31, rv31.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- 顧客階層ビュー
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv31           -- 支払条件マスタ
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term3 = rv31.term_id
              WHERE  rv31.term_id              = gt_bill_payment_term3
-- Modify 2009.07.13 Ver1.02 start
              AND    rv31.due_cutoff_day IS NOT NULL        --締開始日or最終月日付が未設定は対象外
              AND    gd_process_date BETWEEN NVL(rv31.start_date_active, gd_process_date)
                                         AND NVL(rv31.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --第3支払条件(当月)
              SELECT CASE WHEN DECODE(rv32.due_cutoff_day - 1, 0, 31, rv32.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(id_cutoff_date), 'DD')) 
                          THEN LAST_DAY(id_cutoff_date) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(id_cutoff_date, 'YYYY/MM/') || 
                                   DECODE(rv32.due_cutoff_day - 1, 0, 31, rv32.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- 顧客階層ビュー
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv32           -- 支払条件マスタ
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term3 = rv32.term_id
              WHERE  rv32.term_id              = gt_bill_payment_term3
-- Modify 2009.07.13 Ver1.02 start
              AND    rv32.due_cutoff_day IS NOT NULL        --締開始日or最終月日付が未設定は対象外
              AND    gd_process_date BETWEEN NVL(rv32.start_date_active, gd_process_date)
                                         AND NVL(rv32.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
             ) inlv
      WHERE  inlv.cutoff_date < id_cutoff_date      -- 締日
      ;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00302013);    -- 対象期間(自)
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00015,  
                               iv_token_name1  => cv_tkn_data,  
                               iv_token_value1 => lt_look_dict_word),
                             1,
                             5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --請求ヘッダ情報テーブル登録処理
    --==============================================================
    BEGIN
      INSERT INTO xxcfr_invoice_headers(
        invoice_id,                        -- 一括請求書ID
        set_of_books_id,                   -- 会計帳簿ID
        cutoff_date,                       -- 締日
        term_name,                         -- 支払条件
        term_id,                           -- 支払条件ID
        due_months_forword,                -- サイト月数
        month_remit,                       -- 月限
        payment_date,                      -- 支払日
        tax_type,                          -- 消費税区分
        tax_gap_trx_id,                    -- 税差額取引ID
        tax_gap_amount,                    -- 税差額
        inv_amount_no_tax,                 -- 税抜請求金額合計
        tax_amount_sum,                    -- 税額合計
        inv_amount_includ_tax,             -- 税込請求金額合計
        itoen_name,                        -- 取引先名
        postal_code,                       -- 送付先郵便番号
        send_address1,                     -- 送付先住所1
        send_address2,                     -- 送付先住所2
        send_address3,                     -- 送付先住所3
        send_to_name,                      -- 送付先名
        inv_creation_date,                 -- 作成日
        object_month,                      -- 対象年月
        object_date_from,                  -- 対象期間（自）
        object_date_to,                    -- 対象期間（至）
        vender_code,                       -- 仕入先コード
        receipt_location_code,             -- 入金拠点コード
        bill_location_code,                -- 請求拠点コード
        bill_location_name,                -- 請求拠点名
        agent_tel_num,                     -- 担当電話番号
        credit_cust_code,                  -- 与信先顧客コード
        credit_cust_name,                  -- 与信先顧客名
        receipt_cust_code,                 -- 入金先顧客コード
        receipt_cust_name,                 -- 入金先顧客名
        payment_cust_code,                 -- 親請求先顧客コード
        payment_cust_name,                 -- 親請求先顧客名
        bill_cust_code,                    -- 請求先顧客コード
        bill_cust_name,                    -- 請求先顧客名
        bill_cust_kana_name,               -- 請求先顧客カナ名
        bill_cust_account_id,              -- 請求先顧客ID
        bill_cust_acct_site_id,            -- 請求先顧客所在地ID
        bill_shop_code,                    -- 請求先店舗コード
        bill_shop_name,                    -- 請求先店名
        credit_receiv_code2,               -- 売掛コード2（事業所）
        credit_receiv_name2,               -- 売掛コード2（事業所）名称
        credit_receiv_code3,               -- 売掛コード3（その他）
        credit_receiv_name3,               -- 売掛コード3（その他）名称
        invoice_output_form,               -- 請求書出力形式
        org_id,                            -- 組織ID
        created_by,                        -- 作成者
        creation_date,                     -- 作成日
        last_updated_by,                   -- 最終更新者
        last_update_date,                  -- 最終更新日
        last_update_login,                 -- 最終更新ログイン
        request_id,                        -- 要求ID
        program_application_id,            -- コンカレント・プログラム・アプリケーションID
        program_id,                        -- コンカレント・プログラムID
        program_update_date                -- プログラム更新日
      ) VALUES (
        xxcfr_invoice_headers_s1.NEXTVAL,                             -- 一括請求書ID
        gn_set_book_id,                                               -- 会計帳簿ID
        id_cutoff_date,                                               -- 締日
        iv_term_name,                                                 -- 支払条件
        iv_term_id,                                                   -- 支払条件ID
        gt_due_months_forword,                                        -- サイト月数
        gt_month_remit,                                               -- 月限
        gt_payment_date,                                              -- 支払日
        gt_tax_type,                                                  -- 消費税区分
        gt_tax_gap_trx_id,                                            -- 税差額取引ID
        gt_tax_gap_amount,                                            -- 税差額
        gt_amount_no_tax,                                             -- 税抜請求金額合計
        gt_tax_amount_sum,                                            -- 税額合計
        gt_amount_includ_tax,                                         -- 税込請求金額合計
        gt_itoen_name,                                                -- 取引先名
        gt_postal_code,                                               -- 送付先郵便番号
        gt_send_address1,                                             -- 送付先住所1
        gt_send_address2,                                             -- 送付先住所2
        gt_send_address3,                                             -- 送付先住所3
        iv_cust_acct_name,                                            -- 送付先名
        cd_creation_date,                                             -- 作成日
        TO_CHAR(id_cutoff_date, 'YYYYMM'),                            -- 対象年月
        gt_object_date_from,                                          -- 対象期間（自）
        id_cutoff_date,                                               -- 対象期間（至）
        gt_vender_code,                                               -- 仕入先コード
        gt_receipt_location_code,                                     -- 入金拠点コード
        gt_bill_location_code,                                        -- 請求拠点コード
        gt_bill_location_name,                                        -- 請求拠点名
        gt_agent_tel_num,                                             -- 担当電話番号
        NVL(gt_credit_cust_code, iv_cust_acct_code),                  -- 与信先顧客コード
        NVL(gt_credit_cust_name, iv_cust_acct_name),                  -- 与信先顧客名
        gt_receipt_cust_code,                                         -- 入金先顧客コード
        gt_receipt_cust_name,                                         -- 入金先顧客名
        gt_payment_cust_code,                                         -- 親請求先顧客コード
        gt_payment_cust_name,                                         -- 親請求先顧客名
        iv_cust_acct_code,                                            -- 請求先顧客コード
        iv_cust_acct_name,                                            -- 請求先顧客名
        gt_bill_cust_kana_name,                                       -- 請求先顧客カナ名
        iv_cust_acct_id,                                              -- 請求先顧客ID
        iv_cust_acct_site_id,                                         -- 請求先顧客所在地ID
        gt_bill_shop_code,                                            -- 請求先店舗コード
        gt_bill_shop_name,                                            -- 請求先店名
        gt_credit_receiv_code2,                                       -- 売掛コード2（事業所）
        gt_credit_receiv_name2,                                       -- 売掛コード2（事業所）名称
        gt_credit_receiv_code3,                                       -- 売掛コード3（その他）
        gt_credit_receiv_name3,                                       -- 売掛コード3（その他）名称
        gt_invoice_output_form,                                       -- 請求書出力形式
        gn_org_id,                                                    -- 組織ID
        cn_created_by,                                                -- 作成者
        cd_creation_date,                                             -- 作成日
        cn_last_updated_by,                                           -- 最終更新者
        cd_last_update_date,                                          -- 最終更新日
        cn_last_update_login,                                         -- 最終更新ログイン
        cn_request_id,                                                -- 要求ID
        cn_program_application_id,                                    -- コンカレント・プログラム・アプリケーションID
        cn_program_id,                                                -- コンカレント・プログラムID
        cd_program_update_date                                        -- プログラム更新日
      )
      RETURNING invoice_id INTO gt_invoice_id;                        -- 一括請求書ID
--
    EXCEPTION
-- Modify 2009.07.21 Ver1.03 start
    -- *** 一意制約例外ハンドラ ***
      WHEN uniq_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr    
                              ,iv_name         => cv_msg_cfr_00077  
                              ,iv_token_name1  => cv_tkn_cut_date  
                              ,iv_token_value1 => TO_CHAR(id_cutoff_date, 'YYYY/MM/DD')
                              ,iv_token_name2  => cv_tkn_cust_code  
                              ,iv_token_value2 => iv_cust_acct_code
                              ,iv_token_name3  => cv_tkn_cust_name  
                              ,iv_token_value3 => iv_cust_acct_name)
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := cv_status_warn;
        RETURN;
-- Modify 2009.07.21 Ver1.03 end
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- 請求ヘッダ情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --請求ヘッダ情報テーブル登録件数カウントアップ
    --==============================================================
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg || 
                     SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00065,  --請求先顧客コードメッセージ
                               iv_token_name1  => cv_tkn_cust_code,  
                               iv_token_value1 => iv_cust_acct_code),
                             1,
                             5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_invoice_header;
--
-- Modify 2009.09.29 Ver1.06 start
--  /**********************************************************************************
--   * Procedure Name   : update_tax_gap
--   * Description      : 税差額算出処理(A-9)
--   ***********************************************************************************/
--  PROCEDURE update_tax_gap(
--    iv_cust_acct_code       IN  VARCHAR2,     -- 請求先顧客コード
--    id_cutoff_date          IN  DATE,         -- 締日
--    iv_cust_acct_name       IN  VARCHAR2,     -- 請求先顧客名
--    iv_cust_acct_id         IN  VARCHAR2,     -- 請求先顧客ID
--    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
--    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
--    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
--  )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_tax_gap'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_target_cnt       NUMBER;                             -- 対象件数
--    ln_upd_target_cnt   NUMBER;                             -- 更新対象件数
--    ln_tax_gap_amount   NUMBER;                             -- 税差額
--    lt_segment3         gl_code_combinations.segment3%TYPE; -- 勘定科目
--    lt_segment4         gl_code_combinations.segment4%TYPE; -- 補助科目
--    lv_dict_err_code    VARCHAR2(20);                       -- 日本語辞書参照コード
--    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;  -- 日本語辞書ワード
----
--    -- *** ローカル・カーソル ***
----
--    -- 税コード単位の税差額データ抽出
--    CURSOR get_tax_gap_cur
--    IS
---- Modify 2009.07.13 Ver1.02 start
----      SELECT taxv.tax_rate                                       tax_rate,       -- 税率
----             taxv.vat_tax_id                                     vat_tax_id,     -- 税コードID
----             SUM(taxv.re_calc_tax_amount - taxv.sum_tax_amount)  tax_gap_amount, -- 税差額
----             taxv.tax_code                                       tax_code        -- 税コード
----      FROM   (
---- Modify 2009.07.13 Ver1.02 end
--        SELECT avta.tax_rate                        tax_rate,    -- 税率
--               avta.vat_tax_id                      vat_tax_id,  -- 税コードID
---- Modify 2009.07.13 Ver1.02 start
----               avta.tax_code                        tax_code,    -- 税コード
------Modify 2009.04.20 Ver1.01 Start
------               DECODE(gt_tax_round_rule,
------                        'UP',      CEIL(ABS(SUM(rctl.taxable_amount) * avta.tax_rate / 100))
------                                     * SIGN(SUM(rctl.taxable_amount)),
------                        'DOWN',    TRUNC(SUM(rctl.taxable_amount) * avta.tax_rate / 100),
------                        'NEAREST', ROUND(SUM(rctl.taxable_amount) * avta.tax_rate / 100, 0)
------                     )                              re_calc_tax_amount,     -- 消費税額(再計算)
----               DECODE(gt_tax_round_rule,
----                        'UP',     CEIL(ABS(SUM(rlli.extended_amount) * avta.tax_rate / 100))
----                                    * SIGN(SUM(rlli.extended_amount)),
----                        'DOWN',    TRUNC(SUM(rlli.extended_amount) * avta.tax_rate / 100),
----                        'NEAREST', ROUND(SUM(rlli.extended_amount) * avta.tax_rate / 100, 0)
----                     )                              re_calc_tax_amount,     -- 消費税額(再計算)  
------Modify 2009.04.20 Ver1.01 End        
----               SUM(rctl.extended_amount)            sum_tax_amount          -- 消費税額合計
--               DECODE(gt_tax_round_rule,
--                        'UP',     CEIL(ABS(SUM(rlli.extended_amount) * avta.tax_rate / 100))
--                                    * SIGN(SUM(rlli.extended_amount)),
--                        'DOWN',    TRUNC(SUM(rlli.extended_amount) * avta.tax_rate / 100),
--                        'NEAREST', ROUND(SUM(rlli.extended_amount) * avta.tax_rate / 100, 0)
--               )
--             - SUM(rctl.extended_amount)            tax_gap_amount, -- 消費税額(再計算) - 消費税額合計
--               avta.tax_code                        tax_code        -- 税コード
---- Modify 2009.07.13 Ver1.02 end
--        FROM   ra_customer_trx_all        rcta,                -- 取引テーブル
--               ra_customer_trx_lines_all  rctl,                -- 取引明細テーブル
----Modify 2009.04.20 Ver1.01 Start
--               ra_customer_trx_lines_all  rlli,                -- 取引明細テーブル（LINE）
----Modify 2009.04.20 Ver1.01 End
--               ar_vat_tax_all_b           avta                 -- 税金マスタ
--        WHERE  rctl.line_type = cv_line_type_tax               -- 明細タイプ
----Modify 2009.04.20 Ver1.01 Start       
----        AND    rctl.taxable_amount IS NOT NULL                 -- 税金対象額
----        AND    rctl.taxable_amount != 0                        -- 税金対象額
--        AND    rlli.extended_amount IS NOT NULL                 -- 明細金額
--        AND    rlli.extended_amount != 0                        -- 明細金額
----Modify 2009.04.20 Ver1.01 End
--        AND    avta.tax_rate IS NOT NULL                       -- 税率
--        AND    avta.tax_rate != 0                              -- 税率
--        AND    rcta.trx_date <= id_cutoff_date                 -- 締日
--        AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                   cv_inv_hold_status_r)       -- 請求書保留ステータス
--        AND    rcta.bill_to_customer_id = iv_cust_acct_id      -- 請求先顧客ID
--        AND    rcta.org_id          = gn_org_id                -- 組織ID
--        AND    rcta.set_of_books_id = gn_set_book_id           -- 会計帳簿ID
--        AND    rcta.customer_trx_id = rctl.customer_trx_id
--        AND    avta.vat_tax_id = rctl.vat_tax_id  
--        AND    avta.validate_flag = 'Y'           
--        AND    gd_process_date BETWEEN NVL(avta.start_date, gd_process_date)
--                                   AND NVL(avta.end_date,   gd_process_date)
----Modify 2009.04.20 Ver1.01 Start   
--        AND    rctl.link_to_cust_trx_line_id = rlli.customer_trx_line_id
----Modify 2009.04.20 Ver1.01 End                                
--        GROUP BY avta.tax_rate,                                -- 税率
--                 avta.vat_tax_id,                              -- 税コードID
--                 avta.tax_code                                 -- 税コード
---- Modify 2009.07.13 Ver1.02 start
----      ) taxv
----      HAVING SUM(taxv.sum_tax_amount - taxv.re_calc_tax_amount) != 0   -- 税差額
----      GROUP BY taxv.tax_rate,
----               taxv.vat_tax_id,
----               taxv.tax_code
--      HAVING SUM(rctl.extended_amount) <> DECODE(gt_tax_round_rule,
--                                             'UP',     CEIL(ABS(SUM(rlli.extended_amount) * avta.tax_rate / 100))
--                                                         * SIGN(SUM(rlli.extended_amount)),
--                                             'DOWN',    TRUNC(SUM(rlli.extended_amount) * avta.tax_rate / 100),
--                                             'NEAREST', ROUND(SUM(rlli.extended_amount) * avta.tax_rate / 100, 0)
--                                          )    -- 税差額
---- Modify 2009.07.13 Ver1.02 end
--      ;
----
--    TYPE l_get_tax_gap_rtype IS TABLE OF get_tax_gap_cur%ROWTYPE INDEX BY PLS_INTEGER;
--    lt_get_tax_gap_tab       l_get_tax_gap_rtype;
----
--    -- 税差額更新対象データ抽出
--    CURSOR upd_inv_tax_gap_cur
--    IS
--      SELECT xxih.ROWID       row_id
--      FROM   xxcfr_invoice_headers xxih
--      WHERE  xxih.cutoff_date = id_cutoff_date            -- 締日
--      AND    xxih.bill_cust_account_id = iv_cust_acct_id  -- 請求先顧客ID
--      AND    xxih.request_id = cn_request_id              -- コンカレント要求ID
--      AND    xxih.org_id = gn_org_id                      -- 組織ID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- 会計帳簿ID
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE upd_inv_tax_gap_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
--    lt_upd_inv_tax_gap_tab    upd_inv_tax_gap_ttype;
----
--    -- *** ローカル・レコード ***
----
--    -- *** ローカル例外 ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ローカル変数の初期化
--    ln_target_cnt     := 0;
--    ln_tax_gap_amount := 0;
--    lv_dict_err_code  := NULL;
--    lt_look_dict_word := NULL;
--    lt_segment3       := NULL;
--    lt_segment4       := NULL;
----
--    --==============================================================
--    --請求書単位の消費税額の再計算処理
--    --==============================================================
--    -- カーソルオープン
--    OPEN get_tax_gap_cur;
----
--    -- データの一括取得
--    FETCH get_tax_gap_cur BULK COLLECT INTO lt_get_tax_gap_tab;
----
--    -- 処理件数のセット
--    ln_target_cnt := lt_get_tax_gap_tab.COUNT;
----
--    -- カーソルクローズ
--    CLOSE get_tax_gap_cur;
----
--    -- 対象データありの場合は税差額を算出
--    IF (ln_target_cnt > 0) THEN
----
--      <<gap_tax_calc_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--        ln_tax_gap_amount := ln_tax_gap_amount + lt_get_tax_gap_tab(ln_loop_cnt).tax_gap_amount;
--      END LOOP gap_tax_calc_loop;
----
--    -- 対象データなしの場合(税差額なし)、移行の処理を行わない
--    ELSE
--      RETURN;
--    END IF;
----
--    --==============================================================
--    --税差額の更新処理
--    --==============================================================
--    -- 税差額が0ではない場合
--    IF (ln_tax_gap_amount != 0) THEN
--      -- 請求ヘッダ情報テーブルロック
--      -- カーソルオープン
--      OPEN upd_inv_tax_gap_cur;
----
--      -- データの一括取得
--      FETCH upd_inv_tax_gap_cur BULK COLLECT INTO lt_upd_inv_tax_gap_tab;
----
--      -- 処理件数のセット
--      ln_upd_target_cnt := lt_upd_inv_tax_gap_tab.COUNT;
----
--      -- カーソルクローズ
--      CLOSE upd_inv_tax_gap_cur;
----
--      -- 対象データが存在する場合レコードを更新する
--      IF (ln_upd_target_cnt > 0) THEN
--        BEGIN
--          <<upd_invoice_header_loop>>
--          FORALL ln_loop_cnt IN 1..ln_upd_target_cnt
--            UPDATE xxcfr_invoice_headers
--            SET    tax_gap_amount        = ln_tax_gap_amount,                         -- 税差額
--                   tax_amount_sum        = tax_amount_sum + ln_tax_gap_amount,        -- 税額合計
--                   inv_amount_includ_tax = inv_amount_includ_tax + ln_tax_gap_amount, -- 税込請求金額合計
--                   last_updated_by       = cn_last_updated_by,                        -- 最終更新者
--                   last_update_date      = cd_last_update_date,                       -- 最終更新日
--                   last_update_login     = cn_last_update_login                       -- 最終更新ログイン
--            WHERE  ROWID = lt_upd_inv_tax_gap_tab(ln_loop_cnt);
----
--        EXCEPTION
--          -- *** OTHERS例外ハンドラ ***
--          WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00017      -- テーブル更新エラー
--                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                           -- 請求ヘッダ情報テーブル
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--        END;
--      END IF;
----
--      --==============================================================
--      --税差額取引作成テーブルの登録データ抽出処理
--      --==============================================================
--      --税差額取引用勘定科目・補助科目抽出
--      BEGIN
--        SELECT inlv.segment3                segment3,
--               inlv.segment4                segment4
--        INTO   lt_segment3,
--               lt_segment4
--        FROM   (
--          SELECT glcc.segment3              segment3,
--                 glcc.segment4              segment4,
--                 SUM(rctl.extended_amount)  amount
--          FROM   ra_customer_trx_all            rcta
--                ,ra_customer_trx_lines_all      rctl
--                ,ra_cust_trx_line_gl_dist_all   rgda
--                ,gl_code_combinations           glcc
--          WHERE  rgda.account_class = cv_account_class_rec       -- 勘定区分
--          AND    rcta.trx_date <= id_cutoff_date                 -- 締日
--          AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                     cv_inv_hold_status_r)       -- 請求書保留ステータス
--          AND    rcta.bill_to_customer_id = iv_cust_acct_id      -- 請求先顧客ID
--          AND    rcta.org_id          = gn_org_id                -- 組織ID
--          AND    rcta.set_of_books_id = gn_set_book_id           -- 会計帳簿ID
--          AND    rcta.customer_trx_id = rctl.customer_trx_id
--          AND    rctl.customer_trx_id = rgda.customer_trx_id
--          AND    rgda.code_combination_id  = glcc.code_combination_id
--          GROUP BY glcc.segment3,
--                   glcc.segment4
--          ORDER BY amount DESC
--        ) inlv
--        WHERE  ROWNUM = 1
--        ;
----
--      EXCEPTION
--        -- *** OTHERS例外ハンドラ ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00302014);    -- 勘定科目・補助科目
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
----
--      --==============================================================
--      --税差額取引作成テーブルの登録処理
--      --==============================================================
--      --税差額取引作成テーブルの登録ループ
--      <<ins_gap_tax_trx_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
----
--        --税差額取引作成テーブル登録処理
--        BEGIN
--          INSERT INTO xxcfr_tax_gap_trx_list(
--            invoice_id,                   -- 一括請求書ID
--            tax_code_id,                  -- 税金コードID
--            cutoff_date,                  -- 締日
--            bill_cust_code,               -- 請求先顧客コード
--            bill_cust_name,               -- 請求先顧客名
--            tax_code,                     -- 税コード
--            segment3,                     -- 勘定科目
--            segment4,                     -- 補助科目
--            tax_gap_amount,               -- 税差額
--            note,                         -- 注釈
--            created_by,                   -- 作成者
--            creation_date,                -- 作成日
--            last_updated_by,              -- 最終更新者
--            last_update_date,             -- 最終更新日
--            last_update_login,            -- 最終更新ログイン
--            request_id,                   -- 要求ID
--            program_application_id,       -- コンカレント・プログラム・アプリケーションID
--            program_id,                   -- コンカレント・プログラムID
--            program_update_date           -- プログラム更新日
--          )VALUES (
--            gt_invoice_id,                                                    -- 一括請求書ID
--            lt_get_tax_gap_tab(ln_loop_cnt).vat_tax_id,                       -- 税金コードID
--            id_cutoff_date,                                                   -- 締日
--            iv_cust_acct_code,                                                -- 請求先顧客コード
--            iv_cust_acct_name,                                                -- 請求先顧客名
--            lt_get_tax_gap_tab(ln_loop_cnt).tax_code,                         -- 税コード
--            lt_segment3,                                                      -- 勘定科目
--            lt_segment4,                                                      -- 補助科目
--            lt_get_tax_gap_tab(ln_loop_cnt).tax_gap_amount,                   -- 税差額
--            iv_cust_acct_name || '_' || TO_CHAR(id_cutoff_date, 'YYYY/MM/DD'),-- 注釈
--            cn_created_by,                                                    -- 作成者
--            cd_creation_date,                                                 -- 作成日
--            cn_last_updated_by,                                               -- 最終更新者
--            cd_last_update_date,                                              -- 最終更新日
--            cn_last_update_login,                                             -- 最終更新ログイン
--            cn_request_id,                                                    -- 要求ID
--            cn_program_application_id,                                        -- アプリケーションID
--            cn_program_id,                                                    -- プログラムID
--            cd_program_update_date                                            -- プログラム更新日
--          );
----
--        EXCEPTION
--        -- *** OTHERS例外ハンドラ ***
--          WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                    iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                   ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
--                                   ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                   ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxgt))
--                                                                             -- 税差額取引作成テーブル
--                                 ,1
--                                 ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--      END LOOP ins_gap_tax_trx_loop;
----
--    END IF;
----
--  EXCEPTION
--    -- *** テーブルロックエラーハンドラ ***
--    WHEN lock_expt THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
--                             ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                       -- 請求ヘッダ情報テーブル
--                           ,1
--                           ,5000);
--      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END update_tax_gap;
-- Modify 2009.09.29 Ver1.06 End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date            IN  VARCHAR2,     -- 締日
    iv_bill_acct_code         IN  VARCHAR2,     -- 請求先顧客コード
    iv_batch_on_judge_type    IN  VARCHAR2,     -- 夜間手動判断区分
    ov_errbuf                 OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_target_trx_cnt   NUMBER; --請求対象取引データ件数
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
    -- <カーソル名>
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
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    gv_conc_status := cv_status_normal;
--
-- Modify 2009.12.11 Ver1.07 start
    UPDATE ra_customer_trx_all update_tab
    SET 
    update_tab.attribute7 = 'INVALID',
    update_tab.last_update_date = cd_last_update_date,
    update_tab.last_updated_by = cn_last_updated_by,
    update_tab.last_update_login = cn_last_update_login,
    update_tab.request_id = cn_request_id,
    update_tab.program_application_id = cn_program_application_id,
    update_tab.program_id = cn_program_id,
    update_tab.program_update_date = cd_program_update_date
    WHERE update_tab.customer_trx_id IN
    (
    SELECT
    rcta.customer_trx_id
    FROM
    ra_customer_trx_all rcta,
    xxcmm_cust_accounts xxca
    WHERE rcta.bill_to_customer_id = xxca.customer_id
    AND xxca.card_company_div = '1'
    AND EXISTS (SELECT 'X'
                FROM 
                ra_cust_trx_line_gl_dist_all radist,
                gl_code_combinations gcc
                WHERE gcc.segment3 = '14903'
                AND gcc.code_combination_id = radist.code_combination_id
                AND radist.customer_trx_id = rcta.customer_trx_id)
    AND rcta.attribute7 = 'OPEN'
    );
-- Modify 2009.12.11 Ver1.07 end
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_target_date          -- 締日
      ,iv_bill_acct_code       -- 請求先顧客コード
      ,iv_batch_on_judge_type  -- 夜間手動判断区分
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- 請求情報引渡テーブル登録処理 (A-2)
    -- =====================================================
    ins_inv_info_trans(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --夜間手動判断区分の判断
    IF (iv_batch_on_judge_type = cv_judge_type_batch) THEN
      -- =====================================================
      -- 対象請求先顧客取得処理(夜間) (A-3)
      -- =====================================================
      ins_target_bill_acct_n(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    ELSE 
--
      -- =====================================================
      -- 対象請求先顧客取得処理(手動) (A-4)
      -- =====================================================
      ins_target_bill_acct_o(
         iv_bill_acct_code     -- 請求先顧客コード
        ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- =====================================================
    -- 請求締対象顧客情報抽出処理 (A-5)
    -- =====================================================
    get_target_bill_acct(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      --処理を終了する
      RETURN;
    END IF;
--
    --ループ
    <<for_loop>>
    FOR ln_loop_cnt IN gt_get_acct_code_tab.FIRST..gt_get_acct_code_tab.LAST LOOP
      --変数初期化
      ln_target_trx_cnt := 0;
--
      --夜間手動判断区分の判断
      IF (iv_batch_on_judge_type != cv_judge_type_batch) THEN
        -- =====================================================
        -- 前回処理データ削除処理 (A-6)
        -- =====================================================
        delete_last_data(
           gt_get_acct_code_tab(ln_loop_cnt)     -- 請求先顧客コード
          ,gt_get_cutoff_date_tab(ln_loop_cnt)   -- 締日
          ,lv_errbuf                             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                            -- リターン・コード             --# 固定 #
          ,lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- =====================================================
      -- 請求対象取引データ取得処理 (A-7)
      -- =====================================================
      get_bill_info(
         gt_get_cust_acct_id_tab(ln_loop_cnt),   -- 請求先顧客ID
         gt_get_cutoff_date_tab(ln_loop_cnt),    -- 締日
         ln_target_trx_cnt,                      -- 対象取引件数
         lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
         lv_retcode,                             -- リターン・コード             --# 固定 #
         lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      IF (ln_target_trx_cnt > 0) THEN
        -- =====================================================
        -- 請求ヘッダ情報登録処理 (A-8)
        -- =====================================================
        ins_invoice_header(
           gt_get_acct_code_tab(ln_loop_cnt),          -- 請求先顧客コード
           gt_get_cutoff_date_tab(ln_loop_cnt),        -- 締日
           gt_get_cust_name_tab(ln_loop_cnt),          -- 請求先顧客名
           gt_get_cust_acct_id_tab(ln_loop_cnt),       -- 請求先顧客ID
           gt_get_cust_acct_site_id_tab(ln_loop_cnt),  -- 請求先顧客所在地ID
           gt_get_term_name_tab(ln_loop_cnt),          -- 支払条件
           gt_get_term_id_tab(ln_loop_cnt),            -- 支払条件ID
           gt_get_tax_div_tab(ln_loop_cnt),            -- 消費税区分
           lv_errbuf,                                  -- エラー・メッセージ           --# 固定 #
           lv_retcode,                                 -- リターン・コード             --# 固定 #
           lv_errmsg                                   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_warn)  THEN
          --(警告件数カウントアップ)
          gn_error_cnt := gn_error_cnt + 1;
          --警告フラグをセット
          gv_conc_status := cv_status_warn;
        ELSIF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
-- Modify 2009.09.29 Ver1.06 start
--        --請求ヘッダ情報テーブルに登録したかつ、
--        --消費税区分が外税の場合
--        IF (gt_invoice_id IS NOT NULL) AND
--           (gt_get_tax_div_tab(ln_loop_cnt) = cv_tax_div_outtax)
--        THEN
--          -- =====================================================
--          -- 税差額算出処理 (A-9)
--          -- =====================================================
--          update_tax_gap(
--             gt_get_acct_code_tab(ln_loop_cnt),      -- 請求先顧客コード
--             gt_get_cutoff_date_tab(ln_loop_cnt),    -- 締日
--             gt_get_cust_name_tab(ln_loop_cnt),      -- 請求先顧客名
--             gt_get_cust_acct_id_tab(ln_loop_cnt),   -- 請求先顧客ID
--             lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
--             lv_retcode,                             -- リターン・コード             --# 固定 #
--             lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
--          );
--          IF (lv_retcode = cv_status_error) THEN
--            --(エラー処理)
--            RAISE global_process_expt;
--          END IF;
--        END IF;
-- Modify 2009.09.29 Ver1.06 End
--
      --請求対象取引データが存在しなかった場合
      ELSE
        -- スキップ件数をカウント
        gn_warn_cnt := gn_warn_cnt + 1;
--
      END IF;
    END LOOP for_loop;
--
    -- 警告フラグが警告となっている場合
    IF (gv_conc_status = cv_status_warn) THEN
      -- リターン・コードに警告をセット
      ov_retcode := cv_status_warn;
    END IF;
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
    errbuf                  OUT     VARCHAR2,         -- エラー・メッセージ
    retcode                 OUT     VARCHAR2,         -- エラーコード
    iv_target_date          IN      VARCHAR2,         -- 締日
    iv_bill_acct_code       IN      VARCHAR2,         -- 請求先顧客コード
    iv_batch_on_judge_type  IN      VARCHAR2          -- 夜間手動判断区分
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- メッセージコード
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバックメッセージ
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
       iv_target_date            -- 締日
      ,iv_bill_acct_code         -- 請求先顧客コード
      ,iv_batch_on_judge_type    -- 夜間手動判断区分
      ,lv_errbuf                 -- エラー・メッセージ           
      ,lv_retcode                -- リターン・コード             
      ,lv_errmsg                 -- ユーザー・エラー・メッセージ 
    );
--
--###########################  固定部 START   #####################################################
--
    --エラーメッセージが設定されている場合、エラー出力
    IF (lv_errmsg IS NOT NULL) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --
      fnd_file.put_line(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了ステータスが異常終了の場合
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFR003A02C;
/