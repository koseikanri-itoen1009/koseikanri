CREATE OR REPLACE PACKAGE BODY XXCFO010A03C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 * 
 * Package Name    : XXCFO010A03C
 * Description     : GLIFグループID更新
 * MD.050          : MD050_CFO_010_A03_GLIFグループID更新
 * MD.070          : MD050_CFO_010_A03_GLIFグループID更新
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        初期処理(A-1)
 *  upd_group_id      P        グループID更新(A-2)
 *  submain           P        メイン処理プロシージャ
 *  main              P        コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2015-09-01    1.0  SCSK 小路恭弘  初回作成
 ************************************************************************/
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO010A03C';     -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';            -- アドオン：マスタ・経理・共通のアプリケーション短縮名
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';            -- アドオン：会計・アドオン領域のアプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_010a03_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';  -- プロファイル取得エラーメッセージ
  cv_msg_010a03_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';  -- 対象データなしメッセージ
  cv_msg_010a03_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';  -- データ更新エラーメッセージ
  cv_msg_010a03_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00051';  -- パラメータ出力メッセージ
  cv_msg_010a03_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00052';  -- グループID更新件数メッセージ
  cv_msg_010a03_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';  -- データロックエラーメッセージ
--
  -- トークン
  cv_tkn_param1      CONSTANT VARCHAR2(20) := 'PARAM1';            -- パラメータ1
  cv_tkn_param2      CONSTANT VARCHAR2(20) := 'PARAM2';            -- パラメータ2
  cv_tkn_prof        CONSTANT VARCHAR2(20) := 'PROF_NAME';         -- プロファイル名
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';             -- テーブル名
  cv_tkn_errmsg      CONSTANT VARCHAR2(20) := 'ERRMSG';            -- エラー内容
  cv_tkn_group_id    CONSTANT VARCHAR2(20) := 'GROUP_ID';          -- グループID
--
  -- プロファイル
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';            -- 会計帳簿ID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_set_of_bks_id        NUMBER;                                  -- プロファイル値：会計帳簿ID
  gt_group_id0            gl_interface.group_id%TYPE;              -- 更新後グループID0
  gt_group_id1            gl_interface.group_id%TYPE;              -- 更新後グループID1
  gt_group_id2            gl_interface.group_id%TYPE;              -- 更新後グループID2
  gt_group_id3            gl_interface.group_id%TYPE;              -- 更新後グループID3
  gt_group_id4            gl_interface.group_id%TYPE;              -- 更新後グループID4
  gn_upd_cnt0             NUMBER;                                  -- 更新後グループID0の件数
  gn_upd_cnt1             NUMBER;                                  -- 更新後グループID1の件数
  gn_upd_cnt2             NUMBER;                                  -- 更新後グループID2の件数
  gn_upd_cnt3             NUMBER;                                  -- 更新後グループID3の件数
  gn_upd_cnt4             NUMBER;                                  -- 更新後グループID4の件数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_je_source_name  IN  VARCHAR2,  -- 仕訳ソース名
    iv_group_id        IN  VARCHAR2,  -- グループID
    ov_errbuf          OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_param_msg                VARCHAR2(5000);                         -- パラメータ出力用
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
    --==============================================================
    -- パラメータ出力
    --==============================================================
    --メッセージ編集
    lv_param_msg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_cfo              -- アプリケーション
                      , iv_name          => cv_msg_010a03_004           -- メッセージコード
                      , iv_token_name1   => cv_tkn_param1               -- トークンコード１
                      , iv_token_value1  => iv_je_source_name           -- 仕訳ソース名
                      , iv_token_name2   => cv_tkn_param2               -- トークンコード２
                      , iv_token_value2  => iv_group_id                 -- グループID
                    );
    -- ログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
--
    -- プロファイルからGL会計帳簿ID取得
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- 取得エラー時
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a03_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : upd_group_id
   * Description      : グループID更新(A-2)
   ***********************************************************************************/
  PROCEDURE upd_group_id(
    iv_je_source_name  IN  VARCHAR2,  -- 仕訳ソース名
    iv_group_id        IN  VARCHAR2,  -- グループID
    ov_errbuf          OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_group_id'; -- プログラム名
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
    cv_status_new         CONSTANT VARCHAR2(20) := 'NEW';                        -- ステータス:NEW
    cv_gl_interface_name  CONSTANT VARCHAR2(30) := 'GLインタフェーステーブル';   -- エラーメッセージ用テーブル名
    cv_number_0           CONSTANT VARCHAR2(1)  := '0';                          -- グループID末尾0作成用
    cv_number_1           CONSTANT VARCHAR2(1)  := '1';                          -- グループID末尾1作成用
    cv_number_2           CONSTANT VARCHAR2(1)  := '2';                          -- グループID末尾2作成用
    cv_number_3           CONSTANT VARCHAR2(1)  := '3';                          -- グループID末尾3作成用
    cv_number_4           CONSTANT VARCHAR2(1)  := '4';                          -- グループID末尾4作成用
--
    -- *** ローカル変数 ***
    lv_param_msg                VARCHAR2(5000);                   -- パラメータ出力用
    ln_group_id                 NUMBER;                           -- グループID（数値型変換用）
--
    -- *** ローカル・カーソル ***
    -- GLインタフェーステーブルのロック用カーソル
    CURSOR  gl_interface_lock_cur
    IS
      SELECT gi.rowid         row_id
      FROM   gl_interface        gi
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = ln_group_id
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
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
    -- グループIDの型を変換
    ln_group_id := TO_NUMBER(iv_group_id);
--
    -- 1.対象データ件数の取得
    SELECT COUNT(gi.group_id)   target_cnt  -- 対象件数
    INTO   gn_target_cnt
    FROM   gl_interface   gi                -- GLIF
    WHERE  gi.user_je_source_name = iv_je_source_name
    AND    gi.group_id            = ln_group_id
    AND    gi.set_of_books_id     = gn_set_of_bks_id
    AND    gi.status              = cv_status_new
    ;
--
    -- 対象データがない場合
    IF ( gn_target_cnt = 0 ) THEN
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_cfo              -- 'XXCFO'
                       , iv_name          => cv_msg_010a03_002           -- 対象データなしメッセージ
                     );
      -- ログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
      ov_retcode := cv_status_warn;
    -- 対象データがある場合
    ELSIF ( gn_target_cnt > 0 ) THEN
      -- 2.対象データのロックを取得
      BEGIN
        -- ロック用カーソルをオープンする
        OPEN gl_interface_lock_cur;
        -- カーソルをクローズする
        CLOSE   gl_interface_lock_cur;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_010a03_006     -- データロックエラーメッセージ
                                                        ,cv_tkn_table          -- トークン'TABLE'
                                                        ,cv_gl_interface_name  -- GLインタフェーステーブル
                                                        )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      BEGIN
        -- 3.グループIDの更新
        UPDATE gl_interface        gi
        SET    gi.group_id = TO_NUMBER( TO_CHAR( gi.group_id ) ||                                            -- グループID
                                        TO_CHAR( MOD( TO_NUMBER( TO_CHAR( gi.accounting_date, 'DD') ), 5 ) ) -- 計上日の日を5で割った余り
                                      )
        WHERE  gi.user_je_source_name = iv_je_source_name
        AND    gi.group_id            = ln_group_id
        AND    gi.set_of_books_id     = gn_set_of_bks_id
        AND    gi.status              = cv_status_new
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_010a03_003     -- データ更新エラーメッセージ
                                                        ,cv_tkn_table          -- トークン'TABLE'
                                                        ,cv_gl_interface_name  -- GLインタフェーステーブル
                                                        ,cv_tkn_errmsg         -- トークン'ERRMSG'
                                                        ,SQLERRM               -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- 4.更新後の各グループIDの件数を取得
      -- 更新後の各グループID
      gt_group_id0 := TO_NUMBER( iv_group_id || cv_number_0);   -- 末尾0に更新したグループID
      gt_group_id1 := TO_NUMBER( iv_group_id || cv_number_1);   -- 末尾1に更新したグループID
      gt_group_id2 := TO_NUMBER( iv_group_id || cv_number_2);   -- 末尾2に更新したグループID
      gt_group_id3 := TO_NUMBER( iv_group_id || cv_number_3);   -- 末尾3に更新したグループID
      gt_group_id4 := TO_NUMBER( iv_group_id || cv_number_4);   -- 末尾4に更新したグループID
--
      -- ①末尾が0のグループIDの件数を取得
      SELECT COUNT(gi.group_id)   target_cnt  -- 対象件数
      INTO   gn_upd_cnt0
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id0
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- ②末尾が1のグループIDの件数を取得
      SELECT COUNT(gi.group_id)   target_cnt  -- 対象件数
      INTO   gn_upd_cnt1
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id1
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- ③末尾が2のグループIDの件数を取得
      SELECT COUNT(gi.group_id)   target_cnt  -- 対象件数
      INTO   gn_upd_cnt2
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id2
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- ④末尾が3のグループIDの件数を取得
      SELECT COUNT(gi.group_id)   target_cnt  -- 対象件数
      INTO   gn_upd_cnt3
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id3
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- ⑤末尾が4のグループIDの件数を取得
      SELECT COUNT(gi.group_id)   target_cnt  -- 対象件数
      INTO   gn_upd_cnt4
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id4
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- 更新件数の合計を取得
      gn_normal_cnt := gn_upd_cnt0 + gn_upd_cnt1 + gn_upd_cnt2 + gn_upd_cnt3 + gn_upd_cnt4;
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
      --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
      IF ( gl_interface_lock_cur%ISOPEN ) THEN
        CLOSE   gl_interface_lock_cur;
      END IF;
  END upd_group_id;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_je_source_name  IN  VARCHAR2,  -- 仕訳ソース名
    iv_group_id        IN  VARCHAR2,  -- グループID
    ov_errbuf          OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_upd_cnt0   := 0;
    gn_upd_cnt1   := 0;
    gn_upd_cnt2   := 0;
    gn_upd_cnt3   := 0;
    gn_upd_cnt4   := 0;
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
       iv_je_source_name     -- 仕訳ソース名
      ,iv_group_id           -- グループID
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  グループID更新(A-2)
    -- =====================================================
    upd_group_id(
       iv_je_source_name     -- 仕訳ソース名
      ,iv_group_id           -- グループID
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
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
    errbuf             OUT VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode            OUT VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_je_source_name  IN  VARCHAR2,      -- 仕訳ソース名
    iv_group_id        IN  VARCHAR2       -- グループID
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
       iv_je_source_name   -- 仕訳ソース名
      ,iv_group_id         -- グループID
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
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
    -- 処理が正常終了の場合
    IF ( lv_retcode = cv_status_normal ) THEN
      -- 末尾が0のグループIDの件数を出力
      IF ( gn_upd_cnt0 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id0)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt0)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- 末尾が1のグループIDの件数を出力
      IF ( gn_upd_cnt1 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id1)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt1)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- 末尾が2のグループIDの件数を出力
      IF ( gn_upd_cnt2 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id2)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt2)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- 末尾が3のグループIDの件数を出力
      IF ( gn_upd_cnt3 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id3)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt3)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- 末尾が4のグループIDの件数を出力
      IF ( gn_upd_cnt4 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id4)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt4)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
    END IF;
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
END XXCFO010A03C;
/
