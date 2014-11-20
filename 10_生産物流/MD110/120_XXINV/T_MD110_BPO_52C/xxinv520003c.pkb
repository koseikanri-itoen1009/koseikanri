create or replace PACKAGE BODY xxinv520003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv520003c(body)
 * Description      : 品目振替
 * MD.050           : 品目振替 T_MD050_BPO_520
 * MD.070           : 品目振替 T_MD070_BPO_52C
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              初期処理                              (C-0)
 *  chk_param_new          必須チェック(新規)                    (C-1-1)
 *  chk_param_upd          必須チェック(更新・削除)              (C-1-2)
 *  chk_routing            工順有無チェック                      (C-2)
 *  chk_formula            フォーミュラ有無チェック              (C-3)
 *  ins_formula            フォーミュラ登録                      (C-4)
 *  chk_recipe             レシピ有無チェック                    (C-5)
 *  ins_recipe             レシピ登録                            (C-6)
 *  chk_validity_rule      妥当性ルール有無チェック              (C-37) -- 2009/06/02 Add 本番障害#1517
 *  ins_validity_rule      妥当性ルール登録                      (C-38) -- 2009/06/02 Add 本番障害#1517
 *  chk_lot                ロット有無チェック                    (C-7)
 *  update_lot             ロット更新                            (C-8-1)
 *  create_lot             ロット作成                            (C-8-2)
 *  create_batch           バッチ作成                            (C-9)
 *  input_lot_ins          入力ロット割当追加                    (C-10)
 *  output_lot_ins         出力ロット割当追加                    (C-11)
 *  cmpt_batch             バッチ完了                            (C-12)
 *  close_batch            バッチクローズ                        (C-13)
 *  save_batch             バッチ保存                            (C-14)
 *  cancel_batch           バッチ取消                            (C-15)
 *  reschedule_batch       バッチ再スケジュール                  (C-16)
 *  input_lot_upd          入力ロット割当更新                    (C-17)
 *  output_lot_upd         出力ロット割当更新                    (C-18)
 *  input_lot_del          入力ロット割当削除                    (C-19)
 *  output_lot_del         出力ロット割当削除                    (C-20)
 *  get_validity_rule_id   妥当性ルールID取得                    (C-21) -- 2009/06/02 Del 本番障害#1517 C-37で取得するため
 *  chk_mst_data           マスタ存在チェック                    (C-22)
 *  chk_close_period       在庫クローズチェック                  (C-23)
 *  chk_qty_over_plan      引当可能数超過チェック(予定)          (C-24)
 *  chk_qty_over_actual    引当可能数超過チェック(実績)          (C-25)
 *  chk_minus_qty          マイナス在庫チェック                  (C-37)
 *  get_batch_data         バッチデータ取得                      (C-26)
 *  get_item_data          品目データ取得                        (C-27)
 *  chk_and_ins_formula    フォーミュラ有無チェック 登録処理     (C-28)
 *  chk_and_ins_recipe     レシピ有無チェック 登録処理           (C-29)
 *  chk_and_ins_rule       妥当性ルール有無チェック 登録処理     (C-39) -- 2009/06/02 Add 本番障害#1517
 *  chk_and_ins_to_lot     振替先ロット有無チェック 登録処理     (C-30)
 *  input_lot_upd_ind      入力ロット割当更新(完了)              (C-31)
 *  output_lot_upd_ind     出力ロット割当更新(完了)              (C-32)
 *  release_batch          リリースバッチ                        (C-33)
 *  chk_future_date        未来日チェック                        (C-34)
 *  chk_qty_short_plan     引当可能在庫不足チェック(予定)        (C-35)
 *  chk_location           保管倉庫チェック                      (C-36)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/11/11    1.0  Oracle 二瓶 大輔    初回作成
 *  2009/01/15    1.1  SCS    伊藤 ひとみ  指摘2,7対応
 *  2009/02/03    1.2  SCS    伊藤 ひとみ  本番障害#1113対応
 *  2009/03/03    1.3  SCS    椎名 昭圭    本番障害#1241,#1251対応
 *  2009/03/19    1.4  SCS    椎名 昭圭    本番障害#1308対応
 *  2009/06/02    1.5  SCS    伊藤 ひとみ  本番障害#1517対応
 *  2014/04/21    1.6  SCSK   池田 木綿子  E_EBSパッチ_00031 品目振替のESパッチ対応
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
-- 2009/03/03 v1.3 ADD START
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  api_expt               EXCEPTION;     -- API例外
  deadlock_detected      EXCEPTION;     -- デッドロックエラー
--
-- 2009/03/03 v1.3 ADD END
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_ret_sts_success    CONSTANT VARCHAR2(1)    := 'S';            -- 成功
  gv_pkg_name           CONSTANT VARCHAR2(100)  := 'xxinv520003c'; -- パッケージ名
  gv_msg_kbn_cmn        CONSTANT VARCHAR2(5)    := 'XXCMN';
  gv_msg_kbn_inv        CONSTANT VARCHAR2(5)    := 'XXINV';
  gv_yyyymmdd           CONSTANT VARCHAR2(100)  := 'YYYY/MM/DD';
--
  -- メッセージ番号
  gv_msg_52a_02         CONSTANT VARCHAR2(15)   := 'APP-XXCMN-10002'; -- プロファイル取得エラー
--
  gv_msg_52a_00         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10000'; -- APIエラー
  gv_msg_52a_03         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10003'; -- カレンダクローズメッセージ
  gv_msg_52a_11         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10011'; -- データ取得エラーメッセージ
  gv_msg_52a_15         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10015'; -- パラメータエラー
  gv_msg_52a_17         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10017'; -- パラメータ振替元ロットNoエラー
  gv_msg_52a_20         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10020'; -- パラメータ数量エラー
  gv_msg_xxinv_10066    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10066'; -- 未来日エラー
  gv_msg_52a_71         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10071'; -- パラメータ摘要サイズエラー
  gv_msg_52a_72         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10072'; -- 入力パラメータ必須エラー
-- 2009/02/03 H.Itou Add Start 本番障害#1113対応
  gv_msg_xxinv_10186    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10186'; -- 同一品目エラー
-- 2009/02/03 H.Itou Add End
--
  gv_msg_52a_77         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10177'; -- 品目振替_処理区分
  gv_msg_52a_45         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10145'; -- 品目振替_保管倉庫
  gv_msg_52a_46         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10146'; -- 品目振替_振替元品目
  gv_msg_52a_47         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10147'; -- 品目振替_振替元ロットNo
  gv_msg_52a_48         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10148'; -- 品目振替_振替先品目
  gv_msg_52a_49         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10149'; -- 品目振替_数量
  gv_msg_52a_50         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10150'; -- 品目振替_品目振替日
  gv_msg_52a_51         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10151'; -- 品目振替_摘要
  gv_msg_52a_57         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10157'; -- 品目振替_品目振替目的
  gv_msg_52a_52         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10152'; -- 品目振替_生産バッチNo
  gv_msg_52a_66         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10166'; -- ステータスエラー(フォーミュラ)
  gv_msg_52a_67         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10167'; -- ステータスエラー(レシピ)
  gv_msg_52a_69         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10169'; -- ステータスエラー(妥当性ルール)
  gv_msg_52a_78         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10178'; -- 工順未登録エラー
  gv_msg_52a_79         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10179'; -- フォーミュラ複数登録エラー
-- 2009/01/15 H.Itou Add Start 指摘2,7対応
  gv_msg_xxinv_10183    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10183'; -- 保管倉庫不一致エラーメッセージ
  gv_msg_xxinv_10184    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10184'; -- 引当可能在庫不足エラーメッセージ
  gv_msg_xxinv_10185    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10185'; -- 引当可能在庫数超過エラーメッセージ
-- 2009/01/15 H.Itou Add End
-- 2009/03/19 v1.4 ADD START
  gv_msg_xxinv_10188    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10188'; -- マイナス在庫チェックエラーメッセージ
-- 2009/03/19 v1.4 ADD END
--
  -- トークン
  gv_tkn_parameter      CONSTANT VARCHAR2(15)   := 'PARAMETER';
  gv_tkn_value          CONSTANT VARCHAR2(15)   := 'VALUE';
  gv_tkn_value1         CONSTANT VARCHAR2(15)   := 'VALUE1';
  gv_tkn_value2         CONSTANT VARCHAR2(15)   := 'VALUE2';
  gv_tkn_api_name       CONSTANT VARCHAR2(15)   := 'API_NAME';
  gv_tkn_err_msg        CONSTANT VARCHAR2(15)   := 'ERR_MSG';
  gv_tkn_ng_profile     CONSTANT VARCHAR2(15)   := 'NG_PROFILE';
  gv_tkn_formula        CONSTANT VARCHAR2(15)   := 'FORMULA_NO';
  gv_tkn_recipe         CONSTANT VARCHAR2(15)   := 'RECIPE_NO';
  gv_tkn_ship_date      CONSTANT VARCHAR2(15)   := 'SHIP_DATE';
-- 2009/01/15 H.Itou Add Start 指摘2対応
  gv_tkn_location       CONSTANT VARCHAR2(15)   := 'LOCATION';
  gv_tkn_item           CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_tkn_lot            CONSTANT VARCHAR2(15)   := 'LOT';
  gv_tkn_standard_date  CONSTANT VARCHAR2(15)   := 'STANDARD_DATE';
-- 2009/01/15 H.Itou Add End
--
  -- トークン値
  gv_tkn_inv_loc        CONSTANT VARCHAR2(20)   := '保管倉庫';
  gv_tkn_from_item      CONSTANT VARCHAR2(20)   := '振替元品目';
  gv_tkn_to_item        CONSTANT VARCHAR2(20)   := '振替先品目';
  gv_tkn_item_date      CONSTANT VARCHAR2(20)   := '品目振替日';
  gv_tkn_item_aim       CONSTANT VARCHAR2(20)   := '品目振替目的';
  gv_tkn_ins_formula    CONSTANT VARCHAR2(20)   := 'フォーミュラ登録';
  gv_tkn_ins_recipe     CONSTANT VARCHAR2(20)   := 'レシピ登録';
----Add 2014/04/21 1.6 Start
  gv_tkn_chk_formula    CONSTANT VARCHAR2(30)   := 'フォーミュラ有無チェック';
----Add 2014/04/21 1.6 End
-- 2009/06/02 H.Itou Add Start 本番障害#1517
  gv_tkn_ins_validity_rules CONSTANT VARCHAR2(20)   := '妥当性ルール登録';
-- 2009/06/02 H.Itou Add End
  gv_tkn_create_lot     CONSTANT VARCHAR2(20)   := 'ロット作成';
-- 2009/03/03 v1.3 ADD START
  gv_tkn_update_lot     CONSTANT VARCHAR2(20)   := 'ロット更新';
-- 2009/03/03 v1.3 ADD END
  gv_tkn_create_bat     CONSTANT VARCHAR2(20)   := 'バッチ作成';
  gv_tkn_input_lot_ins  CONSTANT VARCHAR2(20)   := '入力ロット割当追加';
  gv_tkn_output_lot_ins CONSTANT VARCHAR2(20)   := '出力ロット割当追加';
  gv_tkn_input_lot_upd  CONSTANT VARCHAR2(20)   := '入力ロット割当更新';
  gv_tkn_output_lot_upd CONSTANT VARCHAR2(20)   := '出力ロット割当更新';
  gv_tkn_input_lot_del  CONSTANT VARCHAR2(20)   := '入力ロット割当削除';
  gv_tkn_output_lot_del  CONSTANT VARCHAR2(20)   := '出力ロット割当削除';
  gv_tkn_input_lot_upd_ind  CONSTANT VARCHAR2(50)   := '入力ロット割当更新(完了)';
  gv_tkn_output_lot_upd_ind CONSTANT VARCHAR2(50)   := '出力ロット割当更新(完了)';
  gv_tkn_release_batch  CONSTANT VARCHAR2(50)   := 'リリースバッチ';
  gv_tkn_cmpt_bat       CONSTANT VARCHAR2(20)   := 'バッチ完了';
  gv_tkn_close_bat      CONSTANT VARCHAR2(20)   := 'バッチクローズ';
  gv_tkn_save_bat       CONSTANT VARCHAR2(20)   := 'バッチ保存';
  gv_tkn_cancel_bat     CONSTANT VARCHAR2(20)   := 'バッチ取消';
  gv_tkn_resche__bat    CONSTANT VARCHAR2(20)   := 'バッチ再スケジュール';
  gv_tkn_plan_batch_no  CONSTANT VARCHAR2(20)   := '生産バッチNo';
  gv_tkn_process_type   CONSTANT VARCHAR2(20)   := '処理区分';
  gv_tkn_lot_no         CONSTANT VARCHAR2(20)   := 'ロットNo';
  gv_tkn_qty            CONSTANT VARCHAR2(20)   := '数量';
  gv_tkn_start_date     CONSTANT VARCHAR2(50)   := 'XXINV:妥当性ルール開始日';
-- 2014/04/21 Y.Ikeda Add Start E_EBSパッチ_00031 品目振替のESパッチ対応
  gv_tkn_cost_alloc     CONSTANT VARCHAR2(50)   := 'XXINV:品目振替原価割当';
-- 2014/04/21 Y.Ikeda Add End
--
  -- ルックアップ
  gv_lt_item_tran_cls   CONSTANT VARCHAR2(30)   := 'XXINV_ITEM_TRANS_CLASS';
--
  -- プロファイル
  gv_pro_start_date     CONSTANT VARCHAR2(100)  := 'XXINV_VALID_RULE_DEFAULT_START_DATE'; -- XXINV:妥当性ルール開始日
-- 2014/04/21 Y.Ikeda Add Start E_EBSパッチ_00031 品目振替のESパッチ対応
  gv_item_trans_cost_alloc  CONSTANT VARCHAR2(100)  := 'XXINV_ITEM_TRANS_COST_ALLOC'; -- XXINV:品目振替原価割当
-- 2014/04/21 Y.Ikeda Add End
--
  -- 品目区分
  gv_material           CONSTANT VARCHAR2(1)    := '1';    -- 原料
  gv_half_material      CONSTANT VARCHAR2(1)    := '4';    -- 半製品
--
  -- フォーミュラ登録タイプ
  gv_record_type        CONSTANT VARCHAR2(1)    := 'I';    -- 挿入
  -- フォーミュラステータス
  gv_fml_sts_new        CONSTANT VARCHAR2(3)    := '100';  -- 新規
  gv_fml_sts_appr       CONSTANT VARCHAR2(3)    := '700';  -- 一般使用の承認
  gv_fml_sts_abo        CONSTANT VARCHAR2(4)    := '1000'; -- 廃止/アーカイブ済
  -- フォーミュラ・バージョン
  gn_fml_vers           CONSTANT NUMBER         := 1;
  -- レシピ・バージョン
  gn_rcp_vers           CONSTANT NUMBER         := 1;
  -- 工順区分
  gv_routing_class_70   CONSTANT VARCHAR2(2)    := '70';   -- 品目振替
--
  -- 明細タイプ
  gn_line_type_p        CONSTANT NUMBER         := 1;      -- 製品
  gn_line_type_i        CONSTANT NUMBER         := -1;     -- 原料
--
  gn_remarks_max        CONSTANT NUMBER         := 240;    -- 摘要チェック用最大バイト数
--
  gn_bat_type_batch     CONSTANT NUMBER         := 0;      -- 0:batch, 10:firm
--
  -- 文書タイプ
  gv_doc_type_code_prod CONSTANT VARCHAR2(2)    := '40';   -- 生産
--
  -- レコードタイプ
  gv_rec_type_code_plan CONSTANT VARCHAR2(2)    := '10';   -- 指示
--
  -- 予定区分
  gv_plan_type_4        CONSTANT VARCHAR2(2)    := '4';    --
--
  -- 工順No固定値
  gv_routing_no_hdr     CONSTANT VARCHAR2(2)    := '9';
--
  -- バッチステータス
  gn_batch_del          CONSTANT NUMBER         := -1;     -- 取消
  gn_batch_comp         CONSTANT NUMBER         := 4;      -- 完了
--
  -- 処理区分
  gv_plan_new           CONSTANT VARCHAR2(1)    := '1';    -- 予定
  gv_plan_change        CONSTANT VARCHAR2(1)    := '2';    -- 予定訂正
  gv_plan_cancel        CONSTANT VARCHAR2(1)    := '3';    -- 予定取消
  gv_actual             CONSTANT VARCHAR2(1)    := '4';    -- 実績(生産バッチNo指定時)
  gv_actual_new         CONSTANT VARCHAR2(1)    := '5';    -- 実績(生産バッチNo指定なし時)
--
-- 2009/03/03 v1.3 ADD START
  -- OPMロットマスタDFF更新APIバージョン
  gn_api_version        CONSTANT NUMBER(2,1)    := 1.0;
--
-- 2009/03/03 v1.3 ADD START
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_plan_batch_no               VARCHAR2(10);             -- 生産バッチNo(予定)
-- 2009/06/02 H.Itou Del Start 本番障害#1517
--  gd_start_date                  DATE;                     -- 妥当性ルール開始日
-- 2009/06/02 H.Itou Del End
-- 2014/04/21 Y.Ikeda Add Start E_EBSパッチ_00031 品目振替のESパッチ対応
  gt_item_trans_cost_alloc      fm_matl_dtl.cost_alloc%TYPE;    -- 品目振替原価割当
-- 2014/04/21 Y.Ikeda Add End
--
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
    -- フォーミュラマスタ
    formula_no              fm_form_mst_b.formula_no%TYPE     -- フォーミュラ番号
  , formula_type            fm_form_mst_b.formula_type%TYPE   -- フォーミュラタイプ
  , inactive_ind            fm_form_mst_b.inactive_ind%TYPE   -- (必須項目)
  , orgn_code               fm_form_mst_b.orgn_code%TYPE      -- 組織(プラント)コード
  , formula_status          fm_form_mst_b.formula_status%TYPE -- ステータス
  , formula_id              fm_form_mst_b.formula_id%TYPE     -- フォーミュラID
  , scale_type_hdr          fm_form_mst_b.scale_type%TYPE     -- スケーリング可
  , delete_mark             fm_form_mst_b.delete_mark%TYPE    -- (必須項目)
    -- フォーミュラ明細マスタ
  , formulaline_id          fm_matl_dtl.formulaline_id%TYPE   -- 明細ID
  , line_type               fm_matl_dtl.line_type%TYPE        -- 明細タイプ
  , line_no                 fm_matl_dtl.line_no%TYPE          -- 明細番号
  , qty                     fm_matl_dtl.qty%TYPE              -- 数量
  , release_type            fm_matl_dtl.release_type%TYPE     -- 収益タイプ/消費タイプ
  , scrap_factor            fm_matl_dtl.scrap_factor%TYPE     -- 廃棄係数
  , scale_type_dtl          fm_matl_dtl.scale_type%TYPE       -- スケールタイプ
  , phantom_type            fm_matl_dtl.phantom_type%TYPE     -- ファントムタイプ
  , rework_type             fm_matl_dtl.rework_type%TYPE      -- (必須項目)
    -- レシピマスタ
  , recipe_id               gmd_recipes_b.recipe_id%TYPE      -- レシピID
  , recipe_no               gmd_recipes_b.recipe_no%TYPE      -- レシピNo
  , recipe_version          gmd_recipes_b.recipe_version%TYPE -- レシピバージョン
  , recipe_status           gmd_recipes_b.recipe_status%TYPE  -- レシピステータス
  , calculate_step_quantity gmd_recipes_b.calculate_step_quantity%TYPE -- ステップ数量の計算
    -- レシピ妥当性ルールテーブル
  , recipe_validity_rule_id gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE -- 妥当性ルール
    -- 工順マスタ
  , routing_id              gmd_routings_b.routing_id%TYPE    -- 工順ID
  , routing_no              gmd_routings_b.routing_no%TYPE    -- 工順No
  , routing_version         gmd_routings_b.routing_vers%TYPE  -- 工順バージョン
-- 2009/06/02 H.Itou Add Start 本番障害#1517
  , effective_start_date    gmd_routings_b.effective_start_date%TYPE  -- 有効開始日
-- 2009/06/02 H.Itou Add End
    -- OPM保管倉庫マスタ
  , inventory_location_id   mtl_item_locations.inventory_location_id%TYPE -- 保管倉庫ID
  , inventory_location_code mtl_item_locations.segment1%TYPE              -- 保管倉庫コード
    -- OPM倉庫マスタ
  , whse_code               ic_whse_mst.whse_code%TYPE        -- 倉庫コード
    -- OPM品目マスタ
  , from_item_id            ic_item_mst_b.item_id%TYPE        -- 振替元品目ID
  , from_item_no            ic_item_mst_b.item_no%TYPE        -- 振替元品目No
  , from_item_um            ic_item_mst_b.item_um%TYPE        -- 振替元単位
  , to_item_id              ic_item_mst_b.item_id%TYPE        -- 振替先品目ID
  , to_item_no              ic_item_mst_b.item_no%TYPE        -- 振替先品目No
  , to_item_um              ic_item_mst_b.item_um%TYPE        -- 振替先単位
    -- OPMロットマスタ
  , from_lot_id             ic_lots_mst.lot_id%TYPE           -- 振替元ロットID
  , to_lot_id               ic_lots_mst.lot_id%TYPE           -- 振替先ロットID
  , lot_no                  ic_lots_mst.lot_no%TYPE           -- ロットNo
  , lot_desc                ic_lots_mst.lot_desc%TYPE         -- 摘要
  , lot_attribute1          ic_lots_mst.attribute1%TYPE       -- 製造年月日
  , lot_attribute2          ic_lots_mst.attribute2%TYPE       -- 固有記号
  , lot_attribute3          ic_lots_mst.attribute3%TYPE       -- 賞味期限
  , lot_attribute4          ic_lots_mst.attribute4%TYPE       -- 納入日(初回)
  , lot_attribute5          ic_lots_mst.attribute5%TYPE       -- 納入日(最終)
  , lot_attribute6          ic_lots_mst.attribute6%TYPE       -- 在庫入数
  , lot_attribute7          ic_lots_mst.attribute7%TYPE       -- 在庫単価
  , lot_attribute8          ic_lots_mst.attribute8%TYPE       -- 取引先
  , lot_attribute9          ic_lots_mst.attribute9%TYPE       -- 仕入形態
  , lot_attribute10         ic_lots_mst.attribute10%TYPE      -- 茶期区分
  , lot_attribute11         ic_lots_mst.attribute11%TYPE      -- 年度
  , lot_attribute12         ic_lots_mst.attribute12%TYPE      -- 産地
  , lot_attribute13         ic_lots_mst.attribute13%TYPE      -- タイプ
  , lot_attribute14         ic_lots_mst.attribute14%TYPE      -- ランク１
  , lot_attribute15         ic_lots_mst.attribute15%TYPE      -- ランク２
  , lot_attribute16         ic_lots_mst.attribute16%TYPE      -- 生産伝票区分
  , lot_attribute17         ic_lots_mst.attribute17%TYPE      -- ラインNo
  , lot_attribute18         ic_lots_mst.attribute18%TYPE      -- 摘要
  , lot_attribute19         ic_lots_mst.attribute19%TYPE      -- ランク３
  , lot_attribute20         ic_lots_mst.attribute20%TYPE      -- 原料製造工場
  , lot_attribute21         ic_lots_mst.attribute21%TYPE      -- 原料製造元ロット番号
  , lot_attribute22         ic_lots_mst.attribute22%TYPE      -- 検査依頼No
  , lot_attribute23         ic_lots_mst.attribute23%TYPE      -- ロットステータス
  , lot_attribute24         ic_lots_mst.attribute24%TYPE      -- 作成区分
  , lot_attribute25         ic_lots_mst.attribute25%TYPE      --
  , lot_attribute26         ic_lots_mst.attribute26%TYPE      --
  , lot_attribute27         ic_lots_mst.attribute27%TYPE      --
  , lot_attribute28         ic_lots_mst.attribute28%TYPE      --
  , lot_attribute29         ic_lots_mst.attribute29%TYPE      --
  , lot_attribute30         ic_lots_mst.attribute30%TYPE      --
--
    -- 生産バッチヘッダ
  , batch_id                gme_batch_header.batch_id%TYPE        -- バッチID
  , batch_no                gme_batch_header.batch_no%TYPE        -- バッチNo
  , plan_start_date         gme_batch_header.plan_start_date%TYPE -- 生産予定日
--
    -- 生産原料詳細
  , from_material_detail_id gme_material_details.material_detail_id%TYPE  -- 生産原料詳細ID(振替元)
  , to_material_detail_id   gme_material_details.material_detail_id%TYPE  -- 生産原料詳細ID(振替先)
--
    -- 保留在庫トランザクション
  , from_trans_id           ic_tran_pnd.trans_id%TYPE             -- トランザクションID(振替元)
  , to_trans_id             ic_tran_pnd.trans_id%TYPE             -- トランザクションID(振替先)
  , trans_qty               ic_tran_pnd.trans_qty%TYPE            -- トランザクション数量
--
    -- 移動ロット詳細
  , from_mov_lot_dtl_id     xxinv_mov_lot_details.mov_lot_dtl_id%TYPE -- 移動ロット詳細ID(振替元)
--
    -- 生産原料詳細アドオン
  , from_mtl_dtl_addon_id   xxwip_material_detail.mtl_detail_addon_id%TYPE  -- 生産原料詳細アドオンID(振替元)
--
  , item_sysdate            DATE                              -- 品目振替日
  , remarks                 VARCHAR2(240)                     -- 摘要
  , item_chg_aim            VARCHAR2(1)                       -- 品目振替目的
  , is_info_flg             BOOLEAN                           -- 情報有無フラグ
  , process_type            VARCHAR2(1)                       -- 処理区分
  , plan_batch_id           gme_batch_header.batch_id%TYPE    -- バッチID(予定)
  );
  gr_gme_batch_header  gme_batch_header%ROWTYPE;   -- 更新用生産バッチレコード
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE init_proc(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
-- 2009/06/02 H.Itou Del Start 本番障害#1517 妥当性ルール開始日は工順マスタの有効開始日。
--    -- ====================================
--    -- プロファイルオプション取得
--    -- ====================================
--    -- XXINV:妥当性ルール開始日
--    gd_start_date := TO_DATE(FND_PROFILE.VALUE(gv_pro_start_date), gv_yyyymmdd);
----
--    -- XXINV:妥当性ルール開始日がNULLの場合、エラー
--    IF (gd_start_date IS NULL) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn
--                                           ,gv_msg_52a_02
--                                           ,gv_tkn_ng_profile
--                                           ,gv_tkn_start_date);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- 2009/06/02 H.Itou Del End
--
    -- ====================================
    -- 工順コードをセット (固定値'9'+保管倉庫コード)
    -- ====================================
    ir_masters_rec.routing_no := gv_routing_no_hdr || ir_masters_rec.inventory_location_code;
--
    -- ====================================
    -- トランザクション数量初期化
    -- ====================================
    ir_masters_rec.trans_qty := 0;
--
-- 2014/04/21 Y.Ikeda Add Start E_EBSパッチ_00031 品目振替のESパッチ対応
    -- ====================================
    -- プロファイルオプション取得
    -- ====================================
    -- XXINV:品目振替原価割当
    gt_item_trans_cost_alloc := FND_PROFILE.VALUE(gv_item_trans_cost_alloc);
--
    -- XXINV:品目振替原価割当がNULLの場合、エラー
    IF (gt_item_trans_cost_alloc IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn
                                           ,gv_msg_52a_02
                                           ,gv_tkn_ng_profile
                                           ,gv_tkn_cost_alloc);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2014/04/21 Y.Ikeda Add End
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
   * Procedure Name   : chk_param_new
   * Description      : 必須チェック(新規)(C-1-1)
   ***********************************************************************************/
  PROCEDURE chk_param_new(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param_new'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==================================
    -- 保管倉庫コード必須チェック
    -- ==================================
    IF ( ir_masters_rec.inventory_location_code IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_inv_loc);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 振替元品目No必須チェック
    -- ==================================
    IF ( ir_masters_rec.from_item_no IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_from_item);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- ロットNo必須チェック
    -- ==================================
    IF ( ir_masters_rec.lot_no IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_lot_no);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 振替先品目No必須チェック
    -- ==================================
    IF ( ir_masters_rec.to_item_no IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_to_item);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 数量必須チェック
    -- ==================================
    IF ( ir_masters_rec.qty IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_qty);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 品目振替日必須チェック
    -- ==================================
    IF ( ir_masters_rec.item_sysdate IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_item_date);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 品目振替目的必須チェック
    -- ==================================
    IF ( ir_masters_rec.item_chg_aim IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_item_aim);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/03 H.Itou Add Start 本番障害#1113対応
    -- ==================================
    -- 同一品目チェック
    -- ==================================
    -- 振替元品目と振替先品目が同じ場合はエラー
    IF ( ir_masters_rec.from_item_no = ir_masters_rec.to_item_no ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10186);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
-- 2009/02/03 H.Itou Add End
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
  END chk_param_new;
--
  /**********************************************************************************
   * Procedure Name   : chk_param_upd
   * Description      : 必須チェック(更新・削除)(C-1-2)
   ***********************************************************************************/
  PROCEDURE chk_param_upd(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param_upd'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==================================
    -- 生産バッチNo(予定)の必須チェック
    -- ==================================
    IF ( ir_masters_rec.plan_batch_id IS NULL ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_plan_batch_no);
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
  END chk_param_upd;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_data
   * Description      : マスタ存在チェック(C-22)
   ***********************************************************************************/
  PROCEDURE chk_mst_data(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_mst_data'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==================================
    -- 保管倉庫存在チェック
    -- ==================================
    BEGIN
      -- ==================================
      -- プラントコード、保管倉庫ID、倉庫コードの取得
      -- ==================================
      SELECT xilv.orgn_code              orgn_code                  -- プラントコード
           , xilv.inventory_location_id  inventory_location_id      -- 保管倉庫ID
           , xilv.whse_code              whse_code                  -- 倉庫コード
      INTO   ir_masters_rec.orgn_code                               -- プラントコード
           , ir_masters_rec.inventory_location_id                   -- 保管倉庫ID
           , ir_masters_rec.whse_code                               -- 倉庫コード
      FROM   xxcmn_item_locations_v xilv                            -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = ir_masters_rec.inventory_location_code -- パラメータ.保管場所
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_inv_loc
                                            , gv_tkn_value
                                            , ir_masters_rec.inventory_location_code);
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 振替元品目存在チェック
    -- ==================================
    BEGIN
      -- ==================================
      -- 振替元Noより導出した情報の取得
      -- ==================================
      SELECT ximv.item_id             item_id   -- 品目ID
           , ximv.item_um             item_um   -- 単位
      INTO   ir_masters_rec.from_item_id        -- 品目ID(振替元)
           , ir_masters_rec.from_item_um        -- 単位(振替元)
      FROM   xxcmn_item_mst_v         ximv      -- OPM品目マスタ情報VIEW
           , xxcmn_item_categories5_v xicv      -- OPM品目カテゴリ情報VIEW5
      WHERE  xicv.item_id         = ximv.item_id
      AND    ximv.item_no         = ir_masters_rec.from_item_no
      AND    xicv.item_class_code IN (gv_material, gv_half_material) -- 原料、半製品
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_from_item
                                            , gv_tkn_value
                                            , ir_masters_rec.from_item_no);
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 振替元ロットNo存在チェック
    -- ==================================
    BEGIN
      -- ==================================
      -- 振替元ロットIDの取得
      -- ==================================
      SELECT ilm.lot_id  lot_id          -- ロットID
      INTO   ir_masters_rec.from_lot_id  -- ロットID(振替元)
      FROM   ic_lots_mst ilm             -- OPMロットマスタ
      WHERE  ilm.lot_no  = ir_masters_rec.lot_no
      AND    ilm.item_id = ir_masters_rec.from_item_id
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_17);
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 振替先品目存在チェック
    -- ==================================
    BEGIN
      -- ==================================
      -- 振替先品目Noより導出した情報の取得
      -- ==================================
      SELECT ximv.item_id             item_id   -- 品目ID
           , ximv.item_um             item_um   -- 単位
      INTO   ir_masters_rec.to_item_id          -- 品目ID(振替先)
           , ir_masters_rec.to_item_um          -- 単位(振替先)
      FROM   xxcmn_item_mst_v         ximv      -- OPM品目マスタ情報VIEW
           , xxcmn_item_categories5_v xicv      -- OPM品目カテゴリ情報VIEW5
      WHERE  xicv.item_id         = ximv.item_id
      AND    ximv.item_no         = ir_masters_rec.to_item_no
      AND    xicv.item_class_code IN (gv_material, gv_half_material) -- 原料、半製品
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_to_item
                                            , gv_tkn_value
                                            , ir_masters_rec.to_item_no);
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 摘要文字数チェック
    -- ==================================
    IF ( LENGTHB(ir_masters_rec.remarks) > gn_remarks_max ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_71);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- 品目振替目的存在チェック
    -- ==================================
    BEGIN
      -- クイックコードに存在しているかを確認
      SELECT flvv.lookup_code      lookup_code -- クイックコード
      INTO   ir_masters_rec.item_chg_aim
      FROM   xxcmn_lookup_values_v flvv        -- クイックコードVIEW
      WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
      AND    flvv.lookup_code  = ir_masters_rec.item_chg_aim
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージを出力
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_item_aim
                                            , gv_tkn_value
                                            , ir_masters_rec.item_chg_aim);
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
    END;--
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
  END chk_mst_data;
--
  /**********************************************************************************
   * Procedure Name   : get_batch_data
   * Description      : バッチデータ取得(C-26)
   ***********************************************************************************/
  PROCEDURE get_batch_data(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_batch_data'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      -- ==================================
      -- バッチNo、バッチID、生産予定日、保管倉庫コードの取得
      -- ==================================
      SELECT gbh.batch_no                batch_no               -- 生産バッチNo
           , gbh.batch_id                batch_id               -- バッチID
           , gbh.plan_start_date         plan_start_date        -- 生産予定日
           , xilv.inventory_location_id  inventory_location_id  -- 保管倉庫ID
           , grb.attribute9              location_code          -- 保管倉庫コード
           , xilv.orgn_code              orgn_code              -- プラントコード
           , xilv.whse_code              whse_code              -- 倉庫コード
      INTO   ir_masters_rec.batch_no                            -- 生産バッチNo
           , ir_masters_rec.batch_id                            -- バッチID
           , ir_masters_rec.plan_start_date                     -- 生産予定日
           , ir_masters_rec.inventory_location_id               -- 保管倉庫ID
           , ir_masters_rec.inventory_location_code             -- 保管倉庫コード
           , ir_masters_rec.orgn_code                           -- プラントコード
           , ir_masters_rec.whse_code                           -- 倉庫コード
      FROM   gme_batch_header        gbh                        -- 生産バッチヘッダ
           , gmd_routings_b          grb                        -- 工順マスタ
           , xxcmn_item_locations_v  xilv                       -- OPM保管場所情報VIEW
      WHERE  gbh.routing_id    = grb.routing_id                 -- 結合条件(生産バッチヘッダ = 工順マスタ)
      AND    grb.attribute9    = xilv.segment1                  -- 結合条件(生産バッチヘッダ = OPM保管場所情報VIEW)
      AND    grb.routing_class = gv_routing_class_70            -- 工順[70:品目振替]
      AND    gbh.batch_status  NOT IN (gn_batch_del , gn_batch_comp)     -- バッチステータスが-1：取消か、4：完了でないもの
      AND    gbh.batch_id      = ir_masters_rec.plan_batch_id   -- バッチID
      ;
      -- 生産バッチNoを保持
      gv_plan_batch_no := ir_masters_rec.batch_no;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_11);
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
    END;
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
  END get_batch_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_data
   * Description      : 品目データ取得(C-27)
   ***********************************************************************************/
  PROCEDURE get_item_data(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_data'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      -- ==================================
      -- 振替元品目の情報取得
      -- ==================================
      SELECT gmd.material_detail_id  from_material_detail_id  -- 生産原料詳細ID
           , itp.trans_id            from_trans_id            -- トランザクションID
           , itp.lot_id              from_lot_id              -- ロットID
           , ximv.item_id            from_item_id             -- 品目ID
           , ximv.item_no            from_item_no             -- 品目コード
           , ximv.item_um            from_item_um             -- 単位
      INTO   ir_masters_rec.from_material_detail_id           -- 生産原料詳細ID(振替元)
           , ir_masters_rec.from_trans_id                     -- トランザクションID(振替元)
           , ir_masters_rec.from_lot_id                       -- ロットID(振替元)
           , ir_masters_rec.from_item_id                      -- 品目ID(振替元)
           , ir_masters_rec.from_item_no                      -- 品目コード(振替元)
           , ir_masters_rec.from_item_um                      -- 単位(振替元)
      FROM   gme_material_details gmd                         -- 生産原料詳細
           , ic_tran_pnd          itp                         -- OPM保留在庫トランザクション
           , xxcmn_item_mst_v     ximv                        -- OPM品目情報VIEW
      WHERE  itp.line_id     = gmd.material_detail_id         -- 結合条件(生産原料詳細                = OPM保留在庫トランザクション)
      AND    gmd.item_id     = ximv.item_id                   -- 結合条件(生産原料詳細                = OPM品目情報VIEW)
      AND    itp.item_id     = ximv.item_id                   -- 結合条件(OPM保留在庫トランザクション = OPM品目情報VIEW)
      AND    gmd.batch_id    = ir_masters_rec.batch_id        -- パラメータ.バッチID
      AND    itp.doc_type    = 'PROD'                         --
      AND    itp.delete_mark = 0                              -- 削除済でない
      AND    itp.lot_id     <> 0                              -- DEFAULTLOTでない
      AND    itp.reverse_id  IS NULL                          --
      AND    itp.line_type   = gn_line_type_i                 -- ラインタイプが原料
      AND    gmd.line_type   = gn_line_type_i                 -- ラインタイプが原料
      ;
--
      -- ==================================
      -- 振替先品目の情報取得
      -- ==================================
      SELECT gmd.material_detail_id  to_material_detail_id    -- 生産原料詳細ID
           , itp.trans_id            to_trans_id              -- トランザクションID
           , itp.trans_qty           trans_qty                -- トランザクション数量
           , itp.lot_id              to_lot_id                -- ロットID
           , ilm.lot_no              lot_no                   -- ロットNo
           , ximv.item_id            to_item_id               -- 品目ID
           , ximv.item_no            to_item_no               -- 品目コード
           , ximv.item_um            to_item_um               -- 単位
      INTO   ir_masters_rec.to_material_detail_id             -- 生産原料詳細ID(振替先)
           , ir_masters_rec.to_trans_id                       -- トランザクションID(振替先)
           , ir_masters_rec.trans_qty                         -- トランザクション数量
           , ir_masters_rec.to_lot_id                         -- ロットID(振替先)
           , ir_masters_rec.lot_no                            -- ロットNo
           , ir_masters_rec.to_item_id                        -- 品目ID(振替先)
           , ir_masters_rec.to_item_no                        -- 品目コード(振替先)
           , ir_masters_rec.to_item_um                        -- 単位(振替先)
      FROM   gme_material_details gmd                         -- 生産原料詳細
           , ic_tran_pnd          itp                         -- OPM保留在庫トランザクション
           , xxcmn_item_mst_v     ximv                        -- OPM品目情報VIEW
           , ic_lots_mst          ilm                         -- OPMロットマスタ
      WHERE  itp.line_id     = gmd.material_detail_id         -- 結合条件(生産原料詳細                = OPM保留在庫トランザクション)
      AND    gmd.item_id     = ximv.item_id                   -- 結合条件(生産原料詳細                = OPM品目情報VIEW)
      AND    itp.item_id     = ximv.item_id                   -- 結合条件(OPM保留在庫トランザクション = OPM品目情報VIEW)
      AND    itp.item_id     = ilm.item_id                    -- 結合条件(OPM保留在庫トランザクション = OPMロットマスタ)
      AND    itp.lot_id      = ilm.lot_id                     -- 結合条件(OPM保留在庫トランザクション = OPMロットマスタ)
      AND    gmd.batch_id    = ir_masters_rec.batch_id        -- パラメータ.バッチID
      AND    itp.doc_type    = 'PROD'                         --
      AND    itp.delete_mark = 0                              -- 削除済でない
      AND    itp.lot_id     <> 0                              -- DEFAULTLOTでない
      AND    itp.reverse_id  IS NULL                          --
      AND    itp.line_type   = gn_line_type_p                 -- ラインタイプが製品
      AND    gmd.line_type   = gn_line_type_p                 -- ラインタイプが製品
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_11);
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
    END;
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
  END get_item_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_close_period
   * Description      : 在庫クローズチェック(C-23)
   ***********************************************************************************/
  PROCEDURE chk_close_period(
    id_date        IN            DATE        -- チェック
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_close_period'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 品目振替日が在庫カレンダーのオープンでない場合
    IF ( id_date <=
         TRUNC(LAST_DAY(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period(), 'YYYY/MM'))) ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_03
                                          , gv_tkn_err_msg
                                          , TO_CHAR(id_date, gv_yyyymmdd));
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
  END chk_close_period;
--
-- 2009/03/19 v1.4 UPDATE START
--  /**********************************************************************************
--   * Procedure Name   : chk_qty_over_actual
--   * Description      : 引当可能数超過チェック(実績)(C-25)
--   ***********************************************************************************/
--  PROCEDURE chk_qty_over_actual(
--    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
---- 2009/01/15 H.Itou Add Start 指摘8対応
--  , id_standard_date IN DATE                   -- 2.有効日付
--  , in_qty           IN NUMBER                 -- 3.実績数量
---- 2009/01/15 H.Itou Add End
--  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
--  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
--  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_qty_over_actual'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
----
--    -- *** ローカル変数 ***
--    ln_onhand_stk_qty  NUMBER;  -- 手持在庫数量格納用
--    ln_fin_stk_qty     NUMBER;  -- 引当済在庫数量格納用
--    ln_can_enc_qty     NUMBER;  -- 引当可能数
--    ln_lot_ship_qty    NUMBER;  -- 数量格納用<実績未計上の出荷依頼>
--    ln_lot_provide_qty NUMBER;  -- 数量格納用<実績未計上の支給指示>
--    ln_lot_inv_out_qty NUMBER;  -- 数量格納用<実績未計上の移動指示>
--    ln_lot_inv_in_qty  NUMBER;  -- 数量格納用<実績計上済の移動入庫実績>
--    ln_lot_produce_qty NUMBER;  -- 数量格納用<実績未計上の生産投入予定>
--    ln_lot_order_qty   NUMBER;  -- 数量格納用<実績未計上の相手先倉庫発注入庫予定>
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := gv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- 手持在庫数量の取得
--    ln_onhand_stk_qty := xxcmn_common_pkg.get_stock_qty(
--                                     ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
--                                   , ir_masters_rec.from_item_id              -- 2.品目ID
--                                   , ir_masters_rec.from_lot_id);             -- 3.ロットID
----
--    -- 数量の取得<実績未計上の出荷依頼>
--    xxcmn_common2_pkg.get_dem_lot_ship_qty(
--                                     ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
--                                   , ir_masters_rec.from_item_id              -- 2.品目ID
--                                   , ir_masters_rec.from_lot_id               -- 3.ロットID
---- 2009/01/15 H.Itou Mod Start 指摘8対応
----                                   , ir_masters_rec.item_sysdate              -- 4.有効日付
--                                   , id_standard_date                         -- 4.有効日付
---- 2009/01/15 H.Itou Mod End
--                                   , ln_lot_ship_qty                          -- 5.数量
--                                   , lv_errbuf     -- エラー・メッセージ           --# 固定 #
--                                   , lv_retcode    -- リターン・コード             --# 固定 #
--                                   , lv_errmsg);   -- ユーザー・エラー・メッセージ --# 固定 #
--    -- 数量の取得<実績未計上の支給指示>
--    xxcmn_common2_pkg.get_dem_lot_provide_qty(
--                                     ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
--                                   , ir_masters_rec.from_item_id              -- 2.品目ID
--                                   , ir_masters_rec.from_lot_id               -- 3.ロットID
---- 2009/01/15 H.Itou Mod Start 指摘8対応
----                                   , ir_masters_rec.item_sysdate              -- 4.有効日付
--                                   , id_standard_date                         -- 4.有効日付
---- 2009/01/15 H.Itou Mod End
--                                   , ln_lot_provide_qty                       -- 5.数量
--                                   , lv_errbuf     -- エラー・メッセージ           --# 固定 #
--                                   , lv_retcode    -- リターン・コード             --# 固定 #
--                                   , lv_errmsg);   -- ユーザー・エラー・メッセージ --# 固定 #
--    -- 数量の取得<実績未計上の移動指示>
--    xxcmn_common2_pkg.get_dem_lot_inv_out_qty(
--                                     ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
--                                   , ir_masters_rec.from_item_id              -- 2.品目ID
--                                   , ir_masters_rec.from_lot_id               -- 3.ロットID
---- 2009/01/15 H.Itou Mod Start 指摘8対応
----                                   , ir_masters_rec.item_sysdate              -- 4.有効日付
--                                   , id_standard_date                         -- 4.有効日付
---- 2009/01/15 H.Itou Mod End
--                                   , ln_lot_inv_out_qty                       -- 5.数量
--                                   , lv_errbuf     -- エラー・メッセージ           --# 固定 #
--                                   , lv_retcode    -- リターン・コード             --# 固定 #
--                                   , lv_errmsg);   -- ユーザー・エラー・メッセージ --# 固定 #
--    -- 数量の取得<実績計上済の移動入庫実績>
--    xxcmn_common2_pkg.get_dem_lot_inv_in_qty(
--                                     ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
--                                   , ir_masters_rec.from_item_id              -- 2.品目ID
--                                   , ir_masters_rec.from_lot_id               -- 3.ロットID
---- 2009/01/15 H.Itou Mod Start 指摘8対応
----                                   , ir_masters_rec.item_sysdate              -- 4.有効日付
--                                   , id_standard_date                         -- 4.有効日付
---- 2009/01/15 H.Itou Mod End
--                                   , ln_lot_inv_in_qty                        -- 5.数量
--                                   , lv_errbuf     -- エラー・メッセージ           --# 固定 #
--                                   , lv_retcode    -- リターン・コード             --# 固定 #
--                                   , lv_errmsg);   -- ユーザー・エラー・メッセージ --# 固定 #
--    -- 数量の取得<実績未計上の生産投入予定>
--    xxcmn_common2_pkg.get_dem_lot_produce_qty(
--                                     ir_masters_rec.inventory_location_code   -- 1.保管倉庫コード
--                                   , ir_masters_rec.from_item_id              -- 2.品目ID
--                                   , ir_masters_rec.from_lot_id               -- 3.ロットID
---- 2009/01/15 H.Itou Mod Start 指摘8対応
----                                   , ir_masters_rec.item_sysdate              -- 4.有効日付
--                                   , id_standard_date                         -- 4.有効日付
---- 2009/01/15 H.Itou Mod End
--                                   , ln_lot_produce_qty                       -- 5.数量
--                                   , lv_errbuf     -- エラー・メッセージ           --# 固定 #
--                                   , lv_retcode    -- リターン・コード             --# 固定 #
--                                   , lv_errmsg);   -- ユーザー・エラー・メッセージ --# 固定 #
--    -- 数量の取得<実績未計上の相手先倉庫発注入庫予定>
--    xxcmn_common2_pkg.get_dem_lot_order_qty(
--                                     ir_masters_rec.inventory_location_code   -- 1.保管倉庫コード
--                                   , ir_masters_rec.from_item_no              -- 2.品目コード
--                                   , ir_masters_rec.from_lot_id               -- 3.ロットID
---- 2009/01/15 H.Itou Mod Start 指摘8対応
----                                   , ir_masters_rec.item_sysdate              -- 4.有効日付
--                                   , id_standard_date                         -- 4.有効日付
---- 2009/01/15 H.Itou Mod End
--                                   , ln_lot_order_qty                         -- 5.数量
--                                   , lv_errbuf    -- エラー・メッセージ           --# 固定 #
--                                   , lv_retcode   -- リターン・コード             --# 固定 #
--                                   , lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
----
--    -- 引当済在庫数量の算出
--    ln_fin_stk_qty := ln_lot_ship_qty
--                    + ln_lot_provide_qty
--                    + ln_lot_inv_out_qty
--                    + ln_lot_inv_in_qty
--                    + ln_lot_produce_qty
--                    + ln_lot_order_qty;
----
--    -- 引当可能数の算出
--    ln_can_enc_qty := ln_onhand_stk_qty
--                    - ln_fin_stk_qty;
----
--    -- 引当可能数より大きい場合
---- 2009/01/15 H.Itou Mod Start 指摘8対応
----    IF ( ir_masters_rec.qty -ir_masters_rec.trans_qty > ln_can_enc_qty ) THEN
--    IF ( ln_can_enc_qty - in_qty < 0 ) THEN
---- 2009/01/15 H.Itou Mod End
--      -- エラーメッセージを取得
---- 2009/01/15 H.Itou Mod Start 指摘2対応
----      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
----                                          , gv_msg_52a_20);
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
--                                          , gv_msg_xxinv_10185
--                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
--                                          , gv_tkn_item          , ir_masters_rec.from_item_no
--                                          , gv_tkn_lot           , ir_masters_rec.lot_no
--                                          , gv_tkn_standard_date , TO_CHAR(id_standard_date, gv_yyyymmdd));
---- 2009/01/15 H.Itou Mod End
--      -- 共通関数例外ハンドラ
--      RAISE global_api_expt;
--    END IF;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := gv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
--      ov_retcode := gv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
--      ov_retcode := gv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END chk_qty_over_actual;
--
  /**********************************************************************************
   * Procedure Name   : chk_qty_over_actual
   * Description      : 引当可能数超過チェック(実績)(C-25)
   ***********************************************************************************/
  PROCEDURE chk_qty_over_actual(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , id_standard_date IN DATE                   -- 2.有効日付
  , in_qty           IN NUMBER                 -- 3.実績数量
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_qty_over_actual'; -- プログラム名
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
    ln_can_enc_qty     NUMBER;  -- 引当可能数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 引当可能数の算出
    ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_qty(
                         ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
                       , ir_masters_rec.from_item_id              -- 2.品目ID
                       , ir_masters_rec.from_lot_id               -- 3.ロットID
                       , id_standard_date);                       -- 4.有効日付
--
    -- 引当可能数より大きい場合
    IF ( ln_can_enc_qty < in_qty ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10185
                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
                                          , gv_tkn_item          , ir_masters_rec.from_item_no
                                          , gv_tkn_lot           , ir_masters_rec.lot_no
                                          , gv_tkn_standard_date , TO_CHAR(id_standard_date, gv_yyyymmdd));
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
  END chk_qty_over_actual;
--
  /**********************************************************************************
   * Procedure Name   : chk_minus_qty
   * Description      : マイナス在庫チェック(C-37)
   ***********************************************************************************/
  PROCEDURE chk_minus_qty(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , in_qty         IN NUMBER                 -- 2.数量
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_minus_qty'; -- プログラム名
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
    ln_onhand_stk_qty  NUMBER;  -- 手持在庫数量格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 手持在庫数量の取得
    ln_onhand_stk_qty := xxcmn_common_pkg.get_stock_qty(
                                     ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
                                   , ir_masters_rec.from_item_id              -- 2.品目ID
                                   , ir_masters_rec.from_lot_id);             -- 3.ロットID
--
--
    -- 手持在庫数量より大きい場合
    IF ( ln_onhand_stk_qty < in_qty ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10188
                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
                                          , gv_tkn_item          , ir_masters_rec.from_item_no
                                          , gv_tkn_lot           , ir_masters_rec.lot_no);
-- 2009/01/15 H.Itou Mod End
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
  END chk_minus_qty;
-- 2009/03/19 v1.4 UPDATE END
--
  /**********************************************************************************
   * Procedure Name   : chk_qty_over_plan
   * Description      : 引当可能数超過チェック(予定)(C-24)
   ***********************************************************************************/
  PROCEDURE chk_qty_over_plan(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
-- 2009/01/15 H.Itou Add Start 指摘2対応
  , id_standard_date         IN DATE                               -- 3.有効日付
  , in_before_qty            IN NUMBER                             -- 4.更新前数量
  , in_after_qty             IN NUMBER                             -- 5.登録数量
-- 2009/01/15 H.Itou Add End
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_qty_over_plan'; -- プログラム名
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
    ln_can_enc_qty     NUMBER;  -- 引当可能数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 有効日ベース引当可能数
    ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_in_time_qty(
                         ir_masters_rec.inventory_location_id     -- 1.保管倉庫ID
                       , ir_masters_rec.from_item_id              -- 2.品目ID
                       , ir_masters_rec.from_lot_id               -- 3.ロットID
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--                       , ir_masters_rec.item_sysdate);            -- 4.有効日付
                       , id_standard_date);                       -- 4.有効日付
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--
    -- 引当可能数より大きい場合
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    IF ( ir_masters_rec.qty - ir_masters_rec.trans_qty > ln_can_enc_qty ) THEN
    IF ( ln_can_enc_qty + in_before_qty - in_after_qty < 0) THEN
-- 2009/01/15 H.Itou Mod End
      -- エラーメッセージを取得
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
--                                          , gv_msg_52a_20);
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10185
                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
                                          , gv_tkn_item          , ir_masters_rec.from_item_no
                                          , gv_tkn_lot           , ir_masters_rec.lot_no
                                          , gv_tkn_standard_date , TO_CHAR(id_standard_date, gv_yyyymmdd));
-- 2009/01/15 H.Itou Mod End
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
  END chk_qty_over_plan;
--
  /**********************************************************************************
   * Procedure Name   : chk_routing
   * Description      : 工順有無チェック(C-2)
   ***********************************************************************************/
  PROCEDURE chk_routing(
    ir_masters_rec IN OUT NOCOPY masters_rec  -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_routing'; -- プログラム名
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
    -- ==================================
    -- 工順情報の取得
    -- ==================================
    SELECT  grv.routing_id             routing_id   -- 工順ID
          , grv.routing_vers           routing_vers -- 工順バージョン
-- 2009/06/02 H.Itou Add Start 本番障害#1517 妥当性ルール開始日は工順マスタの有効開始日。
          , grv.effective_start_date   effective_start_date -- 有効開始日
-- 2009/06/02 H.Itou Add End
    INTO    ir_masters_rec.routing_id               -- 工順ID
          , ir_masters_rec.routing_version          -- 工順バージョン
-- 2009/06/02 H.Itou Add Start 本番障害#1517 妥当性ルール開始日は工順マスタの有効開始日。
          , ir_masters_rec.effective_start_date
-- 2009/06/02 H.Itou Add End
    FROM    gmd_routings_vl            grv          -- 工順マスタVIEW
    WHERE   grv.routing_no     = ir_masters_rec.routing_no -- 工順No
    AND     grv.routing_status = gv_fml_sts_appr           -- 一般使用の承認
    AND     grv.routing_class  = gv_routing_class_70       -- 品目振替
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_78
                                           , gv_tkn_value
                                           , ir_masters_rec.routing_no);
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
  END chk_routing;
--
  /**********************************************************************************
   * Procedure Name   : chk_formula
   * Description      : フォーミュラ有無チェック(C-3)
   ***********************************************************************************/
  PROCEDURE chk_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_formula_status   fm_form_mst_b.formula_status%TYPE;
    lv_return_status    VARCHAR2(2);
    ln_message_count    NUMBER;
    lv_msg_date         VARCHAR2(2000);
    lv_msg_list         VARCHAR2(2000);
    l_data              VARCHAR2(2000);
--Add 2014/04/21 1.6 Start
    lt_cost_alloc       fm_matl_dtl.cost_alloc%TYPE;      -- 品目振替原価割当 
    lt_formula_no       fm_form_mst_b.formula_no%TYPE;    -- フォーミュラNo
    lt_formula_vers     fm_form_mst_b.formula_vers%TYPE;  -- フォーミュラバージョン
    lt_formulaline_id   fm_matl_dtl.formulaline_id%TYPE;  -- フォーミュラ詳細ID
    -- フォーミュラ詳細テーブル型変数
    lt_formula_upd_dtl_tbl gmd_formula_detail_pub.formula_update_dtl_tbl_type;
--Add 2014/04/21 1.6 End
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 情報有無フラグの初期化
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- 振替元品目のフォーミュラID有無チェック
    -- ======================================
--
    -- フォーミュラIDの取得
    SELECT ffmb.formula_id            formula_id     -- フォーミュラID
         , ffmb.formula_status        formula_status -- フォーミュラステータス
----Add 2014/04/21 1.6 Start
         , ffmb.formula_no            formula_no      -- フォーミュラNo
         , ffmb.formula_vers          formula_vers    -- フォーミュラVersion
         , fmd2.formulaline_id        formulaline_id  -- フォーミュラ詳細ID
         , fmd2.cost_alloc            cost_alloc_prod -- 原価割当（製品）
----Add 2014/04/21 1.6 End
    INTO   ir_masters_rec.formula_id                 -- フォーミュラID
         , lv_formula_status                         -- フォーミュラステータス
----Add 2014/04/21 1.6 Start
         , lt_formula_no                             -- フォーミュラNo
         , lt_formula_vers                           -- フォーミュラVersion
         , lt_formulaline_id                         -- フォーミュラ詳細ID
         , lt_cost_alloc                             -- 原価割当（製品）
----Add 2014/04/21 1.6 End
    FROM   fm_form_mst_b              ffmb           -- フォーミュラマスタ
         , fm_matl_dtl                fmd1           -- フォーミュラマスタ明細(振替元)
         , fm_matl_dtl                fmd2           -- フォーミュラマスタ明細(振替先)
    WHERE  ffmb.formula_id      = fmd1.formula_id    -- 結合条件(フォーミュラマスタ = フォーミュラマスタ明細(振替元))
    AND    ffmb.formula_id      = fmd2.formula_id    -- 結合条件(フォーミュラマスタ = フォーミュラマスタ明細(振替元))
    AND    fmd1.item_id         = ir_masters_rec.from_item_id -- 振替元の品目ID
    AND    fmd1.line_type       = gn_line_type_i              -- ラインタイプが原料
    AND    fmd2.item_id         = ir_masters_rec.to_item_id   -- 振替先の品目ID
    AND    fmd2.line_type       = gn_line_type_p              -- ラインタイプが製品
    AND    ffmb.formula_status <> gv_fml_sts_abo              -- ステータスが廃止でない
    AND    SUBSTRB(ffmb.formula_no, 9, 1)
                                = gv_routing_no_hdr           -- 品目振替用フォーミュラ
    AND    EXISTS ( SELECT 1                                  -- 原料→製品が1:1のフォーミュラ
                    FROM   fm_matl_dtl fmd
                    WHERE  fmd.formula_id = ffmb.formula_id
                    GROUP BY fmd.formula_id
                    HAVING COUNT(1) = 2 )
    ;
--
    -- ステータスが「一般使用の承認」の場合
    IF ( lv_formula_status = gv_fml_sts_appr ) THEN
      NULL;
    -- ステータスが「新規」の場合
    ELSIF ( lv_formula_status = gv_fml_sts_new ) THEN
      -- ステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0                       -- APIバージョン番号
          , p_init_msg_list  => TRUE                      -- メッセージ初期化フラグ
          , p_entity_name    => 'FORMULA'                 -- フォーミュラ名
          , p_entity_id      => ir_masters_rec.formula_id -- フォーミュラID
          , p_entity_no      => NULL                      -- 番号(NULL固定)
          , p_entity_version => NULL                      -- バージョン(NULL固定)
          , p_to_status      => gv_fml_sts_appr           -- ステータス変更値
          , p_ignore_flag    => FALSE                     --
          , x_message_count  => ln_message_count          -- エラーメッセージ件数
          , x_message_list   => lv_msg_list               -- エラーメッセージ
          , x_return_status  => lv_return_status          -- プロセス終了ステータス
            );
--
      -- ステータス変更処理が成功でない場合
      IF ( lv_return_status <> gv_ret_sts_success ) THEN
        -- エラーメッセージログ出力
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
         ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
         ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
        );
--
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_formula);
--
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
--
      -- ステータス変更処理が成功の場合
      ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
        -- 確定処理
        COMMIT;
      END IF;
--
    -- ステータスが上記以外の場合
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_66
                                          , gv_tkn_formula
                                          , ir_masters_rec.formula_no);
      RAISE global_api_expt;
    END IF;
----Add 2014/04/21 1.6 Start
--フォーミュラ詳細(製品).原価割当が0だったら、Profile値で更新する。
    IF NVL( lt_cost_alloc, 0 ) = 0 THEN
      --Update用変数設定
      --必須項目
      lt_formula_upd_dtl_tbl(1).formula_no     := lt_formula_no;      -- フォーミュラNo
      lt_formula_upd_dtl_tbl(1).formula_vers   := lt_formula_vers;    -- フォーミュラVersion
      lt_formula_upd_dtl_tbl(1).formulaline_id := lt_formulaline_id;  -- フォーミュラ詳細ID
      lt_formula_upd_dtl_tbl(1).user_id        := FND_GLOBAL.USER_ID; -- UserId
      --原価割当
      lt_formula_upd_dtl_tbl(1).cost_alloc  := gt_item_trans_cost_alloc; --Profileから取得した原価割当
  --
      --フォーミュラ詳細更新API呼出
      GMD_FORMULA_DETAIL_PUB.UPDATE_FORMULADETAIL(
         p_api_version        => 2.0                    --  p_api_version   IN NUMBER (現行,ESパッチ後とも2.0)
        ,p_init_msg_list      => FND_API.G_TRUE         -- ,p_init_msg_list      IN  VARCHAR2
        ,p_commit             => FND_API.G_FALSE        -- ,p_commit             IN  VARCHAR2 
        ,p_called_from_forms  => 'NO'                   -- ,p_called_from_forms  IN  VARCHAR2 := 'NO'
        ,x_return_status      => lv_return_status       -- ,x_return_status      OUT NOCOPY    VARCHAR2
        ,x_msg_count          => ln_message_count       -- ,x_msg_count          OUT NOCOPY    NUMBER
        ,x_msg_data           => lv_msg_list            -- ,x_msg_data           OUT NOCOPY    VARCHAR2
        ,p_formula_detail_tbl => lt_formula_upd_dtl_tbl -- ,p_formula_detail_tbl IN formula_update_dtl_tbl_type
      );
  --
      -- フォーミュラ詳細更新処理が成功でない場合
      IF ( lv_return_status <> gv_ret_sts_success ) THEN
        -- エラーメッセージログ出力
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
  --
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
         ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
         ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
        );
  --
        -- エラーメッセージを取得
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_chk_formula);
  --
        -- 共通関数例外ハンドラ
        RAISE global_api_expt;
  --
      -- フォーミュラ詳細更新処理が成功の場合
      ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
        -- 確定処理
        COMMIT;
      END IF;
    END IF;
--
----Add 2014/04/21 1.6 End
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- 処理対象レコードが1件もなかった場合
      ir_masters_rec.is_info_flg := FALSE;
--
    WHEN TOO_MANY_ROWS THEN   -- 処理対象レコードが複数あった場合
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_79
                                           , gv_tkn_value1
                                           , ir_masters_rec.from_item_no
                                           , gv_tkn_value2
                                           , ir_masters_rec.to_item_no);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
   * Description      : フォーミュラ登録(C-4)
   ***********************************************************************************/
  PROCEDURE ins_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_return_status      VARCHAR2(2);
    ln_message_count      NUMBER;
    lv_msg_date           VARCHAR2(2000);
    -- MODIFY_STATUS API用変数
    lv_msg_list           VARCHAR2(2000);
--
    -- フォーミュラテーブル型変数
    lt_formula_header_tbl gmd_formula_pub.formula_insert_hdr_tbl_type;
--
    l_data                VARCHAR2(2000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- フォーミュラNoの取得
    ir_masters_rec.formula_no := xxinv_common_pkg.xxinv_get_formula_no(ir_masters_rec.to_item_no);
    -- フォーミュラNoが取得できない場合
    IF ( ir_masters_rec.formula_no IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_11);
      RAISE global_api_expt;
    END IF;
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
    lt_formula_header_tbl(1).release_type   := 1;                         -- 収率タイプ(1:手動)
-- 2014/04/21 Y.Ikeda Add Start E_EBSパッチ_00031 品目振替のESパッチ対応
    lt_formula_header_tbl(1).cost_alloc     := gt_item_trans_cost_alloc;  -- 品目振替原価割当
-- 2014/04/21 Y.Ikeda Add End
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
    lt_formula_header_tbl(2).release_type   := 1;                           -- 収率タイプ(1:手動)
--
    -- フォーミュラ登録(EBS標準API)
    GMD_FORMULA_PUB.INSERT_FORMULA(
          p_api_version        => 1.0                   -- APIバージョン番号
        , p_init_msg_list      => FND_API.G_FALSE       -- メッセージ初期化フラグ
-- 2009/02/03 H.Itou Mod Start 本番障害#1113対応
--        , p_commit             => FND_API.G_TRUE        -- 自動コミットフラグ
        , p_commit             => FND_API.G_FALSE       -- 自動コミットフラグ
-- 2009/02/03 H.Itou Mod End
        , p_called_from_forms  => 'NO'
        , x_return_status      => lv_return_status      -- プロセス終了ステータス
        , x_msg_count          => ln_message_count      -- エラーメッセージ件数
        , x_msg_data           => lv_msg_date           -- エラーメッセージ
        , p_formula_header_tbl => lt_formula_header_tbl
        , p_allow_zero_ing_qty => 'FALSE'
          );
    -- 登録処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_ins_formula);
--
      RAISE global_api_expt;
--
    -- 登録処理が成功の場合
    ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
      -- フォーミュラIDの取得
      SELECT ffmb.formula_id   formula_id                  -- フォーミュラID
      INTO   ir_masters_rec.formula_id                     -- フォーミュラID
      FROM   fm_form_mst_b     ffmb                        -- フォーミュラマスタ
-- 2009/02/03 H.Itou Del Start 本番障害#1113対応
--           , fm_matl_dtl       fmd1                        -- フォーミュラマスタ明細(振替元)
--           , fm_matl_dtl       fmd2                        -- フォーミュラマスタ明細(振替先)
--      WHERE  ffmb.formula_id = fmd1.formula_id             -- 結合条件(フォーミュラマスタ = フォーミュラマスタ明細(振替元))
--      AND    ffmb.formula_id = fmd2.formula_id             -- 結合条件(フォーミュラマスタ = フォーミュラマスタ明細(振替先))
--      AND    fmd1.item_id    = ir_masters_rec.from_item_id -- 振替元の品目ID
--      AND    fmd2.item_id    = ir_masters_rec.to_item_id   -- 振替先の品目ID
-- 2009/02/03 H.Itou Del End
-- 2009/02/03 H.Itou Mod Start 本番障害#1113対応
      WHERE  ffmb.formula_no = ir_masters_rec.formula_no   -- フォーミュラNo
-- 2009/02/03 H.Itou Mod End
      ;
    END IF;
--
    -- ステータス変更(EBS標準API)
    GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0                       -- APIバージョン番号
          , p_init_msg_list  => TRUE                      -- メッセージ初期化フラグ
          , p_entity_name    => 'FORMULA'                 -- フォーミュラ名
          , p_entity_id      => ir_masters_rec.formula_id -- フォーミュラID
          , p_entity_no      => NULL                      -- 番号(NULL固定)
          , p_entity_version => NULL                      -- バージョン(NULL固定)
          , p_to_status      => gv_fml_sts_appr           -- ステータス変更値
          , p_ignore_flag    => FALSE                     --
          , x_message_count  => ln_message_count          -- エラーメッセージ件数
          , x_message_list   => lv_msg_list               -- エラーメッセージ
          , x_return_status  => lv_return_status          -- プロセス終了ステータス
            );
--
    -- ステータス変更処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_ins_formula);
      RAISE global_api_expt;
--
    -- ステータス変更処理が成功の場合
    ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
      -- 確定処理
      COMMIT;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
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
   * Description      : レシピ有無チェック(C-5)
   ***********************************************************************************/
  PROCEDURE chk_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_recipe_status                gmd_recipes_b.recipe_status%TYPE;
    lv_recipe_no                    gmd_recipes_b.recipe_no%TYPE;
    ln_recipe_validity_rule_id      gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE;
    lv_validity_rule_status         gmd_recipe_validity_rules.validity_rule_status%TYPE;
    lv_return_status                VARCHAR2(2);
    ln_message_count                NUMBER;
    lv_msg_date                     VARCHAR2(4000);
    lv_msg_list                     VARCHAR2(2000);
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 情報有無フラグの初期化
    ir_masters_rec.is_info_flg := TRUE;
--
    -- レシピIDの取得
    SELECT greb.recipe_id       recipe_id                 -- レシピID
         , greb.recipe_status   recipe_status             -- レシピステータス
         , greb.recipe_no       recipe_no                 -- レシピNo
    INTO   ir_masters_rec.recipe_id                       -- レシピID
         , lv_recipe_status                               -- レシピステータス
-- 2009/06/02 H.Itou Mod Start 本番障害#1517
--         , lv_recipe_no                                   -- レシピNo
         , ir_masters_rec.recipe_no                       -- レシピNo
-- 2009/06/02 H.Itou Mod End
    FROM   gmd_recipes_b        greb                      -- レシピマスタ
         , gmd_routings_b       grob                      -- 工順マスタ
    WHERE  greb.routing_id    = grob.routing_id           -- 結合条件(レシピマスタ = 工順マスタ)
    AND    greb.formula_id    = ir_masters_rec.formula_id -- フォーミュラID
    AND    grob.routing_no    = ir_masters_rec.routing_no -- 工順No
    AND    grob.routing_class = gv_routing_class_70       -- 工順70：品目振替
    ;
-- 2009/06/02 H.Itou Add Start 本番障害#1517
    -- ステータスが「一般使用の承認」の場合
    IF ( lv_recipe_status = gv_fml_sts_appr ) THEN
      NULL;
    -- ステータスが「新規」の場合
    ELSIF ( lv_recipe_status = gv_fml_sts_new ) THEN
      -- レシピステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0
          , p_init_msg_list  => TRUE
          , p_entity_name    => 'RECIPE'
          , p_entity_id      => ir_masters_rec.recipe_id
          , p_entity_no      => NULL            -- (NULL固定)
          , p_entity_version => NULL            -- (NULL固定)
          , p_to_status      => gv_fml_sts_appr
          , p_ignore_flag    => FALSE
          , x_message_count  => ln_message_count
          , x_message_list   => lv_msg_list
          , x_return_status  => lv_return_status
            );
--
      -- ステータス変更処理が成功でない場合
      IF ( lv_return_status <> gv_ret_sts_success ) THEN
        -- エラーメッセージログ出力
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
         ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
         ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
        );
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_recipe);
        RAISE global_api_expt;
--
      -- ステータス変更処理が成功の場合
      ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
        -- 確定処理
        COMMIT;
      END IF;
--
    -- ステータスが上記以外の場合
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_67
                                          , gv_tkn_recipe
                                          , ir_masters_rec.recipe_no);
      RAISE global_api_expt;
    END IF;
-- 2009/06/02 H.Itou Add End
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
  END chk_recipe;
--
  /**********************************************************************************
   * Procedure Name   : ins_recipe
   * Description      : レシピ登録(C-6)
   ***********************************************************************************/
  PROCEDURE ins_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_recipe'; -- プログラム名
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
    -- API用変数
    lv_return_status      VARCHAR2(2);
    ln_message_count      NUMBER;
    lv_msg_date           VARCHAR2(4000);
    -- MODIFY_STATUS API用変数
    lv_msg_list           VARCHAR2(2000);
--
    -- レシピテーブル型変数
    lt_recipe_hdr_tbl     gmd_recipe_header.recipe_tbl;
    lt_recipe_hdr_flex    gmd_recipe_header.recipe_flex;
    lt_recipe_vr_tbl      gmd_recipe_detail.recipe_vr_tbl;
    lt_recipe_vr_flex     gmd_recipe_detail.recipe_flex;
--
    l_data            VARCHAR2(2000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- レシピバージョンをセット
    ir_masters_rec.recipe_version := 1;  -- 固定値
    -- レシピNoの取得
    ir_masters_rec.recipe_no := xxinv_common_pkg.xxinv_get_recipe_no(ir_masters_rec.to_item_no);
    -- レシピNoが取得できない場合
    IF ( ir_masters_rec.recipe_no IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_11);
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- 登録情報をセット
    -- ===============================
--
    -- 所有者コード
    lt_recipe_hdr_tbl(1).owner_orgn_code    := ir_masters_rec.orgn_code;
    -- 作成組織コード
    lt_recipe_hdr_tbl(1).creation_orgn_code := ir_masters_rec.orgn_code;
    -- フォーミュラID
    lt_recipe_hdr_tbl(1).formula_id         := ir_masters_rec.formula_id;
    -- 工順ID
    lt_recipe_hdr_tbl(1).routing_id         := ir_masters_rec.routing_id;
    -- レシピバージョン
    lt_recipe_hdr_tbl(1).recipe_version     := ir_masters_rec.recipe_version;
    -- レシピNo
    lt_recipe_hdr_tbl(1).recipe_no          := ir_masters_rec.recipe_no;
    -- ステップ数量の計算
    lt_recipe_hdr_tbl(1).calculate_step_quantity := 0;
    -- 摘要
    lt_recipe_hdr_tbl(1).recipe_description := ir_masters_rec.recipe_no;
--
    -- レシピ登録(EBS標準API)
    GMD_RECIPE_HEADER.CREATE_RECIPE_HEADER(
            p_api_version        => 1.0                   -- APIバージョン番号
          , p_init_msg_list      => FND_API.G_FALSE       -- メッセージ初期化フラグ
          , p_commit             => FND_API.G_FALSE       -- 自動コミットフラグ
          , p_called_from_forms  => 'NO'                  --
          , x_return_status      => lv_return_status      -- プロセス終了ステータス
          , x_msg_count          => ln_message_count      -- エラーメッセージ件数
          , x_msg_data           => lv_msg_date           -- エラーメッセージ
          , p_recipe_header_tbl  => lt_recipe_hdr_tbl     --
          , p_recipe_header_flex => lt_recipe_hdr_flex    --
            );
    -- 登録処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_ins_recipe);
      RAISE global_api_expt;
--
    -- 登録処理が成功の場合
    ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
--
      -- レシピIDの取得
      SELECT greb.recipe_id            recipe_id                -- レシピID
      INTO   ir_masters_rec.recipe_id                           -- レシピID
      FROM   gmd_recipes_b             greb                     -- レシピマスタ
           , gmd_routings_b            grob                     -- 工順マスタ
      WHERE  greb.routing_id      = grob.routing_id             -- 結合条件(レシピマスタ = 工順マスタ)
      AND    greb.formula_id      = ir_masters_rec.formula_id   -- フォーミュラID
      AND    grob.routing_no      = ir_masters_rec.routing_no   -- 工順No
      AND    grob.routing_class   = gv_routing_class_70         -- 工順70：品目振替
      ;
--
      -- レシピステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0
          , p_init_msg_list  => TRUE
          , p_entity_name    => 'RECIPE'
          , p_entity_id      => ir_masters_rec.recipe_id
          , p_entity_no      => NULL            -- (NULL固定)
          , p_entity_version => NULL            -- (NULL固定)
          , p_to_status      => gv_fml_sts_appr
          , p_ignore_flag    => FALSE
          , x_message_count  => ln_message_count
          , x_message_list   => lv_msg_list
          , x_return_status  => lv_return_status
            );
--
      -- ステータス変更処理が成功でない場合
      IF ( lv_return_status <> gv_ret_sts_success ) THEN
        -- エラーメッセージログ出力
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
         ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
         ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
        );
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_recipe);
        RAISE global_api_expt;
--
-- 2009/06/02 H.Itou Add Start 本番障害#1517 妥当性ルール登録をレシピ登録から分離
      -- ステータス変更処理が成功の場合
      ELSIF (lv_return_status = gv_ret_sts_success) THEN
        -- 確定処理
        COMMIT;
-- 2009/06/02 H.Itou Add End
--
      END IF;
-- 2009/06/02 H.Itou Del Start 本番障害#1517 妥当性ルール登録をレシピ登録から分離
----
--      -- レシピテーブル型変数初期化
--      lt_recipe_vr_tbl.DELETE;
--      -- ===============================
--      -- 登録情報をセット
--      -- ===============================
--      -- レシピ番号
--      lt_recipe_vr_tbl(1).recipe_no            := ir_masters_rec.recipe_no;
--      -- レシピバージョン
--      lt_recipe_vr_tbl(1).recipe_version       := ir_masters_rec.recipe_version;
--      -- 品目
--      lt_recipe_vr_tbl(1).item_id              := ir_masters_rec.to_item_id;
--      -- 標準数量
--      lt_recipe_vr_tbl(1).std_qty              := ir_masters_rec.qty;
--      -- 単位
--      lt_recipe_vr_tbl(1).item_um              := ir_masters_rec.to_item_um;
--      -- 妥当性ルールステータス
--      lt_recipe_vr_tbl(1).validity_rule_status := gv_fml_sts_new;
--      -- 有効日
--      lt_recipe_vr_tbl(1).start_date           := gd_start_date;
----
--      -- 妥当性ルール登録(EBS標準API)
--      GMD_RECIPE_DETAIL.CREATE_RECIPE_VR(
--            p_api_version        => 1.0                   -- APIバージョン番号
--          , p_init_msg_list      => FND_API.G_FALSE       -- メッセージ初期化フラグ
--          , p_commit             => FND_API.G_FALSE       -- 自動コミットフラグ
--          , p_called_from_forms  => 'NO'                  --
--          , x_return_status      => lv_return_status      -- プロセス終了ステータス
--          , x_msg_count          => ln_message_count      -- エラーメッセージ件数
--          , x_msg_data           => lv_msg_date           -- エラーメッセージ
--          , p_recipe_vr_tbl      => lt_recipe_vr_tbl      --
--          , p_recipe_vr_flex     => lt_recipe_vr_flex     --
--            );
----
--      -- 妥当性ルール登録が成功でない場合
--      IF ( lv_return_status <> gv_ret_sts_success ) THEN
--        -- エラーメッセージログ出力
--        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
----
--        xxcmn_common_pkg.put_api_log(
--          ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
--         ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
--         ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
--        );
----
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
--                                            , gv_msg_52a_00
--                                            , gv_tkn_api_name
--                                            , gv_tkn_ins_recipe);
----
--        RAISE global_api_expt;
----
--      -- 妥当性ルール登録が成功の場合
--      ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
----
--        -- 妥当性ルールIDの取得
--        SELECT grvr.recipe_validity_rule_id   recipe_validity_rule_id  -- 妥当性ルールID
--        INTO   ir_masters_rec.recipe_validity_rule_id                  -- 妥当性ルールID
--        FROM   gmd_recipe_validity_rules      grvr                     -- レシピ妥当性ルールマスタ
--        WHERE  grvr.recipe_id = ir_masters_rec.recipe_id               -- レシピID
--        ;
----
--        -- 妥当性ルールステータス変更(EBS標準API)
--        GMD_STATUS_PUB.MODIFY_STATUS(
--            p_api_version    => 1.0
--          , p_init_msg_list  => TRUE
--          , p_entity_name    => 'VALIDITY'
--          , p_entity_id      => ir_masters_rec.recipe_validity_rule_id
--          , p_entity_no      => NULL            -- (NULL固定)
--          , p_entity_version => NULL            -- (NULL固定)
--          , p_to_status      => gv_fml_sts_appr
--          , p_ignore_flag    => FALSE
--          , x_message_count  => ln_message_count
--          , x_message_list   => lv_msg_list
--          , x_return_status  => lv_return_status
--            );
----
--        -- ステータス変更処理が成功でない場合
--        IF (lv_return_status <> gv_ret_sts_success) THEN
--          -- エラーメッセージログ出力
--          FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
----
--          xxcmn_common_pkg.put_api_log(
--            ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
--           ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
--           ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
--          );
----
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
--                                              , gv_msg_52a_00
--                                              , gv_tkn_api_name
--                                              , gv_tkn_ins_recipe);
--          RAISE global_api_expt;
----
--        -- ステータス変更処理が成功の場合
--        ELSIF (lv_return_status = gv_ret_sts_success) THEN
--          -- 確定処理
--          COMMIT;
----
--        END IF;
--      END IF;
-- 2009/06/02 H.Itou Del End
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
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
  END ins_recipe;
--
-- 2009/06/02 H.Itou Add Start 本番障害#1517
  /**********************************************************************************
   * Procedure Name   : chk_validity_rule
   * Description      : 妥当性ルール有無チェック(C-37)
   ***********************************************************************************/
  PROCEDURE chk_validity_rule(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validity_rule'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    lv_status                       gmd_recipe_validity_rules.validity_rule_status%TYPE;
    lv_return_status                VARCHAR2(2);
    ln_message_count                NUMBER;
    lv_msg_date                     VARCHAR2(4000);
    lv_msg_list                     VARCHAR2(2000);
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 情報有無フラグの初期化
    ir_masters_rec.is_info_flg := TRUE;
--
    -- 妥当性ルールIDの取得
    SELECT grvr.recipe_validity_rule_id   recipe_validity_rule_id  -- 妥当性ルールID
         , grvr.validity_rule_status      recipe_status            -- 妥当性ルールステータス
    INTO   ir_masters_rec.recipe_validity_rule_id                  -- 妥当性ルールID
         , lv_status                                               -- 妥当性ルールステータス
    FROM   gmd_recipe_validity_rules      grvr                     -- レシピ妥当性ルールマスタ
    WHERE  grvr.recipe_id = ir_masters_rec.recipe_id               -- レシピID
    ;
--
    -- ステータスが「一般使用の承認」の場合
    IF ( lv_status = gv_fml_sts_appr ) THEN
      NULL;
    -- ステータスが「新規」の場合
    ELSIF ( lv_status = gv_fml_sts_new ) THEN
      -- 妥当性ルールステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
          p_api_version    => 1.0
        , p_init_msg_list  => TRUE
        , p_entity_name    => 'VALIDITY'
        , p_entity_id      => ir_masters_rec.recipe_validity_rule_id
        , p_entity_no      => NULL            -- (NULL固定)
        , p_entity_version => NULL            -- (NULL固定)
        , p_to_status      => gv_fml_sts_appr
        , p_ignore_flag    => FALSE
        , x_message_count  => ln_message_count
        , x_message_list   => lv_msg_list
        , x_return_status  => lv_return_status
          );
--
      -- ステータス変更処理が成功でない場合
      IF (lv_return_status <> gv_ret_sts_success) THEN
        -- エラーメッセージログ出力
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
         ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
         ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
        );
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_validity_rules);
        RAISE global_api_expt;
--
      -- ステータス変更処理が成功の場合
      ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
        -- 確定処理
        COMMIT;
      END IF;
--
    -- ステータスが上記以外の場合
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_69
                                          , gv_tkn_recipe
                                          , ir_masters_rec.recipe_no);
      RAISE global_api_expt;
    END IF;
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
  END chk_validity_rule;
--
  /**********************************************************************************
   * Procedure Name   : ins_validity_rule
   * Description      : 妥当性ルール登録(C-38)
   ***********************************************************************************/
  PROCEDURE ins_validity_rule(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_validity_rule'; -- プログラム名
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
    -- API用変数
    lv_return_status      VARCHAR2(2);
    ln_message_count      NUMBER;
    lv_msg_date           VARCHAR2(4000);
    -- MODIFY_STATUS API用変数
    lv_msg_list           VARCHAR2(2000);
--
    -- レシピテーブル型変数
    lt_recipe_hdr_tbl     gmd_recipe_header.recipe_tbl;
    lt_recipe_hdr_flex    gmd_recipe_header.recipe_flex;
    lt_recipe_vr_tbl      gmd_recipe_detail.recipe_vr_tbl;
    lt_recipe_vr_flex     gmd_recipe_detail.recipe_flex;
--
    l_data            VARCHAR2(2000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- レシピテーブル型変数初期化
    lt_recipe_vr_tbl.DELETE;
    -- ===============================
    -- 登録情報をセット
    -- ===============================
    -- レシピ番号
    lt_recipe_vr_tbl(1).recipe_no            := ir_masters_rec.recipe_no;
    -- レシピバージョン
    lt_recipe_vr_tbl(1).recipe_version       := 1;
    -- 品目
    lt_recipe_vr_tbl(1).item_id              := ir_masters_rec.to_item_id;
    -- 標準数量
    lt_recipe_vr_tbl(1).std_qty              := ir_masters_rec.qty;
    -- 単位
    lt_recipe_vr_tbl(1).item_um              := ir_masters_rec.to_item_um;
    -- 妥当性ルールステータス
    lt_recipe_vr_tbl(1).validity_rule_status := gv_fml_sts_new;
    -- 有効日
    lt_recipe_vr_tbl(1).start_date           := ir_masters_rec.effective_start_date;
--
    -- 妥当性ルール登録(EBS標準API)
    GMD_RECIPE_DETAIL.CREATE_RECIPE_VR(
          p_api_version        => 1.0                   -- APIバージョン番号
        , p_init_msg_list      => FND_API.G_FALSE       -- メッセージ初期化フラグ
        , p_commit             => FND_API.G_FALSE       -- 自動コミットフラグ
        , p_called_from_forms  => 'NO'                  --
        , x_return_status      => lv_return_status      -- プロセス終了ステータス
        , x_msg_count          => ln_message_count      -- エラーメッセージ件数
        , x_msg_data           => lv_msg_date           -- エラーメッセージ
        , p_recipe_vr_tbl      => lt_recipe_vr_tbl      --
        , p_recipe_vr_flex     => lt_recipe_vr_flex     --
          );
--
    -- 妥当性ルール登録が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_ins_validity_rules);
--
      RAISE global_api_expt;
--
    -- 妥当性ルール登録が成功の場合
    ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
--
      -- 妥当性ルールIDの取得
      SELECT grvr.recipe_validity_rule_id   recipe_validity_rule_id  -- 妥当性ルールID
      INTO   ir_masters_rec.recipe_validity_rule_id                  -- 妥当性ルールID
      FROM   gmd_recipe_validity_rules      grvr                     -- レシピ妥当性ルールマスタ
      WHERE  grvr.recipe_id = ir_masters_rec.recipe_id               -- レシピID
      ;
--
      -- 妥当性ルールステータス変更(EBS標準API)
      GMD_STATUS_PUB.MODIFY_STATUS(
          p_api_version    => 1.0
        , p_init_msg_list  => TRUE
        , p_entity_name    => 'VALIDITY'
        , p_entity_id      => ir_masters_rec.recipe_validity_rule_id
        , p_entity_no      => NULL            -- (NULL固定)
        , p_entity_version => NULL            -- (NULL固定)
        , p_to_status      => gv_fml_sts_appr
        , p_ignore_flag    => FALSE
        , x_message_count  => ln_message_count
        , x_message_list   => lv_msg_list
        , x_return_status  => lv_return_status
          );
--
      -- ステータス変更処理が成功でない場合
      IF (lv_return_status <> gv_ret_sts_success) THEN
        -- エラーメッセージログ出力
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
         ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
         ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
        );
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_validity_rules);
        RAISE global_api_expt;
--
      -- ステータス変更処理が成功の場合
      ELSIF (lv_return_status = gv_ret_sts_success) THEN
        -- 確定処理
        COMMIT;
--
      END IF;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
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
  END ins_validity_rule;
-- 2009/06/02 H.Itou Add End
  /**********************************************************************************
   * Procedure Name   : chk_lot
   * Description      : ロット有無チェック(C-7)
   ***********************************************************************************/
  PROCEDURE chk_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.チェック対象レコード
  , it_lot_no       IN            ic_lots_mst.lot_no %TYPE -- 2.ロットNo
  , it_item_id      IN            ic_lots_mst.item_id%TYPE -- 3.品目ID
  , it_lot_id       OUT    NOCOPY ic_lots_mst.lot_id %TYPE -- 3.ロットID
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- 情報有無フラグの初期化
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- ロットID有無チェック
    -- ======================================
    -- ロット情報の取得
    SELECT ilm.lot_id        -- ロットID
         , ilm.lot_desc      -- 摘要
         , ilm.attribute1    -- 製造年月日
         , ilm.attribute2    -- 固有記号
         , ilm.attribute3    -- 賞味期限
         , ilm.attribute4    -- 納入日(初回)
         , ilm.attribute5    -- 納入日(最終)
         , ilm.attribute6    -- 在庫入数
         , ilm.attribute7    -- 在庫単価
         , ilm.attribute8    -- 取引先
         , ilm.attribute9    -- 仕入形態
         , ilm.attribute10   -- 茶期区分
         , ilm.attribute11   -- 年度
         , ilm.attribute12   -- 産地
         , ilm.attribute13   -- タイプ
         , ilm.attribute14   -- ランク１
         , ilm.attribute15   -- ランク２
         , ilm.attribute16   -- 生産伝票区分
         , ilm.attribute17   -- ラインNo
         , ilm.attribute18   -- 摘要
         , ilm.attribute19   -- ランク３
         , ilm.attribute20   -- 原料製造工場
         , ilm.attribute21   -- 原料製造元ロット番号
         , ilm.attribute22   -- 検査依頼No
         , ilm.attribute23   -- ロットステータス
         , ilm.attribute24   -- 作成区分
         , ilm.attribute25   -- 属性25
         , ilm.attribute26   -- 属性26
         , ilm.attribute27   -- 属性27
         , ilm.attribute28   -- 属性28
         , ilm.attribute29   -- 属性29
         , ilm.attribute30   -- 属性30
    INTO   it_lot_id
         , ir_masters_rec.lot_desc
         , ir_masters_rec.lot_attribute1
         , ir_masters_rec.lot_attribute2
         , ir_masters_rec.lot_attribute3
         , ir_masters_rec.lot_attribute4
         , ir_masters_rec.lot_attribute5
         , ir_masters_rec.lot_attribute6
         , ir_masters_rec.lot_attribute7
         , ir_masters_rec.lot_attribute8
         , ir_masters_rec.lot_attribute9
         , ir_masters_rec.lot_attribute10
         , ir_masters_rec.lot_attribute11
         , ir_masters_rec.lot_attribute12
         , ir_masters_rec.lot_attribute13
         , ir_masters_rec.lot_attribute14
         , ir_masters_rec.lot_attribute15
         , ir_masters_rec.lot_attribute16
         , ir_masters_rec.lot_attribute17
         , ir_masters_rec.lot_attribute18
         , ir_masters_rec.lot_attribute19
         , ir_masters_rec.lot_attribute20
         , ir_masters_rec.lot_attribute21
         , ir_masters_rec.lot_attribute22
         , ir_masters_rec.lot_attribute23
         , ir_masters_rec.lot_attribute24
         , ir_masters_rec.lot_attribute25
         , ir_masters_rec.lot_attribute26
         , ir_masters_rec.lot_attribute27
         , ir_masters_rec.lot_attribute28
         , ir_masters_rec.lot_attribute29
         , ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPMロットマスタ
    WHERE  ilm.lot_no  = it_lot_no
    AND    ilm.item_id = it_item_id
    ;
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
-- 2009/03/03 v1.3 ADD START
  /**********************************************************************************
   * Procedure Name   : update_lot
   * Description      : ロットマスタ更新(C-8-1)
  /*********************************************************************************/
  PROCEDURE update_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec              -- 処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_lot'; -- プログラム名
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
    lv_return_status  VARCHAR2(2);     -- リターンステータス
    ln_message_count  NUMBER;          -- メッセージカウント
    lv_msg_date       VARCHAR2(10000); -- メッセージリスト
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_ic_lots_mst          ic_lots_mst%ROWTYPE;          -- ロットマスタレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    -- ====================================
    -- OPMロットマスタレコードに値をセット
    -- ====================================
    lr_ic_lots_mst.last_updated_by        := FND_GLOBAL.USER_ID;                -- 最終更新者
    lr_ic_lots_mst.last_update_date       := SYSDATE;                           -- 最終更新日
--
    SELECT ilm.attribute1    attribute1
          ,ilm.attribute2    attribute2
          ,ilm.attribute3    attribute3
          ,ilm.attribute4    attribute4
          ,ilm.attribute5    attribute5
          ,ilm.attribute6    attribute6
          ,ilm.attribute7    attribute7
          ,ilm.attribute8    attribute8
          ,ilm.attribute9    attribute9
          ,ilm.attribute10   attribute10
          ,ilm.attribute11   attribute11
          ,ilm.attribute12   attribute12
          ,ilm.attribute13   attribute13
          ,ilm.attribute14   attribute14
          ,ilm.attribute15   attribute15
          ,ilm.attribute16   attribute16
          ,ilm.attribute17   attribute17
          ,ilm.attribute18   attribute18
          ,ilm.attribute19   attribute19
          ,ilm.attribute20   attribute20
          ,ilm.attribute21   attribute21
          ,ilm.attribute22   attribute22
          ,ilm.attribute23   attribute23
          ,ilm.attribute24   attribute24
          ,ilm.attribute25   attribute25
          ,ilm.attribute26   attribute26
          ,ilm.attribute27   attribute27
          ,ilm.attribute28   attribute28
          ,ilm.attribute29   attribute29
          ,ilm.attribute30   attribute30
    INTO   lr_ic_lots_mst.attribute1
          ,lr_ic_lots_mst.attribute2
          ,lr_ic_lots_mst.attribute3
          ,lr_ic_lots_mst.attribute4
          ,lr_ic_lots_mst.attribute5
          ,lr_ic_lots_mst.attribute6
          ,lr_ic_lots_mst.attribute7
          ,lr_ic_lots_mst.attribute8
          ,lr_ic_lots_mst.attribute9
          ,lr_ic_lots_mst.attribute10
          ,lr_ic_lots_mst.attribute11
          ,lr_ic_lots_mst.attribute12
          ,lr_ic_lots_mst.attribute13
          ,lr_ic_lots_mst.attribute14
          ,lr_ic_lots_mst.attribute15
          ,lr_ic_lots_mst.attribute16
          ,lr_ic_lots_mst.attribute17
          ,lr_ic_lots_mst.attribute18
          ,lr_ic_lots_mst.attribute19
          ,lr_ic_lots_mst.attribute20
          ,lr_ic_lots_mst.attribute21
          ,lr_ic_lots_mst.attribute22
          ,lr_ic_lots_mst.attribute23
          ,lr_ic_lots_mst.attribute24
          ,lr_ic_lots_mst.attribute25
          ,lr_ic_lots_mst.attribute26
          ,lr_ic_lots_mst.attribute27
          ,lr_ic_lots_mst.attribute28
          ,lr_ic_lots_mst.attribute29
          ,lr_ic_lots_mst.attribute30
    FROM   ic_lots_mst   ilm -- OPMロットマスタ
    WHERE  ilm.item_id = ir_masters_rec.from_item_id   -- 品目ID
    AND    ilm.lot_id  = ir_masters_rec.from_lot_id    -- ロットID
    ;
    -- ===============================
    -- OPMロットマスタロック
    -- ===============================
    BEGIN
      SELECT ilm.item_id       item_id
            ,ilm.lot_id        lot_id
            ,ilm.lot_no        lot_no
      INTO   lr_ic_lots_mst.item_id
            ,lr_ic_lots_mst.lot_id
            ,lr_ic_lots_mst.lot_no
      FROM   ic_lots_mst   ilm -- OPMロットマスタ
      WHERE  ilm.item_id = ir_masters_rec.to_item_id   -- 品目ID
      AND    ilm.lot_id  = ir_masters_rec.to_lot_id    -- ロットID
      FOR UPDATE NOWAIT
      ;
--
    EXCEPTION
      WHEN DEADLOCK_DETECTED THEN
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================
    -- OPMロットマスタDFF更新
    -- ===============================
    GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF(
      p_api_version       => gn_api_version             -- IN  NUMBER
     ,p_init_msg_list     => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_commit            => FND_API.G_FALSE             -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_validation_level  => FND_API.G_VALID_LEVEL_FULL -- IN  NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL
     ,x_return_status     => lv_return_status           -- OUT NOCOPY       VARCHAR2
     ,x_msg_count         => ln_message_count           -- OUT NOCOPY       NUMBER
     ,x_msg_data          => lv_msg_date                -- OUT NOCOPY       VARCHAR2
     ,p_lot_rec           => lr_ic_lots_mst             -- IN  ic_lots_mst%ROWTYPE
    );
--
    -- ロット更新処理が成功でない場合
    IF ( lv_retcode <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_update_lot);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- OPMロットマスタDFFセット
    -- ===============================
    ir_masters_rec.lot_attribute1   := lr_ic_lots_mst.attribute1;
    ir_masters_rec.lot_attribute2   := lr_ic_lots_mst.attribute2;
    ir_masters_rec.lot_attribute3   := lr_ic_lots_mst.attribute3;
    ir_masters_rec.lot_attribute4   := lr_ic_lots_mst.attribute4;
    ir_masters_rec.lot_attribute5   := lr_ic_lots_mst.attribute5;
    ir_masters_rec.lot_attribute6   := lr_ic_lots_mst.attribute6;
    ir_masters_rec.lot_attribute7   := lr_ic_lots_mst.attribute7;
    ir_masters_rec.lot_attribute8   := lr_ic_lots_mst.attribute8;
    ir_masters_rec.lot_attribute9   := lr_ic_lots_mst.attribute9;
    ir_masters_rec.lot_attribute10  := lr_ic_lots_mst.attribute10;
    ir_masters_rec.lot_attribute11  := lr_ic_lots_mst.attribute11;
    ir_masters_rec.lot_attribute12  := lr_ic_lots_mst.attribute12;
    ir_masters_rec.lot_attribute13  := lr_ic_lots_mst.attribute13;
    ir_masters_rec.lot_attribute14  := lr_ic_lots_mst.attribute14;
    ir_masters_rec.lot_attribute15  := lr_ic_lots_mst.attribute15;
    ir_masters_rec.lot_attribute16  := lr_ic_lots_mst.attribute16;
    ir_masters_rec.lot_attribute17  := lr_ic_lots_mst.attribute17;
    ir_masters_rec.lot_attribute18  := lr_ic_lots_mst.attribute18;
    ir_masters_rec.lot_attribute19  := lr_ic_lots_mst.attribute19;
    ir_masters_rec.lot_attribute20  := lr_ic_lots_mst.attribute20;
    ir_masters_rec.lot_attribute21  := lr_ic_lots_mst.attribute21;
    ir_masters_rec.lot_attribute22  := lr_ic_lots_mst.attribute22;
    ir_masters_rec.lot_attribute23  := lr_ic_lots_mst.attribute23;
    ir_masters_rec.lot_attribute24  := lr_ic_lots_mst.attribute24;
    ir_masters_rec.lot_attribute25  := lr_ic_lots_mst.attribute25;
    ir_masters_rec.lot_attribute26  := lr_ic_lots_mst.attribute26;
    ir_masters_rec.lot_attribute27  := lr_ic_lots_mst.attribute27;
    ir_masters_rec.lot_attribute28  := lr_ic_lots_mst.attribute28;
    ir_masters_rec.lot_attribute29  := lr_ic_lots_mst.attribute29;
    ir_masters_rec.lot_attribute30  := lr_ic_lots_mst.attribute30;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END update_lot;
--
-- 2009/03/03 v1.3 ADD END
  /**********************************************************************************
   * Procedure Name   : create_lot
   * Description      : ロット作成(C-8-2)
   ***********************************************************************************/
  PROCEDURE create_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_return_status  VARCHAR2(2);     -- リターンステータス
    ln_message_count  NUMBER;          -- メッセージカウント
    lv_msg_date       VARCHAR2(10000); -- メッセージ
    lb_return_status  BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_lot_rec        gmigapi.lot_rec_typ;
    lr_ic_lots_cpg    ic_lots_cpg%ROWTYPE;
    lr_lot_mst        ic_lots_mst%ROWTYPE;
    l_data            VARCHAR2(2000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lb_return_status := GMIGUTL.SETUP(FND_GLOBAL.USER_NAME()); -- CREATE_LOT API_VERSION補助(必須)
--
        -- ロット情報の取得
    SELECT lot_desc          -- 摘要
         , ilm.attribute1    -- 製造年月日
         , ilm.attribute2    -- 固有記号
         , ilm.attribute3    -- 賞味期限
         , ilm.attribute4    -- 納入日(初回)
         , ilm.attribute5    -- 納入日(最終)
         , ilm.attribute6    -- 在庫入数
         , ilm.attribute7    -- 在庫単価
         , ilm.attribute8    -- 取引先
         , ilm.attribute9    -- 仕入形態
         , ilm.attribute10   -- 茶期区分
         , ilm.attribute11   -- 年度
         , ilm.attribute12   -- 産地
         , ilm.attribute13   -- タイプ
         , ilm.attribute14   -- ランク１
         , ilm.attribute15   -- ランク２
         , ilm.attribute16   -- 生産伝票区分
         , ilm.attribute17   -- ラインNo
         , ilm.attribute18   -- 摘要
         , ilm.attribute19   -- ランク３
         , ilm.attribute20   -- 原料製造工場
         , ilm.attribute21   -- 原料製造元ロット番号
         , ilm.attribute22   -- 検査依頼No
         , ilm.attribute23   -- ロットステータス
         , ilm.attribute24   -- 作成区分
         , ilm.attribute25   -- 属性25
         , ilm.attribute26   -- 属性26
         , ilm.attribute27   -- 属性27
         , ilm.attribute28   -- 属性28
         , ilm.attribute29   -- 属性29
         , ilm.attribute30   -- 属性30
    INTO   ir_masters_rec.lot_desc
        ,  ir_masters_rec.lot_attribute1
        ,  ir_masters_rec.lot_attribute2
        ,  ir_masters_rec.lot_attribute3
        ,  ir_masters_rec.lot_attribute4
        ,  ir_masters_rec.lot_attribute5
        ,  ir_masters_rec.lot_attribute6
        ,  ir_masters_rec.lot_attribute7
        ,  ir_masters_rec.lot_attribute8
        ,  ir_masters_rec.lot_attribute9
        ,  ir_masters_rec.lot_attribute10
        ,  ir_masters_rec.lot_attribute11
        ,  ir_masters_rec.lot_attribute12
        ,  ir_masters_rec.lot_attribute13
        ,  ir_masters_rec.lot_attribute14
        ,  ir_masters_rec.lot_attribute15
        ,  ir_masters_rec.lot_attribute16
        ,  ir_masters_rec.lot_attribute17
        ,  ir_masters_rec.lot_attribute18
        ,  ir_masters_rec.lot_attribute19
        ,  ir_masters_rec.lot_attribute20
        ,  ir_masters_rec.lot_attribute21
        ,  ir_masters_rec.lot_attribute22
        ,  ir_masters_rec.lot_attribute23
        ,  ir_masters_rec.lot_attribute24
        ,  ir_masters_rec.lot_attribute25
        ,  ir_masters_rec.lot_attribute26
        ,  ir_masters_rec.lot_attribute27
        ,  ir_masters_rec.lot_attribute28
        ,  ir_masters_rec.lot_attribute29
        ,  ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPMロットマスタ
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.from_item_id
    ;
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
    lr_lot_rec.expaction_date   := FND_DATE.STRING_TO_DATE('2099/12/31', gv_yyyymmdd);
    lr_lot_rec.expire_date      := FND_DATE.STRING_TO_DATE('2099/12/31', gv_yyyymmdd);
    lr_lot_rec.sublot_no        := NULL;
    lr_lot_rec.lot_desc         := ir_masters_rec.lot_desc;        -- 摘要
    lr_lot_rec.user_name        := FND_GLOBAL.USER_NAME;
    lr_lot_rec.lot_created      := SYSDATE;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ==========================================
    -- ロット作成API
    -- ==========================================
    GMIPAPI.CREATE_LOT(
          p_api_version      => 3.0                        -- APIバージョン番号
        , p_init_msg_list    => FND_API.G_FALSE            -- メッセージ初期化フラグ
-- 2009/03/03 v1.3 UPDATE START
--        , p_commit           => FND_API.G_TRUE             -- 自動コミットフラグ
        , p_commit           => FND_API.G_FALSE            -- 自動コミットフラグ
-- 2009/03/03 v1.3 UPDATE END
        , p_validation_level => FND_API.G_VALID_LEVEL_FULL -- 検証レベル
        , p_lot_rec          => lr_lot_rec
        , x_ic_lots_mst_row  => lr_lot_mst
        , x_ic_lots_cpg_row  => lr_ic_lots_cpg
        , x_return_status    => lv_return_status           -- プロセス終了ステータス
        , x_msg_count        => ln_message_count           -- エラーメッセージ件数
        , x_msg_data         => lv_msg_date                -- エラーメッセージ
          );
--
    -- ロット作成処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_create_lot);
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
    AND    ilm.item_id = ir_masters_rec.to_item_id
    ;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
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
-- 2009/06/02 H.Itou Del Start 本番障害#1517 C-37で取得するため削除
--  /**********************************************************************************
--   * Procedure Name   : get_validity_rule_id
--   * Description      : 妥当性ルールID取得(C-21)
--   ***********************************************************************************/
--  PROCEDURE get_validity_rule_id(
--    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.処理対象レコード
--  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
--  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
--  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_validity_rule_id'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    ln_recipe_id gmd_recipes_b.recipe_id%TYPE;
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := gv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- レシピIDの取得
--    SELECT greb.recipe_id    recipe_id     -- レシピID
--    INTO   ln_recipe_id                    -- レシピID
--    FROM   gmd_recipes_b     greb          -- レシピマスタ
--         , gmd_routings_b    grob          -- 工順マスタ
--    WHERE  greb.formula_id      = ir_masters_rec.formula_id
--    AND    greb.routing_id      = grob.routing_id
--    AND    grob.routing_no      = ir_masters_rec.routing_no
--    AND    grob.routing_class   = gv_routing_class_70
--    ;
----
--    -- 妥当性ルールIDの取得
--    SELECT grvr.recipe_validity_rule_id  recipe_validity_rule_id -- 妥当性ルールID
--    INTO   ir_masters_rec.recipe_validity_rule_id                -- 妥当性ルールID
--    FROM   gmd_recipe_validity_rules     grvr                    -- レシピ妥当性ルールマスタ
--    WHERE  grvr.recipe_id = ln_recipe_id                         -- レシピID
--    ;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
--      ov_retcode := gv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END get_validity_rule_id;
-- 2009/06/02 H.Itou Del End
--
  /**********************************************************************************
   * Procedure Name   : create_batch
   * Description      : バッチ作成(C-9)
   ***********************************************************************************/
  PROCEDURE create_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    lr_in_batch_hdr  gme_batch_header%ROWTYPE;     -- 生産バッチヘッダ(入力)
    lr_out_batch_hrd gme_batch_header%ROWTYPE;     -- 生産バッチヘッダ(出力)
    lt_unalloc_mtl   gme_api_pub.unallocated_materials_tab;
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
    lr_in_batch_hdr.plant_code              := ir_masters_rec.orgn_code;    -- プラントコード(必須)
    lr_in_batch_hdr.plan_start_date         := ir_masters_rec.item_sysdate; -- 生産予定日
    lr_in_batch_hdr.plan_cmplt_date         := ir_masters_rec.item_sysdate; -- 生産完了日
    lr_in_batch_hdr.attribute6              := ir_masters_rec.remarks;      -- 摘要
    lr_in_batch_hdr.attribute7              := ir_masters_rec.item_chg_aim; -- 品目振替目的
    lr_in_batch_hdr.batch_type              := gn_bat_type_batch;           -- バッチタイプ
    lr_in_batch_hdr.wip_whse_code           := ir_masters_rec.whse_code;    -- 倉庫コード
-- 2009/06/02 H.Itou Del Start 本番障害#1517 C-37で取得するため削除
--    -- 13.妥当性ルールID
--    --妥当性ルールIDがセットされていない場合
--    IF ( ir_masters_rec.recipe_validity_rule_id IS NULL ) THEN
--      -- ====================================
--      -- 妥当性ルールID取得(C-21)
--      -- ====================================
--      get_validity_rule_id(ir_masters_rec  -- 1.チェック対象レコード
--                         , lv_errbuf       -- エラー・メッセージ           --# 固定 #
--                         , lv_retcode      -- リターン・コード             --# 固定 #
--                         , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
----
--      -- エラーの場合
--      IF ( lv_retcode = gv_status_error ) THEN
--        RAISE global_api_expt;
--      END IF;
----
--    END IF;
-- 2009/06/02 H.Itou Del End
    lr_in_batch_hdr.recipe_validity_rule_id := ir_masters_rec.recipe_validity_rule_id;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- バッチ作成API
    -- ======================================
    GME_API_PUB.CREATE_BATCH(
          p_api_version          => GME_API_PUB.API_VERSION
        , p_validation_level     => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list        => FALSE
        , p_commit               => FALSE
        , p_batch_header         => lr_in_batch_hdr             -- 必須
        , p_batch_size           => ir_masters_rec.qty          -- 必須
        , p_batch_size_uom       => ir_masters_rec.from_item_um -- 必須
        , p_creation_mode        => 'PRODUCT'                   -- 必須
        , p_recipe_id            => NULL                        -- レシピID
        , p_recipe_no            => NULL                        -- レシピNo
        , p_recipe_version       => NULL                        -- レシピバージョン
        , p_product_no           => NULL                        -- 工順No
        , p_product_id           => NULL                        -- 工順ID
        , p_ignore_qty_below_cap => TRUE
        , p_ignore_shortages     => TRUE                        -- 必須
        , p_use_shop_cal         => NULL
        , p_contiguity_override  => 1
        , x_batch_header         => lr_out_batch_hrd            -- 必須
        , x_message_count        => ln_message_count
        , x_message_list         => lv_message_list
        , x_return_status        => lv_return_status
        , x_unallocated_material => lt_unalloc_mtl              -- 非割当情報テーブル
          );
--
    -- バッチ作成処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_create_bat);
--
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
    SELECT gmd.material_detail_id  material_detail_id  -- 生産原料詳細ID
    INTO   ir_masters_rec.from_material_detail_id      -- 生産原料詳細ID(振替元)
    FROM   gme_material_details    gmd                 -- 生産原料詳細
    WHERE  gmd.batch_id = ir_masters_rec.batch_id      -- バッチID
    AND    gmd.item_id  = ir_masters_rec.from_item_id  -- 品目ID(振替元)
-- 2009/02/03 H.Itou Add Start 本番障害#1113対応
    AND    gmd.line_type   = gn_line_type_i            -- ラインタイプが原料
-- 2009/02/03 H.Itou Add End
    ;
--
    -- 振替先品目の生産原料詳細IDの取得
    SELECT gmd.material_detail_id                      -- 生産原料詳細ID
    INTO   ir_masters_rec.to_material_detail_id        -- 生産原料詳細ID(振替先)
    FROM   gme_material_details gmd                    -- 生産原料詳細
    WHERE  gmd.batch_id = ir_masters_rec.batch_id      -- バッチID
    AND    gmd.item_id  = ir_masters_rec.to_item_id    -- 品目ID(振替先)
-- 2009/02/03 H.Itou Add Start 本番障害#1113対応
    AND    gmd.line_type   = gn_line_type_p            -- ラインタイプが製品
-- 2009/02/03 H.Itou Add End
    ;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
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
   * Procedure Name   : input_lot_ins
   * Description      : 入力ロット割当追加(C-10)
   ***********************************************************************************/
  PROCEDURE input_lot_ins(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_ins'; -- プログラム名
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
    lv_return_status    VARCHAR2(2);     -- リターンステータス
    ln_message_count    NUMBER;          -- メッセージカウント
    lv_msg_date         VARCHAR2(10000); -- メッセージ
    lv_message_list     VARCHAR2(200);   -- メッセージリスト
    l_data              VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_material_datail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_tran_row_in.item_id            := ir_masters_rec.from_item_id;            -- 1.品目ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.倉庫コード
    lr_tran_row_in.lot_id             := ir_masters_rec.from_lot_id;             -- 3.ロットID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.保管場所
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- バッチID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.文書タイプ
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- 実績日
--    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.数量
    lr_tran_row_in.trans_date         := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date); -- 実績日
    lr_tran_row_in.trans_qty          := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty); -- 6.数量
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.trans_um           := ir_masters_rec.from_item_um;            -- 7.単位１
    lr_tran_row_in.material_detail_id := ir_masters_rec.from_material_detail_id; -- 生産原料詳細ID
--
    -- 処理区分5:実績(生産バッチNoなし)の場合は完了フラグON
    IF (ir_masters_rec.process_type = gv_actual_new) THEN
      lr_tran_row_in.completed_ind      := 1;                                      -- 完了フラグ
--
    -- 5:実績(生産バッチNoなし)以外の場合は完了フラグOFF
    ELSE
      lr_tran_row_in.completed_ind      := 0;                                      -- 完了フラグ
    END IF;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当追加API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_datail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- 入力ロット割当追加処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_ins);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- 移動ロット詳細へデータ登録
    -- ======================================
    INSERT INTO xxinv_mov_lot_details(
      mov_lot_dtl_id                  -- ロット詳細ID
    , mov_line_id                     -- 明細ID
    , document_type_code              -- 文書タイプ
    , record_type_code                -- レコードタイプ
    , item_id                         -- OPM品目ID
    , item_code                       -- 品目
    , lot_id                          -- ロットID
    , lot_no                          -- ロットNo
    , actual_date                     -- 実績日
    , actual_quantity                 -- 実績数量
    , created_by                      -- 作成者
    , creation_date                   -- 作成日
    , last_updated_by                 -- 最終更新者
    , last_update_date                -- 最終更新日
    , last_update_login               -- 最終更新ログイン
    , request_id                      -- 要求ID
    , program_application_id          -- コンカレント・プログラム・アプリケーションID
    , program_id                      -- コンカレント・プログラムID
    , program_update_date             -- プログラム更新日
    )
    VALUES(
      xxinv_mov_lot_s1.NEXTVAL                      -- ロット詳細ID
    , ir_masters_rec.from_material_detail_id        -- 明細ID
    , gv_doc_type_code_prod                         -- 文書タイプ
    , gv_rec_type_code_plan                         -- レコードタイプ
    , ir_masters_rec.from_item_id                   -- OPM品目ID
    , ir_masters_rec.from_item_no                   -- 品目
    , ir_masters_rec.from_lot_id                    -- ロットID
    , ir_masters_rec.lot_no                         -- ロットNo
    , NULL                                          -- 実績日
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    , ir_masters_rec.qty                     -- 実績数量
    , NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- 実績数量
-- 2009/01/15 H.Itou Mod End
    , FND_GLOBAL.USER_ID                            -- 作成者
    , SYSDATE                                       -- 作成日
    , FND_GLOBAL.USER_ID                            -- 最終更新者
    , SYSDATE                                       -- 最終更新日
    , FND_GLOBAL.LOGIN_ID                           -- 最終更新ログイン
    , FND_GLOBAL.CONC_REQUEST_ID                    -- 要求ID
    , FND_GLOBAL.PROG_APPL_ID                       -- コンカレント・プログラム・アプリケーションID
    , FND_GLOBAL.CONC_PROGRAM_ID                    -- コンカレント・プログラムID
    , SYSDATE                                       -- プログラム更新日
    );
--
    -- ======================================
    -- 生産原料詳細アドオンへデータ登録
    -- ======================================
    INSERT INTO xxwip_material_detail(-- 生産原料詳細アドオン
      mtl_detail_addon_id             -- 生産原料詳細アドオンID
    , batch_id                        -- バッチID
    , material_detail_id              -- 生産原料詳細ID
    , item_id                         -- 品目ID
    , lot_id                          -- ロットID
    , instructions_qty                -- 指示総数
    , invested_qty                    -- 投入数量
    , return_qty                      -- 戻入数量
    , mtl_prod_qty                    -- 資材製造不良数
    , mtl_mfg_qty                     -- 資材業者不良数
    , location_code                   -- 手配倉庫コード
    , plan_type                       -- 予定区分
    , plan_number                     -- 番号
    , created_by                      -- 作成者
    , creation_date                   -- 作成日
    , last_updated_by                 -- 最終更新者
    , last_update_date                -- 最終更新日
    , last_update_login               -- 最終更新ログイン
    , request_id                      -- 要求ID
    , program_application_id          -- コンカレント・プログラム・アプリケーションID
    , program_id                      -- コンカレント・プログラムID
    , program_update_date             -- プログラム更新日
    )
    VALUES(
      xxwip_mtl_detail_addon_id_s1.NEXTVAL          -- 生産原料詳細アドオンID
    , ir_masters_rec.batch_id                       -- バッチID
    , ir_masters_rec.from_material_detail_id        -- 生産原料詳細ID
    , ir_masters_rec.from_item_id                   -- 品目ID
    , ir_masters_rec.from_lot_id                    -- ロットID
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    , ir_masters_rec.qty                     -- 実績数量
    , NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- 実績数量
-- 2009/01/15 H.Itou Mod End
    , 0                                             -- 投入数量
    , 0                                             -- 戻入数量
    , 0                                             -- 資材製造不良数
    , 0                                             -- 資材業者不良数
    , ir_masters_rec.inventory_location_code        -- 手配倉庫コード
    , gv_plan_type_4                                -- 予定区分
    , NULL                                          -- 予定番号
    , FND_GLOBAL.USER_ID                            -- 作成者
    , SYSDATE                                       -- 作成日
    , FND_GLOBAL.USER_ID                            -- 最終更新者
    , SYSDATE                                       -- 最終更新日
    , FND_GLOBAL.LOGIN_ID                           -- 最終更新ログイン
    , FND_GLOBAL.CONC_REQUEST_ID                    -- 要求ID
    , FND_GLOBAL.PROG_APPL_ID                       -- コンカレント・プログラム・アプリケーションID
    , FND_GLOBAL.CONC_PROGRAM_ID                    -- コンカレント・プログラムID
    , SYSDATE                                       -- プログラム更新日
    );
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
  END input_lot_ins;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_ins
   * Description      : 出力ロット割当追加(C-11)
   ***********************************************************************************/
  PROCEDURE output_lot_ins(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_ins'; -- プログラム名
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_tran_row_in.item_id            := ir_masters_rec.to_item_id;              -- 1.品目ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.倉庫コード
    lr_tran_row_in.lot_id             := ir_masters_rec.to_lot_id;               -- 3.ロットID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.保管場所
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- バッチID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.文書タイプ
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- 実績日
--    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.数量
    lr_tran_row_in.trans_date         := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date); -- 実績日
    lr_tran_row_in.trans_qty          := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty); -- 6.数量
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.trans_um           := ir_masters_rec.to_item_um;              -- 7.単位１
    lr_tran_row_in.material_detail_id := ir_masters_rec.to_material_detail_id;   -- 生産原料詳細ID
--
    -- 処理区分5:実績(生産バッチNoなし)の場合は完了フラグON
    IF (ir_masters_rec.process_type = gv_actual_new) THEN
      lr_tran_row_in.completed_ind      := 1;                                      -- 完了フラグ
--
    -- 5:実績(生産バッチNoなし)以外の場合は完了フラグOFF
    ELSE
      lr_tran_row_in.completed_ind      := 0;                                      -- 完了フラグ
    END IF;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当追加API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- 出力ロット割当追加処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_ins);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- 移動ロット詳細へデータ登録
    -- ======================================
    INSERT INTO xxinv_mov_lot_details(
      mov_lot_dtl_id           -- ロット詳細ID
    , mov_line_id              -- 明細ID
    , document_type_code       -- 文書タイプ
    , record_type_code         -- レコードタイプ
    , item_id                  -- OPM品目ID
    , item_code                -- 品目
    , lot_id                   -- ロットID
    , lot_no                   -- ロットNo
    , actual_date              -- 実績日
    , actual_quantity          -- 実績数量
    , created_by               -- 作成者
    , creation_date            -- 作成日
    , last_updated_by          -- 最終更新者
    , last_update_date         -- 最終更新日
    , last_update_login        -- 最終更新ログイン
    , request_id               -- 要求ID
    , program_application_id   -- コンカレント・プログラム・アプリケーションID
    , program_id               -- コンカレント・プログラムID
    , program_update_date      -- プログラム更新日
    )
    VALUES(
      xxinv_mov_lot_s1.NEXTVAL               -- ロット詳細ID
    , ir_masters_rec.to_material_detail_id   -- 明細ID
    , gv_doc_type_code_prod                  -- 文書タイプ
    , gv_rec_type_code_plan                  -- レコードタイプ
    , ir_masters_rec.to_item_id              -- OPM品目ID
    , ir_masters_rec.to_item_no              -- 品目
    , ir_masters_rec.to_lot_id               -- ロットID
    , ir_masters_rec.lot_no                  -- ロットNo
    , NULL                                   -- 実績日
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    , ir_masters_rec.qty                     -- 実績数量
    , NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- 実績数量
-- 2009/01/15 H.Itou Mod End
    , FND_GLOBAL.USER_ID                     -- 作成者
    , SYSDATE                                -- 作成日
    , FND_GLOBAL.USER_ID                     -- 最終更新者
    , SYSDATE                                -- 最終更新日
    , FND_GLOBAL.LOGIN_ID                    -- 最終更新ログイン
    , FND_GLOBAL.CONC_REQUEST_ID             -- 要求ID
    , FND_GLOBAL.PROG_APPL_ID                -- コンカレント・プログラム・アプリケーションID
    , FND_GLOBAL.CONC_PROGRAM_ID             -- コンカレント・プログラムID
    , SYSDATE                                -- プログラム更新日
    );
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
  END output_lot_ins;
--
  /**********************************************************************************
   * Procedure Name   : cmpt_batch
   * Description      : バッチ完了(C-12)
   ***********************************************************************************/
  PROCEDURE cmpt_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- 生産バッチヘッダ(出力)
    lt_unalloc_mtl   gme_api_pub.unallocated_materials_tab;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    gr_gme_batch_header.actual_start_date := ir_masters_rec.plan_start_date; -- 2.実績開始日
    gr_gme_batch_header.actual_cmplt_date := ir_masters_rec.plan_start_date; -- 3.実績終了日
    gr_gme_batch_header.batch_id          := ir_masters_rec.batch_id;        -- バッチID
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- バッチ完了API
    -- ======================================
    GME_API_PUB.CERTIFY_BATCH(
          p_api_version           => GME_API_PUB.API_VERSION
        , p_validation_level      => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list         => FALSE
        , p_commit                => FALSE
        , x_message_count         => ln_message_count
        , x_message_list          => lv_message_list
        , x_return_status         => lv_return_status
        , p_del_incomplete_manual => TRUE
        , p_ignore_shortages      => TRUE
        , p_batch_header          => gr_gme_batch_header
        , x_batch_header          => lr_out_batch_hrd
        , x_unallocated_material  => lt_unalloc_mtl
          );
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_message_list ='||lv_message_list);
--
    -- バッチ完了処理が成功でない場合
    IF ( lv_return_status IN ( FND_API.g_ret_sts_error, FND_API.g_ret_sts_unexp_error ) ) THEN
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_cmpt_bat);
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
   * Description      : バッチクローズ(C-13)
   ***********************************************************************************/
  PROCEDURE close_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- 生産バッチヘッダ(出力)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    gr_gme_batch_header.batch_close_date  := ir_masters_rec.plan_start_date; -- 2.実績開始日
    gr_gme_batch_header.batch_id          := ir_masters_rec.batch_id;        -- バッチID
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- バッチクローズAPI
    -- ======================================
    GME_API_PUB.CLOSE_BATCH(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
        , p_batch_header     => gr_gme_batch_header
        , x_batch_header     => lr_out_batch_hrd
          );
--
    -- バッチクローズ処理が成功でない場合
    IF ( lv_return_status IN ( FND_API.g_ret_sts_error, FND_API.g_ret_sts_unexp_error ) ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_close_bat);
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
   * Description      : バッチ保存(C-14)
   ***********************************************************************************/
  PROCEDURE save_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lr_in_batch_hdr  gme_batch_header%ROWTYPE;     -- 生産バッチヘッダ(入力)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_in_batch_hdr.batch_id := ir_masters_rec.batch_id;     -- バッチID
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- バッチ保存API
    -- ======================================
    GME_API_PUB.SAVE_BATCH(
          p_batch_header  => lr_in_batch_hdr
        , x_return_status => lv_return_status
        , p_commit        => FALSE
          );
--
    -- バッチ保存処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_save_bat);
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
   * Procedure Name   : cancel_batch
   * Description      : バッチ取消(C-15)
   ***********************************************************************************/
  PROCEDURE cancel_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cancel_batch'; -- プログラム名
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_in_batch_hdr  gme_batch_header%ROWTYPE; -- 生産バッチヘッダ(入力)
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- 生産バッチヘッダ(出力)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_in_batch_hdr.batch_id := ir_masters_rec.batch_id; -- バッチID
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- バッチ取消API
    -- ======================================
    -- バッチ取消関数を実行
    GME_API_PUB.CANCEL_BATCH(
          p_api_version      =>  GME_API_PUB.API_VERSION
        , p_validation_level =>  GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    =>  FALSE
        , p_commit           =>  FALSE
        , x_message_count    =>  ln_message_count
        , x_message_list     =>  lv_message_list
        , x_return_status    =>  lv_return_status
        , p_batch_header     =>  lr_in_batch_hdr
        , x_batch_header     =>  lr_out_batch_hrd
          );
--
    -- バッチ取消処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_cancel_bat);
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
  END cancel_batch;
--
  /**********************************************************************************
   * Procedure Name   : reschedule_batch
   * Description      : バッチ再スケジュール(C-16)
   ***********************************************************************************/
  PROCEDURE reschedule_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reschedule_batch'; -- プログラム名
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_in_batch_hdr  gme_batch_header%ROWTYPE; -- 生産バッチヘッダ(入力)
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- 生産バッチヘッダ(出力)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_in_batch_hdr.batch_id        := ir_masters_rec.batch_id;     -- バッチID
    lr_in_batch_hdr.plan_start_date := ir_masters_rec.item_sysdate; -- 生産予定開始日
    lr_in_batch_hdr.plan_cmplt_date := ir_masters_rec.item_sysdate; -- 生産予定完了日
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- バッチ再スケジュールAPI
    -- ======================================
    -- バッチ再スケジュール関数を実行
    GME_API_PUB.RESCHEDULE_BATCH(
          p_api_version         =>  GME_API_PUB.API_VERSION
        , p_validation_level    =>  GME_API_PUB.MAX_ERRORS
        , p_init_msg_list       =>  FALSE
        , p_commit              =>  FALSE
        , x_message_count       =>  ln_message_count
        , x_message_list        =>  lv_message_list
        , x_return_status       =>  lv_return_status
        , p_batch_header        =>  lr_in_batch_hdr
        , p_use_shop_cal        =>  NULL
        , p_contiguity_override =>  NULL
        , x_batch_header        =>  lr_out_batch_hrd
          );
--
    -- バッチ再スケジュール処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_resche__bat);
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
  END reschedule_batch;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_upd
   * Description      : 入力ロット割当更新(C-17)
   ***********************************************************************************/
  PROCEDURE input_lot_upd(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_upd'; -- プログラム名
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
    lv_return_status    VARCHAR2(2);     -- リターンステータス
    ln_message_count    NUMBER;          -- メッセージカウント
    lv_msg_date         VARCHAR2(10000); -- メッセージ
    lv_message_list     VARCHAR2(200);   -- メッセージリスト
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.from_trans_id;  -- トランザクションID
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    lr_tran_row_in.trans_date    := ir_masters_rec.item_sysdate;   -- 実績日
--    lr_tran_row_in.trans_qty     := ir_masters_rec.qty;            -- 数量
    lr_tran_row_in.trans_date    := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date);   -- 実績日
    lr_tran_row_in.trans_qty     := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty);  -- 数量
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.completed_ind := 0;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当更新API
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- 入力ロット割当更新処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_upd);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- 移動ロット詳細へデータ更新
    -- ======================================
    UPDATE xxinv_mov_lot_details xmlv                                         -- 移動ロット詳細
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    SET    xmlv.actual_quantity             = ir_masters_rec.qty              -- 数量
    SET    xmlv.actual_quantity             = NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- 数量
-- 2009/01/15 H.Itou Mod End
         , xmlv.lot_id                      = ir_masters_rec.from_lot_id      -- ロットID(振替元)
         , xmlv.lot_no                      = ir_masters_rec.lot_no           -- ロットNo
         , xmlv.last_updated_by             = FND_GLOBAL.USER_ID              -- 更新ユーザーID
         , xmlv.last_update_date            = SYSDATE                         -- 最終更新日
         , xmlv.last_update_login           = FND_GLOBAL.LOGIN_ID             -- 更新ログインID
         , xmlv.request_id                  = FND_GLOBAL.CONC_REQUEST_ID      -- 要求ID
         , xmlv.program_application_id      = FND_GLOBAL.PROG_APPL_ID         -- コンカレント・プログラム・アプリケーションID
         , xmlv.program_id                  = FND_GLOBAL.CONC_PROGRAM_ID      -- コンカレント・プログラムID
         , xmlv.program_update_date         = SYSDATE                         -- プログラム更新日
    WHERE  xmlv.mov_line_id        = ir_masters_rec.from_material_detail_id   -- 明細ID(振替元)
    AND    xmlv.item_id            = ir_masters_rec.from_item_id              -- 品目ID(振替元)
    AND    xmlv.document_type_code = gv_doc_type_code_prod                    -- 文書タイプ：生産
    AND    xmlv.record_type_code   = gv_rec_type_code_plan                    -- レコードタイプ：指示
    ;
--
    -- ======================================
    -- 生産原料詳細アドオンへデータ更新
    -- ======================================
    UPDATE xxwip_material_detail xmd                                         -- 生産原料詳細アドオン
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    SET    xmd.instructions_qty            = ir_masters_rec.qty              -- 数量
    SET    xmd.instructions_qty            = NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- 数量
-- 2009/01/15 H.Itou Mod End
         , xmd.lot_id                      = ir_masters_rec.from_lot_id      -- ロットID(振替先)
         , xmd.last_updated_by             = FND_GLOBAL.USER_ID              -- 更新ユーザーID
         , xmd.last_update_date            = SYSDATE                         -- 最終更新日
         , xmd.last_update_login           = FND_GLOBAL.LOGIN_ID             -- 更新ログインID
         , xmd.request_id                  = FND_GLOBAL.CONC_REQUEST_ID      -- 要求ID
         , xmd.program_application_id      = FND_GLOBAL.PROG_APPL_ID         -- コンカレント・プログラム・アプリケーションID
         , xmd.program_id                  = FND_GLOBAL.CONC_PROGRAM_ID      -- コンカレント・プログラムID
         , xmd.program_update_date         = SYSDATE                         -- プログラム更新日
    WHERE  xmd.batch_id           = ir_masters_rec.batch_id                  -- バッチID
    AND    xmd.material_detail_id = ir_masters_rec.from_material_detail_id   -- 生産原料詳細ID(振替元)
    AND    xmd.item_id            = ir_masters_rec.from_item_id              -- 品目ID(振替元)
    AND    xmd.plan_type          = gv_plan_type_4                           -- 予定区分
    ;
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
  END input_lot_upd;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_upd
   * Description      : 出力ロット割当更新(C-18)
   ***********************************************************************************/
  PROCEDURE output_lot_upd(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_upd'; -- プログラム名
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.to_trans_id;    -- トランザクションID
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    lr_tran_row_in.trans_date    := ir_masters_rec.item_sysdate;   -- 実績日
--    lr_tran_row_in.trans_qty     := ir_masters_rec.qty;            -- 数量
    lr_tran_row_in.trans_date    := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date);   -- 実績日
    lr_tran_row_in.trans_qty     := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty);  -- 数量
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.completed_ind := 0;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当更新API
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => ir_masters_rec.lot_no
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- 出力ロット割当更新処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_upd);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- 移動ロット詳細へデータ更新
    -- ======================================
    UPDATE xxinv_mov_lot_details xmlv                                         -- 移動ロット詳細
-- 2009/01/15 H.Itou Mod Start 指摘2対応
--    SET    xmlv.actual_quantity             = ir_masters_rec.qty              -- 数量
    SET    xmlv.actual_quantity             = NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- 数量
-- 2009/01/15 H.Itou Mod End
         , xmlv.lot_id                      = ir_masters_rec.to_lot_id        -- ロットID(振替元)
         , xmlv.lot_no                      = ir_masters_rec.lot_no           -- ロットNo
         , xmlv.last_updated_by             = FND_GLOBAL.USER_ID              -- 更新ユーザーID
         , xmlv.last_update_date            = SYSDATE                         -- 最終更新日
         , xmlv.last_update_login           = FND_GLOBAL.LOGIN_ID             -- 更新ログインID
         , xmlv.request_id                  = FND_GLOBAL.CONC_REQUEST_ID      -- 要求ID
         , xmlv.program_application_id      = FND_GLOBAL.PROG_APPL_ID         -- コンカレント・プログラム・アプリケーションID
         , xmlv.program_id                  = FND_GLOBAL.CONC_PROGRAM_ID      -- コンカレント・プログラムID
         , xmlv.program_update_date         = SYSDATE                         -- プログラム更新日
    WHERE  xmlv.mov_line_id        = ir_masters_rec.to_material_detail_id     -- 明細ID(振替先)
    AND    xmlv.item_id            = ir_masters_rec.to_item_id                -- 品目ID(振替先)
    AND    xmlv.document_type_code = gv_doc_type_code_prod                    -- 文書タイプ：生産
    AND    xmlv.record_type_code   = gv_rec_type_code_plan                    -- レコードタイプ：指示
    ;
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
  END output_lot_upd;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_del
   * Description      : 入力ロット割当削除(C-19)
   ***********************************************************************************/
  PROCEDURE input_lot_del(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_del'; -- プログラム名
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
    lv_return_status    VARCHAR2(2);     -- リターンステータス
    ln_message_count    NUMBER;          -- メッセージカウント
    lv_msg_date         VARCHAR2(10000); -- メッセージ
    lv_message_list     VARCHAR2(200);   -- メッセージリスト
    l_data              VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_material_detail_out  gme_material_details   %ROWTYPE;
    lr_tran_row_out         gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当削除API
    -- ======================================
    GME_API_PUB.DELETE_LINE_ALLOCATION (
      p_api_version        => GME_API_PUB.API_VERSION          -- IN         NUMBER := gme_api_pub.api_version
     ,p_validation_level   => GME_API_PUB.MAX_ERRORS           -- IN         NUMBER := gme_api_pub.max_errors
     ,p_init_msg_list      => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_commit             => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_trans_id           => ir_masters_rec.from_trans_id     -- IN         NUMBER
     ,p_scale_phantom      => FALSE                            -- IN         BOOLEAN DEFAULT FALSE
     ,x_material_detail    => lr_material_detail_out           -- OUT NOCOPY gme_material_details%ROWTYPE
     ,x_def_tran_row       => lr_tran_row_out                  -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
     ,x_message_count      => ln_message_count                 -- OUT NOCOPY NUMBER
     ,x_message_list       => lv_message_list                  -- OUT NOCOPY VARCHAR2
     ,x_return_status      => lv_return_status                 -- OUT NOCOPY VARCHAR2
    );
--
    -- 入力ロット割当削除処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_del);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- 移動ロット詳細データ削除
    -- ======================================
    DELETE xxinv_mov_lot_details xmld                                          -- 移動ロット詳細アドオン
    WHERE  xmld.mov_line_id        = ir_masters_rec.from_material_detail_id    -- 生産原料詳細ID(振替元)
    AND    xmld.item_id            = ir_masters_rec.from_item_id               -- 品目ID(振替元)
    AND    xmld.lot_id             = ir_masters_rec.from_lot_id                -- ロットID(振替元)
    AND    xmld.document_type_code = gv_doc_type_code_prod                     -- 文書タイプ
    AND    xmld.record_type_code   = gv_rec_type_code_plan                     -- レコードタイプ
    ;
--
    -- ======================================
    -- 生産原料詳細アドオンデータ削除
    -- ======================================
    DELETE xxwip_material_detail xmd                                         -- 生産原料詳細アドオン
    WHERE  xmd.batch_id           = ir_masters_rec.batch_id                  -- バッチID
    AND    xmd.material_detail_id = ir_masters_rec.from_material_detail_id   -- 生産原料詳細ID(振替元)
    AND    xmd.item_id            = ir_masters_rec.from_item_id              -- 品目ID(振替元)
    AND    xmd.lot_id             = ir_masters_rec.from_lot_id               -- ロットID(振替元)
    ;
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
  END input_lot_del;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_del
   * Description      : 出力ロット割当削除(C-20)
   ***********************************************************************************/
  PROCEDURE output_lot_del(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_del'; -- プログラム名
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail_out  gme_material_details   %ROWTYPE;
    lr_tran_row_out         gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当削除API
    -- ======================================
    GME_API_PUB.DELETE_LINE_ALLOCATION (
      p_api_version        => GME_API_PUB.API_VERSION          -- IN         NUMBER := gme_api_pub.api_version
     ,p_validation_level   => GME_API_PUB.MAX_ERRORS           -- IN         NUMBER := gme_api_pub.max_errors
     ,p_init_msg_list      => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_commit             => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_trans_id           => ir_masters_rec.to_trans_id       -- IN         NUMBER
     ,p_scale_phantom      => FALSE                            -- IN         BOOLEAN DEFAULT FALSE
     ,x_material_detail    => lr_material_detail_out           -- OUT NOCOPY gme_material_details%ROWTYPE
     ,x_def_tran_row       => lr_tran_row_out                  -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
     ,x_message_count      => ln_message_count                 -- OUT NOCOPY NUMBER
     ,x_message_list       => lv_message_list                  -- OUT NOCOPY VARCHAR2
     ,x_return_status      => lv_return_status                 -- OUT NOCOPY VARCHAR2
    );
--
    -- 出力ロット割当追加処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_del);
      -- 共通関数例外ハンドラ
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- 移動ロット詳細データ削除
    -- ======================================
    DELETE xxinv_mov_lot_details xmld                                          -- 移動ロット詳細アドオン
    WHERE  xmld.mov_line_id        = ir_masters_rec.to_material_detail_id      -- 生産原料詳細ID(振替先)
    AND    xmld.item_id            = ir_masters_rec.to_item_id                 -- 品目ID(振替先)
    AND    xmld.lot_id             = ir_masters_rec.to_lot_id                  -- ロットID(振替先)
    AND    xmld.document_type_code = gv_doc_type_code_prod                     -- 文書タイプ
    AND    xmld.record_type_code   = gv_rec_type_code_plan                     -- レコードタイプ
    ;
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
  END output_lot_del;
--
  /**********************************************************************************
   * Procedure Name   : release_batch
   * Description      : リリースバッチ(C-33)
   ***********************************************************************************/
  PROCEDURE release_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'release_batch'; -- プログラム名
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
    lr_gme_batch_header           gme_batch_header%ROWTYPE;              --
    lr_gme_batch_header_temp      gme_batch_header%ROWTYPE;              --
    lr_unallocated_materials      GME_API_PUB.UNALLOCATED_MATERIALS_TAB; --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
      lr_gme_batch_header.batch_id          := ir_masters_rec.batch_id;
      lr_gme_batch_header.actual_start_date := ir_masters_rec.plan_start_date;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
      -- =========================================
      -- 生産バッチリリース
      -- =========================================
      GME_API_PUB.RELEASE_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS
      , p_init_msg_list                 =>  FALSE
      , p_commit                        =>  FALSE
      , x_message_count                 =>  ln_message_count
      , x_message_list                  =>  lv_message_list
      , x_return_status                 =>  lv_return_status
      , p_batch_header                  =>  lr_gme_batch_header
      , x_batch_header                  =>  lr_gme_batch_header_temp
      , p_ignore_shortages              =>  FALSE
      , p_consume_avail_plain_item      =>  FALSE
      , x_unallocated_material          =>  lr_unallocated_materials
      , p_ignore_unalloc                =>  TRUE
      );
--
    -- 出力ロット割当更新処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_release_batch);
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
  END release_batch;
--
  /**********************************************************************************
   * Procedure Name   : chk_and_ins_formula
   * Description      : フォーミュラ有無チェック 登録処理(C-28)
   ***********************************************************************************/
  PROCEDURE chk_and_ins_formula(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_and_ins_formula'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- フォーミュラ有無チェック(C-3)
    -- ===============================
    chk_formula(ir_masters_rec  -- 1.チェック対象レコード
              , lv_errbuf       -- エラー・メッセージ           --# 固定 #
              , lv_retcode      -- リターン・コード             --# 固定 #
              , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- フォーミュラが存在しない場合
    ELSIF ( NOT(ir_masters_rec.is_info_flg) ) THEN
--
      -- ===============================
      -- フォーミュラ登録(C-4)
      -- ===============================
      ins_formula(ir_masters_rec  -- 1.処理対象レコード
                , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                , lv_retcode      -- リターン・コード             --# 固定 #
                , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
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
  END chk_and_ins_formula;
--
  /**********************************************************************************
   * Procedure Name   : chk_and_ins_recipe
   * Description      : レシピ有無チェック 登録処理(C-29)
   ***********************************************************************************/
  PROCEDURE chk_and_ins_recipe(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_and_ins_recipe'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- レシピ有無チェック(C-5)
    -- ===============================
    chk_recipe(ir_masters_rec
             , lv_errbuf  -- エラー・メッセージ           --# 固定 #
             , lv_retcode -- リターン・コード             --# 固定 #
             , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーの場合
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- レシピが存在しない場合
    ELSIF ( NOT(ir_masters_rec.is_info_flg) ) THEN
      -- ===============================
      -- レシピ登録(C-6)
      -- ===============================
      ins_recipe(ir_masters_rec
               , lv_errbuf  -- エラー・メッセージ           --# 固定 #
               , lv_retcode -- リターン・コード             --# 固定 #
               , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
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
  END chk_and_ins_recipe;
-- 2009/06/02 H.Itou Add Start 本番障害#1517
  /**********************************************************************************
   * Procedure Name   : chk_and_ins_rule
   * Description      : 妥当性ルール有無チェック 登録処理(C-39)
   ***********************************************************************************/
  PROCEDURE chk_and_ins_rule(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_and_ins_rule'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 妥当性ルール有無チェック(C-37)
    -- ===============================
    chk_validity_rule(ir_masters_rec
                    , lv_errbuf  -- エラー・メッセージ           --# 固定 #
                    , lv_retcode -- リターン・コード             --# 固定 #
                    , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーの場合
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- レシピが存在しない場合
    ELSIF ( NOT(ir_masters_rec.is_info_flg) ) THEN
      -- ===============================
      -- 妥当性ルール登録(C-38)
      -- ===============================
      ins_validity_rule(ir_masters_rec
                      , lv_errbuf  -- エラー・メッセージ           --# 固定 #
                      , lv_retcode -- リターン・コード             --# 固定 #
                      , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
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
  END chk_and_ins_rule;
-- 2009/06/02 H.Itou Add End
--
  /**********************************************************************************
   * Procedure Name   : chk_and_ins_to_lot
   * Description      : 振替先ロット有無チェック 登録処理(C-30)
   ***********************************************************************************/
  PROCEDURE chk_and_ins_to_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_and_ins_to_lot'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- ロット有無チェック(C-7)
    -- ===============================
    chk_lot(ir_masters_rec             -- 1.チェック対象レコード
          , ir_masters_rec.lot_no      -- 2.ロットNo
          , ir_masters_rec.to_item_id  -- 3.品目ID(振替先)
          , ir_masters_rec.to_lot_id   -- 4.ロットID(振替元)
          , lv_errbuf       -- エラー・メッセージ           --# 固定 #
          , lv_retcode      -- リターン・コード             --# 固定 #
          , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
-- 2009/03/03 v1.3 ADD START
    ELSIF (ir_masters_rec.is_info_flg) THEN
      -- ===============================
      -- ロット更新(C-8-1)
      -- ===============================
      update_lot(ir_masters_rec             -- 処理対象レコード
               , lv_errbuf       -- エラー・メッセージ           --# 固定 #
               , lv_retcode      -- リターン・コード             --# 固定 #
               , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
-- 2009/03/03 v1.3 ADD END
    -- ロットが存在しない場合
    ELSIF ( NOT(ir_masters_rec.is_info_flg) ) THEN
--
      -- ===============================
      -- ロット作成(C-8-2)
      -- ===============================
      create_lot(ir_masters_rec  -- 1.処理対象レコード
               , lv_errbuf       -- エラー・メッセージ           --# 固定 #
               , lv_retcode      -- リターン・コード             --# 固定 #
               , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
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
  END chk_and_ins_to_lot;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_upd_ind
   * Description      : 入力ロット割当更新(完了)(C-31)
   ***********************************************************************************/
  PROCEDURE input_lot_upd_ind(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_upd_ind'; -- プログラム名
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
    lv_return_status    VARCHAR2(2);     -- リターンステータス
    ln_message_count    NUMBER;          -- メッセージカウント
    lv_msg_date         VARCHAR2(10000); -- メッセージ
    lv_message_list     VARCHAR2(200);   -- メッセージリスト
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・レコード ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.from_trans_id;  -- トランザクションID
    lr_tran_row_in.completed_ind := 1; -- 完了
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当更新API
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- 入力ロット割当更新処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_upd_ind);
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
  END input_lot_upd_ind;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_upd_ind
   * Description      : 出力ロット割当更新(完了)(C-32)
   ***********************************************************************************/
  PROCEDURE output_lot_upd_ind(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.処理対象レコード
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_upd_ind'; -- プログラム名
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
    l_data           VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.to_trans_id;    -- トランザクションID
    lr_tran_row_in.completed_ind := 1; -- 完了
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ロット割当更新API
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => ir_masters_rec.lot_no
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- 出力ロット割当更新処理が成功でない場合
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- エラーメッセージログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_upd_ind);
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
  END output_lot_upd_ind;
--
  /**********************************************************************************
   * Procedure Name   : chk_future_date
   * Description      : 未来日チェック(C-34)
   ***********************************************************************************/
  PROCEDURE chk_future_date(
    id_date        IN            DATE        -- チェック日付
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_future_date'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 日付が未来日の場合
    IF ( TRUNC(SYSDATE) < TRUNC(id_date) ) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10066
                                          , gv_tkn_ship_date
                                          , gv_tkn_item_date);
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
  END chk_future_date;
--
-- 2009/01/15 H.Itou Add Start 指摘2,7対応
  /**********************************************************************************
   * Procedure Name   : chk_qty_short_plan
   * Description      : 引当可能在庫不足チェック(予定)(C-35)
   ***********************************************************************************/
  PROCEDURE chk_qty_short_plan(
    ir_masters_rec    IN masters_rec                        -- 1.チェック対象レコード
  , id_standard_date  IN DATE                               -- 2.有効日付
  , in_before_qty     IN NUMBER                             -- 3.更新前数量
  , in_after_qty      IN NUMBER                             -- 4.登録数量
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_qty_short_plan'; -- プログラム名
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
    ln_can_enc_qty     NUMBER;  -- 引当可能数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 有効日ベース引当可能数
    ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_in_time_qty(
                         ir_masters_rec.inventory_location_id  -- 1.保管倉庫ID
                       , ir_masters_rec.to_item_id             -- 2.品目ID
                       , ir_masters_rec.to_lot_id              -- 3.ロットID
                       , id_standard_date);                    -- 4.有効日付
--
    -- 引当可能数が不足する場合
    IF ( ln_can_enc_qty - in_before_qty + in_after_qty < 0) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10184
                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
                                          , gv_tkn_item          , ir_masters_rec.to_item_no
                                          , gv_tkn_lot           , ir_masters_rec.lot_no
                                          , gv_tkn_standard_date , TO_CHAR(id_standard_date, gv_yyyymmdd));
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
  END chk_qty_short_plan;
--
  /**********************************************************************************
   * Procedure Name   : chk_location
   * Description      : 保管倉庫チェック(C-36)
   ***********************************************************************************/
  PROCEDURE chk_location(
    it_location_code_01   IN xxcmn_item_locations_v.segment1%TYPE -- 1.保管倉庫01
  , it_location_code_02   IN xxcmn_item_locations_v.segment1%TYPE -- 2.保管倉庫02
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_location'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
    -- 保管倉庫が異なる場合、エラー
    IF (it_location_code_01 <> it_location_code_02) THEN
      -- エラーメッセージを取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10183);
      RAISE global_api_expt;
    END IF;
--
--###########################  固定部 END   ############################
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
  END chk_location;
-- 2009/01/15 H.Itou Add End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_process_type   IN          VARCHAR2 --  1.処理区分(1:予定,2:予定訂正,3:予定取消,4:実績)
  , iv_plan_batch_id  IN          VARCHAR2 --  2.バッチID(予定)
  , iv_inv_loc_code   IN          VARCHAR2 --  3.保管倉庫コード
  , iv_from_item_no   IN          VARCHAR2 --  4.振替元品目No
  , iv_lot_no         IN          VARCHAR2 --  5.振替元ロットNo
  , iv_to_item_no     IN          VARCHAR2 --  6.振替先品目No
  , iv_quantity       IN          VARCHAR2 --  7.数量
  , id_sysdate        IN          DATE     --  8.品目振替日
  , iv_remarks        IN          VARCHAR2 --  9.摘要
  , iv_item_chg_aim   IN          VARCHAR2 -- 10.品目振替目的
  , ov_errbuf         OUT  NOCOPY VARCHAR2 --  エラー・メッセージ           --# 固定 #
  , ov_retcode        OUT  NOCOPY VARCHAR2 --  リターン・コード             --# 固定 #
  , ov_errmsg         OUT  NOCOPY VARCHAR2)--  ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lr_masters_rec masters_rec;                   -- 処理対象データ格納レコード
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
    lr_masters_rec.process_type            := iv_process_type;        -- 処理区分
    lr_masters_rec.plan_batch_id           := iv_plan_batch_id;       -- バッチID(予定)
    lr_masters_rec.inventory_location_code := iv_inv_loc_code;        -- 保管倉庫コード
    lr_masters_rec.from_item_no            := iv_from_item_no;        -- 振替元品目No
    lr_masters_rec.lot_no                  := iv_lot_no;              -- ロットNo
    lr_masters_rec.to_item_no              := iv_to_item_no;          -- 振替先品目No
    lr_masters_rec.qty                     := TO_NUMBER(iv_quantity); -- 数量
    lr_masters_rec.item_sysdate            := id_sysdate;             -- 品目振替日
    lr_masters_rec.remarks                 := iv_remarks;             -- 摘要
    lr_masters_rec.item_chg_aim            := iv_item_chg_aim;        -- 品目振替目的
--
    -- 処理区分[4:実績]かつ生産バッチNo(予定)に指定がない場合、処理区分を[5:実績(生産バッチNo指定なし)]に変更
    IF ( ( lr_masters_rec.process_type = gv_actual )
    AND  ( lr_masters_rec.plan_batch_id IS NULL ) ) THEN
      lr_masters_rec.process_type := gv_actual_new;
    END IF;
--
    -- 処理件数の設定
    gn_target_cnt := 1;
--
    -- ===============================
    -- 初期処理(C-0)
    -- ===============================
    init_proc(lr_masters_rec -- 1.処理対象レコード
            , lv_errbuf      -- エラー・メッセージ           --# 固定 #
            , lv_retcode     -- リターン・コード             --# 固定 #
            , lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ************************************************* --
    -- ** 処理種別が「1：予定」の場合                 ** --
    -- ************************************************* --
    IF ( lr_masters_rec.process_type = gv_plan_new ) THEN
--
      -- ===============================
      -- 必須チェック(新規)(C-1-1)
      -- ===============================
      chk_param_new(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- マスタ存在チェック(C-22)
      -- ===============================
      chk_mst_data(lr_masters_rec  -- 1.チェック対象レコード
                 , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                 , lv_retcode      -- リターン・コード             --# 固定 #
                 , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 在庫クローズチェック(C-23)
      -- ===============================
      chk_close_period(id_sysdate  -- 1.比較日付 = 品目振替日
                     , lv_errbuf                    -- エラー・メッセージ           --# 固定 #
                     , lv_retcode                   -- リターン・コード             --# 固定 #
                     , lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 引当可能数超過チェック(予定)(C-24)
      -- ===============================
      -- 振替元品目 出庫数新規チェック
      chk_qty_over_plan(lr_masters_rec                       -- 1.チェック対象レコード
-- 2009/01/15 H.Itou Add Start 指摘2対応
                      , id_sysdate                           -- 2.有効日付
                      , 0                                    -- 3.更新前数量
                      , TO_NUMBER(iv_quantity)               -- 4.登録数量
-- 2009/01/15 H.Itou Add End
                      , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                      , lv_retcode      -- リターン・コード             --# 固定 #
                      , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ====================================
      -- 工順有無チェック(C-2)
      -- ====================================
      chk_routing(lr_masters_rec -- 1.処理対象レコード
                , lv_errbuf      -- エラー・メッセージ           --# 固定 #
                , lv_retcode     -- リターン・コード             --# 固定 #
                , lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- フォーミュラ有無チェック 登録処理(C-28)
      -- ===============================
      chk_and_ins_formula(lr_masters_rec  -- 1.処理対象レコード
                        , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                        , lv_retcode      -- リターン・コード             --# 固定 #
                        , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- レシピ有無チェック 登録処理(C-29)
      -- ===============================
      chk_and_ins_recipe(lr_masters_rec
                       , lv_errbuf  -- エラー・メッセージ           --# 固定 #
                       , lv_retcode -- リターン・コード             --# 固定 #
                       , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/06/02 H.Itou Add Start 本番障害#1517 妥当性ルール登録をレシピ登録から分離
      -- ===============================
      -- 妥当性ルール有無チェック 登録処理(C-39)
      -- ===============================
      chk_and_ins_rule(lr_masters_rec
                     , lv_errbuf  -- エラー・メッセージ           --# 固定 #
                     , lv_retcode -- リターン・コード             --# 固定 #
                     , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/06/02 H.Itou Add End
--
      -- ===============================
      -- 振替先ロット有無チェック 登録処理(C-30)
      -- ===============================
      chk_and_ins_to_lot(lr_masters_rec  -- 1.処理対象レコード
                       , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                       , lv_retcode      -- リターン・コード             --# 固定 #
                       , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチ作成(C-9)
      -- ===============================
      create_batch(lr_masters_rec  -- 1.処理対象レコード
                 , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                 , lv_retcode      -- リターン・コード             --# 固定 #
                 , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 入力ロット割当追加(C-10)
      -- ===============================
      input_lot_ins(lr_masters_rec  -- 1.処理対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 出力ロット割当追加(C-11)
      -- ===============================
      output_lot_ins(lr_masters_rec  -- 1.処理対象レコード
                   , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                   , lv_retcode      -- リターン・コード             --# 固定 #
                   , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    -- ************************************************* --
    -- ** 処理種別が「2：予定訂正」の場合             ** --
    -- ************************************************* --
    ELSIF ( lr_masters_rec.process_type = gv_plan_change ) THEN
      -- ===============================
      -- 必須チェック(更新)(C-1-2)
      -- ===============================
      chk_param_upd(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチデータ取得(C-26)
      -- ===============================
      -- 生産バッチNoに紐付く前回登録分のバッチデータを取得
      get_batch_data(lr_masters_rec  -- 1.チェック対象レコード
                   , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                   , lv_retcode      -- リターン・コード             --# 固定 #
                   , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Add Start 指摘7
      -- ===============================
      -- 保管倉庫チェック(C-36)
      -- ===============================
      chk_location( lr_masters_rec.inventory_location_code  -- 生産バッチに登録済の保管倉庫
                  , iv_inv_loc_code                         -- INパラメータ.保管倉庫
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- 品目データ取得(C-27)
      -- ===============================
      -- 生産バッチNoに紐付く前回登録分の品目データ・ロットデータを取得
      get_item_data(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/03/03 v1.3 DELETE START
--      -- ===============================
--      -- 在庫クローズチェック(C-23)
--      -- ===============================
--      -- 生産バッチNoに紐付く前回登録分の生産予定日のクローズチェック
--      chk_close_period(lr_masters_rec.plan_start_date  -- 1.比較日付 = 生産予定日
--                     , lv_errbuf                       -- エラー・メッセージ           --# 固定 #
--                     , lv_retcode                      -- リターン・コード             --# 固定 #
--                     , lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
----
--      -- エラーの場合
--      IF ( lv_retcode = gv_status_error ) THEN
--        gn_error_cnt := gn_error_cnt + 1;
--        RAISE global_process_expt;
--      END IF;
----
-- 2009/03/03 v1.3 DELETE END
-- 2009/01/15 H.Itou Del Start 指摘2対応
--      -- 数量に変更がある場合
--      IF (lr_masters_rec.trans_qty <> TO_NUMBER(iv_quantity)) THEN
--        -- ===============================
--        -- 引当可能数超過チェック(予定)(C-24)
--        -- ===============================
--        -- 生産バッチNoに紐付く前回登録分の数量と入力した数量の差分で在庫数量チェック
--        chk_qty_over_plan(lr_masters_rec  -- 1.チェック対象レコード
--                   , lv_errbuf       -- エラー・メッセージ           --# 固定 #
--                   , lv_retcode      -- リターン・コード             --# 固定 #
--                   , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
----
--        -- エラーの場合
--        IF ( lv_retcode = gv_status_error ) THEN
--          gn_error_cnt := gn_error_cnt + 1;
--          RAISE global_process_expt;
--        END IF;
----
--      -- 数量に変更がない場合
--      ELSE
--        -- パラメータ.数量に前回登録分の数量をセット
--        lr_masters_rec.qty := lr_masters_rec.trans_qty;
--      END IF;
-- 2009/01/15 H.Itou Del End
-- 2009/01/15 H.Itou Add Start 指摘2対応
      -- 品目振替日(後倒し)かロットNoに変更がある場合
      -- 登録済みのデータ内容を取り消しても引当可能数が不足しないか振替先品目をチェック
      IF ( lr_masters_rec.plan_start_date < id_sysdate )
      OR ( lr_masters_rec.lot_no         <> iv_lot_no ) THEN
        -- ===============================
        -- 引当可能在庫不足チェック(予定)(C-35)
        -- ===============================
        -- 振替先品目 入庫取消チェック
        chk_qty_short_plan(lr_masters_rec                       -- 1.チェック対象レコード
                         , lr_masters_rec.plan_start_date       -- 2.有効日付
                         , lr_masters_rec.trans_qty             -- 3.更新前数量
                         , 0                                    -- 4.登録数量
                         , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                         , lv_retcode      -- リターン・コード             --# 固定 #
                         , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
      -- 数量のみ変更がある場合
      -- 登録済みのデータ内容との数量の差分を考慮して引当可能数が超過・不足しないか振替元品目・振替先品目をチェック
      ELSIF ( lr_masters_rec.trans_qty <> TO_NUMBER(iv_quantity) ) THEN
        -- ===============================
        -- 引当可能数超過チェック(予定)(C-24)
        -- ===============================
        -- 振替元品目 出庫数差分チェック
        chk_qty_over_plan(lr_masters_rec                       -- 1.チェック対象レコード
                        , lr_masters_rec.plan_start_date       -- 2.有効日付
                        , lr_masters_rec.trans_qty             -- 3.更新前数量
                        , TO_NUMBER(iv_quantity)               -- 4.登録数量
                        , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                        , lv_retcode      -- リターン・コード             --# 固定 #
                        , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 引当可能在庫不足チェック(予定)(C-35)
        -- ===============================
        -- 振替先品目 入庫数差分チェック
        chk_qty_short_plan(lr_masters_rec                       -- 1.チェック対象レコード
                         , lr_masters_rec.plan_start_date       -- 2.有効日付
                         , lr_masters_rec.trans_qty             -- 3.更新前数量
                         , TO_NUMBER(iv_quantity)               -- 4.登録数量
                         , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                         , lv_retcode      -- リターン・コード             --# 固定 #
                         , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- 品目振替日が変更された場合
      IF ( lr_masters_rec.plan_start_date <> id_sysdate ) THEN
        -- ===============================
        -- 在庫クローズチェック(C-23)
        -- ===============================
        -- パラメータ.品目振替日のクローズチェック
        chk_close_period(id_sysdate  -- 1.比較日付 = 品目振替日
                       , lv_errbuf                    -- エラー・メッセージ           --# 固定 #
                       , lv_retcode                   -- リターン・コード             --# 固定 #
                       , lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
-- 2009/01/15 H.Itou Add Start 指摘2対応
        IF ( iv_lot_no IS NULL) THEN -- ロットNoに変更がある場合、変更するロットIDが決まってからチェックを行うので、ここではチェックしない。
          -- ===============================
          -- 引当可能数超過チェック(予定)(C-24)
          -- ===============================
          -- 振替元品目 出庫数新規チェック
          chk_qty_over_plan(lr_masters_rec                       -- 1.チェック対象レコード
                          , id_sysdate                           -- 2.有効日付
                          , 0                                                      -- 3.更新前数量
                          , NVL(TO_NUMBER(iv_quantity), lr_masters_rec.trans_qty)  -- 4.登録数量
                          , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                          , lv_retcode      -- リターン・コード             --# 固定 #
                          , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
            -- エラーの場合
            IF ( lv_retcode = gv_status_error ) THEN
              gn_error_cnt := gn_error_cnt + 1;
              RAISE global_process_expt;
            END IF;
          END IF;
-- 2009/01/15 H.Itou Add End
        -- ===============================
        -- バッチ再スケジュール(C-16)
        -- ===============================
-- 2009/01/15 H.Itou Del Start 指摘2対応
--        -- 生産予定日にパラメータ.品目振替日をセット
--        lr_masters_rec.plan_start_date := lr_masters_rec.item_sysdate;
-- 2009/01/15 H.Itou Del End
--
        reschedule_batch(lr_masters_rec  -- 1.処理対象レコード
                       , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                       , lv_retcode      -- リターン・コード             --# 固定 #
                       , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
-- 2009/01/15 H.Itou Del Start 指摘2対応
--      -- 品目振替日に変更がない場合
--      ELSE
--        -- パラメータ.品目振替日に生産予定日をセット
--        lr_masters_rec.item_sysdate := lr_masters_rec.plan_start_date;
-- 2009/01/15 H.Itou Del End
      END IF;
--
      -- ロットNoが変更された場合
      IF ( lr_masters_rec.lot_no   <> iv_lot_no ) THEN
        -- ===============================
        -- 入力ロット割当削除(C-19)
        -- ===============================
        -- 前回登録分の削除
        input_lot_del(lr_masters_rec  -- 1.処理対象レコード
                    , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                    , lv_retcode      -- リターン・コード             --# 固定 #
                    , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 出力ロット割当削除(C-20)
        -- ===============================
        -- 前回登録分の削除
        output_lot_del(lr_masters_rec  -- 1.処理対象レコード
                     , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                     , lv_retcode      -- リターン・コード             --# 固定 #
                     , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- ロット有無チェック(C-7)(振替元)
        -- ===============================
        -- ロットNoにパラメータ.ロットNoをセット
        lr_masters_rec.lot_no := iv_lot_no;
--
        -- 新規登録ロットNoで振替元ロットがあるかチェック。
        chk_lot(lr_masters_rec               -- 1.チェック対象レコード
              , lr_masters_rec.lot_no        -- 2.ロットNo
              , lr_masters_rec.from_item_id  -- 3.品目ID(振替元)
              , lr_masters_rec.from_lot_id   -- 4.ロットID(振替元)
              , lv_errbuf       -- エラー・メッセージ           --# 固定 #
              , lv_retcode      -- リターン・コード             --# 固定 #
              , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
--
        -- ロットが存在しない場合
        ELSIF ( NOT(lr_masters_rec.is_info_flg) ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                              , gv_msg_52a_17);
          RAISE global_process_expt;
        END IF;
--
-- 2009/01/15 H.Itou Add Start 指摘2対応
        -- ===============================
        -- 引当可能数超過チェック(予定)(C-24)
        -- ===============================
        -- 振替元品目 出庫数新規チェック
        chk_qty_over_plan(lr_masters_rec                       -- 1.チェック対象レコード
                        , NVL(id_sysdate, lr_masters_rec.plan_start_date)       -- 2.有効日付
                        , 0                                                     -- 3.更新前数量
                        , NVL(TO_NUMBER(iv_quantity), lr_masters_rec.trans_qty) -- 4.登録数量
                        , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                        , lv_retcode      -- リターン・コード             --# 固定 #
                        , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合
          IF ( lv_retcode = gv_status_error ) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
-- 2009/01/15 H.Itou Add End
--
        -- ===============================
        -- 振替先ロット有無チェック 登録処理(C-30)
        -- ===============================
        -- 新規登録ロットNoで振替先ロットがあるかチェック。なければ作成
        chk_and_ins_to_lot(lr_masters_rec  -- 1.処理対象レコード
                         , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                         , lv_retcode      -- リターン・コード             --# 固定 #
                         , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 入力ロット割当追加(C-10)
        -- ===============================
        -- 新規ロットNoで再登録
        input_lot_ins(lr_masters_rec  -- 1.処理対象レコード
                    , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                    , lv_retcode      -- リターン・コード             --# 固定 #
                    , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 出力ロット割当追加(C-11)
        -- ===============================
        -- 新規ロットNoで再登録
        output_lot_ins(lr_masters_rec  -- 1.処理対象レコード
                     , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                     , lv_retcode      -- リターン・コード             --# 固定 #
                     , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
      ELSE
        -- 数量が変更された場合
        IF (lr_masters_rec.trans_qty <> TO_NUMBER(iv_quantity)) THEN
          -- ===============================
          -- 入力ロット割当更新(C-17)
          -- ===============================
          input_lot_upd(lr_masters_rec  -- 1.処理対象レコード
                      , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                      , lv_retcode      -- リターン・コード             --# 固定 #
                      , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合
          IF ( lv_retcode = gv_status_error ) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 出力ロット割当更新(C-18)
          -- ===============================
          output_lot_upd(lr_masters_rec  -- 1.処理対象レコード
                       , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                       , lv_retcode      -- リターン・コード             --# 固定 #
                       , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合
          IF ( lv_retcode = gv_status_error ) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    -- ************************************************* --
    -- ** 処理種別が「3：予定取消」の場合             ** --
    -- ************************************************* --
    ELSIF ( lr_masters_rec.process_type = gv_plan_cancel ) THEN
      -- ===============================
      -- 必須チェック(更新)(C-1-2)
      -- ===============================
      chk_param_upd(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチデータ取得(C-26)
      -- ===============================
      get_batch_data(lr_masters_rec  -- 1.チェック対象レコード
                   , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                   , lv_retcode      -- リターン・コード             --# 固定 #
                   , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Add Start 指摘2対応
      -- ===============================
      -- 保管倉庫チェック(C-36)
      -- ===============================
      chk_location( lr_masters_rec.inventory_location_code  -- 生産バッチに登録済の保管倉庫
                  , iv_inv_loc_code                         -- INパラメータ.保管倉庫
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
-- 2009/01/15 H.Itou Add Start 指摘7対応
      -- ===============================
      -- 品目データ取得(C-27)
      -- ===============================
      -- 生産バッチNoに紐付く前回登録分の品目データ・ロットデータを取得
      get_item_data(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 引当可能在庫不足チェック(予定)(C-35)
      -- ===============================
      -- 振替先品目 入庫取消チェック
      chk_qty_short_plan(lr_masters_rec                       -- 1.チェック対象レコード
                       , lr_masters_rec.plan_start_date       -- 2.有効日付
                       , lr_masters_rec.trans_qty             -- 3.更新前数量
                       , 0                                    -- 4.登録数量
                       , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                       , lv_retcode      -- リターン・コード             --# 固定 #
                       , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- バッチ取消(C-15)
      -- ===============================
      cancel_batch(lr_masters_rec  -- 1.処理対象レコード
                 , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                 , lv_retcode      -- リターン・コード             --# 固定 #
                 , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    -- *************************************************** --
    -- ** 処理種別が「4：実績(生産バッチNoあり)」の場合 ** --
    -- *************************************************** --
    ELSIF ( lr_masters_rec.process_type = gv_actual ) THEN
      -- ===============================
      -- 必須チェック(更新)(C-1-2)
      -- ===============================
      chk_param_upd(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチデータ取得(C-26)
      -- ===============================
      get_batch_data(lr_masters_rec  -- 1.チェック対象レコード
                   , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                   , lv_retcode      -- リターン・コード             --# 固定 #
                   , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Add Start 指摘2対応
      -- ===============================
      -- 保管倉庫チェック(C-36)
      -- ===============================
      chk_location( lr_masters_rec.inventory_location_code  -- 生産バッチに登録済の保管倉庫
                  , iv_inv_loc_code                         -- INパラメータ.保管倉庫
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- 品目データ取得(C-27)
      -- ===============================
      -- 生産バッチNoに紐付く前回登録分の品目データ・ロットデータを取得
      get_item_data(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/03/03 v1.3 ADD START
      -- ===============================
      -- ロット更新(C-8-1)
      -- ===============================
      update_lot(lr_masters_rec             -- 処理対象レコード
               , lv_errbuf       -- エラー・メッセージ           --# 固定 #
               , lv_retcode      -- リターン・コード             --# 固定 #
               , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
-- 2009/03/03 v1.3 ADD END
      -- ===============================
      -- 在庫クローズチェック(C-23)
      -- ===============================
      chk_close_period(lr_masters_rec.plan_start_date  -- 1.比較日付 = 生産予定日
                     , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                     , lv_retcode      -- リターン・コード             --# 固定 #
                     , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 未来日チェック(C-34)
      -- ===============================
      chk_future_date(lr_masters_rec.plan_start_date  -- 1.比較日付 = 生産予定日
                    , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                    , lv_retcode      -- リターン・コード             --# 固定 #
                    , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/03/19 v1.4 UPDATE START
--
---- 2009/01/15 H.Itou Add Start 指摘8対応
--      -- ===============================
--      -- 引当可能数超過チェック(実績)(C-25)
--      -- ===============================
--      -- 振替元品目 出庫数新規チェック(出庫予定数として登録済みなので、減算しない)
--      chk_qty_over_actual(lr_masters_rec                 -- 1.チェック対象レコード
--                        , lr_masters_rec.plan_start_date -- 2.有効日付
--                        , 0                              -- 3.実績数量
--                        , lv_errbuf       -- エラー・メッセージ           --# 固定 #
--                        , lv_retcode      -- リターン・コード             --# 固定 #
--                        , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
----
--      -- エラーの場合
--      IF ( lv_retcode = gv_status_error ) THEN
--        gn_error_cnt := gn_error_cnt + 1;
--        RAISE global_process_expt;
--      END IF;
---- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- マイナス在庫チェック(C-37)
      -- ===============================
      chk_minus_qty(lr_masters_rec                 -- 1.チェック対象レコード
                  , lr_masters_rec.trans_qty       -- 2.予定数量
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/03/19 v1.4 UPDATE END
--
      -- ===============================
      -- リリースバッチ(C-33)
      -- ===============================
      release_batch(lr_masters_rec  -- 1.処理対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 入力ロット割当更新(完了)(C-31)
      -- ===============================
      input_lot_upd_ind(lr_masters_rec  -- 1.処理対象レコード
                      , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                      , lv_retcode      -- リターン・コード             --# 固定 #
                      , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 出力ロット割当更新(完了)(C-32)
      -- ===============================
      output_lot_upd_ind(lr_masters_rec  -- 1.処理対象レコード
                       , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                       , lv_retcode      -- リターン・コード             --# 固定 #
                       , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチ完了(C-12)
      -- ===============================
      cmpt_batch(lr_masters_rec  -- 1.処理対象レコード
               , lv_errbuf       -- エラー・メッセージ           --# 固定 #
               , lv_retcode      -- リターン・コード             --# 固定 #
               , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチクローズ(C-13)
      -- ===============================
      close_batch(lr_masters_rec  -- 1.処理対象レコード
                , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                , lv_retcode      -- リターン・コード             --# 固定 #
                , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    -- ******************************************************* --
    -- ** 処理種別が「5：実績(生産バッチNo指定なし)」の場合 ** --
    -- ******************************************************* --
    ELSIF ( lr_masters_rec.process_type = gv_actual_new ) THEN
--
      -- ===============================
      -- 必須チェック(新規)(C-1-1)
      -- ===============================
      chk_param_new(lr_masters_rec  -- 1.チェック対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- マスタ存在チェック(C-22)
      -- ===============================
      chk_mst_data(lr_masters_rec  -- 1.チェック対象レコード
                 , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                 , lv_retcode      -- リターン・コード             --# 固定 #
                 , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 在庫クローズチェック(C-23)
      -- ===============================
      chk_close_period(id_sysdate  -- 1.比較日付 = 品目振替日
                     , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                     , lv_retcode      -- リターン・コード             --# 固定 #
                     , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 未来日チェック(C-34)
      -- ===============================
      chk_future_date(id_sysdate  -- 1.比較日付 = 品目振替日
                    , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                    , lv_retcode      -- リターン・コード             --# 固定 #
                    , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/03/19 v1.4 UPDATE START
--      -- ===============================
--      -- 引当可能数超過チェック(実績)(C-25)
--      -- ===============================
--      -- 振替元品目 出庫数新規チェック
--      chk_qty_over_actual(lr_masters_rec          -- 1.チェック対象レコード
---- 2009/01/15 H.Itou Add Start 指摘2対応
--                        , id_sysdate              -- 2.有効日付
--                        , TO_NUMBER(iv_quantity)  -- 3.実績数量
---- 2009/01/15 H.Itou Add End
--                        , lv_errbuf       -- エラー・メッセージ           --# 固定 #
--                        , lv_retcode      -- リターン・コード             --# 固定 #
--                        , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
----
--      -- エラーの場合
--      IF ( lv_retcode = gv_status_error ) THEN
--        gn_error_cnt := gn_error_cnt + 1;
--        RAISE global_process_expt;
--      END IF;
----
--
      -- ===============================
      -- マイナス在庫チェック(C-37)
      -- ===============================
      chk_minus_qty(lr_masters_rec                 -- 1.チェック対象レコード
                  , TO_NUMBER(iv_quantity)         -- 2.実績数量
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 引当可能数超過チェック(実績)
      -- ===============================
      -- 振替元品目 出庫数新規チェック
      chk_qty_over_actual(lr_masters_rec          -- 1.チェック対象レコード
                        , id_sysdate              -- 2.有効日付
                        , TO_NUMBER(iv_quantity)  -- 3.実績数量
                        , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                        , lv_retcode      -- リターン・コード             --# 固定 #
                        , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/03/19 v1.4 UPDATE END
      -- ====================================
      -- 工順有無チェック(C-2)
      -- ====================================
      chk_routing(lr_masters_rec -- 1.処理対象レコード
                , lv_errbuf      -- エラー・メッセージ           --# 固定 #
                , lv_retcode     -- リターン・コード             --# 固定 #
                , lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- フォーミュラ有無チェック 登録処理(C-28)
      -- ===============================
      chk_and_ins_formula(lr_masters_rec  -- 1.処理対象レコード
                        , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                        , lv_retcode      -- リターン・コード             --# 固定 #
                        , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- レシピ有無チェック 登録処理(C-29)
      -- ===============================
      chk_and_ins_recipe(lr_masters_rec
                       , lv_errbuf  -- エラー・メッセージ           --# 固定 #
                       , lv_retcode -- リターン・コード             --# 固定 #
                       , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/06/02 H.Itou Add Start 本番障害#1517 妥当性ルール登録をレシピ登録から分離
      -- ===============================
      -- 妥当性ルール有無チェック 登録処理(C-39)
      -- ===============================
      chk_and_ins_rule(lr_masters_rec
                     , lv_errbuf  -- エラー・メッセージ           --# 固定 #
                     , lv_retcode -- リターン・コード             --# 固定 #
                     , lv_errmsg);-- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/06/02 H.Itou Add End
      -- ===============================
      -- 振替先ロット有無チェック 登録処理(C-30)
      -- ===============================
      chk_and_ins_to_lot(lr_masters_rec  -- 1.処理対象レコード
                       , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                       , lv_retcode      -- リターン・コード             --# 固定 #
                       , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチ作成(C-9)
      -- ===============================
      create_batch(lr_masters_rec  -- 1.処理対象レコード
                 , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                 , lv_retcode      -- リターン・コード             --# 固定 #
                 , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- リリースバッチ(C-33)
      -- ===============================
      -- 生産予定日にパラメータ.品目振替日をセット
      lr_masters_rec.plan_start_date := id_sysdate;
--
      release_batch(lr_masters_rec  -- 1.処理対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 入力ロット割当追加(C-10)
      -- ===============================
      input_lot_ins(lr_masters_rec  -- 1.処理対象レコード
                  , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                  , lv_retcode      -- リターン・コード             --# 固定 #
                  , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 出力ロット割当追加(C-11)
      -- ===============================
      output_lot_ins(lr_masters_rec  -- 1.処理対象レコード
                   , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                   , lv_retcode      -- リターン・コード             --# 固定 #
                   , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチ完了(C-12)
      -- ===============================
      cmpt_batch(lr_masters_rec  -- 1.処理対象レコード
               , lv_errbuf       -- エラー・メッセージ           --# 固定 #
               , lv_retcode      -- リターン・コード             --# 固定 #
               , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- バッチクローズ(C-13)
      -- ===============================
      close_batch(lr_masters_rec  -- 1.処理対象レコード
                , lv_errbuf       -- エラー・メッセージ           --# 固定 #
                , lv_retcode      -- リターン・コード             --# 固定 #
                , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- バッチ保存(C-14)
    -- ===============================
    save_batch(lr_masters_rec  -- 1.処理対象レコード
             , lv_errbuf       -- エラー・メッセージ           --# 固定 #
             , lv_retcode      -- リターン・コード             --# 固定 #
             , lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 正常終了時出力
    -- ===============================
    -- 生産バッチNo
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_52
                                            , gv_tkn_value
                                            , lr_masters_rec.batch_no);
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
    errbuf             OUT NOCOPY VARCHAR2 -- エラーメッセージ #固定#
  , retcode            OUT NOCOPY VARCHAR2 -- エラーコード     #固定#
  , iv_process_type    IN         VARCHAR2 --  1.処理区分(1:予定,2:予定訂正,3:予定取消,4:実績)
  , iv_plan_batch_id   IN         VARCHAR2 --  2.バッチID(予定)
  , iv_inv_loc_code    IN         VARCHAR2 --  3.保管倉庫コード
  , iv_from_item_no    IN         VARCHAR2 --  4.振替元品目No
  , iv_lot_no          IN         VARCHAR2 --  5.ロットNo
  , iv_to_item_no      IN         VARCHAR2 --  6.振替先品目No
  , iv_quantity        IN         VARCHAR2 --  7.数量
  , iv_sysdate         IN         VARCHAR2 --  8.品目振替日
  , iv_remarks         IN         VARCHAR2 --  9.摘要
  , iv_item_chg_aim    IN         VARCHAR2 -- 10.品目振替目的
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
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    lv_normal_msg VARCHAR2(5000);  -- 必須出力メッセージ
    lv_aim_mean   VARCHAR2(20);    -- 品目振替目的 摘要
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
    AND    ROWNUM                    = 1
    ;
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    -- submainの呼び出し
    submain(
        iv_process_type                                   --  1.処理区分(1:予定,2:予定訂正,3:予定取消,4:実績)
      , iv_plan_batch_id                                  --  2.バッチID(予定)
      , iv_inv_loc_code                                   --  3.保管倉庫ID
      , iv_from_item_no                                   --  4.振替元品目ID
      , iv_lot_no                                         --  5.ロットID
      , iv_to_item_no                                     --  6.振替先品目ID
      , iv_quantity                                       --  7.数量
      , FND_DATE.STRING_TO_DATE(iv_sysdate, gv_yyyymmdd)  --  8.品目振替日
      , iv_remarks                                        --  9.摘要
      , iv_item_chg_aim                                   -- 10.品目振替目的
      , lv_errbuf                                         --  エラー・メッセージ           --# 固定 #
      , lv_retcode                                        --  リターン・コード             --# 固定 #
      , lv_errmsg);                                       --  ユーザー・エラー・メッセージ --# 固定 #
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ===============================
    -- 必須出力項目
    -- ===============================
    -- パラメータ処理区分入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_77
                                            , gv_tkn_value
                                            , iv_process_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータバッチID(予定)入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_52
                                            , gv_tkn_value
                                            , gv_plan_batch_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ保管倉庫入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_45
                                            , gv_tkn_value
                                            , iv_inv_loc_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ振替元品目入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_46
                                            , gv_tkn_value
                                            , iv_from_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ振替元ロットNo入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_47
                                            , gv_tkn_value
                                            , iv_lot_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ振替先品目入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_48
                                            , gv_tkn_value
                                            , iv_to_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ数量入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_49
                                            , gv_tkn_value
                                            , iv_quantity);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ品目振替日入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_50
                                            , gv_tkn_value
                                            , iv_sysdate);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ摘要入力値
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_51
                                            , gv_tkn_value
                                            , iv_remarks);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- パラメータ品目振替目的
    -- 品目振替目的の摘要を取得
    BEGIN
      SELECT flvv.meaning            -- 摘要
      INTO   lv_aim_mean
      FROM   xxcmn_lookup_values_v flvv  -- ルックアップVIEW
      WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
      AND    flvv.lookup_code  = iv_item_chg_aim
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- データ取得エラー
        -- 品目振替目的のコードを出力
        lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                                , gv_msg_52a_57
                                                , gv_tkn_value
                                                , iv_item_chg_aim);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    END;
--
    -- データが取得できた場合は品目振替目的の摘要を出力
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_57
                                            , gv_tkn_value
                                            , lv_aim_mean);
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
    IF ( retcode = gv_status_error ) THEN
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
END xxinv520003c;
/
