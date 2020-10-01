CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A28C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A28C (body)
 * Description      : 控除データ用実績振替(EDI)作成
 * MD.050           : 控除データ用実績振替(EDI)作成 MD050_COK_024_A28
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_ins_data           実績振替(EDI)データ抽出・登録(A-2)
 *  purge_data             控除データ用実績振替(EDI)パージ(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/06/05    1.0   N.Koyama         新規作成
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  --
  cv_ins                    CONSTANT VARCHAR2(1) := '1';                                -- 1:追加
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_conc_status   VARCHAR2(30);
  gn_proc_cnt      NUMBER;                    -- 処理件数
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  --*** ロックエラー例外ハンドラ ***
  global_data_lock_expt     EXCEPTION;
  --*** ログのみ出力例外 ***
  global_api_expt_log       EXCEPTION;
  --*** 対象データ無しエラー例外ハンドラ ***
  global_no_data_expt       EXCEPTION;
  --
  -- ロックエラー
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) :=  'XXCOK024A28C';        -- パッケージ名
  cv_xxcok_short_name            CONSTANT  VARCHAR2(100) :=  'XXCOK';               -- 販物領域短縮アプリ名
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) :=  'XXCCP';               -- 共通領域短縮アプリ名
  --メッセージ
  cv_msg_lock_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10732';    -- ロック取得エラーメッセージ
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-00001';    -- 対象データなしメッセージ
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-00003';    -- プロファイル取得エラーメッセージ
  cv_msg_delete_err              CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10730';    -- データ削除エラーメッセージ
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-00028';    -- 業務日付取得エラーメッセージ
  cv_msg_parameter               CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10728';    -- パラメータ出力メッセージ
  cv_msg_proc_count              CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10737';    -- 処理件数メッセージ
  cv_msg_error_count             CONSTANT  VARCHAR2(100) :=  'APP-XXCCP1-90002';    -- エラー件数メッセージ
  --メッセージ用文字列
  cv_str_purge_term              CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10729';    -- XXCOK:控除データ用販売実績保持期間
--
  --トークン名
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE';               -- テーブル名称
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            -- キーデータ
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';             -- プロファイル名 
  cv_tkn_nm_param1               CONSTANT  VARCHAR2(100) :=  'PARAM1';              -- 入力パラメータ１
  cv_tkn_nm_param2               CONSTANT  VARCHAR2(100) :=  'PARAM2';              -- 入力パラメータ２
  cv_tkn_nm_param3               CONSTANT  VARCHAR2(100) :=  'PARAM3';              -- 入力パラメータ３
  cv_tkn_nm_count                CONSTANT  VARCHAR2(100) :=  'COUNT';               -- 件数
  --トークン値
  cv_msg_table                   CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10736';    -- 控除データ用実績振替(EDI)
--
  --クイックコード参照用
  --参照タイプ名
  cv_type_gyotai                 CONSTANT  VARCHAR2(100) :=  'XXCMM_CUST_GYOTAI_SHO';          --業態小分類
  --使用可能フラグ定数
  ct_enabled_flg_y               CONSTANT  fnd_lookup_values.enabled_flag%TYPE 
                                                         :=  'Y';       --使用可能
  cv_lang                        CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );               --言語
--
  -- プロファイル
  ct_prof_errlist_purge_term     CONSTANT  fnd_profile_options.profile_option_name%TYPE 
                                                         := 'XXCOK1_SALES_EXP_KEEP';  -- XXCOK:控除データ用販売実績保持期間
--
  --日付フォーマット
  cv_yyyy_mm_dd                  CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD型
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date                DATE;                                              --業務日付
  gd_from_date                DATE;                                              --処理日付開始
  gd_to_date                  DATE;                                              --処理日付終了
  gn_purge_term               NUMBER;                                            --汎用エラーリスト削除日数
  gn_delete_cnt               NUMBER;                                            --削除件数
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_kind                    IN     VARCHAR2,  -- 処理区分
    iv_from_date                    IN     VARCHAR2,  -- 処理日付From
    iv_to_date                      IN     VARCHAR2,  -- 処理日付To
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- プログラム名
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
    lv_para_msg            VARCHAR2(5000);                         -- パラメータ出力メッセージ
    lv_purge_term          NUMBER;                                 -- 控除データ用販売実績保持月数
    lv_profile_name        fnd_new_messages.message_text%TYPE;     -- プロファイル名
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
    --========================================
    -- パラメータ出力処理
    --========================================
    lv_para_msg             :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcok_short_name,
      iv_name               =>  cv_msg_parameter,
      iv_token_name1        =>  cv_tkn_nm_param1,
      iv_token_value1       =>  iv_proc_kind,
      iv_token_name2        =>  cv_tkn_nm_param2,
      iv_token_value2       =>  iv_from_date,
      iv_token_name3        =>  cv_tkn_nm_param3,
      iv_token_value3       =>  iv_to_date
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
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
    --========================================
    -- 業務日付取得処理
    --========================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
    --==================================
    -- XXCOK:控除データ用販売実績保持期間
    --==================================
    lv_purge_term := FND_PROFILE.VALUE( ct_prof_errlist_purge_term );
    -- プロファイルが取得できない場合はエラー
    IF ( lv_purge_term IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcok_short_name,
        iv_name        => cv_str_purge_term
      );
      --プロファイル名文字列取得
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcok_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf    := lv_errmsg;
      RAISE global_api_expt_log;
    ELSE
      gn_purge_term := TO_NUMBER(lv_purge_term);
    END IF;
    --
--
    --==================================
    -- 4.処理日の設定
    --==================================
    IF ( iv_proc_kind = cv_ins ) THEN
      IF ( iv_from_date IS NOT NULL ) THEN
        gd_from_date := TO_DATE(iv_from_date,cv_yyyy_mm_dd);
      ELSE
        gd_from_date := gd_proc_date;
      END IF;
      IF ( iv_to_date IS NOT NULL ) THEN
        gd_to_date := TO_DATE(iv_to_date,cv_yyyy_mm_dd);
      ELSE
        gd_to_date := gd_proc_date;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ログ限定出力用例外ハンドラ ***
    WHEN global_api_expt_log THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
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
   * Procedure Name   : get_ins_data
   * Description      : 実績振替(EDI)データ抽出・登録(A-2)
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ins_data'; -- プログラム名
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
    cv_1              constant varchar2(1)  := '1' ;
    cv_item_category  constant varchar2(30) := '本社商品区分' ; 
--
    -- *** ローカル変数 ***
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
    -- １．実績振替(EDI)情報の取得・控除データ用実績振替(EDI)の作成
    INSERT INTO xxcok_dedu_edi_sell_trns(
             selling_trns_info_id
            ,selling_trns_type
            ,report_decision_flag
            ,delivery_base_code
            ,selling_from_cust_code
            ,base_code
            ,cust_code
            ,selling_date
            ,item_code
            ,product_class
            ,unit_type
            ,delivery_unit_price
            ,qty
            ,selling_amt_no_tax
            ,tax_code
            ,tax_rate
            ,selling_amt
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date    )
    (SELECT  xsi.selling_trns_info_id
            ,xsi.selling_trns_type
            ,xsi.report_decision_flag
            ,xsi.delivery_base_code
            ,xsi.selling_from_cust_code
            ,xsi.base_code
            ,xsi.cust_code
            ,xsi.selling_date
            ,xsi.item_code
            ,SUBSTRB(mcv.segment1,1,1)
            ,xsi.unit_type
            ,xsi.delivery_unit_price
            ,xsi.qty
            ,xsi.selling_amt_no_tax
            ,xsi.tax_code
            ,xsi.tax_rate
            ,xsi.selling_amt
            ,cn_created_by
            ,cd_creation_date
            ,cn_last_updated_by
            ,cd_last_update_date
            ,cn_last_update_login
            ,cn_request_id
            ,cn_program_application_id
            ,cn_program_id
            ,cd_program_update_date
       FROM  mtl_categories_vl        mcv
            ,gmi_item_categories      gic 
            ,mtl_category_sets_vl     mcsv
            ,xxcmm_system_items_b     xsib
            ,xxcok_selling_trns_info  xsi             -- 売上実績振替情報
            ,fnd_lookup_values        flvc1           -- 業態小分類マスタ
      WHERE  xsi.registration_date   >= gd_from_date
        AND  xsi.registration_date   <= gd_to_date
        AND  xsi.report_decision_flag = cv_1     -- 確定
        AND  xsi.selling_trns_type    = cv_1     -- EDI
        AND  xsib.item_code           = xsi.item_code
        AND  gic.item_id              = xsib.item_id
        AND  mcsv.category_set_id     = gic.category_set_id
        AND  mcsv.category_set_name   = cv_item_category  -- 本社商品区分
        AND  mcv.category_id          = gic.category_id
        AND  xsi.cust_state_type      = flvc1.lookup_code
        AND  flvc1.lookup_type        = cv_type_gyotai
        AND  flvc1.language           = cv_lang
        AND  flvc1.enabled_flag       = ct_enabled_flg_y
        AND  flvc1.attribute2         = ct_enabled_flg_y);
    --処理件数格納
    gn_proc_cnt := SQL%ROWCOUNT;
--
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
  END get_ins_data;
--
  /**********************************************************************************
   * Procedure Name   : purge_data
   * Description      : 控除データ用実績振替(EDI)パージ(A-3)
   ***********************************************************************************/
  PROCEDURE purge_data(
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_data'; -- プログラム名
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
    lv_table_name fnd_new_messages.message_text%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR purge_cur
      IS
        SELECT xdest.selling_trns_info_id
        FROM   xxcok_dedu_edi_sell_trns xdest
        WHERE xdest.selling_date < TRUNC(ADD_MONTHS(gd_proc_date,gn_purge_term * -1),'MM')
        FOR UPDATE NOWAIT;
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
    -- ===============================
    -- ロックの取得
    -- ===============================
    BEGIN
      OPEN  purge_cur;
      CLOSE purge_cur;
    EXCEPTION
      -- *** ロックエラーハンドラ ***
      WHEN global_data_lock_expt THEN
        IF ( purge_cur%ISOPEN ) THEN
          CLOSE purge_cur;
        END IF;
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcok_short_name  -- アプリケーション短縮名
                           ,iv_name        => cv_msg_table         -- メッセージコード
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_short_name     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_lock_err         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_nm_table_name    -- トークンコード1
                       ,iv_token_value1 => lv_table_name           -- トークン値1
                     );
        --
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- 控除データ用実績振替(EDI)の削除
    -- ===============================
    BEGIN
      DELETE 
        FROM  xxcok_dedu_edi_sell_trns xdest
       WHERE  xdest.selling_date < TRUNC(ADD_MONTHS(gd_proc_date,gn_purge_term * -1),'MM')
      ;
--
    --処理件数格納
      gn_proc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      -- *** パージエラーハンドラ ***
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcok_short_name  -- アプリケーション短縮名
                           ,iv_name        => cv_msg_table         -- メッセージコード
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_short_name     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_delete_err       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_nm_table_name    -- トークンコード1
                       ,iv_token_value1 => lv_table_name           -- トークン値1
                       ,iv_token_name2  => cv_tkn_nm_key_data      -- トークンコード1
                       ,iv_token_value2 => SQLERRM                 -- トークン値1
                     );
        --
        RAISE global_api_expt;
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
      IF ( purge_cur%ISOPEN ) THEN
        CLOSE purge_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END purge_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_kind                    IN     VARCHAR2,  -- 処理区分
    iv_from_date                    IN     VARCHAR2,  -- 処理日付From
    iv_to_date                      IN     VARCHAR2,  -- 処理日付To
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
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
    ld_process_date                   DATE;            -- 処理日付
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
    gn_proc_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
       iv_proc_kind                    -- 処理区分
      ,iv_from_date                    -- 処理日付From
      ,iv_to_date                      -- 処理日付To
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- 処理区分判定
    IF ( iv_proc_kind = cv_ins ) THEN
      -- ===============================
      -- A-2  実績振替(EDI)情報抽出・登録
      -- ===============================
      get_ins_data(
         lv_errbuf                       -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                      -- リターン・コード             --# 固定 #
        ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    ELSE
      -- ===============================
      -- A-3  実績振替(EDI)情報パージ
      -- ===============================
      purge_data(
         lv_errbuf                       -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                      -- リターン・コード             --# 固定 #
        ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- エラーメッセージ件数が0件
    IF ( gn_proc_cnt = 0 ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_no_data
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象0件例外ハンドラ ***
    WHEN global_no_data_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg, 1, 5000 );
      -- リターンコードを一時的に警告にする
      ov_retcode := cv_status_warn;
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
    errbuf                          OUT    VARCHAR2,         -- エラー・メッセージ  --# 固定 #
    retcode                         OUT    VARCHAR2,         -- リターン・コード    --# 固定 #
    iv_proc_kind                    IN     VARCHAR2,         -- 処理区分
    iv_from_date                    IN     VARCHAR2,         -- 処理日付From
    iv_to_date                      IN     VARCHAR2          -- 処理日付To
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
       ov_retcode => lv_retcode
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
       iv_proc_kind                    -- 処理区分
      ,iv_from_date                    -- 処理日付From
      ,iv_to_date                      -- 処理日付To
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    -- ===============================================
    -- ステータスの更新
    -- ===============================================
    IF (lv_retcode <> cv_status_error ) THEN
      IF   ( gn_proc_cnt > 0 ) THEN
        -- 処理したヘッダが１件以上ある場合はステータスを正常
        lv_retcode := cv_status_normal;
      ELSIF( gn_proc_cnt = 0 ) THEN
        -- 処理したヘッダが０件の場合はステータスを警告
        lv_retcode := cv_status_warn;
      END IF;
    ELSE
      -- エラー件数設定
      gn_error_cnt  := gn_error_cnt + 1;
      gn_proc_cnt   := 0;
    END IF;
    --
    -- ===============================================
    -- 件数出力
    -- ===============================================
    -- 処理件数と削除件数の出力
    -- 処理件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_msg_proc_count
                    ,iv_token_name1  => cv_tkn_nm_count
                    ,iv_token_value1 => gn_proc_cnt
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
   --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_msg_error_count
                    ,iv_token_name1  => cv_tkn_nm_count
                    ,iv_token_value1 => gn_error_cnt
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
        --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- 終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
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
END XXCOK024A28C;
/
