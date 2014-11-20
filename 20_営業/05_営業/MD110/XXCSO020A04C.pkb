CREATE OR REPLACE PACKAGE BODY APPS.XXCSO020A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A04C(body)
 * Description      : SP専決画面からの要求に従って、SP専決画面で入力された情報で発注依頼を
 *                    作成します。
 * MD.050           : MD050_CSO_020_A04_自販機（什器）発注依頼データ連携機能
 *
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc             初期処理(A-1)
 *  get_sp_dec_head_info   ＳＰ専決ヘッダテーブル取得処理(A-2)
 *  get_employee_info      従業員情報取得処理(A-3)
 *  get_item_info          品目情報取得処理(A-4)
 *  get_vendor_info        見積情報取得処理(A-5)
 *  get_inv_org_id         搬送先組織ＩＤ取得処理(A-6)
 *  get_code_comb_id       費用勘定科目ＩＤ取得処理(A-7)
 *  reg_po_req_interface   購買依頼I/Fテーブル登録処理(A-8)
 *  reg_vendor             発注依頼ヘッダ・明細登録処理(A-9)
 *  confirm_reg_vendor     発注依頼ヘッダ・明細登録完了確認処理(A-10)
 *  get_customer_info      顧客情報取得処理(A-11)
 *  get_po_req_line_id     購買依頼明細ＩＤ取得処理(A-12)
 *  get_temp_info_terget   情報テンプレート登録対象項目情報取得処理(A-13)
 *  reg_temp_info          情報テンプレート登録処理(A-14)
 *  submain                メイン処理プロシージャ
 *  main                   実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   Kazuo.Satomura   新規作成
 *  2009-02-19          Kazuo.Satomura   障害対応
 *                                       ・品目情報取得の時、旧台の場合品目が取得できない
 *                                         障害を修正
 *                                       ・ＳＰ専決の機種コードを国連番号へマッピング
 *                                       ・ＳＰ専決の機種コードから危険分類ＩＤを取得し、
 *                                         マッピング
 *                                       ・顧客情報取得の条件にＳＰ専決顧客区分を追加
 *  2009-02-27          Kazuo.Satomura   障害対応(障害NO39,40,41)
 *                                       ・見積情報検索の条件を有効日付とステータスを追加
 *                                       ・機種コードが未入力の場合は危険分類ＩＤを取得し
 *                                         ないよう修正
 *                                       ・従業員情報取得の条件をログインユーザーＩＤへ変
 *                                         更
 *  2009-03/23    1.1   Kazuo.Satomura   システムテスト障害対応(障害番号T1_0095,100,104)
 *                                       ・バイヤーＩＤをログイン従業員ＩＤから見積ヘッダ
 *                                         のエージェントＩＤへ変更
 *                                       ・見積検索時の条件を有効開始日～有効終了日から
 *                                         開始日～終了日へ変更
 *                                       ・搬送先事業所ＩＤ、搬送先事業所コード、搬送先要
 *                                         求者ＩＤをログインのユーザーＩＤから取得
 *  2009-04-03    1.2   Kazuo.Satomura   システムテスト障害対応(障害番号T1_0109)
 *  2009-04-07    1.3   Kazuo.Satomura   システムテスト障害対応(障害番号T1_0355)
 *  2009-05-01    1.4   Tomoko.Mori      T1_0897対応
 *  2009-05-01    1.5   Kazuo.Satomura   0001138対応
 *                                       ・購買依頼I/FテーブルのバッチＩＤに取引ＩＤを設定
 *                                       ・購買依頼インポート処理の第一パラメータに取引ＩＤ
 *                                         を設定
 *  2010-01-08    1.6   Kazuyo.Hosoi     E_本稼動_01017対応
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt    NUMBER; -- 対象件数
  gn_normal_cnt    NUMBER; -- 正常件数
  gn_error_cnt     NUMBER; -- エラー件数
  gn_warn_cnt      NUMBER; -- スキップ件数
  --
  --################################  固定部 END   ##################################
  --
  --##########################  固定共通例外宣言部 START  ###########################
  --
  --*** 処理部共通例外 ***
  global_process_expt EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO020A04C';                                    -- パッケージ名
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';                                           -- 営業用アプリケーション短縮名
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';                                               -- フラグY
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';                                               -- フラグN
  cv_date_format1          CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';                           -- 日付フォーマット
  cv_date_format2          CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD';                                      -- 日付フォーマット
  cv_year_format           CONSTANT VARCHAR2(21)  := 'YYYY';                                            -- 日付フォーマット（年）
  cv_month_format          CONSTANT VARCHAR2(21)  := 'MM';                                              -- 日付フォーマット（月）
  cv_day_format            CONSTANT VARCHAR2(21)  := 'DD';                                              -- 日付フォーマット（日）
  cd_sysdate               CONSTANT DATE          := SYSDATE;                                           -- システム日付
  cd_process_date          CONSTANT DATE          := xxccp_common_pkg2.get_process_date;                -- 業務処理日付
  cv_lang                  CONSTANT VARCHAR2(2)   := USERENV('LANG');                                   -- 言語
  cn_org_id                CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ログイン組織ＩＤ
  cv_price_type            CONSTANT VARCHAR2(9)   := 'QUOTATION';                                       -- 価格タイプ
  --
  -- メッセージコード
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011'; -- 業務処理日付取得エラー
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00325'; -- パラメータ必須エラー
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00329'; -- データ取得エラー
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00330'; -- データ登録エラー
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00383'; -- シーケンス取得エラー
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00456'; -- コンカレント起動エラー
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00457'; -- コンカレント終了確認エラー
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00458'; -- コンカレント異常終了エラー
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00459'; -- コンカレント警告終了エラー
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00465'; -- 購買依頼登録エラー
  cv_tkn_number_11 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496'; -- パラメータ出力
  cv_tkn_number_12 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00548'; -- 見積複数エラー
  /* 2009.04.03 K.Satomura T1_0109対応 START */
  cv_tkn_number_13 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00337'; -- データ更新エラー
  /* 2009.04.03 K.Satomura T1_0109対応 END */
  --
  -- トークンコード
  cv_tkn_param_name    CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_value         CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_key_name      CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_id        CONSTANT VARCHAR2(20) := 'KEY_ID';
  cv_tkn_table         CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key           CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_error_message CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_sequence      CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_proc_name     CONSTANT VARCHAR2(20) := 'PROC_NAME';
  cv_tkn_request_id    CONSTANT VARCHAR2(20) := 'REQUEST_ID';
  cv_tkn_err_msg       CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_item          CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_api_name      CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg       CONSTANT VARCHAR2(20) := 'API_MSG';
  cv_tkn_action        CONSTANT VARCHAR2(20) := 'ACTION';
  --
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1  CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg2  CONSTANT VARCHAR2(200) := 'cd_process_date = ';
  cv_debug_msg3  CONSTANT VARCHAR2(200) := '<< 入力パラメータ >>';
  cv_debug_msg4  CONSTANT VARCHAR2(200) := 'it_sp_decision_header_id = ';
  cv_debug_msg5  CONSTANT VARCHAR2(200) := '<< ＳＰ専決ヘッダテーブル >>';
  cv_debug_msg6  CONSTANT VARCHAR2(200) := 'sp_decision_number     = ';
  cv_debug_msg7  CONSTANT VARCHAR2(200) := 'approval_complete_date = ';
  cv_debug_msg8  CONSTANT VARCHAR2(200) := 'application_code       = ';
  cv_debug_msg9  CONSTANT VARCHAR2(200) := 'app_base_code          = ';
  cv_debug_msg10 CONSTANT VARCHAR2(200) := 'newold_type            = ';
  cv_debug_msg11 CONSTANT VARCHAR2(200) := 'maker_code             = ';
  cv_debug_msg12 CONSTANT VARCHAR2(200) := 'install_date           = ';
  cv_debug_msg14 CONSTANT VARCHAR2(200) := '<< 従業員情報 >>';
  cv_debug_msg15 CONSTANT VARCHAR2(200) := 'user_name       = ';
  cv_debug_msg16 CONSTANT VARCHAR2(200) := 'person_id       = ';
  cv_debug_msg17 CONSTANT VARCHAR2(200) := 'employee_number = ';
  cv_debug_msg18 CONSTANT VARCHAR2(200) := '<< 品目情報 >>';
  cv_debug_msg19 CONSTANT VARCHAR2(200) := 'category_id = ';
  cv_debug_msg27 CONSTANT VARCHAR2(200) := '<< 発注情報 >>';
  cv_debug_msg28 CONSTANT VARCHAR2(200) := 'vendor_id             = ';
  cv_debug_msg26 CONSTANT VARCHAR2(200) := 'item_description      = ';
  cv_debug_msg23 CONSTANT VARCHAR2(200) := 'unit_meas_lookup_code = ';
  cv_debug_msg22 CONSTANT VARCHAR2(200) := 'unit_price            = ';
  cv_debug_msg30 CONSTANT VARCHAR2(200) := 'quantity              = ';
  cv_debug_msg32 CONSTANT VARCHAR2(200) := '<< 搬送先情報 >>';
  cv_debug_msg29 CONSTANT VARCHAR2(200) := 'ship_to_location_id       = ';
  cv_debug_msg31 CONSTANT VARCHAR2(200) := 'ship_to_location_code     = ';
  cv_debug_msg59 CONSTANT VARCHAR2(200) := 'ship_to_person_id         = ';
  cv_debug_msg33 CONSTANT VARCHAR2(200) := 'inventory_organization_id = ';
  cv_debug_msg34 CONSTANT VARCHAR2(200) := '<< 費用勘定科目ＩＤ >>';
  cv_debug_msg35 CONSTANT VARCHAR2(200) := 'code_combination_id = ';
  cv_debug_msg36 CONSTANT VARCHAR2(200) := '<< 取引ＩＤ(インターフェースソースＩＤ) >>';
  cv_debug_msg37 CONSTANT VARCHAR2(200) := 'transaction_id = ';
  cv_debug_msg38 CONSTANT VARCHAR2(200) := '<< 要求ＩＤ >>';
  cv_debug_msg39 CONSTANT VARCHAR2(200) := 'ln_request_id = ';
  cv_debug_msg40 CONSTANT VARCHAR2(200) := '<< 顧客情報 >>';
  cv_debug_msg41 CONSTANT VARCHAR2(200) := 'account_number             = ';
  cv_debug_msg42 CONSTANT VARCHAR2(200) := 'party_name                 = ';
  cv_debug_msg43 CONSTANT VARCHAR2(200) := 'organization_name_phonetic = ';
  cv_debug_msg44 CONSTANT VARCHAR2(200) := 'postal_code                = ';
  cv_debug_msg45 CONSTANT VARCHAR2(200) := 'state                      = ';
  cv_debug_msg46 CONSTANT VARCHAR2(200) := 'city                       = ';
  cv_debug_msg47 CONSTANT VARCHAR2(200) := 'address1                   = ';
  cv_debug_msg48 CONSTANT VARCHAR2(200) := 'address2                   = ';
  cv_debug_msg49 CONSTANT VARCHAR2(200) := 'address3                   = ';
  cv_debug_msg50 CONSTANT VARCHAR2(200) := 'address_lines_phonetic     = ';
  cv_debug_msg51 CONSTANT VARCHAR2(200) := 'sale_base_code             = ';
  cv_debug_msg52 CONSTANT VARCHAR2(200) := '<< 発注依頼明細ＩＤ >>';
  cv_debug_msg53 CONSTANT VARCHAR2(200) := 'requisition_line_id = ';
  cv_debug_msg54 CONSTANT VARCHAR2(200) := '<< 情報テンプレート >>';
  cv_debug_msg55 CONSTANT VARCHAR2(200) := 'requisition_line_id = ';
  cv_debug_msg56 CONSTANT VARCHAR2(200) := 'attribute_name      = ';
  cv_debug_msg57 CONSTANT VARCHAR2(200) := 'attribute_value     = ';
  cv_debug_msg58 CONSTANT VARCHAR2(200) := 'un_number              = ';
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- マスタ登録情報用構造体
  TYPE g_mst_regist_info_rtype IS RECORD(
    -- ＳＰ専決ヘッダ情報
     sp_decision_number     xxcso_sp_decision_headers.sp_decision_number%TYPE     -- ＳＰ専決書番号
    ,approval_complete_date xxcso_sp_decision_headers.approval_complete_date%TYPE -- 承認完了日
    ,application_code       xxcso_sp_decision_headers.application_code%TYPE       -- 申請者コード
    ,app_base_code          xxcso_sp_decision_headers.app_base_code%TYPE          -- 申請拠点コード
    ,newold_type            xxcso_sp_decision_headers.newold_type%TYPE            -- 新台旧台区分
    ,maker_code             xxcso_sp_decision_headers.maker_code%TYPE             -- メーカーコード
    ,un_number              xxcso_sp_decision_headers.un_number%TYPE              -- 機種コード
    ,install_date           xxcso_sp_decision_headers.install_date%TYPE           -- 設置日
    -- 従業員情報
    ,user_name       xxcso_employees_v2.user_name%TYPE       -- ユーザー名
    ,person_id       xxcso_employees_v2.person_id%TYPE       -- 従業員ＩＤ
    ,employee_number xxcso_employees_v2.employee_number%TYPE -- 従業員番号
    -- 品目情報
    ,category_id     mtl_categories_b.category_id%TYPE        -- 品目ＩＤ
    -- 発注情報
    ,po_header_id          po_headers.po_header_id%TYPE        -- 見積ヘッダーＩＤ
    ,agent_id              po_headers.agent_id%TYPE            -- エージェントＩＤ
    ,vendor_id             po_headers.vendor_id%TYPE           -- 仕入先ＩＤ
    ,line_num              po_lines.line_num%TYPE              -- 明細番号
    ,item_description      po_lines.item_description%TYPE      -- 品目適用
    ,unit_meas_lookup_code po_lines.unit_meas_lookup_code%TYPE -- 単位
    ,unit_price            po_lines.unit_price%TYPE            -- 価格
    ,quantity              po_lines.quantity%TYPE              -- 数量
    -- 搬送先情報
    ,ship_to_location_id       xxcso_locations_v.location_id%TYPE -- 搬送先事業所ＩＤ
    ,ship_to_location_code     xxcso_locations_v.dept_code%TYPE   -- 搬送先事業所コード
    ,ship_to_person_id         xxcso_employees_v2.person_id%TYPE  -- 搬送先要求者ＩＤ
    ,inventory_organization_id NUMBER                             -- 搬送先組織ＩＤ
    -- 費用勘定科目ＩＤ
    ,code_combination_id per_employees_current_x.default_code_combination_id%TYPE -- 費用勘定科目ＩＤ
    -- 顧客情報
    ,account_number             hz_cust_accounts.account_number%TYPE       -- 顧客コード
    ,party_name                 hz_parties.party_name%TYPE                 -- 顧客名
    ,organization_name_phonetic hz_parties.organization_name_phonetic%TYPE -- 顧客名カナ
    ,postal_code                hz_locations.postal_code%TYPE              -- 郵便番号
    ,state                      hz_locations.state%TYPE                    -- 都道府県
    ,city                       hz_locations.city%TYPE                     -- 市・区
    ,address1                   hz_locations.address1%TYPE                 -- 住所１
    ,address2                   hz_locations.address2%TYPE                 -- 住所２
    ,address3                   hz_locations.address3%TYPE                 -- 住所３
    ,address_lines_phonetic     hz_locations.address_lines_phonetic%TYPE   -- 電話番号
    ,sale_base_code             xxcmm_cust_accounts.sale_base_code%TYPE    -- 売上拠点コード
    -- 発注依頼明細ＩＤ
    ,requisition_line_id po_requisition_lines_all.requisition_line_id%TYPE -- 発注依頼明細ＩＤ
  );
  --
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                             -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                             -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_proc'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_tkn_value_sp_dec_hed_id CONSTANT VARCHAR2(30) := 'ＳＰ専決ヘッダＩＤ';
    cv_tkn_value_processdate   CONSTANT VARCHAR2(30) := '業務日付'; 
    --
    -- *** ローカル変数 ***
    lv_msg_from VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ===========================
    -- 起動パラメータメッセージ出力
    -- ===========================
    -- 空行の挿入
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => ''
    );
    --
    lv_msg_from := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_11           -- メッセージコード
                    ,iv_token_name1  => cv_tkn_param_name          -- トークンコード1
                    ,iv_token_value1 => cv_tkn_value_sp_dec_hed_id -- トークン値1
                    ,iv_token_name2  => cv_tkn_value               -- トークンコード2
                    ,iv_token_value2 => it_sp_decision_header_id   -- トークン値2
                   );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => lv_msg_from
    );
    --
    -- ======================
    -- 業務日付チェック
    -- ======================
    IF (cd_process_date IS NULL) THEN
      -- 業務日付が未入力の場合エラー
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item              -- トークコード1
                     ,iv_token_value1 => cv_tkn_value_processdate -- トークン値1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- 業務日付をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(cd_process_date, 'YYYY/MM/DD') || CHR(10) || ''
    );
    -- *** DEBUG_LOG END ***
    --
    -- ======================
    -- 入力パラメータチェック
    -- ======================
    IF (it_sp_decision_header_id IS NULL) THEN
      -- ＳＰ専決ヘッダＩＤが未入力の場合エラー
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_02           -- メッセージコード
                     ,iv_token_name1  => cv_tkn_param_name          -- トークコード1
                     ,iv_token_value1 => cv_tkn_value_sp_dec_hed_id -- トークン値1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- 入力パラメータをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || it_sp_decision_header_id || CHR(10) || ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END start_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_sp_dec_head_info
   * Description      : ＳＰ専決ヘッダテーブル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_sp_dec_head_info(
     it_sp_decision_header_id IN            xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype                              -- マスタ登録情報
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                                             -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                                             -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                                             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_sp_dec_head_info'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_value_sp_dec_head    CONSTANT VARCHAR2(50) := 'ＳＰ専決ヘッダテーブル';
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(50) := 'ＳＰ専決ヘッダＩＤ';
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
    -- ==============================
    -- ＳＰ専決ヘッダテーブル取得処理
    -- ==============================
    BEGIN
      SELECT xsd.sp_decision_number     sp_decision_number     -- ＳＰ専決書番号
            ,xsd.approval_complete_date approval_complete_date -- 承認完了日
            ,xsd.application_code       application_code       -- 申請者コード
            ,xsd.app_base_code          app_base_code          -- 申請拠点コード
            ,xsd.newold_type            newold_type            -- 新台旧台区分
            ,xsd.maker_code             maker_code             -- メーカーコード
            ,xsd.un_number              un_number              -- 機種コード
            ,xsd.install_date           install_date           -- 設置日
      INTO   iot_mst_regist_info_rec.sp_decision_number     -- ＳＰ専決書番号
            ,iot_mst_regist_info_rec.approval_complete_date -- 承認完了日
            ,iot_mst_regist_info_rec.application_code       -- 申請者コード
            ,iot_mst_regist_info_rec.app_base_code          -- 申請拠点コード
            ,iot_mst_regist_info_rec.newold_type            -- 新台旧台区分
            ,iot_mst_regist_info_rec.maker_code             -- メーカーコード
            ,iot_mst_regist_info_rec.un_number              -- 機種コード
            ,iot_mst_regist_info_rec.install_date           -- 設置日
      FROM   xxcso_sp_decision_headers xsd -- ＳＰ専決ヘッダテーブル
      WHERE  xsd.sp_decision_header_id = it_sp_decision_header_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action               -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head    -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name             -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_head_id -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id               -- トークンコード3
                       ,iv_token_value3 => it_sp_decision_header_id    -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- ＳＰ専決ヘッダテーブルをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || iot_mst_regist_info_rec.sp_decision_number                              || CHR(10) ||
                 cv_debug_msg7  || TO_CHAR(iot_mst_regist_info_rec.approval_complete_date,cv_date_format1) || CHR(10) ||
                 cv_debug_msg8  || iot_mst_regist_info_rec.application_code                                || CHR(10) ||
                 cv_debug_msg9  || iot_mst_regist_info_rec.app_base_code                                   || CHR(10) ||
                 cv_debug_msg10 || iot_mst_regist_info_rec.newold_type                                     || CHR(10) ||
                 cv_debug_msg11 || iot_mst_regist_info_rec.maker_code                                      || CHR(10) ||
                 cv_debug_msg12 || TO_CHAR(iot_mst_regist_info_rec.install_date, cv_date_format1)          || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_sp_dec_head_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_employee_info
   * Description      : 従業員情報取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_employee_info(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_employee_info'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_value_employee CONSTANT VARCHAR2(50) := '従業員マスタ(最新)ビュー';
    cv_tkn_value_user_id  CONSTANT VARCHAR2(50) := 'ユーザーＩＤ';
    --
    -- *** ローカル変数 ***
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
    -- ============================
    -- 従業員情報取得
    -- ============================
    BEGIN
      SELECT xev.user_name       user_name       -- ユーザー名
            ,xev.person_id       person_id       -- 従業員ＩＤ
            ,xev.employee_number employee_number -- 従業員番号
      INTO   iot_mst_regist_info_rec.user_name       -- ユーザー名
            ,iot_mst_regist_info_rec.person_id       -- 従業員ＩＤ
            ,iot_mst_regist_info_rec.employee_number -- 従業員番号
      FROM   xxcso_employees_v2 xev -- 従業員マスタ(最新)ビュー
      WHERE  xev.user_id = cn_created_by
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_employee    -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_user_id     -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => cn_created_by            -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 従業員情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg14  || CHR(10) ||
                 cv_debug_msg15  || iot_mst_regist_info_rec.user_name       || CHR(10) ||
                 cv_debug_msg16  || iot_mst_regist_info_rec.person_id       || CHR(10) ||
                 cv_debug_msg17  || iot_mst_regist_info_rec.employee_number || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
     -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_employee_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : 品目情報取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_info(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_item_info'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_lookup_type_cate_type CONSTANT VARCHAR2(50) := 'XXCSO1_PO_CATEGORY_TYPE';
    cv_msg_sep               CONSTANT VARCHAR2(2)  := '・';
    cv_newold_type_old       CONSTANT VARCHAR2(1)  := '2'; -- 新台旧台区分=2
    --
    -- トークン用定数
    cv_tkn_value_item_info CONSTANT VARCHAR2(50) := '品目情報';
    cv_tkn_value_key_name  CONSTANT VARCHAR2(50) := '新台旧台区分・メーカーコード';
    --
    -- *** ローカル変数 ***
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
    -- ============================
    -- 品目情報取得
    -- ============================
    BEGIN
      SELECT mcb.category_id category_id -- カテゴリＩＤ
      INTO   iot_mst_regist_info_rec.category_id -- カテゴリＩＤ
      FROM   fnd_lookup_values_vl flv
            ,mtl_categories_b     mcb
      WHERE  flv.lookup_type                                    =  cv_lookup_type_cate_type
      AND    flv.attribute3                                     =  iot_mst_regist_info_rec.newold_type
      AND    NVL(flv.attribute2, fnd_api.g_miss_char)           =  DECODE(iot_mst_regist_info_rec.newold_type
                                                                         ,cv_newold_type_old, fnd_api.g_miss_char
                                                                         ,iot_mst_regist_info_rec.maker_code)
      AND    flv.enabled_flag                                   =  cv_flag_yes
      AND    TRUNC(NVL(flv.start_date_active, cd_process_date)) <= TRUNC(cd_process_date)
      AND    TRUNC(NVL(flv.end_date_active, cd_process_date))   >= TRUNC(cd_process_date)
      AND    flv.meaning                                        =  mcb.segment1
      AND    mcb.enabled_flag                                   =  cv_flag_yes
      AND    TRUNC(NVL(mcb.start_date_active, cd_process_date)) <= TRUNC(cd_process_date)
      AND    TRUNC(NVL(mcb.end_date_active, cd_process_date))   >= TRUNC(cd_process_date)
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                       -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_item_info              -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                     -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_key_name               -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                       -- トークンコード3
                       ,iv_token_value3 => iot_mst_regist_info_rec.newold_type ||
                                           cv_msg_sep                          ||
                                           iot_mst_regist_info_rec.maker_code  -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 品目情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg18 || CHR(10) ||
                 cv_debug_msg19 || iot_mst_regist_info_rec.category_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_item_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_vendor_info
   * Description      : 見積情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_vendor_info(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_vendor_info';  -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_quotation_class_code CONSTANT VARCHAR2(10) := 'CATALOG';
    cv_status_active        CONSTANT VARCHAR2(1)  := 'A';
    --
    -- トークン用定数
    cv_tkn_value_vendor_info CONSTANT VARCHAR2(50) := '見積情報';
    cv_tkn_value_key_name    CONSTANT VARCHAR2(50) := 'カテゴリＩＤ';
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
    -- ============================
    -- 発注情報取得
    -- ============================
    BEGIN
      SELECT phe.po_header_id          po_header_id          -- 見積ヘッダＩＤ
            ,phe.agent_id              agent_id              -- エージェントＩＤ
            ,phe.vendor_id             vendor_id             -- 仕入先ＩＤ
            ,pli.line_num              line_num              -- 明細番号
            ,pli.item_description      item_description      -- 品目適用
            ,pli.unit_meas_lookup_code unit_meas_lookup_code -- 単位
            ,pli.unit_price            unit_price            -- 価格
            ,pli.quantity              quantity              -- 数量
      INTO   iot_mst_regist_info_rec.po_header_id          -- 見積ヘッダＩＤ
            ,iot_mst_regist_info_rec.agent_id              -- エージェントＩＤ
            ,iot_mst_regist_info_rec.vendor_id             -- 仕入先ＩＤ
            ,iot_mst_regist_info_rec.line_num              -- 明細番号
            ,iot_mst_regist_info_rec.item_description      -- 品目適用
            ,iot_mst_regist_info_rec.unit_meas_lookup_code -- 単位
            ,iot_mst_regist_info_rec.unit_price            -- 価格
            ,iot_mst_regist_info_rec.quantity              -- 数量
      FROM   po_headers   phe -- 見積ヘッダビュー
            ,po_lines     pli -- 見積明細ビュー
      WHERE  pli.category_id                     =  iot_mst_regist_info_rec.category_id
      AND    pli.po_header_id                    =  phe.po_header_id
      AND    phe.type_lookup_code                =  cv_price_type
      AND    phe.quotation_class_code            =  cv_quotation_class_code
      /* 2009.04.07 K.Satomura T1_0355対応 START */
      --AND    TRUNC(NVL(phe.start_date, SYSDATE)) <= TRUNC(cd_process_date)
      --AND    TRUNC(NVL(phe.end_date, SYSDATE))   >= TRUNC(cd_process_date)
      AND    TRUNC(NVL(phe.start_date, cd_process_date)) <= TRUNC(cd_process_date)
      AND    TRUNC(NVL(phe.end_date, cd_process_date))   >= TRUNC(cd_process_date)
      /* 2009.04.07 K.Satomura T1_0355対応 END */
      AND    phe.status_lookup_code              =  cv_status_active
      ;
      --
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12                    -- メッセージコード
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                       -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_vendor_info            -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                     -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_key_name               -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                       -- トークンコード3
                       ,iv_token_value3 => iot_mst_regist_info_rec.category_id -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 発注情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg27 || CHR(10) ||
                 cv_debug_msg28 || iot_mst_regist_info_rec.vendor_id             || CHR(10) ||
                 cv_debug_msg26 || iot_mst_regist_info_rec.item_description      || CHR(10) ||
                 cv_debug_msg23 || iot_mst_regist_info_rec.unit_meas_lookup_code || CHR(10) ||
                 cv_debug_msg22 || iot_mst_regist_info_rec.unit_price            || CHR(10) ||
                 cv_debug_msg30 || iot_mst_regist_info_rec.quantity              || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_vendor_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_inv_org_id
   * Description      : 搬送先組織情報取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_inv_org_id(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_inv_org_id'; -- プログラム名
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
    -- トークン用定数
    cv_tkn_value_iniv_info   CONSTANT VARCHAR2(30) := '搬送先情報';
    cv_tkn_value_iniv_org_id CONSTANT VARCHAR2(30) := '搬送先組織ＩＤ';
    cv_tkn_value_key_name1   CONSTANT VARCHAR2(30) := 'ユーザーＩＤ';
    cv_tkn_value_key_name2   CONSTANT VARCHAR2(30) := '出荷先事業所ＩＤ';
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
    -- ============================
    -- 搬送先情報取得
    -- ============================
    BEGIN
      SELECT xlv.location_id ship_to_location_id   -- 搬送先事業所ＩＤ
            ,xlv.dept_code   ship_to_location_code -- 搬送先事業所コード
            ,xev.person_id   ship_to_person_id     -- 搬送先要求者ＩＤ
      INTO   iot_mst_regist_info_rec.ship_to_location_id
            ,iot_mst_regist_info_rec.ship_to_location_code
            ,iot_mst_regist_info_rec.ship_to_person_id
      FROM   xxcso_employees_v2 xev -- 従業員マスタ（最新）ビュー
            ,xxcso_locations_v  xlv -- 事業所マスタ（最新）ビュー
      WHERE  xev.user_id            = fnd_global.user_id
      AND    xev.work_base_code_new = xlv.dept_code
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_iniv_info   -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_key_name1   -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => fnd_global.user_id       -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ============================
    -- 搬送先組織ＩＤ取得
    -- ============================
    BEGIN
      SELECT NVL(hlo.inventory_organization_id, fsp.inventory_organization_id) org_id -- 搬送先組織ＩＤ
      INTO   iot_mst_regist_info_rec.inventory_organization_id -- 搬送先組織ＩＤ
      FROM   hr_locations                 hlo -- 事業所マスタビュー
            ,financials_system_parameters fsp -- 発注明細ビュー
      WHERE  hlo.location_id = iot_mst_regist_info_rec.ship_to_location_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                               -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_iniv_org_id                    -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                             -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_key_name2                      -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                               -- トークンコード3
                       ,iv_token_value3 => iot_mst_regist_info_rec.ship_to_location_id -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 搬送先情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg32 || CHR(10) ||
                 cv_debug_msg29 || iot_mst_regist_info_rec.ship_to_location_id       || CHR(10) ||
                 cv_debug_msg31 || iot_mst_regist_info_rec.ship_to_location_code     || CHR(10) ||
                 cv_debug_msg59 || iot_mst_regist_info_rec.ship_to_person_id         || CHR(10) ||
                 cv_debug_msg33 || iot_mst_regist_info_rec.inventory_organization_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_inv_org_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_code_comb_id
   * Description      : 費用勘定科目ＩＤ取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_code_comb_id(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_code_comb_id';  -- プログラム名
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
    -- トークン用定数
    cv_tkn_value_ccid     CONSTANT VARCHAR2(50) := '費用勘定科目ＩＤ';
    cv_tkn_value_key_name CONSTANT VARCHAR2(50) := '従業員番号';
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
    -- ============================
    -- 費用勘定科目ＩＤ取得
    -- ============================
    BEGIN
      SELECT pec.default_code_combination_id default_code_combination_id -- デフォルト費用勘定科目ＩＤ
      INTO   iot_mst_regist_info_rec.code_combination_id -- 費用勘定科目ＩＤ
      FROM   per_employees_current_x pec
      WHERE  pec.employee_num = iot_mst_regist_info_rec.employee_number
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                        -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                           -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_ccid                       -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                         -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_key_name                   -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                           -- トークンコード3
                       ,iv_token_value3 => iot_mst_regist_info_rec.employee_number -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 費用勘定科目ＩＤをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg34 || CHR(10) ||
                 cv_debug_msg35 || iot_mst_regist_info_rec.code_combination_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_code_comb_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_po_req_interface
   * Description      : 購買依頼I/Fテーブル登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE reg_po_req_interface(
     it_mst_regist_info_rec   IN         g_mst_regist_info_rtype                                  -- マスタ登録情報
    ,ot_interface_source_code OUT NOCOPY po_requisitions_interface_all.interface_source_code%TYPE -- インターフェースソースＩＤ
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                                 -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                                 -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                                 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_po_req_interface'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_source_type_code      CONSTANT VARCHAR2(6)  := 'VENDOR';
    cv_destination_type_code CONSTANT VARCHAR2(7)  := 'EXPENSE';
    cv_authorization_status  CONSTANT VARCHAR2(10) := 'INCOMPLETE';
    --
    -- トークン用定数
    cv_tkn_value_un_number CONSTANT VARCHAR2(40) := '国連番号ビュー';
    cv_tkn_value_key_name  CONSTANT VARCHAR2(40) := '機種コード（国連番号）';
    cv_tkn_value_table     CONSTANT VARCHAR2(40) := '購買依頼I/Fテーブル';
    cv_tkn_value_sequence  CONSTANT VARCHAR2(40) := '購買依頼I/Fシーケンス';
    --
    -- *** ローカル変数 ***
    lt_hazard_class_id po_un_numbers_vl.hazard_class_id%TYPE;
    lt_transaction_id  po_requisitions_interface_all.transaction_id%TYPE;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ============================
    -- 機器区分取得
    -- ============================
    IF (it_mst_regist_info_rec.un_number IS NOT NULL) THEN
      BEGIN
        SELECT pun.hazard_class_id hazard_class_id
        INTO   lt_hazard_class_id
        FROM   po_un_numbers_vl pun
        WHERE  pun.un_number = it_mst_regist_info_rec.un_number
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name            -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03                    -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action                       -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_un_number            -- トークン値1
                         ,iv_token_name2  => cv_tkn_key_name                     -- トークンコード2
                         ,iv_token_value2 => cv_tkn_value_key_name               -- トークン値2
                         ,iv_token_name3  => cv_tkn_key_id                       -- トークンコード3
                         ,iv_token_value3 => it_mst_regist_info_rec.un_number -- トークン値3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
    -- ============================
    -- 取引ＩＤ取得
    -- ============================
    BEGIN
      SELECT xxcso_po_rqistns_in_all_s01.NEXTVAL transaction_id
      INTO   lt_transaction_id
      FROM   DUAL
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- その他のエラーの場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_sequence          -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sequence    -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ============================
    -- 購買依頼I/Fテーブル登録
    -- ============================
    BEGIN
      INSERT INTO po_requisitions_interface_all(
        /* 2009.08.21 K.Satomura 0001138対応 START */
        -- transaction_id              -- 取引ＩＤ
        --,process_flag                -- 処理フラグ
         process_flag                -- 処理フラグ
        /* 2009.08.21 K.Satomura 0001138対応 END */
        ,request_id                  -- 要求ＩＤ
        ,program_id                  -- プログラムＩＤ
        ,program_application_id      -- プログラムアプリケーションＩＤ
        ,program_update_date         -- プログラム更新日
        ,last_updated_by             -- 最終更新者
        ,last_update_date            -- 最終更新日
        ,last_update_login           -- 最終更新ログイン
        ,creation_date               -- 作成日
        ,created_by                  -- 作成者
        ,interface_source_code       -- インターフェースソースＩＤ
        ,source_type_code            -- ソースタイプコード
        ,destination_type_code       -- 搬送先タイプ
        ,item_description            -- 品目摘要
        ,quantity                    -- 数量
        ,unit_price                  -- 価格
        ,authorization_status        -- ステータス
        /* 2009.08.21 K.Satomura 0001138対応 START */
        ,batch_id                    -- バッチＩＤ
        /* 2009.08.21 K.Satomura 0001138対応 END */
        ,preparer_id                 -- 作成者ＩＤ
        ,autosource_flag             -- オートソースフラグ
        ,header_description          -- ヘッダー摘要
        ,urgent_flag                 -- 緊急フラグ
        ,charge_account_id           -- 費用勘定科目
        ,category_id                 -- カテゴリＩＤ
        ,unit_of_measure             -- 単位
        ,un_number                   -- 国連番号
        ,hazard_class_id             -- 危険分類
        ,destination_organization_id -- 搬送先組織ＩＤ
        ,deliver_to_location_id      -- 搬送先事業所ＩＤ
        ,deliver_to_location_code    -- 搬送先事業所コード
        ,deliver_to_requestor_id     -- 搬送先要求者ＩＤ
        ,suggested_buyer_id          -- SUGGESTED_BUYER_ID
        ,suggested_vendor_id         -- SUGGESTED_VENDOR_ID
        ,need_by_date                -- 希望入手日
        ,preparer_name               -- 作成者名
        ,variance_account_id         -- 原価差額勘定ＩＤ
        ,currency_unit_price         -- 通貨単価
        ,autosource_doc_header_id    -- 自動ソース文書ヘッダ
        ,autosource_doc_line_num     -- 自動ソース文書明細番号
        ,document_type_code          -- DOCUMENT_TYPE_CODE
        ,org_id                      -- ORG_ID
        ,tax_user_override_flag)     -- 税金上書きフラグ
      VALUES(
        /* 2009.08.21 K.Satomura 0001138対応 START */
        -- lt_transaction_id                                -- 取引ＩＤ
        --,cv_flag_yes                                      -- 処理フラグ
         cv_flag_yes                                      -- 処理フラグ
        /* 2009.08.21 K.Satomura 0001138対応 END */
        ,cn_request_id                                    -- 要求ＩＤ
        ,cn_program_id                                    -- プログラムＩＤ
        ,cn_program_application_id                        -- プログラムアプリケーションＩＤ
        ,cd_program_update_date                           -- プログラム更新日
        ,cn_last_updated_by                               -- 最終更新者
        ,cd_last_update_date                              -- 最終更新日
        ,cn_last_update_login                             -- 最終更新ログイン
        ,cd_creation_date                                 -- 作成日
        ,cn_created_by                                    -- 作成者
        ,TO_CHAR(lt_transaction_id)                       -- インターフェースソースＩＤ
        ,cv_source_type_code                              -- ソースタイプコード
        ,cv_destination_type_code                         -- 搬送先タイプ
        ,it_mst_regist_info_rec.item_description          -- 品目摘要
        ,it_mst_regist_info_rec.quantity                  -- 数量
        ,it_mst_regist_info_rec.unit_price                -- 価格
        ,cv_authorization_status                          -- ステータス
        /* 2009.08.21 K.Satomura 0001138対応 START */
        ,lt_transaction_id                                -- バッチＩＤ
        /* 2009.08.21 K.Satomura 0001138対応 END */
        ,it_mst_regist_info_rec.person_id                 -- 作成者ＩＤ
        ,cv_flag_no                                       -- オートソースフラグ
        ,it_mst_regist_info_rec.item_description          -- ヘッダー摘要
        ,cv_flag_no                                       -- 緊急フラグ
        ,it_mst_regist_info_rec.code_combination_id       -- 費用勘定科目
        ,it_mst_regist_info_rec.category_id               -- カテゴリＩＤ
        ,it_mst_regist_info_rec.unit_meas_lookup_code     -- 単位
        ,it_mst_regist_info_rec.un_number                 -- 国連番号
        ,lt_hazard_class_id                               -- 危険分類
        ,it_mst_regist_info_rec.inventory_organization_id -- 搬送先組織ＩＤ
        ,it_mst_regist_info_rec.ship_to_location_id       -- 搬送先事業所ＩＤ
        ,it_mst_regist_info_rec.ship_to_location_code     -- 搬送先事業所コード
        ,it_mst_regist_info_rec.ship_to_person_id         -- 搬送先要求者ＩＤ
        ,it_mst_regist_info_rec.agent_id                  -- SUGGESTED_BUYER_ID
        ,it_mst_regist_info_rec.vendor_id                 -- SUGGESTED_VENDOR_ID
        ,cd_sysdate                                       -- 希望入手日
        ,it_mst_regist_info_rec.user_name                 -- 作成者名
        ,it_mst_regist_info_rec.code_combination_id       -- 原価差額勘定ＩＤ
        ,it_mst_regist_info_rec.unit_price                -- 通貨単価
        ,it_mst_regist_info_rec.po_header_id              -- 自動ソース文書ヘッダ
        ,it_mst_regist_info_rec.line_num                  -- 自動ソース文書明細番号
        ,cv_price_type                                    -- DOCUMENT_TYPE_CODE
        ,cn_org_id                                        -- ORG_ID
        ,cv_flag_no                                       -- 税金上書きフラグ
      );
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_table       -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 取引ＩＤをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg36 || CHR(10) ||
                 cv_debug_msg37 || lt_transaction_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    ot_interface_source_code := TO_CHAR(lt_transaction_id);
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END reg_po_req_interface;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_vendor
   * Description      : 発注依頼ヘッダ・明細登録処理(A-9)
   ***********************************************************************************/
  PROCEDURE reg_vendor(
     it_interface_source_code IN         po_requisitions_interface_all.interface_source_code%TYPE -- インターフェースソースＩＤ
    ,on_request_id            OUT NOCOPY NUMBER                                                   -- 要求ＩＤ
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                                 -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                                 -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                                 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_vendor';  -- プログラム名
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
    cv_application CONSTANT VARCHAR2(2)  := 'PO';
    cv_program     CONSTANT VARCHAR2(20) := 'REQIMPORT';
    cv_argument6   CONSTANT VARCHAR2(2)  := 'N';
    --
    -- トークン用定数
    cv_tkn_value_proc_name CONSTANT VARCHAR2(100) := '購買依頼インポート処理';
    --
    -- *** ローカル変数 ***
    ln_request_id NUMBER;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ============================
    -- 発注依頼ヘッダ・明細登録処理
    -- ============================
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_program
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       /* 2009.08.21 K.Satomura 0001138対応 START */
                       --,argument1   => NULL
                       ,argument1   => it_interface_source_code
                       /* 2009.08.21 K.Satomura 0001138対応 END */
                       ,argument2   => it_interface_source_code
                       ,argument3   => NULL
                       ,argument4   => NULL
                       ,argument5   => NULL
                       ,argument6   => cv_argument6
                     );
    --
    IF (ln_request_id = 0) THEN
      -- 要求ＩＤが0の場合エラーメッセージを取得します。
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_06         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_proc_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード1
                     ,iv_token_value2 => lv_errbuf                -- トークン値1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- 要求ＩＤをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg38 || CHR(10) ||
                 cv_debug_msg39 || ln_request_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    COMMIT;
    on_request_id := ln_request_id;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : confirm_reg_vendor
   * Description      : 発注依頼ヘッダ・明細登録完了確認処理(A-10)
   ***********************************************************************************/
  PROCEDURE confirm_reg_vendor(
     in_request_id IN         NUMBER   -- 要求ＩＤ
    ,ov_errbuf     OUT NOCOPY VARCHAR2 -- エラー・メッセージ --# 固定 #
    ,ov_retcode    OUT NOCOPY VARCHAR2 -- リターン・コード   --# 固定 #
    ,ov_errmsg     OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'confirm_reg_vendor';  -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_profile_option_name1 CONSTANT VARCHAR2(30) := 'XXCSO1_VENDOR_WAIT_TIME';
    cv_profile_option_name2 CONSTANT VARCHAR2(30) := 'XXCSO1_CONC_MAX_WAIT_TIME';
    /* 2009.04.03 K.Satomura T1_0109対応 START */
    cv_purchase_request     CONSTANT VARCHAR2(30) := 'POR';
    /* 2009.04.03 K.Satomura T1_0109対応 END */
    --
    -- 実行フェーズ
    cv_phase_complete CONSTANT VARCHAR2(20) := 'COMPLETE'; -- 完了
    --
    -- ステータス
    cv_ret_status_normal CONSTANT VARCHAR2(20) := 'NORMAL'; -- 正常終了
    --
    -- トークン用定数
    cv_tkn_value_proc_name  CONSTANT VARCHAR2(50) := '購買依頼インポート処理';
    /* 2009.04.03 K.Satomura T1_0109対応 START */
    cv_tkn_value_req_header CONSTANT VARCHAR2(50) := '購買依頼ヘッダ';
    /* 2009.04.03 K.Satomura T1_0109対応 END */
    --
    -- *** ローカル変数 ***
    lb_return     BOOLEAN;
    lv_phase      VARCHAR2(5000);
    lv_status     VARCHAR2(5000);
    lv_dev_phase  VARCHAR2(5000);
    lv_dev_status VARCHAR2(5000);
    lv_message    VARCHAR2(5000);
    ln_work_count NUMBER;
    /* 2009.04.03 K.Satomura T1_0109対応 START */
    lt_requisition_header_id po_requisition_headers.requisition_header_id%TYPE;
    /* 2009.04.03 K.Satomura T1_0109対応 END */
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ================================
    -- 発注依頼ヘッダ・明細登録完了確認
    -- ================================
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => in_request_id
                   ,interval   => fnd_profile.value(cv_profile_option_name1)
                   ,max_wait   => fnd_profile.value(cv_profile_option_name2)
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF NOT (lb_return) THEN
      -- 戻り値がFALSEの場合
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_07         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_proc_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード1
                     ,iv_token_value2 => lv_errbuf                -- トークン値1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    IF (lv_dev_phase <> cv_phase_complete) THEN
      -- 実行フェーズが正常以外の場合
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_08         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_proc_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- トークン値1
                     ,iv_token_name2  => cv_tkn_proc_name         -- トークンコード2
                     ,iv_token_value2 => lv_dev_phase             -- トークン値2
                     ,iv_token_name3  => cv_tkn_proc_name         -- トークンコード3
                     ,iv_token_value3 => lv_dev_status            -- トークン値3
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    IF ((lv_dev_phase = cv_phase_complete)
      AND (lv_dev_status <> cv_ret_status_normal))
    THEN
      -- 実行フェーズが正常かつ、ステータスが正常以外の場合
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_09         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_proc_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- トークン値1
                     ,iv_token_name2  => cv_tkn_request_id        -- トークンコード2
                     ,iv_token_value2 => in_request_id            -- トークン値2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ============================
    -- 発注依頼ヘッダ・明細登録確認
    -- ============================
    SELECT COUNT(1) count
    INTO   ln_work_count
    FROM   po_requisition_headers prh -- 発注ヘッダーテーブル
    WHERE  prh.request_id = in_request_id
    ;
    --
    IF (ln_work_count <= 0) THEN
      -- 発注依頼ヘッダが登録されていない場合
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10         -- メッセージコード
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    /* 2009.04.03 K.Satomura T1_0109対応 START */
    -- ======================
    -- 購買依頼ヘッダ更新処理
    -- ======================
    BEGIN
      SELECT requisition_header_id requisition_header_id -- 購買依頼ヘッダＩＤ
      INTO   lt_requisition_header_id
      FROM   po_requisition_headers prh -- 購買依頼ヘッダービュー
      WHERE  prh.request_id = in_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10         -- メッセージコード
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    BEGIN
      UPDATE po_requisition_headers_all prh -- 購買依頼ヘッダーテーブル
      SET    prh.apps_source_code = cv_purchase_request
      WHERE  prh.requisition_header_id = lt_requisition_header_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_req_header  -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    /* 2009.04.03 K.Satomura T1_0109対応 END */
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END confirm_reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_customer_info
   * Description      : 顧客情報取得処理(A-11)
   ***********************************************************************************/
  PROCEDURE get_customer_info(
     it_sp_decision_header_id IN            xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype                              -- マスタ登録情報
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                                             -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                                             -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                                             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_customer_info'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sp_dec_cust_class_install CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1';
    --
    -- トークン用定数
    cv_tkn_value_customer_info  CONSTANT VARCHAR2(50) := '顧客情報';
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(50) := 'ＳＰ専決ヘッダＩＤ';
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
    -- ================================
    -- 顧客情報取得
    -- ================================
    BEGIN
      SELECT hca.account_number             account_number             -- 顧客コード
            ,hpa.party_name                 party_name                 -- 顧客名
            ,hpa.organization_name_phonetic organization_name_phonetic -- 顧客名カナ
            ,hlo.postal_code                postal_code                -- 郵便番号
            ,hlo.state                      state                      -- 都道府県
            ,hlo.city                       city                       -- 市・区
            ,hlo.address1                   address1                   -- 住所１
            ,hlo.address2                   address2                   -- 住所２
            ,hlo.address3                   address3                   -- 住所３
            ,hlo.address_lines_phonetic     address_lines_phonetic     -- 電話番号
            ,xca.sale_base_code             sale_base_code             -- 売上拠点コード
      INTO   iot_mst_regist_info_rec.account_number             -- 顧客コード
            ,iot_mst_regist_info_rec.party_name                 -- 顧客名
            ,iot_mst_regist_info_rec.organization_name_phonetic -- 顧客名カナ
            ,iot_mst_regist_info_rec.postal_code                -- 郵便番号
            ,iot_mst_regist_info_rec.state                      -- 都道府県
            ,iot_mst_regist_info_rec.city                       -- 市・区
            ,iot_mst_regist_info_rec.address1                   -- 住所１
            ,iot_mst_regist_info_rec.address2                   -- 住所２
            ,iot_mst_regist_info_rec.address3                   -- 住所３
            ,iot_mst_regist_info_rec.address_lines_phonetic     -- 電話番号
            ,iot_mst_regist_info_rec.sale_base_code             -- 売上拠点コード
      FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
            ,hz_cust_accounts        hca -- 顧客マスタ
            /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
            ,hz_cust_acct_sites      hcas -- 顧客サイトマスタ
            /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
            ,hz_parties              hpa -- パーティマスタ
            ,hz_party_sites          hps -- パーティサイトマスタ
            ,hz_locations            hlo -- 顧客事業所マスタ
            ,xxcmm_cust_accounts     xca -- 顧客アドオンマスタ
      WHERE xsd.sp_decision_header_id      = it_sp_decision_header_id
      AND   xsd.sp_decision_customer_class = cv_sp_dec_cust_class_install
      AND   xsd.customer_id                = hca.cust_account_id
      AND   hca.party_id                   = hpa.party_id
      AND   hpa.party_id                   = hps.party_id
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
      AND   hca.cust_account_id            = hcas.cust_account_id
      AND   hcas.party_site_id             = hps.party_site_id
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
      AND   hps.location_id                = hlo.location_id
      AND   xca.customer_id                = hca.cust_account_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action               -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_customer_info  -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name             -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_head_id -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id               -- トークンコード3
                       ,iv_token_value3 => it_sp_decision_header_id    -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 顧客情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg40 || CHR(10) ||
                 cv_debug_msg41 || iot_mst_regist_info_rec.account_number             || CHR(10) ||
                 cv_debug_msg42 || iot_mst_regist_info_rec.party_name                 || CHR(10) ||
                 cv_debug_msg43 || iot_mst_regist_info_rec.organization_name_phonetic || CHR(10) ||
                 cv_debug_msg44 || iot_mst_regist_info_rec.postal_code                || CHR(10) ||
                 cv_debug_msg45 || iot_mst_regist_info_rec.state                      || CHR(10) ||
                 cv_debug_msg46 || iot_mst_regist_info_rec.city                       || CHR(10) ||
                 cv_debug_msg47 || iot_mst_regist_info_rec.address1                   || CHR(10) ||
                 cv_debug_msg48 || iot_mst_regist_info_rec.address2                   || CHR(10) ||
                 cv_debug_msg49 || iot_mst_regist_info_rec.address3                   || CHR(10) ||
                 cv_debug_msg50 || iot_mst_regist_info_rec.address_lines_phonetic     || CHR(10) ||
                 cv_debug_msg51 || iot_mst_regist_info_rec.sale_base_code             || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_customer_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_po_req_line_id
   * Description      : 購買依頼明細ＩＤ取得処理(A-12)
   ***********************************************************************************/
  PROCEDURE get_po_req_line_id(
     in_request_id           IN     NUMBER                         -- 要求ＩＤ
    ,iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_po_req_line_id'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_value_po_req_line  CONSTANT VARCHAR2(50) := '購買依頼明細テーブル';
    cv_tkn_value_request_id   CONSTANT VARCHAR2(50) := '要求ＩＤ';
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
    -- ================================
    -- 購買依頼明細ＩＤ取得
    -- ================================
    BEGIN
      SELECT prl.requisition_line_id -- 購買依頼明細ＩＤ
      INTO   iot_mst_regist_info_rec.requisition_line_id -- 購買依頼明細ＩＤ
      FROM   po_requisition_lines prl
      WHERE  prl.request_id = in_request_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_po_req_line -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_request_id  -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => in_request_id            -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 購買依頼明細ＩＤをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg52 || CHR(10) ||
                 cv_debug_msg53 || iot_mst_regist_info_rec.requisition_line_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_po_req_line_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_temp_info
   * Description      : 情報テンプレート登録処理(A-14)
   ***********************************************************************************/
  PROCEDURE reg_temp_info(
     it_attribute_code       IN            por_template_attributes_v.attribute_code%TYPE -- アトリビュートコード
    ,it_attribute_name       IN            por_template_attributes_v.attribute_name%TYPE -- アトリビュート名
    ,iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype                       -- マスタ登録情報
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                                      -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                                      -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                                      -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_temp_info'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_attribute_name01 CONSTANT VARCHAR2(50) := 'SP_DECISION_NUMBER';        -- ＳＰ専決書番号
    cv_attribute_name02 CONSTANT VARCHAR2(50) := 'SP_DECISION_APPROVAL_DATE'; -- ＳＰ先決承認日
    cv_attribute_name03 CONSTANT VARCHAR2(50) := 'APPROVAL_BASE';             -- 申請拠点
    cv_attribute_name04 CONSTANT VARCHAR2(50) := 'APPLICANT';                 -- 申請者
    cv_attribute_name05 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CUSTOMER_CODE';  -- 設置先顧客コード
    cv_attribute_name06 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CUSTOMER_NAME';  -- 設置先顧客名
    cv_attribute_name07 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CUSTOMER_KANA';  -- 設置先顧客名カナ
    cv_attribute_name08 CONSTANT VARCHAR2(50) := 'INSTALL_AT_ZIP';            -- 設置先郵便番号
    cv_attribute_name09 CONSTANT VARCHAR2(50) := 'INSTALL_AT_PREFECTURES';    -- 設置先都道府県
    cv_attribute_name10 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CITY';           -- 設置先市区町村
    cv_attribute_name11 CONSTANT VARCHAR2(50) := 'INSTALL_AT_ADDR1';          -- 設置先住所１
    cv_attribute_name12 CONSTANT VARCHAR2(50) := 'INSTALL_AT_ADDR2';          -- 設置先住所２
    cv_attribute_name13 CONSTANT VARCHAR2(50) := 'INSTALL_AT_AREA_CODE';      -- 設置先住所３
    cv_attribute_name14 CONSTANT VARCHAR2(50) := 'INSTALL_AT_PHONE';          -- 電話番号
    cv_attribute_name15 CONSTANT VARCHAR2(50) := 'WORK_HOPE_YEAR';            -- 作業希望年
    cv_attribute_name16 CONSTANT VARCHAR2(50) := 'SOLD_CHARGE_BASE';          -- 売上担当拠点
    cv_attribute_name17 CONSTANT VARCHAR2(50) := 'WORK_HOPE_MONTH';           -- 作業希望月
    cv_attribute_name18 CONSTANT VARCHAR2(50) := 'WORK_HOPE_DAY';             -- 作業希望日
    --
    -- トークン用定数
    cv_tkn_value_table   CONSTANT VARCHAR2(100) := '情報テンプレート(アトリビュート名 = )' || it_attribute_name || ')';
    cv_tkn_value_item_id CONSTANT VARCHAR2(50)  := '品目（カテゴリ）ＩＤ';
    --
    -- *** ローカル変数 ***
    lt_attribute_value por_template_info.attribute_value%TYPE;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    lt_attribute_value := NULL;
    --
    -- ================================
    -- 情報テンプレート登録
    -- ================================
    CASE it_attribute_name
      WHEN cv_attribute_name01 THEN
        -- ＳＰ専決書番号
        lt_attribute_value := iot_mst_regist_info_rec.sp_decision_number;
        --
      WHEN cv_attribute_name02 THEN
        -- ＳＰ先決承認日
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.approval_complete_date, cv_date_format2);
        --
      WHEN cv_attribute_name03 THEN
        -- 申請拠点
        lt_attribute_value := iot_mst_regist_info_rec.app_base_code;
        --
      WHEN cv_attribute_name04 THEN
        -- 申請者
        lt_attribute_value := iot_mst_regist_info_rec.application_code;
        --
      WHEN cv_attribute_name05 THEN
        -- 設置先顧客コード
        lt_attribute_value := iot_mst_regist_info_rec.account_number;
        --
      WHEN cv_attribute_name06 THEN
        -- 設置先顧客名
        lt_attribute_value := iot_mst_regist_info_rec.party_name;
        --
      WHEN cv_attribute_name07 THEN
        -- 設置先顧客名カナ
        lt_attribute_value := iot_mst_regist_info_rec.organization_name_phonetic;
        --
      WHEN cv_attribute_name08 THEN
        -- 設置先郵便番号
        lt_attribute_value := iot_mst_regist_info_rec.postal_code;
        --
      WHEN cv_attribute_name09 THEN
        -- 設置先都道府県
        lt_attribute_value := iot_mst_regist_info_rec.state;
        --
      WHEN cv_attribute_name10 THEN
        -- 設置先市区町村
        lt_attribute_value := iot_mst_regist_info_rec.city;
        --
      WHEN cv_attribute_name11 THEN
        -- 設置先住所１
        lt_attribute_value := iot_mst_regist_info_rec.address1;
        --
      WHEN cv_attribute_name12 THEN
        -- 設置先住所２
        lt_attribute_value := iot_mst_regist_info_rec.address2;
        --
      WHEN cv_attribute_name13 THEN
        -- 設置先住所３
        lt_attribute_value := iot_mst_regist_info_rec.address3;
        --
      WHEN cv_attribute_name14 THEN
        -- 電話番号
        lt_attribute_value := iot_mst_regist_info_rec.address_lines_phonetic;
        --
      WHEN cv_attribute_name15 THEN
        -- 作業希望年
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.install_date, cv_year_format);
        --
      WHEN cv_attribute_name16 THEN
        -- 売上担当拠点
        lt_attribute_value := iot_mst_regist_info_rec.sale_base_code;
        --
      WHEN cv_attribute_name17 THEN
        -- 作業希望月
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.install_date, cv_month_format);
        --
      WHEN cv_attribute_name18 THEN
        -- 作業希望日
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.install_date, cv_day_format);
        --
      ELSE
        -- 上記以外の場合
        lt_attribute_value := NULL;
        --
    END CASE;
    --
    BEGIN
      INSERT INTO por_template_info(
         requisition_line_id  -- 発注依頼明細ＩＤ
        ,attribute_code       -- アトリビュートコード
        ,attribute_value      -- アトリビュート値
        ,created_by           -- 作成者
        ,creation_date        -- 作成日
        ,last_updated_by      -- 最終更新者
        ,last_update_date     -- 最終更新日
        ,last_update_login)   -- 最終更新ログイン
      VALUES(
         iot_mst_regist_info_rec.requisition_line_id -- 発注依頼明細ＩＤ
        ,it_attribute_code                           -- アトリビュートコード
        ,lt_attribute_value                          -- アトリビュート値
        ,cn_created_by                               -- 作成者
        ,cd_creation_date                            -- 作成日
        ,cn_last_updated_by                          -- 最終更新者
        ,cd_last_update_date                         -- 最終更新日
        ,cn_last_update_login                        -- 最終更新ログイン
      );
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_table       -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- 情報テンプレートをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg54 || CHR(10) ||
                 cv_debug_msg55 || iot_mst_regist_info_rec.requisition_line_id || CHR(10) ||
                 cv_debug_msg56 || it_attribute_name || CHR(10) ||
                 cv_debug_msg57 || lt_attribute_value || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END reg_temp_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_temp_info_terget
   * Description      : 情報テンプレート登録対象項目情報取得処理(A-13)
   ***********************************************************************************/
  PROCEDURE get_temp_info_terget(
     in_request_id            IN     NUMBER                         -- 要求ＩＤ
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_temp_info_terget'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_value_temp_info CONSTANT VARCHAR2(50) := '情報テンプレート';
    cv_tkn_value_item_id   CONSTANT VARCHAR2(50) := '品目（カテゴリ）ＩＤ';
    --
    -- *** ローカル変数 ***
    --
    -- *** ローカル・カーソル ***
    CURSOR temp_info_cur
    IS
      SELECT ptv.attribute_code attribute_code -- アトリビュートコード
            ,ptv.attribute_name attribute_name -- アトリビュート名
      FROM   por_template_assoc_v      pta -- テンプレート関連ビュー
            ,por_template_attributes_v ptv -- テンプレートアトリビュートビュー
            ,por_templates_all_b       ptb -- テンプレート表Ｂ
            ,por_templates_all_tl      ptt -- テンプレート表ＴＬ
      WHERE  pta.item_or_category_id = iot_mst_regist_info_rec.category_id
      AND    pta.region_code         = ptv.template_code
      AND    ptv.template_code       = ptb.template_code
      AND    ptb.template_code       = ptt.template_code
      AND    ptb.org_id              = cn_org_id
      AND    ptt.language            = cv_lang
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
    -- ====================================
    -- 情報テンプレート登録対象項目情報取得
    -- ====================================
    BEGIN
      --
      <<temp_info_loop>>
      FOR lt_temp_info_rec IN temp_info_cur LOOP
        -- ============================================
        -- A-14.情報テンプレート登録処理
        -- ============================================
        reg_temp_info(
           it_attribute_code       => lt_temp_info_rec.attribute_code
          ,it_attribute_name       => lt_temp_info_rec.attribute_name
          ,iot_mst_regist_info_rec => iot_mst_regist_info_rec
          ,ov_errbuf               => lv_errbuf
          ,ov_retcode              => lv_retcode
          ,ov_errmsg               => lv_errmsg
        );
        --
      END LOOP temp_info_loop;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                       -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_temp_info              -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                     -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_item_id                -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                       -- トークンコード3
                       ,iv_token_value3 => iot_mst_regist_info_rec.category_id -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_temp_info_terget;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,ov_errbuf                OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    lt_mst_regist_info_rec   g_mst_regist_info_rtype;                                  -- マスタ登録情報
    lt_interface_source_code po_requisitions_interface_all.interface_source_code%TYPE; -- インターフェースソースＩＤ
    ln_request_id            NUMBER;                                                   -- 購買依頼要求ＩＤ
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
    gn_target_cnt := 1;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    --
    -- ============
    -- A-1.初期処理
    -- ============
    start_proc(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================================
    -- A-2. ＳＰ専決ヘッダテーブル取得処理
    -- ===================================
    get_sp_dec_head_info(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,iot_mst_regist_info_rec  => lt_mst_regist_info_rec   -- マスタ登録情報
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ==========================
    -- A-3.従業員情報取得処理
    -- ==========================
    get_employee_info(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
      ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode             -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ============================================
    -- A-4.品目情報取得処理
    -- ============================================
    get_item_info(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
      ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode             -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ======================
    -- A-5.見積情報取得処理
    -- ======================
    get_vendor_info(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
      ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode             -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ==========================
    -- A-6.搬送先組織ＩＤ取得処理
    -- ==========================
    get_inv_org_id(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
      ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode             -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ============================
    -- A-7.費用勘定科目ＩＤ取得処理
    -- ============================
    get_code_comb_id(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
      ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode             -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===============================
    -- A-8.購買依頼I/Fテーブル登録処理
    -- ===============================
    reg_po_req_interface(
       it_mst_regist_info_rec   => lt_mst_regist_info_rec   -- マスタ登録情報
      ,ot_interface_source_code => lt_interface_source_code -- インターフェースソースＩＤ
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ================================
    -- A-9.発注依頼ヘッダ・明細登録処理
    -- ================================
    reg_vendor(
       it_interface_source_code => lt_interface_source_code -- インターフェースソースＩＤ
      ,on_request_id            => ln_request_id            -- 要求ＩＤ
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =========================================
    -- A-10.発注依頼ヘッダ・明細登録完了確認処理
    -- =========================================
    confirm_reg_vendor(
       in_request_id => ln_request_id -- 要求ＩＤ
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード   --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =========================================
    -- A-11.顧客情報取得処理
    -- =========================================
    get_customer_info(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,iot_mst_regist_info_rec  => lt_mst_regist_info_rec   -- マスタ登録情報
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =========================================
    -- A-12.購買依頼明細ＩＤ取得処理
    -- =========================================
    get_po_req_line_id(
       in_request_id           => ln_request_id          -- 要求ＩＤ
      ,iot_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
      ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode             -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =============================================
    -- A-13.情報テンプレート登録対象項目情報取得処理
    -- =============================================
    get_temp_info_terget(
       in_request_id           => ln_request_id          -- 要求ＩＤ
      ,iot_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
      ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode             -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    gn_normal_cnt := gn_normal_cnt + 1;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** 処理部共通例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf                   OUT NOCOPY VARCHAR2                                             -- エラーメッセージ #固定#
    ,retcode                  OUT NOCOPY VARCHAR2                                             -- エラーコード     #固定#
    ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
  )
  --
  --###########################  固定部 START   ###########################
  --
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
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
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- 終了メッセージコード
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
      --
    END IF;
    --
    --###########################  固定部 END   #############################
    --
    gn_target_cnt := gn_target_cnt + 1;
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
       -- エラー出力
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --エラーメッセージ
       );
       --
    END IF;
    --
    -- =======================
    -- A-x.終了処理
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
      --
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ステータスセット
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    --
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      --
    END IF;
    --
  EXCEPTION
    --
    --###########################  固定部 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  固定部 END   #######################################################
  --
END XXCSO020A04C;
/
