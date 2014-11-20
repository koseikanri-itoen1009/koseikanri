CREATE OR REPLACE PACKAGE BODY      APPS.XXCOS008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A01C(body)
 * Description      : 工場直送出荷依頼IF作成を行う
 * MD.050           : 工場直送出荷依頼IF作成 MD050_COS_008_A01
 * Version          : 1.19
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                        初期処理(A-1)
 *  get_order_data              受注データ取得(A-2)
 *  get_ship_subinventory       出荷元保管場所取得(A-3)
 *  get_ship_schedule_date      出荷予定日取得(A-4)
 *  data_check                  データチェック(A-5)
 *  make_normal_order_data      PL/SQL表設定(A-6)
 *  make_request_line_bulk_data 出荷依頼I/F明細バルクバインドデータ作成(A-7)
 *  make_request_head_bulk_data 出荷依頼I/Fヘッダバルクバインドデータ作成(A-8)
 *  insert_ship_line_data       出荷依頼I/F明細データ作成(A-9)
 *  insert_ship_header_data     出荷依頼I/Fヘッダデータ作成(A-10)
 *  update_order_line           受注明細更新(A-11)
 *  start_production_system     生産システム起動(A-12)
 *  weight_check                積載効率最適化チェック(A-14)
 *  order_line_division         受注明細データ分割処理(A-15)
 *  order_line_insert           受注明細登録(A-16)
 *  get_delivery                配送先取得(A-17)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   K.Atsushiba      新規作成
 *  2009/02/05    1.1   K.Atsushiba      COS_035対応  出荷依頼I/Fヘッダーの依頼区分に「4」を設定。
 *  2009/02/18    1.2   K.Atsushiba      get_msgのパッケージ名修正
 *  2009/02/23    1.3   K.Atsushiba      パラメータのログファイル出力対応
 *  2009/04/06    1.4   T.Kitajima       [T1_0175]出荷依頼No採番ルール変更[9]→[97]
 *  2009/04/16    1.5   T.Kitajima       [T1_0609]出荷依頼No採番ルール変更[97]→[98]
 *  2009/05/15    1.6   S.Tomita         [T1_1004]生産物流SへのUO切替/戻し、[顧客発注からの自動作成]機能呼出対応
 *  2009/05/26    1.7   T.Kitajima       [T1_0457]再送対応
 *  2009/07/07    1.8   T.Miyata         [0000478]顧客所在地の抽出条件に有効フラグを追加
 *  2009/07/13    1.9   T.Miyata         [0000293]出荷予定日／受注日算出時のリードタイム変更
 *  2009/07/14    1.10  K.Kiriu          [0000063]情報区分の課題対応
 *  2009/07/28    1.11  M.Sano           [0000137]待機間隔と最大待機時間をプロファイルにて取得
 *  2009/09/16    1.12  K.Atsushiba      [0001232]エラーフラグ保持エリアの初期化対応
 *                                       [0000067]車載重量計算結果を加味した工場出荷データ作成機能追加
 *                                       [0001113]リードタイム算出対応
 *                                       [0001389]PT対応
 *  2009/10/19    1.13  K.Atsushiba      [0001544]納品拠点⇒売上拠点に変更、納品予定日稼働日チェックの無効化対応
 *  2009/11/04    1.14  K.Atsushiba      [0000067]出荷元保管場所取得の条件を納品拠点から売上拠点に変更
 *                                                出荷依頼ヘッダ.入力拠点をログインユーザの自拠点コードに変更
 *                                                [A-12]のログインユーザの自拠点取得処理を初期処理に移動し、グローバル変数化
 *  2009/11/22    1.15  S.Miyakoshi      [I_E_698](A-3)物流構成マスタを検索する際に子コードで検索するよう変更
 *                                                (A-5)出荷区分、率区分、顧客受注可能フラグは子コードでチェックするよう変更
 *                                                (A-5)売上対象区分は、子コードがあればチェックせず、なければチェックするよう変更
 *  2009/11/24    1.16  N.Maeda          [E_本稼動_00014] 出荷指示の改行コード対応
 *  2009/11/25    1.17  K.Atsushiba      [E_本稼動_00034]リーフの出荷依頼が明細毎に作成されないように修正
 *  2009/12/01    1.18  K.Atsushiba      [E_本稼動_00206]無限ループ対応
 *  2009/12/07    1.19  K.Atsushiba      [E_本番_00247]子コードが設定されている場合は子コードで重量計算するように修正
 *                                       [E_本稼動_00305]子コードが設定されている場合は子コードで出荷依頼を作成するように修正
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg            VARCHAR2(2000);
  gv_sep_msg            VARCHAR2(2000);
  gv_exec_user          VARCHAR2(100);
  gv_conc_name          VARCHAR2(30);
  gv_conc_status        VARCHAR2(30);
  gn_target_cnt         NUMBER;                    -- 対象件数
  gn_header_normal_cnt  NUMBER;                    -- 正常件数(ヘッダー)
  gn_line_normal_cnt    NUMBER;                    -- 正常件数(明細)
  gn_error_cnt          NUMBER;                    -- エラー件数
  gn_warn_cnt           NUMBER;                    -- スキップ件数
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
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS008A01C'; -- パッケージ名
  -- アプリケーション短縮名
  cv_xxcos_short_name           CONSTANT VARCHAR2(10) := 'XXCOS';
/* 2009/09/16 Ver.1.12 Add Start */
  cv_xxcoi_short_name           CONSTANT VARCHAR2(10) := 'XXCOI';
/* 2009/09/16 Ver.1.12 Add End */
  -- メッセージ
  cv_msg_lock_error             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ロックエラー
  cv_msg_notfound_profile       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    -- プロファイル取得エラー
  cv_msg_notfound_db_data       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003';    -- 対象データ無しエラー
  cv_msg_update_error           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- データ更新エラー
  cv_msg_data_extra_error       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- データ抽出エラー
  cv_msg_org_id                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';    -- 営業単位
  cv_msg_non_business_date      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11601';    -- 業務日付取得エラー
  cv_msg_lead_time_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11602';    -- リードタイム算出エラー
  cv_msg_non_operation_date     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11603';    -- 稼働日取得エラー
  cv_msg_non_input_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11604';    -- 必須入力エラー
  cv_msg_class_val_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11605';    -- 区分値エラー
  cv_msg_operation_date_error   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11606';    -- 稼働日エラー
  cv_msg_ship_schedule_validite CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11607';    -- 出荷予定日妥当性エラー
  cv_msg_ship_schedule_calc     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11608';    -- 出荷予定日導出エラー
  cv_msg_order_date_validite    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11609';    -- 受注日妥当性エラー
  cv_msg_conc_parame            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11610';    -- 入力パラメータ出力
  cv_msg_order_number           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11611';    -- 受注番号
  cv_msg_line_number            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11612';    -- 明細番号
  cv_msg_item_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11613';    -- 品目コード
  cv_msg_send_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11614';    -- 配送先コード
  cv_msg_deli_expect_date       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11615';    -- 納品予定日
  cv_msg_order_table_name       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11616';    -- 受注テーブル
  cv_msg_order_date             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11617';    -- 受注日
  cv_msg_cust_account_id        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11618';    -- 顧客ID
  cv_msg_cust_po_number         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11619';    -- 顧客発注
  cv_msg_ship_schedule_date     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11620';    -- 出荷予定日
  cv_msg_request_date           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11621';    -- 要求日
  cv_msg_ship_subinv            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11622';    -- 出荷元保管場所
  cv_msg_base_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11623';    -- 納品拠点コード
  cv_msg_order_table            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11624';    -- 受注テーブル
  cv_msg_order_header_line      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11625';    -- 受注ヘッダ/明細
  cv_msg_ou_mfg                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11626';    -- 生産営業単位
  cv_msg_ship_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11627';    -- 出荷区分
  cv_msg_sales_div              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11628';    -- 売上対象区分
  cv_msg_customer_order_flag    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11629';    -- 顧客受注可能フラグ
  cv_msg_rate_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11630';    -- 率区分
  cv_msg_header_nomal_count     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11631';    -- ヘッダ成功件数
  cv_msg_line_nomal_count       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11632';    -- 明細成功件数
  cv_msg_order_line             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11633';    -- 受注明細
  cv_msg_hokan_direct_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11634';    -- 保管場所分類取得エラー
  cv_msg_delivery_base_code     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11635';    -- 拠点コード
  cv_msg_col_name               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11636';    -- 名称
  cv_msg_ou_org_name            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11637';    -- 生産営業単位
  cv_msg_shipping_class         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11324';    -- 依頼区分取得エラー
/* 2009/07/28 Ver.1.11 Add Start */
  cv_msg_interval               CONSTANT VARCHAR2(30) := 'APP-XXCOS1-11645';    -- 待機間隔
  cv_msg_max_wait               CONSTANT VARCHAR2(30) := 'APP-XXCOS1-11646';    -- 最大待機間隔
/* 2009/07/28 Ver.1.11 Add End   */
  -- プロファイル
  cv_pf_org_id                  CONSTANT VARCHAR2(30) := 'ORG_ID';              -- MO:営業単位
  cv_pf_ou_mfg                  CONSTANT VARCHAR2(30) := 'XXCOS1_ITOE_OU_MFG';  -- 生産営業単位
/* 2009/07/28 Ver.1.11 Add Start */
  cv_pf_interval                CONSTANT VARCHAR2(30) := 'XXCOS1_INTERVAL';      -- 待機間隔
  cv_pf_max_wait                CONSTANT VARCHAR2(30) := 'XXCOS1_MAX_WAIT';      -- 最大待機間隔
/* 2009/07/28 Ver.1.11 Add End   */
  -- メッセージトークン
  cv_tkn_profile                CONSTANT VARCHAR2(20) := 'PROFILE';             -- プロファイル名
  cv_tkn_param1                 CONSTANT VARCHAR2(20) := 'PARAM1';              -- パラメータ1
  cv_tkn_param2                 CONSTANT VARCHAR2(20) := 'PARAM2';              -- パラメータ2
--****************************** 2009/05/26 1.7 T.Kitajima ADD START ******************************--
  cv_tkn_param3                 CONSTANT VARCHAR2(20) := 'PARAM3';              -- パラメータ3
--****************************** 2009/05/26 1.7 T.Kitajima ADD  END  ******************************--
  cv_tkn_table_name             CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- テーブル名
  cv_tkn_key_data               CONSTANT VARCHAR2(20) := 'KEY_DATA';            -- キー情報
  cv_tkn_order_no               CONSTANT VARCHAR2(20) := 'ORDER_NO';            -- 受注番号
  cv_tkn_line_no                CONSTANT VARCHAR2(20) := 'LINE_NO';             -- 明細番号
  cv_tkn_field_name             CONSTANT VARCHAR2(20) := 'FIELD_NAME';          -- 項目名
  cv_tkn_table                  CONSTANT VARCHAR2(20) := 'TABLE';               -- テーブル
  cv_tkn_divide_value           CONSTANT VARCHAR2(20) := 'DIVIDE_VALUE';        -- 区分値
  cv_tkn_val                    CONSTANT VARCHAR2(20) := 'VAL';                 -- 値
  cv_tkn_order_date             CONSTANT VARCHAR2(20) := 'ORDER_DATE';          -- 受注日
  cv_tkn_operation_date         CONSTANT VARCHAR2(20) := 'OPERATION_DATE';      -- 算出受注日
  cv_tkn_code_from              CONSTANT VARCHAR2(20) := 'CODE_FROM';           -- コード区分From
  cv_tkn_stock_from             CONSTANT VARCHAR2(20) := 'STOCK_FROM';          -- 入出庫区分From
  cv_tkn_code_to                CONSTANT VARCHAR2(20) := 'CODE_TO';             -- コード区分To
  cv_tkn_stock_to               CONSTANT VARCHAR2(20) := 'STOCK_TO';            -- 入出庫区分To
  cv_tkn_stock_form_id          CONSTANT VARCHAR2(20) := 'STOCK_FORM_ID';       -- 出庫形態ID
  cv_tkn_base_date              CONSTANT VARCHAR2(20) := 'BASE_DATE';           -- 基準日
  cv_tkn_operate_date           CONSTANT VARCHAR2(20) := 'OPERATE_DATE';        -- 出荷予定日
  cv_tkn_whse_locat             CONSTANT VARCHAR2(20) := 'WHSE_LOCAT';          -- 保管倉庫コード
  cv_tkn_delivery_code          CONSTANT VARCHAR2(20) := 'DELIVERY_CODE';       -- 配送先コード
  cv_tkn_lead_time              CONSTANT VARCHAR2(20) := 'LEAD_TIME';           -- リードタイム
  cv_tkn_commodity_class        CONSTANT VARCHAR2(20) := 'COMMODITY_CLASS';     -- 商品区分
  cv_tkn_type                   CONSTANT VARCHAR2(20) := 'TYPE';                -- 参照タイプ
  cv_tkn_code                   CONSTANT VARCHAR2(20) := 'CODE';                -- 参照コード
  -- 参照タイプ
  cv_hokan_type_mst_t           CONSTANT VARCHAR2(50) := 'XXCOS1_HOKAN_DIRECT_TYPE_MST';        -- 保管場所分類
  cv_hokan_type_mst_c           CONSTANT VARCHAR2(50) := 'XXCOS_DIRECT_11';                     -- 保管場所分類
  cv_tran_type_mst_t            CONSTANT VARCHAR2(50) := 'XXCOS1_TRAN_TYPE_MST_008_A01';        -- 受注タイプ
  cv_non_inv_item_mst_t         CONSTANT VARCHAR2(50) := 'XXCOS1_NO_INV_ITEM_CODE';             -- 非在庫品目
  cv_shipping_class_t           CONSTANT VARCHAR2(50) := 'XXWSH_SHIPPING_CLASS';                -- 出荷区分(タイプ)
  cv_shipping_class_c           CONSTANT VARCHAR2(50) := '02';                                  -- 出荷区分(コード)
  -- 日時フォーマット
  cv_date_fmt_date_time         CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt_no_sep            CONSTANT VARCHAR2(25) := 'YYYYMMDD';
  --データチェックステータス値
  cn_check_status_normal        CONSTANT  NUMBER := 0;                    -- 正常
  cn_check_status_error         CONSTANT  NUMBER := -1;                   -- エラー
  -- 記帳フラグ
  cv_booked_flag_end            CONSTANT VARCHAR2(1) := 'Y';              -- 済み
  -- 有効フラグ
  cv_enabled_flag               CONSTANT VARCHAR2(1) := 'Y';              -- 有効
  --
  cn_customer_div_cust          CONSTANT  VARCHAR2(4)   := '10';          -- 顧客
  cv_cust_site_use_code         CONSTANT  VARCHAR2(10)  := 'SHIP_TO';     --顧客使用目的：出荷先
  -- 明細ステータス
  cv_flow_status_cancelled      CONSTANT VARCHAR2(10) := 'CANCELLED';     -- 取消
  cv_flow_status_closed         CONSTANT VARCHAR2(10) := 'CLOSED';        -- クローズ
  -- 文字定数
  cv_blank                      CONSTANT VARCHAR2(1) := '';               -- 空文字
  -- リードタイム
  cn_lead_time_non              CONSTANT NUMBER := 0;                     -- リードタイムなし
--****************************** 2009/05/15 1.7 T.Kitajima ADD START ******************************--
  --送信フラグ
  cv_new_send                   CONSTANT VARCHAR2(1)  := '1';
  cv_re_send                    CONSTANT VARCHAR2(1)  := '2';
--****************************** 2009/05/15 1.7 T.Kitajima ADD  END  ******************************--
--****************************** 2009/07/07 1.8 T.Miyata ADD  START ******************************--
  --顧客マスタ系の有効フラグ
  cv_cust_status_active         CONSTANT VARCHAR2(1)  := 'A';             -- 有効
--****************************** 2009/07/07 1.8 T.Miyata ADD  END   ******************************--
/* 2009/07/14 Ver1.10 Add Start */
  --情報区分
  cv_target_order_01            CONSTANT VARCHAR2(2)  := '01';            -- 受注作成対象01
/* 2009/07/14 Ver1.10 Add End   */
/* 2009/09/16 Ver.1.12 Add Start */
  cv_lang                       CONSTANT VARCHAR2(5)  := USERENV('LANG');              -- 言語
  cv_prod_class_drink           CONSTANT VARCHAR2(1)  := '2';                          -- 商品区分:ドリンク
  cv_prod_class_leaf            CONSTANT VARCHAR2(1)  := '1';                          -- 商品区分:リーフ
  cn_inactive_ind_on            CONSTANT NUMBER       := 1;                            -- 無効区分：無効
  cv_obsolete_class_on          CONSTANT VARCHAR2(1)  := '1';                          -- 廃止区分：廃止
  cv_weight_capacity_class      CONSTANT VARCHAR2(30) := 'XXCOS1_WEIGHT_CAPACITY_CLASS';  -- 重量容積区分
  cv_pf_organization_cd         CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';   -- XXCOI:在庫組織コード
  cv_resp_prod                  CONSTANT VARCHAR2(50) := 'XXCOS1_RESPONSIBILITY_PRODUCTION';  -- プロファイル：生産への切替用職責
  cv_weight_capacity_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13951';           -- 重量容積区分取得エラー
  cv_msg_get_login              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11638';           -- ログイン情報取得エラー
  cv_msg_get_resp               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11639';           -- プロファイル(切替用職責)取得エラー
  cv_msg_get_login_prod         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11640';           -- 切替先ログイン情報取得エラー
  cv_uom_cnv_err                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11648';           -- 基準単位・基準数量取得エラー
  cv_calc_total_value_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11649';           -- 合計重量・合計容積取得エラー
  cv_base_code_err              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13952';           -- 拠点取得エラー
  cv_delivery_code_err          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13953';           -- 配送先取得エラー
  cv_max_ship_method_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13954';           -- 最大配送区分取得エラー
  cv_leaf_capacity_over_err     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13955';           -- リーフ積載効率オーバー
  cv_msg_item_name              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13956';           -- メッセージ文字列:品目
  cv_msg_quantity               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13957';           -- メッセージ文字列:数量
  cv_calc_load_efficiency_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13958';           -- 積載効率算出エラー
  cv_msg_max_ship_methods       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13959';           -- 小口区分取得エラー
  cv_msg_quantity_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13960';           -- 受注数量エラー
  cv_msg_warn_end               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13961';           -- 警告終了メッセージ
  cv_msg_item_set_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13962';           -- 品目マスタ設定エラー
  cv_msg_palette_qty            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13963';           -- メッセージ文字:パレ配数
  cv_msg_step_qty               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13964';           -- メッセージ文字:パレ段数
  cv_line_insert_err            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';           -- データ登録エラー
  cv_msg_organization_id        CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';           -- 在庫組織ID取得エラーメッセージ
  cv_msg_organization_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00048';           -- XXCOI:在庫組織コード
  cv_tkn_org_code_tok           CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';               -- 在庫組織コード
  cv_tkn_order_source           CONSTANT VARCHAR2(30) := 'ORDER_SOURCE';               -- 出荷依頼NO
  cv_tkn_ship_method            CONSTANT VARCHAR2(30) := 'SHIP_METHOD';                -- 出荷方法
  cv_tkn_schedule_ship_date     CONSTANT VARCHAR2(30) := 'SCHEDULE_SHIP_DATE';         -- 出荷予定日
  cv_tkn_item_code              CONSTANT VARCHAR2(30) := 'ITEM_CODE';                  -- 品目
  cv_tkn_ordered_quantity       CONSTANT VARCHAR2(30) := 'ORDERED_QUANTITY';           -- 受注数量
  cv_tkn_case_quantity          CONSTANT VARCHAR2(30) := 'CASE_QUANTITY';              -- ケース入数
  cv_tkn_MAX_SHIP_METHODS       CONSTANT VARCHAR2(30) := 'MAX_SHIP_METHODS';           -- 最大配送区分
  cv_tkn_quantity               CONSTANT VARCHAR2(30) := 'ORDERED_QUANTITY';
  cv_tkn_schedule_date          CONSTANT VARCHAR2(30) := 'SCHEDULE_SHIP_DATE';
  cv_tkn_err_msg                CONSTANT VARCHAR2(30) := 'ERR_MSG';
  gn_deliv_cnt                  NUMBER DEFAULT 1;                                      -- 出荷依頼IF用PL/SQL表カウンタ
  gn_organization_id            NUMBER;                                                -- 在庫組織ID
  gv_weight_class_leaf          VARCHAR2(1);
  gv_weight_class_drink         VARCHAR2(1);
  gt_shipping_class             fnd_lookup_values.attribute2%TYPE;                     -- 出荷依頼区分
  gn_check_flag_on              CONSTANT NUMBER := '1';
/* 2009/09/16 Ver.1.12 Add End */
/* 2009/11/04 Ver.1.14 Add Start */
  gt_input_base_code            xxcmn_cust_accounts_v.party_number%TYPE;                      -- 入力拠点
  cv_msg_get_input_base         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11642';                  -- 入力拠点取得エラー
/* 2009/11/04 Ver.1.14 Add End */
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_id                     fnd_profile_option_values.profile_option_value%TYPE;      -- MO:営業単位
  gt_ou_mfg                     fnd_profile_option_values.profile_option_value%TYPE;      -- 生産営業単位
  gd_business_date              DATE;                                                     -- 業務日付
  gn_prod_ou_id                 NUMBER;                                                   -- 生産営業単位ID
  gv_hokan_direct_class         VARCHAR2(10);                                             -- 保管場所分類(直送倉庫)
/* 2009/07/28 Ver.1.11 Add Start */
  gt_max_wait                   fnd_profile_option_values.profile_option_value%TYPE;      -- 最大監視時間
  gt_interval                   fnd_profile_option_values.profile_option_value%TYPE;      -- 監視間隔
/* 2009/07/28 Ver.1.11 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR order_data_cur(
--****************************** 2009/05/15 1.7 T.Kitajima ADD START ******************************--
    iv_send_flg     IN  VARCHAR2,     -- 新規/再送区分
--****************************** 2009/05/15 1.7 T.Kitajima ADD  END  ******************************--
    iv_base_code    IN  VARCHAR2,     -- 拠点コード
    iv_order_number IN  VARCHAR2)     -- 受注番号
  IS
/* 2009/09/16 Ver.1.12 Mod Start */
    SELECT 
           /*+
                 LEADING(xca)
                 INDEX(xca xxcmm_cust_accounts_n21)
                 USE_NL(hca ooha ottah flv_tran)
                 USE_NL(ooha oola ottal msi)
           */
           ooha.context                              context                 -- 受注タイプ
--    SELECT ooha.context                              context                 -- 受注タイプ
/* 2009/09/16 Ver.1.12 Mod End */
          ,TRUNC(ooha.ordered_date)                  ordered_date            -- 受注日
          ,ooha.sold_to_org_id                       sold_to_org_id          -- 顧客コード
          ,ooha.shipping_instructions                shipping_instructions   -- 出荷指示
/* 2009/09/16 Ver.1.12 Mod Start */
          ,NVL(ooha.attribute19,
               DECODE(SUBSTR(ooha.cust_po_number, 1, 1),'I','', ooha.cust_po_number))
                                                      cust_po_number          -- 顧客発注
--          ,ooha.cust_po_number                       cust_po_number          -- 顧客発注
/* 2009/09/16 Ver.1.12 Mod End */
          ,TRUNC(oola.request_date)                  request_date            -- 要求日
          ,NVL(oola.attribute6, oola.ordered_item)   child_code              -- 受注品目
          ,TRUNC(oola.schedule_ship_date)            schedule_ship_date      -- 予定出荷日
          ,oola.ordered_quantity                     ordered_quantity        -- 受注数量
          ,xca.delivery_base_code                    delivery_base_code      -- 納品拠点コード
/* 2009/09/16 Ver.1.12 Mod Start */
           ,NULL                                      province                -- 配送先コード      A-17で設定
--          ,hl.province                               province                -- 配送先コード
/* 2009/09/16 Ver.1.12 Mod End */
/* 2009/12/07 Ver1.19 Mod Start */
          ,NVL(oola.attribute6, oola.ordered_item)   item_code               -- 品目コード
          ,oola.ordered_item                          parent_item_code       -- 親品目コード
          ,oola.context                               line_context           -- コンテキスト
--          ,msib.segment1                             item_code               -- 品目コード
/* 2009/12/07 Ver1.19 Mod End */
          ,xicv.prod_class_name                      item_div_name           -- 商品区分名
          ,xicv.prod_class_code                      prod_class_code         -- 商品区分コード
          ,ooha.order_number                         order_number            -- 受注番号
          ,oola.line_number                          line_number             -- 明細番号
          ,oola.rowid                                row_id                  -- 行ID
          ,oola.attribute5                           sales_class             -- 売上区分
          ,msib.customer_order_enabled_flag          customer_order_flag     -- 顧客受注可能
          ,msib.inventory_item_id                    inventory_item_id       -- 品目ID
          ,oola.order_quantity_uom                   order_quantity_uom      -- 受注単位
          ,ooha.attribute19                          cust_po_number_att19    -- 顧客発注
          ,oola.line_id                              line_id                 -- 明細ID
          ,oola.ship_from_org_id                     ship_from_org_id        -- 組織ID
          ,NVL(oola.attribute8,ooha.attribute13)     time_from               -- 時間指定FROM
          ,NVL(oola.attribute9,ooha.attribute14)     time_to                 -- 時間指定TO
          ,ooha.header_id                            header_id               -- ヘッダID
          ,NULL                                      ship_to_subinv          -- 出荷元保管場所(A-3で設定)
          ,NULL                                      lead_time               -- リードタイム(生産物流)
          ,NULL                                      delivery_lt             -- リードタイム(配送)
          ,NULL                                      req_header_id           -- 出荷依頼用ヘッダーID
          ,NULL                                      conv_ordered_quantity   -- 換算後受注数量
          ,NULL                                      conv_order_quantity_uom -- 換算後受注単位
/* 2009/09/16 Ver.1.12 Mod Start */
          ,NULL                                      head_sort_key           -- ヘッダー集約(ソート)キー   A-5で設定
--          ,NULL                                      sort_key                -- ソートキー
/* 2009/09/16 Ver.1.12 Mod End */
          ,cn_check_status_normal                    check_status            -- チェックステータス
/* 2009/09/16 Ver.1.12 Add Start */
          ,xca.rsv_sale_base_code                    rsv_sale_base_code      -- 予約売上拠点コード
          ,xca.rsv_sale_base_act_date                rsv_sale_base_act_date  -- 予約売上拠点有効開始日
          ,hca.account_number                        account_number          -- 顧客コード
          ,oola.ship_to_org_id                       ship_to_org_id          -- 出荷先組織ID
          ,oola.order_source_id                      order_source_ref        -- 受注ソース参照
          ,oola.packing_instructions                 packing_instructions    -- 出荷依頼NO
          ,oola.line_type_id                         line_type_id            -- 明細タイプ
          ,oola.attribute1                           attribute1
          ,oola.attribute2                           attribute2
          ,oola.attribute3                           attribute3
          ,oola.attribute4                           attribute4
          ,oola.attribute5                           attribute5
          ,oola.attribute6                           attribute6
          ,oola.attribute7                           attribute7
          ,oola.attribute8                           attribute8
          ,oola.attribute9                           attribute9
          ,oola.attribute10                          attribute10
          ,oola.attribute11                          attribute11
          ,oola.attribute12                          attribute12
          ,oola.attribute13                          attribute13
          ,oola.attribute14                          attribute14
          ,oola.attribute15                          attribute15
          ,oola.attribute16                          attribute16
          ,oola.attribute17                          attribute17
          ,oola.attribute18                          attribute18
          ,oola.attribute19                          attribute19
          ,oola.attribute20                          attribute20
          ,oola.global_attribute1                    global_attribute1
          ,oola.global_attribute2                    global_attribute2
          ,oola.global_attribute3                    global_attribute3
          ,oola.global_attribute4                    global_attribute4
          ,oola.global_attribute5                    global_attribute5
          ,oola.global_attribute6                    global_attribute6
          ,oola.global_attribute7                    global_attribute7
          ,oola.global_attribute8                    global_attribute8
          ,oola.global_attribute9                    global_attribute9
          ,oola.global_attribute10                   global_attribute10
          ,oola.global_attribute11                   global_attribute11
          ,oola.global_attribute12                   global_attribute12
          ,oola.global_attribute13                   global_attribute13
          ,oola.global_attribute14                   global_attribute14
          ,oola.global_attribute15                   global_attribute15
          ,oola.global_attribute16                   global_attribute16
          ,oola.global_attribute17                   global_attribute17
          ,oola.global_attribute18                   global_attribute18
          ,oola.global_attribute19                   global_attribute19
          ,oola.global_attribute20                   global_attribute20
          ,DECODE(xim.palette_max_step_qty, NULL, 1, 0, 1, xim.palette_max_step_qty)
                                                     palette_max_step_qty    -- パレット当り最大段数
          ,DECODE(xim.palette_max_cs_qty, NULL, 1, 0, 1,xim.palette_max_cs_qty)  palette_max_cs_qty     -- パレ配数
          ,DECODE(xicv.prod_class_code, cv_prod_class_leaf,  gv_weight_class_leaf
                                      , cv_prod_class_drink, gv_weight_class_drink, NULL)    wc_class   -- 重量容積区分
          ,DECODE(iim.attribute11, NULL, 1, '0', 1, TO_NUMBER(iim.attribute11))              qty_case   -- 本数/ケース
          ,DECODE(iim.attribute11, NULL, 1, '0', 1, TO_NUMBER(iim.attribute11))
             *
             DECODE(xim.palette_max_cs_qty, NULL, 1, 0, 1, xim.palette_max_cs_qty)           qty_step   -- 本数/段
          ,DECODE(xim.palette_max_step_qty, NULL, 1, 0, 1, xim.palette_max_step_qty)
             *
             DECODE(iim.attribute11, NULL, 1, 0, 1, TO_NUMBER(iim.attribute11))
             *
             DECODE(xim.palette_max_cs_qty, NULL, 1, 0, 1, xim.palette_max_cs_qty)           qty_palette   -- 本数/パレット
          ,xim.palette_max_cs_qty                    original_palette_max_cs_qty                -- パレ配数
          ,xim.palette_max_step_qty                  original_palette_max_step_qty              -- パレ段数
          ,oola.schedule_ship_date                   original_schedule_ship_date                -- 予定出荷日
          ,oola.request_date                         original_request_date                      -- 要求日
          ,oola.subinventory                         subinventory                               -- 保管場所
          ,oola.unit_selling_price                   unit_selling_price                         -- 販売単価
          ,oola.orig_sys_line_ref                    orig_sys_line_ref                          -- 明細番号
          ,NULL                                      base_code               -- 拠点(納品拠点 or 予約売上拠点)  A-17で設定
          ,NULL                                      sum_pallet_weight       -- 合計パレット重量  A-5で設定
          ,NULL                                      base_quantity           -- 換算後数量        A-6で設定
          ,NULL                                      add_base_quantity       -- 基本数量          A-6で設定(合算値)
          ,NULL                                      add_sum_weight          -- 合計重量          A-6で設定(合算値)
          ,NULL                                      add_sum_capacity        -- 合計容積          A-6で設定(合算値)
          ,NULL                                      add_sum_pallet_weight   -- 合計パレット重量  A-6で設定(合算値)
          ,NULL                                      weight                  -- 重量容積          A-6で設定
          ,0                                         checked_quantity        -- チェック済数量    A-15で設定
          ,NULL                                      delivery_unit           -- 出荷依頼単位
          ,NULL                                      order_source            -- 出荷依頼No        A-15で設定
          ,NULL                                      efficiency_over_flag    -- 積載効率オーバフラグ  A-15で設定
          ,NULL                                      max_ship_methods        -- 出荷方法
          ,NULL                                      line_key                -- 出荷依頼明細単位  A-5で設定
          ,0                                         conv_palette            -- パレット換算数
          ,0                                         conv_step               -- 段数
          ,0                                         conv_case               -- ケース
          ,0                                         total_conv_palette      -- パレット
          ,0                                         total_conv_step         -- 段
          ,0                                         total_conv_case         -- ケース
/* 2009/09/16 Ver.1.12 Add End */
/* 2009/09/19 Ver.1.13 Add Start */
          ,xca.sale_base_code                      sale_base_code      -- 売上拠点コード
/* 2009/09/19 Ver.1.13 Add End */
    FROM   oe_order_headers_all                   ooha             -- 受注ヘッダ
          ,oe_order_lines_all                     oola             -- 受注明細
          ,hz_cust_accounts                       hca              -- 顧客マスタ
          ,mtl_system_items_b                     msib             -- 品目マスタ
          ,oe_transaction_types_tl                ottah            -- 受注取引タイプ（受注ヘッダ用）
          ,oe_transaction_types_tl                ottal            -- 受注取引タイプ（受注明細用）
          ,mtl_secondary_inventories              msi              -- 保管場所マスタ
          ,xxcmn_item_categories5_v               xicv             -- 商品区分View
          ,xxcmm_cust_accounts                    xca              -- 顧客追加情報
/* 2009/09/16 Ver.1.12 Del Start */
--          ,hz_cust_acct_sites_all                 sites            -- 顧客所在地
--          ,hz_cust_site_uses_all                  uses             -- 顧客使用目的
--          ,hz_party_sites                         hps              -- パーティサイトマスタ
--          ,hz_locations                           hl               -- 顧客事業所マスタ
/* 2009/09/16 Ver.1.12 Del End */
          ,fnd_lookup_values                      flv_tran         -- LookUp参照テーブル(明細.受注タイプ)
/* 2009/09/16 Ver.1.12 Add Start */
          ,ic_item_mst_b                          iim              --OPM品目マスタ
          ,xxcmn_item_mst_b                       xim              --OPM品目アドオンマスタ
/* 2009/09/16 Ver.1.12 Add End */
    WHERE ooha.header_id                          = oola.header_id                            -- ヘッダーID
    AND   ooha.booked_flag                        = cv_booked_flag_end                        -- ステータス
/* 2009/07/14 Ver1.10 Add Start */
    AND   (
            ooha.global_attribute3 IS NULL
          OR
            ooha.global_attribute3 = cv_target_order_01
          )
/* 2009/07/14 Ver1.10 Add End   */
    AND   oola.flow_status_code                   NOT IN (cv_flow_status_cancelled
                                                         ,cv_flow_status_closed)              -- ステータス(明細)
    AND   ooha.sold_to_org_id                     = hca.cust_account_id                       -- 顧客ID
    AND   ooha.order_type_id                      = ottah.transaction_type_id                 -- 取引タイプID
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   ottah.language                          = cv_lang
--    AND   ottah.language                          = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
    AND   ottah.name                              = flv_tran.attribute1                       -- 取引名称
    AND   oola.line_type_id                       = ottal.transaction_type_id
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   ottal.language                          = cv_lang
--    AND   ottal.language                          = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
    AND   ottal.name                              = flv_tran.attribute2                       -- 取引名称
    AND   oola.subinventory                       = msi.secondary_inventory_name              -- 保管場所
    AND   msi.attribute13                         = gv_hokan_direct_class                     -- 保管場所区分
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   xca.delivery_base_code                  = iv_base_code                                -- 納品拠点コード
--    AND   xca.delivery_base_code                  = NVL(iv_base_code, xca.delivery_base_code) -- 納品拠点コード
/* 2009/09/16 Ver.1.12 Mod End */
    AND   ooha.order_number                       = NVL(iv_order_number, ooha.order_number)   -- 受注ヘッダ番号
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--    AND   oola.packing_instructions               IS NULL                                     -- 出荷依頼
    AND   ( 
            ( --新規
                  ( iv_send_flg               = cv_new_send )
              AND ( oola.packing_instructions IS NULL       )
            )
            OR
            ( --再送
                  ( iv_send_flg               = cv_re_send  )
              AND ( oola.packing_instructions IS NOT NULL   )
              AND NOT EXISTS (
                              SELECT xoha.request_no
                                FROM xxwsh_order_headers_all xoha                    -- 受注ヘッダアドオン
                               WHERE xoha.request_no    = oola.packing_instructions  -- 依頼No = 受注明細.出荷依頼No(梱包指示)
                             )
            )
          )
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
    AND   xca.customer_id                         = hca.cust_account_id                       -- 顧客ID
    AND   oola.org_id                             = gt_org_id                                 -- 営業単位
/* 2009/12/07 Ver1.19 Mod Start */
    AND   NVL(oola.attribute6, oola.ordered_item) = msib.segment1                             -- 品目コード
--    AND   oola.ordered_item                       = msib.segment1                             -- 品目コード
/* 2009/12/07 Ver1.19 Mod End */
    AND   xicv.item_no                            = msib.segment1                             -- 品目コード
    AND   msib.organization_id                    = oola.ship_from_org_id                     -- 組織ID
/* 2009/09/16 Ver.1.12 Del Start */
--    AND   hca.cust_account_id                     = sites.cust_account_id                     -- 顧客ID
--    AND   sites.cust_acct_site_id                 = uses.cust_acct_site_id                    -- 顧客サイトID
/* 2009/09/16 Ver.1.12 Del End */
    AND   hca.customer_class_code                 = cn_customer_div_cust                      -- 顧客区分(顧客)
/* 2009/09/16 Ver.1.12 Del Start */
--    AND   uses.site_use_code                      = cv_cust_site_use_code                     -- 顧客使用目的(出荷先)
--    AND   sites.org_id                            = gn_prod_ou_id                             -- 生産営業単位
--    AND   uses.org_id                             = gn_prod_ou_id                             -- 生産営業単位
----****************************** 2009/07/07 1.8 T.Miyata ADD  START ******************************--
--    AND   sites.status                            = cv_cust_status_active                     -- 顧客所在地.ステータス
----****************************** 2009/07/07 1.8 T.Miyata ADD  END   ******************************--
--    AND   sites.party_site_id                     = hps.party_site_id                         -- パーティサイトID
--    AND   hps.location_id                         = hl.location_id                            -- 事業所ID
/* 2009/09/16 Ver.1.12 Del End */
    AND   hca.account_number                      IS NOT NULL                                 -- 顧客番号
/* 2009/09/16 Ver.1.12 Del Start */
--    AND   hl.province                             IS NOT NULL                                 -- 配送先コード
/* 2009/09/16 Ver.1.12 Del End */
    AND   NVL(oola.attribute6,oola.ordered_item) 
              NOT IN ( SELECT flv_non_inv.lookup_code
                       FROM   fnd_lookup_values             flv_non_inv
                       WHERE  flv_non_inv.lookup_type       = cv_non_inv_item_mst_t
/* 2009/09/16 Ver.1.12 Mod Start */
                       AND    flv_non_inv.language          = cv_lang
--                       AND    flv_non_inv.language          = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
                       AND    flv_non_inv.enabled_flag      = cv_enabled_flag)
--                       AND    flv_non_inv.enabled_flag      = cv_enabled_flag)
    AND   flv_tran.lookup_type                    = cv_tran_type_mst_t
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   flv_tran.language                       = cv_lang
--    AND   flv_tran.language                       = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
    AND   flv_tran.enabled_flag                   = cv_enabled_flag
/* 2009/09/16 Ver.1.12 Add Start */
    AND   msi.organization_id                         = gn_organization_id
    AND   msib.organization_id                        = gn_organization_id
    AND   iim.item_no                                 = msib.segment1
    AND   iim.item_id                                 = xim.item_id
    AND   xim.start_date_active                      <= oola.request_date
    AND   NVL(xim.end_date_active,oola.request_date) >= oola.request_date
    AND   iim.inactive_ind                           <> cn_inactive_ind_on
    AND   xim.obsolete_class                         <> cv_obsolete_class_on
/* 2009/09/16 Ver.1.12 Add End */
    FOR UPDATE OF  oola.line_id
                  ,ooha.header_id
    NOWAIT
    ;
  -- ===============================
  -- ユーザー定義グローバル
  -- ===============================
  -- 受注情報テーブル
  TYPE g_n_order_data_ttype IS TABLE OF order_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE g_v_order_data_ttype IS TABLE OF order_data_cur%ROWTYPE INDEX BY VARCHAR(1000);
--
  -- 出荷依頼ヘッダ情報テーブル
  -- ヘッダID
  TYPE g_tab_h_header_id
         IS TABLE OF xxwsh_shipping_headers_if.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注日
  TYPE g_tab_h_ordered_date
         IS TABLE OF xxwsh_shipping_headers_if.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先
  TYPE g_tab_h_party_site_code
         IS TABLE OF xxwsh_shipping_headers_if.party_site_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷指示
  TYPE g_tab_h_shipping_instructions
         IS TABLE OF xxwsh_shipping_headers_if.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客発注
  TYPE g_tab_h_cust_po_number
         IS TABLE OF xxwsh_shipping_headers_if.cust_po_number%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ソース参照
  TYPE g_tab_h_order_source_ref
         IS TABLE OF xxwsh_shipping_headers_if.order_source_ref%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷予定日
  TYPE g_tab_h_schedule_ship_date
         IS TABLE OF xxwsh_shipping_headers_if.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷予定日
  TYPE g_tab_h_schedule_arrival_date
         IS TABLE OF xxwsh_shipping_headers_if.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元
  TYPE g_tab_h_location_code
         IS TABLE OF xxwsh_shipping_headers_if.location_code%TYPE INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE g_tab_h_head_sales_branch
         IS TABLE OF xxwsh_shipping_headers_if.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 入力拠点
  TYPE g_tab_h_input_sales_branch
         IS TABLE OF xxwsh_shipping_headers_if.input_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間From
  TYPE g_tab_h_arrival_time_from
         IS TABLE OF xxwsh_shipping_headers_if.arrival_time_from%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間To
  TYPE g_tab_h_arrival_time_to
         IS TABLE OF xxwsh_shipping_headers_if.arrival_time_to%TYPE INDEX BY BINARY_INTEGER;
  -- データタイプ
  TYPE g_tab_h_data_type
         IS TABLE OF xxwsh_shipping_headers_if.data_type%TYPE INDEX BY BINARY_INTEGER;
  -- 受注番号
  TYPE g_tab_h_order_number
         IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  -- 依頼区分
  TYPE g_tab_h_order_class
         IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
  -- 出荷依頼明細情報テーブル
  -- ヘッダID
  TYPE g_tab_l_header_id
         IS TABLE OF xxwsh_shipping_lines_if.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE g_tab_l_line_number
         IS TABLE OF xxwsh_shipping_lines_if.line_number%TYPE INDEX BY BINARY_INTEGER;
  -- 明細ID
  TYPE g_tab_l_line_id
         IS TABLE OF oe_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注品目
  TYPE g_tab_l_orderd_item_code
         IS TABLE OF xxwsh_shipping_lines_if.orderd_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 数量
  TYPE g_tab_l_orderd_quantity
         IS TABLE OF xxwsh_shipping_lines_if.orderd_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 組織
  TYPE g_tab_l_ship_from_org_id
         IS TABLE OF oe_order_lines_all.ship_from_org_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- 受注明細情報テーブル
  -- ヘッダID
  TYPE g_tab_l_upd_header_id
         IS TABLE OF oe_order_lines_all.header_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- 受注明細更新用レコード変数
  TYPE gr_upd_order_line_rec IS RECORD(
     header_id                NUMBER                                              -- ヘッダーID(受注)
    ,order_source_ref         xxwsh_shipping_headers_if.order_source_ref%TYPE     -- 受注ソース参照(梱包指示)
    ,order_number             oe_order_headers_all.order_number%TYPE              -- 受注番号
    ,line_id                  oe_order_lines_all.line_id%TYPE                     -- 明細ID
    ,line_number              oe_order_lines_all.line_number%TYPE                 -- 明細番号
    ,ship_from_org_id         oe_order_lines_all.ship_from_org_id%TYPE            -- 組織ID
    ,req_header_id            NUMBER                                              -- ヘッダーID(出荷依頼)
/* 2009/09/16 Ver.1.12 Add Start */
    ,upd_status               VARCHAR2(1) DEFAULT NULL                            -- 更新ステイタス
/* 2009/09/16 Ver.1.12 Add End */
  );
  -- 受注明細更新用テーブル
  TYPE gt_upd_order_line_ttype IS TABLE OF gr_upd_order_line_rec INDEX BY BINARY_INTEGER;
  --
  -- (品目)区分値チェック結果用レコード変数
  TYPE gr_item_info_rtype IS RECORD(
     ship_class_flag       NUMBER DEFAULT cn_check_status_normal     -- 出荷区分
    ,sales_div_flag        NUMBER DEFAULT cn_check_status_normal     -- 売上対象区分
    ,rate_class_flag       NUMBER DEFAULT cn_check_status_normal     -- 率区分
    ,cust_order_flag       NUMBER DEFAULT cn_check_status_normal     -- 顧客受注可能フラグ
  );
  -- (品目)区分値チェック結果用テーブル
  TYPE gt_item_info_ttype IS TABLE OF gr_item_info_rtype INDEX BY VARCHAR(50);
--
  -- 出荷依頼ヘッダのインサート用変数定義
  gt_ins_h_header_id                   g_tab_h_header_id;                 -- ヘッダID
  gt_ins_h_ordered_date                g_tab_h_ordered_date;              -- 受注日
  gt_ins_h_party_site_code             g_tab_h_party_site_code;           -- 出荷先
  gt_ins_h_shipping_instructions       g_tab_h_shipping_instructions;     -- 出荷指示
  gt_ins_h_cust_po_number              g_tab_h_cust_po_number;            -- 顧客発注
  gt_ins_h_order_source_ref            g_tab_h_order_source_ref;          -- 受注ソース参照
  gt_ins_h_schedule_ship_date          g_tab_h_schedule_ship_date;        -- 出荷予定日
  gt_ins_h_schedule_arrival_date       g_tab_h_schedule_arrival_date;     -- 着荷予定日
  gt_ins_h_location_code               g_tab_h_location_code;             -- 出荷元
  gt_ins_h_head_sales_branch           g_tab_h_head_sales_branch;         -- 管轄拠点
  gt_ins_h_input_sales_branch          g_tab_h_input_sales_branch;        -- 入力拠点
  gt_ins_h_arrival_time_from           g_tab_h_arrival_time_from;         -- 着荷時間From
  gt_ins_h_arrival_time_to             g_tab_h_arrival_time_to;           -- 着荷時間To
  gt_ins_h_data_type                   g_tab_h_data_type;                 -- データタイプ
  gt_ins_h_order_number                g_tab_h_order_number;              -- 受注番号
  gt_ins_h_order_class                 g_tab_h_order_class;               -- 依頼区分
--
  -- 出荷依頼明細のインサート用変数定義
  gt_ins_l_header_id                   g_tab_l_header_id;                 -- ヘッダID
  gt_ins_l_line_number                 g_tab_l_line_number;               -- 明細番号
  gt_ins_l_line_id                     g_tab_l_line_id;                   -- 明細ID
  gt_ins_l_orderd_item_code            g_tab_l_orderd_item_code;          -- 受注品目
  gt_ins_l_orderd_quantity             g_tab_l_orderd_quantity;           -- 数量
  gt_ins_l_ship_from_org_id            g_tab_l_ship_from_org_id;          -- 組織
--
  -- 受注用変数定義
  gt_order_extra_tbl                   g_n_order_data_ttype;              -- 受注用抽出データ格納
  gt_order_sort_tbl                    g_v_order_data_ttype;              -- 受注用ソートデータ格納
  gt_order_sort_wk_tbl                 g_v_order_data_ttype;              -- 受注用ソートデータ格納
  gt_upd_order_line_tbl                gt_upd_order_line_ttype;           -- 明細更新用
  gt_upd_header_id                     g_tab_l_upd_header_id;             -- 明細更新用
/* 2009/09/16 Ver.1.12 Add Start */
  gt_normal_order_tbl                   g_v_order_data_ttype;              -- 正常受注用
  gt_delivery_if_wk_tbl                 g_n_order_data_ttype;              -- 出荷依頼用(ワーク)
  gt_order_upd_tbl                      g_n_order_data_ttype;              -- 受注明細更新用
  gt_order_ins_tbl                      g_n_order_data_ttype;              -- 受注明細登録用
  -- 受注明細登録用レコード変数
  TYPE gr_order_line_rtype IS RECORD(
      line_rec              oe_order_lines_all%ROWTYPE
     ,order_number          NUMBER
  );
  -- 受注明細登録用変数
  TYPE gt_line_ins_ttype IS TABLE OF  oe_order_lines_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_line_ins_tbl            gt_line_ins_ttype;
/* 2009/09/16 Ver.1.12 Add End */
--
  -- (品目)区分値チェック結果用変数定義
  gt_item_info_tbl                     gt_item_info_ttype;
  gt_item_info_rec                     gr_item_info_rtype;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- レコードロックエラー
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code     IN  VARCHAR2,            -- 1.拠点コード
--    iv_order_number  IN  VARCHAR2,            -- 2.受注番号
    iv_send_flg      IN  VARCHAR2,            -- 1.新規/再送区分
    iv_base_code     IN  VARCHAR2,            -- 2.拠点コード
    iv_order_number  IN  VARCHAR2,            -- 3.受注番号
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END  ******************************--
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    lv_profile_name              VARCHAR2(50);   -- プロファイル名
    lv_ou_org_name               VARCHAR2(50);   -- 生産営業単位名
    lv_out_msg                   VARCHAR2(100);  -- 出力用
    lv_key_info                  VARCHAR2(1000); -- キー情報
    lv_col_name                  VARCHAR2(50);   -- カラム名称
/* 2009/09/16 Ver.1.12 Add Start */
    lv_organization_cd   fnd_profile_option_values.profile_option_value%TYPE := NULL;     -- 在庫組織コード
/* 2009/09/16 Ver.1.12 Add End */
--
    -- *** ローカル例外 ***
    notfound_hokan_direct_expt   EXCEPTION;      -- 直送倉庫保管場所区分取得エラー
    notfound_ou_org_id_expt      EXCEPTION;      -- 生産営業単位取得エラー
/* 2009/09/16 Ver.1.12 Add Start */
    notfound_weight_capacity_expt EXCEPTION;     -- 重量区分取得エラー
/* 2009/09/16 Ver.1.12 Add End */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --===================================================
    --コンカレントプログラム入力項目をメッセージ作成
    --===================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
       iv_application  => cv_xxcos_short_name
      ,iv_name         => cv_msg_conc_parame      -- コンカレントパラメータ
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--      ,iv_token_name1  => cv_tkn_param1           -- 拠点コード
--      ,iv_token_value1 => iv_base_code
--      ,iv_token_name2  => cv_tkn_param2         -- 受注番号
--      ,iv_token_value2 => iv_order_number
      ,iv_token_name1  => cv_tkn_param1           -- 新規/再送区分
      ,iv_token_value1 => iv_send_flg
      ,iv_token_name2  => cv_tkn_param2           -- 拠点コード
      ,iv_token_value2 => iv_base_code
      ,iv_token_name3  => cv_tkn_param3           -- 受注番号
      ,iv_token_value3 => iv_order_number
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
   );
    --
    -- ===============================
    --  コンカレント・メッセージ出力
    -- ===============================
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 空行出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --
    -- ===============================
    --  コンカレント・ログ出力
    -- ===============================
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    --
    -- メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_out_msg
    ); 
    --
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    --
    -- ===============================
    --  MO:営業単位取得
    -- ===============================
    gt_org_id := FND_PROFILE.VALUE(
      name => cv_pf_org_id);
    --
    IF ( gt_org_id IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(営業単位)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_org_id                   -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  業務日付取得
    -- ===============================
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_business_date IS NULL ) THEN
      -- 業務日付が取得できない場合
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_non_business_date    -- メッセージ
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    --  生産営業単位取得名称
    -- ===============================
    gt_ou_mfg := FND_PROFILE.VALUE(
      name => cv_pf_ou_mfg);
    --
    IF ( gt_ou_mfg IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(生産営業単位取得名称)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_ou_mfg                   -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  生産営業単位ID取得
    -- ===============================
    BEGIN
      SELECT hou.organization_id    organization_id
      INTO   gn_prod_ou_id
      FROM   hr_operating_units hou
      WHERE  hou.name  = gt_ou_mfg;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 生産営業単位取得エラー
        -- メッセージ用文字列取得
        lv_col_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_col_name                 -- メッセージID
        );
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_col_name                     -- 名称
         ,iv_data_value1    => gt_ou_mfg
         ,ov_key_info       => lv_key_info                      -- 編集後キー情報
         ,ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
         ,ov_retcode        => lv_retcode                       -- リターンコード
         ,ov_errmsg         => lv_errmsg                        -- ユーザ・エラー・メッセージ
        );
        RAISE notfound_ou_org_id_expt;
    END;
    --
    -- ===============================
    --  保管場所分類取得(直送倉庫)
    -- ===============================
    BEGIN
      SELECT flv.meaning
      INTO   gv_hokan_direct_class
      FROM   fnd_lookup_values     flv
      WHERE  flv.lookup_type     = cv_hokan_type_mst_t
      AND    flv.lookup_code     = cv_hokan_type_mst_c
/* 2009/09/16 Ver.1.12 Mod Start */
      AND    flv.language        = cv_lang
--      AND    flv.language        = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
      AND    flv.enabled_flag    = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 直送倉庫保管場所分類取得エラー
        RAISE notfound_hokan_direct_expt;
    END;
/* 2009/07/28 Ver.1.11 Add Start */
--
    -- ===============================
    --  待機間隔
    -- ===============================
    gt_interval := FND_PROFILE.VALUE( name => cv_pf_interval );
    --
    IF ( gt_interval IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(待機間隔)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_interval                 -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    --  最大待機時間
    -- ===============================
    gt_max_wait := FND_PROFILE.VALUE( name => cv_pf_max_wait );
    --
    IF ( gt_max_wait IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(最大待機時間)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_max_wait                 -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2009/07/28 Ver.1.11 Add End */
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    --  重量容積区分
    -- ===============================
    BEGIN
      SELECT flv_l.attribute1     -- リーフ重量容積区分
             ,flv_d.attribute1    -- ドリンク重量容積区分
      INTO   gv_weight_class_leaf
             ,gv_weight_class_drink
      FROM  fnd_lookup_values  flv_l
            ,fnd_lookup_values  flv_d
      WHERE flv_l.lookup_type = cv_weight_capacity_class
      AND   flv_l.language    = cv_lang
      AND   flv_l.enabled_flag    = cv_enabled_flag
      AND   flv_l.lookup_code = cv_prod_class_leaf
      AND   flv_d.lookup_type = cv_weight_capacity_class
      AND   flv_d.language    = cv_lang
      AND   flv_d.enabled_flag    = cv_enabled_flag
      AND   flv_d.lookup_code = cv_prod_class_drink;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
          ,iv_name         => cv_weight_capacity_err      -- メッセージ
          ,iv_token_name1  => cv_tkn_type                 -- トークン1名
          ,iv_token_value1 => cv_weight_capacity_class);  -- トークン1値
        RAISE  notfound_weight_capacity_expt;
    END;
    --
    --==============================================================
    -- プロファイルの取得(XXCOI:在庫組織コード)
    --==============================================================
    lv_organization_cd := FND_PROFILE.VALUE( name => cv_pf_organization_cd );
--
    -- プロファイルが取得できなかった場合
    IF ( lv_organization_cd IS NULL ) THEN
      -- プロファイル（在庫組織コード）取得エラーを出力
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_organization_cd                   -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 在庫組織IDの取得
    --==============================================================
    IF ( lv_organization_cd IS NOT NULL ) THEN
--
      -- 在庫組織ID取得
      gn_organization_id := xxcoi_common_pkg.get_organization_id( lv_organization_cd );
--
      -- 在庫組織IDが取得できなかった場合
      IF ( gn_organization_id IS NULL ) THEN
        -- 在庫組織ID取得エラーを出力
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcoi_short_name         -- アプリケーション短縮名
          ,iv_name         => cv_msg_organization_id     -- メッセージ
          ,iv_token_name1  => cv_tkn_org_code_tok              -- トークン1名
          ,iv_token_value1 => lv_organization_cd);           -- トークン1値
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
    --
/* 2009/11/04 Ver.1.14 Add Start */
    --==============================================================
    -- ログインユーザの自拠点コードの取得
    --==============================================================
    BEGIN
      SELECT xlobi.base_code             input_base_code
        INTO gt_input_base_code
        FROM xxcos_login_own_base_info_v xlobi
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_input_base   -- 入力拠点取得エラー
                     );
        RAISE global_api_expt;
    END;
/* 2009/11/04 Ver.1.14 Add End */
  --
  EXCEPTION
/* 2009/09/16 Ver.1.12 Add Start */
    WHEN notfound_weight_capacity_expt THEN
      -- 重量区分取得エラー
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2009/09/16 Ver.1.12 Add End */
    WHEN notfound_ou_org_id_expt THEN
      -- 生産営業単位取得エラー
      lv_ou_org_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_ou_org_name              -- メッセージID
      );
       -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_data_extra_error
       ,iv_token_name1  => cv_tkn_table_name
       ,iv_token_value1 => lv_ou_org_name
       ,iv_token_name2  => cv_tkn_key_data
       ,iv_token_value2 => lv_key_info
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    WHEN notfound_hokan_direct_expt THEN
      --*** 直送倉庫保管場所分類取得エラー ***
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_hokan_direct_err
       ,iv_token_name1  => cv_tkn_type
       ,iv_token_value1 => cv_hokan_type_mst_t
       ,iv_token_name2  => cv_tkn_code
       ,iv_token_value2 => cv_hokan_type_mst_c
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_data
   * Description      : 受注データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_data(
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code      IN  VARCHAR2,            -- 1.拠点コード
--    iv_order_number   IN  VARCHAR2,            -- 2.受注番号
    iv_send_flg       IN  VARCHAR2,            -- 1.新規/再送区分
    iv_base_code      IN  VARCHAR2,            -- 2.拠点コード
    iv_order_number   IN  VARCHAR2,            -- 3.受注番号
 --****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
   ov_errbuf         OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_data'; -- プログラム名
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
    lv_table_name               VARCHAR2(50);    -- テーブル名
--
    -- *** ローカル例外 ***
    order_data_extra_expt       EXCEPTION;   -- データ抽出エラー
    notfound_order_data_expt    EXCEPTION;   -- 対象データなし
    lock_expt                   EXCEPTION;   -- ロックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      -- カーソルオープン
      OPEN order_data_cur(
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--         iv_base_code     => iv_base_code      -- 拠点コード
--        ,iv_order_number  => iv_order_number   -- 受注番号
         iv_send_flg      => iv_send_flg       -- 新規/再送区分
        ,iv_base_code     => iv_base_code      -- 拠点コード
        ,iv_order_number  => iv_order_number   -- 受注番号
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
      );
      --
      -- レコード読込み
      FETCH order_data_cur BULK COLLECT INTO gt_order_extra_tbl;
      --
      -- 抽出件数設定
      gn_target_cnt := gt_order_extra_tbl.COUNT;
      --
      -- カーソル・クローズ
      CLOSE order_data_cur;
    EXCEPTION
      -- ロックエラー
      WHEN record_lock_expt THEN
        RAISE lock_expt;
      WHEN OTHERS THEN
        -- 抽出に失敗した場合
        RAISE order_data_extra_expt;
    END;
    --
    -- 抽出件数チェック
    IF ( gt_order_extra_tbl.COUNT = 0 ) THEN
      -- 抽出データが無い場合
      RAISE notfound_order_data_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN
      --*** ロックエラー ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- メッセージ文字列取得
      lv_table_name := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_order_header_line
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_lock_error
       ,iv_token_name1  => cv_tkn_table
       ,iv_token_value1 => lv_table_name
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      --
    WHEN order_data_extra_expt THEN
      --*** データ抽出エラー ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- メッセージ文字列取得
      lv_table_name := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_order_table
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_data_extra_error
       ,iv_token_name1  => cv_tkn_table_name
       ,iv_token_value1 => lv_table_name
       ,iv_token_name2  => cv_tkn_key_data
       ,iv_token_value2 => cv_blank
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      --
    WHEN notfound_order_data_expt THEN
      --*** 抽出データなし ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_notfound_db_data
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_order_data;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_subinventory
   * Description      : 出荷元保管場所取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_ship_subinventory(
    it_order_rec          IN  order_data_cur%ROWTYPE,         -- 1.受注データ
    ov_ship_subinventory  OUT NOCOPY VARCHAR2,                -- 2.出荷保管場所
    ov_errbuf             OUT NOCOPY VARCHAR2,                --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,                --   リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)                --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_subinventory'; -- プログラム名
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
    cv_item_code            CONSTANT VARCHAR2(7) := 'ZZZZZZZ';       -- 品目コード
--
    -- *** ローカル変数 ***
    lv_ship_subinventory    VARCHAR2(50);             -- 出荷元保管場所
    lv_key_info             VARCHAR2(1000);           -- キー情報
    lv_table_name           VARCHAR2(50);             -- テーブル名
    lv_order_number         VARCHAR2(50);             -- 受注番号
    lv_line_number          VARCHAR2(50);             -- 明細番号
    lv_item_code            VARCHAR2(50);             -- 品目コード
    lv_send_code            VARCHAR2(50);             -- 配送先コード
    lv_deli_expect_date     VARCHAR2(50);             -- 納品予定日
    lv_base_code            VARCHAR2(50);             -- 拠点コード
    lv_message              VARCHAR2(500);            -- 出力メッセージ
--
    -- *** ローカル例外 ***
    ship_subinventory_expt  EXCEPTION;                -- 出荷元保管場所取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      -- ===============================
      -- 出荷元保管場所取得①
      -- ===============================
      BEGIN
        SELECT xsr.delivery_whse_code           -- 出荷保管倉庫コード
        INTO   lv_ship_subinventory
        FROM   xxcmn_sourcing_rules  xsr        -- 物流構成アドオンマスタ
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        WHERE  xsr.item_code               = it_order_rec.item_code            -- 品目コード
        WHERE  xsr.item_code               = it_order_rec.child_code           -- 品目コード
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
        AND    xsr.ship_to_code            = it_order_rec.province             -- 配送先コード
        AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                           AND     xsr.end_date_active;        -- 有効日To
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- レコードがない場合
          lv_ship_subinventory := NULL;
      END;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- 出荷元保管場所が取得できてない場合
        -- ===============================
        -- 出荷元保管場所取得②
        -- ===============================
        BEGIN
          SELECT xsr.delivery_whse_code           -- 出荷保管倉庫コード
          INTO   lv_ship_subinventory
          FROM   xxcmn_sourcing_rules  xsr        -- 物流構成アドオンマスタ
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--          WHERE  xsr.item_code               = it_order_rec.item_code            -- 品目コード
          WHERE  xsr.item_code               = it_order_rec.child_code           -- 品目コード
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
/* 2009/11/04 Ver.1.14 Mod Start */
          AND    xsr.base_code               = it_order_rec.base_code            -- 拠点コード
--          AND    xsr.base_code               = it_order_rec.delivery_base_code   -- 拠点コード
/* 2009/11/04 Ver.1.14 Mod End */
          AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                             AND     xsr.end_date_active;        -- 有効日To
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- レコードがない場合
            lv_ship_subinventory := NULL;
        END;
      END IF;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- 出荷元保管場所が取得できてない場合
        -- ===============================
        -- 出荷元保管場所取得③
        -- ===============================
        BEGIN
          SELECT xsr.delivery_whse_code            -- 出荷保管倉庫コード
          INTO   lv_ship_subinventory
          FROM   xxcmn_sourcing_rules  xsr         -- 物流構成アドオンマスタ
          WHERE  xsr.item_code               = cv_item_code                      -- 品目コード
          AND    xsr.ship_to_code            = it_order_rec.province             -- 配送先コード
          AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                             AND     xsr.end_date_active;        -- 有効日To
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- レコードがない場合
            lv_ship_subinventory := NULL;
        END;
      END IF;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- 出荷元保管場所が取得できてない場合
        -- ===============================
        -- 出荷元保管場所取得④
        -- ===============================
        SELECT xsr.delivery_whse_code           -- 出荷保管倉庫コード
        INTO   lv_ship_subinventory
        FROM   xxcmn_sourcing_rules  xsr        -- 物流構成アドオンマスタ
        WHERE  xsr.item_code               = cv_item_code                      -- 品目コード
/* 2009/11/04 Ver.1.14 Mod Start */
        AND    xsr.base_code               = it_order_rec.base_code            -- 拠点コード
--        AND    xsr.base_code               = it_order_rec.delivery_base_code   -- 拠点コード
/* 2009/11/04 Ver.1.14 Mod End */
        AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                           AND     xsr.end_date_active;        -- 有効日To
      END IF;
      --
      -- OUTパラメータ設定
      ov_ship_subinventory := lv_ship_subinventory;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- 出荷元保管場所取得④のSQLで抽出データなし、または、予期せぬエラーが発生した場合
        lv_ship_subinventory := NULL;
        --
        -- メッセージ文字列取得(出荷元保管場所)
        lv_table_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_ship_subinv              -- メッセージID
        );
        --
        -- メッセージ文字列取得(受注番号)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_order_number             -- メッセージID
        );
        --
        -- メッセージ文字列取得(明細番号)
        lv_line_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_line_number              -- メッセージID
        );
        --
        -- メッセージ文字列取得(品目コード)
        lv_item_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_item_code                -- メッセージID
        );
        --
        -- メッセージ文字列取得(配送先コード)
        lv_send_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_send_code                -- メッセージID
        );
        --
        -- メッセージ文字列取得(納品予定日)
        lv_deli_expect_date := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_deli_expect_date         -- メッセージID
        );
        --
        -- メッセージ文字列取得(拠点コード)
        lv_base_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_delivery_base_code      -- メッセージID
        );
        --
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- 受注番号
         ,iv_data_value1    => it_order_rec.order_number
         ,iv_item_name2     => lv_line_number                   -- 明細番号
         ,iv_data_value2    => it_order_rec.line_number
         ,iv_item_name3     => lv_item_code                     -- 品目コード
         ,iv_data_value3    => it_order_rec.item_code
         ,iv_item_name4     => lv_send_code                     -- 配送先コード
         ,iv_data_value4    => it_order_rec.province
         ,iv_item_name5     => lv_base_code                     -- 拠点コード
/* 2009/11/04 Ver.1.14 Mod Start */
         ,iv_data_value5    => it_order_rec.base_code
--         ,iv_data_value5    => it_order_rec.delivery_base_code
/* 2009/11/04 Ver.1.14 Mod End */
         ,iv_item_name6     => lv_deli_expect_date              -- 納品予定日
         ,iv_data_value6    => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
         ,ov_key_info       => lv_key_info                      -- 編集後キー情報
         ,ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
         ,ov_retcode        => lv_retcode                       -- リターンコード
         ,ov_errmsg         => lv_errmsg                        -- ユーザ・エラー・メッセージ
        );
        RAISE ship_subinventory_expt;
    END;
--
  EXCEPTION
    WHEN ship_subinventory_expt THEN
      --***  出荷元保管場所取得エラー ***
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_data_extra_error
        ,iv_token_name1  => cv_tkn_table_name
        ,iv_token_value1 => lv_table_name
        ,iv_token_name2  => cv_tkn_key_data
        ,iv_token_value2 => lv_key_info);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      ov_retcode := cv_status_warn;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ship_subinventory;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_schedule_date
   * Description      : 出荷予定日取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_ship_schedule_date(
    it_order_rec     IN  order_data_cur%ROWTYPE,          -- 1.受注データ
    od_oprtn_day     OUT DATE,                            -- 2.出荷予定日
    on_lead_time     OUT NUMBER,                          -- 3,リードタイム(生産物流)
    on_delivery_lt   OUT NUMBER,                          -- 4.リードタイム(配送)
    ov_errbuf        OUT NOCOPY VARCHAR2,                 --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,                 --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)                 --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_schedule_date'; -- プログラム名
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
    cv_code_from            CONSTANT VARCHAR2(1) := '4';   -- コード区分From(倉庫)
    cv_code_to              CONSTANT VARCHAR2(1) := '9';   -- コード区分To(配送先)
--
    -- *** ローカル変数 ***
    ln_lead_time             NUMBER;            -- リードタイム
    ln_delivery_lt           NUMBER;            -- 配送LT
    ld_oprtn_day             DATE;              -- 稼働日日付
    lv_msg_operate_date      VARCHAR2(30);      -- 出荷予定日
/* 2009/09/16 Ver.1.12 Add Start */
    ln_prod_user_id          NUMBER;
    ln_user_id               NUMBER;  -- ログインユーザID
    ln_resp_id               NUMBER;  -- ログイン職責ID
    ln_resp_appl_id          NUMBER;  -- ログイン職責アプリケーションID
    lt_resp_prod             fnd_profile_option_values.profile_option_value%TYPE;
    ln_prod_resp_id          NUMBER;  -- 切替先職責ID
    ln_prod_resp_appl_id     NUMBER;  -- 切替先職責アプリケーションID
/* 2009/09/16 Ver.1.12 Add End */
--
    -- *** ローカル変数 ***
    common_api_expt          EXCEPTION;      -- 共通APIエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    -- ログインユーザ情報取得
    -- ===============================
    BEGIN
      SELECT    fnd_global.user_id  -- ログインユーザID
              ,fnd_global.resp_id       -- ログイン職責ID
              ,fnd_global.resp_appl_id  -- ログイン職責アプリケーションID
      INTO     ln_user_id
              ,ln_resp_id
              ,ln_resp_appl_id
      FROM    dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login        -- ログイン情報取得エラー
                     );
        RAISE global_api_expt;
    END;
    --
    -- ===================================================
    --  プロファイル「XXCOS:生産への切替用職責名称」取得
    -- ===================================================
    lt_resp_prod := FND_PROFILE.VALUE(
      name => cv_resp_prod);
    --
    IF ( lt_resp_prod IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,      -- XXCOS
                     iv_name        => cv_msg_get_resp           -- プロファイル(切替用職責)取得エラー
                   );
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  切替先ログイン情報取得
    -- ===============================
    BEGIN
      SELECT  frv.responsibility_id    -- 切替先職責ID
              ,frv.application_id      -- 切替先職責アプリケーションID
      INTO    ln_prod_resp_id
              ,ln_prod_resp_appl_id
      FROM    fnd_responsibility_vl  frv
      WHERE   responsibility_name = lt_resp_prod
      AND     ROWNUM              = 1;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login_prod   -- 切替先ログイン情報取得エラー
                     );
        RAISE global_api_expt;
    END;
    --
    ln_prod_user_id := ln_user_id;
    --
    -- ===============================
    --  生産OUへのログイン切替
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
       user_id         => ln_prod_user_id            -- ユーザID
      ,resp_id         => ln_prod_resp_id            -- 職責ID
      ,resp_appl_id    => ln_prod_resp_appl_id       -- アプリケーションID
    );
/* 2009/09/16 Ver.1.12 Add End */
    -- ===============================
    -- リードタイム算出
    -- ===============================
    xxwsh_common910_pkg.calc_lead_time(
       iv_code_class1                => cv_code_from                     -- コード区分FROM
      ,iv_entering_despatching_code1 => it_order_rec.ship_to_subinv      -- 入出庫場所コードFROM
      ,iv_code_class2                => cv_code_to                       -- コード区分TO
      ,iv_entering_despatching_code2 => it_order_rec.province            -- 入出庫場所コードTO
      ,iv_prod_class                 => it_order_rec.prod_class_code     -- 商品区分
      ,in_transaction_type_id        => NULL                             -- 出庫形態ID
      ,id_standard_date              => it_order_rec.request_date        -- 基準日(適用日基準日)
      ,ov_retcode                    => lv_retcode                       -- リターンコード
      ,ov_errmsg_code                => lv_errbuf                        -- エラーメッセージコード
      ,ov_errmsg                     => lv_errmsg                        -- エラーメッセージ
      ,on_lead_time                  => ln_lead_time                     -- 生産物流LT／引取変更LT
      ,on_delivery_lt                => ln_delivery_lt                   -- 配送LT
    );
    --
    -- API実行結果確認
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- リードタイム取得エラーの場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_lead_time_error
        ,iv_token_name1  => cv_tkn_order_no                     -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                      -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_code_from                    -- コード区分From
        ,iv_token_value3 => cv_code_from
        ,iv_token_name4  => cv_tkn_stock_from                   -- 入出庫区分From
        ,iv_token_value4 => it_order_rec.ship_to_subinv
        ,iv_token_name5  => cv_tkn_code_to                      -- コード区分To
        ,iv_token_value5 => cv_code_to
        ,iv_token_name6  => cv_tkn_stock_to                     -- 入出庫区分To
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_commodity_class              -- 商品区分
        ,iv_token_value7 => it_order_rec.item_div_name
        ,iv_token_name8  => cv_tkn_stock_form_id                -- 出庫形態ID
        ,iv_token_value8 => cv_blank
        ,iv_token_name9  => cv_tkn_base_date                    -- 基準日
        ,iv_token_value9 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
      );
      RAISE common_api_expt;
    END IF;
    --
    -- アウトパラメータ設定
    on_lead_time := ln_lead_time;
    on_delivery_lt := ln_delivery_lt;
    --
    IF ( it_order_rec.schedule_ship_date IS NULL ) THEN
      -- 出荷予定日がNULLの場合
      -- 要求日(納品予定日)とリードタイム(配送)から出荷予定日を取得する
      -- ===============================
      -- 出荷予定日取得
      -- ===============================
      lv_retcode := xxwsh_common_pkg.get_oprtn_day(
         id_date            => it_order_rec.request_date           -- 納品予定日
        ,iv_whse_code       => NULL                                -- 保管倉庫コード
        ,iv_deliver_to_code => it_order_rec.province               -- 配送先コード
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--      ,in_lead_time       => ln_lead_time                        -- リードタイム
        ,in_lead_time       => ln_delivery_lt                      -- 配送リードタイム
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
        ,iv_prod_class      => it_order_rec.prod_class_code        -- 商品区分
        ,od_oprtn_day       => ld_oprtn_day                        -- 稼働日日付(出荷予定日)
      );
      --
      -- API実行結果確認
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 稼働日取得エラーの場合
        -- メッセージ文字列取得(出荷予定日)
        lv_msg_operate_date := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_ship_schedule_date       -- メッセージID
        );
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_non_operation_date
          ,iv_token_name1  => cv_tkn_operate_date                          -- 出荷予定日
          ,iv_token_value1 => lv_msg_operate_date
          ,iv_token_name2  => cv_tkn_order_no                              -- 受注番号
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_line_no                               -- 明細番号
          ,iv_token_value3 => it_order_rec.line_number
          ,iv_token_name4  => cv_tkn_base_date                             -- 納品予定日
          ,iv_token_value4 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
          ,iv_token_name5  => cv_tkn_whse_locat                            -- 出荷元保管場所
          ,iv_token_value5 => it_order_rec.ship_to_subinv
          ,iv_token_name6  => cv_tkn_delivery_code                         -- 配送先コード
          ,iv_token_value6 => it_order_rec.province
          ,iv_token_name7  => cv_tkn_lead_time                             -- リードタイム
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--        ,iv_token_value7 => TO_CHAR(ln_lead_time)
          ,iv_token_value7 => TO_CHAR(ln_delivery_lt)
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
          ,iv_token_name8  => cv_tkn_commodity_class                       -- 商品区分
          ,iv_token_value8 => it_order_rec.item_div_name
        );
        RAISE common_api_expt;
      END IF;
      -- アウトパラメータ設定
      od_oprtn_day := ld_oprtn_day;
    ELSE
      -- アウトパラメータ設定
      od_oprtn_day := it_order_rec.schedule_ship_date;
    END IF;
    --
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    --  営業OUへのログイン切替
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
       user_id         => ln_user_id            -- ユーザID
      ,resp_id         => ln_resp_id            -- 職責ID
      ,resp_appl_id    => ln_resp_appl_id       -- アプリケーションID
    );
/* 2009/09/16 Ver.1.12 Add End */
--
  EXCEPTION
    WHEN common_api_expt THEN
      -- 共通APIエラー
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ステータス設定(警告)
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ship_schedule_date;
--
  /**********************************************************************************
   * Procedure Name   : data_check
   * Description      : データチェック(A-5)
   ***********************************************************************************/
  PROCEDURE data_check(
    it_order_rec   IN  order_data_cur%ROWTYPE,         -- 1.受注データ
/* 2009/09/16 Ver.1.12 Add Start */
    in_index       IN  NUMBER,                         -- 2.インデックス
/* 2009/09/16 Ver.1.12 Add End */
    ov_errbuf      OUT NOCOPY VARCHAR2,                --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,                --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)                --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- プログラム名
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
    cv_normal_ship_class        CONSTANT VARCHAR2(1) := '1';      -- 出荷区分(正常値)
    cv_normal_sales_div         CONSTANT VARCHAR2(1) := '1';      -- 売上対象区分(正常値)
    cv_normal_rate_class        CONSTANT VARCHAR2(1) := '0';      -- 率区分(正常値)
    cv_normal_cust_order_flag   CONSTANT VARCHAR2(1) := 'Y';      -- 顧客受注可能フラグ(正常値)
    cn_api_normal               CONSTANT NUMBER := 0;             -- 正常
/* 2009/09/16 Ver.1.12 Add Start */
    cv_tkn_order_no      CONSTANT VARCHAR2(30) := 'ORDER_NO';
    cv_tkn_item_code     CONSTANT VARCHAR2(30) := 'ITEM_CODE';
    cv_tkn_quantity_uom  CONSTANT VARCHAR2(30) := 'ORDER_QUANTITY_UOM';
/* 2009/09/16 Ver.1.12 Add End */
--
    -- *** ローカル変数 ***
    lv_message                  VARCHAR2(1000);       -- 出力メッセージ設定
    lv_item_name                VARCHAR2(50);         -- 項目名
    lv_ship_class               VARCHAR2(10);         -- 出荷区分
    lv_sales_div                VARCHAR2(10);         -- 売上対象区分
    lv_rate_class               VARCHAR2(10);         -- 率区分
    lv_cust_order_flag          VARCHAR2(10);         -- 顧客受注可能フラグ
    ln_result                   NUMBER;               -- API関数用戻り値
    ld_ope_delivery_day         DATE;                 -- 稼動日日付納品予定日
    ld_ope_request_day          DATE;                 -- 稼動日日付受注日
    lv_tmp   varchar2(10);
/* 2009/09/16 Ver.1.12 Add Start */
    lv_organization_code  VARCHAR2(100);     -- 在庫組織コード
    lv_item_code          VARCHAR2(20);      -- 品目コード
    ln_item_id            NUMBER;            -- 品目ID
    ln_organization_id    NUMBER;            -- 在庫組織ID
    ln_content            NUMBER;            -- 入数 
    ln_sum_weight         NUMBER;            -- 合計重量
    ln_sum_capacity       NUMBER;            -- 合計容積
    ln_sum_pallet_weight  NUMBER;            -- 合計パレット重量
    ln_mod                NUMBER;
    lv_base_uom           xxcos_sales_exp_lines.standard_uom_code%TYPE;     -- 基準単位
    ln_base_quantity      xxcos_sales_exp_lines.standard_qty%TYPE;          -- 基準数量
/* 2009/09/16 Ver.1.12 Add End */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 必須入力チェック
    -- ===============================
    ----------------------------------
    -- 顧客発注
    ----------------------------------
/* 2009/09/16 Ver.1.12 Del Start */
--    IF ( it_order_rec.cust_po_number IS NULL ) THEN
--      -- 項目名取得
--      lv_item_name := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_cust_po_number
--      );
--      -- 出力メッセージ作成
--      lv_message := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_non_input_error
--        ,iv_token_name1  => cv_tkn_order_no                    -- 受注番号
--        ,iv_token_value1 => it_order_rec.order_number
--        ,iv_token_name2  => cv_tkn_line_no                     -- 明細番号
--        ,iv_token_value2 => it_order_rec.line_number
--        ,iv_token_name3  => cv_tkn_field_name                  -- 項目名
--        ,iv_token_value3 => lv_item_name
--      );
--      -- メッセージ出力
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_message
--      );
--      -- リターンコード設定(警告)
--      ov_retcode := cv_status_warn;
--    END IF;
/* 2009/09/16 Ver.1.12 Del End */
    --
/*
    ----------------------------------
    -- 要求日
    ----------------------------------
    IF ( it_order_rec.request_date IS NULL ) THEN
      -- 項目名取得
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_request_date
      );
      -- 出力メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                     -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                      -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                   -- 項目名
        ,iv_token_value3 => lv_item_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
*/
    ----------------------------------
    -- 納品拠点コード
    ----------------------------------
    IF ( it_order_rec.delivery_base_code IS NULL ) THEN
      -- 項目名取得
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_base_code
      );
      -- 出力メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                    -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                     -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                  -- 項目名
        ,iv_token_value3 => lv_item_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
/* 2009/10/19 Ver.1.13 Add Start */
    IF ( it_order_rec.prod_class_code = cv_prod_class_drink ) THEN
      ----------------------------------
      -- パレ配数
      ----------------------------------
      IF (( it_order_rec.original_palette_max_cs_qty IS NULL )
          OR ( it_order_rec.original_palette_max_cs_qty = '0' ))
      THEN
        -- 未設定、または、ゼロの場合
        -- 項目名取得
        lv_item_name := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_palette_qty
        );
        -- 出力メッセージ作成
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_item_set_err
          ,iv_token_name1  => cv_tkn_field_name                    -- 項目
          ,iv_token_value1 => lv_item_name
          ,iv_token_name2  => cv_tkn_order_no                    -- 受注番号
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_item_code                    -- 品目コード
          ,iv_token_value3 => it_order_rec.item_code
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- リターンコード設定(警告)
        ov_retcode := cv_status_warn;
      END IF;
      --
      ----------------------------------
      -- パレ段数
      ----------------------------------
      IF (( it_order_rec.original_palette_max_step_qty IS NULL )
          OR ( it_order_rec.original_palette_max_step_qty = '0' ))
      THEN
        -- 未設定、または、ゼロの場合
        -- 項目名取得
        lv_item_name := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_step_qty
        );
        -- 出力メッセージ作成
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_item_set_err
          ,iv_token_name1  => cv_tkn_field_name                    -- 項目
          ,iv_token_value1 => lv_item_name
          ,iv_token_name2  => cv_tkn_order_no                      -- 受注番号
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_item_code                     -- 品目コード
          ,iv_token_value3 => it_order_rec.item_code
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- リターンコード設定(警告)
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
/* 2009/10/19 Ver.1.13 Add End */
    --
    -- ===============================
    -- 区分値チェック
    -- ===============================
    --
/* 2009/09/16 Ver.1.12 Add Start [0001232] */
    -- エラーフラグ保持エリアの初期化
    gt_item_info_rec.ship_class_flag := cn_check_status_normal;      -- 出荷区分
    gt_item_info_rec.sales_div_flag := cn_check_status_normal;       -- 売上対象区分
    gt_item_info_rec.rate_class_flag := cn_check_status_normal;      -- 率区分
    gt_item_info_rec.cust_order_flag := cn_check_status_normal;      -- 顧客受注可能フラグ
/* 2009/09/16 Ver.1.12 Add End [0001232] */
    --
    -- 品目データを取得済みかチェック
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--    IF ( gt_item_info_tbl.EXISTS(it_order_rec.item_code) = TRUE ) THEN
--      -- 取得済みの場合、再利用する
--      gt_item_info_rec := gt_item_info_tbl(it_order_rec.item_code);
    IF ( gt_item_info_tbl.EXISTS(it_order_rec.child_code) = TRUE ) THEN
      -- 取得済みの場合、再利用する
      gt_item_info_rec := gt_item_info_tbl(it_order_rec.child_code);
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
    ELSE
      -- 未取得の場合
      -- 出荷区分、売上対象区分、率区分データ取得
      SELECT  ximv.ship_class                -- 出荷区分
             ,ximv.sales_div                 -- 売上対象区分
             ,ximv.rate_class                -- 率区分
      INTO    lv_ship_class
             ,lv_sales_div
             ,lv_rate_class
      FROM   xxcmn_item_mst2_v   ximv        -- OPM品目情報VIEW2
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--      WHERE  ximv.item_no       = it_order_rec.item_code             -- 品目コード
      WHERE  ximv.item_no       = it_order_rec.child_code            -- 品目コード
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
      AND    gd_business_date   BETWEEN ximv.start_date_active       -- 有効日From
                                AND     ximv.end_date_active;        -- 有効日To
      --
      -- 顧客受注可能フラグ取得
      SELECT msib.customer_order_enabled_flag         -- 顧客受注可能フラグ
      INTO   lv_cust_order_flag
      FROM   mtl_system_items_b       msib            -- 品目マスタ
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--      WHERE  msib.inventory_item_id = it_order_rec.inventory_item_id       -- 品目ID
      WHERE  msib.segment1          = it_order_rec.child_code              -- 品目コード
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
      AND    msib.organization_id   = it_order_rec.ship_from_org_id;       -- 組織ID
      --
      -- 出荷区分チェック
      IF ( ( lv_ship_class IS NULL )
             OR ( lv_ship_class <> cv_normal_ship_class ) )
      THEN
        gt_item_info_rec.ship_class_flag := cn_check_status_error;
      END IF;
      --
      -- 売上対象区分チェック
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD START ******************************--
      IF ( it_order_rec.item_code = it_order_rec.child_code ) THEN
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
      IF ( ( lv_sales_div IS NULL )
             OR ( lv_sales_div <> cv_normal_sales_div ) )
      THEN
        gt_item_info_rec.sales_div_flag := cn_check_status_error;
      END IF;
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD START ******************************--
      END IF;
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
      --
      -- 率区分チェック
      IF ( ( lv_rate_class IS NULL )
            OR ( lv_rate_class <> cv_normal_rate_class ) )
      THEN
        gt_item_info_rec.rate_class_flag := cn_check_status_error;
      END IF;
      --
      -- 顧客受注可能フラグチェック
      IF ( ( lv_cust_order_flag IS NULL )
            OR ( lv_cust_order_flag <> cv_normal_cust_order_flag ) )
      THEN
        gt_item_info_rec.cust_order_flag := cn_check_status_error;
      END IF;
      --
      -- テーブルに設定
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD START ******************************--
--      gt_item_info_tbl(it_order_rec.item_code) := gt_item_info_rec;
      gt_item_info_tbl(it_order_rec.child_code) := gt_item_info_rec;
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
    END IF;
    --
    ----------------------------------
    -- 出荷区分
    ----------------------------------
    IF (  gt_item_info_rec.ship_class_flag = cn_check_status_error ) THEN
      -- 項目名取得(出荷区分)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_ship_class
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                 -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name              -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value            -- 項目値
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        ,iv_token_value4 => it_order_rec.item_code
        ,iv_token_value4 => it_order_rec.child_code
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- 売上対象区分
    ----------------------------------
    IF ( gt_item_info_rec.sales_div_flag = cn_check_status_error ) THEN
      -- 項目名取得(売上対象区分)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_sales_div
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                 -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                  -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name               -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value             -- 項目値
/* 2009/09/16 Ver.1.12 Mod Start */
        ,iv_token_value4 => lv_sales_div
--        ,iv_token_value4 => it_order_rec.item_code
/* 2009/09/16 Ver.1.12 Mod End */
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- 率区分
    ----------------------------------
    IF ( gt_item_info_rec.rate_class_flag = cn_check_status_error ) THEN
      -- 項目名取得(率区分)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_rate_class
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no               -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name             -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value           -- 項目値
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        ,iv_token_value4 => it_order_rec.item_code
        ,iv_token_value4 => it_order_rec.child_code
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- 顧客受注可能フラグ
    ----------------------------------
    IF ( gt_item_info_rec.cust_order_flag = cn_check_status_error ) THEN
      -- 項目名取得(顧客受注可能フラグ)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_customer_order_flag
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                   -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                    -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                 -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value               -- 項目値
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        ,iv_token_value4 => it_order_rec.item_code
        ,iv_token_value4 => it_order_rec.child_code
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- ==========================================
    -- 要求日(納品予定日)が稼動日かチェック
    -- ==========================================
/* 2009/10/19 Ver.1.13 Del Start */
--    ln_result := xxwsh_common_pkg.get_oprtn_day(
--       id_date             => it_order_rec.request_date         -- 日付
--      ,iv_whse_code        => NULL                              -- 保管倉庫コード
--      ,iv_deliver_to_code  => it_order_rec.province             -- 配送先コード
--      ,in_lead_time        => cn_lead_time_non                  -- リードタイム
--      ,iv_prod_class       => it_order_rec.prod_class_code      -- 商品区分
--      ,od_oprtn_day        => ld_ope_delivery_day               -- 稼働日日付納品予定日
--    );
--    --
--    IF ( ld_ope_delivery_day IS NULL ) THEN
--      -- 稼動日取得エラー
--      -- 項目名取得(納品予定日)
--      lv_item_name := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_deli_expect_date
--      );
--      -- メッセージ作成
--      lv_message := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_non_operation_date
--        ,iv_token_name1  => cv_tkn_operate_date                          -- 納品予定日
--        ,iv_token_value1 => lv_item_name
--        ,iv_token_name2  => cv_tkn_order_no                              -- 受注番号
--        ,iv_token_value2 => it_order_rec.order_number
--        ,iv_token_name3  => cv_tkn_line_no                               -- 明細番号
--        ,iv_token_value3 => it_order_rec.line_number
--        ,iv_token_name4  => cv_tkn_base_date                             -- 納品予定日
--        ,iv_token_value4 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
--        ,iv_token_name5  => cv_tkn_whse_locat                            -- 出荷元保管場所
--        ,iv_token_value5 => it_order_rec.ship_to_subinv
--        ,iv_token_name6  => cv_tkn_delivery_code                         -- 配送先コード
--        ,iv_token_value6 => it_order_rec.province
--        ,iv_token_name7  => cv_tkn_lead_time                             -- リードタイム
--        ,iv_token_value7 => TO_CHAR(cn_lead_time_non)
--        ,iv_token_name8  => cv_tkn_commodity_class                       -- 商品区分
--        ,iv_token_value8 => it_order_rec.item_div_name
--      );
--      -- メッセージ出力
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_message
--      );
--      -- 空行出力
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => NULL
--      );
--      -- リターンコード設定(警告)
--      ov_retcode := cv_status_warn;
--    ELSE
/* 2009/10/19 Ver.1.13 Del End */
      -- =====================================
      -- 要求日(出荷予定日)の妥当性チェック
      -- =====================================
      IF ( TRUNC(it_order_rec.schedule_ship_date) < TRUNC(gd_business_date) ) THEN
        -- リードタイムを満たしていない場合(出荷予定日が業務日付より過去の場合)
        -- メッセージ作成
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_ship_schedule_validite
          ,iv_token_name1  => cv_tkn_val                        -- 出荷予定日
          ,iv_token_value1 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
          ,iv_token_name2  => cv_tkn_order_no                   -- 受注番号
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_line_no                    -- 明細番号
          ,iv_token_value3 => it_order_rec.line_number
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- リターンコード設定(警告)
        ov_retcode := cv_status_warn;
        --
      END IF;
/* 2009/10/19 Ver.1.13 Del Start */
--    END IF;
/* 2009/10/19 Ver.1.13 Del End */
    --
    -- ===============================
    -- 受注日チェックが稼動日かチェック
    -- ===============================
    ln_result := xxwsh_common_pkg.get_oprtn_day(
       id_date             => it_order_rec.schedule_ship_date      -- 日付
      ,iv_whse_code        => NULL                                 -- 保管倉庫コード
      ,iv_deliver_to_code  => it_order_rec.province                -- 配送先コード
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--    ,in_lead_time        => it_order_rec.delivery_lt             -- リードタイム(生産物流)
      ,in_lead_time        => it_order_rec.lead_time               -- リードタイム(生産物流)
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
      ,iv_prod_class       => it_order_rec.prod_class_code         -- 商品区分
      ,od_oprtn_day        => ld_ope_request_day                   -- 稼働日日付
    );
    --
/* 2009/10/19 Ver.1.13 Mod Start */
    IF (( ld_ope_request_day IS NULL )
          OR ( ln_result = 1 )) THEN
--    IF ( ld_ope_request_day IS NULL ) THEN
/* 2009/10/19 Ver.1.13 Mod End */
      -- 稼働日取得エラーの場合
      -- メッセージ文字列取得(受注日)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_order_date               -- メッセージID
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_operation_date
        ,iv_token_name1  => cv_tkn_operate_date                          -- 出荷予定日
        ,iv_token_value1 => lv_item_name
        ,iv_token_name2  => cv_tkn_order_no                              -- 受注番号
        ,iv_token_value2 => it_order_rec.order_number
        ,iv_token_name3  => cv_tkn_line_no                               -- 明細番号
        ,iv_token_value3 => it_order_rec.line_number
        ,iv_token_name4  => cv_tkn_base_date                             -- 納品予定日
        ,iv_token_value4 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
        ,iv_token_name5  => cv_tkn_whse_locat                            -- 出荷元保管場所
        ,iv_token_value5 => it_order_rec.ship_to_subinv
        ,iv_token_name6  => cv_tkn_delivery_code                         -- 配送先コード
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_lead_time                             -- リードタイム
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--      ,iv_token_value7 => it_order_rec.delivery_lt
        ,iv_token_value7 => it_order_rec.lead_time
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
        ,iv_token_name8  => cv_tkn_commodity_class                       -- 商品区分
        ,iv_token_value8 => it_order_rec.item_div_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
      --
    ELSE
      -- ===============================
      -- 受注日の妥当性チェック
      -- ===============================
      IF ( TRUNC(it_order_rec.ordered_date) > TRUNC(ld_ope_request_day) ) THEN
        -- リードタイムを満たしていない場合(受注日より上記で取得した稼動日が過去の場合)
        -- メッセージ作成
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_order_date_validite
          ,iv_token_name1  => cv_tkn_order_no                                  -- 受注番号
          ,iv_token_value1 => it_order_rec.order_number
          ,iv_token_name2  => cv_tkn_line_no                                   -- 明細番号
          ,iv_token_value2 => it_order_rec.line_number
          ,iv_token_name3  => cv_tkn_order_date                                -- 抽出受注日
          ,iv_token_value3 => TO_CHAR(it_order_rec.ordered_date,cv_date_fmt_date_time)
          ,iv_token_name4  => cv_tkn_operation_date                            -- 算出受注日
          ,iv_token_value4 => TO_CHAR(ld_ope_request_day,cv_date_fmt_date_time)
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- リターンコード設定(警告)
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
    --
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    -- 品目関連情報取得
    -- ===============================
    lv_item_code := it_order_rec.item_code;
    xxcos_common_pkg.get_uom_cnv(
       iv_before_uom_code      => it_order_rec.order_quantity_uom     -- 換算前単位コード
      ,in_before_quantity      => it_order_rec.ordered_quantity       -- 換算前数量
      ,iov_item_code           => lv_item_code                        -- 品目コード
      ,iov_organization_code   => lv_organization_code                -- 在庫組織コード
      ,ion_inventory_item_id   => ln_item_id                          -- 品目ID
      ,ion_organization_id     => ln_organization_id                  -- 在庫組織ID
      ,iov_after_uom_code      => lv_base_uom                         -- 換算後単位コード
      ,on_after_quantity       => ln_base_quantity                    -- 換算後数量
      ,on_content              => ln_content                          -- 入数
      ,ov_errbuf               => lv_errbuf                           -- エラー・メッセージエラー
      ,ov_retcode              => lv_retcode                          -- リターン・コード
      ,ov_errmsg               => lv_errmsg                           -- ユーザー・エラー・メッセージ
    );
    --
    -- リターンコードチェック
    IF ( lv_retcode = cv_status_error ) THEN
      -- 基準単位・基準数量取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name           -- アプリケーション短縮名
        ,iv_name         => cv_uom_cnv_err                -- メッセージ
        ,iv_token_name1  => cv_tkn_order_no               -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_item_code              -- 受注品目
        ,iv_token_value2 => it_order_rec.item_code
        ,iv_token_name3  => cv_tkn_quantity               -- 受注数量
        ,iv_token_value3 => it_order_rec.ordered_quantity
        ,iv_token_name4  => cv_tkn_quantity_uom           -- 受注単位
        ,iv_token_value4 => it_order_rec.order_quantity_uom
        ,iv_token_name5  => cv_tkn_err_msg                -- エラーメッセージ
        ,iv_token_value5 => lv_errmsg
       );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      --
      ov_retcode := cv_status_warn;
    ELSE
      -- 値設定
      gt_order_extra_tbl(in_index).base_quantity := ln_base_quantity;          -- 換算後数量
      gt_order_extra_tbl(in_index).conv_order_quantity_uom := lv_base_uom;     -- 換算後単位
      -- パレット数、段数、ケース数の算出
      gt_order_extra_tbl(in_index).conv_palette := TRUNC(ln_base_quantity / gt_order_extra_tbl(in_index).qty_palette);
      ln_mod := MOD(ln_base_quantity , gt_order_extra_tbl(in_index).qty_palette);
      gt_order_extra_tbl(in_index).conv_step := TRUNC(ln_mod /  gt_order_extra_tbl(in_index).qty_step);
      ln_mod := MOD(ln_mod , gt_order_extra_tbl(in_index).qty_step);
      gt_order_extra_tbl(in_index).conv_case := TRUNC(ln_mod /  gt_order_extra_tbl(in_index).qty_case);
    END IF;
    --
    -- ========================================================
    -- 合計重量・合計容積・合計パレット重量取得
    -- ========================================================
    xxwsh_common910_pkg.calc_total_value(
       iv_item_no            => it_order_rec.item_code              -- 品目コード
      ,in_quantity           => ln_base_quantity                    -- 数量
      ,ov_retcode            => lv_retcode                          -- リターンコード
      ,ov_errmsg_code        => lv_errbuf                           -- エラーメッセージコード
      ,ov_errmsg             => lv_errmsg                           -- エラーメッセージ
      ,on_sum_weight         => ln_sum_weight                       -- 合計重量
      ,on_sum_capacity       => ln_sum_capacity                     -- 合計容積
      ,on_sum_pallet_weight  => ln_sum_pallet_weight                -- 合計パレット重量
      ,id_standard_date      =>  it_order_rec.schedule_ship_date     -- 基準日(適用日基準日)
    );
    --
    -- リターンコードチェック
    IF ( lv_retcode = cv_status_error ) THEN
      -- 合計重量・合計容積取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name              -- アプリケーション短縮名
        ,iv_name         => cv_calc_total_value_err          -- メッセージ
        ,iv_token_name1  => cv_tkn_order_no                  -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_item_code                 -- 受注品目
        ,iv_token_value2 => it_order_rec.item_code
        ,iv_token_name3  => cv_tkn_quantity                  -- 受注数量
        ,iv_token_value3 => it_order_rec.ordered_quantity
        ,iv_token_name4  => cv_tkn_schedule_date             -- 出荷予定日
        ,iv_token_value4 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
        ,iv_token_name5  => cv_tkn_err_msg                   -- エラーメッセージ
        ,iv_token_value5 => lv_errmsg
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      ov_retcode := cv_status_warn;
    ELSE
      -- アウトパラメータ設定
      gt_order_extra_tbl(in_index).weight      := ln_sum_weight;     -- 品目単位の重量
    END IF;
     --
/* 2009/09/16 Ver.1.12 Add End */
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_check;
--
  /**********************************************************************************
   * Procedure Name   : make_normal_order_data
   * Description      : PL/SQL表設定(A-6)
   ***********************************************************************************/
  PROCEDURE make_normal_order_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_normal_order_data'; -- プログラム名
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
    cv_first_num           CONSTANT VARCHAR2(1) := '0';
--
    -- *** ローカル変数 ***
    lv_idx_key                VARCHAR2(1000);    -- PL/SQL表ソート用インデックス文字列
    lv_idx_sort               VARCHAR2(1000);    -- PL/SQL表ソート用ソート文字列
    ln_val                    NUMBER;            -- 番号生成用
    lv_sort_key               VARCHAR2(1000);    -- ソートキー
/* 2009/09/16 Ver.1.12 Add Start */
    ln_max_valt               NUMBER DEFAULT 0;  -- 最大重量容積
    lv_idx                    VARCHAR2(1000);
    lv_head_key               VARCHAR2(1000);
    lv_output_msg             VARCHAR2(1000);
    lv_line_key               VARCHAR2(1000);
    ln_sum_weight             NUMBER;            -- 合計重量
    ln_sum_capacity           NUMBER;            -- 合計容積
    ln_sum_pallet_weight      NUMBER;            -- 合計パレット重量
    --
    TYPE lr_head_sum_rec IS RECORD(
       base_quantity        NUMBER DEFAULT 0      -- 基準数量
      ,palette_quantity     NUMBER DEFAULT 0      -- パレット数
      ,step_quantity        NUMBER DEFAULT 0      -- 段数
      ,case_quantity        NUMBER DEFAULT 0      -- ケース数
    );
    -- 合算データ格納用
    TYPE it_head_sum_ttype IS TABLE OF lr_head_sum_rec INDEX BY VARCHAR2(1000);
    -- 合算データ変数
    lt_head_sum_tbl        it_head_sum_ttype;
/* 2009/09/16 Ver.1.12 Add End */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 正常データのみのPL/SQL表作成
    -- ===============================
/* 2009/09/16 Ver.1.12 Mod Start */
    -- ===============================
    -- 基準数量の集約
    -- ===============================
    <<sum_loop>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
      IF ( gt_order_extra_tbl(ln_idx).check_status = cn_check_status_normal ) THEN
        -- 集約キー作成
        lv_idx_key := 
          TO_CHAR(gt_order_extra_tbl(ln_idx).ordered_date , cv_date_fmt_no_sep)             -- 受注日
          || gt_order_extra_tbl(ln_idx).province                                            -- 配送先コード
          || NVL(gt_order_extra_tbl(ln_idx).shipping_instructions , cv_blank)               -- 出荷指示
          || NVL(gt_order_extra_tbl(ln_idx).cust_po_number , cv_blank)                      -- 顧客発注番号
/* 2009/10/19 Ver.1.13 Add Start */
          || gt_order_extra_tbl(ln_idx).base_code                                           -- 管轄拠点(売上拠点)
/* 2009/10/19 Ver.1.13 Add End */
          || gt_order_extra_tbl(ln_idx).delivery_base_code                                  -- 入力拠点
          || gt_order_extra_tbl(ln_idx).ship_to_subinv                                      -- 出荷元保管場所
          || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date , cv_date_fmt_no_sep)    -- 出荷予定日
          || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date , cv_date_fmt_no_sep)          -- 受注明細．納品予定日
          || NVL(gt_order_extra_tbl(ln_idx).time_from , cv_blank)                           -- 時間指定From
          || NVL(gt_order_extra_tbl(ln_idx).time_to , cv_blank)                             -- 時間指定To
          || gt_order_extra_tbl(ln_idx).prod_class_code                                     -- 商品区分View.商品区分
          || gt_order_extra_tbl(ln_idx).item_code;                                          -- 品目コード
        --
        IF ( lt_head_sum_tbl.EXISTS(lv_idx_key) = TRUE ) THEN
          -- 存在している場合は合算
          -- 基準数量
          lt_head_sum_tbl(lv_idx_key).base_quantity :=
              lt_head_sum_tbl(lv_idx_key).base_quantity + gt_order_extra_tbl(ln_idx).base_quantity;
          -- パレット
          lt_head_sum_tbl(lv_idx_key).palette_quantity :=
              lt_head_sum_tbl(lv_idx_key).palette_quantity + gt_order_extra_tbl(ln_idx).conv_palette;
          -- 段数
          lt_head_sum_tbl(lv_idx_key).step_quantity :=
              lt_head_sum_tbl(lv_idx_key).step_quantity + gt_order_extra_tbl(ln_idx).conv_step;
          -- ケース数
          lt_head_sum_tbl(lv_idx_key).case_quantity :=
              lt_head_sum_tbl(lv_idx_key).case_quantity + gt_order_extra_tbl(ln_idx).conv_case;
          --
        ELSE
          -- 存在していない場合
          lt_head_sum_tbl(lv_idx_key).base_quantity    := gt_order_extra_tbl(ln_idx).base_quantity;
          lt_head_sum_tbl(lv_idx_key).palette_quantity := gt_order_extra_tbl(ln_idx).conv_palette;
          lt_head_sum_tbl(lv_idx_key).step_quantity    := gt_order_extra_tbl(ln_idx).conv_step;
          lt_head_sum_tbl(lv_idx_key).case_quantity    := gt_order_extra_tbl(ln_idx).conv_case;
          --
        END IF;
      END IF;
    END LOOP sum_loop;
    --
    -- ===============================
    -- 品目単位のソート
    -- ===============================
    <<sort_loop>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
      -- ヘッダソート
      lv_head_key := 
        TO_CHAR(gt_order_extra_tbl(ln_idx).ordered_date , cv_date_fmt_no_sep)             -- 受注日
        || gt_order_extra_tbl(ln_idx).province                                            -- 配送先コード
        || NVL(gt_order_extra_tbl(ln_idx).shipping_instructions , cv_blank)               -- 出荷指示
        || NVL(gt_order_extra_tbl(ln_idx).cust_po_number , cv_blank)                      -- 顧客発注番号
/* 2009/10/19 Ver.1.13 Add Start */
        || gt_order_extra_tbl(ln_idx).base_code                                           -- 管轄拠点(売上拠点)
/* 2009/10/19 Ver.1.13 Add End */
        || gt_order_extra_tbl(ln_idx).delivery_base_code                                  -- 入力拠点
        || gt_order_extra_tbl(ln_idx).ship_to_subinv                                      -- 出荷元保管場所
        || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date , cv_date_fmt_no_sep)    -- 出荷予定日
        || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date , cv_date_fmt_no_sep)          -- 受注明細．納品予定日
        || NVL(gt_order_extra_tbl(ln_idx).time_from , cv_blank)                           -- 時間指定From
        || NVL(gt_order_extra_tbl(ln_idx).time_to , cv_blank)                             -- 時間指定To
        || gt_order_extra_tbl(ln_idx).prod_class_code;                                    -- 商品区分View.商品区分
      -- 明細キー
      lv_line_key := lv_head_key
        || gt_order_extra_tbl(ln_idx).item_code;                                          -- 品目コード
      -- インデックス作成
      lv_idx_key :=lv_head_key
         || gt_order_extra_tbl(ln_idx).wc_class                                            -- 重量容積区分
         || gt_order_extra_tbl(ln_idx).item_code                                           -- 品目コード
         || TO_CHAR(gt_order_extra_tbl(ln_idx).line_id);                                   -- 明細ID
       -- 設定
       gt_order_sort_wk_tbl(lv_idx_key) := gt_order_extra_tbl(ln_idx);
       gt_order_sort_wk_tbl(lv_idx_key).head_sort_key := lv_head_key;
       gt_order_sort_wk_tbl(lv_idx_key).line_key := lv_line_key;
       -- 合算データ設定
       gt_order_sort_wk_tbl(lv_idx_key).add_base_quantity   := lt_head_sum_tbl(lv_line_key).base_quantity;
       gt_order_sort_wk_tbl(lv_idx_key).total_conv_palette  := lt_head_sum_tbl(lv_line_key).palette_quantity;
       gt_order_sort_wk_tbl(lv_idx_key).total_conv_step     := lt_head_sum_tbl(lv_line_key).step_quantity;
       gt_order_sort_wk_tbl(lv_idx_key).total_conv_case     := lt_head_sum_tbl(lv_line_key).case_quantity;
       --
       gt_normal_order_tbl(lv_idx_key) := gt_order_sort_wk_tbl(lv_idx_key);
    END LOOP sort_loop;
    --
    -- ====================================================================
    -- 入数チェック、ヘッダ単位の合計重量・合計容積・合計パレット重量取得
    -- ====================================================================
    lv_idx := gt_order_sort_wk_tbl.FIRST;
    lv_line_key := '--';
    <<sum_loop>>
    WHILE lv_idx IS NOT NULL LOOP
      IF ( lv_line_key <> gt_order_sort_wk_tbl(lv_idx).line_key ) THEN
        -- ヘッダソートキーがブレイクした場合
        IF ( gt_order_sort_wk_tbl(lv_idx).prod_class_code = cv_prod_class_drink ) THEN
          -- ドリンクの場合
          -- ==============================================
          -- 入数の整数倍チェック
          -- ==============================================
          IF ( MOD(gt_order_sort_wk_tbl(lv_idx).add_base_quantity,gt_order_sort_wk_tbl(lv_idx).qty_case) <> 0 ) THEN
            -- ケース入数の倍数でない場合
            -- メッセージ作成
            lv_output_msg := xxccp_common_pkg.get_msg(
               iv_application  => cv_xxcos_short_name                  -- アプリケーション短縮名
              ,iv_name         => cv_msg_quantity_err                     -- メッセージ
              ,iv_token_name1  => cv_tkn_item_code                      -- 受注品目
              ,iv_token_value1 => gt_order_sort_wk_tbl(lv_idx).item_code
              ,iv_token_name2  => cv_tkn_ordered_quantity                -- 受注数量
              ,iv_token_value2 => gt_order_sort_wk_tbl(lv_idx).add_base_quantity
              ,iv_token_name3  => cv_tkn_case_quantity            -- 入数
              ,iv_token_value3 => gt_order_sort_wk_tbl(lv_idx).qty_case
            );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_output_msg
            );
            -- 空行出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => NULL
            );
            --
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
        --
        -- ========================================================
        -- ヘッダ単位の合計重量・合計容積・合計パレット重量取得
        -- ========================================================
        xxwsh_common910_pkg.calc_total_value(
           iv_item_no            =>  gt_order_sort_wk_tbl(lv_idx).item_code              -- 品目コード
          ,in_quantity           =>  gt_order_sort_wk_tbl(lv_idx).add_base_quantity                    -- 数量
          ,ov_retcode            => lv_retcode                          -- リターンコード
          ,ov_errmsg_code        => lv_errbuf                           -- エラーメッセージコード
          ,ov_errmsg             => lv_errmsg                           -- エラーメッセージ
          ,on_sum_weight         => ln_sum_weight                       -- 合計重量
          ,on_sum_capacity       => ln_sum_capacity                     -- 合計容積
          ,on_sum_pallet_weight  => ln_sum_pallet_weight                -- 合計パレット重量
          ,id_standard_date      =>  gt_order_sort_wk_tbl(lv_idx).schedule_ship_date     -- 基準日(適用日基準日)
        );
        --
        -- リターンコードチェック
        IF ( lv_retcode = cv_status_error ) THEN
          -- 合計重量・合計容積取得エラー
          lv_output_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_xxcos_short_name              -- アプリケーション短縮名
            ,iv_name         => cv_calc_total_value_err          -- メッセージ
            ,iv_token_name1  => cv_tkn_order_no                  -- 受注番号
            ,iv_token_value1 => gt_order_sort_wk_tbl(lv_idx).order_number
            ,iv_token_name2  => cv_tkn_item_code                 -- 受注品目
            ,iv_token_value2 => gt_order_sort_wk_tbl(lv_idx).item_code
            ,iv_token_name3  => cv_tkn_quantity                  -- 受注数量
            ,iv_token_value3 => gt_order_sort_wk_tbl(lv_idx).ordered_quantity
            ,iv_token_name4  => cv_tkn_schedule_date             -- 出荷予定日
            ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_idx).schedule_ship_date,cv_date_fmt_date_time)
            ,iv_token_name5  => cv_tkn_err_msg                   -- エラーメッセージ
            ,iv_token_value5 => lv_errmsg
          );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_output_msg
          );
          -- 空行出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => NULL
          );
          --
          gn_warn_cnt := gn_warn_cnt + 1;
          --
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
      --
      gt_order_sort_wk_tbl(lv_idx).add_sum_weight        := ln_sum_weight;
      gt_order_sort_wk_tbl(lv_idx).add_sum_capacity      := ln_sum_capacity;
      gt_order_sort_wk_tbl(lv_idx).add_sum_pallet_weight := ln_sum_pallet_weight;
      --
      lv_line_key := gt_order_sort_wk_tbl(lv_idx).line_key;
      -- 次のインデックス取得
      lv_idx := gt_order_sort_wk_tbl.NEXT(lv_idx);
    END LOOP sum_loop;
    --
    gt_normal_order_tbl := gt_order_sort_wk_tbl;
    gt_order_sort_wk_tbl.DELETE;
    --
    -- ==========================================
    -- ヘッダソートキー、品目単位の最大重量取得
    -- ==========================================
    lv_idx := gt_normal_order_tbl.FIRST;
    <<max_weight_loop>>
    WHILE lv_idx IS NOT NULL LOOP
      IF ( ln_max_valt < TRUNC(gt_normal_order_tbl(lv_idx).add_sum_weight) ) THEN
        ln_max_valt := TRUNC(gt_normal_order_tbl(lv_idx).add_sum_weight);
      END IF;
      lv_idx := gt_normal_order_tbl.NEXT(lv_idx);
    END LOOP max_weight_loop;
    --
    -- ===============================
    -- 重量順にソート
    -- ===============================
    lv_idx := gt_normal_order_tbl.FIRST;
    WHILE lv_idx IS NOT NULL LOOP
    <<weight_sort_loop>>
      -- インデックス作成
      lv_idx_key :=gt_normal_order_tbl(lv_idx).head_sort_key
         || gt_normal_order_tbl(lv_idx).wc_class                                            -- 重量容積区分
         || LPAD(TO_CHAR(ln_max_valt - TRUNC(gt_normal_order_tbl(lv_idx).add_sum_weight)), LENGTH(TO_CHAR(ln_max_valt)) + 1, '0')  -- 重量容積(降順)
         || gt_normal_order_tbl(lv_idx).item_code                                           -- 品目コード
         || TO_CHAR(gt_normal_order_tbl(lv_idx).line_id);                                   -- 明細ID
       gt_order_sort_wk_tbl(lv_idx_key) := gt_normal_order_tbl(lv_idx);
      lv_idx := gt_normal_order_tbl.NEXT(lv_idx);
    END LOOP weight_sort_loop;
    --
--    <<loop_make_sort_data>>
--    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
--      IF ( gt_order_extra_tbl(ln_idx).check_status = cn_check_status_normal ) THEN
--        -- ソートキー
--        lv_idx_sort := TO_CHAR(gt_order_extra_tbl(ln_idx).header_id)                                -- 受注ヘッダID
--                      || gt_order_extra_tbl(ln_idx).ship_to_subinv                                  -- 出荷元保管場所
--                      || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date,cv_date_fmt_no_sep)  -- 出荷予定日
--                      || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date,cv_date_fmt_no_sep)        -- 納品予定日
--                      || gt_order_extra_tbl(ln_idx).time_from                                       -- 時間指定From
--                      || gt_order_extra_tbl(ln_idx).time_to                                         -- 時間指定To
--                      || gt_order_extra_tbl(ln_idx).item_div_name;                                  -- 商品区分
--        -- インデックス
--        lv_idx_key := lv_idx_sort
--                      || gt_order_extra_tbl(ln_idx).item_code                                       -- 品目コード
--                      || cv_first_num;
--        --
--        -- インデックス(同一注文品)のデータが存在しているかチェック
--        IF ( gt_order_sort_tbl.EXISTS(lv_idx_key) = TRUE ) THEN
--          -- 存在する場合
--          ln_val := 1;
--          <<loop_make_next_val>>
--          LOOP
--            lv_idx_key := lv_idx_sort
--                      || gt_order_extra_tbl(ln_idx).item_code                                       -- 品目コード
--                      || TO_CHAR(ln_val);
--            -- 存在しない場合、ループを抜ける
--            EXIT WHEN gt_order_sort_tbl.EXISTS(lv_idx_key) = FALSE;
--            -- カウントアップ
--            ln_val := ln_val + 1;
--          END LOOP loop_make_next_val;
--        END IF;
--        -- ソートキー設定
--        gt_order_extra_tbl(ln_idx).sort_key := lv_idx_sort;
--        gt_order_sort_tbl(lv_idx_key) := gt_order_extra_tbl(ln_idx);
--      END IF;
--    END LOOP loop_make_sort_data;
--    --
--    -- ===============================
--    -- 出荷依頼用ヘッダーID採番
--    -- ===============================
--    IF ( gt_order_sort_tbl.COUNT > 0 ) THEN
--      lv_idx_key := gt_order_sort_tbl.FIRST;
--      --
--      -- ヘッダーID用シーケンス採番
--      SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
--      INTO   ln_header_id
--      FROM   dual;
--      --
--      <<loop_make_header_id>>
--      WHILE lv_idx_key IS NOT NULL LOOP
--        -- 出荷依頼用ヘッダーIDを採番するかチェック
--        IF ( ( lv_sort_key <> gt_order_sort_tbl(lv_idx_key).sort_key )
--             OR ( ( lv_sort_key = gt_order_sort_tbl(lv_idx_key).sort_key )
--                AND ( lv_item_code = gt_order_sort_tbl(lv_idx_key).item_code ) ) )
--        THEN
--          -- ソートキーがブレイク、または、ソートキーと品目が同一の場合
--          -- ヘッダーID用シーケンス採番
--          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
--          INTO   ln_header_id
--          FROM   dual;
--          --
--        END IF;
--        --
--        -- ヘッダーIDを設定
--        gt_order_sort_tbl(lv_idx_key).req_header_id := ln_header_id;
--        --
--        -- ソートキーと品目コードを取得
--        lv_sort_key :=  gt_order_sort_tbl(lv_idx_key).sort_key;
--        lv_item_code := gt_order_sort_tbl(lv_idx_key).item_code;
--        --
--        -- 次のインデックスを取得
--        lv_idx_key := gt_order_sort_tbl.NEXT(lv_idx_key);
--        --
--      END LOOP loop_make_header_id;
--    END IF;
/* 2009/09/16 Ver.1.12 Mod End */
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END make_normal_order_data;
--
  /**********************************************************************************
   * Procedure Name   : make_request_line_bulk_data
   * Description      : 出荷依頼I/F明細バルクバインドデータ作成(A-7)
   ***********************************************************************************/
  PROCEDURE make_request_line_bulk_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_request_line_bulk_data'; -- プログラム名
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
    lv_index                  VARCHAR2(1000);               -- PL/SQL表用インデックス文字列
    lv_organization_code      VARCHAR(100);                 --  在庫組織コード
    lt_item_id                ic_item_mst_b.item_id%TYPE;   --  品目ID
    ln_organization_id        NUMBER;                       --  在庫組織ID
    ln_content                NUMBER;                       --  入数
    ln_count                  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_count := 0;
    lv_index := gt_order_sort_tbl.FIRST;
    --
    <<make_line_bulk_data>>
    WHILE lv_index IS NOT NULL LOOP
/* 2009/09/16 Ver.1.12 Del Start */
--      --==================================
--      -- 基準数量算出
--      --==================================
--      xxcos_common_pkg.get_uom_cnv(
--         iv_before_uom_code    => gt_order_sort_tbl(lv_index).order_quantity_uom       -- 換算前単位コード = 受注単位
--        ,in_before_quantity    => gt_order_sort_tbl(lv_index).ordered_quantity         -- 換算前数量       = 受注数量
--        ,iov_item_code         => gt_order_sort_tbl(lv_index).item_code                -- 品目コード
--        ,iov_organization_code => lv_organization_code                                 -- 在庫組織コード   =NULL
--        ,ion_inventory_item_id => lt_item_id                                           -- 品目ＩＤ         =NULL
--        ,ion_organization_id   => ln_organization_id                                   -- 在庫組織ＩＤ     =NULL
--        ,iov_after_uom_code    => gt_order_sort_tbl(lv_index).conv_order_quantity_uom  --換算後単位コード =>基準単位
--        ,on_after_quantity     => gt_order_sort_tbl(lv_index).conv_ordered_quantity    --換算後数量       =>基準数量
--        ,on_content            => ln_content                                           --入数
--        ,ov_errbuf             => lv_errbuf                         --エラー・メッセージエラー       #固定#
--        ,ov_retcode            => lv_retcode                        --リターン・コード               #固定#
--        ,ov_errmsg             => lv_errmsg                         --ユーザー・エラー・メッセージ   #固定#
--      );
--      -- API実行結果チェック
--      IF ( lv_retcode != cv_status_normal ) THEN
--        RAISE global_api_expt;
--      END IF;
/* 2009/09/16 Ver.1.12 Del End */
      --
      gt_ins_l_header_id(ln_count) := gt_order_sort_tbl(lv_index).req_header_id;                -- ヘッダーID
      gt_ins_l_line_number(ln_count) := gt_order_sort_tbl(lv_index).line_number;                -- 明細番号
      gt_ins_l_orderd_item_code(ln_count) := gt_order_sort_tbl(lv_index).child_code;            -- 受注品目
/* 2009/09/16 Ver.1.12 Del End */
      gt_ins_l_orderd_quantity(ln_count) := gt_order_sort_tbl(lv_index).checked_quantity;      -- 数量
--      gt_ins_l_orderd_quantity(ln_count) := gt_order_sort_tbl(lv_index).conv_ordered_quantity;  -- 数量
/* 2009/09/16 Ver.1.12 Del End */
      gt_ins_l_line_id(ln_count) := gt_order_sort_tbl(lv_index).line_id;                        -- 明細ID
      gt_ins_l_ship_from_org_id(ln_count) := gt_order_sort_tbl(lv_index).ship_from_org_id;      -- 組織ID
      --
      gt_upd_header_id(ln_count) := gt_order_sort_tbl(lv_index).header_id;                      -- ヘッダーID
      --
      -- カウントアップ
      ln_count := ln_count + 1;
      --
      -- 次のインデックスを取得する
      lv_index := gt_order_sort_tbl.NEXT(lv_index);
      --
    END LOOP make_line_bulk_data;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END make_request_line_bulk_data;
--
  /**********************************************************************************
   * Procedure Name   : make_request_head_bulk_data
   * Description      : 出荷依頼I/Fヘッダバルクバインドデータ作成(A-8)
   ***********************************************************************************/
  PROCEDURE make_request_head_bulk_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_request_head_bulk_data'; -- プログラム名
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
    cv_data_type                CONSTANT VARCHAR2(2) := '10';    -- データタイプ
    cv_cust_po_number_first     CONSTANT VARCHAR2(1) := 'I';     -- 顧客発注の先頭文字
--****************************** 2009/04/16 1.5 T.kitajima MOD START ******************************--
----****************************** 2009/04/06 1.4 T.kitajima MOD START ******************************--
----    cv_order_source             CONSTANT VARCHAR2(1) := '9';     -- 受注ソース参照の先頭文字
--    cv_order_source             CONSTANT VARCHAR2(2) := '97';    -- 受注ソース参照の先頭文字
----****************************** 2009/04/06 1.4 T.kitajima MOD  END  ******************************--
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_order_source             CONSTANT VARCHAR2(2) := '98';    -- 受注ソース参照の先頭文字
/* 2009/09/16 Ver.1.12 Del End */
--****************************** 2009/04/16 1.5 T.kitajima MOD  END  ******************************--
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_pad_char                 CONSTANT VARCHAR2(1) := '0';     -- PAD関数で埋め込む文字
/* 2009/09/16 Ver.1.12 Del End */
--****************************** 2009/04/06 1.4 T.kitajima MOD START ******************************--
--    cn_pad_num_char             CONSTANT NUMBER := 11;           -- PAD関数で埋め込む文字数
/* 2009/09/16 Ver.1.12 Del Start */
--    cn_pad_num_char             CONSTANT NUMBER := 10;           -- PAD関数で埋め込む文字数
/* 2009/09/16 Ver.1.12 Del End */
--****************************** 2009/04/06 1.4 T.kitajima MOD  END  ******************************--
--
    -- *** ローカル変数 ***
    lv_index                    VARCHAR2(1000);                        -- PL/SQL表用インデックス文字列
    lt_cust_po_number           VARCHAR2(100);                         -- 顧客発注
    lv_order_source             VARCHAR2(12);                          -- 受注ソース
    ln_req_header_id            NUMBER;                                -- ヘッダーID
    ln_count                    NUMBER;                                -- カウンタ
    ln_order_source_ref         NUMBER;                                -- シーケンス設定用
/* 2009/09/16 Ver.1.12 Del Start */
--    lt_shipping_class           fnd_lookup_values.attribute2%TYPE;     -- 出荷依頼区分
/* 2009/09/16 Ver.1.12 Del End */
--
    -- *** ローカル例外 ***
    non_lookup_value_expt       EXCEPTION;                             -- クイックコード取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------
    -- 出荷依頼区分の取得
    -----------------------------
    BEGIN
      SELECT flv.attribute2     flv_attribute2
/* 2009/09/16 Ver.1.12 Mod Start */
      INTO   gt_shipping_class
--      INTO   lt_shipping_class
/* 2009/09/16 Ver.1.12 Mod End */
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_shipping_class_t
      AND    flv.lookup_code   = cv_shipping_class_c
/* 2009/09/16 Ver.1.12 Mod Start */
      AND    flv.language      = cv_lang
--      AND    flv.language      = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
      AND    flv.enabled_flag  = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE non_lookup_value_expt;
    END;
    --
/* 2009/09/16 Ver.1.12 Mod Start */
    IF ( gt_shipping_class IS NULL ) THEN
--    IF ( lt_shipping_class IS NULL ) THEN
/* 2009/09/16 Ver.1.12 Mod End */
       RAISE non_lookup_value_expt;
    END IF;
    --
    ln_count := 0;
    lv_index := gt_order_sort_tbl.FIRST;
    --
    <<make_header_bulk_data>>
    WHILE lv_index IS NOT NULL LOOP
      -- 最初の1件、または、ヘッダーIDがブレイクしたらデータを作成する
      IF ( ( lv_index = gt_order_sort_tbl.FIRST )
         OR( ln_req_header_id <> gt_order_sort_tbl(lv_index).req_header_id ) ) THEN
        -----------------------------
        -- 顧客発注の設定
        -----------------------------
        IF ( ( gt_order_sort_tbl(lv_index).cust_po_number_att19 IS NOT NULL ) 
           AND ( SUBSTR(gt_order_sort_tbl(lv_index).cust_po_number,1,1) = cv_cust_po_number_first ) )
        THEN
          --
          lt_cust_po_number := gt_order_sort_tbl(lv_index).cust_po_number_att19;
        ELSE
          --
          lt_cust_po_number := gt_order_sort_tbl(lv_index).cust_po_number;
        END IF;
        --
        -----------------------------
        -- 受注ソース参照設定
        -----------------------------
/* 2009/09/16 Ver.1.12 Mod Start */
          lv_order_source := gt_order_sort_tbl(lv_index).order_source;
--        -- シーケンス採番
--        SELECT xxcos_order_source_ref_s01.NEXTVAL
--        INTO   ln_order_source_ref
--        FROM   dual;
--        --
--        lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
--                                                   ,cn_pad_num_char
--                                                   ,cv_pad_char);
/* 2009/09/16 Ver.1.12 Mod End */
        --
        -- ヘッダID
        gt_ins_h_header_id(ln_count) := gt_order_sort_tbl(lv_index).req_header_id;
        -- 受注日
        gt_ins_h_ordered_date(ln_count) := gt_order_sort_tbl(lv_index).ordered_date;
        -- 出荷先
        gt_ins_h_party_site_code(ln_count) := gt_order_sort_tbl(lv_index).province;
        -- 出荷指示
        gt_ins_h_shipping_instructions(ln_count) := gt_order_sort_tbl(lv_index).shipping_instructions;
        -- 顧客発注
        gt_ins_h_cust_po_number(ln_count) := lt_cust_po_number;
        -- 受注ソース参照
        gt_ins_h_order_source_ref(ln_count) := lv_order_source;
        -- 出荷予定日
        gt_ins_h_schedule_ship_date(ln_count) := gt_order_sort_tbl(lv_index).schedule_ship_date;
        -- 着荷予定日
        gt_ins_h_schedule_arrival_date(ln_count) := gt_order_sort_tbl(lv_index).request_date;
        -- 出荷元
        gt_ins_h_location_code(ln_count) := gt_order_sort_tbl(lv_index).ship_to_subinv;
        -- 管轄拠点
/* 2009/09/19 Ver.1.13 Mod Start */
        gt_ins_h_head_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).base_code;
--        gt_ins_h_head_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
/* 2009/09/19 Ver.1.13 Mod End */
        -- 入力拠点
/* 2009/11/04 Ver.1.14 Mod Start */
        gt_ins_h_input_sales_branch(ln_count) := gt_input_base_code;
--        gt_ins_h_input_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
/* 2009/11/04 Ver.1.14 Mod End */
        -- 着荷時間From
        gt_ins_h_arrival_time_from(ln_count) := gt_order_sort_tbl(lv_index).time_from;
        -- 着荷時間To
        gt_ins_h_arrival_time_to(ln_count) := gt_order_sort_tbl(lv_index).time_to;
        -- データタイプ
        gt_ins_h_data_type(ln_count) := cv_data_type;
        -- 受注番号
        gt_ins_h_order_number(ln_count) := gt_order_sort_tbl(lv_index).order_number;
        -- 依頼区分
/* 2009/09/16 Ver.1.12 Mod Start */
        gt_ins_h_order_number(ln_count) := gt_shipping_class;
--        gt_ins_h_order_number(ln_count) := lt_shipping_class;
/* 2009/09/16 Ver.1.12 Mod End */
        --
        -- カウントアップ
        ln_count := ln_count + 1;
        --
      END IF;
      --
      -- ヘッダーID設定
      ln_req_header_id := gt_order_sort_tbl(lv_index).req_header_id;
      --
      -- 次のインデックスを取得する
      lv_index := gt_order_sort_tbl.NEXT(lv_index);
      --
    END LOOP make_header_bulk_data;
--
  EXCEPTION
    WHEN non_lookup_value_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_shipping_class
                       ,iv_token_name1  => cv_tkn_type
                       ,iv_token_value1 => cv_shipping_class_t
                       ,iv_token_name2  => cv_tkn_code
                       ,iv_token_value2 => cv_shipping_class_c);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END make_request_head_bulk_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_ship_line_data
   * Description      : 出荷依頼I/F明細データ作成(A-9)
   ***********************************************************************************/
  PROCEDURE insert_ship_line_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ship_line_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
/* 2009/09/16 Ver.1.12 Add Start */
    ln_header_id       NUMBER;               -- ヘッダID用
    lv_item_code       VARCHAR2(30);         -- 品目ID
/* 2009/09/16 Ver.1.12 Add End */
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FORALL ln_idx IN 0..gt_ins_l_header_id.LAST
      INSERT INTO xxwsh_shipping_lines_if(
         line_id                        -- 明細ID
        ,header_id                      -- ヘッダID
        ,line_number                    -- 明細番号
        ,orderd_item_code               -- 受注品目
        ,case_quantity                  -- ケース数
        ,orderd_quantity                -- 数量
        ,shiped_quantity                -- 出荷実績数量
        ,designated_production_date     -- 製造日(インタフェース用)
        ,original_character             -- 固有記号(インタフェース用)
        ,use_by_date                    -- 賞味期限(インタフェース用)
        ,detailed_quantity              -- 内訳数量(インタフェース用)
        ,ship_to_quantity               -- 入庫実績数量
        ,reserved_status                -- 保留ステータス
        ,lot_no                         -- ロットNo
        ,filler01                       -- 予備01
        ,filler02                       -- 予備02
        ,filler03                       -- 予備03
        ,filler04                       -- 予備04
        ,filler05                       -- 予備05
        ,filler06                       -- 予備06
        ,filler07                       -- 予備07
        ,filler08                       -- 予備08
        ,filler09                       -- 予備09
        ,filler10                       -- 予備10
        ,created_by                     -- 作成者
        ,creation_date                  -- 作成日
        ,last_updated_by                -- 最終更新者
        ,last_update_date               -- 最終更新日
        ,last_update_login              -- 最終更新ログイン
        ,request_id                     -- 要求ID
        ,program_application_id         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,program_id                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,program_update_date            -- プログラム更新日
      ) VALUES (
         xxwsh_shipping_lines_if_s1.NEXTVAL      -- 明細ID
        ,gt_ins_l_header_id(ln_idx)              -- ヘッダID
        ,gt_ins_l_line_number(ln_idx)            -- 明細番号
        ,gt_ins_l_orderd_item_code(ln_idx)       -- 受注品目
        ,NULL                                    -- ケース数
        ,gt_ins_l_orderd_quantity(ln_idx)        -- 数量
        ,NULL                                    -- 出荷実績数量
        ,NULL                                    -- 製造日(インタフェース用)
        ,NULL                                    -- 固有記号(インタフェース用)
        ,NULL                                    -- 賞味期限(インタフェース用)
        ,NULL                                    -- 内訳数量(インタフェース用)
        ,NULL                                    -- 入庫実績数量
        ,NULL                                    -- 保留ステータス
        ,NULL                                    -- ロットNo
        ,NULL                                    -- 予備01
        ,NULL                                    -- 予備02
        ,NULL                                    -- 予備03
        ,NULL                                    -- 予備04
        ,NULL                                    -- 予備05
        ,NULL                                    -- 予備06
        ,NULL                                    -- 予備07
        ,NULL                                    -- 予備08
        ,NULL                                    -- 予備09
        ,NULL                                    -- 予備10
        ,cn_created_by                           -- 作成者
        ,cd_creation_date                        -- 作成日
        ,cn_last_updated_by                      -- 最終更新者
        ,cd_last_update_date                     -- 最終更新日
        ,cn_last_update_login                    -- 最終更新ログイン
        ,cn_request_id                           -- 要求ID
        ,cn_program_application_id               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,cn_program_id                           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,cd_program_update_date                  -- プログラム更新日
      );
      --
      -- 登録件数
      gn_line_normal_cnt := gt_ins_l_header_id.COUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_ship_line_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_ship_header_data
   * Description      : 出荷依頼I/Fヘッダデータ作成(A-10)
   ***********************************************************************************/
  PROCEDURE insert_ship_header_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ship_header_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
/* 2009/09/16 Ver.1.12 Add Start */
    cv_cust_po_number_first     CONSTANT VARCHAR2(1) := 'I';     -- 顧客発注の先頭文字
    cv_order_source             CONSTANT VARCHAR2(2) := '98';    -- 受注ソース参照の先頭文字
    cv_pad_char                 CONSTANT VARCHAR2(1) := '0';     -- PAD関数で埋め込む文字
    cn_pad_num_char             CONSTANT NUMBER := 10;           -- PAD関数で埋め込む文字数
    cv_data_type                CONSTANT VARCHAR2(2) := '10';    -- データタイプ
    ln_header_id           NUMBER;     -- ヘッダID
    ln_order_source_ref    NUMBER;
    lv_order_source        VARCHAR2(50);   -- 受注ソース参照
    lt_cust_po_number      VARCHAR2(50);   -- 顧客発注番号
/* 2009/09/16 Ver.1.12 Add End */
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FORALL ln_idx IN 0..gt_ins_h_header_id.LAST
      INSERT INTO xxwsh_shipping_headers_if(
         header_id                -- ヘッダID
        ,ordered_date             -- 受注日
        ,party_site_code          -- 出荷先
        ,shipping_instructions    -- 出荷指示
        ,cust_po_number           -- 顧客発注
        ,order_source_ref         -- 受注ソース参照
        ,schedule_ship_date       -- 出荷予定日
        ,schedule_arrival_date    -- 着荷予定日
        ,used_pallet_qty          -- パレット使用枚数
        ,collected_pallet_qty     -- パレット回収枚数
        ,location_code            -- 出荷元
        ,head_sales_branch        -- 管轄拠点
        ,input_sales_branch       -- 入力拠点
        ,arrival_time_from        -- 着荷時間From
        ,arrival_time_to          -- 着荷時間To
        ,data_type                -- データタイプ
        ,freight_carrier_code     -- 運送業者
        ,shipping_method_code     -- 配送区分
        ,delivery_no              -- 配送No
        ,shipped_date             -- 出荷日
        ,arrival_date             -- 着荷日
        ,eos_data_type            -- EOSデータ種別
        ,tranceration_number      -- 伝送用枝番
        ,ship_to_location         -- 入庫倉庫
        ,rm_class                 -- 倉替返品区分
        ,ordered_class            -- 依頼区分
        ,report_post_code         -- 報告部署
        ,line_number              -- 制御番号
        ,filler01                 -- 予備01
        ,filler02                 -- 予備02
        ,filler03                 -- 予備03
        ,filler04                 -- 予備04
        ,filler05                 -- 予備05
        ,filler06                 -- 予備06
        ,filler07                 -- 予備07 
        ,filler08                 -- 予備08
        ,filler09                 -- 予備09
        ,filler10                 -- 予備10
        ,filler11                 -- 予備11
        ,filler12                 -- 予備12
        ,filler13                 -- 予備13
        ,filler14                 -- 予備14
        ,filler15                 -- 予備15
        ,filler16                 -- 予備16
        ,filler17                 -- 予備17
        ,filler18                 -- 予備18
        ,created_by               -- 作成者
        ,creation_date            -- 作成日
        ,last_updated_by          -- 最終更新者
        ,last_update_date         -- 最終更新日
        ,last_update_login        -- 最終更新ログイン
        ,request_id               -- 要求ID
        ,program_application_id   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,program_id               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,program_update_date      -- プログラム更新日
      ) VALUES (
         gt_ins_h_header_id(ln_idx)                -- ヘッダID
        ,gt_ins_h_ordered_date(ln_idx)             -- 受注日
        ,gt_ins_h_party_site_code(ln_idx)          -- 出荷先
        ,gt_ins_h_shipping_instructions(ln_idx)    -- 出荷指示
        ,gt_ins_h_cust_po_number(ln_idx)           -- 顧客発注
        ,gt_ins_h_order_source_ref(ln_idx)         -- 受注ソース参照
        ,gt_ins_h_schedule_ship_date(ln_idx)       -- 出荷予定日
        ,gt_ins_h_schedule_arrival_date(ln_idx)    -- 着荷予定日
        ,NULL                                      -- パレット使用枚数
        ,NULL                                      -- パレット回収枚数
        ,gt_ins_h_location_code(ln_idx)            -- 出荷元
        ,gt_ins_h_head_sales_branch(ln_idx)        -- 管轄拠点
        ,gt_ins_h_input_sales_branch(ln_idx)       -- 入力拠点
        ,gt_ins_h_arrival_time_from(ln_idx)        -- 着荷時間From
        ,gt_ins_h_arrival_time_to(ln_idx)          -- 着荷時間To
        ,gt_ins_h_data_type(ln_idx)                -- データタイプ
        ,NULL                                      -- 運送業者
        ,NULL                                      -- 配送区分
        ,NULL                                      -- 配送No
        ,NULL                                      -- 出荷日
        ,NULL                                      -- 着荷日
        ,NULL                                      -- EOSデータ種別
        ,NULL                                      -- 伝送用枝番
        ,NULL                                      -- 入庫倉庫
        ,NULL                                      -- 倉替返品区分
        ,gt_ins_h_order_number(ln_idx)             -- 依頼区分
        ,NULL                                      -- 報告部署
        ,NULL                                      -- 制御番号
        ,NULL                                      -- 予備01
        ,NULL                                      -- 予備02
        ,NULL                                      -- 予備03
        ,NULL                                      -- 予備04
        ,NULL                                      -- 予備05
        ,NULL                                      -- 予備06
        ,NULL                                      -- 予備07
        ,NULL                                      -- 予備08
        ,NULL                                      -- 予備09
        ,NULL                                      -- 予備10
        ,NULL                                      -- 予備11
        ,NULL                                      -- 予備12
        ,NULL                                      -- 予備13
        ,NULL                                      -- 予備14
        ,NULL                                      -- 予備15
        ,NULL                                      -- 予備16
        ,NULL                                      -- 予備17
        ,NULL                                      -- 予備18
        ,cn_created_by                             -- 作成者
        ,cd_creation_date                          -- 作成日
        ,cn_last_updated_by                        -- 最終更新者
        ,cd_last_update_date                       -- 最終更新日
        ,cn_last_update_login                      -- 最終更新ログイン
        ,cn_request_id                             -- 要求ID
        ,cn_program_application_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,cn_program_id                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,cd_program_update_date                    -- プログラム更新日
      );
      --
      -- 登録件数
      gn_header_normal_cnt := gt_ins_h_header_id.COUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_ship_header_data;
--
  /**********************************************************************************
   * Procedure Name   : update_order_line
   * Description      : 受注明細更新(A-11)
   ***********************************************************************************/
  PROCEDURE update_order_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line'; -- プログラム名
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
    cn_index                   CONSTANT NUMBER := 1;    -- インデックス
    cn_version                 CONSTANT NUMBER := 1.0;  -- APIのバージョン
    --
    -- *** ローカル変数 ***
    ln_cnt                     NUMBER;                  -- カウンタ
    lv_key_info                VARCHAR2(1000);          -- キー情報
    lv_order_number            VARCHAR2(100);           -- 受注番号
    lv_line_number             VARCHAR2(100);           -- 明細番号
    lv_table_name              VARCHAR2(100);           -- テーブル名
    ln_header_key              NUMBER;                  -- PL/SQL表のキー
    -- 受注明細更新API用
    lt_header_rec              OE_ORDER_PUB.Header_Rec_Type;
    lt_header_val_rec          OE_ORDER_PUB.Header_Val_Rec_Type;
    lt_header_adj_tbl          OE_ORDER_PUB.Header_Adj_Tbl_Type;
    lt_header_adj_val_tbl      OE_ORDER_PUB.Header_Adj_Val_Tbl_Type;
    lt_header_price_att_tbl    OE_ORDER_PUB.Header_Price_Att_Tbl_Type;
    lt_header_adj_att_tbl      OE_ORDER_PUB.Header_Adj_Att_Tbl_Type;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.Header_Adj_Assoc_Tbl_Type;
    lt_header_scredit_tbl      OE_ORDER_PUB.Header_Scredit_Tbl_Type;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.Header_Scredit_Val_Tbl_Type;
    lt_line_tbl                OE_ORDER_PUB.Line_Tbl_Type;
    lt_line_val_tbl            OE_ORDER_PUB.Line_Val_Tbl_Type;
    lt_line_adj_tbl            OE_ORDER_PUB.Line_Adj_Tbl_Type;
    lt_line_adj_val_tbl        OE_ORDER_PUB.Line_Adj_Val_Tbl_Type;
    lt_line_price_att_tbl      OE_ORDER_PUB.Line_Price_Att_Tbl_Type;
    lt_line_adj_att_tbl        OE_ORDER_PUB.Line_Adj_Att_Tbl_Type;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.Line_Adj_Assoc_Tbl_Type;
    lt_line_scredit_tbl        OE_ORDER_PUB.Line_Scredit_Tbl_Type;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.Line_Scredit_Val_Tbl_Type;
    lt_lot_serial_tbl          OE_ORDER_PUB.Lot_Serial_Tbl_Type;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.Lot_Serial_Val_Tbl_Type;
    lt_action_request_tbl      OE_ORDER_PUB.Request_Tbl_Type;
    lv_return_status           VARCHAR2(2);
    ln_msg_count               NUMBER := 0;
    lv_msg_data                VARCHAR2(2000);
    ln_count                   NUMBER;
    l_msg_count                NUMBER;
    l_index                    NUMBER := 1; 
/* 2009/09/16 Ver.1.12 Add Start */
    lv_dummy                  VARCHAR2(100);
    ln_update_err_flag        NUMBER DEFAULT 0;
/* 2009/09/16 Ver.1.12 Add End */
    --
    l_count  number;
    -- *** ローカル例外 ***
    order_line_update_expt      EXCEPTION;    -- 受注明細更新エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 明細更新データ作成
    -- ===============================
    ------------------------------
    -- 明細データ設定
    ------------------------------
/* 2009/09/16 Ver.1.12 Del Start */
--    <<make_line_data>>
--    FOR ln_idx IN 0..gt_ins_l_header_id.LAST LOOP
--      gt_upd_order_line_tbl(ln_idx).header_id := gt_upd_header_id(ln_idx);                   -- ヘッダID(受注)
--      gt_upd_order_line_tbl(ln_idx).line_id := gt_ins_l_line_id(ln_idx);                     -- 明細ID
--      gt_upd_order_line_tbl(ln_idx).line_number := gt_ins_l_line_number(ln_idx);             -- 明細番号
--      gt_upd_order_line_tbl(ln_idx).ship_from_org_id := gt_ins_l_ship_from_org_id(ln_idx);   -- 組織
--      gt_upd_order_line_tbl(ln_idx).req_header_id := gt_ins_l_header_id(ln_idx);              -- ヘッダID(依頼)
--    END LOOP make_line_data;
--    --
--    ------------------------------
--    -- 梱包指示設定
--    ------------------------------
--    <<loop_line_data>>
--    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
--      <<set_packing_inst>>
--      FOR ln_cnt IN 0..gt_ins_h_header_id.LAST LOOP
--        ln_header_key := ln_cnt;
--        EXIT WHEN gt_upd_order_line_tbl(ln_idx).req_header_id = gt_ins_h_header_id(ln_cnt);
--      END LOOP set_packing_inst;
--      --
--      -- 梱包指示に出荷依頼番号を設定
--      gt_upd_order_line_tbl(ln_idx).order_source_ref := gt_ins_h_order_source_ref(ln_header_key);
--      gt_upd_order_line_tbl(ln_idx).order_number := gt_ins_h_order_number(ln_header_key);
--    END LOOP loop_line_data;
/* 2009/09/16 Ver.1.12 Del End */
    --
/* 2009/12/07 Ver1.19 Del Start */
--    -- OMメッセージリストの初期化
--    OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 Del End */
    --
    -- ===============================
    -- 明細更新
    -- ===============================
    <<update_line_data>>
/* 2009/09/16 Ver.1.12 Mod Start */
    FOR ln_idx IN 1..gt_order_upd_tbl.COUNT LOOP
/* 2009/12/07 Ver1.19 Add Start */
      -- OMメッセージリストの初期化
      OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 Add End */
      lt_line_tbl(cn_index)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(cn_index).operation              := OE_GLOBALS.G_OPR_UPDATE;                         -- 処理モード
      lt_line_tbl(cn_index).line_id                := gt_order_upd_tbl(ln_idx).line_id;                -- 明細ID
      lt_line_tbl(cn_index).ship_from_org_id       := gt_order_upd_tbl(ln_idx).ship_from_org_id;       -- 組織ID
      lt_line_tbl(cn_index).packing_instructions   := gt_order_upd_tbl(ln_idx).order_source;           -- 梱包指示
      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;
      lt_line_tbl(cn_index).program_id             := cn_program_id;
      lt_line_tbl(cn_index).program_update_date    := cd_program_update_date;
      lt_line_tbl(cn_index).request_id             := cn_request_id;
      --
      IF gt_order_ins_tbl.COUNT > 0 THEN
        <<ins_loop>>
        FOR ln_ins_idx IN 1..gt_order_ins_tbl.COUNT LOOP
          IF ( gt_order_ins_tbl(ln_ins_idx).line_id = gt_order_upd_tbl(ln_idx).line_id ) THEN
            IF ( gt_order_upd_tbl(ln_idx).order_quantity_uom = gt_order_upd_tbl(ln_idx).conv_order_quantity_uom ) THEN
              -- 受注画面の入力単位が基準単位の場合
              lt_line_tbl(cn_index).ordered_quantity := gt_order_upd_tbl(ln_idx).checked_quantity;
            ELSE
              -- 受注画面の入力単位がCSの場合
              lt_line_tbl(cn_index).ordered_quantity := gt_order_upd_tbl(ln_idx).checked_quantity / gt_order_upd_tbl(ln_idx).qty_case;
            END IF;
            lt_line_tbl(cn_index).change_reason  := '00';
          END IF;
        END LOOP ins_loop;
      END IF;
--    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
--      lt_line_tbl(cn_index) := OE_ORDER_PUB.G_MISS_LINE_REC;
--      lt_line_tbl(cn_index).operation := OE_GLOBALS.G_OPR_UPDATE;                                     -- 処理モード
--      lt_line_tbl(cn_index).line_id := gt_upd_order_line_tbl(ln_idx).line_id;                         -- 明細ID
--      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- 組織ID
--      lt_line_tbl(cn_index).packing_instructions := gt_upd_order_line_tbl(ln_idx).order_source_ref;   -- 梱包指示
--      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- 組織ID
--      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;
--      lt_line_tbl(cn_index).program_id := cn_program_id;
--      lt_line_tbl(cn_index).program_update_date := cd_program_update_date;
--      lt_line_tbl(cn_index).request_id := cn_request_id;
/* 2009/09/16 Ver.1.12 Mod End */
      --
      --
      --================================================================--
      -- Process Order API
      --================================================================--
      OE_ORDER_PUB.PROCESS_ORDER(
         -- IN Variables
         p_api_version_number      => cn_version
        ,p_line_tbl                => lt_line_tbl
         -- OUT Variables
        ,x_header_rec              => lt_header_rec
        ,x_header_val_rec          => lt_header_val_rec
        ,x_header_adj_tbl          => lt_header_adj_tbl
        ,x_header_adj_val_tbl      => lt_header_adj_val_tbl
        ,x_header_price_att_tbl    => lt_header_price_att_tbl
        ,x_header_adj_att_tbl      => lt_header_adj_att_tbl
        ,x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
        ,x_header_scredit_tbl      => lt_header_scredit_tbl
        ,x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
        ,x_line_tbl                => lt_line_tbl
        ,x_line_val_tbl            => lt_line_val_tbl
        ,x_line_adj_tbl            => lt_line_adj_tbl
        ,x_line_adj_val_tbl        => lt_line_adj_val_tbl
        ,x_line_price_att_tbl      => lt_line_price_att_tbl
        ,x_line_adj_att_tbl        => lt_line_adj_att_tbl
        ,x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
        ,x_line_scredit_tbl        => lt_line_scredit_tbl
        ,x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
        ,x_lot_serial_tbl          => lt_lot_serial_tbl
        ,x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
        ,x_action_request_tbl      => lt_action_request_tbl
        ,x_return_status           => lv_return_status
        ,x_msg_count               => ln_msg_count
        ,x_msg_data                => lv_msg_data
      );
/* 2009/09/16 Ver.1.12 Add Start */
      BEGIN
        SELECT  '1'
        INTO    lv_dummy
        FROM    oe_order_lines_all   oola
        WHERE   oola.line_id              = gt_order_upd_tbl(ln_idx).line_id
        AND     oola.packing_instructions = gt_order_upd_tbl(ln_idx).order_source;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_update_err_flag := 1;
      END;
/* 2009/09/16 Ver.1.12 Add End */
      -- API実行結果確認
/* 2009/09/16 Ver.1.12 Mod Start */
      IF (( lv_return_status <> FND_API.G_RET_STS_SUCCESS )
          OR ( ln_update_err_flag = 1 )) THEN
        --
        IF ln_msg_count > 0 THEN
          FOR l_index IN 1..ln_msg_count LOOP
            lv_msg_data := oe_msg_pub.get(p_msg_index => l_index, p_encoded =>'F');
          END LOOP;
          lv_errbuf := substrb( lv_msg_data,1,250);
        END IF;
--      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
/* 2009/09/16 Ver.1.12 Mod End */
        -- 明細更新エラー
        -- メッセージ文字列取得(受注番号)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_order_number             -- メッセージID
        );
        --
        -- メッセージ文字列取得(明細番号)
        lv_line_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_line_number              -- メッセージID
        );
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- 受注番号
         ,iv_data_value1    => gt_upd_order_line_tbl(ln_idx).order_number
         ,iv_item_name2     => lv_line_number                   -- 明細番号
         ,iv_data_value2    => gt_upd_order_line_tbl(ln_idx).line_number
         ,ov_key_info       => lv_key_info                      -- 編集後キー情報
         ,ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
         ,ov_retcode        => lv_retcode                       -- リターンコード
         ,ov_errmsg         => lv_errmsg                        -- ユーザ・エラー・メッセージ
        );
        RAISE order_line_update_expt;
      END IF;
    END LOOP update_line_data;
--
  EXCEPTION
    WHEN order_line_update_expt THEN
      --*** 受注明細更新エラー ***
      -- メッセージ文字列取得(受注明細)
      lv_table_name := xxccp_common_pkg.get_msg(
             iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
            ,iv_name        => cv_msg_line_number              -- メッセージID
          );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_update_error
        ,iv_token_name1  => cv_tkn_table_name
        ,iv_token_value1 => lv_table_name
        ,iv_token_name2  => cv_tkn_key_data
        ,iv_token_value2 => lv_key_info);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_order_line;
--
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
  /**********************************************************************************
   * Procedure Name   : start_production_system
   * Description      : 生産システム起動
   ***********************************************************************************/
  PROCEDURE start_production_system(
    iv_base_code  IN         VARCHAR2,     --   拠点コード
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_production_system'; -- プログラム名
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
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_resp_prod          CONSTANT VARCHAR2(50) := 'XXCOS1_RESPONSIBILITY_PRODUCTION';  -- プロファイル：生産への切替用職責
/* 2009/09/16 Ver.1.12 Del End */
    cv_xxwsh_short_name   CONSTANT VARCHAR2(10) := 'XXWSH';                             -- 生産システム短縮名
    cv_xxcos_short_name   CONSTANT VARCHAR2(10) := 'XXCOS';                             -- 販売チーム短縮名
    cv_cus_order_pkg      CONSTANT VARCHAR2(50) := 'XXWSH400002C';                      -- 顧客発注からの出荷依頼自動作成
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_msg_get_login      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11638';                  -- ログイン情報取得エラー
--    cv_msg_get_resp       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11639';                  -- プロファイル(切替用職責)取得エラー
--    cv_msg_get_login_prod CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11640';                  -- 切替先ログイン情報取得エラー
/* 2009/09/16 Ver.1.12 Del End */
    cv_msg_start_err_cus  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11641';                  -- コンカレント起動(顧客発注)エラー
/* 2009/11/04 Ver.1.14 Del Start */
--    cv_msg_get_input_base CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11642';                  -- 入力拠点取得エラー
/* 2009/11/04 Ver.1.14 Del End */
    cv_msg_standby_err    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11643';                  -- コンカレント終了待機エラー
    cv_msg_request_id     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11644';                  -- コンカレント要求ID
    cv_con_status_normal  CONSTANT VARCHAR2(10) := 'NORMAL';                            -- ステータス（正常）
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    cv_con_status_warning CONSTANT VARCHAR2(10) := 'WARNING';                           -- ステータス（警告）
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
    cv_user_id            CONSTANT VARCHAR2(10) := 'USER_ID';                           -- ユーザID
    cv_tkn_code           CONSTANT VARCHAR2(10) := 'CODE';                              -- メッセージ用トークン
    cb_sub_request        CONSTANT BOOLEAN      := FALSE;                               -- Sub_request
    cn_interval           CONSTANT NUMBER       := 15;                                  -- Interval
    cn_max_wait           CONSTANT NUMBER       := 0;                                   -- Max_wait
--
    -- *** ローカル変数 ***
    ln_login_user_id      NUMBER;                -- ログインユーザID
    ln_login_resp_id      NUMBER;                -- ログイン職責ID
    ln_login_resp_appl_id NUMBER;                -- ログイン職責アプリケーションID
    lv_resp_prod          VARCHAR2(100);         -- 生産への切替用職責名
    ln_prod_user_id       NUMBER;                -- 切替用ユーザID
    ln_prod_resp_id       NUMBER;                -- 切替用職責ID
    ln_prod_resp_appl_id  NUMBER;                -- 切替用職責アプリケーションID
    ln_request_id         NUMBER DEFAULT 0;      -- 要求ID
    lb_wait_result        BOOLEAN;               -- コンカレント待機成否
    lv_phase              VARCHAR2(50);
    lv_status             VARCHAR2(50);
    lv_dev_phase          VARCHAR2(50);
    lv_dev_status         VARCHAR2(50);
    lv_message            VARCHAR2(5000);
    lv_request_id_message VARCHAR2(5000);
/* 2009/11/04 Ver.1.14 Del End */
--    lt_input_base_code    xxcmn_cust_accounts_v.party_number%TYPE;                      -- 入力拠点
/* 2009/11/04 Ver.1.14 Del End */
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 初期処理
    -- ===============================
    -- *** ログイン情報の取得 ***
    BEGIN
--
      SELECT
         fnd_global.user_id      AS USER_ID        -- ログインユーザID
        ,fnd_global.resp_id      AS RESP_ID        -- ログイン職責ID
        ,fnd_global.resp_appl_id AS RESP_APPL_ID   -- ログイン職責アプリケーションID
      INTO
         ln_login_user_id
        ,ln_login_resp_id
        ,ln_login_resp_appl_id
      FROM
         DUAL
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login        -- ログイン情報取得エラー
                     );
        RAISE global_api_expt;
    END;
--
    -- *** プロファイル：生産への切替用職責名称の取得 ***
    lv_resp_prod := FND_PROFILE.VALUE( cv_resp_prod );
--
    -- プロファイル取得エラーの場合
    IF ( lv_resp_prod IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,      -- XXCOS
                     iv_name        => cv_msg_get_resp           -- プロファイル(切替用職責)取得エラー
                   );
      RAISE global_api_expt;
    END IF;
--
    -- *** 切替先ログイン情報の取得 ***
    BEGIN
--
      SELECT
          responsibility_id AS RESPONSIBILITY_ID   -- 切替用職責ID
         ,application_id    AS APPLICATION_ID      -- 切替用職責アプリケーションID
      INTO
          ln_prod_resp_id
         ,ln_prod_resp_appl_id
      FROM
          fnd_responsibility_vl
      WHERE
          responsibility_name = lv_resp_prod       -- 切替用職責名称
      AND ROWNUM              = 1
      ;
--
      -- 切替用ユーザIDの取得
      ln_prod_user_id := ln_login_user_id;         -- ログインユーザID
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login_prod   -- 切替先ログイン情報取得エラー
                     );
        RAISE global_api_expt;
    END;
--
/* 2009/11/04 Ver.1.14 Del Start */
--    -- *** 入力拠点の取得 ***
--    IF ( iv_base_code IS NOT NULL ) THEN
--      -- 入力パラメータ.拠点コードを入力拠点に設定
--      lt_input_base_code := iv_base_code;
--      --
--    ELSE
--      -- ログインユーザの所属拠点コードを入力拠点に設定
--      BEGIN
--      --
----****************************** 2009/05/26 1.7 T.Kitajima ADD START ******************************--
----        SELECT
----            xcav.party_number AS input_base_code
----        INTO
----            lt_input_base_code
----        FROM
----            fnd_user              fu
----           ,per_all_people_f      papf
----           ,per_all_assignments_f paaf
----           ,xxcmn_locations_v     xlv
----           ,xxcmn_cust_accounts_v xcav 
----        WHERE 
----            fu.user_id        = fnd_profile.value( cv_user_id ) 
----        AND fu.employee_id    = papf.person_id
----        AND nvl( papf.effective_start_date, TRUNC( gd_business_date ) ) <= TRUNC( gd_business_date )
----        AND nvl( papf.effective_end_date,   TRUNC( gd_business_date ) ) >= TRUNC( gd_business_date )
----        AND papf.person_id    = paaf.person_id
----        AND nvl( paaf.effective_start_date, TRUNC( gd_business_date ) ) <= TRUNC( gd_business_date )
----        AND nvl( paaf.effective_end_date,   TRUNC( gd_business_date ) ) >= TRUNC( gd_business_date )
----        AND paaf.location_id  = xlv.location_id
----        AND xlv.location_code = xcav.party_number
--        SELECT xlobi.base_code             input_base_code
--          INTO lt_input_base_code
--          FROM xxcos_login_own_base_info_v xlobi
--        ;
----****************************** 2009/05/26 1.7 T.Kitajima ADD  END  ******************************--
--      --
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application => cv_xxcos_short_name,    -- XXCOS
--                         iv_name        => cv_msg_get_input_base   -- 入力拠点取得エラー
--                       );
--          RAISE global_api_expt;
--      END;
----
--    END IF;
/* 2009/11/04 Ver.1.14 Del End */
--
    -- ===============================
    -- ログイン切替(生産OUへ)
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
      ln_prod_user_id,          -- ユーザID
      ln_prod_resp_id,          -- 職責ID
      ln_prod_resp_appl_id      -- アプリケーションID
    );
--
    --コンカレント起動のためコミット
    COMMIT;
    -- ===============================
    -- コンカレント起動
    -- ===============================
    ln_request_id := fnd_request.submit_request(
                       application => cv_xxwsh_short_name,       -- XXWSH
                       program     => cv_cus_order_pkg,          -- XXWSH400002C
                       description => NULL,
                       start_time  => NULL,
                       sub_request => cb_sub_request,            -- FALSE
/* 2009/11/04 Ver.1.14 Mod Start */
                       argument1   => gt_input_base_code,            -- 引数：入力拠点
--                       argument1   => lt_input_base_code,        -- 引数：入力拠点
/* 2009/11/04 Ver.1.14 Mod Start */
                       argument2   => NULL                       -- 引数：管轄拠点
                     );
--
    -- 要求ID出力
    lv_request_id_message := xxccp_common_pkg.get_msg(
                               iv_application  => cv_xxcos_short_name,      -- XXCOS
                               iv_name         => cv_msg_request_id,        -- コンカレント要求ID
                               iv_token_name1  => cv_tkn_code,              -- CODE
                               iv_token_value1 => TO_CHAR( ln_request_id )  -- 要求ID
                             );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_request_id_message
    ); 
--
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,      -- XXCOS
                     iv_name        => cv_msg_start_err_cus      -- コンカレント起動(顧客発注)エラー
                   );
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
                        request_id => ln_request_id,
/* 2009/07/28 Ver.1.11 Mod Start */
--                        interval   => cn_interval,
--                        max_wait   => cn_max_wait,
                        interval   => gt_interval,
                        max_wait   => gt_max_wait,
/* 2009/07/28 Ver.1.11 Mod End   */
                        phase      => lv_phase,
                        status     => lv_status,
                        dev_phase  => lv_dev_phase,
                        dev_status => lv_dev_status,
                        message    => lv_message
                      );
--
    -- ===============================
    -- ログイン切替(営業OUへ)
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
      ln_login_user_id,         -- ユーザID
      ln_login_resp_id,         -- 職責ID
      ln_login_resp_appl_id     -- アプリケーションID
    );
--
    --コンカレントの終了ステータス
    IF ( ( lb_wait_result = FALSE )
      OR ( lv_dev_status NOT IN ( cv_con_status_normal, cv_con_status_warning ) ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,    -- XXCOS
                     iv_name        => cv_msg_standby_err      -- コンカレント起動(顧客発注)エラー
                   );
      RAISE global_api_expt;
    END IF;
    --警告終了時
    IF ( lv_dev_status = cv_con_status_warning ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END start_production_system;
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
--
/* 2009/09/16 Ver.1.12 Add Start */
--
  /**********************************************************************************
   * Procedure Name   : weight_check
   * Description      : 積載効率最適化チェック(A-14)
   ***********************************************************************************/
  PROCEDURE weight_check(
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'weight_check'; -- プログラム名
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
    cn_status_normal          CONSTANT NUMBER       := 0;                     -- 生産APIステイタス:正常
    cn_status_error           CONSTANT NUMBER       := 1;                     -- 生産APIステイタス:異常
    cv_warehouse_code         CONSTANT VARCHAR2(1)  := '4';                   -- コード区分:倉庫
    cv_delivery_code          CONSTANT VARCHAR2(1)  := '9';                   -- コード区分：配送先
    cv_small_amount_class     CONSTANT VARCHAR2(1)  := '1';                   -- 小口区分
    cv_tkn_whse_locat         CONSTANT VARCHAR2(30) := 'WHSE_LOCAT';          -- 出荷元保管場所
    cv_tkn_delivery_code      CONSTANT VARCHAR2(30) := 'DELIVERY_CODE';       -- 配送先
    cv_tkn_item_div_name      CONSTANT VARCHAR2(30) := 'ITEM_DIV_NAME';       -- 商品区分
    cv_tkn_sum_weight         CONSTANT VARCHAR2(30) := 'SUM_WEIGHT';          -- 合計重量
    cv_tkn_sum_capacity       CONSTANT VARCHAR2(30) := 'SUM_CAPACITY';        -- 合計容積
    cv_tkn_err_msg            CONSTANT VARCHAR2(30) := 'ERR_MSG';             -- エラーメッセージ
    cn_efficiency_over        CONSTANT NUMBER       := 1;                     -- オーバー
    cn_efficiency_non_over    CONSTANT NUMBER       := 0;                     -- 未満
--
    lv_line_key                 VARCHAR2(1000);     -- 明細キー
    lv_pre_line_key             VARCHAR2(1000);     -- 前明細キー
    lv_pre_head_sort_key        VARCHAR2(1000);     -- ヘッダソートキー
    lv_index                    VARCHAR2(1000);     -- インデックス
    lv_small_amount_class       VARCHAR2(10);       -- 小口区分
    lv_max_ship_methods         VARCHAR2(10);       -- 最大配送区分
    lv_loading_over_class       VARCHAR2(100);      -- 積載オーバー区分
    lv_ship_methods             VARCHAR2(100);      -- 出荷方法
    lv_mixed_ship_method        VARCHAR2(100);      -- 混載配送区分
    lv_output_msg               VARCHAR2(1000);     -- 出力メッセージ
    lv_index_wk                 VARCHAR2(1000);     -- インデックス
    ln_ret_val                  NUMBER;             -- リターン値
    ln_sum_capacity             NUMBER;             -- 合算合計容積
    ln_sum_weight               NUMBER;             -- 合算合計重量
    ln_load_efficiency_weight   NUMBER;             -- 重量積載効率
    ln_load_efficiency_capacity NUMBER;             -- 容積積載効率
    ln_load_efficiency          NUMBER;             -- 積載効率
    ln_check_qty                NUMBER DEFAULT 0;   -- チェック済数量
    ln_drink_deadweight         NUMBER;             -- ドリンク積載重量
    ln_leaf_deadweight          NUMBER;             -- リーフ積載重量
    ln_drink_loading_capacity   NUMBER;             -- ドリンク積載容積
    ln_leaf_loading_capacity    NUMBER;             -- リーフ積載容積
    ln_palette_max_qty          NUMBER;             -- パレット最大枚数
    ln_save_check_qty           NUMBER;             -- 前回チェック数量退避用
    ln_save_weight              NUMBER DEFAULT 0;   -- 前回チェック重量退避用
    ln_palette_max_step_qty     NUMBER;             -- 段数/パレット(ループ回数)
    ln_sum_pallet_weight        NUMBER;
    ln_diff_base_qty            NUMBER;
    ln_case_qty                 NUMBER;             -- ケース数/段
    ln_non_stack                NUMBER;
    ln_now_check_qty            NUMBER;
    ln_delivery_unit            NUMBER DEFAULT 0;
    ln_wk                       NUMBER;
    ld_standard_date            DATE;
    lt_checked_rec              order_data_cur%ROWTYPE;
    ld_error_flag               BOOLEAN DEFAULT TRUE;
    ln_step_stack_flag          NUMBER;
    ln_total_palette            NUMBER;
    ln_total_step               NUMBER;
    ln_total_case               NUMBER;
    ln_efficiency_over_flag     NUMBER;   -- 積載効率オーバーフラグ(0：未満、1：オーバー)
    ln_check_palette            NUMBER;
    ln_check_step               NUMBER;
    ln_check_case               NUMBER;
    ln_consolidation_flag       NUMBER DEFAULT 0;
    ln_palette_over_flag        NUMBER;
    ln_order_qty                NUMBER;
    ln_set                      NUMBER;
    ln_loop_flag                NUMBER;
    --
    small_amount_class_expt    EXCEPTION;     -- 小口区分取得エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    lv_index             := gt_order_sort_wk_tbl.FIRST;
    lv_line_key          := gt_order_sort_wk_tbl(lv_index).line_key;
    lv_pre_line_key      := 'NULL';
    lv_pre_head_sort_key := 'NULL';
--
    <<check_loop>>
    WHILE lv_index IS NOT NULL LOOP
      IF ( lv_pre_line_key <> gt_order_sort_wk_tbl(lv_index).line_key ) THEN
        lv_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        ln_total_palette := gt_order_sort_wk_tbl(lv_index).total_conv_palette;
        ln_total_step    := gt_order_sort_wk_tbl(lv_index).total_conv_step;
        ln_total_case    := gt_order_sort_wk_tbl(lv_index).total_conv_case;
        -- ヘッダソートキーがブレイクした場合
        IF ( lv_pre_head_sort_key <> gt_order_sort_wk_tbl(lv_index).head_sort_key ) THEN
            ln_save_weight := 0;
            ln_consolidation_flag := 0;
        END IF;
        --
        -- 積載率のチェック
        -- ==============================================
        -- 出荷元保管場所・配送先間の最大配送区分を算出
        -- ==============================================
        ln_ret_val := xxwsh_common_pkg.get_max_ship_method(
               iv_code_class1                  =>  cv_warehouse_code                   -- 1.コード区分１
              ,iv_entering_despatching_code1   =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv           -- 2.入出庫場所コード１
              ,iv_code_class2                  =>  cv_delivery_code                    -- 3.コード区分２
              ,iv_entering_despatching_code2   =>  gt_order_sort_wk_tbl(lv_index).province                 -- 4.入出庫場所コード２
              ,iv_prod_class                   =>  gt_order_sort_wk_tbl(lv_index).prod_class_code       -- 5.商品区分
              ,iv_weight_capacity_class        =>  gt_order_sort_wk_tbl(lv_index).wc_class                 -- 6.重量容積区分
              ,iv_auto_process_type            =>  NULL                                -- 7.自動配車対象区分
              ,id_standard_date                =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date       -- 8.基準日(適用日基準日)
              ,ov_max_ship_methods             =>  lv_max_ship_methods                 -- 9.最大配送区分
              ,on_drink_deadweight             =>  ln_drink_deadweight                 -- 10.ドリンク積載重量
              ,on_leaf_deadweight              =>  ln_leaf_deadweight                  -- 11.リーフ積載重量
              ,on_drink_loading_capacity       =>  ln_drink_loading_capacity           -- 12.ドリンク積載容積
              ,on_leaf_loading_capacity        =>  ln_leaf_loading_capacity            -- 13.リーフ積載容積
              ,on_palette_max_qty              =>  ln_palette_max_qty                  -- 14.パレット最大枚数
                            );
        -- リターンコードチェック
        IF ( ln_ret_val <> cn_status_error ) THEN
          -- 最大配送区分取得が取得できた場合
          -- ==============================================
          -- ドリンクの場合、最大配送区分の小口区分取得
          -- ==============================================
          IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_drink ) THEN
            BEGIN
              SELECT  xsmv.small_amount_class    -- 小口区分
              INTO    lv_small_amount_class
              FROM    xxwsh_ship_method_v    xsmv
              WHERE   xsmv.ship_method_code = lv_max_ship_methods;
            EXCEPTION
              WHEN OTHERS THEN
                RAISE small_amount_class_expt;
            END;
            --
            -- 小口区分の判定
            IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
              -- 合計重量に合計パレット重量を加算
              ln_sum_weight := gt_order_sort_wk_tbl(lv_index).add_sum_weight + gt_order_sort_wk_tbl(lv_index).add_sum_pallet_weight;
            ELSE
              ln_sum_weight := gt_order_sort_wk_tbl(lv_index).add_sum_weight;
            END IF;
          END IF;
          --
          -- ==============================================
          -- 積載効率算出
          -- ==============================================
          IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_drink ) THEN
            -- ドリンクの場合
            ln_sum_weight := ln_sum_weight;
            ln_sum_capacity := NULL;
          ELSE
            -- リーフの場合
            ln_sum_weight  := NULL;
            ln_sum_capacity := gt_order_sort_wk_tbl(lv_index).add_sum_capacity;
          END IF;
          --
          IF ( ln_consolidation_flag = 1 ) THEN
            ln_sum_weight := ln_sum_weight + ln_save_weight;
          END IF;
          --
          xxwsh_common910_pkg.calc_load_efficiency(
             in_sum_weight                   =>  ln_sum_weight                     -- 1.合計重量
            ,in_sum_capacity                 =>  ln_sum_capacity                   -- 2.合計容積
            ,iv_code_class1                  =>  cv_warehouse_code                 -- 3.コード区分１
            ,iv_entering_despatching_code1   =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv         -- 4.入出庫場所コード１
            ,iv_code_class2                  =>  cv_delivery_code                  -- 5.コード区分２
            ,iv_entering_despatching_code2   =>  gt_order_sort_wk_tbl(lv_index).province               -- 6.入出庫場所コード２
            ,iv_ship_method                  =>  lv_max_ship_methods               -- 7.出荷方法
            ,iv_prod_class                   =>  gt_order_sort_wk_tbl(lv_index).prod_class_code        -- 8.商品区分
            ,iv_auto_process_type            =>  NULL                              -- 9.自動配車対象区分
            ,id_standard_date                =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date     -- 10.基準日(適用日基準日)
            ,ov_retcode                      =>  lv_retcode                        -- 11.リターンコード
            ,ov_errmsg_code                  =>  lv_errbuf                         -- 12.エラーメッセージコード
            ,ov_errmsg                       =>  lv_errmsg                         -- 13.エラーメッセージ
            ,ov_loading_over_class           =>  lv_loading_over_class             -- 14.積載オーバー区分
            ,ov_ship_methods                 =>  lv_ship_methods                   -- 15.出荷方法
            ,on_load_efficiency_weight       =>  ln_load_efficiency_weight         -- 16.重量積載効率
            ,on_load_efficiency_capacity     =>  ln_load_efficiency_capacity       -- 17.容積積載効率
            ,ov_mixed_ship_method            =>  lv_mixed_ship_method              -- 18.混載配送区分
          );
          --
          -- リターンコードチェック
          IF ( lv_retcode = cv_status_normal ) THEN
            -- 積載効率のチェック
            IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_drink ) THEN
              -- ドリンクの場合
              ln_load_efficiency := ln_load_efficiency_weight;
            ELSE
              -- リーフの場合
              ln_load_efficiency := ln_load_efficiency_capacity;
            END IF;
            --
            IF ( ln_load_efficiency <= 100 ) THEN
              -- 積載効率が100%以下の場合
              IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_leaf ) THEN
                -- リーフの場合
                -- ========================================
                -- 出荷依頼I/F作成用PL/SQL表に設定
                -- ========================================
/* 2009/11/24 Ver1.17 Add Start */
                IF ( lv_pre_head_sort_key <> gt_order_sort_wk_tbl(lv_index).head_sort_key ) THEN
                -- ヘッダキーがブレイクした場合
/* 2009/11/24 Ver1.17 Add End */
                ln_delivery_unit := ln_delivery_unit + 1;
/* 2009/11/24 Ver1.17 Add Start */
                END IF;
/* 2009/11/24 Ver1.17 Add End */
                lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                <<head_loop>>
                WHILE  lv_index_wk IS NOT NULL LOOP
                  IF (lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key ) THEN
                    gt_order_sort_wk_tbl(lv_index_wk).checked_quantity := gt_order_sort_wk_tbl(lv_index_wk).base_quantity;
                    gt_order_sort_wk_tbl(lv_index_wk).delivery_unit := ln_delivery_unit;
                    gt_order_sort_wk_tbl(lv_index_wk).max_ship_methods := lv_max_ship_methods;
                    gt_delivery_if_wk_tbl(gn_deliv_cnt) := gt_order_sort_wk_tbl(lv_index_wk);
                    gn_deliv_cnt := gn_deliv_cnt + 1;
                  END IF;
                  lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                END LOOP head_loop;
              ELSE
                -- ドリンクの場合
                -- ========================================
                -- 出荷依頼I/F作成用PL/SQL表に設定
                -- ========================================
                IF ( ln_consolidation_flag = 0 ) THEN
                  ln_delivery_unit := ln_delivery_unit + 1;
                END IF;
                lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                <<head_loop>>
                WHILE  lv_index_wk IS NOT NULL LOOP
                  IF (lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key ) THEN
                    gt_order_sort_wk_tbl(lv_index_wk).checked_quantity := gt_order_sort_wk_tbl(lv_index_wk).base_quantity;
                    gt_order_sort_wk_tbl(lv_index_wk).delivery_unit := ln_delivery_unit;
                    gt_order_sort_wk_tbl(lv_index_wk).max_ship_methods := lv_max_ship_methods;
                    gt_delivery_if_wk_tbl(gn_deliv_cnt) := gt_order_sort_wk_tbl(lv_index_wk);
                    gn_deliv_cnt := gn_deliv_cnt + 1;
                  END IF;
                  lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                END LOOP head_loop;
                -- 重量を退避
                ln_consolidation_flag := 1;
                ln_save_weight := ln_sum_weight;
              END IF;
            ELSE
              -- 積載効率が100%より大きい場合
              IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_leaf ) THEN
                -- リーフの場合
                -- ========================================
                -- 出荷依頼I/F作成用PL/SQL表に設定
                -- ========================================
/* 2009/11/24 Ver1.17 Add Start */
                IF ( lv_pre_head_sort_key <> gt_order_sort_wk_tbl(lv_index).head_sort_key ) THEN
                -- ヘッダキーがブレイクした場合
/* 2009/11/24 Ver1.17 Add End */
                ln_delivery_unit := ln_delivery_unit + 1;
/* 2009/11/24 Ver1.17 Add Start */
                END IF;
/* 2009/11/24 Ver1.17 Add End */
                lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                <<leaf_loop>>
                WHILE  lv_index_wk IS NOT NULL LOOP
                  IF ( lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key ) THEN
                    gt_order_sort_wk_tbl(lv_index_wk).checked_quantity := gt_order_sort_wk_tbl(lv_index_wk).base_quantity;
                    gt_order_sort_wk_tbl(lv_index_wk).delivery_unit := ln_delivery_unit;
                    gt_order_sort_wk_tbl(lv_index_wk).efficiency_over_flag := 1;
                    gt_order_sort_wk_tbl(lv_index_wk).max_ship_methods := lv_max_ship_methods;
                    gt_delivery_if_wk_tbl(gn_deliv_cnt) :=  gt_order_sort_wk_tbl(lv_index_wk);
                    gn_deliv_cnt := gn_deliv_cnt + 1;
                  END IF;
                  lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                END LOOP leaf_loop;
              ELSE
                -- ドリンクの場合
                -- ==============================================
                -- パレット単位の積み上げチェック
                -- ==============================================
                -- 初期化
                ln_check_qty := 0;
                ln_save_check_qty := 0;
                ln_load_efficiency_weight := 0;
                ln_check_palette := 0;
                ln_check_step := 0;
                ln_check_case := 0;
                ln_loop_flag := 1;
                --
                <<pallet_check_loop>>
                WHILE (ln_loop_flag = 1 ) LOOP
/* 2009/12/01 Ver1.18 Add Start */
                  IF ( ln_total_palette > 0 ) THEN
/* 2009/12/01 Ver1.18 Add END */
                    -- チェック本数設定(本数/パレット + 前回チェック数量)
                    ln_check_qty := gt_order_sort_wk_tbl(lv_index).qty_palette + ln_save_check_qty;
                    -- 今回チェックで積み増す本数
                    ln_now_check_qty := gt_order_sort_wk_tbl(lv_index).qty_palette;
                    --
                    -- ==============================================
                    -- 合計重量・合計容積・合計パレット重量を取得
                    -- ==============================================
                    xxwsh_common910_pkg.calc_total_value(
                       iv_item_no            => gt_order_sort_wk_tbl(lv_index).item_code           -- 品目コード
                      ,in_quantity           => ln_check_qty                                       -- 数量
                      ,ov_retcode            => lv_retcode                                         -- リターンコード
                      ,ov_errmsg_code        => lv_errbuf                                          -- エラーメッセージコード
                      ,ov_errmsg             => lv_errmsg                                          -- エラーメッセージ
                      ,on_sum_weight         => ln_sum_weight                                      -- 合計重量
                      ,on_sum_capacity       => ln_sum_capacity                                    -- 合計容積
                      ,on_sum_pallet_weight  => gt_order_sort_wk_tbl(lv_index).sum_pallet_weight   -- 合計パレット重量
                      ,id_standard_date      => gt_order_sort_wk_tbl(lv_index).schedule_ship_date  -- 基準日(適用日基準日)
                    );
                    --
                    -- リターンコードチェック
                    IF ( lv_retcode = cv_status_normal ) THEN
                      -- 正常の場合
                      IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
                        -- 小口区分が小口以外の場合、合計重量に合計パレット重量を加算
                        ln_sum_weight := ln_sum_weight + gt_order_sort_wk_tbl(lv_index).sum_pallet_weight;
                      END IF;
                      --
                      IF ( ln_consolidation_flag = 1 ) THEN
                         ln_sum_weight := ln_sum_weight + ln_save_weight;
                      END IF;
                      --
                      -- ==============================================
                      -- 積載効率算出
                      -- ==============================================
                      xxwsh_common910_pkg.calc_load_efficiency(
                         in_sum_weight                 =>  ln_sum_weight                                       -- 1.合計重量
                        ,in_sum_capacity               =>  NULL                                                -- 2.合計容積
                        ,iv_code_class1                =>  cv_warehouse_code                                   -- 3.コード区分１
                        ,iv_entering_despatching_code1 =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv             -- 4.入出庫場所コード１
                        ,iv_code_class2                =>  cv_delivery_code                     -- 5.コード区分２
                        ,iv_entering_despatching_code2 =>  gt_order_sort_wk_tbl(lv_index).province                               -- 6.入出庫場所コード２
                        ,iv_ship_method                =>  lv_max_ship_methods                                 -- 7.出荷方法
                        ,iv_prod_class                 =>  gt_order_sort_wk_tbl(lv_index).prod_class_code      -- 8.商品区分
                        ,iv_auto_process_type          =>  NULL                                  -- 9.自動配車対象区分
                        ,id_standard_date              =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date   -- 10.基準日(適用日基準日)
                        ,ov_retcode                    =>  lv_retcode                                          -- 11.リターンコード
                        ,ov_errmsg_code                =>  lv_errbuf                                           -- 12.エラーメッセージコード
                        ,ov_errmsg                     =>  lv_errmsg                                           -- 13.エラーメッセージ
                        ,ov_loading_over_class         =>  lv_loading_over_class                               -- 14.積載オーバー区分
                        ,ov_ship_methods               =>  lv_ship_methods                                     -- 15.出荷方法
                        ,on_load_efficiency_weight     =>  ln_load_efficiency_weight                           -- 16.重量積載効率
                        ,on_load_efficiency_capacity   =>  ln_load_efficiency_capacity                         -- 17.容積積載効率
                        ,ov_mixed_ship_method          =>  lv_mixed_ship_method                                -- 18.混載配送区分
                      );
                      -- リターンコードチェック
                      IF ( lv_retcode = cv_status_normal ) THEN
                        -- 正常の場合
                        IF ( ln_load_efficiency_weight <= 100 ) THEN
                          -- 積載効率が100%以下の場合
                          ln_save_check_qty := ln_check_qty;
                          ln_total_palette := ln_total_palette - 1;
                          --
                          ln_check_palette := ln_check_palette + 1;
                        ELSE
                          -- 積載効率が100%より大きい場合
                          ln_palette_over_flag := cn_efficiency_over;
                        END IF;
                        --
/* 2009/12/01 Ver1.18 Add Start */
                      ELSE
                        -- 積載効率算出エラーの場合
                        ov_retcode := cv_status_warn;
                        -- メッセージ作成
                        lv_output_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_name             -- アプリケーション短縮名
                          ,iv_name         => cv_calc_load_efficiency_err     -- メッセージ
                          ,iv_token_name1  => cv_tkn_item_div_name            -- 商品区分コード
                          ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
                          ,iv_token_name2  => cv_tkn_sum_weight               -- 合計重量
                          ,iv_token_value2 => ln_sum_weight
                          ,iv_token_name3  => cv_tkn_sum_capacity             -- 合計容積
                          ,iv_token_value3 => ''
                          ,iv_token_name4  => cv_tkn_whse_locat               -- 出荷元保管場所
                          ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
                          ,iv_token_name5  => cv_tkn_delivery_code            -- 配送先コード
                          ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
                          ,iv_token_name6  => cv_tkn_ship_method              -- 最大配送区分
                          ,iv_token_value6 => lv_max_ship_methods
                          ,iv_token_name7  => cv_tkn_schedule_ship_date       -- 出荷予定日
                          ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                          ,iv_token_name8  => cv_tkn_err_msg                  -- エラーメッセージ
                          ,iv_token_value8 => lv_errmsg
                        );
                        -- メッセージ出力
                        fnd_file.put_line(
                           which  => FND_FILE.OUTPUT
                          ,buff   => lv_output_msg
                        );
                        -- 空行出力
                        fnd_file.put_line(
                           which  => FND_FILE.OUTPUT
                          ,buff   => NULL
                        );
                        -- ループを抜ける
                        EXIT;
                      END IF;
                    ELSE
                      -- 合計重量・合計容積取得エラー
                      ov_retcode := cv_status_warn;
                      -- メッセージ作成
                      lv_output_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                        ,iv_name         => cv_calc_total_value_err              -- メッセージ
                        ,iv_token_name1  => cv_tkn_order_no             -- 受注番号
                        ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
                        ,iv_token_name2  => cv_tkn_item_code            -- 受注品目
                        ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
                        ,iv_token_name3  => cv_tkn_ordered_quantity     -- 受注数量
                        ,iv_token_value3 => ln_check_qty
                        ,iv_token_name4  => cv_tkn_schedule_ship_date   -- 出荷予定日
                        ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                        ,iv_token_name5  => cv_tkn_err_msg              -- エラーメッセージ
                        ,iv_token_value5 => lv_errmsg
                      );
                      -- メッセージ出力
                      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => lv_output_msg
                      );
                      -- 空行出力
                      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => NULL
                      );
                      -- ループを抜ける
                      EXIT;
                    END IF;
                  END IF;
/* 2009/12/01 Ver1.18 Add END */
                      IF ( ln_total_palette = 0 OR  ln_palette_over_flag = cn_efficiency_over ) THEN
                        IF ( ln_total_step > 0 ) THEN
                          -- ==============================================
                          -- 段単位の積み上げチェック
                          -- ==============================================
                          -- 変数初期化
                          ln_non_stack := ln_save_check_qty;
                          ln_palette_max_step_qty := gt_order_sort_wk_tbl(lv_index).palette_max_step_qty;
                          ln_load_efficiency_weight := 0;
                          ln_step_stack_flag := 0;
                          --
                          <<steps_check_loop>>
                          WHILE ( ln_total_step > 0 ) LOOP
                            -- 段単位で積上げ
                            -- チェック数量を設定
                            ln_check_qty := gt_order_sort_wk_tbl(lv_index).qty_step
                                            + ln_save_check_qty;
                            -- 今回チェックで積み増す本数
                            ln_now_check_qty := gt_order_sort_wk_tbl(lv_index).qty_step;
                            --
                            -- ==============================================
                            -- 合計重量・合計容積・合計パレット重量を取得
                            -- ==============================================
                            xxwsh_common910_pkg.calc_total_value(
                               iv_item_no            => gt_order_sort_wk_tbl(lv_index).item_code           -- 品目コード
                              ,in_quantity           => ln_check_qty                                       -- 数量
                              ,ov_retcode            => lv_retcode                                         -- リターンコード
                              ,ov_errmsg_code        => lv_errbuf                                          -- エラーメッセージコード
                              ,ov_errmsg             => lv_errmsg                                          -- エラーメッセージ
                              ,on_sum_weight         => ln_sum_weight                                      -- 合計重量
                              ,on_sum_capacity       => ln_sum_capacity                                    -- 合計容積
                              ,on_sum_pallet_weight  => gt_order_sort_wk_tbl(lv_index).sum_pallet_weight                               -- 合計パレット重量
                              ,id_standard_date      => gt_order_sort_wk_tbl(lv_index).schedule_ship_date  -- 基準日(適用日基準日)
                            );
                            -- リターンコードチェック
                            IF ( lv_retcode = cv_status_normal ) THEN
                              -- 正常の場合
                              IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
                                -- 小口区分が小口('1')以外の場合
                                -- 合計重量と合計パレット重量を合算
                                ln_sum_weight := ln_sum_weight
                                                 + gt_order_sort_wk_tbl(lv_index).sum_pallet_weight;
                              END IF;
                              --
                              IF ( ln_consolidation_flag = 1 ) THEN
                                ln_sum_weight := ln_sum_weight + ln_save_weight;
                              END IF;
                              --
                              -- ==============================================
                              -- 積載効率算出
                              -- ==============================================
                              xxwsh_common910_pkg.calc_load_efficiency(
                                 in_sum_weight                 =>  ln_sum_weight                                       -- 1.合計重量
                                ,in_sum_capacity               =>  NULL                                                -- 2.合計容積
                                ,iv_code_class1                =>  cv_warehouse_code                                   -- 3.コード区分１
                                ,iv_entering_despatching_code1 =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv             -- 4.入出庫場所コード１
                                ,iv_code_class2                =>  cv_delivery_code                          -- 5.コード区分２
                                ,iv_entering_despatching_code2 =>  gt_order_sort_wk_tbl(lv_index).province                               -- 6.入出庫場所コード２
                                ,iv_ship_method                =>  lv_max_ship_methods                                 -- 7.出荷方法
                                ,iv_prod_class                 =>  gt_order_sort_wk_tbl(lv_index).prod_class_code      -- 8.商品区分
                                ,iv_auto_process_type          =>  NULL                                  -- 9.自動配車対象区分
                                ,id_standard_date              =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date   -- 10.基準日(適用日基準日)
                                ,ov_retcode                    =>  lv_retcode                                          -- 11.リターンコード
                                ,ov_errmsg_code                =>  lv_errbuf                                           -- 12.エラーメッセージコード
                                ,ov_errmsg                     =>  lv_errmsg                                           -- 13.エラーメッセージ
                                ,ov_loading_over_class         =>  lv_loading_over_class                               -- 14.積載オーバー区分
                                ,ov_ship_methods               =>  lv_ship_methods                                     -- 15.出荷方法
                                ,on_load_efficiency_weight     =>  ln_load_efficiency_weight                           -- 16.重量積載効率
                                ,on_load_efficiency_capacity   =>  ln_load_efficiency_capacity                         -- 17.容積積載効率
                                ,ov_mixed_ship_method          =>  lv_mixed_ship_method                                -- 18.混載配送区分
                              );
                              -- リターンコードチェック
                              IF ( lv_retcode = cv_status_normal ) THEN
                                -- 正常の場合
                                IF ( ln_load_efficiency_weight <= 100 ) THEN
                                  ln_save_check_qty := ln_check_qty;
                                  ln_total_step := ln_total_step - 1;
                                  --
                                  ln_check_step := ln_check_step + 1;
                                ELSE
                                  -- 一段も積上げられない場合
                                  IF ( ln_save_check_qty = 0 ) THEN
                                    -- チェック数量を退避
                                    ln_save_check_qty := ln_non_stack;
                                  END IF;
                                  -- 積載効率が100%より大きい場合、明細単位の積上げ
                                  EXIT;
                                END IF; -- 段単位チェック:積載効率オーバー確認
                              ELSE
                                -- 段単位チェック:積載効率算出エラー
                                -- -- 積載効率算出エラーの場合
                                ov_retcode := cv_status_warn;
                                -- メッセージ作成
                                lv_output_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_xxcos_short_name             -- アプリケーション短縮名
                                  ,iv_name         => cv_calc_load_efficiency_err-- 積載効率算出エラー     -- メッセージ
                                  ,iv_token_name1  => cv_tkn_item_div_name            -- 商品区分コード
                                  ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
                                  ,iv_token_name2  => cv_tkn_sum_weight               -- 合計重量
                                  ,iv_token_value2 => TO_CHAR(ln_sum_weight)
                                  ,iv_token_name3  => cv_tkn_sum_capacity             -- 合計容積
                                  ,iv_token_value3 => ''
                                  ,iv_token_name4  => cv_tkn_whse_locat               -- 出荷元保管場所
                                  ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
                                  ,iv_token_name5  => cv_tkn_delivery_code            -- 配送先コード
                                  ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
                                  ,iv_token_name6  => cv_tkn_ship_method              -- 最大配送区分
                                  ,iv_token_value6 => lv_max_ship_methods
                                  ,iv_token_name7  => cv_tkn_schedule_ship_date       -- 出荷予定日
                                  ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                  ,iv_token_name8  => cv_tkn_err_msg                  -- エラーメッセージ
                                  ,iv_token_value8 => lv_errmsg
                                );
                                -- メッセージ出力
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => lv_output_msg
                                );
                                -- 空行出力
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => NULL
                                );
                                -- ループを抜ける
                                EXIT;
                              END IF;  -- 段単位チェック:calc_load_efficiency関数の結果確認
                            ELSE
                              -- 段単位チェック:合計重量・合計容積取得エラー
                              ov_retcode := cv_status_warn;
                              -- メッセージ作成
                              lv_output_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                                ,iv_name         => cv_calc_total_value_err              -- メッセージ
                                ,iv_token_name1  => cv_tkn_order_no             -- 受注番号
                                ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
                                ,iv_token_name2  => cv_tkn_item_code            -- 受注品目
                                ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
                                ,iv_token_name3  => cv_tkn_ordered_quantity     -- 受注数量
                                ,iv_token_value3 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).ordered_quantity)
                                ,iv_token_name4  => cv_tkn_schedule_ship_date   -- 出荷予定日
                                ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                ,iv_token_name5  => cv_tkn_err_msg              -- エラーメッセージ
                                ,iv_token_value5 => lv_errmsg
                              );
                              -- メッセージ出力
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => lv_output_msg
                              );
                              -- 空行出力
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => NULL
                              );
                              -- ループを抜ける
                              EXIT;
                            END IF;  -- 段単位チェック:calc_total_value関数の結果確認
                          END LOOP steps_check_loop;
                        END IF;  -- 段単位チェック:段数確認
                        --
                        IF ( ln_total_case > 0 ) THEN
                          -- ==============================================
                          -- 明細単位の積み上げチェック
                          -- ==============================================
                          -- 段積上げで積載効率が100%未満だった数量を設定
                          ln_check_qty := ln_save_check_qty;
                          ln_non_stack := ln_save_check_qty;
                          ln_save_check_qty := 0;
                          ln_case_qty := gt_order_sort_wk_tbl(lv_index).qty_case;
                          ln_load_efficiency_weight := 0;
                          <<line_check_loop>>
                          WHILE (( ln_load_efficiency_weight <= 100 )
                                   AND ( ln_total_case > 0 )) LOOP
                            ln_check_qty := gt_order_sort_wk_tbl(lv_index).qty_case + ln_check_qty + ln_save_check_qty;
                            -- 今回チェックで積み増す本数
                            ln_now_check_qty := gt_order_sort_wk_tbl(lv_index).qty_case;
                            --
                            -- ==============================================
                            -- 合計重量・合計容積・合計パレット重量を取得
                            -- ==============================================
                            xxwsh_common910_pkg.calc_total_value(
                               iv_item_no            => gt_order_sort_wk_tbl(lv_index).item_code           -- 品目コード
                              ,in_quantity           => ln_check_qty                                   -- 数量
                              ,ov_retcode            => lv_retcode                                         -- リターンコード
                              ,ov_errmsg_code        => lv_errbuf                                          -- エラーメッセージコード
                              ,ov_errmsg             => lv_errmsg                                          -- エラーメッセージ
                              ,on_sum_weight         => ln_sum_weight                                      -- 合計重量
                              ,on_sum_capacity       => ln_sum_capacity                                    -- 合計容積
                              ,on_sum_pallet_weight  => gt_order_sort_wk_tbl(lv_index).sum_pallet_weight                               -- 合計パレット重量
                              ,id_standard_date      => gt_order_sort_wk_tbl(lv_index).schedule_ship_date  -- 基準日(適用日基準日)
                            );
                            -- リターンコードチェック
                            IF ( lv_retcode = cv_status_normal ) THEN
                              -- 小口区分が小口以外の場合、合計重量に合計パレット重量を加算
                              IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
                                ln_sum_weight := ln_sum_weight + gt_order_sort_wk_tbl(lv_index).sum_pallet_weight;
                              END IF;
                              --
                              IF ( ln_consolidation_flag = 1 ) THEN
                                ln_sum_weight := ln_sum_weight + ln_save_weight;
                              END IF;
                              -- ==============================================
                              -- 積載効率算出
                              -- ==============================================
                              xxwsh_common910_pkg.calc_load_efficiency(
                                 in_sum_weight                 =>  ln_sum_weight                                       -- 1.合計重量
                                ,in_sum_capacity               =>  NULL                                                -- 2.合計容積
                                ,iv_code_class1                =>  cv_warehouse_code                                   -- 3.コード区分１
                                ,iv_entering_despatching_code1 =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv             -- 4.入出庫場所コード１
                                ,iv_code_class2                =>  cv_delivery_code                 -- 5.コード区分２
                                ,iv_entering_despatching_code2 =>  gt_order_sort_wk_tbl(lv_index).province                               -- 6.入出庫場所コード２
                                ,iv_ship_method                =>  lv_max_ship_methods                                 -- 7.出荷方法
                                ,iv_prod_class                 =>  gt_order_sort_wk_tbl(lv_index).prod_class_code      -- 8.商品区分
                                ,iv_auto_process_type          =>  NULL                                  -- 9.自動配車対象区分
                                ,id_standard_date              =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date   -- 10.基準日(適用日基準日)
                                ,ov_retcode                    =>  lv_retcode                                          -- 11.リターンコード
                                ,ov_errmsg_code                =>  lv_errbuf                                           -- 12.エラーメッセージコード
                                ,ov_errmsg                     =>  lv_errmsg                                           -- 13.エラーメッセージ
                                ,ov_loading_over_class         =>  lv_loading_over_class                               -- 14.積載オーバー区分
                                ,ov_ship_methods               =>  lv_ship_methods                                     -- 15.出荷方法
                                ,on_load_efficiency_weight     =>  ln_load_efficiency_weight                           -- 16.重量積載効率
                                ,on_load_efficiency_capacity   =>  ln_load_efficiency_capacity                         -- 17.容積積載効率
                                ,ov_mixed_ship_method          =>  lv_mixed_ship_method                                -- 18.混載配送区分
                              );
                              -- リターンコードチェック
                              IF ( lv_retcode = cv_status_normal ) THEN
                                IF ( ln_load_efficiency_weight <= 100 ) THEN
                                  ln_check_case := ln_check_case + 1;
                                  ln_total_case := ln_total_case - 1;
                                ELSE
                                  -- ループを抜ける
                                  EXIT;
                                END IF;
                              ELSE
                                -- ケース単位チェック:積載効率取得エラー
                                ov_retcode := cv_status_warn;
                                -- メッセージ作成
                                lv_output_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_xxcos_short_name             -- アプリケーション短縮名
                                  ,iv_name         => cv_calc_load_efficiency_err     -- メッセージ
                                  ,iv_token_name1  => cv_tkn_item_div_name            -- 商品区分コード
                                  ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
                                  ,iv_token_name2  => cv_tkn_sum_weight               -- 合計重量
                                  ,iv_token_value2 => TO_CHAR(ln_sum_weight)
                                  ,iv_token_name3  => cv_tkn_sum_capacity             -- 合計容積
                                  ,iv_token_value3 => ''
                                  ,iv_token_name4  => cv_tkn_whse_locat               -- 出荷元保管場所
                                  ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
                                  ,iv_token_name5  => cv_tkn_delivery_code            -- 配送先コード
                                  ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
                                  ,iv_token_name6  => cv_tkn_ship_method              -- 最大配送区分
                                  ,iv_token_value6 => lv_max_ship_methods
                                  ,iv_token_name7  => cv_tkn_schedule_ship_date       -- 出荷予定日
                                  ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                  ,iv_token_name8  => cv_tkn_err_msg                  -- エラーメッセージ
                                  ,iv_token_value8 => lv_errmsg
                                );
                                -- メッセージ出力
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => lv_output_msg
                                );
                                -- 空行出力
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => NULL
                                );
                                -- ループを抜ける
                                EXIT;
                              END IF;  -- ケース単位チェック:積載効率取得関数の結果確認
                            ELSE
                              -- ケース単位チェック:合計重量・容積取得エラー
                              ov_retcode := cv_status_warn;
                              -- メッセージ作成
                              lv_output_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                                ,iv_name         => cv_calc_total_value_err              -- メッセージ
                                ,iv_token_name1  => cv_tkn_order_no             -- 受注番号
                                ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
                                ,iv_token_name2  => cv_tkn_item_code            -- 受注品目
                                ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
                                ,iv_token_name3  => cv_tkn_ordered_quantity     -- 受注数量
                                ,iv_token_value3 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).ordered_quantity)
                                ,iv_token_name4  => cv_tkn_schedule_ship_date   -- 出荷予定日
                                ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                ,iv_token_name5  => cv_tkn_err_msg              -- エラーメッセージ
                                ,iv_token_value5 => lv_errmsg
                              );
                              -- メッセージ出力
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => lv_output_msg
                              );
                              -- 空行出力
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => NULL
                              );
                              -- ループを抜ける
                              EXIT;
                            END IF;  -- ケース単位チェック:合計重量・容積取得関数の結果確認
                          END LOOP line_check_loop;
                        END IF;  -- ケース単位チェック:ケース数確認
                        --
                        -- ========================================
                        -- 出荷依頼作成
                        -- ========================================
                        IF ( ln_consolidation_flag = 0 ) THEN
                          ln_delivery_unit := ln_delivery_unit + 1;
                        END IF;
                        ln_order_qty := 0;
                        lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                        <<deliv_palette_loop>>
                        WHILE  lv_index_wk IS NOT NULL LOOP
                         IF (( lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key )
                              AND
                             (     ( ln_check_palette > 0 AND gt_order_sort_wk_tbl(lv_index_wk).conv_palette > 0 )
                               OR  ( ln_check_step > 0    AND gt_order_sort_wk_tbl(lv_index_wk).conv_step > 0 )
                               OR  ( ln_check_case > 0    AND gt_order_sort_wk_tbl(lv_index_wk).conv_case > 0)))
                         THEN
                           IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_palette > 0 AND ln_check_palette > 0 ) THEN
                             IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_palette >= ln_check_palette ) THEN
                               ln_set := ln_check_palette;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_palette);
                               gt_order_sort_wk_tbl(lv_index_wk).conv_palette := gt_order_sort_wk_tbl(lv_index_wk).conv_palette - ln_check_palette;
                               ln_check_palette := 0;
                             ELSE
                               ln_set := gt_order_sort_wk_tbl(lv_index_wk).conv_palette;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_palette);
                               ln_check_palette := ln_check_palette - ln_set;
                               gt_order_sort_wk_tbl(lv_index_wk).conv_palette := 0;
                             END IF;
                           END IF;
                           --
                           IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_step > 0 AND ln_check_step > 0 ) THEN
                             IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_step >= ln_check_step ) THEN
                               ln_set := ln_check_step;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_step);
                               gt_order_sort_wk_tbl(lv_index_wk).conv_step := gt_order_sort_wk_tbl(lv_index_wk).conv_step - ln_check_step;
                               ln_check_step := 0;
                             ELSE
                               ln_set := gt_order_sort_wk_tbl(lv_index_wk).conv_step;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_step);
                               ln_check_step := ln_check_step - ln_set;
                               gt_order_sort_wk_tbl(lv_index_wk).conv_step := 0;
                             END IF;
                           END IF;
                           --
                           IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_case > 0 AND ln_check_case > 0 ) THEN
                             IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_case >= ln_check_case ) THEN
                               ln_set := ln_check_case;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_case);
                               gt_order_sort_wk_tbl(lv_index_wk).conv_case := gt_order_sort_wk_tbl(lv_index_wk).conv_case - ln_check_case;
                               ln_check_case := 0;
                             ELSE
                               ln_set := gt_order_sort_wk_tbl(lv_index_wk).conv_case;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_case);
                               ln_check_case := ln_check_case - ln_set;
                               gt_order_sort_wk_tbl(lv_index_wk).conv_case := 0;
                             END IF;
                           END IF;
                           gt_delivery_if_wk_tbl(gn_deliv_cnt) := gt_order_sort_wk_tbl(lv_index_wk);
                           gt_delivery_if_wk_tbl(gn_deliv_cnt).max_ship_methods := lv_max_ship_methods;
                           gt_delivery_if_wk_tbl(gn_deliv_cnt).delivery_unit := ln_delivery_unit;
                           gt_delivery_if_wk_tbl(gn_deliv_cnt).checked_quantity := ln_order_qty;
                           gn_deliv_cnt := gn_deliv_cnt + 1;
                           ln_order_qty := 0;
                         END IF;
                          lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                        END LOOP deliv_palette_loop;
                        --
                        -- 変数クリア
                        ln_check_palette := 0;
                        ln_check_step := 0;
                        ln_check_case := 0;
                        ln_save_check_qty := 0;
                        ln_palette_over_flag := cn_efficiency_non_over;
                        --
                        IF ( ln_load_efficiency_weight <= 100) THEN
                          ln_consolidation_flag := 1;
                          ln_save_weight := ln_sum_weight;
                        ELSE
                          ln_consolidation_flag := 0;
                        END IF;
                        IF ( ln_total_palette <= 0 AND ln_total_step <= 0 AND ln_total_case <= 0) THEN
                          ln_loop_flag := 0;
                        END IF;
                      END IF;
/* 2009/12/01 Ver1.18 DEL START */
--                    ELSE
--                      -- 積載効率算出エラーの場合
--                      ov_retcode := cv_status_warn;
--                      -- メッセージ作成
--                      lv_output_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_xxcos_short_name             -- アプリケーション短縮名
--                        ,iv_name         => cv_calc_load_efficiency_err     -- メッセージ
--                        ,iv_token_name1  => cv_tkn_item_div_name            -- 商品区分コード
--                        ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
--                        ,iv_token_name2  => cv_tkn_sum_weight               -- 合計重量
--                        ,iv_token_value2 => ln_sum_weight
--                        ,iv_token_name3  => cv_tkn_sum_capacity             -- 合計容積
--                        ,iv_token_value3 => ''
--                        ,iv_token_name4  => cv_tkn_whse_locat               -- 出荷元保管場所
--                        ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
--                        ,iv_token_name5  => cv_tkn_delivery_code            -- 配送先コード
--                        ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
--                        ,iv_token_name6  => cv_tkn_ship_method              -- 最大配送区分
--                        ,iv_token_value6 => lv_max_ship_methods
--                        ,iv_token_name7  => cv_tkn_schedule_ship_date       -- 出荷予定日
--                        ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
--                        ,iv_token_name8  => cv_tkn_err_msg                  -- エラーメッセージ
--                        ,iv_token_value8 => lv_errmsg
--                      );
--                      -- メッセージ出力
--                      fnd_file.put_line(
--                         which  => FND_FILE.OUTPUT
--                        ,buff   => lv_output_msg
--                      );
--                      -- 空行出力
--                      fnd_file.put_line(
--                         which  => FND_FILE.OUTPUT
--                        ,buff   => NULL
--                      );
--                      -- ループを抜ける
--                      EXIT;
--                    END IF;
--                  ELSE
--                    -- 合計重量・合計容積取得エラー
--                    ov_retcode := cv_status_warn;
--                    -- メッセージ作成
--                    lv_output_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
--                      ,iv_name         => cv_calc_total_value_err              -- メッセージ
--                      ,iv_token_name1  => cv_tkn_order_no             -- 受注番号
--                      ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
--                      ,iv_token_name2  => cv_tkn_item_code            -- 受注品目
--                      ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
--                      ,iv_token_name3  => cv_tkn_ordered_quantity     -- 受注数量
--                      ,iv_token_value3 => ln_check_qty
--                      ,iv_token_name4  => cv_tkn_schedule_ship_date   -- 出荷予定日
--                      ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
--                      ,iv_token_name5  => cv_tkn_err_msg              -- エラーメッセージ
--                      ,iv_token_value5 => lv_errmsg
--                    );
--                    -- メッセージ出力
--                    fnd_file.put_line(
--                       which  => FND_FILE.OUTPUT
--                      ,buff   => lv_output_msg
--                    );
--                    -- 空行出力
--                    fnd_file.put_line(
--                       which  => FND_FILE.OUTPUT
--                      ,buff   => NULL
--                    );
--                    -- ループを抜ける
--                    EXIT;
--                  END IF;
/* 2009/12/01 Ver1.18 DEL END */
                END LOOP pallet_check_loop;  -- パレット単位の積み上げチェック
              END IF;
            END IF;
          ELSE
            -- 積載効率算出エラー
            ov_retcode := cv_status_warn;
            lv_output_msg := xxccp_common_pkg.get_msg(
               iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
              ,iv_name         => cv_calc_load_efficiency_err     -- メッセージ
              ,iv_token_name1  => cv_tkn_item_div_name        -- 商品区分
              ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
              ,iv_token_name2  => cv_tkn_sum_weight           -- 合計重量
              ,iv_token_value2 => TO_CHAR(ln_sum_weight)
              ,iv_token_name3  => cv_tkn_sum_capacity         -- 合計容積
              ,iv_token_value3 => TO_CHAR(ln_sum_capacity)
              ,iv_token_name4  => cv_tkn_whse_locat           -- 出荷元保管場所
              ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
              ,iv_token_name5  => cv_tkn_delivery_code        -- 配送先
              ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
              ,iv_token_name6  => cv_tkn_ship_method          -- 出荷方法
              ,iv_token_value6 => lv_max_ship_methods
              ,iv_token_name7  => cv_tkn_schedule_ship_date   -- 出荷予定日
              ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
              ,iv_token_name8  => cv_tkn_err_msg              -- エラーメッセージ
              ,iv_token_value8 => lv_errmsg
            );
            --
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_output_msg
            );
            -- 空行出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => NULL
            );
          --
          END IF;
          --
        ELSE
          -- 最大配送区分取得エラー
          ov_retcode := cv_status_warn;
          lv_output_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_xxcos_short_name          -- アプリケーション短縮名
            ,iv_name         => cv_max_ship_method_err       -- メッセージ
            ,iv_token_name1  => cv_tkn_whse_locat            -- 出荷元保管場所
            ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
            ,iv_token_name2  => cv_tkn_delivery_code         -- 配送先
            ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).province
            ,iv_token_name3  => cv_tkn_item_div_name         -- 商品区分
            ,iv_token_value3 => gt_order_sort_wk_tbl(lv_index).prod_class_code
            ,iv_token_name4  => cv_tkn_schedule_ship_date    -- 出荷予定日
            ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
          );
          --
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_output_msg
          );
          -- 空行出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => NULL
          );
        END IF;
        --
        lv_pre_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        lv_pre_head_sort_key := gt_order_sort_wk_tbl(lv_index).head_sort_key;
        lv_index := gt_order_sort_wk_tbl.NEXT(lv_index);
        IF ( lv_index IS NOT NULL ) THEN
          lv_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        END IF;
      ELSE
        lv_pre_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        lv_pre_head_sort_key := gt_order_sort_wk_tbl(lv_index).head_sort_key;
        lv_index := gt_order_sort_wk_tbl.NEXT(lv_index);
        IF ( lv_index IS NOT NULL ) THEN
          lv_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        END IF;
      END IF;
      -- アウトパラメータのリターンコードチェック
      IF ( ov_retcode = cv_status_warn ) THEN
        -- 警告の場合、ループを抜ける
        EXIT;
      END IF;
    END LOOP check_loop;
    --
  --
  EXCEPTION
    WHEN small_amount_class_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_max_ship_methods
        ,iv_token_name1  => cv_tkn_max_ship_methods
        ,iv_token_value1 => lv_max_ship_methods
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END weight_check;
--
  /**********************************************************************************
   * Procedure Name   : order_line_division
   * Description      : 受注明細データ分割処理(A-15)
   ***********************************************************************************/
  PROCEDURE order_line_division(
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_line_division'; -- プログラム名
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
    cv_order_source         CONSTANT VARCHAR2(2) := '98';    -- 受注ソース参照の先頭文字
    cv_pad_char             CONSTANT VARCHAR2(1) := '0';     -- PAD関数で埋め込む文字
    cn_pad_num_char         CONSTANT NUMBER := 10;           -- PAD関数で埋め込む文字数
    --
    lv_sort_key             VARCHAR2(1000);       -- ソートキー
    ln_max_qty              NUMBER DEFAULT 0;     -- 最大基準数量用
    ln_comp_qty             NUMBER;               -- 比較対象数量
    ln_comp_end_qty         NUMBER;               -- 比較済数量
    ln_comp_flag            NUMBER DEFAULT 0;     -- 比較済数量設定済フラグ(0:未、1:済み)
    ln_upd_cnt              NUMBER DEFAULT 1;     -- 受注明細更新用PL/SQL表のインデックス
    ln_ins_cnt              NUMBER DEFAULT 1;     -- 受注明細登録用PL/SQL表のインデックス
    lv_idx                  VARCHAR2(1000);
    ln_header_id            NUMBER;
    ln_delivey_unit         NUMBER;
    ln_order_source_ref     NUMBER;
    lv_order_source         VARCHAR2(12);         -- 受注ソース
    lv_output_msg           VARCHAR2(1000);
    lv_item_code            VARCHAR2(30);
    ln_delivery_id          NUMBER;
    ln_qty                  NUMBER;
    --
    lt_order_line_tbl     g_n_order_data_ttype;
    TYPE l_tab_order_line IS TABLE OF BOOLEAN INDEX BY VARCHAR2(1000);
    lt_line_check_tbl     l_tab_order_line;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF ( gt_delivery_if_wk_tbl.COUNT > 0 ) THEN
      -- ======================================
      -- 出荷依頼用ヘッダーID
      -- ======================================
      SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
      INTO   ln_header_id
      FROM   dual;
      ln_delivey_unit := gt_delivery_if_wk_tbl(1).delivery_unit;
      --
      -- ======================================
      -- 出荷依頼No
      -- ======================================
      SELECT xxcos_order_source_ref_s01.NEXTVAL
      INTO   ln_order_source_ref
      FROM   dual;
      --
      lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
                                                 ,cn_pad_num_char
                                                 ,cv_pad_char);
      --
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        IF ( ln_delivey_unit <> gt_delivery_if_wk_tbl(ln_idx).delivery_unit ) THEN
          -- ======================================
          -- 出荷依頼用ヘッダーID
          -- ======================================
          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
          INTO   ln_header_id
          FROM   dual;
          --
          -- ======================================
          -- 出荷依頼No
          -- ======================================
          SELECT xxcos_order_source_ref_s01.NEXTVAL
          INTO   ln_order_source_ref
          FROM   dual;
          --
          lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
                                                     ,cn_pad_num_char
                                                     ,cv_pad_char);
          ln_delivey_unit := gt_delivery_if_wk_tbl(ln_idx).delivery_unit;
        END IF;
        --
        gt_delivery_if_wk_tbl(ln_idx).req_header_id := ln_header_id;
        gt_delivery_if_wk_tbl(ln_idx).order_source := lv_order_source;
        --
      END LOOP line_loop;
      --
      -- ======================================
      -- 受注明細分割データ作成
      -- ======================================
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        IF ( lt_order_line_tbl.EXISTS(TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).line_id )) = FALSE ) THEN
          -- 存在しない場合
          -- チェック用テーブルに設定
          lt_order_line_tbl(TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).line_id )) := gt_delivery_if_wk_tbl(ln_idx);
          -- 受注明細更新PL/SQL表に退避
          gt_order_upd_tbl(ln_upd_cnt) := gt_delivery_if_wk_tbl(ln_idx);
          ln_upd_cnt := ln_upd_cnt + 1;
        ELSE
          -- 存在した場合(分割の場合)
          -- 受注明細登録PL/SQL表に退避
          gt_order_ins_tbl(ln_ins_cnt) := gt_delivery_if_wk_tbl(ln_idx);
          ln_ins_cnt := ln_ins_cnt + 1;
        END IF;
      END LOOP line_loop;
      --
      gt_order_sort_tbl.DELETE;
      lv_item_code     := gt_delivery_if_wk_tbl(1).item_code;
      ln_delivery_id   := gt_delivery_if_wk_tbl(1).req_header_id;
      ln_qty := 0;
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        lv_sort_key :=
            TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).req_header_id)
            || TO_CHAR( gt_delivery_if_wk_tbl(ln_idx).ordered_date , cv_date_fmt_no_sep )             -- 受注日
            || gt_delivery_if_wk_tbl(ln_idx).province                                                 -- 配送先コード
            || NVL( gt_delivery_if_wk_tbl(ln_idx).shipping_instructions ,cv_blank )                   -- 出荷指示
            || NVL( gt_delivery_if_wk_tbl(ln_idx).cust_po_number, cv_blank )                          -- 顧客発注番号
/* 2009/10/19 Ver.1.13 Add Start */
            || gt_delivery_if_wk_tbl(ln_idx).base_code                                                -- 管轄拠点(売上拠点)
/* 2009/10/19 Ver.1.13 Add End */
            || gt_delivery_if_wk_tbl(ln_idx).delivery_base_code                                       -- 入力拠点
            || gt_delivery_if_wk_tbl(ln_idx).ship_to_subinv                                           -- 出荷元保管場所
            || TO_CHAR( gt_delivery_if_wk_tbl(ln_idx).schedule_ship_date , cv_date_fmt_no_sep )       -- 出荷予定日
            || TO_CHAR( gt_delivery_if_wk_tbl(ln_idx).request_date , cv_date_fmt_no_sep )             -- 納品予定日
            || NVL( gt_delivery_if_wk_tbl(ln_idx).time_from , cv_blank )                              -- 時間指定From
            || NVL( gt_delivery_if_wk_tbl(ln_idx).time_to , cv_blank )                                -- 時間指定To
            || gt_delivery_if_wk_tbl(ln_idx).prod_class_code                                          -- 商品区分
            || gt_delivery_if_wk_tbl(ln_idx).item_code;                                               -- 品目コード
        IF ( gt_order_sort_tbl.EXISTS(lv_sort_key) = TRUE ) THEN
          -- 存在している場合
          gt_order_sort_tbl(lv_sort_key).checked_quantity :=
               gt_order_sort_tbl(lv_sort_key).checked_quantity + gt_delivery_if_wk_tbl(ln_idx).checked_quantity;
        ELSE
          -- 存在していない場合
          gt_order_sort_tbl(lv_sort_key) := gt_delivery_if_wk_tbl(ln_idx);
        END IF;
      END LOOP line_loop;
      --
      -- ======================================
      -- 積載効率オーバーチェック
      -- ======================================
      ln_delivey_unit := -1;
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        IF (( ln_delivey_unit <> gt_delivery_if_wk_tbl(ln_idx).delivery_unit )
              AND ( gt_delivery_if_wk_tbl(ln_idx).efficiency_over_flag = 1  )) THEN
          -- ===============================
          -- 積載効率オーバメッセージ出力
          -- ===============================
          lv_output_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_xxcos_short_name           -- アプリケーション短縮名
            ,iv_name         => cv_leaf_capacity_over_err     -- メッセージ
            ,iv_token_name1  => cv_tkn_order_source           -- 出荷依頼NO
            ,iv_token_value1 => gt_delivery_if_wk_tbl(ln_idx).order_source
            ,iv_token_name2  => cv_tkn_whse_locat             -- 出荷元保管場所
            ,iv_token_value2 => gt_delivery_if_wk_tbl(ln_idx).ship_to_subinv
            ,iv_token_name3  => cv_tkn_delivery_code          -- 配送先
            ,iv_token_value3 => gt_delivery_if_wk_tbl(ln_idx).province
            ,iv_token_name4  => cv_tkn_ship_method            -- 出荷方法
            ,iv_token_value4 => gt_delivery_if_wk_tbl(ln_idx).max_ship_methods
            ,iv_token_name5  => cv_tkn_schedule_ship_date     -- 出荷予定日
            ,iv_token_value5 => TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).schedule_ship_date, cv_date_fmt_date_time)
          );
          --
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_output_msg
          );
          -- 空行出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => NULL
          );
          ln_delivey_unit := gt_delivery_if_wk_tbl(ln_idx).delivery_unit;
        END IF;
      END LOOP line_loop;
    END IF;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END order_line_division;
--
  /**********************************************************************************
   * Procedure Name   : order_line_insert
   * Description      : 受注明細登録(A-16)
   ***********************************************************************************/
  PROCEDURE order_line_insert(
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_line_insert'; -- プログラム名
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
    cn_index                   CONSTANT NUMBER := 1;    -- インデックス
    cn_version                 CONSTANT NUMBER := 1.0;  -- APIのバージョン
    cv_calculate_price_flag_n  CONSTANT VARCHAR2(1) := 'N';
    --
    lv_key_info                VARCHAR2(1000);          -- キー情報
    lv_output_msg              VARCHAR2(1000);          -- 出力メッセージ
    lv_table_name              VARCHAR2(100);           -- テーブル名
    lv_order_number            VARCHAR2(100);           -- 受注番号
    lv_item_name               VARCHAR2(100);           -- 品目
    lv_quantity                VARCHAR2(100);           -- 数量
    lv_return_status           VARCHAR2(2);
    lv_msg_data                VARCHAR2(2000);
    ln_cnt                     NUMBER DEFAULT 1;        -- 登録件数用
    ln_max_number              NUMBER;                  -- 最大明細番号用
    ln_after_max_number        NUMBER;
    ln_msg_count               NUMBER;
    --
    -- 受注明細登録API用
    lt_header_rec              OE_ORDER_PUB.Header_Rec_Type;
    lt_header_val_rec          OE_ORDER_PUB.Header_Val_Rec_Type;
    lt_header_adj_tbl          OE_ORDER_PUB.Header_Adj_Tbl_Type;
    lt_header_adj_val_tbl      OE_ORDER_PUB.Header_Adj_Val_Tbl_Type;
    lt_header_price_att_tbl    OE_ORDER_PUB.Header_Price_Att_Tbl_Type;
    lt_header_adj_att_tbl      OE_ORDER_PUB.Header_Adj_Att_Tbl_Type;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.Header_Adj_Assoc_Tbl_Type;
    lt_header_scredit_tbl      OE_ORDER_PUB.Header_Scredit_Tbl_Type;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.Header_Scredit_Val_Tbl_Type;
    lt_line_tbl                OE_ORDER_PUB.Line_Tbl_Type;
    lt_line_val_tbl            OE_ORDER_PUB.Line_Val_Tbl_Type;
    lt_line_adj_tbl            OE_ORDER_PUB.Line_Adj_Tbl_Type;
    lt_line_adj_val_tbl        OE_ORDER_PUB.Line_Adj_Val_Tbl_Type;
    lt_line_price_att_tbl      OE_ORDER_PUB.Line_Price_Att_Tbl_Type;
    lt_line_adj_att_tbl        OE_ORDER_PUB.Line_Adj_Att_Tbl_Type;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.Line_Adj_Assoc_Tbl_Type;
    lt_line_scredit_tbl        OE_ORDER_PUB.Line_Scredit_Tbl_Type;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.Line_Scredit_Val_Tbl_Type;
    lt_lot_serial_tbl          OE_ORDER_PUB.Lot_Serial_Tbl_Type;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.Lot_Serial_Val_Tbl_Type;
    lt_action_request_tbl      OE_ORDER_PUB.Request_Tbl_Type;
    --
    TYPE g_tab_line_number IS TABLE OF oe_order_lines_all.line_number%TYPE INDEX BY VARCHAR2(100);
    gt_line_number_tbl             g_tab_line_number;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
/* 2009/12/07 Ver1.19 Del Start */
--    -- OMメッセージリストの初期化
--    OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 Del End */
    --
    -- 変数初期化
    ln_msg_count := 0;
    -- ===============================
    -- 明細登録
    -- ===============================
    <<line_ins_loop>>
    FOR ln_idx IN 1..gt_order_ins_tbl.COUNT LOOP
      SELECT  MAX(oola.line_number) + 1
      INTO    ln_max_number
      FROM    oe_order_lines_all  oola
      WHERE   oola.header_id   = gt_order_ins_tbl(ln_idx).header_id
      GROUP BY oola.header_id;
/* 2009/12/07 Ver1.19 Add Start */
      SELECT msib.inventory_item_id
      INTO   gt_order_ins_tbl(ln_idx).inventory_item_id
      FROM   mtl_system_items_b  msib
      WHERE  msib.segment1          = gt_order_ins_tbl(ln_idx).parent_item_code
      AND    msib.organization_id   = gn_organization_id;
      --
      -- OMメッセージリストの初期化
      OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 End Start */
      --
      lt_line_tbl(cn_index)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(cn_index).operation              := OE_GLOBALS.G_OPR_CREATE;                        -- 処理モード
      lt_line_tbl(cn_index).header_id              := gt_order_ins_tbl(ln_idx).header_id;             -- ヘッダID
      lt_line_tbl(cn_index).ship_to_org_id         := gt_order_ins_tbl(ln_idx).ship_to_org_id;        -- 組織ID
      lt_line_tbl(cn_index).line_number            := ln_max_number;                                  -- 明細番号
      lt_line_tbl(cn_index).inventory_item_id      := gt_order_ins_tbl(ln_idx).inventory_item_id;     -- 品目ID
      lt_line_tbl(cn_index).packing_instructions   := gt_order_ins_tbl(ln_idx).order_source;          -- 梱包指示
      lt_line_tbl(cn_index).line_type_id           := gt_order_ins_tbl(ln_idx).line_type_id;          -- 明細タイプ
      lt_line_tbl(cn_index).request_date           := gt_order_ins_tbl(ln_idx).original_request_date; -- 納品予定日
      lt_line_tbl(cn_index).unit_selling_price     := gt_order_ins_tbl(ln_idx).unit_selling_price;    -- 販売単価
      lt_line_tbl(cn_index).calculate_price_flag   := cv_calculate_price_flag_n;                      -- 価格の計算フラグ
      lt_line_tbl(cn_index).schedule_ship_date     := gt_order_ins_tbl(ln_idx).original_schedule_ship_date;  -- 出荷予定日
      lt_line_tbl(cn_index).subinventory           := gt_order_ins_tbl(ln_idx).subinventory;                 -- 保管場所
      lt_line_tbl(cn_index).attribute1             := gt_order_ins_tbl(ln_idx).attribute1;
      lt_line_tbl(cn_index).attribute2             := gt_order_ins_tbl(ln_idx).attribute2;
      lt_line_tbl(cn_index).attribute3             := gt_order_ins_tbl(ln_idx).attribute3;
      lt_line_tbl(cn_index).attribute4             := gt_order_ins_tbl(ln_idx).attribute4;
      lt_line_tbl(cn_index).attribute5             := gt_order_ins_tbl(ln_idx).attribute5;
      lt_line_tbl(cn_index).attribute6             := gt_order_ins_tbl(ln_idx).attribute6;
      lt_line_tbl(cn_index).attribute7             := gt_order_ins_tbl(ln_idx).attribute7;
      lt_line_tbl(cn_index).attribute8             := gt_order_ins_tbl(ln_idx).attribute8;
      lt_line_tbl(cn_index).attribute9             := gt_order_ins_tbl(ln_idx).attribute9;
      lt_line_tbl(cn_index).attribute10            := gt_order_ins_tbl(ln_idx).attribute10;
      lt_line_tbl(cn_index).attribute11            := gt_order_ins_tbl(ln_idx).attribute11;
      lt_line_tbl(cn_index).attribute12            := gt_order_ins_tbl(ln_idx).attribute12;
      lt_line_tbl(cn_index).attribute13            := gt_order_ins_tbl(ln_idx).attribute13;
      lt_line_tbl(cn_index).attribute14            := gt_order_ins_tbl(ln_idx).attribute14;
      lt_line_tbl(cn_index).attribute15            := gt_order_ins_tbl(ln_idx).attribute15;
      lt_line_tbl(cn_index).attribute16            := gt_order_ins_tbl(ln_idx).attribute16;
      lt_line_tbl(cn_index).attribute17            := gt_order_ins_tbl(ln_idx).attribute17;
      lt_line_tbl(cn_index).attribute18            := gt_order_ins_tbl(ln_idx).attribute18;
      lt_line_tbl(cn_index).attribute19            := gt_order_ins_tbl(ln_idx).attribute19;
      lt_line_tbl(cn_index).attribute20            := gt_order_ins_tbl(ln_idx).attribute20;
      lt_line_tbl(cn_index).global_attribute1      := gt_order_ins_tbl(ln_idx).global_attribute1;
      lt_line_tbl(cn_index).global_attribute2      := gt_order_ins_tbl(ln_idx).global_attribute2;
      lt_line_tbl(cn_index).global_attribute3      := TO_CHAR(gt_order_ins_tbl(ln_idx).line_id);            -- 分割元受注明細ID
      lt_line_tbl(cn_index).global_attribute4      := gt_order_ins_tbl(ln_idx).orig_sys_line_ref;           -- 分割元受注明細番号
      lt_line_tbl(cn_index).global_attribute5      := gt_order_ins_tbl(ln_idx).global_attribute5;
      lt_line_tbl(cn_index).global_attribute6      := gt_order_ins_tbl(ln_idx).global_attribute6;
      lt_line_tbl(cn_index).global_attribute7      := gt_order_ins_tbl(ln_idx).global_attribute7;
      lt_line_tbl(cn_index).global_attribute8      := gt_order_ins_tbl(ln_idx).global_attribute8;
      lt_line_tbl(cn_index).global_attribute9      := gt_order_ins_tbl(ln_idx).global_attribute9;
      lt_line_tbl(cn_index).global_attribute10     := gt_order_ins_tbl(ln_idx).global_attribute10;
      lt_line_tbl(cn_index).global_attribute11     := gt_order_ins_tbl(ln_idx).global_attribute11;
      lt_line_tbl(cn_index).global_attribute12     := gt_order_ins_tbl(ln_idx).global_attribute12;
      lt_line_tbl(cn_index).global_attribute13     := gt_order_ins_tbl(ln_idx).global_attribute13;
      lt_line_tbl(cn_index).global_attribute14     := gt_order_ins_tbl(ln_idx).global_attribute14;
      lt_line_tbl(cn_index).global_attribute15     := gt_order_ins_tbl(ln_idx).global_attribute15;
      lt_line_tbl(cn_index).global_attribute16     := gt_order_ins_tbl(ln_idx).global_attribute16;
      lt_line_tbl(cn_index).global_attribute17     := gt_order_ins_tbl(ln_idx).global_attribute17;
      lt_line_tbl(cn_index).global_attribute18     := gt_order_ins_tbl(ln_idx).global_attribute18;
      lt_line_tbl(cn_index).global_attribute19     := gt_order_ins_tbl(ln_idx).global_attribute19;
      lt_line_tbl(cn_index).global_attribute20     := gt_order_ins_tbl(ln_idx).global_attribute20;
      lt_line_tbl(cn_index).org_id                 := gt_org_id;                                         -- 営業単位
      lt_line_tbl(cn_index).request_id             := cn_request_id;                                     -- 要求ID
      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;                         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      lt_line_tbl(cn_index).program_id             := cn_program_id;                                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      lt_line_tbl(cn_index).program_update_date    := cd_program_update_date;                            -- プログラム更新日
/* 2009/12/07 Ver1.19 Add Start */
      lt_line_tbl(cn_index).context                := gt_order_ins_tbl(ln_idx).line_context;
/* 2009/12/07 Ver1.19 Add Start */
      --
      -- 数量の設定
      IF ( gt_order_ins_tbl(ln_idx).order_quantity_uom = gt_order_ins_tbl(ln_idx).conv_order_quantity_uom ) THEN
        -- 受注画面の入力単位が基準単位の場合
        lt_line_tbl(cn_index).ordered_quantity := gt_order_ins_tbl(ln_idx).checked_quantity;
        lt_line_tbl(cn_index).order_quantity_uom := gt_order_ins_tbl(ln_idx).order_quantity_uom;
      ELSE
        -- 受注画面の入力単位がCSの場合
        lt_line_tbl(cn_index).ordered_quantity := gt_order_ins_tbl(ln_idx).checked_quantity / gt_order_ins_tbl(ln_idx).qty_case;
        lt_line_tbl(cn_index).order_quantity_uom := gt_order_ins_tbl(ln_idx).order_quantity_uom;
      END IF;
      --
      --================================================================--
      -- Process Order API
      --================================================================--
      OE_ORDER_PUB.PROCESS_ORDER(
         -- IN Variables
         p_api_version_number      => cn_version
        ,p_line_tbl                => lt_line_tbl
         -- OUT Variables
        ,x_header_rec              => lt_header_rec
        ,x_header_val_rec          => lt_header_val_rec
        ,x_header_adj_tbl          => lt_header_adj_tbl
        ,x_header_adj_val_tbl      => lt_header_adj_val_tbl
        ,x_header_price_att_tbl    => lt_header_price_att_tbl
        ,x_header_adj_att_tbl      => lt_header_adj_att_tbl
        ,x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
        ,x_header_scredit_tbl      => lt_header_scredit_tbl
        ,x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
        ,x_line_tbl                => lt_line_tbl
        ,x_line_val_tbl            => lt_line_val_tbl
        ,x_line_adj_tbl            => lt_line_adj_tbl
        ,x_line_adj_val_tbl        => lt_line_adj_val_tbl
        ,x_line_price_att_tbl      => lt_line_price_att_tbl
        ,x_line_adj_att_tbl        => lt_line_adj_att_tbl
        ,x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
        ,x_line_scredit_tbl        => lt_line_scredit_tbl
        ,x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
        ,x_lot_serial_tbl          => lt_lot_serial_tbl
        ,x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
        ,x_action_request_tbl      => lt_action_request_tbl
        ,x_return_status           => lv_return_status
        ,x_msg_count               => ln_msg_count
        ,x_msg_data                => lv_msg_data
      );
      --
      SELECT  MAX(oola.line_number)
      INTO    ln_after_max_number
      FROM    oe_order_lines_all  oola
      WHERE   oola.header_id   = gt_order_ins_tbl(ln_idx).header_id
      GROUP BY oola.header_id;
      --
      -- API実行結果確認
      IF (( lv_return_status <> FND_API.G_RET_STS_SUCCESS )
            OR ( ln_after_max_number <> ln_max_number )) THEN
        -- 明細登録エラー
        IF ln_msg_count > 0 THEN
          FOR l_index IN 1..ln_msg_count LOOP
            lv_msg_data := oe_msg_pub.get(p_msg_index => l_index, p_encoded =>'F');
          END LOOP;
          lv_errbuf := substrb( lv_msg_data,1,250);
        END IF;
        -- メッセージ文字列取得(受注番号)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_order_number             -- メッセージID
        );
        -- メッセージ文字列取得(品目)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_item_name                -- メッセージID
        );
        -- メッセージ文字列取得(数量)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_quantity                 -- メッセージID
        );
        -- メッセージ文字列取得(受注明細)
        lv_table_name := xxccp_common_pkg.get_msg(
               iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
              ,iv_name        => cv_msg_line_number              -- メッセージID
        );
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- 受注番号
         ,iv_data_value1    => gt_order_ins_tbl(ln_idx).order_number
         ,iv_item_name2     => lv_item_name                     -- 品目
         ,iv_data_value2    => gt_order_ins_tbl(ln_idx).item_code
         ,iv_item_name3     => lv_quantity                      -- 数量
         ,iv_data_value3    => TO_CHAR(lt_line_tbl(ln_cnt).ordered_quantity)
         ,ov_key_info       => lv_key_info                      -- 編集後キー情報
         ,ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
         ,ov_retcode        => lv_retcode                       -- リターンコード
         ,ov_errmsg         => lv_errmsg                        -- ユーザ・エラー・メッセージ
        );
        -- メッセージ文字列作成
        lv_output_msg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name     -- アプリケーション短縮名
          ,iv_name         => cv_line_insert_err      -- メッセージ
          ,iv_token_name1  => cv_tkn_table_name       -- テーブル名
          ,iv_token_value1 => lv_table_name
          ,iv_token_name2  => cv_tkn_key_data         -- キー情報
          ,iv_token_value2 => lv_key_info
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_msg
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        RAISE global_api_expt;
      END IF;
      --
      --
    END LOOP line_ins_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END order_line_insert;
--
  /**********************************************************************************
   * Procedure Name   : get_delivery
   * Description      : 配送先取得(A-17)
   ***********************************************************************************/
  PROCEDURE get_delivery(
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery'; -- プログラム名
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
    cv_site_ship                   CONSTANT VARCHAR2(10) := 'SHIP_TO';                    -- 使用目的:出荷先
    cv_status_effective            CONSTANT VARCHAR2(1)  := 'A';                          -- ステイタス:有効
    cv_tkn_order_no                CONSTANT VARCHAR2(30) := 'ORDER_NO';                   -- 受注番号
    cv_tkn_account_number          CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';             -- 顧客コード
    cv_tkn_rsv_sale_base_code      CONSTANT VARCHAR2(30) := 'RSV_SALE_BASE_CODE';         -- 予約売上拠点
    cv_tkn_delivery_base_code      CONSTANT VARCHAR2(30) := 'DELIVERY_BASE_CODE';         -- 納品拠点
    cv_tkn_rsv_sale_base_act_date  CONSTANT VARCHAR2(30) := 'RSV_SALE_BASE_ACT_DATE';     -- 予約売上拠点適用開始日
    cv_tkn_base_code               CONSTANT VARCHAR2(20) := 'BASE_CODE';                  -- 拠点
    cv_tkn_request_date            CONSTANT VARCHAR2(20) := 'REQUEST_DATE';               -- 納品予定日
    lv_output_msg                  VARCHAR2(1000);                                        -- 出力メッセージ用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<delivery_loop>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
--
-- ******************* 2009/11/24 1.16 N.Maeda MOD START ******************* --
      -- ===============================
      -- 出荷指示の改行コード削除
      -- ===============================
      gt_order_extra_tbl(ln_idx).shipping_instructions := TRANSLATE( gt_order_extra_tbl(ln_idx).shipping_instructions
                                                                     ,CHR(10)
                                                                     ,' '
                                                                   );
-- ******************* 2009/11/24 1.16 N.Maeda MOD  END  ******************* --
      -- ===============================
      -- 対象拠点コード取得
      -- ===============================
      IF (    gt_order_extra_tbl(ln_idx).rsv_sale_base_code IS NULL        -- 予約売上拠点コード
           OR gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date IS NULL    -- 予約売上拠点有効開始日
           OR gt_order_extra_tbl(ln_idx).request_date < gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date ) THEN
        -- 納品拠点の場合
/* 2009/10/19 Ver.1.13 Mod Start */
        gt_order_extra_tbl(ln_idx).base_code := gt_order_extra_tbl(ln_idx).sale_base_code;
--        gt_order_extra_tbl(ln_idx).base_code := gt_order_extra_tbl(ln_idx).delivery_base_code;
/* 2009/10/19 Ver.1.13 Mod End */
        --
      ELSIF ( gt_order_extra_tbl(ln_idx).request_date >= gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date ) THEN
        -- 予約売上拠点の場合
        gt_order_extra_tbl(ln_idx).base_code := gt_order_extra_tbl(ln_idx).rsv_sale_base_code;
        --
      ELSE
        -- 拠点取得エラー
        -- メッセージ作成
        lv_output_msg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name                  -- アプリケーション短縮名
          ,iv_name         => cv_base_code_err                     -- メッセージ
          ,iv_token_name1  => cv_tkn_order_no                      -- 受注番号
          ,iv_token_value1 => gt_order_extra_tbl(ln_idx).order_number
          ,iv_token_name2  => cv_tkn_account_number                -- 顧客コード
          ,iv_token_value2 => gt_order_extra_tbl(ln_idx).account_number
          ,iv_token_name3  => cv_tkn_rsv_sale_base_code            -- 予約売上拠点
          ,iv_token_value3 => gt_order_extra_tbl(ln_idx).rsv_sale_base_code
          ,iv_token_name4  => cv_tkn_delivery_base_code            -- 納品拠点
          ,iv_token_value4 => gt_order_extra_tbl(ln_idx).base_code
          ,iv_token_name5  => cv_tkn_rsv_sale_base_act_date        -- 予約売上拠点適用開始日
          ,iv_token_value5 => TO_CHAR(gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date, cv_date_fmt_date_time)
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_msg
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ===============================
      -- 配送先コード取得
      -- ===============================
      BEGIN
        SELECT  hl.province                          -- 配送先コード
        INTO    gt_order_extra_tbl(ln_idx).province
        FROM   hz_cust_accounts         hca          -- 顧客マスタ
               ,hz_party_sites          hps          -- パーティサイトマスタ
               ,hz_cust_acct_sites_all  hcasa        -- 顧客所在地
               ,hz_locations            hl           -- 顧客事業所マスタ
               ,hz_cust_site_uses_all   hcsua        -- 顧客使用目的
               ,xxcmn_party_sites       xps          -- パーティサイトアドオンマスタ
        WHERE  hca.account_number       =  gt_order_extra_tbl(ln_idx).account_number
        AND    hca.cust_account_id      =  hcasa.cust_account_id
        AND    hcasa.cust_acct_site_id  =  hcsua.cust_acct_site_id
        AND    hcsua.org_id             =  gn_prod_ou_id
        AND    hcasa.status             =  cv_status_effective
        AND    hcsua.org_id             =  gn_prod_ou_id
        AND    hcsua.site_use_code      =  cv_site_ship
        AND    hcasa.party_site_id      =  hps.party_site_id
        AND    hps.status               =  cv_status_effective
        AND    hps.location_id        =  hl.location_id
        AND    hps.party_id             =  xps.party_id
        AND    hps.party_site_id        =  xps.party_site_id
        AND    hps.location_id          =  xps.location_id
        AND    xps.base_code            =  gt_order_extra_tbl(ln_idx).base_code
        AND    xps.start_date_active    <= gt_order_extra_tbl(ln_idx).request_date
        AND    xps.end_date_active      >= gt_order_extra_tbl(ln_idx).request_date;
      EXCEPTION
        WHEN OTHERS THEN
          -- 配送先取得エラー
        -- メッセージ作成
        lv_output_msg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name            -- アプリケーション短縮名
          ,iv_name         => cv_delivery_code_err           -- メッセージ
          ,iv_token_name1  => cv_tkn_order_no                -- 受注番号
          ,iv_token_value1 => gt_order_extra_tbl(ln_idx).order_number
          ,iv_token_name2  => cv_tkn_account_number          -- 顧客コード
          ,iv_token_value2 => gt_order_extra_tbl(ln_idx).account_number
          ,iv_token_name3  => cv_tkn_base_code               -- 拠点
          ,iv_token_value3 => gt_order_extra_tbl(ln_idx).base_code
          ,iv_token_name4  => cv_tkn_request_date            -- 納品予定日
          ,iv_token_value4 => TO_CHAR(gt_order_extra_tbl(ln_idx).request_date, cv_date_fmt_date_time)
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_msg
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        --
        ov_retcode := cv_status_warn;
        --
      END;
    END LOOP delivery_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_delivery;
--
/* 2009/09/16 Ver.1.12 Add End */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code     IN  VARCHAR2,     -- 1.拠点コード
--    iv_order_number  IN  VARCHAR2,     -- 2.受注番号
    iv_send_flg      IN  VARCHAR2,         -- 1.新規/再送区分
    iv_base_code     IN  VARCHAR2,         -- 2.拠点コード
    iv_order_number  IN  VARCHAR2,         -- 3.受注番号
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END ******************************--
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_retcode_a3           VARCHAR2(1);    -- A-3のリターンコード格納
    lv_retcode_a5           VARCHAR2(1);    -- A-5のリターンコード格納
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    lv_retcode_a12          VARCHAR2(1);    -- A-12のリターンコード格納
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
--
    -- *** ローカル例外 ***
    no_data_found_expt      EXCEPTION;      -- 抽出データ無し
/* 2009/09/16 Ver.1.12 Add Start */
    process_warn_expt         EXCEPTION;
/* 2009/09/16 Ver.1.12 Add End */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt        := 0;
    gn_header_normal_cnt := 0;
    gn_line_normal_cnt   := 0;
    gn_error_cnt         := 0;
    gn_warn_cnt          := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--       iv_base_code     => iv_base_code        -- 拠点コード
--      ,iv_order_number  => iv_order_number     -- 受注番号
       iv_send_flg      => iv_send_flg         -- 新規/再送区分
      ,iv_base_code     => iv_base_code        -- 拠点コード
      ,iv_order_number  => iv_order_number     -- 受注番号
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END ******************************--
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ
      ,ov_retcode       => lv_retcode          -- リターン・コード
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 受注データ取得(A-2)
    -- ===============================
    get_order_data(
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--       iv_base_code     => iv_base_code        -- 拠点コード
--      ,iv_order_number  => iv_order_number     -- 受注番号
       iv_send_flg      => iv_send_flg         -- 新規/再送区分
      ,iv_base_code     => iv_base_code        -- 拠点コード
      ,iv_order_number  => iv_order_number     -- 受注番号
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END ******************************--
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ
      ,ov_retcode       => lv_retcode          -- リターン・コード
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE no_data_found_expt;
    END IF;
--
    lv_retcode_a3 := cv_status_normal;
    lv_retcode_a5 := cv_status_normal;
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    lv_retcode_a12 := cv_status_normal;
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
    --
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    -- 配送先取得(A-17)
    -- ===============================
    get_delivery(
       ov_errbuf      => lv_errbuf             -- エラー・メッセージ
      ,ov_retcode     => lv_retcode            -- リターン・コード
      ,ov_errmsg      => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    -- リターンコードチェック
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE process_warn_expt;
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
    <<make_ship_data>>
    FOR ln_idx IN gt_order_extra_tbl.FIRST..gt_order_extra_tbl.LAST LOOP
/* 2009/09/16 Ver.1.12 Add Start */
      -- 初期化
      lv_retcode_a3 := NULL;
/* 2009/09/16 Ver.1.12 Add End */
      -- ===============================
      -- 出荷元保管場所取得(A-3)
      -- ===============================
      get_ship_subinventory(
         it_order_rec          => gt_order_extra_tbl(ln_idx)                 -- 受注データ
        ,ov_ship_subinventory  => gt_order_extra_tbl(ln_idx).ship_to_subinv  -- 出荷元保管場所
        ,ov_errbuf             => lv_errbuf                                  -- エラー・メッセージ
        ,ov_retcode            => lv_retcode                                 -- リターン・コード
        ,ov_errmsg             => lv_errmsg                                  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a3 := cv_status_warn;
/* 2009/09/16 Ver.1.12 Add Start */
        lv_retcode_a5 := cv_status_warn;
/* 2009/09/16 Ver.1.12 Add End */
      END IF;
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 出荷予定日取得(A-4)
      -- ===============================
      IF ( lv_retcode = cv_status_normal ) THEN
        get_ship_schedule_date(
           it_order_rec   => gt_order_extra_tbl(ln_idx)                       -- 受注データ
          ,od_oprtn_day   => gt_order_extra_tbl(ln_idx).schedule_ship_date    -- 出荷予定日
          ,on_lead_time   => gt_order_extra_tbl(ln_idx).lead_time             -- リードタイム(生産物流)
          ,on_delivery_lt => gt_order_extra_tbl(ln_idx).delivery_lt           -- リードタイム(配送)
          ,ov_errbuf      => lv_errbuf                                        -- エラー・メッセージ
          ,ov_retcode     => lv_retcode                                       -- リターン・コード
          ,ov_errmsg      => lv_errmsg                                        -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      --
      -- ===============================
      -- データチェック(A-5)
      -- ===============================
      data_check(
         it_order_rec  => gt_order_extra_tbl(ln_idx)                 -- 受注データ
/* 2009/09/16 Ver.1.12 Add Start */
        ,in_index      => ln_idx                                     -- インデックス
/* 2009/09/16 Ver.1.12 Add End */
        ,ov_errbuf     => lv_errbuf                                  -- エラー・メッセージ
        ,ov_retcode    => lv_retcode                                 -- リターン・コード
        ,ov_errmsg     => lv_errmsg                                  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a5 := cv_status_warn;
      END IF;
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      IF ( ( lv_retcode <> cv_status_normal ) 
           OR ( lv_retcode_a3 = cv_status_warn ) )
      THEN
        -- 正常でない場合、エラーフラグを設定
        gt_order_extra_tbl(ln_idx).check_status := cn_check_status_error;
        --
        -- スキップ件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END LOOP make_ship_data;
    --
/* 2009/09/16 Ver.1.12 Add Start */
    IF ( cv_status_warn IN ( lv_retcode_a3, lv_retcode_a5 )) THEN
      RAISE process_warn_expt;
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
    -- ===============================
    -- PL/SQL表設定(A-6)
    -- ===============================
    make_normal_order_data(
       ov_errbuf        => lv_errbuf           -- エラー・メッセージ
      ,ov_retcode       => lv_retcode          -- リターン・コード
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
/* 2009/09/16 Ver.1.12 Add Start */
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE process_warn_expt;
/* 2009/09/16 Ver.1.12 Add End */
    END IF;
    --
/* 2009/09/16 Ver.1.12 Add Start */
    IF ( gt_normal_order_tbl.COUNT > 0 ) THEN
      -- ===============================
      -- 積載効率最適化チェック(A-14)
      -- ===============================
      weight_check(
         ov_errbuf       => lv_errbuf            -- エラー・メッセージ
        ,ov_retcode      => lv_retcode           -- リターン・コード
        ,ov_errmsg       => lv_errmsg            -- ユーザー・エラー・メッセージ
      );
      -- リターンコードチェック
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        RAISE process_warn_expt;
      END IF;
      --
      -- ===============================
      -- 受注明細データ分割処理(A-15)
      -- ===============================
      order_line_division(
         ov_errbuf       => lv_errbuf            -- エラー・メッセージ
        ,ov_retcode      => lv_retcode           -- リターン・コード
        ,ov_errmsg       => lv_errmsg            -- ユーザー・エラー・メッセージ
      );
      -- リターンコードチェック
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        RAISE process_warn_expt;
      END IF;
      --
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
    IF ( gt_order_sort_tbl.COUNT > 0 ) THEN
      -- 正常データがある場合
      -- ====================================================
      -- 出荷依頼I/F明細バルクバインドデータ作成(A-7)
      -- ====================================================
      make_request_line_bulk_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 出荷依頼I/Fヘッダバルクバインドデータ作成(A-8)
      -- ====================================================
      make_request_head_bulk_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 出荷依頼I/F明細データ作成(A-9)
      -- ====================================================
      insert_ship_line_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 出荷依頼I/Fヘッダデータ作成(A-10)
      -- ====================================================
      insert_ship_header_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 受注明細更新(A-11)
      -- ====================================================
      update_order_line(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
/* 2009/09/16 Ver.1.12 Add Start */
      -- ====================================================
      -- 出荷依頼I/Fヘッダデータ作成(A-16)
      -- ====================================================
      order_line_insert(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
/* 2009/09/16 Ver.1.12 Add End */
    END IF;
--
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    -- 出荷依頼I/F登録データがある場合
    IF ( ( gn_header_normal_cnt > 0 ) OR ( gn_line_normal_cnt > 0 ) ) THEN
--
      -- ===============================
      -- 生産システム起動(A-12)
      -- ===============================
      start_production_system(
         iv_base_code       => iv_base_code        -- 拠点コード
        ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode         => lv_retcode          -- リターン・コード
        ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a12 := cv_status_warn;
      END IF;
    END IF;
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
--
--****************************** 2009/05/15 1.6 S.Tomita MOD START ******************************--
    -- submainのリターンコード判定
--    IF ( cv_status_warn IN ( lv_retcode_a3
--                            ,lv_retcode_a5 ) )
--    THEN
--      ov_retcode := cv_status_warn;
--    END IF;
    IF ( cv_status_warn IN ( lv_retcode_a3
                            ,lv_retcode_a5
                            ,lv_retcode_a12 ) )
    THEN
      ov_retcode := cv_status_warn;
    END IF;
--****************************** 2009/05/15 1.6 S.Tomita MOD END   ******************************--
--
  EXCEPTION
/* 2009/09/16 Ver.1.12 Add Start */
    WHEN process_warn_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_retcode := cv_status_warn;
/* 2009/09/16 Ver.1.12 Add End */
    WHEN no_data_found_expt THEN
      -- 抽出データなし
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    errbuf           OUT VARCHAR2,         --   エラー・メッセージ  --# 固定 #
    retcode          OUT VARCHAR2,         --   リターン・コード    --# 固定 #
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code     IN     VARCHAR2,         -- 1.拠点コード
--    iv_order_number  IN     VARCHAR2          -- 2.受注番号
    iv_send_flg      IN     VARCHAR2,         -- 1.新規/再送区分
    iv_base_code     IN     VARCHAR2,         -- 2.拠点コード
    iv_order_number  IN     VARCHAR2          -- 3.受注番号
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
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
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--       iv_base_code       -- 拠点コード
--      ,iv_order_number    -- 受注番号
       iv_send_flg        -- 新規/再送区分
      ,iv_base_code       -- 拠点コード
      ,iv_order_number    -- 受注番号
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END  ******************************--
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力(ヘッダー)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_header_nomal_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_header_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力(明細)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_line_nomal_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_line_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
/* 2009/09/16 Ver.1.12 Mod Start */
                    ,iv_name         => cv_error_rec_msg
--                    ,iv_name         => cv_skip_rec_msg
/* 2009/09/16 Ver.1.12 Mod End */
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
/* 2009/09/16 Ver.1.12 Add Start */
      IF ( gn_warn_cnt > 0 ) THEN
        -- エラーデータがある場合
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_name
                        ,iv_name         => cv_msg_warn_end
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      ELSE
/* 2009/09/16 Ver.1.12 Add End */
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2009/09/16 Ver.1.12 Add Start */
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
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
END XXCOS008A01C;
/
