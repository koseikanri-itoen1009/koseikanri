CREATE OR REPLACE PACKAGE BODY XXCMN960017C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2013. All rights reserved.
 *
 * Package Name     : XXCMN960017C(body)
 * Description      : OPM手持在庫パージ
 * MD.050           : T_MD050_BPO_96O_OPM手持在庫パージリカバリ
 * Version          : 1.00
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
 *  2013/04/08   1.00  D.Sugahara       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal     CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn       CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error      CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
--
  --=============
  --メッセージ
  --=============
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part          CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont          CONSTANT VARCHAR2(3)  := '.';
  cv_msg_slash         CONSTANT VARCHAR2(3)  := '/';
--
  --XXCMN:パージ/バックアップ分割コミット数
  cv_xxcmn_commit_range     
                       CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_normal_cnt_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';        --正常件数メッセージ
  cv_error_rec_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';        --エラー件数メッセージ
--
  cv_get_profile_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';        --ﾌﾟﾛﾌｧｲﾙ値取得失敗
  cv_token_profile     CONSTANT VARCHAR2(50) := 'NG_PROFILE';             --ﾌﾟﾛﾌｧｲﾙ取得MSG用ﾄｰｸﾝ名
--
  --TBL_NAME SHORI 件数： CNT 件
  cv_cnt_token         CONSTANT VARCHAR2(10) := 'CNT';
--
  --SHORI 処理に失敗しました。【 KINOUMEI 】 KEYNAME1 ： KEY1 , KEYNAME2 ： KEY2 , 
  --                                         KEYNAME3 ： KEY3 , KEYNAME4 ： KEY4
  cv_others_err_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11041';
  cv_token_shori       CONSTANT VARCHAR2(10) := 'SHORI';
  cv_token_kinou       CONSTANT VARCHAR2(10) := 'KINOUMEI';
  cv_token_key_name1   CONSTANT VARCHAR2(10) := 'KEYNAME1';
  cv_token_key_name2   CONSTANT VARCHAR2(10) := 'KEYNAME2';
  cv_token_key_name3   CONSTANT VARCHAR2(10) := 'KEYNAME3';
  cv_token_key_name4   CONSTANT VARCHAR2(10) := 'KEYNAME4';
  cv_token_key1        CONSTANT VARCHAR2(10) := 'KEY1';
  cv_token_key2        CONSTANT VARCHAR2(10) := 'KEY2';
  cv_token_key3        CONSTANT VARCHAR2(10) := 'KEY3';
  cv_token_key4        CONSTANT VARCHAR2(10) := 'KEY4';
  cv_shori             CONSTANT VARCHAR2(50) := 'リカバリ';
  cv_kinou             CONSTANT VARCHAR2(90) := 'OPM手持在庫パージリカバリ';
  cv_key_name1         CONSTANT VARCHAR2(50) := '品目ID';
  cv_key_name2         CONSTANT VARCHAR2(50) := '倉庫コード';
  cv_key_name3         CONSTANT VARCHAR2(50) := 'ロットID';
  cv_key_name4         CONSTANT VARCHAR2(50) := '保管場所';
--
  --API_NAME APIでエラーが発生しました。
  cv_api_err_msg       CONSTANT VARCHAR2(50) := 'APP-XXCMN-10018';
  cv_token_api         CONSTANT VARCHAR2(10) := 'API_NAME';
  cv_api_name          CONSTANT VARCHAR2(50) := 'GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV';
--
  cv_tbl_name          CONSTANT VARCHAR2(50) := 'XXCMN.XXCMN_IC_LOCT_INV_ARC';
  cv_0                 CONSTANT VARCHAR2(1)  :=  '0';
  cv_9                 CONSTANT VARCHAR2(1)  :=  '9';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg           VARCHAR2(2000);
  gn_normal_cnt        NUMBER;                                            --正常件数
  gn_error_cnt         NUMBER;                                            --エラー件数
  gn_restore_cnt       NUMBER;                                            --リストア件数
  gn_rst_cnt_all       NUMBER;                                            --リストア全件数
--
  gt_item_id           ic_loct_inv.item_id%TYPE;                          --品目ID
  gt_whse_code         ic_loct_inv.whse_code%TYPE;                        --倉庫コード
  gt_lot_id            ic_loct_inv.lot_id%TYPE;                           --ロットID
  gt_location          ic_loct_inv.location%TYPE;                         --保管場所
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
  local_process_expt        EXCEPTION;
  local_api_others_expt     EXCEPTION;
  not_init_collection_expt  EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_init_collection_expt, -6531);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960017C'; -- パッケージ名
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
--
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
    ln_rst_cnt_yet            NUMBER;                           --未コミットリストア件数
    ln_commit_range           NUMBER;                           --分割コミット数
    lv_process_part           VARCHAR2(1000);                   --処理部
    lb_ret_code               BOOLEAN;
--
    lt_item_id                ic_loct_inv.item_id%TYPE;
    lt_lot_id                 ic_loct_inv.lot_id%TYPE;
    lt_whse_code              ic_loct_inv.whse_code%TYPE;
    lt_location               ic_loct_inv.location%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    CURSOR OPM手持在庫リカバリデータ取得
    IS
    SELECT 
            OPM手持在庫バックアップ.全カラム
    FROM    OPM手持在庫バックアップ
    WHERE 
      NOT EXISTS
           (-- OPM手持在庫に存在しない
            SELECT 'X'
            FROM   OPM手持在庫
            WHERE  OPM手持在庫.品目ID       = OPM手持在庫バックアップ.品目ID
            AND    OPM手持在庫.ロットID     = OPM手持在庫バックアップ.ロットID
            AND    OPM手持在庫.倉庫コード   = OPM手持在庫バックアップ.倉庫コード
            AND    OPM手持在庫.ロケーション = OPM手持在庫.ロケーション
            AND    ROWNUM = 1
           )
      ;
    */
    CURSOR recover_data_cur
    IS
      SELECT  /*+ INDEX(xili XXCMN_IC_LOCT_INV_ARC_N1) */
        xili.item_id                 AS  item_id,
        xili.whse_code               AS  whse_code,
        xili.lot_id                  AS  lot_id,
        xili.location                AS  location,
        xili.loct_onhand             AS  loct_onhand,
        xili.loct_onhand2            AS  loct_onhand2,
        xili.lot_status              AS  lot_status,
        xili.qchold_res_code         AS  qchold_res_code,
        xili.delete_mark             AS  delete_mark,
        xili.text_code               AS  text_code,
        xili.last_updated_by         AS  last_updated_by,
        xili.created_by              AS  created_by,
        xili.last_update_date        AS  last_update_date,
        xili.creation_date           AS  creation_date,
        xili.last_update_login       AS  last_update_login,
        xili.program_application_id  AS  program_application_id,
        xili.program_id              AS  program_id,
        xili.program_update_date     AS  program_update_date,
        xili.request_id              AS  request_id
      FROM  xxcmn_ic_loct_inv_arc    xili                        --OPM手持在庫バックアップ
      WHERE NOT EXISTS
              (SELECT /*+ INDEX(ili IC_LOCT_INV_PK ) */
                     'X'
               FROM  ic_loct_inv        ili       --OPM手持在庫
               WHERE ili.item_id       = xili.item_id
               AND   ili.lot_id        = xili.lot_id
               AND   ili.whse_code     = xili.whse_code
               AND   ili.location      = xili.location
               AND   ROWNUM = 1
              )
      ;
--
    -- <カーソル名>レコード型
    TYPE lt_loct_inv_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv_tab      lt_loct_inv_ttype;                  --OPM手持在庫（コミット件数分）
--
    TYPE lt_loct_inv2_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv2_tab      lt_loct_inv2_ttype;                --OPM手持在庫（全件分）
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
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_restore_cnt    := 0;
    gn_rst_cnt_all    := 0;
    ln_rst_cnt_yet    := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    lv_process_part   := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）：';
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ分割コミット数);
    */
    ln_commit_range   := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
--
    /* ln_分割コミット数がNULLの場合
         ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                     iv_アプリケーション短縮名  => cv_appl_short_name
                    ,iv_メッセージコード        => cv_get_profile_msg
                    ,iv_トークン名1             => cv_token_profile
                    ,iv_トークン値1             => cv_xxcmn_commit_range
                   );
         ov_リターンコード := cv_status_error;
         RAISE local_process_expt 例外処理
    */
    IF ( ln_commit_range IS NULL ) THEN
--
      -- プロファイル[ NG_PROFILE ]の取得に失敗しました。
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_commit_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- OPM手持在庫テーブル リストア処理
    -- ===============================================
    lv_process_part := 'OPM手持在庫テーブル リストア処理：';
--
    /*
    lt_OPM手持在庫トランザクションテーブル.DELETE;
    */
    l_loct_inv_tab.DELETE;
--
    /*
    OPEN recover_data_cur LOOP;
    FETCH rst_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
    l_loct_inv2_tab.COUNT  > 0 の場合
      gn_リストア処理対象件数 := l_loct_inv2_tab.COUNT;
    */
    OPEN recover_data_cur;
    FETCH recover_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
      IF ( l_loct_inv2_tab.COUNT ) > 0 THEN
--
        gn_rst_cnt_all := l_loct_inv2_tab.COUNT;
--
        /*
        FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
        LOOP
        */
        << loctinv_recov_loop >>
        FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
        LOOP
--
          /*
          gt_対象OPM手持在庫トランザクション品目ID      := l_loct_inv2_tab.品目ID;  
          gt_対象OPM手持在庫トランザクション倉庫コード  := l_loct_inv2_tab.倉庫コード;
          gt_対象OPM手持在庫トランザクションロットID    := l_loct_inv2_tab.ロットID;
          gt_対象OPM手持在庫トランザクション保管場所    := l_loct_inv2_tab.保管場所;
          */
          gt_item_id   := l_loct_inv2_tab(ln_idx).item_id;  
          gt_whse_code := l_loct_inv2_tab(ln_idx).whse_code;
          gt_lot_id    := l_loct_inv2_tab(ln_idx).lot_id;
          gt_location  := l_loct_inv2_tab(ln_idx).location;
--
          -- ===============================================
          -- 分割コミット(OPM手持在庫トランザクション)
          -- ===============================================
          /*
          NVL(ln_分割コミット数, 0) <> 0の場合
          */
          IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
            /*
            ln_未コミットリストア件数(OPM手持在庫トランザクション) > 0 かつ 
            MOD(ln_未コミットリストア件数(OPM手持在庫トランザクション), ln_分割コミット数) = 0
            の場合
            */
            IF (  (ln_rst_cnt_yet > 0)
              AND (MOD(ln_rst_cnt_yet, ln_commit_range) = 0)
               )
            THEN
--
              /*
              FOR ln_idx1 IN 1..ln_未コミットリストア件数(OPM手持在庫トランザクション)
              */
--
              FOR ln_idx1 IN 1..ln_rst_cnt_yet LOOP
--
                -- IC_LOCT_INV 登録処理
                /*
                lb_ret_code = GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV(l_loct_inv_tab(ln_idx1));
                */
                lb_ret_code := GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV(l_loct_inv_tab(ln_idx1));
--
                /*
                IF (lb_ret_code = FALSE ) THEN
                  ov_errmsg := xxcmn_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err_msg
                    ,iv_token_name1  => cv_token_api
                    ,iv_token_value1 => cv_api_name
                  );
--                  ov_retcode := cv_status_error;
                  RAISE local_api_others_expt;
                END IF;
                */
                IF (lb_ret_code = FALSE ) THEN
--
                  --API_NAME APIでエラーが発生しました。
                  ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err_msg
                    ,iv_token_name1  => cv_token_api
                    ,iv_token_value1 => cv_api_name
                   );
--
                  ov_retcode := cv_status_error;
                  RAISE local_api_others_expt;
                END IF;
--
                -- ==========================================================
                -- OPM手持在庫テーブルロック（更新用）
                -- ==========================================================
                /*
                SELECT OPM手持在庫トランザクション.品目ID,
                  OPM手持在庫トランザクション.ロットID,
                  OPM手持在庫トランザクション.倉庫コード,
                  OPM手持在庫トランザクション.保管場所
                INTO lt_品目ID,
                  lt_ロットID,
                  lt_倉庫コード,
                  lt_保管場所
                FROM   OPM手持在庫トランザクション
                WHERE  品目ID         = l_loct_inv_tab(ln_idx1).品目ID
                AND    ロットID       = l_loct_inv_tab(ln_idx1).ロットID
                AND    倉庫コード     = l_loct_inv_tab(ln_idx1).倉庫コード
                AND    保管場所       = l_loct_inv_tab(ln_idx1).保管場所
                FOR UPDATE NOWAIT;
                */
--
                SELECT /*+ INDEX(ili IC_LOCT_INV_PK ) */
                   ili.item_id      AS  item_id,
                   ili.lot_id       AS  lot_id,
                   ili.whse_code    AS  whse_code,
                   ili.location     AS  location
                INTO   lt_item_id,
                   lt_lot_id,
                   lt_whse_code,
                   lt_location
                FROM   ic_loct_inv      ili
                WHERE  ili.item_id    = l_loct_inv_tab(ln_idx1).item_id
                AND    ili.lot_id     = l_loct_inv_tab(ln_idx1).lot_id
                AND    ili.whse_code  = l_loct_inv_tab(ln_idx1).whse_code
                AND    ili.location   = l_loct_inv_tab(ln_idx1).location
                FOR UPDATE NOWAIT;
--
                ----------------------------------
                -- APIで登録されないないWHOカラム更新
                ----------------------------------
                /*
                UPDATE OPM手持在庫トランザクションバックアップ
                SET    最終更新ログイン = l_loct_inv_tab(ln_idx1).最終更新ログイン,
                       プログラムアプリケーションID
                                        = l_loct_inv_tab(ln_idx1).プログラムアプリケーションID,
                       コンカレントプログラムID 
                                        = l_loct_inv_tab(ln_idx1).コンカレントプログラムID
                       プログラム更新日 = l_loct_inv_tab(ln_idx1).プログラム更新日
                       要求ID           = l_loct_inv_tab(ln_idx1).要求ID
                WHERE  品目ID           = l_loct_inv_tab(ln_idx1).品目ID
                AND    ロットID         = l_loct_inv_tab(ln_idx1).ロットID
                AND    倉庫コード       = l_loct_inv_tab(ln_idx1).倉庫コード
                AND    保管場所         = l_loct_inv_tab(ln_idx1).保管場所
                );
                */
                UPDATE ic_loct_inv
                SET  last_update_login      = l_loct_inv_tab(ln_idx1).last_update_login,
                     program_application_id = l_loct_inv_tab(ln_idx1).program_application_id,
                     program_id             = l_loct_inv_tab(ln_idx1).program_id,
                     program_update_date    = l_loct_inv_tab(ln_idx1).program_update_date,
                     request_id             = l_loct_inv_tab(ln_idx1).request_id
                WHERE  item_id                = l_loct_inv_tab(ln_idx1).item_id
                AND    lot_id                 = l_loct_inv_tab(ln_idx1).lot_id 
                AND    whse_code              = l_loct_inv_tab(ln_idx1).whse_code 
                AND    location               = l_loct_inv_tab(ln_idx1).location
                ;
--
              END LOOP;
--
              /*
              COMMIT;
              */
              COMMIT;
--
              /*
              gn_リストア件数（OPM手持在庫トランザクション) := 
                                gn_リストア件数（OPM手持在庫トランザクション) + 
                                ln_未コミットリストア件数(OPM手持在庫トランザクション);
              ln_未コミットリストア件数(OPM手持在庫トランザクション) := 0;
              lt_OPM手持在庫トランザクションテーブル.DELETE;
              */
              gn_restore_cnt := NVL( gn_restore_cnt ,0 ) + NVL( ln_rst_cnt_yet ,0 );
              ln_rst_cnt_yet := 0;
              l_loct_inv_tab.DELETE;
--
            END IF;
--
          END IF;
--
          /*
          ln_未コミットリストア件数(OPM手持在庫トランザクション) :=  
                                    ln_未コミットリストア件数(OPM手持在庫トランザクション) + 1;
          */
          ln_rst_cnt_yet := NVL( ln_rst_cnt_yet,0 ) + 1;
--
          /*
          lt_OPM手持在庫トランザクションテーブル(gn_未コミットバックアップ件数 
                           (OPM手持在庫トランザクション) := l_loct_inv2_tab(ln_idx).全カラム;
          */
          l_loct_inv_tab(ln_rst_cnt_yet).item_id         := l_loct_inv2_tab(ln_idx).item_id;
          l_loct_inv_tab(ln_rst_cnt_yet).whse_code       := l_loct_inv2_tab(ln_idx).whse_code;
          l_loct_inv_tab(ln_rst_cnt_yet).lot_id          := l_loct_inv2_tab(ln_idx).lot_id;
          l_loct_inv_tab(ln_rst_cnt_yet).location        := l_loct_inv2_tab(ln_idx).location;
          l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand     := l_loct_inv2_tab(ln_idx).loct_onhand;
          l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand2    := l_loct_inv2_tab(ln_idx).loct_onhand2;
          l_loct_inv_tab(ln_rst_cnt_yet).lot_status      := l_loct_inv2_tab(ln_idx).lot_status;
          l_loct_inv_tab(ln_rst_cnt_yet).qchold_res_code := l_loct_inv2_tab(ln_idx).qchold_res_code;
          l_loct_inv_tab(ln_rst_cnt_yet).delete_mark     := l_loct_inv2_tab(ln_idx).delete_mark;
          l_loct_inv_tab(ln_rst_cnt_yet).text_code       := l_loct_inv2_tab(ln_idx).text_code;
          l_loct_inv_tab(ln_rst_cnt_yet).last_updated_by := l_loct_inv2_tab(ln_idx).last_updated_by;
          l_loct_inv_tab(ln_rst_cnt_yet).created_by      := l_loct_inv2_tab(ln_idx).created_by;
          l_loct_inv_tab(ln_rst_cnt_yet).last_update_date 
                                                         := l_loct_inv2_tab(ln_idx).last_update_date;
          l_loct_inv_tab(ln_rst_cnt_yet).creation_date   := l_loct_inv2_tab(ln_idx).creation_date;
          l_loct_inv_tab(ln_rst_cnt_yet).last_update_login 
                                                         := l_loct_inv2_tab(ln_idx).last_update_login;
          l_loct_inv_tab(ln_rst_cnt_yet).program_application_id
                                                         := l_loct_inv2_tab(ln_idx).program_application_id;
          l_loct_inv_tab(ln_rst_cnt_yet).program_id      := l_loct_inv2_tab(ln_idx).program_id;
          l_loct_inv_tab(ln_rst_cnt_yet).program_update_date     
                                                         := l_loct_inv2_tab(ln_idx).program_update_date;
          l_loct_inv_tab(ln_rst_cnt_yet).request_id      := l_loct_inv2_tab(ln_idx).request_id;
--
        END LOOP loctinv_recov_loop;
--
      END IF;
--
    CLOSE recover_data_cur;
--
    /*
    FOR ln_idx1 IN 1..ln_未コミットリストア件数(OPM手持在庫トランザクション)
    */
--
    FOR ln_idx1 IN 1..ln_rst_cnt_yet LOOP
--
      -- IC_LOCT_INV 登録処理
      lb_ret_code := GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV(l_loct_inv_tab(ln_idx1));
--
      /*
      IF (lb_ret_code = FALSE ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
             iv_application  => cv_appl_short_name
            ,iv_name         => cv_api_err_msg
            ,iv_token_name1  => cv_token_api
            ,iv_token_value1 => cv_api_name
            );
--
        ov_retcode := cv_status_error;
        RAISE local_api_others_expt;
      END IF;
      */
      IF (lb_ret_code = FALSE ) THEN
        --API_NAME APIでエラーが発生しました。
        ov_errmsg := xxcmn_common_pkg.get_msg(
           iv_application  => cv_appl_short_name
          ,iv_name         => cv_api_err_msg
          ,iv_token_name1  => cv_token_api
          ,iv_token_value1 => cv_api_name
          );
--
        ov_retcode := cv_status_error;
        RAISE local_api_others_expt;
--
      END IF;
--
      -- ==========================================================
      -- OPM手持在庫トランザクションロック（更新用）
      -- ==========================================================
      /*
      SELECT OPM手持在庫トランザクション.品目ID,
             OPM手持在庫トランザクション.ロットID,
             OPM手持在庫トランザクション.倉庫コード,
             OPM手持在庫トランザクション.保管場所
      INTO   lt_品目ID,
             lt_ロットID,
             lt_倉庫コード,
             lt_保管場所
      FROM   OPM手持在庫トランザクション
      WHERE  品目ID           = l_loct_inv_tab(ln_idx1).品目ID
      AND    ロットID         = l_loct_inv_tab(ln_idx1).ロットID
      AND    倉庫コード       = l_loct_inv_tab(ln_idx1).倉庫コード
      AND    保管場所         = l_loct_inv_tab(ln_idx1).保管場所
      FOR UPDATE NOWAIT;
      */
--
      SELECT ili.item_id      AS  item_id,
             ili.lot_id       AS  lot_id,
             ili.whse_code    AS  whse_code,
             ili.location     AS  location
      INTO   lt_item_id,
             lt_lot_id,
             lt_whse_code,
             lt_location
      FROM   ic_loct_inv        ili
      WHERE  ili.item_id      = l_loct_inv_tab(ln_idx1).item_id
      AND    ili.lot_id       = l_loct_inv_tab(ln_idx1).lot_id
      AND    ili.whse_code    = l_loct_inv_tab(ln_idx1).whse_code
      AND    ili.location     = l_loct_inv_tab(ln_idx1).location
      FOR UPDATE NOWAIT;
--
      ----------------------------------
      -- APIで登録しないWHOカラム更新
      ----------------------------------
      /*
      UPDATE OPM手持在庫トランザクションバックアップ
      SET    最終更新ログイン = l_loct_inv_tab(ln_idx1).最終更新ログイン,
             プログラムアプリケーションID
                              = l_loct_inv_tab(ln_idx1).プログラムアプリケーションID,
             コンカレントプログラムID 
                              = l_loct_inv_tab(ln_idx1).コンカレントプログラムID
             プログラム更新日 = l_loct_inv_tab(ln_idx1).プログラム更新日
             要求ID           = l_loct_inv_tab(ln_idx1).要求ID
      WHERE  品目ID           = l_loct_inv_tab(ln_idx1).品目ID
      AND    ロットID         = l_loct_inv_tab(ln_idx1).ロットID
      AND    倉庫コード       = l_loct_inv_tab(ln_idx1).倉庫コード
      AND    保管場所         = l_loct_inv_tab(ln_idx1).保管場所
      );
      */
      UPDATE ic_loct_inv
      SET    last_update_login      = l_loct_inv_tab(ln_idx1).last_update_login,
             program_application_id = l_loct_inv_tab(ln_idx1).program_application_id,
             program_id             = l_loct_inv_tab(ln_idx1).program_id,
             program_update_date    = l_loct_inv_tab(ln_idx1).program_update_date,
             request_id             = l_loct_inv_tab(ln_idx1).request_id
      WHERE  item_id                = l_loct_inv_tab(ln_idx1).item_id
      AND    lot_id                 = l_loct_inv_tab(ln_idx1).lot_id 
      AND    whse_code              = l_loct_inv_tab(ln_idx1).whse_code 
      AND    location               = l_loct_inv_tab(ln_idx1).location
      ;
--
    END LOOP;
--
    /*
    gn_リストア件数（OPM手持在庫トランザクション) := 
                                gn_リストア件数（OPM手持在庫トランザクション) + 
                                ln_未コミットリストア件数(OPM手持在庫トランザクション);
    ln_未コミットリストア件数(OPM手持在庫トランザクション) := 0;
    lt_OPM手持在庫トランザクションテーブル.DELETE;
    */
    gn_restore_cnt := NVL( gn_restore_cnt, 0 ) + NVL( ln_rst_cnt_yet ,0 );
    ln_rst_cnt_yet := 0;
    l_loct_inv_tab.DELETE;    
--
  -- ===============================================
  -- 例外処理
  -- ===============================================
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN local_process_expt    THEN
         NULL;
--
    WHEN local_api_others_expt THEN
         NULL;
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
--
      BEGIN
        IF ( SQL%BULK_EXCEPTIONS.COUNT > 0 ) THEN
--
          IF ( l_loct_inv_tab.COUNT > 0 ) THEN
--
            gt_item_id   := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).item_id;
            gt_whse_code := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).whse_code;
            gt_lot_id    := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).lot_id;
            gt_location  := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).location;
--
            --パージ処理に失敗しました。【OPM手持在庫パージリカバリ】品目ID ： KEY1 , 
            --倉庫コード ： KEY2 , ロットID ： KEY3 , 保管場所 ： KEY4
            ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                       ,iv_name          => cv_others_err_msg
--
                       ,iv_token_name1   => cv_token_shori
                       ,iv_token_value1  => TO_CHAR(cv_shori)
--
                       ,iv_token_name2   => cv_token_kinou
                       ,iv_token_value2  => TO_CHAR(cv_kinou)
--
                       ,iv_token_name3   => cv_token_key_name1   --品目ID
                       ,iv_token_value3  => TO_CHAR(cv_key_name1)
                       ,iv_token_name4   => cv_token_key1
                       ,iv_token_value4  => TO_CHAR(gt_item_id)
--
                       ,iv_token_name5   => cv_token_key_name2   --倉庫コード
                       ,iv_token_value5  => TO_CHAR(cv_key_name2)
                       ,iv_token_name6   => cv_token_key2
                       ,iv_token_value6  => gt_whse_code
--
                       ,iv_token_name7   => cv_token_key_name3   --ロットID
                       ,iv_token_value7  => TO_CHAR(cv_key_name3)
                       ,iv_token_name8   => cv_token_key3
                       ,iv_token_value8  => TO_CHAR(gt_lot_id)
--
                       ,iv_token_name9   => cv_token_key_name4   --保管場所
                       ,iv_token_value9  => TO_CHAR(cv_key_name4)
                       ,iv_token_name10  => cv_token_key4
                       ,iv_token_value10 => gt_location
                      );
          END IF;
--
        END IF;
--
      EXCEPTION
        WHEN not_init_collection_expt THEN
          NULL;
      END;
--
      IF ( (ov_errmsg    IS NULL)     AND (gt_item_id IS NOT NULL) AND
           (gt_whse_code IS NOT NULL) AND (gt_lot_id  IS NOT NULL) AND
           (gt_location  IS NOT NULL)
      ) THEN
            --パージ処理に失敗しました。【OPM手持在庫パージリカバリ】品目ID ： KEY1 ,
            --倉庫コード ： KEY2 , ロットID ： KEY3 , 保管場所 ： KEY4
            ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                       ,iv_name          => cv_others_err_msg
--
                       ,iv_token_name1   => cv_token_shori
                       ,iv_token_value1  => TO_CHAR(cv_shori)
--
                       ,iv_token_name2   => cv_token_kinou
                       ,iv_token_value2  => TO_CHAR(cv_kinou)
--
                       ,iv_token_name3   => cv_token_key_name1   --品目ID
                       ,iv_token_value3  => TO_CHAR(cv_key_name1)
                       ,iv_token_name4   => cv_token_key1
                       ,iv_token_value4  => TO_CHAR(gt_item_id)
--
                       ,iv_token_name5   => cv_token_key_name2   --倉庫コード
                       ,iv_token_value5  => TO_CHAR(cv_key_name2)
                       ,iv_token_name6   => cv_token_key2
                       ,iv_token_value6  => gt_whse_code
--
                       ,iv_token_name7   => cv_token_key_name3   --ロットID
                       ,iv_token_value7  => TO_CHAR(cv_key_name3)
                       ,iv_token_name8   => cv_token_key3
                       ,iv_token_value8  => TO_CHAR(gt_lot_id)
--
                       ,iv_token_name9   => cv_token_key_name4   --保管場所
                       ,iv_token_value9  => TO_CHAR(cv_key_name4)
                       ,iv_token_name10  => cv_token_key4
                       ,iv_token_value10 => gt_location
                      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||SQLERRM;
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
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    lv_nengetu         VARCHAR2(50);
    --
  BEGIN
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
       lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- ログ出力処理
    -- ===============================================
    -- エラー件数出力(エラー件数： CNT 件)
    /*
    エラー件数取得
    gn_エラー件数(OPM手持在庫トランザクション) := 
                                       gn_リストア処理対象件数(OPM手持在庫トランザクション) - 
                                       gn_リストア件数(OPM手持在庫トランザクション);
    */
    IF (lv_retcode = cv_status_error  AND gn_rst_cnt_all - gn_restore_cnt = 0) THEN
      gn_error_cnt  := 1;
    ELSE
      gn_error_cnt  := gn_rst_cnt_all - gn_restore_cnt;
    END IF;
--
    /*
    正常件数取得
    gn_正常件数(OPM手持在庫トランザクション) := gn_リストア件数(OPM手持在庫トランザクション);
    */
    gn_normal_cnt := gn_restore_cnt;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 正常件数出力(正常件数： CNT 件)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_normal_cnt_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力(エラー件数： CNT 件)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- -----------------------
    --  処理判定(submain)
    -- -----------------------
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力(出力の表示)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --エラーメッセージ
      );
--
    END IF;
--
    -- ===============================================
    -- 終了処理
    -- ===============================================
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  -- ===============================================
  -- 例外処理
  -- ===============================================
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
END XXCMN960017C;
/
