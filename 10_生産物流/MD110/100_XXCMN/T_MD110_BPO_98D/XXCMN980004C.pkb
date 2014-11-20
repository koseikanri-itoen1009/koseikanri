CREATE OR REPLACE PACKAGE BODY XXCMN980004C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980004C(body)
 * Description      : 保留在庫TRN（標準）バックアップ
 * MD.050           : T_MD050_BPO_98D_保留在庫TRN（標準）バックアップ
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
 *  2012/11/02   1.00  T.Makuta          新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  cn_request_id      CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
--
  cv_purge_type      CONSTANT VARCHAR2(1)  := '1';                        --ﾊﾟｰｼﾞﾀｲﾌﾟ(1:BUCKUP期間)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9801';                     --ﾊﾟｰｼﾞ定義ｺｰﾄﾞ
  cv_doc_type_p      CONSTANT VARCHAR2(5)  := 'PROD';                     --文書タイプ
  --=============
  --メッセージ
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_archive_range
                     CONSTANT VARCHAR2(50) := 'XXCMN_ARCHIVE_RANGE';      --XXCMN:ﾊﾞｯｸｱｯﾌﾟﾚﾝｼﾞ
  --XXCMN:パージ/バックアップ分割コミット数
  cv_xxcmn_commit_range     
                     CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_target_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11008';          --対象件数メッセージ
  cv_normal_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';          --正常件数メッセージ
  cv_error_rec_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';          --エラー件数メッセージ
--
  cv_proc_date_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11014';          --処理日出力
  cv_par_token       CONSTANT VARCHAR2(10) := 'PAR';                      --処理日MSG用ﾄｰｸﾝ名
--
  cv_get_profile_msg CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';          --ﾌﾟﾛﾌｧｲﾙ値取得失敗
  cv_token_profile   CONSTANT VARCHAR2(50) := 'NG_PROFILE';               --ﾌﾟﾛﾌｧｲﾙ取得MSG用ﾄｰｸﾝ名
--
  cv_get_priod_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11012';          --ﾊﾞｯｸｱｯﾌﾟ期間取得失敗
--
  cv_others_err_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11026';          --ﾊﾞｯｸｱｯﾌﾟ処理失敗
  cv_token_shori     CONSTANT VARCHAR2(10) := 'SHORI';                    --ﾊﾞｯｸｱｯﾌﾟ処理MSG用ﾄｰｸﾝ名
  cv_token_kinou     CONSTANT VARCHAR2(10) := 'KINOUMEI';                 --ﾊﾞｯｸｱｯﾌﾟ処理MSG用ﾄｰｸﾝ名
  cv_token_key_name  CONSTANT VARCHAR2(10) := 'KEYNAME';                  --ﾊﾞｯｸｱｯﾌﾟ処理MSG用ﾄｰｸﾝ名
  cv_token_key       CONSTANT VARCHAR2(10) := 'KEY';                      --ﾊﾞｯｸｱｯﾌﾟ処理MSG用ﾄｰｸﾝ名
  cv_shori           CONSTANT VARCHAR2(50) := 'バックアップ';
  cv_kinou           CONSTANT VARCHAR2(90) := '保留在庫TRN（標準）';
  cv_key_name        CONSTANT VARCHAR2(50) := 'バッチID';
--
  --TBL_NAME SHORI 件数： CNT 件
  cv_end_msg         CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';          --処理内容出力
  cv_token_tblname   CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname         CONSTANT VARCHAR2(90) := 'OPM保留在庫トランザクション（標準）';
  cv_token_shori2    CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori2          CONSTANT VARCHAR2(50) := 'バックアップ';
  cv_cnt_token       CONSTANT VARCHAR2(10) := 'CNT';
---
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_error_cnt       NUMBER;                                     --エラー件数
  gn_arc_cnt_ictran  NUMBER;                                     --ﾊﾞｯｸｱｯﾌﾟ件数
  gn_cnt_header      NUMBER;                                     --処理件数(生産ﾊﾞｯﾁﾍｯﾀﾞ)
  gn_cnt_header_yet  NUMBER;                                     --未ｺﾐｯﾄ件数(生産ﾊﾞｯﾁﾍｯﾀﾞ)
  gn_arc_cnt_opm_yet NUMBER;                                     --未ｺﾐｯﾄﾊﾞｯｸｱｯﾌﾟ件数
  gt_batch_id        gme_batch_header.batch_id%TYPE;
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
  not_init_collection_expt  EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_init_collection_expt, -6531);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN980004C'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE ic_tran_pnd_ttype IS TABLE OF xxcmn_ic_tran_pnd_arc%ROWTYPE INDEX BY BINARY_INTEGER;
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
    iv_proc_date  IN  VARCHAR2,     --   1.処理日
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
    ln_archive_period         NUMBER;                           --バックアップ期間
    ln_archive_range          NUMBER;                           --バックアップレンジ
    ld_standard_date          DATE;                             --基準日
    ln_commit_range           NUMBER;                           --分割コミット数
    lv_process_part           VARCHAR2(1000);                   -- 処理部
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    CURSOR 処理対象生産バッチヘッダ取得
      id_基準日       IN DATE,
      in_バックアップレンジ IN NUMBER
    IS
      SELECT 生産バッチヘッダ.バッチID
      FROM   生産バッチヘッダ
      WHERE  生産バッチヘッダ.計画開始日 >= id_基準日  - in_バックアップレンジ
      AND    生産バッチヘッダ.計画開始日 <  id_基準日
      ;
    */
    CURSOR b_header_cur(
      id_standard_date      DATE
     ,in_archive_range      NUMBER
    )
    IS
      SELECT /*+ INDEX(gbh GME_GBH_N01) */
              gbh.batch_id            AS batch_id
      FROM    gme_batch_header           gbh                    --生産ﾊﾞｯﾁﾍｯﾀﾞ
      WHERE   gbh.plan_start_date     >= id_standard_date - in_archive_range
      AND     gbh.plan_start_date     <  id_standard_date
      ;
    /*
    CURSOR バックアップ対象OPM保留在庫トランザクション取得
       it_バッチID  IN 生産バッチヘッダ.バッチID%TYPE
    IS
      SELECT
            OPM保留在庫トランザクション.全カラム,
             バックアップ登録日,
             バックアップ要求ID,
             NULL,                  --パージ実行日
             NULL                   --パージ要求ID
      FROM  OPM保留在庫トランザクション,
            生産原料詳細
      WHERE 生産原料詳細.バッチID          =  it_バッチID
      AND   生産原料詳細.生産原料詳細ID = OPM保留在庫トランザクション.明細ID
      AND   OPM保留在庫トランザクション.文書タイプ = 'PROD'
      AND NOT EXISTS (SELECT  1
                       FROM OPM保留在庫トランザクションバックアップ
                       WHERE OPM保留在庫トランザクションバックアップ.トランザクションID = 
                                                   OPM保留在庫トランザクション.トランザクションID
                       AND ROWNUM = 1
                      );
    */
--
    CURSOR ic_tran_pnd_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              itp.trans_id                AS trans_id,                    --トランザクションID
              itp.item_id                 AS item_id,
              itp.line_id                 AS line_id,                     --明細ID
              itp.co_code                 AS co_code,
              itp.orgn_code               AS orgn_code,
              itp.whse_code               AS whse_code,
              itp.lot_id                  AS lot_id,
              itp.location                AS location,
              itp.doc_id                  AS doc_id,                      --文書ID
              itp.doc_type                AS doc_type,                    --文書タイプ
              itp.doc_line                AS doc_line,                    --取引明細番号
              itp.line_type               AS line_type,
              itp.reason_code             AS reason_code,                 --事由コード
              itp.creation_date           AS creation_date,
              itp.trans_date              AS trans_date,
              itp.trans_qty               AS trans_qty,
              itp.trans_qty2              AS trans_qty2,
              itp.qc_grade                AS qc_grade,
              itp.lot_status              AS lot_status,
              itp.trans_stat              AS trans_stat,
              itp.trans_um                AS trans_um,
              itp.trans_um2               AS trans_um2,
              itp.op_code                 AS op_code,
              itp.completed_ind           AS completed_ind,               --完了フラグ
              itp.staged_ind              AS staged_ind,
              itp.gl_posted_ind           AS gl_posted_ind,
              itp.event_id                AS event_id,
              itp.delete_mark             AS delete_mark,
              itp.text_code               AS text_code,
              itp.last_update_date        AS last_update_date,
              itp.created_by              AS created_by,
              itp.last_updated_by         AS last_updated_by,
              itp.last_update_login       AS last_update_login,
              itp.program_application_id  AS program_application_id,
              itp.program_id              AS program_id,
              itp.program_update_date     AS program_update_date,
              itp.request_id              AS request_id,
              itp.reverse_id              AS reverse_id,
              itp.pick_slip_number        AS pick_slip_number,
              itp.mvt_stat_status         AS mvt_stat_status,
              itp.movement_id             AS movement_id,
              itp.line_detail_id          AS line_detail_id,
              itp.invoiced_flag           AS invoiced_flag,
              itp.intorder_posted_ind     AS intorder_posted_ind,
              itp.lot_costed_ind          AS lot_costed_ind,
              SYSDATE                     AS archive_date,           --バックアップ登録日
              cn_request_id               AS archive_request_id,     --バックアップ要求ID
              NULL                        AS purge_date,             --パージ実行日
              NULL                        AS purge_request_id        --パージ要求ID
      FROM    ic_tran_pnd                 itp,                       --OPM保留在庫ﾄﾗﾝｻﾞｸｼｮﾝ
              gme_material_details        gmd                        --生産原料詳細
      WHERE   gmd.batch_id             =  it_batch_id
      AND     gmd.material_detail_id   =  itp.line_id
      AND     itp.doc_type             =  cv_doc_type_p              --PROD
      AND NOT EXISTS(SELECT 1
                     FROM  xxcmn_ic_tran_pnd_arc xitp                --OPM保留在庫ﾄﾗﾝｻﾞｸｼｮﾝﾊﾞｯｸｱｯﾌﾟ
                     WHERE xitp.trans_id = itp.trans_id
                     AND   ROWNUM        = 1
                    );
--
    -- <カーソル名>レコード型
    lt_ict_pnd_tbl      ic_tran_pnd_ttype;                           --OPM保留在庫ﾄﾗﾝｻﾞｸｼｮﾝﾃｰﾌﾞﾙ
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
    gn_error_cnt       := 0;
    gn_cnt_header      := 0;
    gn_arc_cnt_ictran  := 0;
    gn_cnt_header_yet  := 0;
    gn_arc_cnt_opm_yet := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- バックアップ期間取得
    -- ===============================================
    /*
    ln_バックアップ期間 := バックアップ期間/パージ期間取得関数（cv_パージタイプ,cv_パージコード）;
     */
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
--
    /*
    ln_バックアップ期間がNULLの場合
      ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                            iv_アプリケーション短縮名  => cv_appl_short_name
                           ,iv_メッセージコード        => cv_get_priod_msg
                          );
      ov_リターンコード := cv_status_error;
      RAISE local_process_expt 例外処理
    */
--
    IF ( ln_archive_period IS NULL ) THEN
--
      --バックアップ期間の取得に失敗しました。
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- ＩＮパラメータの確認
    -- ===============================================
    lv_process_part := 'INパラメータの確認：';
--
    /*
    iv_proc_dateがNULLの場合
--
      ld_基準日 := 処理日取得共通関数から取得した処理日 - ln_バックアップ期間;
--
    iv_proc_dateがNULLでない場合
--
      ld_基準日 := TO_DATE(iv_proc_date)                - ln_バックアップ期間;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date      - ln_archive_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
--
    END IF;
--
     -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）：';
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップ分割コミット数));
     */
    ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_archive_range || '）：';
    /*
    ln_バックアップレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップレンジ));
    */
    ln_archive_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_archive_range));
--
    /*
    ln_バックアップレンジがNULLの場合
    */
    IF ( ln_archive_range IS NULL ) THEN
--
      /*
      ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                     iv_アプリケーション短縮名  => cv_appl_short_name
                    ,iv_メッセージコード        => cv_get_profile_msg
                    ,iv_トークン名1             => cv_token_profile
                    ,iv_トークン値1             => cv_xxcmn_archive_range
                   );
      ov_リターンコード := cv_status_error;
      RAISE local_process_expt 例外処理
      */
--
      -- プロファイル[ NG_PROFILE ]の取得に失敗しました。
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_archive_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    lv_process_part := NULL;
--
    -- ===============================================
    -- 主処理
    -- ===============================================
    /*
    FOR lr_b_header_rec IN 処理対象生産バッチヘッダ取得(ld_基準日,ln_バックアップレンジ) LOOP
    */
    << backup_main >>
    FOR lr_b_header_rec IN b_header_cur(ld_standard_date
                                       ,ln_archive_range ) LOOP
--
      /*
      gt_対象生産バッチID := lr_b_header_rec.生産バッチID;
      */
      gt_batch_id         := lr_b_header_rec.batch_id;
--
      /*
      FOR lr_ict_pnd_rec IN バックアップ対象OPM保留在庫トランザクション取得
                                                                 (lr_b_header_rec.バッチID) LOOP
      */
      << ic_tran_pnd_loop >>
      FOR lr_ict_pnd_rec IN ic_tran_pnd_cur(lr_b_header_rec.batch_id) LOOP
--
        -- ===============================================
        -- 分割コミット
        -- ===============================================
        /*
        NVL(ln_分割コミット数, 0) <> 0の場合
        */
        IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
          /* 
          gn_未コミット件数(生産バッチヘッダ) > 0 かつ 
          MOD(gn_未コミット件数(生産バッチヘッダ), ln_分割コミット数) = 0の場合
          */
          IF (  (gn_cnt_header_yet > 0)
            AND (MOD(gn_cnt_header_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            FORALL ln_idx IN 1..gn_未コミットバックアップ件数(OPM保留在庫トランザクション)
              INSERT INTO OPM保留在庫トランザクションバックアップ
              (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
              )
              VALUES
              (
                lt_OPM保留在庫トランザクションテーブル(ln_idx)全カラム
              , SYSDATE
              , 要求ID
              )
            */
            FORALL ln_idx IN 1..gn_arc_cnt_opm_yet
              INSERT INTO xxcmn_ic_tran_pnd_arc VALUES lt_ict_pnd_tbl(ln_idx);
--
            /*
            gn_処理件数(生産バッチヘッダ) := gn_処理件数(生産バッチヘッダ) + 
                                                     gn_未コミット件数(生産バッチヘッダ);
            gn_未コミット件数(生産バッチヘッダ)   := 0;
            */
--
            gn_cnt_header     := gn_cnt_header + gn_cnt_header_yet;
            gn_cnt_header_yet := 0;
--
            /*
            gn_バックアップ件数(OPM保留在庫トランザクション) := 
                                      gn_バックアップ件数(OPM保留在庫トランザクション) + 
                                      gn_未コミットバックアップ件数(OPM保留在庫トランザクション);
            gn_未コミットバックアップ件数(OPM保留在庫トランザクション) := 0;
            lt_OPM保留在庫トランザクションテーブル.DELETE;
--
            COMMIT;
            */
--
            gn_arc_cnt_ictran  := gn_arc_cnt_ictran + gn_arc_cnt_opm_yet;
            gn_arc_cnt_opm_yet := 0;
            lt_ict_pnd_tbl.DELETE;
--
            COMMIT;
--
          END IF;
--
        END IF;
--
        -- --------------------------------------
        -- OPM保留在庫トランザクション 変数設定
        -- --------------------------------------
        /*
        gn_未コミットバックアップ件数(OPM保留在庫トランザクション) := 
                                    gn_未コミットバックアップ件数(OPM保留在庫トランザクション) + 1;
        lt_OPM保留在庫トランザクションテーブル(gn_未コミットバックアップ件数
                                               (OPM保留在庫トランザクション) := lr_ict_pnd_rec;
        */
        gn_arc_cnt_opm_yet := gn_arc_cnt_opm_yet + 1;
--
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_id            := lr_ict_pnd_rec.trans_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).item_id             := lr_ict_pnd_rec.item_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).line_id             := lr_ict_pnd_rec.line_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).co_code             := lr_ict_pnd_rec.co_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).orgn_code           := lr_ict_pnd_rec.orgn_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).whse_code           := lr_ict_pnd_rec.whse_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).lot_id              := lr_ict_pnd_rec.lot_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).location            := lr_ict_pnd_rec.location;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).doc_id              := lr_ict_pnd_rec.doc_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).doc_type            := lr_ict_pnd_rec.doc_type;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).doc_line            := lr_ict_pnd_rec.doc_line;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).line_type           := lr_ict_pnd_rec.line_type;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).reason_code         := lr_ict_pnd_rec.reason_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).creation_date       := lr_ict_pnd_rec.creation_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_date          := lr_ict_pnd_rec.trans_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_qty           := lr_ict_pnd_rec.trans_qty;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_qty2          := lr_ict_pnd_rec.trans_qty2;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).qc_grade            := lr_ict_pnd_rec.qc_grade;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).lot_status          := lr_ict_pnd_rec.lot_status;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_stat          := lr_ict_pnd_rec.trans_stat;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_um            := lr_ict_pnd_rec.trans_um;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_um2           := lr_ict_pnd_rec.trans_um2;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).op_code             := lr_ict_pnd_rec.op_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).completed_ind       := lr_ict_pnd_rec.completed_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).staged_ind          := lr_ict_pnd_rec.staged_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).gl_posted_ind       := lr_ict_pnd_rec.gl_posted_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).event_id            := lr_ict_pnd_rec.event_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).delete_mark         := lr_ict_pnd_rec.delete_mark;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).text_code           := lr_ict_pnd_rec.text_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).last_update_date    := lr_ict_pnd_rec.last_update_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).created_by          := lr_ict_pnd_rec.created_by;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).last_updated_by     := lr_ict_pnd_rec.last_updated_by;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).last_update_login   := lr_ict_pnd_rec.last_update_login;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).program_application_id := 
                                                            lr_ict_pnd_rec.program_application_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).program_id          := lr_ict_pnd_rec.program_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).program_update_date := 
                                                            lr_ict_pnd_rec.program_update_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).request_id          := lr_ict_pnd_rec.request_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).reverse_id          := lr_ict_pnd_rec.reverse_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).pick_slip_number    := lr_ict_pnd_rec.pick_slip_number;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).mvt_stat_status     := lr_ict_pnd_rec.mvt_stat_status;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).movement_id         := lr_ict_pnd_rec.movement_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).line_detail_id      := lr_ict_pnd_rec.line_detail_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).invoiced_flag       := lr_ict_pnd_rec.invoiced_flag;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).intorder_posted_ind := 
                                                            lr_ict_pnd_rec.intorder_posted_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).lot_costed_ind      := lr_ict_pnd_rec.lot_costed_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).archive_date        := lr_ict_pnd_rec.archive_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).archive_request_id  := 
                                                            lr_ict_pnd_rec.archive_request_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).purge_date          := lr_ict_pnd_rec.purge_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).purge_request_id    := lr_ict_pnd_rec.purge_request_id;
--
      END LOOP ic_tran_pnd_loop;
--
      /*
      gn_未コミット件数(生産バッチヘッダ) := gn_未コミット件数(生産バッチヘッダ) + 1;
      */
      gn_cnt_header_yet := gn_cnt_header_yet + 1;
--
    END LOOP backup_main;
--
    -- --------------------------------------------------------------------
    -- 分割コミット対象外の残データ INSERT処理(OPM保留在庫トランザクション)
    -- --------------------------------------------------------------------
    /*
    FORALL ln_idx IN 1..gn_未コミットバックアップ件数(OPM保留在庫トランザクション)
      INSERT INTO OPM保留在庫トランザクションバックアップ
      (
        全カラム
      , バックアップ登録日
      , バックアップ要求ID
      )
      VALUES
      (
        OPM保留在庫トランザクションテーブル(ln_idx)全カラム
      , SYSDATE
      , 要求ID
      )
      ;
    */
--
    FORALL ln_idx IN 1..gn_arc_cnt_opm_yet
      INSERT INTO xxcmn_ic_tran_pnd_arc VALUES lt_ict_pnd_tbl(ln_idx);
--
    /*
    gn_処理件数(生産バッチヘッダ)         := gn_処理件数(生産バッチヘッダ) + 
                                             gn_未コミット件数(生産バッチヘッダ);
    gn_未コミット件数(生産バッチヘッダ)   := 0;
    */
    gn_cnt_header     := gn_cnt_header + gn_cnt_header_yet;
    gn_cnt_header_yet := 0;
--
    /*
    gn_バックアップ件数(OPM保留在庫トランザクション) := 
                                        gn_バックアップ件数(OPM保留在庫トランザクション) + 
                                        gn_未コミットバックアップ件数(OPM保留在庫トランザクション);
    gn_未コミット件数(生産バッチヘッダ) := 0;
    gn_未コミットバックアップ件数(OPM保留在庫トランザクション) := 0;
    lt_OPM保留在庫トランザクションテーブル.DELETE;
    */
--
    gn_arc_cnt_ictran  := gn_arc_cnt_ictran + gn_arc_cnt_opm_yet;
    gn_arc_cnt_opm_yet := 0;
    lt_ict_pnd_tbl.DELETE;
--
  -- ===============================================
  -- 例外処理
  -- ===============================================
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN local_process_expt THEN
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
          IF ( lt_ict_pnd_tbl.COUNT > 0 ) THEN
            --バックアップ処理に失敗しました。【OPM保留在庫トランザクション】バッチID: KEY
            ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_shori
                      ,iv_token_name2  => cv_token_kinou
                      ,iv_token_value2 => cv_kinou
                      ,iv_token_name3  => cv_token_key_name
                      ,iv_token_value3 => cv_key_name
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(gt_batch_id)
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
      IF ( (ov_errmsg IS NULL) AND (gt_batch_id IS NOT NULL) ) THEN
        --バックアップ処理に失敗しました。【OPM保留在庫トランザクション】バッチID: KEY
            ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_shori
                      ,iv_token_name2  => cv_token_kinou
                      ,iv_token_value2 => cv_kinou
                      ,iv_token_name3  => cv_token_key_name
                      ,iv_token_value3 => cv_key_name
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(gt_batch_id)
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_proc_date  IN  VARCHAR2       --   1.処理日
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
    --
  BEGIN
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
       iv_proc_date -- 1.処理日
      ,lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- ログ出力処理
    -- ===============================================
    --パラメータ(処理日： PAR)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 異常終了時の件数処理
    IF (lv_retcode = cv_status_error) AND (gn_cnt_header  = 0 ) THEN
        gn_arc_cnt_ictran := 0;
    END IF;
--
    --保留在庫TRN（標準） バックアップ 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname
                      ,iv_token_name2  => cv_token_shori2
                      ,iv_token_value2 => cv_shori2
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_arc_cnt_ictran)
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
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_ictran)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力(エラー件数： CNT 件)
    IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := 1;
    ELSE
      gn_error_cnt   := 0;
    END IF;
--
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
END XXCMN980004C;
/
