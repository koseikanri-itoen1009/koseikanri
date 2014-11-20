CREATE OR REPLACE PACKAGE BODY xxwip_common2_pkg
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwip_common2_pkg(BODY)
 * Description            : 生産バッチ一覧画面用関数
 * MD.070(CMD.050)        : なし
 * Version                : 1.1
 *
 * Program List
 * --------------------   ---- ----- --------------------------------------------------
 *  Name                  Type  Ret   Description
 * --------------------   ---- ----- --------------------------------------------------
 * save_batch              P         バッチセーブAPI呼出 画面用
 * create_batch            P         バッチ作成API呼出 画面用
 * create_lot              P         ロット採番・ロット作成API呼出 画面用
 * insert_line_allocation  P         明細割当追加API呼出 画面用
 * insert_material_line    P         生産原料詳細追加API呼出 画面用
 * delete_material_line    P         生産原料詳細削除API呼出 画面用
 * reschedule_batch        P         バッチ再スケジュール
 * update_lot_dff          P         ロットマスタ更新API呼出 画面用
 * update_line_allocation  P         明細割当更新API呼出 画面用
 * delete_line_allocation  P         明細割当削除API呼出 画面用
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/08   1.0   T.Oikawa         新規作成
 *  2008/12/22   1.1   Oracle 二瓶 大輔 本番障害#743対応(ロット追加・更新関数)
 *****************************************************************************************/
AS
--
--###############################  固定グローバル定数宣言部 START   ###############################
--
  gv_status_normal                CONSTANT VARCHAR2(1) := '0';   --正常
  gv_status_warn                  CONSTANT VARCHAR2(1) := '1';   --警告
  gv_status_error                 CONSTANT VARCHAR2(1) := '2';   --失敗
  gv_sts_cd_normal                CONSTANT VARCHAR2(1) := 'C';   --ステータス(正常)
  gv_sts_cd_warn                  CONSTANT VARCHAR2(1) := 'G';   --ステータス(警告)
  gv_sts_cd_error                 CONSTANT VARCHAR2(1) := 'E';   --ステータス(失敗)
  gv_msg_part                     CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot                      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt                      CONSTANT VARCHAR2(3) := ',';
  gv_flg_on                       CONSTANT VARCHAR2(1) := '1';
  gv_msg_cont                     CONSTANT VARCHAR2(3) := '.';
  gv_prof_cost_price              CONSTANT VARCHAR2(26) := 'XXCMN_COST_PRICE_WHSE_CODE';
--
--#####################################  固定部 END   #############################################
--
--###############################  固定グローバル変数宣言部 START   ###############################
--
  gv_out_msg                      VARCHAR2(2000);
  gv_sep_msg                      VARCHAR2(2000);
  gv_exec_user                    VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name                    VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status                  VARCHAR2(30);              -- 処理結果
  gn_target_cnt                   NUMBER;                    -- 対象件数
  gn_normal_cnt                   NUMBER;                    -- 正常件数
  gn_error_cnt                    NUMBER;                    -- 失敗件数
  gn_warn_cnt                     NUMBER;                    -- 警告件数
  gn_report_cnt                   NUMBER;                    -- レポート件数
--
--#####################################  固定部 END   #############################################
--
--##################################  固定共通例外宣言部 START   ##################################
--
  --*** 処理部共通例外 ***
  global_process_expt             EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                 EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--#####################################  固定部 END   #############################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  api_expt                        EXCEPTION;     -- API例外
  skip_expt                       EXCEPTION;     -- スキップ例外
  deadlock_detected               EXCEPTION;     -- デッドロックエラー
--
  PRAGMA EXCEPTION_INIT( deadlock_detected, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                     CONSTANT VARCHAR2(100) := 'xxwip_common2_pkg'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn                        CONSTANT VARCHAR2(100) := 'XXCMN';            -- モジュール名略称：XXCMN 共通
  gv_xxwip                        CONSTANT VARCHAR2(100) := 'XXWIP';            -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
  -- メッセージ
  gv_msg_xxwip10049               CONSTANT VARCHAR2(100) := 'APP-XXWIP-10049';  -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
  gv_batch_no                     CONSTANT VARCHAR2(100) := 'バッチNo.';
--
  -- トークン
  gv_tkn_batch_no                 CONSTANT VARCHAR2(100) := 'BATCH_NO';         -- トークン：BATCH_NO
  gv_tkn_api_name                 CONSTANT VARCHAR2(100) := 'API_NAME';         -- トークン：API_NAME
--
  -- ラインタイプ
  gn_prod                         CONSTANT NUMBER        := 1;                  -- 完成品
  gn_co_prod                      CONSTANT NUMBER        := 2;                  -- 副産物
  gn_material                     CONSTANT NUMBER        := -1;                 -- 投入品
--
  gn_default_lot_id               CONSTANT NUMBER        := 0;                  -- デフォルトロットID
  gn_delete_mark_on               CONSTANT NUMBER        := 1;                  -- 削除フラグON
  gn_delete_mark_off              CONSTANT NUMBER        := 0;                  -- 削除フラグOFF
  gv_cmpnt_code_gen               CONSTANT VARCHAR2(5)   := '01GEN';            -- 品目コンポーネント区分：01GEN
  -- xxcmn共通関数リターン・コード
  gn_e                            CONSTANT NUMBER        := 1;                  -- xxcmn共通関数リターン・コード：1（エラー）
--
  -- 業務ステータス
  gt_duty_status_com              CONSTANT gme_batch_header.attribute4%TYPE  := '7';  -- 業務ステータス：7（完了）
  gt_duty_status_cls              CONSTANT gme_batch_header.attribute4%TYPE  := '8';  -- 業務ステータス：8（クローズ）
  gt_duty_status_can              CONSTANT gme_batch_header.attribute4%TYPE  := '-1'; -- 業務ステータス：-1（取消）
  -- 区分
  gt_division_gme                 CONSTANT xxwip_qt_inspection.division%TYPE := '1';  -- 区分  1:生産
  gt_division_po                  CONSTANT xxwip_qt_inspection.division%TYPE := '2';  -- 区分  2:発注
  gt_division_lot                 CONSTANT xxwip_qt_inspection.division%TYPE := '3';  -- 区分  3:ロット情報
  gt_division_spl                 CONSTANT xxwip_qt_inspection.division%TYPE := '4';  -- 区分  4:外注出来高
  gt_division_tea                 CONSTANT xxwip_qt_inspection.division%TYPE := '5';  -- 区分  5:荒茶製造
  -- 処理区分
  gv_disposal_div_ins             CONSTANT VARCHAR2(1) := '1'; -- 処理区分  1:追加
  gv_disposal_div_upd             CONSTANT VARCHAR2(1) := '2'; -- 処理区分  2:更新
  gv_disposal_div_del             CONSTANT VARCHAR2(1) := '3'; -- 処理区分  3:削除
  -- 対象先
  gv_qt_object_tea                CONSTANT VARCHAR2(1) := '1'; -- 対象先  1:荒茶品目
  gv_qt_object_bp1                CONSTANT VARCHAR2(1) := '2'; -- 対象先  2:副産物１
  gv_qt_object_bp2                CONSTANT VARCHAR2(1) := '3'; -- 対象先  3:副産物２
  gv_qt_object_bp3                CONSTANT VARCHAR2(1) := '4'; -- 対象先  4:副産物３
  -- 生産原料詳細.ラインタイプ
  gt_line_type_goods              CONSTANT gme_material_details.line_type%TYPE := 1;    -- ラインタイプ：1（完成品）
  gt_line_type_sub                CONSTANT gme_material_details.line_type%TYPE := 2;    -- ラインタイプ：2（副産物）
  -- OPM保留在庫トランザクション.完了フラグ
  gt_completed_ind_com            CONSTANT ic_tran_pnd.completed_ind%TYPE     := '1';  -- 完了フラグ：1（完了）
  -- 品質検査結果
  gt_qt_status_mi                 CONSTANT fnd_lookup_values.lookup_code%TYPE := '10';  -- 品質検査結果 10:未判定
  -- 検査種別
  gt_inspect_class_gme            CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '1'; -- 検査種別：1（生産）
  gt_inspect_class_po             CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '2'; -- 検査種別：2（発注仕入）
  -- 品目区分
  gv_item_type_harf_prod          CONSTANT VARCHAR2(1) := '4'; -- 品目区分  4:半製品
  gv_item_type_prod               CONSTANT VARCHAR2(1) := '5'; -- 品目区分  5:製品
  -- OPMロットマスタDFF更新APIバージョン
  gn_api_version                  CONSTANT NUMBER(2,1) := 1.0;
--
  -- 外注出来高情報.処理タイプ
  gt_txns_type_aite               CONSTANT xxpo_vendor_supply_txns.txns_type%TYPE := '1';  -- 処理タイプ：相手先在庫
  gt_txns_type_sok                CONSTANT xxpo_vendor_supply_txns.txns_type%TYPE := '2';  -- 処理タイプ：即時仕入
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /************************************************************************
   * Procedure Name  : save_batch
   * Description     : バッチセーブAPI呼出
   ************************************************************************/
  PROCEDURE save_batch(
    it_batch_id                     IN  gme_batch_header.batch_id%TYPE
  , ov_retcode                      OUT VARCHAR2
  )
  IS
    lr_batch_save                   gme_batch_header%ROWTYPE;
    lv_return_status                VARCHAR2(100);
--
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'save_batch';     -- プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := 'バッチセーブ';
--
  BEGIN
    -- パラメータ設定
    lr_batch_save.batch_id := it_batch_id;
--
    -- バッチセーブAPI実行
    GME_API_PUB.SAVE_BATCH(
      p_batch_header                  =>  lr_batch_save
    , x_return_status                 =>  lv_return_status 
    );
--
    -- リターンコード設定
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END save_batch;
--
  /**********************************************************************************
   * Procedure Name   : create_batch
   * Description      : バッチ作成API呼出
   ***********************************************************************************/
  PROCEDURE create_batch(
    it_plan_start_date              IN  gme_batch_header.plan_start_date          %TYPE
  , it_plan_cmplt_date              IN  gme_batch_header.plan_cmplt_date          %TYPE
  , it_recipe_validity_rule_id      IN  gme_batch_header.recipe_validity_rule_id  %TYPE   -- 妥当性ルールID
  , it_plant_code                   IN  gme_batch_header.plant_code               %TYPE
  , it_wip_whse_code                IN  gme_batch_header.wip_whse_code            %TYPE
  , in_batch_size                   IN  NUMBER
  , iv_batch_size_uom               IN  VARCHAR2
  , ot_batch_id                     OUT gme_batch_header.batch_id                 %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'create_batch';            --プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := 'バッチ作成API呼出';
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(200);
    lv_return_status                VARCHAR2(10);
--
    lr_batch_header_in              gme_batch_header%ROWTYPE;
    lr_batch_header_out             gme_batch_header%ROWTYPE;
    unallocated_materials_tab       GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
--
  BEGIN
    -- ***********************************************
    -- ***  バッチ作成
    -- ***********************************************
    lr_batch_header_in.plan_start_date         := it_plan_start_date;
    lr_batch_header_in.plan_cmplt_date         := it_plan_cmplt_date;
    lr_batch_header_in.recipe_validity_rule_id := it_recipe_validity_rule_id;   -- 妥当性ルールID
    lr_batch_header_in.plant_code              := it_plant_code;
    lr_batch_header_in.wip_whse_code           := it_wip_whse_code;
    lr_batch_header_in.batch_type              := 0;
--
    -- バッチ作成API実行
    GME_API_PUB.CREATE_BATCH(
      p_api_version                   =>  GME_API_PUB.API_VERSION         --      IN         NUMBER
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS          --      IN         NUMBER := gme_api_pub.max_errors,
    , p_init_msg_list                 =>  FALSE                           --      IN         BOOLEAN := FALSE ,
    , p_commit                        =>  FALSE                           --      IN         BOOLEAN := FALSE ,
    , x_message_count                 =>  ln_message_count                --      OUT NOCOPY NUMBER,
    , x_message_list                  =>  lv_message_list                 --      OUT NOCOPY VARCHAR2,
    , x_return_status                 =>  lv_return_status                --      OUT NOCOPY VARCHAR2,
    , p_batch_header                  =>  lr_batch_header_in              -- 必須 IN         gme_batch_header%ROWTYPE,
    , x_batch_header                  =>  lr_batch_header_out             -- 必須 OUT NOCOPY gme_batch_header%ROWTYPE,
    , p_batch_size                    =>  in_batch_size                   -- 必須 IN         NUMBER := NULL,
    , p_batch_size_uom                =>  iv_batch_size_uom               -- 必須 IN         VARCHAR2 := NULL,
    , p_creation_mode                 =>  'PRODUCT'                       -- 必須 IN         VARCHAR2,
    , p_recipe_id                     =>  NULL                            --      IN         NUMBER := NULL,
    , p_recipe_no                     =>  NULL                            --      IN         VARCHAR2 := NULL,
    , p_recipe_version                =>  NULL                            --      IN         NUMBER := NULL,
    , p_product_no                    =>  NULL                            --      IN         VARCHAR2 := NULL,
    , p_product_id                    =>  NULL                            --      IN         NUMBER := NULL,
    , p_ignore_qty_below_cap          =>  TRUE                            --      IN         BOOLEAN := TRUE ,
    , p_ignore_shortages              =>  TRUE                            -- 必須 IN         BOOLEAN,
    , p_use_shop_cal                  =>  NULL                            --      IN         NUMBER,
    , p_contiguity_override           =>  NULL                            --      IN         NUMBER,
    , x_unallocated_material          =>  unallocated_materials_tab       -- 必須 OUT NOCOPY GME_API_PUB.UNALLOCATED_MATERIALS_TAB 非割当の原料または在庫不足のエラー戻り
    );
--
    -- エラー発生時
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := 'バッチ作成に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 作成されたバッチIDをセット
    ot_batch_id := lr_batch_header_out.batch_id;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END create_batch;
--
  /**********************************************************************************
   * Procedure Name   : create_lot
   * Description      : ロット採番・ロット作成API呼出
   ***********************************************************************************/
  PROCEDURE create_lot(
    it_item_id                      IN         ic_item_mst_b.item_id%TYPE    -- 品目ID
  , it_item_no                      IN         ic_item_mst_b.item_no%TYPE    -- 品目コード
  , ot_lot_id                       OUT NOCOPY ic_lots_mst.lot_id   %TYPE    -- ロットID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                      -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                      -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                      -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'create_lot';            --プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := 'ロット採番・ロット作成';
--
    lt_lot_no                       ic_lots_mst.lot_no   %TYPE;              -- ロットNo
    lt_sublot_no                    ic_lots_mst.sublot_no%TYPE;              -- サブロットNo
    ln_return_status                NUMBER;                                  -- リターンステータス
    lv_return_status                VARCHAR2(1);                             -- リターンステータス
    ln_message_count                NUMBER;
    lv_msg_data                     VARCHAR2(10000);
--
    lr_create_lot                   GMIGAPI.LOT_REC_TYP;
    lr_ic_lots_mst                  ic_lots_mst%ROWTYPE;
    lr_ic_lots_cpg                  ic_lots_cpg%ROWTYPE;
--
    lv_errbuf                       VARCHAR2(5000);                          -- エラー・メッセージ
    lv_retcode                      VARCHAR2(1);                             -- リターン・コード
    lv_errmsg                       VARCHAR2(5000);                          -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ***********************************************
    -- ***  ロットNo採番
    -- ***********************************************
    GMI_AUTOLOT.GENERATE_LOT_NUMBER(
      p_item_id                       =>  it_item_id          -- IN         NUMBER
    , p_in_lot_no                     =>  NULL                -- IN         VARCHAR2
    , p_orgn_code                     =>  NULL                -- IN         VARCHAR2
    , p_doc_id                        =>  NULL                -- IN         NUMBER
    , p_line_id                       =>  NULL                -- IN         NUMBER
    , p_doc_type                      =>  NULL                -- IN         VARCHAR2
    , p_out_lot_no                    =>  lt_lot_no           -- OUT NOCOPY VARCHAR2
    , p_sublot_no                     =>  lt_sublot_no        -- OUT NOCOPY VARCHAR2
    , p_return_status                 =>  ln_return_status    -- OUT NOCOPY NUMBER
    );
--
    -- 採番されていない場合、エラー終了
    IF ( lt_lot_no IS NULL ) THEN
      ov_errmsg  := 'ロット採番に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- ***********************************************
    -- ***  ロット作成
    -- ***********************************************
    lr_create_lot.item_no          := it_item_no;
    lr_create_lot.lot_no           := lt_lot_no;
    lr_create_lot.sublot_no        := NULL;
    lr_create_lot.lot_desc         := NULL;
    lr_create_lot.origination_type := 2;
    lr_create_lot.attribute24      := '5'; -- 生産出来高
    lr_create_lot.user_name        := FND_GLOBAL.USER_NAME;
    lr_create_lot.lot_created      := SYSDATE;
-- 2008/12/22 D.Nihei ADD START
    lr_create_lot.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD');
    lr_create_lot.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/22 D.Nihei ADD END
--
    -- ロット作成API
    GMIPAPI.CREATE_LOT(
      p_api_version                   =>  3.0                           -- IN         NUMBER
    , p_init_msg_list                 =>  FND_API.G_FALSE               -- IN         VARCHAR2 default fnd_api.g_false
    , p_commit                        =>  FND_API.G_FALSE               -- IN         VARCHAR2 default fnd_api.g_false
    , p_validation_level              =>  FND_API.G_VALID_LEVEL_FULL    -- IN         NUMBER   default fnd_api.g_valid_level_full
    , p_lot_rec                       =>  lr_create_lot                 -- IN         GMIGAPI.lot_rec_typ
    , x_ic_lots_mst_row               =>  lr_ic_lots_mst                -- OUT NOCOPY ic_lots_mst%ROWTYPE
    , x_ic_lots_cpg_row               =>  lr_ic_lots_cpg                -- OUT NOCOPY ic_lots_cpg%ROWTYPE
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    , x_msg_count                     =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_msg_data                      =>  lv_msg_data                   -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_msg_data;
      ov_errmsg  := 'ロット作成に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 作成されたロットIDをセット
    ot_lot_id := lr_ic_lots_mst.lot_id;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END create_lot;
--
  /**********************************************************************************
   * Procedure Name   : insert_line_allocation
   * Description      : 明細割当追加API呼出
   ***********************************************************************************/
  PROCEDURE insert_line_allocation(
    it_item_id                      IN         gme_inventory_txns_gtmp.item_id            %TYPE
  , it_whse_code                    IN         gme_inventory_txns_gtmp.whse_code          %TYPE
  , it_lot_id                       IN         gme_inventory_txns_gtmp.lot_id             %TYPE
  , it_location                     IN         gme_inventory_txns_gtmp.location           %TYPE
  , it_doc_id                       IN         gme_inventory_txns_gtmp.doc_id             %TYPE
  , it_trans_date                   IN         gme_inventory_txns_gtmp.trans_date         %TYPE
  , it_trans_qty                    IN         gme_inventory_txns_gtmp.trans_qty          %TYPE
  , it_completed_ind                IN         gme_inventory_txns_gtmp.completed_ind      %TYPE
  , it_material_detail_id           IN         gme_inventory_txns_gtmp.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'insert_line_allocation';            --プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := '明細割当追加API呼出';
--
    lv_errbuf                       VARCHAR2(5000);                          -- エラー・メッセージ
    lv_retcode                      VARCHAR2(1);                             -- リターン・コード
    lv_errmsg                       VARCHAR2(5000);                          -- ユーザー・エラー・メッセージ
--
    ln_message_cnt                  NUMBER;
    lv_return_status                VARCHAR2(1);
    lv_message_list                 VARCHAR2(200);
--
    lr_material_detail              gme_material_details     %ROWTYPE;
    lr_tran_row_in                  gme_inventory_txns_gtmp  %ROWTYPE;
    lr_tran_row_out                 gme_inventory_txns_gtmp  %ROWTYPE;
    lr_def_tran_row                 gme_inventory_txns_gtmp  %ROWTYPE;
--
  BEGIN
    -- ***********************************************
    -- ***  明細割当追加
    -- ***********************************************
    -- パラメータ設定
    lr_tran_row_in.item_id            := it_item_id;
    lr_tran_row_in.whse_code          := it_whse_code;
    lr_tran_row_in.lot_id             := it_lot_id;
    lr_tran_row_in.location           := it_location;
    lr_tran_row_in.doc_id             := it_doc_id;
    lr_tran_row_in.trans_date         := it_trans_date;
    lr_tran_row_in.trans_qty          := it_trans_qty;
    lr_tran_row_in.completed_ind      := it_completed_ind;
    lr_tran_row_in.material_detail_id := it_material_detail_id;
--
    -- 明細割当追加API実行
    GME_API_PUB.INSERT_LINE_ALLOCATION(
      p_api_version                   =>  GME_API_PUB.API_VERSION       -- IN         NUMBER  := gme_api_pub.api_version
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS        -- IN         NUMBER  := gme_api_pub.max_errors
    , p_init_msg_list                 =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_tran_row                      =>  lr_tran_row_in                -- IN         gme_inventory_txns_gtmp%ROWTYPE
    , p_lot_no                        =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_sublot_no                     =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_create_lot                    =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , p_ignore_shortage               =>  TRUE                          -- IN         BOOLEAN DEFAULT FALSE
    , p_scale_phantom                 =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , x_material_detail               =>  lr_material_detail            -- OUT NOCOPY gme_material_details%ROWTYPE,
    , x_tran_row                      =>  lr_tran_row_out               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE,
    , x_def_tran_row                  =>  lr_def_tran_row               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE,
    , x_message_count                 =>  ln_message_cnt                -- OUT NOCOPY NUMBER,
    , x_message_list                  =>  lv_message_list               -- OUT NOCOPY VARCHAR2,
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '明細割当追加に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END insert_line_allocation;
--
  /************************************************************************
   * Procedure Name  : insert_material_line
   * Description     : 生産原料詳細追加API呼出
   ************************************************************************/
  PROCEDURE insert_material_line(
    it_batch_id                     IN  gme_material_details.batch_id           %TYPE -- バッチID
  , it_item_id                      IN  gme_material_details.item_id            %TYPE -- 品目ID
  , it_item_um                      IN  gme_material_details.item_um            %TYPE -- 単位
  , it_slit                         IN  gme_material_details.attribute8         %TYPE -- 投入口
  , it_attribute5                   IN  gme_material_details.attribute5         %TYPE -- 打込区分
  , it_attribute7                   IN  gme_material_details.attribute7         %TYPE -- 依頼総数
  , it_attribute13                  IN  gme_material_details.attribute13        %TYPE -- 出倉庫コード１
  , it_attribute18                  IN  gme_material_details.attribute18        %TYPE -- 出倉庫コード２
  , it_attribute19                  IN  gme_material_details.attribute19        %TYPE -- 出倉庫コード３
  , it_attribute20                  IN  gme_material_details.attribute20        %TYPE -- 出倉庫コード４
  , it_attribute21                  IN  gme_material_details.attribute21        %TYPE -- 出倉庫コード５
  , ot_material_detail_id           OUT gme_material_details.material_detail_id %TYPE -- 生産原料詳細ID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                               -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                               -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                               -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'insert_material_line';     -- プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := '生産原料詳細追加API呼出';
--
    ln_line_no                      NUMBER;
    ln_batch_step_no                NUMBER;
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(200);
    lv_return_status                VARCHAR2(10);
    lv_api_msg                      VARCHAR2(2000);
    ln_dummy_cnt                    NUMBER;
--
    lr_material_detail_in           gme_material_details%ROWTYPE;
    lr_material_detail_out          gme_material_details%ROWTYPE;
--
  BEGIN
    -- 行番号を取得
    SELECT COUNT( gmd.rowid ) + 1
    INTO ln_line_no
    FROM gme_material_details  gmd
    WHERE gmd.line_type = -1
      AND gmd.batch_id  = it_batch_id
    ;
--
    -- パラメータ設定
    lr_material_detail_in.batch_id                := it_batch_id;
    lr_material_detail_in.line_no                 := ln_line_no;
    lr_material_detail_in.item_id                 := it_item_id;
    lr_material_detail_in.line_type               := -1;
    lr_material_detail_in.item_um                 := it_item_um;
    lr_material_detail_in.release_type            := 1;                                     -- リリースタイプ
    lr_material_detail_in.scrap_factor            := 0;                                     -- 廃棄係数
    lr_material_detail_in.scale_type              := 1;                                     -- スケールタイプ
    lr_material_detail_in.phantom_type            := 0;
    lr_material_detail_in.contribute_yield_ind    := 'Y';                                   -- コントリビュート収率
    lr_material_detail_in.contribute_step_qty_ind := 'Y';                                   -- コントリビュート払出先ステップ数量
    lr_material_detail_in.plan_qty                := NVL( TO_NUMBER( it_attribute7 ), 0 );  -- 計画数
    lr_material_detail_in.actual_qty              := NULL;                                  -- 実績数量
    lr_material_detail_in.original_qty            := NULL;                                  -- オリジナル数量
--
    ln_batch_step_no := TO_NUMBER( it_slit );
--
    lr_material_detail_in.attribute5  := it_attribute5;
    lr_material_detail_in.attribute7  := it_attribute7;
    lr_material_detail_in.attribute8  := it_slit;
    lr_material_detail_in.attribute13 := it_attribute13;
    lr_material_detail_in.attribute18 := it_attribute18;
    lr_material_detail_in.attribute19 := it_attribute19;
    lr_material_detail_in.attribute20 := it_attribute20;
    lr_material_detail_in.attribute21 := it_attribute21;
--
    -- 生産原料詳細追加API実行
    GME_API_PUB.INSERT_MATERIAL_LINE(
      p_api_version               =>  GME_API_PUB.API_VERSION         -- IN         NUMBER  := gme_api_pub.api_version
    , p_validation_level          =>  GME_API_PUB.MAX_ERRORS          -- IN         NUMBER  := gme_api_pub.max_errors
    , p_init_msg_list             =>  FALSE                           -- IN         BOOLEAN := FALSE
    , p_commit                    =>  FALSE                           -- IN         BOOLEAN := FALSE
    , x_message_count             =>  ln_message_count                -- OUT NOCOPY NUMBER
    , x_message_list              =>  lv_message_list                 -- OUT NOCOPY VARCHAR2
    , x_return_status             =>  lv_return_status                -- OUT NOCOPY VARCHAR2
    , p_material_detail           =>  lr_material_detail_in           -- IN         gme_material_details%ROWTYPE
    , p_batchstep_no              =>  ln_batch_step_no                -- IN         NUMBER DEFAULT NULL
    , x_material_detail           =>  lr_material_detail_out          -- OUT NOCOPY gme_material_details%ROWTYPE
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_message_list;
      ov_errmsg  := '生産原料詳細追加に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ot_material_detail_id := lr_material_detail_out.material_detail_id;
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END insert_material_line;
--
  /************************************************************************
   * Procedure Name  : delete_material_line
   * Description     : 生産原料詳細削除API呼出
   ************************************************************************/
  PROCEDURE delete_material_line(
    it_batch_id                     IN  gme_material_details.item_id            %TYPE
  , it_material_detail_id           IN  gme_material_details.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'delete_material_line';     -- プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := '生産原料詳細削除';
--
    lv_errbuf                       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                      VARCHAR2(1);     -- リターン・コード
    lv_errmsg                       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
    lv_return_status                VARCHAR2(100);
--
    lr_material_detail_in           gme_material_details    %ROWTYPE;
--
  BEGIN
    lr_material_detail_in.batch_id           := it_batch_id;
    lr_material_detail_in.material_detail_id := it_material_detail_id;
--
    GME_API_PUB.DELETE_MATERIAL_LINE(
      p_api_version                   =>  GME_API_PUB.API_VERSION     -- IN         NUMBER  := gme_api_pub.api_version
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS      -- IN         NUMBER  := gme_api_pub.max_errors
    , p_init_msg_list                 =>  FALSE                       -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                       -- IN         BOOLEAN := FALSE
    , x_message_count                 =>  ln_message_count            -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list             -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status            -- OUT NOCOPY VARCHAR2
    , p_material_detail               =>  lr_material_detail_in       -- IN         gme_material_details%ROWTYPE
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '生産原料詳細削除に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END delete_material_line;
--
  /************************************************************************
   * Procedure Name  : reschedule_batch
   * Description     : バッチ再スケジュール
   ************************************************************************/
  PROCEDURE reschedule_batch(
    it_batch_id                     IN         gme_batch_header.batch_id         %TYPE
  , it_plan_start_date              IN         gme_batch_header.plan_start_date  %TYPE
  , it_plan_cmplt_date              IN         gme_batch_header.plan_cmplt_date  %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'reschedule_batch';     -- プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := 'バッチ再スケジュール';
--
    lv_return_status                VARCHAR2(1);
    lv_retcode                      VARCHAR2(1);
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
--
    p_batch_header                  gme_batch_header%ROWTYPE;
    o_batch_header                  gme_batch_header%ROWTYPE;
--
  BEGIN
    p_batch_header.batch_id        := it_batch_id;
    p_batch_header.plan_start_date := it_plan_start_date;
    p_batch_header.plan_cmplt_date := it_plan_cmplt_date;
--
    -- バッチ再スケジュールAPIを実行
    GME_API_PUB.RESCHEDULE_BATCH(
      p_api_version                   =>  GME_API_PUB.API_VERSION     -- IN         NUMBER := GME_API_PUB.API_VERSION
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS      -- IN         NUMBER := GME_API_PUB.MAX_ERRORS
    , p_init_msg_list                 =>  FALSE                       -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                       -- IN         BOOLEAN := FALSE
    , x_message_count                 =>  ln_message_count            -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list             -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status            -- OUT NOCOPY VARCHAR2
    , p_batch_header                  =>  p_batch_header              -- IN         gme_batch_header%ROWTYPE
    , p_use_shop_cal                  =>  NULL                        -- IN         NUMBER
    , p_contiguity_override           =>  NULL                        -- IN         NUMBER
    , x_batch_header                  =>  o_batch_header              -- OUT NOCOPY gme_batch_header%ROWTYPE
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := 'バッチ再スケジュールに失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END reschedule_batch;
--
  /**********************************************************************************
   * Procedure Name   : update_lot_dff
   * Description      : ロットマスタDFF更新API呼出
  /*********************************************************************************/
  PROCEDURE update_lot_dff(
    it_item_id                      IN         ic_lots_mst.item_id     %TYPE              -- 品目ID
  , it_lot_id                       IN         ic_lots_mst.lot_id      %TYPE              -- ロットID
  , it_attribute2                   IN         ic_lots_mst.attribute2  %TYPE DEFAULT NULL -- 固有記号
  , it_attribute13                  IN         ic_lots_mst.attribute13 %TYPE DEFAULT NULL -- タイプ
  , it_attribute14                  IN         ic_lots_mst.attribute14 %TYPE DEFAULT NULL -- ランク1
  , it_attribute15                  IN         ic_lots_mst.attribute15 %TYPE DEFAULT NULL -- ランク2
  , it_attribute16                  IN         ic_lots_mst.attribute16 %TYPE DEFAULT NULL -- 伝票区分
  , it_attribute17                  IN         ic_lots_mst.attribute17 %TYPE DEFAULT NULL -- ラインNo
  , it_attribute18                  IN         ic_lots_mst.attribute18 %TYPE DEFAULT NULL -- 摘要
  , it_attribute23                  IN         ic_lots_mst.attribute23 %TYPE DEFAULT NULL -- ロットステータス
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'update_lot_dff';       -- プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := 'ロットマスタDFF更新API呼出';
--
    lv_errbuf                       VARCHAR2(5000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(5000);
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(200);
--
    lr_ic_lots_mst                  ic_lots_mst%ROWTYPE;
--
  BEGIN
    -- パラメータ設定
    lr_ic_lots_mst.last_updated_by        := FND_GLOBAL.USER_ID;                -- 最終更新者
    lr_ic_lots_mst.last_update_date       := SYSDATE;                           -- 最終更新日
--
    -- OPMロットマスタDFF取得
    BEGIN
      SELECT
        ilm.item_id           item_id
      , ilm.lot_id            lot_id
      , ilm.lot_no            lot_no
      , ilm.attribute1        attribute1
      , ilm.attribute2        attribute2
      , ilm.attribute3        attribute3
      , ilm.attribute4        attribute4
      , ilm.attribute5        attribute5
      , ilm.attribute6        attribute6
      , ilm.attribute7        attribute7
      , ilm.attribute8        attribute8
      , ilm.attribute9        attribute9
      , ilm.attribute10       attribute10
      , ilm.attribute11       attribute11
      , ilm.attribute12       attribute12
      , ilm.attribute13       attribute13
      , ilm.attribute14       attribute14
      , ilm.attribute15       attribute15
      , ilm.attribute16       attribute16
      , ilm.attribute17       attribute17
      , ilm.attribute18       attribute18
      , ilm.attribute19       attribute19
      , ilm.attribute20       attribute20
      , ilm.attribute21       attribute21
      , ilm.attribute22       attribute22
      , ilm.attribute23       attribute23
      , ilm.attribute24       attribute24
      , ilm.attribute25       attribute25
      , ilm.attribute26       attribute26
      , ilm.attribute27       attribute27
      , ilm.attribute28       attribute28
      , ilm.attribute29       attribute29
      , ilm.attribute30       attribute30
      INTO
        lr_ic_lots_mst.item_id
      , lr_ic_lots_mst.lot_id
      , lr_ic_lots_mst.lot_no
      , lr_ic_lots_mst.attribute1
      , lr_ic_lots_mst.attribute2
      , lr_ic_lots_mst.attribute3
      , lr_ic_lots_mst.attribute4
      , lr_ic_lots_mst.attribute5
      , lr_ic_lots_mst.attribute6
      , lr_ic_lots_mst.attribute7
      , lr_ic_lots_mst.attribute8
      , lr_ic_lots_mst.attribute9
      , lr_ic_lots_mst.attribute10
      , lr_ic_lots_mst.attribute11
      , lr_ic_lots_mst.attribute12
      , lr_ic_lots_mst.attribute13
      , lr_ic_lots_mst.attribute14
      , lr_ic_lots_mst.attribute15
      , lr_ic_lots_mst.attribute16
      , lr_ic_lots_mst.attribute17
      , lr_ic_lots_mst.attribute18
      , lr_ic_lots_mst.attribute19
      , lr_ic_lots_mst.attribute20
      , lr_ic_lots_mst.attribute21
      , lr_ic_lots_mst.attribute22
      , lr_ic_lots_mst.attribute23
      , lr_ic_lots_mst.attribute24
      , lr_ic_lots_mst.attribute25
      , lr_ic_lots_mst.attribute26
      , lr_ic_lots_mst.attribute27
      , lr_ic_lots_mst.attribute28
      , lr_ic_lots_mst.attribute29
      , lr_ic_lots_mst.attribute30
      FROM
        ic_lots_mst   ilm -- OPMロットマスタ
      WHERE
            ilm.item_id = it_item_id   -- 品目ID
        AND ilm.lot_id  = it_lot_id    -- ロットID
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_errmsg  := 'OPMロットマスタを取得できません';
        RAISE api_expt;
--
      WHEN TOO_MANY_ROWS THEN
        ov_errmsg  := 'OPMロットマスタから複数フェッチされました。';
        RAISE api_expt;
--
    END;
--
    -- ===============================
    -- 値の設定
    -- ===============================
    IF ( it_attribute2 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute2 := it_attribute2;   -- 固有記号
    END IF;
    IF ( it_attribute13 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute13 := it_attribute13;   -- タイプ
    END IF;
    IF ( it_attribute14 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute14 := it_attribute14;   -- ランク1
    END IF;
    IF ( it_attribute15 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute15 := it_attribute15;   -- ランク2
    END IF;
    IF ( it_attribute16 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute16 := it_attribute16;   -- 伝票区分
    END IF;
    IF ( it_attribute17 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute17 := it_attribute17;   -- ラインNo
    END IF;
    IF ( it_attribute18 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute18 := it_attribute18;   -- 摘要
    END IF;
    IF ( it_attribute23 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute23 := it_attribute23;   -- ロットステータス
    END IF;
--
    -- ===============================
    -- OPMロットマスタDFF更新
    -- ===============================
    GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF(
      p_api_version                 =>  gn_api_version                -- IN         NUMBER
    , p_init_msg_list               =>  FND_API.G_FALSE               -- IN         VARCHAR2 DEFAULT FND_API.G_FALSE
    , p_commit                      =>  FND_API.G_FALSE               -- IN         VARCHAR2 DEFAULT FND_API.G_FALSE
    , p_validation_level            =>  FND_API.G_VALID_LEVEL_FULL    -- IN         NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL
    , x_return_status               =>  lv_retcode                    -- OUT NOCOPY VARCHAR2
    , x_msg_count                   =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_msg_data                    =>  lv_message_list               -- OUT NOCOPY VARCHAR2
    , p_lot_rec                     =>  lr_ic_lots_mst                -- IN  ic_lots_mst%ROWTYPE
    );
--
    -- 成功以外の場合、エラー
    IF ( lv_retcode <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_retcode || lv_message_list;
      ov_errmsg  := 'ロットマスタDFF更新関数エラー';
      RAISE api_expt;
--
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
  END update_lot_dff;
--
  /**********************************************************************************
   * Function Name    : update_line_allocation
   * Description      : 明細割当更新API呼出
   ***********************************************************************************/
  PROCEDURE update_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE -- バッチID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE -- 保留在庫TrID
  , it_trans_qty                    IN         ic_tran_pnd.trans_qty      %TYPE -- 指示総数
  , it_completed_ind                IN         ic_tran_pnd.completed_ind  %TYPE -- 完了フラグ
  , ov_errbuf                       OUT NOCOPY VARCHAR2                         -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                         -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                         -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'update_line_allocation';            --プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := '明細割当更新API呼出';
--
    lv_errbuf                       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                      VARCHAR2(1);     -- リターン・コード
    lv_errmsg                       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
    lv_return_status                VARCHAR2(100);
--
    lr_tran_row_in                  gme_inventory_txns_gtmp %ROWTYPE;
    lr_tran_row_out                 gme_inventory_txns_gtmp %ROWTYPE;
    lr_def_tran_row                 gme_inventory_txns_gtmp %ROWTYPE;
    lr_material_detail              gme_material_details    %ROWTYPE;
--
  BEGIN
    -- パラメータ設定
    lr_tran_row_in.trans_id      := it_trans_id;
    lr_tran_row_in.trans_qty     := it_trans_qty;
    lr_tran_row_in.completed_ind := it_completed_ind;
--
    -- API実行
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
      p_api_version                   =>  GME_API_PUB.API_VERSION       -- IN         NUMBER := GME_API_PUB.API_VERSION
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS        -- IN         NUMBER := GME_API_PUB.MAX_ERRORS
    , p_init_msg_list                 =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_tran_row                      =>  lr_tran_row_in                -- IN         gme_inventory_txns_gtmp%ROWTYPE
    , p_lot_no                        =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_sublot_no                     =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_create_lot                    =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , p_ignore_shortage               =>  TRUE                          -- IN         BOOLEAN DEFAULT FALSE
    , p_scale_phantom                 =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , x_material_detail               =>  lr_material_detail            -- OUT NOCOPY gme_material_details%ROWTYPE
    , x_tran_row                      =>  lr_tran_row_out               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
    , x_def_tran_row                  =>  lr_def_tran_row               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
    , x_message_count                 =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list               -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '明細割当更新に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END update_line_allocation;
--
  /**********************************************************************************
   * Function Name    : delete_line_allocation
   * Description      : 明細割当削除API呼出
   ***********************************************************************************/
  PROCEDURE delete_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE -- バッチID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE -- 保留在庫TrID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                         -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                         -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                         -- ユーザー・エラー・メッセージ
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'delete_line_allocation';   -- プログラム名
    cv_api_name                     CONSTANT VARCHAR2(100) := '明細割当削除API呼出';
--
    lv_errbuf                       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                      VARCHAR2(1);     -- リターン・コード
    lv_errmsg                       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
    lv_return_status                VARCHAR2(100);
--
    lr_material_detail              gme_material_details    %ROWTYPE;
    lr_def_tran_row                 gme_inventory_txns_gtmp %ROWTYPE;
--
  BEGIN
    -- API実行
    gme_api_pub.delete_line_allocation(
      p_api_version                   =>  GME_API_PUB.API_VERSION       -- IN         NUMBER  := GME_API_PUB.API_VERSION
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS        -- IN         NUMBER  := GME_API_PUB.MAX_ERRORS
    , p_init_msg_list                 =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_trans_id                      =>  it_trans_id                   -- IN         NUMBER
    , p_scale_phantom                 =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , x_material_detail               =>  lr_material_detail            -- OUT NOCOPY gme_material_details%ROWTYPE
    , x_def_tran_row                  =>  lr_def_tran_row               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
    , x_message_count                 =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list               -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_message_list;
      ov_errmsg  := '明細割当削除に失敗しました。';
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END delete_line_allocation;
--
END xxwip_common2_pkg;
/
