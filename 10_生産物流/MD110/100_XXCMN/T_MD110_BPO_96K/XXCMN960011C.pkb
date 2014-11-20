CREATE OR REPLACE PACKAGE BODY XXCMN960011C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960011C(body)
 * Description      : OPM手持在庫パージ
 * MD.050           : T_MD050_BPO_96K_OPM手持在庫パージ
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
 *  2012/12/06   1.00  T.Makuta          新規作成
 *  2013/01/31   1.1   N.Miyamoto        障害管理票IT_0014対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal     CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn       CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error      CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  cv_date_format       CONSTANT VARCHAR2(6)  := 'YYYYMM';
  cv_purge_type        CONSTANT VARCHAR2(1)  := '0';                      --ﾊﾟｰｼﾞﾀｲﾌﾟ(0:パージ期間)
  cv_purge_code        CONSTANT VARCHAR2(10) := '9701';                   --ﾊﾟｰｼﾞ定義ｺｰﾄﾞ
  cv_app_name          CONSTANT VARCHAR2(10) := 'GMI';
  cv_app_name_xxcmn    CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_gmipebal          CONSTANT VARCHAR2(10) := 'GMIPEBAL';
  cv_description       CONSTANT VARCHAR2(50) := '空残高のパージ';
--
  --=============
  --メッセージ
  --=============
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part          CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont          CONSTANT VARCHAR2(3)  := '.';
  cv_msg_slash         CONSTANT VARCHAR2(3)  := '/';
  cv_conc_p_c          CONSTANT VARCHAR2(20) := 'COMPLETE';
  cv_conc_s_n          CONSTANT VARCHAR2(20) := 'NORMAL';
  cv_conc_s_w          CONSTANT VARCHAR2(20) := 'WARNING';
  cv_conc_s_e          CONSTANT VARCHAR2(20) := 'ERROR';
  cv_conc_s_c          CONSTANT VARCHAR2(20) := 'CANCELLED';
  cv_conc_s_t          CONSTANT VARCHAR2(20) := 'TERMINATED';
--
  --XXCMN:パージ/バックアップ分割コミット数
  cv_xxcmn_commit_range     
                       CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_normal_cnt_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';        --正常件数メッセージ
  cv_error_rec_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';        --エラー件数メッセージ
--
  cv_proc_date_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-11043';        --処理年月出力
  cv_nengetu_token     CONSTANT VARCHAR2(10) := 'NENGETU';                --処理年月MSG用ﾄｰｸﾝ名
--
  cv_get_profile_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';        --ﾌﾟﾛﾌｧｲﾙ値取得失敗
  cv_token_profile     CONSTANT VARCHAR2(50) := 'NG_PROFILE';             --ﾌﾟﾛﾌｧｲﾙ取得MSG用ﾄｰｸﾝ名
--
  cv_get_priod_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-11011';        --パージ期間取得失敗
--
  cv_conc_err          CONSTANT VARCHAR2(50) := 'APP-XXCMN-10135';        --要求の発行失敗エラー
--
  cv_request_err_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11020';
  cv_request_err_token CONSTANT VARCHAR2(10) := 'REQUEST';
--
  --TBL_NAME SHORI 件数： CNT 件
  cv_end_msg1          CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';        --処理内容出力
  cv_token_tblname     CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname           CONSTANT VARCHAR2(90) := 'OPM手持在庫トランザクション（標準）';
  cv_token_shori_p     CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori_p           CONSTANT VARCHAR2(50) := '削除';
  cv_cnt_token         CONSTANT VARCHAR2(10) := 'CNT';
--
  --空残高のパージ(リクエストID)： REQUEST_ID
  cv_end_msg2          CONSTANT VARCHAR2(50) := 'APP-XXCMN-11042';        --処理内容出力
  cv_req_id            CONSTANT VARCHAR2(10) := 'REQUEST_ID';
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
  cv_shori             CONSTANT VARCHAR2(50) := 'パージ';
  cv_kinou             CONSTANT VARCHAR2(90) := 'OPM手持在庫パージ';
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
  gv_sep_msg           VARCHAR2(2000);
  gv_exec_user         VARCHAR2(100);
  gv_conc_name         VARCHAR2(30);
  gv_conc_status       VARCHAR2(30);
  gn_normal_cnt        NUMBER;                                            --正常件数
  gn_error_cnt         NUMBER;                                            --エラー件数
  gn_del_cnt           NUMBER;                                            --削除件数
  gn_purge_cnt         NUMBER;                                            --空残高のパージ処理件数
  gn_restore_cnt       NUMBER;                                            --リストア件数
  gn_rst_cnt_all       NUMBER;                                            --リストア全件数
--
  gt_shori_ym          xxinv_stc_inventory_month_stck.invent_ym%TYPE;
  gn_request_id        NUMBER;
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960011C'; -- パッケージ名
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
    ln_purge_period           NUMBER;                           --パージ期間
    ln_bkp_cnt                NUMBER;                           --バックアップ処理件数
    ln_arc_cnt_yet            NUMBER;                           --未コミットバックアップ件数
    ln_rst_cnt_yet            NUMBER;                           --未コミットリストア件数
    lv_standard_ym            VARCHAR2(6);                      --処理年月(YYYYMM)
    ln_commit_range           NUMBER;                           --分割コミット数
    lv_process_part           VARCHAR2(1000);                   --処理部
    lb_ret_code               BOOLEAN;
    ln_purge_cnt_b            NUMBER;                           --空残高のパージ（処理前）件数
    ln_purge_cnt_a            NUMBER;                           --空残高のパージ（処理後）件数
--
    lt_item_id                ic_loct_inv.item_id%TYPE;
    lt_lot_id                 ic_loct_inv.lot_id%TYPE;
    lt_whse_code              ic_loct_inv.whse_code%TYPE;
    lt_location               ic_loct_inv.location%TYPE;
--
    --FND_REQUEST.SUBMIT_REQUESTで使用する変数
    lv_phase                  VARCHAR2(100);
    lv_status                 VARCHAR2(100);
    lv_dev_phase              VARCHAR2(100);
    lv_dev_status             VARCHAR2(100);
--
    lv_errbuf_wait            VARCHAR2(5000);
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    CURSOR パージ対象OPM手持在庫トランザクションバックアップ取得
    IS
    SELECT 
            OPM手持在庫トランザクション.全カラム
    FROM    OPM手持在庫トランザクション
    WHERE   OPM手持在庫トランザクション.手持数量 = 0 ;
    */
    CURSOR bkp_data_cur
    IS
      SELECT
        ili.item_id                  AS  item_id,
        ili.whse_code                AS  whse_code,
        ili.lot_id                   AS  lot_id,
        ili.location                 AS  location,
        ili.loct_onhand              AS  loct_onhand,
        ili.loct_onhand2             AS  loct_onhand2,
        ili.lot_status               AS  lot_status,
        ili.qchold_res_code          AS  qchold_res_code,
        ili.delete_mark              AS  delete_mark,
        ili.text_code                AS  text_code,
        ili.last_updated_by          AS  last_updated_by,
        ili.created_by               AS  created_by,
        ili.last_update_date         AS  last_update_date,
        ili.creation_date            AS  creation_date,
        ili.last_update_login        AS  last_update_login,
        ili.program_application_id   AS  program_application_id,
        ili.program_id               AS  program_id,
        ili.program_update_date      AS  program_update_date,
        ili.request_id               AS  request_id
      FROM  ic_loct_inv              ili
      WHERE ili.loct_onhand          =   0;
--
    /*
    CURSOR パージ対象OPM手持在庫トランザクションリストアデータ取得
      it_処理年月  IN 棚卸月末在庫(アドオン).棚卸年月%TYPE
    IS
    SELECT 
            OPM手持在庫トランザクションバックアップ.処理件数
            OPM手持在庫トランザクションバックアップ.全カラム
    FROM    OPM手持在庫トランザクションバックアップ
    WHERE 
      EXISTS
           (-- 棚卸月末在庫に指定した過去のデータが存在する
            SELECT 'X'
            FROM   棚卸月末在庫
            WHERE  棚卸月末在庫.品目ID    = OPM手持在庫トランザクションバックアップ.品目ID
            AND    棚卸月末在庫.ロットID  = OPM手持在庫トランザクションバックアップ.ロットID
            AND    棚卸月末在庫.倉庫コード= OPM手持在庫トランザクションバックアップ.倉庫コード
            AND    棚卸月末在庫(アドオン).棚卸年月 >= it_処理年月
            AND    ROWNUM = 1
           )
      GROUP BY
        OPM手持在庫トランザクションバックアップ.全カラム
      ;
    */
    CURSOR rst_data_cur(
      it_shori_ym  xxinv_stc_inventory_month_stck.invent_ym%TYPE
    )
    IS
-- 2013/01/31 v1.1 UPDATE START
--    SELECT
      SELECT  /*+ INDEX(xili XXCMN_IC_LOCT_INV_ARC_N1) */
-- 2009/01/31 v1.1 UPDATE END
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
      FROM  xxcmn_ic_loct_inv_arc    xili                        --OPM手持在庫ﾄﾗﾝｻﾞｸｼｮﾝﾊﾞｯｸｱｯﾌﾟ
      WHERE EXISTS
-- 2013/01/31 v1.1 UPDATE START
--            (SELECT /*+ INDEX(xsim XXINV_SIMS_N03 ) */
              (SELECT /*+ INDEX(xsim XXINV_SIMS_N01 ) */
-- 2009/01/31 v1.1 UPDATE END
                     'X'
               FROM  xxinv_stc_inventory_month_stck   xsim       --棚卸月末在庫(ｱﾄﾞｵﾝ)
               WHERE xsim.item_id       = xili.item_id
               AND   xsim.lot_id        = xili.lot_id
               AND   xsim.whse_code     = xili.whse_code
               AND   xsim.invent_ym    >= it_shori_ym
               AND   ROWNUM = 1
              )
      ;
--
    -- <カーソル名>レコード型
    TYPE lt_loct_inv_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv_tab      lt_loct_inv_ttype;                      --OPM手持在庫
--
    TYPE lt_loct_inv2_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv2_tab      lt_loct_inv2_ttype;                    --OPM手持在庫
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
    gn_del_cnt        := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gt_shori_ym       := NULL;
    gn_purge_cnt      := 0;
    gn_restore_cnt    := 0;
    gn_rst_cnt_all    := 0;
    ln_arc_cnt_yet    := 0;
    ln_rst_cnt_yet    := 0;
    ln_bkp_cnt        := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- パージ期間取得
    -- ===============================================
   /*
    ln_パージ期間 := バックアップ期間/パージ期間取得関数(cv_パージタイプ,cv_パージコード);
     */
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
--
    /*
    ln_パージ期間がNULLの場合
      ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                            iv_アプリケーション短縮名  => cv_appl_short_name
                           ,iv_メッセージコード        => cv_get_priod_msg
                          );
      ov_リターンコード := cv_status_error;
      RAISE local_process_expt 例外処理
     */
    IF ( ln_purge_period IS NULL ) THEN
--
      --パージ期間の取得に失敗しました。
      ov_errmsg  := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    /*
    -- 処理年月取得
    gt_処理年月 := TO_CHAR(ADD_MONTHS(処理日取得共通関数より取得した処理日,
                                                           (ln_パージ期間 * -1)),'cv_年月');
    */
    gt_shori_ym := TO_CHAR(ADD_MONTHS(xxcmn_common4_pkg.get_syori_date,
                                                       (ln_purge_period * -1)),cv_date_format);
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
    -- バックアップテーブルトランケート
    -- ===============================================
    lv_process_part := 'バックアップテーブルトランケート：';
--
    -- バックアップテーブルトランケート
    /*
    EXECUTE IMMEDIATE 'TRUNCATE TABLE OPM手持在庫トランザクションバックアップ';
    */
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || cv_tbl_name;
--
    -- ===============================================
    -- OPM手持在庫トランザクション バックアップ処理
    -- ===============================================
    lv_process_part := 'OPM手持在庫トランザクション バックアップ処理：';
--
    /*
    FOR lr_loctinv_arc_rec IN パージ対象OPM手持在庫トランザクションバックアップ取得 LOOP
--
      gt_対象OPM手持在庫トランザクション品目ID     := lr_loctinv_arc_rec.品目ID;  
      gt_対象OPM手持在庫トランザクション倉庫コード := lr_loctinv_arc_rec.倉庫コード;
      gt_対象OPM手持在庫トランザクションロットID   := lr_loctinv_arc_rec.ロットID;
      gt_対象OPM手持在庫トランザクション保管場所   := lr_loctinv_arc_rec.保管場所;
    */
    << loctinv_arc_loop >>
    FOR lr_loctinv_arc_rec IN bkp_data_cur LOOP
--
      gt_item_id   := lr_loctinv_arc_rec.item_id;  
      gt_whse_code := lr_loctinv_arc_rec.whse_code;
      gt_lot_id    := lr_loctinv_arc_rec.lot_id;
      gt_location  := lr_loctinv_arc_rec.location;
--
      -- ===============================================
      -- 分割コミット(OPM手持在庫トランザクション)
      -- ===============================================
      /*
      NVL(ln_分割コミット数, 0) <> 0の場合
      */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
          /*
           ln_未コミットバックアップ件数(OPM手持在庫トランザクション) > 0 かつ 
           MOD(ln_未コミットバックアップ件数(OPM手持在庫トランザクション), ln_分割コミット数) = 0
           の場合
          */
        IF (  (ln_arc_cnt_yet > 0)
          AND (MOD(ln_arc_cnt_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数(OPM手持在庫トランザクション)
            INSERT INTO OPM手持在庫トランザクションバックアップ
            (
                全カラム
            )
            VALUES
            (
                lt_OPM手持在庫トランザクションテーブル(ln_idx)全カラム
            );
          COMMIT;
          */
          FORALL ln_idx IN 1..ln_arc_cnt_yet
            INSERT INTO xxcmn_ic_loct_inv_arc VALUES l_loct_inv_tab(ln_idx);
--
          COMMIT;
--
          /*
          ln_バックアップ件数(OPM手持在庫トランザクション) := 
                                        ln_バックアップ件数(OPM手持在庫トランザクション) +
                                        ln_未コミットバックアップ件数(OPM手持在庫トランザクション);
          ln_未コミットバックアップ件数(OPM手持在庫トランザクション) := 0;
          lt_OPM手持在庫トランザクションテーブル.DELETE;
          */
--
          ln_bkp_cnt      := ln_bkp_cnt + ln_arc_cnt_yet;
          ln_arc_cnt_yet  := 0;
          l_loct_inv_tab.DELETE;
--
        END IF;
--
      END IF;
--
      /*
      ln_未コミットバックアップ件数(OPM手持在庫トランザクション) :=  
                            ln_未コミットバックアップ件数(OPM手持在庫トランザクション) + 1;
      */
      ln_arc_cnt_yet  := ln_arc_cnt_yet + 1;
      /*
      lt_OPM手持在庫トランザクションテーブル(
               ln_未コミットバックアップ件数(OPM手持在庫トランザクション) := lr_loctinv_arc_rec;
      */
      l_loct_inv_tab(ln_arc_cnt_yet).item_id           := lr_loctinv_arc_rec.item_id;
      l_loct_inv_tab(ln_arc_cnt_yet).whse_code         := lr_loctinv_arc_rec.whse_code;
      l_loct_inv_tab(ln_arc_cnt_yet).lot_id            := lr_loctinv_arc_rec.lot_id;
      l_loct_inv_tab(ln_arc_cnt_yet).location          := lr_loctinv_arc_rec.location;
      l_loct_inv_tab(ln_arc_cnt_yet).loct_onhand       := lr_loctinv_arc_rec.loct_onhand;
      l_loct_inv_tab(ln_arc_cnt_yet).loct_onhand2      := lr_loctinv_arc_rec.loct_onhand2;
      l_loct_inv_tab(ln_arc_cnt_yet).lot_status        := lr_loctinv_arc_rec.lot_status;
      l_loct_inv_tab(ln_arc_cnt_yet).qchold_res_code   := lr_loctinv_arc_rec.qchold_res_code;
      l_loct_inv_tab(ln_arc_cnt_yet).delete_mark       := lr_loctinv_arc_rec.delete_mark;
      l_loct_inv_tab(ln_arc_cnt_yet).text_code         := lr_loctinv_arc_rec.text_code;
      l_loct_inv_tab(ln_arc_cnt_yet).last_updated_by   := lr_loctinv_arc_rec.last_updated_by;
      l_loct_inv_tab(ln_arc_cnt_yet).created_by        := lr_loctinv_arc_rec.created_by;
      l_loct_inv_tab(ln_arc_cnt_yet).last_update_date  := lr_loctinv_arc_rec.last_update_date;
      l_loct_inv_tab(ln_arc_cnt_yet).creation_date     := lr_loctinv_arc_rec.creation_date;
      l_loct_inv_tab(ln_arc_cnt_yet).last_update_login := lr_loctinv_arc_rec.last_update_login;
      l_loct_inv_tab(ln_arc_cnt_yet).program_application_id
                                                    := lr_loctinv_arc_rec.program_application_id;
      l_loct_inv_tab(ln_arc_cnt_yet).program_id        :=   lr_loctinv_arc_rec.program_id;
      l_loct_inv_tab(ln_arc_cnt_yet).program_update_date     
                                                    := lr_loctinv_arc_rec.program_update_date;
      l_loct_inv_tab(ln_arc_cnt_yet).request_id        := lr_loctinv_arc_rec.request_id;
--
    END LOOP loctinv_arc_loop;
--
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数(OPM手持在庫トランザクション)
      INSERT INTO OPM手持在庫トランザクションバックアップ
      (
       全カラム
      )
      VALUES
      (
       lt_OPM手持在庫トランザクションテーブル(ln_idx)全カラム
      );
    */
    FORALL ln_idx IN 1..ln_arc_cnt_yet
      INSERT INTO xxcmn_ic_loct_inv_arc VALUES l_loct_inv_tab(ln_idx);
--
    /*
    ln_バックアップ件数(OPM手持在庫トランザクション) := 
                                        ln_バックアップ件数(OPM手持在庫トランザクション) +
                                        ln_未コミットバックアップ件数(OPM手持在庫トランザクション);
    ln_未コミットバックアップ件数(OPM手持在庫トランザクション) := 0;
    COMMIT;
    */
    ln_bkp_cnt     := ln_bkp_cnt + ln_arc_cnt_yet;
    ln_arc_cnt_yet := 0;
    COMMIT;
--
    /*
    ln_バックアップ件数(OPM手持在庫トランザクション) <> 0の場合
    */
--
    IF (ln_bkp_cnt <> 0 ) THEN
--
      -- ===============================================
      -- 標準コンカレント(空残高のパージ：GMIPEBAL)
      -- ===============================================
      lv_process_part := '標準コンカレント(空残高のパージ：GMIPEBAL)：';
--
      --コンカレント実施前データ件数カウント
      /*
      SELECT  COUNT(1)
      INTO    ln_空残高のパージ(処理前)件数
      FROM    OPM手持在庫トランザクション; 
      */
--
      SELECT  COUNT(1)  AS cnt
      INTO    ln_purge_cnt_b
      FROM    ic_loct_inv;
--
      /*
      gn_request_id := FND_REQUEST.SUBMIT_REQUEST(
                     application       =>  cv_app_name          --アプリケーション短縮名(GMI)
                    ,program           =>  cv_gmipebal          --プログラム名(GMIPEBAL)
                    ,description       =>  cv_description       --摘要(空残高のパージ)
                    ,start_time        =>  NULL                 --実行日
                    ,sub_request       =>  FALSE
                    ,argument1         =>  NULL                 --品目:自
                    ,argument2         =>  NULL                 --品目:至
                    ,argument3         =>  NULL                 --倉庫:自
                    ,argument4         =>  NULL                 --倉庫:至
                    ,argument5         =>  NULL                 --在庫区分
                    ,argument6         =>  NULL                 --ロット管理品目(0:NO,1:YES)
                    ,argument7         =>  cv_9                 --精度のパージ
                 ) ;
      */
      gn_request_id := FND_REQUEST.SUBMIT_REQUEST(
                     application       =>  cv_app_name          --アプリケーション短縮名(GMI)
                    ,program           =>  cv_gmipebal          --プログラム名(GMIPEBAL)
                    ,description       =>  cv_description       --摘要(空残高のパージ)
                    ,start_time        =>  NULL                 --実行日
                    ,sub_request       =>  FALSE
                    ,argument1         =>  NULL                 --品目:自
                    ,argument2         =>  NULL                 --品目:至
                    ,argument3         =>  NULL                 --倉庫:自
                    ,argument4         =>  NULL                 --倉庫:至
                    ,argument5         =>  NULL                 --在庫区分
                    ,argument6         =>  NULL                 --ロット管理品目(0:NO,1:YES)
                    ,argument7         =>  cv_9                 --精度のパージ
                 ) ;
--
      /*
      -- コンカレント起動失敗の場合はエラー処理
      IF ( NVL(gn_request_id, 0) = 0 ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_app_name_xxcmn
                    ,iv_name          => cv_conc_err);
        RAISE global_api_others_expt;
      ELSE
        COMMIT;
      END IF;
      */
--
      IF ( NVL(gn_request_id, 0) = 0 ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_app_name_xxcmn
                    ,iv_name          => cv_conc_err);
        ov_retcode := cv_status_error;
        RAISE local_api_others_expt;
      ELSE
        COMMIT;
      END IF;
--
      -----------------------------------------
      --発行されたコンカレントの終了チェック
      -----------------------------------------
      --コンカレント実行結果を取得
      /*
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(.
           request_id => gn_request_id.
          ,interval   => 1.
          ,max_wait   => 0.
          ,phase      => lv_phase.
          ,status     => lv_status.
          ,dev_phase  => lv_dev_phase.
          ,dev_status => lv_dev_status.
          ,message    => lv_errbuf_wait
          ) ) THEN
      */
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
           request_id => gn_request_id
          ,interval   => 1
          ,max_wait   => 0
          ,phase      => lv_phase
          ,status     => lv_status
          ,dev_phase  => lv_dev_phase
          ,dev_status => lv_dev_status
          ,message    => lv_errbuf_wait
         ) ) THEN
--
        -- ステータス反映
        -- フェーズ:完了
        IF ( lv_dev_phase = cv_conc_p_c ) THEN
--
          /*
          lv_dev_statusが'ERROR','CANCELLED','TERMINATED'の場合はエラー終了
          テータスをエラーにして終了
          lv_dev_statusが'WARNING'の場合は警告終了
          ステータスを警告にする
          lv_dev_statusが'NORMAL'の場合は正常処理続行
          lv_dev_statusが上記以外の場合はエラー終了
          ステータスをエラーにして終了
          */
          --ステータスコードにより状況判定
          CASE lv_dev_status
            --エラー
            WHEN cv_conc_s_e THEN
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
--
            --キャンセル
            WHEN cv_conc_s_c THEN
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
--
            --強制終了
            WHEN cv_conc_s_t THEN
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
--
            --警告終了
            WHEN cv_conc_s_w THEN
              --今まで正常の場合のみ警告ステータス
              IF ( ov_retcode < 1 ) THEN
                ov_retcode := cv_status_warn;
              END IF;
--
            --正常終了
            WHEN cv_conc_s_n THEN
              NULL;
--
            --他の値は例外処理
            ELSE
              --要求[ REQUEST ]が正常に終了しませんでした。
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
          END CASE;
--
        --完了まで処理を待つが、完了ステータスではなかった場合の例外ハンドル
        ELSE
          ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_gmipebal
                     );
          ov_retcode := cv_status_error;
          RAISE local_api_others_expt;
        END IF;
--
      --WAIT_FOR_REQUESTが異常だった場合の例外ハンドル
      ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_gmipebal
                     );
        ov_retcode := cv_status_error;
        RAISE local_api_others_expt;
      END IF;
--
      --コンカレント実施後データ件数カウント
      /*
      SELECT  COUNT(1)
      INTO    ln_空残高のパージ(処理後)件数
      FROM    OPM手持在庫トランザクション; 
      */
--
      SELECT  COUNT(1)  AS cnt
      INTO    ln_purge_cnt_a
      FROM    ic_loct_inv;
--
      /*
      gn_空残高のパージ処理件数 := ln_空残高のパージ(処理前)件数 - ln_空残高のパージ(処理後)件数;
      */
      gn_purge_cnt := ln_purge_cnt_b - ln_purge_cnt_a;
--
      -- ===============================================
      -- 標準テーブル リストア処理
      -- ===============================================
      lv_process_part := '標準テーブル リストア処理：';
--
      /*
      lt_OPM手持在庫トランザクションテーブル.DELETE;
      */
      l_loct_inv_tab.DELETE;
--
      /*
      OPEN rst_data_cur(gt_処理年月) LOOP;
      FETCH rst_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
      l_loct_inv2_tab.COUNT  > 0 の場合
        gn_リストア処理対象件数 := l_loct_inv2_tab.COUNT;
--
      */
      OPEN rst_data_cur(gt_shori_ym);
      FETCH rst_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
        IF ( l_loct_inv2_tab.COUNT ) > 0 THEN
--
          gn_rst_cnt_all := l_loct_inv2_tab.COUNT;
--
          /*
          FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
          LOOP
          */
          << loctinv_rst_loop >>
          FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
          LOOP
--
            /*
            gt_対象OPM手持在庫トランザクション品目ID      := lr_loctinv_rst_rec.品目ID;  
            gt_対象OPM手持在庫トランザクション倉庫コード  := lr_loctinv_rst_rec.倉庫コード;
            gt_対象OPM手持在庫トランザクションロットID    := lr_loctinv_rst_rec.ロットID;
            gt_対象OPM手持在庫トランザクション保管場所    := lr_loctinv_rst_rec.保管場所;
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
                  -- OPM手持在庫トランザクションロック
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
                  SELECT ili.item_id  AS  item_id,
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
                gn_restore_cnt := gn_restore_cnt + ln_rst_cnt_yet;
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
            ln_rst_cnt_yet := ln_rst_cnt_yet + 1;
--
            /*
            lt_OPM手持在庫トランザクションテーブル(gn_未コミットバックアップ件数 
                             (OPM手持在庫トランザクション) := l_loct_inv2_tab(ln_idx).全カラム;
            */
            l_loct_inv_tab(ln_rst_cnt_yet).item_id         := l_loct_inv2_tab(ln_idx).item_id;
            l_loct_inv_tab(ln_rst_cnt_yet).whse_code       := l_loct_inv2_tab(ln_idx).whse_code;
            l_loct_inv_tab(ln_rst_cnt_yet).lot_id          := l_loct_inv2_tab(ln_idx).lot_id;
            l_loct_inv_tab(ln_rst_cnt_yet).location        := l_loct_inv2_tab(ln_idx).location;
            l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand     
                                               := l_loct_inv2_tab(ln_idx).loct_onhand;
            l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand2    
                                               := l_loct_inv2_tab(ln_idx).loct_onhand2;
            l_loct_inv_tab(ln_rst_cnt_yet).lot_status      := l_loct_inv2_tab(ln_idx).lot_status;
            l_loct_inv_tab(ln_rst_cnt_yet).qchold_res_code 
                                               := l_loct_inv2_tab(ln_idx).qchold_res_code;
            l_loct_inv_tab(ln_rst_cnt_yet).delete_mark     
                                               := l_loct_inv2_tab(ln_idx).delete_mark;
            l_loct_inv_tab(ln_rst_cnt_yet).text_code       := l_loct_inv2_tab(ln_idx).text_code;
            l_loct_inv_tab(ln_rst_cnt_yet).last_updated_by 
                                               := l_loct_inv2_tab(ln_idx).last_updated_by;
            l_loct_inv_tab(ln_rst_cnt_yet).created_by      := l_loct_inv2_tab(ln_idx).created_by;
            l_loct_inv_tab(ln_rst_cnt_yet).last_update_date 
                                               := l_loct_inv2_tab(ln_idx).last_update_date;
            l_loct_inv_tab(ln_rst_cnt_yet).creation_date   
                                               := l_loct_inv2_tab(ln_idx).creation_date;
            l_loct_inv_tab(ln_rst_cnt_yet).last_update_login 
                                               := l_loct_inv2_tab(ln_idx).last_update_login;
            l_loct_inv_tab(ln_rst_cnt_yet).program_application_id
                                               := l_loct_inv2_tab(ln_idx).program_application_id;
            l_loct_inv_tab(ln_rst_cnt_yet).program_id      
                                               :=   l_loct_inv2_tab(ln_idx).program_id;
            l_loct_inv_tab(ln_rst_cnt_yet).program_update_date     
                                               := l_loct_inv2_tab(ln_idx).program_update_date;
            l_loct_inv_tab(ln_rst_cnt_yet).request_id      := l_loct_inv2_tab(ln_idx).request_id;
--
          END LOOP loctinv_rst_loop;
--
        END IF;
--
      CLOSE rst_data_cur;
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
        -- OPM手持在庫トランザクションロック
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
      gn_restore_cnt := gn_restore_cnt + ln_rst_cnt_yet;
      ln_rst_cnt_yet := 0;
--
    /*
    ln_バックアップ件数(OPM手持在庫トランザクション) <> 0の場合 IF文終了
    */
    END IF;
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
            --パージ処理に失敗しました。【OPM手持在庫パージ】品目ID ： KEY1 , 
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
            --パージ処理に失敗しました。【OPM手持在庫パージ】品目ID ： KEY1 ,
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
    IF ( gt_shori_ym IS NULL ) THEN
      lv_nengetu  := NULL;
    ELSE
      lv_nengetu  := SUBSTRB(gt_shori_ym,1,4) || cv_msg_slash || SUBSTRB(gt_shori_ym,5,2);
    END IF;
--
    --パラメータ(処理年月： NENGETU)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_nengetu_token
                    ,iv_token_value1 => lv_nengetu
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空残高のパージ（リクエストID）： REQUEST_ID
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg2
                      ,iv_token_name1  => cv_req_id
                      ,iv_token_value1 => TO_CHAR(gn_request_id)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
    削除件数取得
    gn_削除件数(OPM手持在庫トランザクション) := 
                                       gn_空残高のパージ処理件数(OPM手持在庫トランザクション) - 
                                       gn_リストア処理対象件数(OPM手持在庫トランザクション);
    */
    gn_del_cnt    := gn_purge_cnt - gn_restore_cnt;
--
    /*
    正常件数取得
    gn_正常件数(OPM手持在庫トランザクション) := 
                                       gn_空残高のパージ処理件数(OPM手持在庫トランザクション) - 
                                       gn_リストア処理対象件数(OPM手持在庫トランザクション);
    */
    gn_normal_cnt := gn_purge_cnt - gn_rst_cnt_all;
--
    --OPM手持在庫トランザクション（標準） 削除 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg1
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname
                      ,iv_token_name2  => cv_token_shori_p
                      ,iv_token_value2 => cv_shori_p
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_del_cnt)
                     );
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
END XXCMN960011C;
/
