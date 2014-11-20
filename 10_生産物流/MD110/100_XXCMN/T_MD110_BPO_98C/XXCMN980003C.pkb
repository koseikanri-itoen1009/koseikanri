CREATE OR REPLACE PACKAGE BODY XXCMN980003C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980003C(body)
 * Description      : 生産バッチヘッダ(標準)バックアップ
 * MD.050           : T_MD050_BPO_98C_生産バッチヘッダ(標準)バックアップ
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
 *  2012/10/26   1.00  T.Makuta          新規作成
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
  --=============
  --メッセージ
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_archive_range
                     CONSTANT VARCHAR2(50) := 'XXCMN_ARCHIVE_RANGE';      --XXCMN:ﾊﾞｯｸｱｯﾌﾟﾚﾝｼﾞ
--
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
  cv_others_err_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11019';          --ﾊﾞｯｸｱｯﾌﾟ処理失敗
  cv_token_key       CONSTANT VARCHAR2(10) := 'KEY';                      --ﾊﾞｯｸｱｯﾌﾟ処理MSG用ﾄｰｸﾝ名
--
  --TBL_NAME SHORI 件数： CNT 件
  cv_end_msg         CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';          --処理内容出力
  cv_token_tblname   CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname_h       CONSTANT VARCHAR2(90) := '生産バッチヘッダ（標準）';
  cv_tblname_m       CONSTANT VARCHAR2(90) := '生産原料詳細（標準）';
  cv_tblname_s       CONSTANT VARCHAR2(90) := '生産バッチステップ（標準）';
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
  gn_error_cnt       NUMBER;                                     --エラー件数
  gn_arc_cnt_header  NUMBER;                                     --ﾊﾞｯｸｱｯﾌﾟ件数(生産ﾊﾞｯﾁﾍｯﾀﾞ)
  gn_arc_cnt_detail  NUMBER;                                     --ﾊﾞｯｸｱｯﾌﾟ件数(生産原料詳細)
  gn_arc_cnt_step    NUMBER;                                     --ﾊﾞｯｸｱｯﾌﾟ件数(生産ﾊﾞｯﾁｽﾃｯﾌﾟ)
  gt_batch_id        gme_batch_header.batch_id%TYPE;             --対象バッチID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN980003C'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE b_header_ttype IS TABLE OF xxcmn_gme_batch_header_arc%ROWTYPE     INDEX BY BINARY_INTEGER;
  TYPE m_detail_ttype IS TABLE OF xxcmn_gme_material_details_arc%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE b_step_ttype   IS TABLE OF xxcmn_gme_batch_steps_arc%ROWTYPE      INDEX BY BINARY_INTEGER;
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
    ln_arc_cnt_header_yet     NUMBER;                           --未ｺﾐｯﾄﾊﾞｯｸｱｯﾌﾟ件数(生産ﾊﾞｯﾁﾍｯﾀﾞ)
    ln_arc_cnt_detail_yet     NUMBER;                           --未ｺﾐｯﾄﾊﾞｯｸｱｯﾌﾟ件数(生産原料詳細)
    ln_arc_cnt_step_yet       NUMBER;                           --未ｺﾐｯﾄﾊﾞｯｸｱｯﾌﾟ件数(生産ﾊﾞｯﾁｽﾃｯﾌﾟ)
    lv_process_part           VARCHAR2(1000);                   -- 処理部
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    -- 生産バッチヘッダ
    CURSOR バックアップ対象生産バッチヘッダ取得
      id_基準日         IN DATE,
      in_バックアップレンジ IN NUMBER
    IS
      SELECT 生産バッチヘッダ.全カラム,
             バックアップ登録日,
             バックアップ要求ID,
             NULL,                  --パージ実行日
             NULL                   --パージ要求ID
      FROM   生産バッチヘッダ
      WHERE  生産バッチヘッダ.計画開始日 >= id_基準日  - in_バックアップレンジ
      AND    生産バッチヘッダ.計画開始日 <  id_基準日
      AND NOT EXISTS (
               SELECT  1
               FROM 生産バッチヘッダバックアップ
               WHERE 生産バッチヘッダバックアップ.バッチID = 生産バッチヘッダ.バッチID
               AND ROWNUM = 1
             );
    */
    CURSOR b_header_cur(
      id_standard_date      DATE
     ,in_archive_range      NUMBER
    )
    IS
      SELECT  /*+ INDEX(gbh GME_GBH_N01) */
              gbh.batch_id                AS  batch_id,                   --バッチID
              gbh.plant_code              AS  plant_code,                 --プラントコード
              gbh.batch_no                AS  batch_no,                   --バッチNO
              gbh.batch_type              AS  batch_type,                 --バッチタイプ
              gbh.prod_id                 AS  prod_id,
              gbh.prod_sequence           AS  prod_sequence,
              gbh.recipe_validity_rule_id AS  recipe_validity_rule_id,    --妥当性ルールID
              gbh.formula_id              AS  formula_id,                 --フォーミュラID
              gbh.routing_id              AS  routing_id,                 --工順ID
              gbh.plan_start_date         AS  plan_start_date,            --計画開始日
              gbh.actual_start_date       AS  actual_start_date,          --実績開始日
              gbh.due_date                AS  due_date,                   --必須完了日
              gbh.plan_cmplt_date         AS  plan_cmplt_date,            --計画完了日
              gbh.actual_cmplt_date       AS  actual_cmplt_date,          --実績完了日
              gbh.batch_status            AS  batch_status,               --バッチステータス
              gbh.priority_value          AS  priority_value,
              gbh.priority_code           AS  priority_code,
              gbh.print_count             AS  print_count,
              gbh.fmcontrol_class         AS  fmcontrol_class,
              gbh.wip_whse_code           AS  wip_whse_code,              --wip倉庫
              gbh.batch_close_date        AS  batch_close_date,           --クローズ日
              gbh.poc_ind                 AS  poc_ind,
              gbh.actual_cost_ind         AS  actual_cost_ind,
              gbh.update_inventory_ind    AS  update_inventory_ind,
              gbh.last_update_date        AS  last_update_date,           --最終更新日
              gbh.last_updated_by         AS  last_updated_by,            --最終更新者
              gbh.creation_date           AS  creation_date,              --作成日
              gbh.created_by              AS  created_by,                 --作成者
              gbh.last_update_login       AS  last_update_login,          --最終更新ログイン
              gbh.delete_mark             AS  delete_mark,                --削除マーク
              gbh.text_code               AS  text_code,
              gbh.parentline_id           AS  parentline_id,
              gbh.fpo_id                  AS  fpo_id, 
              gbh.attribute1              AS  attribute1,                 --伝票区分
              gbh.attribute2              AS  attribute2,                 --成績管理部署
              gbh.attribute3              AS  attribute3,                 --送信済フラグ
              gbh.attribute4              AS  attribute4,                 --業務ステータス
              gbh.attribute5              AS  attribute5,                 --旧伝票番号
              gbh.attribute6              AS  attribute6,                 --品目振替摘要
              gbh.attribute7              AS  attribute7,
              gbh.attribute8              AS  attribute8,
              gbh.attribute9              AS  attribute9,
              gbh.attribute10             AS  attribute10,
              gbh.attribute11             AS  attribute11,
              gbh.attribute12             AS  attribute12,
              gbh.attribute13             AS  attribute13,
              gbh.attribute14             AS  attribute14,
              gbh.attribute15             AS  attribute15,
              gbh.attribute16             AS  attribute16,
              gbh.attribute17             AS  attribute17,
              gbh.attribute18             AS  attribute18,
              gbh.attribute19             AS  attribute19,
              gbh.attribute20             AS  attribute20,
              gbh.attribute21             AS  attribute21,
              gbh.attribute22             AS  attribute22,
              gbh.attribute23             AS  attribute23,
              gbh.attribute24             AS  attribute24,
              gbh.attribute25             AS  attribute25,
              gbh.attribute26             AS  attribute26,
              gbh.attribute27             AS  attribute27,
              gbh.attribute28             AS  attribute28,
              gbh.attribute29             AS  attribute29,
              gbh.attribute30             AS  attribute30,
              gbh.attribute_category      AS  attribute_category,
              gbh.automatic_step_calculation  
                                          AS  automatic_step_calculation,
              gbh.gl_posted_ind           AS  gl_posted_ind,
              gbh.firmed_ind              AS  firmed_ind,
              gbh.finite_scheduled_ind    AS  finite_scheduled_ind,
              gbh.order_priority          AS  order_priority,
              gbh.attribute31             AS  attribute31,
              gbh.attribute32             AS  attribute32,
              gbh.attribute33             AS  attribute33,
              gbh.attribute34             AS  attribute34,
              gbh.attribute35             AS  attribute35,
              gbh.attribute36             AS  attribute36,
              gbh.attribute37             AS  attribute37,
              gbh.attribute38             AS  attribute38,
              gbh.attribute39             AS  attribute39,
              gbh.attribute40             AS  attribute40,
              gbh.migrated_batch_ind      AS  migrated_batch_ind,
              gbh.enforce_step_dependency AS  enforce_step_dependency,
              gbh.terminated_ind          AS  terminated_ind,
              SYSDATE                     AS  archive_date,               --バックアップ登録日
              cn_request_id               AS  archive_request_id,         --バックアップ要求ID
              NULL                        AS  purge_date,                 --パージ実行日
              NULL                        AS  purge_request_id            --パージ要求ID
      FROM    gme_batch_header            gbh                             --生産ﾊﾞｯﾁﾍｯﾀﾞ
      WHERE   gbh.plan_start_date     >=  id_standard_date - in_archive_range
      AND     gbh.plan_start_date     <   id_standard_date
      AND NOT EXISTS(SELECT 1
                     FROM  xxcmn_gme_batch_header_arc xgbh                --生産ﾊﾞｯﾁﾍｯﾀﾞﾊﾞｯｸｱｯﾌﾟ
                     WHERE xgbh.batch_id = gbh.batch_id
                     AND   ROWNUM        = 1
                    );
--
    /*
    -- 生産原料詳細
    CURSOR バックアップ対象生産原料詳細取得
       in_バッチID  IN 生産バッチヘッダ.バッチID%TYPE
    IS
      SELECT 生産原料詳細.全カラム,
             バックアップ登録日,
             バックアップ要求ID,
             NULL,                  --パージ実行日
             NULL                   --パージ要求ID
      FROM   生産原料詳細
      WHERE  生産原料詳細.バッチID          =  in_バッチID
      AND NOT EXISTS (
               SELECT  1
               FROM  生産原料詳細バックアップ
               WHERE 生産原料詳細バックアップ.生産原料詳細ID = 生産原料詳細.生産原料詳細ID
               AND ROWNUM = 1
             )
    ;
*/
    CURSOR m_detail_cur(
     it_batch_id gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              gmd.material_detail_id      AS  material_detail_id,         --生産原料詳ID
              gmd.batch_id                AS  batch_id,                   --バッチID
              gmd.formulaline_id          AS  formulaline_id,             --フォーミュラ明細ID
              gmd.line_no                 AS  line_no,                    --行No
              gmd.item_id                 AS  item_id,                    --品目ID
              gmd.line_type               AS  line_type,                  --ラインタイプ
              gmd.plan_qty                AS  plan_qty,                   --計画数量
              gmd.item_um                 AS  item_um,                    --品目単位
              gmd.item_um2                AS  item_um2,
              gmd.actual_qty              AS  actual_qty,                 --実績数
              gmd.release_type            AS  release_type,
              gmd.scrap_factor            AS  scrap_factor,
              gmd.scale_type              AS  scale_type,
              gmd.phantom_type            AS  phantom_type,
              gmd.cost_alloc              AS  cost_alloc,                 --原価割当
              gmd.alloc_ind               AS  alloc_ind,                  --割当済フラグ
              gmd.cost                    AS  cost, 
              gmd.text_code               AS  text_code,
              gmd.phantom_id              AS  phantom_id,
              gmd.rounding_direction      AS  rounding_direction,
              gmd.creation_date           AS  creation_date,              --作成日
              gmd.created_by              AS  created_by,                 --作成者
              gmd.last_update_date        AS  last_update_date,           --最終更新日
              gmd.last_updated_by         AS  last_updated_by,            --最終更新者
              gmd.attribute1              AS  attribute1,                 --タイプ
              gmd.attribute2              AS  attribute2,                 --ランク1
              gmd.attribute3              AS  attribute3,                 --ランク2
              gmd.attribute4              AS  attribute4,                 --摘要
              gmd.attribute5              AS  attribute5,                 --打込区分
              gmd.attribute6              AS  attribute6,                 --在庫入数
              gmd.attribute7              AS  attribute7,                 --依頼総額
              gmd.attribute8              AS  attribute8,                 --投入口
              gmd.attribute9              AS  attribute9,                 --委託加工単価
              gmd.attribute10             AS  attribute10,                --賞味期限日
              gmd.attribute11             AS  attribute11,                --生産日
              gmd.attribute12             AS  attribute12,                --移動場所コード
              gmd.attribute13             AS  attribute13,                --出倉庫コード
              gmd.attribute14             AS  attribute14,                --委託計算区分
              gmd.attribute15             AS  attribute15,                --委託加工費
              gmd.attribute16             AS  attribute16,                --その他金額
              gmd.attribute17             AS  attribute17,                --製造日
              gmd.attribute18             AS  attribute18,                --出倉庫コード2
              gmd.attribute19             AS  attribute19,                --出倉庫コード3
              gmd.attribute20             AS  attribute20,                --出倉庫コード4
              gmd.attribute21             AS  attribute21,                --出倉庫コード5
              gmd.attribute22             AS  attribute22,                --原料入庫予定日
              gmd.attribute23             AS  attribute23,                --指図総数
              gmd.attribute24             AS  attribute24,                --原料削除フラグ
              gmd.attribute25             AS  attribute25,
              gmd.attribute26             AS  attribute26,
              gmd.attribute27             AS  attribute27,
              gmd.attribute28             AS  attribute28,
              gmd.attribute29             AS  attribute29,
              gmd.attribute30             AS  attribute30,
              gmd.attribute_category      AS  attribute_category,
              gmd.last_update_login       AS  last_update_login,
              gmd.scale_rounding_variance AS  scale_rounding_variance,
              gmd.scale_multiple          AS  scale_multiple,
              gmd.contribute_yield_ind    AS  contribute_yield_ind,
              gmd.contribute_step_qty_ind AS  contribute_step_qty_ind,
              gmd.wip_plan_qty            AS  wip_plan_qty,               --WIP計画数量
              gmd.original_qty            AS  original_qty,               --オリジナル数量
              gmd.by_product_type         AS  by_product_type,
              SYSDATE                     AS  archive_date,               --バックアップ登録日
              cn_request_id               AS  archive_request_id,         --バックアップ要求ID
              NULL                        AS  purge_date,                 --パージ実行日
              NULL                        AS  purge_request_id            --パージ要求ID
      FROM    gme_material_details        gmd                             --生産原料詳細
      WHERE   gmd.batch_id            =   it_batch_id
      AND NOT EXISTS (SELECT 1
                       FROM  xxcmn_gme_material_details_arc xgmd          --生産原料詳細ﾊﾞｯｸｱｯﾌﾟ 
                       WHERE xgmd.material_detail_id = gmd.material_detail_id
                       AND   ROWNUM                  = 1
                      );
--
   /*
    -- 生産バッチヘッダステップ
    CURSOR バックアップ対象生産バッチヘッダステップ取得
       in_バッチID  IN 生産バッチヘッダ.バッチID%TYPE
    IS
      SELECT 生産バッチヘッダステップ.全カラム,
             バックアップ登録日,
             バックアップ要求ID,
             NULL,                  --パージ実行日
             NULL                   --パージ要求ID
      FROM   生産バッチヘッダステップ
      WHERE  生産バッチヘッダステップ.バッチID    =  in_バッチID
      AND NOT EXISTS(
               SELECT  1
               FROM 生産バッチステップバックアップ
               WHERE 生産バッチステップバックアップ.バッチステップID = 
                                                     生産バッチステップ.バッチステップID
               AND ROWNUM = 1
             );
    */
    CURSOR b_step_cur(
      it_batch_id gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(gbs GME_BATCH_STEPS_U1) */
              gbs.batch_id                AS  batch_id,                   --バッチID
              gbs.batchstep_id            AS  batchstep_id,               --バッチステップID
              gbs.routingstep_id          AS  routingstep_id,             --工順ステップID
              gbs.batchstep_no            AS  batchstep_no,               --バッチステップNo
              gbs.oprn_id                 AS  oprn_id,                    --工程ID
              gbs.plan_step_qty           AS  plan_step_qty,
              gbs.actual_step_qty         AS  actual_step_qty,
              gbs.step_qty_uom            AS  step_qty_uom,
              gbs.backflush_qty           AS  backflush_qty,
              gbs.plan_start_date         AS  plan_start_date,
              gbs.actual_start_date       AS  actual_start_date,
              gbs.due_date                AS  due_date,
              gbs.plan_cmplt_date         AS  plan_cmplt_date,
              gbs.actual_cmplt_date       AS  actual_cmplt_date,
              gbs.step_close_date         AS  step_close_date,
              gbs.step_status             AS  step_status,
              gbs.priority_code           AS  priority_code,
              gbs.priority_value          AS  priority_value,
              gbs.delete_mark             AS  delete_mark,
              gbs.steprelease_type        AS  steprelease_type,
              gbs.max_step_capacity       AS  max_step_capacity,
              gbs.max_step_capacity_uom   AS  max_step_capacity_uom,
              gbs.plan_charges            AS  plan_charges,
              gbs.actual_charges          AS  actual_charges,
              gbs.mass_ref_uom            AS  mass_ref_uom,
              gbs.plan_mass_qty           AS  plan_mass_qty,
              gbs.volume_ref_uom          AS  volume_ref_uom,
              gbs.plan_volume_qty         AS  plan_volume_qty,
              gbs.text_code               AS  text_code,
              gbs.actual_mass_qty         AS  actual_mass_qty,
              gbs.actual_volume_qty       AS  actual_volume_qty,
              gbs.last_update_date        AS  last_update_date,           --最終更新日
              gbs.creation_date           AS  creation_date,              --作成日
              gbs.created_by              AS  created_by,                 --作成者
              gbs.last_updated_by         AS  last_updated_by,            --最終更新日
              gbs.last_update_login       AS  last_update_login,          --最終更新ログイン
              gbs.attribute_category      AS  attribute_category,
              gbs.attribute1              AS  attribute1,
              gbs.attribute2              AS  attribute2,
              gbs.attribute3              AS  attribute3,
              gbs.attribute4              AS  attribute4,
              gbs.attribute5              AS  attribute5,
              gbs.attribute6              AS  attribute6,
              gbs.attribute7              AS  attribute7,
              gbs.attribute8              AS  attribute8,
              gbs.attribute9              AS  attribute9,
              gbs.attribute10             AS  attribute10,
              gbs.attribute11             AS  attribute11,
              gbs.attribute12             AS  attribute12,
              gbs.attribute13             AS  attribute13,
              gbs.attribute14             AS  attribute14,
              gbs.attribute15             AS  attribute15,
              gbs.attribute16             AS  attribute16,
              gbs.attribute17             AS  attribute17,
              gbs.attribute18             AS  attribute18,
              gbs.attribute19             AS  attribute19,
              gbs.attribute20             AS  attribute20,
              gbs.attribute21             AS  attribute21,
              gbs.attribute22             AS  attribute22,
              gbs.attribute23             AS  attribute23,
              gbs.attribute24             AS  attribute24,
              gbs.attribute25             AS  attribute25,
              gbs.attribute26             AS  attribute26,
              gbs.attribute27             AS  attribute27,
              gbs.attribute28             AS  attribute28,
              gbs.attribute29             AS  attribute29,
              gbs.attribute30             AS  attribute30,
              gbs.quality_status          AS  quality_status,
              gbs.minimum_transfer_qty    AS  minimum_transfer_qty,
              gbs.terminated_ind          AS  terminated_ind,
              SYSDATE                     AS  archive_date,               --バックアップ登録日
              cn_request_id               AS  archive_request_id,         --バックアップ要求ID
              NULL                        AS  purge_date,                 --パージ実行日
              NULL                        AS  purge_request_id            --パージ要求ID
      FROM    gme_batch_steps             gbs                             --生産ﾊﾞｯﾁｽﾃｯﾌﾟ
      WHERE   gbs.batch_id      =         it_batch_id
      AND NOT EXISTS(SELECT 1
                     FROM   xxcmn_gme_batch_steps_arc  xgbs               --生産ﾊﾞｯﾁｽﾃｯﾌﾟﾊﾞｯｸｱｯﾌﾟ
                     WHERE  xgbs.batchstep_id = gbs.batchstep_id
                     AND    ROWNUM            = 1
                    );
--
    -- <カーソル名>レコード型
    lt_b_header_tbl      b_header_ttype;                         --生産バッチヘッダテーブル
    lt_m_detail_tbl      m_detail_ttype;                         --生産原料詳細テーブル
    lt_b_step_tbl        b_step_ttype;                           --生産バッチヘッダステップテーブル
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数の初期化
    gn_error_cnt          := 0;
    gn_arc_cnt_header     := 0;
    gn_arc_cnt_detail     := 0;
    gn_arc_cnt_step       := 0;
    ln_arc_cnt_header_yet := 0;
    ln_arc_cnt_detail_yet := 0;
    ln_arc_cnt_step_yet   := 0;
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
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_archive_range || '）：';
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
    FOR lr_b_header_rec IN バックアップ対象生産バッチヘッダ取得
                                                       (ld_基準日,ln_バックアップレンジ) LOOP
   */
    << b_header_loop >>
    FOR lr_b_header_rec IN b_header_cur(ld_standard_date
                                       ,ln_archive_range ) LOOP
--
      /*
      gt_対象生産バッチヘッダバッチID := lr_b_header_rec.バッチID;
      */
      gt_batch_id                     := lr_b_header_rec.batch_id;
--
      -- ===============================================
      -- 分割コミット(生産バッチヘッダ)
      -- ===============================================
      /*
      NVL(ln_分割コミット数, 0) <> 0の場合
       */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
        /* ln_未コミットバックアップ件数(生産バッチヘッダ) > 0 かつ 
           MOD(ln_未コミットバックアップ件数(生産バッチヘッダ), ln_分割コミット数) = 0の場合
        */
        IF (  (ln_arc_cnt_header_yet > 0)
          AND (MOD(ln_arc_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx1 IN 1..ln_未コミットバックアップ件数(生産バッチヘッダ)
            INSERT INTO 生産バッチヘッダバックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                lt_生産バッチヘッダテーブル(ln_idx1)全カラム
              , SYSDATE
              , 要求ID
            )
          */
          FORALL ln_idx1 IN 1..ln_arc_cnt_header_yet
            INSERT INTO xxcmn_gme_batch_header_arc VALUES lt_b_header_tbl(ln_idx1);
--
          -- ===============================================
          -- 分割登録(生産原料詳細)
          -- ===============================================
          /*
          FORALL ln_idx2 IN 1..ln_未コミットバックアップ件数(生産原料詳細)
            INSERT INTO 生産原料詳細バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                生産原料詳細テーブル(ln_idx2)全カラム
              , SYSDATE
              , 要求ID
            )
          */
          FORALL ln_idx2 IN 1..ln_arc_cnt_detail_yet
            INSERT INTO xxcmn_gme_material_details_arc VALUES lt_m_detail_tbl(ln_idx2);
--
          -- ===============================================
          -- 分割登録(生産バッチステップ)
          -- ===============================================
          /*
          FORALL ln_idx3 IN 1..ln_未コミットバックアップ件数(生産バッチステップ)
            INSERT INTO 生産バッチステップバックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                生産バッチステップテーブル(ln_idx3)全カラム
              , SYSDATE
              , 要求ID
            )
            */
          FORALL ln_idx3 IN 1..ln_arc_cnt_step_yet
            INSERT INTO xxcmn_gme_batch_steps_arc VALUES lt_b_step_tbl(ln_idx3);
--
          /*
          gn_バックアップ件数(生産バッチヘッダ) := gn_バックアップ件数(生産バッチヘッダ) + 
                                                ln_未コミットバックアップ件数(生産バッチヘッダ);
          ln_未コミットバックアップ件数(生産バッチヘッダ) := 0;
          lt_生産バッチヘッダテーブル.DELETE;
          */
--
          gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
          ln_arc_cnt_header_yet := 0;
          lt_b_header_tbl.DELETE;
          /*
          gn_バックアップ件数(生産原料詳細) := gn_バックアップ件数(生産原料詳細) + 
                                               ln_未コミットバックアップ件数(生産原料詳細);
          ln_未コミットバックアップ件数(生産原料詳細) := 0;
          lt_生産原料詳細テーブル.DELETE;
          */
          gn_arc_cnt_detail     := gn_arc_cnt_detail + ln_arc_cnt_detail_yet;
          ln_arc_cnt_detail_yet := 0;
          lt_m_detail_tbl.DELETE;
--
          /*
          gn_バックアップ件数(生産バッチステップ) := gn_バックアップ件数(生産バッチステップ) + 
                                               ln_未コミットバックアップ件数(生産バッチステップ);
          ln_未コミットバックアップ件数(生産バッチステップ) := 0;
          lt_生産バッチステップテーブル.DELETE;
          COMMIT;
          */
          gn_arc_cnt_step       := gn_arc_cnt_step + ln_arc_cnt_step_yet;
          lt_b_step_tbl.DELETE;
          ln_arc_cnt_step_yet := 0;
--
          COMMIT;
--
        END IF;
--
      END IF;
--
      -- ===============================================
      -- 生産原料詳細 データ抽出
      -- ===============================================
      /*
      FOR lr_m_detail_rec IN バックアップ対象生産原料詳細取得(lr_b_header_rec.バッチID) LOOP
      */
--
      << m_detail_loop >>
      FOR lr_m_detail_rec IN m_detail_cur(lr_b_header_rec.batch_id) LOOP
--
        /*
        ln_未コミットバックアップ件数(生産原料詳細) := 
                                                   ln_未コミットバックアップ件数(生産原料詳細) + 1;
        */
        ln_arc_cnt_detail_yet := ln_arc_cnt_detail_yet + 1;
--
        /*
        lt_生産原料詳細テーブル(ln_未コミットバックアップ件数(生産原料詳細) 
                                                    := lr_m_detail_rec;
        */
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).material_detail_id  := 
                                                               lr_m_detail_rec.material_detail_id;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).batch_id        := lr_m_detail_rec.batch_id;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).formulaline_id  := lr_m_detail_rec.formulaline_id;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).line_no         := lr_m_detail_rec.line_no;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).item_id         := lr_m_detail_rec.item_id;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).line_type       := lr_m_detail_rec.line_type;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).plan_qty        := lr_m_detail_rec.plan_qty;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).item_um         := lr_m_detail_rec.item_um;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).item_um2        := lr_m_detail_rec.item_um2;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).actual_qty      := lr_m_detail_rec.actual_qty;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).release_type    := lr_m_detail_rec.release_type;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).scrap_factor    := lr_m_detail_rec.scrap_factor;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).scale_type      := lr_m_detail_rec.scale_type;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).phantom_type    := lr_m_detail_rec.phantom_type;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).cost_alloc      := lr_m_detail_rec.cost_alloc;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).alloc_ind       := lr_m_detail_rec.alloc_ind;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).cost            := lr_m_detail_rec.cost;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).text_code       := lr_m_detail_rec.text_code;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).phantom_id      := lr_m_detail_rec.phantom_id;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).rounding_direction  := 
                                                               lr_m_detail_rec.rounding_direction;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).creation_date   := lr_m_detail_rec.creation_date;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).created_by      := lr_m_detail_rec.created_by;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).last_update_date    := 
                                                               lr_m_detail_rec.last_update_date;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).last_updated_by := lr_m_detail_rec.last_updated_by;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute1      := lr_m_detail_rec.attribute1;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute2      := lr_m_detail_rec.attribute2;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute3      := lr_m_detail_rec.attribute3;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute4      := lr_m_detail_rec.attribute4;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute5      := lr_m_detail_rec.attribute5;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute6      := lr_m_detail_rec.attribute6;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute7      := lr_m_detail_rec.attribute7;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute8      := lr_m_detail_rec.attribute8;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute9      := lr_m_detail_rec.attribute9;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute10     := lr_m_detail_rec.attribute10;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute11     := lr_m_detail_rec.attribute11;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute12     := lr_m_detail_rec.attribute12;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute13     := lr_m_detail_rec.attribute13;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute14     := lr_m_detail_rec.attribute14;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute15     := lr_m_detail_rec.attribute15;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute16     := lr_m_detail_rec.attribute16;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute17     := lr_m_detail_rec.attribute17;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute18     := lr_m_detail_rec.attribute18;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute19     := lr_m_detail_rec.attribute19;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute20     := lr_m_detail_rec.attribute20;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute21     := lr_m_detail_rec.attribute21;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute22     := lr_m_detail_rec.attribute22;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute23     := lr_m_detail_rec.attribute23;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute24     := lr_m_detail_rec.attribute24;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute25     := lr_m_detail_rec.attribute25;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute26     := lr_m_detail_rec.attribute26;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute27     := lr_m_detail_rec.attribute27;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute28     := lr_m_detail_rec.attribute28;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute29     := lr_m_detail_rec.attribute29;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute30     := lr_m_detail_rec.attribute30;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).attribute_category       := 
                                                           lr_m_detail_rec.attribute_category;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).last_update_login  
                                                              := lr_m_detail_rec.last_update_login;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).scale_rounding_variance  := 
                                                           lr_m_detail_rec.scale_rounding_variance;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).scale_multiple := lr_m_detail_rec.scale_multiple;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).contribute_yield_ind     := 
                                                           lr_m_detail_rec.contribute_yield_ind;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).contribute_step_qty_ind  :=
                                                           lr_m_detail_rec.contribute_step_qty_ind;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).wip_plan_qty    := lr_m_detail_rec.wip_plan_qty;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).original_qty    := lr_m_detail_rec.original_qty;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).by_product_type := lr_m_detail_rec.by_product_type;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).archive_date    := lr_m_detail_rec.archive_date;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).archive_request_id   := 
                                                        lr_m_detail_rec.archive_request_id;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).purge_date      := lr_m_detail_rec.purge_date;
        lt_m_detail_tbl(ln_arc_cnt_detail_yet).purge_request_id:= lr_m_detail_rec.purge_request_id;
--
      END LOOP m_detail_loop;
--
      -- ===============================================
      -- 生産バッチステップ データ抽出
      -- ===============================================
      /*
      FOR lr_b_step_rec IN バックアップ対象生産バッチステップ取得(lr_b_header_rec.バッチID)LOOP
      */
--
      << b_step_loop >>
      FOR lr_b_step_rec IN b_step_cur(lr_b_header_rec.batch_id)   LOOP
--
        /*
        ln_未コミットバックアップ件数(生産バッチステップ) := 
                                          ln_未コミットバックアップ件数(生産バッチステップ) + 1;
        */
        ln_arc_cnt_step_yet   := ln_arc_cnt_step_yet + 1;
--
        /*
        lt_生産バッチステップテーブル(ln_未コミットバックアップ件数(生産バッチステップ) 
                                                          := lr_b_step_rec;
        */
        lt_b_step_tbl(ln_arc_cnt_step_yet).batch_id           := lr_b_step_rec.batch_id;
        lt_b_step_tbl(ln_arc_cnt_step_yet).batchstep_id       := lr_b_step_rec.batchstep_id;
        lt_b_step_tbl(ln_arc_cnt_step_yet).routingstep_id     := lr_b_step_rec.routingstep_id;
        lt_b_step_tbl(ln_arc_cnt_step_yet).batchstep_no       := lr_b_step_rec.batchstep_no;
        lt_b_step_tbl(ln_arc_cnt_step_yet).oprn_id            := lr_b_step_rec.oprn_id;
        lt_b_step_tbl(ln_arc_cnt_step_yet).plan_step_qty      := lr_b_step_rec.plan_step_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).actual_step_qty    := lr_b_step_rec.actual_step_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).step_qty_uom       := lr_b_step_rec.step_qty_uom;
        lt_b_step_tbl(ln_arc_cnt_step_yet).backflush_qty      := lr_b_step_rec.backflush_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).plan_start_date    := lr_b_step_rec.plan_start_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).actual_start_date  := lr_b_step_rec.actual_start_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).due_date           := lr_b_step_rec.due_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).plan_cmplt_date    := lr_b_step_rec.plan_cmplt_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).actual_cmplt_date  := lr_b_step_rec.actual_cmplt_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).step_close_date    := lr_b_step_rec.step_close_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).step_status        := lr_b_step_rec.step_status;
        lt_b_step_tbl(ln_arc_cnt_step_yet).priority_code      := lr_b_step_rec.priority_code;
        lt_b_step_tbl(ln_arc_cnt_step_yet).priority_value     := lr_b_step_rec.priority_value;
        lt_b_step_tbl(ln_arc_cnt_step_yet).delete_mark        := lr_b_step_rec.delete_mark;
        lt_b_step_tbl(ln_arc_cnt_step_yet).steprelease_type   := lr_b_step_rec.steprelease_type;
        lt_b_step_tbl(ln_arc_cnt_step_yet).max_step_capacity  := lr_b_step_rec.max_step_capacity;
        lt_b_step_tbl(ln_arc_cnt_step_yet).max_step_capacity_uom := 
                                                               lr_b_step_rec.max_step_capacity_uom;
        lt_b_step_tbl(ln_arc_cnt_step_yet).plan_charges       := lr_b_step_rec.plan_charges;
        lt_b_step_tbl(ln_arc_cnt_step_yet).actual_charges     := lr_b_step_rec.actual_charges;
        lt_b_step_tbl(ln_arc_cnt_step_yet).mass_ref_uom       := lr_b_step_rec.mass_ref_uom;
        lt_b_step_tbl(ln_arc_cnt_step_yet).plan_mass_qty      := lr_b_step_rec.plan_mass_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).volume_ref_uom     := lr_b_step_rec.volume_ref_uom;
        lt_b_step_tbl(ln_arc_cnt_step_yet).plan_volume_qty    := lr_b_step_rec.plan_volume_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).text_code          := lr_b_step_rec.text_code;
        lt_b_step_tbl(ln_arc_cnt_step_yet).actual_mass_qty    := lr_b_step_rec.actual_mass_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).actual_volume_qty  := lr_b_step_rec.actual_volume_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).last_update_date   := lr_b_step_rec.last_update_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).creation_date      := lr_b_step_rec.creation_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).created_by         := lr_b_step_rec.created_by;
        lt_b_step_tbl(ln_arc_cnt_step_yet).last_updated_by    := lr_b_step_rec.last_updated_by;
        lt_b_step_tbl(ln_arc_cnt_step_yet).last_update_login  := lr_b_step_rec.last_update_login;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute_category := lr_b_step_rec.attribute_category;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute1         := lr_b_step_rec.attribute1;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute2         := lr_b_step_rec.attribute2;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute3         := lr_b_step_rec.attribute3;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute4         := lr_b_step_rec.attribute4;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute5         := lr_b_step_rec.attribute5;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute6         := lr_b_step_rec.attribute6;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute7         := lr_b_step_rec.attribute7;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute8         := lr_b_step_rec.attribute8;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute9         := lr_b_step_rec.attribute9;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute10        := lr_b_step_rec.attribute10;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute11        := lr_b_step_rec.attribute11;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute12        := lr_b_step_rec.attribute12;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute13        := lr_b_step_rec.attribute13;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute14        := lr_b_step_rec.attribute14;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute15        := lr_b_step_rec.attribute15;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute16        := lr_b_step_rec.attribute16;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute17        := lr_b_step_rec.attribute17;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute18        := lr_b_step_rec.attribute18;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute19        := lr_b_step_rec.attribute19;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute20        := lr_b_step_rec.attribute20;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute21        := lr_b_step_rec.attribute21;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute22        := lr_b_step_rec.attribute22;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute23        := lr_b_step_rec.attribute23;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute24        := lr_b_step_rec.attribute24;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute25        := lr_b_step_rec.attribute25;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute26        := lr_b_step_rec.attribute26;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute27        := lr_b_step_rec.attribute27;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute28        := lr_b_step_rec.attribute28;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute29        := lr_b_step_rec.attribute29;
        lt_b_step_tbl(ln_arc_cnt_step_yet).attribute30        := lr_b_step_rec.attribute30;
        lt_b_step_tbl(ln_arc_cnt_step_yet).quality_status     := lr_b_step_rec.quality_status;
        lt_b_step_tbl(ln_arc_cnt_step_yet).minimum_transfer_qty := 
                                                              lr_b_step_rec.minimum_transfer_qty;
        lt_b_step_tbl(ln_arc_cnt_step_yet).terminated_ind     := lr_b_step_rec.terminated_ind;
        lt_b_step_tbl(ln_arc_cnt_step_yet).archive_date       := lr_b_step_rec.archive_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).archive_request_id   := 
                                                              lr_b_step_rec.archive_request_id;
        lt_b_step_tbl(ln_arc_cnt_step_yet).purge_date         := lr_b_step_rec.purge_date;
        lt_b_step_tbl(ln_arc_cnt_step_yet).purge_request_id   := lr_b_step_rec.purge_request_id;
--
      END LOOP b_step_loop;
--
      -- ===============================================
      -- 生産バッチヘッダ データ抽出
      -- ===============================================
      /*
      ln_未コミットバックアップ件数(生産バッチヘッダ) := 
                                           ln_未コミットバックアップ件数(生産バッチヘッダ) + 1;
      */
      ln_arc_cnt_header_yet := ln_arc_cnt_header_yet + 1;
--
      /*
      lt_生産バッチヘッダテーブル(ln_未コミットバックアップ件数(生産バッチヘッダ) 
                                                      := lr_b_header_rec;
      */
      lt_b_header_tbl(ln_arc_cnt_header_yet).batch_id         := lr_b_header_rec.batch_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).plant_code       := lr_b_header_rec.plant_code;
      lt_b_header_tbl(ln_arc_cnt_header_yet).batch_no         := lr_b_header_rec.batch_no;
      lt_b_header_tbl(ln_arc_cnt_header_yet).batch_type       := lr_b_header_rec.batch_type;
      lt_b_header_tbl(ln_arc_cnt_header_yet).prod_id          := lr_b_header_rec.prod_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).prod_sequence    := lr_b_header_rec.prod_sequence;
      lt_b_header_tbl(ln_arc_cnt_header_yet).recipe_validity_rule_id    := 
                                                        lr_b_header_rec.recipe_validity_rule_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).formula_id       := lr_b_header_rec.formula_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).routing_id       := lr_b_header_rec.routing_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).plan_start_date  := lr_b_header_rec.plan_start_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).actual_start_date          := 
                                                        lr_b_header_rec.actual_start_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).due_date         := lr_b_header_rec.due_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).plan_cmplt_date  := lr_b_header_rec.plan_cmplt_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).actual_cmplt_date          := 
                                                        lr_b_header_rec.actual_cmplt_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).batch_status     := lr_b_header_rec.batch_status;
      lt_b_header_tbl(ln_arc_cnt_header_yet).priority_value   := lr_b_header_rec.priority_value;
      lt_b_header_tbl(ln_arc_cnt_header_yet).priority_code    := lr_b_header_rec.priority_code;
      lt_b_header_tbl(ln_arc_cnt_header_yet).print_count      := lr_b_header_rec.print_count;
      lt_b_header_tbl(ln_arc_cnt_header_yet).fmcontrol_class  := lr_b_header_rec.fmcontrol_class;
      lt_b_header_tbl(ln_arc_cnt_header_yet).wip_whse_code    := lr_b_header_rec.wip_whse_code;
      lt_b_header_tbl(ln_arc_cnt_header_yet).batch_close_date := lr_b_header_rec.batch_close_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).poc_ind          := lr_b_header_rec.poc_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).actual_cost_ind  := lr_b_header_rec.actual_cost_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).update_inventory_ind       := 
                                                        lr_b_header_rec.update_inventory_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).last_update_date := lr_b_header_rec.last_update_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).last_updated_by  := lr_b_header_rec.last_updated_by;
      lt_b_header_tbl(ln_arc_cnt_header_yet).creation_date    := lr_b_header_rec.creation_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).created_by       := lr_b_header_rec.created_by;
      lt_b_header_tbl(ln_arc_cnt_header_yet).last_update_login          := 
                                                        lr_b_header_rec.last_update_login;
      lt_b_header_tbl(ln_arc_cnt_header_yet).delete_mark      := lr_b_header_rec.delete_mark;
      lt_b_header_tbl(ln_arc_cnt_header_yet).text_code        := lr_b_header_rec.text_code;
      lt_b_header_tbl(ln_arc_cnt_header_yet).parentline_id    := lr_b_header_rec.parentline_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).fpo_id           := lr_b_header_rec.fpo_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute1       := lr_b_header_rec.attribute1;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute2       := lr_b_header_rec.attribute2;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute3       := lr_b_header_rec.attribute3;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute4       := lr_b_header_rec.attribute4;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute5       := lr_b_header_rec.attribute5;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute6       := lr_b_header_rec.attribute6;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute7       := lr_b_header_rec.attribute7;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute8       := lr_b_header_rec.attribute8;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute9       := lr_b_header_rec.attribute9;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute10      := lr_b_header_rec.attribute10;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute11      := lr_b_header_rec.attribute11;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute12      := lr_b_header_rec.attribute12;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute13      := lr_b_header_rec.attribute13;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute14      := lr_b_header_rec.attribute14;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute15      := lr_b_header_rec.attribute15;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute16      := lr_b_header_rec.attribute16;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute17      := lr_b_header_rec.attribute17;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute18      := lr_b_header_rec.attribute18;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute19      := lr_b_header_rec.attribute19;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute20      := lr_b_header_rec.attribute20;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute21      := lr_b_header_rec.attribute21;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute22      := lr_b_header_rec.attribute22;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute23      := lr_b_header_rec.attribute23;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute24      := lr_b_header_rec.attribute24;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute25      := lr_b_header_rec.attribute25;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute26      := lr_b_header_rec.attribute26;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute27      := lr_b_header_rec.attribute27;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute28      := lr_b_header_rec.attribute28;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute29      := lr_b_header_rec.attribute29;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute30      := lr_b_header_rec.attribute30;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute_category         :=
                                                        lr_b_header_rec.attribute_category;
      lt_b_header_tbl(ln_arc_cnt_header_yet).automatic_step_calculation := 
                                                        lr_b_header_rec.automatic_step_calculation;
      lt_b_header_tbl(ln_arc_cnt_header_yet).gl_posted_ind    := lr_b_header_rec.gl_posted_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).firmed_ind       := lr_b_header_rec.firmed_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).finite_scheduled_ind       := 
                                                        lr_b_header_rec.finite_scheduled_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).order_priority := lr_b_header_rec.order_priority;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute31      := lr_b_header_rec.attribute31;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute32      := lr_b_header_rec.attribute32;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute33      := lr_b_header_rec.attribute33;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute34      := lr_b_header_rec.attribute34;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute35      := lr_b_header_rec.attribute35;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute36      := lr_b_header_rec.attribute36;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute37      := lr_b_header_rec.attribute37;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute38      := lr_b_header_rec.attribute38;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute39      := lr_b_header_rec.attribute39;
      lt_b_header_tbl(ln_arc_cnt_header_yet).attribute40      := lr_b_header_rec.attribute40;
      lt_b_header_tbl(ln_arc_cnt_header_yet).migrated_batch_ind         := 
                                                        lr_b_header_rec.migrated_batch_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).enforce_step_dependency    := 
                                                        lr_b_header_rec.enforce_step_dependency;
      lt_b_header_tbl(ln_arc_cnt_header_yet).terminated_ind   := lr_b_header_rec.terminated_ind;
      lt_b_header_tbl(ln_arc_cnt_header_yet).archive_date     := lr_b_header_rec.archive_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).archive_request_id   := 
                                                        lr_b_header_rec.archive_request_id;
      lt_b_header_tbl(ln_arc_cnt_header_yet).purge_date       := lr_b_header_rec.purge_date;
      lt_b_header_tbl(ln_arc_cnt_header_yet).purge_request_id := lr_b_header_rec.purge_request_id;
--
    END LOOP b_header_loop;
--
--
    -- ---------------------------------------------------------
    -- 分割コミット対象外の残データ INSERT処理(生産バッチヘッダ)
    -- ---------------------------------------------------------
    /*
    FORALL ln_idx1 IN 1..ln_未コミットバックアップ件数(生産バッチヘッダ)
      INSERT INTO 生産バッチヘッダバックアップ
        (
          全カラム
        , バックアップ登録日
        , バックアップ要求ID
        )
        VALUES
        (
          生産バッチヘッダテーブル(ln_idx1)全カラム
        , SYSDATE
        , 要求ID
        )
        ;
    */
    FORALL ln_idx1 IN 1..ln_arc_cnt_header_yet
      INSERT INTO xxcmn_gme_batch_header_arc VALUES lt_b_header_tbl(ln_idx1);
--
    -- ---------------------------------------------------------
    -- 分割コミット対象外の残データ INSERT処理(生産原料詳細)
    -- ---------------------------------------------------------
    /*
    FORALL ln_idx2 IN 1..ln_未コミットバックアップ件数(生産原料詳細)
      INSERT INTO 生産原料詳細バックアップ
        (
           全カラム
         , バックアップ登録日
         , バックアップ要求ID
        )
        VALUES
        (
           lt_生産原料詳細テーブル(ln_idx2)全カラム
         , SYSDATE
         , 要求ID
        );
    */
    FORALL ln_idx2 IN 1..ln_arc_cnt_detail_yet
      INSERT INTO xxcmn_gme_material_details_arc VALUES lt_m_detail_tbl(ln_idx2);
--
    -- ---------------------------------------------------------
    -- 分割コミット対象外の残データ INSERT処理(生産バッチステップ)
    -- ---------------------------------------------------------
    /*
    FORALL ln_idx3 IN 1..ln_未コミットバックアップ件数(生産バッチステップ)
      INSERT INTO 生産バッチステップバックアップ
        (
           全カラム
         , バックアップ登録日
         , バックアップ要求ID
        )
        VALUES
        (
           lt_生産バッチステップテーブル(ln_idx3)全カラム
         , SYSDATE
         , 要求ID
        );
    */
--
    FORALL ln_idx3 IN 1..ln_arc_cnt_step_yet
      INSERT INTO xxcmn_gme_batch_steps_arc VALUES lt_b_step_tbl(ln_idx3);
--
    /*
    gn_バックアップ件数(生産バッチヘッダ) := gn_バックアップ件数(生産バッチヘッダ) + 
                                             ln_未コミットバックアップ件数(生産バッチヘッダ);
    ln_未コミットバックアップ件数(生産バッチヘッダ) := 0;
    lt_生産バッチヘッダテーブル.DELETE;
    */
--
    gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
    ln_arc_cnt_header_yet := 0;
    lt_b_header_tbl.DELETE;
--
    /*
    gn_バックアップ件数(生産原料詳細) := gn_バックアップ件数(生産原料詳細) + 
                                         ln_未コミットバックアップ件数(生産原料詳細);
    ln_未コミットバックアップ件数(生産原料詳細) := 0;
    lt_生産原料詳細テーブル.DELETE;
    */
--
    gn_arc_cnt_detail     := gn_arc_cnt_detail + ln_arc_cnt_detail_yet;
    ln_arc_cnt_detail_yet := 0;
    lt_m_detail_tbl.DELETE;
--
    /*
    gn_バックアップ件数(生産バッチステップ) := gn_バックアップ件数(生産バッチステップ) + 
                                               ln_未コミットバックアップ件数(生産バッチステップ);
    ln_未コミットバックアップ件数(生産バッチステップ) := 0;
    lt_生産バッチステップテーブル.DELETE;
    */
--
    gn_arc_cnt_step       := gn_arc_cnt_step + ln_arc_cnt_step_yet;
    ln_arc_cnt_step_yet   := 0;
    lt_b_step_tbl.DELETE;
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
          IF ( lt_b_header_tbl.COUNT > 0 ) THEN
--          
            BEGIN
              gt_batch_id := lt_b_header_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).batch_id;
              NULL;
--
            EXCEPTION
              WHEN OTHERS THEN
                BEGIN
                  gt_batch_id := lt_m_detail_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).batch_id;
                  NULL;
--
                EXCEPTION
                  WHEN OTHERS THEN
                    gt_batch_id := lt_b_step_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).batch_id;
                    NULL;
                END;
            END;
            --バックアップ処理に失敗しました。【生産バッチ（標準）】バッチID: KEY
            ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_batch_id)
                     );
--
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
        --バックアップ処理に失敗しました。【生産バッチ（標準）】バッチID: KEY
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_batch_id)
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
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
    --生産バッチヘッダ（標準） バックアップ 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname_h
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_arc_cnt_header)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --生産原料詳細（標準） バックアップ 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname_m
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_arc_cnt_detail)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --生産バッチステップ（標準） バックアップ 件数： CNT 件
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname_s
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_arc_cnt_step)
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
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_header)
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
END XXCMN980003C;
/
