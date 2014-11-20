CREATE OR REPLACE PACKAGE BODY xxcmn000001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn000001c(body)
 * Description      : 月次伝票番号更新
 * MD.050           : 月次伝票番号更新       T_MD050_BPO_00A
 * MD.070           : 月次伝票番号更新       T_MD070_BPO_00A
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/27    1.0   Oracle 飯田 甫   初回作成
 *  2009/07/07    1.1   SCS丸下          本番1564対応
 *  2009/07/09    1.2   SCS丸下          API変更
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxcmn000001c';      -- パッケージ名
  gv_app_name            CONSTANT VARCHAR2(5)   := 'XXCMN';             -- アプリケーション短縮名
  gv_prof_option_name    CONSTANT VARCHAR2(16)  := 'XXCMN_SEQ_YYYYMM';  -- プロファイルオプション名
/* 2009/07/09 DEL START
  gn_level_id            CONSTANT NUMBER        := 10001;               -- レベルID
   2009/07/09 DEL END */
--
  gv_yyyymm              CONSTANT VARCHAR2(6)   := 'YYYYMM';            -- 年月
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate             DATE;          -- システム日付
  gn_user_id             NUMBER;        -- ユーザID
  gn_login_id            NUMBER;        -- 最終更新ログイン
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_application_short_name      CONSTANT VARCHAR2(100) := 'XXCMN';
    cv_profile_option_name         CONSTANT VARCHAR2(100) := 'XXCMN_SEQ_YYYYMM';
 /* 2009/07/09 DEL START
    cn_level_id                    CONSTANT NUMBER        := 10001;
    2009/07/09 DEL END */
-- 2009/07/07 ADD START
    cv_no_change_msg               CONSTANT VARCHAR2(100) := '採番変更不要:';
-- 2009/07/07 ADD END
--
    -- *** ローカル変数 ***
    -- プロファイル
 /* 2009/07/09 DEL START
    ln_apprication_id              fnd_profile_option_values.application_id%TYPE;
    ln_profile_option_id           fnd_profile_option_values.profile_option_id%TYPE;
    ln_level_id                    fnd_profile_option_values.level_id%TYPE;
    ln_level_value                 fnd_profile_option_values.level_value%TYPE;
    ln_level_value_application_id  fnd_profile_option_values.level_value_application_id%TYPE;
    lv_profile_option_value        fnd_profile_option_values.profile_option_value%TYPE;
   2009/07/09 DEL END */
    -- 採番関数
    lv_seq_no                      VARCHAR2(12);            -- 採番後の固定長12桁の番号
--
 /* 2009/07/09 DEL START
-- 2009/07/07 ADD START
    lv_present_month fnd_profile_option_values.profile_option_value%TYPE;
-- 2009/07/07 ADD END
   2009/07/09 DEL END */
-- 2009/07/09 ADD START
    lv_profile_option_value        VARCHAR2(100);
    lv_present_month               VARCHAR2(100);
-- 2009/07/09 ADD END
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
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
    --**********************************************
    --***  伝票番号を月次で切り替える処理を行う  ***
    --**********************************************
--
    -- ================================
    -- 0.関連データ取得
    -- ================================
    -- システム日付取得
    gd_sysdate  := SYSDATE;
--
    -- WHOカラム情報取得
    gn_user_id  := FND_GLOBAL.USER_ID;              -- 最終更新ユーザID
    gn_login_id := FND_GLOBAL.LOGIN_ID;             -- 最終更新ログイン
--

-- 2009/07/07 ADD START
 /* 2009/07/09 DEL START
    -- ================================
    -- プロファイル情報取得
    -- ================================
    SELECT TO_CHAR(TO_DATE(fpov.profile_option_value, gv_yyyymm),gv_yyyymm)
    INTO   lv_present_month
    FROM   fnd_profile_option_values  fpov
          ,fnd_profile_options        fpo
          ,fnd_application            fa
    WHERE  fa.application_short_name = gv_app_name
    AND    fpo.application_id        = fa.application_id
    AND    fpo.profile_option_name   = gv_prof_option_name
    AND    fpov.application_id       = fa.application_id
    AND    fpov.level_id             = gn_level_id
    AND    fpo.profile_option_id     = fpov.profile_option_id;
   2009/07/09 DEL END */
--
-- 2009/07/09 ADD END
    lv_present_month := TO_CHAR(TO_DATE(FND_PROFILE.VALUE(gv_prof_option_name), gv_yyyymm),gv_yyyymm);
-- 2009/07/09 ADD END
    IF(lv_present_month < TO_CHAR(gd_sysdate,gv_yyyymm)) THEN
-- 2009/07/07 ADD END
  --
      -- ================================
      -- 1.シーケンスドロップ
      -- ================================
      EXECUTE IMMEDIATE 'DROP SEQUENCE xxcmn.xxcmn_slip_no_s1';
  --
      -- ================================
      -- 2.シーケンス作成
      -- ================================
      EXECUTE IMMEDIATE 'CREATE SEQUENCE xxcmn.xxcmn_slip_no_s1 MINVALUE 1 MAXVALUE 99999999 '
        || 'INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE';
  --
/* 2009/07/09 DEL START
      -- ================================
      -- 3.プロファイル値更新情報取得
      -- ================================
      SELECT fpov.application_id
            ,fpov.profile_option_id
            ,fpov.level_id
            ,fpov.level_value
            ,fpov.level_value_application_id
            ,TO_CHAR(ADD_MONTHS(TO_DATE(fpov.profile_option_value, gv_yyyymm), 1), gv_yyyymm)
      INTO   ln_apprication_id
            ,ln_profile_option_id
            ,ln_level_id
            ,ln_level_value
            ,ln_level_value_application_id
            ,lv_profile_option_value
      FROM   fnd_profile_option_values  fpov
            ,fnd_profile_options        fpo
            ,fnd_application            fa
      WHERE  fa.application_short_name = gv_app_name
      AND    fpo.application_id        = fa.application_id
      AND    fpo.profile_option_name   = gv_prof_option_name
      AND    fpov.application_id       = fa.application_id
      AND    fpov.level_id             = gn_level_id
      AND    fpo.profile_option_id     = fpov.profile_option_id;
  --
      -- ================================
      -- 4.プロファイル値更新
      -- ================================
      fnd_profile_option_values_pkg.update_row(
        x_application_id             => ln_apprication_id
       ,x_profile_option_id          => ln_profile_option_id
       ,x_level_id                   => ln_level_id
       ,x_level_value                => ln_level_value
       ,x_level_value_application_id => ln_level_value_application_id
       ,x_profile_option_value       => lv_profile_option_value
       ,x_last_update_date           => gd_sysdate
       ,x_last_updated_by            => gn_user_id
       ,x_last_update_login          => gn_login_id
      );
   2009/07/09 DEL END */
-- 2009/07/09 ADD START
      -- ================================
      -- 4.プロファイル値更新
      -- ================================
      lv_profile_option_value := TO_CHAR(ADD_MONTHS(TO_DATE(lv_present_month, gv_yyyymm), 1), gv_yyyymm);
      IF(FND_PROFILE.SAVE(gv_prof_option_name, lv_profile_option_value, 'SITE'))THEN
        NULL;
      END IF;
-- 2009/07/09 ADD END
  --
      -- ================================
      -- 5.採番関数の実行(採番可能を確認)
      -- ================================
      xxcmn_common_pkg.get_seq_no(
        iv_seq_class => NULL              -- 採番する番号を表す区分
       ,ov_seq_no    => lv_seq_no         -- 採番した固定長12桁の番号
       ,ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
  --
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- 2009/07/07 ADD START
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, cv_no_change_msg || lv_present_month);
    END IF;
-- 2009/07/07 ADD END
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf           OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2)         -- エラーコード     #固定#
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
--
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add start 1.5
    ELSIF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.5
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
/*
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
*/
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxcmn000001c;
/
