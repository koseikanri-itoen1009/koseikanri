CREATE OR REPLACE PACKAGE BODY xxwip200003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP200003C(body)
 * Description      : 出来高実績アップロード
 * MD.050           : 生産バッチ T_MD050_BPO_202
 * MD.070           : 出来高実績アップロード T_MD070_BPO_20F
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_profile            プロファイル取得プロシージャ
 *  get_if_data            実績データ取得プロシージャ(E-1)
 *  get_tbl_lock           ロック取得プロシージャ(E-2)
 *  proc_check             チェック処理プロシージャ(E-3)
 *  proc_lot_execute       ロット登録・更新処理プロシージャ(E-4)
 *  proc_make_qt           品質検査処理プロシージャ(E-5)
 *  proc_update_material   出来高実績処理プロシージャ(E-6)
 *  proc_update_price      在庫単価更新処理プロシージャ(E-7)
 *  proc_save_batch        生産セーブ処理プロシージャ(E-8)
 *  term_proc              インタフェーステーブル削除処理プロシージャ(E-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/06    1.0   Oracle 山根 一浩 初回作成
 *  2008/05/27    1.1   Oracle 二瓶 大輔 結合テスト不具合対応(割当関数実行時に倉庫コード指定追加)
 *  2008/06/12    1.2   Oracle 二瓶 大輔 STテスト不具合対応#81
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  check_sub_main_expt             EXCEPTION;     -- サブメインでのエラー
  check_get_if_data_expt          EXCEPTION;     -- 実績データ取得でのエラー
  check_get_tbl_lock_expt         EXCEPTION;     -- ロック処理でのエラー
  check_proc_check_expt           EXCEPTION;     -- チェック処理のエラー
  check_proc_lot_execute_expt     EXCEPTION;     -- ロット登録・更新処理のエラー
  check_proc_make_qt_expt         EXCEPTION;     -- 品質検査処理のエラー
  check_proc_update_mat_expt      EXCEPTION;     -- 出来高実績処理のエラー
  check_proc_update_price_expt    EXCEPTION;     -- 在庫単価更新処理のエラー
  check_proc_save_batch_expt      EXCEPTION;     -- 生産セーブ処理のエラー
--
  lock_expt                       EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxwip200003c'; -- パッケージ名
  gv_item_class_code  CONSTANT VARCHAR2(1)   := '5';
  gv_test_code_mi     CONSTANT VARCHAR2(2)   := '10';
  gv_test_code_ok     CONSTANT VARCHAR2(2)   := '50';
  gv_data_ok          CONSTANT VARCHAR2(1)   := '0';
  gv_data_comp        CONSTANT VARCHAR2(1)   := '1';
  gv_test_code_off    CONSTANT VARCHAR2(1)   := '0';
  gv_test_code_on     CONSTANT VARCHAR2(1)   := '1';
  gv_division_prod    CONSTANT VARCHAR2(1)   := '1';
  gv_disposal_div_add CONSTANT VARCHAR2(1)   := '1';
  gv_disposal_div_upd CONSTANT VARCHAR2(1)   := '2';
--
  gv_prf_master_org_name    CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
    volume_actual_if_id   xxwip_volume_actual_if.volume_actual_if_id%TYPE,   -- 出来高実績IFID
    plant_code            xxwip_volume_actual_if.plant_code%TYPE,            -- プラントコード
    batch_no              xxwip_volume_actual_if.batch_no%TYPE,              -- 手配No
    item_code             xxwip_volume_actual_if.item_code%TYPE,             -- 品目コード
    volume_actual_qty     xxwip_volume_actual_if.volume_actual_qty%TYPE,     -- 出来高実績数
    rcv_date              xxwip_volume_actual_if.rcv_date%TYPE,              -- 受入実績日
    actual_date           xxwip_volume_actual_if.actual_date%TYPE,           -- 生産日
    maker_date            xxwip_volume_actual_if.maker_date%TYPE,            -- 製造日
    expiration_date       xxwip_volume_actual_if.expiration_date%TYPE,       -- 賞味期限日
--
    -- 検索項目
    batch_id              gme_batch_header.batch_id%TYPE,                    -- バッチID
    routing_no            gmd_routings_b.routing_no%TYPE,                    -- 工順番号
    routing_id            gmd_routings_b.routing_id%TYPE,                    -- 工順ID
    attribute19           gmd_routings_b.attribute19%TYPE,                   -- 固有番号
    attribute13           gmd_routings_b.attribute13%TYPE,                   -- 生産伝票区分
    attribute9            gmd_routings_b.attribute9%TYPE,                    -- 納品場所
    attribute20           gmd_routings_b.attribute20%TYPE,                   -- 作業部署
-- 2008/05/27 D.Nihei INS START
    attribute21           gmd_routings_b.attribute21%TYPE,                   -- 納品倉庫
-- 2008/05/27 D.Nihei INS END
    inventory_location_id xxcmn_item_locations_v.inventory_location_id%TYPE, -- 倉庫ID
    test_code             xxcmn_item_mst_v.test_code%TYPE,                   -- 試験有無区分
    item_um               xxcmn_item_mst_v.item_um%TYPE,                     -- 単位
    num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE,                -- ケース入数
    frequent_qty          xxcmn_item_mst_v.frequent_qty%TYPE,                -- 代表入数
    item_class_code       xxcmn_item_categories3_v.item_class_code%TYPE,     -- 品目区分
    material_detail_id    gme_material_details.material_detail_id%TYPE,      -- 生産原料詳細ID
    item_id               gme_material_details.item_id%TYPE,                 -- 品目ID
    lot_id                ic_tran_pnd.lot_id%TYPE,                           -- ロットID
    lot_no                ic_lots_mst.lot_no%TYPE,                           -- ロットNO
    attribute22           ic_lots_mst.attribute22%TYPE,                      -- 品質検査依頼NO
    batch_status          gme_batch_header.batch_status%TYPE,                -- バッチステータス
--
    in_data               VARCHAR2(5000),                                    -- 入力データ
--
    error_flg             BOOLEAN                                            -- 処理結果
--
  );
--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_prf_master_org_id      VARCHAR2(100);
  gt_mast_tb                masters_tbl; -- 各マスタへ登録するデータ
  gv_batch_no               xxwip_volume_actual_if.batch_no%TYPE;
--
  gd_sysdate               DATE;
  gn_user_id               NUMBER(15);
  gn_login_id              NUMBER(15);
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
    -- 生産バッチヘッダ
    CURSOR gc_gbh_cur
    IS
      SELECT gbh.batch_id
      FROM   gme_batch_header gbh
      WHERE  gbh.batch_no = gv_batch_no
      AND    ROWNUM = 1
      FOR UPDATE OF gbh.batch_id NOWAIT;
--
    -- 生産原料詳細
    CURSOR gc_gmd_cur
    IS
      SELECT gmd.batch_id
      FROM   gme_material_details gmd
      WHERE  EXISTS (
        SELECT gbh.batch_id
        FROM   gme_batch_header gbh
        WHERE  gbh.batch_no = gv_batch_no
        AND    gmd.batch_id = gbh.batch_id
        AND    ROWNUM = 1)
      FOR UPDATE OF gmd.batch_id NOWAIT;
--
    -- OPM保留在庫トランザクション
    CURSOR gc_itp_cur
    IS
      SELECT itp.trans_id
      FROM   ic_tran_pnd itp
      WHERE  EXISTS (
        SELECT gbh.batch_id
        FROM   gme_batch_header gbh
        WHERE  gbh.batch_no = gv_batch_no
        AND    itp.doc_id   = gbh.batch_id
        AND    ROWNUM = 1)
      FOR UPDATE OF itp.trans_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : プロファイルよりマスタ組織IDを取得します。
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --マスタ組織ID取得
    gv_prf_master_org_id := FND_PROFILE.VALUE(gv_prf_master_org_name);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_prf_master_org_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10067',
                                            'NG_PROFILE',
                                            'マスタ組織ID');
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_profile;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : 実績データ取得(E-1)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
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
    lb_retcd  BOOLEAN;
--
    -- *** ローカル・カーソル ***
    CURSOR actual_if_cur
    IS
      SELECT volume_actual_if_id
            ,plant_code
            ,batch_no
            ,item_code
            ,volume_actual_qty
            ,rcv_date
            ,actual_date
            ,maker_date
            ,expiration_date
            ,volume_actual_if_id||gv_msg_pnt||
             plant_code||gv_msg_pnt||
             batch_no||gv_msg_pnt||
             item_code||gv_msg_pnt||
             volume_actual_qty||gv_msg_pnt||
             rcv_date||gv_msg_pnt||
             actual_date||gv_msg_pnt||
             maker_date||gv_msg_pnt||
             expiration_date as in_data
      FROM  xxwip_volume_actual_if
      ORDER BY plant_code,batch_no;
--
    -- *** ローカル・レコード ***
    lr_actual_if_rec actual_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lb_retcd := TRUE;
--
    -- テーブルロック処理(出来高実績インタフェース)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock('XXWIP', 'xxwip_volume_actual_if');
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10004',
                                            'TABLE',
                                            '出来高実績インタフェース');
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    OPEN actual_if_cur;
--
    <<actual_if_loop>>
    LOOP
      FETCH actual_if_cur INTO lr_actual_if_rec;
      EXIT WHEN actual_if_cur%NOTFOUND;
--
      gt_mast_tb(gn_target_cnt).volume_actual_if_id := lr_actual_if_rec.volume_actual_if_id;
      gt_mast_tb(gn_target_cnt).plant_code          := lr_actual_if_rec.plant_code;
      gt_mast_tb(gn_target_cnt).batch_no            := lr_actual_if_rec.batch_no;
      gt_mast_tb(gn_target_cnt).item_code           := lr_actual_if_rec.item_code;
      gt_mast_tb(gn_target_cnt).volume_actual_qty   := lr_actual_if_rec.volume_actual_qty;
      gt_mast_tb(gn_target_cnt).rcv_date            := lr_actual_if_rec.rcv_date;
      gt_mast_tb(gn_target_cnt).actual_date         := lr_actual_if_rec.actual_date;
      gt_mast_tb(gn_target_cnt).maker_date          := lr_actual_if_rec.maker_date;
      gt_mast_tb(gn_target_cnt).expiration_date     := lr_actual_if_rec.expiration_date;
      gt_mast_tb(gn_target_cnt).in_data             := lr_actual_if_rec.in_data;
--
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP actual_if_loop;
--
    CLOSE actual_if_cur;
--
    -- データなし
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP','APP-XXWIP-10040');
      RAISE check_get_if_data_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_get_if_data_expt THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (actual_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE actual_if_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (actual_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE actual_if_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (actual_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE actual_if_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_if_data;
--
  /***********************************************************************************
   * Procedure Name   : get_tbl_lock
   * Description      : インタフェースのテーブルロックを行います。(E-2)
   ***********************************************************************************/
  PROCEDURE get_tbl_lock(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tbl_lock'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd    BOOLEAN;
--
    ln_batch_id            gme_batch_header.batch_id%TYPE;
    ln_trans_id            ic_tran_pnd.trans_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    gv_batch_no := ir_masters_rec.batch_no;
--
    -- 生産バッチヘッダ
    BEGIN
      OPEN gc_gmd_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10004',
                                              'TABLE',
                                              '生産原料詳細');
        lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
        RAISE check_get_tbl_lock_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- 生産原料詳細
    BEGIN
      OPEN gc_gbh_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10004',
                                              'TABLE',
                                              '生産バッチヘッダ');
        lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
        RAISE check_get_tbl_lock_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- OPM保留在庫トランザクション
    BEGIN
      OPEN gc_itp_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10004',
                                              'TABLE',
                                              'OPM保留在庫トランザクション');
        lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
        RAISE check_get_tbl_lock_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_get_tbl_lock_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_tbl_lock;
--
  /***********************************************************************************
   * Procedure Name   : proc_check
   * Description      : チェック処理を行います。(E-3)
   ***********************************************************************************/
  PROCEDURE proc_check(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd  BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      SELECT gbh.batch_id                                               -- バッチID
            ,grb.routing_no                                             -- 工順番号
            ,grb.routing_id                                             -- 工順ID
            ,grb.attribute19                                            -- 固有番号
            ,grb.attribute13                                            -- 生産伝票区分
            ,grb.attribute9                                             -- 納品場所
            ,grb.attribute20                                            -- 作業部署
-- 2008/05/27 D.Nihei INS START
            ,grb.attribute21                                            -- 納品倉庫
-- 2008/05/27 D.Nihei INS END
            ,xilv.inventory_location_id                                 -- 倉庫ID
            ,ximv.test_code                                             -- 試験有無区分
            ,ximv.item_um                                               -- 単位
            ,ximv.num_of_cases                                          -- ケース入数
            ,ximv.frequent_qty                                          -- 代表入数
            ,xicv.item_class_code                                       -- 品目区分
            ,gmd.material_detail_id                                     -- 生産原料詳細ID
            ,gmd.item_id                                                -- 品目ID
            ,itp.lot_id                                                 -- ロットID
            ,ilm.lot_no                                                 -- ロットNO
            ,ilm.attribute22                                            -- 品質検査依頼NO
            ,gbh.batch_status                                           -- バッチステータス
      INTO   ir_masters_rec.batch_id
            ,ir_masters_rec.routing_no
            ,ir_masters_rec.routing_id
            ,ir_masters_rec.attribute19
            ,ir_masters_rec.attribute13
            ,ir_masters_rec.attribute9
            ,ir_masters_rec.attribute20
-- 2008/05/27 D.Nihei INS START
            ,ir_masters_rec.attribute21
-- 2008/05/27 D.Nihei INS END
            ,ir_masters_rec.inventory_location_id
            ,ir_masters_rec.test_code
            ,ir_masters_rec.item_um
            ,ir_masters_rec.num_of_cases
            ,ir_masters_rec.frequent_qty
            ,ir_masters_rec.item_class_code
            ,ir_masters_rec.material_detail_id
            ,ir_masters_rec.item_id
            ,ir_masters_rec.lot_id
            ,ir_masters_rec.lot_no
            ,ir_masters_rec.attribute22
            ,ir_masters_rec.batch_status
      FROM   gme_batch_header gbh                               -- 生産バッチヘッダ
            ,gme_material_details gmd                           -- 生産原料詳細
            ,gmd_routings_b grb                                 -- 工順マスタ
            ,ic_tran_pnd itp                                    -- OPM保留在庫トランザクション
            ,ic_lots_mst ilm                                    -- OPMロットマスタ
            ,xxcmn_item_locations_v xilv                        -- OPM保管場所情報VIEW
            ,xxcmn_item_mst2_v ximv                             -- OPM品目情報VIEW2
            ,xxcmn_item_categories3_v xicv                      -- OPM品目カテゴリ割当情報VIEW3
      WHERE gbh.batch_id      = gmd.batch_id
      AND   gbh.routing_id    = grb.routing_id
      AND   xilv.segment1     = grb.attribute9
      AND   ximv.item_id      = gmd.item_id
      AND   ximv.item_id      = xicv.item_id
      AND   itp.line_type     = gmd.line_type
      AND   itp.doc_id        = gbh.batch_id
      AND   itp.line_id       = gmd.material_detail_id
      AND   itp.lot_id        = ilm.lot_id
      AND   gmd.item_id       = ilm.item_id
      AND   itp.lot_id        = 0
      AND   gmd.line_type     = 1
      AND   itp.delete_mark   = gv_data_ok
      AND   itp.completed_ind = gv_data_ok
      AND   ximv.item_no      = ir_masters_rec.item_code                -- 品目コード
      AND   gbh.plant_code    = ir_masters_rec.plant_code               -- プラントコード
      AND   gbh.batch_no      = ir_masters_rec.batch_no                 -- 手配No
      AND   ximv.start_date_active <= ir_masters_rec.actual_date        -- 生産日
      AND   ximv.end_date_active   >= ir_masters_rec.actual_date        -- 生産日
      AND   ROWNUM            = 1;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10042',
                                              'TABLE_NAME',
                                              '生産バッチヘッダテーブル',
                                              'DATA',
                                              ir_masters_rec.in_data);
--
        lv_errbuf := lv_errmsg;
        RAISE check_proc_check_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 出来高実績数が０以下
    IF (ir_masters_rec.volume_actual_qty <= 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10043',
                                            'ITEM',
                                            '出来高実績数',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_check_expt;
    END IF;
--
    -- 品目区分が製品以外
    IF (ir_masters_rec.item_class_code <> gv_item_class_code) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10071');
      RAISE check_proc_check_expt;
    END IF;
--
    -- バッチステータスが保留以外
    IF (ir_masters_rec.batch_status <> '1') THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10072');
      RAISE check_proc_check_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_check_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_check;
--
  /***********************************************************************************
   * Procedure Name   : proc_lot_execute
   * Description      : ロット登録・更新処理を行います。(E-4)
   ***********************************************************************************/
  PROCEDURE proc_lot_execute(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_lot_execute'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_in_lot_mst       ic_lots_mst%ROWTYPE;                 -- OPMロットマスタ
    lv_item_no          ic_item_mst_b.item_no%TYPE;          -- 品目コード
    ln_line_type        gme_material_details.line_type%TYPE; -- ラインタイプ
    lv_item_class_code  mtl_categories_b.segment1%TYPE;      -- 品目区分
    lv_lot_no_prod      ic_lots_mst.lot_no%TYPE;             -- 完成品のロットNo
    lr_out_lot_mst      ic_lots_mst%ROWTYPE;                 -- OPMロットマスタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lv_item_no                := ir_masters_rec.item_code;
    lv_item_class_code        := ir_masters_rec.item_class_code;
    ln_line_type              := 1;
    lr_in_lot_mst.item_id     := ir_masters_rec.item_id;
    lr_in_lot_mst.lot_id      := ir_masters_rec.lot_id;
    lr_in_lot_mst.attribute1  := TO_CHAR(ir_masters_rec.maker_date,'YYYY/MM/DD');
    lr_in_lot_mst.attribute2  := ir_masters_rec.attribute19;
    lr_in_lot_mst.attribute3  := TO_CHAR(ir_masters_rec.expiration_date,'YYYY/MM/DD');
    lr_in_lot_mst.attribute16 := ir_masters_rec.attribute13;
    lr_in_lot_mst.attribute17 := ir_masters_rec.routing_no;
    lr_in_lot_mst.attribute6  := TO_CHAR(ir_masters_rec.num_of_cases);
--
    -- 試験有無区分が無
    IF (ir_masters_rec.test_code = gv_test_code_off) THEN
      -- ロットステータスに’１０’
      lr_in_lot_mst.attribute23 := gv_test_code_mi;
--
    -- 試験有無区分が有
    ELSIF (ir_masters_rec.test_code = gv_test_code_on) THEN
      -- ロットステータスに’５０’
      lr_in_lot_mst.attribute23 := gv_test_code_ok;
    END IF;
--
    -- ロット追加・更新関数
    xxwip_common_pkg.lot_execute(
       ir_lot_mst         => lr_in_lot_mst
      ,it_item_no         => lv_item_no
      ,it_line_type       => ln_line_type
      ,it_item_class_code => lv_item_class_code
      ,it_lot_no_prod     => lv_lot_no_prod
      ,or_lot_mst         => lr_out_lot_mst
      ,ov_errbuf          => lv_errbuf
      ,ov_retcode         => lv_retcode
      ,ov_errmsg          => lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            'XXWIPロット追加・更新関数',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_lot_execute_expt;
    END IF;
--
    ir_masters_rec.lot_id := lr_out_lot_mst.lot_id;
    ir_masters_rec.attribute22 := lr_out_lot_mst.attribute22;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_lot_execute_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_lot_execute;
--
  /***********************************************************************************
   * Procedure Name   : proc_make_qt
   * Description      : 品質検査処理を行います。(E-5)
   ***********************************************************************************/
  PROCEDURE proc_make_qt(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_make_qt'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_division       xxwip_qt_inspection.division%TYPE;             -- IN  1.区分
    lv_disposal_div   VARCHAR2(1);                                   -- IN  2.処理区分
    ln_lot_id         xxwip_qt_inspection.lot_id%TYPE;               -- IN  3.ロットID
    ln_item_id        xxwip_qt_inspection.item_id%TYPE;              -- IN  4.品目ID
    lv_qt_object      VARCHAR2(1);                                   -- IN  5.対象先
    ln_batch_id       xxwip_qt_inspection.batch_po_id%TYPE;          -- IN  6.生産バッチID
    ln_batch_po_id    xxwip_qt_inspection.batch_po_id%TYPE;          -- IN  7.明細番号
    ln_qty            xxwip_qt_inspection.qty%TYPE;                  -- IN  8.数量
    ld_prod_dely_date xxwip_qt_inspection.prod_dely_date%TYPE;       -- IN  9.納入日
    lv_vendor_line    xxwip_qt_inspection.vendor_line%TYPE;          -- IN 10.仕入先コード
    ln_in_req_no      xxwip_qt_inspection.qt_inspect_req_no%TYPE;    -- IN 11.検査依頼No
    ln_out_req_no     xxwip_qt_inspection.qt_inspect_req_no%TYPE;    -- OUT 1.検査依頼No
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 試験有無区分が有かつ検査依頼NOがNULL
    IF ((ir_masters_rec.test_code = gv_test_code_on)
    AND (ir_masters_rec.attribute22 IS NULL)) THEN
--
      lv_division     := gv_division_prod;                    -- 区分：生産
      lv_disposal_div := gv_disposal_div_add;                 -- 処理区分：追加
      ln_batch_id     := ir_masters_rec.batch_id;             -- 生産バッチID
      ln_lot_id       := ir_masters_rec.lot_id;               -- ロットID
      ln_item_id      := ir_masters_rec.item_id;              -- 品目ID
--
      -- 品質検査依頼情報作成
      xxwip_common_pkg.make_qt_inspection(
         it_division          => lv_division
        ,iv_disposal_div      => lv_disposal_div
        ,it_lot_id            => ln_lot_id
        ,it_item_id           => ln_item_id
        ,iv_qt_object         => lv_qt_object
        ,it_batch_id          => ln_batch_id
        ,it_batch_po_id       => ln_batch_po_id
        ,it_qty               => ln_qty
        ,it_prod_dely_date    => ld_prod_dely_date
        ,it_vendor_line       => lv_vendor_line
        ,it_qt_inspect_req_no => ln_in_req_no
        ,ot_qt_inspect_req_no => ln_out_req_no
        ,ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10050',
                                              'API_NAME',
                                              '品質検査依頼情報作成',
                                              'DATA',
                                              ir_masters_rec.in_data);
        RAISE check_proc_make_qt_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_make_qt_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_make_qt;
--
  /***********************************************************************************
   * Procedure Name   : proc_update_material
   * Description      : 出来高実績処理を行います。(E-6)
   ***********************************************************************************/
  PROCEDURE proc_update_material(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_update_material'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_message_count         NUMBER;                             -- メッセージカウント
    lv_message_list          VARCHAR2(200);                      -- メッセージリスト
    lv_return_status         VARCHAR2(100);                      -- リターンステータス
    lr_tran_row_in           gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out          gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def          gme_inventory_txns_gtmp%ROWTYPE;
    lr_material_detail_out   gme_material_details%ROWTYPE;
    lr_gme_batch_header      gme_batch_header%ROWTYPE;
    lr_gme_batch_header_temp gme_batch_header%ROWTYPE;
    lr_unallocated_materials GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ステータス更新関数を実行
    xxwip_common_pkg.update_duty_status(
        in_batch_id     => ir_masters_rec.batch_id
        ,iv_duty_status => '7'
        ,ov_errbuf      => lv_errbuf
        ,ov_retcode     => lv_retcode
        ,ov_errmsg      => lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            'ステータス更新関数',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_update_mat_expt;
    END IF;
--
    BEGIN
      -- 生産原料詳細(直接更新)
      UPDATE gme_material_details gmd
      SET    gmd.batch_id          = ir_masters_rec.batch_id
            ,gmd.attribute6        = TO_CHAR(ir_masters_rec.num_of_cases)
            ,gmd.attribute10       = TO_CHAR(ir_masters_rec.expiration_date,'YYYY/MM/DD')
            ,gmd.attribute11       = TO_CHAR(ir_masters_rec.actual_date,'YYYY/MM/DD')
            ,gmd.attribute17       = TO_CHAR(ir_masters_rec.maker_date,'YYYY/MM/DD')
            ,gmd.last_update_login = gn_login_id
            ,gmd.last_update_date  = gd_sysdate
            ,gmd.last_updated_by   = gn_user_id
      WHERE  gmd.material_detail_id = ir_masters_rec.material_detail_id;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10050',
                                              'API_NAME',
                                              '原料明細更新関数',
                                              'DATA',
                                              ir_masters_rec.in_data);
        RAISE check_proc_update_mat_expt;
    END;
--
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;
    lr_tran_row_in.lot_id             := ir_masters_rec.lot_id;
    lr_tran_row_in.trans_qty          := ir_masters_rec.volume_actual_qty;
    lr_tran_row_in.trans_date         := ir_masters_rec.actual_date;
    lr_tran_row_in.location           := ir_masters_rec.attribute9;
    lr_tran_row_in.material_detail_id := ir_masters_rec.material_detail_id;
    lr_tran_row_in.completed_ind      := gv_data_comp;
-- 2008/05/27 D.Nihei INS START
    lr_tran_row_in.whse_code          := ir_masters_rec.attribute21; -- 納品倉庫
-- 2008/05/27 D.Nihei INS END
--
    -- 明細割当追加関数を実行
    GME_API_PUB.INSERT_LINE_ALLOCATION(
       P_API_VERSION        => GME_API_PUB.API_VERSION
      ,P_VALIDATION_LEVEL   => GME_API_PUB.MAX_ERRORS
      ,P_INIT_MSG_LIST      => FALSE
      ,P_COMMIT             => FALSE
      ,P_TRAN_ROW           => lr_tran_row_in
      ,P_LOT_NO             => ir_masters_rec.lot_no
      ,P_SUBLOT_NO          => NULL
      ,P_CREATE_LOT         => FALSE
      ,P_IGNORE_SHORTAGE    => FALSE
      ,P_SCALE_PHANTOM      => FALSE
      ,X_MATERIAL_DETAIL    => lr_material_detail_out
      ,X_TRAN_ROW           => lr_tran_row_out
      ,X_DEF_TRAN_ROW       => lr_tran_row_def
      ,X_MESSAGE_COUNT      => ln_message_count
      ,X_MESSAGE_LIST       => lv_message_list
      ,X_RETURN_STATUS      => lv_return_status
    );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            '明細割当追加関数',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_update_mat_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_update_mat_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_update_material;
--
  /***********************************************************************************
   * Procedure Name   : proc_update_price
   * Description      : 在庫単価更新処理を行います。(E-7)
   ***********************************************************************************/
  PROCEDURE proc_update_price(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_update_price'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_batch_id  gme_batch_header.batch_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ln_batch_id := ir_masters_rec.batch_id;
--
    -- 在庫単価更新関数
    xxwip_common_pkg.update_inv_price(
       it_batch_id  => ln_batch_id
      ,ov_errbuf    => lv_errbuf
      ,ov_retcode   => lv_retcode
      ,ov_errmsg    => lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            'XXWIP在庫単価更新関数',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_update_price_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_update_price_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_update_price;
--
  /***********************************************************************************
   * Procedure Name   : proc_save_batch
   * Description      : 生産セーブ処理を行います。(E-8)
   ***********************************************************************************/
  PROCEDURE proc_save_batch(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_save_batch'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_batch_header  gme_batch_header%ROWTYPE;
    lv_return_status VARCHAR2(30);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lr_batch_header.batch_id := ir_masters_rec.batch_id;
--
    -- 生産バッチセーブ
    GME_API_PUB.SAVE_BATCH (
      P_BATCH_HEADER    => lr_batch_header
     ,X_RETURN_STATUS   => lv_return_status
     ,P_COMMIT          => FALSE
    );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            '生産バッチセーブ API',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_save_batch_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_save_batch_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_save_batch;
--
  /***********************************************************************************
   * Procedure Name   : term_proc
   * Description      : インタフェーステーブル削除処理を行います。(E-9)
   ***********************************************************************************/
  PROCEDURE term_proc(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'term_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd   BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
 --#####################################  固定部 END   #############################################--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- データ削除(出来高実績インタフェース)
    lb_retcd := xxcmn_common_pkg.del_all_data('XXWIP','xxwip_volume_actual_if');
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN', 
                                            'APP-XXCMN-10022',
                                            'TABLE', 
                                            '出来高実績インタフェース');
--
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END term_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_cnt        NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    ln_cnt        := 0;
--
    gn_user_id     := FND_GLOBAL.USER_ID;
    gd_sysdate     := SYSDATE;
    gn_login_id    := FND_GLOBAL.LOGIN_ID;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- プロファイルの取得
    get_profile(lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- 実績データ取得(E-1)
    -- ===============================
    get_if_data(lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    <<chk_price_loop>>
    FOR i IN 0..gn_target_cnt-1 LOOP
--
      gt_mast_tb(i).error_flg := TRUE;
--
      -- ===============================
      -- テーブルロック取得(E-2)
      -- ===============================
      get_tbl_lock(gt_mast_tb(i),
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- チェック処理(E-3)
        -- ===============================
        proc_check(gt_mast_tb(i),
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- ロット登録・更新処理(E-4)
        -- ===============================
        proc_lot_execute(gt_mast_tb(i),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
  --
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- 出来高実績処理(E-6)
        -- ===============================
        proc_update_material(gt_mast_tb(i),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
  --
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- 生産セーブ処理(E-8)
        -- ===============================
        proc_save_batch(gt_mast_tb(i),
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- 在庫単価更新処理(E-7)
        -- ===============================
        proc_update_price(gt_mast_tb(i),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- 品質検査処理(E-5)
        -- ===============================
        proc_make_qt(gt_mast_tb(i),
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      -- カーソルが開いていれば
      IF (gc_gmd_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gmd_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_gbh_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gbh_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_itp_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_itp_cur;
      END IF;
--
      -- 処理成功
      IF (gt_mast_tb(i).error_flg) THEN
        COMMIT;
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        ROLLBACK;
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
--
    END LOOP chk_price_loop;
--
    -- ===============================
    -- インタフェーステーブル削除(E-9)
    -- ===============================
    term_proc(lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
-- 2008/06/12 D.Nihei ADD START
    -- ===============================
    -- リターンコード判定
    -- ===============================
    -- エラー件数が1件でも存在する場合は警告にする
    IF (gn_error_cnt > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
-- 2008/06/12 D.Nihei ADD END
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- カーソルが開いていれば
      IF (gc_gmd_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gmd_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_gbh_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gbh_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_itp_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_itp_cur;
      END IF;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (gc_gmd_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gmd_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_gbh_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gbh_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_itp_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_itp_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (gc_gmd_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gmd_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_gbh_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gbh_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_itp_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_itp_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (gc_gmd_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gmd_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_gbh_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_gbh_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_itp_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_itp_cur;
      END IF;
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
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2       --   リターン・コード    --# 固定 #
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
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
    submain(lv_errbuf,   -- エラー・メッセージ           --# 固定 #
            lv_retcode,  -- リターン・コード             --# 固定 #
            lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
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
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
                                            gv_status_normal, gv_sts_cd_normal,
                                            gv_status_warn,   gv_sts_cd_warn,
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
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwip200003c;
/
