CREATE OR REPLACE PACKAGE BODY xxinv590001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv590001c(body)
 * Description      : OPM在庫会計期間オープン
 * MD.050           : OPM在庫会計期間オープン(クローズ) T_MD050_BPO_590
 * MD.070           : OPM在庫会計期間オープン(59A) T_MD070_BPO_59A
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/08/06    1.0   Y.Suzuki         新規作成
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
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  lock_expt              EXCEPTION;               -- ロック取得例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- メッセージ用定数
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxinv590001c';                           -- パッケージ名
  gv_app_name       CONSTANT VARCHAR2(5)   := 'XXCMN';                                  -- アプリケーション短縮名
  gv_tkn_name       CONSTANT VARCHAR2(100) := '在庫倉庫ステータス/在庫倉庫オープン表';  -- テーブル名
--
  -- メッセージ
  gv_msg_xxcmn10019 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';   -- ロック取得エラー
--
  -- トークン
  gv_tkn_table      CONSTANT VARCHAR2(10) := 'TABLE';             -- トークン：テーブル名
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
  TYPE whse_code_typ IS TABLE OF ic_whse_sts.whse_code%TYPE INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- 対象倉庫取得用レコード
  TYPE whse_code_rec IS RECORD(
    whse_code ic_whse_sts.whse_code%TYPE
  );
--
  -- ***************************************
  -- ***      項目格納テーブル型定義     ***
  -- ***************************************
--
  -- 対象倉庫取得用レコード
  TYPE whse_code_tbl IS TABLE OF whse_code_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- テーブル型グローバル変数
  gt_whse_code_tbl  whse_code_tbl;            -- 対象倉庫取得用レコード
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_sequence         IN     VARCHAR2,                -- シーケンスID
    iv_fiscal_year      IN     VARCHAR2,                -- 会計年度
    iv_period           IN     VARCHAR2,                -- 期間
    iv_period_id        IN     VARCHAR2,                -- 期間ID
    iv_start_date       IN     VARCHAR2,                -- 開始日付
    iv_end_date         IN     VARCHAR2,                -- 終了日付
    iv_op_code          IN     VARCHAR2,                -- Operators Identifier Number
    iv_orgn_code        IN     VARCHAR2,                -- 会社コード
    iv_close_ind        IN     VARCHAR2,                -- 処理区分(1:OPEN,2:暫定CLOSE,3:CLOSE)
    ov_errbuf           OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2,                -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2)                -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- プログラム名
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
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_user_id   NUMBER;
    ln_login_id  NUMBER;
--
    -- *** ローカル・レコード ***
    lt_whse_code whse_code_typ;
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
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'INPUT PARAMETERS');
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'SEQUENCE   - '||iv_sequence);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'FISCAL YEAR- '||iv_fiscal_year);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'PERIOD     - '||iv_period);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'PERIOD ID  - '||iv_period_id);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'START DATE - '||iv_start_date);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'END DATE   - '||iv_end_date);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'OP CODE    - '||iv_op_code);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'ORGN CODE  - '||iv_orgn_code);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'CLOSE IND  - '||iv_close_ind);
--
    ln_user_id  := FND_GLOBAL.USER_ID;
    ln_login_id := FND_GLOBAL.LOGIN_ID;
--
    -- A-1 対象データの取得
    SELECT iws.whse_code
    BULK COLLECT INTO gt_whse_code_tbl
    FROM   xxinv_open_warehouses xow
          ,ic_whse_sts iws
    WHERE  xow.inventory_open_id = TO_NUMBER(iv_sequence)
    AND    xow.whse_code         = iws.whse_code
    AND    iws.fiscal_year       = iv_fiscal_year
    AND    iws.period            = iv_period
    FOR UPDATE NOWAIT;
--
    IF (gt_whse_code_tbl IS NOT NULL) THEN
      -- ループ処理にて、バルク取得したデータを項目単位のテーブル型へ移行
      <<upd_loop>>
      FOR col_cnt IN 1 .. gt_whse_code_tbl.COUNT LOOP
        lt_whse_code(col_cnt)    := gt_whse_code_tbl(col_cnt).whse_code;
      END LOOP upd_loop;
--
      -- A-2 ic_whse_sts表の更新
      FORALL upd_cnt IN 1 .. lt_whse_code.COUNT
        UPDATE ic_whse_sts
        SET    log_end_date      = SYSDATE
              ,close_whse_ind    = iv_close_ind
              ,last_updated_by   = ln_user_id
              ,last_update_date  = SYSDATE
              ,last_update_login = ln_login_id
        WHERE  whse_code         = lt_whse_code(upd_cnt)
        AND    fiscal_year       = iv_fiscal_year
        AND    period            = iv_period;
--
      -- A-3 xxinv_open_warehouses表の削除
      DELETE FROM xxinv_open_warehouses
      WHERE inventory_open_id = TO_NUMBER(iv_sequence);
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ロック取得例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10019,  -- メッセージ：APP-XXCMN-10019 ロックエラー
                            gv_tkn_table,       -- トークンTABLE
                            gv_tkn_name         -- テーブル名
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf              OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    retcode             OUT    VARCHAR2,                -- リターン・コード             --# 固定 #
    iv_sequence         IN     VARCHAR2,                -- シーケンスID
    iv_fiscal_year      IN     VARCHAR2,                -- 会計年度
    iv_period           IN     VARCHAR2,                -- 期間
    iv_period_id        IN     VARCHAR2,                -- 期間ID
    iv_start_date       IN     VARCHAR2,                -- 開始日付
    iv_end_date         IN     VARCHAR2,                -- 終了日付
    iv_op_code          IN     VARCHAR2,                -- Operators Identifier Number
    iv_orgn_code        IN     VARCHAR2,                -- 会社コード
    iv_close_ind        IN     VARCHAR2)                -- 処理区分(1:OPEN,2:暫定CLOSE,3:CLOSE
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                 -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_sequence,            -- シーケンスID
      iv_fiscal_year,         -- 会計年度
      iv_period,              -- 期間
      iv_period_id,           -- 期間ID
      iv_start_date,          -- 開始日付
      iv_end_date,            -- 終了日付
      iv_op_code,             -- Operators Identifier Number
      iv_orgn_code,           -- 会社コード
      iv_close_ind,           -- 処理区分(1:OPEN,2:暫定CLOSE,3:CLOSE)
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      errbuf := lv_errbuf;
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxinv590001c;
/
