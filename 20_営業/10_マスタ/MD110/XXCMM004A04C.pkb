CREATE OR REPLACE PACKAGE BODY XXCMM004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A04C(spec)
 * Description      : Disc品目変更履歴アドオンマスタにて変更予約管理されている項目を
 *                  : 適用日が到来したタイミングで各品目情報に反映します。
 * MD.050           : 変更予約適用    MD050_CMM_004_A04
 * Version          : Issue3.9
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  proc_init                 初期処理 (A-1)
 *  loop_main                 変更適用品目情報の取得 (A-2)
 *                               ・proc_apply_update
 *  proc_apply_update         品目変更適用処理
 *                               ・proc_first_update
 *                               ・proc_status_update
 *                               ・proc_parent_item_update
 *                               ・proc_comp_apply_update
 *  proc_first_update         初回登録データ処理 (A-3)
 *  proc_status_update        品目ステータス変更
 *                               ・proc_item_status_update
 *                               ・proc_inherit_parent
 *  proc_item_status_update   品目ステータス反映処理 (A-5)
 *                               ・validate_item
 *  validate_item             データ妥当性チェック (A-4)
 *  proc_inherit_parent       親品目情報の継承 (A-6)
 *  proc_parent_item_update   親品目変更時の継承 (A-7)
 *  proc_comp_apply_update    品目変更適用済み情報の更新 (A-8,A-9)
 *  submain                   メイン処理プロシージャ
 *                               ・proc_init
 *                               ・loop_main
 *  main                      コンカレント実行ファイル登録プロシージャ
 *                               ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   H.Yoshikawa      main新規作成
 *  2009/01/20    1.1   H.Yoshikawa      単体テスト不具合による修正
 *  2009/01/27    1.2   H.Yoshikawa      標準原価登録まわりの修正
 *                                      （未来分すべて登録するよう修正）
 *  2009/01/29    1.3   H.Yoshikawa      親品目の仮登録変更時に「率区分」を必須項目に追加
 *  2009/01/30    1.4   H.Yoshikawa      原価組織変更による修正
 *  2009/02/19    1.5   H.Yoshikawa      品目ステータスチェックを追加
 *  2009/02/20                           検索対象更新日に業務日付を設定するよう修正
 *  2009/03/23    1.6   H.Yoshikawa      障害NoT1_0037対応      重量/容積・重量容積区分の設定を追加
 *                                       障害NoT1_0039対応      マスタ受信日時(OPM品目.ATTRIBUTE30)の設定を追加
 *  2009/04/03    1.7   K.Ito            障害対応(T1_0295)      品目OIF作成時にロット管理(LOT_CONTROL_CODE)に「1」(管理なし)を追加
 *  2009/05/27    1.7   H.Yoshikawa      障害対応(T1_0906)      親品目継承項目の追加【case_conv_inc_num(ケース換算入数)】
 *  2009/06/11    1.8   H.Yoshikawa      障害対応(T1_1366)      政策群変更時、群コードも変更するよう修正
 *  2009/07/07    1.9   H.Yoshikawa      障害対応(0000364)      標準原価_コンポーネント区分不足対応
 *                                       障害対応(0000365)      新規適用時の旧値(定価・営業原価・政策群)設定対応
 *  2009/07/15    1.10  H.Yoshikawa      障害対応(0000463)      保管棚管理の設定値に『管理なし』を設定
 *  2009/08/10    1.11  Y.Kuboshima      障害対応(0000862)      標準原価チェック処理を追加
 *                                       障害対応(0000894)      日付項目の修正(SYSDATE -> 業務日付)
 *  2009/09/11    1.12  Y.Kuboshima      障害対応(0000948)      単位換算を作成するタイミングを変更
 *                                                              (基準単位が本でケース入数が設定されている場合 -> 本登録時)
 *                                       障害対応(0001130)      在庫組織の修正(S01 -> Z99)
 *                                       障害対応(0001258)      品目カテゴリ割当(Disc)の対象カテゴリを追加
 *                                                              (品目区分,内外区分,商品区分,品質区分,工場群コード,経理部用群コード)
 *  2009/10/16    1.13  Y.Kuboshima      障害対応(0001423)      子品目を本登録にする時、親品目が本登録以外の場合はエラーとするよう修正
 *                                                              標準原価継承条件を変更
 *  2009/12/24    1.14  Shigeto.Niki     障害対応(本稼動_00577) 新規品目登録時は、保管棚管理に『1:管理なし』を設定
 *                                                              既存品目更新時は、保管棚管理に『組織レベル値』を設定
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  --正常:0
  cv_status_warn               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    --警告:1
  cv_status_error              CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   --異常:2
  --WHOカラム
  cn_created_by                CONSTANT NUMBER      := fnd_global.user_id;            --CREATED_BY
  cd_creation_date             CONSTANT DATE        := SYSDATE;                       --CREATION_DATE
  cn_last_updated_by           CONSTANT NUMBER      := fnd_global.user_id;            --LAST_UPDATED_BY
  cd_last_update_date          CONSTANT DATE        := SYSDATE;                       --LAST_UPDATE_DATE
  cn_last_update_login         CONSTANT NUMBER      := fnd_global.login_id;           --LAST_UPDATE_LOGIN
  cn_request_id                CONSTANT NUMBER      := fnd_global.conc_request_id;    --REQUEST_ID
  cn_program_application_id    CONSTANT NUMBER      := fnd_global.prog_appl_id;       --PROGRAM_APPLICATION_ID
  cn_program_id                CONSTANT NUMBER      := fnd_global.conc_program_id;    --PROGRAM_ID
  cd_program_update_date       CONSTANT DATE        := SYSDATE;                       --PROGRAM_UPDATE_DATE
  cv_msg_part                  CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                  CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                   VARCHAR2(2000);
  gv_sep_msg                   VARCHAR2(2000);
  gv_exec_user                 VARCHAR2(100);
  gv_conc_name                 VARCHAR2(30);
  gv_conc_status               VARCHAR2(30);
  gn_target_cnt                NUMBER;                    -- 対象件数
  gn_normal_cnt                NUMBER;                    -- 正常件数
  gn_error_cnt                 NUMBER;                    -- エラー件数
  gn_warn_cnt                  NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt          EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt              EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt       EXCEPTION;
  global_check_lock_expt       EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCMM004A04C';       -- パッケージ名
  cv_appl_name_xxcmm           CONSTANT VARCHAR2(10)  := 'XXCMM';              -- アドオン：共通・マスタ
  --
  cv_date_fmt_std              CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                               -- 日付書式：YYYY/MM/DD
  --
  cv_msg_space                 CONSTANT VARCHAR2(1)   := ' ';
  cv_boot_flag_online          CONSTANT VARCHAR2(1)   := '1';
  cv_boot_flag_batch           CONSTANT VARCHAR2(1)   := '2';
  cv_yes                       CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                        CONSTANT VARCHAR2(1)   := 'N';
  cv_inherit_kbn_hst           CONSTANT VARCHAR2(1)   := '0';                  -- 親値継承情報区分【'0'：履歴情報による更新】
  cv_inherit_kbn_inh           CONSTANT VARCHAR2(1)   := '1';                  -- 親値継承情報区分【'1'：親品目変更による更新】
-- Ver1.6  2009/04/03 Add Start Disc品目.ロット管理(LOT_CONTROL_CODE)
  cn_lot_control_code_no       CONSTANT NUMBER        := 1;                    -- 「1」(管理なし)
-- Ver1.6  2009/04/03 Add End
-- Ver1.10 2009/07/15 Add  保管棚管理(LOCATION_CONTROL_CODE)追加
  cn_location_control_code_no  CONSTANT NUMBER        := 1;                    -- 「1」(管理なし)
-- End1.10
  --
  -- 品目ステータス
  cn_itm_status_num_tmp        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;
                                                                               -- 仮採番
  cn_itm_status_pre_reg        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;
                                                                               -- 仮登録
  cn_itm_status_regist         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;
                                                                               -- 本登録
  cn_itm_status_no_sch         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;
                                                                               -- 廃
  cn_itm_status_trn_only       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;
                                                                               -- Ｄ’
  cn_itm_status_no_use         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                               -- Ｄ
  --
  -- 標準原価
  cv_whse_code                 CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                               -- 倉庫
  cv_cost_mthd_code            CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                               -- 原価方法
  cv_cost_analysis_code        CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                               -- 分析コード
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
  cv_pro_org_code              CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';   -- 在庫組織コード
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
  --
  -- メッセージ関連
  -- メッセージ
-- Ver1.7 2009/05/27 Add  現在ステータスが「Ｄ」の場合、品目ステータス以外の変更は不可
  cv_msg_xxcmm_00430           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00430';   -- 品目ステータスチェックエラー
-- End
-- Ver1.5 チェック処理追加
  cv_msg_xxcmm_00436           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00436';   -- 子品目ステータスチェックエラー
  cv_msg_xxcmm_00437           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00437';   -- 親品目ステータスチェックエラー
-- End
  cv_msg_xxcmm_00440           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00440';   -- プロファイル取得エラー
  cv_msg_xxcmm_00441           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00441';   -- データ取得エラー(データ特定トークンなし)
  cv_msg_xxcmm_00442           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00442';   -- データ取得エラー(変更予約情報)
  cv_msg_xxcmm_00443           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00443';   -- ロック取得エラー(変更予約情報)
  cv_msg_xxcmm_00444           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00444';   -- データ登録エラー(変更予約情報)
  cv_msg_xxcmm_00445           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00445';   -- データ更新エラー(変更予約情報)
  cv_msg_xxcmm_00446           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00446';   -- データ取得エラー(親品目変更による継承時)
  cv_msg_xxcmm_00447           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00447';   -- ロック取得エラー(親品目変更による継承時)
  cv_msg_xxcmm_00448           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00448';   -- データ登録エラー(親品目変更による継承時)
  cv_msg_xxcmm_00449           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00449';   -- データ更新エラー(親品目変更による継承時)
  cv_msg_xxcmm_00450           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00450';   -- データ妥当性エラー
  cv_msg_xxcmm_00451           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00451';   -- 処理件数ログ
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
  cv_msg_xxcmm_00432           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00432';   -- 標準原価0円エラー
  cv_msg_xxcmm_00433           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00433';   -- 営業原価エラー
-- End1.9
-- 2009/08/10 Ver1.11 障害0000862 add start by Y.Kuboshima
  cv_msg_xxcmm_00491           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00491';   -- 標準原価小数エラー
-- 2009/08/10 Ver1.11 障害0000862 add end by Y.Kuboshima
--
-- 2009/10/16 Ver1.13 障害0001423 add start by Y.Kuboshima
  cv_msg_xxcmm_00492           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00492';   -- 親品目本登録ステータスチェックエラー
-- 2009/10/16 Ver1.13 障害0001423 add start by Y.Kuboshima
--
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
  cv_msg_xxcmm_00002           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';   -- プロファイル取得エラー
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
  --
  -- トークン
  cv_tkn_param_name            CONSTANT VARCHAR2(100) := 'PARAM_NAME';
  cv_tkn_data_info             CONSTANT VARCHAR2(100) := 'DATA_INFO';
  cv_tkn_table                 CONSTANT VARCHAR2(20)  := 'TABLE';              -- テーブル名
  cv_tkn_item_code             CONSTANT VARCHAR2(20)  := 'ITEM_CODE';          -- 品目コード
  cv_tkn_item_status           CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';        -- 品目ステータス
  cv_tkn_parent_item           CONSTANT VARCHAR2(20)  := 'PARENT_ITEM';        -- 親品目コード
  cv_tkn_err_msg               CONSTANT VARCHAR2(20)  := 'ERR_MSG';            -- エラーメッセージ
  cv_tkn_data_name             CONSTANT VARCHAR2(20)  := 'DATA_NAME';          -- 件数名
  cv_tkn_data_cnt              CONSTANT VARCHAR2(20)  := 'DATA_CNT';           -- データ件数
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
  cv_tkn_disc_cost             CONSTANT VARCHAR2(20)  := 'DISC_COST';          -- 営業原価
  cv_tkn_opm_cost              CONSTANT VARCHAR2(20)  := 'OPM_COST';           -- 標準原価
-- End1.9
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
  cv_tkn_ng_profile            CONSTANT VARCHAR2(20)  := 'NG_PROFILE';         -- プロファイル名
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
  --
  cv_tkn_val_categ_policy_cd   CONSTANT VARCHAR2(30)  := '政策群カテゴリ情報';
-- Ver1.8  2009/06/11  Add  政策群コードが変更された場合、群コードにも反映
  cv_tkn_val_categ_gun_cd      CONSTANT VARCHAR2(30)  := '群コードカテゴリ情報';
-- End1.8
  cv_tkn_val_categ_prd_class   CONSTANT VARCHAR2(30)  := '本社商品区分カテゴリ情報';
  cv_tkn_val_item_status       CONSTANT VARCHAR2(30)  := '品目ステータス情報';
  cv_tkn_val_item              CONSTANT VARCHAR2(30)  := '品目';
  cv_tkn_val_uon_conv          CONSTANT VARCHAR2(30)  := '区分間換算';
  cv_tkn_val_target_cnt        CONSTANT VARCHAR2(30)  := '処理件数  ： ';
  cv_tkn_val_item_status_cnt   CONSTANT VARCHAR2(30)  := '品目ステータス変更件数  ： ';
  cv_tkn_val_policy_group_cnt  CONSTANT VARCHAR2(30)  := '政策群変更件数  ： ';
  cv_tkn_val_fixed_price_cnt   CONSTANT VARCHAR2(30)  := '定価変更件数  ： ';
  cv_tkn_val_disc_cost_cnt     CONSTANT VARCHAR2(30)  := '営業原価変更件数  ： ';
  cv_tkn_val_error_cnt         CONSTANT VARCHAR2(30)  := 'エラー件数  ： ';
  --
  cv_tkn_val_xxcmm_discitem    CONSTANT VARCHAR2(30)  := 'Ｄｉｓｃ品目アドオン';
  cv_tkn_val_xxcmm_itemhst     CONSTANT VARCHAR2(30)  := 'Ｄｉｓｃ品目変更履歴';
  cv_tkn_val_discitem_if       CONSTANT VARCHAR2(30)  := 'Ｄｉｓｃ品目インタフェース';
  cv_tkn_val_disccost_if       CONSTANT VARCHAR2(30)  := 'Ｄｉｓｃ原価インタフェース';
  cv_tkn_val_mtl_item_categ    CONSTANT VARCHAR2(30)  := 'Ｄｉｓｃ品目カテゴリ割当';
  cv_tkn_val_xxcmn_opmitem     CONSTANT VARCHAR2(30)  := 'ＯＰＭ品目アドオン';
  cv_tkn_val_opmitem           CONSTANT VARCHAR2(30)  := 'ＯＰＭ品目';
  cv_tkn_val_opmcost           CONSTANT VARCHAR2(30)  := 'ＯＰＭ標準原価';
  cv_tkn_val_opm_item_categ    CONSTANT VARCHAR2(30)  := 'ＯＰＭ品目カテゴリ割当';
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
  cv_tkn_val_org_code          CONSTANT VARCHAR2(20)  := '在庫組織コード';     -- 在庫組織コード
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
  --
  -- 品目カテゴリセット名
  cv_categ_set_seisakugun      CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;
                                                                               -- 政策群コード
  cv_categ_set_hon_prod        CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;
                                                                               -- 本社商品区分
  cv_categ_set_item_prod       CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_prod;
                                                                               -- 商品製品区分
-- Ver1.8  2009/06/11  Add  政策群コードが変更された場合、群コードにも反映
  cv_categ_set_baracha_div     CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_baracha_div;
                                                                               -- バラ茶区分
  cv_categ_set_mark_pg         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_mark_pg;
                                                                               -- マーケ用群コード
  cv_categ_set_gun_code        CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_gun_code;
                                                                               -- 群コード
-- End1.8
-- 2009/09/11 Ver1.12 障害0001258 add start by Y.Kuboshima
  cv_categ_set_item_div        CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_div;
                                                                               -- 品目区分
  cv_categ_set_inout_div       CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_inout_div;
                                                                               -- 内外区分
  cv_categ_set_product_div     CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_product_div;
                                                                               -- 商品区分
  cv_categ_set_quality_div     CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_quality_div;
                                                                               -- 品質区分
  cv_categ_set_fact_pg         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_fact_pg;
                                                                               -- 工場群コード
  cv_categ_set_acnt_pg         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_acnt_pg;
                                                                               -- 経理部用群コード
-- 2009/09/11 Ver1.12 障害0001258 add end by Y.Kuboshima
  --
  -- ルックアップ
  cv_lookup_item_status        CONSTANT VARCHAR2(20)  := 'XXCMM_ITM_STATUS';   -- 品目ステータス
  cv_lookup_cost_cmpt          CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';   -- 標準原価コンポーネント
-- 2009/09/11 Ver1.12 障害0000948 add start by Y.Kuboshima
  cv_lookup_item_um            CONSTANT VARCHAR2(30)  := 'XXCMM_UNITS_OF_MEASURE';   -- 基準単位
-- 2009/09/11 Ver1.12 障害0000948 add end by Y.Kuboshima
  --
-- 2009/08/10 Ver1.11 障害0000862 add start by Y.Kuboshima
  -- 資材品目
  cv_leaf_material             CONSTANT VARCHAR2(1)   := '5';                  -- 資材品目(リーフ)
  cv_drink_material            CONSTANT VARCHAR2(1)   := '6';                  -- 資材品目(ドリンク)
-- 2009/08/10 Ver1.11 障害0000862 add end by Y.Kuboshima
-- 2009/08/10 Ver1.11 障害0000894 move start by Y.Kuboshima
-- この位置ではgd_process_dateはまだ定義されていないため、カーソルを下へ移動します。
--
--  -- 変更適用品目抽出カーソル
--  CURSOR update_item_cur(
--    pd_apply_date        DATE )
--  IS
--    SELECT      xsibh.item_hst_id                                       -- 品目変更履歴ID
--               ,1                     AS  item_div                      -- 親子区分（1:親品目）
--               ,xoiv.inventory_item_id                                  -- Disc品目ID
--               ,xoiv.item_id                                            -- OPM品目ID
--               ,xoiv.parent_item_id                                     -- 親商品ID
--               ,xoiv.item_no                                            -- 品目コード
--               ,xoiv.item_status      AS  b_item_status                 -- 変更前品目ステータス
--               ,xoiv.item_um                                            -- 基準単位        （OPM品目）
--               ,xoiv.num_of_cases                                       -- ケース入数      （OPM品目）
--               ,xoiv.sales_div                                          -- 売上対象区分    （OPM品目）
--               ,xoiv.net                                                -- NET             （OPM品目）
--               ,xoiv.unit                                               -- 重量            （OPM品目）
--               ,xoiv.crowd_code_new                                     -- 新・政策群コード（OPM品目）
--               ,xoiv.price_new                                          -- 新・定価        （OPM品目）
--               ,xoiv.opt_cost_new                                       -- 新・営業原価    （OPM品目）
--               ,xoiv.item_name_alt                                      -- カナ名          （OPM品目アドオン）
--               ,xoiv.rate_class                                         -- 率区分          （OPM品目アドオン）
--               ,xoiv.palette_max_cs_qty                                 -- 配数            （OPM品目アドオン）
--               ,xoiv.palette_max_step_qty                               -- 段数            （OPM品目アドオン）
--               ,xoiv.nets                                               -- 内容量          （Disc品目アドオン）
--               ,xoiv.nets_uom_code                                      -- 内容量単位      （Disc品目アドオン）
--               ,xoiv.inc_num                                            -- 内訳入数        （Disc品目アドオン）
--               ,xoiv.baracha_div                                        -- バラ茶区分      （Disc品目アドオン）
--               ,xoiv.sp_supplier_code                                   -- 専門店仕入先    （Disc品目アドオン）
--               ,xsibh.apply_date                                        -- 適用日（適用開始日）
--               ,xsibh.apply_flag                                        -- 適用有無
--               ,xsibh.item_status                                       -- 品目ステータス
--               ,xsibh.policy_group                                      -- 群コード（政策群コード）
--               ,xsibh.fixed_price                                       -- 定価
--               ,xsibh.discrete_cost                                     -- 営業原価
--               ,xsibh.first_apply_flag                                  -- 初回適用フラグ
--               ,xoiv.purchasing_item_flag                               -- 購買品目
--               ,xoiv.shippable_item_flag                                -- 出荷可能
--               ,xoiv.customer_order_flag                                -- 顧客受注
--               ,xoiv.purchasing_enabled_flag                            -- 購買可能
--               ,xoiv.internal_order_enabled_flag                        -- 社内発注
--               ,xoiv.so_transactions_flag                               -- OE 取引可能
--               ,xoiv.reservable_type                                    -- 予約可能
--    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc品目変更履歴アドオン
--               ,xxcmm_opmmtl_items_v      xoiv                          -- 品目ビュー
--    WHERE       xsibh.apply_date       <= pd_apply_date                 -- 適用日(起動日付で対象とならない日があるかも)
--    AND         xsibh.apply_flag        = cv_no                         -- 未適用
--    AND         xoiv.item_no            = xsibh.item_code               -- 品目コード
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- 適用開始日
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- 適用終了日
--    AND         xoiv.start_date_active <= gd_process_date               -- 適用開始日
--    AND         xoiv.end_date_active   >= gd_process_date               -- 適用終了日
--    AND         xoiv.item_id            = xoiv.parent_item_id           -- 親品目
--    --
--    UNION ALL
--    --
--    SELECT      xsibh.item_hst_id                                       -- 品目変更履歴ID
--               ,2                     AS  item_div                      -- 親子区分（2:子品目）
--               ,xoiv.inventory_item_id                                  -- Disc品目ID
--               ,xoiv.item_id                                            -- OPM品目ID
--               ,xoiv.parent_item_id                                     -- 親商品ID
--               ,xoiv.item_no                                            -- 品目コード
--               ,xoiv.item_status      AS  b_item_status                 -- 変更前品目ステータス
--               ,xoiv.item_um                                            -- 基準単位        （OPM品目）
--               ,xoiv.num_of_cases                                       -- ケース入数      （OPM品目）
--               ,xoiv.sales_div                                          -- 売上対象区分    （OPM品目）
--               ,xoiv.net                                                -- NET             （OPM品目）
--               ,xoiv.unit                                               -- 重量            （OPM品目）
--               ,xoiv.crowd_code_new                                     -- 新・政策群コード（OPM品目）
--               ,xoiv.price_new                                          -- 新・定価        （OPM品目）
--               ,xoiv.opt_cost_new                                       -- 新・営業原価    （OPM品目）
--               ,xoiv.item_name_alt                                      -- カナ名          （OPM品目アドオン）
--               ,xoiv.rate_class                                         -- 率区分          （OPM品目アドオン）
--               ,xoiv.palette_max_cs_qty                                 -- 配数            （OPM品目アドオン）
--               ,xoiv.palette_max_step_qty                               -- 段数            （OPM品目アドオン）
--               ,xoiv.nets                                               -- 内容量          （Disc品目アドオン）
--               ,xoiv.nets_uom_code                                      -- 内容量単位      （Disc品目アドオン）
--               ,xoiv.inc_num                                            -- 内訳入数        （Disc品目アドオン）
--               ,xoiv.baracha_div                                        -- バラ茶区分      （Disc品目アドオン）
--               ,xoiv.sp_supplier_code                                   -- 専門店仕入先    （Disc品目アドオン）
--               ,xsibh.apply_date                                        -- 適用日（適用開始日）
--               ,xsibh.apply_flag                                        -- 適用有無
--               ,xsibh.item_status                                       -- 品目ステータス
--               ,xsibh.policy_group                                      -- 群コード（政策群コード）
--               ,xsibh.fixed_price                                       -- 定価
--               ,xsibh.discrete_cost                                     -- 営業原価
--               ,xsibh.first_apply_flag                                  -- 初回適用フラグ
--               ,xoiv.purchasing_item_flag                               -- 購買品目
--               ,xoiv.shippable_item_flag                                -- 出荷可能
--               ,xoiv.customer_order_flag                                -- 顧客受注
--               ,xoiv.purchasing_enabled_flag                            -- 購買可能
--               ,xoiv.internal_order_enabled_flag                        -- 社内発注
--               ,xoiv.so_transactions_flag                               -- OE 取引可能
--               ,xoiv.reservable_type                                    -- 予約可能
--    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc品目変更履歴アドオン
--               ,xxcmm_opmmtl_items_v      xoiv                          -- 品目ビュー
--    WHERE       xsibh.apply_date       <= pd_apply_date                 -- 適用日(起動日付で対象とならない日があるかも)
--    AND         xsibh.apply_flag        = cv_no                         -- 未適用
--    AND         xoiv.item_no            = xsibh.item_code               -- 品目コード
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- 適用開始日
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- 適用終了日
---- Ver1.1 2009/01/14 MOD テストシナリオ 4-3
----    AND         xoiv.item_id           != xoiv.parent_item_id           -- 親品目
--    AND      (  xoiv.item_id           != xoiv.parent_item_id           -- 親品目でない
--             OR xoiv.parent_item_id    IS NULL )                        -- 親品目が未設定
---- Ver1.1 MOD END
--    ORDER BY    item_div
--               ,apply_date
--               ,first_apply_flag
--               ,item_no;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_boot_flag                 VARCHAR2(1);                                    -- 起動種別
  gn_bus_org_id                mtl_parameters.organization_id%TYPE;            -- 営業組織ID[Z99]
  gn_cost_org_id               mtl_parameters.cost_organization_id%TYPE;       -- 原価組織ID[ZZZ]
  gn_master_org_id             mtl_parameters.master_organization_id%TYPE;     -- マスター在庫組織ID[ZZZ]
  --
-- Ver1.5 2009/02/20 Add 検索対象更新日に業務日付を設定するよう修正
  gd_process_date              DATE;                                           -- 業務日付
--
  gd_apply_date                DATE;                                           -- 適用日
  gv_inherit_kbn               VARCHAR2(1);                                    -- 親値継承情報区分【'0'：履歴情報による更新、'1'：親品目変更による更新】
  --
  gn_item_status_cnt           NUMBER;                                         -- ステータス更新件数
  gn_policy_group_cnt          NUMBER;                                         -- 政策群更新件数  （変更履歴ベース）
  gn_fixed_price_cnt           NUMBER;                                         -- 定価更新件数    （変更履歴ベース）
  gn_discrete_cost_cnt         NUMBER;                                         -- 営業原価更新件数（変更履歴ベース）
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
  gv_bus_org_code              VARCHAR2(3);                                    -- 在庫組織コード
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  -- 品目ステータス反映
  TYPE item_status_rtype IS RECORD
  (
    item_id                        ic_item_mst_b.item_id%TYPE                             -- 品目ID
   ,apply_date                     xxcmm_system_items_b_hst.apply_date%TYPE               -- 適用日
   ,item_status                    xxcmm_system_items_b_hst.item_status%TYPE              -- 品目ステータス
   ,inventory_item_id              mtl_system_items_b.inventory_item_id%TYPE              -- Disc品目ID
   ,organization_id                mtl_system_items_b.organization_id%TYPE                -- 組織ID
   ,purchasing_item_flag           mtl_system_items_b.purchasing_item_flag%TYPE           -- 購買品目
   ,shippable_item_flag            mtl_system_items_b.shippable_item_flag%TYPE            -- 出荷可能
   ,customer_order_flag            mtl_system_items_b.customer_order_flag%TYPE            -- 顧客受注
   ,purchasing_enabled_flag        mtl_system_items_b.purchasing_enabled_flag%TYPE        -- 購買可能
   ,internal_order_enabled_flag    mtl_system_items_b.internal_order_enabled_flag%TYPE    -- 社内発注
   ,so_transactions_flag           mtl_system_items_b.so_transactions_flag%TYPE           -- OE 取引可能
   ,reservable_type                mtl_system_items_b.reservable_type%TYPE                -- 予約可能
  );
  --
-- 2009/08/10 Ver1.11 move start by Y.Kuboshima
  -- 変更適用品目抽出カーソル
  CURSOR update_item_cur(
    pd_apply_date        DATE )
  IS
    SELECT      xsibh.item_hst_id                                       -- 品目変更履歴ID
               ,1                     AS  item_div                      -- 親子区分（1:親品目）
               ,xoiv.inventory_item_id                                  -- Disc品目ID
               ,xoiv.item_id                                            -- OPM品目ID
               ,xoiv.parent_item_id                                     -- 親商品ID
               ,xoiv.item_no                                            -- 品目コード
               ,xoiv.item_status      AS  b_item_status                 -- 変更前品目ステータス
               ,xoiv.item_um                                            -- 基準単位        （OPM品目）
               ,xoiv.num_of_cases                                       -- ケース入数      （OPM品目）
               ,xoiv.sales_div                                          -- 売上対象区分    （OPM品目）
               ,xoiv.net                                                -- NET             （OPM品目）
               ,xoiv.unit                                               -- 重量            （OPM品目）
               ,xoiv.crowd_code_new                                     -- 新・政策群コード（OPM品目）
               ,xoiv.price_new                                          -- 新・定価        （OPM品目）
               ,xoiv.opt_cost_new                                       -- 新・営業原価    （OPM品目）
               ,xoiv.item_name_alt                                      -- カナ名          （OPM品目アドオン）
               ,xoiv.rate_class                                         -- 率区分          （OPM品目アドオン）
               ,xoiv.palette_max_cs_qty                                 -- 配数            （OPM品目アドオン）
               ,xoiv.palette_max_step_qty                               -- 段数            （OPM品目アドオン）
               ,xoiv.nets                                               -- 内容量          （Disc品目アドオン）
               ,xoiv.nets_uom_code                                      -- 内容量単位      （Disc品目アドオン）
               ,xoiv.inc_num                                            -- 内訳入数        （Disc品目アドオン）
               ,xoiv.baracha_div                                        -- バラ茶区分      （Disc品目アドオン）
               ,xoiv.sp_supplier_code                                   -- 専門店仕入先    （Disc品目アドオン）
               ,xsibh.apply_date                                        -- 適用日（適用開始日）
               ,xsibh.apply_flag                                        -- 適用有無
               ,xsibh.item_status                                       -- 品目ステータス
               ,xsibh.policy_group                                      -- 群コード（政策群コード）
               ,xsibh.fixed_price                                       -- 定価
               ,xsibh.discrete_cost                                     -- 営業原価
               ,xsibh.first_apply_flag                                  -- 初回適用フラグ
               ,xoiv.purchasing_item_flag                               -- 購買品目
               ,xoiv.shippable_item_flag                                -- 出荷可能
               ,xoiv.customer_order_flag                                -- 顧客受注
               ,xoiv.purchasing_enabled_flag                            -- 購買可能
               ,xoiv.internal_order_enabled_flag                        -- 社内発注
               ,xoiv.so_transactions_flag                               -- OE 取引可能
               ,xoiv.reservable_type                                    -- 予約可能
    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc品目変更履歴アドオン
               ,xxcmm_opmmtl_items_v      xoiv                          -- 品目ビュー
    WHERE       xsibh.apply_date       <= pd_apply_date                 -- 適用日(起動日付で対象とならない日があるかも)
    AND         xsibh.apply_flag        = cv_no                         -- 未適用
    AND         xoiv.item_no            = xsibh.item_code               -- 品目コード
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- 適用開始日
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- 適用終了日
    AND         xoiv.start_date_active <= gd_process_date               -- 適用開始日
    AND         xoiv.end_date_active   >= gd_process_date               -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
    AND         xoiv.item_id            = xoiv.parent_item_id           -- 親品目
    --
    UNION ALL
    --
    SELECT      xsibh.item_hst_id                                       -- 品目変更履歴ID
               ,2                     AS  item_div                      -- 親子区分（2:子品目）
               ,xoiv.inventory_item_id                                  -- Disc品目ID
               ,xoiv.item_id                                            -- OPM品目ID
               ,xoiv.parent_item_id                                     -- 親商品ID
               ,xoiv.item_no                                            -- 品目コード
               ,xoiv.item_status      AS  b_item_status                 -- 変更前品目ステータス
               ,xoiv.item_um                                            -- 基準単位        （OPM品目）
               ,xoiv.num_of_cases                                       -- ケース入数      （OPM品目）
               ,xoiv.sales_div                                          -- 売上対象区分    （OPM品目）
               ,xoiv.net                                                -- NET             （OPM品目）
               ,xoiv.unit                                               -- 重量            （OPM品目）
               ,xoiv.crowd_code_new                                     -- 新・政策群コード（OPM品目）
               ,xoiv.price_new                                          -- 新・定価        （OPM品目）
               ,xoiv.opt_cost_new                                       -- 新・営業原価    （OPM品目）
               ,xoiv.item_name_alt                                      -- カナ名          （OPM品目アドオン）
               ,xoiv.rate_class                                         -- 率区分          （OPM品目アドオン）
               ,xoiv.palette_max_cs_qty                                 -- 配数            （OPM品目アドオン）
               ,xoiv.palette_max_step_qty                               -- 段数            （OPM品目アドオン）
               ,xoiv.nets                                               -- 内容量          （Disc品目アドオン）
               ,xoiv.nets_uom_code                                      -- 内容量単位      （Disc品目アドオン）
               ,xoiv.inc_num                                            -- 内訳入数        （Disc品目アドオン）
               ,xoiv.baracha_div                                        -- バラ茶区分      （Disc品目アドオン）
               ,xoiv.sp_supplier_code                                   -- 専門店仕入先    （Disc品目アドオン）
               ,xsibh.apply_date                                        -- 適用日（適用開始日）
               ,xsibh.apply_flag                                        -- 適用有無
               ,xsibh.item_status                                       -- 品目ステータス
               ,xsibh.policy_group                                      -- 群コード（政策群コード）
               ,xsibh.fixed_price                                       -- 定価
               ,xsibh.discrete_cost                                     -- 営業原価
               ,xsibh.first_apply_flag                                  -- 初回適用フラグ
               ,xoiv.purchasing_item_flag                               -- 購買品目
               ,xoiv.shippable_item_flag                                -- 出荷可能
               ,xoiv.customer_order_flag                                -- 顧客受注
               ,xoiv.purchasing_enabled_flag                            -- 購買可能
               ,xoiv.internal_order_enabled_flag                        -- 社内発注
               ,xoiv.so_transactions_flag                               -- OE 取引可能
               ,xoiv.reservable_type                                    -- 予約可能
    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc品目変更履歴アドオン
               ,xxcmm_opmmtl_items_v      xoiv                          -- 品目ビュー
    WHERE       xsibh.apply_date       <= pd_apply_date                 -- 適用日(起動日付で対象とならない日があるかも)
    AND         xsibh.apply_flag        = cv_no                         -- 未適用
    AND         xoiv.item_no            = xsibh.item_code               -- 品目コード
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- 適用開始日
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- 適用終了日
    AND         xoiv.start_date_active <= gd_process_date               -- 適用開始日
    AND         xoiv.end_date_active   >= gd_process_date               -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
-- Ver1.1 2009/01/14 MOD テストシナリオ 4-3
--    AND         xoiv.item_id           != xoiv.parent_item_id           -- 親品目
    AND      (  xoiv.item_id           != xoiv.parent_item_id           -- 親品目でない
             OR xoiv.parent_item_id    IS NULL )                        -- 親品目が未設定
-- Ver1.1 MOD END
    ORDER BY    item_div
               ,apply_date
               ,first_apply_flag
               ,item_no;
--
  /**********************************************************************************
   * Procedure Name   : proc_comp_apply_update
   * Description      : 品目変更適用済み情報の更新
   **********************************************************************************/
  PROCEDURE proc_comp_apply_update(
    i_update_item_rec   IN     update_item_cur%ROWTYPE
   ,ov_errbuf           OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_COMP_APPLY_UPDATE'; -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_step                    VARCHAR2(10);
    --
    -- *** ローカル変数 ***
    lv_msg_token               VARCHAR2(100);
    lv_msg_errm                VARCHAR2(4000);
    --
    lv_policy_group            VARCHAR2(4);     -- 政策群コード
    ln_fixed_price             NUMBER;          -- 定価
    ln_discrete_cost           NUMBER;          -- 営業原価
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- Disc品目アドオンロックカーソル
    CURSOR xxcmm_item_lock_cur(
      pv_item_code    VARCHAR2 )
    IS
      SELECT    'x'
      FROM      xxcmm_system_items_b
      WHERE     item_code = pv_item_code
      FOR UPDATE NOWAIT;
    --
    -- Disc品目変更履歴ロックカーソル
    CURSOR xxcmm_item_hst_lock_cur(
      pn_item_hst_id    NUMBER )
    IS
      SELECT    'x'
      FROM      xxcmm_system_items_b_hst
      WHERE     item_hst_id = pn_item_hst_id
      FOR UPDATE NOWAIT;
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    data_update_err_expt            EXCEPTION;    -- データ更新エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-8 Disc品目アドオンの更新
    --==============================================================
    --==============================================================
    --A-8.1 Disc品目アドオンのロック取得
    --==============================================================
    lv_step := 'STEP-11010';
    lv_msg_token := cv_tkn_val_xxcmm_discitem;
    --
    OPEN   xxcmm_item_lock_cur( i_update_item_rec.item_no );
    CLOSE  xxcmm_item_lock_cur;
    --
    --==============================================================
    --A-8.2 Disc品目アドオンの更新
    --==============================================================
    BEGIN
      IF ( i_update_item_rec.parent_item_id IS NULL 
        OR i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
        --
        -- 親品目未設定時、または、品目ステータスがＤの場合は親品目情報から更新しない。
        lv_step := 'STEP-11020';
        UPDATE      xxcmm_system_items_b    -- Disc品目アドオン
-- Ver1.5 2009/02/20 Mod 検索対象更新日に業務日付を設定するよう修正
--        SET         search_update_date     = i_update_item_rec.apply_date
                    -- 検索対象更新日
        SET         search_update_date     = gd_process_date
-- End
                    -- 品目ステータス
                   ,item_status            = NVL( i_update_item_rec.item_status, item_status )
                    -- 品目ステータス適用日
                   ,item_status_apply_date = NVL2( i_update_item_rec.item_status, i_update_item_rec.apply_date
                                                                                , item_status_apply_date )
                    --
                   ,last_updated_by        = cn_last_updated_by
                   ,last_update_date       = cd_last_update_date
                   ,last_update_login      = cn_last_update_login
                   ,request_id             = cn_request_id
                   ,program_application_id = cn_program_application_id
                   ,program_id             = cn_program_id
                   ,program_update_date    = cd_program_update_date
                    --
        WHERE       item_code              = i_update_item_rec.item_no;
        --
      ELSE
        -- 親品目設定時、かつ、品目ステータスがＤ以外の場合、
        -- 親品目情報から内容量、内訳入数、バラ茶区分、ケースJAN、ボール入数、容器群、経理群、
        --               経理容器群、ブランド群、専門店仕入先 を設定する
        --（親品目の場合同じレコードの値が設定されるため実質更新されない。）
        lv_step := 'STEP-11030';
        UPDATE      xxcmm_system_items_b    xsib    -- Disc品目アドオン
        SET       ( search_update_date              -- 検索対象更新日
                   ,item_status                     -- 品目ステータス
                   ,item_status_apply_date          -- 品目ステータス適用日
                    --
                   ,nets                            -- 内容量
                   ,inc_num                         -- 内訳入数
                   ,baracha_div                     -- バラ茶区分
                   ,case_jan_code                   -- ケースJAN
                   ,bowl_inc_num                    -- ボール入数
                   ,vessel_group                    -- 容器群
                   ,acnt_group                      -- 経理群
                   ,acnt_vessel_group               -- 経理容器群
                   ,brand_group                     -- ブランド群
                   ,sp_supplier_code                -- 専門店仕入先
-- Ver1.7 2009/05/27 Add  ケース換算入数を継承項目に追加（T1_0906）
                   ,case_conv_inc_num               -- ケース換算入数
-- End
                    --
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                   ,request_id
                   ,program_application_id
                   ,program_id
                   ,program_update_date )
               =  ( SELECT
-- Ver1.5 2009/02/20 Mod 検索対象更新日に業務日付を設定するよう修正
--                                i_update_item_rec.apply_date
                                -- 検索対象更新日
                                gd_process_date
-- End
                                -- 品目ステータス
                               ,NVL( i_update_item_rec.item_status, xsib.item_status )
                                -- 品目ステータス適用日
                               ,NVL2( i_update_item_rec.item_status, i_update_item_rec.apply_date
                                    , xsib.item_status_apply_date )
                               ,parent_xsib.nets                      -- 内容量
                               ,parent_xsib.inc_num                   -- 内訳入数
                               ,parent_xsib.baracha_div               -- バラ茶区分
                               ,parent_xsib.case_jan_code             -- ケースJAN
                               ,parent_xsib.bowl_inc_num              -- ボール入数
                               ,parent_xsib.vessel_group              -- 容器群
                               ,parent_xsib.acnt_group                -- 経理群
                               ,parent_xsib.acnt_vessel_group         -- 経理容器群
                               ,parent_xsib.brand_group               -- ブランド群
                               ,parent_xsib.sp_supplier_code          -- 専門店仕入先
-- Ver1.7 2009/05/27 Add  ケース換算入数を継承項目に追加（T1_0906）
                               ,parent_xsib.case_conv_inc_num         -- ケース換算入数
-- End
                               ,cn_last_updated_by
                               ,cd_last_update_date
                               ,cn_last_update_login
                               ,cn_request_id
                               ,cn_program_application_id
                               ,cn_program_id
                               ,cd_program_update_date
                    FROM        xxcmm_opmmtl_items_v    xoiv          -- 品目ビュー
                               ,ic_item_mst_b           iimb          -- OPM品目
                               ,xxcmm_system_items_b    parent_xsib   -- Disc品目アドオン
                    WHERE       xoiv.item_no            = i_update_item_rec.item_no
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--                    AND         xoiv.start_date_active <= TRUNC( SYSDATE )
--                    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )
                    AND         xoiv.start_date_active <= gd_process_date
                    AND         xoiv.end_date_active   >= gd_process_date
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
                    AND         iimb.item_id            = xoiv.parent_item_id
                    AND         parent_xsib.item_code   = iimb.item_no )
        WHERE       item_code = i_update_item_rec.item_no;
        --
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg_errm  := SQLERRM;
        lv_msg_token := cv_tkn_val_xxcmm_discitem;
        RAISE data_update_err_expt;  -- 更新エラー
    END;
    --
    --==============================================================
    --A-9 Disc品目変更履歴アドオンの更新
    --==============================================================
    --==============================================================
    --A-9.1 Disc品目変更履歴アドオンのロック取得
    --==============================================================
    lv_step := 'STEP-11030';
    lv_msg_token := cv_tkn_val_xxcmm_itemhst;
    --
    OPEN   xxcmm_item_hst_lock_cur( i_update_item_rec.item_hst_id );
    CLOSE  xxcmm_item_hst_lock_cur;
    --
    --==============================================================
    --A-9.2 Disc品目変更履歴アドオンの更新
    --==============================================================
    lv_step := 'STEP-11040';
    BEGIN
      UPDATE      xxcmm_system_items_b_hst
      SET         apply_flag              =  cv_yes
                  --
                 ,last_updated_by         =  cn_last_updated_by
                 ,last_update_date        =  cd_last_update_date
                 ,last_update_login       =  cn_last_update_login
                 ,request_id              =  cn_request_id
                 ,program_application_id  =  cn_program_application_id
                 ,program_id              =  cn_program_id
                 ,program_update_date     =  cd_program_update_date
                  --
      WHERE       item_hst_id             =  i_update_item_rec.item_hst_id;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg_errm  := SQLERRM;
        lv_msg_token := cv_tkn_val_xxcmm_itemhst;
        RAISE data_update_err_expt;  -- 更新エラー
    END;
    --
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      -- カーソルクローズ
      IF ( xxcmm_item_lock_cur%ISOPEN ) THEN
        CLOSE  xxcmm_item_lock_cur;
      END IF;
      --
      -- カーソルクローズ
      IF ( xxcmm_item_hst_lock_cur%ISOPEN ) THEN
        CLOSE  xxcmm_item_hst_lock_cur;
      END IF;
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00443            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ更新例外ハンドラ ***
    WHEN data_update_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00445            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                     ,iv_token_value3 => lv_msg_errm                   -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END proc_comp_apply_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_item_update
   * Description      : 品目更新処理(A-7)
   **********************************************************************************/
  PROCEDURE proc_item_update(
    in_item_id            IN     NUMBER             --   OPM品目ID
   ,in_inventory_item_id  IN     NUMBER             --   Disc品目ID
   ,iv_item_no            IN     VARCHAR2           --   品目コード
   ,iv_policy_group       IN     VARCHAR2           --   政策群コード
   ,in_fixed_price        IN     NUMBER             --   定価
   ,in_discrete_cost      IN     NUMBER             --   営業原価
   ,in_organization_id    IN     NUMBER             --   Disc品目原価組織ID
   ,iv_apply_date         IN     VARCHAR2           --   適用日
   ,iv_parent_item        IN     VARCHAR2 DEFAULT NULL
                                                    --   親品目コード
   ,ov_errbuf             OUT    VARCHAR2           --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT    VARCHAR2           --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT    VARCHAR2           --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_ITEM_UPDATE'; -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);     -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
    cn_process_flag              CONSTANT NUMBER(1)    := 1;
    cn_group_id                  CONSTANT NUMBER       := 1000;
    cv_cost_element              CONSTANT VARCHAR2(10) := '資材';            -- 原価要素
    cv_resource_code             CONSTANT VARCHAR2(10) := '営業原価';        -- 副原価要素
    --
-- Ver1.6 2009/03/23 ADD  障害No39対応 マスタ受信日時(OPM品目.ATTRIBUTE30)の設定を追加
    cv_date_format_rmd           CONSTANT VARCHAR2(10) := 'RRRR/MM/DD';      -- マスタ受信日時フォーマット
-- Ver1.6 ADD END
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    lv_msg_errm                  VARCHAR2(4000);
    ln_exsits_count              NUMBER;
    --
    ln_category_set_id           mtl_category_sets.category_set_id%TYPE;     -- カテゴリセットID
    ln_category_id               mtl_categories.category_id%TYPE;            -- カテゴリID
    --
    -- レコード型
    l_opm_item_rec               ic_item_mst_b%ROWTYPE;
    l_opmitem_category_rec       xxcmm_004common_pkg.opmitem_category_rtype;
    l_discitem_category_rec      xxcmm_004common_pkg.discitem_category_rtype;
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    data_rock_err_expt           EXCEPTION;    -- データ抽出エラー
    data_select_err_expt         EXCEPTION;    -- データ抽出エラー
    data_insert_err_expt         EXCEPTION;    -- データ登録エラー
    data_update_err_expt         EXCEPTION;    -- データ更新エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-7.6-0 OPM品目登録情報の抽出
    --==============================================================
    -- OPM品目マスタの更新にAPIを使用 
    lv_step := 'STEP-10010';
    lv_msg_token := cv_tkn_val_opmitem;
    --
    BEGIN
      -- 全項目指定が必要なので登録データを取得する。
      -- 継承する項目は親品目から取得（親品目時も）
      SELECT      iimb.item_id
                 ,iimb.item_no
                 ,iimb.item_desc1
                 ,iimb.item_desc2
                 ,iimb.alt_itema
                 ,iimb.alt_itemb
                 ,iimb.item_um
                 ,iimb.dualum_ind
                 ,iimb.item_um2
                 ,iimb.deviation_lo
                 ,iimb.deviation_hi
                 ,iimb.level_code
                 ,iimb.lot_ctl
                 ,iimb.lot_indivisible
                 ,iimb.sublot_ctl
                 ,iimb.loct_ctl
                 ,iimb.noninv_ind
                 ,iimb.match_type
                 ,iimb.inactive_ind
                 ,iimb.inv_type
                 ,iimb.shelf_life
                 ,iimb.retest_interval
                 ,iimb.gl_class
                 ,iimb.inv_class
                 ,iimb.sales_class
                 ,iimb.ship_class
                 ,iimb.frt_class
                 ,iimb.price_class
                 ,iimb.storage_class
                 ,iimb.purch_class
                 ,iimb.tax_class
                 ,iimb.customs_class
                 ,iimb.alloc_class
                 ,iimb.planning_class
                 ,iimb.itemcost_class
                 ,iimb.cost_mthd_code
                 ,iimb.upc_code
                 ,iimb.grade_ctl
                 ,iimb.status_ctl
                 ,iimb.qc_grade
                 ,iimb.lot_status
                 ,iimb.bulk_id
                 ,iimb.pkg_id
                 ,iimb.qcitem_id
                 ,iimb.qchold_res_code
                 ,iimb.expaction_code
                 ,iimb.fill_qty
                 ,iimb.fill_um
                 ,iimb.expaction_interval
                 ,iimb.phantom_type
                 ,iimb.whse_item_id
                 ,iimb.experimental_ind
                 ,iimb.exported_date
                 ,iimb.trans_cnt
                 ,iimb.delete_mark
                 ,iimb.text_code
                 ,iimb.seq_dpnd_class
                 ,iimb.commodity_code
                 ,iimb.creation_date
                 ,iimb.created_by
                 ,cd_last_update_date               -- WHOカラム（更新日時）
                 ,cn_last_updated_by                -- WHOカラム（更新者）
                 ,cn_last_update_login              -- WHOカラム（最終更新ログイン）
                 ,cn_program_application_id         -- WHOカラム（アプリケーションID）
                 ,cn_program_id                     -- WHOカラム（プログラムID）
                 ,cd_program_update_date            -- WHOカラム（プログラム最終更新日時）
                 ,cn_request_id                     -- WHOカラム（要求ID）
                 ,iimb.attribute1
                 ,iimb.attribute2
                 ,iimb.attribute3
                 ,iimb.attribute4
                 ,iimb.attribute5
                 ,iimb.attribute6
                 ,iimb.attribute7
                 ,iimb.attribute8
                 ,iimb.attribute9
-- Ver1.6 2009/03/23 MOD  障害No37対応 重量/容積・重量容積区分の設定を追加
--                 ,iimb.attribute10
                 ,parent_iimb.attribute10           -- 重量容積区分(親品目から取得)
-- Ver1.6 MOD END
                 ,parent_iimb.attribute11           -- ケース入数(親品目から取得)
                 ,parent_iimb.attribute12           -- NET(親品目から取得)
                 ,iimb.attribute13
                 ,iimb.attribute14
                 ,iimb.attribute15
-- Ver1.6 2009/03/23 MOD  障害No37対応 重量/容積・重量容積区分の設定を追加
--                 ,iimb.attribute16
                 ,parent_iimb.attribute16           -- 容積(親品目から取得)
-- Ver1.6 MOD END
                 ,iimb.attribute17
                 ,iimb.attribute18
                 ,iimb.attribute19
                 ,iimb.attribute20
                 ,parent_iimb.attribute21           -- JAN(親品目から取得)
                 ,parent_iimb.attribute22           -- ITF
                 ,iimb.attribute23
                 ,iimb.attribute24
                 ,parent_iimb.attribute25           -- 重量/体積(親品目から取得)
                 ,iimb.attribute26
                 ,iimb.attribute27
                 ,iimb.attribute28
                 ,iimb.attribute29
-- Ver1.6 2009/03/23 MOD  障害No39対応 マスタ受信日時(OPM品目.ATTRIBUTE30)の設定を追加
--                 ,iimb.attribute30
                 ,TO_CHAR( SYSDATE, cv_date_format_rmd )
                                                    -- マスタ受信日時
-- Ver1.6 MOD END
                 ,iimb.attribute_category
                 ,iimb.item_abccode
                 ,iimb.ont_pricing_qty_source
                 ,iimb.alloc_category_id
                 ,iimb.customs_category_id
                 ,iimb.frt_category_id
                 ,iimb.gl_category_id
                 ,iimb.inv_category_id
                 ,iimb.cost_category_id
                 ,iimb.planning_category_id
                 ,iimb.price_category_id
                 ,iimb.purch_category_id
                 ,iimb.sales_category_id
                 ,iimb.seq_category_id
                 ,iimb.ship_category_id
                 ,iimb.storage_category_id
                 ,iimb.tax_category_id
                 ,iimb.autolot_active_indicator
                 ,iimb.lot_prefix
                 ,iimb.lot_suffix
                 ,iimb.sublot_prefix
                 ,iimb.sublot_suffix
      INTO        l_opm_item_rec
      FROM        ic_item_mst_b       iimb
                 ,ic_item_mst_b       parent_iimb
                 ,xxcmn_item_mst_b    ximb
      WHERE       iimb.item_id            = in_item_id
      AND         ximb.item_id            = iimb.item_id
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--      AND         ximb.start_date_active <= TRUNC( SYSDATE )
--      AND         ximb.end_date_active   >= TRUNC( SYSDATE )
      AND         ximb.start_date_active <= gd_process_date
      AND         ximb.end_date_active   >= gd_process_date
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
      AND         parent_iimb.item_id     = ximb.parent_item_id
      FOR UPDATE OF iimb.item_id NOWAIT;
      --
    EXCEPTION
      -- *** ロックエラー例外ハンドラ ***
      WHEN global_check_lock_expt THEN
        RAISE data_rock_err_expt;    -- ロックエラー
        --
      WHEN OTHERS THEN
        lv_msg_errm  := SQLERRM;
        lv_msg_token := cv_tkn_val_opmitem;
        RAISE data_select_err_expt;  -- 抽出エラー
    END;
    --
    --==============================================================
    --A-7.2 カテゴリセットIDの取得（政策群コード）
    --A-7.3 カテゴリIDの取得（政策群コード）
    --==============================================================
    IF ( iv_policy_group IS NOT NULL ) THEN
      --
      lv_step := 'STEP-10020';
      BEGIN
        -- 政策群コード カテゴリセットID,カテゴリID取得
        SELECT      mcs.category_set_id    -- カテゴリセットID
                   ,mc.category_id         -- カテゴリID
        INTO        ln_category_set_id
                   ,ln_category_id
        FROM        mtl_categories       mc
                   ,mtl_category_sets    mcs
        WHERE       mcs.description = cv_categ_set_seisakugun
        AND         mc.structure_id = mcs.structure_id
        AND         mc.segment1     = iv_policy_group;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg_errm  := SQLERRM;
          lv_msg_token := cv_tkn_val_categ_policy_cd;
          RAISE data_select_err_expt;  -- 抽出エラー
      END;
      --
      -- OPM品目カテゴリ更新用パラメータ設定
      l_opmitem_category_rec.item_id            := in_item_id;
      l_opmitem_category_rec.category_set_id    := ln_category_set_id;
      l_opmitem_category_rec.category_id        := ln_category_id;
      -- Disc品目カテゴリ更新用パラメータ設定
      l_discitem_category_rec.inventory_item_id := in_inventory_item_id;
      l_discitem_category_rec.category_set_id   := ln_category_set_id;
      l_discitem_category_rec.category_id       := ln_category_id;
      --
      --==============================================================
      --A-7.4 品目カテゴリ割当の更新（政策群コード）
      --==============================================================
      -- OPM品目カテゴリ反映
      lv_step := 'STEP-10030';
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec  =>  l_opmitem_category_rec    -- 品目カテゴリ割当レコードタイプ
       ,ov_errbuf            =>  lv_errbuf                 -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           =>  lv_retcode                -- リターン・コード             --# 固定 #
       ,ov_errmsg            =>  lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_opm_item_categ;
        RAISE data_update_err_expt;
      END IF;
      --
      -- Disc品目カテゴリ反映
      lv_step := 'STEP-10040';
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec  =>  l_discitem_category_rec    -- 品目カテゴリ割当レコードタイプ
       ,ov_errbuf            =>  lv_errbuf                  -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           =>  lv_retcode                 -- リターン・コード             --# 固定 #
       ,ov_errmsg            =>  lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_mtl_item_categ;
        RAISE data_update_err_expt;
      END IF;
      --
-- Ver1.8  2009/06/11  Add  政策群コードが変更された場合、群コードにも反映
      --==============================================================
      --A-7.2 カテゴリセットIDの取得（群コード）
      --A-7.3 カテゴリIDの取得（群コード）
      --==============================================================
      lv_step := 'STEP-10050';
      BEGIN
        -- 群コード カテゴリセットID,カテゴリID取得
        SELECT      mcs.category_set_id    -- カテゴリセットID
                   ,mc.category_id         -- カテゴリID
        INTO        ln_category_set_id
                   ,ln_category_id
        FROM        mtl_categories       mc
                   ,mtl_category_sets    mcs
        WHERE       mcs.description = cv_categ_set_gun_code
        AND         mc.structure_id = mcs.structure_id
        AND         mc.segment1     = iv_policy_group;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg_errm  := SQLERRM;
          lv_msg_token := cv_tkn_val_categ_gun_cd;
          RAISE data_select_err_expt;  -- 抽出エラー
      END;
      --
      -- OPM品目カテゴリ更新用パラメータ設定
      l_opmitem_category_rec.item_id            := in_item_id;
      l_opmitem_category_rec.category_set_id    := ln_category_set_id;
      l_opmitem_category_rec.category_id        := ln_category_id;
      -- Disc品目カテゴリ更新用パラメータ設定
      l_discitem_category_rec.inventory_item_id := in_inventory_item_id;
      l_discitem_category_rec.category_set_id   := ln_category_set_id;
      l_discitem_category_rec.category_id       := ln_category_id;
      --
      --==============================================================
      --A-7.4 品目カテゴリ割当の更新（群コード）
      --==============================================================
      -- OPM品目カテゴリ反映
      lv_step := 'STEP-10060';
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec  =>  l_opmitem_category_rec    -- 品目カテゴリ割当レコードタイプ
       ,ov_errbuf            =>  lv_errbuf                 -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           =>  lv_retcode                -- リターン・コード             --# 固定 #
       ,ov_errmsg            =>  lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_opm_item_categ;
        RAISE data_update_err_expt;
      END IF;
      --
      -- Disc品目カテゴリ反映
      lv_step := 'STEP-10070';
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec  =>  l_discitem_category_rec    -- 品目カテゴリ割当レコードタイプ
       ,ov_errbuf            =>  lv_errbuf                  -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           =>  lv_retcode                 -- リターン・コード             --# 固定 #
       ,ov_errmsg            =>  lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_categ_gun_cd;
        RAISE data_update_err_expt;
      END IF;
      --
-- End1.8
      --
      --==============================================================
      --A-7.6-0 OPM品目更新用政策群の設定
      --==============================================================
      lv_step := 'STEP-10080';
      -- 旧・群コード ← 新・群コード
-- Ver1.9  2009/07/06  Mod  障害対応(0000365)
--      l_opm_item_rec.attribute1 := l_opm_item_rec.attribute2;
      l_opm_item_rec.attribute1 := NVL( l_opm_item_rec.attribute2, iv_policy_group );
-- End1.9
      -- 新・群コード
      l_opm_item_rec.attribute2 := iv_policy_group;
      -- 群ｺｰﾄﾞ適用開始日
      l_opm_item_rec.attribute3 := iv_apply_date;
    END IF;
    --
    -- 定価
    IF ( in_fixed_price IS NOT NULL ) THEN
      --==============================================================
      --A-7.6-0 OPM品目更新用定価の設定
      --==============================================================
      lv_step := 'STEP-10110';
      -- 旧・定価 ← 新・定価
-- Ver1.9  2009/07/06  Mod  障害対応(0000365)
--      l_opm_item_rec.attribute4 := l_opm_item_rec.attribute5;
      l_opm_item_rec.attribute4 := NVL( l_opm_item_rec.attribute5, in_fixed_price );
-- End1.9
      -- 新・定価
      l_opm_item_rec.attribute5 := in_fixed_price;
      -- 定価適用開始日
      l_opm_item_rec.attribute6 := iv_apply_date;
    END IF;
    --
    --==============================================================
    --A-7.5 営業原価（保留原価）の登録
    --  原価OIFはインポート時にパージが可能
    --  原価は『原価情報のパージ』コンカレントの実行が必要っぽい。
    --==============================================================
    IF ( in_discrete_cost IS NOT NULL ) THEN
      --
      lv_step := 'STEP-10210';
      SELECT      COUNT( cif.ROWID )
      INTO        ln_exsits_count
      FROM        cst_item_cst_dtls_interface    cif
      WHERE       cif.inventory_item_id = in_inventory_item_id
      AND         cif.organization_id   = in_organization_id
-- Ver1.4 2009/01/30 Add 原価組織変更による修正
      AND         cif.process_flag      = cn_process_flag
      AND         cif.group_id          = cn_group_id
-- End
      AND         ROWNUM                = 1;
      --
      IF ( ln_exsits_count = 0 ) THEN
        -- データ未登録の場合は新規登録
        lv_step := 'STEP-10220';
        BEGIN
          -- 原価OIFへ登録
          INSERT INTO cst_item_cst_dtls_interface(
            inventory_item_id         -- 品目ID
           ,organization_id           -- 組織ID
           ,group_id                  -- グループID
           ,usage_rate_or_amount      -- 原価金額
           ,resource_code             -- 副原価要素
           ,cost_element              -- 原価要素
           ,process_flag )            -- プロセスフラグ
          VALUES(
            in_inventory_item_id
           ,in_organization_id
           ,cn_group_id
           ,in_discrete_cost
           ,cv_resource_code
           ,cv_cost_element
           ,cn_process_flag );
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_msg_errm  := SQLERRM;
            lv_msg_token := cv_tkn_val_disccost_if;
            RAISE data_insert_err_expt;  -- 登録エラー
        END;
      ELSE
        -- データ登録済みの場合は更新
        lv_step := 'STEP-10230';
        BEGIN
          UPDATE      cst_item_cst_dtls_interface                     -- 原価OIF
          SET         usage_rate_or_amount = in_discrete_cost         -- 原価金額
          WHERE       inventory_item_id    = in_inventory_item_id     -- 品目ID
          AND         organization_id      = in_organization_id       -- 組織ID
-- Ver1.4 2009/01/30 Add 原価組織変更による修正
          AND         process_flag         = cn_process_flag          -- プロセスフラグ
          AND         group_id             = cn_group_id;             -- グループID
-- End
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_msg_errm  := SQLERRM;
            lv_msg_token := cv_tkn_val_disccost_if;
            RAISE data_update_err_expt;  -- 更新エラー
        END;
      END IF;
      --
      --==============================================================
      --A-7.6-0 OPM品目更新用営業原価の設定
      --==============================================================
      lv_step := 'STEP-10240';
      -- 旧・営業原価 ← 新・営業原価
-- Ver1.9  2009/07/06  Mod  障害対応(0000365)
--      l_opm_item_rec.attribute7 := l_opm_item_rec.attribute8;
      l_opm_item_rec.attribute7 := NVL( l_opm_item_rec.attribute8, in_discrete_cost );
-- End1.9
      -- 新・営業原価
      l_opm_item_rec.attribute8 := in_discrete_cost;
      -- 営業原価適用開始日
      l_opm_item_rec.attribute9 := iv_apply_date;
    END IF;
    --
    lv_step := 'STEP-10310';
    xxcmm_004common_pkg.upd_opm_item(
      i_opm_item_rec  =>  l_opm_item_rec         -- OPM品目レコードタイプ
     ,ov_errbuf       =>  lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      =>  lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg       =>  lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      lv_msg_errm  := lv_errmsg;
      lv_msg_token := cv_tkn_val_opmitem;
      RAISE data_update_err_expt;
    END IF;
    --
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN data_rock_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00443            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                       ,iv_token_value2 => iv_item_no                    -- トークン値2
                      );
      ELSE
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00447            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_parent_item            -- トークンコード2
                       ,iv_token_value2 => iv_parent_item                -- トークン値2
                       ,iv_token_name3  => cv_tkn_item_code              -- トークンコード3
                       ,iv_token_value3 => iv_item_no                    -- トークン値3
                      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ抽出例外ハンドラ ***
    WHEN data_select_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        -- 品目変更適用による更新
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00442            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_data_info              -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                       ,iv_token_value2 => iv_item_no                    -- トークン値2
                      );
      ELSE
        -- 親品目変更による子品目への継承時
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00446            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_data_info              -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_parent_item            -- トークンコード2
                       ,iv_token_value2 => iv_parent_item                -- トークン値2
                       ,iv_token_name3  => cv_tkn_item_code              -- トークンコード3
                       ,iv_token_value3 => iv_item_no                    -- トークン値3
                      );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg || cv_msg_space|| lv_msg_errm;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ登録例外ハンドラ ***
    WHEN data_insert_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        -- 品目変更適用による更新
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00444            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                       ,iv_token_value2 => iv_item_no                    -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                       ,iv_token_value3 => lv_msg_errm                   -- トークン値3
                      );
      ELSE
        -- 親品目変更による子品目への継承時
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00448            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_parent_item            -- トークンコード2
                       ,iv_token_value2 => iv_parent_item                -- トークン値2
                       ,iv_token_name3  => cv_tkn_item_code              -- トークンコード3
                       ,iv_token_value3 => iv_item_no                    -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg                -- トークンコード4
                       ,iv_token_value4 => lv_msg_errm                   -- トークン値4
                      );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ更新例外ハンドラ ***
    WHEN data_update_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        -- 品目変更適用による更新
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00445            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                       ,iv_token_value2 => iv_item_no                    -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                       ,iv_token_value3 => lv_msg_errm                   -- トークン値3
                      );
      ELSE
        -- 親品目変更による子品目への継承時
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00449            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => lv_msg_token                  -- トークン値1
                       ,iv_token_name2  => cv_tkn_parent_item            -- トークンコード2
                       ,iv_token_value2 => iv_parent_item                -- トークン値2
                       ,iv_token_name3  => cv_tkn_item_code              -- トークンコード3
                       ,iv_token_value3 => iv_item_no                    -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg                -- トークンコード4
                       ,iv_token_value4 => lv_msg_errm                   -- トークン値4
                      );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END proc_item_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_parent_item_update
   * Description      : 親品目変更時の更新、親品目変更時の継承(A-7)
   **********************************************************************************/
  PROCEDURE proc_parent_item_update(
    i_update_item_rec   IN     update_item_cur%ROWTYPE
   ,ov_errbuf           OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_PARENT_ITEM_UPDATE'; -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_step                    VARCHAR2(10);
    --
    -- *** ローカル変数 ***
    lv_msg_token               VARCHAR2(100);
    lv_msg_errm                VARCHAR2(4000);
    --
    lv_item_no                 ic_item_mst_b.item_no%TYPE;     -- 品目コード
    lv_policy_group            VARCHAR2(4);                    -- 政策群コード
    ln_fixed_price             NUMBER;                         -- 定価
    ln_discrete_cost           NUMBER;                         -- 営業原価
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 子商品抽出カーソル
    CURSOR parent_item_cur(
      pn_item_id    NUMBER )
    IS
      SELECT      xoiv.item_id                                    -- OPM品目ID
                 ,xoiv.item_no                                    -- 品目コード
                 ,xoiv.item_status                                -- 品目ステータス
                 ,xoiv.inventory_item_id                          -- Disc品目ID
      FROM        xxcmm_opmmtl_items_v      xoiv                  -- 品目ビュー
      WHERE       xoiv.parent_item_id     = pn_item_id            -- 親商品ID
      AND         xoiv.item_id           != xoiv.parent_item_id   -- 親品目以外
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )      -- 適用開始日
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE );     -- 適用終了日
      AND         xoiv.start_date_active <= gd_process_date       -- 適用開始日
      AND         xoiv.end_date_active   >= gd_process_date;      -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
    --
    -- Disc品目アドオンロックカーソル
    CURSOR xxcmm_item_lock_cur(
      pv_item_code    VARCHAR2 )
    IS
      SELECT    'x'
      FROM      xxcmm_system_items_b
      WHERE     item_code = pv_item_code
      FOR UPDATE NOWAIT;
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    sub_proc_expt              EXCEPTION;
    data_update_err_expt       EXCEPTION;    -- データ更新エラー
    --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --親品目の変更
    --  A-7 親品目変更時の継承
    --==============================================================
    -- 品目判定
    -- 親品目、かつ、政策群コード、定価、営業原価のいずれかの変更
    -- 品目ステータスがＤの場合は対象外（データ登録されないはず）
    IF   ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id )
    AND  ( i_update_item_rec.policy_group  IS NOT NULL
        OR i_update_item_rec.fixed_price   IS NOT NULL
        OR i_update_item_rec.discrete_cost IS NOT NULL )
-- Ver1.7 2009/05/27 Mod  現在のステータスがＤ時に、変更予約のステータスがブランクの想定はしていなかったが
--                        Ｄ時、または、Ｄに変更する場合、登録情報の変更をさせないよう修正
--    AND  ( NVL( i_update_item_rec.item_status, cn_itm_status_num_tmp )  -- 変更予約のステータス
--                                           != cn_itm_status_no_use )    -- 現在のステータスも参照する必要あり
    -- 変更予約のステータスがＤの場合
    -- または、変更予約のステータスが未設定で現ステータスがＤの場合、処理しない
    AND  ( NVL( i_update_item_rec.item_status, i_update_item_rec.b_item_status )
                                             != cn_itm_status_no_use )
-- End
    THEN
      --
      -------------------
      -- 親品目への反映
      -------------------
      lv_step := 'STEP-09010';
      proc_item_update(
        in_item_id            =>  i_update_item_rec.item_id              -- OPM品目ID
       ,in_inventory_item_id  =>  i_update_item_rec.inventory_item_id    -- Disc品目ID
       ,iv_item_no            =>  i_update_item_rec.item_no              -- 品目コード
       ,iv_policy_group       =>  i_update_item_rec.policy_group         -- 政策群コード
       ,in_fixed_price        =>  i_update_item_rec.fixed_price          -- 定価
       ,in_discrete_cost      =>  i_update_item_rec.discrete_cost        -- 営業原価
       ,in_organization_id    =>  gn_cost_org_id                         -- Disc品目原価組織ID
       ,iv_apply_date         =>  TO_CHAR( i_update_item_rec.apply_date, cv_date_fmt_std ) 
                                                                         -- 適用日
       ,ov_errbuf             =>  lv_errbuf                              -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            =>  lv_retcode                             -- リターン・コード             --# 固定 #
       ,ov_errmsg             =>  lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        RAISE sub_proc_expt;
      END IF;
      --
      --==============================================================
      --A-7 親品目変更時の継承
      --==============================================================
      gv_inherit_kbn := cv_inherit_kbn_inh;    -- 親値継承情報区分【'1'：親品目変更による更新】
      --
      --==============================================================
      --A-7.1 品目情報の抽出
      --==============================================================
      lv_step := 'STEP-09020';
      <<child_item_loop>>
      FOR l_parent_item_rec IN parent_item_cur( i_update_item_rec.item_id ) LOOP
        -- メッセージ出力用に退避
        lv_item_no := l_parent_item_rec.item_no;
        --
        IF ( l_parent_item_rec.item_status = cn_itm_status_num_tmp
          OR l_parent_item_rec.item_status IS NULL ) THEN
          -- 仮採番時、NULL時
          lv_step := 'STEP-09030';
          -- 政策群コード：子品目の品目ステータスがＤ以外の場合反映する
          lv_policy_group    := i_update_item_rec.policy_group;
          ln_fixed_price     := NULL;         -- 定価
          ln_discrete_cost   := NULL;         -- 営業原価
          --
        ELSIF ( l_parent_item_rec.item_status = cn_itm_status_pre_reg ) THEN
          -- 仮登録時
          lv_step := 'STEP-09040';
          -- 政策群コード：子品目の品目ステータスがＤ以外の場合反映する
          lv_policy_group    := i_update_item_rec.policy_group;
          -- 定価        ：子品目の品目ステータスが仮登録以降Ｄ以前の場合反映する
          ln_fixed_price     := i_update_item_rec.fixed_price;
          ln_discrete_cost   := NULL;         -- 営業原価
          --
        ELSIF ( l_parent_item_rec.item_status IN ( cn_itm_status_regist
                                                 , cn_itm_status_no_sch
                                                 , cn_itm_status_trn_only ) ) THEN
          -- 本登録、廃、Ｄ’時
          lv_step := 'STEP-09050';
          -- 政策群コード：子品目の品目ステータスがＤ以外の場合反映する
          lv_policy_group    := i_update_item_rec.policy_group;
          -- 定価        ：子品目の品目ステータスが仮登録以降Ｄ以前の場合反映する
          ln_fixed_price     := i_update_item_rec.fixed_price;
          -- 営業原価    ：子品目の品目ステータスが本登録以降Ｄ以前の場合反映する
          ln_discrete_cost   := i_update_item_rec.discrete_cost;
          --
        ELSE
          -- Ｄ時
          lv_step := 'STEP-09060';
          -- なにもしない
          lv_policy_group    := NULL;         -- 政策群コード
          ln_fixed_price     := NULL;         -- 定価
          ln_discrete_cost   := NULL;         -- 営業原価
        END IF;
        --
        -- 変更適用を実施する項目が存在するか
        IF ( lv_policy_group  IS NOT NULL
          OR ln_fixed_price   IS NOT NULL
          OR ln_discrete_cost IS NOT NULL ) THEN
          -- 
          -------------------
          -- 子品目への展開
          -------------------
          lv_step := 'STEP-09070';
          proc_item_update(
            in_item_id            =>  l_parent_item_rec.item_id              -- OPM品目ID
           ,in_inventory_item_id  =>  l_parent_item_rec.inventory_item_id    -- Disc品目ID
           ,iv_item_no            =>  l_parent_item_rec.item_no              -- 品目コード
           ,iv_policy_group       =>  lv_policy_group                        -- 政策群コード
           ,in_fixed_price        =>  ln_fixed_price                         -- 定価
           ,in_discrete_cost      =>  ln_discrete_cost                       -- 営業原価
           ,in_organization_id    =>  gn_cost_org_id                         -- Disc品目原価組織ID
           ,iv_apply_date         =>  TO_CHAR( i_update_item_rec.apply_date, cv_date_fmt_std ) 
                                                                             -- 適用日
           ,iv_parent_item        =>  i_update_item_rec.item_no              -- 親品目コード
           ,ov_errbuf             =>  lv_errbuf                              -- エラー・メッセージ           --# 固定 #
           ,ov_retcode            =>  lv_retcode                             -- リターン・コード             --# 固定 #
           ,ov_errmsg             =>  lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            --
            RAISE sub_proc_expt;
          END IF;
          --
          --==============================================================
          --A-7.7 子品目時のDisc品目アドオンの更新
          --==============================================================
          lv_step := 'STEP-09080';
          -- Disc品目アドオンロック
          lv_msg_token := cv_tkn_val_xxcmm_discitem;
          --
          OPEN   xxcmm_item_lock_cur( l_parent_item_rec.item_no );
          CLOSE  xxcmm_item_lock_cur;
          --
          lv_step := 'STEP-09090';
          BEGIN
            UPDATE      xxcmm_system_items_b    -- Disc品目アドオン
-- Ver1.5 2009/02/20 Mod 検索対象更新日に業務日付を設定するよう修正
--            SET         search_update_date     = i_update_item_rec.apply_date
                        -- 検索対象更新日
            SET         search_update_date     = gd_process_date
-- End
                       ,last_updated_by        = cn_last_updated_by
                       ,last_update_date       = cd_last_update_date
                       ,last_update_login      = cn_last_update_login
                       ,request_id             = cn_request_id
                       ,program_application_id = cn_program_application_id
                       ,program_id             = cn_program_id
                       ,program_update_date    = cd_program_update_date
                        --
            WHERE       item_code              = l_parent_item_rec.item_no;
            --
          EXCEPTION
            WHEN OTHERS THEN
              lv_msg_errm  := SQLERRM;
              lv_msg_token := cv_tkn_val_xxcmm_discitem;
              RAISE data_update_err_expt;  -- 更新エラー
          END;
          --
        END IF;
      END LOOP child_item_loop;
      --
      gv_inherit_kbn := cv_inherit_kbn_hst;    -- 親値継承情報区分【'0'：履歴情報による更新】
    END IF;
    --
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      -- カーソルクローズ
      IF ( xxcmm_item_lock_cur%ISOPEN ) THEN
        CLOSE  xxcmm_item_lock_cur;
      END IF;
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00447            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_parent_item            -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_item_code              -- トークンコード3
                     ,iv_token_value3 => lv_item_no                    -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ更新例外ハンドラ ***
    WHEN data_update_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00449            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_parent_item            -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_item_code              -- トークンコード3
                     ,iv_token_value3 => lv_item_no                    -- トークン値3
                     ,iv_token_name4  => cv_tkn_err_msg                -- トークンコード4
                     ,iv_token_value4 => lv_msg_errm                   -- トークン値4
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END proc_parent_item_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_inherit_parent
   * Description      : 親品目情報の継承(A-6)
   **********************************************************************************/
  PROCEDURE proc_inherit_parent(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2             --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT    VARCHAR2             --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT    VARCHAR2             --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_INHERIT_PARENT';  -- プログラム名
    --
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);     -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
-- Ver1.6 2009/03/23 ADD  障害No37  Ｄからのステータス変更時
    lv_msg_errm                  VARCHAR2(4000);
-- Ver1.6 ADD END
    --
    ln_exsits_count              NUMBER;
    ln_cmp_cost_index            NUMBER;
    --
    -- 登録値確認用
    ln_fixed_price               NUMBER;          -- 定価
    ln_discrete_cost             NUMBER;          -- 営業原価
    lv_policy_group              VARCHAR2(4);     -- 政策群コード
    -- 変更用(親値)
    ln_fixed_price_parent        NUMBER;          -- 定価
    ln_discrete_cost_parent      NUMBER;          -- 営業原価
    lv_policy_group_parent       VARCHAR2(4);     -- 政策群コード
    --
-- Ver1.6 2009/03/23 ADD  障害No37  Ｄからのステータス変更時
    ln_category_set_id           mtl_category_sets.category_set_id%TYPE;     -- カテゴリセットID
    ln_category_id               mtl_categories.category_id%TYPE;            -- カテゴリID
-- Ver1.6 ADD END
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
-- Ver1.2 2009/01/27 MOD 標準原価登録ロジックの修正
--    -- 親品目標準原価抽出カーソル
--    CURSOR cnp_cost_cur(
--      pn_parent_item_id  NUMBER
--     ,pn_item_id         NUMBER
--     ,pd_apply_date      DATE )
--    IS
--      SELECT    ccmd2.cmpntcost_id
--               ,ccmd.item_id                  -- 品目ID
--               ,ccmd.calendar_code            -- カレンダコード
--               ,ccmd.period_code              -- 期間コード
--               ,ccmd.cost_cmpntcls_id         -- 原価コンポーネントID
--               ,ccmv.cost_cmpntcls_code       -- 原価コンポーネントコード
--               ,ccmd.cmpnt_cost               -- 原価
--      FROM      cm_cmpt_dtl          ccmd     -- OPM標準原価(親-原価取得)
--               ,cm_cmpt_dtl          ccmd2    -- OPM標準原価(子-原価ＩＤ取得)
--               ,cm_cldr_dtl          cclr     -- OPM原価カレンダ
--               ,cm_cmpt_mst_vl       ccmv     -- 原価コンポーネント
--               ,fnd_lookup_values_vl flv      -- 参照コード値
--      WHERE     ccmd.item_id             = pn_parent_item_id            -- 品目（親）
--      AND       ccmd2.item_id(+)         = pn_item_id                   -- 品目（子）
--      AND       cclr.start_date         <= pd_apply_date                -- 開始日
--      AND       cclr.end_date           >= pd_apply_date                -- 終了日
--      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- 参照タイプ
--      AND       flv.enabled_flag         = cv_yes                       -- 使用可能
--      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- 原価コンポーネントコード
--      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id        -- 原価コンポーネントID
--      AND       ccmd.calendar_code       = cclr.calendar_code           -- カレンダコード
--      AND       ccmd.period_code         = cclr.period_code             -- 期間コード
--      AND       ccmd.whse_code           = cv_whse_code                 -- 倉庫
--      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code            -- 原価方法
--      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code        -- 分析コード
--      AND       ccmd.cost_cmpntcls_id    = ccmd2.cost_cmpntcls_id(+)    -- 原価コンポーネントID
--      AND       ccmd.calendar_code       = ccmd2.calendar_code(+)       -- カレンダコード
--      AND       ccmd.period_code         = ccmd2.period_code(+)         -- 期間コード
--      AND       ccmd.whse_code           = ccmd2.whse_code(+)           -- 倉庫
--      AND       ccmd.cost_mthd_code      = ccmd2.cost_mthd_code(+)      -- 原価方法
--      AND       ccmd.cost_analysis_code  = ccmd2.cost_analysis_code(+)  -- 分析コード
--      ORDER BY  ccmv.cost_cmpntcls_code;
    --
    -- 標準原価ヘッダ抽出カーソル
    CURSOR cnp_cost_hd_cur(
      pn_parent_item_id  NUMBER
     ,pd_apply_date      DATE )
    IS
      SELECT    DISTINCT
                ccmd.calendar_code            -- カレンダコード
               ,ccmd.period_code              -- 期間コード
      FROM      cm_cmpt_dtl          ccmd     -- OPM標準原価(親-原価取得)
               ,cm_cldr_dtl          cclr     -- OPM原価カレンダ
               ,cm_cmpt_mst_vl       ccmv     -- 原価コンポーネント
               ,fnd_lookup_values_vl flv      -- 参照コード値
      WHERE     ccmd.item_id             = pn_parent_item_id            -- 品目（親）
      AND       cclr.end_date           >= pd_apply_date                -- 終了日
      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- 参照タイプ
      AND       flv.enabled_flag         = cv_yes                       -- 使用可能
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- 原価コンポーネントコード
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id        -- 原価コンポーネントID
      AND       ccmd.calendar_code       = cclr.calendar_code           -- カレンダコード
      AND       ccmd.period_code         = cclr.period_code             -- 期間コード
      AND       ccmd.whse_code           = cv_whse_code                 -- 倉庫
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code            -- 原価方法
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code        -- 分析コード
      ORDER BY  ccmd.calendar_code
               ,ccmd.period_code;
    --
    -- 標準原価明細抽出カーソル
    CURSOR cnp_cost_dt_cur(
      pn_parent_item_id  NUMBER
     ,pn_item_id         NUMBER
     ,pv_calendar_code   VARCHAR2
     ,pv_period_code     VARCHAR2 )
-- Ver1.9  2009/07/06  Del  使用していないため削除
--     ,pd_apply_date      DATE )
-- End1.9
    IS
      SELECT    ccmd2.cmpntcost_id            -- 標準原価ID
               ,ccmd.item_id                  -- 品目ID
               ,ccmd.calendar_code            -- カレンダコード
               ,ccmd.period_code              -- 期間コード
               ,ccmd.cost_cmpntcls_id         -- 原価コンポーネントID
               ,ccmv.cost_cmpntcls_code       -- 原価コンポーネントコード
               ,ccmd.cmpnt_cost               -- 原価
      FROM      cm_cmpt_dtl          ccmd     -- OPM標準原価(親-原価取得)
               ,cm_cmpt_dtl          ccmd2    -- OPM標準原価(子-原価ＩＤ取得)
               ,cm_cldr_dtl          cclr     -- OPM原価カレンダ
               ,cm_cmpt_mst_vl       ccmv     -- 原価コンポーネント
               ,fnd_lookup_values_vl flv      -- 参照コード値
      WHERE     ccmd.item_id             = pn_parent_item_id            -- 品目（親）
      AND       ccmd2.item_id(+)         = pn_item_id                   -- 品目（子）
      AND       cclr.calendar_code       = pv_calendar_code             -- カレンダコード
      AND       cclr.period_code         = pv_period_code               -- 期間コード
      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- 参照タイプ
      AND       flv.enabled_flag         = cv_yes                       -- 使用可能
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- 原価コンポーネントコード
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id        -- 原価コンポーネントID
      AND       ccmd.calendar_code       = cclr.calendar_code           -- カレンダコード
      AND       ccmd.period_code         = cclr.period_code             -- 期間コード
      AND       ccmd.whse_code           = cv_whse_code                 -- 倉庫
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code            -- 原価方法
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code        -- 分析コード
      AND       ccmd.cost_cmpntcls_id    = ccmd2.cost_cmpntcls_id(+)    -- 原価コンポーネントID
      AND       ccmd.calendar_code       = ccmd2.calendar_code(+)       -- カレンダコード
      AND       ccmd.period_code         = ccmd2.period_code(+)         -- 期間コード
      AND       ccmd.whse_code           = ccmd2.whse_code(+)           -- 倉庫
      AND       ccmd.cost_mthd_code      = ccmd2.cost_mthd_code(+)      -- 原価方法
      AND       ccmd.cost_analysis_code  = ccmd2.cost_analysis_code(+)  -- 分析コード
      ORDER BY  ccmv.cost_cmpntcls_code;
-- End （Ver1.2 2009/01/27 MOD 標準原価登録ロジックの修正）
    --
    -- レコード型
    -- OPM標準原価用
    l_opm_cost_header_rec        xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab          xxcmm_004common_pkg.opm_cost_dist_ttype;
    --
-- Ver1.6 2009/03/23 ADD  障害No37  Ｄからのステータス変更時
    l_opmitem_category_rec       xxcmm_004common_pkg.opmitem_category_rtype;
    l_discitem_category_rec      xxcmm_004common_pkg.discitem_category_rtype;
-- Ver1.6 ADD END
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    item_common_ins_expt         EXCEPTION;    -- データ登録エラー(品目共通API)
    sub_proc_expt                EXCEPTION;
    --
-- Ver1.6 2009/03/23 ADD  障害No37  Ｄからのステータス変更時
    data_select_err_expt         EXCEPTION;    -- データ抽出エラー
    data_update_err_expt         EXCEPTION;    -- データ更新エラー
-- Ver1.6 ADD END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-6 親品目情報の継承
    --==============================================================
    ------------------------
    -- 子品目時の親値継承
    ------------------------
    IF ( i_update_item_rec.parent_item_id IS NULL 
      OR i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
      -- 親品目が設定されていない（仮採番）場合、ＯＰＭ更新なし
      -- 品目ステータスがＤの場合もＯＰＭ更新なし
      NULL;
    ELSIF ( i_update_item_rec.item_id != i_update_item_rec.parent_item_id ) THEN
      --==============================================================
      --A-6 親品目が設定されている場合、親品目情報を継承する
      --==============================================================
      lv_step := 'STEP-08010';
      -- 営業原価、定価、政策群の登録値確認
      SELECT      xoiv.opt_cost_new                                     -- 営業原価
                 ,xoiv.price_new                                        -- 定価
                 ,xoiv.crowd_code_new                                   -- 政策群
      INTO        ln_discrete_cost
                 ,ln_fixed_price
                 ,lv_policy_group
      FROM        xxcmm_opmmtl_items_v      xoiv                        -- 品目ビュー
      WHERE       xoiv.item_id            = i_update_item_rec.item_id   -- 品目ID
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )            -- 適用開始日
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE );           -- 適用終了日
      AND         xoiv.start_date_active <= gd_process_date             -- 適用開始日
      AND         xoiv.end_date_active   >= gd_process_date;            -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
      --
      IF ( lv_policy_group IS NULL
        OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
        --==============================================================
        --A-6.1-2 親品目の政策群の取得
        --==============================================================
        lv_step := 'STEP-08020';
        SELECT      xoiv.crowd_code_new                                          -- 政策群コード
        INTO        lv_policy_group_parent
        FROM        xxcmm_opmmtl_items_v      xoiv                               -- 品目ビュー
        WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- 親品目ID
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--        AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- 適用開始日
--        AND         xoiv.end_date_active   >= TRUNC( SYSDATE );                  -- 適用終了日
        AND         xoiv.start_date_active <= gd_process_date                    -- 適用開始日
        AND         xoiv.end_date_active   >= gd_process_date;                   -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
        --
        IF ( lv_policy_group = lv_policy_group_parent ) THEN
          -- 変更されていない場合政策群の更新をしない
          lv_policy_group_parent := NULL;
        END IF;
      END IF;
      --
      --==============================================================
      --A-6.1 品目ステータスが’仮登録’以降の場合
      --==============================================================
      IF ( i_update_item_rec.item_status > cn_itm_status_num_tmp ) THEN
        --
        IF ( ln_fixed_price IS NULL
          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
          --==============================================================
          --A-6.1-2 親品目の定価の取得
          --==============================================================
          lv_step := 'STEP-08110';
          SELECT      xoiv.price_new                                               -- 定価
          INTO        ln_fixed_price_parent
          FROM        xxcmm_opmmtl_items_v      xoiv                               -- 品目ビュー
          WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- 親品目ID
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--          AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- 適用開始日
--          AND         xoiv.end_date_active   >= TRUNC( SYSDATE );                  -- 適用終了日
          AND         xoiv.start_date_active <= gd_process_date                    -- 適用開始日
          AND         xoiv.end_date_active   >= gd_process_date;                   -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
          --
          IF ( ln_fixed_price = ln_fixed_price_parent ) THEN
            -- 変更されていない場合定価の更新をしない
            ln_fixed_price_parent := NULL;
          END IF;
        END IF;
        --
-- Ver1.9  2009/07/07  Add  標準原価の継承は仮登録時に変更
-- 2009/10/16 Ver1.13 modify start by Yutaka.Kuboshima
-- ※子品目への継承条件を削除
-- ⇒親品目の指定が仮登録時も可能になったため、親品目が仮登録時は標準原価を保持していないので、
--   現状の仕様では標準原価が0円で継承されてしまう。さらに、継承タイミングが1度しかないため、
--   子品目の標準原価が0円のままになってしまう恐れがあるため継承条件を削除。
        --
        -- 標準原価登録済み確認
--        lv_step := 'STEP-08210';
--
--        SELECT      COUNT( ccmd.ROWID )
--        INTO        ln_exsits_count
--        FROM        cm_cmpt_dtl    ccmd                          -- OPM標準原価
--        WHERE       ccmd.item_id = i_update_item_rec.item_id     -- 品目ID
--        AND         ROWNUM = 1;
--        --
--        -- 該当子品目に標準原価が登録されている場合、最新なので処理しない。
--        -- ただし、変更前ステータスがＤの場合、最新の保証がないため更新する
--        IF ( ln_exsits_count = 0
--          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
--          --
--          --==============================================================
--          --A-6.2-5 親品目の標準原価の取得
--          --==============================================================
--          -- 原価ヘッダ(カレンダコード、期間コード)の取得
--          lv_step := 'STEP-08220';
--          <<cnp_cost_hd_loop>>
--          FOR l_cnp_cost_hd_rec IN cnp_cost_hd_cur( i_update_item_rec.parent_item_id
--                                                   ,i_update_item_rec.apply_date ) LOOP
--            -----------------
--            -- 原価ヘッダ
--            -----------------
--            lv_step := 'STEP-08230';
--            -- カレンダコード
--            l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_rec.calendar_code;
--            -- 期間コード
--            l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_rec.period_code;
--            -- 品目ID
--            l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
--            --
--            lv_step := 'STEP-08240';
--            ln_cmp_cost_index := 0;
--            <<cnp_cost_dt_loop>>
--            FOR l_cnp_cost_dt_rec IN cnp_cost_dt_cur( i_update_item_rec.parent_item_id
--                                                     ,i_update_item_rec.item_id
--                                                     ,l_cnp_cost_hd_rec.calendar_code
--                                                     ,l_cnp_cost_hd_rec.period_code ) LOOP
--              -----------------
--              -- 原価明細
--              -----------------
--              lv_step := 'STEP-08250';
--              ln_cmp_cost_index := ln_cmp_cost_index + 1;
--              --
--              -- 原価ID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_dt_rec.cmpntcost_id;
--              -- 原価コンポーネントID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_dt_rec.cost_cmpntcls_id;
--              -- 原価
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_dt_rec.cmpnt_cost;
--            --
--            END LOOP cnp_cost_dt_loop;
--            --
--            --==============================================================
--            --A-6.2-6 標準原価の登録・更新
--            --==============================================================
--            lv_step := 'STEP-08260';
--            xxcmm_004common_pkg.proc_opmcost_ref(
--              i_cost_header_rec  =>  l_opm_cost_header_rec  -- 原価ヘッダレコードタイプ
--             ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- 原価明細テーブルタイプ
--             ,ov_errbuf          =>  lv_errbuf              -- エラー・メッセージ           --# 固定 #
--             ,ov_retcode         =>  lv_retcode             -- リターン・コード             --# 固定 #
--             ,ov_errmsg          =>  lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
--            );
--            --
--            IF ( lv_retcode = cv_status_error ) THEN
--              --
--              lv_msg_token := cv_tkn_val_opmcost;
--              RAISE item_common_ins_expt;
--            END IF;
--            --
--          END LOOP cnp_cost_hd_loop;
--          --
--        END IF;
-- End1.9
        --==============================================================
        --A-6.2-5 親品目の標準原価の取得
        --==============================================================
        -- 原価ヘッダ(カレンダコード、期間コード)の取得
        lv_step := 'STEP-08210';
        <<cnp_cost_hd_loop>>
        FOR l_cnp_cost_hd_rec IN cnp_cost_hd_cur( i_update_item_rec.parent_item_id
                                                 ,i_update_item_rec.apply_date ) LOOP
          -----------------
          -- 原価ヘッダ
          -----------------
          lv_step := 'STEP-08220';
          -- カレンダコード
          l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_rec.calendar_code;
          -- 期間コード
          l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_rec.period_code;
          -- 品目ID
          l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
          --
          lv_step := 'STEP-08230';
          ln_cmp_cost_index := 0;
          <<cnp_cost_dt_loop>>
          FOR l_cnp_cost_dt_rec IN cnp_cost_dt_cur( i_update_item_rec.parent_item_id
                                                   ,i_update_item_rec.item_id
                                                   ,l_cnp_cost_hd_rec.calendar_code
                                                   ,l_cnp_cost_hd_rec.period_code ) LOOP
            -----------------
            -- 原価明細
            -----------------
            lv_step := 'STEP-08240';
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            --
            -- 原価ID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_dt_rec.cmpntcost_id;
            -- 原価コンポーネントID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_dt_rec.cost_cmpntcls_id;
            -- 原価
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_dt_rec.cmpnt_cost;
          --
          END LOOP cnp_cost_dt_loop;
          --
          --==============================================================
          --A-6.2-6 標準原価の登録・更新
          --==============================================================
          lv_step := 'STEP-08250';
          xxcmm_004common_pkg.proc_opmcost_ref(
            i_cost_header_rec  =>  l_opm_cost_header_rec  -- 原価ヘッダレコードタイプ
           ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- 原価明細テーブルタイプ
           ,ov_errbuf          =>  lv_errbuf              -- エラー・メッセージ           --# 固定 #
           ,ov_retcode         =>  lv_retcode             -- リターン・コード             --# 固定 #
           ,ov_errmsg          =>  lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            --
            lv_msg_token := cv_tkn_val_opmcost;
            RAISE item_common_ins_expt;
          END IF;
          --
        END LOOP cnp_cost_hd_loop;
-- 2009/10/16 Ver1.13 modify end by Yutaka.Kuboshima
      END IF;
      --
      --==============================================================
      --A-6.2 品目ステータスが’本登録’以降の場合
      --==============================================================
      IF ( i_update_item_rec.item_status > cn_itm_status_pre_reg ) THEN
        --
        IF ( ln_discrete_cost IS NULL
          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
          --==============================================================
          --A-6.2-2 親品目営業原価の取得
          --==============================================================
          lv_step := 'STEP-08310';
          SELECT      xoiv.opt_cost_new                                            -- 定価
          INTO        ln_discrete_cost_parent
          FROM        xxcmm_opmmtl_items_v      xoiv                               -- 品目ビュー
          WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- 親品目ID
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--          AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- 適用開始日
--          AND         xoiv.end_date_active   >= TRUNC( SYSDATE );                  -- 適用終了日
          AND         xoiv.start_date_active <= gd_process_date                    -- 適用開始日
          AND         xoiv.end_date_active   >= gd_process_date;                   -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
          --
          IF ( ln_discrete_cost = ln_discrete_cost_parent ) THEN
            -- 変更されていない場合営業原価の更新をしない
            ln_discrete_cost_parent := NULL;
          END IF;
        END IF;
        --
-- Ver1.9  2009/07/07  Del  標準原価の継承は仮登録時に変更
--        -- 標準原価登録済み確認
--        lv_step := 'STEP-08050';
--        SELECT      COUNT( ccmd.ROWID )
--        INTO        ln_exsits_count
--        FROM        cm_cmpt_dtl    ccmd                          -- OPM標準原価
--        WHERE       ccmd.item_id = i_update_item_rec.item_id     -- 品目ID
--        AND         ROWNUM = 1;
--        --
--        -- 該当子品目に標準原価が登録されている場合、最新なので処理しない。
--        -- ただし、変更前ステータスがＤの場合、最新の保証がないため更新する
--        IF ( ln_exsits_count = 0
--          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
--          --
--          --==============================================================
--          --A-6.2-5 親品目の標準原価の取得
--          --==============================================================
---- Ver1.2 2009/01/27 MOD 標準原価登録ロジックの修正
----          lv_step := 'STEP-08060';
----          ln_cmp_cost_index := 0;
----          <<cnp_cost_loop>>
----          FOR l_cnp_cost_rec IN cnp_cost_cur( i_update_item_rec.parent_item_id
----                                             ,i_update_item_rec.item_id
----                                             ,gd_apply_date ) LOOP
----            --
----            ln_cmp_cost_index := ln_cmp_cost_index + 1;
----            -- 原価ヘッダ
----            IF ( ln_cmp_cost_index = 1 ) THEN
----              -- カレンダコード
----              l_opm_cost_header_rec.calendar_code     := l_cnp_cost_rec.calendar_code;
----              -- 期間コード
----              l_opm_cost_header_rec.period_code       := l_cnp_cost_rec.period_code;
----              -- 品目ID
----              l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
----            END IF;
----            --
----            -- 原価明細
----            -- 原価ID
----            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_rec.cmpntcost_id;
----            -- 原価コンポーネントID
----            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_rec.cost_cmpntcls_id;
----            -- 原価
----            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_rec.cmpnt_cost;
----            --
----          END LOOP cnp_cost_loop;
----          --
----          --==============================================================
----          --A-6.2-6 標準原価の登録・更新
----          --==============================================================
----          lv_step := 'STEP-08070';
----          xxcmm_004common_pkg.proc_opmcost_ref(
----            i_cost_header_rec  =>  l_opm_cost_header_rec  -- 原価ヘッダレコードタイプ
----           ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- 原価明細テーブルタイプ
----           ,ov_errbuf          =>  lv_errbuf              -- エラー・メッセージ           --# 固定 #
----           ,ov_retcode         =>  lv_retcode             -- リターン・コード             --# 固定 #
----           ,ov_errmsg          =>  lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
----          );
----          --
----          IF ( lv_retcode = cv_status_error ) THEN
----            --
----            lv_msg_token := cv_tkn_val_opmcost;
----            RAISE item_common_ins_expt;
----          END IF;
----
--          -- 原価ヘッダ(カレンダコード、期間コード)の取得
--          lv_step := 'STEP-08060';
--          <<cnp_cost_hd_loop>>
--          FOR l_cnp_cost_hd_rec IN cnp_cost_hd_cur( i_update_item_rec.parent_item_id
--                                                   ,gd_apply_date ) LOOP
--            -----------------
--            -- 原価ヘッダ
--            -----------------
--            lv_step := 'STEP-08070';
--            -- カレンダコード
--            l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_rec.calendar_code;
--            -- 期間コード
--            l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_rec.period_code;
--            -- 品目ID
--            l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
--            --
--            -- カレンダ、期間毎に原価情報を取得
--            --   2009/07/06 記  複数期間（カレンダ）の登録を想定していたが、
--            --                  カレンダ毎に明細を初期化しておらず顕在化していないバグだったと思われる。
--            --                  0000364対応でコンポーネントが歯抜けになる可能性がなくなったため対応はなし。
--            lv_step := 'STEP-08080';
--            ln_cmp_cost_index := 0;
--            <<cnp_cost_dt_loop>>
--            FOR l_cnp_cost_dt_rec IN cnp_cost_dt_cur( i_update_item_rec.parent_item_id
--                                                     ,i_update_item_rec.item_id
--                                                     ,l_cnp_cost_hd_rec.calendar_code
--                                                     ,l_cnp_cost_hd_rec.period_code
--                                                     ,gd_apply_date ) LOOP
--              -----------------
--              -- 原価明細
--              -----------------
--              lv_step := 'STEP-08090';
--              ln_cmp_cost_index := ln_cmp_cost_index + 1;
--              --
--              -- 原価ID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_dt_rec.cmpntcost_id;
--              -- 原価コンポーネントID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_dt_rec.cost_cmpntcls_id;
--              -- 原価
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_dt_rec.cmpnt_cost;
--            --
--            END LOOP cnp_cost_dt_loop;
--            --
--            --==============================================================
--            --A-6.2-6 標準原価の登録・更新
--            --==============================================================
--            lv_step := 'STEP-08100';
--            xxcmm_004common_pkg.proc_opmcost_ref(
--              i_cost_header_rec  =>  l_opm_cost_header_rec  -- 原価ヘッダレコードタイプ
--             ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- 原価明細テーブルタイプ
--             ,ov_errbuf          =>  lv_errbuf              -- エラー・メッセージ           --# 固定 #
--             ,ov_retcode         =>  lv_retcode             -- リターン・コード             --# 固定 #
--             ,ov_errmsg          =>  lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
--            );
--            --
--            IF ( lv_retcode = cv_status_error ) THEN
--              --
--              lv_msg_token := cv_tkn_val_opmcost;
--              RAISE item_common_ins_expt;
--            END IF;
--            --
--          END LOOP cnp_cost_hd_loop;
--          --
---- End （Ver1.2 2009/01/27 MOD 標準原価登録ロジックの修正）
--        END IF;
-- End1.9
      END IF;
      --
-- Ver1.6 2009/03/23 MOD  障害No37、39対応  Ｄからのステータス変更時
--      IF ( ln_fixed_price_parent   IS NOT NULL
--        OR ln_discrete_cost_parent IS NOT NULL
--        OR lv_policy_group_parent  IS NOT NULL ) THEN
      IF ( ln_fixed_price_parent   IS NOT NULL
        OR ln_discrete_cost_parent IS NOT NULL
        OR lv_policy_group_parent  IS NOT NULL
        OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
-- Ver1.6 MOD END
--
-- Ver1.6 2009/03/23 ADD  障害No37  Ｄからのステータス変更時
--
        -- Ｄからのステータス変更時、かつ、本社商品区分が変更されている場合、
        -- 親品目の本社商品区分を反映する。
        IF ( i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
          --
          lv_step := 'STEP-08410';
          BEGIN
            -- 本社商品区分 カテゴリセットID,カテゴリID取得
            -- 親品目と同じ場合ＮＵＬＬを設定
            SELECT      DECODE( p_hon.p_hon_prd, c_hon.c_hon_prd, NULL
                                               , p_hon.category_set_id )    category_set_id
                       ,DECODE( p_hon.p_hon_prd, c_hon.c_hon_prd, NULL
                                               , p_hon.category_id )        category_id
            INTO        ln_category_set_id
                       ,ln_category_id
            FROM        -- 本社商品区分用(親品目)
                      ( SELECT      mcsv_ho.category_set_id   category_set_id
                                   ,mcv_ho.category_id        category_id
                                   ,mcv_ho.segment1           p_hon_prd
                        FROM        gmi_item_categories       gic_ho
                                   ,mtl_category_sets_vl      mcsv_ho
                                   ,mtl_categories_vl         mcv_ho
                        WHERE       mcsv_ho.category_set_name = cv_categ_set_hon_prod
                        AND         gic_ho.category_set_id    = mcsv_ho.category_set_id
                        AND         gic_ho.category_id        = mcv_ho.category_id
                        AND         gic_ho.item_id            = i_update_item_rec.parent_item_id ) p_hon,
                        -- 本社商品区分用(子品目)
                      ( SELECT      mcv_ho.segment1           c_hon_prd
                        FROM        gmi_item_categories       gic_ho
                                   ,mtl_category_sets_vl      mcsv_ho
                                   ,mtl_categories_vl         mcv_ho
                        WHERE       mcsv_ho.category_set_name = cv_categ_set_hon_prod
                        AND         gic_ho.category_set_id    = mcsv_ho.category_set_id
                        AND         gic_ho.category_id        = mcv_ho.category_id
                        AND         gic_ho.item_id            = i_update_item_rec.item_id ) c_hon;
            --
          EXCEPTION
            WHEN OTHERS THEN
              lv_msg_errm  := SQLERRM;
              lv_msg_token := cv_tkn_val_categ_prd_class;
              RAISE data_select_err_expt;  -- 抽出エラー
          END;
          --
          -- 親品目の本社商品区分と異なる場合処理を実施
          IF ( ln_category_set_id IS NOT NULL ) THEN
            -- OPM品目カテゴリ更新用パラメータ設定
            l_opmitem_category_rec.item_id            := i_update_item_rec.item_id;
            l_opmitem_category_rec.category_set_id    := ln_category_set_id;
            l_opmitem_category_rec.category_id        := ln_category_id;
            -- Disc品目カテゴリ更新用パラメータ設定
            l_discitem_category_rec.inventory_item_id := i_update_item_rec.inventory_item_id;
            l_discitem_category_rec.category_set_id   := ln_category_set_id;
            l_discitem_category_rec.category_id       := ln_category_id;
            --
            -- OPM品目カテゴリ反映
            lv_step := 'STEP-08420';
            xxcmm_004common_pkg.proc_opmitem_categ_ref(
              i_item_category_rec  =>  l_opmitem_category_rec    -- 品目カテゴリ割当レコードタイプ
             ,ov_errbuf            =>  lv_errbuf                 -- エラー・メッセージ           --# 固定 #
             ,ov_retcode           =>  lv_retcode                -- リターン・コード             --# 固定 #
             ,ov_errmsg            =>  lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              lv_msg_errm  := lv_errmsg;
              lv_msg_token := cv_tkn_val_opm_item_categ;
              RAISE data_update_err_expt;
            END IF;
            --
            -- Disc品目カテゴリ反映
            lv_step := 'STEP-08430';
            xxcmm_004common_pkg.proc_discitem_categ_ref(
              i_item_category_rec  =>  l_discitem_category_rec    -- 品目カテゴリ割当レコードタイプ
             ,ov_errbuf            =>  lv_errbuf                  -- エラー・メッセージ           --# 固定 #
             ,ov_retcode           =>  lv_retcode                 -- リターン・コード             --# 固定 #
             ,ov_errmsg            =>  lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              lv_msg_errm  := lv_errmsg;
              lv_msg_token := cv_tkn_val_mtl_item_categ;
              RAISE data_update_err_expt;
            END IF;
          END IF;
          --
        END IF;
        --
-- Ver1.6 ADD END
        --
        --==============================================================
        --A-6.2-3 営業原価の登録
        --A-6.2-4 OPM品目更新
        --==============================================================
        lv_step := 'STEP-08510';
        proc_item_update(
          in_item_id            =>  i_update_item_rec.item_id              -- OPM品目ID
         ,in_inventory_item_id  =>  i_update_item_rec.inventory_item_id    -- Disc品目ID
         ,iv_item_no            =>  i_update_item_rec.item_no              -- 品目コード
         ,iv_policy_group       =>  lv_policy_group_parent                 -- 政策群コード
         ,in_fixed_price        =>  ln_fixed_price_parent                  -- 定価
         ,in_discrete_cost      =>  ln_discrete_cost_parent                -- 営業原価
         ,in_organization_id    =>  gn_cost_org_id                         -- Disc品目原価組織ID
         ,iv_apply_date         =>  TO_CHAR( i_update_item_rec.apply_date, cv_date_fmt_std ) 
                                                                           -- 適用日
         ,ov_errbuf             =>  lv_errbuf                              -- エラー・メッセージ           --# 固定 #
         ,ov_retcode            =>  lv_retcode                             -- リターン・コード             --# 固定 #
         ,ov_errmsg             =>  lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          --
          RAISE sub_proc_expt;
        END IF;
      END IF;
    END IF;
    --
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
    -- *** データ登録エラー(品目共通API)例外ハンドラ ***
    WHEN item_common_ins_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00444            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                     ,iv_token_value3 => lv_errmsg                     -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ抽出例外ハンドラ ***
    WHEN data_select_err_expt THEN
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00442            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_data_info              -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                    );
      --
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg || cv_msg_space|| lv_msg_errm;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ更新例外ハンドラ ***
    WHEN data_update_err_expt THEN
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00445            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                     ,iv_token_value3 => lv_msg_errm                   -- トークン値3
                    );
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END proc_inherit_parent;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : データ妥当性チェック
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,iv_item_status_name   IN     VARCHAR2
   ,ov_errbuf             OUT    VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode            OUT    VARCHAR2                                        -- リターン・コード
   ,ov_errmsg             OUT    VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'VALIDATE_ITEM';      -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_product_com             CONSTANT VARCHAR2(1)   := '1';                  -- 商品(1)
    cv_head_product_drink      CONSTANT VARCHAR2(1)   := '2';                  -- ドリンク(2)
    --
    cv_validate_info           CONSTANT VARCHAR2(20)  := '品目チェック情報';
    cv_item_name_alt           CONSTANT VARCHAR2(20)  := 'カナ';
    cv_sales_div               CONSTANT VARCHAR2(20)  := '売上対象';
    cv_parent_item             CONSTANT VARCHAR2(20)  := '親商品コード';
    cv_fixed_price             CONSTANT VARCHAR2(20)  := '定価';
    cv_num_of_cases            CONSTANT VARCHAR2(20)  := 'ケース入数';
    cv_item_um                 CONSTANT VARCHAR2(20)  := '基準単位';
    cv_rate_class              CONSTANT VARCHAR2(20)  := '率区分';
    cv_net                     CONSTANT VARCHAR2(20)  := 'ＮＥＴ';
    cv_unit                    CONSTANT VARCHAR2(20)  := '重量/体積';
    cv_nets                    CONSTANT VARCHAR2(20)  := '内容量';
    cv_nets_uom_code           CONSTANT VARCHAR2(20)  := '内容量単位';
    cv_inc_num                 CONSTANT VARCHAR2(20)  := '内訳入数';
    cv_baracha_div             CONSTANT VARCHAR2(20)  := 'バラ茶区分';
    cv_item_product            CONSTANT VARCHAR2(20)  := '商品製品区分';
    cv_head_product            CONSTANT VARCHAR2(20)  := '本社商品区分';
    cv_discrete_cost           CONSTANT VARCHAR2(20)  := '営業原価';
    cv_policy_group            CONSTANT VARCHAR2(20)  := '政策群';
    cv_opmcost                 CONSTANT VARCHAR2(20)  := '標準原価';
    cv_sp_supplier_code        CONSTANT VARCHAR2(20)  := '専門店仕入先';
    cv_palette_max_cs_qty      CONSTANT VARCHAR2(20)  := '配数';
    cv_palette_max_step_qty    CONSTANT VARCHAR2(20)  := '段数';
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                    VARCHAR2(10);
    lv_msg_token               VARCHAR2(100);
    --
    ln_exists_cnt              NUMBER;
    lv_item_product            mtl_categories.segment1%TYPE;
    lv_head_product            mtl_categories.segment1%TYPE;
    --
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
    ln_cmpnt_cost_sum          cm_cmpt_dtl.cmpnt_cost%TYPE;
-- End1.9
--
-- 2009/10/16 Ver1.13 障害0001423 add start by Y.Kuboshima
    lv_parent_code             ic_item_mst_b.item_no%TYPE;            -- 親品目コード
    ln_parent_status           xxcmm_system_items_b.item_status%TYPE; -- 親品目ステータス
    lv_parent_status_name      fnd_lookup_values.meaning%TYPE;        -- 親品目ステータス名
-- 2009/10/16 Ver1.13 障害0001423 add end by Y.Kuboshima
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    data_validate_expt         EXCEPTION;    -- データチェックエラー
-- Ver1.5 チェック処理追加
    child_status_chk_expt      EXCEPTION;    -- 子品目ステータスチェックエラー
    parent_status_chk_expt     EXCEPTION;    -- 親品目ステータスチェックエラー
-- End
    --
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
    opm_cost_chk_expt          EXCEPTION;    -- 標準原価0円エラー
    disc_cost_chk_expt         EXCEPTION;    -- 営業原価エラー
-- End1.9
    --
-- 2009/08/10 Ver1.11 障害0000862 add start by Y.Kuboshima
    cost_decimal_chk_expt      EXCEPTION;    -- 標準原価小数エラー
-- 2009/08/10 Ver1.11 障害0000862 add end by Y.Kuboshima
    --
-- 2009/10/16 Ver1.13 障害0001423 add start by Y.Kuboshima
    parent_st_regist_chk_expt  EXCEPTION;    -- 親品目本登録ステータスチェックエラー
-- 2009/10/16 Ver1.13 障害0001423 add start by Y.Kuboshima
    --
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
-- Ver1.5 チェック処理追加
    -- 親品目のステータスをＤに変更時、子品目のステータスが全てＤであること
    IF  ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id )
    AND ( i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
      --
      lv_step := 'STEP-07010';
      -- 子品目のステータスチェック
      SELECT      COUNT( xoiv.item_id )
      INTO        ln_exists_cnt
      FROM        xxcmm_opmmtl_items_v      xoiv                                -- 品目ビュー
      WHERE       xoiv.parent_item_id     = i_update_item_rec.item_id           -- 親品目ID
      AND         xoiv.item_id           != i_update_item_rec.item_id           -- 親品目以外
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )                    -- 適用開始日
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE )                    -- 適用終了日
      AND         xoiv.start_date_active <= gd_process_date                     -- 適用開始日
      AND         xoiv.end_date_active   >= gd_process_date                     -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
      AND         NVL( xoiv.item_status, cn_itm_status_num_tmp )
                                         != cn_itm_status_no_use                -- Ｄ以外
      AND         ROWNUM = 1;
      --
      IF ( ln_exists_cnt = 1 ) THEN
        RAISE child_status_chk_expt;
      END IF;
      --
    -- 子品目のステータス変更時、親品目のステータスがＤでないこと
    --  仮採番、仮登録時には子品目の作成はできないためチェックしない。
    ELSIF ( i_update_item_rec.item_id != i_update_item_rec.parent_item_id )
    AND   ( i_update_item_rec.item_status != cn_itm_status_no_use ) THEN
      --
      lv_step := 'STEP-07020';
-- 2009/10/16 Ver1.13 障害0001423 modify start by Y.Kuboshima
--      -- 親品目のステータスチェック
--      SELECT      COUNT( xoiv.item_id )
--      INTO        ln_exists_cnt
--      FROM        xxcmm_opmmtl_items_v      xoiv                                -- 品目ビュー
--      WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id    -- 親品目
---- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
----      AND         xoiv.start_date_active <= TRUNC( SYSDATE )                    -- 適用開始日
----      AND         xoiv.end_date_active   >= TRUNC( SYSDATE )                    -- 適用終了日
--      AND         xoiv.start_date_active <= gd_process_date                     -- 適用開始日
--      AND         xoiv.end_date_active   >= gd_process_date                     -- 適用終了日
---- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
--      AND         xoiv.item_status        = cn_itm_status_no_use                -- Ｄ以外
--      AND         ROWNUM = 1;
--      --
--      IF ( ln_exists_cnt = 1 ) THEN
--        RAISE parent_status_chk_expt;
--      END IF;
      -- 本登録にステータス変更時、親品目のステータスが本登録以外の場合はエラー
      IF (i_update_item_rec.item_status = cn_itm_status_regist ) THEN
        BEGIN
          -- 親品目コード、親品目ステータス取得
          SELECT xoiv.item_no
                ,xoiv.item_status
                ,flvv.meaning
          INTO   lv_parent_code
                ,ln_parent_status
                ,lv_parent_status_name
          FROM   xxcmm_opmmtl_items_v xoiv
                ,fnd_lookup_values_vl flvv
          WHERE  TO_CHAR(xoiv.item_status) = flvv.lookup_code
          AND    xoiv.item_id              = i_update_item_rec.parent_item_id    -- 親品目
          AND    xoiv.start_date_active   <= gd_process_date                     -- 適用開始日
          AND    xoiv.end_date_active     >= gd_process_date                     -- 適用終了日
          AND    flvv.lookup_type          = cv_lookup_item_status
          AND    ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            lv_parent_code        := NULL;
            ln_parent_status      := -1;
            lv_parent_status_name := NULL;
        END;
        --
        -- 親品目のステータスチェック
        -- 本登録以外の場合はエラー
        IF ( ln_parent_status <> cn_itm_status_regist ) THEN
          RAISE parent_st_regist_chk_expt;
        END IF;
      -- 本登録以外にステータス変更時、親品目のステータスがＤの場合はエラー
      ELSE
        -- 親品目のステータスチェック
        SELECT      COUNT( xoiv.item_id )
        INTO        ln_exists_cnt
        FROM        xxcmm_opmmtl_items_v      xoiv                                -- 品目ビュー
        WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id    -- 親品目
        AND         xoiv.start_date_active <= gd_process_date                     -- 適用開始日
        AND         xoiv.end_date_active   >= gd_process_date                     -- 適用終了日
        AND         xoiv.item_status        = cn_itm_status_no_use                -- Ｄ
        AND         ROWNUM = 1;
        --
        IF ( ln_exists_cnt = 1 ) THEN
          RAISE parent_status_chk_expt;
        END IF;
      END IF;
-- 2009/10/16 Ver1.13 障害0001423 modify end by Y.Kuboshima
    END IF;
-- End
    --
    -- 変更前ステータスがNULL、仮採番、仮登録、Ｄ
    -- 変更後ステータスが仮登録、本登録、廃、Ｄ’の場合チェックする。
    lv_step := 'STEP-07100';
    IF  ( NVL( i_update_item_rec.b_item_status, cn_itm_status_num_tmp ) IN ( cn_itm_status_num_tmp      -- 仮採番
                                                                           , cn_itm_status_pre_reg      -- 仮登録
                                                                           , cn_itm_status_no_use ) )   -- Ｄ
    AND ( i_update_item_rec.item_status IN ( cn_itm_status_pre_reg              -- 仮登録
                                           , cn_itm_status_regist               -- 本登録
                                           , cn_itm_status_no_sch               -- 廃
                                           , cn_itm_status_trn_only ) ) THEN    -- Ｄ’
      --=====================================================================================
      -- 変更適用反映が可能かチェック
      -- ・仮登録以降：子品目 カナ、売上対象、親商品 必須
      --                      ※親商品が設定されていれば他項目も設定されている想定。
      -- ・仮登録以降：親品目 定価（変更適用）
      --                      カナ、売上対象、親商品
      --                      ケース入数、基準単位、商品製品区分
      --                      NET、重量/体積、内容量、内容量単位
      --                      内訳入数、本社商品区分、バラ茶区分
      -- ・本登録以降：親品目 営業原価、政策群コード（変更適用）
      --                      標準原価、専門店仕入先(商品の場合のみ)
      --                      配数(ドリンクの場合のみ)、段数(ドリンクの場合のみ)
      --=====================================================================================
      -------------------------
      -- チェック処理
      -------------------------
      -- カナ名
      lv_step := 'STEP-07110';
      IF ( i_update_item_rec.item_name_alt IS NULL ) THEN
        lv_msg_token := cv_item_name_alt;
        RAISE data_validate_expt;
      END IF;
      --
      -- 売上対象区分
      lv_step := 'STEP-07120';
      IF ( i_update_item_rec.sales_div IS NULL ) THEN
        lv_msg_token := cv_sales_div;
        RAISE data_validate_expt;
      END IF;
      --
      -- 親品目ID
      lv_step := 'STEP-07130';
      IF ( i_update_item_rec.parent_item_id IS NULL ) THEN
        lv_msg_token := cv_parent_item;
        RAISE data_validate_expt;
      END IF;
      --
      -- 親品目の場合
      IF ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id ) THEN
        --
        lv_step := 'STEP-07210';
        BEGIN
          -- 商品製品区分の取得
          SELECT      mcv.segment1             item_product                 -- 商品製品区分
          INTO        lv_item_product                                       -- 商品製品区分
          FROM        gmi_item_categories      gic                          -- OPM品目カテゴリ割当（商品製品区分）
                     ,mtl_category_sets_vl     mcsv                         -- カテゴリセットビュー（商品製品区分）
                     ,mtl_categories_vl        mcv                          -- カテゴリビュー（商品製品区分）
          WHERE       mcsv.category_set_name = cv_categ_set_item_prod       -- 商品製品区分
          AND         gic.item_id            = i_update_item_rec.item_id    -- 品目
          AND         gic.category_set_id    = mcsv.category_set_id         -- カテゴリセットID
          AND         gic.category_id        = mcv.category_id;             -- カテゴリID
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_item_product := NULL;
        END;
        --
        lv_step := 'STEP-07220';
        BEGIN
          -- 本社商品区分
          SELECT      mcv.segment1             head_product                 -- 本社商品区分
          INTO        lv_head_product                                       -- 本社商品区分
          FROM        gmi_item_categories      gic                          -- OPM品目カテゴリ割当（本社商品区分）
                     ,mtl_category_sets_vl     mcsv                         -- カテゴリセットビュー（本社商品区分）
                     ,mtl_categories_vl        mcv                          -- カテゴリビュー（本社商品区分）
          WHERE       mcsv.category_set_name = cv_categ_set_hon_prod        -- 本社商品区分
          AND         gic.item_id            = i_update_item_rec.item_id    -- 品目
          AND         gic.category_set_id    = mcsv.category_set_id         -- カテゴリセットID
          AND         gic.category_id        = mcv.category_id;             -- カテゴリID
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_head_product := NULL;
        END;
        --
        -- 変更前ステータスは、NULL、仮採番、仮登録、Ｄのみ
        -- 変更後ステータスは、仮登録、本登録、廃、Ｄ’のみ
        --  まとめ
        --    変更前ステータス   変更後ステータス   仮登録   本登録   備考
        --    NULL               仮採番               ×       ×     
        --    NULL               仮登録               ○       ×     
        --    NULL               本登録               ○       ○     
        --    NULL               廃                   ○       ○     
        --    NULL               Ｄ’                 ○       ○     
        --    仮採番             仮登録               ○       ×     
        --    仮採番             本登録               ○       ○     
        --    仮採番             廃                   ○       ○     
        --    仮採番             Ｄ’                 ○       ○     
        --    仮登録             本登録               ×       ○     仮登録チェックを実施してもよい
        --    仮登録             廃                   ×       ○     仮登録チェックを実施してもよい
        --    仮登録             Ｄ’                 ×       ○     仮登録チェックを実施してもよい
        --    本登録以降         －                   ×       ×     
        --    Ｄ                 本登録               ○       ○     
        --    Ｄ                 廃                   ○       ○     
        --    Ｄ                 Ｄ’                 ○       ○     
        --
        -- 変更前ステータスが『仮登録』以外(NULL, 仮採番, Ｄ)の場合
        -- 仮登録時のチェックを実施する。
-- Ver1.9  2009/07/06  Mod  変更前ステータスがNULL時チェックされないため。
--        IF ( i_update_item_rec.b_item_status != cn_itm_status_pre_reg ) THEN
        IF ( NVL( i_update_item_rec.b_item_status, cn_itm_status_num_tmp ) != cn_itm_status_pre_reg ) THEN
-- End1.9
          --------------------------------------
          -- 仮登録チェック
          --------------------------------------
          -- 定価
          lv_step := 'STEP-07310';
          IF (   i_update_item_rec.price_new   IS NULL
             AND i_update_item_rec.fixed_price IS NULL ) THEN
            lv_msg_token := cv_fixed_price;
            RAISE data_validate_expt;
          END IF;
          --
          -- ケース入数
          lv_step := 'STEP-07320';
          IF ( i_update_item_rec.num_of_cases IS NULL ) THEN
            lv_msg_token := cv_num_of_cases;
            RAISE data_validate_expt;
          END IF;
          --
          -- 単位
          lv_step := 'STEP-07330';
          IF ( i_update_item_rec.item_um IS NULL ) THEN
            lv_msg_token := cv_item_um;
            RAISE data_validate_expt;
          END IF;
          --
-- Ver1.3 2009/01/29 ADD 率区分を必須項目に追加
          -- 率区分
          lv_step := 'STEP-07340';
          IF ( i_update_item_rec.rate_class IS NULL ) THEN
            lv_msg_token := cv_rate_class;
            RAISE data_validate_expt;
          END IF;
-- End
          -- NET
          lv_step := 'STEP-07350';
          IF ( i_update_item_rec.net IS NULL ) THEN
            lv_msg_token := cv_net;
            RAISE data_validate_expt;
          END IF;
          --
          -- 重量/体積
          lv_step := 'STEP-07360';
          IF ( i_update_item_rec.unit IS NULL ) THEN
            lv_msg_token := cv_unit;
            RAISE data_validate_expt;
          END IF;
          --
          -- 内容量
          lv_step := 'STEP-07370';
          IF ( i_update_item_rec.nets IS NULL ) THEN
            lv_msg_token := cv_nets;
            RAISE data_validate_expt;
          END IF;
          --
          -- 内容量単位
          lv_step := 'STEP-07380';
          IF ( i_update_item_rec.nets_uom_code IS NULL ) THEN
            lv_msg_token := cv_nets_uom_code;
            RAISE data_validate_expt;
          END IF;
          --
          -- 内訳入数
          lv_step := 'STEP-07390';
          IF ( i_update_item_rec.inc_num IS NULL ) THEN
            lv_msg_token := cv_inc_num;
            RAISE data_validate_expt;
          END IF;
          --
          -- バラ茶区分
          lv_step := 'STEP-07400';
          IF ( i_update_item_rec.baracha_div IS NULL ) THEN
            lv_msg_token := cv_baracha_div;
            RAISE data_validate_expt;
          END IF;
          --
          -- 商品製品区分
          lv_step := 'STEP-07410';
          IF ( lv_item_product IS NULL ) THEN
            lv_msg_token := cv_item_product;
            RAISE data_validate_expt;
          END IF;
          --
          -- 本社商品区分
          lv_step := 'STEP-07420';
          IF ( lv_head_product IS NULL ) THEN
            lv_msg_token := cv_head_product;
            RAISE data_validate_expt;
          END IF;
          --
        END IF;
        --
        -- 変更後ステータスが『仮登録』以外(本登録, 廃, Ｄ’)の場合
        -- 本登録時のチェックを実施する。
        IF ( i_update_item_rec.item_status != cn_itm_status_pre_reg ) THEN
          --------------------------------------
          -- 本登録チェック
          --------------------------------------
          -- 営業原価
          lv_step := 'STEP-07510';
          IF (   i_update_item_rec.opt_cost_new  IS NULL
             AND i_update_item_rec.discrete_cost IS NULL ) THEN
            lv_msg_token := cv_discrete_cost;
            RAISE data_validate_expt;
          END IF;
          --
          -- 政策群コード
          lv_step := 'STEP-07520';
          IF (   i_update_item_rec.crowd_code_new  IS NULL
             AND i_update_item_rec.policy_group    IS NULL ) THEN
            lv_msg_token := cv_policy_group;
            RAISE data_validate_expt;
          END IF;
          --
-- Ver1.9  2009/07/06  Del  障害対応(0000364)
--          -- 標準原価
--          lv_step := 'STEP-07530';
--          SELECT    COUNT( ccmd.cmpntcost_id )
--          INTO      ln_exists_cnt
--          FROM      cm_cmpt_dtl                ccmd                          -- OPM標準原価
--                   ,cm_cldr_dtl                cclr                          -- OPM原価カレンダ
--                   ,cm_cmpt_mst_vl             ccmv                          -- 原価コンポーネント
--                   ,fnd_lookup_values_vl       flv                           -- 参照コード値
--          WHERE     ccmd.item_id             = i_update_item_rec.item_id     -- 品目ID
--          AND       cclr.start_date         <= i_update_item_rec.apply_date  -- 開始日
--          AND       cclr.end_date           >= i_update_item_rec.apply_date  -- 終了日
--          AND       flv.lookup_type          = cv_lookup_cost_cmpt           -- 参照タイプ
--          AND       flv.enabled_flag         = cv_yes                        -- 使用可能
--          AND       ccmv.cost_cmpntcls_code  = flv.meaning                   -- 原価コンポーネントコード
--          AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id         -- 原価コンポーネントID
--          AND       ccmd.calendar_code       = cclr.calendar_code            -- カレンダコード
--          AND       ccmd.period_code         = cclr.period_code              -- 期間コード
--          AND       ccmd.whse_code           = cv_whse_code                  -- 倉庫
--          AND       ccmd.cost_mthd_code      = cv_cost_mthd_code             -- 原価方法
--          AND       ccmd.cost_analysis_code  = cv_cost_analysis_code         -- 分析コード
--          AND       ROWNUM                   = 1;
--          --
--          IF ( ln_exists_cnt = 0 ) THEN
--            lv_msg_token := cv_opmcost;
--            RAISE data_validate_expt;
--          END IF;
-- End1.9
          --
          -- 商品製品区分 = 「商品」の場合必須
          -- 専門店仕入先
          lv_step := 'STEP-07540';
          IF  ( lv_item_product = cv_product_com ) 
          AND ( i_update_item_rec.sp_supplier_code IS NULL ) THEN
            lv_msg_token := cv_sp_supplier_code;
            RAISE data_validate_expt;
          END IF;
          --
          -- 本社商品区分 = 「ドリンク」の場合必須
          IF ( lv_head_product = cv_head_product_drink ) THEN
            -- 配数
            lv_step := 'STEP-07550';
            IF ( i_update_item_rec.palette_max_cs_qty IS NULL ) THEN
              lv_msg_token := cv_palette_max_cs_qty;
              RAISE data_validate_expt;
            END IF;
            --
            -- 段数
            lv_step := 'STEP-07560';
            IF ( i_update_item_rec.palette_max_step_qty IS NULL ) THEN
              lv_msg_token := cv_palette_max_step_qty;
              RAISE data_validate_expt;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
    --
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
    -- 親品目の場合、標準原価が正常に登録されているか
    -- また、営業原価の予約の場合
    IF  ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id ) THEN
      --
      -- 標準原価計の取得
      SELECT    COUNT( ccmd.cmpntcost_id )
               ,SUM( ccmd.cmpnt_cost )
      INTO      ln_exists_cnt
               ,ln_cmpnt_cost_sum
      FROM      cm_cmpt_dtl                ccmd                          -- OPM標準原価
               ,cm_cldr_dtl                cclr                          -- OPM原価カレンダ
               ,cm_cmpt_mst_vl             ccmv                          -- 原価コンポーネント
               ,fnd_lookup_values_vl       flv                           -- 参照コード値
      WHERE     ccmd.item_id             = i_update_item_rec.item_id     -- 品目ID
      AND       cclr.start_date         <= i_update_item_rec.apply_date  -- 開始日
      AND       cclr.end_date           >= i_update_item_rec.apply_date  -- 終了日
      AND       flv.lookup_type          = cv_lookup_cost_cmpt           -- 参照タイプ
      AND       flv.enabled_flag         = cv_yes                        -- 使用可能
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                   -- 原価コンポーネントコード
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id         -- 原価コンポーネントID
      AND       ccmd.calendar_code       = cclr.calendar_code            -- カレンダコード
      AND       ccmd.period_code         = cclr.period_code              -- 期間コード
      AND       ccmd.whse_code           = cv_whse_code                  -- 倉庫
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code             -- 原価方法
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code;        -- 分析コード
      --
      IF ( i_update_item_rec.item_status IN ( cn_itm_status_regist               -- 本登録
                                            , cn_itm_status_no_sch               -- 廃
                                            , cn_itm_status_trn_only ) ) THEN    -- Ｄ’
        --
        -- 原価コンポーネント未登録時はエラー
        IF ( ln_exists_cnt = 0 ) THEN
          lv_msg_token := cv_opmcost;
          RAISE data_validate_expt;
        -- 標準原価 = 0 の場合エラー
        ELSIF ( ln_cmpnt_cost_sum = 0 ) THEN
          RAISE opm_cost_chk_expt;
-- 2009/08/10 Ver1.11 障害0000862 add start by Y.Kuboshima
        ELSE
          -- 資材品目の場合
          IF ( SUBSTRB( i_update_item_rec.item_no, 1, 1 ) IN ( cv_leaf_material, cv_drink_material )  ) THEN
            -- 標準原価が小数点三桁以上の場合
            IF ( ln_cmpnt_cost_sum <> TRUNC( ln_cmpnt_cost_sum, 2 ) ) THEN
              -- 標準原価エラー
              RAISE cost_decimal_chk_expt;
            END IF;
          -- 資材品目以外の場合
          ELSE
            -- 標準原価が整数以外の場合
            IF ( ln_cmpnt_cost_sum <> TRUNC( ln_cmpnt_cost_sum ) ) THEN
              -- 標準原価エラー
              RAISE cost_decimal_chk_expt;
            END IF;
          END IF;
-- 2009/08/10 Ver1.11 障害0000862 add end by Y.Kuboshima
        END IF;
        --
      END IF;
      --
      IF ( i_update_item_rec.discrete_cost IS NOT NULL ) THEN
        -- 営業原価 < 標準原価 の場合エラー
        IF ( i_update_item_rec.discrete_cost < ln_cmpnt_cost_sum ) THEN
          RAISE disc_cost_chk_expt;
        END IF;
      END IF;
      --
    END IF;
-- End1.9
    --
  EXCEPTION
--
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
    -- *** 標準原価0円チェック例外ハンドラ ***
    WHEN opm_cost_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00432                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item_code                      -- トークンコード1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** 営業原価チェック例外ハンドラ ***
    WHEN disc_cost_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00433                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_disc_cost                      -- トークンコード1
                     ,iv_token_value1 => TO_CHAR( i_update_item_rec.discrete_cost )
                                                                               -- トークン値1
                     ,iv_token_name2  => cv_tkn_opm_cost                       -- トークンコード2
                     ,iv_token_value2 => TO_CHAR( ln_cmpnt_cost_sum )          -- トークン値2
                     ,iv_token_name3  => cv_tkn_item_code                      -- トークンコード3
                     ,iv_token_value3 => i_update_item_rec.item_no             -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- End1.9
--
-- Ver1.5 チェック処理追加
    -- *** 子品目ステータスチェック例外ハンドラ ***
    WHEN child_status_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00436                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item_code                      -- トークンコード1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_status                    -- トークンコード2
                     ,iv_token_value2 => iv_item_status_name                   -- トークン値2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** 親品目ステータスチェック例外ハンドラ ***
    WHEN parent_status_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00437                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item_code                      -- トークンコード1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_status                    -- トークンコード2
                     ,iv_token_value2 => iv_item_status_name                   -- トークン値2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- End
--
--
-- 2009/10/16 Ver1.13 障害0001423 add start by Y.Kuboshima
    -- *** 親品目本登録ステータスチェック例外ハンドラ ***
    WHEN parent_st_regist_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00492                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item_code                      -- トークンコード1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- トークン値1
                     ,iv_token_name2  => cv_tkn_parent_item                    -- トークンコード2
                     ,iv_token_value2 => lv_parent_code                        -- トークン値2
                     ,iv_token_name3  => cv_tkn_item_status                    -- トークンコード3
                     ,iv_token_value3 => lv_parent_status_name                 -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- 2009/10/16 Ver1.13 障害0001423 add end by Y.Kuboshima
--
-- 2009/08/10 Ver1.11 障害0000862 add start by Y.Kuboshima
    -- *** 標準原価小数チェック例外ハンドラ ***
    WHEN cost_decimal_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00491                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_opm_cost                       -- トークンコード1
                     ,iv_token_value1 => TO_CHAR( ln_cmpnt_cost_sum )          -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code                      -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no             -- トークン値2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- 2009/08/10 Ver1.11 障害0000862 add end by Y.Kuboshima
--
    -- *** データチェック例外ハンドラ ***
    WHEN data_validate_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00450                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_data_info                      -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                          -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code                      -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no             -- トークン値2
                     ,iv_token_name3  => cv_tkn_item_status                    -- トークンコード3
                     ,iv_token_value3 => iv_item_status_name                   -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : proc_item_status_update
   * Description      : 品目ステータス反映処理(A-5)
   **********************************************************************************/
  PROCEDURE proc_item_status_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2             --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT    VARCHAR2             --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT    VARCHAR2             --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_ITEM_STATUS_UPDATE'; -- プログラム名
-- 2009/09/11 Ver1.12 障害0000948 add start by Y.Kuboshima
    cv_uom_class_conv_to         CONSTANT VARCHAR2(10) := 'CS';
-- 2009/09/11 Ver1.12 障害0000948 add end by Y.Kuboshima
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);     -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
    cn_process_flag              CONSTANT NUMBER(1)    := 1;
    cv_tran_type_create          CONSTANT VARCHAR2(10) := 'CREATE';          -- 新規登録
    cv_tran_type_update          CONSTANT VARCHAR2(10) := 'UPDATE';          -- 更新
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    lv_msg_errm                  VARCHAR2(4000);
    --
    lv_transaction_type          mtl_system_items_interface.transaction_type%TYPE;

    ln_exsits_count              NUMBER;
    --
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
    ln_cmp_cost_index            NUMBER;
-- END1.9
-- 2009/12/24 Ver1.14 障害E_本稼動_00577 add start by Shigeto.Niki
    ln_location_control_code     mtl_system_items_interface.location_control_code%TYPE;
-- 2009/12/24 Ver1.14 障害E_本稼動_00577 add end by Shigeto.Niki
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 品目ステータス関連情報取得カーソル
    CURSOR item_status_info_cur(
      pv_item_status    VARCHAR2 )
    IS
      SELECT     flvv.lookup_code    AS item_status_code                 -- 品目ステータス
                ,flvv.meaning        AS item_status_name                 -- 品目ステータス名
                ,flvv.attribute6     AS returnable_flag                  -- 返品可能
                ,flvv.attribute7     AS stock_enabled_flag               -- 在庫保有可能
                ,flvv.attribute8     AS mtl_transactions_enabled_flag    -- 取引可能
                ,flvv.attribute9     AS customer_order_enabled_flag      -- 顧客受注可能
--                ,flvv.attribute10    AS rate_class                       -- 率区分
                ,flvv.attribute11    AS obsolete_class                   -- 廃止区分
      FROM       fnd_lookup_values_vl    flvv
      WHERE      flvv.lookup_type = cv_lookup_item_status
      AND        flvv.lookup_code = pv_item_status;
      --
    -- OPM品目アドオンロックカーソル
    CURSOR xxcmn_item_lock_cur(
      pn_item_id    NUMBER )
    IS
      SELECT      'x'
      FROM        xxcmn_item_mst_b
      WHERE       item_id            = pn_item_id
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--      AND         start_date_active <= TRUNC(SYSDATE)
--      AND         end_date_active   >= TRUNC(SYSDATE)
      AND         start_date_active <= gd_process_date
      AND         end_date_active   >= gd_process_date
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
      FOR UPDATE NOWAIT;
      --
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
    -- 標準原価ヘッダ抽出カーソル
    CURSOR cnp_cost_hd_par_cur(
      pd_apply_date      DATE )
    IS
      SELECT    cclr.calendar_code            -- カレンダコード
               ,cclr.period_code              -- 期間コード
      FROM      cm_cldr_dtl          cclr     -- OPM原価カレンダ
      WHERE     cclr.start_date         <= pd_apply_date    -- 開始日
      AND       cclr.end_date           >= pd_apply_date    -- 終了日
      ORDER BY  cclr.calendar_code
               ,cclr.period_code;
    --
    -- 標準原価明細抽出カーソル
    CURSOR cnp_noext_cost_dt_cur(
      pn_item_id         NUMBER
     ,pv_calendar_code   VARCHAR2
     ,pv_period_code     VARCHAR2 )
    IS
      SELECT    cclr.calendar_code            -- カレンダコード
               ,cclr.period_code              -- 期間コード
               ,ccmv.cost_cmpntcls_id         -- 原価コンポーネントID
               ,ccmv.cost_cmpntcls_code       -- 原価コンポーネントコード
      FROM      cm_cldr_dtl          cclr     -- OPM原価カレンダ
               ,cm_cmpt_mst_vl       ccmv     -- 原価コンポーネント
               ,fnd_lookup_values_vl flv      -- 参照コード値
      WHERE     cclr.calendar_code       = pv_calendar_code             -- カレンダコード
      AND       cclr.period_code         = pv_period_code               -- 期間コード
      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- 参照タイプ
      AND       flv.enabled_flag         = cv_yes                       -- 使用可能
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- 原価コンポーネントコード
      AND NOT EXISTS(
                  SELECT    'x'
                  FROM      cm_cmpt_dtl    ccmd      -- OPM標準原価
                  WHERE     ccmd.item_id             = pn_item_id               -- 品目
                  AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id    -- 原価コンポーネントID
                  AND       ccmd.calendar_code       = cclr.calendar_code       -- カレンダコード
                  AND       ccmd.period_code         = cclr.period_code         -- 期間コード
                  AND       ccmd.whse_code           = cv_whse_code             -- 倉庫
                  AND       ccmd.cost_mthd_code      = cv_cost_mthd_code        -- 原価方法
                  AND       ccmd.cost_analysis_code  = cv_cost_analysis_code    -- 分析コード
                )
      ORDER BY  ccmv.cost_cmpntcls_code;
    --
-- 2009/09/11 Ver1.12 障害0000948 add start by Y.Kuboshima
    -- 基準単位抽出カーソル
    CURSOR units_of_measure_cur(
      pv_item_um IN VARCHAR2 )
    IS
      SELECT     flvv.attribute1              -- 単位換算作成フラグ
      FROM       fnd_lookup_values_vl flvv
      WHERE      flvv.lookup_type  = cv_lookup_item_um
      AND        flvv.enabled_flag = cv_yes
      AND        flvv.meaning      = pv_item_um;
    --
    -- 基準単位抽出レコード型
    l_units_of_measure_rec       units_of_measure_cur%ROWTYPE;
-- 2009/09/11 Ver1.12 障害0000948 add end by Y.Kuboshima
    --
-- END1.9
    -- <カーソル名>レコード型
    l_item_status_info_rec       item_status_info_cur%ROWTYPE;
    --
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
    -- OPM標準原価用
    l_opm_cost_header_rec        xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab          xxcmm_004common_pkg.opm_cost_dist_ttype;
-- END1.9
    --
-- 2009/09/11 Ver1.12 障害0000948 add start by Y.Kuboshima
    -- 単位換算用
    l_uom_class_conv_rec         xxcmm_004common_pkg.uom_class_conv_rtype;
-- 2009/09/11 Ver1.12 障害0000948 add end by Y.Kuboshima
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    sub_proc_expt                EXCEPTION;
    data_select_err_expt         EXCEPTION;    -- データ抽出エラー
    data_insert_err_expt         EXCEPTION;    -- データ登録エラー
    data_update_err_expt         EXCEPTION;    -- データ更新エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-5 品目ステータス情報反映
    --==============================================================
    lv_step := 'STEP-06010';
    -- 品目ステータス情報取得
    OPEN  item_status_info_cur( TO_CHAR( i_update_item_rec.item_status ) );
    --
    lv_step := 'STEP-06020';
    FETCH item_status_info_cur INTO l_item_status_info_rec;
    --
    IF item_status_info_cur%NOTFOUND THEN
      CLOSE item_status_info_cur;
      lv_msg_token := cv_tkn_val_item_status;
      RAISE data_select_err_expt;  -- 抽出エラー
    END IF;
    --
    lv_step := 'STEP-06030';
    CLOSE item_status_info_cur;
    --
    --==============================================================
    -- データ妥当性チェック
    --==============================================================
    lv_step := 'STEP-06040';
    validate_item(
      i_update_item_rec    =>  i_update_item_rec    -- 品目変更適用情報
     ,iv_item_status_name  =>  l_item_status_info_rec.item_status_name
                                                    -- 品目ステータス名称
     ,ov_errbuf            =>  lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           =>  lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg            =>  lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    ELSE
      --==============================================================
      --A-5.2 OPM品目アドオンのロック取得
      --==============================================================
      -- OPM品目アドオンロック
      lv_step := 'STEP-06050';
      lv_msg_token := cv_tkn_val_xxcmn_opmitem;
      --
      OPEN  xxcmn_item_lock_cur( i_update_item_rec.item_id );
      CLOSE xxcmn_item_lock_cur;
      --
      --==============================================================
      --A-5.2 OPM品目アドオンの更新
      --==============================================================
      BEGIN
        IF ( i_update_item_rec.parent_item_id IS NULL 
          OR i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
          --
          -- 親品目未設定時、または、品目ステータスがＤの場合は親品目情報から更新しない。
          lv_step := 'STEP-06060';
          UPDATE      xxcmn_item_mst_b
                      -- 廃止区分
          SET         obsolete_class          = l_item_status_info_rec.obsolete_class
                      -- 廃止日
                     ,obsolete_date           = DECODE( i_update_item_rec.item_status
                                                       ,cn_itm_status_no_use, i_update_item_rec.apply_date, NULL )
                     ,last_updated_by         = cn_last_updated_by
                     ,last_update_date        = cd_last_update_date
                     ,last_update_login       = cn_last_update_login
                     ,request_id              = cn_request_id
                     ,program_application_id  = cn_program_application_id
                     ,program_id              = cn_program_id
                     ,program_update_date     = cd_program_update_date
                      --
          WHERE       item_id                 = i_update_item_rec.item_id
-- Ver1.1 2009/01/14 MOD テストシナリオ 5-6
--          AND         active_flag             = cv_yes
-- Ver1.1 End
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--          AND         start_date_active      <= TRUNC( SYSDATE )
--          AND         end_date_active        >= TRUNC( SYSDATE );
          AND         start_date_active      <= gd_process_date
          AND         end_date_active        >= gd_process_date;
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
          --
        ELSE
          -- 親品目設定時、かつ、品目ステータスがＤ以外の場合、
          -- 親品目情報から商品分類、配数、段数を設定する（親品目の場合実質更新されない。）
          lv_step := 'STEP-06070';
          UPDATE      xxcmn_item_mst_b
          SET       ( obsolete_class           -- 廃止区分
                     ,obsolete_date            -- 廃止日
                     ,product_class            -- 商品分類
                     ,palette_max_cs_qty       -- 配数
                     ,palette_max_step_qty     -- 段数
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,request_id
                     ,program_application_id
                     ,program_id
                     ,program_update_date )
                 = (  SELECT      -- 廃止区分
                                  l_item_status_info_rec.obsolete_class
                                  -- 廃止日
                                 ,DECODE( i_update_item_rec.item_status
                                         ,cn_itm_status_no_use, i_update_item_rec.apply_date, NULL )
                                  -- 商品分類
                                 ,ximb.product_class
                                  -- 配数
                                 ,ximb.palette_max_cs_qty
                                  -- 段数
                                 ,ximb.palette_max_step_qty
                                 ,cn_last_updated_by
                                 ,cd_last_update_date
                                 ,cn_last_update_login
                                 ,cn_request_id
                                 ,cn_program_application_id
                                 ,cn_program_id
                                 ,cd_program_update_date
                      FROM        xxcmn_item_mst_b    ximb
                      WHERE       ximb.item_id            = i_update_item_rec.parent_item_id
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--                      AND         ximb.start_date_active <= TRUNC( SYSDATE )
--                      AND         ximb.end_date_active   >= TRUNC( SYSDATE ) )
                      AND         ximb.start_date_active <= gd_process_date
                      AND         ximb.end_date_active   >= gd_process_date )
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
          WHERE       item_id                 = i_update_item_rec.item_id
-- Ver1.1 2009/01/14 MOD テストシナリオ 5-6
--          AND         active_flag             = cv_yes
-- Ver1.1 End
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--          AND         start_date_active      <= TRUNC( SYSDATE )
--          AND         end_date_active        >= TRUNC( SYSDATE );
          AND         start_date_active      <= gd_process_date
          AND         end_date_active        >= gd_process_date;
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
          --
        END IF;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg_errm  := SQLERRM;
          lv_msg_token := cv_tkn_val_xxcmn_opmitem;
          RAISE data_update_err_expt;  -- 更新エラー
      END;
      --
      --==============================================================
      --A-5.3 営業組織：Z99への品目割当確認
      --==============================================================
      -- 20:仮登録の場合、[Z99]に組織割当
      -- 30:本登録 40:廃 50:Ｄ’60:Ｄの場合、Disc品目を更新
      -- 営業組織[Z99]に品目が未割当の場合、品目割当も実施
      IF ( i_update_item_rec.item_status IN ( cn_itm_status_pre_reg         -- 20:仮登録
                                             ,cn_itm_status_regist          -- 30:本登録
                                             ,cn_itm_status_no_sch          -- 40:廃
                                             ,cn_itm_status_trn_only        -- 50:Ｄ’
                                             ,cn_itm_status_no_use ) )      -- 60:Ｄ
      THEN
        -- Disc品目マスタに対する更新項目はすべて組織レベル。
        -- 更新はZ99のみでOKなのか？
        --==============================================================
        --A-5.3 営業組織：Z99への品目割当確認
        --==============================================================
        lv_step := 'STEP-06080';
-- 2009/12/24 Ver1.14 障害E_本稼動_00577 modify start by Shigeto.Niki
        -- 営業組織に品目が割り当たっているか取得
--        SELECT      COUNT( msib.ROWID )
--        INTO        ln_exsits_count
--        FROM        mtl_system_items_b    msib
--        WHERE       msib.inventory_item_id = i_update_item_rec.inventory_item_id
--        AND         msib.organization_id   = gn_bus_org_id
--        AND         ROWNUM                 = 1;
--        --
--        IF ( ln_exsits_count = 0 ) THEN
--          -- 営業組織に品目が割当っていない場合、登録
--          lv_step := 'STEP-06090';
--          lv_transaction_type := cv_tran_type_create;
--        ELSE
--          -- 営業組織に品目が割当っている場合、更新
--          lv_step := 'STEP-06100';
--          lv_transaction_type := cv_tran_type_update;
--        END IF;
        --
        BEGIN 
          -- 営業組織の保管棚管理を取得
          SELECT      msib.location_control_code
          INTO        ln_location_control_code
          FROM        mtl_system_items_b    msib
          WHERE       msib.inventory_item_id = i_update_item_rec.inventory_item_id
          AND         msib.organization_id   = gn_bus_org_id
          AND         ROWNUM                 = 1;
          -- 営業組織の保管棚管理が取得できた場合、更新
          lv_step := 'STEP-06100';
          lv_transaction_type := cv_tran_type_update;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 営業組織の保管棚管理が取得できない場合、登録
            lv_step := 'STEP-06090';
            lv_transaction_type := cv_tran_type_create;
            ln_location_control_code := cn_location_control_code_no;
            --
        END;
-- 2009/12/24 Ver1.14 障害E_本稼動_00577 modify end by Shigeto.Niki
        --==============================================================
        --A-5.4 Disc品目マスタインタフェース登録
        --==============================================================
        lv_step := 'STEP-06110';
        BEGIN
          -- 品目I/Fへ登録
          INSERT INTO  mtl_system_items_interface(
            inventory_item_id                -- Disc品目ID
           ,organization_id                  -- 組織（Z99）
           ,purchasing_item_flag             -- 購買品目
           ,shippable_item_flag              -- 出荷可能
           ,customer_order_flag              -- 顧客受注
           ,purchasing_enabled_flag          -- 購買可能
           ,customer_order_enabled_flag      -- 顧客受注可能
           ,internal_order_enabled_flag      -- 社内発注
           ,so_transactions_flag             -- OE 取引可能
           ,mtl_transactions_enabled_flag    -- 取引可能
           ,reservable_type                  -- 予約可能
           ,returnable_flag                  -- 返品可能
           ,stock_enabled_flag               -- 在庫保有可能
-- Ver1.7  2009/04/03 Add Start ロット管理(LOT_CONTROL_CODE)追加
           ,lot_control_code                 -- ロット管理
-- Ver1.7  2009/04/03 Add End
-- Ver1.10 2009/07/15 Add  保管棚管理(LOCATION_CONTROL_CODE)追加
           ,location_control_code            -- 保管棚管理
-- End1.10
           ,process_flag                     -- プロセスフラグ
           ,transaction_type )               -- 処理タイプ
          VALUES(
            i_update_item_rec.inventory_item_id
           ,gn_bus_org_id
           ,i_update_item_rec.purchasing_item_flag
           ,i_update_item_rec.shippable_item_flag
           ,i_update_item_rec.customer_order_flag
           ,i_update_item_rec.purchasing_enabled_flag
           ,l_item_status_info_rec.customer_order_enabled_flag
           ,i_update_item_rec.internal_order_enabled_flag
           ,i_update_item_rec.so_transactions_flag
           ,l_item_status_info_rec.mtl_transactions_enabled_flag
           ,i_update_item_rec.reservable_type
           ,l_item_status_info_rec.returnable_flag
           ,l_item_status_info_rec.stock_enabled_flag
-- Ver1.7  2009/04/03 Add Start ロット管理(LOT_CONTROL_CODE)追加
           ,cn_lot_control_code_no
-- Ver1.7  2009/04/03 Add End
-- Ver1.10 2009/07/15 Add  保管棚管理(LOCATION_CONTROL_CODE)追加
-- 2009/12/24 Ver1.14 障害E_本稼動_00577 add start by Shigeto.Niki
--           ,cn_location_control_code_no
           ,ln_location_control_code
-- 2009/12/24 Ver1.14 障害E_本稼動_00577 end start by Shigeto.Niki
-- End1.10
           ,cn_process_flag
           ,lv_transaction_type );
           --
        EXCEPTION
          WHEN OTHERS THEN
            lv_msg_errm  := SQLERRM;
            lv_msg_token := cv_tkn_val_discitem_if;
            RAISE data_insert_err_expt;  -- 登録エラー
        END;
      END IF;
      --
-- Ver1.9  2009/07/06  Add  障害対応(0000364)
      -- 親品目を仮登録～Ｄ'に変更時、コンポーネント区分の不足分を登録
        -- 本登録～Ｄ'に変更する場合、全コンポーネントが登録されている必要があり、
        -- また、標準原価計 > 0円 である必要がある。
      IF  ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id )
      AND ( i_update_item_rec.item_status >= cn_itm_status_pre_reg )
      AND ( i_update_item_rec.item_status <= cn_itm_status_trn_only ) THEN
        -- 原価ヘッダ(カレンダコード、期間コード)の取得
        --  ※カーソルにしているが、対象は１件のみ
        lv_step := 'STEP-6210';
        <<cnp_cost_hd_par_loop>>
        FOR l_cnp_cost_hd_par_rec IN cnp_cost_hd_par_cur( i_update_item_rec.apply_date ) LOOP
          -----------------
          -- 原価ヘッダ
          -----------------
          lv_step := 'STEP-6220';
          -- カレンダコード
          l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_par_rec.calendar_code;
          -- 期間コード
          l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_par_rec.period_code;
          -- 品目ID
          l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
          --
          -- カレンダ、期間毎に原価情報を取得
          lv_step := 'STEP-6230';
          ln_cmp_cost_index := 0;
          --
          <<cnp_noext_cost_dt_loop>>
          FOR l_cnp_noext_cost_dt_rec IN cnp_noext_cost_dt_cur( i_update_item_rec.item_id
                                                               ,l_cnp_cost_hd_par_rec.calendar_code
                                                               ,l_cnp_cost_hd_par_rec.period_code ) LOOP
            -----------------
            -- 原価明細
            -----------------
            lv_step := 'STEP-6240';
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            --
            -- 原価コンポーネントID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_noext_cost_dt_rec.cost_cmpntcls_id;
            -- 原価
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := 0;
          --
          END LOOP cnp_noext_cost_dt_loop;
          --
          --==============================================================
          -- 標準原価登録（未登録コンポーネントの０円設定）
          --==============================================================
          lv_step := 'STEP-6250';
          xxcmm_004common_pkg.proc_opmcost_ref(
            i_cost_header_rec  =>  l_opm_cost_header_rec  -- 原価ヘッダレコードタイプ
           ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- 原価明細テーブルタイプ
           ,ov_errbuf          =>  lv_errbuf              -- エラー・メッセージ           --# 固定 #
           ,ov_retcode         =>  lv_retcode             -- リターン・コード             --# 固定 #
           ,ov_errmsg          =>  lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            --
            lv_msg_token := cv_tkn_val_opmcost;
            lv_msg_errm  := lv_errmsg;
            RAISE data_insert_err_expt;
          END IF;
          --
        END LOOP cnp_cost_hd_par_loop;
      END IF;
-- End1.9
      --
-- 2009/09/11 Ver1.12 障害0000948 add start by Y.Kuboshima
      -- 単位換算を作るタイミングを品目ステータス変更時に変更
      -- 単位換算作成フラグ取得
      OPEN units_of_measure_cur(i_update_item_rec.item_um);
      FETCH units_of_measure_cur INTO l_units_of_measure_rec;
      CLOSE units_of_measure_cur;
      -- 区分間換算登録判定
      -- 単位換算作成フラグが'Y'の場合かつ、品目ステータスが'30'(本登録)の場合、単位換算を作成する
      IF  ( l_units_of_measure_rec.attribute1 = cv_yes ) 
        AND ( i_update_item_rec.item_status = cn_itm_status_regist)
      THEN
        --==============================================================
        --A-5.6 区分間換算の登録
        --==============================================================
        lv_step := 'STEP-05060';
        l_uom_class_conv_rec.inventory_item_id := i_update_item_rec.inventory_item_id;
        l_uom_class_conv_rec.from_uom_code     := i_update_item_rec.item_um;
        l_uom_class_conv_rec.to_uom_code       := cv_uom_class_conv_to;                   -- CS
        l_uom_class_conv_rec.conversion_rate   := i_update_item_rec.num_of_cases;
        --
        -- 区分間換算登録API
        lv_step := 'STEP-04030';
        xxcmm_004common_pkg.proc_uom_class_ref(
          i_uom_class_conv_rec  =>  l_uom_class_conv_rec  -- 区分間換算反映用レコードタイプ
         ,ov_errbuf             =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
         ,ov_retcode            =>  lv_retcode            -- リターン・コード             --# 固定 #
         ,ov_errmsg             =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          --
          lv_msg_token := cv_tkn_val_uon_conv;
          RAISE data_insert_err_expt;
        END IF;
      END IF;
-- 2009/09/11 Ver1.12 障害0000948 add end by Y.Kuboshima
      --
    END IF;
    --
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      --
    -- *** データ抽出例外ハンドラ ***
    WHEN data_select_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00442            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_data_info              -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                    );
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg || cv_msg_space|| SQLERRM;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ登録例外ハンドラ ***
    WHEN data_insert_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00444            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                     ,iv_token_value3 => lv_msg_errm                   -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ更新例外ハンドラ ***
    WHEN data_update_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00445            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                     ,iv_token_value3 => lv_msg_errm                   -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END proc_item_status_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_status_update
   * Description      : 品目ステータス変更
   **********************************************************************************/
  PROCEDURE proc_status_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_STATUS_UPDATE'; -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);     -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    sub_proc_expt                EXCEPTION;
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    --==============================================================
    --A-5 品目ステータス情報反映
    --==============================================================
    lv_step := 'STEP-05010';
    proc_item_status_update(
      i_update_item_rec   =>  i_update_item_rec     -- 品目ステータス反映レコード
     ,ov_errbuf           =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-6 親品目情報の継承
    --==============================================================
    lv_step := 'STEP-05020';
    proc_inherit_parent(
      i_update_item_rec   =>  i_update_item_rec     -- 品目ステータス反映レコード
     ,ov_errbuf           =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END proc_status_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_first_update
   * Description      : 初回登録データ処理(A-4)
   **********************************************************************************/
  PROCEDURE proc_first_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_FIRST_UPDATE'; -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);     -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
-- 2009/09/11 Ver1.12 障害0000948 delete start by Y.Kuboshima
--    cv_uom_class_conv_from       CONSTANT VARCHAR2(10) := 'kg';
--    cv_uom_class_conv_to         CONSTANT VARCHAR2(10) := 'CS';
-- 2009/09/11 Ver1.12 障害0000948 delete end by Y.Kuboshima
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    ln_exsits_count              NUMBER;
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 品目カテゴリ割当抽出カーソル(本社製品区分、製品商品区分、政策群)
    --                              群コード、バラ茶区分、マーケ用群コード 2009/06/11追加
    CURSOR opm_item_categ_cur(
      pn_item_id    NUMBER )
    IS
      SELECT      gic.item_id                  -- 品目ID
                 ,gic.category_set_id          -- カテゴリセットID
                 ,gic.category_id              -- カテゴリID
      FROM        gmi_item_categories  gic     -- OPM品目カテゴリ割当
                 ,mtl_category_sets    mcs     -- カテゴリセット
      WHERE       gic.item_id  = pn_item_id    -- 品目ID
-- Ver1.8  2009/06/11  Add  群コード、バラ茶区分、マーケ用群コードを追加
--      AND         mcs.category_set_name IN ( cv_categ_set_seisakugun       -- 政策群コード
--                                            ,cv_categ_set_item_prod        -- 製品商品区分
--                                            ,cv_categ_set_hon_prod )       -- 本社商品区分
      AND         mcs.category_set_name IN ( cv_categ_set_seisakugun       -- 政策群コード
                                            ,cv_categ_set_gun_code         -- 群コード
                                            ,cv_categ_set_item_prod        -- 製品商品区分
                                            ,cv_categ_set_hon_prod         -- 本社商品区分
                                            ,cv_categ_set_baracha_div      -- バラ茶区分
                                            ,cv_categ_set_mark_pg          -- マーケ用群コード
-- 2009/09/11 Ver1.12 障害0001258 add start by Y.Kuboshima
                                            ,cv_categ_set_item_div         -- 品目区分
                                            ,cv_categ_set_inout_div        -- 内外区分
                                            ,cv_categ_set_product_div      -- 商品区分
                                            ,cv_categ_set_quality_div      -- 品質区分
                                            ,cv_categ_set_fact_pg          -- 工場群コード
                                            ,cv_categ_set_acnt_pg )        -- 経理部用群コード
-- 2009/09/11 Ver1.12 障害0001258 add end by Y.Kuboshima
--
-- End1.8
      AND         gic.category_set_id = mcs.category_set_id;
    --
    -- 品目カテゴリ割当抽出カーソル(本社製品区分、製品商品区分)
    --                              バラ茶区分、マーケ用群コード 2009/06/11追加
    CURSOR opm_item_categ_cur2(
      pn_item_id    NUMBER )
    IS
      SELECT      gic.item_id                  -- 品目ID
                 ,gic.category_set_id          -- カテゴリセットID
                 ,gic.category_id              -- カテゴリID
      FROM        gmi_item_categories  gic     -- OPM品目カテゴリ割当
                 ,mtl_category_sets    mcs     -- カテゴリセット
      WHERE       gic.item_id  = pn_item_id    -- 品目ID
-- Ver1.8  2009/06/11  Add  バラ茶区分、マーケ用群コードを追加
--      AND         mcs.category_set_name IN ( cv_categ_set_item_prod        -- 製品商品区分
--                                            ,cv_categ_set_hon_prod )       -- 本社商品区分
      AND         mcs.category_set_name IN ( cv_categ_set_item_prod        -- 製品商品区分
                                            ,cv_categ_set_hon_prod         -- 本社商品区分
                                            ,cv_categ_set_baracha_div      -- バラ茶区分
                                            ,cv_categ_set_mark_pg          -- マーケ用群コード
-- 2009/09/11 Ver1.12 障害0001258 add start by Y.Kuboshima
                                            ,cv_categ_set_item_div         -- 品目区分
                                            ,cv_categ_set_inout_div        -- 内外区分
                                            ,cv_categ_set_product_div      -- 商品区分
                                            ,cv_categ_set_quality_div      -- 品質区分
                                            ,cv_categ_set_fact_pg          -- 工場群コード
                                            ,cv_categ_set_acnt_pg )        -- 経理部用群コード
-- 2009/09/11 Ver1.12 障害0001258 add end by Y.Kuboshima
--
-- End1.8
      AND         gic.category_set_id = mcs.category_set_id;
    --
    -- レコード型
-- 2009/09/11 Ver1.12 障害0000948 delete start by Y.Kuboshima
--    -- 単位換算用
--    l_uom_class_conv_rec         xxcmm_004common_pkg.uom_class_conv_rtype;
-- 2009/09/11 Ver1.12 障害0000948 delete end by Y.Kuboshima
    -- Disc品目カテゴリ用
    l_discitem_category_rec      xxcmm_004common_pkg.discitem_category_rtype;
    -- 品目カテゴリ割当抽出カーソルのレコードタイプ
    l_opm_item_categ_rec         opm_item_categ_cur%ROWTYPE;
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    item_common_ins_expt         EXCEPTION;    -- データ登録エラー(品目共通API)
    --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-4 初回登録データ処理
    --==============================================================
    lv_step := 'STEP-04010';
-- 2009/09/11 Ver1.12 障害0000948 delete start by Y.Kuboshima
-- ※単位換算を作るタイミングを品目ステータス変更時に行う
--
--    -- 区分間換算登録判定
---- 基準単位が「本」の場合、単位換算を行う
--    IF  ( i_update_item_rec.item_um = cv_uom_class_conv_from )
--    AND ( NVL( i_update_item_rec.num_of_cases, 0 ) > 0 ) THEN
--      --==============================================================
--      --A-4.1 区分間換算の登録
--      --==============================================================
--      lv_step := 'STEP-04020';
--      l_uom_class_conv_rec.inventory_item_id := i_update_item_rec.inventory_item_id;
--      l_uom_class_conv_rec.from_uom_code     := i_update_item_rec.item_um;
--      l_uom_class_conv_rec.to_uom_code       := cv_uom_class_conv_to;                   -- CS
--      l_uom_class_conv_rec.conversion_rate   := i_update_item_rec.num_of_cases;
--      --
--      -- 区分間換算登録API
--      lv_step := 'STEP-04030';
--      xxcmm_004common_pkg.proc_uom_class_ref(
--        i_uom_class_conv_rec  =>  l_uom_class_conv_rec  -- 区分間換算反映用レコードタイプ
--       ,ov_errbuf             =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
--       ,ov_retcode            =>  lv_retcode            -- リターン・コード             --# 固定 #
--       ,ov_errmsg             =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      --
--      IF ( lv_retcode = cv_status_error ) THEN
--        --
--        lv_msg_token := cv_tkn_val_uon_conv;
--        RAISE item_common_ins_expt;
--      END IF;
--    END IF;
-- 2009/09/11 Ver1.12 障害0000948 delete end by Y.Kuboshima
    --
    --==============================================================
    --A-4.3 ＯＰＭ品目カテゴリ割当情報取得
    --==============================================================
    -------------------------
    -- 親品目の政策群変更確認
    -------------------------
    IF ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id ) THEN
      -- 親品目の場合、政策群は変更予約されるので処理しない
      ln_exsits_count := 1;
    ELSE
      -- 子品目の場合
      lv_step := 'STEP-04040';
      --==============================================================
      --A-4.2 親品目の政策群変更適用存在チェック
      --==============================================================
      SELECT      COUNT( xsibh.ROWID )
      INTO        ln_exsits_count
      FROM        xxcmm_system_items_b_hst  xsibh                              -- Disc品目変更履歴アドオン
                 ,xxcmm_opmmtl_items_v      xoiv                               -- 品目ビュー
      WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- 親品目ID
-- 2009/08/10 Ver1.11 障害0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- 適用開始日
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE )                   -- 適用終了日
      AND         xoiv.start_date_active <= gd_process_date                    -- 適用開始日
      AND         xoiv.end_date_active   >= gd_process_date                    -- 適用終了日
-- 2009/08/10 Ver1.11 障害0000894 modify end by Y.Kuboshima
      AND         xsibh.item_code         = xoiv.item_no                       -- 品目コード
      AND         xsibh.apply_date       <= gd_apply_date                      -- 適用日
-- Ver1.1 2009/01/16 MOD テストシナリオ 4-5
--      AND         xsibh.apply_flag        = cv_no                              -- 未適用
      AND         xsibh.request_id        = cn_request_id                      -- 同じ変更適用であること
-- End
      AND         xsibh.policy_group     IS NOT NULL                           -- 政策群
      AND         ROWNUM = 1;
      --
    END IF;
   --
    --==============================================================
    --A-4.3 ＯＰＭ品目カテゴリ割当情報取得
    --==============================================================
    IF ( ln_exsits_count = 0 ) THEN
      -- 政策群ありカーソル
      lv_step := 'STEP-04050';
      OPEN opm_item_categ_cur( i_update_item_rec.item_id );
    ELSE
      -- 政策群なしカーソル
      lv_step := 'STEP-04060';
      OPEN opm_item_categ_cur2( i_update_item_rec.item_id );
    END IF;
    --
    -- 品目カテゴリ割当(Disc)登録
    <<disc_categ_loop>>
    LOOP
      --
      IF ( ln_exsits_count = 0 ) THEN
        -- フェッチ
        lv_step := 'STEP-04070';
        FETCH opm_item_categ_cur INTO l_opm_item_categ_rec;
        -- 
        IF (opm_item_categ_cur%NOTFOUND) THEN
          CLOSE opm_item_categ_cur;
          EXIT;
        END IF;
      ELSE
        -- フェッチ
        lv_step := 'STEP-04080';
        FETCH opm_item_categ_cur2 INTO l_opm_item_categ_rec;
        --
        IF (opm_item_categ_cur2%NOTFOUND) THEN
          CLOSE opm_item_categ_cur2;
          EXIT;
        END IF;
      END IF;
      --
      lv_step := 'STEP-04090';
      l_discitem_category_rec.inventory_item_id := i_update_item_rec.inventory_item_id;    -- Disc品目ID
      l_discitem_category_rec.category_set_id   := l_opm_item_categ_rec.category_set_id;   -- カテゴリセットID
      l_discitem_category_rec.category_id       := l_opm_item_categ_rec.category_id;       -- カテゴリID
      --
      --==============================================================
      --A-4.4 品目カテゴリ割当の登録
      --==============================================================
      lv_step := 'STEP-04100';
      -- 品目カテゴリ割当(Disc)登録API
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec  =>  l_discitem_category_rec    -- 品目カテゴリ割当レコードタイプ
       ,ov_errbuf            =>  lv_errbuf                  -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           =>  lv_retcode                 -- リターン・コード             --# 固定 #
       ,ov_errmsg            =>  lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        IF ( ln_exsits_count = 0 ) THEN
          CLOSE opm_item_categ_cur;
        ELSE
          CLOSE opm_item_categ_cur2;
        END IF;
        --
        lv_msg_token := cv_tkn_val_mtl_item_categ;
        RAISE item_common_ins_expt;
      END IF;
      --
    END LOOP disc_categ_loop;
    --
  EXCEPTION
--
    -- *** データ登録エラー(品目共通API)例外ハンドラ ***
    WHEN item_common_ins_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00444            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1 => lv_msg_token                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code              -- トークンコード2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                     ,iv_token_value3 => lv_errmsg                     -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END proc_first_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_apply_update
   * Description      : 品目変更適用処理
   **********************************************************************************/
  PROCEDURE proc_apply_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_APPLY_UPDATE'; -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);     -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    sub_proc_expt                EXCEPTION;
    --
-- Ver1.7 2009/05/27 Add  現在ステータスが「Ｄ」時のチェックを追加
    item_no_use_expt           EXCEPTION;    -- 現在の品目ステータス「Ｄ」時のチェックエラー
-- End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --品目変更適用処理
    --==============================================================
    -- 初回品目適用判定
    IF ( i_update_item_rec.first_apply_flag = cv_yes ) THEN
      --==============================================================
      --A-4 初回登録データ処理
      --==============================================================
      lv_step := 'STEP-03010';
      proc_first_update(
        i_update_item_rec   =>  i_update_item_rec     -- 
       ,ov_errbuf           =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode          =>  lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg           =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        RAISE sub_proc_expt;
      END IF;
      --
    END IF;
    --
    ------------------------
    -- 品目ステータス反映
    ------------------------
    IF ( i_update_item_rec.item_status IS NOT NULL ) THEN
      --==============================================================
      --品目ステータス変更
      --  A-5 品目ステータス情報反映（品目ステータス変更による更新）
      --  A-6 親品目情報の継承      （品目ステータス変更に伴う更新）
      --==============================================================
      lv_step := 'STEP-03020';
      proc_status_update(
        i_update_item_rec   =>  i_update_item_rec     -- 品目ステータス反映レコード
       ,ov_errbuf           =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode          =>  lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg           =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        RAISE sub_proc_expt;
      END IF;
      --
-- Ver1.7 2009/05/27 Add  現在ステータスが「Ｄ」の場合、品目ステータス以外の変更は不可
    ELSE
      lv_step := 'STEP-3025';
      IF  ( i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
        RAISE item_no_use_expt;
      END IF;
-- End
    --
    END IF;
    --
    --==============================================================
    --親品目の変更
    --  A-7 親品目変更時の更新、子品目への継承
    --==============================================================
    lv_step := 'STEP-03030';
    proc_parent_item_update(
      i_update_item_rec   =>  i_update_item_rec     -- 品目ステータス反映レコード
     ,ov_errbuf           =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-8 Disc品目アドオンの更新
    --A-9 Disc品目変更履歴アドオンの更新
    --==============================================================
    lv_step := 'STEP-03040';
    proc_comp_apply_update(
      i_update_item_rec   =>  i_update_item_rec     -- 品目ステータス反映レコード
     ,ov_errbuf           =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- 更新件数のインクリメント
    --==============================================================
    lv_step := 'STEP-03050';
    IF ( i_update_item_rec.item_status  IS NOT NULL ) THEN
      -- ステータス更新件数
      gn_item_status_cnt := gn_item_status_cnt + 1;
    END IF;
    --
    lv_step := 'STEP-03060';
    IF ( i_update_item_rec.policy_group  IS NOT NULL ) THEN
      -- 政策群更新件数
      gn_policy_group_cnt := gn_policy_group_cnt + 1;
    END IF;
    --
    lv_step := 'STEP-03070';
    IF ( i_update_item_rec.fixed_price   IS NOT NULL ) THEN
      -- 定価更新件数
      gn_fixed_price_cnt := gn_fixed_price_cnt + 1;
    END IF;
    --
    lv_step := 'STEP-03080';
    IF ( i_update_item_rec.discrete_cost IS NOT NULL ) THEN
      -- 営業原価更新件数
      gn_discrete_cost_cnt := gn_discrete_cost_cnt + 1;
    END IF;
    --
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
-- Ver1.7 2009/05/27 Add  現在ステータスが「Ｄ」の場合、品目ステータス以外の変更は不可
    -- *** 現在の品目ステータスチェック例外ハンドラ ***
    WHEN item_no_use_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00430                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item_code                      -- トークンコード1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- End
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END proc_apply_update;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 品目変更適用ループ
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf             OUT    VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode            OUT    VARCHAR2                                        -- リターン・コード
   ,ov_errmsg             OUT    VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'LOOP_MAIN';          -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    --
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    --==============================================================
    --A-3.変更適用品目情報の取得
    --==============================================================
    lv_step := 'STEP-02010';
    <<apply_item_loop>>
    FOR l_update_item_rec IN update_item_cur( gd_apply_date ) LOOP
      --
      -- 品目変更適用１件ずつ制御
      -- 子品目が複数ある場合、変更適用ずつロールバックするため
      lv_step := 'STEP-02020';
      SAVEPOINT hst_record_savepoint;
      --
      lv_step := 'STEP-02030';
      gn_target_cnt  := gn_target_cnt + 1;
      gv_inherit_kbn := cv_inherit_kbn_hst;          -- 親値継承情報区分【'0'：履歴情報による更新】
      -- 
      --==============================================================
      --品目変更適用処理
      --  A-4 初回登録データ処理
      --  A-5 品目ステータス情報反映
      --  A-6 親品目情報の継承
      --  A-7 親品目変更時の継承
      --  A-8 Disc品目アドオンの更新
      --  A-9 Disc品目変更履歴アドオンの更新
      --==============================================================
      lv_step := 'STEP-02040';
      proc_apply_update(
        i_update_item_rec  =>  l_update_item_rec    -- 品目変更適用情報
       ,ov_errbuf          =>  lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         =>  lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg          =>  lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 変更適用１データずつコミット
        lv_step := 'STEP-02050';
        COMMIT;
        --
        gn_normal_cnt := gn_normal_cnt + 1;    -- 正常件数
        --
      ELSE
        --
        lv_step := 'STEP-02060';
        ROLLBACK TO hst_record_savepoint;
        --
        gn_error_cnt  := gn_error_cnt  + 1;    -- エラー件数
        gn_warn_cnt   := gn_warn_cnt   + 1;    -- スキップ件数
        --
        lv_step := 'STEP-02070';
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf
        );
        --
      END IF;
      --
    END LOOP apply_item_loop;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理 (A-2)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_boot_flag          IN     VARCHAR2                                        -- 入力パラメータ.起動種別
   ,ov_errbuf             OUT    VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode            OUT    VARCHAR2                                        -- リターン・コード
   ,ov_errmsg             OUT    VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_INIT';          -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_param_boot_flag           CONSTANT VARCHAR2(10) := '起動種別';            -- パラメータ名
    cv_process_date              CONSTANT VARCHAR2(10) := '業務日付';            -- 業務日付取得失敗時
    cv_process_date_next         CONSTANT VARCHAR2(10) := '翌営業日';            -- 翌営業日取得失敗時
    cv_organization_info         CONSTANT VARCHAR2(20) := '営業組織情報';        -- 営業組織情報失敗時
    --
-- 2009/09/11 Ver1.12 障害0001130 delete start by Y.Kuboshima
--    cv_bus_org_code              CONSTANT VARCHAR2(3)  := 'S01';                 -- 営業組織 組織コード
-- 2009/09/11 Ver1.12 障害0001130 delete end by Y.Kuboshima
    cv_bom_calendar_name         CONSTANT VARCHAR2(30) := 'システム稼働日カレンダ';
--    cv_bom_calendar_name         CONSTANT VARCHAR2(30) := '伊藤園稼働日カレンダ';  -- こっちが正しい？
                                                                                 -- 稼働日カレンダ名称
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    --
-- Ver1.5 2009/02/20 Del 検索対象更新日に業務日付を設定するよう修正
--    ld_process_date              DATE;                                           -- 業務日付
--
    ld_apply_date                DATE;                                           -- 処理日
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    get_param_expt               EXCEPTION;
    get_info_err_expt            EXCEPTION;                                      -- データ抽出エラー(データ特定トークンなし)
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
    get_profile_expt             EXCEPTION;                                      -- プロファイル取得エラー
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    --==============================================================
    --A-1.1 パラメータチェック
    --==============================================================
    lv_step := 'STEP-01010';
    IF ( iv_boot_flag IS NULL ) THEN
      lv_msg_token := cv_param_boot_flag;
      RAISE get_param_expt;
    END IF;
    --
    lv_step := 'STEP-01020';
    gv_boot_flag  :=  iv_boot_flag;            -- INパラメータを格納
    --
    lv_step := 'STEP-01030';
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_param_boot_flag || cv_msg_part || gv_boot_flag
    );
    --
    --==============================================================
    --A-2 初期処理
    --==============================================================
    --==============================================================
    --A-2.1 業務日付の取得
    --==============================================================
    lv_step := 'STEP-01040';
    -- 業務日付の取得
-- Ver1.5 2009/02/20 Mod 検索対象更新日に業務日付を設定するよう修正
--    ld_process_date := xxccp_common_pkg2.get_process_date;
--    --
--    -- 取得エラー時
--    IF ( ld_process_date IS NULL ) THEN
--
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- 取得エラー時
    IF ( gd_process_date IS NULL ) THEN
-- End
      lv_msg_token := cv_process_date;
      RAISE get_info_err_expt;       -- 取得エラー
    END IF;
    --
    --==============================================================
    --A-2.2 翌営業日付の取得
    --==============================================================
    lv_step := 'STEP-01050';
    -- パラメータ.起動種別が夜間の場合、翌営業日を取得
    IF ( gv_boot_flag = cv_boot_flag_online ) THEN
      lv_step := 'STEP-01060';
      -- オンライン時：業務日付を処理日に設定
-- Ver1.5 2009/02/20 Mod 検索対象更新日に業務日付を設定するよう修正
--      ld_apply_date := ld_process_date;
      ld_apply_date := gd_process_date;
-- End
    ELSE
      lv_step := 'STEP-01070';
      BEGIN
        -- 夜間バッチ時：翌営業日を処理日に設定
        SELECT      MIN( bcd.calendar_date )    AS next_bus_date
        INTO        ld_apply_date
        FROM        bom_calendar_dates     bcd
                   ,bom_calendars          bc
        WHERE       bc.description    = cv_bom_calendar_name
        AND         bcd.calendar_code = bc.calendar_code
-- Ver1.5 2009/02/20 Mod 検索対象更新日に業務日付を設定するよう修正
--        AND         bcd.calendar_date > ld_process_date
        AND         bcd.calendar_date > gd_process_date
-- End
        AND         bcd.calendar_date = bcd.next_date;
      EXCEPTION
        WHEN OTHERS THEN
          --翌営業日
          lv_msg_token := cv_process_date_next;
          RAISE get_info_err_expt;  -- 取得エラー
      END;
    END IF;
    --
-- Ver1.1 2009/01/13 ADD テストシナリオ 2-6
    -- 取得エラー時
    IF ( ld_apply_date IS NULL ) THEN
      lv_msg_token := cv_process_date_next;
      RAISE get_info_err_expt;      -- 取得エラー
    END IF;
-- Ver1.1 ADD END
    --
    lv_step := 'STEP-01080';
    gd_apply_date := ld_apply_date;
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
    --
    --==============================================================
    --A-2.3 プロファイルの取得
    --==============================================================
    lv_step := 'STEP-1090';
    -- 在庫組織コードの取得
    gv_bus_org_code := fnd_profile.value(cv_pro_org_code);
    IF (gv_bus_org_code IS NULL) THEN
      lv_msg_token := cv_tkn_val_org_code;
      RAISE get_profile_expt;
    END IF;
    --
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
    --
    --==============================================================
    --A-2.4 営業組織情報の取得
    --==============================================================
    lv_step := 'STEP-01100';
    BEGIN
      -- 営業組織ID,原価組織ID,マスター在庫組織IDの取得
      SELECT      mp.organization_id           -- 営業組織ID
                 ,mp.cost_organization_id      -- 原価組織ID
                 ,mp.master_organization_id    -- マスター在庫組織ID
      INTO        gn_bus_org_id
                 ,gn_cost_org_id
                 ,gn_master_org_id
      FROM        mtl_parameters    mp
-- 2009/09/11 Ver1.12 障害0001130 modify start by Y.Kuboshima
--      WHERE       mp.organization_code = cv_bus_org_code;
      WHERE       mp.organization_code = gv_bus_org_code;
-- 2009/09/11 Ver1.12 障害0001130 modify end by Y.Kuboshima
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg_token := cv_organization_info;
        RAISE get_info_err_expt;  -- 取得エラー
    END;
    --
  EXCEPTION
--
    -- *** パラメータチェック例外ハンドラ ***
    WHEN get_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00440    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_param_name     -- トークンコード1
                     ,iv_token_value1 => lv_msg_token          -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** データ抽出エラーハンドラ（データ特定トークンなし） ***
    WHEN get_info_err_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_name_xxcmm    -- モジュール名略称:XXCMN
                                                      ,cv_msg_xxcmm_00441    -- メッセージ:APP-XXCMM1-00441
                                                      ,cv_tkn_data_info      -- トークンコード1
                                                      ,lv_msg_token )        -- トークン値1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
-- 2009/09/11 Ver1.12 障害0001130 add start by Y.Kuboshima
    -- *** プロファイル取得エラーハンドラ ***
    WHEN get_profile_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_name_xxcmm    -- モジュール名略称:XXCMN
                                                      ,cv_msg_xxcmm_00002    -- メッセージ:APP-XXCMM1-00002
                                                      ,cv_tkn_ng_profile     -- トークンコード1
                                                      ,lv_msg_token )        -- トークン値1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
-- 2009/09/11 Ver1.12 障害0001130 add end by Y.Kuboshima
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_boot_flag          IN     VARCHAR2                                        -- 起動種別【1:オンライン、2：夜間】
   ,ov_errbuf             OUT    VARCHAR2                                        -- エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT    VARCHAR2                                        -- リターン・コード             --# 固定 #
   ,ov_errmsg             OUT    VARCHAR2                                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'SUBMAIN';            -- プログラム名
    --
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
    lv_step                      VARCHAR2(10);
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    sub_proc_expt                EXCEPTION;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    gn_item_status_cnt   := 0;           -- ステータス更新件数
    gn_policy_group_cnt  := 0;           -- 政策群更新件数  （変更履歴ベース）
    gn_fixed_price_cnt   := 0;           -- 定価更新件数    （変更履歴ベース）
    gn_discrete_cost_cnt := 0;           -- 営業原価更新件数（変更履歴ベース）
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --==============================================================
    --A-1 パラメータチェック
    --A-2 初期処理
    --==============================================================
    lv_step := 'STEP-00010';
    proc_init(
      iv_boot_flag  =>  iv_boot_flag    -- 起動種別【1:オンライン、2：夜間】
     ,ov_errbuf     =>  lv_errbuf       -- エラー・メッセージ
     ,ov_retcode    =>  lv_retcode      -- リターン・コード
     ,ov_errmsg     =>  lv_errmsg       -- ユーザー・エラー・メッセージ
    );
    --
    -- 戻り値が異常の場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --品目変更適用ループ
    --  A-3 変更適用品目情報の取得
    --  A-4 初回登録データ処理
    --  A-5 品目ステータス情報反映
    --  A-6 親品目情報の継承
    --  A-7 親品目変更時の継承
    --  A-8 Disc品目アドオンの更新
    --  A-9 Disc品目変更履歴アドオンの更新
    --==============================================================
    lv_step := 'STEP-00020';
    loop_main(
      ov_errbuf   =>  lv_errbuf     -- エラー・メッセージ
     ,ov_retcode  =>  lv_retcode    -- リターン・コード
     ,ov_errmsg   =>  lv_errmsg     -- ユーザー・エラー・メッセージ
    );
    -- 戻り値が異常の場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    -- エラーデータ存在時は警告終了
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
    --
    --
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
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
    errbuf                OUT    VARCHAR2                                        --   エラーメッセージ #固定#
   ,retcode               OUT    VARCHAR2                                        --   エラーコード     #固定#
   ,iv_boot_flag          IN     VARCHAR2                                        --   起動種別【1:オンライン、2：夜間】
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'MAIN';               -- プログラム名
    --
    cv_appl_name_xxccp           CONSTANT VARCHAR2(10)  := 'XXCCP';              -- アドオン：共通・IF領域
    cv_target_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- 対象件数メッセージ
    cv_success_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- 成功件数メッセージ
    cv_error_rec_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- エラー件数メッセージ
    cv_skip_rec_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';   -- スキップ件数メッセージ
    cv_cnt_token                 CONSTANT VARCHAR2(10)  := 'COUNT';              -- 件数メッセージ用トークン名
    cv_normal_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- 正常終了メッセージ
    cv_warn_msg                  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- 警告終了メッセージ
    cv_error_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';   -- エラー終了全ロールバック
    --
    cv_log                       CONSTANT VARCHAR2(100) := 'LOG';                -- ログ
    cv_output                    CONSTANT VARCHAR2(100) := 'OUTPUT';             -- アウトプット
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                    VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_message_code              VARCHAR2(100);                                  -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
    --
    ----------------------------------
    -- ログヘッダ出力
    ----------------------------------
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_boot_flag  =>  iv_boot_flag          -- 1.起動種別【1:オンライン、2：夜間】
     ,ov_errbuf     =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = cv_status_error ) THEN
      -- 出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                -- ユーザー・エラーメッセージ
      );
      -- ログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                -- エラーメッセージ
      );
    END IF;
    --
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    ----------------------------------
    -- ログフッタ出力
    ----------------------------------
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- アプリケーション短縮名
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- メッセージコード
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- トークンコード1
                   ,iv_token_value1  =>  cv_tkn_val_target_cnt             -- トークン値1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- トークンコード2
                   ,iv_token_value2  =>  TO_CHAR( gn_target_cnt )          -- トークン値2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 品目ステータス変更件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- アプリケーション短縮名
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- メッセージコード
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- トークンコード1
                   ,iv_token_value1  =>  cv_tkn_val_item_status_cnt        -- トークン値1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- トークンコード2
                   ,iv_token_value2  =>  TO_CHAR( gn_item_status_cnt )     -- トークン値2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 政策群変更件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- アプリケーション短縮名
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- メッセージコード
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- トークンコード1
                   ,iv_token_value1  =>  cv_tkn_val_policy_group_cnt       -- トークン値1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- トークンコード2
                   ,iv_token_value2  =>  TO_CHAR( gn_policy_group_cnt )    -- トークン値2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 定価変更件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- アプリケーション短縮名
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- メッセージコード
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- トークンコード1
                   ,iv_token_value1  =>  cv_tkn_val_fixed_price_cnt        -- トークン値1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- トークンコード2
                   ,iv_token_value2  =>  TO_CHAR( gn_fixed_price_cnt )     -- トークン値2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 営業原価件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- アプリケーション短縮名
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- メッセージコード
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- トークンコード1
                   ,iv_token_value1  =>  cv_tkn_val_disc_cost_cnt          -- トークン値1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- トークンコード2
                   ,iv_token_value2  =>  TO_CHAR( gn_discrete_cost_cnt )   -- トークン値2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- アプリケーション短縮名
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- メッセージコード
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- トークンコード1
                   ,iv_token_value1  =>  cv_tkn_val_error_cnt              -- トークン値1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- トークンコード2
                   ,iv_token_value2  =>  TO_CHAR( gn_warn_cnt )            -- トークン値2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
--    -- 対象件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_target_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_target_cnt )
--                  );
--    --
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
--    --
--    -- 成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_success_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
--                  );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
--    --
--    -- エラー件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_error_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_error_cnt )
--                  );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
--    --
--    -- スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_skip_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_warn_cnt )
--                  );
--    --
--    fnd_file.put_line(
--      which  =>  FND_FILE.OUTPUT
--     ,buff   =>  gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
    --
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_appl_name_xxccp
                   ,iv_name         =>  lv_message_code
                  );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT
     ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
    --
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
  END main;
--
END XXCMM004A04C;
/
