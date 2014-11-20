CREATE OR REPLACE PACKAGE BODY XXWSH400012C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * Package Name     : XXWSH400001C(spec)
 * Description      : 引取計画からのリーフ出荷依頼自動作成起動処理
 * MD.050/070       : 出荷依頼                                      (T_MD050_BPO_400)
 *                    引取計画からのリーフ出荷依頼自動作成起動処理  (T_MD070_BPO_40M)
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  parameter_check          入力パラメータチェック(M-1)
 *  get_target_sales_branch  処理対象拠点取得(M-2)
 *  submit_request_40a       子コンカレント呼出処理(M-3)
 *  status_check             コンカレント終了ステータスチェック(M-4)
 *  submain
 *  main
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/29    1.0   H.Itou           初回作成
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
  no_target_expt            EXCEPTION;     -- 対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(100) := 'XXWSH400012C';      -- パッケージ名
  --メッセージ番号
  gv_cons_msg_kbn_wsh       CONSTANT VARCHAR2(100) := 'XXWSH';             -- メッセージ区分XXWSH
  gv_cons_msg_kbn_cmn       CONSTANT VARCHAR2(100) := 'XXCMN';             -- メッセージ区分XXCMN
  gv_msg_xxcmn10135         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- 要求の発行失敗エラー
  gv_msg_xxwsh11001         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11001';   -- マスタチェックエラーメッセージ
  gv_msg_xxwsh11002         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11002';   -- マスタ書式エラーメッセージ
  gv_msg_xxwsh11004         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11004';   -- 必須入力Ｐ未設定エラーメッセージ
  gv_msg_xxwsh11007         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11007';   -- 対象年月メッセージ
  gv_msg_xxwsh11008         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11008';   -- 管轄拠点メッセージ
  gv_msg_xxwsh10002         CONSTANT VARCHAR2(100) := 'APP-XXWSH-10002';   -- 対象無し
  --定数
  gv_msg_normal             CONSTANT VARCHAR2(100) := '正常終了';
  gv_msg_warn               CONSTANT VARCHAR2(100) := '警告終了';
  gv_msg_error              CONSTANT VARCHAR2(100) := '異常終了';
  --トークン
  gv_tkn_in_parm            CONSTANT VARCHAR2(100) := 'IN_PARAM';
  gv_tkn_yymm               CONSTANT VARCHAR2(100) := 'YYMM';
  gv_tkn_kyoten             CONSTANT VARCHAR2(100) := 'KYOTEN';
  gv_msg_yyyymm             CONSTANT VARCHAR2(100) := '対象年月';
  gv_msg_sales_branch       CONSTANT VARCHAR2(100) := '管轄拠点';
  gv_msg_request_id         CONSTANT VARCHAR2(100) := '要求ID';
  gv_msg_conc_result        CONSTANT VARCHAR2(100) := '処理結果';
--
  -- YES/NO
  gv_yes                    CONSTANT VARCHAR2(100) := 'Y'; -- YES
  gv_no                     CONSTANT VARCHAR2(100) := 'N'; -- NO
  -- 顧客区分
  gv_customer_class_code_b  CONSTANT VARCHAR2(100) := '1'; -- 拠点
  -- 出荷自動作成区分
  gv_order_auto_code_on     CONSTANT VARCHAR2(100) := '1'; -- 自動作成
  -- 商品区分
  gv_prod_code_leaf         CONSTANT VARCHAR2(100) := '1'; -- リーフ
  -- フォーキャスト種類
  gv_h_plan                 CONSTANT VARCHAR2(100) := '01'; -- 引取計画
--
  -- コンカレント終了ステータス
  gv_conc_p_c               CONSTANT VARCHAR2(100) := 'COMPLETE';
  gv_conc_s_w               CONSTANT VARCHAR2(100) := 'WARNING';
  gv_conc_s_e               CONSTANT VARCHAR2(100) := 'ERROR';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -------------------------------
  -- レコード型宣言
  -------------------------------
  TYPE param_data_rec IS RECORD   -- 入力Ｐ格納用レコード型
    (
     yyyymm        VARCHAR2(6)    -- 対象年月
   , base          VARCHAR2(4)    -- 管轄拠点
    );
--
  TYPE data_cnt_rec   IS RECORD   -- 処理結果格納レコード型
    (
      error_cnt    NUMBER         -- その日のエラー件数
    , warn_cnt     NUMBER         -- その日の警告件数
    , nomal_cnt    NUMBER         -- その日の正常件数
    , sales_branch mrp_forecast_designators.attribute3%TYPE  -- 拠点
    );
--
  -------------------------------
  -- テーブル型宣言
  -------------------------------
  TYPE sales_branch_tbl IS TABLE OF mrp_forecast_designators.attribute3%TYPE INDEX BY BINARY_INTEGER; -- 処理対象拠点         テーブル型
  TYPE data_cnt_tbl     IS TABLE OF data_cnt_rec                             INDEX BY BINARY_INTEGER; -- 処理結果格納レコード テーブル型
  TYPE number_tab       IS TABLE OF NUMBER                                   INDEX BY BINARY_INTEGER; -- NUMBER               テーブル型
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate           DATE;              -- システム現在日付
  gd_yyyymm            DATE;              -- 対象年月
--
  gr_param             param_data_rec;    -- 入力パラメータレコード
  gr_sales_branch_tbl  sales_branch_tbl;  -- 処理対象拠点格納テーブル
  gr_data_cnt_tbl      data_cnt_tbl;      -- 処理結果格納レコードテーブル
  gr_request_id_tbl    number_tab;        -- 要求IDテーブル
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : 入力パラメータチェック(M-1)
   ***********************************************************************************/
  PROCEDURE parameter_check
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt    NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 入力Ｐ「対象年月」の取得
    ------------------------------------------
    -- 取得エラー時
    IF (gr_param.yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_wsh    -- 'XXWSH'
                                                     ,gv_msg_xxwsh11004      -- 必須入力Ｐ未設定エラー
                                                     ,gv_tkn_in_parm         -- トークン
                                                     ,gv_msg_yyyymm          -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 入力Ｐ「対象年月」の書式変換(YYYYMM)
    gd_yyyymm := FND_DATE.STRING_TO_DATE(gr_param.yyyymm,'YYYYMM');
    -- 変換エラー時
    IF (gd_yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_wsh    -- 'XXWSH'
                                                     ,gv_msg_xxwsh11002      -- マスタ書式エラー
                                                     ,gv_tkn_yymm            -- トークン
                                                     ,gr_param.yyyymm        -- 入力Ｐ[対象年月]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- 入力Ｐ「管轄拠点」の取得
    ------------------------------------------
    -- 入力Ｐ「管轄拠点」が入力されていたら
    IF (gr_param.base IS NOT NULL) THEN
--
      ------------------------------------------------------------------------
      -- 顧客マスタ・パーティマスタに拠点が登録されているかどうかの判定
      ------------------------------------------------------------------------
      SELECT COUNT(account_number)
      INTO   ln_cnt
      FROM   xxcmn_parties_v                                 -- パーティ情報 V
      WHERE  account_number      = gr_param.base             -- 入力Ｐ[管轄拠点]
      AND    customer_class_code = gv_customer_class_code_b  -- '拠点'を示す「コード区分」
      AND    ROWNUM              = 1;
--
      -- 入力Ｐ[管轄拠点]が顧客マスタに存在しない場合
      IF (ln_cnt = 0) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                       ,gv_msg_xxwsh11001    -- マスタ書式エラー
                                                       ,gv_tkn_kyoten        -- トークン
                                                       ,gr_param.base        -- 入力Ｐ[管轄拠点]
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_target_sales_branch
   * Description      : 処理対象拠点取得(M-2)
   ***********************************************************************************/
  PROCEDURE get_target_sales_branch
    (
      ov_errbuf     OUT VARCHAR2                  --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_sales_branch'; -- プログラム名
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR cur_sales_branch
    IS
      SELECT mfds.attribute3                AS sales_branch        -- 拠点
      FROM  mrp_forecast_designators  mfds   -- フォーキャスト名        T
           ,mrp_forecast_dates        mfd    -- フォーキャスト日付      T
           ,xxcmn_cust_accounts_v     xcav   -- 顧客情報                V
           ,xxcmn_cust_acct_sites_v   xcasv  -- 顧客サイト情報          V
           ,xxcmn_item_categories5_v  xicv   -- OPM品目カテゴリ割当情報 V
           ,xxcmn_item_mst2_v         ximv   -- OPM品目情報             V
      WHERE mfds.attribute1                     = gv_h_plan                -- 引取計画 '01'
      AND   mfds.forecast_designator            = mfd.forecast_designator  -- フォーキャスト名
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gr_param.yyyymm          -- 入力Ｐ[対象年月]
      AND   mfd.organization_id                 = mfds.organization_id     -- 組織ID
      AND   ximv.inventory_item_id              = mfd.inventory_item_id    -- 品目ID
      AND   xcav.account_number                 = mfds.attribute3          -- 拠点
      AND   xcav.customer_class_code            = gv_customer_class_code_b -- 顧客区分 '1'
      AND   xcav.order_auto_code                = gv_order_auto_code_on    -- 出荷依頼自動作成区分 '1'
      AND   xcav.cust_account_id                = xcasv.cust_account_id    -- 顧客ID
      AND   xcasv.primary_flag                  = gv_yes                   -- 主フラグ 'Y'
      AND   xcav.party_id                       = xcasv.party_id           -- パーティID
      AND   xicv.item_id                        = ximv.item_id             -- 品目ID
      AND   xicv.prod_class_code                = gv_prod_code_leaf        -- 'リーフ'
      AND   ximv.start_date_active             <= gd_sysdate
      AND   ximv.end_date_active               >= gd_sysdate
      GROUP BY mfds.attribute3             -- 拠点
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 管轄拠点に指定がない場合
    IF (gr_param.base IS NULL) THEN
      -- カーソルオープン
      OPEN cur_sales_branch;
      -- バルクフェッチ
      FETCH cur_sales_branch BULK COLLECT INTO gr_sales_branch_tbl;
      -- カーソルクローズ
      CLOSE cur_sales_branch;
--
    -- 管轄拠点に指定がある場合
    ELSE
      gr_sales_branch_tbl(1) := gr_param.base;
    END IF;
--
    -- 処理件数取得
    gn_target_cnt := gr_sales_branch_tbl.COUNT;
--
    -- 対象データがない場合
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh
                                          , gv_msg_xxwsh10002);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルオープン時、クローズへ
      IF (cur_sales_branch%ISOPEN) THEN
        CLOSE cur_sales_branch;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルオープン時、クローズへ
      IF (cur_sales_branch%ISOPEN) THEN
        CLOSE cur_sales_branch;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルオープン時、クローズへ
      IF (cur_sales_branch%ISOPEN) THEN
        CLOSE cur_sales_branch;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_target_sales_branch;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_40a
   * Description      : 子コンカレント呼出処理(M-3)
   ***********************************************************************************/
  PROCEDURE submit_request_40a
    (
      ov_errbuf     OUT VARCHAR2                  --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_40a'; -- プログラム名
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
    -- ====================================
    -- 取得した拠点の数だけコンカレント実行
    -- ====================================
    <<target_loop>>
    FOR ln_cnt IN 1..gr_sales_branch_tbl.COUNT LOOP
      gr_request_id_tbl(ln_cnt) := FND_REQUEST.SUBMIT_REQUEST(
                                     APPLICATION  => 'XXWSH'                     -- アプリケーション短縮名
                                   , PROGRAM      => 'XXWSH400001C'              -- プログラム名
                                   , ARGUMENT1    => gr_param.yyyymm             -- 対象年月
                                   , ARGUMENT2    => gr_sales_branch_tbl(ln_cnt) -- 処理種別
                                   );
--
      -- 要求IDを取得できなかった場合
      IF ( gr_request_id_tbl(ln_cnt) = 0 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application   => gv_cons_msg_kbn_cmn
                      ,iv_name          => gv_msg_xxcmn10135);
        RAISE global_api_expt;
--
      -- 正常終了の場合
      ELSE
        COMMIT;
      END IF;
--
    END LOOP target_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END submit_request_40a;
--
  /**********************************************************************************
   * Procedure Name   : status_check
   * Description      : コンカレント終了ステータスチェック(M-4)
   ***********************************************************************************/
  PROCEDURE status_check
    (
      ov_errbuf     OUT VARCHAR2                  --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_check'; -- プログラム名
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
    lv_phase         VARCHAR2(100);
    lv_status        VARCHAR2(100);
    lv_dev_phase     VARCHAR2(100);
    lv_dev_status    VARCHAR2(100);
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
    <<status_check_loop>>
    FOR ln_cnt IN 1 .. gr_request_id_tbl.COUNT LOOP
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
             REQUEST_ID => gr_request_id_tbl(ln_cnt)
            ,INTERVAL   => 1
            ,MAX_WAIT   => 0
            ,PHASE      => lv_phase
            ,STATUS     => lv_status
            ,DEV_PHASE  => lv_dev_phase
            ,DEV_STATUS => lv_dev_status
            ,MESSAGE    => lv_errbuf
            ) ) THEN
        -- ステータス反映
        -- フェーズ:完了
        IF ( lv_dev_phase = gv_conc_p_c ) THEN
          -- ステータス:異常
          IF ( lv_dev_status = gv_conc_s_e ) THEN
            lv_errmsg  :=               gv_msg_yyyymm       || gv_msg_part || gr_param.yyyymm             -- 対象年月
                       || gv_msg_pnt || gv_msg_sales_branch || gv_msg_part || gr_sales_branch_tbl(ln_cnt) -- 管轄拠点
                       || gv_msg_pnt || gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- 要求ID
                       || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_error                -- 処理結果
                       ;
            gn_error_cnt := gn_error_cnt + 1;
--
          -- ステータス:警告
          ELSIF ( lv_dev_status = gv_conc_s_w ) THEN
            lv_errmsg  :=               gv_msg_yyyymm       || gv_msg_part || gr_param.yyyymm             -- 対象年月
                       || gv_msg_pnt || gv_msg_sales_branch || gv_msg_part || gr_sales_branch_tbl(ln_cnt) -- 管轄拠点
                       || gv_msg_pnt || gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- 要求ID
                       || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_warn                 -- 処理結果
                       ;
            gn_warn_cnt := gn_warn_cnt + 1;
--
          -- ステータス:正常
          ELSE
            lv_errmsg  :=               gv_msg_yyyymm       || gv_msg_part || gr_param.yyyymm             -- 対象年月
                       || gv_msg_pnt || gv_msg_sales_branch || gv_msg_part || gr_sales_branch_tbl(ln_cnt) -- 管轄拠点
                       || gv_msg_pnt || gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- 要求ID
                       || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_normal               -- 処理結果
                       ;
            gn_normal_cnt := gn_normal_cnt + 1;
          END IF;
        END IF;
--
      ELSE
        lv_errmsg  :=               gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- 要求ID
                   || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_error                -- 処理結果
                   ;
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    END LOOP status_check_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END status_check;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_yyyymm   IN   VARCHAR2     --  01.対象年月
     ,iv_base     IN   VARCHAR2     --  02.管轄拠点
     ,ov_errbuf   OUT  VARCHAR2     --  エラー・メッセージ           --# 固定 #
     ,ov_retcode  OUT  VARCHAR2     --  リターン・コード             --# 固定 #
     ,ov_errmsg   OUT  VARCHAR2     --  ユーザー・エラー・メッセージ --# 固定 #
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
    cv_param_1    CONSTANT VARCHAR2(100) := '1';
--
    -- *** ローカル変数 ***
    ln_loop_cnt      NUMBER := 0;      -- ループカウント
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;   -- 対象件数
    gn_normal_cnt := 0;   -- 正常件数
    gn_warn_cnt   := 0;   -- 警告件数
    gn_error_cnt  := 0;   -- エラー件数
--
    -- ===============================================
    -- パラメータ格納
    -- ===============================================
    gr_param.yyyymm  := iv_yyyymm;    -- 対象年月
    gr_param.base    := iv_base;      -- 管轄拠点
--
    gd_sysdate       := TRUNC( SYSDATE );
--
    -- ===============================================
    -- 入力パラメータ出力
    -- ===============================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 入力パラメータ「対象年月」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh
                                         , gv_msg_xxwsh11007
                                         , gv_tkn_yymm
                                         , gr_param.yyyymm);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「管轄拠点」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh
                                         , gv_msg_xxwsh11008
                                         , gv_tkn_kyoten
                                         , gr_param.base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- =====================================================
    --  入力パラメータチェック(M-1)
    -- =====================================================
    parameter_check
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  処理対象拠点取得(M-2)
    -- =====================================================
    get_target_sales_branch
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    -- 異常終了の場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 対象データなしの場合
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE no_target_expt;
    END IF;
--
    -- =====================================================
    --  子コンカレント呼出処理(M-3)
    -- =====================================================
    submit_request_40a
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  コンカレント終了ステータスチェック(M-4)
    -- =====================================================
    status_check
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 子コンカレント実行でエラー終了がある場合
    IF (gn_error_cnt <> 0) THEN
      ov_retcode := gv_status_error;
--
    -- 子コンカレント実行で警告終了がある場合
    ELSIF (gn_warn_cnt <> 0) THEN
      ov_retcode := gv_status_warn;
--
    -- 子コンカレント実行がすべて正常終了の場合
    ELSE
      ov_retcode := gv_status_normal;
    END IF;
--
  EXCEPTION
    WHEN no_target_expt THEN -- 対象データなし
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := gv_status_warn;
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
    errbuf     OUT    VARCHAR2     --  エラー・メッセージ  --# 固定 #
   ,retcode    OUT    VARCHAR2     --  リターン・コード    --# 固定 #
   ,iv_yyyymm  IN     VARCHAR2     --  01.対象年月
   ,iv_base    IN     VARCHAR2     --  02.管轄拠点
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
    ln_deliver_from_id   NUMBER; -- 出庫元
    ln_deliver_type      NUMBER; -- 出庫形態
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain
      (
        iv_yyyymm   => iv_yyyymm   -- 01.対象年月
       ,iv_base     => iv_base     -- 02.管轄拠点
       ,ov_errbuf   => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      IF ( lv_errmsg IS NULL ) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00008', 'CNT', TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00009', 'CNT', TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00010', 'CNT', TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    --gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00011', 'CNT', TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'警告件数： ' || TO_CHAR(gn_warn_cnt) || ' 件');
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00012','STATUS',gv_conc_status);
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
END XXWSH400012C;
/
