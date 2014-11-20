CREATE OR REPLACE PACKAGE BODY xxinv520001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV520001C(body)
 * Description      : 品目振替
 * MD.050           : 品目振替 T_MD050_BPO_520
 * MD.070           : 品目振替 T_MD070_BPO_52A
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              初期処理を行うプロシージャ
 *  chk_param              パラメータチェックを行うプロシージャ(A-1)
 *  set_masters_rec        パラメータから導出されるデータのセットを行うプロシージャ
 *  chk_formula            フォーミュラ有無チェックを行うプロシージャ(A-2)
 *  ins_formula            フォーミュラ登録を行うプロシージャ(A-3)
 *  chk_recipe             レシピ有無チェックを行うプロシージャ(A-4)
 *  upd_recipe             レシピ更新を行うプロシージャ
 *  chk_lot                ロット有無チェックを行うプロシージャ(A-6)
 *  create_lot             ロット作成を行うプロシージャ(A-7)
 *  create_batch           バッチ作成を行うプロシージャ(A-8)
 *  input_lot_assign       入力ロット割当を行うプロシージャ(A-9)
 *  output_lot_assign      出力ロット割当を行うプロシージャ(A-11)
 *  cmpt_batch             バッチ完了を行うプロシージャ(A-12)
 *  close_batch            バッチクローズを行うプロシージャ(A-13)
 *  save_batch             バッチ保存を行うプロシージャ
 *  get_validity_rule_id   妥当性ルールIDを取得するプロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/11    1.0  Oracle 和田 大輝   初回作成
 *  2008/04/28    1.1  Oracle 河野 優子   内部変更対応#63
 *  2008/05/22    1.2  Oracle 熊本 和郎   結合テスト障害対応(ステータスチェック・更新処理追加)
 *  2008/05/22    1.3  Oracle 熊本 和郎   結合テスト障害対応(同一パラメータによる実行時のエラー)
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
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_ret_sts_success CONSTANT VARCHAR2(1)   := 'S';            -- 成功
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxinv520001c'; -- パッケージ名
  gv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_msg_kbn_inv     CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- メッセージ番号
  gv_msg_52a_02      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- プロファイル取得エラー
--
  gv_msg_52a_00      CONSTANT VARCHAR2(15) := 'APP-XXINV-10000'; -- APIエラー
  gv_msg_52a_03      CONSTANT VARCHAR2(15) := 'APP-XXINV-10003'; -- カレンダクローズメッセージ
  gv_msg_52a_11      CONSTANT VARCHAR2(15) := 'APP-XXINV-10011'; -- データ取得エラーメッセージ
  gv_msg_52a_15      CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- パラメータエラー
  gv_msg_52a_17      CONSTANT VARCHAR2(15) := 'APP-XXINV-10017'; -- パラメータ振替元ロットNoエラー
  gv_msg_52a_20      CONSTANT VARCHAR2(15) := 'APP-XXINV-10020'; -- パラメータ数量エラー
  gv_msg_52a_21      CONSTANT VARCHAR2(15) := 'APP-XXINV-10021'; -- パラメータ品目振替実績日エラー
  gv_msg_52a_71      CONSTANT VARCHAR2(15) := 'APP-XXINV-10071'; -- パラメータ摘要サイズエラー
--
  gv_msg_52a_45      CONSTANT VARCHAR2(15) := 'APP-XXINV-10145'; -- 品目振替_保管倉庫
  gv_msg_52a_46      CONSTANT VARCHAR2(15) := 'APP-XXINV-10146'; -- 品目振替_振替元品目
  gv_msg_52a_47      CONSTANT VARCHAR2(15) := 'APP-XXINV-10147'; -- 品目振替_振替元ロットNo
  gv_msg_52a_48      CONSTANT VARCHAR2(15) := 'APP-XXINV-10148'; -- 品目振替_振替先品目
  gv_msg_52a_49      CONSTANT VARCHAR2(15) := 'APP-XXINV-10149'; -- 品目振替_数量
  gv_msg_52a_50      CONSTANT VARCHAR2(15) := 'APP-XXINV-10150'; -- 品目振替_品目振替実績日
  gv_msg_52a_51      CONSTANT VARCHAR2(15) := 'APP-XXINV-10151'; -- 品目振替_摘要
  gv_msg_52a_57      CONSTANT VARCHAR2(15) := 'APP-XXINV-10157'; -- 品目振替_品目振替目的
  gv_msg_52a_52      CONSTANT VARCHAR2(15) := 'APP-XXINV-10152'; -- 品目振替_生産バッチNo
--add start 1.2
  gv_msg_52a_66      CONSTANT VARCHAR2(15) := 'APP-XXINV-10166'; -- ステータスエラー(フォーミュラ)
  gv_msg_52a_67      CONSTANT VARCHAR2(15) := 'APP-XXINV-10167'; -- ステータスエラー(レシピ)
  gv_msg_52a_69      CONSTANT VARCHAR2(15) := 'APP-XXINV-10169'; -- ステータスエラー(妥当性ルール)
--add end 1.2
--
  -- トークン
  gv_tkn_parameter   CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_tkn_value       CONSTANT VARCHAR2(15) := 'VALUE';
  gv_tkn_api_name    CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_err_msg     CONSTANT VARCHAR2(15) := 'ERR_MSG';
  gv_tkn_ng_profile  CONSTANT VARCHAR2(15) := 'NG_PROFILE';
--add start 1.2
  gv_tkn_formula     CONSTANT VARCHAR2(15) := 'FORMULA_NO';
  gv_tkn_recipe      CONSTANT VARCHAR2(15) := 'RECIPE_NO';
--add end 1.2
--
  -- トークン値
  gv_tkn_prf_dummy   CONSTANT VARCHAR2(20) := 'ダミー工順';
  gv_tkn_inv_loc     CONSTANT VARCHAR2(20) := '保管倉庫';
  gv_tkn_from_item   CONSTANT VARCHAR2(20) := '振替元品目';
  gv_tkn_to_item     CONSTANT VARCHAR2(20) := '振替先品目';
  gv_tkn_item_date   CONSTANT VARCHAR2(20) := '品目振替実績日';
  gv_tkn_item_aim    CONSTANT VARCHAR2(20) := '品目振替目的';
  gv_tkn_ins_formula CONSTANT VARCHAR2(20) := 'フォーミュラ登録';
  gv_tkn_upd_recipe  CONSTANT VARCHAR2(20) := 'レシピ更新';
  gv_tkn_create_lot  CONSTANT VARCHAR2(20) := 'ロット作成';
  gv_tkn_create_bat  CONSTANT VARCHAR2(20) := 'バッチ作成';
  gv_tkn_input_lot   CONSTANT VARCHAR2(20) := '入力ロット割当';
  gv_tkn_output_lot  CONSTANT VARCHAR2(20) := '出力ロット割当';
  gv_tkn_cmpt_bat    CONSTANT VARCHAR2(20) := 'バッチ完了';
  gv_tkn_close_bat   CONSTANT VARCHAR2(20) := 'バッチクローズ';
  gv_tkn_save_bat    CONSTANT VARCHAR2(20) := 'バッチ保存';
--
  -- プロファイル
  gv_prf_dummy_routing  CONSTANT VARCHAR2(20) := 'XXINV_DUMMY_ROUTING';
  -- プロファイル値
  gv_prf_val_item_ctgr  CONSTANT VARCHAR2(10) := '品目区分';
--
  -- ルックアップ
  gv_lt_item_tran_cls   CONSTANT VARCHAR2(30) := 'XXINV_ITEM_TRANS_CLASS';
--
  -- 品目区分
  gv_material        CONSTANT VARCHAR2(2)  := '1'; -- 原料
  gv_half_material   CONSTANT VARCHAR2(2)  := '4'; -- 半製品
--
  -- ROWNUM判定
  gn_rownum          CONSTANT NUMBER       := 1;
--
  -- フォーミュラ登録タイプ
  gv_record_type     CONSTANT VARCHAR2(2) := 'I'; -- 挿入
  -- フォーミュラステータス
  gv_fml_sts_new     CONSTANT VARCHAR2(4) := '100'; -- 新規
  gv_fml_sts_appr    CONSTANT VARCHAR2(4) := '700'; -- 一般使用の承認
  -- フォーミュラ・バージョン
  gn_fml_vers        CONSTANT NUMBER      := 1;
  -- レシピ・バージョン
  gn_rcp_vers        CONSTANT NUMBER      := 1;
--
  -- 明細タイプ
  gn_line_type_p     CONSTANT NUMBER      := 1;   -- 製品
  gn_line_type_i     CONSTANT NUMBER      := -1;  -- 原料
--
  gn_remarks_max     CONSTANT NUMBER      := 240; -- 摘要チェック用最大バイト数
--
  gn_bat_type_batch  CONSTANT NUMBER      := 0; -- 0:batch, 10:firm
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_prf_dummy_val   gmd_routings_b.routing_desc%TYPE;  -- ダミー工順
--
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
    -- フォーミュラマスタ
    formula_no              fm_form_mst_b.formula_no%TYPE,     -- フォーミュラ番号
    formula_type            fm_form_mst_b.formula_type%TYPE,   -- フォーミュラタイプ
    inactive_ind            fm_form_mst_b.inactive_ind%TYPE,   -- (必須項目)
    orgn_code               fm_form_mst_b.orgn_code%TYPE,      -- 組織(プラント)コード
    formula_status          fm_form_mst_b.formula_status%TYPE, -- ステータス
    formula_id              fm_form_mst_b.formula_id%TYPE,     -- フォーミュラID
    scale_type_hdr          fm_form_mst_b.scale_type%TYPE,     -- スケーリング可
    delete_mark             fm_form_mst_b.delete_mark%TYPE,    -- (必須項目)
    -- フォーミュラ明細マスタ
    formulaline_id          fm_matl_dtl.formulaline_id%TYPE,   -- 明細ID
    line_type               fm_matl_dtl.line_type%TYPE,        -- 明細タイプ
    line_no                 fm_matl_dtl.line_no%TYPE,          -- 明細番号
    qty                     fm_matl_dtl.qty%TYPE,              -- 数量
    release_type            fm_matl_dtl.release_type%TYPE,     -- 収益タイプ/消費タイプ
    scrap_factor            fm_matl_dtl.scrap_factor%TYPE,     -- 廃棄係数
    scale_type_dtl          fm_matl_dtl.scale_type%TYPE,       -- スケールタイプ
    phantom_type            fm_matl_dtl.phantom_type%TYPE,     -- ファントムタイプ
    rework_type             fm_matl_dtl.rework_type%TYPE,      -- (必須項目)
    -- レシピマスタ
    recipe_id               gmd_recipes_b.recipe_id%TYPE,               -- レシピID
    recipe_status           gmd_recipes_b.recipe_status%TYPE,           -- レシピステータス
    calculate_step_quantity gmd_recipes_b.calculate_step_quantity%TYPE, -- ステップ数量の計算
    -- レシピ妥当性ルールテーブル
    recipe_validity_rule_id gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE, -- 妥当性ルール
    -- 工順マスタ
    routing_id              gmd_routings_b.routing_id%TYPE,   -- 工順ID
    routing_no              gmd_routings_b.routing_no%TYPE,   -- 工順No
    routing_version         gmd_routings_b.routing_vers%TYPE, -- 工順バージョン
    -- OPM保管倉庫マスタ
    inventory_location_id   mtl_item_locations.inventory_location_id%TYPE, -- 保管倉庫ID
    inventory_location_code mtl_item_locations.segment1%TYPE,              -- 保管倉庫コード
    -- OPM倉庫マスタ
    whse_code               ic_whse_mst.whse_code%TYPE,                    -- 倉庫コード
    -- OPM品目マスタ
    from_item_id            ic_item_mst_b.item_id%TYPE, -- 振替元品目ID
    from_item_no            ic_item_mst_b.item_no%TYPE, -- 振替元品目No
    from_item_um            ic_item_mst_b.item_um%TYPE, -- 振替元単位
    to_item_id              ic_item_mst_b.item_id%TYPE, -- 振替先品目ID
    to_item_no              ic_item_mst_b.item_no%TYPE, -- 振替先品目No
    to_item_um              ic_item_mst_b.item_um%TYPE, -- 振替先単位
    -- OPMロットマスタ
    from_lot_id             ic_lots_mst.lot_id%TYPE,   -- 振替元ロットID
    to_lot_id               ic_lots_mst.lot_id%TYPE,   -- 振替先ロットID
    lot_no                  ic_lots_mst.lot_no%TYPE,        -- ロットNo
    lot_desc                ic_lots_mst.lot_desc%TYPE,      -- 摘要
    lot_attribute1          ic_lots_mst.attribute1%TYPE,    -- 製造年月日
    lot_attribute2          ic_lots_mst.attribute2%TYPE,    -- 固有記号
    lot_attribute3          ic_lots_mst.attribute3%TYPE,    -- 賞味期限
    lot_attribute4          ic_lots_mst.attribute4%TYPE,    -- 納入日(初回)
    lot_attribute5          ic_lots_mst.attribute5%TYPE,    -- 納入日(最終)
    lot_attribute6          ic_lots_mst.attribute6%TYPE,    -- 在庫入数
    lot_attribute7          ic_lots_mst.attribute7%TYPE,    -- 在庫単価
    lot_attribute8          ic_lots_mst.attribute8%TYPE,    -- 取引先
    lot_attribute9          ic_lots_mst.attribute9%TYPE,    -- 仕入形態
    lot_attribute10         ic_lots_mst.attribute10%TYPE,   -- 茶期区分
    lot_attribute11         ic_lots_mst.attribute11%TYPE,   -- 年度
    lot_attribute12         ic_lots_mst.attribute12%TYPE,   -- 産地
    lot_attribute13         ic_lots_mst.attribute13%TYPE,   -- タイプ
    lot_attribute14         ic_lots_mst.attribute14%TYPE,   -- ランク１
    lot_attribute15         ic_lots_mst.attribute15%TYPE,   -- ランク２
    lot_attribute16         ic_lots_mst.attribute16%TYPE,   -- 生産伝票区分
    lot_attribute17         ic_lots_mst.attribute17%TYPE,   -- ラインNo
    lot_attribute18         ic_lots_mst.attribute18%TYPE,   -- 摘要
    lot_attribute19         ic_lots_mst.attribute19%TYPE,   -- ランク３
    lot_attribute20         ic_lots_mst.attribute20%TYPE,   -- 原料製造工場
    lot_attribute21         ic_lots_mst.attribute21%TYPE,   -- 原料製造元ロット番号
    lot_attribute22         ic_lots_mst.attribute22%TYPE,   -- 検査依頼No
    lot_attribute23         ic_lots_mst.attribute23%TYPE,   -- ロットステータス
    lot_attribute24         ic_lots_mst.attribute24%TYPE,   -- 作成区分
    lot_attribute25         ic_lots_mst.attribute25%TYPE,
    lot_attribute26         ic_lots_mst.attribute26%TYPE,
    lot_attribute27         ic_lots_mst.attribute27%TYPE,
    lot_attribute28         ic_lots_mst.attribute28%TYPE,
    lot_attribute29         ic_lots_mst.attribute29%TYPE,
    lot_attribute30         ic_lots_mst.attribute30%TYPE,
--
    -- 生産バッチヘッダ
    batch_id                gme_batch_header.batch_id%TYPE,  -- バッチID
    batch_no                gme_batch_header.batch_no%TYPE,  -- バッチNo
--
    -- 生産原料詳細
    from_material_detail_id gme_material_details.material_detail_id%TYPE, -- 生産原料詳細ID(振替元)
    to_material_detail_id   gme_material_details.material_detail_id%TYPE, -- 生産原料詳細ID(振替先)
--
    item_sysdate            DATE,                          -- 品目振替実績日
    remarks                 VARCHAR2(240),                 -- 摘要
    item_chg_aim            VARCHAR2(1),                   -- 品目振替目的
    is_info_flg             BOOLEAN                        -- 情報有無フラグ
  );
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE init_proc(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ダミー工順にプロファイル値をセット
    gv_prf_dummy_val := FND_PROFILE.VALUE(gv_prf_dummy_routing);
    -- プロファイル値が取得できない場合
    IF (gv_prf_dummy_val IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,    gv_msg_52a_02,
                                            gv_tkn_ng_profile, gv_tkn_prf_dummy);
      RAISE global_api_expt;
    END IF;
--
    -- フォーミュラNoの取得
    ir_masters_rec.formula_no := xxinv_common_pkg.xxinv_get_formula_no(ir_masters_rec.from_item_no
                                                                      ,ir_masters_rec.to_item_no);
    -- フォーミュラNoが取得できない場合
    IF (ir_masters_rec.formula_no IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
      RAISE global_api_expt;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : パラメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.チェック対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_count           NUMBER;  -- カウンター
    ln_onhand_stk_qty  NUMBER;  -- 手持在庫数量格納用
    ln_fin_stk_qty     NUMBER;  -- 引当済在庫数量格納用
    ln_can_enc_qty     NUMBER;  -- 引当可能数
    ln_lot_ship_qty    NUMBER;  -- 数量格納用<実績未計上の出荷依頼>
    ln_lot_provide_qty NUMBER;  -- 数量格納用<実績未計上の支給指示>
    ln_lot_inv_out_qty NUMBER;  -- 数量格納用<実績未計上の移動指示>
    ln_lot_inv_in_qty  NUMBER;  -- 数量格納用<実績計上済の移動入庫実績>
    ln_lot_produce_qty NUMBER;  -- 数量格納用<実績未計上の生産投入予定>
    ln_lot_order_qty   NUMBER;  -- 数量格納用<実績未計上の相手先倉庫発注入庫予定>
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
    -- 手持在庫数量の初期化
    ln_onhand_stk_qty := 0;
--
    -- ==================================
    -- 保管倉庫のパラメータチェック
    -- ==================================
    -- カウンターの初期化
    ln_count := 0;
--
    SELECT COUNT(xilv.segment1) inventory_location_code  -- 保管倉庫コード
    INTO   ln_count
    FROM   xxcmn_item_locations_v  xilv                             -- OPM保管場所情報VIEW
    WHERE  xilv.segment1 = ir_masters_rec.inventory_location_code
    AND    ROWNUM        = gn_rownum;
--
    -- OPM保管場所マスタに登録されていない場合
    IF (ln_count < 1) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_inv_loc,
                                            gv_tkn_value,
                                            ir_masters_rec.inventory_location_code);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    -- 登録されている場合
    ELSE
      -- ==================================
      -- 保管倉庫ID、倉庫コードの取得
      -- ==================================
      SELECT xilv.inventory_location_id,  -- 保管倉庫ID
             xilv.whse_code               -- 倉庫コード
      INTO   ir_masters_rec.inventory_location_id,
             ir_masters_rec.whse_code
      FROM   xxcmn_item_locations_v xilv -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = ir_masters_rec.inventory_location_code;
    END IF;
--
    -- ==================================
    -- 振替元品目のパラメータチェック
    -- ==================================
    -- カウンターの初期化
    ln_count := 0;
--
    SELECT COUNT(xicv.item_no) item_no  -- 品目No
    INTO   ln_count
    FROM   xxcmn_item_categories_v xicv -- OPM品目カテゴリ割当情報VIEW
    WHERE  xicv.item_no  = ir_masters_rec.from_item_no
    AND    xicv.category_set_name = gv_prf_val_item_ctgr
    AND    xicv.segment1 IN (gv_material, gv_half_material)
    AND    ROWNUM        = gn_rownum;
--
    -- 振替元品目IDが登録されていない、または原料か半製品でない場合
    IF (ln_count < 1) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_from_item,
                                            gv_tkn_value,     ir_masters_rec.from_item_no);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    -- 登録されている場合
    ELSE
      -- ==================================
      -- 振替元Noより導出した情報の取得
      -- ==================================
      SELECT iimb.item_id,               -- 品目ID
             iimb.item_um                -- 単位
      INTO   ir_masters_rec.from_item_id,
             ir_masters_rec.from_item_um
      FROM   ic_item_mst_b iimb          -- OPM品目マスタ
      WHERE  iimb.item_no = ir_masters_rec.from_item_no;
    END IF;
--
    -- ==================================
    -- 振替元ロットNoのパラメータチェック
    -- ==================================
    -- カウンターの初期化
    ln_count := 0;
--
    SELECT COUNT(ilm.lot_no) lot_no  -- ロットNo
    INTO   ln_count
    FROM   ic_lots_mst  ilm          -- OPMロットマスタ
    WHERE  ilm.lot_no       = ir_masters_rec.lot_no
    AND    ilm.item_id      = ir_masters_rec.from_item_id
    --AND    ilm.inactive_ind = '0'
    --AND    ilm.delete_mark  = '0'
    AND    ROWNUM           = gn_rownum;
--
    -- OPMロットマスタに登録されていない場合
    IF (ln_count < 1) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_17);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    -- 登録されている場合
    ELSE
      -- ==================================
      -- 振替元ロットIDの取得
      -- ==================================
      SELECT ilm.lot_id                  -- ロットID
      INTO   ir_masters_rec.from_lot_id
      FROM   ic_lots_mst ilm             -- OPMロットマスタ
      WHERE  ilm.lot_no  = ir_masters_rec.lot_no
      AND    ilm.item_id = ir_masters_rec.from_item_id;
    END IF;
--
    -- ==================================
    -- 振替先品目のパラメータチェック
    -- ==================================
    -- カウンターの初期化
    ln_count := 0;
--
    SELECT COUNT(xicv.item_no) item_no  -- 品目No
    INTO   ln_count
    FROM   xxcmn_item_categories_v xicv -- OPM品目カテゴリ割当情報VIEW
    WHERE  xicv.item_no  = ir_masters_rec.to_item_no
    AND    xicv.category_set_name = gv_prf_val_item_ctgr
    AND    xicv.segment1 IN (gv_material, gv_half_material)
    AND    ROWNUM        = gn_rownum;
--
    -- OPM品目マスタに登録されていない場合
    IF (ln_count < 1) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_to_item,
                                            gv_tkn_value,     ir_masters_rec.to_item_no);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    -- 登録されている場合
    ELSE
      -- ==================================
      -- 振替先品目Noより導出した情報の取得
      -- ==================================
      SELECT iimb.item_id,               -- 品目ID
             iimb.item_um                -- 単位
      INTO   ir_masters_rec.to_item_id,
             ir_masters_rec.to_item_um
      FROM   ic_item_mst_b iimb          -- OPM品目マスタ
      WHERE  iimb.item_no = ir_masters_rec.to_item_no;
    END IF;
--
    -- ==================================
    -- 品目振替実績日のパラメータチェック
    -- ==================================
    -- 品目振替実績日が未来日の場合
    IF (TRUNC(ir_masters_rec.item_sysdate) > TRUNC(SYSDATE)) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_21);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- 品目振替実績日が在庫カレンダーのオープンでない場合
    IF (TRUNC(ir_masters_rec.item_sysdate) <=
      TRUNC(LAST_DAY(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period(),
        'YYYY/MM')))) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_03,
                                            gv_tkn_err_msg, ir_masters_rec.item_sysdate);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 数量のパラメータチェック
    -- ==================================
    -- 手持在庫数量の取得
    ln_onhand_stk_qty := xxcmn_common_pkg.get_stock_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.保管倉庫ID
                                     ir_masters_rec.from_item_id,              -- 2.品目ID
                                     ir_masters_rec.from_lot_id);              -- 3.ロットID
--
    -- 数量の取得<実績未計上の出荷依頼>
    xxcmn_common2_pkg.get_dem_lot_ship_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.保管倉庫ID
                                     ir_masters_rec.from_item_id,              -- 2.品目ID
                                     ir_masters_rec.from_lot_id,               -- 3.ロットID
                                     ir_masters_rec.item_sysdate,              -- 4.有効日付
                                     ln_lot_ship_qty,                          -- 5.数量
                                     lv_errbuf,     -- エラー・メッセージ           --# 固定 #
                                     lv_retcode,    -- リターン・コード             --# 固定 #
                                     lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
    -- 数量の取得<実績未計上の支給指示>
    xxcmn_common2_pkg.get_dem_lot_provide_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.保管倉庫ID
                                     ir_masters_rec.from_item_id,              -- 2.品目ID
                                     ir_masters_rec.from_lot_id,               -- 3.ロットID
                                     ir_masters_rec.item_sysdate,              -- 4.有効日付
                                     ln_lot_provide_qty,                       -- 5.数量
                                     lv_errbuf,     -- エラー・メッセージ           --# 固定 #
                                     lv_retcode,    -- リターン・コード             --# 固定 #
                                     lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
    -- 数量の取得<実績未計上の移動指示>
    xxcmn_common2_pkg.get_dem_lot_inv_out_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.保管倉庫ID
                                     ir_masters_rec.from_item_id,              -- 2.品目ID
                                     ir_masters_rec.from_lot_id,               -- 3.ロットID
                                     ir_masters_rec.item_sysdate,              -- 4.有効日付
                                     ln_lot_inv_out_qty,                       -- 5.数量
                                     lv_errbuf,     -- エラー・メッセージ           --# 固定 #
                                     lv_retcode,    -- リターン・コード             --# 固定 #
                                     lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
    -- 数量の取得<実績計上済の移動入庫実績>
    xxcmn_common2_pkg.get_dem_lot_inv_in_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.保管倉庫ID
                                     ir_masters_rec.from_item_id,              -- 2.品目ID
                                     ir_masters_rec.from_lot_id,               -- 3.ロットID
                                     ir_masters_rec.item_sysdate,              -- 4.有効日付
                                     ln_lot_inv_in_qty,                        -- 5.数量
                                     lv_errbuf,     -- エラー・メッセージ           --# 固定 #
                                     lv_retcode,    -- リターン・コード             --# 固定 #
                                     lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
    -- 数量の取得<実績未計上の生産投入予定>
    xxcmn_common2_pkg.get_dem_lot_produce_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.保管倉庫ID
                                     ir_masters_rec.from_item_id,              -- 2.品目ID
                                     ir_masters_rec.from_lot_id,               -- 3.ロットID
                                     ir_masters_rec.item_sysdate,              -- 4.有効日付
                                     ln_lot_produce_qty,                       -- 5.数量
                                     lv_errbuf,     -- エラー・メッセージ           --# 固定 #
                                     lv_retcode,    -- リターン・コード             --# 固定 #
                                     lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
    -- 数量の取得<実績未計上の相手先倉庫発注入庫予定>
    xxcmn_common2_pkg.get_dem_lot_order_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.保管倉庫ID
                                     ir_masters_rec.from_item_id,              -- 2.品目ID
                                     ir_masters_rec.from_lot_id,               -- 3.ロットID
                                     ir_masters_rec.item_sysdate,              -- 4.有効日付
                                     ln_lot_order_qty,                         -- 5.数量
                                     lv_errbuf,    -- エラー・メッセージ           --# 固定 #
                                     lv_retcode,   -- リターン・コード             --# 固定 #
                                     lv_errmsg);   -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 引当済在庫数量の算出
    ln_fin_stk_qty := ln_lot_ship_qty + ln_lot_provide_qty + ln_lot_inv_out_qty
                      + ln_lot_inv_in_qty + ln_lot_produce_qty + ln_lot_order_qty;
--
    -- 引当可能数の算出
    ln_can_enc_qty := ln_onhand_stk_qty - ln_fin_stk_qty;
--
    -- 引当可能数より大きい場合
    IF (ir_masters_rec.qty > ln_can_enc_qty) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_20);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 摘要のパラメータチェック
    -- ==================================
    IF (LENGTHB(ir_masters_rec.remarks) > gn_remarks_max) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_71);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 品目振替目的のパラメータチェック
    -- ==================================
    -- カウンターの初期化
    ln_count := 0;
--
    -- クイックコードに存在しているかを確認
    SELECT COUNT(flvv.lookup_code)
    INTO   ln_count
    FROM   xxcmn_lookup_values_v flvv   -- ルックアップVIEW
    WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
    AND    flvv.lookup_code  = ir_masters_rec.item_chg_aim;
--
    -- 品目振替目的がクイックコードに登録されていない場合
    IF (ln_count < 1) THEN
      -- エラーメッセージを出力
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_item_aim,
                                            gv_tkn_value,     ir_masters_rec.item_chg_aim);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : set_masters_rec
   * Description      : データセット処理
   ***********************************************************************************/
  PROCEDURE set_masters_rec(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.チェック対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_masters_rec'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- ==================================
    -- プラント(組織)コードの取得
    -- ==================================
    SELECT xilv.orgn_code               -- プラントコード
    INTO   ir_masters_rec.orgn_code
    FROM   xxcmn_item_locations_v xilv -- OPM保管場所情報VIEW
    WHERE  xilv.inventory_location_id = ir_masters_rec.inventory_location_id;
--
    -- ==================================
    -- 工順情報の取得
    -- ==================================
    SELECT grb.routing_id,             -- 工順ID
           grb.routing_no,             -- 工順NO
           grb.routing_vers            -- 工順バージョン
    INTO   ir_masters_rec.routing_id,
           ir_masters_rec.routing_no,
           ir_masters_rec.routing_version
    FROM   gmd_routings_b       grb,   -- 工順マスタ
           gmd_routing_class_b  grcb,  -- 工順区分マスタ
           gmd_routing_class_tl grct   -- 工順区分マスタ日本語
    WHERE  grct.routing_class_desc = gv_prf_dummy_val
    AND    grct.language           = 'JA'
    AND    grct.routing_class      = grcb.routing_class
    AND    grcb.routing_class      = grb.routing_class;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END set_masters_rec;
--
  /**********************************************************************************
   * Procedure Name   : chk_formula
   * Description      : フォーミュラ有無チェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.チェック対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_formula'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--add start 1.2
    lv_formula_status  fm_form_mst_b.formula_status%TYPE;
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(2000);
    lv_msg_list      VARCHAR2(2000);
--add end 1.2
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
    -- 情報有無フラグの初期化
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- 振替元品目のフォーミュラID有無チェック
    -- ======================================
--
    -- フォーミュラIDの取得
--mod start 1.2
--    SELECT ffmb.formula_id            -- フォーミュラID
--    INTO   ir_masters_rec.formula_id
    SELECT ffmb.formula_id             -- フォーミュラID
          ,ffmb.formula_status         -- フォーミュラステータス
    INTO   ir_masters_rec.formula_id
          ,lv_formula_status
--mod end 1.2
    FROM   fm_form_mst_b ffmb,         -- フォーミュラマスタ
           fm_matl_dtl   fmd1,         -- フォーミュラマスタ明細
           fm_matl_dtl   fmd2          -- フォーミュラマスタ明細
    WHERE  ffmb.formula_id = fmd1.formula_id
    AND    ffmb.formula_id = fmd2.formula_id
    AND    fmd1.item_id    = ir_masters_rec.from_item_id
    AND    fmd2.item_id    = ir_masters_rec.to_item_id
    AND    ffmb.formula_no = ir_masters_rec.formula_no;
--
--add start 1.2
    -- ステータスが「一般使用の承認」の場合
    IF (lv_formula_status = gv_fml_sts_appr) THEN
      NULL;
    -- ステータスが「新規」の場合
    ELSIF (lv_formula_status = gv_fml_sts_new) THEN
      -- ステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
                         P_API_VERSION    => 1.0,                       -- APIバージョン番号
                         P_INIT_MSG_LIST  => TRUE,                      -- メッセージ初期化フラグ
                         P_ENTITY_NAME    => 'FORMULA',                 -- フォーミュラ名
                         P_ENTITY_ID      => ir_masters_rec.formula_id, -- フォーミュラID
                         P_ENTITY_NO      => NULL,                      -- 番号(NULL固定)
                         P_ENTITY_VERSION => NULL,                      -- バージョン(NULL固定)
                         P_TO_STATUS      => gv_fml_sts_appr,           -- ステータス変更値
                         P_IGNORE_FLAG    => FALSE,
                         X_MESSAGE_COUNT  => ln_message_count,          -- エラーメッセージ件数
                         X_MESSAGE_LIST   => lv_msg_list,               -- エラーメッセージ
                         X_RETURN_STATUS  => lv_return_status           -- プロセス終了ステータス
                            );
--
      -- ステータス変更処理が成功でない場合
      IF (lv_return_status <> gv_ret_sts_success) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                              gv_tkn_api_name, gv_tkn_ins_formula);
        RAISE global_api_expt;
      -- ステータス変更処理が成功の場合
      ELSIF (lv_return_status = gv_ret_sts_success) THEN
        -- 確定処理
        COMMIT;
      END IF;
--
    -- ステータスが上記以外の場合
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_66,
                                            gv_tkn_formula, ir_masters_rec.formula_no);
      RAISE global_api_expt;
    END IF;
--add end 1.2
  EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- 処理対象レコードが1件もなかった場合
      ir_masters_rec.is_info_flg := FALSE;
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
  END chk_formula;
--
  /**********************************************************************************
   * Procedure Name   : ins_formula
   * Description      : フォーミュラ登録(A-3)
   ***********************************************************************************/
  PROCEDURE ins_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_formula'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- INSERT_FORMULA API用変数
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(2000);
    -- MODIFY_STATUS API用変数
    lv_msg_list      VARCHAR2(2000);
--
    -- フォーミュラテーブル型変数
    lt_formula_header_tbl GMD_FORMULA_PUB.FORMULA_INSERT_HDR_TBL_TYPE;
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
    -- 登録情報をセット(親品目:製品)
    lt_formula_header_tbl(1).formula_no     := ir_masters_rec.formula_no; -- 番号
    lt_formula_header_tbl(1).formula_vers   := gn_fml_vers;               -- バージョン
    lt_formula_header_tbl(1).formula_desc1  := ir_masters_rec.formula_no; -- 摘要
    lt_formula_header_tbl(1).formula_status := gv_fml_sts_new;            -- ステータス
    lt_formula_header_tbl(1).orgn_code      := ir_masters_rec.orgn_code;  -- 組織
    lt_formula_header_tbl(1).line_no        := 1;                         -- 明細番号
    lt_formula_header_tbl(1).line_type      := gn_line_type_p;            -- 明細タイプ
    lt_formula_header_tbl(1).item_no        := ir_masters_rec.to_item_no; -- 品目No
    lt_formula_header_tbl(1).qty            := ir_masters_rec.qty;        -- 数量
    lt_formula_header_tbl(1).item_um        := ir_masters_rec.to_item_um; -- 単位
    lt_formula_header_tbl(1).user_name      := FND_GLOBAL.USER_NAME;      -- ユーザー
    lt_formula_header_tbl(1).release_type   := 0;                         -- 収率タイプ(0:自動)
--
    -- 登録情報をセット(構成品目:原料)
    lt_formula_header_tbl(2).formula_no     := ir_masters_rec.formula_no;   -- 番号
    lt_formula_header_tbl(2).formula_vers   := gn_fml_vers;                 -- バージョン
    lt_formula_header_tbl(2).formula_desc1  := ir_masters_rec.formula_no;   -- 摘要
    lt_formula_header_tbl(2).formula_status := gv_fml_sts_new;              -- ステータス
    lt_formula_header_tbl(2).orgn_code      := ir_masters_rec.orgn_code;    -- 組織
    lt_formula_header_tbl(2).line_no        := 1;                           -- 明細番号
    lt_formula_header_tbl(2).line_type      := gn_line_type_i;              -- 明細タイプ
    lt_formula_header_tbl(2).item_no        := ir_masters_rec.from_item_no; -- 品目No
    lt_formula_header_tbl(2).qty            := ir_masters_rec.qty;          -- 数量
    lt_formula_header_tbl(2).item_um        := ir_masters_rec.from_item_um; -- 単位
    lt_formula_header_tbl(2).user_name      := FND_GLOBAL.USER_NAME;        -- ユーザー
    lt_formula_header_tbl(2).release_type   := 0;                           -- 収率タイプ(0:自動)
--
    -- フォーミュラ登録(EBS標準API)
    GMD_FORMULA_PUB.INSERT_FORMULA(
                         P_API_VERSION        => 1.0,                   -- APIバージョン番号
                         P_INIT_MSG_LIST      => FND_API.G_FALSE,       -- メッセージ初期化フラグ
                         P_COMMIT             => FND_API.G_TRUE,        -- 自動コミットフラグ
                         P_CALLED_FROM_FORMS  => 'NO',
                         X_RETURN_STATUS      => lv_return_status,      -- プロセス終了ステータス
                         X_MSG_COUNT          => ln_message_count,      -- エラーメッセージ件数
                         X_MSG_DATA           => lv_msg_date,           -- エラーメッセージ
                         P_FORMULA_HEADER_TBL => lt_formula_header_tbl,
                         P_ALLOW_ZERO_ING_QTY => 'FALSE'
                                  );
    -- 登録処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_ins_formula);
      RAISE global_api_expt;
    -- 登録処理が成功の場合
    ELSIF (lv_return_status = gv_ret_sts_success) THEN
      -- フォーミュラIDの取得
      SELECT ffmb.formula_id           -- フォーミュラID
      INTO   ir_masters_rec.formula_id
      FROM   fm_form_mst_b ffmb,       -- フォーミュラマスタ
             fm_matl_dtl   fmd1,       -- フォーミュラマスタ明細
             fm_matl_dtl   fmd2        -- フォーミュラマスタ明細
      WHERE  ffmb.formula_id = fmd1.formula_id
      AND    ffmb.formula_id = fmd2.formula_id
      AND    fmd1.item_id    = ir_masters_rec.from_item_id
      AND    fmd2.item_id    = ir_masters_rec.to_item_id
      AND    ffmb.formula_no = ir_masters_rec.formula_no;
    END IF;
--
    -- ステータス変更(EBS標準API)
    GMD_STATUS_PUB.MODIFY_STATUS(
                       P_API_VERSION    => 1.0,                       -- APIバージョン番号
                       P_INIT_MSG_LIST  => TRUE,                      -- メッセージ初期化フラグ
                       P_ENTITY_NAME    => 'FORMULA',                 -- フォーミュラ名
                       P_ENTITY_ID      => ir_masters_rec.formula_id, -- フォーミュラID
                       P_ENTITY_NO      => NULL,                      -- 番号(NULL固定)
                       P_ENTITY_VERSION => NULL,                      -- バージョン(NULL固定)
                       P_TO_STATUS      => gv_fml_sts_appr,           -- ステータス変更値
                       P_IGNORE_FLAG    => FALSE,
                       X_MESSAGE_COUNT  => ln_message_count,          -- エラーメッセージ件数
                       X_MESSAGE_LIST   => lv_msg_list,               -- エラーメッセージ
                       X_RETURN_STATUS  => lv_return_status           -- プロセス終了ステータス
                          );
--
    -- ステータス変更処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_ins_formula);
      RAISE global_api_expt;
    -- ステータス変更処理が成功の場合
    ELSIF (lv_return_status = gv_ret_sts_success) THEN
      -- 確定処理
      COMMIT;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END ins_formula;
--
  /**********************************************************************************
   * Procedure Name   : chk_recipe
   * Description      : レシピ有無チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.チェック対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_recipe'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--add start 1.2
    lv_recipe_status                gmd_recipes_b.recipe_status%TYPE;
    lv_recipe_no                    gmd_recipes_b.recipe_no%TYPE;
    ln_recipe_validity_rule_id      gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE;
    lv_validity_rule_status         gmd_recipe_validity_rules.validity_rule_status%TYPE;
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(4000);
    lv_msg_list      VARCHAR2(2000);
--add end 1.2
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
    -- 情報有無フラグの初期化
    ir_masters_rec.is_info_flg := TRUE;
--
    -- レシピIDの取得
--mod start 1.2
--    SELECT greb.recipe_id              -- レシピID
--    INTO   ir_masters_rec.recipe_id
    SELECT greb.recipe_id              -- レシピID
          ,greb.recipe_status          -- レシピステータス
          ,greb.recipe_no              -- レシピNo
    INTO   ir_masters_rec.recipe_id
          ,lv_recipe_status
          ,lv_recipe_no
--mod end 1.2
    FROM   gmd_recipes_b             greb, -- レシピマスタ
           gmd_routings_b            grob  -- 工順マスタ
    WHERE  greb.formula_id      = ir_masters_rec.formula_id
    AND    greb.routing_id      = grob.routing_id
    AND    grob.routing_no      = ir_masters_rec.routing_no
    AND    grob.routing_class   = (SELECT grb.routing_class
                                   FROM   gmd_routings_b        grb,  -- 工順マスタ
                                          gmd_routing_class_b   grcb, -- 工順区分マスタ
                                          gmd_routing_class_tl  grct  -- 工順区分マスタ日本語
                                   WHERE  grb.routing_class       = grcb.routing_class
                                   AND    grcb.routing_class      = grct.routing_class
                                   AND    grct.language           = 'JA'
                                   AND    grct.routing_class_desc = gv_prf_dummy_val
                                   AND    grb.routing_id = ir_masters_rec.routing_id);
--
--add start 1.2
    -- ステータスが「一般使用の承認」の場合
    IF (lv_recipe_status = gv_fml_sts_appr) THEN
      NULL;
    -- ステータスが「新規」の場合
    ELSIF (lv_recipe_status = gv_fml_sts_new) THEN
      -- レシピステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
                                   P_API_VERSION    => 1.0,
                                   P_INIT_MSG_LIST  => TRUE,
                                   P_ENTITY_NAME    => 'RECIPE',
                                   P_ENTITY_ID      => ir_masters_rec.recipe_id,
                                   P_ENTITY_NO      => NULL,            -- (NULL固定)
                                   P_ENTITY_VERSION => NULL,            -- (NULL固定)
                                   P_TO_STATUS      => gv_fml_sts_appr,
                                   P_IGNORE_FLAG    => FALSE,
                                   X_MESSAGE_COUNT  => ln_message_count,
                                   X_MESSAGE_LIST   => lv_msg_list,
                                   X_RETURN_STATUS  => lv_return_status
                                  );
--
      -- ステータス変更処理が成功でない場合
      IF (lv_return_status <> gv_ret_sts_success) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                              gv_tkn_api_name, gv_tkn_upd_recipe);
        RAISE global_api_expt;
      ELSE
        COMMIT;
      END IF;
--
    -- ステータスが上記以外の場合
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_67,
                                            gv_tkn_recipe, lv_recipe_no);
      RAISE global_api_expt;
    END IF;
--
    -- 妥当性ルールIDの取得
    SELECT grvr.recipe_validity_rule_id
          ,grvr.validity_rule_status
    INTO   ln_recipe_validity_rule_id
          ,lv_validity_rule_status
    FROM   gmd_recipe_validity_rules grvr   -- レシピ妥当性ルールマスタ
    WHERE  grvr.recipe_id = ir_masters_rec.recipe_id;
--
    -- ステータスが「一般使用の承認」の場合
    IF (lv_validity_rule_status = gv_fml_sts_appr) THEN
      NULL;
    -- ステータスが「新規」の場合
    ELSIF (lv_validity_rule_status = gv_fml_sts_new) THEN
      -- 妥当性ルールステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
                                   P_API_VERSION    => 1.0,
                                   P_INIT_MSG_LIST  => TRUE,
                                   P_ENTITY_NAME    => 'VALIDITY',
                                   P_ENTITY_ID      => ln_recipe_validity_rule_id,
                                   P_ENTITY_NO      => NULL,            -- (NULL固定)
                                   P_ENTITY_VERSION => NULL,            -- (NULL固定)
                                   P_TO_STATUS      => gv_fml_sts_appr,
                                   P_IGNORE_FLAG    => FALSE,
                                   X_MESSAGE_COUNT  => ln_message_count,
                                   X_MESSAGE_LIST   => lv_msg_list,
                                   X_RETURN_STATUS  => lv_return_status
                                  );
--
      -- ステータス変更処理が成功でない場合
      IF (lv_return_status <> gv_ret_sts_success) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                              gv_tkn_api_name, gv_tkn_upd_recipe);
        RAISE global_api_expt;
      -- ステータス変更処理が成功の場合
      ELSIF (lv_return_status = gv_ret_sts_success) THEN
        -- 確定処理
        COMMIT;
      END IF;
--
    -- ステータスが上記以外の場合
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_69,
                                            gv_tkn_recipe, lv_recipe_no);
      RAISE global_api_expt;
    END IF;
--add end 1.2
  EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- 処理対象レコードが1件もなかった場合
      ir_masters_rec.is_info_flg := FALSE;
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
  END chk_recipe;
--
  /**********************************************************************************
   * Procedure Name   : upd_recipe
   * Description      : レシピ更新
   ***********************************************************************************/
  PROCEDURE upd_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_recipe'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- CREATE_RECIPE_HEADER API用変数
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(4000);
    -- MODIFY_STATUS API用変数
    lv_msg_list      VARCHAR2(2000);
--
    -- レシピテーブル型変数
    lt_recipe_hdr_tbl    GMD_RECIPE_HEADER.RECIPE_TBL;
    lt_recipe_hdr_flex   GMD_RECIPE_HEADER.RECIPE_UPDATE_FLEX;
--
-- for debug
	l_data					VARCHAR2(2000);
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
    -- レシピIDの取得
    SELECT greb.recipe_id              -- レシピID
    INTO   ir_masters_rec.recipe_id
    FROM   gmd_recipes_b             greb, -- レシピマスタ
           gmd_routings_b            grob  -- 工順マスタ
    WHERE  greb.formula_id      = ir_masters_rec.formula_id
    AND    greb.routing_id      IS NULL
    AND    grob.routing_no      = ir_masters_rec.routing_no
    AND    grob.routing_class   = (SELECT grb.routing_class
                                   FROM   gmd_routings_b        grb,  -- 工順マスタ
                                          gmd_routing_class_b   grcb, -- 工順区分マスタ
                                          gmd_routing_class_tl  grct  -- 工順区分マスタ日本語
                                   WHERE  grb.routing_class       = grcb.routing_class
                                   AND    grcb.routing_class      = grct.routing_class
                                   AND    grct.language           = 'JA'
                                   AND    grct.routing_class_desc = gv_prf_dummy_val
                                   AND    grb.routing_id = ir_masters_rec.routing_id);
--
    -- ===============================
    -- 登録情報をセット
    -- ===============================
    -- レシピID
    lt_recipe_hdr_tbl(1).recipe_id          := ir_masters_rec.recipe_id;
    -- 工順ID
    lt_recipe_hdr_tbl(1).routing_id         := ir_masters_rec.routing_id;
    -- 工順番号
    lt_recipe_hdr_tbl(1).routing_no         := ir_masters_rec.routing_no;
    -- 工順バージョン
    lt_recipe_hdr_tbl(1).routing_vers       := ir_masters_rec.routing_version;
    -- レシピ更新(EBS標準API)
    GMD_RECIPE_HEADER.UPDATE_RECIPE_HEADER(
                                           P_API_VERSION        => 2.0,
                                           P_INIT_MSG_LIST      => FND_API.G_FALSE,
                                           P_COMMIT             => FND_API.G_TRUE,
                                           P_CALLED_FROM_FORMS  => 'NO',
                                           X_RETURN_STATUS      => lv_return_status,
                                           X_MSG_COUNT          => ln_message_count,
                                           X_MSG_DATA           => lv_msg_date,
                                           P_RECIPE_HEADER_TBL  => lt_recipe_hdr_tbl,
                                           P_RECIPE_UPDATE_FLEX => lt_recipe_hdr_flex
                                          );
    -- 更新処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
-- add 2008/05/20
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
      IF (ln_message_count > 0) THEN
        FOR i IN 1..ln_message_count LOOP
          -- 次のメッセージの取得
          l_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_data = '|| l_data);
        END LOOP;
      END IF;
-- add 2008/05/20
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_upd_recipe);
      RAISE global_api_expt;
    END IF;
--
    -- レシピステータス変更(EBS標準API)
    GMD_STATUS_PUB.MODIFY_STATUS(
                                 P_API_VERSION    => 1.0,
                                 P_INIT_MSG_LIST  => TRUE,
                                 P_ENTITY_NAME    => 'RECIPE',
                                 P_ENTITY_ID      => ir_masters_rec.recipe_id,
                                 P_ENTITY_NO      => NULL,            -- (NULL固定)
                                 P_ENTITY_VERSION => NULL,            -- (NULL固定)
                                 P_TO_STATUS      => gv_fml_sts_appr,
                                 P_IGNORE_FLAG    => FALSE,
                                 X_MESSAGE_COUNT  => ln_message_count,
                                 X_MESSAGE_LIST   => lv_msg_list,
                                 X_RETURN_STATUS  => lv_return_status
                                );
--
    -- ステータス変更処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_upd_recipe);
      RAISE global_api_expt;
    END IF;
--
    -- 妥当性ルールIDの取得
    SELECT grvr.recipe_validity_rule_id
    INTO   ir_masters_rec.recipe_validity_rule_id
    FROM   gmd_recipe_validity_rules grvr   -- レシピ妥当性ルールマスタ
    WHERE  grvr.recipe_id = ir_masters_rec.recipe_id;
--
    -- 妥当性ルールステータス変更(EBS標準API)
    GMD_STATUS_PUB.MODIFY_STATUS(
                                 P_API_VERSION    => 1.0,
                                 P_INIT_MSG_LIST  => TRUE,
                                 P_ENTITY_NAME    => 'VALIDITY',
                                 P_ENTITY_ID      => ir_masters_rec.recipe_validity_rule_id,
                                 P_ENTITY_NO      => NULL,            -- (NULL固定)
                                 P_ENTITY_VERSION => NULL,            -- (NULL固定)
                                 P_TO_STATUS      => gv_fml_sts_appr,
                                 P_IGNORE_FLAG    => FALSE,
                                 X_MESSAGE_COUNT  => ln_message_count,
                                 X_MESSAGE_LIST   => lv_msg_list,
                                 X_RETURN_STATUS  => lv_return_status
                                );
--
    -- ステータス変更処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_upd_recipe);
      RAISE global_api_expt;
    -- ステータス変更処理が成功の場合
    ELSIF (lv_return_status = gv_ret_sts_success) THEN
      -- 確定処理
      COMMIT;
--
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END upd_recipe;
--
  /**********************************************************************************
   * Procedure Name   : chk_lot
   * Description      : ロット有無チェック(A-6)
   ***********************************************************************************/
  PROCEDURE chk_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.チェック対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_lot'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- 情報有無フラグの初期化
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- ロットID有無チェック
    -- ======================================
    -- ロット情報の取得
    SELECT ilm.lot_id,        -- ロットID
           ilm.lot_desc,      -- 摘要
           ilm.attribute1,    -- 製造年月日
           ilm.attribute2,    -- 固有記号
           ilm.attribute3,    -- 賞味期限
           ilm.attribute4,    -- 納入日(初回)
           ilm.attribute5,    -- 納入日(最終)
           ilm.attribute6,    -- 在庫入数
           ilm.attribute7,    -- 在庫単価
           ilm.attribute8,    -- 取引先
           ilm.attribute9,    -- 仕入形態
           ilm.attribute10,   -- 茶期区分
           ilm.attribute11,   -- 年度
           ilm.attribute12,   -- 産地
           ilm.attribute13,   -- タイプ
           ilm.attribute14,   -- ランク１
           ilm.attribute15,   -- ランク２
           ilm.attribute16,   -- 生産伝票区分
           ilm.attribute17,   -- ラインNo
           ilm.attribute18,   -- 摘要
           ilm.attribute19,   -- ランク３
           ilm.attribute20,   -- 原料製造工場
           ilm.attribute21,   -- 原料製造元ロット番号
           ilm.attribute22,   -- 検査依頼No
           ilm.attribute23,   -- ロットステータス
           ilm.attribute24,   -- 作成区分
           ilm.attribute25,   -- 属性25
           ilm.attribute26,   -- 属性26
           ilm.attribute27,   -- 属性27
           ilm.attribute28,   -- 属性28
           ilm.attribute29,   -- 属性29
           ilm.attribute30    -- 属性30
    INTO   ir_masters_rec.to_lot_id,
           ir_masters_rec.lot_desc,
           ir_masters_rec.lot_attribute1,
           ir_masters_rec.lot_attribute2,
           ir_masters_rec.lot_attribute3,
           ir_masters_rec.lot_attribute4,
           ir_masters_rec.lot_attribute5,
           ir_masters_rec.lot_attribute6,
           ir_masters_rec.lot_attribute7,
           ir_masters_rec.lot_attribute8,
           ir_masters_rec.lot_attribute9,
           ir_masters_rec.lot_attribute10,
           ir_masters_rec.lot_attribute11,
           ir_masters_rec.lot_attribute12,
           ir_masters_rec.lot_attribute13,
           ir_masters_rec.lot_attribute14,
           ir_masters_rec.lot_attribute15,
           ir_masters_rec.lot_attribute16,
           ir_masters_rec.lot_attribute17,
           ir_masters_rec.lot_attribute18,
           ir_masters_rec.lot_attribute19,
           ir_masters_rec.lot_attribute20,
           ir_masters_rec.lot_attribute21,
           ir_masters_rec.lot_attribute22,
           ir_masters_rec.lot_attribute23,
           ir_masters_rec.lot_attribute24,
           ir_masters_rec.lot_attribute25,
           ir_masters_rec.lot_attribute26,
           ir_masters_rec.lot_attribute27,
           ir_masters_rec.lot_attribute28,
           ir_masters_rec.lot_attribute29,
           ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPMロットマスタ
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.to_item_id;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- 処理対象レコードが1件もなかった場合
      ir_masters_rec.is_info_flg := FALSE;
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
  END chk_lot;
--
  /**********************************************************************************
   * Procedure Name   : create_lot
   * Description      : ロット作成(A-7)
   ***********************************************************************************/
  PROCEDURE create_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_lot'; -- プログラム名
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
    lv_return_status VARCHAR2(2);     -- リターンステータス
    ln_message_count NUMBER;          -- メッセージカウント
    lv_msg_date      VARCHAR2(10000); -- メッセージ
    lb_return_status BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_lot_rec     GMIGAPI.LOT_REC_TYP;
    lr_ic_lots_cpg ic_lots_cpg%ROWTYPE;
    lr_lot_mst     ic_lots_mst%ROWTYPE;
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
    lb_return_status := GMIGUTL.SETUP(FND_GLOBAL.USER_NAME()); -- CREATE_LOT API_VERSION補助(必須)
--
        -- ロット情報の取得
    SELECT lot_desc,          -- 摘要
           ilm.attribute1,    -- 製造年月日
           ilm.attribute2,    -- 固有記号
           ilm.attribute3,    -- 賞味期限
           ilm.attribute4,    -- 納入日(初回)
           ilm.attribute5,    -- 納入日(最終)
           ilm.attribute6,    -- 在庫入数
           ilm.attribute7,    -- 在庫単価
           ilm.attribute8,    -- 取引先
           ilm.attribute9,    -- 仕入形態
           ilm.attribute10,   -- 茶期区分
           ilm.attribute11,   -- 年度
           ilm.attribute12,   -- 産地
           ilm.attribute13,   -- タイプ
           ilm.attribute14,   -- ランク１
           ilm.attribute15,   -- ランク２
           ilm.attribute16,   -- 生産伝票区分
           ilm.attribute17,   -- ラインNo
           ilm.attribute18,   -- 摘要
           ilm.attribute19,   -- ランク３
           ilm.attribute20,   -- 原料製造工場
           ilm.attribute21,   -- 原料製造元ロット番号
           ilm.attribute22,   -- 検査依頼No
           ilm.attribute23,   -- ロットステータス
           ilm.attribute24,   -- 作成区分
           ilm.attribute25,   -- 属性25
           ilm.attribute26,   -- 属性26
           ilm.attribute27,   -- 属性27
           ilm.attribute28,   -- 属性28
           ilm.attribute29,   -- 属性29
           ilm.attribute30    -- 属性30
    INTO   ir_masters_rec.lot_desc,
           ir_masters_rec.lot_attribute1,
           ir_masters_rec.lot_attribute2,
           ir_masters_rec.lot_attribute3,
           ir_masters_rec.lot_attribute4,
           ir_masters_rec.lot_attribute5,
           ir_masters_rec.lot_attribute6,
           ir_masters_rec.lot_attribute7,
           ir_masters_rec.lot_attribute8,
           ir_masters_rec.lot_attribute9,
           ir_masters_rec.lot_attribute10,
           ir_masters_rec.lot_attribute11,
           ir_masters_rec.lot_attribute12,
           ir_masters_rec.lot_attribute13,
           ir_masters_rec.lot_attribute14,
           ir_masters_rec.lot_attribute15,
           ir_masters_rec.lot_attribute16,
           ir_masters_rec.lot_attribute17,
           ir_masters_rec.lot_attribute18,
           ir_masters_rec.lot_attribute19,
           ir_masters_rec.lot_attribute20,
           ir_masters_rec.lot_attribute21,
           ir_masters_rec.lot_attribute22,
           ir_masters_rec.lot_attribute23,
           ir_masters_rec.lot_attribute24,
           ir_masters_rec.lot_attribute25,
           ir_masters_rec.lot_attribute26,
           ir_masters_rec.lot_attribute27,
           ir_masters_rec.lot_attribute28,
           ir_masters_rec.lot_attribute29,
           ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPMロットマスタ
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.from_item_id;
--
    -- ======================================
    -- ロットを新規に作成
    -- ======================================
    lr_lot_rec.item_no          := ir_masters_rec.to_item_no;      -- 1.品目No
    lr_lot_rec.lot_no           := ir_masters_rec.lot_no;          -- 2.ロットNo
    lr_lot_rec.attribute1       := ir_masters_rec.lot_attribute1;  -- 3.属性1
    lr_lot_rec.attribute2       := ir_masters_rec.lot_attribute2;  -- 3.属性2
    lr_lot_rec.attribute3       := ir_masters_rec.lot_attribute3;  -- 3.属性3
    lr_lot_rec.attribute4       := ir_masters_rec.lot_attribute4;  -- 3.属性4
    lr_lot_rec.attribute5       := ir_masters_rec.lot_attribute5;  -- 3.属性5
    lr_lot_rec.attribute6       := ir_masters_rec.lot_attribute6;  -- 3.属性6
    lr_lot_rec.attribute7       := ir_masters_rec.lot_attribute7;  -- 3.属性7
    lr_lot_rec.attribute8       := ir_masters_rec.lot_attribute8;  -- 3.属性8
    lr_lot_rec.attribute9       := ir_masters_rec.lot_attribute9;  -- 3.属性9
    lr_lot_rec.attribute10      := ir_masters_rec.lot_attribute10; -- 3.属性10
    lr_lot_rec.attribute11      := ir_masters_rec.lot_attribute11; -- 3.属性11
    lr_lot_rec.attribute12      := ir_masters_rec.lot_attribute12; -- 3.属性12
    lr_lot_rec.attribute13      := ir_masters_rec.lot_attribute13; -- 3.属性13
    lr_lot_rec.attribute14      := ir_masters_rec.lot_attribute14; -- 3.属性14
    lr_lot_rec.attribute15      := ir_masters_rec.lot_attribute15; -- 3.属性15
    lr_lot_rec.attribute16      := ir_masters_rec.lot_attribute16; -- 3.属性16
    lr_lot_rec.attribute17      := ir_masters_rec.lot_attribute17; -- 3.属性17
    lr_lot_rec.attribute18      := ir_masters_rec.lot_attribute18; -- 3.属性18
    lr_lot_rec.attribute19      := ir_masters_rec.lot_attribute19; -- 3.属性19
    lr_lot_rec.attribute20      := ir_masters_rec.lot_attribute20; -- 3.属性20
    lr_lot_rec.attribute21      := ir_masters_rec.lot_attribute21; -- 3.属性21
    lr_lot_rec.attribute22      := ir_masters_rec.lot_attribute22; -- 3.属性22
    lr_lot_rec.attribute23      := ir_masters_rec.lot_attribute23; -- 3.属性23
    lr_lot_rec.attribute24      := ir_masters_rec.lot_attribute24; -- 3.属性24
    lr_lot_rec.attribute25      := ir_masters_rec.lot_attribute25; -- 3.属性25
    lr_lot_rec.attribute26      := ir_masters_rec.lot_attribute26; -- 3.属性26
    lr_lot_rec.attribute27      := ir_masters_rec.lot_attribute27; -- 3.属性27
    lr_lot_rec.attribute28      := ir_masters_rec.lot_attribute28; -- 3.属性28
    lr_lot_rec.attribute29      := ir_masters_rec.lot_attribute29; -- 3.属性29
    lr_lot_rec.attribute30      := ir_masters_rec.lot_attribute30; -- 3.属性30
    lr_lot_rec.sublot_no        := NULL;
    lr_lot_rec.lot_desc         :=  ir_masters_rec.lot_desc;       -- 摘要
    lr_lot_rec.user_name        := FND_GLOBAL.USER_NAME;
    lr_lot_rec.lot_created      := SYSDATE;
--
    --ロット作成API
    GMIPAPI.CREATE_LOT(
                       P_API_VERSION      => 3.0,                        -- APIバージョン番号
                       P_INIT_MSG_LIST    => FND_API.G_FALSE,            -- メッセージ初期化フラグ
                       P_COMMIT           => FND_API.G_TRUE,            -- 自動コミットフラグ
                       P_VALIDATION_LEVEL => FND_API.G_VALID_LEVEL_FULL, -- 検証レベル
                       P_LOT_REC          => lr_lot_rec,
                       X_IC_LOTS_MST_ROW  => lr_lot_mst,
                       X_IC_LOTS_CPG_ROW  => lr_ic_lots_cpg,
                       X_RETURN_STATUS    => lv_return_status,           -- プロセス終了ステータス
                       X_MSG_COUNT        => ln_message_count,           -- エラーメッセージ件数
                       X_MSG_DATA         => lv_msg_date                 -- エラーメッセージ
                      );
--
    -- ロット作成処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_create_lot);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 振替先ロットIDの取得
    -- ==================================
    SELECT ilm.lot_id                  -- ロットID
    INTO   ir_masters_rec.to_lot_id
    FROM   ic_lots_mst ilm             -- OPMロットマスタ
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.to_item_id;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END create_lot;
--
--add start 1.3
  /**********************************************************************************
   * Procedure Name   : get_validity_rule_id
   * Description      : 妥当性ルールID
   ***********************************************************************************/
  PROCEDURE get_validity_rule_id(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_validity_rule_id'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    ln_recipe_id gmd_recipes_b.recipe_id%TYPE;
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
    -- レシピIDの取得
    SELECT greb.recipe_id              -- レシピID
    INTO   ln_recipe_id
    FROM   gmd_recipes_b             greb, -- レシピマスタ
           gmd_routings_b            grob  -- 工順マスタ
    WHERE  greb.formula_id      = ir_masters_rec.formula_id
    AND    greb.routing_id      = grob.routing_id
    AND    grob.routing_no      = ir_masters_rec.routing_no
    AND    grob.routing_class   = (SELECT grb.routing_class
                                   FROM   gmd_routings_b        grb,  -- 工順マスタ
                                          gmd_routing_class_b   grcb, -- 工順区分マスタ
                                          gmd_routing_class_tl  grct  -- 工順区分マスタ日本語
                                   WHERE  grb.routing_class       = grcb.routing_class
                                   AND    grcb.routing_class      = grct.routing_class
                                   AND    grct.language           = 'JA'
                                   AND    grct.routing_class_desc = gv_prf_dummy_val
                                   AND    grb.routing_id = ir_masters_rec.routing_id);
--
    -- 妥当性ルールIDの取得
    SELECT grvr.recipe_validity_rule_id
    INTO   ir_masters_rec.recipe_validity_rule_id
    FROM   gmd_recipe_validity_rules grvr   -- レシピ妥当性ルールマスタ
    WHERE  grvr.recipe_id = ln_recipe_id;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_validity_rule_id;
--add end 1.3
  /**********************************************************************************
   * Procedure Name   : create_batch
   * Description      : バッチ作成(A-8)
   ***********************************************************************************/
  PROCEDURE create_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 1.処理対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_batch'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_return_status VARCHAR2(2);     -- リターンステータス
    ln_message_count NUMBER;          -- メッセージカウント
    lv_message_list  VARCHAR2(200);   -- メッセージリスト
--
    -- *** ローカル・レコード ***
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE;     -- 生産バッチヘッダ(入力)
    lr_out_batch_hrd GME_BATCH_HEADER%ROWTYPE;     -- 生産バッチヘッダ(出力)
    lr_batch_dtl     GME_MATERIAL_DETAILS%ROWTYPE; -- 生産原材料詳細
    lt_unalloc_mtl   GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
--
    l_data           VARCHAR2(2000);
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
    lr_in_batch_hdr.plant_code              := ir_masters_rec.orgn_code;    -- 1.組織コード(必須)
    lr_in_batch_hdr.formula_id              := ir_masters_rec.formula_id;   -- 2.フォーミュラID
    lr_in_batch_hdr.routing_id              := ir_masters_rec.routing_id;   -- 3.工順ID
    lr_in_batch_hdr.actual_start_date       := ir_masters_rec.item_sysdate; -- 4.実績開始日
    lr_in_batch_hdr.actual_cmplt_date       := ir_masters_rec.item_sysdate; -- 5.実績終了日
    lr_in_batch_hdr.attribute6              := ir_masters_rec.remarks;      -- 6.摘要
    lr_in_batch_hdr.attribute7              := ir_masters_rec.item_chg_aim; -- 7.品目振替目的
    lr_batch_dtl.item_id                    := ir_masters_rec.from_item_id; -- 8.品目ID
    lr_batch_dtl.wip_plan_qty               := ir_masters_rec.qty;          -- 9.予定数量
    lr_batch_dtl.original_qty               := ir_masters_rec.qty;          -- 10.実績数量
    lr_batch_dtl.item_um                    := ir_masters_rec.from_item_um; -- 11.単位１
    lr_in_batch_hdr.batch_type              := gn_bat_type_batch;           -- 12.バッチタイプ
    lr_in_batch_hdr.wip_whse_code           := ir_masters_rec.whse_code;    -- 13.倉庫コード
    -- 13.妥当性ルールID
--add start 1.3
    --妥当性ルールIDがセットされていない場合
    IF (ir_masters_rec.recipe_validity_rule_id IS NULL) THEN
      get_validity_rule_id(ir_masters_rec,  -- 1.チェック対象レコード
                           lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                           lv_retcode,      -- リターン・コード             --# 固定 #
                           lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--add end 1.3
    lr_in_batch_hdr.recipe_validity_rule_id := ir_masters_rec.recipe_validity_rule_id;
--
    -- ======================================
    -- バッチ作成API
    -- ======================================
    GME_API_PUB.CREATE_BATCH(
                       P_API_VERSION          => GME_API_PUB.API_VERSION,
                       P_VALIDATION_LEVEL     => GME_API_PUB.MAX_ERRORS,
                       P_INIT_MSG_LIST        => FALSE,
                       P_COMMIT               => FALSE,
                       P_BATCH_HEADER         => lr_in_batch_hdr,             -- 必須
                       P_BATCH_SIZE           => ir_masters_rec.qty,          -- 必須
                       P_BATCH_SIZE_UOM       => ir_masters_rec.from_item_um, -- 必須
                       P_CREATION_MODE        => 'PRODUCT',                   -- 必須
                       P_RECIPE_ID            => NULL,                        -- レシピID
                       P_RECIPE_NO            => NULL,                        -- レシピNo
                       P_RECIPE_VERSION       => NULL,                        -- レシピバージョン
                       P_PRODUCT_NO           => NULL,                        -- 工順No
                       P_PRODUCT_ID           => NULL,                        -- 工順ID
                       P_IGNORE_QTY_BELOW_CAP => TRUE,
                       P_IGNORE_SHORTAGES     => TRUE,                        -- 必須
                       P_USE_SHOP_CAL         => NULL,
                       P_CONTIGUITY_OVERRIDE  => 1,
                       X_BATCH_HEADER         => lr_out_batch_hrd,            -- 必須
                       X_MESSAGE_COUNT        => ln_message_count,
                       X_MESSAGE_LIST         => lv_message_list,
                       X_RETURN_STATUS        => lv_return_status,
                       X_UNALLOCATED_MATERIAL => lt_unalloc_mtl               -- 非割当情報テーブル
    );
--
    -- バッチ作成処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
--
      -- add 2008/05/20
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
      IF (ln_message_count > 0) THEN
        FOR i IN 1..ln_message_count LOOP
          -- 次のメッセージの取得
          l_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_data = '|| l_data);
        END LOOP;
      END IF;
      -- add 2008/05/20
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_create_bat);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- バッチIDの格納
    ir_masters_rec.batch_id := lr_out_batch_hrd.batch_id;
    -- バッチNoの格納
    ir_masters_rec.batch_no := lr_out_batch_hrd.batch_no;
--
    -- 振替元品目の生産原料詳細IDの取得
    SELECT gmd.material_detail_id                -- 生産原料詳細ID
    INTO   ir_masters_rec.from_material_detail_id
    FROM   gme_material_details gmd              -- 生産原料詳細
    WHERE  gmd.batch_id = ir_masters_rec.batch_id
    AND    gmd.item_id  = ir_masters_rec.from_item_id;
--
    -- 振替先品目の生産原料詳細IDの取得
    SELECT gmd.material_detail_id                -- 生産原料詳細ID
    INTO   ir_masters_rec.to_material_detail_id
    FROM   gme_material_details gmd              -- 生産原料詳細
    WHERE  gmd.batch_id = ir_masters_rec.batch_id
    AND    gmd.item_id  = ir_masters_rec.to_item_id;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END create_batch;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_assign
   * Description      : 入力ロット割当(A-9)
   ***********************************************************************************/
  PROCEDURE input_lot_assign(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 1.処理対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_assign'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_return_status VARCHAR2(2);     -- リターンステータス
    ln_message_count NUMBER;          -- メッセージカウント
    lv_msg_date      VARCHAR2(10000); -- メッセージ
    lv_message_list  VARCHAR2(200);   -- メッセージリスト
--
    -- *** ローカル・レコード ***
    lr_material_datail GME_MATERIAL_DETAILS%ROWTYPE;
    lr_tran_row_in     GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_tran_row_out    GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_def_tran_row    GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_in_batch_hdr    GME_BATCH_HEADER%ROWTYPE;
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
    lr_tran_row_in.item_id            := ir_masters_rec.from_item_id;            -- 1.品目ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.倉庫コード
    lr_tran_row_in.lot_id             := ir_masters_rec.from_lot_id;             -- 3.ロットID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.保管場所
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- バッチID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.文書タイプ
    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- 実績日
    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.数量１
    lr_tran_row_in.trans_um           := ir_masters_rec.from_item_um;            -- 7.単位１
    lr_tran_row_in.completed_ind      := 0;                                      -- 完了フラグ
    lr_tran_row_in.material_detail_id := ir_masters_rec.from_material_detail_id; -- 生産原料詳細ID
    lr_in_batch_hdr.batch_id          := ir_masters_rec.batch_id;                -- バッチID
--
    -- ======================================
    -- ロット割当API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
                                       P_API_VERSION      => GME_API_PUB.API_VERSION,
                                       P_VALIDATION_LEVEL => GME_API_PUB.MAX_ERRORS,
                                       P_INIT_MSG_LIST    => FALSE,
                                       P_COMMIT           => FALSE,
                                       P_TRAN_ROW         => lr_tran_row_in,
                                       P_LOT_NO           => NULL,
                                       P_SUBLOT_NO        => NULL,
                                       P_CREATE_LOT       => FALSE,
                                       P_IGNORE_SHORTAGE  => TRUE,
                                       P_SCALE_PHANTOM    => FALSE,
                                       X_MATERIAL_DETAIL  => lr_material_datail,
                                       X_TRAN_ROW         => lr_tran_row_out,
                                       X_DEF_TRAN_ROW     => lr_def_tran_row,
                                       X_MESSAGE_COUNT    => ln_message_count,
                                       X_MESSAGE_LIST     => lv_message_list,
                                       X_RETURN_STATUS    => lv_return_status
                                      );
--
    -- 入力ロット割当処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_input_lot);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
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
  END input_lot_assign;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_assign
   * Description      : 出力ロット割当(A-11)
   ***********************************************************************************/
  PROCEDURE output_lot_assign(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 1.処理対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_assign'; -- プログラム名
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
    lv_return_status VARCHAR2(2);     -- リターンステータス
    ln_message_count NUMBER;          -- メッセージカウント
    lv_msg_date      VARCHAR2(10000); -- メッセージ
    lv_message_list  VARCHAR2(200);   -- メッセージリスト
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail  GME_MATERIAL_DETAILS%ROWTYPE;
    lr_tran_row_in      GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_tran_row_out     GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_def_tran_row     GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_in_batch_hdr     GME_BATCH_HEADER%ROWTYPE;
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
    lr_tran_row_in.item_id            := ir_masters_rec.to_item_id;              -- 1.品目ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.倉庫コード
    lr_tran_row_in.lot_id             := ir_masters_rec.to_lot_id;               -- 3.ロットID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.保管場所
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- バッチID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.文書タイプ
    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- 実績日
    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.数量１
    lr_tran_row_in.trans_um           := ir_masters_rec.to_item_um;              -- 7.単位１
    lr_tran_row_in.completed_ind      := 0;                                      -- 完了フラグ
    lr_tran_row_in.material_detail_id := ir_masters_rec.to_material_detail_id;   -- 生産原料詳細ID
    lr_in_batch_hdr.batch_id          := ir_masters_rec.batch_id;                -- バッチID
--
    -- ======================================
    -- ロット割当API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
                                       P_API_VERSION      => GME_API_PUB.API_VERSION,
                                       P_VALIDATION_LEVEL => GME_API_PUB.MAX_ERRORS,
                                       P_INIT_MSG_LIST    => FALSE,
                                       P_COMMIT           => FALSE,
                                       P_TRAN_ROW         => lr_tran_row_in,
                                       P_LOT_NO           => ir_masters_rec.lot_no,
                                       P_SUBLOT_NO        => NULL,
                                       P_CREATE_LOT       => FALSE,
                                       P_IGNORE_SHORTAGE  => TRUE,
                                       P_SCALE_PHANTOM    => FALSE,
                                       X_MATERIAL_DETAIL  => lr_material_detail,
                                       X_TRAN_ROW         => lr_tran_row_out,
                                       X_DEF_TRAN_ROW     => lr_def_tran_row,
                                       X_MESSAGE_COUNT    => ln_message_count,
                                       X_MESSAGE_LIST     => lv_message_list,
                                       X_RETURN_STATUS    => lv_return_status
                                      );
--
    -- 出力ロット割当処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_output_lot);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
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
  END output_lot_assign;
--
  /**********************************************************************************
   * Procedure Name   : cmpt_batch
   * Description      : バッチ完了(A-12)
   ***********************************************************************************/
  PROCEDURE cmpt_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cmpt_batch'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_return_status VARCHAR2(2);     -- リターンステータス
    ln_message_count NUMBER;          -- メッセージカウント
    lv_message_list  VARCHAR2(200);   -- メッセージリスト
--
    -- *** ローカル・レコード ***
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE; -- 生産バッチヘッダ(入力)
    lr_out_batch_hrd GME_BATCH_HEADER%ROWTYPE; -- 生産バッチヘッダ(出力)
    lt_unalloc_mtl   GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
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
    lr_in_batch_hdr.batch_status      := 1;                           -- 1.ステータス
    lr_in_batch_hdr.actual_start_date := ir_masters_rec.item_sysdate; -- 2.実績開始日
    lr_in_batch_hdr.actual_cmplt_date := ir_masters_rec.item_sysdate; -- 3.実績終了日
    lr_in_batch_hdr.batch_id          := ir_masters_rec.batch_id;     -- バッチID

--
    -- ======================================
    -- バッチ完了API
    -- ======================================
    GME_API_PUB.CERTIFY_BATCH(
                              P_API_VERSION           => GME_API_PUB.API_VERSION,
                              P_VALIDATION_LEVEL      => GME_API_PUB.MAX_ERRORS,
                              P_INIT_MSG_LIST         => FALSE,
                              P_COMMIT                => FALSE,
                              X_MESSAGE_COUNT         => ln_message_count,
                              X_MESSAGE_LIST          => lv_message_list,
                              X_RETURN_STATUS         => lv_return_status,
                              P_DEL_INCOMPLETE_MANUAL => FALSE,
                              P_IGNORE_SHORTAGES      => TRUE,
                              P_BATCH_HEADER          => lr_in_batch_hdr,
                              X_BATCH_HEADER          => lr_out_batch_hrd,
                              X_UNALLOCATED_MATERIAL  => lt_unalloc_mtl
                             );
--
    -- バッチ完了処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_cmpt_bat);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
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
  END cmpt_batch;
--
  /**********************************************************************************
   * Procedure Name   : close_batch
   * Description      : バッチクローズ(A-13)
   ***********************************************************************************/
  PROCEDURE close_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_batch'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_return_status VARCHAR2(2);     -- リターンステータス
    ln_message_count NUMBER;          -- メッセージカウント
    lv_message_list  VARCHAR2(200);   -- メッセージリスト
--
    -- *** ローカル・レコード ***
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE; -- 生産バッチヘッダ(入力)
    lr_out_batch_hrd GME_BATCH_HEADER%ROWTYPE; -- 生産バッチヘッダ(出力)
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
    lr_in_batch_hdr.batch_status     := 2;                           -- 1.ステータス
    lr_in_batch_hdr.batch_close_date := ir_masters_rec.item_sysdate; -- 2.実績開始日
    lr_in_batch_hdr.batch_id         := ir_masters_rec.batch_id;     -- バッチID
--
    -- ======================================
    -- バッチクローズAPI
    -- ======================================
    GME_API_PUB.CLOSE_BATCH(
                            P_API_VERSION      => GME_API_PUB.API_VERSION,
                            P_VALIDATION_LEVEL => GME_API_PUB.MAX_ERRORS,
                            P_INIT_MSG_LIST    => FALSE,
                            P_COMMIT           => FALSE,
                            X_MESSAGE_COUNT    => ln_message_count,
                            X_MESSAGE_LIST     => lv_message_list,
                            X_RETURN_STATUS    => lv_return_status,
                            P_BATCH_HEADER     => lr_in_batch_hdr,
                            X_BATCH_HEADER     => lr_out_batch_hrd
                           );
--
    -- バッチクローズ処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_close_bat);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
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
  END close_batch;
--
  /**********************************************************************************
   * Procedure Name   : save_batch
   * Description      : バッチ保存
   ***********************************************************************************/
  PROCEDURE save_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.処理対象レコード
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'save_batch'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_return_status VARCHAR2(2);     -- リターンステータス
--
    -- *** ローカル・レコード ***
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE;     -- 生産バッチヘッダ(入力)
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
    lr_in_batch_hdr.batch_id         := ir_masters_rec.batch_id;     -- バッチID
--
    -- ======================================
    -- バッチ保存API
    -- ======================================
    GME_API_PUB.SAVE_BATCH(
                           P_BATCH_HEADER  => lr_in_batch_hdr,
                           X_RETURN_STATUS => lv_return_status,
                           P_COMMIT        => FALSE
                          );
--
    -- バッチ保存処理が成功でない場合
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_save_bat);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
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
  END save_batch;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_inv_loc_code   IN          VARCHAR2, --  1.保管倉庫コード
    iv_from_item_no   IN          VARCHAR2, --  2.振替元品目No
    iv_lot_no         IN          VARCHAR2, --  3.振替元ロットNo
    iv_to_item_no     IN          VARCHAR2, --  4.振替先品目No
--2008.4.28 Y.Kawano modify start
--    in_quantity       IN          NUMBER,   --  5.数量
    iv_quantity       IN          VARCHAR2, --  5.数量
--2008.4.28 Y.Kawano modify end
    id_sysdate        IN          DATE,     --  6.品目振替実績日
    iv_remarks        IN          VARCHAR2, --  7.摘要
    iv_item_chg_aim   IN          VARCHAR2, --  8.品目振替目的
    ov_errbuf         OUT  NOCOPY VARCHAR2, --  エラー・メッセージ           --# 固定 #
    ov_retcode        OUT  NOCOPY VARCHAR2, --  リターン・コード             --# 固定 #
    ov_errmsg         OUT  NOCOPY VARCHAR2) --  ユーザー・エラー・メッセージ --# 固定 #
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lr_masters_rec masters_rec;                  -- 処理対象データ格納レコード
--
    lv_normal_msg VARCHAR2(1000);                 -- 正常終了時メッセージ格納変数
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
    -- グローバルレコード変数にパラメータをセット
    lr_masters_rec.inventory_location_code := iv_inv_loc_code; -- 保管倉庫コード
    lr_masters_rec.from_item_no            := iv_from_item_no; -- 振替元品目No
    lr_masters_rec.lot_no                  := iv_lot_no;       -- ロットNo
    lr_masters_rec.to_item_no              := iv_to_item_no;   -- 振替先品目No
--2008.4.28 Y.Kawano modify start
--    lr_masters_rec.qty                     := in_quantity;     -- 数量
    lr_masters_rec.qty                     := TO_NUMBER(iv_quantity);
                                                               -- 数量
--2008.4.28 Y.Kawano modify end
    lr_masters_rec.item_sysdate            := id_sysdate;      -- 品目振替実績日
    lr_masters_rec.remarks                 := iv_remarks;      -- 摘要
    lr_masters_rec.item_chg_aim            := iv_item_chg_aim; -- 品目振替目的
--
    -- 処理件数の設定
    gn_target_cnt := 1;
--
    -- ===============================
    -- 初期処理
    -- ===============================
    init_proc(lr_masters_rec, -- 1.処理対象レコード
              lv_errbuf,      -- エラー・メッセージ           --# 固定 #
              lv_retcode,     -- リターン・コード             --# 固定 #
              lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- パラメータチェック(A-1)
    -- ===============================
    chk_param(lr_masters_rec,  -- 1.チェック対象レコード
              lv_errbuf,       -- エラー・メッセージ           --# 固定 #
              lv_retcode,      -- リターン・コード             --# 固定 #
              lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- データセット処理
    -- ====================================
    set_masters_rec(lr_masters_rec, -- 1.処理対象レコード
                    lv_errbuf,      -- エラー・メッセージ           --# 固定 #
                    lv_retcode,     -- リターン・コード             --# 固定 #
                    lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- フォーミュラ有無チェック(A-2)
    -- ===============================
    chk_formula(lr_masters_rec,  -- 1.チェック対象レコード
                lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                lv_retcode,      -- リターン・コード             --# 固定 #
                lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
--
    -- フォーミュラが存在しない場合
    ELSIF (NOT(lr_masters_rec.is_info_flg)) THEN
--
      -- ===============================
      -- フォーミュラ登録(A-3)
      -- ===============================
      ins_formula(lr_masters_rec,  -- 1.処理対象レコード
                  lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                  lv_retcode,      -- リターン・コード             --# 固定 #
                  lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- レシピ有無チェック(A-4)
    -- ===============================
    chk_recipe(lr_masters_rec,
               lv_errbuf,  -- エラー・メッセージ           --# 固定 #
               lv_retcode, -- リターン・コード             --# 固定 #
               lv_errmsg); -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
--
    -- レシピの工順が設定されていない場合
    ELSIF (NOT(lr_masters_rec.is_info_flg)) THEN
      -- ===============================
      -- レシピ更新
      -- ===============================
      upd_recipe(lr_masters_rec,
                 lv_errbuf,  -- エラー・メッセージ           --# 固定 #
                 lv_retcode, -- リターン・コード             --# 固定 #
                 lv_errmsg); -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- ロット有無チェック(A-6)
    -- ===============================
    chk_lot(lr_masters_rec,  -- 1.チェック対象レコード
            lv_errbuf,       -- エラー・メッセージ           --# 固定 #
            lv_retcode,      -- リターン・コード             --# 固定 #
            lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
--
    -- ロットが存在しない場合
    ELSIF (NOT(lr_masters_rec.is_info_flg)) THEN
--
      -- ===============================
      -- ロット作成(A-7)
      -- ===============================
      create_lot(lr_masters_rec,  -- 1.処理対象レコード
                 lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                 lv_retcode,      -- リターン・コード             --# 固定 #
                 lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- バッチ作成(A-8)
    -- ===============================
    create_batch(lr_masters_rec,  -- 1.処理対象レコード
                 lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                 lv_retcode,      -- リターン・コード             --# 固定 #
                 lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 入力ロット割当(A-9)
    -- ===============================
    input_lot_assign(lr_masters_rec,  -- 1.処理対象レコード
                     lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                     lv_retcode,      -- リターン・コード             --# 固定 #
                     lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 出力ロット割当(A-11)
    -- ===============================
    output_lot_assign(lr_masters_rec,  -- 1.処理対象レコード
                      lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                      lv_retcode,      -- リターン・コード             --# 固定 #
                      lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- バッチ完了(A-12)
    -- ===============================
    cmpt_batch(lr_masters_rec,  -- 1.処理対象レコード
               lv_errbuf,       -- エラー・メッセージ           --# 固定 #
               lv_retcode,      -- リターン・コード             --# 固定 #
               lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- バッチクローズ(A-13)
    -- ===============================
    close_batch(lr_masters_rec,  -- 1.処理対象レコード
                lv_errbuf,       -- エラー・メッセージ           --# 固定 #
                lv_retcode,      -- リターン・コード             --# 固定 #
                lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- バッチ保存
    -- ===============================
    save_batch(lr_masters_rec,  -- 1.処理対象レコード
               lv_errbuf,       -- エラー・メッセージ           --# 固定 #
               lv_retcode,      -- リターン・コード             --# 固定 #
               lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 正常終了時出力
    -- ===============================
    -- 生産バッチNo
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_52,
                                              gv_tkn_value,   lr_masters_rec.batch_no);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
--
    -- 成功件数の設定
    gn_normal_cnt := 1;
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
--
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2, -- エラーメッセージ #固定#
    retcode         OUT NOCOPY VARCHAR2, -- エラーコード     #固定#
    iv_inv_loc_code IN         VARCHAR2, -- 1.保管倉庫コード
    iv_from_item_no IN         VARCHAR2, -- 2.振替元品目No
    iv_lot_no       IN         VARCHAR2, -- 3.ロットNo
    iv_to_item_no   IN         VARCHAR2, -- 4.振替先品目No
 --2008.4.28 Y.Kawano modify start
--   in_quantity     IN         NUMBER,   -- 5.数量
   iv_quantity     IN         VARCHAR2, -- 5.数量
--2008.4.28 Y.Kawano modify end
    iv_sysdate      IN         VARCHAR2, -- 6.品目振替実績日
    iv_remarks      IN         VARCHAR2, -- 7.摘要
    iv_item_chg_aim IN         VARCHAR2  -- 8.品目振替目的
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    lv_normal_msg VARCHAR2(5000); -- 必須出力メッセージ
    lv_aim_mean   VARCHAR2(20);   -- 品目振替目的 摘要
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
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    -- submainの呼び出し
    submain(
      iv_inv_loc_code,                                   --  1.保管倉庫ID
      iv_from_item_no,                                   --  2.振替元品目ID
      iv_lot_no,                                         --  3.ロットID
      iv_to_item_no,                                     --  4.振替先品目ID
--2008.4.28 Y.Kawano modify start
--      in_quantity,                                       --  5.数量
      iv_quantity,                                       --  5.数量
--2008.4.28 Y.Kawano modify end
      FND_DATE.STRING_TO_DATE(iv_sysdate, 'YYYY/MM/DD'), --  6.品目振替実績日
      iv_remarks,                                        --  7.摘要
      iv_item_chg_aim,                                   --  8.品目振替目的
      lv_errbuf,                         --  エラー・メッセージ           --# 固定 #
      lv_retcode,                        --  リターン・コード             --# 固定 #
      lv_errmsg);                        --  ユーザー・エラー・メッセージ --# 固定 #
--
    -- ===============================
    -- 必須出力項目
    -- ===============================
    -- パラメータ保管倉庫入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_45,
                                              gv_tkn_value,   iv_inv_loc_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ振替元品目入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_46,
                                              gv_tkn_value,   iv_from_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ振替元ロットNo入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_47,
                                              gv_tkn_value,   iv_lot_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ振替先品目入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_48,
                                              gv_tkn_value,   iv_to_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ数量入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_49,
                                              gv_tkn_value,   iv_quantity);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ品目振替実績日入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_50,
                                              gv_tkn_value,   iv_sysdate);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ摘要入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_51,
                                              gv_tkn_value,   iv_remarks);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ品目振替目的
    -- 品目振替目的の摘要を取得
    BEGIN
      SELECT flvv.meaning            -- 摘要
      INTO   lv_aim_mean
      FROM   xxcmn_lookup_values_v flvv  -- ルックアップVIEW
      WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
      AND    flvv.lookup_code  = iv_item_chg_aim;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- データ取得エラー
        -- 品目振替目的のコードを出力
        lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_57,
                                                  gv_tkn_value,   iv_item_chg_aim);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    END;
--
    -- データが取得できた場合は品目振替目的の摘要を出力
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_57,
                                              gv_tkn_value,   lv_aim_mean);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
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
END xxinv520001c;
/
