CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : 目標達成状況メール配信(body)
 * Description      : 売上目標のメール配信を行う
 * MD.050           : 目標達成状況メール配信 <MD050_COS_002_A08>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  del_send_mail_relate   メール配信関連テーブル削除(A-2)
 *  ins_send_mail_trn      メール配信状況トラン作成(A-3)
 *  ins_target_date        メール配信対象一時テーブル作成(A-4)
 *  edit_mail_text         メール本文編集(A-5)
 *  get_send_mail_data_e   メール配信データ取得(従業員計)(A-6)
 *  get_send_mail_data_b   メール配信データ取得(拠点計)(A-7)
 *  ins_wf_mail            アラートメール送信テーブル作成(A-8)
 *  upd_send_mail_trn      メール配信状況トラン更新(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2013/06/12    1.0   K.Kiriu          新規作成
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
  lock_expt            EXCEPTION;         -- ロック例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  no_data_expt         EXCEPTION;         -- 対象データなし例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS002A08C';   -- パッケージ名
  --汎用
  cv_yes           CONSTANT VARCHAR2(1)   := 'Y';              -- 汎用(Y)
  cv_no            CONSTANT VARCHAR2(1)   := 'N';              -- 汎用(N)
  cn_1             CONSTANT NUMBER        := 1;                -- 汎用(1)
  --アプリケーション
  cv_app_xxcos     CONSTANT VARCHAR2(5)   := 'XXCOS';
  --パラメータ
  cv_base          CONSTANT VARCHAR2(1)   := '1';  --拠点集計
  cv_emp           CONSTANT VARCHAR2(1)   := '2';  --従業員集計
  cv_parge         CONSTANT VARCHAR2(1)   := '3';  --メール配信テーブルパージ
  --書式設定
  cv_date_mm       CONSTANT VARCHAR2(2)   := 'MM';
  cv_month         CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_num_achieve   CONSTANT VARCHAR2(5)   := '990.0';
  --起動日・起動時間取得
  cd_sysdate       CONSTANT DATE          := SYSDATE;
  --メール内容の編集パターン
  cv_area          CONSTANT VARCHAR2(1)   := '3';  --地区集計
  --参照タイプ
  cv_send_mail     CONSTANT VARCHAR2(29)  := 'XXCOS1_SALES_TARGET_SEND_MAIL';
  cv_item_g_sum    CONSTANT VARCHAR2(25)  := 'XXCMM1_ITEM_GROUP_SUMMARY';
  --プロファイル
  ct_prof_bus_cal_code
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE'; -- XXCOS:カレンダコード
  ct_prof_keep_day
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SEND_MAIL_KEEPING_DAY';  -- XXCOS:送信メール保持日
  ct_prof_set_of_bks_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';              -- GL会計帳簿ID
  --メッセージ
  cv_msg_param     CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14651';  --パラメータ出力
  cv_msg_lock_err  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';  --ロックエラー
  cv_msg_no_data   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';  --対象データ無しエラー
  cv_msg_profile   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';  --プロファイル取得
  cv_msg_ins_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010';  --データ登録エラー
  cv_msg_upd_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';  --データ更新エラー
  cv_msg_del_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';  --データ削除エラー
  cv_msg_sel_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013';  --データ抽出エラー
  cv_msg_cal       CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14652';  --メッセージ：カレンダテーブル
  cv_msg_mail_wf   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14653';  --メッセージ：メール配信テーブル
  cv_msg_mail_trn  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14654';  --メッセージ：メール配信状況トランテーブル
  cv_msg_mail_tmp  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14665';  --メッセージ：売上目標状況メール配信一時表テーブル
  cv_msg_rs_info   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14666';  --メッセージ：営業員情報日次テーブル
  --メッセージ(メール用固定文字)
  cv_msg_word_1    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14655';  --メッセージ：年
  cv_msg_word_2    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14656';  --メッセージ：月
  cv_msg_word_3    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14657';  --メッセージ：地区計
  cv_msg_word_4    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14658';  --メッセージ：拠点計
  cv_msg_word_5    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14659';  --メッセージ：営業員計
  cv_msg_word_6    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14660';  --メッセージ：目標
  cv_msg_word_7    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14661';  --メッセージ：実績
  cv_msg_word_8    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14662';  --メッセージ：達成率
  cv_msg_word_9    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14663';  --メッセージ：千円
  cv_msg_word_10   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14664';  --メッセージ：%
  --トークン
  cv_tkn_proc      CONSTANT VARCHAR2(4)   := 'PROC';
  cv_tkn_trg_time  CONSTANT VARCHAR2(11)  := 'TARGET_TIME';
  cv_tkn_prof_nm   CONSTANT VARCHAR2(7)   := 'PROFILE';
  cv_tkn_tab_name  CONSTANT VARCHAR2(10)  := 'TABLE_NAME';
  cv_tkn_tab       CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_tkn_key_data  CONSTANT VARCHAR2(8)   := 'KEY_DATA';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --メール送信用固定文字取得用
  TYPE g_fixed_word_ttype IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;
  g_fixed_word_tab g_fixed_word_ttype;
  --メール内容編集用
  TYPE g_edit_rtype IS RECORD (
     target_management_code  xxcso_wk_sales_target.target_management_code%TYPE  --目標管理項目コード
    ,target_month            xxcso_wk_sales_target.target_month%TYPE            --対象年月
    ,total_code              fnd_lookup_values_vl.lookup_code%TYPE              --合計行コード
    ,total_name              fnd_lookup_values_vl.description%TYPE              --合計行名称
    ,line_code               fnd_lookup_values_vl.lookup_code%TYPE              --明細行コード
    ,line_name               fnd_lookup_values_vl.description%TYPE              --明細行名称
    ,target_amount           xxcso_wk_sales_target.target_amount%TYPE           --目標金額
    ,sale_amount_month_sum   xxcso_wk_sales_target.sale_amount_month_sum%TYPE   --売上金額
    ,mail_to_1               fnd_lookup_values_vl.attribute5%TYPE               --宛先1
    ,mail_to_2               fnd_lookup_values_vl.attribute6%TYPE               --宛先2
    ,mail_to_3               fnd_lookup_values_vl.attribute7%TYPE               --宛先3
    ,mail_to_4               fnd_lookup_values_vl.attribute8%TYPE               --宛先4
  );
  TYPE g_edit_ttype IS TABLE OF g_edit_rtype INDEX BY BINARY_INTEGER;
  gt_edit_tab  g_edit_ttype;
  --アラートメール送信テーブル作成用
  TYPE g_wf_mail_ttype IS TABLE OF xxccp_wf_mail%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_wf_mail_tab  g_wf_mail_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date        DATE;           --起動日(時間なし)
  gv_proc_time        VARCHAR2(5);    --起動時間(配信対象取得用)
  gv_trn_create_flag  VARCHAR2(1);    --メール配信状況トラン作成判断フラグ
  gd_data_target_day  DATE;           --データ取得日(1営業日の場合前月、それ以外は当月)
  gn_set_of_books_id  NUMBER;         --会計帳簿ID
  gn_ins_wf_cnt       BINARY_INTEGER; --アラートメール送信テーブル用配列
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_process    IN  VARCHAR2,     -- 1.処理区分 ( 1：従業員集計 2：部門集計 3:パージ処理)
    iv_trg_time   IN  VARCHAR2,     -- 2.配信タイミング ( HH24:MI 形式 )
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
--
    -- *** ローカル変数 ***
    lv_para_msg       VARCHAR2(100);                                       --パラメータ出力用
    lt_last_proc_date xxcos_mail_send_status_trn.target_date%TYPE;         --最終実行日取得用
    lt_bus_cla_code   fnd_profile_option_values.profile_option_value%TYPE; --カレンダコード
    lt_first_day_seq  bom_calendar_dates.seq_num%TYPE;                     --1営業日のシーケンス
    lt_day_seq        bom_calendar_dates.seq_num%TYPE;                     --当日のシーケンス
    lv_msg_token      VARCHAR2(100);                                       --メッセージ用
    lt_msg_word_code  fnd_new_messages.message_name%TYPE;                  --メール文言用のメッセージコード格納用
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -------------------
    --パラメータ出力
    -------------------
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  cv_app_xxcos,
      iv_name          =>  cv_msg_param,
      iv_token_name1   =>  cv_tkn_proc,
      iv_token_value1  =>  iv_process,
      iv_token_name2   =>  cv_tkn_trg_time,
      iv_token_value2  =>  iv_trg_time
      );
    --出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
    --ログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    --空白
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --起動日・時間取得(配信対象取得用)
    gd_proc_date  := xxccp_common_pkg2.get_process_date;
    gv_proc_time  := iv_trg_time;
--
    --処理区分がパージ処理の場合、以降の処理は行わない
    IF ( iv_process = cv_parge ) THEN
      RETURN;
    END IF;
--
    --変数初期化
    gv_trn_create_flag := cv_no;  --メール配信状況トラン作成判断フラグ
    gd_data_target_day := NULL;   --取得データ日
    gn_ins_wf_cnt      := 0;      --アラートメール送信テーブル配列用

    -------------------
    --プロファイル取得
    -------------------
    --カレンダコード
    lt_bus_cla_code   := FND_PROFILE.VALUE( ct_prof_bus_cal_code );
    -- プロファイルが取得できない場合はエラー
    IF ( lt_bus_cla_code IS NULL ) THEN
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos          -- アプリケーション短縮名
                    ,iv_name         => cv_msg_profile        -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm        -- トークンコード1
                    ,iv_token_value1 => ct_prof_bus_cal_code  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --会計帳簿ID
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_set_of_bks_id ) );
    -- プロファイルが取得できない場合はエラー
    IF ( gn_set_of_books_id IS NULL ) THEN
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos           -- アプリケーション短縮名
                    ,iv_name         => cv_msg_profile         -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm         -- トークンコード1
                    ,iv_token_value1 => ct_prof_set_of_bks_id  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ---------------------
    -- トラン作成判断
    ---------------------
    --メール配信状況トランから指定の処理区分で最後に実行した日を取得(初回起動は前日を設定)
    SELECT NVL( MAX( xmsst.target_date ), gd_proc_date -1 )
    INTO   lt_last_proc_date
    FROM   xxcos_mail_send_status_trn xmsst
    WHERE  xmsst.summary_type = iv_process
    ;
    --最終起動が前日以前の場合(当日の初回実行)
    IF ( gd_proc_date > lt_last_proc_date ) THEN
      --メール配信状況トランを作成する。
      gv_trn_create_flag := cv_yes;
    END IF;
--
    --------------------------
    --月初(1営業日)判断
    --------------------------
    BEGIN
      --当月の最初のシーケンスをカレンダより取得
      SELECT MIN(seq_num)
      INTO   lt_first_day_seq
      FROM   bom_calendar_dates gcd
      WHERE  gcd.calendar_code = lt_bus_cla_code
      AND    gcd.calendar_date BETWEEN TRUNC( gd_proc_date, cv_date_mm )  --起動日の月初
                               AND     LAST_DAY( gd_proc_date )           --起動日の月末
      AND    gcd.seq_num       IS NOT NULL
      ;
      --当日のシーケンスを取得(非営業日の起動(NULL)はないとする)
      SELECT seq_num
      INTO   lt_day_seq
      FROM   bom_calendar_dates gcd
      WHERE  gcd.calendar_code = lt_bus_cla_code
      AND    gcd.calendar_date = gd_proc_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ生成
        lv_msg_token := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos   -- アプリケーション短縮名
                      ,iv_name         => cv_msg_cal     -- メッセージコード
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                      ,iv_name         => cv_msg_sel_err   -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                      ,iv_token_value1 => lv_msg_token     -- トークン値1
                      ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                      ,iv_token_value2 => SQLERRM          -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --当月月初のシーケンスと当日のシーケンスが同じ(1営業日の場合)
    IF ( lt_first_day_seq = lt_day_seq ) THEN
      --データの取得日を前月にする
      gd_data_target_day := LAST_DAY( ADD_MONTHS( gd_proc_date, -1 ) );
    --1営業日以外
    ELSE
      --データの取得日を本日にする
      gd_data_target_day := gd_proc_date;
    END IF;
--
    --------------------------
    --メール用固定文字取得
    --------------------------
    FOR i IN 1.. 10 LOOP
      --メッセージコードの取得
      IF ( i = 1 ) THEN
        lt_msg_word_code := cv_msg_word_1;  --年
      ELSIF ( i = 2 ) THEN
        lt_msg_word_code := cv_msg_word_2;  --月
      ELSIF ( i = 3 ) THEN
        lt_msg_word_code := cv_msg_word_3;  --地区計
      ELSIF ( i = 4 ) THEN
        lt_msg_word_code := cv_msg_word_4;  --拠点計
      ELSIF ( i = 5 ) THEN
        lt_msg_word_code := cv_msg_word_5;  --営業員計
      ELSIF ( i = 6 ) THEN
        lt_msg_word_code := cv_msg_word_6;  --目標
      ELSIF ( i = 7 ) THEN
        lt_msg_word_code := cv_msg_word_7;  --実績
      ELSIF ( i = 8 ) THEN
        lt_msg_word_code := cv_msg_word_8;  --達成率
      ELSIF ( i = 9 ) THEN
        lt_msg_word_code := cv_msg_word_9;  --千円
      ELSIF ( i = 10 ) THEN
        lt_msg_word_code := cv_msg_word_10; --%
      END IF;
      --メッセージ成績
      lv_msg_token := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos      -- アプリケーション短縮名
                    ,iv_name         => lt_msg_word_code  -- メッセージコード
                   );
      --配列に格納
      g_fixed_word_tab(i) := lv_msg_token;
--
    END LOOP;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : del_send_mail_relate
   * Description      : メール配信関連テーブル削除(A-2)
   ***********************************************************************************/
  PROCEDURE del_send_mail_relate(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_send_mail_relate'; -- プログラム名
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
    cv_create_program   CONSTANT VARCHAR2(100)  := 'XXCOS002A081C';
--
    -- *** ローカル変数 ***
    ln_keep_day_cnt  NUMBER;         --メール配信保持日
    ld_keep_day      DATE;           --メール配信保持
    lv_msg_token     VARCHAR2(100);  --メッセージ用
--
    -- *** ローカル・カーソル ***
    --メール配信テーブルロック用
    CURSOR lock_wf_cur
    IS
      SELECT 1
      FROM   xxccp_wf_mail xwm
      WHERE  TRUNC( xwm.creation_date ) < ld_keep_day
      AND    xwm.program_id IN (
               SELECT concurrent_program_id
               FROM   fnd_concurrent_programs_vl fcpv
               WHERE  fcpv.concurrent_program_name = cv_create_program
             )
      FOR UPDATE NOWAIT
      ;
    --メール配信状況トランロック用
    CURSOR lock_trn_cur
    IS
      SELECT 1
      FROM   xxcos_mail_send_status_trn xmsst
      WHERE  xmsst.target_date < ld_keep_day
      FOR UPDATE NOWAIT
      ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ----------------------------
    -- 営業員情報日次テーブル削除
    ----------------------------
    BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_rs_info_day';
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ生成
        lv_msg_token := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_xxcos    -- アプリケーション短縮名
                          ,iv_name         => cv_msg_rs_info  -- メッセージコード
                 );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_del_err   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                       ,iv_token_value2 => SQLERRM          -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --------------------
    --プロファイル取得
    --------------------
    --送信メール保持日
    ln_keep_day_cnt   := TO_NUMBER(FND_PROFILE.VALUE( ct_prof_keep_day ));
    -- プロファイルが取得できない場合はエラー
    IF ( ln_keep_day_cnt IS NULL ) THEN
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                    ,iv_name         => cv_msg_profile   -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm   -- トークンコード1
                    ,iv_token_value1 => ct_prof_keep_day -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --保持日の設定
    ld_keep_day := gd_proc_date - ln_keep_day_cnt;
--
    --------------------------
    -- メール送信テーブル削除
    --------------------------
    --エラー時のトークン取得
    lv_msg_token := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_xxcos    -- アプリケーション短縮名
                  ,iv_name         => cv_msg_mail_wf  -- メッセージコード
                 );
    --ロック取得
    BEGIN
      OPEN  lock_wf_cur;
      CLOSE lock_wf_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_lock_err  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab       -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --削除
    BEGIN
      DELETE
      FROM   xxccp_wf_mail xwm
      WHERE  TRUNC( xwm.creation_date ) < ld_keep_day
      AND    xwm.program_id IN (
               SELECT concurrent_program_id
               FROM   fnd_concurrent_programs_vl fcpv
               WHERE  fcpv.concurrent_program_name = cv_create_program
             )
      ;
      gn_target_cnt := SQL%ROWCOUNT;
      gn_normal_cnt := gn_target_cnt;
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_del_err   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                       ,iv_token_value2 => SQLERRM          -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ----------------------------
    -- メール配信状況トラン削除
    ----------------------------
    --エラー時のトークン取得
    lv_msg_token := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_xxcos    -- アプリケーション短縮名
                  ,iv_name         => cv_msg_mail_trn -- メッセージコード
                 );
    BEGIN
      OPEN  lock_trn_cur;
      CLOSE lock_trn_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_lock_err  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab       -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --削除
    BEGIN
      DELETE
      FROM   xxcos_mail_send_status_trn xmsst
      WHERE  xmsst.target_date < ld_keep_day
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_del_err   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                       ,iv_token_value2 => SQLERRM          -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END del_send_mail_relate;
--
  /**********************************************************************************
   * Procedure Name   : ins_send_mail_trn
   * Description      : メール配信状況トラン作成(A-3)
   ***********************************************************************************/
  PROCEDURE ins_send_mail_trn(
    iv_process    IN  VARCHAR,     -- -- 1.処理区分 ( 1：部門集計 2：従業員集計 )
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_send_mail_trn'; -- プログラム名
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
    lv_msg_token     VARCHAR2(100);  --メッセージ用
--
    -- *** ローカル・カーソル ***
    --メール配信状況トラン作成用カーソル(拠点)
    CURSOR send_time_base_cur
    IS
      SELECT flvv.attribute4  --配信タイミング
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_send_mail --送信先メールテーブル（参照タイプ）
      AND    flvv.attribute2  = cv_yes       --部門集計
      GROUP BY
             flvv.attribute4  --配信タイミング
      ;
    --メール配信状況トラン作成用カーソル(従業員)
    CURSOR send_time_emp_cur
    IS
      SELECT flvv.attribute4  --配信タイミング
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_send_mail --送信先メールテーブル（参照タイプ）
      AND    flvv.attribute1  = cv_yes       --従業員集計
      GROUP BY
             flvv.attribute4  --配信タイミング
      ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    TYPE g_send_time_ttype IS TABLE OF fnd_lookup_values_vl.attribute4%TYPE INDEX BY BINARY_INTEGER;
    g_send_time_tab g_send_time_ttype;
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
    ------------------------------
    --メール配信状況トラン作成
    ------------------------------
    --部門集計
    IF ( iv_process = cv_base ) THEN
      OPEN  send_time_base_cur;
      FETCH send_time_base_cur BULK COLLECT INTO g_send_time_tab;
      CLOSE send_time_base_cur;
    --従業員集計
    ELSIF ( iv_process = cv_emp ) THEN
      OPEN  send_time_emp_cur;
      FETCH send_time_emp_cur BULK COLLECT INTO g_send_time_tab;
      CLOSE send_time_emp_cur;
    END IF;
--
    BEGIN
      --作成
      FORALL i IN 1..g_send_time_tab.COUNT
        INSERT INTO xxcos_mail_send_status_trn(
           mail_trn_id           --メールトランID
          ,send_time             --配信タイミング
          ,summary_type          --集計区分
          ,send_flag             --送信フラグ
          ,target_date           --対象日
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
          xxcos_mail_send_status_trn_s01.NEXTVAL --メールトランID
         ,g_send_time_tab(i)                     --配信タイミング
         ,iv_process                             --集計区分
         ,cv_no                                  --送信フラグ
         ,gd_proc_date                           --対象日
         ,cn_created_by
         ,cd_creation_date
         ,cn_last_updated_by
         ,cd_last_update_date
         ,cn_last_update_login
         ,cn_request_id
         ,cn_program_application_id
         ,cn_program_id
         ,cd_program_update_date
        )
        ;
      --配列削除
      g_send_time_tab.DELETE;
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ生成
        lv_msg_token := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                      ,iv_name         => cv_msg_mail_trn  -- メッセージコード
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                      ,iv_name         => cv_msg_ins_err   -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                      ,iv_token_value1 => lv_msg_token     -- トークン値1
                      ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                      ,iv_token_value2 => SQLERRM          -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -----------------------------
    -- 営業員情報日次テーブル作成
    -----------------------------
    IF ( iv_process = cv_emp ) THEN
      BEGIN
        INSERT INTO xxcos_rs_info_day(
           rs_info_id                --営業員情報ID
          ,base_code                 --拠点コード
          ,employee_number           --営業員コード
          ,employee_name             --営業員名称
          ,group_code                --グループ番号
          ,group_in_sequence         --グループ内番号
          ,effective_start_date      --拠点適用開始日
          ,effective_end_date        --拠点適用終了日
          ,per_effective_start_date  --従業員適用開始日
          ,per_effective_end_date    --従業員適用終了日
          ,paa_effective_start_date  --アサインメント適用開始日
          ,paa_effective_end_date    --アサインメント適用終了日
          ,created_by                --作成者
          ,creation_date             --作成日
          ,last_updated_by           --最終更新者
          ,last_update_date          --最終更新日
          ,last_update_login         --最終更新ログイン
          ,request_id                --要求ID
          ,program_application_id    --コンカレント・プログラム・アプリケーションID
          ,program_id                --コンカレント・プログラムID
          ,program_update_date       --プログラム更新日
        )
        SELECT
           xxcos_rs_info_day_s01.NEXTVAL
          ,base_code
          ,employee_number
          ,employee_name
          ,group_code
          ,group_in_sequence
          ,effective_start_date
          ,effective_end_date
          ,per_effective_start_date
          ,per_effective_end_date
          ,paa_effective_start_date
          ,paa_effective_end_date
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        FROM  xxcos_rs_info2_v xriv
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ生成
          lv_msg_token := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                        ,iv_name         => cv_msg_rs_info   -- メッセージコード
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                        ,iv_name         => cv_msg_ins_err   -- メッセージコード
                        ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                        ,iv_token_value1 => lv_msg_token     -- トークン値1
                        ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                        ,iv_token_value2 => SQLERRM          -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
--
    --メール配信状況トランデータの当日分、及び、営業員情報を確定する為、COMMIT
    COMMIT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_send_mail_trn;
--
  /**********************************************************************************
   * Procedure Name   : ins_target_date
   * Description      : メール配信対象一時テーブル作成(A-4)
   ***********************************************************************************/
  PROCEDURE ins_target_date(
    iv_process    IN  VARCHAR2,     -- 1.処理区分 ( 1：部門集計 2：従業員集計 )
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_target_date'; -- プログラム名
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
    --階層取得用
    ct_application_id          fnd_id_flex_segments.application_id%TYPE          := 101;
    ct_id_flex_code            fnd_id_flex_segments.id_flex_code%TYPE            := 'GL#';
    ct_application_column_name fnd_id_flex_segments.application_column_name%TYPE := 'SEGMENT2';
--
    -- *** ローカル変数 ***
    lt_area_base_code          fnd_lookup_values_vl.lookup_type%TYPE; --地区コード
    lv_msg_token               VARCHAR2(100);                         --メッセージ用
--
    -- *** ローカル・カーソル ***
    --地区コード指定のデータ取得カーソル
    CURSOR area_base_cur
    IS
      SELECT    flvv.lookup_code  area_base_code
               ,flvv.description  area_base_name
               ,''                base_code
               ,''                base_name
               ,flvv.attribute5   mail_to_1
               ,flvv.attribute6   mail_to_2
               ,flvv.attribute7   mail_to_3
               ,flvv.attribute8   mail_to_4
               ,''                base_sort_code
      FROM      xxcos_mail_send_status_trn xmsst --メール配信状況トラン
               ,fnd_lookup_values_vl       flvv  --売上目標送信先マスタ
      WHERE     xmsst.target_date       = gd_proc_date          --起動日
      AND       xmsst.summary_type      = iv_process            --拠点集計
      AND       xmsst.send_flag         = cv_no                 --未処理
      AND       xmsst.send_time        <= gv_proc_time          --配信タイミングが起動時間より前
      AND       xmsst.send_time         = flvv.attribute4
      AND       flvv.lookup_type        = cv_send_mail          --XXCOS1_SALES_TARGET_SEND_MAIL
      AND       flvv.enabled_flag       = cv_yes                --有効
      AND       gd_data_target_day      BETWEEN flvv.start_date_active
                                        AND     NVL( flvv.end_date_active, gd_data_target_day ) --対象期間内
      AND       flvv.attribute2         = cv_yes                --拠点集計
      AND       flvv.attribute3         = cv_yes                --地区区分"Y"(直下の階層)
      ;
    --地区コード配下の拠点取得カーソル
    CURSOR under_area_base_cur
    IS
      SELECT xhdv.child_base_code  child_base_code  --拠点コード(地区配下)
            ,ffv.attribute4        child_base_name  --拠点名(正式名)
            ,ffv.attribute9        base_sort_code   --本部コード(新) ※ソート用
      FROM   (SELECT  level                       lev
                     ,xablv.base_code             area_base_code
                     ,xablv.child_base_code       child_base_code
                     ,xablv.flex_value_set_id     flex_value_set_id
              FROM    (
                       SELECT  ffvnh.parent_flex_value      base_code
                              ,ffvnh.child_flex_value_low   child_base_code
                              ,ffvnh.flex_value_set_id      flex_value_set_id
                        FROM
                               gl_sets_of_books              gsob
                              ,fnd_id_flex_segments          fifs
                              ,fnd_flex_value_norm_hierarchy ffvnh
                        WHERE  gsob.set_of_books_id         = gn_set_of_books_id
                        AND    fifs.application_id          = ct_application_id
                        AND    fifs.id_flex_code            = ct_id_flex_code
                        AND    fifs.application_column_name = ct_application_column_name
                        AND    fifs.id_flex_num             = gsob.chart_of_accounts_id
                        AND    ffvnh.flex_value_set_id      = fifs.flex_value_set_id
                        AND    EXISTS (
                                 SELECT  1
                                 FROM    APPS.fnd_flex_values ffv
                                 WHERE   ffv.flex_value_set_id = ffvnh.flex_value_set_id
                                 AND     ffv.flex_value        = ffvnh.parent_flex_value
                                 AND     NVL(ffv.start_date_active, gd_data_target_day) <= gd_data_target_day
                                 AND     NVL(ffv.end_date_active,   gd_data_target_day) >= gd_data_target_day
                               )
                        AND    EXISTS (
                                 SELECT  1
                                 FROM    APPS.fnd_flex_values ffv
                                 WHERE   ffv.flex_value_set_id = ffvnh.flex_value_set_id
                                 AND     ffv.flex_value        = ffvnh.child_flex_value_low
                                 AND     NVL(ffv.start_date_active, gd_data_target_day)  <= gd_data_target_day
                                 AND     NVL(ffv.end_date_active,   gd_data_target_day)  >= gd_data_target_day
                               )
                           
                      ) xablv
              START WITH
                      xablv.base_code = lt_area_base_code
              CONNECT BY NOCYCLE PRIOR
                      xablv.base_code = xablv.child_base_code
              )                         xhdv   --階層インラインビュー
             ,fnd_flex_values           ffv    --フレックス値
      WHERE   xhdv.lev                = 1      --指定された部門の直下の階層
      AND     xhdv.flex_value_set_id  = ffv.flex_value_set_id
      AND     xhdv.child_base_code    = ffv. flex_value
      ;
--
    -- *** ローカル・レコード ***
    area_base_rec        area_base_cur%ROWTYPE;
    under_area_base_rec  under_area_base_cur%ROWTYPE;
--
    -- *** 例外 ***
    ins_error_expt EXCEPTION;
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
    --処理区分が拠点集計の場合
    IF ( iv_process = cv_base ) THEN
--
      BEGIN
        ---------------------------
        --一時表に挿入(自拠点のみ)
        ---------------------------
        INSERT INTO xxcos_tmp_mail_send (
           area_base_code  --地区コード
          ,area_base_name  --地区名称
          ,base_code       --拠点コード
          ,base_name       --拠点名
          ,mail_to_1       --宛先１
          ,mail_to_2       --宛先２
          ,mail_to_3       --宛先３
          ,mail_to_4       --宛先４
          ,base_sort_code  --本部コード(新)
        )
          SELECT  flvv.lookup_code  area_base_code
                 ,flvv.description  area_base_name
                 ,flvv.lookup_code  base_code
                 ,flvv.description  base_name
                 ,flvv.attribute5   mail_to_1
                 ,flvv.attribute6   mail_to_2
                 ,flvv.attribute7   mail_to_3
                 ,flvv.attribute8   mail_to_4
                 ,cn_1              base_sort_code
          FROM    xxcos_mail_send_status_trn xmsst --メール配信状況トラン
                 ,fnd_lookup_values_vl       flvv  --売上目標送信先マスタ
          WHERE   xmsst.target_date       = gd_proc_date          --起動日
          AND     xmsst.summary_type      = iv_process            --拠点集計
          AND     xmsst.send_flag         = cv_no                 --未処理
          AND     xmsst.send_time        <= gv_proc_time          --配信タイミングが起動時間より前
          AND     xmsst.send_time         = flvv.attribute4
          AND     flvv.lookup_type        = cv_send_mail          --XXCOS1_SALES_TARGET_SEND_MAIL
          AND     flvv.enabled_flag       = cv_yes                --有効
          AND     gd_data_target_day      BETWEEN flvv.start_date_active
                                          AND     NVL( flvv.end_date_active, gd_data_target_day ) --対象期間内
          AND     flvv.attribute2         = cv_yes                --拠点集計
          AND     flvv.attribute3         = cv_no                 --地区区分"N"(自拠点のみ)
        ;
     EXCEPTION
       WHEN OTHERS THEN
         --メッセージ生成
         lv_msg_token := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_mail_tmp  -- メッセージコード
                      );
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_ins_err   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                       ,iv_token_value2 => SQLERRM          -- トークン値1
                      );
         lv_errbuf := lv_errmsg;
         RAISE ins_error_expt;
     END;
--
      --一時表に挿入(直下の拠点分)
     OPEN  area_base_cur;
     <<area_base_loop>>
     LOOP
       FETCH area_base_cur INTO area_base_rec;
       EXIT WHEN area_base_cur%NOTFOUND;
       --条件となる親部門コード設定
       lt_area_base_code := area_base_rec.area_base_code;
       --AFF部門から配下の拠点を取得
       OPEN  under_area_base_cur;
       <<under_area_loop>>
       LOOP
         FETCH under_area_base_cur INTO under_area_base_rec;
         EXIT WHEN under_area_base_cur%NOTFOUND;
         BEGIN
           ---------------------------
           --一時表に挿入(地区配下拠点)
           ---------------------------
           INSERT INTO xxcos_tmp_mail_send (
              area_base_code  --地区コード
             ,area_base_name  --地区名称
             ,base_code       --拠点コード
             ,base_name       --拠点名
             ,mail_to_1       --宛先１
             ,mail_to_2       --宛先２
             ,mail_to_3       --宛先３
             ,mail_to_4       --宛先４
             ,base_sort_code  --本部コード(新)
           ) VALUES (
             area_base_rec.area_base_code
            ,area_base_rec.area_base_name
            ,under_area_base_rec.child_base_code
            ,under_area_base_rec.child_base_name
            ,area_base_rec.mail_to_1
            ,area_base_rec.mail_to_2
            ,area_base_rec.mail_to_3
            ,area_base_rec.mail_to_4
            ,under_area_base_rec.base_sort_code
           )
           ;
         EXCEPTION
           WHEN OTHERS THEN
             --メッセージ生成
             lv_msg_token := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                           ,iv_name         => cv_msg_mail_tmp  -- メッセージコード
                          );
             lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                           ,iv_name         => cv_msg_ins_err   -- メッセージコード
                           ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                           ,iv_token_value1 => lv_msg_token     -- トークン値1
                           ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                           ,iv_token_value2 => SQLERRM          -- トークン値1
                          );
             lv_errbuf := lv_errmsg;
             RAISE ins_error_expt;
         END;
       END LOOP under_area_base_cur;
       CLOSE under_area_base_cur;
--
     END LOOP area_base_loop;
     CLOSE area_base_cur;
--
    --処理区分が従業員集計の場合
    ELSIF ( iv_process = cv_emp ) THEN
--
      BEGIN
        ---------------------------
        --一時表に挿入(従業員集計)
        ---------------------------
        INSERT INTO xxcos_tmp_mail_send (
           area_base_code  --地区コード
          ,area_base_name  --地区名称
          ,base_code       --拠点コード
          ,base_name       --拠点名
          ,mail_to_1       --宛先１
          ,mail_to_2       --宛先２
          ,mail_to_3       --宛先３
          ,mail_to_4       --宛先４
          ,base_sort_code  --本部コード(新)
        )
          SELECT  ''                area_base_code
                 ,''                area_base_name
                 ,flvv.lookup_code  base_code
                 ,flvv.description  base_name
                 ,flvv.attribute5   mail_to_1
                 ,flvv.attribute6   mail_to_2
                 ,flvv.attribute7   mail_to_3
                 ,flvv.attribute8   mail_to_4
                 ,''                base_sort_code
          FROM    xxcos_mail_send_status_trn xmsst --メール配信状況トラン
                 ,fnd_lookup_values_vl       flvv  --売上目標送信先マスタ
          WHERE   xmsst.target_date       = gd_proc_date          --起動日
          AND     xmsst.summary_type      = iv_process            --従業員集計
          AND     xmsst.send_flag         = cv_no                 --未処理
          AND     xmsst.send_time        <= gv_proc_time          --配信タイミングが起動時間より前
          AND     xmsst.send_time         = flvv.attribute4
          AND     flvv.lookup_type        = cv_send_mail          --XXCOS1_SALES_TARGET_SEND_MAIL
          AND     flvv.enabled_flag       = cv_yes                --有効
          AND     gd_data_target_day      BETWEEN flvv.start_date_active
                                          AND     NVL( flvv.end_date_active, gd_data_target_day ) --対象期間内
          AND     flvv.attribute1         = cv_yes                --従業員集計
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ生成
          lv_msg_token := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                        ,iv_name         => cv_msg_mail_tmp  -- メッセージコード
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                        ,iv_name         => cv_msg_ins_err   -- メッセージコード
                        ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                        ,iv_token_value1 => lv_msg_token     -- トークン値1
                        ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                        ,iv_token_value2 => SQLERRM          -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE ins_error_expt;
      END;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN ins_error_expt THEN
      --カーソルクローズ
      IF ( area_base_cur%ISOPEN ) THEN
        CLOSE area_base_cur;
      END IF;
      IF ( under_area_base_cur%ISOPEN ) THEN
        CLOSE under_area_base_cur;
      END IF;
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
  END ins_target_date;
--
--
  /**********************************************************************************
   * Procedure Name   : edit_mail_text
   * Description      : メール本文編集(A-5)
   ***********************************************************************************/
  PROCEDURE edit_mail_text(
    it_edit_tab               IN  g_edit_ttype, -- 1.メール内容編集用テーブル型
    in_target_amount          IN  NUMBER,       -- 2.目標金額(計)
    in_sale_amount_month_sum  IN  NUMBER,       -- 3.実績金額(計)
    iv_pattern                IN  VARCHAR2,     -- 4.編集パターン( 1:地区 2:拠点 3:従業員 )
    ov_errbuf                 OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_mail_text'; -- プログラム名
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
    cv_canma           CONSTANT VARCHAR2(1) := ',';  --宛先編集用
    cv_t               CONSTANT VARCHAR2(1) := 'T';  --見出し取得用
    cv_part            CONSTANT VARCHAR2(1) := ':';  --区切り
    cv_parentheses_l   CONSTANT VARCHAR2(1) := '(';  --括弧(左)
    cv_parentheses_r   CONSTANT VARCHAR2(1) := ')';  --括弧(右)
    cn_no_target_amt   CONSTANT NUMBER      := 0;    --目標が0の場合の達成率
--
    -- *** ローカル変数 ***
    lt_target_name     fnd_lookup_values_vl.description%TYPE;  --売上目標名称
    lv_text            VARCHAR2(20000);                        --メール本文編集用
    lv_pattern         VARCHAR2(1);                            --メール編集パターン
    ln_target_amount   NUMBER := 0;                            --目標金額計算用
    ln_sales_amount    NUMBER := 0;                            --実績金額計算用
    ln_achievement_cal NUMBER := 0;                            --達成率計算用
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
    <<edit_loop>>
    FOR i IN 1.. it_edit_tab.COUNT LOOP
--
      --最初の1行
      IF ( i = 1) THEN
--
        --配列用添え字カウントアップ
        gn_ins_wf_cnt := gn_ins_wf_cnt + 1;
--
        --メール編集パターン判定(拠点は自拠点と地区に分かれる為)
        IF ( iv_pattern = cv_base ) THEN
--
          --地区コードと拠点コードが異なる場合は地区
          IF ( it_edit_tab(i).total_code <> it_edit_tab(i).line_code ) THEN
            lv_pattern := cv_area;       --地区
          --同じ場合は自拠点
          ELSE
            lv_pattern := cv_base;       --拠点
          END IF;
--
        ELSE
          lv_pattern   := cv_emp;        --従業員
        END IF;
--
        ------------
        --シーケンス
        ------------
        SELECT xxccp_wf_mail_s01.NEXTVAL
        INTO   gt_wf_mail_tab(gn_ins_wf_cnt).wf_mail_id
        FROM   DUAL
        ;
--
        ------------
        --宛先編集
        ------------
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := it_edit_tab(i).mail_to_1;
        --宛先2
        IF ( it_edit_tab(i).mail_to_2 IS NOT NULL ) THEN
          gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := gt_wf_mail_tab(gn_ins_wf_cnt).mail_to || cv_canma || it_edit_tab(i).mail_to_2;
        END IF;
        --宛先3
        IF ( it_edit_tab(i).mail_to_3 IS NOT NULL ) THEN
          gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := gt_wf_mail_tab(gn_ins_wf_cnt).mail_to || cv_canma || it_edit_tab(i).mail_to_3;
        END IF;
        --宛先4
        IF ( it_edit_tab(i).mail_to_4 IS NOT NULL ) THEN
          gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := gt_wf_mail_tab(gn_ins_wf_cnt).mail_to || cv_canma || it_edit_tab(i).mail_to_4;
        END IF;
--
        -----------------
        --メールCC
        -----------------
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_cc  := NULL;
--
        -----------------
        --メールBCC
        -----------------
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_bcc := NULL;
--
        ------------------
        --メール件名編集
        ------------------
        BEGIN
          SELECT flvv.description description
          INTO   lt_target_name
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type                = cv_item_g_sum
          AND    SUBSTRB(flvv.lookup_code, 1, 3) = SUBSTRB( it_edit_tab(i).target_management_code, 1, 3 )  --最初3桁が対象のコード
          AND    flvv.attribute3                 = cv_t                                                    --見出し
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_target_name := NULL;
        END;
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_subject := SUBSTRB( it_edit_tab(i).target_month, 3, 2) || g_fixed_word_tab(1)   || --年
                                                      SUBSTRB( it_edit_tab(i).target_month, 5, 2) || g_fixed_word_tab(2)   || --月
                                                      cv_part                                                              || --区切り
                                                      lt_target_name                                                       || --売上目標名称
                                                      cv_parentheses_l || it_edit_tab(i).total_name || cv_parentheses_r;      --地区(拠点)名称
--
        ----------------
        --WHOカラム
        ----------------
        gt_wf_mail_tab(gn_ins_wf_cnt).created_by              :=  cn_created_by;
        gt_wf_mail_tab(gn_ins_wf_cnt).creation_date           :=  cd_creation_date;
        gt_wf_mail_tab(gn_ins_wf_cnt).last_updated_by         :=  cn_last_updated_by;
        gt_wf_mail_tab(gn_ins_wf_cnt).last_update_date        :=  cd_last_update_date;
        gt_wf_mail_tab(gn_ins_wf_cnt).last_update_login       :=  cn_last_update_login;
        gt_wf_mail_tab(gn_ins_wf_cnt).request_id              :=  cn_request_id;
        gt_wf_mail_tab(gn_ins_wf_cnt).program_application_id  :=  cn_program_application_id;
        gt_wf_mail_tab(gn_ins_wf_cnt).program_id              :=  cn_program_id;
        gt_wf_mail_tab(gn_ins_wf_cnt).program_update_date     :=  cd_program_update_date;
--
        ----------------
        -- 合計行の編集
        ----------------
        --目標金額の計算(千円単位四捨五入)
        ln_target_amount := ROUND( in_target_amount / 1000 );
        --実績金額の計算(千円単位四捨五入)
        ln_sales_amount  := ROUND( in_sale_amount_month_sum / 1000 );
--
        --達成率の計算(小数第１位以下切捨て) ※目標・実績は四捨五入後の値で計算
        IF ( in_target_amount <> 0 ) THEN
          ln_achievement_cal := TRUNC( ( ln_sales_amount / ln_target_amount ) * 100, 1 );
        ELSE
          ln_achievement_cal := cn_no_target_amt; --目標が0の場合エラーとなる為
        END IF;
--
        --見出し(地区)
        IF ( lv_pattern = cv_area ) THEN
          lv_text := g_fixed_word_tab(3) || CHR(10);  --地区計(固定値)
        --見出し(拠点)
        ELSIF ( lv_pattern = cv_base ) THEN
          lv_text := g_fixed_word_tab(4) || CHR(10);  --拠点計(固定値)
        --見出し(従業員)
        ELSIF ( lv_pattern = cv_emp  ) THEN
          lv_text := g_fixed_word_tab(4) || CHR(10);  --拠点計(固定値)
        END IF;
--
        --目標・実績・達成率の編集
        lv_text := lv_text || '  ' || it_edit_tab(i).total_code || ' ' || it_edit_tab(i).total_name          --地区コード・地区名称
                           || CHR(10);
        lv_text := lv_text || '    ' || g_fixed_word_tab(6) || ' ' || LPAD( TO_CHAR( ln_target_amount ),9 ,' ' )   || g_fixed_word_tab(9)  --目標金額
                           || CHR(10);
        lv_text := lv_text || '    ' || g_fixed_word_tab(7) || ' ' || LPAD( TO_CHAR( ln_sales_amount ),9 ,' ' )    || g_fixed_word_tab(9)  --実績金額
                           || CHR(10);
        lv_text := lv_text || '    ' || g_fixed_word_tab(8) || ' ' || LPAD( TO_CHAR( ln_achievement_cal, cv_num_achieve ),7 ,' ' ) || g_fixed_word_tab(10) --達成率
                           || CHR(10);
        lv_text := lv_text || CHR(10); --空白行
--
        --明細の見出し(地区)
        IF ( lv_pattern = cv_area ) THEN
          lv_text := lv_text || g_fixed_word_tab(4) || CHR(10);  --拠点計(固定値)
        --明細の見出し(従業員)
        ELSIF ( lv_pattern = cv_emp ) THEN
          lv_text := lv_text || g_fixed_word_tab(5) || CHR(10);  --営業員計(固定値)
        END IF;
--
      END IF;
--
      --拠点計は1行のみ(合計行のみなので処理修了)
      IF ( lv_pattern = cv_base ) THEN
        EXIT;
      END IF;
--
      --------------------------------------------------
      --明細行編集(地区・従業員の場合)
      --------------------------------------------------
      --変数初期化
      ln_target_amount   := 0;
      ln_sales_amount    := 0;
      ln_achievement_cal := 0;
--
      --目標金額の計算(千円単位四捨五入)
      ln_target_amount := ROUND( it_edit_tab(i).target_amount / 1000 );
      --実績金額の計算(千円単位四捨五入)
      ln_sales_amount  := ROUND( it_edit_tab(i).sale_amount_month_sum / 1000 );
--
      --達成率の計算(小数第１位以下切捨て) ※目標・実績は四捨五入後の値で計算
      IF ( it_edit_tab(i).target_amount <> 0 ) THEN
        ln_achievement_cal := TRUNC( ( ln_sales_amount / ln_target_amount ) * 100, 1 );
      ELSE
        ln_achievement_cal := cn_no_target_amt; --目標が0の場合エラーとなる為
      END IF;
--
      --目標・実績・達成率の編集
      lv_text := lv_text || '  ' || it_edit_tab(i).line_code || ' ' || it_edit_tab(i).line_name             --拠点コード・拠点名称
                         || CHR(10);
      lv_text := lv_text || '    ' || g_fixed_word_tab(6) || ' ' || LPAD( TO_CHAR( ln_target_amount ),9 ,' ' )   || g_fixed_word_tab(9)  --目標金額
                         || CHR(10);
      lv_text := lv_text || '    ' || g_fixed_word_tab(7) || ' ' || LPAD( TO_CHAR( ln_sales_amount ),9 ,' ' )    || g_fixed_word_tab(9)  --実績金額
                         || CHR(10); 
      lv_text := lv_text || '    ' || g_fixed_word_tab(8) || ' ' || LPAD( TO_CHAR( ln_achievement_cal, cv_num_achieve ),7 ,' ' ) || g_fixed_word_tab(10) --達成率
                         || CHR(10); 
      lv_text := lv_text || CHR(10); --空白行
--
    END LOOP edit_loop;
--
    gt_wf_mail_tab(gn_ins_wf_cnt).mail_text := SUBSTRB( lv_text, 1, 4000 );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END edit_mail_text;
--
  /**********************************************************************************
   * Procedure Name   : get_send_mail_data_e
   * Description      : メール配信データ取得(従業員計)(A-6)
   ***********************************************************************************/
  PROCEDURE get_send_mail_data_e(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_send_mail_data_e'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lt_target_management_code    xxcso_wk_sales_target.target_management_code%TYPE;  --目標管理項目コード(ブレーク判定用)
    lt_base_code                 xxcos_tmp_mail_send.base_code%TYPE;                 --拠点コード(ブレーク判定用)
    lv_last_flag                 VARCHAR2(1);                                        --最終データ判定用
    ln_sum_target_amount         NUMBER;                                             --拠点計(目標)
    ln_sum_sale_amount_month_sum NUMBER;                                             --拠点計(実績)
    ln_work_cnt                  BINARY_INTEGER;                                     --配列用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 従業員集計用カーソル
    CURSOR get_emp_data_cur
    IS
      SELECT  /*+
                 LEADING(xtms xwst xrid)
                 USE_NL(xtms xwst xrid )
                 INDEX(xrid xxcos_rs_info_day_pk)
              */
              xwst.target_management_code        target_management_code  --目標管理項目コード
             ,xwst.target_month                  target_month            --対象年月
             ,xtms.base_code                     base_code               --拠点コード
             ,xtms.base_name                     base_name               --拠点名
             ,xwst.employee_code                 employee_code           --営業員コード
             ,xrid.employee_name                 employee_name           --営業員名
             ,SUM( xwst.target_amount )          target_amount           --目標金額
             ,SUM( xwst.sale_amount_month_sum )  sale_amount_month_sum   --実績金額
             ,xtms.mail_to_1                     mail_to_1               --宛先1
             ,xtms.mail_to_2                     mail_to_2               --宛先2
             ,xtms.mail_to_3                     mail_to_3               --宛先3
             ,xtms.mail_to_4                     mail_to_4               --宛先4
      FROM    xxcos_tmp_mail_send    xtms  --売上目標状況メール配信一時表
             ,xxcso_wk_sales_target  xwst  --売上目標ワーク
             ,xxcos_rs_info_day      xrid  --営業員情報日次
      WHERE   xtms.base_code          = xwst.base_code
      AND     xwst.target_month       = TO_CHAR( gd_data_target_day, cv_month ) --対象とする年月(月初は前月、それ以外は当月)
      AND     EXISTS (
                SELECT 1
                FROM   xxcso_sales_target_mst xstm --売上目標マスタ
                WHERE  xstm.employee_code          = xwst.employee_code
                AND    xstm.target_month           = xwst.target_month
                AND    xstm.base_code              = xwst.base_code
                AND    xstm.target_management_code = xwst.target_management_code
                AND    ROWNUM                      = 1
              )                                                                 --目標が紐付く行
      AND     xrid.rs_info_id         = (
                SELECT xridi.rs_info_id
                FROM   xxcos_rs_info_day xridi
                WHERE  xridi.employee_number   = xwst.employee_code
                AND    xridi.base_code         = xwst.base_code
                AND    gd_data_target_day      BETWEEN TRUNC( xridi.effective_start_date, cv_date_mm )
                                                AND     LAST_DAY( xridi.effective_end_date )
                AND    gd_data_target_day      BETWEEN TRUNC( xridi.per_effective_start_date, cv_date_mm )
                                                AND     LAST_DAY( xridi.per_effective_end_date )
                AND    gd_data_target_day      BETWEEN TRUNC( xridi.paa_effective_start_date, cv_date_mm )
                                                AND     LAST_DAY( xridi.paa_effective_end_date )
                AND    ROWNUM                  = 1
             )                                                                  --該当の月で複数同一拠点が存在する場合１つを取得
      GROUP BY
               xwst.target_management_code   --目標管理項目コード
              ,xwst.target_month             --対象年月
              ,xtms.base_code                --拠点
              ,xtms.base_name                --拠点名
              ,xwst.employee_code            --営業員コード
              ,xrid.employee_name            --営業員名
              ,xtms.mail_to_1                --宛先1
              ,xtms.mail_to_2                --宛先2
              ,xtms.mail_to_3                --宛先3
              ,xtms.mail_to_4                --宛先4
              ,xrid.group_code               --グループ番号
              ,xrid.group_in_sequence        --グループ順位
      ORDER BY
               xwst.target_management_code       --目標管理項目コード
              ,xtms.base_code                    --拠点
              ,TO_NUMBER(xrid.group_code)        --グループ番号
              ,TO_NUMBER(xrid.group_in_sequence) --グループ順位
              ,xwst.employee_code                --従業員コード
      ;
    -- *** ローカルテーブル ***
    TYPE l_emp_data_ttype IS TABLE OF get_emp_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    -- *** ローカル配列 ***
    l_emp_data_tab       l_emp_data_ttype;
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 変数初期化
    ln_sum_target_amount          := 0;
    ln_sum_sale_amount_month_sum  := 0;
    ln_work_cnt                   := 0;
--
    -- オープン
    OPEN get_emp_data_cur;
    -- データ取得
    FETCH get_emp_data_cur BULK COLLECT INTO l_emp_data_tab;
    -- クローズ
    CLOSE get_emp_data_cur;
--
    --処理データがない場合、警告で修了
    IF ( l_emp_data_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                    ,iv_name         => cv_msg_no_data   -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    <<emp_edit_loop>>
    FOR i IN 1.. l_emp_data_tab.COUNT LOOP
--
      --最初の1件目の場合、ブレーク変数を設定
      IF ( i = 1 ) THEN
        lt_target_management_code := l_emp_data_tab(i).target_management_code;
        lt_base_code              := l_emp_data_tab(i).base_code;
      END IF;
--
      --最終行の場合、最終データ編集用のフラグをONにする
      IF ( i = l_emp_data_tab.COUNT ) THEN
        lv_last_flag := cv_yes;
      END IF;
--
      --ブレークしたら編集処理を実施
      IF (
           ( lt_target_management_code <> l_emp_data_tab(i).target_management_code )
           OR
           ( lt_base_code              <> l_emp_data_tab(i).base_code )
         )
      THEN
        ---------------------------
        -- メール本文編集(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.メール内容編集用テーブル型
          in_target_amount          => ln_sum_target_amount,          -- 2.目標金額(拠点計)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.実績金額(拠点計)
          iv_pattern                => cv_emp,                        -- 4.編集パターン(従業員)
          ov_errbuf                 => lv_errbuf,                     --   エラー・メッセージ           --# 固定 #
          ov_retcode                => lv_retcode,                    --   リターン・コード             --# 固定 #
          ov_errmsg                 => lv_errmsg                      --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --配列用変数初期化
        gt_edit_tab.DELETE;
        ln_work_cnt                   := 1;
        --拠点計初期化
        ln_sum_target_amount          := l_emp_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := l_emp_data_tab(i).sale_amount_month_sum;
        --ブレーク変数設定
        lt_target_management_code     := l_emp_data_tab(i).target_management_code;
        lt_base_code                  := l_emp_data_tab(i).base_code;
--
      ELSE
--
        --配列用変数カウントアップ
        ln_work_cnt                   := ln_work_cnt + 1;
        --拠点計用
        ln_sum_target_amount          := ln_sum_target_amount         + l_emp_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := ln_sum_sale_amount_month_sum + l_emp_data_tab(i).sale_amount_month_sum;
--
      END IF;
--
      --明細行設定
      gt_edit_tab(ln_work_cnt).target_management_code  :=  l_emp_data_tab(i).target_management_code;
      gt_edit_tab(ln_work_cnt).target_month            :=  l_emp_data_tab(i).target_month;
      gt_edit_tab(ln_work_cnt).total_code              :=  l_emp_data_tab(i).base_code;
      gt_edit_tab(ln_work_cnt).total_name              :=  l_emp_data_tab(i).base_name;
      gt_edit_tab(ln_work_cnt).line_code               :=  l_emp_data_tab(i).employee_code;
      gt_edit_tab(ln_work_cnt).line_name               :=  l_emp_data_tab(i).employee_name;
      gt_edit_tab(ln_work_cnt).target_amount           :=  l_emp_data_tab(i).target_amount;
      gt_edit_tab(ln_work_cnt).sale_amount_month_sum   :=  l_emp_data_tab(i).sale_amount_month_sum;
      gt_edit_tab(ln_work_cnt).mail_to_1               :=  l_emp_data_tab(i).mail_to_1;
      gt_edit_tab(ln_work_cnt).mail_to_2               :=  l_emp_data_tab(i).mail_to_2;
      gt_edit_tab(ln_work_cnt).mail_to_3               :=  l_emp_data_tab(i).mail_to_3;
      gt_edit_tab(ln_work_cnt).mail_to_4               :=  l_emp_data_tab(i).mail_to_4;
--
      --最終行のメール編集
      IF ( lv_last_flag = cv_yes ) THEN
        ---------------------------
        -- メール本文編集(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.メール内容編集用テーブル型
          in_target_amount          => ln_sum_target_amount,          -- 2.目標金額(拠点計)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.実績金額(拠点計)
          iv_pattern                => cv_emp,                        -- 4.編集パターン(従業員)
          ov_errbuf                 => lv_errbuf,                     --   エラー・メッセージ           --# 固定 #
          ov_retcode                => lv_retcode,                    --   リターン・コード             --# 固定 #
          ov_errmsg                 => lv_errmsg                      --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP emp_edit_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 対象データなし例外ハンドラ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_send_mail_data_e;
--
  /**********************************************************************************
   * Procedure Name   : get_send_mail_data_b
   * Description      : メール配信データ取得(拠点計)(A-7)
   ***********************************************************************************/
  PROCEDURE get_send_mail_data_b(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_send_mail_data_b'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lt_target_management_code    xxcso_wk_sales_target.target_management_code%TYPE;  --目標管理項目コード(ブレーク判定用)
    lt_area_base_code            xxcos_tmp_mail_send.area_base_code%TYPE;            --地区コード(ブレーク判定用)
    lv_last_flag                 VARCHAR2(1);                                        --最終データ判定用
    ln_sum_target_amount         NUMBER;                                             --地区計(目標)
    ln_sum_sale_amount_month_sum NUMBER;                                             --地区計(実績)
    ln_work_cnt                  BINARY_INTEGER;                                     --配列用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 拠点集計用カーソル
    CURSOR get_base_data_cur
    IS
      SELECT  /*+
                 LEADING( xtms xwst )
                 USE_NL( xtms xwst )
              */
              xwst.target_management_code        target_management_code  --目標管理項目コード
             ,xwst.target_month                  target_month            --対象年月
             ,xtms.area_base_code                area_base_code          --地区コード
             ,xtms.area_base_name                area_base_name          --地区名称
             ,xtms.base_code                     base_code               --拠点コード
             ,xtms.base_name                     base_name               --拠点名
             ,SUM( xwst.target_amount )          target_amount           --目標金額
             ,SUM( xwst.sale_amount_month_sum )  sale_amount_month_sum   --実績金額
             ,xtms.mail_to_1                     mail_to_1               --宛先1
             ,xtms.mail_to_2                     mail_to_2               --宛先2
             ,xtms.mail_to_3                     mail_to_3               --宛先3
             ,xtms.mail_to_4                     mail_to_4               --宛先4
      FROM    xxcos_tmp_mail_send    xtms  --売上目標状況メール配信一時表
             ,xxcso_wk_sales_target  xwst  --売上目標ワーク
      WHERE   xtms.base_code          = xwst.base_code
      AND     xwst.target_month       = TO_CHAR( gd_data_target_day, cv_month ) --対象とする年月(月初は前月、それ以外は当月)
      AND     EXISTS (
                SELECT 1
                FROM   xxcso_sales_target_mst xstm --売上目標マスタ
                WHERE  xstm.target_month           = xwst.target_month
                AND    xstm.base_code              = xwst.base_code
                AND    xstm.target_management_code = xwst.target_management_code
                AND    ROWNUM                      = 1
              )                                                                 --目標が紐付く行
      GROUP BY
               xwst.target_management_code   --目標管理項目コード
              ,xwst.target_month             --対象年月
              ,xtms.area_base_code           --地区コード
              ,xtms.area_base_name           --地区名称
              ,xtms.base_code                --拠点
              ,xtms.base_name                --拠点名
              ,xtms.mail_to_1                --宛先1
              ,xtms.mail_to_2                --宛先2
              ,xtms.mail_to_3                --宛先3
              ,xtms.mail_to_4                --宛先4
              ,xtms.base_sort_code           --本部コード(新)
      ORDER BY
               xwst.target_management_code   --目標管理項目コード
              ,xtms.area_base_code           --拠点
              ,xtms.base_sort_code           --本部コード(新)
      ;
    -- *** ローカルテーブル ***
    TYPE l_base_data_ttype IS TABLE OF get_base_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    -- *** ローカル配列 ***
    l_base_data_tab       l_base_data_ttype;
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 変数初期化
    ln_sum_target_amount          := 0;
    ln_sum_sale_amount_month_sum  := 0;
    ln_work_cnt                   := 0;
--
    -- オープン
    OPEN get_base_data_cur;
    -- データ取得
    FETCH get_base_data_cur BULK COLLECT INTO l_base_data_tab;
    -- クローズ
    CLOSE get_base_data_cur;
--
    --処理データがない場合、警告で修了
    IF ( l_base_data_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                    ,iv_name         => cv_msg_no_data   -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    <<emp_edit_loop>>
    FOR i IN 1.. l_base_data_tab.COUNT LOOP
--
      --最初の1件目の場合、ブレーク変数を設定
      IF ( i = 1 ) THEN
        lt_target_management_code  := l_base_data_tab(i).target_management_code;
        lt_area_base_code          := l_base_data_tab(i).area_base_code;
      END IF;
--
      --最終行の場合、最終データ編集用のフラグをONにする
      IF ( i = l_base_data_tab.COUNT ) THEN
        lv_last_flag := cv_yes;
      END IF;
--
      --ブレークしたら編集処理を実施
      IF (
           ( lt_target_management_code <> l_base_data_tab(i).target_management_code )
           OR
           ( lt_area_base_code         <> l_base_data_tab(i).area_base_code )
         )
      THEN
        ---------------------------
        -- メール本文編集(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.メール内容編集用テーブル型
          in_target_amount          => ln_sum_target_amount,          -- 2.目標金額(拠点計)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.実績金額(拠点計)
          iv_pattern                => cv_base,                       -- 4.編集パターン(拠点)
          ov_errbuf                 => lv_errbuf,                     --   エラー・メッセージ           --# 固定 #
          ov_retcode                => lv_retcode,                    --   リターン・コード             --# 固定 #
          ov_errmsg                 => lv_errmsg                      --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --配列用変数初期化
        gt_edit_tab.DELETE;
        ln_work_cnt                   := 1;
        --地区計初期化
        ln_sum_target_amount          := l_base_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := l_base_data_tab(i).sale_amount_month_sum;
        --ブレーク変数設定
        lt_target_management_code     := l_base_data_tab(i).target_management_code;
        lt_area_base_code             := l_base_data_tab(i).area_base_code;
--
      ELSE
--
        --配列用変数カウントアップ
        ln_work_cnt                   := ln_work_cnt + 1;
        --地区計用
        ln_sum_target_amount          := ln_sum_target_amount         + l_base_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := ln_sum_sale_amount_month_sum + l_base_data_tab(i).sale_amount_month_sum;
--
      END IF;
--
      --明細行設定
      gt_edit_tab(ln_work_cnt).target_management_code  :=  l_base_data_tab(i).target_management_code;
      gt_edit_tab(ln_work_cnt).target_month            :=  l_base_data_tab(i).target_month;
      gt_edit_tab(ln_work_cnt).total_code              :=  l_base_data_tab(i).area_base_code;
      gt_edit_tab(ln_work_cnt).total_name              :=  l_base_data_tab(i).area_base_name;
      gt_edit_tab(ln_work_cnt).line_code               :=  l_base_data_tab(i).base_code;
      gt_edit_tab(ln_work_cnt).line_name               :=  l_base_data_tab(i).base_name;
      gt_edit_tab(ln_work_cnt).target_amount           :=  l_base_data_tab(i).target_amount;
      gt_edit_tab(ln_work_cnt).sale_amount_month_sum   :=  l_base_data_tab(i).sale_amount_month_sum;
      gt_edit_tab(ln_work_cnt).mail_to_1               :=  l_base_data_tab(i).mail_to_1;
      gt_edit_tab(ln_work_cnt).mail_to_2               :=  l_base_data_tab(i).mail_to_2;
      gt_edit_tab(ln_work_cnt).mail_to_3               :=  l_base_data_tab(i).mail_to_3;
      gt_edit_tab(ln_work_cnt).mail_to_4               :=  l_base_data_tab(i).mail_to_4;
--
      --最終行のメール編集
      IF ( lv_last_flag = cv_yes ) THEN
        ---------------------------
        -- メール本文編集(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.メール内容編集用テーブル型
          in_target_amount          => ln_sum_target_amount,          -- 2.目標金額(拠点計)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.実績金額(拠点計)
          iv_pattern                => cv_base,                       -- 4.編集パターン(拠点)
          ov_errbuf                 => lv_errbuf,                     --   エラー・メッセージ           --# 固定 #
          ov_retcode                => lv_retcode,                    --   リターン・コード             --# 固定 #
          ov_errmsg                 => lv_errmsg                      --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP emp_edit_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 対象データなし例外ハンドラ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_send_mail_data_b;
--
  /**********************************************************************************
   * Procedure Name   : ins_wf_mail
   * Description      : アラートメール送信テーブル作成(A-8)
   ***********************************************************************************/
  PROCEDURE ins_wf_mail(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_wf_mail'; -- プログラム名
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
    lv_msg_token   VARCHAR2(100); --メッセージ取得用
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
    --対象件数取得
    gn_target_cnt := gt_wf_mail_tab.COUNT;
--
    BEGIN
      FORALL i IN 1..gt_wf_mail_tab.COUNT
        --アラートメール送信テーブルデータ挿入処理
        INSERT INTO xxccp_wf_mail
        VALUES gt_wf_mail_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ生成
        lv_msg_token := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                      ,iv_name         => cv_msg_mail_wf   -- メッセージコード
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                      ,iv_name         => cv_msg_ins_err   -- メッセージコード
                      ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                      ,iv_token_value1 => lv_msg_token     -- トークン値1
                      ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                      ,iv_token_value2 => SQLERRM          -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
    --成功件数取得
    gn_normal_cnt := gn_target_cnt;
    
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_wf_mail;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_send_mail_trn
   * Description      : メール配信状況トラン更新(A-9)
   ***********************************************************************************/
  PROCEDURE upd_send_mail_trn(
    iv_process   IN   VARCHAR2,     -- 1.( 1：部門集計 2：従業員集計 )
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_send_mail_trn'; -- プログラム名
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
    lv_msg_token   VARCHAR2(100);  --メッセージトークン用
--
    -- *** ローカル・カーソル ***
    --メール配信状況トランロックカーソル
    CURSOR upd_trn_cur
    IS
      SELECT 1
      FROM   xxcos_mail_send_status_trn xmsst
      WHERE  xmsst.send_time    <= gv_proc_time  --配信タイミング
      AND    xmsst.summary_type  = iv_process    --集計区分
      AND    xmsst.target_date   = gd_proc_date  --対象日
      AND    xmsst.send_flag     = cv_no         --送信フラグ
      FOR UPDATE NOWAIT
      ;
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
    --エラー時のトークン取得
    lv_msg_token  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                      ,iv_name         => cv_msg_mail_trn  -- メッセージコード
                     );
    --ロック取得
    BEGIN
      OPEN  upd_trn_cur;
      CLOSE upd_trn_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_lock_err  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab       -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --更新
    BEGIN
      UPDATE  xxcos_mail_send_status_trn xmsst
      SET     xmsst.send_flag               = cv_yes  --送信済
             ,xmsst.last_updated_by         = cn_last_updated_by
             ,xmsst.last_update_date        = cd_last_update_date
             ,xmsst.last_update_login       = cn_last_update_login
             ,xmsst.request_id              = cn_request_id
             ,xmsst.program_application_id  = cn_program_application_id
             ,xmsst.program_id              = cn_program_id
             ,xmsst.program_update_date     = cd_program_update_date
      WHERE   xmsst.send_time    <= gv_proc_time  --配信タイミング
      AND     xmsst.summary_type  = iv_process    --集計区分
      AND     xmsst.target_date   = gd_proc_date  --対象日
      AND     xmsst.send_flag     = cv_no         --送信フラグ
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_upd_err   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tab_name  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token     -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_data  -- トークンコード1
                       ,iv_token_value2 => SQLERRM          -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END upd_send_mail_trn;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_process    IN  VARCHAR2,     -- 1.処理区分 ( 1：部門集計 2：従業員集計 3:パージ処理)
    iv_trg_time   IN  VARCHAR2,     -- 2.配信タイミング ( HH24:MI 形式)
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
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_process  => iv_process,        -- 1.処理区分
      iv_trg_time => iv_trg_time,       -- 2.配信タイミング ( HH24:MI 形式)
      ov_errbuf   => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode  => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );        
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --処理区分がパージの場合
    IF ( iv_process = cv_parge ) THEN
      -- ===============================
      -- メール配信関連テーブル削除(A-2)
      -- ===============================
      del_send_mail_relate(
        ov_errbuf  => lv_errbuf,   -- エラー・メッセージ           --# 固定 #
        ov_retcode => lv_retcode,  -- リターン・コード             --# 固定 #
        ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    --処理区分がパージ処理以外の場合
    ELSE
--
      --処理区分ごとに起動日の初回起動の場合
      IF ( gv_trn_create_flag = cv_yes ) THEN
        -- ===================================
        -- メール配信状況トラン作成(A-3)
        -- ===================================
        ins_send_mail_trn(
          iv_process => iv_process,  -- 1.処理区分
          ov_errbuf  => lv_errbuf,   -- エラー・メッセージ           --# 固定 #
          ov_retcode => lv_retcode,  -- リターン・コード             --# 固定 #
          ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ====================================
      -- メール配信対象一時テーブル作成(A-4)
      -- ====================================
      ins_target_date(
        iv_process => iv_process,  -- 1.処理区分
        ov_errbuf  => lv_errbuf,   --   エラー・メッセージ           --# 固定 #
        ov_retcode => lv_retcode,  --   リターン・コード             --# 固定 #
        ov_errmsg  => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- 起動が従業員集計の場合
      IF ( iv_process = cv_emp ) THEN
--
        -- ====================================
        -- メール配信データ取得(従業員計)(A-6)
        -- ====================================
        get_send_mail_data_e(
          ov_errbuf  => lv_errbuf,   -- エラー・メッセージ           --# 固定 #
          ov_retcode => lv_retcode,  -- リターン・コード             --# 固定 #
          ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
      -- 起動が拠点集計の場合
      ELSIF (  iv_process = cv_base ) THEN
--
        -- ====================================
        -- メール配信データ取得(拠点計)(A-7)
        -- ====================================
        get_send_mail_data_b(
          ov_errbuf  => lv_errbuf,   -- エラー・メッセージ           --# 固定 #
          ov_retcode => lv_retcode,  -- リターン・コード             --# 固定 #
          ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      IF ( gt_wf_mail_tab.COUNT <> 0 ) THEN
        -- ====================================
        -- アラートメール送信テーブル作成(A-8)
        -- ====================================
        ins_wf_mail(
          ov_errbuf  => lv_errbuf,   -- エラー・メッセージ           --# 固定 #
          ov_retcode => lv_retcode,  -- リターン・コード             --# 固定 #
          ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
        -- ====================================
        -- メール配信状況トラン更新(A-9)
        -- ====================================
        upd_send_mail_trn(
          iv_process => iv_process,  -- 1.処理区分
          ov_errbuf  => lv_errbuf,   --   エラー・メッセージ           --# 固定 #
          ov_retcode => lv_retcode,  --   リターン・コード             --# 固定 #
          ov_errmsg  => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
      --対象が0件の場合、警告終了
      ELSE
        ov_retcode := cv_status_warn;
      END IF;
--
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_process    IN  VARCHAR2,      -- 1.処理区分 (1：部門集計 2：従業員集計 3:パージ処理)
    iv_trg_time   IN  VARCHAR2       -- 2.配信タイミング ( HH24:MI 形式)
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
       iv_process
      ,iv_trg_time
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
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
      --エラー件数カウント
      gn_error_cnt  := 1;
      --成功件数初期化
      gn_normal_cnt := 0;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCOS002A08C;
/
