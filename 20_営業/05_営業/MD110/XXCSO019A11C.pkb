CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A11C(body)
 * Description      : 指定された拠点CD・基準日を元に、所属している営業員が、基準日に対して
 *                    有効期間中の担当顧客のデータを取得し、CSV形式で出力ファイルに出力します。
 * MD.050           : MD050_CSO_019_A11_担当営業員一覧データ出力
 *
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  output_csv_rec              出力ファイルへのデータ出力 (A-3)
 *  submain                     メイン処理プロシージャ
 *                                  担当営業員データ抽出 (A-2)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010-03-19    1.0   Kazuyo.Hosoi     新規作成
 *  2011-03-15    1.1   Naoki.Horigome   E_本稼動_01946対応
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
--  gn_skip_cnt               NUMBER;                    -- スキップ件数
--
  gv_company_cd             VARCHAR2(2000);            -- 会社コード(固定値001)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A11C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- アプリケーション短縮名
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- アドオン：共通・IF領域
--
--
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00610';  -- パラメータ拠点CD
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00611';  -- パラメータ基準日
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00612';  -- パラメータ基準日エラーメッセージ
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー 
  -- 2011-03-15 Ver1.1 Add Naoki.Horigome strat
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00239';  -- 対象データなしメッセージ
  -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
  -- トークンコード
  cv_tkn_bs_cd           CONSTANT VARCHAR2(20)  := 'BASE_CD';
  cv_tkn_stndrd_dt       CONSTANT VARCHAR2(20)  := 'STANDARD_DATE';
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<<業務処理日付、基準日付>>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'od_process_date = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := 'od_standard_date = ';
  --
  cv_dt_format           CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           -- 日付書式
  cv_mnth_format         CONSTANT VARCHAR2(10)  := 'MM';                   -- 日付書式
  --
  cv_whick_log           CONSTANT VARCHAR2(3)   := 'LOG';                  -- ログ
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gb_hdr_put_flg         BOOLEAN DEFAULT FALSE; -- CSVヘッダー出力フラグ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
     account_number         xxcso_cust_resources_v.account_number%TYPE          -- 顧客CD
    ,party_name             xxcso_cust_accounts_v.party_name%TYPE               -- 顧客名
    ,customer_class_code    xxcso_cust_accounts_v.customer_class_code%TYPE      -- 顧客区分
    ,customer_class_name    xxcso_cust_accounts_v.customer_class_name%TYPE      -- 顧客区分名
    ,customer_status        xxcso_cust_accounts_v.customer_status%TYPE          -- 顧客ステータス
    ,customer_status_name   fnd_lookup_values_vl.meaning%TYPE                   -- 顧客ステータス名
    ,business_low_type      xxcso_cust_accounts_v.business_low_type%TYPE        -- 業態小分類
    ,business_low_type_name fnd_lookup_values_vl.meaning%TYPE                   -- 業態小分類名
    ,sale_base_code         xxcso_cust_accounts_v.sale_base_code%TYPE           -- 売上拠点
    ,rsv_sale_base_act_date xxcso_cust_accounts_v.rsv_sale_base_act_date%TYPE   -- 予約売上拠点有効開始日
    ,rsv_sale_base_code     xxcso_cust_accounts_v.rsv_sale_base_code%TYPE       -- 予約売上拠点
    ,route_no               xxcso_cust_routes_v.route_number%TYPE               -- ルートNo
    ,employee_number        xxcso_resources_v2.employee_number%TYPE             -- 担当営業員CD
    ,full_name              xxcso_resources_v2.full_name%TYPE                   -- 担当営業員名
    ,start_date_active      xxcso_cust_resources_v.start_date_active%TYPE       -- 担当営業員開始日
    ,end_date_active        xxcso_cust_resources_v.end_date_active%TYPE         -- 担当営業員終了日
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code        IN         VARCHAR2     -- 拠点コード
   ,iv_standard_date    IN         VARCHAR2     -- 基準日(1：当月 / 2：翌月)
   ,od_process_date     OUT NOCOPY DATE         -- 業務処理日付
   ,od_standard_date    OUT NOCOPY DATE         -- 基準日付
   ,ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- プログラム名
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    -- 参照タイプ
    cv_lkup_tp_standard_date CONSTANT VARCHAR2(100) := 'XXCSO1_STANDARD_DATE';
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
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
    cv_ths_mnth             CONSTANT VARCHAR2(1)   := '1';             -- 当月
    cv_nxt_mnth             CONSTANT VARCHAR2(1)   := '2';             -- 翌月
    -- *** ローカル変数 ***
    ld_sysdate           DATE;             -- システム日付
    lv_msg               VARCHAR2(5000);   -- メッセージ格納用
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    lt_standard_date_name fnd_lookup_values_vl.meaning%TYPE;
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================
    -- システム日付取得処理 
    -- =====================
    ld_sysdate := SYSDATE;
--
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    -- ===================
    -- 基準日名称取得処理 
    -- ===================
    SELECT flv.meaning
    INTO   lt_standard_date_name
    FROM   fnd_lookup_values_vl flv
    WHERE  flv.lookup_type = cv_lkup_tp_standard_date
    AND    flv.lookup_code = iv_standard_date
    ;
    
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
--
    -- =============================
    -- 入力パラメータメッセージ出力 
    -- =============================
    -- パラメータ拠点CD
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name              -- アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_01         -- メッセージコード
                  ,iv_token_name1  => cv_tkn_bs_cd             -- トークンコード1
                  ,iv_token_value1 => iv_base_code             -- トークン値1
                 );
--
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
--
    -- パラメータ基準日
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name              -- アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_02         -- メッセージコード
                  ,iv_token_name1  => cv_tkn_stndrd_dt         -- トークンコード1
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome start
--                  ,iv_token_value1 => iv_standard_date         -- トークン値1
                  ,iv_token_value1 => lt_standard_date_name         -- トークン値1
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome end
                 );
--
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
--
    -- 空行出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
    );
--
    -- =============================
    -- パラメータ.基準日妥当性チェック
    -- =============================
    -- パラメータ.基準日が1または2でない場合はエラー
    IF ((iv_standard_date <> cv_ths_mnth)
      AND (iv_standard_date <> cv_nxt_mnth)) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_03             -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- 業務処理日付取得処理
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日付取得に失敗した場合
    IF (od_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_04             -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- 基準日付導出処理
    -- =====================
    IF (iv_standard_date = cv_ths_mnth) THEN
      od_standard_date := od_process_date; -- 業務処理日付
    ELSIF (iv_standard_date = cv_nxt_mnth) THEN
      -- 業務処理月の翌月第一日
      SELECT TRUNC(ADD_MONTHS(od_process_date,1),cv_mnth_format)
      INTO   od_standard_date
      FROM   dual
      ;
    END IF;
    -- *** DEBUG_LOG START ***
    -- 業務処理日付、基準日付をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(od_process_date,cv_dt_format)|| CHR(10) ||
                 cv_debug_msg3 || TO_CHAR(od_standard_date,cv_dt_format)|| CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_rec
   * Description      : 出力ファイルへのデータ出力 (A-3)
   ***********************************************************************************/
  PROCEDURE output_csv_rec(
     i_cst_rsurcs_dt_rec    IN         g_get_data_rtype       -- 担当営業員データ
    ,iv_base_code           IN         VARCHAR2               -- 拠点コード
    ,id_standard_date       IN         DATE                   -- 基準日付
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- リターン・コード             --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'output_csv_rec';       -- プログラム名
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
    --
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome start
--    cv_hdr_output_dt           CONSTANT VARCHAR2(100)  := '出力基準日';           -- 出力基準日
--    cv_hdr_bs_cd               CONSTANT VARCHAR2(100)  := '出力拠点CD';           -- 出力拠点CD
--    cv_hdr_acct_num            CONSTANT VARCHAR2(100)  := '顧客CD';               -- 顧客CD
--    cv_hdr_prty_nm             CONSTANT VARCHAR2(100)  := '顧客名';               -- 顧客名
--    cv_hdr_cust_cls_cd         CONSTANT VARCHAR2(100)  := '顧客区分';             -- 顧客区分
--    cv_hdr_cust_cls_nm         CONSTANT VARCHAR2(100)  := '顧客区分名';           -- 顧客区分名
--    cv_hdr_cust_stts           CONSTANT VARCHAR2(100)  := '顧客ステータス';       -- 顧客ステータス
--    cv_hdr_cust_stts_nm        CONSTANT VARCHAR2(100)  := '顧客ステータス名';     -- 顧客ステータス名
--    cv_hdr_bsnss_lw_tp         CONSTANT VARCHAR2(100)  := '業態小分類';           -- 業態小分類
--    cv_hdr_bsnss_lw_tp_nm      CONSTANT VARCHAR2(100)  := '業態小分類名';         -- 業態小分類名
--    cv_hdr_sl_bs_cd            CONSTANT VARCHAR2(100)  := '売上拠点CD';           -- 売上拠点CD
--    cv_hdr_rsv_sl_bs_act_dt    CONSTANT VARCHAR2(100)  := '予約売上拠点開始日';   -- 予約売上拠点開始日
--    cv_hdr_rsv_sl_bs_cd        CONSTANT VARCHAR2(100)  := '予約売上拠点';         -- 予約売上拠点
--    cv_hdr_route_no            CONSTANT VARCHAR2(100)  := 'ルートNo';             -- ルートNo
--    cv_hdr_emply_num           CONSTANT VARCHAR2(100)  := '担当営業員CD';         -- 担当営業員CD
--    cv_hdr_fll_nm              CONSTANT VARCHAR2(100)  := '担当営業員名';         -- 担当営業員名
--    cv_hdr_strt_dt_active      CONSTANT VARCHAR2(100)  := '担当営業員開始日';     -- 担当営業員開始日
--    cv_hdr_ed_dt_active        CONSTANT VARCHAR2(100)  := '担当営業員終了日';     -- 担当営業員終了日
    cv_hdr_output            CONSTANT VARCHAR2(100)  := 'XXCSO1_SALES_MEMBER_LIST_HEAD';  -- 出力ヘッダ部
    
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome end
    --
    cb_false                   CONSTANT BOOLEAN        := FALSE;
    cb_true                    CONSTANT BOOLEAN        := TRUE;
    -- *** ローカル変数 ***
    lv_hdr_data                VARCHAR2(4000);   --ヘッダー行格納用
    lv_line_data               VARCHAR2(4000);   --明細行格納用
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
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
    -- 変数初期化
    lv_hdr_data  := NULL;
    lv_line_data := NULL;
    -- ==========================
    -- CSVデータの項目名を出力
    -- ==========================
    IF (gb_hdr_put_flg = cb_false) THEN
      -- 2011-03-15 Ver1.1 Mod Naoki.Horigome start
--      lv_hdr_data := cv_sep_wquot || cv_hdr_output_dt        || cv_sep_wquot || cv_sep_com ||   -- 出力基準日
--                     cv_sep_wquot || cv_hdr_bs_cd            || cv_sep_wquot || cv_sep_com ||   -- 出力拠点CD
--                     cv_sep_wquot || cv_hdr_acct_num         || cv_sep_wquot || cv_sep_com ||   -- 顧客CD
--                     cv_sep_wquot || cv_hdr_prty_nm          || cv_sep_wquot || cv_sep_com ||   -- 顧客名
--                     cv_sep_wquot || cv_hdr_cust_cls_cd      || cv_sep_wquot || cv_sep_com ||   -- 顧客区分
--                     cv_sep_wquot || cv_hdr_cust_cls_nm      || cv_sep_wquot || cv_sep_com ||   -- 顧客区分名
--                     cv_sep_wquot || cv_hdr_cust_stts        || cv_sep_wquot || cv_sep_com ||   -- 顧客ステータス
--                     cv_sep_wquot || cv_hdr_cust_stts_nm     || cv_sep_wquot || cv_sep_com ||   -- 顧客ステータス名
--                     cv_sep_wquot || cv_hdr_bsnss_lw_tp      || cv_sep_wquot || cv_sep_com ||   -- 業態小分類
--                     cv_sep_wquot || cv_hdr_bsnss_lw_tp_nm   || cv_sep_wquot || cv_sep_com ||   -- 業態小分類名
--                     cv_sep_wquot || cv_hdr_sl_bs_cd         || cv_sep_wquot || cv_sep_com ||   -- 売上拠点CD
--                     cv_sep_wquot || cv_hdr_rsv_sl_bs_act_dt || cv_sep_wquot || cv_sep_com ||   -- 予約売上拠点開始日
--                     cv_sep_wquot || cv_hdr_rsv_sl_bs_cd     || cv_sep_wquot || cv_sep_com ||   -- 予約売上拠点
--                     cv_sep_wquot || cv_hdr_route_no         || cv_sep_wquot || cv_sep_com ||   -- ルートNo
--                     cv_sep_wquot || cv_hdr_emply_num        || cv_sep_wquot || cv_sep_com ||   -- 担当営業員CD
--                     cv_sep_wquot || cv_hdr_fll_nm           || cv_sep_wquot || cv_sep_com ||   -- 担当営業員名
--                     cv_sep_wquot || cv_hdr_strt_dt_active   || cv_sep_wquot || cv_sep_com ||   -- 担当営業員開始日
--                     cv_sep_wquot || cv_hdr_ed_dt_active     || cv_sep_wquot                    -- 担当営業員終了日
--                     ;
--
      -- ==========================
      -- 参照タイプの取得
      -- ==========================
--
      -- ヘッダ部
      SELECT flv.attribute1 || flv.attribute2
      INTO   lv_hdr_data
      FROM   fnd_lookup_values_vl flv
      WHERE  flv.lookup_type = cv_hdr_output;
      -- 2011-03-15 Ver1.1 Mod Naoki.Horigome end
--
      -- ヘッダーの出力
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_hdr_data
                       );
      gb_hdr_put_flg := cb_true;
    END IF;
    -- ==========================
    -- 担当営業員データ
    -- ==========================
    lv_line_data := cv_sep_wquot || TO_CHAR(id_standard_date, cv_dt_format)    || cv_sep_wquot || cv_sep_com ||   -- 出力基準日
                    cv_sep_wquot || iv_base_code                               || cv_sep_wquot || cv_sep_com ||   -- 出力拠点CD
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.account_number         || cv_sep_wquot || cv_sep_com ||   -- 顧客CD
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.party_name             || cv_sep_wquot || cv_sep_com ||   -- 顧客名
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_class_code    || cv_sep_wquot || cv_sep_com ||   -- 顧客区分
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_class_name    || cv_sep_wquot || cv_sep_com ||   -- 顧客区分名
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_status        || cv_sep_wquot || cv_sep_com ||   -- 顧客ステータス
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_status_name   || cv_sep_wquot || cv_sep_com ||   -- 顧客ステータス名
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.business_low_type      || cv_sep_wquot || cv_sep_com ||   -- 業態小分類
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.business_low_type_name || cv_sep_wquot || cv_sep_com ||   -- 業態小分類名
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.sale_base_code         || cv_sep_wquot || cv_sep_com ||   -- 売上拠点CD
                    cv_sep_wquot || TO_CHAR(i_cst_rsurcs_dt_rec.rsv_sale_base_act_date, cv_dt_format) || cv_sep_wquot || cv_sep_com ||   -- 予約売上拠点開始日
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.rsv_sale_base_code     || cv_sep_wquot || cv_sep_com ||   -- 予約売上拠点
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.route_no               || cv_sep_wquot || cv_sep_com ||   -- ルートNo
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.employee_number        || cv_sep_wquot || cv_sep_com ||   -- 担当営業員CD
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.full_name              || cv_sep_wquot || cv_sep_com ||   -- 担当営業員名
                    cv_sep_wquot || TO_CHAR(i_cst_rsurcs_dt_rec.start_date_active, cv_dt_format) || cv_sep_wquot || cv_sep_com ||   -- 担当営業員開始日
                    cv_sep_wquot || TO_CHAR(i_cst_rsurcs_dt_rec.end_date_active, cv_dt_format)   || cv_sep_wquot                    -- 担当営業員終了日
                   ;
    -- ヘッダーの出力
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT
                     ,buff   => lv_line_data
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
  END output_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     iv_base_code        IN         VARCHAR2   -- 拠点コード
    ,iv_standard_date    IN         VARCHAR2   -- 基準日(1：当月 / 2：翌月)
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
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
    -- パラメータ基準日
    cv_ths_mnth             CONSTANT VARCHAR2(1)   := '1';             -- 当月
    cv_nxt_mnth             CONSTANT VARCHAR2(1)   := '2';             -- 翌月
    -- 参照タイプ
    cv_lkup_tp_kokyaku_status CONSTANT VARCHAR2(100) := 'XXCMM_CUST_KOKYAKU_STATUS';
    cv_lkup_tp_gyotai_sho     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_SHO';
    -- 顧客ステータス
    cv_cst_clss_cd_cust       CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '10'; -- 顧客区分＝顧客
    cv_cst_clss_cd_uesama     CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '12'; -- 顧客区分＝上様顧客
    cv_cst_clss_cd_cyclic     CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '15'; -- 顧客区分＝巡回
    cv_cst_clss_cd_tonya      CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '16'; -- 顧客区分＝問屋帳合先
    cv_cst_clss_cd_plan       CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '17'; -- 顧客区分＝計画
    -- 顧客区分コード
    cv_cst_stts_mc_cnddt      CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '10'; -- 顧客ステータス＝ＭＣ候補
    cv_cst_stts_mc            CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '20'; -- 顧客ステータス＝ＭＣ
    cv_cst_stts_sp_dcsn       CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '25'; -- 顧客ステータス＝ＳＰ決裁済
    cv_cst_stts_apprvd        CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '30'; -- 顧客ステータス＝承認済
    cv_cst_stts_cstmr         CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '40'; -- 顧客ステータス＝顧客
    cv_cst_stts_brk           CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '50'; -- 顧客ステータス＝休止
    cv_cst_stts_abrt_apprvd   CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '90'; -- 顧客ステータス＝中止決裁済
    cv_cst_stts_nt_applcbl    CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '99'; -- 顧客ステータス＝対象外
    --
    cv_no                     CONSTANT VARCHAR2(1)                                    :=  'N';
    -- *** ローカル変数 ***
    ld_process_date           DATE;                             -- 業務処理日付
    ld_standard_date          DATE;                             -- 基準日
    lv_standard_date          VARCHAR2(10);                     -- 入力パラメータ：基準日
    lv_base_code              VARCHAR2(150);                    -- 入力パラメータ：拠点CD
    -- *** ローカル・カーソル ***
    CURSOR    get_cst_rsurcs_data_cur
    IS
      SELECT xcrv.account_number         account_number         --顧客CD
      ,      xcav.party_name             party_name             --顧客名
      ,      xcav.customer_class_code    customer_class_code    --顧客区分
      ,      xcav.customer_class_name    customer_class_name    --顧客区分名
      ,      xcav.customer_status        customer_status        --顧客ステータス
      ,      (
              SELECT flv.meaning
              FROM   fnd_lookup_values_vl flv
              WHERE  flv.lookup_type = cv_lkup_tp_kokyaku_status
              AND    flv.lookup_code = xcav.customer_status
             ) customer_status_name                             --顧客ステータス名
      ,      xcav.business_low_type      business_low_type      --業態小分類
      ,      (
              SELECT flv.meaning
              FROM   fnd_lookup_values_vl flv
              WHERE  flv.lookup_type = cv_lkup_tp_gyotai_sho
              AND    flv.lookup_code = xcav.business_low_type
             ) business_low_type_name                           --業態小分類名
      ,      xcav.sale_base_code         sale_base_code         --売上拠点
      ,      xcav.rsv_sale_base_act_date rsv_sale_base_act_date --予約売上拠点有効開始日
      ,      xcav.rsv_sale_base_code     rsv_sale_base_code     --予約売上拠点
      ,      (
              SELECT xcrtv.route_number
              FROM   xxcso_cust_routes_v xcrtv
              WHERE  xcrtv.account_number = xcrv.account_number
              AND    ld_standard_date BETWEEN xcrtv.start_date_active AND NVL(xcrtv.end_date_active,ld_standard_date)
              AND    ROWNUM=1
             ) route_no                                         --ルートNo
      ,      xrv2.employee_number        employee_number        --担当営業員CD
      ,      xrv2.full_name              full_name              --担当営業員名
      ,      xcrv.start_date_active      start_date_active      --担当営業員開始日
      ,      xcrv.end_date_active        end_date_active        --担当営業員終了日
      FROM   xxcso_resources_v2 xrv2
      ,      ( --終了日が未来日のリソースグループのみ
               SELECT jrgb.attribute1    rsg_dept_code,
                      jrgm.resource_id   resource_id
               FROM   jtf_rs_groups_b jrgb,
                      jtf_rs_group_members jrgm
               WHERE  NVL(jrgb.end_date_active, ld_process_date) >= ld_process_date
               AND    jrgm.delete_flag = cv_no
               AND    jrgm.group_id = jrgb.group_id
             ) jrgmo
      ,      xxcso_cust_resources_v xcrv   -- 顧客担当営業員ビュー
      ,      xxcso_cust_accounts_v  xcav   -- 顧客マスタビュー
      WHERE  jrgmo.rsg_dept_code  = lv_base_code
      AND    xrv2.resource_id     = jrgmo.resource_id
      AND    (xxcso_util_common_pkg.get_rs_base_code(jrgmo.resource_id, ld_standard_date) = jrgmo.rsg_dept_code)
      AND    xcrv.employee_number =  xrv2.employee_number
      AND    ld_standard_date BETWEEN xcrv.start_date_active AND NVL(xcrv.end_date_active,ld_standard_date)
      AND    xcav.account_number  =  xcrv.account_number
      AND     ( 
                (lv_standard_date = cv_ths_mnth AND (xcav.sale_base_code = jrgmo.rsg_dept_code OR xcav.sale_base_code IS NULL))
                OR
                (lv_standard_date = cv_nxt_mnth AND (xcav.sale_base_code IS NULL ))
                OR
                (lv_standard_date = cv_nxt_mnth AND (
                                                     xcav.sale_base_code = jrgmo.rsg_dept_code   --売上拠点が指定拠点
                                                     AND 
                                                     (
                                                       xcav.rsv_sale_base_act_date IS NULL       --予約がない
                                                       OR 
                                                       xcav.rsv_sale_base_act_date > ld_standard_date  --予約が翌月１日より未来
                                                      )
                                                     )
                )
                OR
                (lv_standard_date = cv_nxt_mnth AND (
                                                     xcav.rsv_sale_base_code = jrgmo.rsg_dept_code  --予約売上拠点が指定拠点
                                                     AND
                                                     xcav.rsv_sale_base_act_date >= ld_standard_date --予約が翌月１日以降
                                                    )
                )
              )
      AND    (
               ((xcav.customer_class_code IS NULL) AND (xcav.customer_status IN (cv_cst_stts_mc_cnddt,cv_cst_stts_mc)))
               OR
               ((xcav.customer_class_code IN (cv_cst_clss_cd_cust)) AND (xcav.customer_status IN (cv_cst_stts_mc_cnddt ,cv_cst_stts_mc,
                                                                                                  cv_cst_stts_sp_dcsn  ,cv_cst_stts_apprvd,
                                                                                                  cv_cst_stts_cstmr    ,cv_cst_stts_brk
               )))
               OR
               ((xcav.customer_class_code IN (cv_cst_clss_cd_uesama)) AND (xcav.customer_status IN (cv_cst_stts_apprvd,cv_cst_stts_cstmr)))
               OR
               ((xcav.customer_class_code IN (cv_cst_clss_cd_cyclic,cv_cst_clss_cd_tonya,cv_cst_clss_cd_plan)) AND (xcav.customer_status IN (cv_cst_stts_nt_applcbl)))
             )
      ORDER BY xrv2.employee_number
              ,route_no
              ,xcrv.account_number
    ;
    -- *** ローカル・レコード ***
    l_cst_rsurcs_data_rec   get_cst_rsurcs_data_cur%ROWTYPE;
    l_get_data_rec          g_get_data_rtype;
    -- *** ローカル・例外 ***
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
    gn_error_cnt  := 0;
--    gn_skip_cnt   :=0;
    -- 入力パラメータを変数に格納
    lv_base_code     := iv_base_code;
    lv_standard_date := iv_standard_date;
--
    -- ================================
    -- A-1.初期処理
    -- ================================
    init(
       iv_base_code        => lv_base_code      -- 拠点コード
      ,iv_standard_date    => lv_standard_date  -- 基準日(1：当月 / 2：翌月)
      ,od_process_date     => ld_process_date   -- 業務処理日付
      ,od_standard_date    => ld_standard_date  -- 基準日付
      ,ov_errbuf           => lv_errbuf         -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode        -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.担当営業員データ抽出
    -- ================================
    -- カーソルオープン
    OPEN get_cst_rsurcs_data_cur;
--
    <<get_data_loop>>
    LOOP
      FETCH get_cst_rsurcs_data_cur INTO l_cst_rsurcs_data_rec;
      -- 処理対象件数格納
      gn_target_cnt := get_cst_rsurcs_data_cur%ROWCOUNT;
--
      EXIT WHEN get_cst_rsurcs_data_cur%NOTFOUND
      OR  get_cst_rsurcs_data_cur%ROWCOUNT = 0;
      -- レコード変数初期化
      l_get_data_rec := NULL;
      -- 取得データを格納
      l_get_data_rec.account_number          := l_cst_rsurcs_data_rec.account_number;             -- 顧客CD
      l_get_data_rec.party_name              := l_cst_rsurcs_data_rec.party_name;                 -- 顧客名
      l_get_data_rec.customer_class_code     := l_cst_rsurcs_data_rec.customer_class_code;        -- 顧客区分
      l_get_data_rec.customer_class_name     := l_cst_rsurcs_data_rec.customer_class_name;        -- 顧客区分名
      l_get_data_rec.customer_status         := l_cst_rsurcs_data_rec.customer_status;            -- 顧客ステータス
      l_get_data_rec.customer_status_name    := l_cst_rsurcs_data_rec.customer_status_name;       -- 顧客ステータス名
      l_get_data_rec.business_low_type       := l_cst_rsurcs_data_rec.business_low_type;          -- 業態小分類
      l_get_data_rec.business_low_type_name  := l_cst_rsurcs_data_rec.business_low_type_name;     -- 業態小分類名
      l_get_data_rec.sale_base_code          := l_cst_rsurcs_data_rec.sale_base_code;             -- 売上拠点
      l_get_data_rec.rsv_sale_base_act_date  := l_cst_rsurcs_data_rec.rsv_sale_base_act_date;     -- 予約売上拠点有効開始日
      l_get_data_rec.rsv_sale_base_code      := l_cst_rsurcs_data_rec.rsv_sale_base_code;         -- 予約売上拠点
      l_get_data_rec.route_no                := l_cst_rsurcs_data_rec.route_no;                   -- ルートNo
      l_get_data_rec.employee_number         := l_cst_rsurcs_data_rec.employee_number;            -- 担当営業員CD
      l_get_data_rec.full_name               := l_cst_rsurcs_data_rec.full_name;                  -- 担当営業員名
      l_get_data_rec.start_date_active       := l_cst_rsurcs_data_rec.start_date_active;          -- 担当営業員開始日
      l_get_data_rec.end_date_active         := l_cst_rsurcs_data_rec.end_date_active;            -- 担当営業員終了日
--
      -- ========================================
      -- A-3.出力ファイルへのデータ出力
      -- ========================================
      output_csv_rec(
        i_cst_rsurcs_dt_rec  =>  l_get_data_rec        -- 担当営業員データ
       ,iv_base_code         =>  lv_base_code          -- 拠点コード
       ,id_standard_date     =>  ld_standard_date      -- 基準日付
       ,ov_errbuf            =>  lv_errbuf             -- エラー・メッセージ
       ,ov_retcode           =>  lv_retcode            -- リターン・コード
       ,ov_errmsg            =>  lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- 正常件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP get_data_loop;
--
    -- カーソルクローズ
    CLOSE get_cst_rsurcs_data_cur;
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    IF (gn_target_cnt = 0) THEN
      ov_errbuf := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_05             -- メッセージコード
       );
--
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
--
      ov_retcode := cv_status_warn;
    END IF;
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (get_cst_rsurcs_data_cur%ISOPEN) THEN
        CLOSE get_cst_rsurcs_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (get_cst_rsurcs_data_cur%ISOPEN) THEN
        CLOSE get_cst_rsurcs_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_cst_rsurcs_data_cur%ISOPEN) THEN
        CLOSE get_cst_rsurcs_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
     errbuf              OUT NOCOPY VARCHAR2     -- エラー・メッセージ  --# 固定 #
    ,retcode             OUT NOCOPY VARCHAR2     -- リターン・コード    --# 固定 #
    ,iv_base_code        IN         VARCHAR2     -- 拠点コード
    ,iv_standard_date    IN         VARCHAR2     -- 基準日(1：当月 / 2：翌月)
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了
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
       iv_which   => cv_whick_log
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
       iv_base_code      => iv_base_code       -- 拠点コード
      ,iv_standard_date  => iv_standard_date   -- 基準日(1：当月 / 2：翌月)
      ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode        => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-4.終了処理
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
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
    --成功件数出力
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
    --エラー件数出力
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
    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
--                   );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
END XXCSO019A11C;
/
