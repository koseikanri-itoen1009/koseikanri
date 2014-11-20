CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A08C(body)
 * Description      : 要求の発行画面から、営業員ごとに指定日を含む月の1日～指定日まで
 *                    訪問実績の無い顧客を表示します。
 * MD.050           : MD050_CSO_019_A08_未訪問顧客一覧表
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_param              パラメータ・チェック(A-2)
 *  process_data           データ加工(A-4)
 *  insert_row             ワークテーブルデータ登録(A-5)
 *  update_row             営業員別軒数計をワークテーブルデータ登録(A-6)
 *  act_svf                SVF起動(A-7)
 *  delete_row             ワークテーブルデータ削除(A-8)
 *  submain                メイン処理プロシージャ
 *                           データ取得(A-3)
 *                           SVF起動APIエラーチェック(A-9)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-10)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-12    1.0   Ryo.Oikawa       新規作成
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF起動API埋め込み
 *  2009-03-11    1.1   Kazuyo.Hosoi     【障害対応047】顧客区分、ステータス抽出条件変更
 *  2009-03-19    1.1   Mio.Maruyama     【障害対応070】SVF起動関数コール位置修正(submain)
 *  2009-04-22    1.2   Daisuke.Abe      【T1_0680】ルートNO対応
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897対応
 *  2009-05-14    1.4   Makoto.Ohtsuki   【T1_0790】出力条件の変更
 *  2009-05-20    1.5   Makoto.Ohtsuki   ＳＴ障害対応(T1_0696)
 *  2009-06-03    1.6   Kazuo.Satomura   ＳＴ障害対応(T1_0696 SQLERRMを削除)
 *  2009-06-04    1.7   Kazuo.Satomura   ＳＴ障害対応(T1_1329)
 *  2010-05-25    1.8   T.Maruyama       E_本稼動_02809 訪問回数取得できない場合ゼロとする
 *  2011-07-14    1.9   K.Kiriu          E_本稼動_07825 PT対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A08C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  cv_ref_app_name        CONSTANT VARCHAR2(5)   := 'XXCMM';         -- 参照コード用アプリケーション短縮名
  cn_org_id              CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ログイン組織ＩＤ
  --
  cv_report_id           CONSTANT VARCHAR2(30)  := 'XXCSO019A08C';  -- 帳票ID
  -- 日付書式
  cv_format_date_ymd1    CONSTANT VARCHAR2(8)   := 'YYYYMMDD';      -- 日付フォーマット（年月日）
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00129';  -- パラメータ出力
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00005';  -- 必須項目エラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042';  -- ＤＢ登録・更新エラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  -- APIエラーメッセージ
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- 明細0件メッセージ
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00132';  -- 年月日の型違いメッセージ
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00157';  -- 年月日の未来日メッセージ
      /* 20090514_Ohtsuki_T1_0790 START*/
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラーメッセージ
      /* 20090514_Ohtsuki_T1_0790 END  */
  -- トークンコード
  cv_tkn_param_nm        CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_param1          CONSTANT VARCHAR2(20) := 'PARAM1';
  cv_tkn_act             CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_entry           CONSTANT VARCHAR2(20) := 'ENTRY';
      /* 20090514_Ohtsuki_T1_0790 START*/
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
      /* 20090514_Ohtsuki_T1_0790 END  */
  --
  cv_msg_prnthss_l       CONSTANT VARCHAR2(1)  := '(';
  cv_msg_prnthss_r       CONSTANT VARCHAR2(1)  := ')';
  cv_msg_comma           CONSTANT VARCHAR2(1)  := ',';
  --
  cn_user_id             CONSTANT NUMBER       := fnd_global.user_id;           -- ユーザーID
  cn_resp_id             CONSTANT NUMBER       := fnd_global.resp_id;           -- 職責ID
  cd_sysdate             CONSTANT DATE         := SYSDATE;                      -- SYSDATE
  cv_rep_tp              CONSTANT VARCHAR2(1)  := '1';                          -- 帳票タイプ
  cv_true                CONSTANT VARCHAR2(4)  := 'TRUE';                       -- 戻り値判断用
  cv_false               CONSTANT VARCHAR2(5)  := 'FALSE';                      -- 戻り値判断用
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 未訪問顧客一覧表帳票ワークテーブル データ格納用レコード型定義
  TYPE g_rp_nov_data_rtype IS RECORD(
     line_num                      xxcso_rep_novisit.line_num%TYPE                     -- 行番号
    ,report_id                     xxcso_rep_novisit.report_id%TYPE                    -- 帳票ＩＤ
    ,report_name                   xxcso_rep_novisit.report_name%TYPE                  -- 帳票タイトル
    ,output_date                   xxcso_rep_novisit.output_date%TYPE                  -- 出力日時
    ,base_date                     xxcso_rep_novisit.base_date%TYPE                    -- 基準年月日
    ,base_date_start               xxcso_rep_novisit.base_date_start%TYPE              -- 基準日START
    ,base_date_end                 xxcso_rep_novisit.base_date_end%TYPE                -- 基準日END
    ,base_code                     xxcso_rep_novisit.base_code%TYPE                    -- 拠点コード
    ,hub_name                      xxcso_rep_novisit.hub_name%TYPE                     -- 拠点名称
    ,employee_number               xxcso_rep_novisit.employee_number%TYPE              -- 営業員コード
    ,employee_name                 xxcso_rep_novisit.employee_name%TYPE                -- 営業員名
    ,total_count                   xxcso_rep_novisit.total_count%TYPE                  -- 総軒数計／軒数計
    ,route_no                      xxcso_rep_novisit.route_no%TYPE                     -- ルートNo.
    ,visit_times                   xxcso_rep_novisit.visit_times%TYPE                  -- 訪問回数
    ,account_number                xxcso_rep_novisit.account_number%TYPE               -- 顧客コード
    ,account_name                  xxcso_rep_novisit.account_name%TYPE                 -- 顧客名
    ,final_call_date               xxcso_rep_novisit.final_call_date%TYPE              -- 最終訪問日
    ,final_tran_date               xxcso_rep_novisit.final_tran_date%TYPE              -- 最終取引日
    ,business_low_type             xxcso_rep_novisit.business_low_type%TYPE            -- 業態（小分類）
    ,mc_flag                       xxcso_rep_novisit.mc_flag%TYPE                      -- ＭＣフラグ
    ,created_by                    xxcso_rep_novisit.created_by%TYPE                   -- 作成者
    ,creation_date                 xxcso_rep_novisit.creation_date%TYPE                -- 作成日
    ,last_updated_by               xxcso_rep_novisit.last_updated_by%TYPE              -- 最終更新者
    ,last_update_date              xxcso_rep_novisit.last_update_date%TYPE             -- 最終更新日
    ,last_update_login             xxcso_rep_novisit.last_update_login%TYPE            -- 最終更新ログイン
    ,request_id                    xxcso_rep_novisit.request_id%TYPE                   -- 要求ID
    ,program_application_id        xxcso_rep_novisit.program_application_id%TYPE       -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
    ,program_id                    xxcso_rep_novisit.program_id%TYPE                   -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
    ,program_update_date           xxcso_rep_novisit.program_update_date%TYPE          -- ﾌﾟﾛｸﾞﾗﾑ更新日
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_current_date     IN  VARCHAR2         -- 基準日
    ,ov_employee_number  OUT NOCOPY VARCHAR2  -- 従業員コード
    ,ov_employee_name    OUT NOCOPY VARCHAR2  -- 漢字氏名
    ,ov_work_base_code   OUT NOCOPY VARCHAR2  -- 勤務地拠点コード
    ,ov_hub_name         OUT NOCOPY VARCHAR2  -- 勤務地拠点名
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- *** ローカル変数 ***
    lt_employee_number    xxcso_employees_v2.employee_number%TYPE;  -- 従業員コード
    lt_last_name          xxcso_employees_v2.last_name%TYPE;        -- 漢字姓
    lt_first_name         xxcso_employees_v2.first_name%TYPE;       -- 漢字名
    lv_work_base_code     VARCHAR2(150);                            -- 勤務地拠点コード
    lv_work_base_name     VARCHAR2(4000);                           -- 勤務地拠点名
    -- メッセージ出力用
    lv_msg_crnt_dt       VARCHAR2(5000);
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
    -- 入力パラメータメッセージ出力
    -- ===========================
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- メッセージ取得(基準日)
    lv_msg_crnt_dt := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01      --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry          --トークンコード1
                       ,iv_token_value1 => iv_current_date       --トークン値1
                     );
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_crnt_dt
    );
    -- ===========================
    -- ログインユーザー情報取得
    -- ===========================
--
    BEGIN
      SELECT  xev.employee_number                               -- 従業員コード
             ,xev.last_name                                     -- 漢字性
             ,xev.first_name                                    -- 漢字名
             ,xxcso_util_common_pkg.get_emp_parameter(
                xev.work_base_code_new
               ,xev.work_base_code_old
               ,xev.issue_date
               ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
              ) Work_base_code                                  -- 勤務地拠点コード
             ,xxcso_util_common_pkg.get_emp_parameter(
                xev.work_base_name_new
               ,xev.work_base_name_old
               ,xev.issue_date
               ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
              ) Work_base_name                                  -- 勤務地拠点名
      INTO    lt_employee_number
             ,lt_last_name
             ,lt_first_name
             ,lv_work_base_code
             ,lv_work_base_name
      FROM    xxcso_employees_v2  xev                          -- 従業員マスタ（最新）ビュー
      WHERE   xev.user_id = cn_user_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- OUTパラメータの設定
    ov_employee_number := lt_employee_number;  -- 従業員コード
    ov_employee_name   := SUBSTRB(lt_last_name || lt_first_name, 1, 40);  -- 漢字氏名
    ov_work_base_code  := lv_work_base_code;   -- 勤務地拠点コード
    ov_hub_name        := lv_work_base_name;   -- 勤務地拠点名
--
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
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
   * Procedure Name   : chk_param
   * Description      : パラメータ・チェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
     iv_current_date     IN  VARCHAR2         -- 基準日
    ,od_current_date     OUT DATE             -- 基準日(DATE型)
    ,od_first_date       OUT DATE             -- 基準日の月初(DATE型)
    ,ov_emp_chk_cd       OUT VARCHAR2         -- 営業員チェック値
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';   -- プログラム名
    cv_first                CONSTANT VARCHAR2(100)   := '01';          -- 月初
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- *** ローカル定数 ***
    cv_crnt_dt          CONSTANT VARCHAR2(100)   := '基準日';
    cv_first_dt         CONSTANT VARCHAR2(100)   := '基準日の月初';
      /* 20090514_Ohtsuki_T1_0790 START*/
    cv_emp_flg           CONSTANT VARCHAR2(100) := 'XXCSO1_ALL_EMP_SEL_FLG_08C';                    -- XXCSO:配下従業員出力可能フラグ
    cv_emp_flg_yes       CONSTANT VARCHAR2(30) := 'Y';
      /* 20090514_Ohtsuki_T1_0790 END  */
    -- *** ローカル変数 ***
    ld_sysdate          DATE;                  -- システム日付
    ld_current_date     DATE;                  -- 基準日
    ld_first_date       DATE;                  -- 基準日の月初
    lv_retcd            VARCHAR2(5);           -- 共通関数戻り値格納
      /* 20090514_Ohtsuki_T1_0790 START*/
    lv_emp_flg           VARCHAR2(10);                                                              -- プロファイル取得用
      /* 20090514_Ohtsuki_T1_0790 END  */
    -- メッセージ出力用
    lv_msg              VARCHAR2(5000);
    -- *** ローカル例外 ***
    chk_param_expt   EXCEPTION;  -- 基準日未入力エラー
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
    -- パラメータ必須チェック
    -- ===========================
    IF (iv_current_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02      --メッセージコード
                    ,iv_token_name1  => cv_tkn_clmn           --トークンコード1
                    ,iv_token_value1 => cv_crnt_dt            --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- ===========================
    -- パラメータ（基準日）チェック
    -- ===========================
    ld_sysdate := TRUNC(xxcso_util_common_pkg.get_online_sysdate);
--
    BEGIN
      SELECT TO_DATE(iv_current_date, cv_format_date_ymd1)   current_date  -- INパラメータ基準日
      INTO   ld_current_date
      FROM   dual
      WHERE  TO_DATE(iv_current_date, cv_format_date_ymd1) <= ld_sysdate
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_09    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => cv_crnt_dt          --トークン値1
                     );
        /* 2009.06.03 K.Satomura T1_0696対応 START */
        --lv_errbuf := lv_errmsg || SQLERRM;
        lv_errbuf := lv_errmsg;
        /* 2009.06.03 K.Satomura T1_0696対応 END */
        RAISE chk_param_expt;
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => cv_crnt_dt          --トークン値1
                     );
        /* 2009.06.03 K.Satomura T1_0696対応 START */
        --lv_errbuf := lv_errmsg || SQLERRM;
        lv_errbuf := lv_errmsg;
        /* 2009.06.03 K.Satomura T1_0696対応 END */
        RAISE chk_param_expt;
    END;
--
    BEGIN
      SELECT TO_DATE(TO_CHAR(ld_current_date,'YYYYMM')||cv_first,'YYYYMMDD')   first_date  -- INパラメータ基準日
      INTO   ld_first_date
      FROM   dual
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => cv_first_dt         --トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE chk_param_expt;
    END;
--
    -- ===========================
    -- 従業員コード判定
    -- ===========================
      /* 20090514_Ohtsuki_T1_0790 START*/
--    lv_retcd   := xxcso_util_common_pkg.chk_responsibility(
--                    in_user_id     => cn_user_id       -- ログインユーザＩＤ
--                   ,in_resp_id     => cn_resp_id       -- 職位ＩＤ
--                   ,iv_report_type => cv_rep_tp        -- 帳票タイプ（1:営業員別、2:営業員グループ別、その他は指定不可）
--                  );
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
-- プロファイル値取得
    lv_emp_flg := FND_PROFILE.VALUE(cv_emp_flg);
--
    IF (lv_emp_flg IS NULL) THEN                                                                    -- プロファイルの取得に失敗した場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_app_name                          -- アプリケーション短縮名
                                           ,iv_name         => cv_tkn_number_10                     -- メッセージコード
                                           ,iv_token_name1  => cv_tkn_prof_nm                       -- トークンコード
                                           ,iv_token_value1 => cv_emp_flg                           -- トークン値
                                           );
      lv_errbuf := lv_errmsg;
      RAISE chk_param_expt;
    END IF;
--
    IF (lv_emp_flg = cv_emp_flg_yes) THEN                                                           -- 出力可能フラグ = 'Y'の場合
      lv_retcd := cv_false;
    ELSE
      lv_retcd := cv_true;
    END IF;
      /* 20090514_Ohtsuki_T1_0790 END*/
    -- OUTパラメータの設定
    od_current_date      := ld_current_date;    -- 基準日
    od_first_date        := ld_first_date;      -- 基準日の月初
    ov_emp_chk_cd        := lv_retcd;           -- 営業員チェック値
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** パラメータチェックエラー ***
    WHEN chk_param_expt THEN
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : process_data
   * Description      : データ加工(A-4)
   ***********************************************************************************/
  PROCEDURE process_data(
     io_rp_nov_dt_rec      IN OUT NOCOPY g_rp_nov_data_rtype      -- 未訪問顧客データ
    ,iv_account_sts        IN  VARCHAR2                           -- 顧客ステータス（ソート用）
    ,ov_errbuf             OUT NOCOPY VARCHAR2                    -- エラー・メッセージ            --# 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2                    -- リターン・コード              --# 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2                    -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'process_data';  -- プログラム名
    cv_sort_type1           CONSTANT VARCHAR2(1)     := '1';  -- ソートタイプ
    cv_zero                 CONSTANT VARCHAR2(1)     := '0';  -- 「0」
    cv_one                  CONSTANT VARCHAR2(1)     := '1';  -- 「1」
    /* 2010/05/25 T.Maruyama E_本稼動_02809 START */
    cn_zero                 CONSTANT NUMBER          := 0;  -- 「0」
    /* 2010/05/25 T.Maruyama E_本稼動_02809 END */
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
    -- クイックコード取得
    cv_lkup_tp_cst_kkyaku_sts       CONSTANT VARCHAR2(30) := 'XXCMM_CUST_KOKYAKU_STATUS';
    cv_yes                          CONSTANT VARCHAR2(30) := 'Y';
    -- メッセージ出力用トークン
    cv_tkn_party_name               CONSTANT VARCHAR2(100) := '顧客ステータス名称';
    cv_tkn_mc                       CONSTANT VARCHAR2(100) := 'ＭＣ';
    -- *** ローカル変数 ***
    lv_route_no              xxcso_in_route_no.route_no%TYPE;    -- ルートNO
    lv_mc_flag               VARCHAR2(1);          -- ＭＣフラグ
    ln_visit_times           NUMBER;               -- 訪問回数
    ld_sysdate               DATE;                 -- システム日付
    -- メッセージ格納用
    lv_msg                   VARCHAR2(5000);
    -- 警告メッセージ出力判断フラグ
    lv_msg_flg               BOOLEAN DEFAULT FALSE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- システム日付を編集し、格納
    ld_sysdate := TRUNC(xxcso_util_common_pkg.get_online_sysdate);
--
    -- ===========================
    -- ルートNO、ＭＣフラグ取得
    -- ===========================
    IF ( iv_account_sts  = cv_sort_type1 ) THEN
      lv_route_no := io_rp_nov_dt_rec.route_no;
      lv_mc_flag  := cv_zero;
      /* 20090422_abe_T1_0680 START*/
      IF ( lv_route_no IS NOT NULL ) THEN
      /* 20090422_abe_T1_0680 END*/
        -- ===========================
        -- 訪問回数取得
        -- ===========================
        xxcso_route_common_pkg.calc_visit_times(
           it_route_number  => lv_route_no
          ,on_times         => ln_visit_times
          ,ov_errbuf        => lv_errbuf
          ,ov_retcode       => lv_retcode
          ,ov_errmsg        => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          /* 2010/05/25 T.Maruyama E_本稼動_02809 START */
          ln_visit_times := cn_zero;
          --RAISE global_api_others_expt;
          /* 2010/05/25 T.Maruyama E_本稼動_02809 END */
        END IF;
      /* 20090422_abe_T1_0680 START*/
      END IF;
      /* 20090422_abe_T1_0680 END*/
    ELSE
      lv_route_no    := cv_tkn_mc;
      lv_mc_flag     := cv_one;
      ln_visit_times := NULL;
    END IF;
--
    -- ====================================
    -- 取得値をOUTパラメータに設定
    -- ====================================
    io_rp_nov_dt_rec.route_no              := lv_route_no;                -- ルートNO
    io_rp_nov_dt_rec.mc_flag               := lv_mc_flag;                 -- ＭＣフラグ
    io_rp_nov_dt_rec.visit_times           := ln_visit_times;             -- 訪問回数
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
  END process_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ワークテーブルデータ登録(A-5)
   ***********************************************************************************/
  PROCEDURE insert_row(
     i_rp_nov_dt_rec        IN  g_rp_nov_data_rtype      -- 未訪問顧客データ
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- プログラム名
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
    cv_report_name        CONSTANT VARCHAR2(40)  := '≪未訪問顧客一覧表≫'; -- 帳票タイトル
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '未訪問顧客一覧表帳票ワークテーブルの登録';
    -- *** ローカル例外 ***
    insert_row_expt     EXCEPTION;          -- ワークテーブル出力処理例外
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
      -- ワークテーブル出力
      INSERT INTO xxcso_rep_novisit
        ( line_num                     -- 行番号
         ,report_id                    -- 帳票ＩＤ
         ,report_name                  -- 帳票タイトル
         ,output_date                  -- 出力日時
         ,base_date                    -- 基準年月日
         ,base_date_start              -- 基準日START
         ,base_date_end                -- 基準日END
         ,base_code                    -- 拠点コード
         ,hub_name                     -- 拠点名称
         ,employee_number              -- 従業員コード
         ,employee_name                -- 従業員名
         ,total_count                  -- 総軒数計／軒数計
         ,route_no                     -- ルートNO.
         ,visit_times                  -- 訪問回数
         ,account_number               -- 顧客コード
         ,account_name                 -- 顧客名
         ,final_call_date              -- 最終訪問日
         ,final_tran_date              -- 最終取引日
         ,business_low_type            -- 業態（小分類）
         ,mc_flag                      -- ＭＣフラグ
         ,created_by                   -- 作成者
         ,creation_date                -- 作成日
         ,last_updated_by              -- 最終更新者
         ,last_update_date             -- 最終更新日
         ,last_update_login            -- 最終更新ログイン
         ,request_id                   -- 要求ＩＤ        
         ,program_application_id       -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
         ,program_id                   -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
         ,program_update_date          -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
      VALUES
        ( i_rp_nov_dt_rec.line_num                     -- 行番号
         ,cv_report_id                                 -- 帳票ＩＤ
         ,cv_report_name                               -- 帳票タイトル
         ,cd_sysdate                                   -- 出力日時
         ,i_rp_nov_dt_rec.base_date                    -- 基準年月日
         ,i_rp_nov_dt_rec.base_date_start              -- 基準日START
         ,i_rp_nov_dt_rec.base_date_end                -- 基準日END
         ,i_rp_nov_dt_rec.base_code                    -- 拠点コード
         ,i_rp_nov_dt_rec.hub_name                     -- 拠点名称
         ,i_rp_nov_dt_rec.employee_number              -- 従業員コード
         ,i_rp_nov_dt_rec.employee_name                -- 従業員名
         ,i_rp_nov_dt_rec.total_count                  -- 総軒数計／軒数計
         ,i_rp_nov_dt_rec.route_no                     -- ルートNO.
         ,i_rp_nov_dt_rec.visit_times                  -- 訪問回数
         ,i_rp_nov_dt_rec.account_number               -- 顧客コード
         ,i_rp_nov_dt_rec.account_name                 -- 顧客名
         ,i_rp_nov_dt_rec.final_call_date              -- 最終訪問日
         ,i_rp_nov_dt_rec.final_tran_date              -- 最終取引日
         ,i_rp_nov_dt_rec.business_low_type            -- 業態（小分類）
         ,i_rp_nov_dt_rec.mc_flag                      -- ＭＣフラグ
         ,i_rp_nov_dt_rec.created_by                   -- 作成者
         ,i_rp_nov_dt_rec.creation_date                -- 作成日
         ,i_rp_nov_dt_rec.last_updated_by              -- 最終更新者
         ,i_rp_nov_dt_rec.last_update_date             -- 最終更新日
         ,i_rp_nov_dt_rec.last_update_login            -- 最終更新ログイン
         ,i_rp_nov_dt_rec.request_id                   -- 要求ＩＤ        
         ,i_rp_nov_dt_rec.program_application_id       -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
         ,i_rp_nov_dt_rec.program_id                   -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
         ,i_rp_nov_dt_rec.program_update_date          -- ﾌﾟﾛｸﾞﾗﾑ更新日
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_04        --メッセージコード
                 ,iv_token_name1  => cv_tkn_act              --トークンコード1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --トークン値1
                 ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                 ,iv_token_value2 => SQLERRM                 --トークン値2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ワークテーブル出力処理例外 ***
    WHEN insert_row_expt THEN
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
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : update_row
   * Description      : 営業員別軒数計をワークテーブルデータ登録(A-6)
   ***********************************************************************************/
  PROCEDURE update_row(
     iv_employee_number     IN  VARCHAR2                 -- 従業員番号
    ,in_emp_cnt             IN  NUMBER                   -- 軒数
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'update_row';     -- プログラム名
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '未訪問顧客一覧表帳票ワークテーブルの更新';
    -- *** ローカル例外 ***
    update_row_expt     EXCEPTION;          -- ワークテーブル出力処理例外
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
      -- ワークテーブル出力
      UPDATE  xxcso_rep_novisit
        SET   total_count = in_emp_cnt
        /* 2009.06.04 K.Satomura T1_1329対応 START */
        --WHERE employee_number = iv_employee_number;
        WHERE employee_number = iv_employee_number
        AND   request_id      = cn_request_id
        ;
        /* 2009.06.04 K.Satomura T1_1329対応 END */
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_04        --メッセージコード
                 ,iv_token_name1  => cv_tkn_act              --トークンコード1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --トークン値1
                 ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                 ,iv_token_value2 => SQLERRM                 --トークン値2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE update_row_expt;
    END;
--
  EXCEPTION
    -- *** ワークテーブル出力処理例外 ***
    WHEN update_row_expt THEN
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
  END update_row;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF起動(A-7)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF起動';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO019A08S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO019A08S.vrq';  -- クエリー様式ファイル名
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
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd1)
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
     ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
     ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
     );
--
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
   * Procedure Name   : delete_row
   * Description      : ワークテーブルデータ削除(A-8)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_row';     -- プログラム名
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '未訪問顧客一覧表帳票ワークテーブル';
    -- *** ローカル変数 ***
    lt_line_num           xxcso_rep_novisit.line_num%TYPE;  -- 未訪問顧客一覧表帳票ワークテーブルＩＤ格納用
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
    -- ワークテーブルデータ削除
    -- ==========================
    DELETE FROM xxcso_rep_novisit xrn -- 未訪問顧客一覧表帳票ワークテーブル
    WHERE xrn.request_id = cn_request_id;
--
  EXCEPTION
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
  END delete_row;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     iv_current_date     IN  VARCHAR2          --   基準日
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
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
    cb_true                CONSTANT BOOLEAN := TRUE;
    cv_tkn_nvt_info        CONSTANT VARCHAR2(100) := '未訪問顧客一覧情報';
    cv_zero                CONSTANT VARCHAR2(5)   := '0';
    cv_accnt_type1         CONSTANT VARCHAR2(5)   := '10'; -- 顧客区分（顧客）
    cv_accnt_type2         CONSTANT VARCHAR2(5)   := '15'; -- 顧客区分（巡回）
    cv_accnt_sts1          CONSTANT VARCHAR2(5)   := '25'; -- 顧客ステータス（SP決済済）
    cv_accnt_sts2          CONSTANT VARCHAR2(5)   := '30'; -- 顧客ステータス（承認済み）
    cv_accnt_sts3          CONSTANT VARCHAR2(5)   := '40'; -- 顧客ステータス（顧客）
    cv_accnt_sts4          CONSTANT VARCHAR2(5)   := '50'; -- 顧客ステータス（休止）
    cv_accnt_sts5          CONSTANT VARCHAR2(5)   := '99'; -- 顧客ステータス（対象外）
    cv_target_div          CONSTANT VARCHAR2(5)   := '1';  -- 訪問対象
    /* 2011-07-14 E_本稼動_07825 ADD START */
    cd_sysdate             CONSTANT DATE          := TRUNC(xxcso_util_common_pkg.get_online_sysdate); -- システム日付
    /* 2011-07-14 E_本稼動_07825 ADD END */
    -- OUTパラメータ格納用
    ld_current_date        DATE;                     -- 基準日
    ld_first_date          DATE;                     -- 基準日の月初
    lv_employee_number     VARCHAR(30);              -- 従業員番号
    lv_employee_name       VARCHAR(40);              -- 漢字氏名
    lv_work_base_code      VARCHAR2(150);            -- 勤務地拠点コード
    lv_hub_name            VARCHAR2(4000);           -- 勤務地拠点名
    lv_emp_chk_cd          VARCHAR2(5);              -- 営業員チェック値
    ln_emp_cnt             NUMBER(10);               -- 軒数
    -- *** ローカル変数 ***
    lv_current_sts         VARCHAR2(100);            -- 顧客ステータス（ソート用）
    ln_ins_cnt             NUMBER DEFAULT 0;         -- カウンタ
    ln_line_num            NUMBER DEFAULT 0;         -- 行番号
    -- SVF起動API戻り値格納用
    lv_errbuf_svf          VARCHAR2(5000);           -- エラー・メッセージ
    lv_retcode_svf         VARCHAR2(1);              -- リターン・コード
    lv_errmsg_svf          VARCHAR2(5000);           -- ユーザー・エラー・メッセージ
--
    -- *** ローカル・カーソル ***
    -- 営業員別未訪問顧客データ抽出カーソル
    CURSOR get_novisit_data_cur(
               iv_wb_cd      IN VARCHAR2  -- 拠点コード
              ,iv_emp_num    IN VARCHAR2  -- 従業員コード
              ,id_frt_dt     IN DATE      -- 基準日の月初
              ,id_crnt_dt    IN DATE      -- 基準日
              ,iv_emp_chk_cd IN VARCHAR2  -- 営業員チェック値
            )
    IS
      SELECT  xrv.employee_number         employee_number       -- 従業員番号
             ,SUBSTRB(xrv.last_name || xrv.first_name, 1, 40)   employee_name         -- 漢字氏名
             /* 2011-07-14 E_本稼動_07825 MOD START */
             --,CASE
             --   WHEN  xcav.customer_status <= cv_accnt_sts2 THEN
             --     xcav.customer_status
             --   ELSE
             --     xcrv.route_number
             -- END                         route_customer       -- ルートNO/顧客ステータス
             ,xcav.customer_status        customer_status      -- 顧客ステータス
             /* 2011-07-14 E_本稼動_07825 MOD END */
             ,xcav.account_number         account_number       -- 顧客コード
             ,xcav.party_name             party_name           -- 顧客名
             ,xcav.final_tran_date        final_tran_date      -- 最終取引日
             ,xcav.final_call_date        final_call_date      -- 最終訪問日
             ,xcav.business_low_type      business_low_type    -- 業態（小分類）
             ,CASE
                WHEN  xcav.customer_status <= cv_accnt_sts2 THEN
                  2
                ELSE
                  1
              END                         status_sort          -- 顧客ステータス（ソート用）
      FROM    xxcso_resources_v2      xrv                      -- リソースマスタ(最新)VIEW
             ,xxcso_cust_accounts_v   xcav                     -- 顧客マスタVIEW
             /* 2011-07-14 E_本稼動_07825 DEL START */
             --,xxcso_cust_routes_v2    xcrv                     -- 顧客ルートNo（最新）VIEW
             /* 2011-07-14 E_本稼動_07825 DEL END */
             ,xxcso_cust_resources_v2 xcrev                    -- 営業員担当顧客（最新）VIEW
             /* 2011-07-14 E_本稼動_07825 DEL START */
             --,(
             --   SELECT employee_number
             --         ,xxcso_util_common_pkg.get_emp_parameter(
             --            xrv2.work_base_code_new
             --           ,xrv2.work_base_code_old
             --           ,xrv2.issue_date
             --           ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)) work_base_code
             --   FROM xxcso_resources_v2 xrv2
             -- ) xrv3
             /* 2011-07-14 E_本稼動_07825 DEL END */
      /* 2011-07-14 E_本稼動_07825 MOD START */
      --WHERE   xrv3.work_base_code   = iv_wb_cd
      WHERE   xxcso_util_common_pkg.get_emp_parameter(
                         xrv.work_base_code_new
                        ,xrv.work_base_code_old
                        ,xrv.issue_date
                        ,cd_sysdate ) = iv_wb_cd
      /* 2011-07-14 E_本稼動_07825 MOD END */
        AND   (
                xcav.final_call_date < id_frt_dt
                OR
                xcav.final_call_date > id_crnt_dt
                OR
                xcav.final_call_date IS NULL
              )
        AND ((xcav.customer_class_code = cv_accnt_type1
               AND xcav.customer_status IN (cv_accnt_sts1, cv_accnt_sts2,
                                             cv_accnt_sts3, cv_accnt_sts4)
              )
            OR (xcav.customer_class_code = cv_accnt_type2
               AND xcav.customer_status = cv_accnt_sts5
              ))
        AND   xcav.vist_target_div = cv_target_div
        AND ((iv_emp_chk_cd  =  cv_true
               AND xrv.employee_number   = iv_emp_num
              )
            OR (iv_emp_chk_cd   =  cv_false
               AND 1 = 1
              ))
        /* 2011-07-14 E_本稼動_07825 DEL START */
        --AND   xrv3.employee_number  = xrv.employee_number
        /* 2011-07-14 E_本稼動_07825 DEL END */
        AND   xcrev.employee_number = xrv.employee_number
        AND   xcrev.account_number  = xcav.account_number
        /* 2011-07-14 E_本稼動_07825 DEL START */
        --AND   xcav.account_number   = xcrv.account_number(+)
        /* 2011-07-14 E_本稼動_07825 DEL END */
      ;
--
    -- *** ローカル・カーソル ***
    -- 営業員別軒数抽出カーソル
    CURSOR get_emp_cnt_cur
    IS
      SELECT  xrn.employee_number         employee_number       -- 従業員番号
             ,COUNT(xrn.employee_number)  emp_cnt               -- 軒数
      FROM    xxcso_rep_novisit   xrn
      WHERE   xrn.request_id = cn_request_id
        AND   xrn.mc_flag    = cv_zero
      GROUP BY xrn.employee_number
      ;

    -- *** ローカル・レコード ***
    l_get_novisit_dt_rec     get_novisit_data_cur%ROWTYPE;
    l_rp_nov_dt_rec          g_rp_nov_data_rtype;
    l_get_emp_cnt_rec        get_emp_cnt_cur%ROWTYPE;
    -- *** ローカル・例外 ***
    no_data_expt           EXCEPTION; -- 対象データ0件例外
    -- メッセージ格納用
    lv_msg                   VARCHAR2(5000);
    -- 警告メッセージ出力判断フラグ
    lv_msg_flg               BOOLEAN DEFAULT FALSE;
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
    -- カウンタの初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    ln_ins_cnt    := 0;
--
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
      iv_current_date    => iv_current_date     -- 基準日
     ,ov_employee_number => lv_employee_number  -- 従業員コード
     ,ov_employee_name   => lv_employee_name    -- 漢字氏名
     ,ov_work_base_code  => lv_work_base_code   -- 勤務地拠点コード
     ,ov_hub_name        => lv_hub_name         -- 勤務地拠点名
     ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode         => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-2.パラメータチェック
    -- ========================================
    chk_param(
       iv_current_date     => iv_current_date        -- 基準日
      ,od_current_date     => ld_current_date        -- 基準日(DATE型)
      ,od_first_date       => ld_first_date          -- 基準日の月初(DATE型)
      ,ov_emp_chk_cd       => lv_emp_chk_cd          -- 営業員チェック値
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-3.データ取得
    -- ========================================
    -- カーソルオープン
    OPEN get_novisit_data_cur(
               iv_wb_cd      => lv_work_base_code  -- 拠点コード
              ,iv_emp_num    => lv_employee_number -- 従業員コード
              ,id_frt_dt     => ld_first_date      -- 基準日の月初
              ,id_crnt_dt    => ld_current_date    -- 基準日
              ,iv_emp_chk_cd => lv_emp_chk_cd      -- 営業員チェック値
            );
--
    <<get_novisit_data_loop>>
    LOOP
      FETCH get_novisit_data_cur INTO l_get_novisit_dt_rec;
      -- 処理対象件数格納
      gn_target_cnt := get_novisit_data_cur%ROWCOUNT;
--
      -- 処理対象データが存在しなかった場合EXIT
      EXIT WHEN get_novisit_data_cur%NOTFOUND
      OR  get_novisit_data_cur%ROWCOUNT = 0;
--
      -- レコード変数初期化
      l_rp_nov_dt_rec := NULL;
--
      -- 行番号を取得
      ln_line_num := ln_line_num + 1;
--
      -- 取得データを格納
      l_rp_nov_dt_rec.line_num                   := ln_line_num;                             -- 行番号
      l_rp_nov_dt_rec.base_date                  := ld_current_date;                         -- 基準年月日
      l_rp_nov_dt_rec.base_date_start            := ld_first_date;                           -- 基準日START
      l_rp_nov_dt_rec.base_date_end              := ld_current_date;                         -- 基準日END
      l_rp_nov_dt_rec.base_code                  := lv_work_base_code;                       -- 拠点コード
      l_rp_nov_dt_rec.hub_name                   := lv_hub_name;                             -- 拠点名称
      l_rp_nov_dt_rec.employee_number            := l_get_novisit_dt_rec.employee_number;    -- 従業員番号
      l_rp_nov_dt_rec.employee_name              := l_get_novisit_dt_rec.employee_name;      -- 漢字氏名
      /* 2011-07-14 E_本稼動_07825 MOD START */
      --l_rp_nov_dt_rec.route_no                   := l_get_novisit_dt_rec.route_customer;     -- ルートNO/顧客ステータス
      -- ルートNO/顧客ステータス
      IF ( l_get_novisit_dt_rec.customer_status <= cv_accnt_sts2  ) THEN
        l_rp_nov_dt_rec.route_no                 := l_get_novisit_dt_rec.customer_status;
      ELSE
        BEGIN
          --ルートNo取得
          SELECT xcrv.route_number route_number
          INTO   l_rp_nov_dt_rec.route_no
          FROM   xxcso_cust_routes_v2 xcrv
          WHERE  xcrv.account_number = l_get_novisit_dt_rec.account_number
          ;
        EXCEPTION
          WHEN OTHERS THEN
            l_rp_nov_dt_rec.route_no := NULL;
        END;
      END IF;
      /* 2011-07-14 E_本稼動_07825 MOD END */
      l_rp_nov_dt_rec.account_number             := l_get_novisit_dt_rec.account_number;     -- 顧客コード
      l_rp_nov_dt_rec.account_name               := l_get_novisit_dt_rec.party_name;         -- 顧客名
      l_rp_nov_dt_rec.final_tran_date            := l_get_novisit_dt_rec.final_tran_date;    -- 最終取引日
      l_rp_nov_dt_rec.final_call_date            := l_get_novisit_dt_rec.final_call_date;    -- 最終訪問日
      l_rp_nov_dt_rec.business_low_type          := l_get_novisit_dt_rec.business_low_type;  -- 業態（小分類）
      l_rp_nov_dt_rec.created_by                 := cn_created_by;                           -- 作成者
      l_rp_nov_dt_rec.creation_date              := cd_creation_date;                        -- 作成日
      l_rp_nov_dt_rec.last_updated_by            := cn_last_updated_by;                      -- 最終更新者
      l_rp_nov_dt_rec.last_update_date           := cd_last_update_date;                     -- 最終更新日
      l_rp_nov_dt_rec.last_update_login          := cn_last_update_login;                    -- 最終更新ログイン
      l_rp_nov_dt_rec.request_id                 := cn_request_id;                           -- 要求ＩＤ
      l_rp_nov_dt_rec.program_application_id     := cn_program_application_id;               -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
      l_rp_nov_dt_rec.program_id                 := cn_program_id;                           -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
      l_rp_nov_dt_rec.program_update_date        := cd_program_update_date;                  -- ﾌﾟﾛｸﾞﾗﾑ更新日
      lv_current_sts                             := l_get_novisit_dt_rec.status_sort;         -- 顧客ステータス（ソート用）
--
      -- ========================================
      -- A-4.加工処理
      -- ========================================
      process_data(
        io_rp_nov_dt_rec       => l_rp_nov_dt_rec        -- 未訪問顧客データ
       ,iv_account_sts         => lv_current_sts         -- 顧客ステータス（ソート用）
       ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            --# 固定 #
       ,ov_retcode             => lv_retcode             -- リターン・コード              --# 固定 #
       ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ========================================
      -- A-5.ワークテーブル出力
      -- ========================================
      insert_row(
        i_rp_nov_dt_rec        => l_rp_nov_dt_rec        -- 未訪問顧客データ
       ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            --# 固定 #
       ,ov_retcode             => lv_retcode             -- リターン・コード              --# 固定 #
       ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- INSERT成功件数をカウントアップ
      ln_ins_cnt := ln_ins_cnt + 1;
--
    END LOOP get_novisit_data_loop;
--
    -- カーソルクローズ
    CLOSE get_novisit_data_cur;
--
    -- 処理対象データが0件の場合
    IF (gn_target_cnt = 0) THEN
      -- 0件メッセージ出力
      lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name         --アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_07    --メッセージコード
                );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg                                 --ユーザー・エラーメッセージ
      );
--
      ov_retcode := cv_status_normal;
    ELSE
      -- カーソルオープン
      OPEN get_emp_cnt_cur;
--
      <<get_emp_cnt_loop>>
      LOOP
        FETCH get_emp_cnt_cur INTO l_get_emp_cnt_rec;
--
        -- 処理対象データが存在しなかった場合EXIT
        EXIT WHEN get_emp_cnt_cur%NOTFOUND
        OR  get_emp_cnt_cur%ROWCOUNT = 0;
      -- ========================================
      -- A-6.ワークテーブル更新
      -- ========================================
        update_row(
          iv_employee_number     => l_get_emp_cnt_rec.employee_number        -- 従業員番号
         ,in_emp_cnt             => l_get_emp_cnt_rec.emp_cnt                -- 軒数
         ,ov_errbuf              => lv_errbuf                                -- エラー・メッセージ            --# 固定 #
         ,ov_retcode             => lv_retcode                               -- リターン・コード              --# 固定 #
         ,ov_errmsg              => lv_errmsg                                -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP get_emp_cnt_loop;
--
      -- カーソルクローズ
      CLOSE get_emp_cnt_cur;
--
      -- ========================================
      -- A-7.SVF起動
      -- ========================================
      act_svf(
         ov_errbuf     => lv_errbuf_svf                        -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode_svf                       -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg_svf                        -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF  (lv_retcode_svf <> cv_status_error) THEN
        gn_normal_cnt := ln_ins_cnt;
      END IF;
--
    END IF;
--
    -- ========================================
    -- A-8.ワークテーブルデータ削除
    -- ========================================
    delete_row(
       ov_errbuf     => lv_errbuf                        -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode                       -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg                        -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-9.SVF起動APIエラーチェック
    -- ========================================
    IF (lv_retcode_svf = cv_status_error) THEN
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_novisit_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_novisit_data_cur;
      END IF;
--
      IF (get_emp_cnt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_emp_cnt_cur;
      END IF;
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
      -- カーソルがクローズされていない場合
      IF (get_novisit_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_novisit_data_cur;
      END IF;
--
      IF (get_emp_cnt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_emp_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_novisit_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_novisit_data_cur;
      END IF;
--
      IF (get_emp_cnt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_emp_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf             OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode            OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_current_date    IN  VARCHAR2           --   基準日
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--    cv_log_msg         CONSTANT VARCHAR2(100) := 'システムエラーが発生しました。システム管理者に確認してください。';
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
    -- エラーメッセージ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';  -- コンカレントヘッダメッセージ出力 出力区分
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
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
       iv_current_date => iv_current_date    -- 基準日
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.LOG
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
         ,buff   => SUBSTRB(
                    cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf ,1,5000
                    )
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
       );
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => SUBSTRB(
--                      cv_log_msg ||cv_msg_prnthss_l||
--                      cv_pkg_name||cv_msg_cont||
--                      cv_prg_name||cv_msg_part||
--                      lv_errbuf  ||cv_msg_prnthss_r,1,5000
--                    )
--       );                                                     --エラーメッセージ
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
    END IF;
--
    -- =======================
    -- A-10.終了処理 
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
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
END XXCSO019A08C;
/
