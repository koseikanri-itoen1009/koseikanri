CREATE OR REPLACE PACKAGE BODY XXCMN960016C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960016C(body)
 * Description      : OPM完了トランバックアップ・更新
 * MD.050           : T_MD050_BPO_96N_OPM完了トランバックアップ・更新
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
 *  2012/12/03   1.00  K.Boku            新規作成
 *  2013/02/13   1.01  M.Kitajima        結合テスト不具合(IT_0018)対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := '0'; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1';   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2';  --異常:2
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
  gn_arc_cnt       NUMBER;                                    -- バックアップ件数（ OPM完了在庫トランザクション（標準））
  gn_upd_cnt       NUMBER;                                    -- 更新件数（ OPM完了在庫トランザクション（標準））
  gt_tran_id       xxcmn_ic_tran_cmp_arc.trans_id%TYPE;       -- 対象完了在庫トランザクションID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960002C'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_ic_tran_cmp_arc_ttype IS TABLE OF xxcmn_ic_tran_cmp_arc%ROWTYPE INDEX BY BINARY_INTEGER;
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
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    cv_appl_short_name          CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
    cv_get_priod_arc_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';  -- バックアップ期間の取得に失敗しました。
    cv_get_priod_purdge_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- パージ期間の取得に失敗しました。
    cv_get_profile_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- プロファイル[ ＆NG_PROFILE ]の取得に失敗しました。
    cv_local_others_arc_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11036';  -- バックアップ処理に失敗しました。【OPM完了在庫トランザクション（標準）】トランザクションID： ＆KEY
    cv_local_others_upd_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11037';  -- 更新処理に失敗しました。【OPM完了在庫トランザクション（標準）】トランザクションID： ＆KEY
    cv_token_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key                CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range       CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_archive_range      CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';
    cv_xxcmn_purdge_range       CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';
--
    cv_adji                     CONSTANT VARCHAR2(4)   := 'ADJI';
--
    cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
    cv_gl_post_fla             CONSTANT NUMBER  := 1;
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
    cv_purge_type_1   CONSTANT VARCHAR2(1)  := '1';                               -- パージタイプ（1:バックアップ処理期間）
    cv_purge_type_0   CONSTANT VARCHAR2(1)  := '0';                               -- パージタイプ（0:パージ処理期間）
    cv_purge_code     CONSTANT VARCHAR2(30) := '9601';                            -- パージ定義コード
--
    -- *** ローカル変数 ***
    ln_arc_cnt_yet            NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数（OPM完了在庫トランザクション（標準））
    ln_upd_cnt_line_yet       NUMBER DEFAULT 0;                                 -- 未コミット更新件数（OPM完了在庫トランザクション（標準））
    ln_archive_period         NUMBER;                                           -- バックアップ期間
    ln_purge_period           NUMBER;                                           -- パージ期間
    ln_archive_range          NUMBER;                                           -- バックアップレンジ
    ln_purge_range            NUMBER;                                           -- パージレンジ
    ld_standard_date_arc      DATE;                                             -- 基準日（バックアップ）
    ld_standard_date_purdge   DATE;                                             -- 基準日（パージ）
    ln_commit_range           NUMBER;                                           -- 分割コミット数
    lv_process_part           VARCHAR2(1000);                                   -- 処理部
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    -- バックアップ対象OPM完了在庫トランザクション（標準）取得
    CURSOR バックアップ対象OPM完了在庫トランザクション（標準）取得
      id_基準日  IN DATE
      in_バックアップ IN NUMBER
    IS
      SELECT 
             OPM完了在庫トランザクション（標準）．全カラム
      FROM OPMジャーナルマスタ(標準)
           ,    OPM在庫調整ジャーナル(標準)
           ,    OPM完了在庫トランザクション(標準)
      WHERE OPMジャーナルマスタ(標準)．DFF1 IS NULL
      AND OPM在庫調整ジャーナル(標準)．ジャーナルID = OPMジャーナルマスタ(標準)．ジャーナルID
      AND OPM完了在庫トランザクション(標準)．文書タイプ = OPM在庫調整ジャーナル(標準)．文書タイプ
      AND OPM完了在庫トランザクション(標準)．文書ID = OPM在庫調整ジャーナル(標準)．文書ID
      AND OPM完了在庫トランザクション(標準)．取引明細番号 = OPM在庫調整ジャーナル(標準)．取引明細番号
      AND OPM完了在庫トランザクション(標準)．文書タイプ = 'ADJI'
      AND OPM完了在庫トランザクション．取引日 ≧ 基準日－in_バックアップ
      AND OPM完了在庫トランザクション．取引日 ＜ 基準日
      AND NOT EXISTS (
               SELECT 1
               FROM OPM完了在庫トランザクション（標準）バックアップ
               WHERE OPM完了在庫トランザクション（標準）バックアップ．トランザクションID = OPM完了在庫トランザクション（標準）．トランザクションID
               AND ROWNUM = 1
             )
     */
    CURSOR archive_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
    )
    IS
      SELECT  /*+ LEADING(itc) USE_NL(itc iaj ijm) */
              itc.trans_id                  AS  trans_id
             ,itc.item_id                   AS item_id
             ,itc.line_id                   AS line_id
             ,itc.co_code                   AS co_code
             ,itc.orgn_code                 AS orgn_code
             ,itc.whse_code                 AS whse_code
             ,itc.lot_id                    AS lot_id
             ,itc.location                  AS location
             ,itc.doc_id                    AS doc_id
             ,itc.doc_type                  AS doc_type
             ,itc.doc_line                  AS doc_line
             ,itc.line_type                 AS line_type
             ,itc.reason_code               AS reason_code
             ,itc.creation_date             AS creation_date
             ,itc.trans_date                AS trans_date
             ,itc.trans_qty                 AS trans_qty
             ,itc.trans_qty2                AS trans_qty2
             ,itc.qc_grade                  AS qc_grade
             ,itc.lot_status                AS lot_status
             ,itc.trans_stat                AS trans_stat
             ,itc.trans_um                  AS trans_um
             ,itc.trans_um2                 AS trans_um2
             ,itc.op_code                   AS op_code
             ,itc.gl_posted_ind             AS gl_posted_ind
             ,itc.event_id                  AS event_id
             ,itc.text_code                 AS text_code
             ,itc.last_update_date          AS last_update_date
             ,itc.created_by                AS created_by
             ,itc.last_updated_by           AS last_updated_by
             ,itc.last_update_login         AS last_update_login
             ,itc.program_application_id    AS program_application_id
             ,itc.program_id                AS program_id
             ,itc.program_update_date       AS program_update_date
             ,itc.request_id                AS request_id
             ,itc.movement_id               AS movement_id
             ,itc.mvt_stat_status           AS mvt_stat_status
             ,itc.line_detail_id            AS line_detail_id
             ,itc.invoiced_flag             AS invoiced_flag
             ,itc.staged_ind                AS staged_ind
             ,itc.intorder_posted_ind       AS intorder_posted_ind
             ,itc.lot_costed_ind            AS lot_costed_ind
      FROM    ic_jrnl_mst    ijm           -- OPMジャーナルマスタ(標準)
             ,ic_adjs_jnl    iaj           -- OPM在庫調整ジャーナル(標準)
             ,ic_tran_cmp    itc           -- OPM完了在庫トランザクション(標準)
      WHERE   ijm.attribute1 IS NULL
      AND     iaj.journal_id                = ijm.journal_id
      AND     itc.doc_type                  = iaj.trans_type
      AND     itc.doc_id                    = iaj.doc_id      
      AND     itc.doc_line                  = iaj.doc_line
      AND     itc.doc_type                  = cv_adji
      AND     itc.trans_date  >= id_standard_date - in_archive_range
      AND     itc.trans_date   < id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_cmp_arc  xitca
                WHERE   xitca.trans_id = itc.trans_id
                AND     ROWNUM                = 1
              )
    ;
    /*
    -- 更新対象OPM完了在庫トランザクション（標準）
    CURSOR 更新対象OPM完了在庫トランザクション（標準）取得
      id_基準日  IN DATE
      in_パージレンジ IN NUMBER
    IS
      SELECT 
             OPM完了在庫トランザクション（標準）．トランザクションID
      FROM      OPMジャーナルマスタ(標準)
           ,    OPM在庫調整ジャーナル(標準)
           ,    OPM完了在庫トランザクション(標準)バックアップ
           ,    OPM完了在庫トランザクション(標準)
      WHERE  OPMジャーナルマスタ(標準)．DFF1 IS NULL
      AND OPM在庫調整ジャーナル(標準)．ジャーナルID = OPMジャーナルマスタ(標準)．ジャーナルID
      AND OPM完了在庫トランザクション(標準)バックアップ．文書タイプ = OPM在庫調整ジャーナル(標準)．文書タイプ
      AND OPM完了在庫トランザクション(標準)バックアップ．文書ID = OPM在庫調整ジャーナル(標準)．文書ID
      AND OPM完了在庫トランザクション(標準)バックアップ．取引明細番号 = OPM在庫調整ジャーナル(標準)．取引明細番号
      AND OPM完了在庫トランザクション(標準)バックアップ．文書タイプ = 'ADJI'
      AND OPM完了在庫トランザクション(標準)．トランザクションID = OPM完了在庫トランザクション(標準)バックアップ．トランザクションID
      AND OPM完了在庫トランザクション．取引日 ≧ 基準日－in_パージレンジ
      AND OPM完了在庫トランザクション．取引日 ＜ 基準日
     */
    CURSOR upd_cur(
      id_standard_date          DATE
     ,in_purdge_range           NUMBER
    )
    IS
      SELECT /*+ LEADING(itc) USE_NL(itc xitca iaj ijm) */
              itc.trans_id             AS  trans_id
      FROM    ic_jrnl_mst              ijm     -- OPMジャーナルマスタ(標準)
             ,ic_adjs_jnl              iaj     -- OPM在庫調整ジャーナル(標準)
             ,xxcmn_ic_tran_cmp_arc    xitca   -- OPM完了在庫トランザクション（標準）バックアップ
             ,ic_tran_cmp              itc     -- OPM完了在庫トランザクション(標準)
      WHERE   ijm.attribute1 IS NULL
      AND     iaj.journal_id                = ijm.journal_id
      AND     itc.doc_type                  = iaj.trans_type
      AND     itc.doc_id                    = iaj.doc_id      
      AND     itc.doc_line                  = iaj.doc_line
      AND     itc.doc_type                  = cv_adji
      AND     itc.trans_id                  = xitca.trans_id
      AND     itc.trans_date  >= id_standard_date - in_purdge_range
      AND     itc.trans_date   < id_standard_date
    ;
    -- <カーソル名>レコード型
    lt_tran_cmp_arc_tbl       g_ic_tran_cmp_arc_ttype;           -- OPM完了在庫トランザクション（標準）バックアップテーブル
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
    gn_arc_cnt    := 0;
    gn_upd_cnt    := 0;
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
    ln_バックアップ期間 := バックアップ期間取得共通関数（cv_パージ定義コード）;
     */
    lv_process_part := 'バックアップ期間取得';
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type_1, cv_purge_code);
    IF ( ln_archive_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_arc_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- パージ期間取得
    -- ===============================================
    /*
    ln_パージ期間 := パージ期間取得共通関数（cv_パージ定義コード）;
     */
    lv_process_part := 'パージ期間取得';
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type_0, cv_purge_code);
    IF ( ln_purge_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_purdge_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- ＩＮパラメータの確認
    -- ===============================================
    /*
    iv_proc_dateがNULLの場合
--
      ld_基準日(バックアップ) := 処理日取得共通関数から取得した処理日 - ln_バックアップ期間;
      ld_基準日(パージ) := 処理日取得共通関数から取得した処理日 - ln_パージ期間;
--
    iv_proc_dateがNULLでないの場合
--
      ld_基準日(バックアップ) := TO_DATE(iv_proc_date) - ln_バックアップ期間;
      ld_基準日(パージ) := TO_DATE(iv_proc_date) - ln_パージ期間;
     */
    lv_process_part := 'INパラメータの確認';
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date_arc    := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
      ld_standard_date_purdge := xxcmn_common4_pkg.get_syori_date - ln_purge_period;
--
    ELSE
--
      ld_standard_date_arc    := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
      ld_standard_date_purdge := TO_DATE(iv_proc_date, cv_date_format) - ln_purge_period;
--
    END IF;
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ/バックアップ分割コミット数));
    ln_バックアップレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップレンジ));
    ln_パージレンジ := TO_NUMBER(プロファイル・オプション取得（XXCMN:パージレンジ）);					
     */
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）';
    ln_commit_range  := TO_NUMBER ( fnd_profile.value(cv_xxcmn_commit_range) );
    IF ( ln_commit_range IS NULL ) THEN
--
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
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_archive_range || '）';
    ln_archive_range := TO_NUMBER ( fnd_profile.value(cv_xxcmn_archive_range) );
    IF ( ln_archive_range IS NULL ) THEN
--
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
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_purdge_range || '）';
    ln_purge_range := TO_NUMBER ( fnd_profile.value(cv_xxcmn_purdge_range) );
    IF ( ln_purge_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_purdge_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- バックアップ対象OPM完了在庫トランザクション（標準）取得
    -- ===============================================
    /*
        FOR lr_trx_rec IN バックアップ対象OPM完了在庫トランザクション（標準）取得（ld_基準日(バックアップ)，ln_バックアップレンジ） LOOP
     */
    << archive_loop >>
    FOR lr_archive_rec IN archive_cur(
                           ld_standard_date_arc
                          ,ln_archive_range
                         )
    LOOP
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
        ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準）） > 0
        かつ MOD(ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））, ln_分割コミット数) = 0の場合
         */
        IF (  (ln_arc_cnt_yet > 0)
          AND (MOD(ln_arc_cnt_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））
            INSERT INTO OPM完了在庫トランザクション（標準）バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                lt_OPM完了在庫トランザクション（標準）バックアップテーブル（ln_idx）全カラム
              , SYSDATE
              , 要求ID
            )
          ;
           */
          lv_process_part := 'OPM完了在庫トランザクション（標準）登録１';
          FORALL ln_idx IN 1..ln_arc_cnt_yet
            INSERT INTO xxcmn_ic_tran_cmp_arc VALUES lt_tran_cmp_arc_tbl(ln_idx)
          ;
--
          /*
          lt_OPM完了在庫トランザクション（標準）バックアップテーブル．DELETE;
           */
          lt_tran_cmp_arc_tbl.DELETE;
--
          /*
          gn_バックアップ件数（OPM完了在庫トランザクション（標準）） := gn_バックアップ件数（OPM完了在庫トランザクション（標準））
                                                                      + ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））;
          ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準）） := 0;
          lt_OPM完了在庫トランザクション（標準）テーブル．DELETE;
           */
          gn_arc_cnt     := gn_arc_cnt + ln_arc_cnt_yet;
          ln_arc_cnt_yet := 0;
--
          /*
          COMMIT;
           */
          COMMIT;
--
        END IF;
--
      END IF;
--
      /*
      ln_対象完了在庫トランザクションID := lr_trx_rec．トランザクションID;
       */
      gt_tran_id := lr_archive_rec.trans_id;
--
      /*
      ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））） := ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））） + 1;
      lt_OPM完了在庫トランザクション（標準）テーブル（ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））） := lr_archive_rec;
       */
      ln_arc_cnt_yet := ln_arc_cnt_yet + 1;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_id                     :=  lr_archive_rec.trans_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).item_id                      :=  lr_archive_rec.item_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).line_id                      :=  lr_archive_rec.line_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).co_code                      :=  lr_archive_rec.co_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).orgn_code                    :=  lr_archive_rec.orgn_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).whse_code                    :=  lr_archive_rec.whse_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).lot_id                       :=  lr_archive_rec.lot_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).location                     :=  lr_archive_rec.location;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).doc_id                       :=  lr_archive_rec.doc_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).doc_type                     :=  lr_archive_rec.doc_type;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).doc_line                     :=  lr_archive_rec.doc_line;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).line_type                    :=  lr_archive_rec.line_type;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).reason_code                  :=  lr_archive_rec.reason_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).creation_date                :=  lr_archive_rec.creation_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_date                   :=  lr_archive_rec.trans_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_qty                    :=  lr_archive_rec.trans_qty;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_qty2                   :=  lr_archive_rec.trans_qty2;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).qc_grade                     :=  lr_archive_rec.qc_grade;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).lot_status                   :=  lr_archive_rec.lot_status;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_stat                   :=  lr_archive_rec.trans_stat;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_um                     :=  lr_archive_rec.trans_um;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_um2                    :=  lr_archive_rec.trans_um2;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).op_code                      :=  lr_archive_rec.op_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).gl_posted_ind                :=  lr_archive_rec.gl_posted_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).event_id                     :=  lr_archive_rec.event_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).text_code                    :=  lr_archive_rec.text_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).last_update_date             :=  lr_archive_rec.last_update_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).created_by                   :=  lr_archive_rec.created_by;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).last_updated_by              :=  lr_archive_rec.last_updated_by;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).last_update_login            :=  lr_archive_rec.last_update_login;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).program_application_id       :=  lr_archive_rec.program_application_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).program_id                   :=  lr_archive_rec.program_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).program_update_date          :=  lr_archive_rec.program_update_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).request_id                   :=  lr_archive_rec.request_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).movement_id                  :=  lr_archive_rec.movement_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).mvt_stat_status              :=  lr_archive_rec.mvt_stat_status;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).line_detail_id               :=  lr_archive_rec.line_detail_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).invoiced_flag                :=  lr_archive_rec.invoiced_flag;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).staged_ind                   :=  lr_archive_rec.staged_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).intorder_posted_ind          :=  lr_archive_rec.intorder_posted_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).lot_costed_ind               :=  lr_archive_rec.lot_costed_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).archive_date                 :=  SYSDATE;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).archive_request_id           :=  cn_request_id;
--
    END LOOP archive_loop;
--
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））
      INSERT INTO OPM完了在庫トランザクション（アドオン）バックアップ
      (
           全カラム
        , バックアップ登録日
        , バックアップ要求ID
      )
      VALUES
      (
          lt_OPM完了在庫トランザクション（標準）テーブル（ln_idx）全カラム
        , SYSDATE
        , 要求ID
      )
    ;
     */
    lv_process_part := 'OPM完了在庫トランザクション（標準）登録２';
    FORALL ln_idx IN 1..ln_arc_cnt_yet
      INSERT INTO xxcmn_ic_tran_cmp_arc VALUES lt_tran_cmp_arc_tbl(ln_idx)
    ;
--
    /*
    lt_OPM完了在庫トランザクション（標準）テーブル．DELETE;
     */
    lt_tran_cmp_arc_tbl.DELETE;
--
    /*
    gn_バックアップ件数（OPM完了在庫トランザクション（標準）） := gn_バックアップ件数（OPM完了在庫トランザクション（標準））
                                                                 + ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））;
    ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準）） := 0;
     */
    gn_arc_cnt     := gn_arc_cnt + ln_arc_cnt_yet;
    ln_arc_cnt_yet := 0;
    COMMIT;
--
    -- ===============================================
    -- 更新対象OPM完了在庫トランザクション（標準）取得
    -- ===============================================
    /*
        FOR lr_trx_rec IN 更新対象OPM完了在庫トランザクション（標準）取得（ld_基準日(パージ)，ln_パージレンジ） LOOP
     */
    << upd_loop >>
    FOR lr_upd_rec IN upd_cur(
                           ld_standard_date_purdge
                          ,ln_purge_range
                         )
    LOOP
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
        ln_未コミット更新件数（OPM完了在庫トランザクション（標準）） > 0
        かつ MOD(ln_未コミット更新件数（OPM完了在庫トランザクション（標準））, ln_分割コミット数) = 0の場合
         */
        IF (  (ln_upd_cnt_line_yet > 0)
          AND (MOD(ln_upd_cnt_line_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          gn_更新件数（OPM完了在庫トランザクション（標準）） := gn_更新件数（OPM完了在庫トランザクション（標準））					
                                                                             + ln_未コミット更新件数（OPM完了在庫トランザクション（標準））;
          ln_未コミット更新件数（OPM完了在庫トランザクション（標準）） := 0;
           */
          gn_upd_cnt     := gn_upd_cnt + ln_upd_cnt_line_yet;
          ln_upd_cnt_line_yet := 0;
--
          /*
          COMMIT;
           */
          COMMIT;
--
        END IF;
--
      END IF;
--
      /*
      ln_対象完了在庫トランザクションID := lr_trx_rec．トランザクションID;
       */
      gt_tran_id := lr_upd_rec.trans_id;
--
      /*
      ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））） := ln_未コミットバックアップ件数（OPM完了在庫トランザクション（標準））） + 1;
       */
      ln_upd_cnt_line_yet := ln_upd_cnt_line_yet + 1;
--
      -- ===================================================
      -- 更新対象OPM完了在庫トランザクション（標準））ロック
      -- ===================================================
      /*
      SELECT
            OPM完了在庫トランザクション（標準）．トランザクションID
      FROM OPM完了在庫トランザクション（標準）
      WHERE OPM完了在庫トランザクション（標準）．トランザクションID = lr_trx_rec．トランザクションID
      FOR UPDATE NOWAIT
       */
      lv_process_part := '更新対象OPM完了在庫トランザクション（標準））ロック';
      SELECT  /*+ INDEX(itc IC_TRAN_CMP_PK) */
              itc.trans_id      AS trans_id
      INTO    gt_tran_id
      FROM    ic_tran_cmp  itc
      WHERE   itc.trans_id = lr_upd_rec.trans_id
      FOR UPDATE NOWAIT
      ;
      -- ===============================================
      -- OPM完了在庫トランザクション（標準）更新
      -- ===============================================
      /*
      UPDATE OPM完了在庫トランザクション（標準）
      SET GL転送済フラグ = 1
         ,   最終更新日 = SYSDATE
         ,   最終更新者 = ユーザーID
         ,   最終更新ログイン = ログインID
         ,   プログラムアプリケーションID = プログラムアプリケーションID
         ,   プログラムID = コンカレントプログラムID
         ,   プログラム更新日 = SYSDATE
         ,   リクエストID = コンカレントリクエストID
      WHERE トランザクションID = lr_trx_rec．トランザクションID
      ;
       */
      lv_process_part := 'OPM完了在庫トランザクション（標準）更新';
      UPDATE ic_tran_cmp
      SET    gl_posted_ind            = cv_gl_post_fla
            ,last_update_date         = SYSDATE
            ,last_updated_by          = cn_last_updated_by
            ,last_update_login        = cn_last_update_login
            ,program_application_id   = cn_program_application_id
            ,program_id               = cn_program_id
            ,program_update_date      = SYSDATE
            ,request_id               = cn_request_id
      WHERE  trans_id = lr_upd_rec.trans_id
      ;
--
    END LOOP upd_loop;
--
    /*
    gn_更新件数（OPM完了在庫トランザクション（標準）） := gn_更新件数（OPM完了在庫トランザクション（標準））
                                                                       + ln_未コミット更新件数（OPM完了在庫トランザクション（標準））;
    ln_未コミット更新件数（OPM完了在庫トランザクション（標準）） := 0;
     */
    gn_upd_cnt     := gn_upd_cnt + ln_upd_cnt_line_yet;
    ln_upd_cnt_line_yet := 0;
--
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
        IF ( SQL%BULK_EXCEPTIONS.COUNT > 0 ) THEN
--
          IF ( lt_tran_cmp_arc_tbl.COUNT > 0 ) THEN
            gt_tran_id := lt_tran_cmp_arc_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).trans_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_arc_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(gt_tran_id)
                         );
          ELSE
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_upd_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(gt_tran_id)
                         );
          END IF;
        END IF;
        IF ( (ov_errmsg IS NULL) AND (gt_tran_id IS NOT NULL) ) THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_upd_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(gt_tran_id)
                         );
        END IF;
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||cv_msg_part||SQLERRM;
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
    cv_com_cnt_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';  -- バックアップ、更新件数＆TBL_NAME ＆SHORI 件数： ＆CNT 件
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- 正常件数： ＆CNT 件
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- エラー件数： ＆CNT 件
    cv_proc_date_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- 処理日： ＆PAR
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'CNT';              -- 件数メッセージ用トークン名
    cv_token_tbl_name  CONSTANT VARCHAR2(10)  := 'TBL_NAME';         -- 件数メッセージ用トークン名
    cv_token_shori     CONSTANT VARCHAR2(10)  := 'SHORI';            -- 件数メッセージ用トークン名
    cv_par_token       CONSTANT VARCHAR2(10)  := 'PAR';              -- 処理日メッセージ用トークン名
    cv_tbl_name_cmp    CONSTANT VARCHAR2(100) := 'OPM完了在庫トランザクション（標準）';
    cv_upd             CONSTANT VARCHAR2(10)  := '更新';
    cv_arc             CONSTANT VARCHAR2(100) := 'バックアップ';
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
    --処理日出力
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_proc_date -- 1.処理日
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --バックアップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_com_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_cmp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_arc
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --更新件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_com_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_cmp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_upd
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_upd_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --正常件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt + gn_upd_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    IF (lv_retcode = cv_status_error) THEN
--
      gn_error_cnt := 1;
--
    ELSE
--
      gn_error_cnt := 0;
--
    END IF;
--
    --エラー件数出力
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
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
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
END XXCMN960016C;
/
