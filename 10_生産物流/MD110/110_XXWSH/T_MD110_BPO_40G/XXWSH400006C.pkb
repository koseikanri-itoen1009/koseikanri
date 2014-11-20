create or replace PACKAGE BODY xxwsh400006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400006c(spec)
 * Description      : 出荷依頼確定処理
 * MD.050           : T_MD050_BPO_401_出荷依頼
 * MD.070           : 出荷依頼確定処理 T_MD070_EDO_BPO_40G
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  ship_set               出荷依頼確定処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/3/24     1.0   R.Matusita       新規作成
 *  2008/4/23     1.1   R.Matusita       内部変更要求#63
 *  2008/6/05     1.2   N.Yoshida        配送先コード⇒配送先ID変換対応(内部不具合)
 *  2009/4/20     1.3   Y.Kazama         本番障害#1398対応
 *  2009/11/25    1.4   M.Miyagawa       本番障害#1671対応
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  lock_expt                 EXCEPTION;     -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxwsh400006c'; -- パッケージ名
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';        -- モジュール名省略：XXCMNマスタ共通
  gv_cnst_msg_kbn   CONSTANT VARCHAR2(5)    := 'XXWSH';
--
  -- メッセージ
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';
                                            -- メッセージ：ロック取得エラー
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- メッセージ：データ取得エラー
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';
                                            -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
  gv_cnst_msg_null CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-11161';  -- 必須チェックエラーメッセージ
  gv_cnst_msg_222  CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-11222';  --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_upd_cnt          NUMBER DEFAULT 0;      -- 更新件数
--
  gv_msg_kbn          CONSTANT VARCHAR2(5)  DEFAULT 'XXCMN';
  --メッセージ番号
  gv_msg_80a_016      CONSTANT VARCHAR2(15) DEFAULT 'APP-XXCMN-10018';  --APIエラー(コンカレント)
  --トークン
  gv_tkn_api_name     CONSTANT VARCHAR2(15) DEFAULT 'API_NAME';
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_head_sales_branch     IN  VARCHAR2  DEFAULT NULL, -- 管轄拠点
    iv_input_sales_branch    IN  VARCHAR2  DEFAULT NULL, -- 入力拠点
    iv_deliver_to_id         IN  VARCHAR2  DEFAULT NULL, -- 配送先ID
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- 依頼No
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- 出庫日
    id_schedule_arrival_date IN  DATE      DEFAULT NULL, -- 着日
    iv_status_kbn            IN  VARCHAR2,               -- 締めステータスチェック区分
    ov_errbuf                OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    gv_cnst_msg       CONSTANT VARCHAR2(30)  := '締めステータスチェック区分';
    gv_cnst_del_to_id CONSTANT VARCHAR2(30)  := '配送先ID';
    lv_type           CONSTANT VARCHAR2(30)  := '数値';
    -- *** ローカル変数 ***
--
    ln_deliver_to_id   NUMBER ; -- 配送先ID(数値型)
    ivv_deliver_to_id  VARCHAR2(30) ; -- 配送先ID(変換後配送先ID)
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
    -- 「締めステータスチェック区分」チェック(G-1)
    IF (iv_status_kbn IS NULL) THEN
      -- 締めステータスチェック区分のNULLチェックを行います
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_null,
                                            'PARAMETER',
                                            gv_cnst_msg);
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- 配送先コード⇒配送先ID変換処理
    -- ==================================================
    IF (iv_deliver_to_id IS NOT NULL) THEN
      BEGIN
        SELECT party_site_id
        INTO   ivv_deliver_to_id
-- Ver1.4 M.Miyagawa 本番障害#1671 Mod Start
--        FROM   xxcmn_cust_acct_sites2_v
        FROM   xxcmn_cust_acct_sites_v
-- Ver1.4 M.Miyagawa 本番障害#1671 Mod End
        WHERE  ship_to_no  = iv_deliver_to_id;
-- Ver1.3 Y.Kazama 本番障害#1398 Mod Start
-- Ver1.4 M.Miyagawa 本番障害#1671 Del Start
--        AND    party_site_status = 'A'  -- サイトステータス[A:有効];
-- Ver1.4 M.Miyagawa 本番障害#1671 Del End        
--        GROUP BY party_site_id;
-- Ver1.3 Y.Kazama 本番障害#1398 Mod End
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ivv_deliver_to_id := NULL;
        WHEN TOO_MANY_ROWS THEN
          RAISE global_process_expt;
      END;
    ELSE
      ivv_deliver_to_id := NULL;
    END IF;
    
    ln_deliver_to_id := TO_NUMBER(ivv_deliver_to_id);

--
    -- ==================================================
    -- 出荷依頼確定関数起動(G-2)
    -- ==================================================
    xxwsh400003c.ship_set(
      iv_prod_class,                  -- 商品区分
      iv_head_sales_branch,           -- 管轄拠点
      iv_input_sales_branch,          -- 入力拠点
      ln_deliver_to_id,               -- 配送先ID
      iv_request_no,                  -- 依頼No
      id_schedule_ship_date,          -- 出庫日
      id_schedule_arrival_date,       -- 着日
      '1',                            -- 呼出元フラグ
      iv_status_kbn,                  -- 締めステータスチェック区分
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_warn) THEN
      -- ワーニングの場合
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
    ELSIF (lv_retcode = gv_status_error) THEN
      -- main側でROLLBACK処理を行う為、normalを代入
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 数値変換エラーハンドラ ***
    WHEN INVALID_NUMBER THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_222,
                                              'PARAMETER',
                                              gv_cnst_del_to_id,
                                              'TYPE',
                                              lv_type);
      RAISE global_process_expt;
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
    errbuf                   OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode                  OUT NOCOPY VARCHAR2,         -- エラーコード     #固定#
    iv_prod_class            IN  VARCHAR2,                -- 商品区分
    iv_head_sales_branch     IN  VARCHAR2,                -- 管轄拠点
    iv_input_sales_branch    IN  VARCHAR2,                -- 入力拠点
    iv_deliver_to_id         IN  VARCHAR2,                -- 配送先ID
    iv_request_no            IN  VARCHAR2,                -- 依頼No
    iv_schedule_ship_date    IN  VARCHAR2,                -- 出庫日
    iv_schedule_arrival_date IN  VARCHAR2,                -- 着日
    iv_status_kbn            IN  VARCHAR2                 -- 締めステータスチェック区分
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      iv_prod_class,                               -- 商品区分
      iv_head_sales_branch,                        -- 管轄拠点
      iv_input_sales_branch,                       -- 入力拠点
      iv_deliver_to_id,                            -- 配送先ID
      iv_request_no,                               -- 依頼No
      FND_DATE.STRING_TO_DATE(iv_schedule_ship_date, 'YYYY/MM/DD'),    -- 出庫日
      FND_DATE.STRING_TO_DATE(iv_schedule_arrival_date, 'YYYY/MM/DD'), -- 着日
      iv_status_kbn,                               -- 締めステータスチェック区分
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ======================
    -- ワーニング・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
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
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
END xxwsh400006c;
/
