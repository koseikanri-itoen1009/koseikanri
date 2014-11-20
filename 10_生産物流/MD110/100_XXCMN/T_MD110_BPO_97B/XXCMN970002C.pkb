CREATE OR REPLACE PACKAGE BODY XXCMN970002C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN970002C(body)
 * Description      : 棚卸月末在庫テーブルバックアップ
 * MD.050           : T_MD050_BPO_97B_棚卸月末在庫テーブルバックアップ
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
 *  2012/11/09   1.00  T.Makuta          新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_request_id      CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cv_date_format1    CONSTANT VARCHAR2(6)  := 'YYYYMM';
  cv_date_format2    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
  cv_purge_type      CONSTANT VARCHAR2(1)  := '1';                        --ﾊﾟｰｼﾞﾀｲﾌﾟ(1:BUCKUP期間)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9701';                     --ﾊﾟｰｼﾞ定義ｺｰﾄﾞ
--
  --=============
  --メッセージ
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_archive_range
                     CONSTANT VARCHAR2(50) := 'XXCMN_ARCHIVE_RANGE_MONTH'; --XXCMN:ﾊﾞｯｸｱｯﾌﾟﾚﾝｼﾞ
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
  cv_others_err_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11027';          --ﾊﾞｯｸｱｯﾌﾟ処理失敗
  cv_token_key       CONSTANT VARCHAR2(10) := 'KEY';                      --ﾊﾞｯｸｱｯﾌﾟ処理MSG用ﾄｰｸﾝ名
--
  --TBL_NAME SHORI 件数： CNT 件
  cv_end_msg         CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';          --処理内容出力
  cv_token_tblname   CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname         CONSTANT VARCHAR2(90) := '棚卸月末在庫(アドオン)';
  cv_token_shori     CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori           CONSTANT VARCHAR2(50) := 'バックアップ';
  cv_cnt_token       CONSTANT VARCHAR2(10) := 'CNT';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                                     --対象件数
  gn_normal_cnt      NUMBER;                                     --正常件数
  gn_error_cnt       NUMBER;                                     --エラー件数
  gn_arc_cnt         NUMBER;                                     --ﾊﾞｯｸｱｯﾌﾟ件数
  gt_inv_month_stc_id xxinv_stc_inventory_month_stck.invent_monthly_stock_id%TYPE; 
                                                                 --棚卸月末在庫ID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN970002C'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE lt_month_stc_ttype IS TABLE OF xxcmn_stc_inv_month_stck_arc%ROWTYPE INDEX BY BINARY_INTEGER;
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
    ln_arc_cnt_yet            NUMBER;                           --未ｺﾐｯﾄﾊﾞｯｸｱｯﾌﾟ件数
    ln_archive_period         NUMBER;                           --バックアップ期間
    ln_archive_range          NUMBER;                           --バックアップレンジ
    lv_standard_ym            VARCHAR2(6);                      --基準年月(YYYYMM)
    ln_proc_date              NUMBER;
    ln_commit_range           NUMBER;                           --分割コミット数
    lv_process_part           VARCHAR2(1000);                   --処理部
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    CURSOR バックアップ対象棚卸月末在庫(アドオン)取得
      it_基準年月  IN 棚卸月末在庫(アドオン).棚卸年月%TYPE
      in_バックアップレンジ IN NUMBER
    IS
      SELECT 
             棚卸月末在庫(アドオン).全カラム,
             バックアップ登録日,
             バックアップ要求ID,
             NULL,                  --パージ実行日
             NULL                   --パージ要求ID
      FROM   棚卸月末在庫(アドオン)
      WHERE  棚卸月末在庫(アドオン).棚卸年月 >= TO_CHAR(ADD_MONTHS(TO_DATE(it_基準年月，'YYYYMM')，
                                                         (in_バックアップレンジ * -1))，'YYYYMM')
      AND    棚卸月末在庫(アドオン).棚卸年月 < it_基準年月
      AND NOT EXISTS (SELECT 1
                      FROM   棚卸月末在庫(アドオン)バックアップ
                      WHERE  棚卸月末在庫(アドオン)バックアップ.棚卸月末在庫ＩＤ = 
                             棚卸月末在庫(アドオン).棚卸月末在庫ＩＤ
                      AND ROWNUM = 1
                     );
    */
--
    CURSOR mstck_cur(
      it_standard_ym        xxinv_stc_inventory_month_stck.invent_monthly_stock_id%TYPE
     ,in_archive_range      NUMBER
    )
    IS
      SELECT /*+ INDEX(xsim XXINV_SIMS_N03) */
             xsim.invent_monthly_stock_id  AS  invent_monthly_stock_id,   --棚卸月末在庫ID
             xsim.whse_code                AS  whse_code,                 --倉庫コード
             xsim.item_id                  AS  item_id,                   --品目ID
             xsim.item_code                AS  item_code,                 --品目コード
             xsim.lot_id                   AS  lot_id,                    --ロットID
             xsim.lot_no                   AS  lot_no,                    --ロットNo.
             xsim.monthly_stock            AS  monthly_stock,             --月末在庫数
             xsim.cargo_stock              AS  cargo_stock,               --積送中在庫数
             xsim.invent_ym                AS  invent_ym,                 --棚卸年月
             xsim.created_by               AS  created_by,                --作成者
             xsim.creation_date            AS  creation_date,             --作成日
             xsim.last_updated_by          AS  last_updated_by,           --最終更新者
             xsim.last_update_date         AS  last_update_date,          --最終更新日
             xsim.last_update_login        AS  last_update_login,         --最終更新ログイン
             xsim.request_id               AS  request_id,                --要求ID
             xsim.program_application_id   AS  program_application_id,    --ｱﾌﾟﾘｹｰｼｮﾝID
             xsim.program_id               AS  program_id,                --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
             xsim.program_update_date      AS  program_update_date,       --プログラム更新日
             xsim.cargo_stock_not_stn      AS  cargo_stock_not_stn,       --積送中在庫数(標準なし)
             SYSDATE                       AS  archive_date,              --バックアップ登録日
             cn_request_id                 AS  archive_request_id,        --バックアップ要求ID
             NULL                          AS  purge_date,                --パージ実行日
             NULL                          AS  purge_request_id           --パージ要求ID
      FROM   xxinv_stc_inventory_month_stck xsim                          --棚卸月末在庫(アドオン)
      WHERE  xsim.invent_ym >= TO_CHAR(ADD_MONTHS(TO_DATE(it_standard_ym,cv_date_format1),
                                                         (ln_archive_range * -1)),cv_date_format1)
      AND    xsim.invent_ym <  it_standard_ym
      AND NOT EXISTS
              (SELECT 1
               FROM  xxcmn_stc_inv_month_stck_arc   xsima             --棚卸月末在庫(ｱﾄﾞｵﾝ)ﾊﾞｯｸｱｯﾌﾟ
               WHERE xsim.invent_monthly_stock_id = xsima.invent_monthly_stock_id
               AND   ROWNUM = 1
              );
--
    -- <カーソル名>レコード型
    lt_mstc_tbl      lt_month_stc_ttype;                              --棚卸月末在庫(ｱﾄﾞｵﾝ)ﾃｰﾌﾞﾙ
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
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_arc_cnt        := 0;
    ln_arc_cnt_yet    := 0;
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
    ln_バックアップ期間 := バックアップ期間/パージ期間取得関数(cv_パージタイプ,cv_パージコード);
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
      lv_基準年月 := TO_CHAR(ADD_MONTHS(処理日取得共通関数より取得した処理日，
                                                           (ln_バックアップ期間 * -1))，'YYYYMM');
--
    iv_proc_dateがNULLでない場合
--
      lv_基準年月 := TO_CHAR(ADD_MONTHS(TO_DATE(iv_proc_date),
                                                           (ln_バックアップ期間 * -1)),'YYYYMM');
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      lv_standard_ym := TO_CHAR(ADD_MONTHS(xxcmn_common4_pkg.get_syori_date,
                                           (ln_archive_period * -1)),cv_date_format1);
--
    ELSE
--
      ln_proc_date   := TO_NUMBER(REPLACE(iv_proc_date,'/',''));
      lv_standard_ym := TO_CHAR(ADD_MONTHS(TO_DATE(ln_proc_date,cv_date_format2),
                                                  (ln_archive_period * -1)),cv_date_format1);
--
    END IF;
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）：';
--
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップ分割コミット数));
     */
    ln_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_archive_range || '）:';
--
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
    FOR lr_mstck_rec IN バックアップ対象棚卸月末在庫(アドオン)取得
                                                    (lv_基準年月，ln_バックアップレンジ) LOOP
   */
    << stc_inv_mstck_loop >>
    FOR lr_mstck_rec IN mstck_cur(lv_standard_ym
                                 ,ln_archive_range ) LOOP
--
      -- ===============================================
      -- 分割コミット
      -- ===============================================
      /*
      NVL(ln_分割コミット数, 0) <> 0の場合
       */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
        /* ln_未コミットバックアップ件数(棚卸月末在庫(アドオン)) > 0
           かつ MOD(ln_未コミットバックアップ件数(棚卸月末在庫(アドオン)), ln_分割コミット数) = 0
           の場合
        */
        IF (  (ln_arc_cnt_yet > 0)
          AND (MOD(ln_arc_cnt_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数(棚卸月末在庫(アドオン))
            INSERT INTO 棚卸月末在庫(アドオン)バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                lt_棚卸月末在庫(アドオン)テーブル(ln_idx)全カラム
              , SYSDATE
              , 要求ID
            )
--
          COMMIT;
          */
--
          FORALL ln_idx IN 1..ln_arc_cnt_yet
            INSERT INTO xxcmn_stc_inv_month_stck_arc VALUES lt_mstc_tbl(ln_idx);
--
          COMMIT;
--
          /*
          gn_バックアップ件数(棚卸月末在庫(アドオン))           := 
                                    gn_バックアップ件数(棚卸月末在庫(アドオン)) + 
                                    ln_未コミットバックアップ件数(棚卸月末在庫(アドオン));
          ln_未コミットバックアップ件数(棚卸月末在庫(アドオン)) := 0;
          lt_棚卸月末在庫(アドオン)テーブル.DELETE;
          */
--
          gn_arc_cnt := gn_arc_cnt + ln_arc_cnt_yet;
          ln_arc_cnt_yet    := 0;
          lt_mstc_tbl.DELETE;
--
        END IF;
--
      END IF;
--
      -- ----------------------------------
      -- 棚卸月末在庫(アドオン) 変数設定
      -- ----------------------------------
      /*
      ln_未コミットバックアップ件数(棚卸月末在庫(アドオン)) := 
                                    ln_未コミットバックアップ件数(棚卸月末在庫(アドオン)) + 1;
      */
--
      ln_arc_cnt_yet := ln_arc_cnt_yet + 1;
--
      /*
      lt_棚卸月末在庫(アドオン)テーブル(ln_未コミットバックアップ件数
                                       (棚卸月末在庫(アドオン)) := lr_mstck_rec;
      */
      lt_mstc_tbl(ln_arc_cnt_yet).invent_monthly_stock_id := lr_mstck_rec.invent_monthly_stock_id;
      lt_mstc_tbl(ln_arc_cnt_yet).whse_code               := lr_mstck_rec.whse_code;
      lt_mstc_tbl(ln_arc_cnt_yet).item_id                 := lr_mstck_rec.item_id;
      lt_mstc_tbl(ln_arc_cnt_yet).item_code               := lr_mstck_rec.item_code;
      lt_mstc_tbl(ln_arc_cnt_yet).lot_id                  := lr_mstck_rec.lot_id;
      lt_mstc_tbl(ln_arc_cnt_yet).lot_no                  := lr_mstck_rec.lot_no;
      lt_mstc_tbl(ln_arc_cnt_yet).monthly_stock           := lr_mstck_rec.monthly_stock;
      lt_mstc_tbl(ln_arc_cnt_yet).cargo_stock             := lr_mstck_rec.cargo_stock;
      lt_mstc_tbl(ln_arc_cnt_yet).invent_ym               := lr_mstck_rec.invent_ym;
      lt_mstc_tbl(ln_arc_cnt_yet).created_by              := lr_mstck_rec.created_by;
      lt_mstc_tbl(ln_arc_cnt_yet).creation_date           := lr_mstck_rec.creation_date;
      lt_mstc_tbl(ln_arc_cnt_yet).last_updated_by         := lr_mstck_rec.last_updated_by;
      lt_mstc_tbl(ln_arc_cnt_yet).last_update_date        := lr_mstck_rec.last_update_date;
      lt_mstc_tbl(ln_arc_cnt_yet).last_update_login       := lr_mstck_rec.last_update_login;
      lt_mstc_tbl(ln_arc_cnt_yet).request_id              := lr_mstck_rec.request_id;
      lt_mstc_tbl(ln_arc_cnt_yet).program_application_id  := lr_mstck_rec.program_application_id;
      lt_mstc_tbl(ln_arc_cnt_yet).program_id              := lr_mstck_rec.program_id;
      lt_mstc_tbl(ln_arc_cnt_yet).program_update_date     := lr_mstck_rec.program_update_date;
      lt_mstc_tbl(ln_arc_cnt_yet).cargo_stock_not_stn     := lr_mstck_rec.cargo_stock_not_stn;
      lt_mstc_tbl(ln_arc_cnt_yet).archive_date            := lr_mstck_rec.archive_date;
      lt_mstc_tbl(ln_arc_cnt_yet).archive_request_id      := lr_mstck_rec.archive_request_id;
      lt_mstc_tbl(ln_arc_cnt_yet).purge_date              := lr_mstck_rec.purge_date;
      lt_mstc_tbl(ln_arc_cnt_yet).purge_request_id        := lr_mstck_rec.purge_request_id;
--
    END LOOP stc_inv_mstck_loop;
--
    -- ---------------------------------------------------------
    -- 分割コミット対象外の残データ INSERT処理(棚卸月末在庫(アドオン))
    -- ---------------------------------------------------------
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数(棚卸月末在庫(アドオン))
        INSERT INTO 棚卸月末在庫(アドオン)バックアップ
        (
          全カラム
        , バックアップ登録日
        , バックアップ要求ID
        )
        VALUES
        (
          棚卸月末在庫(アドオン)テーブル(ln_idx)全カラム
        , SYSDATE
        , 要求ID
        )
        ;
    */
--
    FORALL ln_idx IN 1..ln_arc_cnt_yet
      INSERT INTO xxcmn_stc_inv_month_stck_arc VALUES lt_mstc_tbl(ln_idx);
--
    /*
    gn_バックアップ件数(棚卸月末在庫(アドオン)) := 
                                        gn_バックアップ件数(棚卸月末在庫(アドオン)) + 
                                        ln_未コミットバックアップ件数(棚卸月末在庫(アドオン));
    ln_未コミットバックアップ件数(棚卸月末在庫(アドオン)) := 0;
    lt_棚卸月末在庫(アドオン)テーブル.DELETE;
    */
--
    gn_arc_cnt := gn_arc_cnt + ln_arc_cnt_yet;
    ln_arc_cnt_yet    := 0;
    lt_mstc_tbl.DELETE;
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
          IF ( lt_mstc_tbl.COUNT > 0 ) THEN
            gt_inv_month_stc_id := 
                     lt_mstc_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).invent_monthly_stock_id;
            --バックアップ処理に失敗しました。【棚卸月末在庫(アドオン)】棚卸月末在庫ID: KEY
             ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_others_err_msg
                       ,iv_token_name1  => cv_token_key
                       ,iv_token_value1 => TO_CHAR(gt_inv_month_stc_id)
                      );
          END IF;
        END IF;
--
      EXCEPTION
        WHEN not_init_collection_expt THEN
          NULL;
      END;
--
      IF ( (ov_errmsg IS NULL) AND (gt_inv_month_stc_id IS NOT NULL) ) THEN
           --バックアップ処理に失敗しました。【棚卸月末在庫(アドオン)】棚卸月末在庫ID: KEY
           ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_others_err_msg
                       ,iv_token_name1  => cv_token_key
                       ,iv_token_value1 => TO_CHAR(gt_inv_month_stc_id)
                      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||SQLERRM;
      ov_retcode := cv_status_error;
--
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
    --棚卸月末在庫(アドオン) バックアップ 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_arc_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt)
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
END XXCMN970002C;
/
