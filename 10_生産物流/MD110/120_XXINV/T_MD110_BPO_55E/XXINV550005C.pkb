CREATE OR REPLACE PACKAGE BODY XXINV550005C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550005C(body)
 * Description      : 計画・移動・在庫：在庫(帳票)
 * MD.050/070       : T_MD050_BPO_550_在庫(帳票)Issue1.0 (T_MD050_BPO_550)
 *                  : 棚卸スナップショット作成           (T_MD070_BPO_55E)
 * Version          : 1.1
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/22    1.0  Oracle 大橋孝郎  新規作成
 *  2008/11/13    1.1  Y.Kawano         統合テスト指摘#580対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
--#####################  固定共通例外宣言部 START   ####################
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
--###########################  固定部 END   ############################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  gv_pkg_name            CONSTANT VARCHAR2(20) := 'XXINV550005C' ;     -- パッケージ名
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_inv     CONSTANT VARCHAR2(5)   := 'XXINV' ;           -- アプリケーション（XXINV）
  gc_xxinv_10117         CONSTANT VARCHAR2(15)  := 'APP-XXINV-10117' ; -- 棚卸スナップショット作成エラー
-- 2008/11/13 Y.Kawano Add Start
  gc_xxinv_10009         CONSTANT VARCHAR2(15)  := 'APP-XXINV-10009';  -- データ取得失敗
  -- トークン
  gv_c_tkn_msg           CONSTANT VARCHAR2(30)  := 'MSG';
  gv_c_calendar          CONSTANT VARCHAR2(60)  := 'OPM在庫会計期間CLOSE年月';
-- 2008/11/13 Y.Kawano Add End
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  parameter_check_expt     EXCEPTION;     -- パラメータチェック例外
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_invent_ym             IN  VARCHAR2     -- 01 : 対象年月	
    ,iv_whse_code1            IN  VARCHAR2     -- 02 : 倉庫コード１
    ,iv_whse_code2            IN  VARCHAR2     -- 03 : 倉庫コード２
    ,iv_whse_code3            IN  VARCHAR2     -- 04 : 倉庫コード３
    ,iv_whse_department1      IN  VARCHAR2     -- 05 : 倉庫管理部署１
    ,iv_whse_department2      IN  VARCHAR2     -- 06 : 倉庫管理部署２
    ,iv_whse_department3      IN  VARCHAR2     -- 07 : 倉庫管理部署３
    ,iv_block1                IN  VARCHAR2     -- 08 : ブロック１
    ,iv_block2                IN  VARCHAR2     -- 09 : ブロック２
    ,iv_block3                IN  VARCHAR2     -- 10 : ブロック３
    ,iv_arti_div_code         IN  VARCHAR2     -- 11 : 商品区分
    ,iv_item_class_code       IN  VARCHAR2     -- 12 : 品目区分
    ,ov_errbuf                OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode               OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg                OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    )
--
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
    -- *** ローカル変数 ***
    ln_ret_num        NUMBER ;        -- 関数戻り値：数値型
    lv_err_code       VARCHAR2(100) ; -- エラーコード格納用
-- 2008/11/13 Y.Kawano Add Start
    lv_invent_ym      VARCHAR2(6) ;   -- 対象年月
-- 2008/11/13 Y.Kawano Add End
--
    -- *** ローカル・例外処理 ***
    create_snap_expt  EXCEPTION ;     -- 棚卸スナップショット作成エラー
-- 2008/11/13 Y.Kawano Add Start
    get_data_err_expt EXCEPTION ;     -- データ取得エラー
-- 2008/11/13 Y.Kawano Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/11/13 Y.Kawano Add Start
   -- パラメータ：対象年月がNULLの場合、直近締月の翌月を設定
   IF ( iv_invent_ym IS NULL )
   THEN
     -- OPM在庫カレンダの直近締月の翌月取得
     lv_invent_ym := TO_CHAR(ADD_MONTHS(TO_DATE(xxcmn_common_pkg.get_opminv_close_period, 'YYYYMM'), 1),'YYYYMM');
     --
     IF ( lv_invent_ym IS NULL )              --*** データ取得エラー ***
     THEN
      RAISE get_data_err_expt;
     END IF;
     --
   ELSE
     lv_invent_ym := iv_invent_ym;
   END IF;
-- 2008/11/13 Y.Kawano Add End
--
    -- ====================================================
    -- 棚卸スナップショット作成プログラム呼出
    -- ====================================================
-- 2008/11/13 Y.Kawano Add Start
--    ln_ret_num := xxinv550004c.create_snapshot( iv_invent_ym         -- 対象年月
    ln_ret_num := xxinv550004c.create_snapshot( lv_invent_ym         -- 対象年月
-- 2008/11/13 Y.Kawano Add End
                                               ,iv_whse_code1        -- 倉庫コード1
                                               ,iv_whse_code2        -- 倉庫コード2
                                               ,iv_whse_code3        -- 倉庫コード3
                                               ,iv_whse_department1  -- 倉庫管理部署1
                                               ,iv_whse_department2  -- 倉庫管理部署2
                                               ,iv_whse_department3  -- 倉庫管理部署3
                                               ,iv_block1            -- ブロック1
                                               ,iv_block2            -- ブロック2
                                               ,iv_block3            -- ブロック3
                                               ,iv_arti_div_code     -- 商品区分
                                               ,iv_item_class_code   -- 品目区分
                                              )
    ;
    IF ( ln_ret_num <> 0 ) THEN
      lv_err_code := gc_xxinv_10117 ;
      RAISE create_snap_expt ;
    END IF ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg  ;
    ov_errbuf  := lv_errbuf  ;
--
  EXCEPTION
    --*** 棚卸スナップショット作成エラー例外 ***
    WHEN create_snap_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
      ov_errmsg := lv_errmsg ;
      ov_errbuf := SQLERRM;
      ov_retcode := gv_status_error ;
--
-- 2008/11/13 Y.Kawano Add Start
    --*** データ取得エラー例外 ***
    WHEN get_data_err_expt THEN
      -- メッセージセット
       lv_errmsg := xxcmn_common_pkg.get_msg(gc_application_inv,
                                             gc_xxinv_10009,   -- データ取得エラー
                                             gv_c_tkn_msg,     -- トークンMSG
                                             gv_c_calendar     -- トークン値
                                             );
      ov_errmsg := lv_errmsg ;
      ov_errbuf := SQLERRM;
      ov_retcode := gv_status_error ;
-- 2008/11/13 Y.Kawano Add Start
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
 PROCEDURE main
    (
      errbuf                  OUT  VARCHAR2     -- エラーメッセージ
     ,retcode                 OUT  VARCHAR2     -- エラーコード
     ,iv_invent_ym            IN   VARCHAR2     -- 01. 対象年月	
     ,iv_whse_code1           IN   VARCHAR2     -- 02. 倉庫コード１
     ,iv_whse_code2           IN   VARCHAR2     -- 03. 倉庫コード２
     ,iv_whse_code3           IN   VARCHAR2     -- 04. 倉庫コード３
     ,iv_whse_department1     IN   VARCHAR2     -- 05. 倉庫管理部署１
     ,iv_whse_department2     IN   VARCHAR2     -- 06. 倉庫管理部署２
     ,iv_whse_department3     IN   VARCHAR2     -- 07. 倉庫管理部署３
     ,iv_block1               IN   VARCHAR2     -- 08. ブロック１
     ,iv_block2               IN   VARCHAR2     -- 09. ブロック２
     ,iv_block3               IN   VARCHAR2     -- 10. ブロック３
     ,iv_arti_div_code        IN   VARCHAR2     -- 11. 商品区分
     ,iv_item_class_code      IN   VARCHAR2     -- 12. 品目区分
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_invent_ym           -- 01 : 対象年月	
      ,iv_whse_code1          -- 02 : 倉庫コード１
      ,iv_whse_code2          -- 03 : 倉庫コード２
      ,iv_whse_code3          -- 04 : 倉庫コード３
      ,iv_whse_department1    -- 05 : 倉庫管理部署１
      ,iv_whse_department2    -- 06 : 倉庫管理部署２
      ,iv_whse_department3    -- 07 : 倉庫管理部署３
      ,iv_block1              -- 08 : ブロック１
      ,iv_block2              -- 09 : ブロック２
      ,iv_block3              -- 10 : ブロック３
      ,iv_arti_div_code       -- 11 : 商品区分
      ,iv_item_class_code     -- 12 : 品目区分
      ,lv_errbuf              -- エラー・メッセージ
      ,lv_retcode             -- リターン・コード
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXINV550005C;
/
