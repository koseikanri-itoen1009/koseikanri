CREATE OR REPLACE PACKAGE BODY XXCMN980001C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980001C(body)
 * Description      : 生産原料詳細アドオンパージ
 * MD.050           : T_MD050_BPO_98A_生産原料詳細アドオンパージ
 * Version          : 1.00
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/22   1.00  T.Makuta          新規作成
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
  cv_purge_type      CONSTANT VARCHAR2(1)  := '0';                        --ﾊﾟｰｼﾞﾀｲﾌﾟ(0:ﾊﾟｰｼﾞ期間)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9801';                     --ﾊﾟｰｼﾞ定義ｺｰﾄﾞ
  cv_doc_type_40     CONSTANT VARCHAR2(2)  := '40';                       --文書タイプ
  cn_b_status_m1     CONSTANT NUMBER       := -1;
  cn_b_status_m3     CONSTANT NUMBER       := -3;
  cn_b_status_p4     CONSTANT NUMBER       := 4;
--
  --=============
  --メッセージ
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_purge_range      
                     CONSTANT VARCHAR2(50) := 'XXCMN_PURGE_RANGE';        --XXCMN:パージレンジ
  --XXCMN:パージ/バックアップ分割コミット数
  cv_xxcmn_commit_range     
                     CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_target_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11008';          --対象件数メッセージ
  cv_normal_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';          --正常件数メッセージ
  cv_error_rec_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';          --エラー件数メッセージ
  cv_get_priod_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11011';          --パージ期間取得失敗
  cv_get_profile_msg CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';          --ﾌﾟﾛﾌｧｲﾙ値取得失敗
  cv_token_profile   CONSTANT VARCHAR2(50) := 'NG_PROFILE';               --ﾌﾟﾛﾌｧｲﾙ取得MSG用ﾄｰｸﾝ名
  cv_proc_date_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11014';          --処理日出力
  cv_par_token       CONSTANT VARCHAR2(10) := 'PAR';                      --処理日MSG用ﾄｰｸﾝ名
--
  cv_others_err_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11026';          --削除処理失敗
  cv_token_shori_2   CONSTANT VARCHAR2(10) := 'SHORI';                    --削除処理MSG用ﾄｰｸﾝ名
  cv_token_kinou     CONSTANT VARCHAR2(10) := 'KINOUMEI';                 --削除処理MSG用ﾄｰｸﾝ名
  cv_token_key_name  CONSTANT VARCHAR2(10) := 'KEYNAME';                  --削除処理MSG用ﾄｰｸﾝ名
  cv_token_key       CONSTANT VARCHAR2(10) := 'KEY';                      --削除処理MSG用ﾄｰｸﾝ名
  cv_shori_2         CONSTANT VARCHAR2(50) := '削除';
  cv_kinou1          CONSTANT VARCHAR2(90) := '生産原料詳細（アドオン）';
  cv_kinou2          CONSTANT VARCHAR2(90) := '移動ロット詳細（アドオン）';
  cv_kinou3          CONSTANT VARCHAR2(90) := '生産バッチヘッダ（標準）';
  cv_key_name        CONSTANT VARCHAR2(50) := 'バッチID';
--
  cv_normal_msg      CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90004';         --正常終了メッセージ
  cv_error_msg       CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90006';         --エラー終了全ﾛｰﾙﾊﾞｯｸ
--
  --TBL_NAME SHORI 件数： CNT 件
  cv_end_msg         CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';          --処理内容出力
  cv_token_tblname   CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname_s       CONSTANT VARCHAR2(90) := '生産原料詳細（アドオン）';
  cv_tblname_i       CONSTANT VARCHAR2(90) := '移動ロット詳細（アドオン）';
  cv_token_shori     CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori           CONSTANT VARCHAR2(50) := '削除';
  cv_cnt_token       CONSTANT VARCHAR2(10) := 'CNT';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                       -- 対象件数
  gn_normal_cnt             NUMBER;                                       -- 正常件数
  gn_error_cnt              NUMBER;                                       -- エラー件数
--
  --削除件数(アドオンテーブル)
  gn_del_cnt_mdtl           NUMBER;                                       --生産原料詳細
  gn_del_cnt_lot            NUMBER;                                       --移動ロット詳細
  --未コミット削除件数(アドオンテーブル)
  gn_del_cnt_yet_mdtl       NUMBER;                                       --生産原料詳細
  gn_del_cnt_yet_lot        NUMBER;                                       --移動ロット詳細
--
  gn_cnt_header_yet         NUMBER;                                       --未コミット処理件数
  gt_b_hdr_id               gme_batch_header.batch_id%TYPE;
  gt_b_hdr_id_lock          gme_batch_header.batch_id%TYPE;
  gt_m_dtl_addon_id         xxwip_material_detail.mtl_detail_addon_id%TYPE;
  gt_mov_lot_dtl_id         xxinv_mov_lot_details.mov_lot_dtl_id%TYPE;
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN980001C';  -- パッケージ名
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
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf               VARCHAR2(5000);                      -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                         -- リターン・コード
    lv_errmsg               VARCHAR2(5000);                      -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_purge_period         NUMBER;                              -- パージ期間
    ld_standard_date        DATE;                                -- 基準日
    ln_commit_range         NUMBER;                              -- 分割コミット数
    ln_purge_range          NUMBER;                              -- パージレンジ
    lv_process_part         VARCHAR2(1000);                      -- 処理部
    ln_shori_flg           NUMBER;
    lv_errmsg_kinou         VARCHAR2(90);                        -- エラーメッセージ出力用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    CURSOR 生産バッチヘッダ取得
      id_基準日       IN DATE,
      in_パージレンジ IN NUMBER
    IS
      SELECT 生産バッチヘッダ.バッチID
      FROM   生産バッチヘッダ
      WHERE  生産バッチヘッダ.計画開始日 >= id_基準日  - in_パージレンジ
      AND    生産バッチヘッダ.計画開始日 <  id_基準日
      AND    生産バッチヘッダ.バッチステータス IN(-1,-3,4)
      ;
    */
    CURSOR b_header_cur(
      id_standard_date      DATE
     ,in_purge_range        NUMBER
    )
    IS
      SELECT /*+ INDEX(gbh GME_GBH_N01) */
              gbh.batch_id            AS batch_id,
              gbh.batch_status        AS batch_status
      FROM    gme_batch_header           gbh                    --生産ﾊﾞｯﾁﾍｯﾀﾞ
      WHERE   gbh.plan_start_date     >= id_standard_date - in_purge_range
      AND     gbh.plan_start_date     <  id_standard_date
      AND     gbh.batch_status IN(cn_b_status_m1,cn_b_status_m3,cn_b_status_p4)
      ;
--
    /*
    CURSOR パージ対象生産原料詳細(アドオン)取得
      it_バッチID IN 生産バッチヘッダ.バッチID%TYPE
    IS
      SELECT 生産原料詳細(アドオン).生産原料詳細アドオンID
      FROM   生産原料詳細,
             生産原料詳細(アドオン),
             生産原料詳細(アドオン)バックアップ
      WHERE  生産原料詳細.バッチID         =  it_バッチID
      AND    生産原料詳細.生産原料詳細ID   =  生産原料詳細(アドオン).生産原料詳細アドオンID
      AND    生産原料詳細(アドオン).生産原料詳細アドオンID = 
                                    生産原料詳細(アドオン)バックアップ.生産原料詳細アドオンID ;
    */
    CURSOR mdtl_addn_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmd.mtl_detail_addon_id AS mtl_detail_addon_id
      FROM    gme_material_details       gmd,                    --生産原料詳細
              xxwip_material_detail      xmd,                    --生産原料詳細(ｱﾄﾞｵﾝ)
              xxcmn_material_detail_arc  xmda                    --生産原料詳細(ｱﾄﾞｵﾝ)ﾊﾞｯｸｱｯﾌﾟ
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmd.material_detail_id
      AND     xmd.mtl_detail_addon_id  = xmda.mtl_detail_addon_id
      ;
--
    /*
    CURSOR パージ対象移動ロット詳細(アドオン)取得
      it_バッチID IN 生産バッチヘッダ.バッチID%TYPE
    IS
      SELECT 移動ロット詳細(アドオン).ロット詳細ID
      FROM   生産原料詳細,
             移動ロット詳細(アドオン),
             移動ロット詳細(アドオン)バックアップ
      WHERE  生産原料詳細.バッチID         = it_バッチID
      AND    生産原料詳細.生産原料詳細ID   = 移動ロット詳細(アドオン).明細ID
      AND    移動ロット詳細(アドオン).文書タイプ   = '40' 
      AND    移動ロット詳細(アドオン).ロット詳細ID = 
                                                 移動ロット詳細(アドオン)バックアップ.ロット詳細ID;
    */
    CURSOR mlot_dtl_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmld.mov_lot_dtl_id     AS mov_lot_dtl_id
      FROM    gme_material_details       gmd,                    --生産原料詳細
              xxinv_mov_lot_details      xmld,                   --移動ロット詳細(ｱﾄﾞｵﾝ)
              xxcmn_mov_lot_details_arc  xmlda                   --移動ロット詳細(ｱﾄﾞｵﾝ)ﾊﾞｯｸｱｯﾌﾟ
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmld.mov_line_id
      AND     xmld.document_type_code  = cv_doc_type_40
      AND     xmld.mov_lot_dtl_id      = xmlda.mov_lot_dtl_id
      ;
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode        := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_del_cnt_mdtl     := 0;
    gn_del_cnt_lot      := 0;
    gn_del_cnt_yet_mdtl := 0;
    gn_del_cnt_yet_lot  := 0;
    gn_cnt_header_yet   := 0;
--
    -- ローカル変数の初期化
    lv_errmsg_kinou     := NULL;
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
      ld_基準日 := 処理日取得共通関数より取得した処理日 - ln_パージ期間;
--
    iv_proc_dateがNULLでない場合
      ld_基準日 := TO_DATE(iv_proc_date) - ln_パージ期間;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_purge_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_purge_period;
--
    END IF;
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）：';
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ分割コミット数);
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
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_purge_range || '）:';
--
    /*
    ln_パージレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージレンジ);
    */
    ln_purge_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
--
    /*
    ln_パージレンジがNULLの場合
    */
    IF ( ln_purge_range IS NULL ) THEN
--
      /*
      ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                     iv_アプリケーション短縮名 => cv_appl_short_name
                    ,iv_メッセージコード       => cv_get_profile_msg
                    ,iv_トークン名1            => cv_token_profile
                    ,iv_トークン値1            => cv_xxcmn_purge_range
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
                    ,iv_token_value1 => cv_xxcmn_purge_range
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
    FOR lr_b_header_rec IN 処理対象生産バッチヘッダ取得(ld_基準日,ln_パージレンジ) LOOP
    */
   << purge_main >>
    FOR lr_b_header_rec IN b_header_cur(ld_standard_date
                                       ,ln_purge_range ) LOOP
--
      /*
      ln_処理フラグ := 0;
      */
      ln_shori_flg        := 0;
--
      /*
      gt_対象生産バッチID := lr_b_header_rec.生産バッチID;
      */
      gt_b_hdr_id         := lr_b_header_rec.batch_id;
--
      -- ===============================================
      -- 分割コミット(生産バッチヘッダ)
      -- ===============================================
      /*
      NVL(ln_分割コミット数, 0) <> 0の場合
       */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
        /* gn_未コミット処理件数(生産バッチヘッダ) > 0 かつ 
           MOD(gn_未コミット処理件数(生産バッチヘッダ), ln_分割コミット数) = 0の場合
        */
        IF (  (gn_cnt_header_yet > 0)
          AND (MOD(gn_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
            /*
            COMMIT;
            */
            COMMIT;
            /*
            gn_削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) := gn_削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) + 
                                                gn_未コミット削除件数(生産原料詳細(ｱﾄﾞｵﾝ))
            gn_未コミット削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) := 0;
            ln_未コミット処理件数(生産バッチヘッダ)    := 0;
            */
            gn_del_cnt_mdtl     := gn_del_cnt_mdtl + gn_del_cnt_yet_mdtl;
            gn_del_cnt_yet_mdtl := 0;
--
            /*
            gn_削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) := gn_削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) + 
                                                  gn_未コミット削除件数(移動ロット詳細(ｱﾄﾞｵﾝ));
            gn_未コミット削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) := 0;
            */
            gn_del_cnt_lot      := gn_del_cnt_lot + gn_del_cnt_yet_lot;
            gn_del_cnt_yet_lot  := 0;
--
            /*
            gn_未コミット処理件数(生産バッチヘッダ)    := 0;
            */
            gn_cnt_header_yet   := 0;
--
        END IF;
--
      END IF;
--
      -- ===============================================
      -- パージ対象生産原料詳細(アドオン)取得
      -- ===============================================
      /*
      FOR lr_mdtl_addn_rec IN パージ対象生産原料詳細(アドオン)取得
                                                                 (lr_b_header_rec.バッチID) LOOP
      */
      << purge_mdtl_addn >>
      FOR lr_mdtl_addn_rec IN mdtl_addn_cur(lr_b_header_rec.batch_id) LOOP
--
        /* 対象件数は、生産原料詳細(ｱﾄﾞｵﾝ)の件数を使用する
        gn_対象件数 := gn_対象件数 + 1;
        */
        gn_target_cnt        := gn_target_cnt + 1;
--
        -- ==========================================================
        -- 処理対象生産原料詳細（アドオン）、バックアップ共にロック
        -- ==========================================================
        /*
        ln_処理フラグ := 1;
--
        SELECT 生産原料詳細.生産原料詳細アドオンID
        INTO   gt_生産原料詳細アドオンID
        FROM   生産原料詳細（アドオン）,
               生産原料詳細（アドオン）バックアップ
        WHERE  生産原料詳細アドオンID = lr_mdtl_addn_rec.生産原料詳細アドオンID
        AND    生産原料詳細（アドオン）.生産原料詳細アドオンID = 
                            生産原料詳細（アドオン）バックアップ.生産原料詳細アドオンID
        FOR UPDATE NOWAIT
        */
--
        ln_shori_flg               := 1;
--
        SELECT  xmd.mtl_detail_addon_id   AS mtl_detail_addon_id
        INTO    gt_m_dtl_addon_id
        FROM    xxwip_material_detail     xmd,
                xxcmn_material_detail_arc xmda
        WHERE   xmd.mtl_detail_addon_id = lr_mdtl_addn_rec.mtl_detail_addon_id
        AND     xmd.mtl_detail_addon_id = xmda.mtl_detail_addon_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- 生産原料詳細(アドオン)パージ
        -- ===============================================
        /*
        DELETE FROM 生産原料詳細(アドオン)
        WHERE 生産原料詳細アドオンID = lr_mdtl_addn_rec.生産原料詳細アドオンID
        */
        DELETE FROM xxwip_material_detail
        WHERE  mtl_detail_addon_id = lr_mdtl_addn_rec.mtl_detail_addon_id
        ;
--
        /*
        UPDATE 生産原料詳細(アドオン)バックアップ
        SET パージ実行日 = SYSDATE
           ,パージ要求ID = 要求ID
        WHERE 生産原料詳細アドオンID = lr_mdtl_addn_rec.生産原料詳細アドオンID
        */
        UPDATE xxcmn_material_detail_arc
        SET    purge_date          = SYSDATE
              ,purge_request_id    = cn_request_id
        WHERE  mtl_detail_addon_id = lr_mdtl_addn_rec.mtl_detail_addon_id
        ;
--
        /*
        gn_未コミット削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) := 
                                            gn_未コミット削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) + 1;
        */
        gn_del_cnt_yet_mdtl := gn_del_cnt_yet_mdtl + 1;
--
      END LOOP purge_mdtl_addn;
--
      -- ===============================================
      -- パージ対象移動ロット詳細(アドオン)取得
      -- ===============================================
      /*
      FOR lr_mlot_dtl_rec IN パージ対象移動ロット詳細(アドオン)取得
                                                     (lr_b_header_rec.バッチID) LOOP
      */
      << purge_mlot_dtl >>
      FOR lr_mlot_dtl_rec IN mlot_dtl_cur(lr_b_header_rec.batch_id) LOOP
--
        -- ==========================================================
        -- 処理対象移動ロット詳細（アドオン）、バックアップ共にロック
        -- ==========================================================
        /*
        ln_処理フラグ := 2;
--
        SELECT 移動ロット詳細.ロット詳細ID
        INTO   gt_ロット詳細ID
        FROM   移動ロット詳細（アドオン）,
               移動ロット詳細（アドオン）バックアップ
        WHERE  移動ロット詳細（アドオン）. ロット詳細ID = lr_mlot_dtl_rec.ロット詳細ID
        AND    移動ロット詳細（アドオン）. ロット詳細ID = 
                                           移動ロット詳細（アドオン）バックアップ.ロット詳細ID
        AND    移動ロット詳細（アドオン）. 文書タイプ   = '40'
        FOR UPDATE NOWAIT
        */
--
        ln_shori_flg               := 2;
--
        SELECT  xmld.mov_lot_dtl_id       AS mov_lot_dtl_id
        INTO    gt_mov_lot_dtl_id
        FROM    xxinv_mov_lot_details     xmld,
                xxcmn_mov_lot_details_arc xmlda
        WHERE   xmld.mov_lot_dtl_id     = lr_mlot_dtl_rec.mov_lot_dtl_id
        AND     xmld.mov_lot_dtl_id     = xmlda.mov_lot_dtl_id
        AND     xmlda.document_type_code = cv_doc_type_40
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- 移動ロット詳細(アドオン)パージ
        -- ===============================================
        /*
        DELETE FROM 移動ロット詳細(アドオン)
        WHERE  ロット詳細ID = lr_mlot_dtl_rec.ロット詳細ID
        AND    文書タイプ   = '40'
        */
        DELETE FROM xxinv_mov_lot_details
        WHERE  mov_lot_dtl_id     = lr_mlot_dtl_rec.mov_lot_dtl_id
        AND    document_type_code = cv_doc_type_40
        ;
--
        /*
        UPDATE 移動ロット詳細(アドオン)バックアップ
        SET   パージ実行日 = SYSDATE
             ,パージ要求ID = 要求ID
        WHERE ロット詳細ID = lr_mlot_dtl_rec.ロット詳細ID
        AND   文書タイプ   = '40'
        */
        UPDATE xxcmn_mov_lot_details_arc
        SET    purge_date          = SYSDATE
              ,purge_request_id    = cn_request_id
        WHERE  mov_lot_dtl_id      = lr_mlot_dtl_rec.mov_lot_dtl_id
        AND    document_type_code  = cv_doc_type_40
        ;
        /*
        gn_未コミット削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) := 
                                              gn_未コミット削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) + 1;
        */
        gn_del_cnt_yet_lot  := gn_del_cnt_yet_lot + 1;
--
      END LOOP purge_mlot_dtl;
--
      /* 
      gn_未コミット処理件数(生産バッチヘッダ) := gn_未コミット処理件数(生産バッチヘッダ) + 1;
      */
      gn_cnt_header_yet   := gn_cnt_header_yet + 1;
--
      /*
      -- ==========================================================
      -- 処理対象生産バッチヘッダロック
      -- ==========================================================
      /* 
      lr_b_header_rec.batch_status = 4 でかつ
      ln_処理フラグ <> 0 の場合
      */
      IF ( lr_b_header_rec.batch_status =  cn_b_status_p4  AND
           ln_shori_flg                 <> 0             ) THEN
--
        /*
        ln_処理フラグ             := 3;
--
        SELECT 生産バッチヘッダ.バッチID
        INTO   gt_バッチヘッダバッチID
        FROM   生産バッチヘッダ
        WHERE  生産バッチヘッダ.バッチID         = lr_b_header_rec.生産バッチID
        AND    生産バッチヘッダ.バッチステータス = 4
        FOR UPDATE NOWAIT;
        */
--
        ln_shori_flg              := 3;
--
        SELECT gbh.batch_id        AS batch_id
        INTO   gt_b_hdr_id_lock
        FROM   gme_batch_header       gbh
        WHERE  gbh.batch_id         = lr_b_header_rec.batch_id
        AND    gbh.batch_status     = cn_b_status_p4
        FOR UPDATE NOWAIT;
--
        /*
        UPDATE 生産バッチヘッダ
        SET    生産バッチヘッダ.GL転送フラグ     = 1
        WHERE  生産バッチヘッダ.バッチID         = lr_b_header_rec.batch_id
        AND    生産バッチヘッダ.バッチステータス = 4
        */
--
        UPDATE gme_batch_header
        SET    gl_posted_ind = 1
        WHERE  batch_id      = lr_b_header_rec.batch_id
        AND    batch_status  = cn_b_status_p4;
--
      END IF;
--
    END LOOP purge_main;
--
    /*
    gn_削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) := gn_削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) + 
                                        gn_未コミット削除件数(生産原料詳細(ｱﾄﾞｵﾝ))
    gn_未コミット削除件数(生産原料詳細(ｱﾄﾞｵﾝ)) := 0;
    */
    gn_del_cnt_mdtl     := gn_del_cnt_mdtl + gn_del_cnt_yet_mdtl;
    gn_del_cnt_yet_mdtl := 0;
--
    /*
    gn_削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) := gn_削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) + 
                                          gn_未コミット削除件数(移動ロット詳細(ｱﾄﾞｵﾝ));
    gn_未コミット削除件数(移動ロット詳細(ｱﾄﾞｵﾝ)) := 0;
    */
    gn_del_cnt_lot      := gn_del_cnt_lot + gn_del_cnt_yet_lot;
    gn_del_cnt_yet_lot  := 0;
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
      IF ( gt_b_hdr_id IS NOT NULL ) THEN
--
        IF ( ln_shori_flg = 1 ) THEN
          lv_errmsg_kinou := cv_kinou1;
        ELSIF ( ln_shori_flg = 2 ) THEN
          lv_errmsg_kinou := cv_kinou2;
        ELSIF ( ln_shori_flg = 3 ) THEN
          lv_errmsg_kinou := cv_kinou3;
        END IF;
--
        --SHORI 処理に失敗しました。【 KINOUMEI 】 KEYNAME ： KEY
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_shori_2
                      ,iv_token_value1 => cv_shori_2
                      ,iv_token_name2  => cv_token_kinou
                      ,iv_token_value2 => lv_errmsg_kinou
                      ,iv_token_name3  => cv_token_key_name
                      ,iv_token_value3 => cv_key_name
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(gt_b_hdr_id)
                     );
--
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
    --生産原料詳細（アドオン） 削除 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname_s
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_del_cnt_mdtl)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --移動ロット詳細（アドオン） 削除 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname_i
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_del_cnt_lot)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 対象件数出力(対象件数： CNT 件)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
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
                    ,iv_token_value1 => TO_CHAR(gn_del_cnt_mdtl)      --削除件数
                   );
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
END XXCMN980001C;
/
