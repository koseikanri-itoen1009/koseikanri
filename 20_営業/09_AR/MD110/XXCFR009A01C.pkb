CREATE OR REPLACE PACKAGE BODY XXCFR009A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR009A01C(body)
 * Description      : 営業員別払日別入金予定表
 * MD.050           : MD050_CFR_009_A01_営業員別払日別入金予定表
 * MD.070           : MD050_CFR_009_A01_営業員別払日別入金予定表
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  insert_work_table      p ワークテーブルデータ登録                (A-3)
-- Modify 2010.01.21 Ver1.7 Start
 *  set_receipt_class      p 入金区分設定処理                        (A-8)
-- Modify 2010.01.21 Ver1.7 End
 *  start_svf_api          p SVF起動                                 (A-4)
 *  delete_work_table      p ワークテーブルデータ削除                (A-5)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/18    1.00 SCS 中村 博      初回作成
 *  2009/02/19    1.1  SCS T.KANEDA     [障害COK_008] 税差額取得不具合対応
 *  2009/03/05    1.2  SCS M.OKAWA      共通関数リリースに伴うSVF起動処理変更対応
 *                                      中間テーブルデータ削除処理コメントアウト削除対応
 *  2009/04/14    1.3  SCS M.OKAWA      [障害T1_0533] 出力ファイル名変数文字列オーバーフロー対応
 *  2009/04/24    1.4  SCS S.KAYAHARA   [障害T1_0633] 組織プロファイル結合条件対応
 *  2009/07/15    1.5  SCS M.HIROSE     [障害0000481] パフォーマンス改善
 *  2009/09/29    1.6  SCS T.KANEDA     [共通課題IE542] 拠点並び順変更
 *  2010/01/21    1.7  SCS T.KANEDA     [本稼動_01145] 支払方法の取得先を顧客マスタに変更する
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
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  file_not_exists_expt  EXCEPTION;      -- ファイル存在エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR009A01C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- アプリケーション短縮名(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- アプリケーション短縮名(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- アプリケーション短縮名(XXCFR)
-- Modify 2009.07.15 Ver1.5 Start
  cv_msg_kbn_ar      CONSTANT VARCHAR2(5)   := 'AR';    -- アプリケーション短縮名(AR)
-- Modify 2009.07.15 Ver1.5 End
--
  -- メッセージ番号
  cv_msg_009a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; --エラー終了一部処理メッセージ
  cv_msg_009a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; --システムエラーメッセージ
--
  cv_msg_009a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_009a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --ロックエラーメッセージ
  cv_msg_009a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --データ削除エラーメッセージ
  cv_msg_009a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --テーブル挿入エラー
  cv_msg_009a01_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; --帳票０件メッセージ
  cv_msg_009a01_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; --APIエラーメッセージ
  cv_msg_009a01_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --帳票０件ログメッセージ
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API名
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- コメント
--
  -- 日本語辞書
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF起動
--
  --プロファイル
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
-- Modify 2009.02.19 Ver1.1 Start
  cv_prof_trx_source     CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_TAX_DIFF_TRX_SOURCE';          -- 税差額取引ソース
-- Modify 2009.02.19 Ver1.1 End
--
  -- 使用DB名
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_REP_SALES_REP_PAY_SCH';  -- ワークテーブル名
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)  := 'Y';         -- 有効フラグ（Ｙ）
--
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';          -- 日付フォーマット（年月日）
  cv_format_date_ymdhns CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';  -- 日付フォーマット（年月日時分秒）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id             NUMBER;             -- 組織ID
  gn_set_of_bks_id      NUMBER;             -- 会計帳簿ID
-- Modify 2009.02.19 Ver1.1 Start
  gt_taxd_trx_source     fnd_profile_option_values.profile_option_value%TYPE;  -- 税差額取引ソース
-- Modify 2009.02.19 Ver1.1 End
--
-- Modify 2010.01.21 Ver1.7 Start
    gv_no_data_msg  VARCHAR2(5000); -- 帳票０件メッセージ
-- Modify 2010.01.21 Ver1.7 End
--
--
  /**********************************************************************************
   * Function Name    : get_receipt_class_name
   * Description      : 入金区分名取得処理
   ***********************************************************************************/
  FUNCTION get_receipt_class_name(
    iv_receipt_class_id          IN  VARCHAR2 )       -- 入金区分ＩＤ
  RETURN VARCHAR2 IS -- 入金区分名
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_class_name'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt     NUMBER;         -- 対象件数
    ln_loop_cnt       NUMBER;         -- ループカウンタ
    lt_receipt_class_id    ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分ＩＤ
    lt_receipt_class_name  ar_receipt_methods.name%TYPE;              -- 入金区分名
--
    -- *** ローカル・カーソル ***
--
    -- テーブル名抽出
    CURSOR receipt_class_name_cur IS
    SELECT arc.name                 receipt_class_name  -- 入金区分名
    FROM ar_receipt_classes         arc                 -- 入金区分
    WHERE arc.receipt_class_id      = lt_receipt_class_id
    ;
--
    TYPE receipt_class_name_tbl IS TABLE OF receipt_class_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_receipt_class_name_data  receipt_class_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lt_receipt_class_id := TO_NUMBER( iv_receipt_class_id );
--
    -- カーソルオープン
    OPEN receipt_class_name_cur;
--
    -- データの一括取得
    FETCH receipt_class_name_cur BULK COLLECT INTO lt_receipt_class_name_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_receipt_class_name_data.COUNT;
--
    -- カーソルクローズ
    CLOSE receipt_class_name_cur;
--
    -- 対象データありの場合はテーブル名を戻り値に設定
    IF (ln_target_cnt > 0) THEN
      <<data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lt_receipt_class_name := lt_receipt_class_name_data(ln_loop_cnt).receipt_class_name;
      END LOOP data_loop;
      RETURN lt_receipt_class_name;
--
    -- 対象データなしの場合は、NULLを戻り値に設定
    ELSE
--
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_receipt_class_name;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_receive_base_code   IN      VARCHAR2,         --    入金拠点
    iv_sales_rep           IN      VARCHAR2,         --    営業担当者
    iv_due_date_from       IN      VARCHAR2,         --    支払期日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払期日(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    入金区分１
    iv_receipt_class2      IN      VARCHAR2,         --    入金区分２
    iv_receipt_class3      IN      VARCHAR2,         --    入金区分３
    iv_receipt_class4      IN      VARCHAR2,         --    入金区分４
    iv_receipt_class5      IN      VARCHAR2,         --    入金区分５
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
    lt_receipt_class_name1  ar_receipt_methods.name%TYPE := NULL;  -- 入金区分名１
    lt_receipt_class_name2  ar_receipt_methods.name%TYPE := NULL;  -- 入金区分名２
    lt_receipt_class_name3  ar_receipt_methods.name%TYPE := NULL;  -- 入金区分名３
    lt_receipt_class_name4  ar_receipt_methods.name%TYPE := NULL;  -- 入金区分名４
    lt_receipt_class_name5  ar_receipt_methods.name%TYPE := NULL;  -- 入金区分名５
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
    --入金区分変換
    --==============================================================
    IF (iv_receipt_class1 IS NOT NULL) THEN
      -- 入金区分名１取得
      lt_receipt_class_name1 := get_receipt_class_name(
                                  iv_receipt_class1
                                );
    END IF;
    IF (iv_receipt_class2 IS NOT NULL) THEN
      -- 入金区分名２取得
      lt_receipt_class_name2 := get_receipt_class_name(
                                  iv_receipt_class2
                                );
    END IF;
    IF (iv_receipt_class3 IS NOT NULL) THEN
      -- 入金区分名３取得
      lt_receipt_class_name3 := get_receipt_class_name(
                                  iv_receipt_class3
                                );
    END IF;
    IF (iv_receipt_class4 IS NOT NULL) THEN
      -- 入金区分名４取得
      lt_receipt_class_name4 := get_receipt_class_name(
                                  iv_receipt_class4
                                );
    END IF;
    IF (iv_receipt_class5 IS NOT NULL) THEN
      -- 入金区分名５取得
      lt_receipt_class_name5 := get_receipt_class_name(
                                  iv_receipt_class5
                                );
    END IF;
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log       -- ログ出力
      ,iv_conc_param1  => iv_receive_base_code   -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_sales_rep           -- コンカレントパラメータ２
      ,iv_conc_param3  => iv_due_date_from       -- コンカレントパラメータ３
      ,iv_conc_param4  => iv_due_date_to         -- コンカレントパラメータ４
      ,iv_conc_param5  => lt_receipt_class_name1 -- コンカレントパラメータ５
      ,iv_conc_param6  => lt_receipt_class_name2 -- コンカレントパラメータ６
      ,iv_conc_param7  => lt_receipt_class_name3 -- コンカレントパラメータ７
      ,iv_conc_param8  => lt_receipt_class_name4 -- コンカレントパラメータ８
      ,iv_conc_param9  => lt_receipt_class_name5 -- コンカレントパラメータ９
      ,ov_errbuf       => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
--
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
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
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
-- Modify 2009.02.18 Ver1.1 Start
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
-- Modify 2009.02.18 Ver1.1 End
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
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_009a01_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- 会計帳簿ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織ID取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_009a01_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- 組織ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.02.18 Ver1.1 Start
    --==============================================================
    --プロファイル取得処理
    --==============================================================
    --税差額取引ソース
    gt_taxd_trx_source := fnd_profile.value(cv_prof_trx_source);
    IF (gt_taxd_trx_source IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_009a01_010
                                                    ,iv_token_name1  => cv_tkn_prof
                                                    ,iv_token_value1 
                                                        => xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_source))
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.02.18 Ver1.1 End
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ワークテーブルデータ登録 (A-3)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_receive_base_code    IN         VARCHAR2,            -- 入金拠点
    iv_sales_rep            IN         VARCHAR2,            -- 営業担当者
    iv_due_date_from        IN         VARCHAR2,            -- 支払期日(FROM)
    iv_due_date_to          IN         VARCHAR2,            -- 支払期日(TO)
    iv_receipt_class1       IN         VARCHAR2,            -- 入金区分１
    iv_receipt_class2       IN         VARCHAR2,            -- 入金区分２
    iv_receipt_class3       IN         VARCHAR2,            -- 入金区分３
    iv_receipt_class4       IN         VARCHAR2,            -- 入金区分４
    iv_receipt_class5       IN         VARCHAR2,            -- 入金区分５
    ov_errbuf               OUT        VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT        VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT        VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- プログラム名
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
    cv_rounding_rule_n  CONSTANT VARCHAR2(10) := 'NEAREST';  -- 四捨五入
    cv_rounding_rule_u  CONSTANT VARCHAR2(10) := 'UP';       -- 切上げ
    cv_rounding_rule_d  CONSTANT VARCHAR2(10) := 'DOWN';     -- 切捨て
    cv_bill_to          CONSTANT VARCHAR2(10) := 'BILL_TO';  -- 使用目的：請求先
    cv_status_op        CONSTANT VARCHAR2(10) := 'OP';       -- ステータス：オープン
    cv_status_enabled   CONSTANT VARCHAR2(10) := 'A';        -- ステータス：有効
    cv_relate_class     CONSTANT VARCHAR2(10) := '2';        -- 関連分類：入金
    cv_lookup_tax_type  CONSTANT VARCHAR2(30) := 'XXCMM_CSUT_SYOHIZEI_KBN';   -- 消費税区分
    cv_sales_rep_attr   CONSTANT VARCHAR2(30) := 'RESOURCE' ;   -- 担当営業員属性
--
    -- *** ローカル変数 ***
    ln_target_cnt   NUMBER := 0;    -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    lv_no_data_msg  VARCHAR2(5000); -- 帳票０件メッセージ
--
-- Modify 2010.01.21 Ver1.7 Start
--    lt_receipt_class_id1  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分１
--    lt_receipt_class_id2  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分２
--    lt_receipt_class_id3  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分３
--    lt_receipt_class_id4  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分４
--    lt_receipt_class_id5  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分５
-- Modify 2010.01.21 Ver1.7 End
--
    -- *** ローカル・カーソル ***
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
    -- ====================================================
    -- 帳票０件メッセージ取得
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                       ,cv_msg_009a01_014 -- 帳票０件メッセージ
                                                      )
                                                    ,1
                                                    ,5000);
-- Modify 2010.01.21 Ver1.7 Start
    -- 他のプロシージャで使用するので、グローバル変数に格納
    gv_no_data_msg := lv_no_data_msg;
-- Modify 2010.01.21 Ver1.7 End
--
-- Modify 2010.01.21 Ver1.7 Start
--    lt_receipt_class_id1 := TO_NUMBER( iv_receipt_class1 );
--    lt_receipt_class_id2 := TO_NUMBER( iv_receipt_class2 );
--    lt_receipt_class_id3 := TO_NUMBER( iv_receipt_class3 );
--    lt_receipt_class_id4 := TO_NUMBER( iv_receipt_class4 );
--    lt_receipt_class_id5 := TO_NUMBER( iv_receipt_class5 );
-- Modify 2010.01.21 Ver1.7 End
--
    -- ====================================================
    -- ワークテーブルへの登録
    -- ====================================================
    BEGIN
--
      INSERT INTO xxcfr_rep_sales_rep_pay_sch ( 
         report_id
        ,output_date
        ,receipt_area_code
        ,receipt_dept_code
        ,receipt_dept_name
        ,receipt_sales_rep_code
        ,receipt_sales_rep_name
        ,due_date
        ,receipt_customer_code
        ,receipt_customer_name
        ,receipt_class_id
        ,receipt_class_name
        ,tax_class_code
        ,tax_class_name
        ,amount_due_original
        ,amount_due_remaining
        ,amount_due_remaining_ex_tax
        ,tax_original
        ,tax_remaining
        ,data_empty_message
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
      SELECT
-- Modify 2009.07.15 Ver1.5 Start
             /*+ INDEX(hp    HZ_PARTIES_U1 )
                 INDEX(hop   HZ_ORGANIZATION_PROFILES_N1)
                 INDEX(hopeb HZ_ORG_PROFILES_EXT_B_N1)
-- Modify 2010.01.21 Ver1.7 Start
--                 INDEX(xca   XXCMM_CUST_ACCOUNTS_PK)
-- Modify 2010.01.21 Ver1.7 End
             */
-- Modify 2009.07.15 Ver1.5 End
        cv_pkg_name                                 report_id,            -- 帳票ＩＤ
        TO_CHAR( cd_creation_date, cv_format_date_ymdhns ) output_date,   -- 出力日
-- Modify 2009.09.29 Ver1.6 Start
--        xdev.attribute9                             receipt_area_code,    -- 入金拠点エリアコード（本部コード）
        CASE 
          WHEN TO_DATE(xdev.attribute6,'yyyymmdd') > TRUNC ( SYSDATE ) THEN xdev.attribute7
          ELSE xdev.attribute9
        END                                           receipt_area_code,    -- 入金拠点エリアコード（本部コード）
-- Modify 2009.09.29 Ver1.6 End
-- Modify 2010.01.21 Ver1.7 Start
--        NVL( xca.receiv_base_code, xca.sale_base_code ) receipt_dept_code, -- 入金拠点コード
        ca.receiv_base_code                         receipt_dept_code, -- 入金拠点コード
-- Modify 2010.01.21 Ver1.7 End
        xdev.description                            receipt_dept_name,    -- 入金拠点名
        hopeb.c_ext_attr1                           sales_rep_code,       -- 営業担当者コード
        papf.per_information18 || papf.per_information19 sales_rep_name,  -- 従業員氏名
        pay_sch.due_date                            due_date,             -- 支払期日
        ca.cr_account_number                        cr_account_number,    -- 入金先顧客コード
        hp.party_name                               party_name,           -- 入金先顧客名
-- Modify 2010.01.21 Ver1.7 Start
--        pay_sch.receipt_class_id                    receipt_class_id,     -- 入金区分ID
--        pay_sch.receipt_class_name                  receipt_class_name,   -- 入金区分名
--        xca.tax_div                                 tax_div,              -- 消費税区分
        NULL                                        receipt_class_id,     -- 入金区分ID
        NULL                                        receipt_class_name,   -- 入金区分名
        ca.tax_div                                  tax_div,              -- 消費税区分
-- Modify 2010.01.21 Ver1.7 End
        flv.meaning                                 tax_div_name,         -- 消費税区分名
        NVL( SUM( pay_sch.amount_due_original ),0 ) amount_due_original,  -- 当初残高（税込）
        NVL( SUM( pay_sch.amount_due_remaining ),0 ) amount_due_remaining, -- 未回収残高（税込）
        NVL( SUM( pay_sch.amount_due_remaining ),0 )
-- Modify 2010.01.21 Ver1.7 Start
--         -  NVL( SUM( DECODE( pay_sch.tax_rounding_rule,
         -  NVL( SUM( DECODE( hcsua.tax_rounding_rule,
-- Modify 2010.01.21 Ver1.7 End
                              cv_rounding_rule_n, ROUND( pay_sch.tax_due_remaining ),
                              cv_rounding_rule_u, CEIL ( pay_sch.tax_due_remaining ),
                              cv_rounding_rule_d, FLOOR( pay_sch.tax_due_remaining ),
                              ROUND( pay_sch.tax_due_remaining )
                            )
                     ) 
               ,0 )                                 amount_due_remaining_ex_tax,
                                                                          -- 未回収残高（税抜）
        NVL( SUM( pay_sch.tax_original ), 0 )       tax_original,         -- 当初税額
-- Modify 2010.01.21 Ver1.7 Start
--        NVL( SUM( DECODE( pay_sch.tax_rounding_rule,
        NVL( SUM( DECODE( hcsua.tax_rounding_rule,
-- Modify 2010.01.21 Ver1.7 End
                          cv_rounding_rule_n, ROUND( pay_sch.tax_due_remaining ),
                          cv_rounding_rule_u, CEIL ( pay_sch.tax_due_remaining ),
                          cv_rounding_rule_d, FLOOR( pay_sch.tax_due_remaining ),
                          ROUND( pay_sch.tax_due_remaining )
                        )
                )
           ,0 )                                     tax_due_remaining,    -- 未回収税額
        NULL                                        data_empty_message,   -- 0件メッセージ
        cn_created_by                               created_by,           -- 作成者
        cd_creation_date                            creation_date,        -- 作成日
        cn_last_updated_by                          last_updated_by,      -- 最終更新者
        cd_last_update_date                         last_update_date,     -- 最終更新日
        cn_last_update_login                        last_update_login,    -- 最終更新ログイン
        cn_request_id                               request_id,           -- 要求ID
        cn_program_application_id                   program_application_id, -- コンカレント・プログラム・アプリケーションID
        cn_program_id                               program_id,           -- コンカレント・プログラムID
        cd_program_update_date                      program_update_date   -- プログラム更新日
      FROM
        ( 
        SELECT 
-- Modify 2009.07.15 Ver1.5 Start
               /*+ INDEX(apsa  XXCFR_AR_PAYMENT_SCHEDULES_N01)
               */
-- Modify 2009.07.15 Ver1.5 End
               rcta.bill_to_customer_id           bill_to_customer_id,    -- 請求先顧客ID
-- Modify 2010.01.21 Ver1.7 Start
--               arm.name                           receipt_method_name,    -- 入金方法（支払方法）
--               arm.receipt_class_id               receipt_class_id,       -- 入金区分ID
--               arc.name                           receipt_class_name,     -- 入金区分
-- Modify 2010.01.21 Ver1.7 End
               apsa.due_date                      due_date,               -- 支払期日
               SUM ( apsa.amount_due_remaining )  amount_due_remaining,   -- 未回収残高（税込）
               SUM ( apsa.amount_due_original )   amount_due_original,    -- 当初残高（税込）
-- Modify 2009.02.18 Ver1.1 Start
--               SUM ( apsa.tax_original )          tax_original,           -- 当初税額
--               SUM ( DECODE ( apsa.amount_due_remaining, 
--                              apsa.amount_due_original, apsa.tax_original,
--                              apsa.amount_due_remaining / apsa.amount_due_original * apsa.tax_original ) )
--                                                  tax_due_remaining,      -- 未回収税額
--
               SUM ( DECODE ( rbsa.name,
                              gt_taxd_trx_source,apsa.amount_due_original,
                              apsa.tax_original ) )          tax_original,           -- 当初税額
               SUM ( DECODE ( apsa.amount_due_remaining, 
                              apsa.amount_due_original, DECODE ( rbsa.name,
                                                                 gt_taxd_trx_source,apsa.amount_due_original,
                                                                 apsa.tax_original ),
                              apsa.amount_due_remaining / apsa.amount_due_original
                                                              * DECODE ( rbsa.name,
                                                                         gt_taxd_trx_source,apsa.amount_due_original,
                                                                         apsa.tax_original ) ) )
--                              apsa.amount_due_remaining / apsa.amount_due_original * apsa.tax_original ) )
-- Modify 2010.01.21 Ver1.7 Start
--                                                  tax_due_remaining,      -- 未回収税額
---- Modify 2009.02.18 Ver1.1 End
--               hcsua.tax_rounding_rule            tax_rounding_rule       -- 税金－端数処理
                                                  tax_due_remaining      -- 未回収税額
-- Modify 2010.01.21 Ver1.7 End
-- Modify 2009.07.15 Ver1.5 Start
--        FROM ra_customer_trx_all        rcta,     -- 取引ヘッダ
--             ar_payment_schedules_all   apsa,     -- 支払計画
        FROM ra_customer_trx            rcta,     -- 取引ヘッダ
             ar_payment_schedules       apsa,     -- 支払計画
-- Modify 2009.07.15 Ver1.5 End
-- Modify 2010.01.21 Ver1.7 Start
--             ar_receipt_methods         arm,      -- 入金方法（支払方法）
--             ar_receipt_classes         arc,      -- 入金区分
--             hz_cust_accounts           hca,      -- 顧客マスタ（請求先）
-- Modify 2010.01.21 Ver1.7 End
-- Modify 2009.07.15 Ver1.5 Start
--             hz_cust_acct_sites_all     hcasa,    -- 顧客所在地マスタ
--             hz_cust_site_uses_all      hcsua     -- 顧客使用目的マスタ
---- Modify 2009.02.18 Ver1.1 Start
--            ,ra_batch_sources_all       rbsa
---- Modify 2009.02.18 Ver1.1 End
-- Modify 2010.01.21 Ver1.7 Start
--             hz_cust_acct_sites         hcasa,    -- 顧客所在地マスタ
--             hz_cust_site_uses          hcsua,    -- 顧客使用目的マスタ
-- Modify 2010.01.21 Ver1.7 End
             ra_batch_sources           rbsa
-- Modify 2009.07.15 Ver1.5 End
        WHERE rcta.customer_trx_id      = apsa.customer_trx_id
-- Modify 2010.01.21 Ver1.7 Start
--          AND rcta.receipt_method_id    = arm.receipt_method_id
--          AND arm.receipt_class_id      = arc.receipt_class_id
--          AND rcta.bill_to_customer_id  = hca.cust_account_id
--          AND hca.cust_account_id       = hcasa.cust_account_id(+)
--          AND hcasa.cust_acct_site_id   = hcsua.cust_acct_site_id(+)
--          AND hcsua.site_use_code       = cv_bill_to   -- 使用目的：請求先
-- Modify 2010.01.21 Ver1.7 End
          AND rcta.set_of_books_id      = gn_set_of_bks_id
-- Modify 2009.07.15 Ver1.5 Start
--          AND rcta.org_id               = gn_org_id
-- Modify 2009.07.15 Ver1.5 End
          AND apsa.status               = cv_status_op -- ステータス：オープン
-- Modify 2010.01.21 Ver1.7 Start
--          AND (
--                ( lt_receipt_class_id1 IS NULL 
--                  AND lt_receipt_class_id2 IS NULL
--                  AND lt_receipt_class_id3 IS NULL
--                  AND lt_receipt_class_id4 IS NULL
--                  AND lt_receipt_class_id5 IS NULL
--                )
--                OR arm.receipt_class_id IN ( 
--                    lt_receipt_class_id1,
--                    lt_receipt_class_id2,
--                    lt_receipt_class_id3,
--                    lt_receipt_class_id4,
--                    lt_receipt_class_id5
--                )
--              )
-- Modify 2010.01.21 Ver1.7 End
          AND ( apsa.due_date >= xxcfr_common_pkg.get_date_param_trans ( iv_due_date_from )
                OR iv_due_date_from IS NULL )
          AND ( apsa.due_date <= xxcfr_common_pkg.get_date_param_trans ( iv_due_date_to )
                OR iv_due_date_to IS NULL )
-- Modify 2009.02.18 Ver1.1 Start
          AND rcta.batch_source_id      = rbsa.batch_source_id
          AND rcta.org_id               = rbsa.org_id
-- Modify 2009.02.18 Ver1.1 End
        GROUP BY 
          rcta.bill_to_customer_id,   -- 請求先顧客ID
-- Modify 2010.01.21 Ver1.7 Start
--          arm.name,                   -- 入金方法（支払方法）
--          arm.receipt_class_id,       -- 入金区分ID
--          arc.name,                   -- 入金区分
--          apsa.due_date,              -- 支払期日
--          hcsua.tax_rounding_rule     -- 税金－端数処理
          apsa.due_date              -- 支払期日
-- Modify 2010.01.21 Ver1.7 End
        )                         pay_sch,        -- 顧客別未回収残高ビュー
        (
          SELECT
-- Modify 2010.01.21 Ver1.7 Start
                 /*+ USE_CONCAT
                     LEADING( xca hca_c hcara hca )
                     USE_NL ( xca hca_c hcara hca )
                 */
-- Modify 2010.01.21 Ver1.7 End
            hca.cust_account_id                     bill_cust_account_id,   -- 請求先顧客ＩＤ
            hca_c.cust_account_id                   cr_cust_account_id,     -- 入金先の顧客ＩＤ
            hca.account_number                      bill_to_account_number, -- 請求先顧客コード（請求先顧客コード）
            hca_c.account_number                    cr_account_number,      -- 入金先顧客コード
-- Modify 2010.01.21 Ver1.7 Start
            xca.tax_div                             tax_div,                -- 税区分
            NVL( xca.receiv_base_code
               , xca.sale_base_code
            )                                       receiv_base_code,       -- NVL(入金拠点,売上拠点)
-- Modify 2010.01.21 Ver1.7 End
            hca_c.party_id                          cr_party_id             -- 入金先顧客パーティＩＤ
          FROM hz_cust_accounts           hca_c,    -- 顧客マスタ（入金）
               hz_cust_accounts           hca,      -- 顧客マスタ（請求先）
-- Modify 2010.01.21 Ver1.7 Start
               xxcmm_cust_accounts        xca,      -- 顧客追加情報(入金)
-- Modify 2010.01.21 Ver1.7 End
-- Modify 2009.07.15 Ver1.5 Start
--               hz_cust_acct_relate_all    hcara     -- 顧客関連
               hz_cust_acct_relate        hcara     -- 顧客関連
-- Modify 2009.07.15 Ver1.5 End
          WHERE hca_c.cust_account_id     = hcara.cust_account_id
            AND hcara.related_cust_account_id = hca.cust_account_id
            AND hcara.status              = cv_status_enabled -- ステータス：有効
            AND hcara.attribute1          = cv_relate_class   -- 関連分類：入金
-- Modify 2010.01.21 Ver1.7 Start
            AND hca_c.cust_account_id     = xca.customer_id   -- 顧客内部ID
            AND ( ( iv_receive_base_code IS NULL                  )  -- パラメータがNULLか
               OR ( xca.receiv_base_code  = iv_receive_base_code  )  -- 入金拠点がパラメータに等しいか
               OR ( ( xca.receiv_base_code IS NULL                 ) -- 入金拠点が入力なら売上拠点に等しいか
                AND ( xca.sale_base_code    = iv_receive_base_code )
                  )
                )
-- Modify 2010.01.21 Ver1.7 End
-- Modify 2009.07.15 Ver1.5 Start
--          UNION
          UNION ALL
-- Modify 2009.07.15 Ver1.5 End
          SELECT
-- Modify 2010.01.21 Ver1.7 Start
                 /*+ USE_CONCAT
                     LEADING( xca hca )
                     USE_NL( xca hca )
                 */
-- Modify 2010.01.21 Ver1.7 End
            hca.cust_account_id                     bill_cust_account_id,   -- 請求先顧客ＩＤ
            hca.cust_account_id                     cr_cust_account_id,     -- 入金先顧客ＩＤ
            hca.account_number                      bill_to_account_number, -- 請求先顧客コード（請求先顧客コード）
            hca.account_number                      cr_account_number,      -- 入金先顧客コード
-- Modify 2010.01.21 Ver1.7 Start
            xca.tax_div                             tax_div,                -- 税区分
            NVL( xca.receiv_base_code
               , xca.sale_base_code
            )                                       receiv_base_code,       -- NVL(入金拠点,売上拠点)
-- Modify 2010.01.21 Ver1.7 End
            hca.party_id                            cr_party_id             -- 入金先顧客パーティＩＤ
-- Modify 2010.01.21 Ver1.7 Start
--          FROM hz_cust_accounts           hca      -- 顧客マスタ（入金関連なし）
          FROM hz_cust_accounts           hca,      -- 顧客マスタ（入金関連なし）
               xxcmm_cust_accounts        xca       -- 顧客追加情報（入金関連なし）
-- Modify 2010.01.21 Ver1.7 End
          WHERE NOT EXISTS (
                  SELECT 'X'
                    FROM hz_cust_acct_relate_all   cash_hcar_1       --顧客関連マスタ(入金関連)
                   WHERE cash_hcar_1.status     = cv_status_enabled  --顧客関連マスタ(入金関連).ステータス = ‘A’
                     AND cash_hcar_1.attribute1 = cv_relate_class    --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
                     AND cash_hcar_1.related_cust_account_id = hca.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
                )
-- Modify 2010.01.21 Ver1.7 Start
            AND hca.cust_account_id       = xca.customer_id   -- 顧客内部ID
            AND ( ( iv_receive_base_code IS NULL                  )  -- パラメータがNULLか
               OR ( xca.receiv_base_code  = iv_receive_base_code  )  -- 入金拠点がパラメータに等しいか
               OR ( ( xca.receiv_base_code IS NULL                 ) -- 入金拠点が入力なら売上拠点に等しいか
                AND ( xca.sale_base_code    = iv_receive_base_code )
                  )
                )
-- Modify 2010.01.21 Ver1.7 End
        )                         ca,             -- 顧客入金関連取得ビュー
        hz_parties                hp,             -- パーティ
        hz_organization_profiles  hop,            -- 組織プロファイル
        hz_org_profiles_ext_b     hopeb,          -- 組織プロファイル拡張
        ego_attr_groups_v         eagv,           -- 組織プロファイル拡張属性グループ
        per_all_people_f          papf,           -- 従業員マスタ
-- Modify 2010.01.21 Ver1.7 Start
--        xxcmm_cust_accounts       xca,            -- 顧客追加情報テーブル
        hz_cust_acct_sites        hcasa,    -- 顧客所在地マスタ
        hz_cust_site_uses         hcsua,    -- 顧客使用目的マスタ
-- Modify 2010.01.21 Ver1.7 End
        xx03_departments_ext_v    xdev,           -- 部門マスタビュー
        fnd_lookup_values         flv             -- 参照表（消費税区分）
-- Modify 2009.07.15 Ver1.5 Start
       ,fnd_application           fapp            -- アプリケーション
-- Modify 2009.07.15 Ver1.5 End
      WHERE pay_sch.bill_to_customer_id = ca.bill_cust_account_id
-- Modify 2010.01.21 Ver1.7 Start
        AND ca.bill_cust_account_id     = hcasa.cust_account_id   -- 顧客内部ID
        AND hcasa.cust_acct_site_id     = hcsua.cust_acct_site_id -- 顧客所在地内部ID
        AND hcsua.site_use_code         = cv_bill_to              -- 使用目的：請求先
        AND hcsua.status                = cv_status_enabled       -- 有効('A')
-- Modify 2010.01.21 Ver1.7 End
        AND ca.cr_party_id              = hp.party_id
        AND hp.party_id                 = hop.party_id(+)
-- Modify 2009.04.24 Ver1.4 Start
        AND hop.effective_end_date(+) is NULL
-- Modify 2009.04.24 Ver1.4 End
        AND hop.organization_profile_id = hopeb.organization_profile_id(+)
        AND hopeb.attr_group_id         = eagv.attr_group_id(+)
        AND eagv.attr_group_name        = cv_sales_rep_attr    -- 担当営業員属性
-- Modify 2009.07.15 Ver1.5 Start
        AND eagv.application_id         = fapp.application_id  -- アプリケーションID
        AND fapp.application_short_name = cv_msg_kbn_ar        -- アプリケーション短縮名(AR)
-- Modify 2009.07.15 Ver1.5 Start
        AND hopeb.c_ext_attr1           = papf.employee_number
        AND ( hopeb.d_ext_attr1 <= TRUNC ( SYSDATE )
           OR hopeb.d_ext_attr1 IS NULL )
        AND ( hopeb.d_ext_attr2 >= TRUNC ( SYSDATE )
           OR hopeb.d_ext_attr2 IS NULL )
        AND papf.effective_start_date   <= TRUNC ( SYSDATE )
        AND papf.effective_end_date     >= TRUNC ( SYSDATE )
-- Modify 2010.01.21 Ver1.7 Start
--        AND ca.cr_cust_account_id       = xca.customer_id
--        AND NVL( xca.receiv_base_code, xca.sale_base_code )
--                                        = xdev.flex_value
        AND ca.receiv_base_code         = xdev.flex_value
-- Modify 2010.01.21 Ver1.7 End
        AND xdev.enabled_flag           = cv_enabled_yes
-- Modify 2009.07.15 Ver1.5 Start
        AND xdev.set_of_books_id        = gn_set_of_bks_id
-- Modify 2009.07.15 Ver1.5 End
-- Modify 2010.01.21 Ver1.7 Start
--        AND NVL( xca.receiv_base_code, xca.sale_base_code )
--                                        = NVL ( iv_receive_base_code, 
--                                                NVL( xca.receiv_base_code, xca.sale_base_code ) )
-- Modify 2010.01.21 Ver1.7 End
        AND hopeb.c_ext_attr1           = NVL ( iv_sales_rep, hopeb.c_ext_attr1 )
-- Modify 2010.01.21 Ver1.7 Start
--        AND xca.tax_div                 = flv.lookup_code
        AND ca.tax_div                  = flv.lookup_code
-- Modify 2010.01.21 Ver1.7 End
        AND flv.lookup_type             = cv_lookup_tax_type
        AND flv.language                = USERENV( 'LANG' )
        AND flv.enabled_flag            = cv_enabled_yes
        AND ( flv.start_date_active     IS NULL
           OR flv.start_date_active     <= TRUNC ( SYSDATE ) )
        AND ( flv.end_date_active       IS NULL
           OR flv.end_date_active       >= TRUNC ( SYSDATE ) )
      GROUP BY
-- Modify 2009.09.29 Ver1.6 Start
--        xdev.attribute9,                    -- 入金拠点エリアコード（本部コード）
        CASE 
          WHEN TO_DATE(xdev.attribute6,'yyyymmdd') > TRUNC ( SYSDATE ) THEN xdev.attribute7
          ELSE xdev.attribute9
        END,                                  -- 入金拠点エリアコード（本部コード）
-- Modify 2009.09.29 Ver1.6 End
-- Modify 2010.01.21 Ver1.7 Start
--        NVL( xca.receiv_base_code, xca.sale_base_code ), -- 入金拠点コード
        ca.receiv_base_code,                -- 入金拠点コード
-- Modify 2010.01.21 Ver1.7 End
        xdev.description,                   -- 入金拠点名
        hopeb.c_ext_attr1,                  -- 営業担当者コード
        papf.per_information18,             -- 従業員姓
        papf.per_information19,             -- 従業員名
        pay_sch.due_date,                   -- 支払期日
        ca.cr_account_number,               -- 入金先顧客コード
        hp.party_name,                      -- 入金先顧客名
-- Modify 2010.01.21 Ver1.7 Start
--        pay_sch.receipt_class_id,           -- 入金区分ID
--        pay_sch.receipt_class_name,         -- 入金区分名
-- Modify 2010.01.21 Ver1.7 End
-- Modify 2010.01.21 Ver1.7 Start
--        xca.tax_div,                        -- 消費税区分
        ca.tax_div,                         -- 消費税区分
-- Modify 2010.01.21 Ver1.7 End
        flv.meaning                         -- 消費税区分名
      ;
--
      gn_target_cnt := SQL%ROWCOUNT;
--
-- Modify 2010.01.21 Ver1.7 Start  後続処理で実現する。
--      -- 登録データが１件も存在しない場合、０件メッセージレコード追加
--      IF ( gn_target_cnt = 0 ) THEN
----
--        INSERT INTO xxcfr_rep_sales_rep_pay_sch ( 
--           report_id
--          ,output_date
--          ,receipt_dept_code
--          ,receipt_sales_rep_code
--          ,data_empty_message
--          ,created_by
--          ,creation_date
--          ,last_updated_by
--          ,last_update_date
--          ,last_update_login 
--          ,request_id
--          ,program_application_id
--          ,program_id
--          ,program_update_date
--        )
--        VALUES ( 
--          cv_pkg_name                                        , -- 帳票ＩＤ
--          TO_CHAR( cd_creation_date, cv_format_date_ymdhns ) , -- 出力日
--          iv_receive_base_code                               , -- 入金拠点コード
--          iv_sales_rep                                       , -- 営業担当者
--          lv_no_data_msg                                     , -- 0件メッセージ
--          cn_created_by                                      , -- 作成者
--          cd_creation_date                                   , -- 作成日
--          cn_last_updated_by                                 , -- 最終更新者
--          cd_last_update_date                                , -- 最終更新日
--          cn_last_update_login                               , -- 最終更新ログイン
--          cn_request_id                                      , -- 要求ID
--          cn_program_application_id                          , -- コンカレント・プログラム・アプリケーションID
--          cn_program_id                                      , -- コンカレント・プログラムID
--          cd_program_update_date                               -- プログラム更新日
--        );
----
--        -- 警告終了
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
--                                                       ,cv_msg_009a01_016    -- 対象データ0件警告
--                                                      )
--                                                      ,1
--                                                      ,5000);
--        ov_errmsg  := lv_errmsg;
--        ov_retcode := cv_status_warn;
----
--      END IF;
-- Modify 2010.01.21 Ver1.7 End
--
    EXCEPTION
      WHEN OTHERS THEN  -- 登録時エラー
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_009a01_013    -- テーブル登録エラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- 営業員別払日別入金予定表帳票ワークテーブル
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    -- 成功件数の設定
    gn_normal_cnt := gn_target_cnt;
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
  END insert_work_table;
--
-- Modify 2010.01.21 Ver1.7 Start
  /**********************************************************************************
   * Procedure Name   : 入金区分設定処理
   * Description      : 初期処理(A-8)
   ***********************************************************************************/
  PROCEDURE set_receipt_class(
    iv_receive_base_code IN VARCHAR2,  -- 入金拠点
    iv_sales_rep         IN VARCHAR2,  -- 営業担当者
    iv_receipt_class1    IN VARCHAR2,  -- 入金区分１
    iv_receipt_class2    IN VARCHAR2,  -- 入金区分２
    iv_receipt_class3    IN VARCHAR2,  -- 入金区分３
    iv_receipt_class4    IN VARCHAR2,  -- 入金区分４
    iv_receipt_class5    IN VARCHAR2,  -- 入金区分５
    ov_errbuf           OUT VARCHAR2,  --    エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,  --    リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)  --    ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_receipt_class'; -- プログラム名
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
    ln_count              PLS_INTEGER;  -- カウンタ
    ln_count_inner        PLS_INTEGER;  -- カウンタ
    ln_first              PLS_INTEGER;  -- 初めの要素
    ld_sysdate            DATE;         -- システム日付
--
    lt_receipt_class_id1  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分１
    lt_receipt_class_id2  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分２
    lt_receipt_class_id3  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分３
    lt_receipt_class_id4  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分４
    lt_receipt_class_id5  ar_receipt_methods.receipt_class_id%TYPE;  -- 入金区分５
--
    -- *** ローカル・カーソル ***
    -- ワークテーブルより入金先顧客を取得
    CURSOR get_rep_sales_rep_cur
    IS
      SELECT xrsr.receipt_customer_code AS receipt_customer_code  -- 入金先顧客番号
      FROM   xxcfr_rep_sales_rep_pay_sch  xrsr  -- 帳票用ワークテーブル
      WHERE  xrsr.request_id = cn_request_id  -- 要求ID
      GROUP BY xrsr.receipt_customer_code  -- 入金先顧客番号
      ;
--
    -- 顧客に紐付く支払方法を取得
    CURSOR get_receipt_method_cur(
             iv_receipt_customer_code IN hz_cust_accounts.account_number%TYPE  -- 入金先顧客番号
            ,id_sysdate               IN DATE                                  -- システム日付
           )
    IS
      SELECT /*+ USE_CONCAT
                 LEADING( hzca rcrm arm arc )
                 USE_NL( hzca rcrm arm arc )
             */
             arc.receipt_class_id    AS receipt_class_id    -- 入金区分ID
            ,arc.name                AS receipt_class_name  -- 入金区分名
        FROM hz_cust_accounts        hzca  -- 顧客マスタ
            ,ra_cust_receipt_methods rcrm  -- 顧客支払方法
            ,ar_receipt_methods      arm   -- 入金方法（支払方法）
            ,ar_receipt_classes      arc   -- 入金区分
       WHERE hzca.cust_account_id   = rcrm.customer_id          -- 顧客内部ID
         AND rcrm.receipt_method_id = arm.receipt_method_id     -- 支払方法ID
         AND arm.receipt_class_id   = arc.receipt_class_id      -- 入金区分ID
         AND hzca.account_number    = iv_receipt_customer_code  -- 入金先顧客番号
         AND rcrm.primary_flag      = cv_enabled_yes            -- 有効('Y')
         AND id_sysdate BETWEEN rcrm.start_date                 -- 開始日
                            AND NVL(rcrm.end_date,id_sysdate)   -- 終了日
         AND (
                -- パラメータ(入金区分)が設定されていないとき
                (     lt_receipt_class_id1 IS NULL  -- 入金区分ID1(パラメータ)
                  AND lt_receipt_class_id2 IS NULL  -- 入金区分ID2(パラメータ)
                  AND lt_receipt_class_id3 IS NULL  -- 入金区分ID3(パラメータ)
                  AND lt_receipt_class_id4 IS NULL  -- 入金区分ID4(パラメータ)
                  AND lt_receipt_class_id5 IS NULL  -- 入金区分ID5(パラメータ)
                )
                -- パラメータ(入金区分)が何らか設定されているとき
             OR ( arm.receipt_class_id IN ( 
                      lt_receipt_class_id1          -- 入金区分ID1(パラメータ)
                     ,lt_receipt_class_id2          -- 入金区分ID2(パラメータ)
                     ,lt_receipt_class_id3          -- 入金区分ID3(パラメータ)
                     ,lt_receipt_class_id4          -- 入金区分ID4(パラメータ)
                     ,lt_receipt_class_id5          -- 入金区分ID5(パラメータ)
                  )
                )
             )
      ORDER BY rcrm.primary_flag      DESC  -- 主フラグ
              ,rcrm.end_date          DESC  -- 終了日
              ,rcrm.start_date        DESC  -- 開始日
      ;
--
    -- *** ローカル・レコード ***
--
    TYPE get_rep_sales_rep_ttype  IS TABLE OF get_rep_sales_rep_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    TYPE get_receipt_method_ttype IS TABLE OF get_receipt_method_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_rep_sales_rep_rec     get_rep_sales_rep_ttype;
    lt_receipt_method_rec    get_receipt_method_ttype;
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
    -- システム日付の取得
    ld_sysdate := TRUNC(SYSDATE);
--
    lt_receipt_class_id1 := TO_NUMBER( iv_receipt_class1 );  -- 入金区分ID1
    lt_receipt_class_id2 := TO_NUMBER( iv_receipt_class2 );  -- 入金区分ID2
    lt_receipt_class_id3 := TO_NUMBER( iv_receipt_class3 );  -- 入金区分ID3
    lt_receipt_class_id4 := TO_NUMBER( iv_receipt_class4 );  -- 入金区分ID4
    lt_receipt_class_id5 := TO_NUMBER( iv_receipt_class5 );  -- 入金区分ID5
--
    -- 帳票出力対象のデータを取得する
    OPEN get_rep_sales_rep_cur;
--
    FETCH get_rep_sales_rep_cur BULK COLLECT INTO lt_rep_sales_rep_rec;
--
    CLOSE get_rep_sales_rep_cur;
--
    <<get_sales_rep_loop>>
    FOR ln_count IN 1..lt_rep_sales_rep_rec.COUNT LOOP
--
      -- 当該顧客の支払方法・入金区分を取得する
      OPEN get_receipt_method_cur(
             lt_rep_sales_rep_rec(ln_count).receipt_customer_code  -- 入金先顧客番号
            ,ld_sysdate                                            -- システム日付
           )
      ;
--
      FETCH get_receipt_method_cur BULK COLLECT INTO lt_receipt_method_rec;
--
      CLOSE get_receipt_method_cur;
--
      -- 取得できなかった時、パラメータで入金区分が異なっていたので帳票出力対象外
      IF ( lt_receipt_method_rec.COUNT < 1 ) THEN
--
        DELETE FROM xxcfr_rep_sales_rep_pay_sch  xrsr  -- 帳票用ワークテーブル
        WHERE xrsr.request_id            = cn_request_id                               -- 要求ID
          AND xrsr.receipt_customer_code = lt_rep_sales_rep_rec(ln_count).receipt_customer_code  -- 入金先顧客番号
        ;
--
        -- 出力対象件数、成功件数を減らす
        gn_target_cnt := gn_target_cnt - SQL%ROWCOUNT;
        gn_normal_cnt := gn_target_cnt;
--
      -- 
      -- パラメータに該当したので、入金区分を入金先顧客の値で更新する。
      ELSE
--
        -- 最初のコレクションを取得
        ln_first := lt_receipt_method_rec.FIRST;
--
        -- 入金区分を設定する。
        UPDATE xxcfr_rep_sales_rep_pay_sch  xrsr  -- 帳票用ワークテーブル
        SET    xrsr.receipt_class_id   = lt_receipt_method_rec(ln_first).receipt_class_id   -- 入金区分ID
              ,xrsr.receipt_class_name = lt_receipt_method_rec(ln_first).receipt_class_name -- 入金区分名
        WHERE  xrsr.request_id            = cn_request_id                                                             -- 要求ID
          AND  xrsr.receipt_customer_code = lt_rep_sales_rep_rec(ln_count).receipt_customer_code  -- 入金先顧客番号
        ;
--
      END IF;
--
    END LOOP get_sales_rep_loop;
--
    -- 登録データが１件も存在しない場合、０件メッセージレコード追加
    IF ( gn_target_cnt = 0 ) THEN
--
      BEGIN
--
        INSERT INTO xxcfr_rep_sales_rep_pay_sch ( 
           report_id
          ,output_date
          ,receipt_dept_code
          ,receipt_sales_rep_code
          ,data_empty_message
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
        VALUES ( 
          cv_pkg_name                                        , -- 帳票ＩＤ
          TO_CHAR( cd_creation_date, cv_format_date_ymdhns ) , -- 出力日
          iv_receive_base_code                               , -- 入金拠点コード
          iv_sales_rep                                       , -- 営業担当者
          gv_no_data_msg                                     , -- 0件メッセージ
          cn_created_by                                      , -- 作成者
          cd_creation_date                                   , -- 作成日
          cn_last_updated_by                                 , -- 最終更新者
          cd_last_update_date                                , -- 最終更新日
          cn_last_update_login                               , -- 最終更新ログイン
          cn_request_id                                      , -- 要求ID
          cn_program_application_id                          , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                                      , -- コンカレント・プログラムID
          cd_program_update_date                               -- プログラム更新日
        );
--
        -- 警告終了
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_009a01_016    -- 対象データ0件警告
                                                      )
                                                      ,1
                                                      ,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_warn;
--
      EXCEPTION
        WHEN OTHERS THEN  -- 登録時エラー
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                         ,cv_msg_009a01_013    -- テーブル登録エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- 営業員別払日別入金予定表帳票ワークテーブル
                                                         ,1
                                                         ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          raise global_api_expt;
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
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( get_receipt_method_cur%ISOPEN ) THEN
        CLOSE get_receipt_method_cur;
      END IF;
      IF ( get_rep_sales_rep_cur%ISOPEN ) THEN
        CLOSE get_rep_sales_rep_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_receipt_method_cur%ISOPEN ) THEN
        CLOSE get_receipt_method_cur;
      END IF;
      IF ( get_rep_sales_rep_cur%ISOPEN ) THEN
        CLOSE get_rep_sales_rep_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_receipt_method_cur%ISOPEN ) THEN
        CLOSE get_receipt_method_cur;
      END IF;
      IF ( get_rep_sales_rep_cur%ISOPEN ) THEN
        CLOSE get_rep_sales_rep_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_receipt_class;
-- Modify 2010.01.21 Ver1.7 End
--
  /**********************************************************************************
   * Procedure Name   : start_svf_api
   * Description      : SVF起動 (A-4)
   ***********************************************************************************/
  PROCEDURE start_svf_api(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf_api'; -- プログラム名
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
-- Modify 2009.03.05 Ver1.2 Start
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR009A01S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR009A01S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- 出力区分(=1：PDF出力）
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- 拡張子（pdf）
-- Modify 2009.03.05 Ver1.2 End
--
    -- *** ローカル変数 ***
    lv_no_data_msg     VARCHAR2(5000);  -- 帳票０件メッセージ
-- Modify 2009.04.14 Ver1.3 Start
--    lv_svf_file_name   VARCHAR2(30);
    lv_svf_file_name   VARCHAR2(100);
-- Modify 2009.04.14 Ver1.3 END
-- Modify 2009.03.05 Ver1.2 Start
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- Modify 2009.03.05 Ver1.2 End
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
    -- =====================================================
    --  SVF起動 (A-4)
    -- =====================================================
--
-- Modify 2009.03.05 Ver1.2 Start
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
    -- コンカレント名の設定
    lv_conc_name := cv_pkg_name;
--
    -- ファイルIDの設定
    lv_file_id := cv_pkg_name;
--
--    -- 帳票０件メッセージ取得
--    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                       ,cv_msg_009a01_016 -- 帳票０件メッセージ
--                                                      )
--                                                    ,1
--                                                    ,5000);
--
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_svf_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      ,iv_conc_name    => lv_conc_name          -- コンカレント名
      ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
      ,iv_file_id      => lv_file_id            -- 帳票ID
      ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
      ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
      ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
      ,iv_org_id       => gn_org_id             -- ORG_ID
      ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
      ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
      ,iv_doc_name     => NULL                  -- 文書名
      ,iv_printer_name => NULL                  -- プリンタ名
      ,iv_request_id   => cn_request_id         -- 要求ID
      ,iv_nodata_msg   => NULL                  -- データなしメッセージ
    );
-- Modify 2009.03.05 Ver1.2 End
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_009a01_015    -- APIエラー
                                                     ,cv_tkn_api           -- トークン'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_msg_kbn_cfr
                                                       ,cv_dict_svf 
                                                      )  -- SVF起動
                                                    )
                                                  ,1
                                                  ,5000);
-- Modify 2009.03.05 Ver1.2 Start
--      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
-- Modify 2009.03.05 Ver1.2 End
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
  END start_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ワークテーブルデータ削除 (A-5)
   ***********************************************************************************/
  PROCEDURE delete_work_table(
    ov_errbuf               OUT        VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT        VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT        VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- プログラム名
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
    ln_target_cnt   NUMBER;         -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR del_rep_sales_rep_cur
    IS
      SELECT xrsr.ROWID        ln_rowid
      FROM xxcfr_rep_sales_rep_pay_sch  xrsr
      WHERE xrsr.request_id             = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT
    ;
--
    TYPE g_del_rep_sales_rep_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_sales_rep_data    g_del_rep_sales_rep_ttype;
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
    -- カーソルオープン
    OPEN del_rep_sales_rep_cur;
--
    -- データの一括取得
    FETCH del_rep_sales_rep_cur BULK COLLECT INTO lt_del_rep_sales_rep_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_del_rep_sales_rep_data.COUNT;
--
    -- カーソルクローズ
    CLOSE del_rep_sales_rep_cur;
--
    -- 対象データが存在する場合レコードを削除する
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<data_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_rep_sales_rep_pay_sch
          WHERE ROWID = lt_del_rep_sales_rep_data(ln_loop_cnt);
--
        -- コミット発行
        COMMIT;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_009a01_012 -- データ削除エラー
                                                        ,cv_tkn_table         -- トークン'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- 営業員別払日別入金予定表帳票ワークテーブル
                                                        ,1
                                                        ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_009a01_011    -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- 営業員別払日別入金予定表帳票ワークテーブル
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
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
  END delete_work_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_receive_base_code   IN      VARCHAR2,         --    入金拠点
    iv_sales_rep           IN      VARCHAR2,         --    営業担当者
    iv_due_date_from       IN      VARCHAR2,         --    支払期日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払期日(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    入金区分１
    iv_receipt_class2      IN      VARCHAR2,         --    入金区分２
    iv_receipt_class3      IN      VARCHAR2,         --    入金区分３
    iv_receipt_class4      IN      VARCHAR2,         --    入金区分４
    iv_receipt_class5      IN      VARCHAR2,         --    入金区分５
    ov_errbuf              OUT     VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_receive_base_code   -- 入金拠点
      ,iv_sales_rep           -- 営業担当者
      ,iv_due_date_from       -- 支払期日(FROM)
      ,iv_due_date_to         -- 支払期日(TO)
      ,iv_receipt_class1      -- 入金区分１
      ,iv_receipt_class2      -- 入金区分２
      ,iv_receipt_class3      -- 入金区分３
      ,iv_receipt_class4      -- 入金区分４
      ,iv_receipt_class5      -- 入金区分５
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ワークテーブルデータ登録 (A-3)
    -- =====================================================
    insert_work_table(
       iv_receive_base_code   -- 入金拠点
      ,iv_sales_rep           -- 営業担当者
      ,iv_due_date_from       -- 支払期日(FROM)
      ,iv_due_date_to         -- 支払期日(TO)
      ,iv_receipt_class1      -- 入金区分１
      ,iv_receipt_class2      -- 入金区分２
      ,iv_receipt_class3      -- 入金区分３
      ,iv_receipt_class4      -- 入金区分４
      ,iv_receipt_class5      -- 入金区分５
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --(戻り値の保存)
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
    END IF;
--
-- Modify 2010.01.21 Ver1.7 Start
    -- =====================================================
    --  入金区分設定処理(A-8)
    -- =====================================================
    set_receipt_class(
       iv_receive_base_code   -- 入金拠点
      ,iv_sales_rep           -- 営業担当者
      ,iv_receipt_class1      -- 入金区分１
      ,iv_receipt_class2      -- 入金区分２
      ,iv_receipt_class3      -- 入金区分３
      ,iv_receipt_class4      -- 入金区分４
      ,iv_receipt_class5      -- 入金区分５
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --(戻り値の保存)
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
    END IF;
-- Modify 2010.01.21 Ver1.7 End
--
    -- =====================================================
    --  SVF起動 (A-4)
    -- =====================================================
    start_svf_api(
       lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode_svf            -- リターン・コード             --# 固定 #
      ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- =====================================================
    --  ワークテーブルデータ削除 (A-5)
    -- =====================================================
-- Modify 2009.03.05 Ver1.2 Start
--/*
-- Modify 2009.03.05 Ver1.2 End
    delete_work_table(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
-- Modify 2009.03.05 Ver1.2 Start
--*/
-- Modify 2009.03.05 Ver1.2 End
--
    -- =====================================================
    --  SVF起動APIエラーチェック (A-6)
    -- =====================================================
    IF (lv_retcode_svf = cv_status_error) THEN
      --(エラー処理)
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
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
    errbuf                 OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                OUT     VARCHAR2,         --    エラーコード     #固定#
    iv_receive_base_code   IN      VARCHAR2,         --    入金拠点
    iv_sales_rep           IN      VARCHAR2,         --    営業担当者
    iv_due_date_from       IN      VARCHAR2,         --    支払期日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払期日(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    入金区分１
    iv_receipt_class2      IN      VARCHAR2,         --    入金区分２
    iv_receipt_class3      IN      VARCHAR2,         --    入金区分３
    iv_receipt_class4      IN      VARCHAR2,         --    入金区分４
    iv_receipt_class5      IN      VARCHAR2          --    入金区分５
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
    lv_message_code VARCHAR2(100);   --メッセージコード
--
    lv_errbuf2      VARCHAR2(5000);  -- エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
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
       iv_receive_base_code   -- 入金拠点
      ,iv_sales_rep           -- 営業担当者
      ,iv_due_date_from       -- 支払期日(FROM)
      ,iv_due_date_to         -- 支払期日(TO)
      ,iv_receipt_class1      -- 入金区分１
      ,iv_receipt_class2      -- 入金区分２
      ,iv_receipt_class3      -- 入金区分３
      ,iv_receipt_class4      -- 入金区分４
      ,iv_receipt_class5      -- 入金区分５
      ,lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --エラーメッセージが設定されている場合、エラー出力
    IF (lv_errmsg IS NOT NULL) THEN
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_009a01_009
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
    END IF;
--
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
--
-- Add End   2008/11/18 SCS H.Nakamura テンプレートを修正
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End 2008/11/18 SCS H.Nakamura テンプレートを修正
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
END XXCFR009A01C;
/