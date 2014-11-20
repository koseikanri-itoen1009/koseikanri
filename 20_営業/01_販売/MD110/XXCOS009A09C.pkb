CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A09C (spec)
 * Description      : 受注一覧発行状況CSV出力
 * MD.050           : 受注一覧発行状況CSV出力 MD050_COS_009_A09
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_order_list_cond    受注一覧発行状況データ抽出(A-2)
 *  output_data            データ出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/09/12    1.0   M.Takasaki       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
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
  --*** 出力日 日付逆転チェック例外 ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) :=  'XXCOS009A09C';        -- パッケージ名
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) :=  'XXCOS';               -- 販物領域短縮アプリ名
  --メッセージ
  cv_msg_date_rever_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- 日付逆転エラーメッセージ
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_parameter          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14454';    -- パラメータ出力メッセージ
  --トークン名
  cv_tkn_nm_base_code       CONSTANT  VARCHAR2(100) :=  'BASE_CODE';           -- 拠点コード
  cv_tkn_nm_date_from       CONSTANT  VARCHAR2(100) :=  'DATE_FROM';           -- 出力日(FROM)
  cv_tkn_nm_date_to         CONSTANT  VARCHAR2(100) :=  'DATE_TO';             -- 出力日(TO)
  --トークン値
  cv_msg_vl_order_li_basecd CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14451';    -- 拠点コード
  cv_msg_vl_order_li_from   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14452';    -- 出力日(FROM)
  cv_msg_vl_order_li_to     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14453';    -- 出力日(TO)
  --受注一覧出力管理テーブル取得用
  cv_class_base             CONSTANT  VARCHAR2(2)   := '1';    -- 顧客区分:拠点
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date              DATE;                                              --業務日付
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 受注一覧出力管理テーブル取得
  CURSOR get_order_list_data_cur(
           ip_base_code               VARCHAR,  -- 拠点コード
           ip_order_list_date_from    DATE,     -- 出力日(FROM)
           ip_order_list_date_to      DATE)     -- 出力日(TO)
  IS
    SELECT    xolc.delivery_base_code As base_code                   -- 受注一覧出力管理テーブル.拠点コード
             ,hp_ba.party_name        AS base_code_name              -- パーティマスタ_拠点.名称           ：拠点名
             ,TO_CHAR(xolc.output_datetime,'YYYY/MM/DD HH24:MI:SS')
                                      AS output_datetime             -- 受注一覧出力管理テーブル.出力時間
             ,papf.per_information18 || papf.per_information19
                                      AS creater_name                -- 従業員マスタ.漢字姓 + 漢字名       ：出力者
             ,xolc.chain_code         AS chain_code                  -- 受注一覧出力管理テーブル.チェーン店コード
             ,xolc.chain_name         AS chain_name                  -- 受注一覧出力管理テーブル.チェーン店名
             ,xolc.store_code         AS store_code                  -- 受注一覧出力管理テーブル.店舗コード
             ,xolc.invoice_number     AS invoice_number              -- 受注一覧出力管理テーブル.伝票番号
             ,xolc.order_number       AS order_number                -- 受注一覧出力管理テーブル.受注番号
             ,xolc.request_id         AS con_number                  -- 受注一覧出力管理テーブル.要求ID    ：コンカレント番号
    FROM      xxcos_order_list_conditions xolc                       -- 受注一覧出力管理テーブル
             ,hz_parties                  hp_ba                      -- パーティマスタ_拠点
             ,hz_cust_accounts            hca_ba                     -- 顧客マスタ_拠点
             ,per_all_people_f            papf                       -- 従業員マスタ
             ,fnd_user                    fu                         -- ユーザーマスタ
    WHERE    -- 出力時間がパラメータの期間内 かつ、拠点コードがパラメータと同じ
             TRUNC(xolc.output_datetime) >= ip_order_list_date_from  -- 受注一覧出力管理テーブル.出力時間   ≧ パラメータ.出力日(FROM)
    AND      TRUNC(xolc.output_datetime) <= ip_order_list_date_to    -- 受注一覧出力管理テーブル.出力時間   ≦ パラメータ.出力日(TO)
    AND      xolc.delivery_base_code = ip_base_code                  -- 受注一覧出力管理テーブル.拠点コード ＝ パラメータ．拠点コード
    AND      xolc.delivery_base_code = hca_ba.account_number         -- 受注一覧出力管理テーブル.拠点コード ＝ 顧客マスタ_拠点.顧客コード
    AND      hca_ba.customer_class_code  =  cv_class_base            -- 顧客マスタ_拠点.顧客区分            ＝ '1'    ：拠点
    AND      hca_ba.party_id  =  hp_ba.party_id                      -- 顧客マスタ_拠点.パーティID          ＝ パーティマスタ_拠点.パーティID
    AND      xolc.created_by = fu.user_id                            -- 受注一覧出力管理テーブル.作成者     ＝ ユーザーマスタ.ユーザーID
    AND      papf.person_id = fu.employee_id                         -- 従業員マスタ.従業員ID               ＝ ユーザーマスタ.従業員ID
    AND      TRUNC(xolc.output_datetime) >= TRUNC(papf.effective_start_date)  -- 受注一覧出力管理テーブル.出力時間   ≧ 従業員マスタ.有効開始日
    AND      TRUNC(xolc.output_datetime) <= TRUNC(papf.effective_end_date)    -- 受注一覧出力管理テーブル.出力時間   ≦ 従業員マスタ.有効終了日
    ORDER BY
       xolc.delivery_base_code                                       -- 拠点コード
      ,xolc.output_datetime                                          -- 出力時間
      ,xolc.chain_code                                               -- チェーン店
      ,xolc.store_code                                               -- 店舗
      ,xolc.invoice_number                                           -- 伝票番号
  ;
  --取得データ格納変数定義
  TYPE g_out_file_ttype IS TABLE OF get_order_list_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code                    IN     VARCHAR2,  -- 1.拠点コード
    iv_order_list_date_from         IN     VARCHAR2,  -- 2.出力日(FROM)
    iv_order_list_date_to           IN     VARCHAR2,  -- 3.出力日(TO)
    od_order_list_date_from         OUT    DATE,      -- 1.出力日(FROM)_チェックOK
    od_order_list_date_to           OUT    DATE,      -- 2.出力日(TO)_チェックOK
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_para_msg                     VARCHAR2(5000);     -- パラメータ出力メッセージ
    lv_check_d_from                 VARCHAR2(100);      -- 出力日(FROM)文言
    lv_check_d_to                   VARCHAR2(100);      -- 出力日(TO)文言
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
    --========================================
    -- パラメータ出力処理
    --========================================
    lv_para_msg             :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_parameter,
      iv_token_name1        =>  cv_tkn_nm_base_code,
      iv_token_value1       =>  iv_base_code,
      iv_token_name2        =>  cv_tkn_nm_date_from,
      iv_token_value2       =>  iv_order_list_date_from,
      iv_token_name3        =>  cv_tkn_nm_date_to,
      iv_token_value3       =>  iv_order_list_date_to
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    od_order_list_date_from   := TO_DATE( iv_order_list_date_from, 'RRRR/MM/DD' );  -- 出力日 (FROM)
    od_order_list_date_to     := TO_DATE( iv_order_list_date_to, 'RRRR/MM/DD' );    -- 出力日(TO)
    --
    --========================================
    -- 1.入力パラメータチェック
    --========================================
    -- 出力日(FROM)／ 出力日(TO)  日付逆転チェック
    IF ( od_order_list_date_from > od_order_list_date_to ) THEN
      RAISE global_date_rever_old_chk_expt;
    END IF;
    --========================================
    -- 2.業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- ***出力日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_old_chk_expt THEN
      lv_check_d_from         :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_li_from
      );
      lv_check_d_to           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_li_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_d_from,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_d_to
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_list_cond
   * Description      : 受注一覧発行状況データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_list_cond(
    iv_base_code                    IN     VARCHAR2,  -- 1.拠点コード
    id_order_list_date_from         IN     DATE,      -- 2.出力日(FROM)_チェックOK
    id_order_list_date_to           IN     DATE,      -- 3.出力日(TO)_チェックOK
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_list_cond'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --対象データ取得
    OPEN get_order_list_data_cur(
             iv_base_code,                 --拠点コード
             id_order_list_date_from,      --出力日(FROM)
             id_order_list_date_to);       --出力日(TO)
    FETCH get_order_list_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_order_list_data_cur;
    --処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
--
  EXCEPTION
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
  END get_order_list_cond;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_enabled_flg_y        CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                    :=  'Y';                          --使用可能
    cv_lang                 CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );            --言語
    cv_type_head            CONSTANT  VARCHAR2(100) := 'XXCOS1_EXCEL_OUTPUT_HEAD';    --エクセル出力用見出し
    cv_code_eoh_009a09      CONSTANT  VARCHAR2(100) := '009A09%';                     --エクセル出力用見出しのクイックコード
    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';                           -- 区切り文字
    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';                           -- 単語囲み文字
--
    -- *** ローカル変数 ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUTデータ編集用
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR head_cur
    IS
      SELECT  flv.description  head
      FROM    fnd_lookup_values flv
      WHERE   flv.language      = cv_lang
      AND     flv.lookup_type   = cv_type_head
      AND     lookup_code    LIKE cv_code_eoh_009a09
      AND     gd_proc_date     >= NVL( flv.start_date_active, gd_proc_date )
      AND     gd_proc_date     <= NVL( flv.end_date_active,   gd_proc_date )
      AND     flv.enabled_flag  = ct_enabled_flg_y
      ORDER BY
              flv.lookup_code
      ;
    --見出し
    TYPE l_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_head_tab l_head_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 見出しの出力
    ------------------------------------------
    -- データの見出しを取得
    OPEN  head_cur;
    FETCH head_cur BULK COLLECT INTO lt_head_tab;
    CLOSE head_cur;
--
    --データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --データを編集
      lv_line_data :=     cv_enclosed || gt_out_file_tab(i).base_code       || cv_enclosed  -- 拠点コード
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).base_code_name  || cv_enclosed  -- 拠点名
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).output_datetime || cv_enclosed  -- 出力時間
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).creater_name    || cv_enclosed  -- 出力者
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).chain_code      || cv_enclosed  -- チェーン店コード
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).chain_name      || cv_enclosed  -- チェーン店名
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).store_code      || cv_enclosed  -- 店舗コード
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).invoice_number  || cv_enclosed  -- 伝票番号
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).order_number    || cv_enclosed  -- 受注番号
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).con_number      || cv_enclosed  -- コンカレント番号
      ;
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code                    IN     VARCHAR2,  --   1.拠点コード
    iv_order_list_date_from         IN     VARCHAR2,  --   2.出力日(FROM)
    iv_order_list_date_to           IN     VARCHAR2,  --   3.出力日(TO)
    ov_errbuf                       OUT    VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_order_list_date_from         DATE;             -- 出力日(FROM)_チェックOK
    ld_order_list_date_to           DATE;             -- 出力日(TO)_チェックOK
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
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
      iv_base_code,                 -- 拠点コード
      iv_order_list_date_from,      -- 出力日(FROM)
      iv_order_list_date_to,        -- 出力日(TO)
      ld_order_list_date_from,      -- 出力日(FROM)_チェックOK
      ld_order_list_date_to,        -- 出力日(TO)_チェックOK
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  受注一覧発行状況データ抽出
    -- ===============================
    get_order_list_cond(
      iv_base_code,                 -- 拠点コード
      ld_order_list_date_from,      -- 出力日(FROM)_チェックOK
      ld_order_list_date_to,        -- 出力日(TO)_チェックOK
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  データ出力
    -- ===============================
    output_data(
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
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
    errbuf                          OUT    VARCHAR2,  --   エラー・メッセージ  --# 固定 #
    retcode                         OUT    VARCHAR2,  --   リターン・コード    --# 固定 #
    iv_base_code                    IN     VARCHAR2,  --   1.拠点コード
    iv_order_list_date_from         IN     VARCHAR2,  --   2.出力日(FROM)
    iv_order_list_date_to           IN     VARCHAR2   --   3.出力日(TO)
  )
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_base_code                    -- 拠点コード
      ,iv_order_list_date_from         -- 出力日(FROM)
      ,iv_order_list_date_to           -- 出力日(TO)
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --エラーの場合、成功件数クリア
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
END XXCOS009A09C;
/