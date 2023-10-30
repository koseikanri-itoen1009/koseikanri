CREATE OR REPLACE PACKAGE BODY XXCFR003A24C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2023. All rights reserved.
 *
 * Package Name     : XXCFR003A24C(body)
 * Description      : 請求明細請求先顧客反映
 * MD.050           : MD050_CFR_003_A24_請求明細請求先顧客反映
 * MD.070           : MD050_CFR_003_A24_請求明細請求先顧客反映
 * Version          : 1.01
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    p 初期処理(請求ヘッダ作成)                (A-1)
 *  ins_target_bill_acct_n  p 対象請求先顧客取得処理                  (A-2)
 *  get_target_bill_acct    p 請求締対象顧客情報抽出処理              (A-3)
 *  ins_invoice_header      p 請求ヘッダ情報登録処理                  (A-4)
 *  get_update_target_line  p 請求明細更新対象取得処理                (A-5)
 *  update_invoice_lines_id p 請求ID更新処理 請求明細情報テーブル     (A-6)
 *  get_update_target_bill  p 請求更新対象取得処理                    (A-7)
 *  update_invoice_lines    p 請求金額更新処理 請求明細情報テーブル   (A-8)
 *  update_bill_amount      p 請求金額更新処理 請求ヘッダ情報テーブル (A-9)
 *
 *  submain                 p メイン処理プロシージャ
 *  main                    p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023/10/20    1.00  SCSK 赤地 学     初回作成 [E_本稼動_19546] 請求書の消費税額訂正
 *  2023/10/27    1.01  SCSK 赤地 学     [E_本稼動_19546] 請求書の消費税額訂正 修正
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
  gn_ins_cnt       NUMBER;                    -- バックアップ件数
  gn_target_header_cnt    NUMBER;             -- 対象件数(請求ヘッダ単位)
  gn_target_line_cnt      NUMBER;             -- 対象件数(請求明細単位)
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A24C'; -- パッケージ名
  
  -- プロファイルオプション
  ct_prof_name_itoen_name  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_GENERAL_INVOICE_ITOEN_NAME';   -- 汎用請求書取引先名
  cv_org_id                CONSTANT VARCHAR2(6)  := 'ORG_ID';                   -- 組織ID
  cv_set_of_books_id       CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';         -- 会計帳簿ID
  cv_invoice_h_parallel_count CONSTANT VARCHAR2(36)
                                      := 'XXCFR1_INVOICE_HEADER_PARALLEL_COUNT';  -- XXCFR:請求ヘッダパラレル実行数
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
  cv_msg_cfr_00077  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00077'; --一意制約エラーメッセージ
  cv_msg_cfr_00132  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00132'; --売掛コード1(請求先)エラーメッセージ(EDI請求)
  cv_msg_cfr_00133  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00133'; --売掛コード1(請求先)エラーメッセージ(伊藤園標準)
  cv_msg_cfr_00134  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00134'; --請求書出力形式定義無しエラーメッセージ(0件)
  cv_msg_cfr_00135  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00135'; --請求書出力形式定義無しエラーメッセージ
  cv_msg_cfr_00146  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00146'; --更新件数メッセージ
  cv_msg_cfr_00018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00018'; --メッセージタイトル(ヘッダ部)
  cv_msg_cfr_00019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00019'; --メッセージタイトル(明細部)
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
  cv_dict_cfr_00303014  CONSTANT VARCHAR2(20) := 'CFR003A03014'; -- 処理対象コンカレント要求ID
--
  -- メッセージトークン
  cv_tkn_prof_name  CONSTANT VARCHAR2(30)  := 'PROF_NAME';       -- プロファイルオプション名
  cv_tkn_func_name  CONSTANT VARCHAR2(30)  := 'FUNC_NAME';       -- ファンクション名
  cv_tkn_table      CONSTANT VARCHAR2(30)  := 'TABLE';           -- テーブル名
  cv_tkn_cust_code  CONSTANT VARCHAR2(30)  := 'CUST_CODE';       -- 顧客コード
  cv_tkn_cust_name  CONSTANT VARCHAR2(30)  := 'CUST_NAME';       -- 顧客名
  cv_tkn_column     CONSTANT VARCHAR2(30)  := 'COLUMN';          -- カラム名
  cv_tkn_data       CONSTANT VARCHAR2(30)  := 'DATA';            -- データ
  cv_tkn_cut_date   CONSTANT VARCHAR2(30)  := 'CUTOFF_DATE';     -- 締日
  cv_tkn_lookup_type        CONSTANT VARCHAR2(30)  := 'LOOKUP_TYPE';       -- 参照タイプ
  cv_tkn_lookup_code        CONSTANT VARCHAR2(30)  := 'LOOKUP_CODE';       -- 参照コード
  cv_tkn_bill_invoice_type  CONSTANT VARCHAR2(30)  := 'BILL_INVOICE_TYPE'; -- 請求書出力形式
--
  -- 使用DB名
  cv_table_xiit       CONSTANT VARCHAR2(100) := 'XXCFR_INV_INFO_TRANSFER';     -- 請求情報引渡テーブル
  cv_table_xtcl       CONSTANT VARCHAR2(100) := 'XXCFR_INV_TARGET_CUST_LIST';  -- 請求締対象顧客ワークテーブル
  cv_table_xxih       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_HEADERS';       -- 請求ヘッダ情報テーブル
  cv_table_xxil       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_LINES';         -- 請求明細情報テーブル
  cv_table_xxgt       CONSTANT VARCHAR2(100) := 'XXCFR_TAX_GAP_TRX_LIST';      -- 税差額取引作成テーブル
  cv_table_xwil       CONSTANT VARCHAR2(100) := 'XXCFR_WK_INVOICE_LINES';      -- 請求明細情報ワークテーブル
--
  -- 参照タイプ
  cv_look_type_ar_cd  CONSTANT VARCHAR2(100) := 'XXCMM_INVOICE_GRP_CODE';     -- 売掛コード1(請求書)
  cv_inv_output_form_type  CONSTANT VARCHAR2(100) := 'XXCMM_CUST_SEKYUSYO_SHUT_KSK';  -- 請求書出力形式
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
  cv_inv_prt_type       CONSTANT VARCHAR2(1)  := '3';         -- 請求書出力区分 3(EDI)
  cv_delete_flag_yes    CONSTANT VARCHAR2(1)  := 'Y';         -- 前回処理データ削除フラグ(Y)
  cv_delete_flag_no     CONSTANT VARCHAR2(1)  := 'N';         -- 前回処理データ削除フラグ(N)
  cv_inv_creation_flag  CONSTANT VARCHAR2(1)  := 'Y';         -- 請求作成対象フラグ(Y)
  cv_tax_rounding_rule_down        CONSTANT VARCHAR2(10)    :=  'DOWN';    -- 切り捨て
  cv_output_format_1               CONSTANT VARCHAR2(1)     :=   '1';      -- 請求書出力形式（伊藤園標準）
  cv_output_format_4               CONSTANT VARCHAR2(1)     :=   '4';      -- 請求書出力形式（業者委託）
  cv_output_format_5               CONSTANT VARCHAR2(1)     :=   '5';      -- 請求書出力形式（発行なし）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
    TYPE inv_output_form_rtype IS RECORD(
      inv_output_form_code            fnd_lookup_values_vl.lookup_code%type     -- 請求書出力形式
     ,inv_output_form_name            fnd_lookup_values_vl.meaning%type         -- 請求書出力形式名称
    );
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
    TYPE inv_output_form_ttype        IS TABLE OF inv_output_form_rtype
                                                  INDEX BY fnd_lookup_values.lookup_code%TYPE;
    TYPE inv_output_form_sub_ttype    IS TABLE OF inv_output_form_rtype
                                                  INDEX BY BINARY_INTEGER;
    gt_get_acct_code_tab            get_acct_code_ttype;
    gt_get_cutoff_date_tab          get_cutoff_date_ttype;
    gt_get_cust_name_tab            get_cust_name_ttype;
    gt_get_cust_acct_id_tab         get_cust_acct_id_ttype;
    gt_get_cust_acct_site_id_tab    get_cust_acct_site_id_ttype;
    gt_get_term_name_tab            get_term_name_ttype;
    gt_get_term_id_tab              get_term_id_ttype;
    gt_get_tax_div_tab              get_tax_div_ttype;
    gt_get_bill_pub_cycle_tab       get_bill_pub_cycle_ttype;
    gt_inv_output_form_tab          inv_output_form_ttype;
    gt_inv_output_form_sub_tab      inv_output_form_sub_ttype;
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
  gt_target_request_id       xxcfr_inv_info_transfer.target_request_id%TYPE;    -- 処理対象コンカレント要求ID
  gv_party_ref_type          VARCHAR2(50);                                         -- パーティ関連タイプ(与信関連)
  gv_party_rev_code          VARCHAR2(50);                                         -- パーティ関連(売掛管理先)
  gt_bill_payment_term_id    hz_cust_site_uses_all.payment_term_id%TYPE;           -- 支払条件1
  gt_bill_payment_term2      hz_cust_site_uses_all.attribute2%TYPE;                -- 支払条件2
  gt_bill_payment_term3      hz_cust_site_uses_all.attribute3%TYPE;                -- 支払条件3
  gn_parallel_count          NUMBER DEFAULT 0;                                     -- 請求ヘッダパラレル実行数

  TYPE get_inv_id_ttype          IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
                                                  INDEX BY PLS_INTEGER;
  TYPE get_amt_no_tax_ttype      IS TABLE OF xxcfr_invoice_headers.inv_amount_no_tax%TYPE
                                                  INDEX BY PLS_INTEGER;
  TYPE get_tax_amt_sum_ttype     IS TABLE OF xxcfr_invoice_headers.tax_amount_sum%TYPE
                                                  INDEX BY PLS_INTEGER;

  gt_get_inv_id_tab          get_inv_id_ttype;
  TYPE get_tax_gap_amount_ttype    IS TABLE OF xxcfr_invoice_headers.tax_gap_amount%TYPE      INDEX BY PLS_INTEGER;
  TYPE get_inv_gap_amount_ttype    IS TABLE OF xxcfr_invoice_headers.inv_gap_amount%TYPE      INDEX BY PLS_INTEGER;
  TYPE get_invoice_tax_div_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_tax_div%TYPE     INDEX BY PLS_INTEGER;
  TYPE get_output_format_ttype     IS TABLE OF xxcfr_invoice_headers.output_format%TYPE       INDEX BY PLS_INTEGER;
--
  gt_invoice_tax_div_tab    get_invoice_tax_div_ttype;       -- 請求書消費税積上げ計算方式
  gt_output_format_tab      get_output_format_ttype;         -- 請求書出力形式
  gt_tax_gap_amount_tab     get_tax_gap_amount_ttype;        -- 税差額
  gt_tax_sum1_tab           get_tax_amt_sum_ttype;           -- 税額合計１
  gt_tax_sum2_tab           get_tax_amt_sum_ttype;           -- 税額合計２
  gt_inv_gap_amount_tab     get_inv_gap_amount_ttype;        -- 本体差額
  gt_no_tax_sum1_tab        get_amt_no_tax_ttype;            -- 税抜合計１
  gt_no_tax_sum2_tab        get_amt_no_tax_ttype;            -- 税抜合計２
  gt_tax_div_tab            get_tax_div_ttype;               -- 消費税区分
  cv_inv_type_no        CONSTANT VARCHAR2(2)  := '00';        -- 請求区分(通常)
  cv_inv_type_re        CONSTANT VARCHAR2(2)  := '01';        -- 請求区分(再請求)
  cv_tax_div_inslip     CONSTANT VARCHAR2(1)  := '2';         -- 消費税区分(内税(伝票))
  cv_tax_div_inunit     CONSTANT VARCHAR2(1)  := '3';         -- 消費税区分(内税(単価))
  cv_tax_div_notax      CONSTANT VARCHAR2(1)  := '4';         -- 消費税区分(非課税)
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)  := 'XXCCP';
  cv_tkn_count          CONSTANT VARCHAR2(30) := 'COUNT';           -- 件数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date          IN VARCHAR2,      -- 締日
    iv_bill_acct_code       IN VARCHAR2,      -- 請求先顧客コード
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
    --入力パラメータ日付型変換処理
    --==============================================================
--
    IF (iv_target_date IS NOT NULL) THEN
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
    --==============================================================
    -- 請求書出力形式
    --==============================================================
    BEGIN
      SELECT
        flv.lookup_code      lookup_code  -- 請求書出力形式
       ,flv.meaning          line_type    -- 請求書出力形式名称
      BULK COLLECT INTO
        gt_inv_output_form_sub_tab        -- 請求書出力形式
      FROM
        fnd_lookup_values    flv
      WHERE
          flv.lookup_type        = cv_inv_output_form_type
      AND flv.language           = USERENV( 'LANG' )
      AND flv.enabled_flag       = 'Y'
      AND gd_process_date  BETWEEN NVL( flv.start_date_active , gd_process_date )
                               AND NVL( flv.end_date_active , gd_process_date )
      ;
--
      IF( gt_inv_output_form_sub_tab.COUNT = 0) THEN
        RAISE NO_DATA_FOUND;
      END IF; 
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cfr           -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00134         -- 請求書出力形式
                             ,iv_token_name1  => cv_tkn_lookup_type       -- トークン'lookup_type'
                             ,iv_token_value1 => cv_inv_output_form_type) -- 参照タイプ
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg || cv_msg_part || SQLERRM;
        RAISE global_api_expt;
    END;
--
    FOR i IN 1..gt_inv_output_form_sub_tab.COUNT LOOP
      gt_inv_output_form_tab( gt_inv_output_form_sub_tab( i ).inv_output_form_code ) := gt_inv_output_form_sub_tab( i );
    END LOOP;
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
    -- *** 変換例外ハンドラ ***
    WHEN VALUE_ERROR THEN
      ov_errmsg  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
   * Procedure Name   : ins_target_bill_acct_n
   * Description      : 対象請求先顧客取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE ins_target_bill_acct_n(
    iv_bill_acct_code       IN  VARCHAR2,     -- 請求先顧客コード
    iv_bill_acct_id         IN  VARCHAR2,     -- 請求先顧客ID
    iv_bill_acct_name       IN  VARCHAR2,     -- 請求先顧客名称
    id_cutoff_date          IN  DATE,         -- 振替元請求先の締日
    iv_term_name            IN  VARCHAR2,     -- 振替元請求先の支払条件
    in_term_id              IN  NUMBER,       -- 振替元請求先の支払条件ID
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
    ln_bill_cust_acct_site_id NUMBER;      -- 請求先顧客所在地ID
    lv_tax_div                VARCHAR2(1); -- 消費税区分
    lv_bill_pub_cycle         VARCHAR2(1); -- 請求書発行サイクル
    
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
    -- 振替先請求顧客の情報を取得する
    BEGIN
        SELECT hzsa.cust_acct_site_id    AS bill_cust_acct_site_id  -- 請求先顧客所在地ID
              ,xxca.tax_div              AS tax_div                 -- 消費税区分
              ,hzsu.attribute8           AS bill_pub_cycle          -- 請求書発行サイクル
        INTO   ln_bill_cust_acct_site_id
              ,lv_tax_div
              ,lv_bill_pub_cycle
        FROM   hz_cust_site_uses_all     hzsu              -- 顧客使用目的
              ,hz_cust_acct_sites_all    hzsa              -- 顧客所在地
              ,hz_cust_accounts          hzca              -- 顧客マスタ
              ,xxcmm_cust_accounts       xxca              -- 顧客追加情報
              ,hz_customer_profiles      hzcp              -- 顧客プロファイル
        WHERE  
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND    hzsu.site_use_code = 'BILL_TO'                     -- 使用目的コード(請求先)
            AND    hzsu.status = 'A'                                  -- 使用目的ステータス = 'A'
            AND    hzcp.cons_inv_flag = 'Y'                           -- 一括請求書式使用可能FLAG('Y')
            AND    hzsa.org_id = gn_org_id                            -- 組織ID
            AND    hzsu.org_id = gn_org_id                            -- 組織ID
            AND    hzca.cust_account_id = iv_bill_acct_id
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_bill_cust_acct_site_id := NULL;
        lv_tax_div := NULL;
        lv_bill_pub_cycle := NULL;
    END;
--
    -- 対象データが存在時,請求締対象顧客ワークテーブル登録
    BEGIN
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
      ) VALUES (
         iv_bill_acct_code
        ,id_cutoff_date
        ,iv_bill_acct_name
        ,iv_bill_acct_id
        ,ln_bill_cust_acct_site_id
        ,iv_term_name
        ,in_term_id
        ,lv_tax_div
        ,lv_bill_pub_cycle
      )
      ;
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
   * Procedure Name   : get_target_bill_acct
   * Description      : 請求締対象顧客情報抽出処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_target_bill_acct(
    iv_bill_acct_code       IN  VARCHAR2,     -- 請求先顧客コード
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
      WHERE  bill_cust_code = iv_bill_acct_code
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
  /**********************************************************************************
   * Procedure Name   : ins_invoice_header
   * Description      : 請求ヘッダ情報登録処理(A-4)
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
    iv_bill_acct_code       IN  VARCHAR2,     -- 請求先顧客コード(コンカレントパラメータ)
    ov_invoice_id           OUT NUMBER,       -- 一括請求書ID
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
    ln_target_inv_cnt   NUMBER;                             -- 対象請求件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    acct_info_required_expt  EXCEPTION;      -- 顧客情報必須エラー
    uniq_expt                EXCEPTION;      -- 一意制約エラー
--
    PRAGMA EXCEPTION_INIT(uniq_expt, -1);    -- 一意制約エラー
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
    ln_target_inv_cnt := 0;
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
    gt_bill_payment_term_id  := NULL;      -- 支払条件1
    gt_bill_payment_term2    := NULL;      -- 支払条件2
    gt_bill_payment_term3    := NULL;      -- 支払条件3
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
            ,xxhv.bill_payment_term_id                bill_payment_term_id    -- 支払条件1
            ,xxhv.bill_payment_term2                  bill_payment_term2      -- 支払条件2
            ,xxhv.bill_payment_term3                  bill_payment_term3      -- 支払条件3
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
        AND   hsua_bill.status = 'A'
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
        IF (gt_invoice_output_form = cv_inv_prt_type ) THEN  -- '3'(EDI)
          -- EDI請求の場合
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr
                               ,iv_name         => cv_msg_cfr_00132
                               ,iv_token_name1  => cv_tkn_cust_code
                               ,iv_token_value1 => iv_cust_acct_code
                               ,iv_token_name2  => cv_tkn_cust_name
                               ,iv_token_value2 => iv_cust_acct_name)
                               ,1
                               ,5000);
        ELSE
          -- EDI請求以外の場合
          IF ( gt_inv_output_form_tab.EXISTS( gt_invoice_output_form )) THEN
            -- 請求書出力形式が登録されている場合
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( 
                                  iv_application  => cv_msg_kbn_cfr
                                 ,iv_name         => cv_msg_cfr_00133
                                 ,iv_token_name1  => cv_tkn_cust_code
                                 ,iv_token_value1 => iv_cust_acct_code
                                 ,iv_token_name2  => cv_tkn_cust_name
                                 ,iv_token_value2 => iv_cust_acct_name
                                 ,iv_token_name3  => cv_tkn_bill_invoice_type
                                 ,iv_token_value3 => gt_inv_output_form_tab( gt_invoice_output_form ).inv_output_form_name)
                                 ,1
                                 ,5000);
          ELSE
            -- 請求書出力形式が登録されていない場合
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr           -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00135         -- 請求書出力形式
                                 ,iv_token_name1  => cv_tkn_lookup_type       -- トークン'lookup_type'
                                 ,iv_token_value1 => cv_inv_output_form_type  -- 参照タイプ
                                 ,iv_token_name2  => cv_tkn_lookup_code       -- トークン'lookup_code'
                                 ,iv_token_value2 => gt_invoice_output_form)  -- 参照コード
                                 ,1
                                 ,5000);
          END IF;
        END IF;
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := cv_status_warn;
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
                     ra_terms_vl             rv11           -- 支払条件マスタ
              WHERE  rv11.term_id              = gt_bill_payment_term_id
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
                     ra_terms_vl             rv12           -- 支払条件マスタ
              WHERE  rv12.term_id              = gt_bill_payment_term_id
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
                     ra_terms_vl             rv21           -- 支払条件マスタ
              WHERE  rv21.term_id              = gt_bill_payment_term2
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
                     ra_terms_vl             rv22           -- 支払条件マスタ
              WHERE  rv22.term_id              = gt_bill_payment_term2
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
                     ra_terms_vl             rv31           -- 支払条件マスタ
              WHERE  rv31.term_id              = gt_bill_payment_term3
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
                     ra_terms_vl             rv32           -- 支払条件マスタ
              WHERE  rv32.term_id              = gt_bill_payment_term3
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
    -- 一括請求書ID採番
    ov_invoice_id := xxcfr_invoice_headers_s1.NEXTVAL;
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
        program_update_date,               -- プログラム更新日
        parallel_type                      -- パラレル実行区分
      ) VALUES (
--        xxcfr_invoice_headers_s1.NEXTVAL,                             -- 一括請求書ID
        ov_invoice_id,
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
        gt_target_request_id,                                         -- 要求ID
        cn_program_application_id,                                    -- コンカレント・プログラム・アプリケーションID
        cn_program_id,                                                -- コンカレント・プログラムID
        cd_program_update_date,                                       -- プログラム更新日
        gn_parallel_count                                             -- パラレル実行区分
      )
      RETURNING invoice_id INTO gt_invoice_id;                        -- 一括請求書ID
--
    EXCEPTION
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
  /**********************************************************************************
   * Procedure Name   : update_invoice_lines_id
   * Description      : 請求ID更新処理 請求明細情報テーブル(A-6)
   ***********************************************************************************/
  PROCEDURE update_invoice_lines_id(
    in_xih_invoice_id         IN  NUMBER,       -- 請求ヘッダ.請求書ID
    in_xil_invoice_id         IN  NUMBER,       -- 請求明細.請求書ID
    in_invoice_detail_num     IN  NUMBER,       -- 一括請求書明細No
    ov_errbuf                 OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_invoice_lines_id'; -- プログラム名
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
    -- 請求明細情報テーブル請求金額更新
    BEGIN
--
      UPDATE  xxcfr_invoice_lines  xxil   -- 請求明細情報テーブル
      SET     xxil.invoice_id         = in_xih_invoice_id         -- 更新する一括請求書ID
             ,xxil.invoice_detail_num = ( SELECT NVL(MAX(xxil.invoice_detail_num),0) + 1
                                          FROM   xxcfr_invoice_lines xxil
                                          WHERE  xxil.invoice_id = in_xih_invoice_id ) -- インボイス明細番号の最大値+1
             ,invoice_id_bef            = in_xil_invoice_id          -- 一括請求書ID(最新請求先適用前)
             ,invoice_detail_num_bef    = in_invoice_detail_num      -- 一括請求書明細No(最新請求先適用前)
      WHERE   xxil.invoice_id = in_xil_invoice_id                    -- 一括請求書ID
      AND     xxil.invoice_detail_num = in_invoice_detail_num        -- 一括請求書明細No
      ;
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- データ更新エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil)) -- 請求明細情報テーブル
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_invoice_lines_id;
--
  /**********************************************************************************
   * Procedure Name   : get_update_target_line
   * Description      : 請求明細更新対象取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_update_target_line(
    iv_target_date          IN VARCHAR2,      -- 締日
    iv_bill_acct_code       IN VARCHAR2,      -- 請求先顧客コード
--    ov_target_trx_cnt       OUT NUMBER,       -- 対象取引件数
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_update_target_line'; -- プログラム名
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
    ln_xih_invoice_id    NUMBER;                       -- 請求ヘッダ.一括請求書ID
    ln_target_trx_cnt    NUMBER;                       -- 請求対象取引データ件数
    lv_bill_acct_code    VARCHAR2(30);                      -- 
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
--
--    -- *** ローカル・カーソル ***
    --請求明細情報データロックカーソル
    CURSOR lock_target_inv_lines_cur
    IS
      SELECT  xxil.invoice_id         AS invoice_id    -- 請求書ID
      FROM    xxcfr_invoice_lines xxil              -- 請求明細情報テーブル
      WHERE   xxil.invoice_id IN
      ( SELECT xxih.invoice_id
        FROM xxcfr_invoice_headers xxih
        WHERE xxih.request_id = gt_target_request_id )
      FOR UPDATE NOWAIT
      ;
    --
    --対象請求明細情報取得
    CURSOR get_target_inv_cur
    IS
      SELECT  xxil.invoice_id                     AS xil_invoice_id              -- 請求明細.一括請求書ID
             ,xxil.invoice_detail_num             AS xil_invoice_detail_num      -- 請求明細.一括請求書明細No
             ,ship_cust_info.bill_account_id      AS mst_bill_account_id         -- 顧客階層.請求先顧客ID
             ,ship_cust_info.bill_account_number  AS mst_bill_account_number     -- 顧客階層.請求先顧客コード
             ,ship_cust_info.bill_account_name    AS mst_bill_account_name       -- 顧客階層.請求先顧客名称
             ,xxih.cutoff_date                    AS xih_cutoff_date             -- 請求ヘッダ.締日
             ,xxih.term_name                      AS xih_term_name               -- 請求ヘッダ.支払条件
             ,xxih.term_id                        AS xih_term_id                 -- 請求ヘッダ.支払条件ID
      FROM    xxcfr_invoice_headers xxih                                         -- 請求ヘッダ情報テーブル
             ,xxcfr_invoice_lines   xxil                                         -- 請求明細情報テーブル
             ,xxcfr_cust_hierarchy_v  ship_cust_info                             -- 顧客階層ビュー
      WHERE   xxih.request_id = gt_target_request_id                             -- コンカレント要求ID
      AND     xxil.invoice_id = xxih.invoice_id
      AND     ship_cust_info.ship_account_number = xxil.ship_cust_code
      AND     xxih.bill_cust_account_id != ship_cust_info.bill_account_id
      AND     xxih.invoice_output_form  != cv_inv_prt_type                       -- 振替元請求先請求書出力形式(EDI)は除く
      ;
    --
    --請求ヘッダ情報取得
    CURSOR get_header_inf_cur( p_bill_cust_account_id number
                              ,p_cutoff_date date )
    IS
      SELECT  xxih.invoice_id                     AS xih_invoice_id             -- 請求明細.一括請求書ID
      FROM    xxcfr_invoice_headers xxih
      WHERE   xxih.cutoff_date = p_cutoff_date
      AND     xxih.bill_cust_account_id  = p_bill_cust_account_id
      ;
--
    -- *** ローカル・レコード ***
--
    get_header_inf_rec  get_header_inf_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数の初期化
--    ov_target_trx_cnt := 0;
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
    --==============================================================
    --請求情報引渡テーブルデータ抽出処理
    --==============================================================
    -- 処理対象コンカレント要求ID抽出
--
    BEGIN
      SELECT xiit.target_request_id  target_request_id
      INTO   gt_target_request_id
      FROM   xxcfr_inv_info_transfer xiit
      WHERE  xiit.set_of_books_id = gn_set_book_id
      AND    xiit.org_id = gn_org_id
      ;
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00303014);    -- 処理対象コンカレント要求ID
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
    --==============================================================
    --請求明細テーブルロック情報取得処理
    --==============================================================
    BEGIN
      OPEN lock_target_inv_lines_cur;
--
      CLOSE lock_target_inv_lines_cur;
--
    EXCEPTION
      -- *** テーブルロックエラーハンドラ ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))  -- 請求明細情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_target_date          -- 締日
      ,lv_bill_acct_code       -- 請求先顧客コード
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --請求明細情報更新処理
    --==============================================================
    --
    <<edit_loop>>
    FOR get_target_inv_rec IN get_target_inv_cur LOOP
--
      OPEN  get_header_inf_cur(get_target_inv_rec.mst_bill_account_id ,get_target_inv_rec.xih_cutoff_date);
      FETCH get_header_inf_cur INTO get_header_inf_rec;
--
      -- 請求ヘッダ.一括請求書ID
      ln_xih_invoice_id := get_header_inf_rec.xih_invoice_id;
--
      IF ( iv_bill_acct_code IS NULL ) THEN
        lv_bill_acct_code := get_target_inv_rec.mst_bill_account_number;
      ELSE 
        lv_bill_acct_code := iv_bill_acct_code;
      END IF;
--
      IF get_header_inf_cur%NOTFOUND  THEN
--
        -- グローバル変数の初期化
        gn_target_cnt  := 0;
        gn_normal_cnt  := 0;
        gn_error_cnt   := 0;
        gn_warn_cnt    := 0;
        gv_conc_status := cv_status_normal;
        gn_ins_cnt   := 0;
        
        -- メッセージ出力
        xxcfr_common_pkg.put_log_param(
           iv_which        => cv_file_type_out        -- メッセージ出力
          ,iv_conc_param1  => iv_target_date          -- 締日
          ,iv_conc_param2  => lv_bill_acct_code       -- 請求先顧客コード
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
          ,iv_conc_param2  => lv_bill_acct_code       -- 請求先顧客コード
          ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        END IF;
--
          -- =====================================================
          -- 対象請求先顧客取得処理 (A-2)
          -- =====================================================
          ins_target_bill_acct_n(
             lv_bill_acct_code     -- 請求先顧客コード
            ,get_target_inv_rec.mst_bill_account_id     -- 請求先顧客ID
            ,get_target_inv_rec.mst_bill_account_name   -- 請求先顧客名称
            ,get_target_inv_rec.xih_cutoff_date         -- 振替元請求先の締日
            ,get_target_inv_rec.xih_term_name           -- 振替元請求先の支払条件
            ,get_target_inv_rec.xih_term_id             -- 振替元請求先の支払条件ID
            ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode            -- リターン・コード             --# 固定 #
            ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
        -- =====================================================
        -- 請求締対象顧客情報抽出処理 (A-3)
        -- =====================================================
        get_target_bill_acct(
           lv_bill_acct_code     -- 請求先顧客コード
          ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
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
--          RETURN;
          CONTINUE;
        END IF;
--
        --ループ
        <<for_loop>>
        FOR ln_loop_cnt IN gt_get_acct_code_tab.FIRST..gt_get_acct_code_tab.LAST LOOP
          --変数初期化
          ln_target_trx_cnt := 0;
--
            -- =====================================================
            -- 請求ヘッダ情報登録処理 (A-4)
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
               lv_bill_acct_code,                          -- 請求先顧客コード
               ln_xih_invoice_id,                          -- 請求ヘッダ.一括請求書ID
               lv_errbuf,                                  -- エラー・メッセージ           --# 固定 #
               lv_retcode,                                 -- リターン・コード             --# 固定 #
               lv_errmsg                                   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            -- ヘッダ作成件数
            gn_target_header_cnt := gn_target_header_cnt + 1;
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
        END LOOP for_loop;
--
        -- 警告フラグが警告となっている場合
        IF (gv_conc_status = cv_status_warn) THEN
          -- リターン・コードに警告をセット
          ov_retcode := cv_status_warn;
        END IF;
        -- 請求ヘッダ移植 E
      END IF;
      CLOSE get_header_inf_cur;
--
      -- 請求明細更新(A-6)
      update_invoice_lines_id(
        ln_xih_invoice_id,                            -- 請求ヘッダ.一括請求書ID
        get_target_inv_rec.xil_invoice_id,            -- 請求明細.一括請求書ID
        get_target_inv_rec.xil_invoice_detail_num,    -- 一括請求書明細No
        lv_errbuf,                                    -- エラー・メッセージ           --# 固定 #
        lv_retcode,                                   -- リターン・コード             --# 固定 #
        lv_errmsg                                     -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
      --明細更新件数
      gn_target_line_cnt := gn_target_line_cnt + 1;
    END LOOP edit_loop;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_update_target_line;
--
--
  /**********************************************************************************
   * Procedure Name   : update_invoice_lines
   * Description      : 請求金額更新処理 請求明細情報テーブル(A-8)
   ***********************************************************************************/
  PROCEDURE update_invoice_lines(
    in_invoice_id             IN  NUMBER,       -- 請求書ID
    in_invoice_detail_num     IN  NUMBER,       -- 一括請求書明細No
    in_tax_gap_amount         IN  NUMBER,       -- 税差額
    in_tax_sum1               IN  NUMBER,       -- 税額合計１
    in_tax_sum2               IN  NUMBER,       -- 税額合計２
    in_inv_gap_amount         IN  NUMBER,       -- 本体差額
    in_no_tax_sum1            IN  NUMBER,       -- 税抜合計１
    in_no_tax_sum2            IN  NUMBER,       -- 税抜合計２
    iv_category               IN  VARCHAR2,     -- 内訳分類
    iv_invoice_printing_unit  IN  VARCHAR2,     -- 請求書印刷単位
    iv_customer_for_sum       IN  VARCHAR2,     -- 顧客(集計用)
    iv_tax_div                IN  VARCHAR2,     -- 消費税区分
    ov_errbuf                 OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_invoice_lines'; -- プログラム名
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
    -- 請求明細情報テーブル請求金額更新
    BEGIN
--
      UPDATE  xxcfr_invoice_lines  xxil   -- 請求明細情報テーブル
      SET     xxil.tax_gap_amount        = in_tax_gap_amount         -- 税差額
             ,xxil.tax_amount_sum        = in_tax_sum1               -- 税額合計１
             ,xxil.tax_amount_sum2       = in_tax_sum2               -- 税額合計２
             ,xxil.inv_gap_amount        = in_inv_gap_amount         -- 本体差額
             ,xxil.inv_amount_sum        = in_no_tax_sum1            -- 税抜合計１
             ,xxil.inv_amount_sum2       = in_no_tax_sum2            -- 税抜合計２
             ,xxil.category              = iv_category               -- 内訳分類
             ,xxil.invoice_printing_unit = iv_invoice_printing_unit  -- 請求書印刷単位
             ,xxil.customer_for_sum      = iv_customer_for_sum       -- 顧客(集計用)
      WHERE   xxil.invoice_id = in_invoice_id                        -- 一括請求書ID
      AND     xxil.invoice_detail_num = in_invoice_detail_num        -- 一括請求書明細No
      ;
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- データ更新エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil)) -- 請求明細情報テーブル
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_invoice_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_update_target_bill
   * Description      : 請求更新対象取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_update_target_bill(
    ov_target_trx_cnt       OUT NUMBER,       -- 対象取引件数
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_update_target_bill'; -- プログラム名
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
    ln_int             PLS_INTEGER := 0;
    lt_invoice_id      xxcfr_invoice_headers.invoice_id%TYPE;     -- 一括請求書ID
    lt_tax_gap_amount  xxcfr_invoice_lines.tax_gap_amount%TYPE;   -- 税差額
    lt_tax_sum1        xxcfr_invoice_lines.tax_amount_sum%TYPE;   -- 税額合計１
    lt_inv_gap_amount  xxcfr_invoice_lines.inv_gap_amount%TYPE;   -- 本体差額
    lt_no_tax_sum1     xxcfr_invoice_lines.inv_amount_sum%TYPE;   -- 税抜合計１
--
    -- *** ローカル・カーソル ***
    --対象請求書情報データロックカーソル
    CURSOR lock_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id         invoice_id    -- 請求書ID
      FROM    xxcfr_invoice_headers xxih            -- 請求ヘッダ情報テーブル
      WHERE   xxih.request_id = gt_target_request_id   -- コンカレント要求ID
      FOR UPDATE NOWAIT
      ;
--
   --請求明細情報データロックカーソル
    CURSOR lock_target_inv_lines_cur
    IS
      SELECT  xxil.invoice_id         invoice_id    -- 請求書ID
      FROM    xxcfr_invoice_lines xxil              -- 請求明細情報テーブル
      WHERE   EXISTS (SELECT 1 
                      FROM xxcfr_invoice_headers xxih            -- 請求ヘッダ情報テーブル
                      WHERE  xxih.invoice_id = xxil.invoice_id
                      AND    xxih.request_id = gt_target_request_id   -- コンカレント要求ID
                     )
      FOR UPDATE NOWAIT
      ;
--
    --
    CURSOR get_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id                 invoice_id    -- 請求書ID
             ,MIN(xxil.invoice_detail_num)    invoice_detail_num     -- 一括請求書明細No
             ,SUM(NVL(xxil.ship_amount, 0))   ship_amount   -- 税抜額合計
             ,SUM(NVL(xxil.tax_amount, 0))    tax_amount    -- 税額合計
             ,SUM(NVL(xxil.ship_amount, 0) + NVL(xxil.tax_amount, 0)) sold_amount  -- 税込額合計
             ,flv.attribute2                  category               -- 内訳分類
             ,DECODE(xcal.invoice_printing_unit,
                     '0',xxil.ship_cust_code,'1',xcal.invoice_code,'2',xxil.ship_cust_code,
                     '3',xxih.bill_cust_code,
                     '4',xcal20.customer_code || xcal.bill_base_code,
                     '5',xcal14.customer_code || xcal.bill_base_code,
                     '6',xcal.invoice_code,  '7',xcal.invoice_code,'8',xcal20.enclose_invoice_code,
                     '9',xxih.bill_cust_code,'A',xxih.bill_cust_code,'B',xxih.bill_cust_code,
                     'C',xxih.bill_cust_code,'D',xxil.ship_cust_code, null)
                                              customer_for_sum       -- 顧客(集計用)
             ,xxih.invoice_output_form        output_format          -- 請求書出力形式
             ,xxil.tax_rate                   tax_rate               -- 消費税率
             ,NVL(xxca.invoice_tax_div,'N')   invoice_tax_div        -- 請求書消費税積上げ計算方式
             ,xxca.tax_div                    tax_div                -- 消費税区分
             ,xcal.invoice_printing_unit      invoice_printing_unit  -- 請求書印刷単位
      FROM    xxcfr_invoice_headers xxih                          -- 請求ヘッダ情報テーブル
             ,xxcfr_invoice_lines   xxil                          -- 請求明細情報テーブル
             ,xxcmm_cust_accounts   xxca                          -- 顧客追加情報
             ,fnd_lookup_values     flv                           -- 参照表（税分類）
             ,xxcmm_cust_accounts   xcal20                        -- 顧客追加情報(請求書用顧客)
             ,xxcmm_cust_accounts   xcal14                        -- 顧客追加情報(請求書用顧客)
             ,xxcmm_cust_accounts   xcal                          -- 顧客追加情報(納品先顧客)
      WHERE   xxih.request_id = gt_target_request_id              -- コンカレント要求ID
      AND     xxih.invoice_output_form IN ( '1', '4', '5' )
      AND     xxih.invoice_id = xxil.invoice_id
      AND     xxca.customer_id = xxih.bill_cust_account_id
      AND     flv.lookup_type(+)        = 'XXCFR1_TAX_CATEGORY'   -- 税分類
      AND     flv.lookup_code(+)        = xxil.tax_code           -- 参照表（税分類）.ルックアップコード = 請求明細.税金コード
      AND     flv.language(+)           = USERENV( 'LANG' )
      AND     flv.enabled_flag(+)       = 'Y'
      AND     flv.attribute2(+)         IS NOT NULL               -- 内訳分類
      AND     xxil.ship_cust_code       = xcal.customer_code
      AND     xcal20.customer_code(+)   = xcal.invoice_code
      AND     xcal14.customer_code(+)   = xxih.bill_cust_code
      GROUP BY xxih.invoice_id
              ,flv.attribute2                  -- 内訳分類
              ,DECODE(xcal.invoice_printing_unit,
                      '0',xxil.ship_cust_code,'1',xcal.invoice_code,'2',xxil.ship_cust_code,
                      '3',xxih.bill_cust_code,
                      '4',xcal20.customer_code || xcal.bill_base_code,
                      '5',xcal14.customer_code || xcal.bill_base_code,
                      '6',xcal.invoice_code,  '7',xcal.invoice_code,'8',xcal20.enclose_invoice_code,
                      '9',xxih.bill_cust_code,'A',xxih.bill_cust_code,'B',xxih.bill_cust_code,
                      'C',xxih.bill_cust_code,'D',xxil.ship_cust_code, null)
              ,xxih.invoice_output_form        -- 請求書出力形式
              ,xxil.tax_rate                   -- 税率
              ,NVL(xxca.invoice_tax_div,'N')   -- 請求書消費税積上げ計算方式
              ,xxca.tax_div                    -- 消費税区分
              ,xcal.invoice_printing_unit      -- 請求書印刷単位
      ORDER BY 
               invoice_id
              ,category
              ,customer_for_sum
      ;
--
    -- *** ローカル・レコード ***
--
    get_target_inv_rec  get_target_inv_cur%ROWTYPE;
--
    -- *** ローカル・ファンクション ***
    -- 税額合計１（税抜き）算出処理
    FUNCTION calc_tax_sum1(
       it_ship_amount        IN   xxcfr_invoice_lines.ship_amount%TYPE      -- 税抜額合計
      ,it_tax_rate           IN   xxcfr_invoice_lines.tax_rate%TYPE         -- 消費税率
    ) RETURN NUMBER
    IS
--
      ln_tax_sum1  NUMBER;          -- 戻り値：税額合計１
--
    BEGIN
      ln_tax_sum1 := 0;
      -- 少数点以下の端数を切り捨てします。
      ln_tax_sum1 := TRUNC( it_ship_amount * ( it_tax_rate / 100 ) );
--
      RETURN ln_tax_sum1;
    END calc_tax_sum1;
--
    -- *** ローカル・ファンクション ***
    -- 税抜合計１算出処理
    FUNCTION calc_no_tax_sum1(
       it_sold_amount        IN   xxcfr_invoice_lines.sold_amount%TYPE      -- 税込額合計
      ,it_tax_rate           IN   xxcfr_invoice_lines.tax_rate%TYPE         -- 消費税率
    ) RETURN NUMBER
    IS
--
      ln_no_tax_sum1  NUMBER;          -- 戻り値：税抜合計１
--
    BEGIN
      ln_no_tax_sum1 := 0;
      -- 少数点以下の端数を切り捨てします。
      ln_no_tax_sum1 := TRUNC( it_sold_amount / ( it_tax_rate / 100 + 1 ) );
--
      RETURN ln_no_tax_sum1;
    END calc_no_tax_sum1;
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
    ov_target_trx_cnt := 0;
--
    --==============================================================
    --請求テーブルロック情報取得処理
    --==============================================================
    BEGIN
      OPEN lock_target_inv_cur;
--
      CLOSE lock_target_inv_cur;
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
    --==============================================================
    --請求明細テーブルロック情報取得処理
    --==============================================================
    BEGIN
      OPEN lock_target_inv_lines_cur;
--
      CLOSE lock_target_inv_lines_cur;
--
    EXCEPTION
      -- *** テーブルロックエラーハンドラ ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))  -- 請求明細情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --請求明細情報更新処理
    --==============================================================
    --
    <<edit_loop>>
    FOR get_target_inv_rec IN get_target_inv_cur LOOP
--
      --初回、又は、一括請求書IDが変わった場合ブレーク
      IF (
           ( lt_invoice_id IS NULL )
           OR
           ( lt_invoice_id <> get_target_inv_rec.invoice_id )
         )
      THEN
        --初期化、及び、１レコード目の税別項目設定
        ln_int                           := ln_int + 1;                             -- 配列カウントアップ
        gt_get_inv_id_tab(ln_int)        := get_target_inv_rec.invoice_id;          -- 一括請求書ID
        gt_invoice_tax_div_tab(ln_int)   := get_target_inv_rec.invoice_tax_div;     -- 請求書消費税積上げ計算方式
        gt_output_format_tab(ln_int)     := get_target_inv_rec.output_format;       -- 請求書出力形式
        gt_tax_div_tab(ln_int)           := get_target_inv_rec.tax_div;             -- 消費税区分
--
        lt_tax_sum1       := 0;  -- 税額合計１
        lt_no_tax_sum1    := 0;  -- 税抜合計１
        lt_tax_gap_amount := 0;  -- 税差額
        lt_inv_gap_amount := 0;  -- 本体差額
        --
        -- 税抜き（消費税区分：外税、非課税）
        IF ( get_target_inv_rec.tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) ) THEN
          -- 税額合計１（税抜き）算出処理
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
             lt_tax_sum1 := calc_tax_sum1( get_target_inv_rec.ship_amount
                                          ,get_target_inv_rec.tax_rate );
          END IF;
          -- 税抜合計１は取得した税抜額合計
          lt_no_tax_sum1 := get_target_inv_rec.ship_amount;
          -- 本体差額は0
          lt_inv_gap_amount := 0;
        --
        -- 税込み（消費税区分：内税(伝票)、内税(単価)）
        ELSIF ( get_target_inv_rec.tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
          -- 税抜合計１算出処理
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
            lt_no_tax_sum1 := calc_no_tax_sum1( get_target_inv_rec.sold_amount
                                               ,get_target_inv_rec.tax_rate );
          END IF;
          -- 税額合計１
          lt_tax_sum1 := get_target_inv_rec.sold_amount - lt_no_tax_sum1;
          -- 本体差額
          -- 請求書消費税積上げ計算方式がYの場合は0
          IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
             lt_inv_gap_amount := 0;
          ELSE
          -- 請求書消費税積上げ計算方式がY以外の場合、税抜合計１ －税抜合計２
             lt_inv_gap_amount := lt_no_tax_sum1 - get_target_inv_rec.ship_amount;
          END IF;
        END IF;
        -- 税差額
        -- 請求書消費税積上げ計算方式がYの場合は0
        IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
           lt_tax_gap_amount := 0;
        ELSE
        -- 請求書消費税積上げ計算方式がY以外の場合、税額合計１ －税額合計２
           lt_tax_gap_amount := lt_tax_sum1 - get_target_inv_rec.tax_amount;
        END IF;
--
        -- 請求ヘッダ更新用にデータを保持します
        gt_tax_gap_amount_tab(ln_int) := lt_tax_gap_amount;                      -- 税差額
        gt_tax_sum1_tab(ln_int)       := lt_tax_sum1;                            -- 税額合計１
        gt_tax_sum2_tab(ln_int)       := get_target_inv_rec.tax_amount;          -- 税額合計２
        gt_inv_gap_amount_tab(ln_int) := lt_inv_gap_amount;                      -- 本体差額
        gt_no_tax_sum1_tab(ln_int)    := lt_no_tax_sum1;                         -- 税抜合計１
        gt_no_tax_sum2_tab(ln_int)    := get_target_inv_rec.ship_amount;         -- 税抜合計２
        lt_invoice_id                 := get_target_inv_rec.invoice_id;          -- ブレークコード設定
--
        -- 請求明細更新(A-8)
        update_invoice_lines(
          get_target_inv_rec.invoice_id,             -- 請求書ID
          get_target_inv_rec.invoice_detail_num,     -- 一括請求書明細No
          lt_tax_gap_amount,                         -- 税差額
          lt_tax_sum1,                               -- 税額合計１
          get_target_inv_rec.tax_amount,             -- 税額合計２
          lt_inv_gap_amount,                         -- 本体差額
          lt_no_tax_sum1,                            -- 税抜合計１
          get_target_inv_rec.ship_amount,            -- 税抜合計２
          get_target_inv_rec.category,               -- 内訳分類
          get_target_inv_rec.invoice_printing_unit,  -- 請求書印刷単位
          get_target_inv_rec.customer_for_sum,       -- 顧客(集計用)
          get_target_inv_rec.tax_div,                -- 消費税区分
          lv_errbuf,                                 -- エラー・メッセージ           --# 固定 #
          lv_retcode,                                -- リターン・コード             --# 固定 #
          lv_errmsg                                  -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
      ELSE
        -- 2レコード目以降
        lt_tax_sum1       := 0;  -- 税額合計１
        lt_no_tax_sum1    := 0;  -- 税抜合計１
        lt_tax_gap_amount := 0;  -- 税差額
        lt_inv_gap_amount := 0;  -- 本体差額
        --
        -- 税抜き（消費税区分：外税、非課税）
        IF ( get_target_inv_rec.tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) ) THEN
          -- 税額合計１（税抜き）算出処理
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
             lt_tax_sum1 := calc_tax_sum1( get_target_inv_rec.ship_amount
                                          ,get_target_inv_rec.tax_rate );
          END IF;
          -- 税抜合計１は取得した税抜額合計
          lt_no_tax_sum1 := get_target_inv_rec.ship_amount;
          -- 本体差額は0
          lt_inv_gap_amount := 0;
        --
        -- 税込み（消費税区分：内税(伝票)、内税(単価)）
        ELSIF ( get_target_inv_rec.tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
          -- 税抜合計１算出処理
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
            lt_no_tax_sum1 := calc_no_tax_sum1( get_target_inv_rec.sold_amount
                                               ,get_target_inv_rec.tax_rate );
          END IF;
          -- 税額合計１
          lt_tax_sum1 := get_target_inv_rec.sold_amount - lt_no_tax_sum1;
          -- 本体差額
          -- 請求書消費税積上げ計算方式がYの場合は0
          IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
             lt_inv_gap_amount := 0;
          ELSE
          -- 請求書消費税積上げ計算方式がY以外の場合、税抜合計１ －税抜合計２
             lt_inv_gap_amount := lt_no_tax_sum1 - get_target_inv_rec.ship_amount;
          END IF;
        END IF;
        -- 税差額
        -- 請求書消費税積上げ計算方式がYの場合は0
        IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
           lt_tax_gap_amount := 0;
        ELSE
        -- 請求書消費税積上げ計算方式がY以外の場合、税額合計１ －税額合計２
           lt_tax_gap_amount := lt_tax_sum1 - get_target_inv_rec.tax_amount;
        END IF;
--
        -- 請求ヘッダ更新用にデータを保持します
        gt_tax_gap_amount_tab(ln_int) := gt_tax_gap_amount_tab(ln_int) + lt_tax_gap_amount;                -- 税差額
        gt_tax_sum1_tab(ln_int)       := gt_tax_sum1_tab(ln_int) + lt_tax_sum1;                            -- 税額合計１
        gt_tax_sum2_tab(ln_int)       := gt_tax_sum2_tab(ln_int) + get_target_inv_rec.tax_amount;          -- 税額合計２
        gt_inv_gap_amount_tab(ln_int) := gt_inv_gap_amount_tab(ln_int) + lt_inv_gap_amount;                -- 本体差額
        gt_no_tax_sum1_tab(ln_int)    := gt_no_tax_sum1_tab(ln_int) + lt_no_tax_sum1;                      -- 税抜合計１
        gt_no_tax_sum2_tab(ln_int)    := gt_no_tax_sum2_tab(ln_int) + get_target_inv_rec.ship_amount;      -- 税抜合計２
--
        -- 請求明細更新(A-8)
        update_invoice_lines(
          get_target_inv_rec.invoice_id,             -- 請求書ID
          get_target_inv_rec.invoice_detail_num,     -- 一括請求書明細No
          lt_tax_gap_amount,                         -- 税差額
          lt_tax_sum1,                               -- 税額合計１
          get_target_inv_rec.tax_amount,             -- 税額合計２
          lt_inv_gap_amount,                         -- 本体差額
          lt_no_tax_sum1,                            -- 税抜合計１
          get_target_inv_rec.ship_amount,            -- 税抜合計２
          get_target_inv_rec.category,               -- 内訳分類
          get_target_inv_rec.invoice_printing_unit,  -- 請求書印刷単位
          get_target_inv_rec.customer_for_sum,       -- 顧客(集計用)
          get_target_inv_rec.tax_div,                -- 消費税区分
          lv_errbuf,                                 -- エラー・メッセージ           --# 固定 #
          lv_retcode,                                -- リターン・コード             --# 固定 #
          lv_errmsg                                  -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP edit_loop;
--
    -- 処理件数のセット
    ov_target_trx_cnt := gt_get_inv_id_tab.COUNT;
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
  END get_update_target_bill;
--
--
  /**********************************************************************************
   * Procedure Name   : update_bill_amount
   * Description      : 請求金額更新処理 請求ヘッダ情報テーブル(A-9)
   ***********************************************************************************/
  PROCEDURE update_bill_amount(
    in_invoice_id           IN  NUMBER,       -- 請求書ID
    in_tax_gap_amount       IN  NUMBER,       -- 税差額
    in_tax_amount_sum       IN  NUMBER,       -- 税額合計１
    in_tax_amount_sum2      IN  NUMBER,       -- 税額合計２
    in_inv_gap_amount       IN  NUMBER,       -- 本体差額
    in_inv_amount_sum       IN  NUMBER,       -- 税抜額合計１
    in_inv_amount_sum2      IN  NUMBER,       -- 税抜額合計２
    iv_invoice_tax_div      IN  VARCHAR2,     -- 請求書消費税積上げ計算方式
    iv_output_format        IN  VARCHAR2,     -- 請求書出力形式
    iv_tax_div              IN  VARCHAR2,     -- 税区分
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_bill_amount'; -- プログラム名
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
    lt_inv_gap_amount              xxcfr_invoice_headers.inv_gap_amount%TYPE;              -- 本体差額
    lt_inv_amount_no_tax           xxcfr_invoice_headers.inv_amount_no_tax%TYPE;           -- 税抜請求金額合計
    lt_tax_amount_sum              xxcfr_invoice_headers.tax_amount_sum%TYPE;              -- 税額合計
    lt_inv_amount_includ_tax       xxcfr_invoice_headers.inv_amount_includ_tax%TYPE;       -- 税込請求金額合計
    lt_tax_diff_amount_create_flg  xxcfr_invoice_headers.tax_diff_amount_create_flg%TYPE;  -- 消費税差額作成フラグ
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
    lt_inv_gap_amount              := 0;
    lt_inv_amount_no_tax           := 0;
    lt_tax_amount_sum              := 0;
    lt_inv_amount_includ_tax       := 0;
    lt_tax_diff_amount_create_flg  := NULL;
--
    -- 税額合計
    IF ( iv_invoice_tax_div = 'Y' ) THEN
      lt_tax_amount_sum := in_tax_amount_sum2;  -- 税額合計に税額合計２を設定
    ELSE
      lt_tax_amount_sum := in_tax_amount_sum;   -- 税額合計に税額合計１を設定
    END IF;
    -- 税抜きの場合
    IF ( iv_tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) )  THEN
      lt_inv_gap_amount    := 0;                    -- 本体差額に0を設定
      lt_inv_amount_no_tax := in_inv_amount_sum2;   -- 税抜請求金額合計に税抜額合計２を設定
--
    -- 税込みの場合
    ELSIF ( iv_tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
      IF ( iv_invoice_tax_div = 'Y' ) THEN
        lt_inv_gap_amount    := 0;                  -- 本体差額に0を設定
        lt_inv_amount_no_tax := in_inv_amount_sum2; -- 税抜請求金額合計に税抜額合計２を設定
      ELSE
        lt_inv_gap_amount    := in_inv_gap_amount;  -- 本体差額
        lt_inv_amount_no_tax := in_inv_amount_sum;  -- 税抜請求金額合計に税抜額合計１を設定
      END IF;
    END IF;
--
    -- 税込請求金額合計 = 税抜請求金額合計 ＋ 税額合計
    lt_inv_amount_includ_tax := NVL(lt_inv_amount_no_tax,0) + lt_tax_amount_sum;
    -- 消費税差額作成フラグ
    -- 請求書消費税積上げ計算方式がY以外かつ税差額または本体差額が0またはNULLでない場合
    IF ( iv_invoice_tax_div <> 'Y' AND
         (( NVL(in_tax_gap_amount,0) <> 0 ) OR ( NVL(lt_inv_gap_amount,0) <> 0 )) ) THEN
      lt_tax_diff_amount_create_flg := '0';
    END IF;
-- Ver1.190 Add End
--
    -- 請求ヘッダ情報テーブル請求金額更新
    BEGIN
--
      UPDATE  xxcfr_invoice_headers  xxih -- 請求ヘッダ情報テーブル
      SET    xxih.tax_gap_amount              =  in_tax_gap_amount         -- 税差額
            ,xxih.inv_amount_no_tax           =  lt_inv_amount_no_tax      -- 税抜請求金額合計
            ,xxih.tax_amount_sum              =  lt_tax_amount_sum         -- 税額合計
            ,xxih.inv_amount_includ_tax       =  lt_inv_amount_includ_tax  -- 税込請求金額合計
            ,xxih.inv_gap_amount              =  lt_inv_gap_amount         -- 本体差額
            ,xxih.invoice_tax_div             =  iv_invoice_tax_div        -- 請求書消費税積上げ計算方式
            ,xxih.tax_diff_amount_create_flg  =  lt_tax_diff_amount_create_flg  -- 消費税差額作成フラグ
            ,xxih.tax_rounding_rule           =  cv_tax_rounding_rule_down      -- 税金－端数処理
            ,xxih.output_format               =  iv_output_format          -- 請求書出力形式
      WHERE   xxih.invoice_id = in_invoice_id          -- 請求書ID
      ;
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- データ更新エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- 請求ヘッダ情報テーブル
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_bill_amount;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date            IN  VARCHAR2,     -- 締日
    iv_bill_acct_code         IN  VARCHAR2,     -- 請求先顧客コード
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
    -- グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    gv_conc_status := cv_status_normal;
    gn_ins_cnt   := 0;
    gn_target_header_cnt := 0;
    gn_target_line_cnt   := 0;
--
--
    -- =====================================================
    --  請求明細更新対象取得処理(A-5)
    -- =====================================================
    get_update_target_line(
       iv_target_date          -- 締日
      ,iv_bill_acct_code       -- 請求先顧客コード
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 請求ヘッダ情報の請求金額を再計算する。
    --変数初期化
    ln_target_trx_cnt := 0;
    -- =====================================================
    -- 請求更新対象取得処理 (A-7)
    -- =====================================================
    get_update_target_bill(
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
      --ループ
      <<for_loop>>
      FOR ln_loop_cnt IN gt_get_inv_id_tab.FIRST..gt_get_inv_id_tab.LAST LOOP
        -- =====================================================
        -- 請求金額更新処理 請求ヘッダ情報テーブル(A-9)
        -- =====================================================
        update_bill_amount(
           gt_get_inv_id_tab(ln_loop_cnt),         -- 請求書ID
           gt_tax_gap_amount_tab(ln_loop_cnt),     -- 税差額
           gt_tax_sum1_tab(ln_loop_cnt),           -- 税額合計１
           gt_tax_sum2_tab(ln_loop_cnt),           -- 税額合計２
           gt_inv_gap_amount_tab(ln_loop_cnt),     -- 本体差額
           gt_no_tax_sum1_tab(ln_loop_cnt),        -- 税抜額合計１
           gt_no_tax_sum2_tab(ln_loop_cnt),        -- 税抜額合計２
           gt_invoice_tax_div_tab(ln_loop_cnt),    -- 請求書消費税積上げ計算方式
           gt_output_format_tab(ln_loop_cnt),      -- 請求書出力形式
           gt_tax_div_tab(ln_loop_cnt),            -- 税区分
           lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
           lv_retcode,                             -- リターン・コード             --# 固定 #
           lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
    END LOOP for_loop;
--
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
    iv_bill_acct_code       IN      VARCHAR2         -- 請求先顧客コード
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
--      gn_target_cnt := 0;
--      gn_normal_cnt := 0;
      gn_target_header_cnt := 0;
      gn_target_line_cnt := 0;
      gn_error_cnt  := 1;
--      gn_warn_cnt   := 0;
--      gn_ins_cnt    := 0;
    END IF;
    --メッセージタイトル(ヘッダ部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00018
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(ヘッダ部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --メッセージタイトル(明細部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00019
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(明細部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt)
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
END XXCFR003A24C;
/
