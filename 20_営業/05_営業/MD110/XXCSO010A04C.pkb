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
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_contract_data      データ取得(A-2)
 *  insert_data            ワークテーブル出力(A-3)
 *  act_svf                SVF起動(A-4)
 *  delete_data            ワークテーブルデータ削除(A-5)
 *  submain                メイン処理プロシージャ
 *                           SVF起動APIエラーチェック(A-6)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-7)
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
--
  -- 日付書式
  cv_flag_1             CONSTANT VARCHAR2(1)  := '1';             -- 処理A-2-1
  cv_flag_2             CONSTANT VARCHAR2(1)  := '2';             -- 処理A-2-2
  -- 有効
  cv_enabled_flag       CONSTANT VARCHAR2(1)  := 'Y';
  -- アクティブ
  cv_active_status      CONSTANT VARCHAR2(1)  := 'A';
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- 自動販売機設置契約書ID
  gt_contract_number    xxcso_contract_managements.contract_number%TYPE;             -- 契約書番号
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
    install_support_amt           xxcso_rep_auto_sale_cont.install_support_amt%TYPE,           -- 設置協賛金
    electricity_information       xxcso_rep_auto_sale_cont.electricity_information%TYPE,       -- 電気代情報
    transfer_commission_info      xxcso_rep_auto_sale_cont.transfer_commission_info%TYPE,      -- 振り込み手数料情報
    electricity_amount            xxcso_sp_decision_headers.electricity_amount%TYPE,           -- 電気代
    condition_contents_flag       BOOLEAN,                                              -- 販売手数料情報有無フラグ
    install_support_amt_flag      BOOLEAN,                                              -- 設置協賛金有無フラグ
    electricity_information_flag  BOOLEAN                                              -- 電気代情報有無フラグ
  );
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
            ,(CASE
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
                 '販売価格 ' || TO_CHAR(xsdl.sales_price)
                             || '円のとき、１本につき販売価格の '
                             || TO_CHAR(xsdl.bm1_bm_rate) || '%を支払う'
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
                       AND (xsdl.bm1_bm_amount IS NOT NULL AND xsdl.bm1_bm_amount <> '0')) THEN
                 '販売価格 ' || TO_CHAR(xsdl.sales_price)
                             || '円のとき、１本につき '
                             || TO_CHAR(xsdl.bm1_bm_amount) || '円を支払う'
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
                 '販売容器が ' || flvv.meaning
                               || 'のとき、１本につき売価の '
                               || TO_CHAR(xsdl.bm1_bm_rate) || '%を支払う'
               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                       AND (xsdl.bm1_bm_amount IS NOT NULL  AND xsdl.bm1_bm_amount <> '0')) THEN
                 '販売容器が ' || flvv.meaning
                               || 'のとき、１本につき '
                               || TO_CHAR(xsdl.bm1_bm_amount) || '円を支払う'
              END) condition_contents                               -- 条件内容
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
              ,xsdh.contract_year_date contract_period             -- 契約期間
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
              ,xba.bank_name bank_name                             -- 銀行名
              ,xba.branch_name blanches_name                       -- 支店名
              ,xba.bank_account_number bank_account_number         -- 口座番号
              ,xba.bank_account_name_kana bank_account_name_kana   -- 口座名義カナ
              ,xcm.install_account_number account_number           -- 設置先顧客コード
              ,xcm.publish_dept_code publish_base_code             -- 担当所属コード
              ,xlv2.location_name publish_base_name                -- 担当拠点名
              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) contract_effect_date                             -- 契約書発効日
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '')
                    || xlv2.address_line1) issue_belonging_address      -- 住所
              ,xlv2.location_name issue_belonging_name             -- 発行元所属名
              ,xsdh.install_support_amt install_support_amt        -- 初回設置協賛金
              ,xsdh.electricity_amount electricity_amount          -- 電気代
              ,(DECODE(xsdh.electricity_type
                          , cv_electricity_type_1,  '月額 定額 '|| xsdh.electricity_amount || '円'
                          , cv_electricity_type_2, '販売機に関わる電気代は、実費にて乙が支払う'
                          , '')
                ) electricity_information                          -- 電気代情報
              ,(DECODE(xd.bank_transfer_fee_charge_div
                          , cv_bank_trans_fee_div_1,  '振り込み手数料は甲の負担とする'
                          , cv_bank_trans_fee_div_2, '振り込み手数料は乙の負担とする'
                          , '振り込み手数料は発生致しません')
                ) transfer_commission_info                         -- 振り込み手数料情報
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
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.install_account_number = xcav.account_number
          AND  xcav.account_status = cv_active_status
          AND  xcav.party_status = cv_active_status
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xd.contract_management_id(+) = xcm.contract_management_id
          AND  xd.delivery_div(+) = cv_delivery_div_1
          AND  xd.delivery_id = xba.delivery_id(+)
          AND  xlv2.dept_code = xcm.publish_dept_code;
--
        SELECT  (CASE
                  WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
                       xev2.position_name_old
                  ELSE xev2.position_name_new
                END) issue_belonging_boss_position                 -- 発行元所属長職位名
                ,xev2.full_name issue_belonging_boss               -- 氏名
        INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- 発行元所属長職位名
                ,o_rep_cont_data_rec.issue_belonging_boss          -- 氏名
        FROM   xxcso_employees_v2         xev2     -- 従業員マスタ（最新）ビュー
        WHERE  ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
                   AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
               OR
                (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
                   AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
               )
        AND ROWNUM = 1;
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
              ,xsdh.contract_year_date contract_period                 -- 契約期間
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
              ,xbav.bank_name bank_name                                -- 銀行名
              ,xbav.bank_branch_name blanches_name                     -- 支店名
              ,xbav.bank_account_num bank_account_number               -- 口座番号
              ,xbav.account_holder_name_alt bank_account_name_kana     -- 口座名義カナ
              ,xcm.install_account_number account_number               -- 設置先顧客コード
              ,xcm.publish_dept_code publish_base_code                 -- 担当所属コード
              ,xlv2.location_name publish_base_name                    -- 担当拠点名
              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) contract_effect_date                                 -- 契約書発効日
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '') 
                  || xlv2.address_line1) issue_belonging_address       -- 住所
              ,xlv2.location_name issue_belonging_name                 -- 発行元所属名
              ,xsdh.install_support_amt install_support_amt            -- 初回設置協賛金
              ,xsdh.electricity_amount electricity_amount              -- 電気代
              ,DECODE(xsdh.electricity_type
                      , cv_electricity_type_1, '月額 定額 '|| xsdh.electricity_amount || '円'
                      , cv_electricity_type_2, '販売機に関わる電気代は、実費にて乙が支払う'
                      , '') electricity_information                   -- 電気代情報
              ,DECODE(pvs.bank_charge_bearer
                      , cv_bank_trans_fee_div_1, '振り込み手数料は甲の負担とする'
                      , cv_bank_trans_fee_div_2, '振り込み手数料は乙の負担とする'
                      , '振り込み手数料は発生致しません') transfer_commission_info -- 振り込み手数料情報
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
        FROM   xxcso_contract_managements xcm      -- 契約管理テーブル
              ,xxcso_cust_acct_sites_v    xcasv    -- 顧客マスタサイトビュー
              ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
              ,xxcso_sp_decision_custs    xsdc     -- ＳＰ専決顧客テーブル
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
               ,po_vendors pv                      -- 仕入先マスタ
               ,po_vendor_sites pvs                -- 仕入先サイトマスタ
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xsdc.sp_decision_customer_class = cv_sp_d_cust_class_3
          AND  xcm.install_account_id = xcasv.cust_account_id
          AND  xsdc.customer_id = xbav.vendor_id(+)
          AND  xlv2.dept_code = xcm.publish_dept_code
          AND  pv.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num)
          AND  pvs.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num);
--
        SELECT  (CASE
                  WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
                       xev2.position_name_old
                  ELSE xev2.position_name_new
                END)  issue_belonging_boss_position                -- 発行元所属長職位名
                ,xev2.full_name issue_belonging_boss               -- 氏名
        INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- 発行元所属長職位名
                ,o_rep_cont_data_rec.issue_belonging_boss          -- 氏名
        FROM    xxcso_employees_v2         xev2     -- 従業員マスタ（最新）ビュー
        WHERE   ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
                   AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
               OR
                (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
                   AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
                   AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
               )
        AND ROWNUM = 1;
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
    -- =================================
    -- 販売手数料情報取得（A-2-1,2 -2）
    -- =================================
    BEGIN
--
      -- 変数初期化
      ln_lines_cnt             := 0;               -- 明細件数
      ln_bm1_bm_rate           := 0;               -- ＢＭ１ＢＭ率
      ln_bm1_bm_amount         := 0;               -- ＢＭ１ＢＭ金額
      lb_bm1_bm_rate           := TRUE;            -- ＢＭ１ＢＭ率による定率判断フラグ
      lb_bm1_bm_amount         := TRUE;            -- ＢＭ１ＢＭ金額による定率判断フラグ
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
          -- ＢＭ１ＢＭ率、金額
          IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
            lb_bm1_bm_rate := FALSE;
          ELSE
            ln_bm1_bm_rate := l_sales_charge_rec.bm1_bm_rate;
          END IF;
          IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
            lb_bm1_bm_amount := FALSE;
          ELSE
            ln_bm1_bm_amount := l_sales_charge_rec.bm1_bm_amount;
          END IF;
--
          -- 締め日
          o_rep_cont_data_rec.close_day_code := l_sales_charge_rec.close_day_code;
          -- 払い月
          o_rep_cont_data_rec.transfer_month_code := l_sales_charge_rec.transfer_month_code;
          -- 払い日
          o_rep_cont_data_rec.transfer_day_code := l_sales_charge_rec.transfer_day_code;
        ELSE
          -- ＢＭ１ＢＭ率
          IF (lb_bm1_bm_rate = TRUE) THEN
            IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
              lb_bm1_bm_rate := FALSE;
            ELSIF (ln_bm1_bm_rate <> l_sales_charge_rec.bm1_bm_rate) THEN
              lb_bm1_bm_rate := FALSE;
            END IF;
          END IF;
          -- ＢＭ１ＢＭ金額
          IF (lb_bm1_bm_amount = TRUE) THEN
            IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
              lb_bm1_bm_amount := FALSE;
            ELSIF (ln_bm1_bm_amount <> l_sales_charge_rec.bm1_bm_amount) THEN
              lb_bm1_bm_amount := FALSE;
            END IF;
          END IF;
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
      -- 明細件数が1件を超える場合
      IF (ln_lines_cnt > 1) THEN
        -- 容器別、定率の場合
        IF ((lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
               AND (lb_bm1_bm_rate OR lb_bm1_bm_amount)) THEN
          -- ＢＭ１ＢＭ率
          IF (lb_bm1_bm_rate) THEN
            lv_cond_conts_tmp := '販売金額につき、１本 ' || ln_bm1_bm_rate || '%を支払う';
          -- ＢＭ１ＢＭ金額
          ELSE
            lv_cond_conts_tmp := '販売金額につき、１本 ' || ln_bm1_bm_amount || '円を支払う';
          END IF;
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
--
          -- ログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => '' || CHR(10) || '販売手数料情報が容器別、定率です。'
          );
--
        ELSE
          -- 条件内容が12件に満たない場合、最終行に「以下余白」をセット
          IF (ln_lines_cnt < 12) THEN
          -- 条件内容セット
            IF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_2 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_3 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_4 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_5 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_6 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_7 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_8 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_9 := cv_cond_conts_space;    -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_10 := cv_cond_conts_space;   -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_11 := cv_cond_conts_space;   -- 以下余白
            ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
              o_rep_cont_data_rec.condition_contents_12 := cv_cond_conts_space;   -- 以下余白
            END IF;
          END IF;
        END IF;
      END IF;
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
          ,install_support_amt              -- 設置協賛金
          ,electricity_information          -- 電気代情報
          ,transfer_commission_info         -- 振り込み手数料情報
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
          ,i_rep_cont_data_rec.install_support_amt              -- 設置協賛金
          ,i_rep_cont_data_rec.electricity_information          -- 電気代情報
          ,i_rep_cont_data_rec.transfer_commission_info         -- 振り込み手数料情報
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
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '自動販売機設置契約書PDFを出力しました。'
      );
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
--
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ワークテーブルデータ削除(A-5)
   ***********************************************************************************/
  PROCEDURE delete_data(
     i_rep_cont_data_rec    IN         g_rep_cont_data_rtype  -- 契約書データ
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
    -- *** ローカル変数 ***
    lt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- 自動販売機設置契約書ID
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
      ,buff   => '' || CHR(10) || '<< 帳票出力パターン >>'
    );
--
    -- ① 販売手数料有り、且つ設置協賛金有り、且つ電気代有りの場合
    IF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
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
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
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
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
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
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
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
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
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
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
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
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
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
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
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

    -- ========================================
    -- A-4.SVF起動
    -- ========================================
    act_svf(
       iv_svf_form_nm  => lv_svf_form_nm
      ,iv_svf_query_nm => lv_svf_query_nm
      ,ov_errbuf       => lv_errbuf_svf                 -- エラー・メッセージ            --# 固定 #
      ,ov_retcode      => lv_retcode_svf                -- リターン・コード              --# 固定 #
      ,ov_errmsg       => lv_errmsg_svf                 -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    -- ========================================
    -- A-5.ワークテーブルデータ削除
    -- ========================================
    delete_data(
       i_rep_cont_data_rec  => l_rep_cont_data_rec      -- 契約書データ
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
    -- A-6.SVF起動APIエラーチェック
    -- ========================================
    IF (lv_retcode_svf = cv_status_error) THEN
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;

--
    -- 成功件数カウント
    gn_normal_cnt := gn_normal_cnt + 1;
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
    -- A-7.終了処理 
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
