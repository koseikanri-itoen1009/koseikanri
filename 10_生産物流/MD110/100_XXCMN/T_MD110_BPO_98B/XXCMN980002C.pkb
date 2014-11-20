CREATE OR REPLACE PACKAGE BODY XXCMN980002C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980002C(body)
 * Description      : 生産原料詳細アドオンバックアップ
 * MD.050           : T_MD050_BPO_98B_生産原料詳細アドオンバックアップ
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
 *  2012/12/07   1.00   Miyamoto         新規作成
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
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_conc_name     VARCHAR2(30);
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
  gn_arc_cnt_header         NUMBER;                                             -- バックアップ件数(移動依頼/指示ヘッダ(アドオン))
  gn_arc_cnt_line           NUMBER;                                             -- バックアップ件数(移動依頼/指示明細(アドオン))
  gn_arc_cnt_lot            NUMBER;                                             -- バックアップ件数(移動ロット詳細(アドオン))
  gt_batch_header_id        gme_batch_header.batch_id%TYPE;                     -- 対象バッチヘッダID
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN980002C'; -- パッケージ名
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
    cv_get_priod_msg            CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';  -- バックアップ期間の取得に失敗しました。
    cv_get_profile_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- プロファイル[ ＆NG_PROFILE ]の取得に失敗しました。
    cv_local_others_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-11026';  -- ＆SHORI 処理に失敗しました。【 ＆KINOUMEI 】 ＆KEYNAME ： ＆KEY
    cv_token_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_shori              CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_token_kinoumei           CONSTANT VARCHAR2(10)  := 'KINOUMEI';
    cv_token_keyname            CONSTANT VARCHAR2(10)  := 'KEYNAME';
    cv_token_key                CONSTANT VARCHAR2(10)  := 'KEY';
    cv_token_proc_date          CONSTANT VARCHAR2(100) := '処理日';
    cv_token_bkup               CONSTANT VARCHAR2(100) := 'バックアップ';
    cv_token_xmd                CONSTANT VARCHAR2(100) := '生産原料詳細(アドオン)';
    cv_token_xmld               CONSTANT VARCHAR2(100) := '移動ロット詳細(アドオン)';
    cv_token_batch_id           CONSTANT VARCHAR2(100) := 'バッチID';
    cv_token_param              CONSTANT VARCHAR2(50)  := 'ERROR_PARAM';
    cv_token_value              CONSTANT VARCHAR2(50)  := 'ERROR_VALUE';
--
    cv_xxcmn_commit_range       CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_archive_range      CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';
--
    cv_doc_type_40              CONSTANT VARCHAR2(2)   := '40';
--
    cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_sqlerrm VARCHAR2(5000);
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_purge_type   CONSTANT VARCHAR2(1)  := '1';                               -- パージタイプ(1:バックアップ処理期間)
    cv_purge_code   CONSTANT VARCHAR2(30) := '9801';                            -- パージ定義コード
--
    -- *** ローカル変数 ***
    ln_arc_cnt_header_yet     NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数(移動依頼/指示ヘッダ(アドオン))
    ln_arc_cnt_line_yet       NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数(移動依頼/指示明細(アドオン))
    ln_arc_cnt_lot_yet        NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数(移動ロット詳細(アドオン))
    ln_archive_period         NUMBER;                                           -- バックアップ期間
    ln_archive_range          NUMBER;                                           -- バックアップレンジ
    ld_standard_date          DATE;                                             -- 基準日
    ln_commit_range           NUMBER;                                           -- 分割コミット数
    lv_process_part           VARCHAR2(1000);                                   -- 処理部
    ln_key_id                 NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    CURSOR 生産バッチヘッダ取得
      id_基準日       IN DATE,
      in_バックアップレンジ IN NUMBER
    IS
      SELECT 生産バッチヘッダ.バッチID
      FROM   生産バッチヘッダ
      WHERE  生産バッチヘッダ.計画開始日 >= id_基準日  - in_バックアップレンジ
      AND    生産バッチヘッダ.計画開始日 <  id_基準日
      ;
    */
    CURSOR batch_header_cur(
      id_standard_date      DATE
     ,in_purge_range        NUMBER
    )
    IS
      SELECT /*+ INDEX(gbh GME_GBH_N01) */
              gbh.batch_id            AS batch_id
      FROM    gme_batch_header           gbh                    --生産ﾊﾞｯﾁﾍｯﾀﾞ
      WHERE   gbh.plan_start_date     >= id_standard_date - in_purge_range
      AND     gbh.plan_start_date     <  id_standard_date
      ;
--
    /*
    CURSOR バックアップ対象生産原料詳細(アドオン)取得
       it_バッチID  IN 生産バッチヘッダ.バッチID%TYPE
    IS
      SELECT
             生産原料詳細(アドオン).全カラム
      FROM   生産原料詳細,
             生産原料詳細(アドオン)
      WHERE  生産原料詳細.バッチID = in_バッチID
      AND    生産原料詳細.生産原料詳細ID  = 生産原料詳細(アドオン).生産原料詳細ID
      AND NOT EXISTS (
               SELECT  1
               FROM 生産原料詳細(アドオン)バックアップ
               WHERE 生産原料詳細(アドオン).生産原料詳細アドオンID = 生産原料詳細(アドオン)バックアップ.生産原料詳細アドオンＩＤ
               AND ROWNUM = 1
             )
      ;
    */
    CURSOR mdtl_addn_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmd.mtl_detail_addon_id      AS  mtl_detail_addon_id
             ,xmd.batch_id                 AS  batch_id
             ,xmd.material_detail_id       AS  material_detail_id
             ,xmd.item_id                  AS  item_id
             ,xmd.lot_id                   AS  lot_id
             ,xmd.instructions_qty         AS  instructions_qty
             ,xmd.invested_qty             AS  invested_qty
             ,xmd.return_qty               AS  return_qty
             ,xmd.mtl_prod_qty             AS  mtl_prod_qty
             ,xmd.mtl_mfg_qty              AS  mtl_mfg_qty
             ,xmd.location_code            AS  location_code
             ,xmd.plan_type                AS  plan_type
             ,xmd.plan_number              AS  plan_number
             ,xmd.created_by               AS  created_by
             ,xmd.creation_date            AS  creation_date
             ,xmd.last_updated_by          AS  last_updated_by
             ,xmd.last_update_date         AS  last_update_date
             ,xmd.last_update_login        AS  last_update_login
             ,xmd.request_id               AS  request_id
             ,xmd.program_application_id   AS  program_application_id
             ,xmd.program_id               AS  program_id
             ,xmd.program_update_date      AS  program_update_date
      FROM    gme_material_details       gmd,                    --生産原料詳細
              xxwip_material_detail      xmd                     --生産原料詳細(ｱﾄﾞｵﾝ)
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmd.material_detail_id
      AND NOT EXISTS (
               SELECT  1
               FROM xxcmn_material_detail_arc xmda
               WHERE xmd.material_detail_id = xmda.material_detail_id
               AND ROWNUM = 1
             )
      ;
--
    /*
    CURSOR バックアップ対象移動ロット詳細(アドオン)取得
       it_バッチID  IN 生産バッチヘッダ.バッチID%TYPE
    IS
      SELECT
             移動ロット詳細(アドオン).全カラム
      FROM   生産原料詳細,
             移動ロット詳細(アドオン)
      WHERE  生産原料詳細.バッチID = in_バッチID
      AND    生産原料詳細.生産原料詳細ID  = 移動ロット詳細(アドオン).明細ID
      AND    移動ロット詳細(アドオン).文書タイプ = '40' 
      AND NOT EXISTS (
               SELECT  1
               FROM    移動ロット詳細(アドオン)バックアップ
               WHERE  移動ロット詳細(アドオン).ロット詳細ID = 移動ロット詳細(アドオン)バックアップ.ロット詳細ID 
               AND ROWNUM = 1
             )
    */
    CURSOR mlot_dtl_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmld.mov_lot_dtl_id                 AS mov_lot_dtl_id
             ,xmld.mov_line_id                    AS mov_line_id
             ,xmld.document_type_code             AS document_type_code
             ,xmld.record_type_code               AS record_type_code
             ,xmld.item_id                        AS item_id
             ,xmld.item_code                      AS item_code
             ,xmld.lot_id                         AS lot_id
             ,xmld.lot_no                         AS lot_no
             ,xmld.actual_date                    AS actual_date
             ,xmld.actual_quantity                AS actual_quantity
             ,xmld.before_actual_quantity         AS before_actual_quantity
             ,xmld.automanual_reserve_class       AS automanual_reserve_class
             ,xmld.created_by                     AS created_by
             ,xmld.creation_date                  AS creation_date
             ,xmld.last_updated_by                AS last_updated_by
             ,xmld.last_update_date               AS last_update_date
             ,xmld.last_update_login              AS last_update_login
             ,xmld.request_id                     AS request_id
             ,xmld.program_application_id         AS program_application_id
             ,xmld.program_id                     AS program_id
             ,xmld.program_update_date            AS program_update_date
             ,xmld.actual_confirm_class           AS actual_confirm_class
      FROM    gme_material_details       gmd,                    --生産原料詳細
              xxinv_mov_lot_details      xmld                    --移動ロット詳細(ｱﾄﾞｵﾝ)
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmld.mov_line_id
      AND     xmld.document_type_code  = cv_doc_type_40
      AND NOT EXISTS (
               SELECT  /*+ INDEX(xmlda XXINV_MOV_LOT_DETAILS_PK) */
                       1
               FROM    xxcmn_mov_lot_details_arc xmlda
               WHERE   xmld.mov_lot_dtl_id = xmlda.mov_lot_dtl_id
               AND ROWNUM = 1
             )
      ;
    TYPE l_batch_header_ttype   IS TABLE OF gme_batch_header.batch_id%TYPE    INDEX BY BINARY_INTEGER;
    TYPE l_mat_line_ttype     IS TABLE OF xxcmn_material_detail_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
    TYPE l_mov_lot_dtl_ttype  IS TABLE OF xxcmn_mov_lot_details_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
    -- <カーソル名>レコード型
    l_batch_header_tab       l_batch_header_ttype;                               -- 生産バッチヘッダ
    l_mat_line_tab           l_mat_line_ttype;                                   -- 生産原料詳細(アドオン)バックアップテーブル
    l_mov_lot_dtl_tab        l_mov_lot_dtl_ttype;                                -- 移動ロット詳細(アドオン)テーブル
    l_mov_lot_dtl_key_tab    l_batch_header_ttype;                               -- 移動ロット詳細(アドオン)バッチID用テーブル
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
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_arc_cnt_header := 0;
    gn_arc_cnt_line   := 0;
    gn_arc_cnt_lot    := 0;
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
    ln_バックアップ期間 := バックアップ期間取得共通関数(cv_パージ定義コード);
     */
    lv_process_part := 'バックアップ期間取得';
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_archive_period IS NULL ) THEN
--
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
    lv_process_part := '処理日取得';
    /*
    iv_proc_dateがNULLの場合
      ld_基準日 := 処理日取得共通関数から取得した処理日 - ln_バックアップ期間;
--
    iv_proc_dateがNULLでない場合
      ld_基準日 := TO_DATE(iv_proc_date,'YYYY/MM/DD') - ln_バックアップ期間;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
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
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ/バックアップ分割コミット数));
    ln_バックアップレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップレンジ));
     */
    lv_process_part := 'プロファイル・オプション値取得(' || cv_xxcmn_commit_range || ')';
    ln_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    END IF;

    lv_process_part := 'プロファイル・オプション値取得(' || cv_xxcmn_archive_range || ')';
    ln_archive_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_archive_range));
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
    END IF;
--
    -- ===============================================
    -- 主処理
    -- ===============================================
    /*
    OPEN 生産バッチヘッダ取得(
                                    ld_基準日
                                    ,ln_バックアップレンジ 
                                   );
    FETCH 生産バッチヘッダ取得 BULK COLLECT INTO l_生産バッチヘッダテーブル;
     */
    OPEN batch_header_cur(
                                    ld_standard_date
                                   ,ln_archive_range
                                   );
    FETCH batch_header_cur BULK COLLECT INTO l_batch_header_tab;
    /*
    gn_処理件数(生産バッチヘッダ) := l_生産バッチヘッダテーブル.COUNT;
    IF gn_処理件数(生産バッチヘッダ) > 0 THEN
      BEGIN
        << batch_header_loop >>
        FOR ln_main_idx in 1 .. l_生産バッチヘッダテーブル.COUNT
        LOOP
    */
    gn_arc_cnt_header := l_batch_header_tab.COUNT;
    IF ( gn_arc_cnt_header ) > 0 THEN
      BEGIN
        << batch_header_loop >>
        FOR ln_main_idx in 1 .. l_batch_header_tab.COUNT
        LOOP
--
          /*
          gt_対象バッチヘッダID := 生産バッチヘッダテーブル.移動ヘッダID;
           */
          gt_batch_header_id := l_batch_header_tab(ln_main_idx);
          -- ===============================================
          -- 分割コミット
          -- ===============================================
          /*
          NVL(ln_分割コミット数, 0) <> 0の場合
           */
          IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
            /*
            ln_未コミットバックアップ件数(生産バッチヘッダ) > 0
            かつ MOD(ln_未コミットバックアップ件数(生産バッチヘッダ), ln_分割コミット数) = 0の場合
             */
            IF (  (ln_arc_cnt_header_yet > 0)
              AND (MOD(ln_arc_cnt_header_yet, ln_commit_range) = 0)
               )
            THEN
--
              /*
              FORALL ln_idx1 IN 1..ln_未コミットバックアップ件数(生産原料詳細(アドオン))
                INSERT INTO 生産原料詳細(アドオン)バックアップ
                (
                  全カラム
                , バックアップ登録日
                , バックアップ要求ID
                )
                VALUES
                (
                  lt_生産原料詳細(アドオン)テーブル(ln_idx1)全カラム
                , SYSDATE
                , 要求ID
                )
               */
              BEGIN
                lv_process_part := '生産原料詳細(アドオン)登録１';
                FORALL ln_idx IN 1..ln_arc_cnt_line_yet
                  INSERT INTO xxcmn_material_detail_arc VALUES l_mat_line_tab(ln_idx)
                ;
              EXCEPTION
                WHEN OTHERS THEN
                  ln_key_id := l_mat_line_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).batch_id;
                  ov_errmsg := xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_appl_short_name
                                ,iv_name         => cv_local_others_msg
                                ,iv_token_name1  => cv_token_shori
                                ,iv_token_value1 => cv_token_bkup
                                ,iv_token_name2  => cv_token_kinoumei
                                ,iv_token_value2 => cv_token_xmd
                                ,iv_token_name3  => cv_token_keyname
                                ,iv_token_value3 => cv_token_batch_id
                                ,iv_token_name4  => cv_token_key
                                ,iv_token_value4 => TO_CHAR(ln_key_id)
                               );
                  lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
                  RAISE local_process_expt;
              END;
--
              /*
              FORALL ln_idx IN 1..ln_未コミットバックアップ件数(移動ロット詳細(アドオン))
                INSERT INTO 移動ロット詳細(アドオン)バックアップ
                (
                    全カラム
                  , バックアップ登録日
                  , バックアップ要求ID
                )
                VALUES
                (
                    移動ロット詳細(アドオン)テーブル(ln_idx)全カラム
                  , SYSDATE
                  , 要求ID
                )
               */
              BEGIN
                lv_process_part := '移動ロット詳細(アドオン)登録１';
                FORALL ln_idx IN 1..ln_arc_cnt_lot_yet
                  INSERT INTO xxcmn_mov_lot_details_arc VALUES l_mov_lot_dtl_tab(ln_idx)
                ;
              EXCEPTION
                WHEN OTHERS THEN
                  ln_key_id := l_mov_lot_dtl_key_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX);
                  ov_errmsg := xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_appl_short_name
                                ,iv_name         => cv_local_others_msg
                                ,iv_token_name1  => cv_token_shori
                                ,iv_token_value1 => cv_token_bkup
                                ,iv_token_name2  => cv_token_kinoumei
                                ,iv_token_value2 => cv_token_xmld
                                ,iv_token_name3  => cv_token_keyname
                                ,iv_token_value3 => cv_token_batch_id
                                ,iv_token_name4  => cv_token_key
                                ,iv_token_value4 => TO_CHAR(ln_key_id)
                               );
                  lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
                  RAISE local_process_expt;
              END;
--
              /*
              ln_未コミット件数(生産バッチヘッダ)   := 0;
              */
              ln_arc_cnt_header_yet := 0;
--
              /*
              gn_バックアップ件数(生産原料詳細(アドオン)) := gn_バックアップ件数(生産原料詳細(アドオン)) 
                                                              + ln_未コミットバックアップ件数(生産原料詳細(アドオン));
              ln_未コミットバックアップ件数(生産原料詳細(アドオン)) := 0;
              l_生産原料詳細(アドオン)テーブル.DELETE;
              */
              gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
              ln_arc_cnt_line_yet := 0;
              l_mat_line_tab.DELETE;
--
              /*
              gn_バックアップ件数(移動ロット詳細(アドオン)) := gn_バックアップ件数(移動ロット詳細(アドオン)) 
                                                              + ln_未コミットバックアップ件数(移動ロット詳細(アドオン));
              ln_未コミットバックアップ件数(移動ロット詳細(アドオン)) := 0;
              l_移動ロット詳細(アドオン)テーブル.DELETE;
               */
              gn_arc_cnt_lot     := gn_arc_cnt_lot + ln_arc_cnt_lot_yet;
              ln_arc_cnt_lot_yet := 0;
              l_mov_lot_dtl_tab.DELETE;
              l_mov_lot_dtl_key_tab.DELETE;
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
--
          -- ===============================================
          -- バックアップ対象生産原料詳細(アドオン)取得
          -- ===============================================
          /*
          FOR lr_mdtl_addn_rec IN バックアップ対象生産原料詳細(アドオン)取得 (gt_対象バッチヘッダID) LOOP
           */
          << archive_mov_line_loop >>
          FOR lr_mdtl_addn_rec IN mdtl_addn_cur(
                               gt_batch_header_id
                             )
          LOOP
            /*
            ln_未コミットバックアップ件数(生産原料詳細(アドオン)) := ln_未コミットバックアップ件数(生産原料詳細(アドオン)) + 1;
            lt_生産原料詳細(アドオン)テーブル(ln_未コミットバックアップ件数(生産原料詳細(アドオン))) := lr_mdtl_addn_rec;
             */
            ln_arc_cnt_line_yet := ln_arc_cnt_line_yet + 1;
            l_mat_line_tab(ln_arc_cnt_line_yet).mtl_detail_addon_id     := lr_mdtl_addn_rec.mtl_detail_addon_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).batch_id                := lr_mdtl_addn_rec.batch_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).material_detail_id      := lr_mdtl_addn_rec.material_detail_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).item_id                 := lr_mdtl_addn_rec.item_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).lot_id                  := lr_mdtl_addn_rec.lot_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).instructions_qty        := lr_mdtl_addn_rec.instructions_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).invested_qty            := lr_mdtl_addn_rec.invested_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).return_qty              := lr_mdtl_addn_rec.return_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).mtl_prod_qty            := lr_mdtl_addn_rec.mtl_prod_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).mtl_mfg_qty             := lr_mdtl_addn_rec.mtl_mfg_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).location_code           := lr_mdtl_addn_rec.location_code;
            l_mat_line_tab(ln_arc_cnt_line_yet).plan_type               := lr_mdtl_addn_rec.plan_type;
            l_mat_line_tab(ln_arc_cnt_line_yet).plan_number             := lr_mdtl_addn_rec.plan_number;
            l_mat_line_tab(ln_arc_cnt_line_yet).created_by              := lr_mdtl_addn_rec.created_by;
            l_mat_line_tab(ln_arc_cnt_line_yet).creation_date           := lr_mdtl_addn_rec.creation_date;
            l_mat_line_tab(ln_arc_cnt_line_yet).last_updated_by         := lr_mdtl_addn_rec.last_updated_by;
            l_mat_line_tab(ln_arc_cnt_line_yet).last_update_date        := lr_mdtl_addn_rec.last_update_date;
            l_mat_line_tab(ln_arc_cnt_line_yet).last_update_login       := lr_mdtl_addn_rec.last_update_login;
            l_mat_line_tab(ln_arc_cnt_line_yet).request_id              := lr_mdtl_addn_rec.request_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).program_application_id  := lr_mdtl_addn_rec.program_application_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).program_id              := lr_mdtl_addn_rec.program_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).program_update_date     := lr_mdtl_addn_rec.program_update_date;
            l_mat_line_tab(ln_arc_cnt_line_yet).archive_date               := SYSDATE;
            l_mat_line_tab(ln_arc_cnt_line_yet).archive_request_id         := cn_request_id;
--
          END LOOP archive_mov_line_loop;
          -- ===============================================
          -- バックアップ対象移動ロット詳細(アドオン)取得
          -- ===============================================
          /*
          FOR lr_lot_rec IN バックアップ対象移動ロット詳細(アドオン)取得(gt_対象バッチヘッダID) LOOP
           */
          << archive_mov_lot_dtl_loop >>
          FOR lr_lot_rec IN mlot_dtl_cur(
                             gt_batch_header_id
                            )
          LOOP
--
            /*
            ln_未コミットバックアップ件数(移動ロット詳細(アドオン)) := ln_未コミットバックアップ件数(移動ロット詳細(アドオン)) + 1;
            l_移動ロット詳細(アドオン)テーブル(ln_未コミットバックアップ件数(移動ロット詳細(アドオン)) := lr_lot_rec;
             */
            ln_arc_cnt_lot_yet := ln_arc_cnt_lot_yet + 1;
            l_mov_lot_dtl_key_tab(ln_arc_cnt_lot_yet)                      := gt_batch_header_id;           --紐付くバッチIDを別コレクションに格納
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).mov_lot_dtl_id           := lr_lot_rec.mov_lot_dtl_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).mov_line_id              := lr_lot_rec.mov_line_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).document_type_code       := lr_lot_rec.document_type_code;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).record_type_code         := lr_lot_rec.record_type_code;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).item_id                  := lr_lot_rec.item_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).item_code                := lr_lot_rec.item_code;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).lot_id                   := lr_lot_rec.lot_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).lot_no                   := lr_lot_rec.lot_no;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).actual_date              := lr_lot_rec.actual_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).actual_quantity          := lr_lot_rec.actual_quantity;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).before_actual_quantity   := lr_lot_rec.before_actual_quantity;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).automanual_reserve_class := lr_lot_rec.automanual_reserve_class;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).created_by               := lr_lot_rec.created_by;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).creation_date            := lr_lot_rec.creation_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).last_updated_by          := lr_lot_rec.last_updated_by;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).last_update_date         := lr_lot_rec.last_update_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).last_update_login        := lr_lot_rec.last_update_login;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).request_id               := lr_lot_rec.request_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).program_application_id   := lr_lot_rec.program_application_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).program_id               := lr_lot_rec.program_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).program_update_date      := lr_lot_rec.program_update_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).actual_confirm_class     := lr_lot_rec.actual_confirm_class;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).archive_date             := SYSDATE;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).archive_request_id       := cn_request_id;
--
          END LOOP archive_mov_lot_dtl_loop;
--
          /*
          ln_未コミット件数(生産バッチヘッダ) := ln_未コミット件数(生産バッチヘッダ) + 1;
          */
          ln_arc_cnt_header_yet := ln_arc_cnt_header_yet + 1;
--
        END LOOP archive_mov_header_loop;
        -- ===============================================
        -- 分割コミット対象外の残データ INSERT処理
        -- ===============================================
        /*
        -- 生産原料詳細(アドオン)
        FORALL ln_idx IN 1..ln_未コミットバックアップ件数(生産原料詳細(アドオン))
            INSERT INTO 生産原料詳細(アドオン)バックアップ
            (
               全カラム
             , バックアップ登録日
             , バックアップ要求ID
            )
            VALUES
            (
              lt_生産原料詳細(アドオン)テーブル(ln_idx)全カラム
            , SYSDATE
            , 要求ID
            )
        */
        lv_process_part := '生産原料詳細(アドオン)登録２';
        BEGIN
          FORALL ln_idx IN 1..ln_arc_cnt_line_yet
            INSERT INTO xxcmn_material_detail_arc VALUES l_mat_line_tab(ln_idx)
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_key_id := l_mat_line_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).batch_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_msg
                          ,iv_token_name1  => cv_token_shori
                          ,iv_token_value1 => cv_token_bkup
                          ,iv_token_name2  => cv_token_kinoumei
                          ,iv_token_value2 => cv_token_xmd
                          ,iv_token_name3  => cv_token_keyname
                          ,iv_token_value3 => cv_token_batch_id
                          ,iv_token_name4  => cv_token_key
                          ,iv_token_value4 => TO_CHAR(ln_key_id)
                         );
            lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
            RAISE local_process_expt;
        END;
--
        /*
        --移動ロット詳細(アドオン)
        FORALL ln_idx IN 1..ln_未コミットバックアップ件数(移動ロット詳細(アドオン))
            INSERT INTO 移動ロット詳細(アドオン)バックアップ
            (
               全カラム
             , バックアップ登録日
             , バックアップ要求ID
            )
            VALUES
            (
              lt_移動ロット詳細(アドオン)テーブル(ln_idx)全カラム
            , SYSDATE
            , 要求ID
            )
         */
        lv_process_part := '移動ロット詳細(アドオン)登録２';
        BEGIN
          FORALL ln_idx IN 1..ln_arc_cnt_lot_yet
            INSERT INTO xxcmn_mov_lot_details_arc VALUES l_mov_lot_dtl_tab(ln_idx)
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_key_id := l_mov_lot_dtl_key_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX);
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_msg
                          ,iv_token_name1  => cv_token_shori
                          ,iv_token_value1 => cv_token_bkup
                          ,iv_token_name2  => cv_token_kinoumei
                          ,iv_token_value2 => cv_token_xmld
                          ,iv_token_name3  => cv_token_keyname
                          ,iv_token_value3 => cv_token_batch_id
                          ,iv_token_name4  => cv_token_key
                          ,iv_token_value4 => TO_CHAR(ln_key_id)
                         );
            lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
            RAISE local_process_expt;
        END;
        /*
        gn_バックアップ件数(生産原料詳細(アドオン))  := gn_バックアップ件数(生産原料詳細(アドオン))
                                                       + ln_未コミットバックアップ件数(生産原料詳細(アドオン));
        gn_バックアップ件数(移動ロット詳細(アドオン)):= gn_バックアップ件数(移動ロット詳細(アドオン))
                                                       + ln_未コミットバックアップ件数(移動ロット詳細(アドオン));
        ln_未コミットバックアップ件数(生産バッチヘッダ)         := 0;
        ln_未コミットバックアップ件数(生産原料詳細(アドオン))   := 0;
        ln_未コミットバックアップ件数(移動ロット詳細(アドオン)) := 0;
        lt_生産原料詳細(アドオン)テーブル.DELETE;
        lt_移動ロット詳細(アドオン)テーブル.DELETE;
         */
        gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
        gn_arc_cnt_lot     := gn_arc_cnt_lot + ln_arc_cnt_lot_yet;
        ln_arc_cnt_header_yet := 0;
        ln_arc_cnt_line_yet := 0;
        ln_arc_cnt_lot_yet := 0;
        l_mat_line_tab.DELETE;
        l_mov_lot_dtl_tab.DELETE;
        l_mov_lot_dtl_key_tab.DELETE;
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE local_process_expt;
      END;
--
    END IF;
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN local_process_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_sqlerrm;
      ov_retcode := cv_status_error;
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
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCMN';                          -- アドオン：共通・IF領域
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';                -- ＆TBL_NAME ＆SHORI 件数： ＆CNT 件
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                            -- 件数メッセージ用トークン名(件数)
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                       -- 件数メッセージ用トークン名(テーブル名)
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                          -- 件数メッセージ用トークン名(処理名)
    cv_table_cnt_xmda   CONSTANT VARCHAR2(100) := '生産原料詳細(アドオン)';         -- 件数メッセージ用テーブル名
    cv_table_cnt_xmld   CONSTANT VARCHAR2(100) := '移動ロット明細(アドオン)';       -- 件数メッセージ用テーブル名
    cv_shori_cnt_arc    CONSTANT VARCHAR2(100) := 'バックアップ';                   -- 件数メッセージ用処理名
    cv_success_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';                -- 正常件数： ＆CNT 件
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';                -- エラー件数： ＆CNT 件
    cv_proc_date_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';                -- 処理日： ＆PAR
    cv_par_token        CONSTANT VARCHAR2(100) := 'PAR';                            -- 処理日メッセージ用トークン名
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
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
       iv_proc_date -- 1.処理日
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --lineバックアップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmda
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_line)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --lotバックアップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmld
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_lot)
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
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_line)
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
                    ,iv_token_name1  => cv_token_cnt
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
END XXCMN980002C;
/
