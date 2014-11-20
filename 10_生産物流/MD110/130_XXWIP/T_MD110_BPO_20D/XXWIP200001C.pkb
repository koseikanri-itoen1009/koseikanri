CREATE OR REPLACE PACKAGE BODY xxwip200001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip200001c(body)
 * Description      : 生産バッチ情報ダウンロード
 * MD.050           : 生産バッチ T_MD050_BPO_202
 * MD.070           : 生産バッチ情報ダウンロード T_MD070_BPO_20D
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init_proc           前処理 (D-1)
 *  get_data            対象データ取得 (D-2)
 *  output_csv          CSVファイル出力：処理結果レポート出力 (D-4)
 *  set_batch_id        生産バッチID格納 (D-5)
 *  upd_send_type       送信済フラグ更新 (D-6)
 *  submain             メイン処理プロシージャ
 *  main                コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/16    1.0  Oracle 野村 正幸  初回作成
 *  2008/06/18    1.1  Oracle 二瓶 大輔  ST不具合対応#160(日付書式修正)
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
  lock_expt              EXCEPTION;        -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxwip200001c';    -- パッケージ名
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';           -- アプリケーション短縮名
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';           -- アプリケーション短縮名
--
  gv_rep_file        CONSTANT VARCHAR2(1)   := '0';               -- 処理結果レポート
  gv_csv_file        CONSTANT VARCHAR2(1)   := '1';               -- CSVファイル
-- 
  -- データ区分
  gt_data_type_add   CONSTANT VARCHAR2(1)   := '0';               -- データ区分：0（追加）
  gt_data_type_mod   CONSTANT VARCHAR2(1)   := '1';               -- データ区分：1（訂正）
  gt_data_type_del   CONSTANT VARCHAR2(1)   := '2';               -- データ区分：2（削除）
--
  -- メッセージ
  gv_xxwip_nodata_err       CONSTANT VARCHAR2(100) := 'APP-XXWIP-10040';  -- 対象データ未取得エラー
  gv_xxcom_noprof_err       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- プロファイル取得エラー
  gv_xxwip_table_lock_err   CONSTANT VARCHAR2(100) := 'APP-XXWIP-10029';  -- テーブルロックエラー
  gv_xxwip_output_nodir_err CONSTANT VARCHAR2(100) := 'APP-XXWIP-10041';  -- 出力先ディレクトリ不在エラー
--
  -- トークン
  gv_tkn_ng_profile  CONSTANT VARCHAR2(100) := 'NG_PROFILE';        -- トークン：NG_PROFILE
  gv_tkn_table       CONSTANT VARCHAR2(100) := 'TABLE';             -- トークン：TABLE
  gv_tkn_target_name CONSTANT VARCHAR2(100) := 'TARGET_NAME';       -- トークン：TARGET_NAME
  gv_tkn_path        CONSTANT VARCHAR2(100) := 'PATH';              -- トークン：PATH
--
  --プロファイル
  gv_prf_out_dir     CONSTANT VARCHAR2(50) := 'XXWIP_BATCH_OUT_DIR';       -- プロファイル：出力先
  gv_prf_out_file    CONSTANT VARCHAR2(50) := 'XXWIP_BATCH_OUT_FILE_NAME'; -- プロファイル：出力ファイル名
--
  -- 生産バッチヘッダ 業務ステータス
  gt_oprtn_sts_cmp   CONSTANT gme_batch_header.attribute4%TYPE  := '6';     -- 業務ステータス：6 （受付済）
  gt_oprtn_sts_can   CONSTANT gme_batch_header.attribute4%TYPE  := '-1';    -- 業務ステータス：-1（取消）
--
  -- 生産バッチヘッダ 送信区分
  gt_send_type_non   CONSTANT gme_batch_header.attribute3%TYPE  := '0';     -- 送信区分：0（未送信）
  gt_send_type_cmp   CONSTANT gme_batch_header.attribute3%TYPE  := '1';     -- 送信区分：1（送信済）
  gt_send_type_mod   CONSTANT gme_batch_header.attribute3%TYPE  := '2';     -- 送信区分：2（修正）
  gt_send_type_can   CONSTANT gme_batch_header.attribute3%TYPE  := '3';     -- 送信区分：3（取消）
--
  -- 生産原料詳細 ラインタイプ
  gt_compl_line_type  CONSTANT gme_material_details.line_type%TYPE := 1;    -- ラインタイプ：1（完成品）
--
  -- 工順マスタ 送信対象フラグ
  gt_send_flag_y      CONSTANT gmd_routings_b.attribute18%TYPE  := 'Y';     -- 送信対象フラグ：Y（送信済）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 生産バッチ情報を格納するレコード
  TYPE material_info_rec IS RECORD(
    batch_id              gme_batch_header.batch_id%TYPE,           -- バッチID
    plant_code            gme_batch_header.plant_code%TYPE,         -- プラントコード
    batch_no              gme_batch_header.batch_no%TYPE,           -- 手配No
    item_no               xxcmn_item_mst_v.item_no%TYPE,            -- 品目コード
    routing_no            gmd_routings_b.routing_no%TYPE,           -- ラインNo
    location_code         gmd_routings_b.attribute9%TYPE,           -- 保管倉庫コード
    plan_start_date       gme_batch_header.plan_start_date%TYPE,    -- 生産予定日
    instruction_total     gme_material_details.attribute23%TYPE,    -- 指示総数
    send_type             gme_batch_header.attribute3%TYPE          -- 送信区分
  );
--
  -- 生産バッチ情報を格納するテーブル型の定義
  TYPE material_info_tbl IS TABLE OF material_info_rec INDEX BY PLS_INTEGER;
  -- 登録・更新用PL/SQL表型
  TYPE batch_id_ttype   IS TABLE OF  gme_batch_header.batch_id%TYPE INDEX BY BINARY_INTEGER;  -- バッチID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_material_info_tbl  material_info_tbl;  -- 結合配列の定義
  gt_batch_id_upd_tab      batch_id_ttype;     -- バッチID
  gd_sysdate            DATE;               -- システム現在日付
--
  gv_out_dir        VARCHAR2(150);          -- 生産バッチ情報出力先
  gv_out_file_name  VARCHAR2(150);          -- 生産バッチ情報ファイル名
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 前処理 (D-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
    cv_out_dir  CONSTANT VARCHAR2(30) := '生産バッチ情報出力先';
    cv_out_file CONSTANT VARCHAR2(30) := '生産バッチ情報ファイル名';
--
    -- *** ローカル変数 ***
    ld_last_update  DATE;               -- 最終更新日時
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- **************************************************
    -- *** グローバル変数初期化
    -- **************************************************
    gv_out_dir := NULL;
    gv_out_file_name := NULL;
--
    -- **************************************************
    -- *** プロファイル取得：生産バッチ情報出力
    -- **************************************************
    gv_out_dir := TRIM(FND_PROFILE.VALUE(gv_prf_out_dir));
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_out_dir IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            cv_out_dir);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** プロファイル取得：生産バッチ情報ファイル名
    -- **************************************************
    gv_out_file_name := TRIM(FND_PROFILE.VALUE(gv_prf_out_file));
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_out_file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            cv_out_file);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END init_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 対象データ取得 (D-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    -- *** ローカル定数 ***
    cv_xxwip_batch_header     VARCHAR2(50) := '生産バッチヘッダ';
--
    -- *** ローカル変数 ***
    ld_last_update  DATE;               -- 最終更新日時
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- **************************************************
    -- *** 生産バッチ情報を取得
    -- **************************************************
    SELECT gbh.batch_id,                -- バッチID
           gbh.plant_code,              -- プラントコード
           gbh.batch_no,                -- 手配No
           ximv.item_no,                -- 品目コード
           grb.routing_no,              -- ラインNo
           grb.attribute9,              -- 保管倉庫コード
           gbh.plan_start_date,         -- 生産予定日
           gmd.attribute23,             -- 指示総数
           gbh.attribute3               -- 送信済フラグ
    BULK COLLECT INTO gt_material_info_tbl
    FROM  xxcmn_item_mst_v        ximv,     -- OPM品目情報VIEW
          gmd_routings_b          grb,      -- 工順マスタ
          gme_material_details    gmd,      -- 生産原料詳細
          gme_batch_header        gbh       -- 生産バッチヘッダ
    WHERE gbh.batch_id            =   gmd.batch_id            -- バッチID
    AND   gbh.routing_id          =   grb.routing_id          -- 工順ID
    AND   gmd.item_id             =   ximv.item_id            -- 品目ID
    AND   gmd.line_type           =   gt_compl_line_type      -- ラインタイプ=完成品
    AND   grb.attribute18         =   gt_send_flag_y          -- 送信対象フラグ=Y
    AND   gbh.attribute3          IN  (gt_send_type_non,      -- 送信区分：未送信
                                      gt_send_type_mod,       --         ：修正
                                      gt_send_type_can)       --         ：取消
    AND   ((gbh.attribute4        =   gt_oprtn_sts_cmp        -- 業務ステータス=受付済
            AND   gbh.attribute3  <>  gt_send_type_cmp  )     -- 送信区分<>送信済
    OR    (gbh.attribute4         =   gt_oprtn_sts_can        -- 業務ステータス=取消済
            AND   gbh.attribute3  =   gt_send_type_can  ))    -- 送信区分=取消
    ORDER BY gbh.batch_no                                     -- バッチNo
    FOR UPDATE OF gbh.batch_id NOWAIT;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
    WHEN lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxwip                      -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                    ,gv_xxwip_table_lock_err       -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
                    ,gv_tkn_table                  -- トークンTABLE
                    ,cv_xxwip_batch_header         -- テーブル名：生産バッチヘッダ
                    ),1,5000);
--
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力 (D-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type  IN  VARCHAR2,            -- ファイル種別
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカル定数 ***
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot    CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lf_file_hand    UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
    lv_csv_file     VARCHAR2(5000);        -- 出力情報
    lv_data_type    VARCHAR2(1);           -- データ区分
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- **************************************************
    -- *** 出力ファイルオープン
    -- **************************************************
    -- CSVファイル出力の場合
    IF (iv_file_type = gv_csv_file) THEN
      lf_file_hand := UTL_FILE.FOPEN(gv_out_dir,        -- ディレクトリ
                                     gv_out_file_name,  -- ファイル名
                                     'w');              -- 書込みモード
    END IF;
--
    -- **************************************************
    -- *** 生産バッチ情報が取得できている場合
    -- **************************************************
    IF (gt_material_info_tbl.COUNT <> 0) THEN
--
      -- ファイル出力ループ
      <<gt_material_info_tbl_loop>>
      FOR i IN gt_material_info_tbl.FIRST .. gt_material_info_tbl.LAST LOOP
--
        -- **************************************************
        -- *** データ区分編集
        -- **************************************************
        -- データ区分初期化
        lv_data_type := NULL;
--
        -- 未送信の場合
        IF (gt_material_info_tbl(i).send_type = gt_send_type_non) THEN
          lv_data_type := gt_data_type_add;
--
        -- 修正の場合
        ELSIF (gt_material_info_tbl(i).send_type = gt_send_type_mod) THEN
          lv_data_type := gt_data_type_mod;
--
        -- 取消の場合
        ELSIF (gt_material_info_tbl(i).send_type = gt_send_type_can) THEN
          lv_data_type := gt_data_type_del;
        END IF;
--
        -- 取得データCVS形式生成
        lv_csv_file :=     cv_sep_wquot   || gt_material_info_tbl(i).plant_code  || cv_sep_wquot 
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).batch_no || cv_sep_wquot 
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).item_no || cv_sep_wquot 
                        || cv_sep_com 
-- 2008/06/18 D.Nihei MOD START
--                        || cv_sep_wquot   || TO_CHAR(gt_material_info_tbl(i).plan_start_date, 'YYYYMMDD') || cv_sep_wquot 
                        || cv_sep_wquot   || TO_CHAR(gt_material_info_tbl(i).plan_start_date, 'YYYY/MM/DD') || cv_sep_wquot 
-- 2008/06/18 D.Nihei MOD END
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).routing_no || cv_sep_wquot 
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).location_code || cv_sep_wquot 
                        || cv_sep_com 
                        || gt_material_info_tbl(i).instruction_total 
                        || cv_sep_com 
                        || cv_sep_wquot   || lv_data_type || cv_sep_wquot;
--
        -- **************************************************
        -- *** 出力処理
        -- **************************************************
        -- CVSファイル出力の場合
        IF (iv_file_type = gv_csv_file) THEN
          UTL_FILE.PUT_LINE(lf_file_hand, lv_csv_file);
--
        -- 処理結果出力の場合
        ELSIF (iv_file_type = gv_rep_file) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_csv_file);
--
        END IF;
      END LOOP gt_material_info_tbl_loop;
--
      -- **************************************************
      -- *** CSVファイルクローズ
      -- **************************************************
      -- CSVファイル出力の場合
      IF (iv_file_type = gv_csv_file) THEN
        IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
          UTL_FILE.FCLOSE(lf_file_hand);
        END IF;
      END IF;
--
    END IF;
--
  --==============================================================
  --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
  --==============================================================
--
  EXCEPTION
--
    -- ファイルパス不正エラー
    WHEN UTL_FILE.INVALID_PATH THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip,
                                            gv_xxwip_output_nodir_err,
                                            gv_tkn_target_name,
                                            gv_out_file_name,
                                            gv_tkn_path,
                                            gv_out_dir);
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    --ファイル名不正エラー
    WHEN UTL_FILE.INVALID_FILENAME THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip,
                                            gv_xxwip_output_nodir_err,
                                            gv_tkn_target_name,
                                            gv_out_file_name,
                                            gv_tkn_path,
                                            gv_out_dir);
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    --ファイルアクセス権限エラー
    WHEN UTL_FILE.ACCESS_DENIED THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip,
                                            gv_xxwip_output_nodir_err,
                                            gv_tkn_target_name,
                                            gv_out_file_name,
                                            gv_tkn_path,
                                            gv_out_dir);
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
--
  /**********************************************************************************
   * Procedure Name   : set_batch_id
   * Description      : 生産バッチID格納 (D-5)
   ***********************************************************************************/
  PROCEDURE set_batch_id(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_send_type'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 対象データが0件以外の場合
    IF gt_material_info_tbl.COUNT <> 0 THEN
--
      -- **************************************************
      -- *** バッチID格納
      -- **************************************************
      <<batch_id_upd_tab_loop>>
      FOR i IN gt_material_info_tbl.FIRST .. gt_material_info_tbl.LAST LOOP
        gt_batch_id_upd_tab(i) := gt_material_info_tbl(i).batch_id;
      END LOOP batch_id_upd_tab_loop;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END set_batch_id;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_send_type
   * Description      : 送信済フラグ更新 (D-6)
   ***********************************************************************************/
  PROCEDURE upd_send_type(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_send_type'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 件数が0件以外の場合
    IF gt_batch_id_upd_tab.COUNT <> 0 THEN
--
      -- **************************************************
      -- *** 送信済フラグ更新一括更新処理
      -- **************************************************
      FORALL ln_cnt_loop IN gt_batch_id_upd_tab.FIRST .. gt_batch_id_upd_tab.LAST
        UPDATE gme_batch_header         -- 生産バッチヘッダ
        SET    attribute3               = gt_send_type_cmp                -- 送信区分（送信済み）
              ,last_updated_by          = FND_GLOBAL.USER_ID              -- 最終更新者
              ,last_update_date         = SYSDATE                         -- 最終更新日
              ,last_update_login        = FND_GLOBAL.LOGIN_ID             -- 最終更新ログイン
        WHERE batch_id = gt_batch_id_upd_tab(ln_cnt_loop);                   -- バッチID
--
  END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END upd_send_type;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf            OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lc_out_par    VARCHAR2(1000);   -- 入力パラメータ出力
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
    gn_target_cnt := 0;       -- 対象件数
    gn_normal_cnt := 0;       -- 正常件数
    gn_error_cnt  := 0;       -- エラー件数
    gn_warn_cnt   := 0;       -- スキップ件数
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理
    -- ===============================
--
    -- 開始時のシステム現在日付を代入
    gd_sysdate := SYSDATE;
--
    -- ===============================
    -- 前処理 (D-1)
    -- ===============================
    init_proc(
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象データ取得 (D-2)
    -- ===============================
    get_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- *******************************
    -- *** 対象件数 設定
    -- *******************************
    gn_target_cnt := gt_material_info_tbl.COUNT;
--
    -- ===============================
    -- 処理結果レポート出力 (D-4)
    -- ===============================
    output_csv(
      gv_rep_file,        -- 処理種別：処理結果レポート
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- CSVファイル出力 (D-4)
    -- ===============================
    output_csv(
      gv_csv_file,        -- 処理種別：CSVファイル出力
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 生産バッチID格納 (D-5)
    -- ===============================
    set_batch_id(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 送信済フラグ更新 (D-6)
    -- ===============================
    upd_send_type(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- *******************************
    -- *** 正常件数 設定
    -- *******************************
    gn_normal_cnt := gt_material_info_tbl.COUNT;
--
  EXCEPTION
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
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- エラー・メッセージ  --# 固定 #
    retcode             OUT NOCOPY VARCHAR2      -- リターン・コード    --# 固定 #
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
      lv_errbuf,             -- エラー・メッセージ           --# 固定 #
      lv_retcode,            -- リターン・コード             --# 固定 #
      lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
END xxwip200001c;
/
