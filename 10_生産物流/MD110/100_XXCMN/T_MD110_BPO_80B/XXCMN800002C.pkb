CREATE OR REPLACE PACKAGE BODY xxcmn800002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800002c(body)
 * Description      : 品目マスタインタフェース
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 品目インタフェース T_MD070_BPO_80B
 * Version          : 1.19
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_mtl_categories    品目カテゴリマスタの登録処理  2008/09/16 Add
 *  get_profile            プロファイル取得プロシージャ
 *  set_if_lock            インタフェーステーブルに対するロック取得プロシージャ
 *  set_error_status       エラーが発生した状態にするプロシージャ
 *  set_warn_status        警告が発生した状態にするプロシージャ
 *  set_warok_status       警告が発生した状態にするプロシージャ
 *  init_status            ステータス初期化プロシージャ
 *  is_file_status_nomal   ファイルレベルで正常か状況を確認するファンクション
 *  init_row_status        行レベルステータス初期化プロシージャ
 *  is_row_status_nomal    行レベルで正常か状況を確認するファンクション
 *  is_row_status_warn     行レベルで警告か状況を確認するファンクション
 *  is_row_status_warok    行レベルで警告か状況を確認するファンクション
 *  add_report             レポート用データを設定するプロシージャ
 *  disp_report            レポート用データを出力するプロシージャ
 *  get_xxcmn_item_if      品目インタフェースの以前の件数取得を行うプロシージャ
 *  chk_ic_item_mst_b      品目コードの存在チェックを行うプロシージャ(OPM品目マスタ)
 *  chk_xxcmn_item_mst_b   品目コードの存在チェックを行うプロシージャ(OPM品目アドオンマスタ)
 *  chk_gmi_item_category  品目コードの存在チェックを行うプロシージャ(OPM品目カテゴリ割当)
 *  chk_cm_cmpt_dtl        品目コードの存在チェックを行うプロシージャ(品目原価マスタ)
 *  chk_parent_id          親品目コードの存在チェックを行うプロシージャ
 *  check_proc_code        操作対象のレコードであることをチェックするプロシージャ
 *  init_cmpntcls_id       コンポーネント区分IDの初期取得を行うプロシージャ
 *  get_price              単価の取得を行うプロシージャ
 *  get_item_id            品目IDの取得を行うプロシージャ
 *  get_parent_id          親品目IDの取得を行うプロシージャ
 *  get_period_code        期間の取得を行うプロシージャ
 *  get_uom_code           単位の取得を行うプロシージャ
 *  get_cmpnt_id           原価詳細IDの取得を行うプロシージャ
 *  proc_xxcmn_item_mst    OPM品目アドオンマスタの処理を行うプロシージャ
 *  proc_item_category     OPM品目カテゴリ割当の処理を行うプロシージャ
 *  proc_ic_item_mst       OPM品目マスタの処理を行うプロシージャ
 *  chk_price              単価のチェックを行うプロシージャ
 *  check_item_ins         品目登録用データをチェックするプロシージャ
 *  check_item_upd         品目更新用データをチェックするプロシージャ
 *  check_item_del         品目削除用データをチェックするプロシージャ
 *  check_cmpt_ins         品目原価登録用データをチェックするプロシージャ
 *  check_cmpt_upd         品目原価更新用データをチェックするプロシージャ
 *  item_insert_proc       品目登録処理を行うプロシージャ
 *  item_update_proc       品目更新処理を行うプロシージャ
 *  item_delete_proc       品目削除処理を行うプロシージャ
 *  cmpt_insert_proc       品目原価登録処理を行うプロシージャ
 *  cmpt_update_proc       品目原価更新処理を行うプロシージャ
 *  proc_item              反映処理を行うプロシージャ
 *  init_proc              初期処理を行うプロシージャ
 *  term_proc              終了処理を行うプロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/16    1.0   Oracle 山根 一浩 初回作成
 *  2008/02/05    1.0   Oracle 山根 一浩 変更要求No９対応
 *  2008/04/24    1.1   Oracle 山根 一浩 変更要求No60対応
 *  2008/05/20    1.2   Oracle 丸下 博宣 OPM品目カテゴリ割当の修正
 *  2008/05/27    1.3   Oracle 丸下 博宣 内部変更要求No122対応
 *  2008/06/23    1.4   Oracle 山根 一浩 ST事前検証不具合対応
 *  2008/06/25    1.5   Oracle 山根 一浩 不具合No275対応
 *  2008/07/07    1.6   Oracle 山根 一浩 I_S_192対応
 *  2008/08/07    1.7   Oracle 椎名 昭圭 内部変更要求#178対応
 *  2008/08/20    1.8   Oracle 椎名 昭圭 PT_3-2_22_指摘13対応
 *  2008/08/27    1.9   Oracle 山根 一浩 T_S_543,T_S_496対応
 *  2008/09/08    1.10  Oracle 山根 一浩 T_S_628対応
 *  2008/09/16    1.11  Oracle 山根一浩  T_S_421対応
 *  2008/09/29    1.12  Oracle 山根一浩  T_S_546,T_S_547対応
 *  2008/10/02    1.13  Oracle 椎名 昭圭 統合障害＃293対応
 *  2008/10/10    1.14  Oracle 椎名 昭圭 T_S_442対応にあわせ原価内訳取得方法統一
 *  2008/10/21    1.15  Oracle 丸下 博宣 I_S_431対応
 *  2008/11/13    1.16  Oracle 伊藤ひとみ 統合テスト指摘538,641対応
 *  2008/11/24    1.17  Oracle 大橋孝郎  本番環境問合せ_障害管理表#221対応
 *  2008/12/22    1.18  Oracle 椎名 昭圭 本番#830対応
 *  2009/01/09    1.19  Oracle 佐久間尚豊 本番#950対応
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
  gn_warok_cnt     NUMBER;                    -- スキップ件数
  gn_report_cnt    NUMBER;                    -- レポート件数
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
  check_sub_main_expt         EXCEPTION;     -- サブメインのエラー
  check_item_ins_expt         EXCEPTION;     -- 登録処理のエラー(品目)
  check_item_upd_expt         EXCEPTION;     -- 更新処理のエラー(品目)
  check_item_del_expt         EXCEPTION;     -- 削除処理のエラー(品目)
  check_cmpt_ins_expt         EXCEPTION;     -- 登録処理のエラー(品目原価)
  check_cmpt_upd_expt         EXCEPTION;     -- 更新処理のエラー(品目原価)
--
  lock_expt                   EXCEPTION;     -- デッドロックエラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- インタフェースデータの操作種別
  gn_proc_insert CONSTANT NUMBER := 1;  -- 登録
  gn_proc_update CONSTANT NUMBER := 2;  -- 更新
  gn_proc_delete CONSTANT NUMBER := 9;  -- 削除
--
  -- 処理状況をあらわすステータス
  gn_data_status_nomal CONSTANT NUMBER := 0; -- 正常
  gn_data_status_error CONSTANT NUMBER := 1; -- 失敗
  gn_data_status_warn  CONSTANT NUMBER := 2; -- 警告
  gn_data_status_warok CONSTANT NUMBER := 3; -- 警告(原価)
--
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn800002c'; -- パッケージ名
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_item_if_name      CONSTANT VARCHAR2(100) := 'xxcmn_item_if';
--
  gv_lookup_type       CONSTANT VARCHAR2(100) := 'XXPO_PRICE_TYPE';
  gv_meaning           CONSTANT VARCHAR2(100) := '標準';
  gv_description       CONSTANT VARCHAR2(100) := '本';
  gv_lookup_code       CONSTANT VARCHAR2(1)   := '2';
  gv_lot_ctl_on        CONSTANT VARCHAR2(1)   := '1';
-- 2008/12/22 v1.18 ADD START
  gv_lot_ctl_off       CONSTANT VARCHAR2(1)   := '0';
-- 2008/12/22 v1.18 ADD END
  gv_active_flag_mi    CONSTANT VARCHAR2(1)   := 'N';
  gv_inactive_ind_on   CONSTANT VARCHAR2(1)   := '0';
  gv_inactive_ind_off  CONSTANT VARCHAR2(1)   := '1';
  gv_language          CONSTANT VARCHAR2(10)  := userenv('LANG');
  gv_cost_level_on     CONSTANT VARCHAR2(1)   := '0';
  gv_def_item_um       CONSTANT VARCHAR2(2)   := '本';
  gv_autolot_on        CONSTANT NUMBER        := 1;
  gv_lot_suffix_on     CONSTANT NUMBER        := 0;
  gv_dot_pnt           CONSTANT NUMBER        := 2;
  gv_api_ver           CONSTANT NUMBER        := 2.0;
  gn_loct_ctl_on       CONSTANT NUMBER        := 1;
  gv_div_code_reef     CONSTANT VARCHAR2(1)   := '1';                    -- リーフ
  gv_div_code_drink    CONSTANT VARCHAR2(1)   := '2';                    -- ドリンク
  gv_rate_code_reef    CONSTANT VARCHAR2(1)   := '2';                    -- 容積
  gv_rate_code_drink   CONSTANT VARCHAR2(1)   := '1';                    -- 重量
--2008/09/08
  gv_def_code_zero     CONSTANT VARCHAR2(1)   := '0';
--2008/09/16
  gn_kbn_def           CONSTANT NUMBER        := 0;                      -- デフォルト値
  gn_kbn_oth           CONSTANT NUMBER        := 1;                      -- 入力値
--2008/10/10 MOD↓
  -- クイックコードタイプ
  gv_expense_item_type        CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE';  -- 費目区分
  gv_cmpntcls_type            CONSTANT VARCHAR2(100) := 'XXCMN_D19';               -- 原価内訳区分
--2008/10/10 MOD↑
--
  --メッセージ番号
  gv_msg_80b_001       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';  --ユーザー名
  gv_msg_80b_002       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';  --コンカレント名
  gv_msg_80b_003       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';  --セパレータ
  gv_msg_80b_004       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';  --成功データ(見出し)
  gv_msg_80b_005       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';  --エラーデータ(見出し)
  gv_msg_80b_006       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';  --スキップデータ(見出し)
  gv_msg_80b_007       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';  --処理件数
  gv_msg_80b_008       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';  --成功件数
  gv_msg_80b_009       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';  --エラー件数
  gv_msg_80b_010       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';  --スキップ件数
  gv_msg_80b_011       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';  --処理ステータス
  gv_msg_80b_012       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  --プロファイル取得エラー
  gv_msg_80b_013       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --APIエラー(コンカレント)
  gv_msg_80b_014       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';  --ロックエラー
  gv_msg_80b_015       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10020';  --従業員対象外レコード
  gv_msg_80b_016       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10021';  --範囲外データ
  gv_msg_80b_017       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10022';  --テーブル削除エラー
  gv_msg_80b_018       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';  --コンカレント定型エラー
  gv_msg_80b_019       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';  --起動時間
  gv_msg_80b_020       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10148';  --品目原価未入力エラー
  gv_msg_80b_021       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00024';  --成功データ・警告あり(見出し)
  gv_msg_80b_022       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10036';  --データ取得エラー１
--
  gv_msg_80b_023       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10040';  --存在チェック１：汎用１ 2008/08/27 Add
--エラー・ワーニング
  gv_msg_80b_100       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10099';  --品目原価更新の原価チェック
  gv_msg_80b_101       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10100';  --品目原価登録の原価チェック
  gv_msg_80b_102       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10101';  --品目更新の存在チェック
  gv_msg_80b_103       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10102';  --品目削除の存在チェック
  gv_msg_80b_104       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10103';  --品目登録の重複チェック
  gv_msg_80b_105       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10104';  --品目原価更新の存在チェック
  gv_msg_80b_106       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10105';  --品目原価削除の存在チェック
  gv_msg_80b_107       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10106';  --品目原価登録の重複チェック
  gv_msg_80b_108       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10149';  --親品目存在チェック
--
  --トークン
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_hinmoku    CONSTANT VARCHAR2(15) := 'NG_HINMOKU';
  gv_tkn_ng_genka      CONSTANT VARCHAR2(15) := 'NG_GENKA';
  gv_tkn_ng_item_cd    CONSTANT VARCHAR2(15) := 'NG_ITEM_CODE';
--
  gv_tkn_item_name     CONSTANT VARCHAR2(15) := 'ITEM_NAME';                -- 2008/08/27 Add
  gv_tkn_item_value    CONSTANT VARCHAR2(15) := 'ITEM_VALUE';               -- 2008/08/27 Add
  gv_tkn_table_name    CONSTANT VARCHAR2(15) := 'TABLE_NAME';               -- 2008/08/27 Add
--
  -- 使用DB名
  gv_xxcmn_item_if_name      CONSTANT VARCHAR2(100) := '品目インタフェース';
  gv_ic_item_mst_b_name      CONSTANT VARCHAR2(100) := 'OPM品目マスタ';
  gv_xxcmn_item_mst_b_name   CONSTANT VARCHAR2(100) := 'OPM品目アドオンマスタ';
  gv_gmi_item_category_name  CONSTANT VARCHAR2(100) := 'OPM品目カテゴリ割当';
  gv_cm_cmpt_dtl_name        CONSTANT VARCHAR2(100) := '品目原価マスタ';
  gv_xxpo_price_headers_name CONSTANT VARCHAR2(100) := '仕入/標準原価マスタ';
--
  --プロファイル
  gv_prf_max_date             CONSTANT VARCHAR2(50) := 'XXCMN_MAX_DATE';
  gv_prf_min_date             CONSTANT VARCHAR2(50) := 'XXCMN_MIN_DATE';
  gv_prf_category_name_otgun  CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_OTGUN';
  gv_prf_policy_group_code    CONSTANT VARCHAR2(50) := 'XXCMN_POLICY_GROUP_CODE';
  gv_prf_marke_crowd_code     CONSTANT VARCHAR2(50) := 'XXCMN_MARKE_CROWD_CODE';
  gv_prf_product_div_code     CONSTANT VARCHAR2(50) := 'XXCMN_PRODUCT_DIV_CODE';
  gv_prf_arti_div_code        CONSTANT VARCHAR2(50) := 'XXCMN_ARTI_DIV_CODE';
  gv_prf_div_tea_code         CONSTANT VARCHAR2(50) := 'XXCMN_DIV_TEA_CODE';
  gv_prf_cost_price_whse_code CONSTANT VARCHAR2(50) := 'XXCMN_COST_PRICE_WHSE_CODE';
  gv_prf_item_cal             CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_CAL';
  gv_prf_cost_div             CONSTANT VARCHAR2(50) := 'XXCMN_COST_DIV';
  gv_prf_raw_material_cost    CONSTANT VARCHAR2(50) := 'XXCMN_RAW_MATERIAL_COST';
  gv_prf_agein_cost           CONSTANT VARCHAR2(50) := 'XXCMN_AGEIN_COST';
  gv_prf_material_cost        CONSTANT VARCHAR2(50) := 'XXCMN_MATERIAL_COST';
  gv_prf_pack_cost            CONSTANT VARCHAR2(50) := 'XXCMN_PACK_COST';
  gv_prf_out_order_cost       CONSTANT VARCHAR2(50) := 'XXCMN_OUT_ORDER_COST';
  gv_prf_safekeep_cost        CONSTANT VARCHAR2(50) := 'XXCMN_SAFEKEEP_COST';
  gv_prf_other_expense_cost   CONSTANT VARCHAR2(50) := 'XXCMN_OTHER_EXPENSE_COST';
  gv_prf_spare1               CONSTANT VARCHAR2(50) := 'XXCMN_SPARE1';
  gv_prf_spare2               CONSTANT VARCHAR2(50) := 'XXCMN_SPARE2';
  gv_prf_spare3               CONSTANT VARCHAR2(50) := 'XXCMN_SPARE3';
--2008/09/16 Add
  gv_prf_def_crowd            CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_CROWD_CODE';
  gv_prf_def_policy           CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_POLICY_CODE';
  gv_prf_def_market           CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_MARKET_CODE';
  gv_prf_def_acnt             CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_ACNT_CROWD_CODE';
  gv_prf_def_factory          CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_FACTORY_CODE';
--
  gv_prf_max_date_name        CONSTANT VARCHAR2(50) := 'MAX日付';
  gv_prf_min_date_name        CONSTANT VARCHAR2(50) := 'MIN日付';
  gv_prf_crowd_code_name      CONSTANT VARCHAR2(50) := 'カテゴリセット名(群コード)';
  gv_prf_policy_code_name     CONSTANT VARCHAR2(50) := 'カテゴリセット名(政策群コード)';
  gv_prf_marke_code_name      CONSTANT VARCHAR2(50) := 'カテゴリセット名(マーケ用群コード)';
  gv_prf_product_code_name    CONSTANT VARCHAR2(50) := 'カテゴリセット名(商品製品区分)';
  gv_prf_arti_code_name       CONSTANT VARCHAR2(50) := 'カテゴリセット名(本社商品区分)';
  gv_prf_tea_code_name        CONSTANT VARCHAR2(50) := 'カテゴリセット名(バラ茶区分)';
  gv_prf_whse_code_name       CONSTANT VARCHAR2(50) := '原価倉庫';
  gv_prf_item_cal_name        CONSTANT VARCHAR2(50) := 'カレンダ';
  gv_prf_cost_div_name        CONSTANT VARCHAR2(50) := '原価方法';
  gv_prf_raw_mat_cost_name    CONSTANT VARCHAR2(50) := '原料';
  gv_prf_agein_cost_name      CONSTANT VARCHAR2(50) := '再製費';
  gv_prf_material_cost_name   CONSTANT VARCHAR2(50) := '資材費';
  gv_prf_pack_cost_name       CONSTANT VARCHAR2(50) := '包装費';
  gv_prf_out_order_cost_name  CONSTANT VARCHAR2(50) := '外注加工費';
  gv_prf_safekeep_cost_name   CONSTANT VARCHAR2(50) := '保管費';
  gv_prf_other_cost_name      CONSTANT VARCHAR2(50) := 'その他経費';
  gv_prf_spare1_name          CONSTANT VARCHAR2(50) := '予備１';
  gv_prf_spare2_name          CONSTANT VARCHAR2(50) := '予備２';
  gv_prf_spare3_name          CONSTANT VARCHAR2(50) := '予備３';
--2008/09/16 Add
  gv_prf_def_crowd_name       CONSTANT VARCHAR2(50) := '初期値：群コード';
  gv_prf_def_policy_name      CONSTANT VARCHAR2(50) := '初期値：政策群コード';
  gv_prf_def_market_name      CONSTANT VARCHAR2(50) := '初期値：マーケ用群コード';
  gv_prf_def_acnt_name        CONSTANT VARCHAR2(50) := '初期値：経理部用群コード';
  gv_prf_def_factory_name     CONSTANT VARCHAR2(50) := '初期値：工場群コード';
--
  gv_acnt_crowd_code          CONSTANT VARCHAR2(50) := '経理部用群コード';
  gv_factory_code             CONSTANT VARCHAR2(50) := '工場群コード';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- コンポーネント区分マスタの必要なデータを格納するレコード
  TYPE cmpntcls_rec IS RECORD(
    cost_cmpntcls_id      cm_cmpt_mst_tl.cost_cmpntcls_id%TYPE,     -- コンポーネント区分ID
    cost_cmpntcls_code    cm_cmpt_mst.cost_cmpntcls_code%TYPE,      -- コンポーネント区分コード
    cost_cmpntcls_desc    cm_cmpt_mst_tl.cost_cmpntcls_desc%TYPE,   -- コンポーネント区分名
    sorter                NUMBER,                                   -- 順番
    cost_price            NUMBER                                    -- 金額
  );
--
  -- コンポーネント区分マスタのデータを格納する結合配列
  TYPE cmpntcls_tbl IS TABLE OF cmpntcls_rec INDEX BY PLS_INTEGER;
--
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
    seq_number            xxcmn_item_if.seq_number%TYPE,            --- SEQ番号
    proc_code             xxcmn_item_if.proc_code%TYPE,             --- 更新区分
    item_code             xxcmn_item_if.item_code%TYPE,             --- 品名コード
    item_name             xxcmn_item_if.item_name%TYPE,             --- 品名・正式名
    item_short_name       xxcmn_item_if.item_short_name%TYPE,       --- 品名・略名
    item_name_alt         xxcmn_item_if.item_name_alt%TYPE,         --- 品名・カナ
    old_crowd_code        xxcmn_item_if.old_crowd_code%TYPE,        --- 旧・群コード
    new_crowd_code        xxcmn_item_if.new_crowd_code%TYPE,        --- 新・群コード
    crowd_start_date      xxcmn_item_if.crowd_start_date%TYPE,      --- 適用開始日
    policy_group_code     xxcmn_item_if.policy_group_code%TYPE,     --- 政策群コード
    marke_crowd_code      xxcmn_item_if.marke_crowd_code%TYPE,      --- マーケ用群コード
    old_price             xxcmn_item_if.old_price%TYPE,             --- 旧・定価
    new_price             xxcmn_item_if.new_price%TYPE,             --- 新・定価
    price_start_date      xxcmn_item_if.price_start_date%TYPE,      --- 適用開始日
    old_standard_cost     xxcmn_item_if.old_standard_cost%TYPE,     --- 旧・標準原価
    new_standard_cost     xxcmn_item_if.new_standard_cost%TYPE,     --- 新・標準原価
    standard_start_date   xxcmn_item_if.standard_start_date%TYPE,   --- 適用開始日
    old_business_cost     xxcmn_item_if.old_business_cost%TYPE,     --- 旧・営業原価
    new_business_cost     xxcmn_item_if.new_business_cost%TYPE,     --- 新・営業原価
    business_start_date   xxcmn_item_if.business_start_date%TYPE,   --- 適用開始日
    old_tax               xxcmn_item_if.old_tax%TYPE,               --- 旧・消費税率
    new_tax               xxcmn_item_if.new_tax%TYPE,               --- 新・消費税率
    tax_start_date        xxcmn_item_if.tax_start_date%TYPE,        --- 適用開始日
    rate_code             xxcmn_item_if.rate_code%TYPE,             --- 率区分
    case_num              xxcmn_item_if.case_num%TYPE,              --- ケース入数
    product_div_code      xxcmn_item_if.product_div_code%TYPE,      --- 商品製品区分
    net                   xxcmn_item_if.net%TYPE,                   --- NET
    weight_volume         xxcmn_item_if.weight_volume%TYPE,         --- 重量/体積
    arti_div_code         xxcmn_item_if.arti_div_code%TYPE,         --- 商品区分
    div_tea_code          xxcmn_item_if.div_tea_code%TYPE,          --- バラ茶区分
    parent_item_code      xxcmn_item_if.parent_item_code%TYPE,      --- 親品名コード
    sale_obj_code         xxcmn_item_if.sale_obj_code%TYPE,         --- 売上対象区分
    jan_code              xxcmn_item_if.jan_code%TYPE,              --- JANコード
    sale_start_date       xxcmn_item_if.sale_start_date%TYPE,       --- 発売開始日(製造開始日)
    abolition_code        xxcmn_item_if.abolition_code%TYPE,        --- 廃止区分
    abolition_date        xxcmn_item_if.abolition_date%TYPE,        --- 廃止日(製造中止日)
    raw_mate_consumption  xxcmn_item_if.raw_mate_consumption%TYPE,  --- 原料使用量
    raw_material_cost     xxcmn_item_if.raw_material_cost%TYPE,     --- 原料
    agein_cost            xxcmn_item_if.agein_cost%TYPE,            --- 再製費
    material_cost         xxcmn_item_if.material_cost%TYPE,         --- 資材費
    pack_cost             xxcmn_item_if.pack_cost%TYPE,             --- 包装費
    out_order_cost        xxcmn_item_if.out_order_cost%TYPE,        --- 外注加工費
    safekeep_cost         xxcmn_item_if.safekeep_cost%TYPE,         --- 保管費
    other_expense_cost    xxcmn_item_if.other_expense_cost%TYPE,    --- その他経費
    spare1                xxcmn_item_if.spare1%TYPE,                --- 予備1
    spare2                xxcmn_item_if.spare2%TYPE,                --- 予備2
    spare3                xxcmn_item_if.spare3%TYPE,                --- 予備3
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
    palette_max_cs_qty    xxcmn_item_if.dansu%TYPE,                 --- 配数
    palette_max_step_qty  xxcmn_item_if.haisu%TYPE,                 --- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
    spare                 xxcmn_item_if.spare%TYPE,                 --- 予備
--
    item_id               ic_item_mst_b.item_id%TYPE,               --- 品目ID
    parent_item_id        ic_item_mst_b.item_id%TYPE,               --- 親品目ID
    period_code           cm_cldr_dtl.period_code%TYPE,             --- 期間
    cmpntcost_id          cm_cmpt_dtl.cmpntcost_id%TYPE,            --- 原価詳細ID
    cost_id               cm_cmpt_mst_tl.cost_cmpntcls_id%TYPE,     --- コンポーネント区分ID
--
    cmpntcls_mast         cmpntcls_tbl,                             --- コンポーネント区分マスタ
--
    crowd_start_days      VARCHAR2(10),                             --- 群コード適用開始日
    price_start_days      VARCHAR2(10),                             --- 定価適用開始日
    buis_start_days       VARCHAR2(10),                             --- 営業原価適用開始日
    sale_start_days       VARCHAR2(10),                             --- 発売開始日(製造開始日)
--
    -- 以前の件数
    row_ins_cnt           NUMBER,                                   -- 登録件数
    row_upd_cnt           NUMBER,                                   -- 更新件数
-- 2008/10/02 UPDATE START
--    row_del_cnt           NUMBER                                    -- 削除件数
    row_del_cnt           NUMBER,                                   -- 削除件数
    cldr_n_flg            BOOLEAN,                            -- 原価カレンダ存在チェックフラグ
    cldr_n_msg            VARCHAR2(1000)                      -- 原価カレンダ存在チェックメッセージ
-- 2008/10/02 UPDATE END
  );
--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- 出力するログを格納するレコード
  TYPE report_rec IS RECORD(
    seq_number            xxcmn_item_if.seq_number%TYPE,            --- SEQ番号
    proc_code             xxcmn_item_if.proc_code%TYPE,             --- 更新区分
    item_code             xxcmn_item_if.item_code%TYPE,             --- 品名コード
    item_name             xxcmn_item_if.item_name%TYPE,             --- 品名・正式名
    item_short_name       xxcmn_item_if.item_short_name%TYPE,       --- 品名・略名
    item_name_alt         xxcmn_item_if.item_name_alt%TYPE,         --- 品名・カナ
    old_crowd_code        xxcmn_item_if.old_crowd_code%TYPE,        --- 旧・群コード
    new_crowd_code        xxcmn_item_if.new_crowd_code%TYPE,        --- 新・群コード
    crowd_start_date      xxcmn_item_if.crowd_start_date%TYPE,      --- 適用開始日
    policy_group_code     xxcmn_item_if.policy_group_code%TYPE,     --- 政策群コード
    marke_crowd_code      xxcmn_item_if.marke_crowd_code%TYPE,      --- マーケ用群コード
    old_price             xxcmn_item_if.old_price%TYPE,             --- 旧・定価
    new_price             xxcmn_item_if.new_price%TYPE,             --- 新・定価
    price_start_date      xxcmn_item_if.price_start_date%TYPE,      --- 適用開始日
    old_standard_cost     xxcmn_item_if.old_standard_cost%TYPE,     --- 旧・標準原価
    new_standard_cost     xxcmn_item_if.new_standard_cost%TYPE,     --- 新・標準原価
    standard_start_date   xxcmn_item_if.standard_start_date%TYPE,   --- 適用開始日
    old_business_cost     xxcmn_item_if.old_business_cost%TYPE,     --- 旧・営業原価
    new_business_cost     xxcmn_item_if.new_business_cost%TYPE,     --- 新・営業原価
    business_start_date   xxcmn_item_if.business_start_date%TYPE,   --- 適用開始日
    old_tax               xxcmn_item_if.old_tax%TYPE,               --- 旧・消費税率
    new_tax               xxcmn_item_if.new_tax%TYPE,               --- 新・消費税率
    tax_start_date        xxcmn_item_if.tax_start_date%TYPE,        --- 適用開始日
    rate_code             xxcmn_item_if.rate_code%TYPE,             --- 率区分
    case_num              xxcmn_item_if.case_num%TYPE,              --- ケース入数
    product_div_code      xxcmn_item_if.product_div_code%TYPE,      --- 商品製品区分
    net                   xxcmn_item_if.net%TYPE,                   --- NET
    weight_volume         xxcmn_item_if.weight_volume%TYPE,         --- 重量/体積
    arti_div_code         xxcmn_item_if.arti_div_code%TYPE,         --- 商品区分
    div_tea_code          xxcmn_item_if.div_tea_code%TYPE,          --- バラ茶区分
    parent_item_code      xxcmn_item_if.parent_item_code%TYPE,      --- 親品名コード
    sale_obj_code         xxcmn_item_if.sale_obj_code%TYPE,         --- 売上対象区分
    jan_code              xxcmn_item_if.jan_code%TYPE,              --- JANコード
    sale_start_date       xxcmn_item_if.sale_start_date%TYPE,       --- 発売開始日(製造開始日)
    abolition_code        xxcmn_item_if.abolition_code%TYPE,        --- 廃止区分
    abolition_date        xxcmn_item_if.abolition_date%TYPE,        --- 廃止日(製造中止日)
    raw_mate_consumption  xxcmn_item_if.raw_mate_consumption%TYPE,  --- 原料使用量
    raw_material_cost     xxcmn_item_if.raw_material_cost%TYPE,     --- 原料
    agein_cost            xxcmn_item_if.agein_cost%TYPE,            --- 再製費
    material_cost         xxcmn_item_if.material_cost%TYPE,         --- 資材費
    pack_cost             xxcmn_item_if.pack_cost%TYPE,             --- 包装費
    out_order_cost        xxcmn_item_if.out_order_cost%TYPE,        --- 外注加工費
    safekeep_cost         xxcmn_item_if.safekeep_cost%TYPE,         --- 保管費
    other_expense_cost    xxcmn_item_if.other_expense_cost%TYPE,    --- その他経費
    spare1                xxcmn_item_if.spare1%TYPE,                --- 予備1
    spare2                xxcmn_item_if.spare2%TYPE,                --- 予備2
    spare3                xxcmn_item_if.spare3%TYPE,                --- 予備3
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
    palette_max_cs_qty    xxcmn_item_if.dansu%TYPE,                 --- 配数
    palette_max_step_qty  xxcmn_item_if.haisu%TYPE,                 --- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
    spare                 xxcmn_item_if.spare%TYPE,                 --- 予備
--
    imb_flg               NUMBER,                                   -- OPM品目マスタ
    xmb_flg               NUMBER,                                   -- OPM品目アドオンマスタ
    gic_flg               NUMBER,                                   -- OPM品目カテゴリ割当
    ccd_flg               NUMBER,                                   -- 品目原価マスタ
--
    row_level_status      NUMBER,                                   -- 0.正常,1.失敗,2.警告
    message               VARCHAR2(1000)
  );
--
  -- 出力するレポートを格納する結合配列
  TYPE report_tbl IS TABLE OF report_rec INDEX BY PLS_INTEGER;
--
  -- 処理状況を管理するレコード
  TYPE status_rec IS RECORD(
    file_level_status         NUMBER,                               -- 0.正常,1.失敗・警告あり
    row_level_status          NUMBER,                               -- 0.正常,1.失敗,2.警告
    row_err_message           VARCHAR2(1000)                        -- エラーメッセージ
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_min_date              VARCHAR2(10);    -- 最小日付
  gv_max_date              VARCHAR2(10);    -- 最大日付
  gv_crowd_code            VARCHAR2(20);    -- 群コード
  gv_policy_group_code     VARCHAR2(20);    -- 政策群コード
  gv_marke_crowd_code      VARCHAR2(20);    -- マーケ用群コード
  gv_product_div_code      VARCHAR2(20);    -- 商品製品区分
  gv_arti_div_code         VARCHAR2(20);    -- 商品区分
  gv_div_tea_code          VARCHAR2(20);    -- バラ茶区分
  gv_whse_code             VARCHAR2(20);    -- 原価倉庫
  gv_item_cal              VARCHAR2(20);    -- カレンダ
  gv_cost_div              VARCHAR2(20);    -- 原価方法
  gv_raw_material_cost     VARCHAR2(20);    -- 原料
  gv_agein_cost            VARCHAR2(20);    -- 再製費
  gv_material_cost         VARCHAR2(20);    -- 資材費
  gv_pack_cost             VARCHAR2(20);    -- 包装費
  gv_out_order_cost        VARCHAR2(20);    -- 外注加工費
  gv_safekeep_cost         VARCHAR2(20);    -- 保管費
  gv_other_expense_cost    VARCHAR2(20);    -- その他経費
  gv_spare1                VARCHAR2(20);    -- 予備1
  gv_spare2                VARCHAR2(20);    -- 予備2
  gv_spare3                VARCHAR2(20);    -- 予備3
--2008/09/16 Add
  -- 郡コード初期値
  gv_def_crowd_code        VARCHAR2(20);    -- 初期値：群コード
  gv_def_policy_code       VARCHAR2(20);    -- 初期値：政策群コード
  gv_def_market_code       VARCHAR2(20);    -- 初期値：マーケ用群コード
  gv_def_acnt_crowd_code   VARCHAR2(20);    -- 初期値：経理部用群コード
  gv_def_factory_code      VARCHAR2(20);    -- 初期値：工場群コード
--
  gd_sysdate               DATE;
-- 2008/09/08 Mod ↓
/*
  gn_user_id               NUMBER(15);
  gn_login_id              NUMBER(15);
  gn_request_id            NUMBER(15);
  gn_appl_id               NUMBER(15);
  gn_program_id            NUMBER(15);
*/
  gn_user_id               NUMBER;
  gn_login_id              NUMBER;
  gn_request_id            NUMBER;
  gn_appl_id               NUMBER;
  gn_program_id            NUMBER;
-- 2008/09/08 Mod ↑
  gd_min_date              DATE;
  gd_max_date              DATE;
  gv_user_name             fnd_user.user_name%TYPE;
--
  gt_cmpntcls_mast cmpntcls_tbl; -- コンポーネント区分マスタのデータ
--
-- 2008/09/08 Del ↓
/*
  gv_cmpntcls_desc_01      VARCHAR2(20);
  gv_cmpntcls_desc_02      VARCHAR2(20);
  gv_cmpntcls_desc_03      VARCHAR2(20);
  gv_cmpntcls_desc_04      VARCHAR2(20);
  gv_cmpntcls_desc_05      VARCHAR2(20);
  gv_cmpntcls_desc_06      VARCHAR2(20);
  gv_cmpntcls_desc_07      VARCHAR2(20);
  gv_cmpntcls_desc_08      VARCHAR2(20);
  gv_cmpntcls_desc_09      VARCHAR2(20);
  gv_cmpntcls_desc_10      VARCHAR2(20);
  gv_cmpntcls_num_01       NUMBER;
  gv_cmpntcls_num_02       NUMBER;
  gv_cmpntcls_num_03       NUMBER;
  gv_cmpntcls_num_04       NUMBER;
  gv_cmpntcls_num_05       NUMBER;
  gv_cmpntcls_num_06       NUMBER;
  gv_cmpntcls_num_07       NUMBER;
  gv_cmpntcls_num_08       NUMBER;
  gv_cmpntcls_num_09       NUMBER;
  gv_cmpntcls_num_10       NUMBER;
*/
-- 2008/09/08 Del ↑
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
    -- OPM品目マスタ(IC_ITEM_MST_B)
    CURSOR ic_item_mst_b_cur
    IS
-- 2008/08/20 v1.8 UPDATE START
/*
      SELECT imb.item_id
      FROM   ic_item_mst_b imb
      WHERE  EXISTS (
        SELECT xif.item_code
        FROM   xxcmn_item_if xif
        WHERE  imb.item_no = xif.item_code
        AND    ROWNUM = 1)
      AND    imb.inactive_ind = gv_inactive_ind_on
      FOR UPDATE OF imb.item_id NOWAIT;
*/
      SELECT imb.item_id
      FROM   ic_item_mst_b imb
            ,xxcmn_item_if xif
      WHERE  imb.item_no      = xif.item_code
      AND    imb.inactive_ind = gv_inactive_ind_on
      FOR UPDATE OF imb.item_id NOWAIT;
-- 2008/08/20 v1.8 UPDATE END
--
    -- OPM品目アドオンマスタ(XXCMN_ITEM_MST_B)
    CURSOR xxcmn_item_mst_b_cur
    IS
-- 2008/08/20 v1.8 UPDATE START
/*
      SELECT xmb.item_id
      FROM   xxcmn_item_mst_b xmb
      WHERE  EXISTS (
        SELECT imb.item_id
        FROM   ic_item_mst_b imb
        WHERE  EXISTS (
          SELECT xif.item_code
          FROM   xxcmn_item_if xif
          WHERE  imb.item_no = xif.item_code
          AND    ROWNUM = 1)
        AND    imb.inactive_ind = gv_inactive_ind_on
        AND    imb.item_id      = xmb.item_id
        AND    ROWNUM = 1)
      FOR UPDATE OF xmb.item_id NOWAIT;
*/
      SELECT xmb.item_id
      FROM   xxcmn_item_mst_b xmb
      WHERE  xmb.item_id IN (
             SELECT imb.item_id
             FROM   ic_item_mst_b imb
                   ,xxcmn_item_if xif
             WHERE  imb.item_no      = xif.item_code
             AND    imb.inactive_ind = gv_inactive_ind_on )
      FOR UPDATE OF xmb.item_id NOWAIT;
-- 2008/08/20 v1.8 UPDATE END
--
    -- OPM品目カテゴリ割当(GMI_ITEM_CATEGORIES)
    CURSOR gmi_item_categories_cur
    IS
-- 2008/08/20 v1.8 UPDATE START
/*
      SELECT gic.item_id
      FROM   gmi_item_categories gic
      WHERE  EXISTS (
        SELECT imb.item_id
        FROM   ic_item_mst_b imb
        WHERE  EXISTS (
          SELECT xif.item_code
          FROM   xxcmn_item_if xif
          WHERE  imb.item_no = xif.item_code
          AND    ROWNUM = 1)
        AND    imb.inactive_ind = gv_inactive_ind_on
        AND    imb.item_id      = gic.item_id
        AND    ROWNUM = 1)
      FOR UPDATE OF gic.item_id NOWAIT;
*/
      SELECT gic.item_id 
      FROM   gmi_item_categories gic
      WHERE  gic.item_id IN (
             SELECT imb.item_id
             FROM   ic_item_mst_b imb
                   ,xxcmn_item_if xif
             WHERE  imb.item_no      = xif.item_code
             AND    imb.inactive_ind = gv_inactive_ind_on ) 
      FOR UPDATE OF gic.item_id NOWAIT;
-- 2008/08/20 v1.8 UPDATE END
--
    -- 品目原価マスタ(CM_CMPT_DTL)
    CURSOR cm_cmpt_dtl_cur
    IS
-- 2008/08/20 v1.8 UPDATE START
/*
      SELECT ccd.item_id
      FROM   cm_cmpt_dtl ccd
      WHERE  EXISTS (
        SELECT imb.item_id
        FROM   ic_item_mst_b imb
        WHERE  EXISTS (
          SELECT xif.item_code
          FROM   xxcmn_item_if xif
          WHERE  imb.item_no = xif.item_code
          AND    ROWNUM = 1)
        AND    imb.item_id = ccd.item_id
        AND    imb.inactive_ind = gv_inactive_ind_on
        AND    ROWNUM = 1)
      AND    ccd.whse_code      = gv_whse_code
      AND    ccd.calendar_code  = gv_item_cal
      AND    ccd.cost_mthd_code = gv_cost_div
      AND    ccd.cost_level     = gv_cost_level_on
      FOR UPDATE OF ccd.item_id NOWAIT;
*/
      SELECT ccd.item_id
      FROM   cm_cmpt_dtl ccd
      WHERE  ccd.item_id IN (
             SELECT imb.item_id
             FROM   ic_item_mst_b imb
                   ,xxcmn_item_if xif
             WHERE  imb.inactive_ind = gv_inactive_ind_on
             AND    imb.item_no      = xif.item_code )
      AND    ccd.whse_code      = gv_whse_code
      AND    ccd.calendar_code  = gv_item_cal
      AND    ccd.cost_mthd_code = gv_cost_div
      AND    ccd.cost_level     = gv_cost_level_on
      FOR UPDATE OF ccd.item_id NOWAIT;
-- 2008/08/20 v1.8 UPDATE END
-- 2008/09/16 Add ↓
  /***********************************************************************************
   * Procedure Name   : proc_mtl_categories
   * Description      : 品目カテゴリマスタの登録処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_mtl_categories(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    in_kbn          IN            NUMBER,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_mtl_categories'; -- プログラム名
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
    ln_cnt            NUMBER;
    ln_category_id    mtl_categories_b.category_id%TYPE;
    lv_segment1       mtl_categories_b.segment1%TYPE;
    lt_category_rec   INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_errorcode      NUMBER;
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lv_api_name       VARCHAR2(200);
--
    -- *** ローカル・カーソル ***
    CURSOR category_cur
    IS
       SELECT mcsb.category_set_id,
              mcst.description,
              mcsb.structure_id
       FROM   mtl_category_sets_tl mcst,
              mtl_category_sets_b  mcsb
       WHERE  mcsb.category_set_id = mcst.category_set_id
       AND    mcst.language        = gv_language
       AND    mcst.source_lang     = gv_language
       AND    mcst.description IN (
                                   gv_crowd_code,                 -- 群コード
                                   gv_policy_group_code,          -- 政策群コード
                                   gv_marke_crowd_code,           -- マーケ用群コード
                                   gv_acnt_crowd_code             -- 経理部用群コード
--2008/09/29 Mod ↓
/*
                                   gv_acnt_crowd_code,            -- 経理部用群コード
                                   gv_factory_code                -- 工場群コード
*/
--2008/09/29 Mod ↑
                                  )
       ;
--
    -- *** ローカル・レコード ***
    lr_category_rec category_cur%ROWTYPE;
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
    OPEN category_cur;
--
    <<category_loop>>
    LOOP
      FETCH category_cur INTO lr_category_rec;
      EXIT WHEN category_cur%NOTFOUND;
--
      lt_category_rec.structure_id := lr_category_rec.structure_id;
--
      -- 初期値作成
      IF (in_kbn = gn_kbn_def) THEN
--
        IF (lr_category_rec.description = gv_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_crowd_code;
--
        ELSIF (lr_category_rec.description = gv_policy_group_code) THEN
          lt_category_rec.segment1 := gv_def_policy_code;
--
        ELSIF (lr_category_rec.description = gv_marke_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_market_code;
--
        ELSIF (lr_category_rec.description = gv_acnt_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_acnt_crowd_code;
--2008/09/29 Mod ↓
/*
--
        ELSIF (lr_category_rec.description = gv_factory_code) THEN
          lt_category_rec.segment1 := gv_def_factory_code;
*/
--2008/09/29 Mod ↑
        END IF;
--
      -- 入力値作成
      ELSE
--
        IF (lr_category_rec.description = gv_crowd_code) THEN
          lt_category_rec.segment1 := ir_masters_rec.new_crowd_code;
--
        ELSIF (lr_category_rec.description = gv_policy_group_code) THEN
          lt_category_rec.segment1 := ir_masters_rec.policy_group_code;
--
        ELSIF (lr_category_rec.description = gv_marke_crowd_code) THEN
          lt_category_rec.segment1 := ir_masters_rec.marke_crowd_code;
--
        ELSIF (lr_category_rec.description = gv_acnt_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_acnt_crowd_code;
--2008/09/29 Mod ↓
/*
--
        ELSIF (lr_category_rec.description = gv_factory_code) THEN
          lt_category_rec.segment1 := gv_def_factory_code;
*/
--2008/09/29 Mod ↓
        END IF;
      END IF;
--
      lt_category_rec.summary_flag := 'N';
      lt_category_rec.enabled_flag := 'Y';
--
      lt_category_rec.web_status := NULL;
      lt_category_rec.supplier_enabled_flag := NULL;
--
      -- 品目カテゴリマスタ存在チェック
      BEGIN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   mtl_categories_b mcb
        WHERE  mcb.structure_id = lt_category_rec.structure_id
        AND    mcb.segment1     = lt_category_rec.segment1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_cnt := 0;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 存在しない
      IF (ln_cnt = 0) THEN
--
        -- 品目カテゴリマスタ登録
        INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY(
           P_API_VERSION      => 1.0
          ,P_INIT_MSG_LIST    => FND_API.G_FALSE
          ,P_COMMIT           => FND_API.G_FALSE
          ,X_RETURN_STATUS    => lv_return_status
          ,X_ERRORCODE        => ln_errorcode
          ,X_MSG_COUNT        => ln_msg_count
          ,X_MSG_DATA         => lv_msg_data
          ,P_CATEGORY_REC     => lt_category_rec
          ,X_CATEGORY_ID      => ln_category_id
        );
--
        -- 失敗
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          lv_api_name := 'INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY';
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_013,
                                                gv_tkn_api_name,
                                                lv_api_name);
--
          lv_msg_data := lv_errmsg;
--
          xxcmn_common_pkg.put_api_log(
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          lv_errmsg := lv_msg_data;
          lv_errbuf := lv_msg_data;
          RAISE global_api_expt;
        END IF;
--
      -- 存在する
      ELSE
        BEGIN
          SELECT mcb.category_id
          INTO   ln_category_id
          FROM   mtl_categories_b mcb
          WHERE  mcb.structure_id = lt_category_rec.structure_id
          AND    mcb.segment1     = lt_category_rec.segment1
          ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- 品目カテゴリ割当存在チェック
      BEGIN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   gmi_item_categories gic
        WHERE  gic.item_id         = ir_masters_rec.item_id
        AND    gic.category_set_id = lr_category_rec.category_set_id
        AND    gic.category_id     = ln_category_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_cnt := 0;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- デフォルト値のみ
      IF (in_kbn = gn_kbn_def) THEN
--
        -- 存在しない
        IF (ln_cnt = 0) THEN
          INSERT INTO gmi_item_categories
             (item_id
             ,category_set_id
             ,category_id
             ,created_by
             ,creation_date
             ,last_updated_by
             ,last_update_date
             ,last_update_login)
          VALUES (
              ir_masters_rec.item_id
             ,lr_category_rec.category_set_id
             ,ln_category_id
             ,gn_user_id
             ,gd_sysdate
             ,gn_user_id
             ,gd_sysdate
             ,gn_login_id
          );
        END IF;
      END IF;
--
    END LOOP category_loop;
--
    CLOSE category_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_mtl_categories;
--
-- 2008/09/16 Add ↑
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : プロファイルよりMAX日付,MIN日付を取得します。
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
    lv_min_date  VARCHAR2(10);
    lv_max_date  VARCHAR2(10);
    lv_role_id   VARCHAR2(1);
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
    --最大日付取得
    gv_max_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_max_date),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_max_date := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
--
    --最小日付取得
    gv_min_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_min_date),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_min_date := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
--
    --カテゴリセット名(群コード)
    gv_crowd_code := FND_PROFILE.VALUE(gv_prf_category_name_otgun);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_crowd_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_crowd_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --カテゴリセット名(政策群コード)
    gv_policy_group_code := FND_PROFILE.VALUE(gv_prf_policy_group_code);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_policy_group_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_policy_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --カテゴリセット名(マーケ用群コード)
    gv_marke_crowd_code := FND_PROFILE.VALUE(gv_prf_marke_crowd_code);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_marke_crowd_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_marke_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --カテゴリセット名(商品製品区分)
    gv_product_div_code := FND_PROFILE.VALUE(gv_prf_product_div_code);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_product_div_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_product_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --カテゴリセット名(本社商品区分)
    gv_arti_div_code := FND_PROFILE.VALUE(gv_prf_arti_div_code);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_arti_div_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_arti_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --カテゴリセット名(バラ茶区分)
    gv_div_tea_code := FND_PROFILE.VALUE(gv_prf_div_tea_code);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_div_tea_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_tea_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --原価倉庫
    gv_whse_code := FND_PROFILE.VALUE(gv_prf_cost_price_whse_code);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_whse_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_whse_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --カレンダ
    gv_item_cal := FND_PROFILE.VALUE(gv_prf_item_cal);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_item_cal IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_item_cal_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --原価方法
    gv_cost_div := FND_PROFILE.VALUE(gv_prf_cost_div);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_cost_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_cost_div_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --原料
    gv_raw_material_cost := FND_PROFILE.VALUE(gv_prf_raw_material_cost);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_raw_material_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_raw_mat_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --再製費
    gv_agein_cost := FND_PROFILE.VALUE(gv_prf_agein_cost);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_agein_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_agein_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --資材費
    gv_material_cost := FND_PROFILE.VALUE(gv_prf_material_cost);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_material_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_material_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --包装費
    gv_pack_cost := FND_PROFILE.VALUE(gv_prf_pack_cost);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_pack_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_pack_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --外注加工費
    gv_out_order_cost := FND_PROFILE.VALUE(gv_prf_out_order_cost);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_out_order_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_out_order_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --保管費
    gv_safekeep_cost := FND_PROFILE.VALUE(gv_prf_safekeep_cost);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_safekeep_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_safekeep_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --その他経費
    gv_other_expense_cost := FND_PROFILE.VALUE(gv_prf_other_expense_cost);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_other_expense_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_other_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --予備1
    gv_spare1 := FND_PROFILE.VALUE(gv_prf_spare1);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_spare1 IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_spare1_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --予備2
    gv_spare2 := FND_PROFILE.VALUE(gv_prf_spare2);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_spare2 IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_spare2_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --予備3
    gv_spare3 := FND_PROFILE.VALUE(gv_prf_spare3);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_spare3 IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_spare3_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--2008/09/16 Add ↓
--
    -- プロファイル：初期値：群コードの取得
    gv_def_crowd_code := FND_PROFILE.VALUE(gv_prf_def_crowd);
    -- 取得エラー時
    IF (gv_def_crowd_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_msg_kbn,             -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_80b_012,         -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_ng_profile,      -- トークン：NG_PROFILE
                            gv_prf_def_crowd_name   -- 初期値：群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル：初期値：政策群コードの取得
    gv_def_policy_code := FND_PROFILE.VALUE(gv_prf_def_policy);
    -- 取得エラー時
    IF (gv_def_policy_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_msg_kbn,             -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_80b_012,         -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_ng_profile,      -- トークン：NG_PROFILE
                            gv_prf_def_policy_name  -- 初期値：政策群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル：初期値：マーケ用群コードの取得
    gv_def_market_code := FND_PROFILE.VALUE(gv_prf_def_market);
    -- 取得エラー時
    IF (gv_def_market_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_msg_kbn,             -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_80b_012,         -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_ng_profile,      -- トークン：NG_PROFILE
                            gv_prf_def_market_name  -- 初期値：マーケ用群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル：初期値：経理部用群コードの取得
    gv_def_acnt_crowd_code := FND_PROFILE.VALUE(gv_prf_def_acnt);
    -- 取得エラー時
    IF (gv_def_acnt_crowd_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_msg_kbn,             -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_80b_012,         -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_ng_profile,      -- トークン：NG_PROFILE
                            gv_prf_def_acnt_name    -- 初期値：経理部用群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル：初期値：工場群コードの取得
    gv_def_factory_code := FND_PROFILE.VALUE(gv_prf_def_factory);
    -- 取得エラー時
    IF (gv_def_factory_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_msg_kbn,             -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_80b_012,         -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_ng_profile,      -- トークン：NG_PROFILE
                            gv_prf_def_factory_name -- 初期値：工場群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--2008/09/16 Add ↑
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
  /***********************************************************************************
   * Procedure Name   : set_if_lock
   * Description      : 品目インタフェースのテーブルロックを行います。
   ***********************************************************************************/
  PROCEDURE set_if_lock(
    ov_errbuf   OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_if_lock'; -- プログラム名
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
    ln_item_id  ic_item_mst_b.item_id%TYPE;
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
    lb_retcd := TRUE;
--
    -- テーブルロック処理(品目インタフェース)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_item_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                            gv_tkn_table, gv_xxcmn_item_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- OPM品目マスタ(IC_ITEM_MST_B)
    BEGIN
--
      OPEN ic_item_mst_b_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_ic_item_mst_b_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- OPM品目アドオンマスタ(XXCMN_ITEM_MST_B)
    BEGIN
--
      OPEN xxcmn_item_mst_b_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_xxcmn_item_mst_b_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- OPM品目カテゴリ割当(GMI_ITEM_CATEGORIES)
    BEGIN
--
      OPEN gmi_item_categories_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_gmi_item_category_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- 品目原価マスタ(CM_CMPT_DTL)
    BEGIN
--
      OPEN cm_cmpt_dtl_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_cm_cmpt_dtl_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
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
  END set_if_lock;
--
  /***********************************************************************************
   * Procedure Name   : set_error_status
   * Description      : エラーが発生した状態にします。
   ***********************************************************************************/
  PROCEDURE set_error_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    iv_message    IN            VARCHAR2,    -- チェック対象データ
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_error_status'; -- プログラム名
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
    ir_status_rec.file_level_status := gn_data_status_error;
    ir_status_rec.row_level_status  := gn_data_status_error;
    ir_status_rec.row_err_message   := iv_message;
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
  END set_error_status;
--
  /***********************************************************************************
   * Procedure Name   : set_warn_status
   * Description      : 警告が発生した状態にします。
   ***********************************************************************************/
  PROCEDURE set_warn_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    iv_message    IN            VARCHAR2,    -- チェック対象データ
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_warn_status'; -- プログラム名
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
    ir_status_rec.row_level_status  := gn_data_status_warn;
    ir_status_rec.row_err_message   := iv_message;
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
  END set_warn_status;
--
  /***********************************************************************************
   * Procedure Name   : set_warok_status
   * Description      : 警告が発生した状態にします。
   ***********************************************************************************/
  PROCEDURE set_warok_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    iv_message    IN            VARCHAR2,    -- チェック対象データ
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_warok_status'; -- プログラム名
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
    ir_status_rec.row_level_status  := gn_data_status_warok;
    ir_status_rec.row_err_message   := iv_message;
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
  END set_warok_status;
--
  /***********************************************************************************
   * Function Name    : is_file_status_nomal
   * Description      : ファイルレベルで正常な状態であるかを返します。
   ***********************************************************************************/
  FUNCTION is_file_status_nomal(
    ir_status_rec  IN status_rec)  -- 処理状況
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_file_status_nomal'; --プログラム名
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
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.file_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END is_file_status_nomal;
--
  /***********************************************************************************
   * Procedure Name   : init_row_status
   * Description      : 行レベルのステータスを初期化します。
   ***********************************************************************************/
  PROCEDURE init_row_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_row_status'; -- プログラム名
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
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
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
  END init_row_status;
--
  /***********************************************************************************
   * Function Name    : is_row_status_nomal
   * Description      : 行レベルで正常な状態であるかを返します。
   ***********************************************************************************/
  FUNCTION is_row_status_nomal(
    ir_status_rec  IN status_rec)  -- 処理状況
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_nomal'; --プログラム名
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
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END is_row_status_nomal;
--
  /***********************************************************************************
   * Function Name    : is_row_status_warn
   * Description      : 行レベルで警告状態であるかを返します。
   ***********************************************************************************/
  FUNCTION is_row_status_warn(
    ir_status_rec  IN status_rec)  -- 処理状況
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_warn'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd    BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_warn) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END is_row_status_warn;
--
  /***********************************************************************************
   * Function Name    : is_row_status_warok
   * Description      : 行レベルで警告状態であるかを返します。
   ***********************************************************************************/
  FUNCTION is_row_status_warok(
    ir_status_rec  IN status_rec)  -- 処理状況
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_warok'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd    BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_warok) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END is_row_status_warok;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : レポート用データを設定します。
   ***********************************************************************************/
  PROCEDURE add_report(
    ir_status_rec  IN            status_rec,
    ir_masters_rec IN            masters_rec,
    it_report_tbl  IN OUT NOCOPY report_tbl,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- プログラム名
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
    lr_report_rec report_rec;
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
    -- レポートレコードに値を設定
    lr_report_rec.seq_number           := ir_masters_rec.seq_number;
    lr_report_rec.proc_code            := ir_masters_rec.proc_code;
    lr_report_rec.item_code            := ir_masters_rec.item_code;
    lr_report_rec.item_name            := ir_masters_rec.item_name;
    lr_report_rec.item_short_name      := ir_masters_rec.item_short_name;
    lr_report_rec.item_name_alt        := ir_masters_rec.item_name_alt;
    lr_report_rec.old_crowd_code       := ir_masters_rec.old_crowd_code;
    lr_report_rec.new_crowd_code       := ir_masters_rec.new_crowd_code;
    lr_report_rec.crowd_start_date     := ir_masters_rec.crowd_start_date;
    lr_report_rec.policy_group_code    := ir_masters_rec.policy_group_code;
    lr_report_rec.marke_crowd_code     := ir_masters_rec.marke_crowd_code;
    lr_report_rec.old_price            := ir_masters_rec.old_price;
    lr_report_rec.new_price            := ir_masters_rec.new_price;
    lr_report_rec.price_start_date     := ir_masters_rec.price_start_date;
    lr_report_rec.old_standard_cost    := ir_masters_rec.old_standard_cost;
    lr_report_rec.new_standard_cost    := ir_masters_rec.new_standard_cost;
    lr_report_rec.standard_start_date  := ir_masters_rec.standard_start_date;
    lr_report_rec.old_business_cost    := ir_masters_rec.old_business_cost;
    lr_report_rec.new_business_cost    := ir_masters_rec.new_business_cost;
    lr_report_rec.business_start_date  := ir_masters_rec.business_start_date;
    lr_report_rec.old_tax              := ir_masters_rec.old_tax;
    lr_report_rec.new_tax              := ir_masters_rec.new_tax;
    lr_report_rec.tax_start_date       := ir_masters_rec.tax_start_date;
    lr_report_rec.rate_code            := ir_masters_rec.rate_code;
    lr_report_rec.case_num             := ir_masters_rec.case_num;
    lr_report_rec.product_div_code     := ir_masters_rec.product_div_code;
    lr_report_rec.net                  := ir_masters_rec.net;
    lr_report_rec.weight_volume        := ir_masters_rec.weight_volume;
    lr_report_rec.arti_div_code        := ir_masters_rec.arti_div_code;
    lr_report_rec.div_tea_code         := ir_masters_rec.div_tea_code;
    lr_report_rec.parent_item_code     := ir_masters_rec.parent_item_code;
    lr_report_rec.sale_obj_code        := ir_masters_rec.sale_obj_code;
    lr_report_rec.jan_code             := ir_masters_rec.jan_code;
    lr_report_rec.sale_start_date      := ir_masters_rec.sale_start_date;
    lr_report_rec.abolition_code       := ir_masters_rec.abolition_code;
    lr_report_rec.abolition_date       := ir_masters_rec.abolition_date;
    lr_report_rec.raw_mate_consumption := ir_masters_rec.raw_mate_consumption;
    lr_report_rec.raw_material_cost    := ir_masters_rec.raw_material_cost;
    lr_report_rec.agein_cost           := ir_masters_rec.agein_cost;
    lr_report_rec.material_cost        := ir_masters_rec.material_cost;
    lr_report_rec.pack_cost            := ir_masters_rec.pack_cost;
    lr_report_rec.out_order_cost       := ir_masters_rec.out_order_cost;
    lr_report_rec.safekeep_cost        := ir_masters_rec.safekeep_cost;
    lr_report_rec.other_expense_cost   := ir_masters_rec.other_expense_cost;
    lr_report_rec.spare1               := ir_masters_rec.spare1;
    lr_report_rec.spare2               := ir_masters_rec.spare2;
    lr_report_rec.spare3               := ir_masters_rec.spare3;
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
    lr_report_rec.palette_max_cs_qty   := ir_masters_rec.palette_max_cs_qty;         -- 配数
    lr_report_rec.palette_max_step_qty := ir_masters_rec.palette_max_step_qty; -- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
    lr_report_rec.spare                := ir_masters_rec.spare;
--
    lr_report_rec.row_level_status     := ir_status_rec.row_level_status;
    lr_report_rec.message              := ir_status_rec.row_err_message;
--
    lr_report_rec.imb_flg              := 0;
    lr_report_rec.xmb_flg              := 0;
    lr_report_rec.gic_flg              := 0;
    lr_report_rec.ccd_flg              := 0;
--
    -- レポートテーブルに追加
    it_report_tbl(gn_report_cnt) := lr_report_rec;
    gn_report_cnt := gn_report_cnt + 1;
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
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : レポート用データを出力します。
   ***********************************************************************************/
  PROCEDURE disp_report(
    it_report_tbl  IN         report_tbl,   -- メッセージテーブル
    disp_kbn       IN         NUMBER,       -- 表示対象区分(0:正常,1:異常,2:警告)
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
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
    lr_report_rec report_rec;
    ln_disp_cnt   NUMBER;
    lv_dspbuf     VARCHAR2(5000);  -- エラー・メッセージ
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 正常
    IF (disp_kbn = gn_data_status_nomal) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_004);
--
    -- エラー
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_005);
--
    -- 警告
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_006);
--
    -- 正常・警告あり
    ELSIF (disp_kbn = gn_data_status_warok) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_021);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 設定されているレポートの出力
    <<disp_report_loop>>
    FOR ln_disp_cnt IN 0..gn_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(ln_disp_cnt);
--
      --入力データの再構成
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number)  || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.proc_code)   || gv_msg_pnt ||
                   lr_report_rec.item_code            || gv_msg_pnt ||
                   lr_report_rec.item_name            || gv_msg_pnt ||
                   lr_report_rec.item_short_name      || gv_msg_pnt ||
                   lr_report_rec.item_name_alt        || gv_msg_pnt ||
                   lr_report_rec.old_crowd_code       || gv_msg_pnt ||
                   lr_report_rec.new_crowd_code       || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.crowd_start_date,'YYYY/MM/DD')     || gv_msg_pnt ||
                   lr_report_rec.policy_group_code    || gv_msg_pnt ||
                   lr_report_rec.marke_crowd_code     || gv_msg_pnt ||
                   lr_report_rec.old_price            || gv_msg_pnt ||
                   lr_report_rec.new_price            || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.price_start_date,'YYYY/MM/DD')     || gv_msg_pnt ||
                   lr_report_rec.old_standard_cost    || gv_msg_pnt ||
                   lr_report_rec.new_standard_cost    || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.standard_start_date,'YYYY/MM/DD')  || gv_msg_pnt ||
                   lr_report_rec.old_business_cost    || gv_msg_pnt ||
                   lr_report_rec.new_business_cost    || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.business_start_date,'YYYY/MM/DD')  || gv_msg_pnt ||
                   lr_report_rec.old_tax              || gv_msg_pnt ||
                   lr_report_rec.new_tax              || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.tax_start_date,'YYYY/MM/DD')       || gv_msg_pnt ||
                   lr_report_rec.rate_code            || gv_msg_pnt ||
                   lr_report_rec.case_num             || gv_msg_pnt ||
                   lr_report_rec.product_div_code     || gv_msg_pnt ||
                   lr_report_rec.net                  || gv_msg_pnt ||
                   lr_report_rec.weight_volume        || gv_msg_pnt ||
                   lr_report_rec.arti_div_code        || gv_msg_pnt ||
                   lr_report_rec.div_tea_code         || gv_msg_pnt ||
                   lr_report_rec.parent_item_code     || gv_msg_pnt ||
                   lr_report_rec.sale_obj_code        || gv_msg_pnt ||
                   lr_report_rec.jan_code             || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.sale_start_date,'YYYY/MM/DD')      || gv_msg_pnt ||
                   lr_report_rec.abolition_code       || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.abolition_date,'YYYY/MM/DD')       || gv_msg_pnt ||
                   lr_report_rec.raw_mate_consumption || gv_msg_pnt ||
                   lr_report_rec.raw_material_cost    || gv_msg_pnt ||
                   lr_report_rec.agein_cost           || gv_msg_pnt ||
                   lr_report_rec.material_cost        || gv_msg_pnt ||
                   lr_report_rec.pack_cost            || gv_msg_pnt ||
                   lr_report_rec.out_order_cost       || gv_msg_pnt ||
                   lr_report_rec.safekeep_cost        || gv_msg_pnt ||
                   lr_report_rec.other_expense_cost   || gv_msg_pnt ||
                   lr_report_rec.spare1               || gv_msg_pnt ||
                   lr_report_rec.spare2               || gv_msg_pnt ||
                   lr_report_rec.spare3               || gv_msg_pnt || 
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
                   lr_report_rec.palette_max_cs_qty   || gv_msg_pnt || -- 配数
                   lr_report_rec.palette_max_step_qty || gv_msg_pnt || -- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
                   lr_report_rec.spare;
--
      -- 対象
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        IF ((disp_kbn = gn_data_status_nomal) OR (disp_kbn = gn_data_status_warok)) THEN
          -- OPM品目マスタ
          IF (lr_report_rec.imb_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_ic_item_mst_b_name);
          END IF;
          -- OPM品目アドオンマスタ
          IF (lr_report_rec.xmb_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_item_mst_b_name);
          END IF;
          -- OPM品目カテゴリ割当
          IF (lr_report_rec.gic_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_gmi_item_category_name);
          END IF;
          -- 品目原価マスタ
          IF (lr_report_rec.ccd_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_cm_cmpt_dtl_name);
          END IF;
        END IF;
--
        -- 正常以外
        IF (disp_kbn <> gn_data_status_nomal) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_report_loop;
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
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_item_if
   * Description      : 品目インタフェースの過去の件数取得を行います。
   ***********************************************************************************/
  PROCEDURE get_xxcmn_item_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_item_if'; -- プログラム名
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
    BEGIN
--
      ir_masters_rec.row_ins_cnt := 0;
      ir_masters_rec.row_upd_cnt := 0;
      ir_masters_rec.row_del_cnt := 0;
--
      -- 社員インタフェース
      SELECT SUM(NVL(DECODE(xei.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_ins_cnt,
             ir_masters_rec.row_upd_cnt,
             ir_masters_rec.row_del_cnt
      FROM   xxcmn_item_if xei
      WHERE  xei.item_code = ir_masters_rec.item_code         -- 品目コードが同じ
      AND    xei.seq_number < ir_masters_rec.seq_number       -- SEQ番号が以前のデータ
      GROUP BY xei.item_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_ins_cnt := 0;
        ir_masters_rec.row_upd_cnt := 0;
        ir_masters_rec.row_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_xxcmn_item_if;
--
  /***********************************************************************************
   * Procedure Name   : chk_ic_item_mst_b
   * Description      : 品目コードの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_ic_item_mst_b(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_ic_item_mst_b'; -- プログラム名
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
    ln_cnt   NUMBER;
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
    ov_retcd := FALSE;
--
    -- 登録
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(iimb.item_id)
      INTO   ln_cnt
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no = ir_masters_rec.item_code
      AND    ROWNUM       = 1;
--
    -- 登録以外
    ELSE
      SELECT COUNT(iimb.item_id)
      INTO   ln_cnt
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no      = ir_masters_rec.item_code
      AND    iimb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM            = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
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
  END chk_ic_item_mst_b;
--
  /***********************************************************************************
   * Procedure Name   : chk_xxcmn_item_mst_b
   * Description      : 品目コードの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_xxcmn_item_mst_b(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_xxcmn_item_mst_b'; -- プログラム名
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
    ln_cnt   NUMBER;
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
    ov_retcd := FALSE;
--
    -- 登録
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(ximb.item_id)
      INTO   ln_cnt
      FROM   xxcmn_item_mst_b ximb,
             ic_item_mst_b iimb
      WHERE  iimb.item_no = ir_masters_rec.item_code
      AND    ximb.item_id = iimb.item_id
      AND    ROWNUM       = 1;
--
    -- 登録以外
    ELSE
      SELECT COUNT(ximb.item_id)
      INTO   ln_cnt
      FROM   xxcmn_item_mst_b ximb,
             ic_item_mst_b iimb
      WHERE  iimb.item_no      = ir_masters_rec.item_code
      AND    ximb.item_id      = iimb.item_id
      AND    iimb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM            = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
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
  END chk_xxcmn_item_mst_b;
--
  /***********************************************************************************
   * Procedure Name   : chk_gmi_item_category
   * Description      : 品目コードの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_gmi_item_category(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_gmi_item_category'; -- プログラム名
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
    ln_cnt   NUMBER;
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
    ov_retcd := FALSE;
--
    -- 登録
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(gic.item_id)
      INTO   ln_cnt
      FROM   gmi_item_categories gic,
             ic_item_mst_b iimb
      WHERE  iimb.item_no = ir_masters_rec.item_code
      AND    gic.item_id  = iimb.item_id
      AND    ROWNUM       = 1;
--
    -- 登録以外
    ELSE
      SELECT COUNT(gic.item_id)
      INTO   ln_cnt
      FROM   gmi_item_categories gic,
             ic_item_mst_b iimb
      WHERE  iimb.item_no      = ir_masters_rec.item_code
      AND    gic.item_id       = iimb.item_id
      AND    iimb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM            = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
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
  END chk_gmi_item_category;
--
  /***********************************************************************************
   * Procedure Name   : chk_cm_cmpt_dtl
   * Description      : 品目コードの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_cm_cmpt_dtl(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    lb_cmpnt_id     IN            NUMBER,       -- コンポーネント区分ID
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cm_cmpt_dtl'; -- プログラム名
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
    ln_cnt   NUMBER;
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
    ov_retcd := FALSE;
--
    -- 登録
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(ccd.item_id)
      INTO   ln_cnt
      FROM   cm_cmpt_dtl ccd,
             ic_item_mst_b iimb
      WHERE  iimb.item_no      = ir_masters_rec.item_code
      AND    ccd.item_id       = iimb.item_id
      AND    ccd.calendar_code = gv_item_cal                     -- 2008.06.23 Add
      AND    ROWNUM            = 1;
--
    -- 登録以外
    ELSE
      SELECT COUNT(ccd.item_id)
      INTO   ln_cnt
      FROM   cm_cmpt_dtl ccd,
             ic_item_mst_b iimb
      WHERE  iimb.item_no         = ir_masters_rec.item_code
      AND    ccd.item_id          = iimb.item_id
      AND    iimb.inactive_ind    = gv_inactive_ind_on
      AND    ccd.cost_cmpntcls_id = lb_cmpnt_id
      AND    ccd.calendar_code    = gv_item_cal                  -- 2008.06.23 Add
      AND    ROWNUM               = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
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
  END chk_cm_cmpt_dtl;
--
  /***********************************************************************************
   * Procedure Name   : chk_parent_id
   * Description      : 品目IDの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_parent_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parent_id'; -- プログラム名
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
    ln_cnt   NUMBER;
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
    ov_retcd := FALSE;
--
    -- OPM品目マスタの存在チェック
    SELECT COUNT(imb.item_id)
    INTO   ln_cnt
    FROM   ic_item_mst_b imb
    WHERE  imb.item_no      = ir_masters_rec.parent_item_code
    AND    imb.inactive_ind = gv_inactive_ind_on
    AND    ROWNUM           = 1;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
--
    ELSE
--
      -- 自分自身の品目コードと一致
      IF (ir_masters_rec.item_code = ir_masters_rec.parent_item_code) THEN
        ov_retcd := TRUE;
--
      ELSE
--
        -- 以前に存在している
        SELECT COUNT(xif.seq_number)
        INTO   ln_cnt
        FROM   xxcmn_item_if xif
        WHERE  xif.item_code   = ir_masters_rec.parent_item_code
        AND    xif.seq_number <= ir_masters_rec.seq_number
        AND    (xif.proc_code  = gn_proc_insert
        OR      xif.proc_code  = gn_proc_update)
        AND    ROWNUM          = 1;
--
        IF (ln_cnt > 0) THEN
          ov_retcd := TRUE;
        END IF;
      END IF;
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
  END chk_parent_id;
--
  /***********************************************************************************
   * Procedure Name   : check_proc_code
   * Description      : 操作対象のデータであることを確認します。
   ***********************************************************************************/
  PROCEDURE check_proc_code(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN            masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc_code'; -- プログラム名
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
    --処理区分が(登録・更新・削除)以外
    IF ((ir_masters_rec.proc_code <> gn_proc_insert)
    AND (ir_masters_rec.proc_code <> gn_proc_update)
    AND (ir_masters_rec.proc_code <> gn_proc_delete)) THEN
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_016,
                                                'VALUE',    TO_CHAR(ir_masters_rec.proc_code)),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
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
  END check_proc_code;
--
  /***********************************************************************************
   * Procedure Name   : get_user_name
   * Description      : ユーザー名の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_user_name(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_name'; -- プログラム名
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
    BEGIN
--
      SELECT user_name
      INTO   gv_user_name
      FROM   fnd_user
      WHERE  user_id = gn_user_id
      AND    ROWNUM  = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_user_name := NULL;
    END;
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
  END get_user_name;
--
  /***********************************************************************************
   * Procedure Name   : init_cmpntcls_id
   * Description      : コンポーネント区分IDの初期取得を行います。
   ***********************************************************************************/
  PROCEDURE init_cmpntcls_id(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_cmpntcls_id'; -- プログラム名
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
    ln_cnt      NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR cmpnt_cur
    IS
      SELECT ccmt.cost_cmpntcls_id,
             ccm.cost_cmpntcls_code,
             ccmt.cost_cmpntcls_desc,
             DECODE(ccmt.cost_cmpntcls_desc,
                    gv_raw_material_cost, 1,                   -- 原料
                    gv_agein_cost,        2,                   -- 再製費
                    gv_material_cost,     3,                   -- 資材費
                    gv_pack_cost,         4,                   -- 包装費
                    gv_out_order_cost,    5,                   -- 外注加工費
                    gv_safekeep_cost,     6,                   -- 保管費
                    gv_other_expense_cost,7,                   -- その他経費
                    gv_spare1,            8,                   -- 予備１
                    gv_spare2,            9,                   -- 予備２
                    gv_spare3,            10                   -- 予備３
                   ) as sorter
      FROM   cm_cmpt_mst_tl ccmt,
             cm_cmpt_mst ccm
      WHERE  ccmt.cost_cmpntcls_id   = ccm.cost_cmpntcls_id
      AND    ccmt.language           = gv_language
      AND    ccmt.cost_cmpntcls_desc IN (
                            gv_raw_material_cost,
                            gv_agein_cost,
                            gv_material_cost,
                            gv_pack_cost,
                            gv_out_order_cost,
                            gv_safekeep_cost,
                            gv_other_expense_cost,
                            gv_spare1,
                            gv_spare2,
                            gv_spare3);
--
    -- *** ローカル・レコード ***
    lr_cmpnt_rec cmpnt_cur%ROWTYPE;
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
    gt_cmpntcls_mast.DELETE;
--
    <<init_loop>>
    FOR i IN 1..10 LOOP
--
      gt_cmpntcls_mast(i).cost_cmpntcls_id   := NULL;
      gt_cmpntcls_mast(i).cost_cmpntcls_code := NULL;
      gt_cmpntcls_mast(i).cost_cmpntcls_desc := NULL;
--
    END LOOP init_loop;
--
    OPEN cmpnt_cur;
--
    <<cmpnt_loop>>
    LOOP
      FETCH cmpnt_cur INTO lr_cmpnt_rec;
      EXIT WHEN cmpnt_cur%NOTFOUND;
--
      ln_cnt := lr_cmpnt_rec.sorter;
--
      gt_cmpntcls_mast(ln_cnt).cost_cmpntcls_id   := lr_cmpnt_rec.cost_cmpntcls_id;
      gt_cmpntcls_mast(ln_cnt).cost_cmpntcls_code := lr_cmpnt_rec.cost_cmpntcls_code;
      gt_cmpntcls_mast(ln_cnt).cost_cmpntcls_desc := lr_cmpnt_rec.cost_cmpntcls_desc;
      gt_cmpntcls_mast(ln_cnt).sorter             := ln_cnt;
--
    END LOOP cmpnt_loop;
--
    CLOSE cmpnt_cur;
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
  END init_cmpntcls_id;
--
  /***********************************************************************************
   * Procedure Name   : get_price
   * Description      : 単価の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_price(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    iv_expense_type IN            VARCHAR2,     -- 対象費目区分
    on_price           OUT NOCOPY NUMBER,       -- 単価
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price'; -- プログラム名
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
    ln_price      NUMBER;
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
--
--- 2008/10/10 MOD↓
          -- コンポーネント区分ごとの単価合計値取得。取得できない場合は0。
      SELECT NVL(SUM(xpl.unit_price),0)   unit_price       -- 単価合計
      INTO   ln_price
      FROM   xxpo_price_headers    xph              -- 仕入/標準原価ヘッダ
            ,xxpo_price_lines      xpl              -- 仕入/標準原価明細
            ,xxcmn_lookup_values_v xlvv1            -- クイックコード情報VIEW  費目区分情報
            ,xxcmn_lookup_values_v xlvv2            -- クイックコード情報VIEW  原価内訳区分情報
      WHERE  -- *** 結合条件 仕入/標準原価明細・費目区分情報 *** --
             xpl.expense_item_type = xlvv1.attribute1
             -- *** 結合条件 費目区分情報・原価内訳区分情報 *** --
      AND    xlvv1.attribute2 = xlvv2.lookup_code
             -- *** 抽出条件 *** --
      AND    xph.price_header_id   = xpl.price_header_id
      AND    xph.price_type        = gv_lookup_code
      AND    xph.item_code         = ir_masters_rec.item_code
      AND    xlvv1.lookup_type     = gv_expense_item_type   -- 費目区分
      AND    xlvv2.lookup_type     = gv_cmpntcls_type       -- 原価内訳区分
      AND    xlvv2.meaning         = iv_expense_type        -- コンポーネント区分名
    ;
--- 2008/10/10 MOD↑
      on_price := ln_price;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_price := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_price;
--
  /***********************************************************************************
   * Procedure Name   : get_item_id
   * Description      : 品目IDの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_item_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_id'; -- プログラム名
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
    BEGIN
--
      SELECT imb.item_id
      INTO   ir_masters_rec.item_id
      FROM   ic_item_mst_b imb
      WHERE  imb.item_no      = ir_masters_rec.item_code
      AND    imb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM           = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.item_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_item_id;
--
  /***********************************************************************************
   * Procedure Name   : get_parent_id
   * Description      : 品目IDの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_parent_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_parent_id'; -- プログラム名
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
    BEGIN
--
      SELECT imb.item_id
      INTO   ir_masters_rec.parent_item_id
      FROM   ic_item_mst_b imb
      WHERE  imb.item_no      = ir_masters_rec.parent_item_code
      AND    imb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM           = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.parent_item_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_parent_id;
--
  /***********************************************************************************
   * Procedure Name   : get_period_code
   * Description      : 期間の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_period_code(
    ir_status_rec   IN OUT NOCOPY status_rec,   -- 処理状況  2008/08/27 Add
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_code'; -- プログラム名
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
    cv_item_name   CONSTANT VARCHAR2(100) := '原価適用開始日';               -- 2008/08/27 Add
    cv_table_name  CONSTANT VARCHAR2(100) := '原価カレンダー';               -- 2008/08/27 Add
--
    -- *** ローカル変数 ***
    cv_start_date  VARCHAR2(10);                                             -- 2008/08/27 Add
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
--
      cv_start_date := TO_CHAR(ir_masters_rec.standard_start_date,'YYYY/MM/DD');   -- 2008/08/27 Add
--
      SELECT ccd.period_code
      INTO   ir_masters_rec.period_code
      FROM   cm_cldr_dtl ccd
      WHERE  ccd.calendar_code = gv_item_cal
      AND    ccd.start_date   <= ir_masters_rec.standard_start_date
      AND    ccd.end_date     >= ir_masters_rec.standard_start_date
      AND    ROWNUM            = 1;
--
-- 2008/08/27 Add ↓
      IF (ir_masters_rec.period_code IS NULL) THEN
-- 2008/10/02 v1.13 ADD START
       -- 更新
       IF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
        -- 原価カレンダ存在チェックフラグをオン
        ir_masters_rec.cldr_n_flg := TRUE;
        ir_masters_rec.cldr_n_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_023,
                                                  gv_tkn_item_name,  cv_item_name,
                                                  gv_tkn_item_value, cv_start_date,
                                                  gv_tkn_table_name, cv_table_name);
--
       ELSE
        ir_masters_rec.cldr_n_flg := FALSE;
        ir_masters_rec.cldr_n_msg := NULL;
-- 2008/10/02 v1.13 ADD END
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_023,
                                                  gv_tkn_item_name,  cv_item_name,
                                                  gv_tkn_item_value, cv_start_date,
                                                  gv_tkn_table_name, cv_table_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
  --
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
-- 2008/10/02 v1.13 ADD START
       END IF;
      ELSE
        ir_masters_rec.cldr_n_flg := FALSE;
        ir_masters_rec.cldr_n_msg := NULL;
-- 2008/10/02 v1.13 ADD END
      END IF;
-- 2008/08/27 Add ↑
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.period_code := NULL;
-- 2008/10/02 v1.13 ADD START
        -- 更新
        IF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
         -- 原価カレンダ存在チェックフラグをオン
         ir_masters_rec.cldr_n_flg := TRUE;
         ir_masters_rec.cldr_n_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                   gv_msg_80b_023,
                                                   gv_tkn_item_name,  cv_item_name,
                                                   gv_tkn_item_value, cv_start_date,
                                                   gv_tkn_table_name, cv_table_name);
--
        ELSE
          ir_masters_rec.cldr_n_flg := FALSE;
          ir_masters_rec.cldr_n_msg := NULL;
--
-- 2008/10/02 v1.13 ADD END
-- 2008/08/27 Add ↓
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_023,
                                                  gv_tkn_item_name,  cv_item_name,
                                                  gv_tkn_item_value, cv_start_date,
                                                  gv_tkn_table_name, cv_table_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
  --
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
-- 2008/08/27 Add ↑
-- 2008/10/02 v1.13 ADD START
        END IF;
-- 2008/10/02 v1.13 ADD END
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_period_code;
--
  /***********************************************************************************
   * Procedure Name   : get_uom_code
   * Description      : 単位の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_uom_code(
    on_uom_code        OUT NOCOPY VARCHAR2,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uom_code'; -- プログラム名
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
    BEGIN
--
      SELECT mum.uom_code
      INTO   on_uom_code
      FROM   msc_units_of_measure mum
      WHERE  mum.description = gv_description
      AND    ROWNUM          = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_uom_code := gv_def_item_um;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_uom_code;
--
  /***********************************************************************************
   * Procedure Name   : get_cmpnt_id
   * Description      : 原価詳細ID名の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_cmpnt_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cmpnt_id'; -- プログラム名
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
    BEGIN
--
      SELECT ccd.cmpntcost_id
      INTO   ir_masters_rec.cmpntcost_id
      FROM   cm_cmpt_dtl ccd
      WHERE  ccd.item_id          = ir_masters_rec.item_id
      AND    ccd.cost_cmpntcls_id = ir_masters_rec.cost_id
      AND    ccd.period_code      = ir_masters_rec.period_code
      AND    ccd.whse_code        = gv_whse_code
      AND    ccd.calendar_code    = gv_item_cal
      AND    ccd.cost_mthd_code   = gv_cost_div
      AND    ROWNUM               = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.cmpntcost_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_cmpnt_id;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxcmn_item_mst
   * Description      : OPM品目アドオンマスタの処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_xxcmn_item_mst(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    in_kbn          IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxcmn_item_mst'; -- プログラム名
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
    -- 親品目IDの取得
    get_parent_id(ir_masters_rec,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 登録
    IF (in_kbn = gn_proc_insert) THEN
      INSERT INTO xxcmn_item_mst_b
         (item_id
         ,start_date_active
         ,end_date_active
         ,active_flag
         ,item_name
         ,item_short_name
         ,item_name_alt
         ,parent_item_id
         ,obsolete_class
         ,obsolete_date
         ,rate_class
         ,raw_material_consumption
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
         ,palette_max_cs_qty    -- 配数
         ,palette_max_step_qty  -- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
      ) VALUES (
          ir_masters_rec.item_id                                      -- 品目ID
         ,gd_min_date                                                 -- 運用開始日
         ,gd_max_date                                                 -- 運用終了日
         ,gv_active_flag_mi                                           -- 適用済フラグ
         ,ir_masters_rec.item_name                                    -- 正式名
         ,ir_masters_rec.item_short_name                              -- 略称
         ,ir_masters_rec.item_name_alt                                -- カナ名
         ,ir_masters_rec.parent_item_id                               -- 親品目ID
         ,ir_masters_rec.abolition_code                               -- 廃止区分
         ,ir_masters_rec.abolition_date                               -- 廃止日(製造中止)
         ,ir_masters_rec.rate_code                                    -- 率区分
         ,ir_masters_rec.raw_mate_consumption                         -- 原料使用量
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
         ,ir_masters_rec.palette_max_cs_qty                           -- 配数
         ,ir_masters_rec.palette_max_step_qty                         -- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
         ,gn_user_id
         ,gd_sysdate
         ,gn_user_id
         ,gd_sysdate
         ,gn_login_id
         ,gn_request_id
         ,gn_appl_id
         ,gn_program_id
         ,gd_sysdate
      );
--
    -- 更新
    ELSIF (in_kbn = gn_proc_update) THEN
      UPDATE xxcmn_item_mst_b
      SET    item_name                = ir_masters_rec.item_name            -- 正式名
            ,item_short_name          = ir_masters_rec.item_short_name      -- 略称
            ,item_name_alt            = ir_masters_rec.item_name_alt        -- カナ名
            ,parent_item_id           = ir_masters_rec.parent_item_id       -- 親品目ID
            ,obsolete_class           = ir_masters_rec.abolition_code       -- 廃止区分
            ,obsolete_date            = ir_masters_rec.abolition_date       -- 廃止日(製造中止)
            ,rate_class               = ir_masters_rec.rate_code            -- 率区分
            ,raw_material_consumption = ir_masters_rec.raw_mate_consumption -- 原料使用量
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
            ,palette_max_cs_qty       = ir_masters_rec.palette_max_cs_qty   -- 配数
            ,palette_max_step_qty     = ir_masters_rec.palette_max_step_qty -- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
-- 2008/10/21 ADD START
            ,active_flag              = gv_active_flag_mi -- 適用済フラグ
-- 2008/10/21 ADD END
            ,last_updated_by          = gn_user_id
            ,last_update_date         = gd_sysdate
            ,last_update_login        = gn_login_id
            ,request_id               = gn_request_id
            ,program_application_id   = gn_appl_id
            ,program_id               = gn_program_id
            ,program_update_date      = gd_sysdate
      WHERE  item_id = ir_masters_rec.item_id;
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
  END proc_xxcmn_item_mst;
--
  /***********************************************************************************
   * Procedure Name   : proc_item_category
   * Description      : OPM品目カテゴリ割当の処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_item_category(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    in_kbn          IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_item_category'; -- プログラム名
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
    ln_old_category_id    gmi_item_categories.category_id%TYPE;
    ln_new_category_id    gmi_item_categories.category_id%TYPE;
    lv_description        mtl_category_sets_tl.description%TYPE;
    lv_segment1           mtl_categories_b.segment1%TYPE;
    ln_cnt                NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR category_cur
    IS
       SELECT mcsb.category_set_id,                       -- カテゴリセットID
              mcst.description                            -- カテゴリ名
       FROM   mtl_category_sets_tl mcst,
              mtl_category_sets_b  mcsb,
              mtl_categories_b     mcb
       WHERE  mcsb.category_set_id = mcst.category_set_id
       AND    mcsb.structure_id    = mcb.structure_id
       AND    mcst.language        = gv_language
       AND    mcst.source_lang     = gv_language
       AND    mcst.description IN (
                                   gv_crowd_code,                        -- 群コード
                                   gv_policy_group_code,                 -- 政策群コード
                                   gv_marke_crowd_code,                  -- マーケ用群コード
                                   gv_product_div_code,                  -- 商品製品区分
                                   gv_arti_div_code,                     -- 本社商品区分
                                   gv_div_tea_code                       -- バラ茶区分
                                  )
       GROUP BY mcsb.category_set_id,mcst.description
       ;
--
    -- *** ローカル・レコード ***
    lr_category_rec category_cur%ROWTYPE;
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
    -- 登録の場合のみ
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
--
      -- 品目カテゴリマスタの初期値登録
      proc_mtl_categories(ir_masters_rec,
                          gn_kbn_def,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 品目カテゴリマスタの入力値登録
    proc_mtl_categories(ir_masters_rec,
                        gn_kbn_oth,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    OPEN category_cur;
--
    <<category_loop>>
    LOOP
      FETCH category_cur INTO lr_category_rec;
      EXIT WHEN category_cur%NOTFOUND;
--
      lv_description := lr_category_rec.description;
--
      -- 群コード
      IF (lv_description = gv_crowd_code) THEN
        lv_segment1    := ir_masters_rec.new_crowd_code;
--
      -- 政策群コード
      ELSIF (lv_description = gv_policy_group_code) THEN
        lv_segment1    := ir_masters_rec.policy_group_code;
--
      -- マーケ用群コード
      ELSIF (lv_description = gv_marke_crowd_code) THEN
        lv_segment1    := ir_masters_rec.marke_crowd_code;
--
      -- 商品製品区分
      ELSIF (lv_description = gv_product_div_code) THEN
        lv_segment1    := ir_masters_rec.product_div_code;
--
      -- 本社商品区分
      ELSIF (lv_description = gv_arti_div_code) THEN
        lv_segment1    := ir_masters_rec.arti_div_code;
--
      -- バラ茶区分
      ELSIF (lv_description = gv_div_tea_code) THEN
        lv_segment1    := ir_masters_rec.div_tea_code;
      END IF;
--
      -- 存在チェック
      BEGIN
         SELECT COUNT(1)
         INTO   ln_cnt
         FROM   mtl_category_sets_tl mcst,
                mtl_category_sets_b  mcsb,
                gmi_item_categories  gic
         WHERE  mcsb.category_set_id = mcst.category_set_id
         AND    mcsb.category_set_id = gic.category_set_id
         AND    mcst.language        = gv_language
         AND    mcst.source_lang     = gv_language
         AND    mcst.description     = lv_description
         AND    gic.item_id          = ir_masters_rec.item_id
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_cnt := 0;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 更新対象取得
      BEGIN
         SELECT mcb.category_id
         INTO   ln_new_category_id
         FROM   mtl_category_sets_tl mcst,
                mtl_category_sets_b  mcsb,
                mtl_categories_b     mcb
         WHERE  mcsb.category_set_id = mcst.category_set_id
         AND    mcsb.structure_id    = mcb.structure_id
         AND    mcst.language        = gv_language
         AND    mcst.source_lang     = gv_language
         AND    mcst.description     = lv_description
         AND    mcb.segment1         = lv_segment1
         AND    ROWNUM               = 1
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_new_category_id := NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      IF (ln_new_category_id IS NOT NULL) THEN
--
        -- 存在しない
        IF (ln_cnt = 0) THEN
--
          INSERT INTO gmi_item_categories
               (item_id
               ,category_set_id
               ,category_id
               ,created_by
               ,creation_date
               ,last_updated_by
               ,last_update_date
               ,last_update_login)
            VALUES (
                ir_masters_rec.item_id
               ,lr_category_rec.category_set_id
               ,ln_new_category_id
               ,gn_user_id
               ,gd_sysdate
               ,gn_user_id
               ,gd_sysdate
               ,gn_login_id
            );
--
        -- 存在する
        ELSE
--
          -- 更新先取得
          BEGIN
            SELECT gic.category_id
            INTO   ln_old_category_id
            FROM   mtl_category_sets_tl mcst,
                   mtl_category_sets_b  mcsb,
                   gmi_item_categories  gic
            WHERE  mcsb.category_set_id = mcst.category_set_id
            AND    mcsb.category_set_id = gic.category_set_id
            AND    mcst.language        = gv_language
            AND    mcst.source_lang     = gv_language
            AND    mcst.description     = lv_description
            AND    gic.item_id          = ir_masters_rec.item_id
            AND    ROWNUM               = 1
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_old_category_id := NULL;
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
--
          IF (ln_old_category_id IS NOT NULL) THEN
--
            -- 更新
            UPDATE gmi_item_categories
            SET    category_id       = ln_new_category_id
                  ,last_updated_by   = gn_user_id
                  ,last_update_date  = gd_sysdate
                  ,last_update_login = gn_login_id
            WHERE  item_id         = ir_masters_rec.item_id
            AND    category_set_id = lr_category_rec.category_set_id
            AND    category_id     = ln_old_category_id;
          END IF;
        END IF;
      END IF;
--
    END LOOP category_loop;
--
    CLOSE category_cur;
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
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END proc_item_category;
--
  /***********************************************************************************
   * Procedure Name   : proc_ic_item_mst
   * Description      : OPM品目マスタの処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_ic_item_mst(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    in_kbn          IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ic_item_mst'; -- プログラム名
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
    lv_attribute10             ic_item_mst_b.attribute10%TYPE;
    lv_attribute16             ic_item_mst_b.attribute16%TYPE;
    lv_attribute25             ic_item_mst_b.attribute25%TYPE;
-- 2009/01/09 H.Sakuma Add Start 本番#950
    lv_attribute30             ic_item_mst_b.attribute30%TYPE;
-- 2009/01/09 H.Sakuma Add End   本番#950
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
    -- 更新
    IF (in_kbn = gn_proc_update) THEN
--
      -- 商品区分＝リーフ
      IF (ir_masters_rec.arti_div_code = gv_div_code_reef) THEN
        lv_attribute10 := gv_rate_code_reef;
        lv_attribute16 := ir_masters_rec.weight_volume;
--2008/09/08 Mod ↓
--        lv_attribute25 := NULL;
        lv_attribute25 := gv_def_code_zero;
--2008/09/08 Mod ↑
      ELSE
        lv_attribute10 := gv_rate_code_drink;
--2008/09/08 Mod ↓
--        lv_attribute16 := NULL;
        lv_attribute16 := gv_def_code_zero;
--2008/09/08 Mod ↑
        lv_attribute25 := ir_masters_rec.weight_volume;
      END IF;
-- 2009/01/09 H.Sakuma Add Start 本番#950
    lv_attribute30     :=  TO_CHAR(SYSDATE, 'YYYY/MM/DD');
-- 2009/01/09 H.Sakuma Add End   本番#950
--
      UPDATE ic_item_mst_b
      SET    item_desc1             = ir_masters_rec.item_name
            ,attribute1             = ir_masters_rec.old_crowd_code
            ,attribute2             = ir_masters_rec.new_crowd_code
            ,attribute3             = ir_masters_rec.crowd_start_days
            ,attribute4             = ir_masters_rec.old_price
            ,attribute5             = ir_masters_rec.new_price
            ,attribute6             = ir_masters_rec.price_start_days
            ,attribute7             = ir_masters_rec.old_business_cost
            ,attribute8             = ir_masters_rec.new_business_cost
            ,attribute9             = ir_masters_rec.buis_start_days
            ,attribute10            = lv_attribute10
            ,attribute11            = ir_masters_rec.case_num
            ,attribute12            = ir_masters_rec.net
            ,attribute13            = ir_masters_rec.sale_start_days
            ,attribute16            = lv_attribute16
            ,attribute21            = ir_masters_rec.jan_code
            ,attribute25            = lv_attribute25
            ,attribute26            = ir_masters_rec.sale_obj_code
-- 2009/01/09 H.Sakuma Add Start 本番#950
            ,attribute30            = lv_attribute30
-- 2009/01/09 H.Sakuma Add End   本番#950
            ,inactive_ind           = gv_inactive_ind_on
            ,last_updated_by        = gn_user_id
            ,last_update_date       = gd_sysdate
            ,last_update_login      = gn_login_id
            ,request_id             = gn_request_id
            ,program_application_id = gn_appl_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_sysdate
      WHERE  item_id = ir_masters_rec.item_id;
--
    -- 削除
    ELSIF (in_kbn = gn_proc_delete) THEN
      UPDATE ic_item_mst_b
      SET    inactive_ind           = gv_inactive_ind_off
            ,last_updated_by        = gn_user_id
            ,last_update_date       = gd_sysdate
            ,last_update_login      = gn_login_id
            ,request_id             = gn_request_id
            ,program_application_id = gn_appl_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_sysdate
      WHERE  item_id = ir_masters_rec.item_id;
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
  END proc_ic_item_mst;
--
  /***********************************************************************************
   * Procedure Name   : chk_price
   * Description      : 単価のチェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_price(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    ov_retmsg          OUT NOCOPY VARCHAR2,     -- エラーメッセージ
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_price'; -- プログラム名
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
    ln_price     NUMBER;
    lv_type      VARCHAR2(2);
    ln_flg       NUMBER;
    ln_ind       NUMBER;
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
    ln_flg := 0;
    ov_retcd := TRUE;
--
    <<chk_price_loop>>
    FOR i IN 1..10 LOOP
-- 2008/09/08 Mod ↓
--      lv_type := TO_CHAR(i);
-- 2008/10/10 Mod ↓
--      lv_type := TO_CHAR(ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id);
-- 2008/10/10 Mod ↑
-- 2008/09/08 Mod ↑
--
      -- 入力あり
      IF (ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id IS NOT NULL) THEN
--
-- 2008/10/10 Mod ↓
--        -- 単価の取得
--        get_price(ir_masters_rec,
--                  lv_type,
--                  ln_price,
--                  lv_errbuf,
--                  lv_retcode,
--                  lv_errmsg);
--
        -- 単価の取得
        get_price(ir_masters_rec,
                  ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_desc,
                  ln_price,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
-- 2008/10/10 Mod ↑
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
-- 2008/09/08 Del ↓
--        IF (lv_type = ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id) THEN
-- 2008/09/08 Del ↑
--
          -- 入力あり
          IF (ir_masters_rec.cmpntcls_mast(i).cost_price IS NOT NULL) THEN
--
-- 2008/10/02 v1.13 ADD START
--------------------------------------------------------------------------------
-- LOG START
--------------------------------------------------------------------------------
           FND_FILE.PUT_LINE( FND_FILE.LOG, '品名コード：'
                                            || ir_masters_rec.item_code
                                            || ', '
                                            || 'コンポーネント区分名：'
                                            || ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_desc);
           FND_FILE.PUT_LINE( FND_FILE.LOG, '単価：'
                                            || ln_price);
           FND_FILE.PUT_LINE( FND_FILE.LOG, '金額：'
                                            || ir_masters_rec.cmpntcls_mast(i).cost_price);
--------------------------------------------------------------------------------
-- LOG END
--------------------------------------------------------------------------------
-- 2008/10/02 v1.13 ADD END
            -- 金額の比較
            IF (NVL(ln_price,-1) <> ir_masters_rec.cmpntcls_mast(i).cost_price) THEN
              ln_flg := 1;
              ov_retmsg := ov_retmsg || ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_desc;
-- 2008/09/08 Mod ↓
--              IF (i <> 10) THEN
              IF (i < 10) THEN
-- 2008/09/08 Mod ↑
                ov_retmsg := ov_retmsg || gv_msg_pnt;
              END IF;
            END IF;
          END IF;
-- 2008/09/08 Del ↓
--        END IF;
-- 2008/09/08 Del ↑
      END IF;
--
    END LOOP chk_price_loop;
--
    IF (ln_flg = 1) THEN
      ov_retcd := FALSE;
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
  END chk_price;
--
  /***********************************************************************************
   * Procedure Name   : check_item_ins
   * Description      : 品目登録用データのチェック処理を行います。(B-2)
   ***********************************************************************************/
  PROCEDURE check_item_ins(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_ins'; -- プログラム名
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
    lb_retcd     BOOLEAN;
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
    -- 以前に存在していない
    IF ((ir_masters_rec.row_ins_cnt > 0)
     OR (ir_masters_rec.row_upd_cnt > 0)
     OR (ir_masters_rec.row_del_cnt > 0)) THEN
--
      -- 重複エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- 品目の存在チェック(OPM品目マスタ)
    chk_ic_item_mst_b(ir_masters_rec,
                      lb_retcd,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在している
    IF (lb_retcd) THEN
--
      -- 重複エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- 品目の存在チェック(OPM品目アドオンマスタ)
    chk_xxcmn_item_mst_b(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在している
    IF (lb_retcd) THEN
--
      -- 重複エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- 品目の存在チェック(OPM品目カテゴリ割当)
    chk_gmi_item_category(ir_masters_rec,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在している
    IF (lb_retcd) THEN
--
      -- 重複エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- 親品目の存在チェック
    chk_parent_id(ir_masters_rec,
                  lb_retcd,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在しない
    IF (NOT lb_retcd) THEN
--
      -- 存在エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_108,
                                                gv_tkn_ng_item_cd,
                                                ir_masters_rec.parent_item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_item_ins_expt THEN
      NULL;
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
  END check_item_ins;
--
  /***********************************************************************************
   * Procedure Name   : check_item_upd
   * Description      : 品目更新用データのチェック処理を行います。(B-3)
   ***********************************************************************************/
  PROCEDURE check_item_upd(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_upd'; -- プログラム名
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
    lb_retcd     BOOLEAN;
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
    -- 以前に存在していない
    IF (ir_masters_rec.row_del_cnt > 0) THEN
--
      -- 存在エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_102,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_upd_expt;
    END IF;
--
    -- 以前に登録データが存在しない
    IF (ir_masters_rec.row_ins_cnt = 0) THEN
--
      -- 品目の存在チェック(OPM品目マスタ)
      chk_ic_item_mst_b(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在していない
      IF (NOT lb_retcd) THEN
--
        -- 存在エラー
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_102,
                                                  gv_tkn_ng_hinmoku,
                                                  ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
--
      -- 品目の存在チェック(OPM品目アドオンマスタ)
      chk_xxcmn_item_mst_b(ir_masters_rec,
                           lb_retcd,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在していない
      IF (NOT lb_retcd) THEN
--
        -- 存在エラー
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_102,
                                                  gv_tkn_ng_hinmoku,
                                                  ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
--
      -- 品目の存在チェック(OPM品目カテゴリ割当)
      chk_gmi_item_category(ir_masters_rec,
                            lb_retcd,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在していない
      IF (NOT lb_retcd) THEN
--
        -- 存在エラー
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_102,
                                                  gv_tkn_ng_hinmoku,
                                                  ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
--
      -- 親品目の存在チェック
      chk_parent_id(ir_masters_rec,
                    lb_retcd,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF (NOT lb_retcd) THEN
--
        -- 存在エラー
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_108,
                                                  gv_tkn_ng_item_cd,
                                                  ir_masters_rec.parent_item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_item_upd_expt THEN
      NULL;
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
  END check_item_upd;
--
  /***********************************************************************************
   * Procedure Name   : check_item_del
   * Description      : 品目削除用データのチェック処理を行います。(B-4)
   ***********************************************************************************/
  PROCEDURE check_item_del(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_del'; -- プログラム名
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
    lb_retcd     BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    -- 以前に存在していない
    IF (ir_masters_rec.row_del_cnt > 0) THEN
--
      -- 存在ワーニング
      set_warn_status(ir_status_rec,
                      xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                               gv_msg_80b_103,
                                               gv_tkn_ng_hinmoku,
                                               ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_del_expt;
    END IF;
--
    -- 以前に存在していない
    IF (ir_masters_rec.row_ins_cnt = 0) THEN
--
      -- 品目の存在チェック(OPM品目マスタ)
      chk_ic_item_mst_b(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在していない
      IF (NOT lb_retcd) THEN
--
        -- 存在ワーニング
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80b_103,
                                                 gv_tkn_ng_hinmoku,
                                                 ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_del_expt;
      END IF;
--
      -- 品目の存在チェック(OPM品目アドオンマスタ)
      chk_xxcmn_item_mst_b(ir_masters_rec,
                           lb_retcd,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在していない
      IF (NOT lb_retcd) THEN
--
        -- 存在ワーニング
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80b_103,
                                                 gv_tkn_ng_hinmoku,
                                                 ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_del_expt;
      END IF;
--
      -- 品目の存在チェック(OPM品目カテゴリ割当)
      chk_gmi_item_category(ir_masters_rec,
                            lb_retcd,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在していない
      IF (NOT lb_retcd) THEN
--
        -- 存在ワーニング
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80b_103,
                                                 gv_tkn_ng_hinmoku,
                                                 ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_del_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_item_del_expt THEN
      NULL;
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
  END check_item_del;
--
  /***********************************************************************************
   * Procedure Name   : check_cmpt_ins
   * Description      : 品目原価登録用データのチェック処理を行います。(B-8)
   ***********************************************************************************/
  PROCEDURE check_cmpt_ins(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cmpt_ins'; -- プログラム名
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
    lb_retcd     BOOLEAN;
    ln_price     NUMBER;
    lv_retmsg    VARCHAR2(500);
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
    -- 以前に存在している
    IF ((ir_masters_rec.row_ins_cnt > 0)
     OR (ir_masters_rec.row_upd_cnt > 0)
     OR (ir_masters_rec.row_del_cnt > 0)) THEN
--
      -- 重複エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_107,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    -- 品目原価がすべて未入力
    IF ((ir_masters_rec.raw_material_cost IS NULL)
    AND (ir_masters_rec.agein_cost IS NULL)
    AND (ir_masters_rec.material_cost IS NULL)
    AND (ir_masters_rec.pack_cost IS NULL)
    AND (ir_masters_rec.out_order_cost IS NULL)
    AND (ir_masters_rec.safekeep_cost IS NULL)
    AND (ir_masters_rec.other_expense_cost IS NULL)
    AND (ir_masters_rec.spare1 IS NULL)
    AND (ir_masters_rec.spare2 IS NULL)
    AND (ir_masters_rec.spare3 IS NULL)) THEN
--
      -- 品目原価未入力エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_020,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    -- 品目の存在チェック(品目原価マスタ)
    chk_cm_cmpt_dtl(ir_masters_rec,
                    NULL,
                    lb_retcd,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在している
    IF (lb_retcd) THEN
--
      -- 重複エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_107,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    -- 単価のチェック
    chk_price(ir_masters_rec,
              lv_retmsg,
              lb_retcd,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (NOT lb_retcd) THEN
      -- 単価チェックワーニング
      set_warok_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_101,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code,
                                                gv_tkn_ng_genka,
                                                lv_retmsg),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_cmpt_ins_expt THEN
      NULL;
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
  END check_cmpt_ins;
--
  /***********************************************************************************
   * Procedure Name   : check_cmpt_upd
   * Description      : 品目原価更新用データのチェック処理を行います。(B-9)
   ***********************************************************************************/
  PROCEDURE check_cmpt_upd(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cmpt_upd'; -- プログラム名
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
    lb_retcd     BOOLEAN;
    ln_price     NUMBER;
    lv_retmsg    VARCHAR2(500);
    ln_type      NUMBER;
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
    -- 以前に存在していない
    IF (ir_masters_rec.row_del_cnt > 0) THEN
--
      -- 存在エラー
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_105,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_upd_expt;
    END IF;
--
    -- 以前に登録データが存在していない
    IF (ir_masters_rec.row_ins_cnt = 0) THEN
      <<check_cmpt_loop>>
      FOR i IN 1..10 LOOP
--
        ln_type := NULL;
-- 2008/09/08 Mod ↓
/*
--
        -- 原料
        IF ((i = 1) AND (ir_masters_rec.raw_material_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- 再製費
        ELSIF ((i = 2) AND (ir_masters_rec.agein_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- 資材費
        ELSIF ((i = 3) AND (ir_masters_rec.material_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- 包装費
        ELSIF ((i = 4) AND (ir_masters_rec.pack_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- 外注加工費
        ELSIF ((i = 5) AND (ir_masters_rec.out_order_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- 保管費
        ELSIF ((i = 6) AND (ir_masters_rec.safekeep_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- その他経費
        ELSIF ((i = 7) AND (ir_masters_rec.other_expense_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- 予備1
        ELSIF ((i = 8) AND (ir_masters_rec.spare1 IS NOT NULL)) THEN
          ln_type := i;
--
        -- 予備2
        ELSIF ((i = 9) AND (ir_masters_rec.spare2 IS NOT NULL)) THEN
          ln_type := i;
--
        -- 予備3
        ELSIF ((i = 10) AND (ir_masters_rec.spare3 IS NOT NULL)) THEN
          ln_type := i;
        END IF;
--
*/
--
        -- 原料
        IF ((i = 1) AND (ir_masters_rec.raw_material_cost IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 再製費
        ELSIF ((i = 2) AND (ir_masters_rec.agein_cost IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 資材費
        ELSIF ((i = 3) AND (ir_masters_rec.material_cost IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 包装費
        ELSIF ((i = 4) AND (ir_masters_rec.pack_cost IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 外注加工費
        ELSIF ((i = 5) AND (ir_masters_rec.out_order_cost IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 保管費
        ELSIF ((i = 6) AND (ir_masters_rec.safekeep_cost IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- その他経費
        ELSIF ((i = 7) AND (ir_masters_rec.other_expense_cost IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 予備1
        ELSIF ((i = 8) AND (ir_masters_rec.spare1 IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 予備2
        ELSIF ((i = 9) AND (ir_masters_rec.spare2 IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
--
        -- 予備3
        ELSIF ((i = 10) AND (ir_masters_rec.spare3 IS NOT NULL)) THEN
          ln_type := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
        END IF;
--
-- 2008/09/08 Mod ↑
        -- 対象あり
        IF (ln_type IS NOT NULL) THEN
--
          -- 品目の存在チェック(品目原価マスタ)
          chk_cm_cmpt_dtl(ir_masters_rec,
                          ln_type,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 存在していない
          IF (NOT lb_retcd) THEN
--
            -- 存在エラー
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80b_105,
                                                      gv_tkn_ng_hinmoku,
                                                      ir_masters_rec.item_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            RAISE check_cmpt_upd_expt;
          END IF;
        END IF;
--
      END LOOP check_cmpt_loop;
    END IF;
--
    -- 単価のチェック
    chk_price(ir_masters_rec,
              lv_retmsg,
              lb_retcd,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (NOT lb_retcd) THEN
      -- 単価チェックワーニング
      set_warok_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_100,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code,
                                                gv_tkn_ng_genka,
                                                lv_retmsg),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_upd_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_cmpt_upd_expt THEN
      NULL;
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
  END check_cmpt_upd;
--
  /***********************************************************************************
   * Procedure Name   : item_insert_proc
   * Description      : 品目登録処理を行います。
   ***********************************************************************************/
  PROCEDURE item_insert_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- レポート出力結合配列
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_insert_proc'; -- プログラム名
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
    cv_flg_on  CONSTANT VARCHAR2(1)   := '1';     -- 2008/08/27 Add
--
    -- *** ローカル変数 ***
    lv_api_name       VARCHAR2(200);
    lr_item_rec       GMI_ITEM_PUB.ITEM_REC_TYP;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lv_uom_code       msc_units_of_measure.uom_code%TYPE;
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
    -- 単位の取得
    get_uom_code(lv_uom_code,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    lr_item_rec.item_no     := ir_masters_rec.item_code;           -- 品名コード
    lr_item_rec.item_desc1  := ir_masters_rec.item_name;           -- 品名・正式名
    lr_item_rec.item_um     := lv_uom_code;
-- 2008/12/22 v1.18 ADD START
   IF (SUBSTRB(ir_masters_rec.item_code, 1, 1) = '5') THEN
    lr_item_rec.lot_ctl     := gv_lot_ctl_off;
   ELSE
-- 2008/12/22 v1.18 ADD END
    lr_item_rec.lot_ctl     := gv_lot_ctl_on;
-- 2008/12/22 v1.18 ADD START
   END IF;
-- 2008/12/22 v1.18 ADD END
    lr_item_rec.attribute1  := ir_masters_rec.old_crowd_code;      -- 旧・群コード
    lr_item_rec.attribute2  := ir_masters_rec.new_crowd_code;      -- 新・群コード
    lr_item_rec.attribute3  := ir_masters_rec.crowd_start_days;    -- 適用開始日
    lr_item_rec.attribute4  := ir_masters_rec.old_price;           -- 旧・定価
    lr_item_rec.attribute5  := ir_masters_rec.new_price;           -- 新・定価
    lr_item_rec.attribute6  := ir_masters_rec.price_start_days;    -- 適用開始日
    lr_item_rec.attribute7  := ir_masters_rec.old_business_cost;   -- 旧・営業原価
    lr_item_rec.attribute8  := ir_masters_rec.new_business_cost;   -- 新・営業原価
    lr_item_rec.attribute9  := ir_masters_rec.buis_start_days;     -- 適用開始日
--
    -- 商品区分＝リーフ
    IF (ir_masters_rec.arti_div_code = gv_div_code_reef) THEN
      lr_item_rec.attribute10 := gv_rate_code_reef;           -- 容積
    ELSE
      lr_item_rec.attribute10 := gv_rate_code_drink;          -- 重量
    END IF;
    lr_item_rec.attribute11 := ir_masters_rec.case_num;            -- ケース入数
    lr_item_rec.attribute12 := ir_masters_rec.net;                 -- NET
    lr_item_rec.attribute13 := ir_masters_rec.sale_start_days;     -- 適用開始日
    lr_item_rec.attribute21 := ir_masters_rec.jan_code;            -- JANコード
--
    -- 商品区分＝ドリンク
    IF (ir_masters_rec.arti_div_code = gv_div_code_drink) THEN
      lr_item_rec.attribute25 := ir_masters_rec.weight_volume;       -- 重量/体積
      lr_item_rec.attribute16 := gv_def_code_zero;                   -- 2008/09/08 Add
    ELSE
      lr_item_rec.attribute16 := ir_masters_rec.weight_volume;       -- 重量/体積
      lr_item_rec.attribute25 := gv_def_code_zero;                   -- 2008/09/08 Add
    END IF;
    lr_item_rec.attribute26 := ir_masters_rec.sale_obj_code;       -- 売上対象区分
    lr_item_rec.attribute30 := TO_CHAR(SYSDATE, 'YYYY/MM/DD');
--
    -- 2008/02/05 Mod
    lr_item_rec.loct_ctl := gn_loct_ctl_on;                        -- 保管場所
--
    -- 2008.06.25 Mod
    lr_item_rec.user_name := gv_user_name;
--
    lr_item_rec.attribute18 := cv_flg_on;       -- 出荷区分 2008/08/27 Add
--
    -- OPM品目マスタ(登録)
    GMI_ITEM_PUB.CREATE_ITEM(
        P_API_VERSION      => gv_api_ver
       ,P_INIT_MSG_LIST    => FND_API.G_FALSE
       ,P_COMMIT           => FND_API.G_FALSE
       ,P_VALIDATION_LEVEL => FND_API.G_VALID_LEVEL_FULL
       ,P_ITEM_REC         => lr_item_rec
       ,X_RETURN_STATUS    => lv_return_status
       ,X_MSG_COUNT        => ln_msg_count
       ,X_MSG_DATA         => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'GMI_ITEM_PUB.CREATE_ITEM';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80b_013,
                                            gv_tkn_api_name, lv_api_name);
--
      lv_msg_data := lv_errmsg;
--
      xxcmn_common_pkg.put_api_log(
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      lv_errmsg := lv_msg_data;
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.imb_flg := 1;
--
    -- 品目IDの取得
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
-- 2008/12/22 v1.18 ADD START
   IF (lr_item_rec.lot_ctl = gv_lot_ctl_on) THEN
-- 2008/12/22 v1.18 ADD END
    -- 自動ロット採番有効・ロット・サフィックスの更新
    BEGIN
      UPDATE ic_item_mst_b
      SET    autolot_active_indicator = gv_autolot_on
            ,lot_suffix               = gv_lot_suffix_on
-- add start ver1.17
            ,last_updated_by        = gn_user_id
            ,last_update_date       = gd_sysdate
            ,last_update_login      = gn_login_id
            ,request_id             = gn_request_id
            ,program_application_id = gn_appl_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_sysdate
-- add end ver1.17
      WHERE  item_id = ir_masters_rec.item_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
-- 2008/12/22 v1.18 ADD START
   END IF;
-- 2008/12/22 v1.18 ADD END
    -- OPM品目アドオンマスタ(直接)
    proc_xxcmn_item_mst(ir_masters_rec,
                        gn_proc_insert,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.xmb_flg := 1;
--
    -- OPM品目カテゴリ割当
    proc_item_category(ir_masters_rec,
                       gn_proc_insert,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.gic_flg := 1;
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
  END item_insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : item_update_proc
   * Description      : 品目更新処理を行います。
   ***********************************************************************************/
  PROCEDURE item_update_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- レポート出力結合配列
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_update_proc'; -- プログラム名
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
    -- 品目IDの取得
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- OPM品目マスタ(直接)
    proc_ic_item_mst(ir_masters_rec,
                     gn_proc_update,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.imb_flg := 1;
--
    -- OPM品目アドオンマスタ(直接)
    proc_xxcmn_item_mst(ir_masters_rec,
                        gn_proc_update,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.xmb_flg := 1;
--
    -- OPM品目カテゴリ割当
    proc_item_category(ir_masters_rec,
                       gn_proc_update,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.gic_flg := 1;
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
  END item_update_proc;
--
  /***********************************************************************************
   * Procedure Name   : item_delete_proc
   * Description      : 品目削除処理を行います。
   ***********************************************************************************/
  PROCEDURE item_delete_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- レポート出力結合配列
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_delete_proc'; -- プログラム名
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
    -- 品目IDの取得
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- OPM品目マスタ(直接)
    proc_ic_item_mst(ir_masters_rec,
                     gn_proc_delete,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.imb_flg := 1;
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
  END item_delete_proc;
--
  /***********************************************************************************
   * Procedure Name   : cmpt_insert_proc
   * Description      : 品目原価登録処理を行います。
   ***********************************************************************************/
  PROCEDURE cmpt_insert_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- レポート出力結合配列
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cmpt_insert_proc'; -- プログラム名
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
    lv_api_name       VARCHAR2(200);
    lr_this_tbl       GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE;
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lr_head_rec       GMF_ITEMCOST_PUB.HEADER_REC_TYPE;
    lr_ids_tbl        GMF_ITEMCOST_PUB.COSTCMPNT_IDS_TBL_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(5000);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
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
    -- 品目IDの取得
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
/* 2008/08/27 Del ↓
--
    -- 期間の取得
    get_period_code(ir_masters_rec,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
2008/08/27 Del ↑ */
--
    -- 基本設定値
    lr_head_rec.item_id        := ir_masters_rec.item_id;
    lr_head_rec.item_no        := ir_masters_rec.item_code;
    lr_head_rec.whse_code      := gv_whse_code;
    lr_head_rec.calendar_code  := gv_item_cal;
    lr_head_rec.period_code    := ir_masters_rec.period_code;
    lr_head_rec.cost_mthd_code := gv_cost_div;
    lr_head_rec.user_name      := gv_user_name;
--
    ln_cnt := 1;
--
    <<cmpt_insert_loop>>
    FOR i IN 1..10 LOOP
--
      -- 区分入力あり
      IF (ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id IS NOT NULL) THEN
--
        -- 金額入力あり
        IF (ir_masters_rec.cmpntcls_mast(i).cost_price IS NOT NULL) THEN
          lr_this_tbl(ln_cnt).cost_analysis_code := '0000';
          lr_this_tbl(ln_cnt).burden_ind  := 0;
          lr_this_tbl(ln_cnt).delete_mark := 0;
--
          lr_this_tbl(ln_cnt).cmpnt_cost       := ir_masters_rec.cmpntcls_mast(i).cost_price;
          lr_this_tbl(ln_cnt).cost_cmpntcls_id := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
          ln_cnt := ln_cnt + 1;
        END IF;
      END IF;
--
    END LOOP cmpt_insert_loop;
--
    -- 対象あり
    IF (lr_this_tbl.COUNT > 0) THEN
--
      -- 品目原価マスタ(登録)
      GMF_ITEMCOST_PUB.CREATE_ITEM_COST(
          P_API_VERSION         => gv_api_ver
         ,P_INIT_MSG_LIST       => FND_API.G_FALSE
         ,P_COMMIT              => FND_API.G_FALSE
         ,X_RETURN_STATUS       => lv_return_status
         ,X_MSG_COUNT           => ln_msg_count
         ,X_MSG_DATA            => lv_msg_data
         ,P_HEADER_REC          => lr_head_rec
         ,P_THIS_LEVEL_DTL_TBL  => lr_this_tbl
         ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
         ,X_COSTCMPNT_IDS       => lr_ids_tbl
      );
--
      -- 失敗
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        lv_api_name := 'GMF_ITEMCOST_PUB.CREATE_ITEM_COST';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80b_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_msg_data := lv_errmsg;
--
        xxcmn_common_pkg.put_api_log(
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        lv_errmsg := lv_msg_data;
        lv_errbuf := lv_msg_data;
--
        RAISE global_api_expt;
      END IF;
--
      it_report_rec.ccd_flg := 1;
--
    END IF;
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
  END cmpt_insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : cmpt_update_proc
   * Description      : 品目原価更新処理を行います。
   ***********************************************************************************/
  PROCEDURE cmpt_update_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- レポート出力結合配列
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 処理対象データ格納レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cmpt_update_proc'; -- プログラム名
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
    lv_api_name       VARCHAR2(200);
    lr_this_tbl       GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE;
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lr_head_rec       GMF_ITEMCOST_PUB.HEADER_REC_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
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
    -- 品目IDの取得
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
/* 2008/08/27 Del ↓
--
    -- 期間の取得
    get_period_code(ir_masters_rec,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
2008/08/27 Del ↑ */
--
    -- 基本設定値
    lr_head_rec.item_id        := ir_masters_rec.item_id;
    lr_head_rec.item_no        := NULL;
    lr_head_rec.whse_code      := gv_whse_code;
    lr_head_rec.calendar_code  := gv_item_cal;
    lr_head_rec.period_code    := ir_masters_rec.period_code;
    lr_head_rec.cost_mthd_code := gv_cost_div;
    lr_head_rec.user_name      := gv_user_name;
--
    ln_cnt := 1;
--
    <<cmpt_update_loop>>
    FOR i IN 1..10 LOOP
--
      -- 区分入力あり
      IF (ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id IS NOT NULL) THEN
--
        -- 金額入力あり
        IF (ir_masters_rec.cmpntcls_mast(i).cost_price IS NOT NULL) THEN
          lr_this_tbl(ln_cnt).burden_ind  := 0;
          lr_this_tbl(ln_cnt).delete_mark := 0;
--
          ir_masters_rec.cost_id         := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
          lr_this_tbl(ln_cnt).cmpnt_cost := ir_masters_rec.cmpntcls_mast(i).cost_price;
--
          -- 原価詳細IDの取得
          get_cmpnt_id(ir_masters_rec,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          lr_this_tbl(ln_cnt).cmpntcost_id := ir_masters_rec.cmpntcost_id;
          ln_cnt := ln_cnt + 1;
        END IF;
      END IF;
    END LOOP cmpt_update_loop;
--
    -- 対象あり
    IF (lr_this_tbl.COUNT > 0) THEN
--
      -- 品目原価マスタ(更新)
      GMF_ITEMCOST_PUB.UPDATE_ITEM_COST(
          P_API_VERSION         => gv_api_ver
         ,P_INIT_MSG_LIST       => FND_API.G_FALSE
         ,P_COMMIT              => FND_API.G_FALSE
         ,X_RETURN_STATUS       => lv_return_status
         ,X_MSG_COUNT           => ln_msg_count
         ,X_MSG_DATA            => lv_msg_data
         ,P_HEADER_REC          => lr_head_rec
         ,P_THIS_LEVEL_DTL_TBL  => lr_this_tbl
         ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
      );
--
      -- 失敗
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        lv_api_name := 'GMF_ITEMCOST_PUB.UPDATE_ITEM_COST';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80b_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_msg_data := lv_errmsg;
--
        xxcmn_common_pkg.put_api_log(
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        lv_errmsg := lv_msg_data;
        lv_errbuf := lv_msg_data;
--
        RAISE global_api_expt;
      END IF;
--
      it_report_rec.ccd_flg := 1;
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
  END cmpt_update_proc;
--
  /***********************************************************************************
   * Procedure Name   : proc_item
   * Description      : 反映処理を行います。(B-14)
   ***********************************************************************************/
  PROCEDURE proc_item(
    it_ins_mast_tbl IN OUT NOCOPY masters_tbl,  -- 対象データ(登録)
    it_upd_mast_tbl IN OUT NOCOPY masters_tbl,  -- 対象データ(更新)
    it_del_mast_tbl IN OUT NOCOPY masters_tbl,  -- 対象データ(削除)
    it_report_tbl   IN OUT NOCOPY report_tbl,   -- レポート出力結合配列
    in_insert_cnt   IN            NUMBER,       -- 登録件数
    in_update_cnt   IN            NUMBER,       -- 更新件数
    in_delete_cnt   IN            NUMBER,       -- 削除件数
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_item'; -- プログラム名
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
    ln_exec_cnt   NUMBER;
    ln_log_cnt    NUMBER;
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
    -- 登録データの反映(B-14)
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_insert_cnt-1 LOOP
      <<insert_log_loop>>
      FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
        -- 登録
        IF (it_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
          -- SEQ番号
          IF (it_report_tbl(ln_log_cnt).seq_number =
              it_ins_mast_tbl(ln_exec_cnt).seq_number) THEN
--
            -- 品目登録処理
            item_insert_proc(it_report_tbl(ln_log_cnt),
                             it_ins_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            -- 品目原価登録処理
            cmpt_insert_proc(it_report_tbl(ln_log_cnt),
                             it_ins_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END LOOP insert_log_loop;
    END LOOP insert_proc_loop;
--
    -- 更新データの反映(B-14)
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_update_cnt-1 LOOP
      <<update_log_loop>>
      FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
        -- 更新
        IF (it_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
          -- SEQ番号
          IF (it_report_tbl(ln_log_cnt).seq_number =
              it_upd_mast_tbl(ln_exec_cnt).seq_number) THEN
--
-- 2008/10/02 ADD START
           IF (NOT it_upd_mast_tbl(ln_exec_cnt).cldr_n_flg) THEN
-- 2008/10/02 ADD END
            -- 品目原価更新処理
            cmpt_update_proc(it_report_tbl(ln_log_cnt),
                             it_upd_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
-- 2008/10/02 ADD START
           END IF;
-- 2008/10/02 ADD END
            -- 品目更新処理
            item_update_proc(it_report_tbl(ln_log_cnt),
                             it_upd_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END LOOP update_log_loop;
    END LOOP update_proc_loop;
--
    -- 削除データの反映(B-14)
    <<delete_proc_loop>>
    FOR ln_exec_cnt IN 0..in_delete_cnt-1 LOOP
      <<delete_log_loop>>
      FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
        -- 削除
        IF (it_report_tbl(ln_log_cnt).proc_code = gn_proc_delete) THEN
          -- SEQ番号
          IF (it_report_tbl(ln_log_cnt).seq_number =
              it_del_mast_tbl(ln_exec_cnt).seq_number) THEN
--
            -- 削除処理
            item_delete_proc(it_report_tbl(ln_log_cnt),
                             it_del_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END LOOP delete_log_loop;
    END LOOP delete_proc_loop;
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
  END proc_item;
--
  /***********************************************************************************
   * Procedure Name   : init_status
   * Description      : ステータスを初期化します。
   ***********************************************************************************/
  PROCEDURE init_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_status'; -- プログラム名
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
    ir_status_rec.file_level_status := gn_data_status_nomal;
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
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
  END init_status;
--
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理を行います。
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    -- ===============================
    -- プロファイル取得
    -- ===============================
    get_profile(lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                lv_retcode,        -- リターン・コード             --# 固定 #
                lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- テーブルロック処理
    -- ===============================
    set_if_lock(lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                lv_retcode,        -- リターン・コード             --# 固定 #
                lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- コンポーネント区分の取得
    -- ===============================
    init_cmpntcls_id(lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                     lv_retcode,        -- リターン・コード             --# 固定 #
                     lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END init_proc;
--
  /***********************************************************************************
   * Procedure Name   : term_proc
   * Description      : 終了処理を行います。(B-16)
   ***********************************************************************************/
  PROCEDURE term_proc(
    it_report_tbl IN            report_tbl,   -- 出力用テーブル
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
    lb_retcd := TRUE;
--
    IF (gn_normal_cnt > 0) THEN
      -- ログ出力処理(成功:0)
      disp_report(it_report_tbl,
                  gn_data_status_nomal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_error_cnt > 0) THEN
      -- ログ出力処理(失敗:1)
      disp_report(it_report_tbl,
                  gn_data_status_error,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      -- ログ出力処理(警告:2)
      disp_report(it_report_tbl,
                  gn_data_status_warn,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_warok_cnt > 0) THEN
      -- ログ出力処理(警告:3)
      disp_report(it_report_tbl,
                  gn_data_status_warok,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- OPM品目マスタ(IC_ITEM_MST_B)
    IF (ic_item_mst_b_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE ic_item_mst_b_cur;
    END IF;
    -- OPM品目アドオンマスタ(XXCMN_ITEM_MST_B)
    IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE xxcmn_item_mst_b_cur;
    END IF;
    -- OPM品目カテゴリ割当(GMI_ITEM_CATEGORIES)
    IF (gmi_item_categories_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gmi_item_categories_cur;
    END IF;
    -- 品目原価マスタ(CM_CMPT_DTL)
    IF (cm_cmpt_dtl_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE cm_cmpt_dtl_cur;
    END IF;
--
    -- データ削除(品目インタフェース)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_item_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_017,
                                            gv_tkn_table, gv_xxcmn_item_if_name);
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
    lr_masters_rec   masters_rec; -- 処理対象データ格納レコード
    lr_status_rec    status_rec;  -- 処理状況格納レコード
--
    lt_report_tbl    report_tbl;  -- レポート出力結合配列
--
    ln_normal_cnt    NUMBER;
    ln_warn_cnt      NUMBER;
    ln_error_cnt     NUMBER;
--
    -- 品目用
    lt_item_ins_mast masters_tbl; -- 各マスタへ登録するデータ
    lt_item_upd_mast masters_tbl; -- 各マスタへ更新するデータ
    lt_item_del_mast masters_tbl; -- 各マスタへ削除するデータ
    ln_item_ins_cnt  NUMBER;      -- 登録件数
    ln_item_upd_cnt  NUMBER;      -- 更新件数
    ln_item_del_cnt  NUMBER;      -- 削除件数
--
    -- 品目原価用
    lt_cmpt_ins_mast masters_tbl; -- 各マスタへ登録するデータ
    lt_cmpt_upd_mast masters_tbl; -- 各マスタへ更新するデータ
    ln_cmpt_ins_cnt  NUMBER;      -- 登録件数
    ln_cmpt_upd_cnt  NUMBER;      -- 更新件数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR item_if_cur
    IS
      SELECT xif.seq_number,            -- SEQ番号
             xif.proc_code,             -- 更新区分
             xif.item_code,             -- 品名コード
             xif.item_name,             -- 品名・正式名
             xif.item_short_name,       -- 品名・略名
             xif.item_name_alt,         -- 品名・カナ
--2008/09/16 Mod ↓
/*
             xif.old_crowd_code,        -- 旧・群コード
             xif.new_crowd_code,        -- 新・群コード
*/
             DECODE(xif.old_crowd_code,
                    NULL,gv_def_crowd_code,
                    xif.old_crowd_code) AS old_crowd_code, -- 旧・群コード
             DECODE(xif.new_crowd_code,
                    NULL,gv_def_crowd_code,
                    xif.new_crowd_code) AS new_crowd_code, -- 新・群コード
--2008/09/16 Mod ↑
             xif.crowd_start_date,      -- 適用開始日
--2008/09/16 Mod ↓
/*
             xif.policy_group_code,     -- 政策群コード
             xif.marke_crowd_code,      -- マーケ用群コード
*/
             DECODE(xif.policy_group_code,
                    NULL,gv_def_policy_code,
                    xif.policy_group_code) AS policy_group_code, -- 政策群コード
             DECODE(xif.marke_crowd_code,
                    NULL,gv_def_market_code,
                    xif.marke_crowd_code) AS marke_crowd_code,   -- マーケ用群コード
--2008/09/16 Mod ↑
             xif.old_price,             -- 旧・定価
             xif.new_price,             -- 新・定価
             xif.price_start_date,      -- 適用開始日
             xif.old_standard_cost,     -- 旧・標準原価
             xif.new_standard_cost,     -- 新・標準原価
             xif.standard_start_date,   -- 適用開始日
             xif.old_business_cost,     -- 旧・営業原価
             xif.new_business_cost,     -- 新・営業原価
             xif.business_start_date,   -- 適用開始日
             xif.old_tax,               -- 旧・消費税率
             xif.new_tax,               -- 新・消費税率
             xif.tax_start_date,        -- 適用開始日
             xif.rate_code,             -- 率区分
             xif.case_num,              -- ケース入数
             xif.product_div_code,      -- 商品製品区分
             xif.net,                   -- NET
             xif.weight_volume,         -- 重量/体積
             xif.arti_div_code,         -- 商品区分
             xif.div_tea_code,          -- バラ茶区分
             xif.parent_item_code,      -- 親品名コード
             xif.sale_obj_code,         -- 売上対象区分
             xif.jan_code,              -- JANコード
             xif.sale_start_date,       -- 発売開始日(製造開始日)
-- 2008/08/07 v1.7 UPDATE START
--             xif.abolition_code,        -- 廃止区分
             DECODE(xif.abolition_code,
                    NULL, '0',
                    '1')  AS  abolition_code,
                                        -- 廃止区分
-- 2008/08/07 v1.7 UPDATE END
             xif.abolition_date,        -- 廃止日(製造中止日)
             xif.raw_mate_consumption,  -- 原料使用量
             xif.raw_material_cost,     -- 原料
             xif.agein_cost,            -- 再製費
             xif.material_cost,         -- 資材費
             xif.pack_cost,             -- 包装費
             xif.out_order_cost,        -- 外注加工費
             xif.safekeep_cost,         -- 保管費
             xif.other_expense_cost,    -- その他経費
             xif.spare1,                -- 予備1
             xif.spare2,                -- 予備2
             xif.spare3,                -- 予備3
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
             xif.haisu   palette_max_cs_qty,   -- 配数
             xif.dansu   palette_max_step_qty, -- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
             xif.spare                  -- 予備
      FROM   xxcmn_item_if xif
      ORDER BY seq_number;
--
    -- *** ローカル・レコード ***
    lr_item_if_rec item_if_cur%ROWTYPE;
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
    gn_warok_cnt  := 0;
    gn_report_cnt := 0;
--
    ln_normal_cnt   := 0;
    ln_error_cnt    := 0;
    ln_warn_cnt     := 0;
    ln_item_ins_cnt := 0;
    ln_item_upd_cnt := 0;
    ln_item_del_cnt := 0;
    ln_cmpt_ins_cnt := 0;
    ln_cmpt_upd_cnt := 0;
--
    gn_user_id     := FND_GLOBAL.USER_ID;
    gd_sysdate     := SYSDATE;
    gn_login_id    := FND_GLOBAL.LOGIN_ID;
    gn_request_id  := FND_GLOBAL.CONC_REQUEST_ID;
--    gn_appl_id     := FND_GLOBAL.QUEUE_APPL_ID;       -- 2008/08/27 Mod
    gn_appl_id     := FND_GLOBAL.PROG_APPL_ID;
    gn_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理
    -- プロファイルの取得、テーブルロック
    -- ===============================
    init_proc(lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ファイルレベルのステータスを初期化
    init_status(lr_status_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ユーザ名の取得
    get_user_name(lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- 品目インタフェース取得(B-1)
    -- ===============================
--
    OPEN item_if_cur;
--
    <<item_if_loop>>
    LOOP
      FETCH item_if_cur INTO lr_item_if_rec;
      EXIT WHEN item_if_cur%NOTFOUND;
      gn_target_cnt := gn_target_cnt + 1; -- 処理件数カウントアップ
--
      -- 行レベルのステータスを初期化
      init_row_status(lr_status_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- 取得した値をレコードにコピー
      lr_masters_rec.seq_number           := lr_item_if_rec.seq_number;
      lr_masters_rec.proc_code            := lr_item_if_rec.proc_code;
      lr_masters_rec.item_code            := lr_item_if_rec.item_code;
      lr_masters_rec.item_name            := lr_item_if_rec.item_name;
      lr_masters_rec.item_short_name      := lr_item_if_rec.item_short_name;
      lr_masters_rec.item_name_alt        := lr_item_if_rec.item_name_alt;
      lr_masters_rec.old_crowd_code       := lr_item_if_rec.old_crowd_code;
      lr_masters_rec.new_crowd_code       := lr_item_if_rec.new_crowd_code;
      lr_masters_rec.crowd_start_date     := lr_item_if_rec.crowd_start_date;
      lr_masters_rec.policy_group_code    := lr_item_if_rec.policy_group_code;
      lr_masters_rec.marke_crowd_code     := lr_item_if_rec.marke_crowd_code;
      lr_masters_rec.old_price            := lr_item_if_rec.old_price;
      lr_masters_rec.new_price            := lr_item_if_rec.new_price;
      lr_masters_rec.price_start_date     := lr_item_if_rec.price_start_date;
      lr_masters_rec.old_standard_cost    := lr_item_if_rec.old_standard_cost;
      lr_masters_rec.new_standard_cost    := lr_item_if_rec.new_standard_cost;
      lr_masters_rec.standard_start_date  := lr_item_if_rec.standard_start_date;
      lr_masters_rec.old_business_cost    := lr_item_if_rec.old_business_cost;
      lr_masters_rec.new_business_cost    := lr_item_if_rec.new_business_cost;
      lr_masters_rec.business_start_date  := lr_item_if_rec.business_start_date;
      lr_masters_rec.old_tax              := lr_item_if_rec.old_tax;
      lr_masters_rec.new_tax              := lr_item_if_rec.new_tax;
      lr_masters_rec.tax_start_date       := lr_item_if_rec.tax_start_date;
      lr_masters_rec.rate_code            := lr_item_if_rec.rate_code;
      lr_masters_rec.case_num             := lr_item_if_rec.case_num;
      lr_masters_rec.product_div_code     := lr_item_if_rec.product_div_code;
      lr_masters_rec.net                  := lr_item_if_rec.net;
      lr_masters_rec.weight_volume        := lr_item_if_rec.weight_volume;
      lr_masters_rec.arti_div_code        := lr_item_if_rec.arti_div_code;
      lr_masters_rec.div_tea_code         := lr_item_if_rec.div_tea_code;
      lr_masters_rec.parent_item_code     := lr_item_if_rec.parent_item_code;
      lr_masters_rec.sale_obj_code        := lr_item_if_rec.sale_obj_code;
      lr_masters_rec.jan_code             := lr_item_if_rec.jan_code;
      lr_masters_rec.sale_start_date      := lr_item_if_rec.sale_start_date;
      lr_masters_rec.abolition_code       := lr_item_if_rec.abolition_code;
      lr_masters_rec.abolition_date       := lr_item_if_rec.abolition_date;
      lr_masters_rec.raw_mate_consumption := lr_item_if_rec.raw_mate_consumption;
      lr_masters_rec.raw_material_cost    := lr_item_if_rec.raw_material_cost;
      lr_masters_rec.agein_cost           := lr_item_if_rec.agein_cost;
      lr_masters_rec.material_cost        := lr_item_if_rec.material_cost;
      lr_masters_rec.pack_cost            := lr_item_if_rec.pack_cost;
      lr_masters_rec.out_order_cost       := lr_item_if_rec.out_order_cost;
      lr_masters_rec.safekeep_cost        := lr_item_if_rec.safekeep_cost;
      lr_masters_rec.other_expense_cost   := lr_item_if_rec.other_expense_cost;
      lr_masters_rec.spare1               := lr_item_if_rec.spare1;
      lr_masters_rec.spare2               := lr_item_if_rec.spare2;
      lr_masters_rec.spare3               := lr_item_if_rec.spare3;
-- 2008/11/13 H.Itou Add Start 統合テスト指摘538
      lr_masters_rec.palette_max_cs_qty   := lr_item_if_rec.palette_max_cs_qty;   -- 配数
      lr_masters_rec.palette_max_step_qty := lr_item_if_rec.palette_max_step_qty; -- パレット当り最大段数
-- 2008/11/13 H.Itou Add End
      lr_masters_rec.spare                := lr_item_if_rec.spare;
--
      -- コンポーネント区分の設定
      lr_masters_rec.cmpntcls_mast        := gt_cmpntcls_mast;
--
      -- 原価内訳の数値化
      IF (lr_masters_rec.raw_material_cost IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(1).cost_price := TO_NUMBER(lr_masters_rec.raw_material_cost);
      END IF;
      IF (lr_masters_rec.agein_cost IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(2).cost_price := TO_NUMBER(lr_masters_rec.agein_cost);
      END IF;
      IF (lr_masters_rec.material_cost IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(3).cost_price := TO_NUMBER(lr_masters_rec.material_cost);
      END IF;
      IF (lr_masters_rec.pack_cost IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(4).cost_price := TO_NUMBER(lr_masters_rec.pack_cost);
      END IF;
      IF (lr_masters_rec.out_order_cost IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(5).cost_price := TO_NUMBER(lr_masters_rec.out_order_cost);
      END IF;
      IF (lr_masters_rec.safekeep_cost IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(6).cost_price := TO_NUMBER(lr_masters_rec.safekeep_cost);
      END IF;
      IF (lr_masters_rec.other_expense_cost IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(7).cost_price := TO_NUMBER(lr_masters_rec.other_expense_cost);
      END IF;
      IF (lr_masters_rec.spare1 IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(8).cost_price := TO_NUMBER(lr_masters_rec.spare1);
      END IF;
      IF (lr_masters_rec.spare2 IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(9).cost_price := TO_NUMBER(lr_masters_rec.spare2);
      END IF;
      IF (lr_masters_rec.spare3 IS NOT NULL) THEN
        lr_masters_rec.cmpntcls_mast(10).cost_price := TO_NUMBER(lr_masters_rec.spare3);
      END IF;
--
      -- 日付の文字列化
      lr_masters_rec.crowd_start_days := TO_CHAR(lr_item_if_rec.crowd_start_date,'YYYY/MM/DD');
      lr_masters_rec.price_start_days := TO_CHAR(lr_item_if_rec.price_start_date,'YYYY/MM/DD');
      lr_masters_rec.buis_start_days  := TO_CHAR(lr_item_if_rec.business_start_date,'YYYY/MM/DD');
      lr_masters_rec.sale_start_days  := TO_CHAR(lr_item_if_rec.sale_start_date,'YYYY/MM/DD');
--
      -- 更新区分チェック
      check_proc_code(lr_status_rec,
                      lr_masters_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
--2008/08/27 Add ↓
--
      -- 正常なら
      IF (is_row_status_nomal(lr_status_rec)) THEN
        -- 期間の取得
        get_period_code(lr_status_rec,
                        lr_masters_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    --
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--2008/08/27 Add ↑
--
      -- 正常なら
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- 以前のデータ状態の取得
        get_xxcmn_item_if(lr_masters_rec,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      -- ===============================
      -- 品目チェック
      -- ===============================
--
      -- 正常なら
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- 登録
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
          -- ===============================
          -- 品目登録分チェック(B-2)
          -- ===============================
          check_item_ins(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF (is_row_status_nomal(lr_status_rec)) THEN
            -- ===============================
            -- 品目登録分格納(B-5)
            -- ===============================
            lt_item_ins_mast(ln_item_ins_cnt) := lr_masters_rec;
            ln_item_ins_cnt := ln_item_ins_cnt + 1;
          END IF;
--
        -- 更新
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
          -- ===============================
          -- 品目更新分チェック(B-3)
          -- ===============================
          check_item_upd(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF (is_row_status_nomal(lr_status_rec)) THEN
            -- ===============================
            -- 品目更新分格納(B-6)
            -- ===============================
            lt_item_upd_mast(ln_item_upd_cnt) := lr_masters_rec;
            ln_item_upd_cnt := ln_item_upd_cnt + 1;
          END IF;
--
        -- 削除
        ELSIF (lr_masters_rec.proc_code = gn_proc_delete) THEN
          -- ===============================
          -- 品目削除分チェック(B-4)
          -- ===============================
          check_item_del(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF (is_row_status_nomal(lr_status_rec)) THEN
            -- ===============================
            -- 品目削除分格納(B-7)
            -- ===============================
            lt_item_del_mast(ln_item_del_cnt) := lr_masters_rec;
            ln_item_del_cnt := ln_item_del_cnt + 1;
          END IF;
        END IF;
      END IF;
--
      -- ===============================
      -- 品目原価チェック
      -- ===============================
--
      -- 正常なら
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- 登録
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
          -- ===============================
          -- 品目原価登録分チェック(B-8)
          -- ===============================
          check_cmpt_ins(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF ((is_row_status_nomal(lr_status_rec))
           OR (is_row_status_warok(lr_status_rec))) THEN
            -- ===============================
            -- 品目原価登録分格納(B-11)
            -- ===============================
            lt_cmpt_ins_mast(ln_cmpt_ins_cnt) := lr_masters_rec;
            ln_cmpt_ins_cnt := ln_cmpt_ins_cnt + 1;
          END IF;
--
        -- 更新
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
-- 2008/10/02 v1.13 ADD START
         -- 原価カレンダ存在チェックフラグがオンの場合
         IF (lr_masters_rec.cldr_n_flg) THEN
--
          -- 期間の取得ワーニング
          set_warok_status(lr_status_rec,
                           lr_masters_rec.cldr_n_msg,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
         ELSE
--
-- 2008/10/02 v1.13 ADD END
          -- ===============================
          -- 品目原価更新分チェック(B-9)
          -- ===============================
          check_cmpt_upd(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
-- 2008/10/02 v1.13 DELETE START
/*
          IF ((is_row_status_nomal(lr_status_rec))
           OR (is_row_status_warok(lr_status_rec))) THEN
            -- ===============================
            -- 品目原価更新分格納(B-12)
            -- ===============================
            lt_cmpt_upd_mast(ln_cmpt_upd_cnt) := lr_masters_rec;
            ln_cmpt_upd_cnt := ln_cmpt_upd_cnt + 1;
          END IF;
*/
-- 2008/10/02 v1.13 DELETE END
-- 2008/10/02 v1.13 ADD START
         END IF;
-- 2008/10/02 v1.13 ADD END
        END IF;
      END IF;
--
      -- 正常件数をカウントアップ
      IF (is_row_status_nomal(lr_status_rec)) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
--
      ELSE
        -- 警告件数をカウントアップ
        IF (is_row_status_warn(lr_status_rec)) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
--
        -- 警告件数をカウントアップ
        ELSIF (is_row_status_warok(lr_status_rec)) THEN
          gn_warok_cnt := gn_warok_cnt + 1;
--
        -- 異常件数をカウントアップ
        ELSE
          gn_error_cnt := gn_error_cnt +1;
        END IF;
      END IF;
--
      -- ログ出力用データの格納
      add_report(lr_status_rec,
                 lr_masters_rec,
                 lt_report_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP item_if_loop;
--
    CLOSE item_if_cur;
--
    -- 正常なら
    IF (is_file_status_nomal(lr_status_rec)) THEN
      -- ===============================
      -- 反映処理(B-14)
      -- ===============================
      proc_item(lt_item_ins_mast,
                lt_item_upd_mast,
                lt_item_del_mast,
                lt_report_tbl,
                ln_item_ins_cnt,
                ln_item_upd_cnt,
                ln_item_del_cnt,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- 終了処理(B-16)
    -- ===============================
    term_proc(lt_report_tbl,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    gn_normal_cnt := gn_normal_cnt + gn_warok_cnt;
--
    -- 2008/07/07 Add ↓
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_80b_022);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      gn_warn_cnt := gn_warn_cnt + 1;
      ov_retcode := gv_status_warn;
    END IF;
    -- 2008/07/07 Add ↑
--
        -- エラー、ワーニングデータ有りの場合はワーニング終了する。
    IF ((gn_error_cnt + gn_warn_cnt + gn_warok_cnt) > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- カーソルが開いていれば
      IF (item_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE item_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gmi_item_categories_cur;
      END IF;
      -- カーソルが開いていれば
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE cm_cmpt_dtl_cur;
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
      IF (item_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE item_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gmi_item_categories_cur;
      END IF;
      -- カーソルが開いていれば
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE cm_cmpt_dtl_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (item_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE item_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gmi_item_categories_cur;
      END IF;
      -- カーソルが開いていれば
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE cm_cmpt_dtl_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (item_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE item_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gmi_item_categories_cur;
      END IF;
      -- カーソルが開いていれば
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE cm_cmpt_dtl_cur;
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80b_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80b_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80b_019,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,gv_msg_80b_003);
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
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
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_018);
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_007,
                                           gv_tkn_cnt, TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_008,
                                           gv_tkn_cnt, TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_009,
                                           gv_tkn_cnt, TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_010,
                                           gv_tkn_cnt, TO_CHAR(gn_warn_cnt));
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80b_011,
                                           gv_tkn_status, gv_conc_status);
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
END xxcmn800002c;
/
