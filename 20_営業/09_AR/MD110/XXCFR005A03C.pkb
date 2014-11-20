CREATE OR REPLACE PACKAGE BODY XXCFR005A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A03C(body)
 * Description      : ロックボックス入金処理自動化
 * MD.050           : MD050_CFR_005_A03_ロックボックス入金処理自動化
 * MD.070           : MD050_CFR_005_A03_ロックボックス入金処理自動化
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 入力パラメータ値ログ出力処理            (A-1)
 *  get_profile_value      P プロファイル取得処理                    (A-2)
 *  get_submit_request     p ロックボックス処理起動処理              (A-4)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.00  SCS 濱中 亮一    初回作成
 *  2009/12/12    1.1   SCS 金田 拓朗    処理後に残るごみデータを削除するよう修正
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR005A03C';        -- パッケージ名
  cv_pg_name         CONSTANT VARCHAR2(100) := 'ARLPLB';              -- コンカレント名
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';               -- アプリケーション短縮名(XXCFR)
  cv_dict_cd         CONSTANT VARCHAR2(100) := 'CFR005A01003';        -- プログラム名
--
  -- メッセージ番号
  cv_msg_005a03_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004';     -- プロファイル取得エラーメッセージ
  cv_msg_005a03_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00012';     -- コンカレント発行エラーメッセージ
  cv_msg_005a03_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00013';     -- コンカレント監視エラーメッセージ
  cv_msg_005a03_067  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00067';     -- ロックボックス正常終了メッセージ
  cv_msg_005a03_027  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00027';     -- ロックボックス警告終了メッセージ
  cv_msg_005a03_028  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00028';     -- ロックボックスエラー終了メッセージ
--
-- トークン
  cv_tkn_prof          CONSTANT VARCHAR2(15) := 'PROF_NAME';            -- プロファイル名
  cv_tkn_prog_name     CONSTANT VARCHAR2(30) := 'PROGRAM_NAME';         -- コンカレントプログラム名
  cv_tkn_request       CONSTANT VARCHAR2(15) := 'REQUEST_ID';           -- 要求ID
  cv_transmission_name CONSTANT VARCHAR2(18) := 'TRANSMISSION_NAME';    -- 伝送名
  cv_tkn_file_name     CONSTANT VARCHAR2(15) := 'FB_FILE_NAME';         -- 対象の伝送名
  cv_tkn_dev_phase     CONSTANT VARCHAR2(15) := 'DEV_PHASE';            -- DEV_PHASE
  cv_tkn_dev_status    CONSTANT VARCHAR2(15) := 'DEV_STATUS';           -- DEV_STATUS
--
  -- コンカレントDEVフェーズ
  cv_dev_phase_complete CONSTANT VARCHAR2(30) := 'COMPLETE';          -- '完了'
--
  -- コンカレントDEVステータス
  cv_dev_status_normal  CONSTANT VARCHAR2(30) := 'NORMAL';            -- '正常'
  cv_dev_status_warn    CONSTANT VARCHAR2(30) := 'WARNING';           -- '警告'
  cv_dev_status_err     CONSTANT VARCHAR2(30) := 'ERROR';             -- 'エラー'
--
  --プロファイル
  cv_org_id                   CONSTANT VARCHAR2(30) := 'ORG_ID';                          -- 組織ID
  cv_prof_name_wait_interval  CONSTANT VARCHAR2(35) := 'XXCFR1_GENERAL_RECEIPT_INTERVAL';
                                                                       -- XXCFR:ロックボックス要求完了チェック待機秒数
  cv_prof_name_wait_max       CONSTANT VARCHAR2(35) := 'XXCFR1_GENERAL_RECEIPT_MAX_WAIT';
                                                                       -- XXCFR:ロックボックス要求完了待機最大秒数
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';               -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';                  -- ログ出力
--
-- Modify 2009.12.12 Ver1.1 Start
  cv_2               CONSTANT VARCHAR2(30) := '2';                    -- データレコード
-- Modify 2009.12.12 Ver1.1 End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gn_org_id          NUMBER;                                               -- 組織ID
  gv_pg_name         VARCHAR2(100);                                        -- コンカレント名
  gv_wait_interval   fnd_profile_option_values.profile_option_value%TYPE;  -- コンカレント監視間隔
  gv_wait_max        fnd_profile_option_values.profile_option_value%TYPE;  -- コンカレント監視最大時間
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf              OUT     VARCHAR2,         --    エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         --    リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         --    ユーザー・エラー・メッセージ --# 固定 #
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
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- コンカレントパラメータ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- メッセージ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
    -- プロファイルから組織ID取得
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a03_004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                                       -- 組織ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:ロックボックス要求完了チェック待機秒数を取得
    gv_wait_interval := FND_PROFILE.VALUE(cv_prof_name_wait_interval);
    IF (gv_wait_interval IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a03_004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_interval))
                                                       -- XXCFR:ロックボックス要求完了チェック待機秒数
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:ロックボックス要求完了待機最大秒数を取得
    gv_wait_max := FND_PROFILE.VALUE(cv_prof_name_wait_max);
    IF (gv_wait_max IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a03_004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_max))
                                                       -- XXCFR:ロックボックス要求完了待機最大秒数
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure  Name   : get_submit_request
   * Description      : ロックボックス処理起動処理 (A-4)
   ***********************************************************************************/
  Procedure get_submit_request(
    iv_transmission_id                 VARCHAR2,            -- 伝送ID
    iv_transmission_name               VARCHAR2,            -- 伝送名
    iv_transmission_request_id         VARCHAR2,            -- 当初要求ID
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_submit_request'; -- プログラム名
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
    cv_conc_appli   CONSTANT VARCHAR2(2) := 'AR'; -- アプリケーション短縮名('AR')
    cv_conc_param_y CONSTANT VARCHAR2(1) := 'Y';  -- コンカレントパラメータ('Y')
    cv_conc_param_n CONSTANT VARCHAR2(1) := 'N';  -- コンカレントパラメータ('N')
    cv_conc_param_a CONSTANT VARCHAR2(1) := 'A';  -- コンカレントパラメータ('A')
    cv_conc_null    CONSTANT VARCHAR2(1) := NULL; -- コンカレントパラメータ(NULL)
    cv_zengin       CONSTANT VARCHAR2(3) := '102';-- 'ZENGIN'
--
    -- *** ローカル変数 ***
    ln_request_id   NUMBER;           -- コンカレント要求ID
    lb_wait_request BOOLEAN;          -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_phase        VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_status       VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_dev_phase    VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_dev_status   VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_message      VARCHAR2(5000);   -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
--
    -- *** ローカル・カーソル ***
--
-- Modify 2009.12.12 Ver1.1 Start
    CURSOR ar_payments_interface_cur(in_transmission_request_id IN NUMBER)
    IS
      SELECT apia.transmission_request_id transmission_request_id
      FROM ar_payments_interface_all apia                              -- ロックボックスIF
      WHERE apia.transmission_request_id = in_transmission_request_id  -- 当初要求ID
        AND apia.record_type = cv_2                                    -- データレコード
      GROUP BY apia.transmission_request_id
    ;
    ar_payments_interface_rec    ar_payments_interface_cur%ROWTYPE;
-- Modify 2009.12.12 Ver1.1 End
    -- ===============================
    -- ローカル例外
    -- ===============================
    submit_request_expt    EXCEPTION;  -- コンカレント発行エラー例外
    wait_for_request_expt  EXCEPTION;  -- コンカレント監視エラー例外
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
    -- コンカレント発行
    ln_request_id := 
    FND_REQUEST.SUBMIT_REQUEST( application => cv_conc_appli              -- アプリケーション短縮名
                               ,program     => cv_pg_name                 -- コンカレントプログラム名
                               ,argument1   => cv_conc_param_n            -- 新規伝送
                               ,argument2   => iv_transmission_id         -- 伝送ID
                               ,argument3   => iv_transmission_request_id -- 当初要求ID
                               ,argument4   => iv_transmission_name       -- 伝送名
                               ,argument5   => cv_conc_param_n            -- インポートの発行
                               ,argument6   => cv_conc_null               -- データ・ファイル
                               ,argument7   => cv_conc_null               -- 管理ファイル
                               ,argument8   => cv_zengin                  -- 伝送フォーマットID
                               ,argument9   => cv_conc_param_y            -- 検証の発行
                               ,argument10  => cv_conc_param_n            -- 無関連請求書支払
                               ,argument11  => cv_conc_null               -- ロックボックスID
                               ,argument12  => cv_conc_null               -- GL記帳日
                               ,argument13  => cv_conc_param_a            -- レポート・フォーマット
                               ,argument14  => cv_conc_param_n            -- 完了パッチのみ
                               ,argument15  => cv_conc_param_y            -- パッチ転記の発行
                               ,argument16  => cv_conc_param_n            -- カナ検索オプション
                               ,argument17  => cv_conc_null               -- 一部金額の転記または全入金の拒否
                               ,argument18  => cv_conc_null               -- USSGL取引コード
                               ,argument19  => gn_org_id                  -- 組織ID
                              );
    IF (ln_request_id = 0) THEN
      RAISE submit_request_expt;
    END IF;
--
    COMMIT;
    -- コンカレント要求監視
    lb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => ln_request_id    -- 要求ID
                                                       ,interval   => gv_wait_interval -- コンカレント監視間隔
                                                       ,max_wait   => gv_wait_max      -- コンカレント監視最大時間
                                                       ,phase      => lv_phase         -- 要求フェーズ
                                                       ,status     => lv_status        -- 要求ステータス
                                                       ,dev_phase  => lv_dev_phase     -- 要求フェーズコード
                                                       ,dev_status => lv_dev_status    -- 要求ステータスコード
                                                       ,message    => lv_message       -- 完了メッセージ
                                                      );
    IF (lb_wait_request) THEN
      IF (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_normal)
      THEN
        -- 正常終了の場合
        gn_normal_cnt := gn_normal_cnt + 1;
        -- 正常終了メッセージ出力
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               iv_application => cv_msg_kbn_cfr       -- 'XXCFR'
                              ,iv_name => cv_msg_005a03_067           -- 正常終了メッセージ
                              ,iv_token_name1 => cv_tkn_prog_name     -- トークン'PROGRAM_NAME'
                              ,iv_token_value1 => xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr
                                                                                     ,cv_dict_cd
                                                                                    ) -- プログラム名
                              ,iv_token_name2 => cv_tkn_request       -- トークン'REQUEST_ID'
                              ,iv_token_value2 => TO_CHAR(ln_request_id)
                              ,iv_token_name3 => cv_transmission_name       -- トークン'TRANSMISSION_NAME'
                              ,iv_token_value3 => iv_transmission_name
                              )
                             ,1
                             ,5000
                            );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSIF (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_warn)
      THEN
        -- 警告終了の場合
        gn_error_cnt := gn_error_cnt + 1;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr     -- 'XXCFR'
                              ,cv_msg_005a03_027  -- 警告終了メッセージ
                              ,cv_tkn_request     -- トークン'REQUEST_ID'
                              ,ln_request_id
                                 -- 要求ID
                              ,cv_tkn_file_name   -- トークン'FB_FILE_NAME'
                              ,iv_transmission_name
                                 -- 対象の伝送名
                              ,cv_tkn_dev_phase   -- トークン'DEV_PHASE'
                              ,lv_dev_phase
                                 -- DEV_PHASE
                              ,cv_tkn_dev_status  -- トークン'DEV_STATUS'
                              ,lv_dev_status
                            )    -- DEV_STATUS
                           ,1
                           ,5000
                          );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSE
        -- エラー終了の場合
        gn_error_cnt := gn_error_cnt + 1;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr     -- 'XXCFR'
                              ,cv_msg_005a03_028  -- エラー終了メッセージ
                              ,cv_tkn_request     -- トークン'REQUEST_ID'
                              ,ln_request_id
                                 -- 要求ID
                              ,cv_tkn_file_name   -- トークン'FB_FILE_NAME'
                              ,iv_transmission_name
                                 -- 対象の伝送名
                              ,cv_tkn_dev_phase   -- トークン'DEV_PHASE'
                              ,lv_dev_phase
                                 -- DEV_PHASE
                              ,cv_tkn_dev_status  -- トークン'DEV_STATUS'
                              ,lv_dev_status
                            )    -- DEV_STATUS
                           ,1
                           ,5000
                          );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      END IF;
    ELSE
      RAISE wait_for_request_expt;
    END IF;
--
-- Modify 2009.12.12 Ver1.1 Start
    OPEN ar_payments_interface_cur(iv_transmission_request_id);
    FETCH ar_payments_interface_cur INTO ar_payments_interface_rec;
    IF ar_payments_interface_cur%NOTFOUND THEN
    -- データレコードが存在しない場合は、ごみデータを全て削除する
      DELETE FROM ar_payments_interface
      WHERE transmission_request_id = iv_transmission_request_id;
    END IF;
-- Modify 2009.12.12 Ver1.1 End
  EXCEPTION
--
    -- *** 要求発行失敗時 ***
    WHEN submit_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_REQUEST.SUBMIT_REQUESTでスタックされたエラーメッセージを取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a03_012,   -- コンカレント発行エラーメッセージ
                                            iv_token_name1  => cv_tkn_prog_name,    -- トークン'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                  cv_msg_kbn_cfr
                                                                 ,cv_dict_cd
                                                               )                    -- プログラム名
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 要求監視失敗時 ***
    WHEN wait_for_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_REQUEST.WAIT_FOR_REQUESTでスタックされたエラーメッセージを取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a03_013,   -- コンカレント監視エラーメッセージ
                                            iv_token_name1  => cv_tkn_prog_name,    -- トークン'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                  cv_msg_kbn_cfr
                                                                 ,cv_dict_cd
                                                               )                    -- プログラム名
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END get_submit_request;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    on_target_cnt          OUT     NUMBER,           -- 対象件数
    on_normal_cnt          OUT     NUMBER,           -- 成功件数
    on_error_cnt           OUT     NUMBER,           -- エラー件数
    on_warn_cnt            OUT     NUMBER,           -- 警告件数
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- 抽出
    CURSOR ar_transmissions_cur
    IS
      SELECT tra.transmission_id         transmission_id         -- 伝送ID
            ,tra.transmission_name       transmission_name       -- 伝送名
            ,tra.transmission_request_id transmission_request_id -- 当初要求ID
      FROM ar_transmissions_all tra                              -- ロックボックスデータ伝送履歴テーブル
      WHERE EXISTS (SELECT 'X'
                    FROM ar_payments_interface_all pay           -- ロックボックスIF
                    WHERE pay.transmission_request_id = tra.transmission_request_id)  -- 当初要求ID
    ;
--
    ar_transmissions_rec ar_transmissions_cur%ROWTYPE;
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf                     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                    -- リターン・コード             --# 固定 #
      ,lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  対象ロックボックスデータ取得処理(A-3)
    -- =====================================================
--
    -- カーソルオープン
    OPEN ar_transmissions_cur;
--
    <<transmissions_loop>>
    LOOP
      -- リターン値初期化
      lv_retcode  := cv_status_normal;
--
    -- データの取得
      FETCH ar_transmissions_cur INTO ar_transmissions_rec;
      EXIT WHEN ar_transmissions_cur%NOTFOUND;
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
    -- =====================================================
    --  ロックボックス処理起動処理(A-4)
    -- =====================================================
--
      -- ロックボックス処理起動処理
      get_submit_request(
         ar_transmissions_rec.transmission_id           -- 伝送ID
        ,ar_transmissions_rec.transmission_name         -- 伝送名
        ,ar_transmissions_rec.transmission_request_id   -- 当初要求ID
        ,lv_errbuf                                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    END LOOP transmissions_loop;
--
    -- カーソルクローズ
    CLOSE ar_transmissions_cur;
--
    -- =====================================================
    --  終了処理 (A-5)
    -- =====================================================
    on_target_cnt  := gn_target_cnt;  -- 対象件数カウント
    on_normal_cnt  := gn_normal_cnt;  -- 成功件数カウント
    on_error_cnt   := gn_error_cnt;   -- エラー件数カウント
    on_warn_cnt    := gn_warn_cnt;    -- 警告件数カウント
--
    -- 警告フラグ判定
    IF (gn_error_cnt > 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka テンプレートを修正
      IF (ar_transmissions_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE ar_transmissions_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka テンプレートを修正
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka テンプレートを修正
      IF (ar_transmissions_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE ar_transmissions_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka テンプレートを修正
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka テンプレートを修正
      IF (ar_transmissions_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE ar_transmissions_cur;
      END IF;
-- Add End 2008/12/15 SCS R.Hamanaka テンプレートを修正
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
    errbuf                 OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                OUT     VARCHAR2)         --    エラーコード        --# 固定 #
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
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_error_msg_part  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了一部処理メッセージ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- メッセージコード
-- ↓↓↓ 個別処理を挿入 --
    lv_error_msg    VARCHAR2(100);   -- エラーメッセージ格納
-- ↑↑↑ 個別処理を挿入 --
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
       gn_target_cnt -- 対象件数
      ,gn_normal_cnt -- 成功件数
      ,gn_error_cnt  -- エラー件数
      ,gn_warn_cnt   -- 警告件数
      ,lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
-- ↓↓↓ 個別処理を挿入 --
      IF (NVL(gn_normal_cnt,0) = 0) THEN
        lv_error_msg := cv_error_msg;
-- ↑↑↑ 個別処理を挿入 --
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
        gn_warn_cnt   := 0;
-- ↓↓↓ 個別処理を挿入 --
      ELSE
        lv_error_msg := cv_error_msg_part;
        gn_error_cnt  := 1;
      END IF;
-- ↑↑↑ 個別処理を挿入 --

    END IF;
--
--###########################  固定部 START   #####################################################
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
-- ↓↓↓ 個別処理を挿入 --
--      lv_message_code := cv_error_msg;
      lv_message_code := lv_error_msg;
-- ↑↑↑ 個別処理を挿入 --
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
END XXCFR005A03C;
/
