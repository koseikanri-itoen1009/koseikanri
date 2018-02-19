CREATE OR REPLACE PACKAGE BODY APPS.XXWSH400013C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXWSH400013C(body)
 * Description      : 出荷依頼更新アップロード
 * MD.050           : 出荷依頼 <MD050_BPO_401>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(M-1)
 *  get_if_data            ファイルアップロードIFデータ取得(M-2)
 *  get_ship_request_data  出荷依頼データ取得(M-3)
 *  upd_order_data         受注アドオン更新(M-4)
 *  del_data               データ削除(M-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/01/23    1.0   K.Kiriu          新規作成(E_本稼動_14672)
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
  global_lock_expt     EXCEPTION;               -- ロックエラー例外*
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXWSH400013C';     -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxwsh       CONSTANT VARCHAR2(5)   := 'XXWSH';            -- XXWSH
  cv_appl_name_xxcmn       CONSTANT VARCHAR2(5)   := 'XXCMN';            -- XXCMN
  -- メッセージ(XXWSH)
  cv_msg_xxwsh_13192       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13192';  -- パラメータ未入力エラー
  cv_msg_xxwsh_13193       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13193';  -- プロファイル取得失敗エラー
  cv_msg_xxwsh_13194       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13194';  -- 在庫組織ID取得失敗エラー
  cv_msg_xxwsh_13195       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13195';  -- データ取得エラー
  cv_msg_xxwsh_13196       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13196';  -- ロック取得エラー
  cv_msg_xxwsh_13197       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13197';  -- 参照タイプ取得エラー
  cv_msg_xxwsh_13228       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13228';  -- パラメータ出力
  cv_msg_xxwsh_13198       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13198';  -- 挿入エラー
  cv_msg_xxwsh_13223       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13223';  -- 削除エラー
  cv_msg_xxwsh_13199       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13199';  -- 対象未存在エラー
  cv_msg_xxwsh_13238       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13238';  -- 在庫会計期間チェックエラー
  cv_msg_xxwsh_13200       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13200';  -- 取引タイプエラー
  cv_msg_xxwsh_13201       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13201';  -- ステータスエラー
  cv_msg_xxwsh_13202       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13202';  -- 通知ステータスエラー
  cv_msg_xxwsh_13203       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13203';  -- 重量容積区分エラー
  cv_msg_xxwsh_13204       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13204';  -- 手動引当済みエラー
  cv_msg_xxwsh_13205       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13205';  -- 更新項目なしエラー
  cv_msg_xxwsh_13206       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13206';  -- 対象外品目エラー（変更前）
  cv_msg_xxwsh_13207       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13207';  -- 対象外品目エラー（変更後）
  cv_msg_xxwsh_13208       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13208';  -- 必須エラー
  cv_msg_xxwsh_13209       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13209';  -- INV品目対象外エラー
  cv_msg_xxwsh_13210       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13210';  -- 子品目対象外エラー
  cv_msg_xxwsh_13211       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13211';  -- 出荷入数整数倍エラー
  cv_msg_xxwsh_13212       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13212';  -- 桁数オーバーエラー
  cv_msg_xxwsh_13213       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13213';  -- 共通関数エラー（積載効率チェック(合計値算出)）
  cv_msg_xxwsh_13231       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13231';  -- 物流構成アドオン未登録ワーニング
  cv_msg_xxwsh_13248       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13248';  -- 出荷可否チェック関数エラーワーニング
  cv_msg_xxwsh_13232       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13232';  -- 出荷可否チェック（出荷数制限）ワーニング
  cv_msg_xxwsh_13235       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13235';  -- 出荷可否チェック（出荷停止日）ワーニング
  cv_msg_xxwsh_13236       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13236';  -- 出荷可否チェック（引取計画）ワーニング
  cv_msg_xxwsh_13214       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13214';  -- ロック取得エラー２
  cv_msg_xxwsh_13215       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13215';  -- 更新エラー
  cv_msg_xxwsh_13216       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13216';  -- 共通関数エラー（引当解除）
  cv_msg_xxwsh_13217       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13217';  -- 共通関数エラー（最大配送区分算出）
  cv_msg_xxwsh_13239       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13239';  -- パレット最大枚数超過ワーニング
  cv_msg_xxwsh_13218       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13218';  -- 共通関数エラー(積載効率チェック(積載効率算出))
  cv_msg_xxwsh_13219       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13219';  -- 積載重量オーバーエラー
  cv_msg_xxwsh_13220       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13220';  -- ロック取得エラー３
  cv_msg_xxwsh_13221       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13221';  -- 更新エラー２
  cv_msg_xxwsh_13222       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13222';  -- 共通関数エラー（配車解除関数）
  cv_msg_xxwsh_13240       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13240';  -- 混載元No取得失敗エラー
  cv_msg_xxwsh_13241       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13241';  -- 混載合計重量オーバーエラー
  cv_msg_xxwsh_13251       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13251';  -- ファイル項目チェックエラー
  cv_msg_xxwsh_13252       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13252';  -- データ項目数マイナスエラー文言
  -- メッセージ(XXCMN)
  cv_msg_xxcmn_10640       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10640';  -- BLOBデータ変換エラー
  cv_msg_xxcmn_10639       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10639';  -- ファイル項目チェックエラー
  -- トークンメッセージ
  cv_msg_xxwsh_13224       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13224';  -- ファイルID(文言)
  cv_msg_xxwsh_13225       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13225';  -- フォーマットパターン(文言)
  cv_msg_xxwsh_13226       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13226';  -- ファイルアップロードIFテーブル(文言)
  cv_msg_xxwsh_13227       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13227';  -- 出荷依頼更新アップロード項目定義(文言)
  cv_msg_xxwsh_13229       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13229';  -- 出荷依頼更新アップロード(文言)
  cv_msg_xxwsh_13230       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13230';  -- 出荷依頼更新アップロードワーク(文言)
  cv_msg_xxwsh_13244       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13244';  -- 入出庫換算単位(文言)
  cv_msg_xxwsh_13245       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13245';  -- ケース数(文言)
  cv_msg_xxwsh_13246       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13246';  -- パレット値最大段数(文言)
  cv_msg_xxwsh_13247       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13247';  -- 配数(文言)
  cv_msg_xxwsh_13233       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13233';  -- 出荷数制限(商品部)(文言)
  cv_msg_xxwsh_13234       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13234';  -- 出荷数制限(物流部)(文言)
  cv_msg_xxwsh_13237       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13237';  -- 出荷数制限(引取計画商品)(文言)
  cv_msg_xxwsh_13249       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13249';  -- 受注明細アドオン(文言)
  cv_msg_xxwsh_13250       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13250';  -- 受注ヘッダアドオン(文言)
  -- データ取得用メッセージ
  cv_msg_xxwsh_13242       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13242';  -- 品目区分（文言）
  cv_msg_xxwsh_13243       CONSTANT VARCHAR2(20)  := 'APP-XXWSH-13243';  -- 商品区分（文言）
  -- トークン
  cv_tkn_parameter         CONSTANT VARCHAR2(9)   := 'PARAMETER';
  cv_tkn_prof_name         CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_tkn_org_code          CONSTANT VARCHAR2(8)   := 'ORG_CODE';
  cv_tkn_table             CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_tkn_lookup            CONSTANT VARCHAR2(6)   := 'LOOKUP';
  cv_tkn_upload_name       CONSTANT VARCHAR2(11)  := 'UPLOAD_NAME';
  cv_tkn_file_name         CONSTANT VARCHAR2(9)   := 'FILE_NAME';
  cv_tkn_file_id           CONSTANT VARCHAR2(7)   := 'FILE_ID';
  cv_tkn_format            CONSTANT VARCHAR2(6)   := 'FORMAT';
  cv_tkn_count             CONSTANT VARCHAR2(5)   := 'COUNT';
  cv_tkn_input_line_no     CONSTANT VARCHAR2(13)  := 'INPUT_LINE_NO';
  cv_tkn_err_msg           CONSTANT VARCHAR2(7)   := 'ERR_MSG';
  cv_tkn_request_no        CONSTANT VARCHAR2(10)  := 'REQUEST_NO';
  cv_tkn_item_code         CONSTANT VARCHAR2(9)   := 'ITEM_CODE';
  cv_tkn_ship_date         CONSTANT VARCHAR2(9)   := 'SHIP_DATE';
  cv_tkn_pallet_q          CONSTANT VARCHAR2(15)  := 'PALLET_QUANTITY';
  cv_tkn_layer_q           CONSTANT VARCHAR2(14)  := 'LAYER_QUANTITY';
  cv_tkn_case_q            CONSTANT VARCHAR2(13)  := 'CASE_QUANTITY';
  cv_tkn_column            CONSTANT VARCHAR2(6)   := 'COLUMN';
  cv_tkn_quantity          CONSTANT VARCHAR2(8)   := 'QUANTITY';
  cv_tkn_num_of_deliver    CONSTANT VARCHAR2(14)  := 'NUM_OF_DELIVER';
  cv_tkn_deliver_to        CONSTANT VARCHAR2(10)  := 'DELIVER_TO';
  cv_tkn_deliver_from      CONSTANT VARCHAR2(12)  := 'DELIVER_FROM';
  cv_tkn_hs_branch         CONSTANT VARCHAR2(9)   := 'HS_BRANCH';
  cv_tkn_chk_type          CONSTANT VARCHAR2(9)   := 'CHK_TYPE';
  cv_tkn_base_date         CONSTANT VARCHAR2(9)   := 'BASE_DATE';
  cv_tkn_prod_class        CONSTANT VARCHAR2(10)  := 'PROD_CLASS';
  cv_tkn_weight_class      CONSTANT VARCHAR2(12)  := 'WEIGHT_CLASS';
  cv_tkn_err_code          CONSTANT VARCHAR2(10)  := 'ERROR_CODE';
  cv_tkn_s_method_code     CONSTANT VARCHAR2(16)  := 'SHIP_METHOD_CODE';
  cv_tkn_weight            CONSTANT VARCHAR2(6)   := 'WEIGHT';
  cv_max_weight            CONSTANT VARCHAR2(10)  := 'MAX_WEIGHT';
  cv_cur_weight            CONSTANT VARCHAR2(10)  := 'CUR_WEIGHT';
  -- プロファイル
  cv_prf_item_num          CONSTANT VARCHAR2(27)  := 'XXWSH_ORDER_UPLOAD_ITEM_NUM';    -- XXWSH:出荷依頼更新項目数
  cv_prf_org_code          CONSTANT VARCHAR2(18)  := 'XXWSH_INV_ORG_CODE';             -- XXWSH:INV在庫組織コード
  -- 参照タイプコード
  cv_lookup_upload_def     CONSTANT VARCHAR2(22)  := 'XXWSH_ORDER_UPLOAD_DEF';         -- 出荷依頼更新アップロード項目定義
  cv_lookup_process_upload CONSTANT VARCHAR2(22)  := 'XXWSH_PROCESS_UPLOAD';           -- 処理種別（出荷依頼更新アップロード）
  cv_lookup_t_status       CONSTANT VARCHAR2(24)  := 'XXWSH_TRANSACTION_STATUS';       -- ステータス
  cv_lookup_n_status       CONSTANT VARCHAR2(18)  := 'XXWSH_NOTIF_STATUS';             -- 通知ステータス
  -- 項目定義
  cv_null_ok               CONSTANT VARCHAR2(7)   := 'NULL_OK';          -- 任意項目
  cv_null_ng               CONSTANT VARCHAR2(7)   := 'NULL_NG';          -- 必須項目
  cv_varchar               CONSTANT VARCHAR2(8)   := 'VARCHAR2';         -- 文字列
  cv_number                CONSTANT VARCHAR2(6)   := 'NUMBER';           -- 数値
  cv_date                  CONSTANT VARCHAR2(4)   := 'DATE';             -- 日付
  cv_varchar_cd            CONSTANT VARCHAR2(1)   := '0';                -- 文字列項目
  cv_number_cd             CONSTANT VARCHAR2(1)   := '1';                -- 数値項目
  cv_date_cd               CONSTANT VARCHAR2(1)   := '2';                -- 日付項目
  cv_not_null              CONSTANT VARCHAR2(1)   := '1';                -- 必須
  -- CSVファイルのデミリタ文字
  cv_msg_comma             CONSTANT VARCHAR2(1)   := ',';                -- カンマ
  -- 重量容積区分
  cv_weight                CONSTANT VARCHAR2(1)   := '1';                -- 重量
  -- 自動手動引当区分
  cv_reserve_flag_auto     CONSTANT VARCHAR2(2)   := '10';               -- 自動引当
  cv_manual                CONSTANT VARCHAR2(2)   := '20';               -- 手動引当
  -- 出荷区分
  cv_ship_class_1          CONSTANT VARCHAR2(1)   := '1';                -- 出荷可
  -- 廃止区分
  cv_obsolete_class_0      CONSTANT VARCHAR2(1)   := '0';                -- 廃止されていない
  -- 率区分
  cv_rate_class_0          CONSTANT VARCHAR2(1)   := '0';                -- 標準原価
  -- 売上対象区分
  cv_sales_div_1           CONSTANT VARCHAR2(1)   := '1';                -- 売上対象
  -- カテゴリ（品目区分）
  cv_item_div_5            CONSTANT VARCHAR2(1)   := '5';                -- 製品
  -- カテゴリ（商品区分）
  cv_product_div_2         CONSTANT VARCHAR2(1)   := '2';                -- ドリンク
  -- 品目ステータス
  cv_inactive              CONSTANT VARCHAR2(8)   := 'Inactive';         -- Inactive
  -- 品目コードの1桁目
  cv_item_code_5           CONSTANT VARCHAR2(1)   := '5';                -- 資材
  cv_item_code_6           CONSTANT VARCHAR2(1)   := '6';                -- 資材
  -- 出荷可否チェック(共通関数)
  cv_check_class_2         CONSTANT VARCHAR2(1)   := '2';                -- 出荷数制限(商品部)
  cv_check_class_3         CONSTANT VARCHAR2(1)   := '3';                -- 出荷数制限(物流部)
  cv_check_class_4         CONSTANT VARCHAR2(1)   := '4';                -- 出荷数制限(引取計画商品)
  cn_ret_normal            CONSTANT NUMBER        := 0;                  -- 処理結果：正常
  cn_ret_num_over          CONSTANT NUMBER        := 1;                  -- 処理結果：数量オーバー
  cn_ret_date_err          CONSTANT NUMBER        := 2;                  -- 処理結果：出荷停止日エラー
  cv_plan_item_flag        CONSTANT VARCHAR(1)    := '1';                -- 計画商品フラグ:1(計画商品対象)
  -- 業務種別(共通関数)
  cv_ship                  CONSTANT VARCHAR(1)    := '1';                -- 業務種別：出荷
  -- 小口区分
  cv_amount_class_small    CONSTANT VARCHAR(1)    := '1';                -- 小口区分：小口
  -- 運賃区分
  cv_freight_charge_on     CONSTANT VARCHAR(1)    := '1';                -- 運賃区分：ON
  -- コード区分(共通関数)
  cv_code_class_4          CONSTANT VARCHAR(1)    := '4';                -- コード区分１：4(倉庫)
  cv_code_class_9          CONSTANT VARCHAR(1)    := '9';                -- コード区分２：9(配送先)
  -- 積載オーバー区分(共通関数)
  cv_loading_over          CONSTANT VARCHAR2(1)   := '1';                -- 積載オーバー
  -- 配車解除(共通関数)
  cv_cancel_flag_judge     CONSTANT VARCHAR2(1)   := '2';                -- 重量オーバーの場合のみ配車解除
  -- システム日付
  cd_sysdate               CONSTANT DATE          := TRUNC(SYSDATE);     -- システム日付
  -- 汎用
  cv_no                    CONSTANT VARCHAR2(1)   := 'N';                -- No
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                -- Yes
  cn_0                     CONSTANT NUMBER        := 0;                  -- 0
  cn_1                     CONSTANT NUMBER        := 1;                  -- 1
  cv_minus                 CONSTANT VARCHAR2(1)   := '-';                -- マイナス
  -- 日付フォーマット
  cv_yyyymm                CONSTANT VARCHAR2(6)   := 'YYYYMM';           -- YYYYMM形式
  cv_yyyymmdd_sla          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';       -- YYYY/MM/DD形式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目定義レコード型定義
  TYPE g_item_def_rtype IS RECORD(
     item_name             VARCHAR2(100)                               -- 項目名
    ,item_attribute        VARCHAR2(100)                               -- 項目属性
    ,item_essential        VARCHAR2(100)                               -- 必須フラグ
    ,item_length           NUMBER                                      -- 項目の長さ(整数部分)
    ,decim                 NUMBER                                      -- 項目の長さ(小数点以下)
  );
  -- 出荷依頼更新アップロードワークレコード型定義
  TYPE g_upload_work_rtype IS RECORD(
     line_number       xxwsh_order_upload_work.line_number%TYPE
    ,request_no        xxwsh_order_upload_work.request_no%TYPE
    ,item_code         xxwsh_order_upload_work.item_code%TYPE
    ,conv_item_code    xxwsh_order_upload_work.conv_item_code%TYPE
    ,pallet_quantity   xxwsh_order_upload_work.pallet_quantity%TYPE
    ,layer_quantity    xxwsh_order_upload_work.layer_quantity%TYPE
    ,case_quantity     xxwsh_order_upload_work.case_quantity%TYPE
    ,request_id        xxwsh_order_upload_work.request_id%TYPE
  );
  -- 出荷依頼データレコード型定義
  TYPE g_order_rtype IS RECORD(
     transaction_type_name     xxwsh_oe_transaction_types_v.transaction_type_name%TYPE
    ,status                    xxcmn_lookup_values2_v.attribute1%TYPE
    ,notif_status              xxcmn_lookup_values2_v.attribute1%TYPE
    ,order_header_id           xxwsh_order_headers_all.order_header_id%TYPE
    ,request_no                xxwsh_order_headers_all.request_no%TYPE
    ,weight_capacity_class     xxwsh_order_headers_all.weight_capacity_class%TYPE
    ,freight_charge_class      xxwsh_order_headers_all.freight_charge_class%TYPE
    ,schedule_ship_date        xxwsh_order_headers_all.schedule_ship_date%TYPE
    ,schedule_arrival_date     xxwsh_order_headers_all.schedule_arrival_date%TYPE
    ,based_weight              xxwsh_order_headers_all.based_weight%TYPE
    ,mixed_no                  xxwsh_order_headers_all.mixed_no%TYPE
    ,head_sales_branch         xxwsh_order_headers_all.head_sales_branch%TYPE
    ,deliver_to                xxwsh_order_headers_all.deliver_to%TYPE
    ,deliver_from              xxwsh_order_headers_all.deliver_from%TYPE
    ,deliver_from_id           xxwsh_order_headers_all.deliver_from_id%TYPE
    ,xola_rowid                rowid
    ,order_line_id             xxwsh_order_lines_all.order_line_id%TYPE
    ,automanual_reserve_class  xxwsh_order_lines_all.automanual_reserve_class%TYPE
    ,request_item_code         xxwsh_order_lines_all.request_item_code%TYPE
    ,pallet_quantity           xxwsh_order_lines_all.pallet_quantity%TYPE
    ,layer_quantity            xxwsh_order_lines_all.layer_quantity%TYPE
    ,case_quantity             xxwsh_order_lines_all.case_quantity%TYPE
    ,shipped_quantity          xxwsh_order_lines_all.shipped_quantity%TYPE
    ,based_request_quantity    xxwsh_order_lines_all.based_request_quantity%TYPE
  );
  -- 変更後の品目データレコード型定義
  TYPE g_new_item_rtype IS RECORD(
     item_id              xxcmn_item_mst2_v.item_id%TYPE
    ,parent_item_id       xxcmn_item_mst2_v.parent_item_id%TYPE
    ,inventory_item_id    xxcmn_item_mst2_v.inventory_item_id%TYPE
    ,item_no              xxcmn_item_mst2_v.item_no%TYPE
    ,conv_unit            xxcmn_item_mst2_v.conv_unit%TYPE
    ,num_of_cases         xxcmn_item_mst2_v.num_of_cases%TYPE
    ,max_palette_steps    xxcmn_item_mst2_v.max_palette_steps%TYPE
    ,delivery_qty         xxcmn_item_mst2_v.delivery_qty%TYPE
    ,item_um              xxcmn_item_mst2_v.item_um%TYPE
    ,num_of_deliver       xxcmn_item_mst2_v.num_of_deliver%TYPE
  );
  -- 更新用明細データレコード型定義
  TYPE g_ship_line_data_rtype IS RECORD(
     line_number                 xxwsh_order_upload_work.line_number%TYPE               -- 行No
    ,automanual_reserve_class    xxwsh_order_lines_all.automanual_reserve_class%TYPE    -- 自動手動引当区分
    ,order_header_id             xxwsh_order_headers_all.order_header_id%TYPE           -- 受注ヘッダアドオンID
    ,request_no                  xxwsh_order_headers_all.request_no%TYPE                -- 依頼No
    ,mixed_no                    xxwsh_order_headers_all.mixed_no%TYPE                  -- 混載元No
    ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE         -- 管轄拠点
    ,deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE                -- 出荷先
    ,deliver_from                xxwsh_order_headers_all.deliver_from%TYPE              -- 出荷元保管場所
    ,deliver_from_id             xxwsh_order_headers_all.deliver_from_id%TYPE           -- 出荷元ID
    ,schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE        -- 出庫予定日
    ,schedule_arrival_date       xxwsh_order_headers_all.schedule_arrival_date%TYPE     -- 着荷予定日
    ,xola_rowid                  rowid                                                  -- 明細ROWID
    ,order_line_id               xxwsh_order_lines_all.order_line_id%TYPE               -- 受注明細アドオンID
    ,shipping_inventory_item_id  xxwsh_order_lines_all.shipping_inventory_item_id%TYPE  -- 出荷品目ID
    ,shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE          -- 出荷品目
    ,quantity                    xxwsh_order_lines_all.quantity%TYPE                    -- 数量
    ,uom_code                    xxwsh_order_lines_all.uom_code%TYPE                    -- 単位
    ,shipped_quantity            xxwsh_order_lines_all.shipped_quantity%TYPE            -- 出荷実績数量
    ,based_request_quantity      xxwsh_order_lines_all.based_request_quantity%TYPE      -- 拠点依頼数量
    ,request_item_id             xxwsh_order_lines_all.request_item_id%TYPE             -- 依頼品目ID
    ,request_item_code           xxwsh_order_lines_all.request_item_code%TYPE           -- 依頼品目
    ,po_number                   xxwsh_order_lines_all.po_number%TYPE                   -- 発注NO
    ,pallet_quantity             xxwsh_order_lines_all.pallet_quantity%TYPE             -- パレット数
    ,layer_quantity              xxwsh_order_lines_all.layer_quantity%TYPE              -- 段数
    ,case_quantity               xxwsh_order_lines_all.case_quantity%TYPE               -- ケース数
    ,weight                      xxwsh_order_lines_all.weight%TYPE                      -- 重量
    ,capacity                    xxwsh_order_lines_all.capacity%TYPE                    -- 容積
    ,pallet_weight               xxwsh_order_lines_all.pallet_weight%TYPE               -- パレット重量
    ,pallet_qty                  xxwsh_order_lines_all.pallet_qty%TYPE                  -- パレット枚数
    ,shipping_request_if_flg     xxwsh_order_lines_all.shipping_request_if_flg%TYPE     -- 出荷依頼インタフェース済フラグ
    ,shipping_result_if_flg      xxwsh_order_lines_all.shipping_result_if_flg%TYPE      -- 出荷実績インタフェース済フラグ
    ,last_updated_by             xxwsh_order_lines_all.last_updated_by%TYPE             -- 最終更新者
    ,last_update_date            xxwsh_order_lines_all.last_update_date%TYPE            -- 最終更新日
    ,last_update_login           xxwsh_order_lines_all.last_update_login%TYPE           -- 最終更新ログイン
    ,request_id                  xxwsh_order_lines_all.request_id%TYPE                  -- 要求ID
    ,program_application_id      xxwsh_order_lines_all.program_application_id%TYPE      -- コンカレント・プログラム・アプリケーションID
    ,program_id                  xxwsh_order_lines_all.program_id%TYPE                  -- コンカレント・プログラムID
    ,program_update_date         xxwsh_order_lines_all.program_update_date%TYPE         -- プログラム更新日
  );
  -- 項目定義テーブル型定義
  TYPE g_item_def_ttype       IS TABLE OF g_item_def_rtype       INDEX BY BINARY_INTEGER;
  -- 出荷依頼更新アップロードワークテーブル型定義
  TYPE g_upload_work_ttype    IS TABLE OF g_upload_work_rtype    INDEX BY BINARY_INTEGER;
  -- 更新用明細データテーブル型定義
  TYPE g_ship_line_data_ttype IS TABLE OF g_ship_line_data_rtype INDEX BY BINARY_INTEGER;
  -- 項目定義テーブル型
  gt_item_def_tab        g_item_def_ttype;
  -- 出荷依頼更新アップロードワークテーブル型
  gt_upload_work_tab     g_upload_work_ttype;
  -- 更新用明細データテーブル型
  gt_ship_line_data_tab  g_ship_line_data_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_id                       NUMBER;            -- ファイルＩＤ
  gv_format                        VARCHAR2(100);     -- フォーマットパターン
  gn_item_num                      NUMBER;            -- 出荷依頼更新項目数
  gv_org_code                      VARCHAR2(100);     -- INV在庫組織コード
  gn_inv_org_id                    NUMBER;            -- INV在庫組織ID
  gv_opm_close_period              VARCHAR2(6);       -- OPMクローズ会計期間
  gv_item_div_name                 VARCHAR2(20);      -- カテゴリセット名（品目区分）文言
  gv_product_div_name              VARCHAR2(20);      -- カテゴリセット名（商品区分）文言
  gn_skip_cnt                      NUMBER;            -- スキップ件数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(M-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2  -- ファイルＩＤ
    ,iv_format     IN  VARCHAR2  -- フォーマットパターン
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- *** ローカル定義例外 ***
    get_param_expt            EXCEPTION;                                       -- パラメータNULLエラー
    get_profile_expt          EXCEPTION;                                       -- プロファイル取得例外
    get_org_id_expt           EXCEPTION;                                       -- INV在庫組織ID取得エラー
    get_data_expt             EXCEPTION;                                       -- データ取得エラー
    get_lookup_expt           EXCEPTION;                                       -- 参照タイプ取得エラー
    -- *** ローカル変数 ***
    lv_error_token            VARCHAR2(100);                                   -- トークンメッセージ格納用
    ln_cnt                    NUMBER;                                          -- 項目定義確認用
    lv_parameter              VARCHAR2(5000);                                  -- パラメータ出力用
    lv_csv_file_name          xxinv_mrp_file_ul_interface.file_name%TYPE;      -- ファイル名格納用
    -- *** ローカル・カーソル ***
    -- データ項目定義取得用カーソル
    CURSOR get_def_info_cur
    IS
      SELECT   xlvv.meaning                     AS item_name       -- 内容
              ,DECODE( xlvv.attribute1
                      ,cv_varchar, cv_varchar_cd
                      ,cv_number , cv_number_cd
                      , cv_date_cd
                     )                          AS item_attribute  -- 項目属性
              ,DECODE( xlvv.attribute2
                      ,cv_not_null, cv_null_ng
                      ,cv_null_ok
                     )                          AS item_essential  -- 必須フラグ
              ,TO_NUMBER(xlvv.attribute3)       AS item_length     -- 長さ(整数)
              ,TO_NUMBER(xlvv.attribute4)       AS decim           -- 長さ(小数点以下)
      FROM     xxcmn_lookup_values_v  xlvv  -- クイックコードVIEW
      WHERE    xlvv.lookup_type        = cv_lookup_upload_def
      ORDER BY xlvv.lookup_code
      ;
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
    -- M-1.1 入力パラメータ（FILE_ID、フォーマット）のNULLチェック
    --==============================================================
--
    -- 1.ファイルID
    IF ( iv_file_id IS NULL ) THEN
      lv_error_token := cv_msg_xxwsh_13224;
      RAISE get_param_expt;
    END IF;
--
    -- 2.フォーマットパターン
    IF ( iv_format IS NULL ) THEN
      lv_error_token := cv_msg_xxwsh_13225;
      RAISE get_param_expt;
    END IF;
--
    -- INパラメータを格納
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
--
    --==============================================================
    -- M-1.2 プロファイル値取得
    --==============================================================
--
    -- XXWSH:出荷依頼更新項目数の取得
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num));
    -- 取得エラー時
    IF ( gn_item_num IS NULL ) THEN
      lv_error_token := cv_prf_item_num;
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:INV在庫組織コードの取得
    gv_org_code := FND_PROFILE.VALUE(cv_prf_org_code);
    -- 取得エラー時
    IF ( gv_org_code IS NULL ) THEN
      lv_error_token := cv_prf_org_code;
      RAISE get_profile_expt;
    END IF;
--
    --==============================================================
    -- M-1.3 INV在庫組織ID取得
    --==============================================================
    BEGIN
      SELECT  mp.organization_id  master_org_id   -- INV在庫組織ID
      INTO    gn_inv_org_id
      FROM    mtl_parameters  mp  -- 組織パラメータ
      WHERE   mp.organization_code = gv_org_code  -- 上記で取得したINV在庫組織コード
      ;
    --
    EXCEPTION
      -- 取得エラー時
      WHEN NO_DATA_FOUND THEN
        lv_error_token := gv_org_code;
        RAISE get_org_id_expt;
    END;
--
    --==============================================================
    -- M-1.4 ファイルアップロードIFデータ取得
    --==============================================================
    BEGIN
      SELECT  fui.file_name      file_name     -- ファイル名
      INTO    lv_csv_file_name
      FROM    xxinv_mrp_file_ul_interface  fui -- ファイルアップロードIFテーブル
      WHERE   fui.file_id = gn_file_id         -- ファイルID
      FOR UPDATE NOWAIT
      ;
    --
    EXCEPTION
      -- 取得エラー時
      WHEN NO_DATA_FOUND THEN
        lv_error_token := cv_msg_xxwsh_13226;
        RAISE get_data_expt;
      -- ロック取得エラー時
      WHEN global_lock_expt THEN
        lv_error_token := cv_msg_xxwsh_13226;
        RAISE global_lock_expt;
    END;
--
    --==============================================================
    -- M-1.5 出荷依頼更新アップロード項目定義情報の取得
    --==============================================================
    -- 変数の初期化
    ln_cnt := 0;
    -- テーブル定義取得LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_item_def_tab(ln_cnt).item_name       := get_def_info_rec.item_name;       -- 項目名
      gt_item_def_tab(ln_cnt).item_attribute  := get_def_info_rec.item_attribute;  -- 項目属性
      gt_item_def_tab(ln_cnt).item_essential  := get_def_info_rec.item_essential;  -- 必須フラグ
      gt_item_def_tab(ln_cnt).item_length     := get_def_info_rec.item_length;     -- 長さ(整数部分)
      gt_item_def_tab(ln_cnt).decim           := get_def_info_rec.decim;           -- 長さ(小数点以下)
    END LOOP def_info_loop;
    -- 定義情報が取得できない場合はエラー
    IF ( ln_cnt = 0 ) THEN
      lv_error_token := cv_msg_xxwsh_13227;
      RAISE get_data_expt;
    END IF;
--
    --==============================================================
    -- M-1.6 OPM在庫会計期間CLOSE年月の取得
    --==============================================================
    gv_opm_close_period := xxcmn_common_pkg.get_opminv_close_period;
--
    --==============================================================
    -- M-1.7 INパラメータの出力
    --==============================================================
    lv_parameter := xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_name_xxwsh
                     ,iv_name          => cv_msg_xxwsh_13228
                     ,iv_token_name1   => cv_tkn_upload_name   --パラメータ1(トークン)
                     ,iv_token_value1  => cv_msg_xxwsh_13229   --文言
                     ,iv_token_name2   => cv_tkn_file_name     --パラメータ2(トークン)
                     ,iv_token_value2  => lv_csv_file_name     --文言
                     ,iv_token_name3   => cv_tkn_file_id       --パラメータ3(トークン)
                     ,iv_token_value3  => iv_file_id           --文言
                     ,iv_token_name4   => cv_tkn_format        --パラメータ4(トークン)
                     ,iv_token_value4  => iv_format            --文言
                   );
    -- 出力に表示
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_parameter
    );
    -- 出力に表示(空行)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ログに表示
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_parameter
    );
    -- ログに表示(空行)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- 処理に使用する固定文言(メッセージ)を取得
--
    -- 品目区分
    gv_item_div_name     := xxccp_common_pkg.get_msg(
                              iv_application   => cv_appl_name_xxwsh
                             ,iv_name          => cv_msg_xxwsh_13242
                            );
    -- 商品区分
    gv_product_div_name  := xxccp_common_pkg.get_msg(
                              iv_application   => cv_appl_name_xxwsh
                             ,iv_name          => cv_msg_xxwsh_13243
                            );
--
  EXCEPTION
    -- *** パラメータNULLエラー ***
    WHEN get_param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_name_xxwsh
                    ,iv_name          => cv_msg_xxwsh_13192
                    ,iv_token_name1   => cv_tkn_parameter     --パラメータ1(トークン)
                    ,iv_token_value1  => lv_error_token       --文言
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル取得エラー ***
    WHEN get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_name_xxwsh
                    ,iv_name          => cv_msg_xxwsh_13193
                    ,iv_token_name1   => cv_tkn_prof_name     --パラメータ1(トークン)
                    ,iv_token_value1  => lv_error_token       --文言
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** INV在庫組織ID取得エラー ***
    WHEN get_org_id_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxwsh_13194            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_org_code
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** データ取得エラー ***
    WHEN get_data_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxwsh_13195            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ロック取得エラー ***
    WHEN global_lock_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxwsh_13196            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 参照タイプ取得エラー ***
    WHEN get_lookup_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxwsh_13197            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_lookup
                      ,iv_token_value1 => lv_error_token
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(M-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
     ov_errbuf     OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- *** ローカル定義例外 ***
    blob_expt                 EXCEPTION;  -- BLOBデータ変換エラー
    ins_err_expt              EXCEPTION;  -- 挿入エラー
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_item_num               NUMBER;                             -- 項目数
    ln_line_cnt               NUMBER;                             -- 行カウンタ
    ln_item_cnt               NUMBER;                             -- 項目数カウンタ
    lv_err_flag               VARCHAR2(1);                        -- エラーフラグ
    lv_item_err_flag          VARCHAR2(1);                        -- エラーフラグ（項目）
    ln_data_cnt               NUMBER;                             -- ワークテーブルカウンタ
    -- *** ローカル・テーブル ***
    lt_if_data_tab   xxcmn_common3_pkg.g_file_data_tbl;  --  テーブル型変数を宣言
    -- チェック用情報
    TYPE g_check_data_ttype IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
    lt_check_data_tab  g_check_data_ttype;
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
    -- M-2.1 ファイルアップロードIFデータ取得
    --==============================================================
    xxcmn_common3_pkg.blob_to_varchar2(    -- BLOBデータ変換共通関数
      in_file_id   => gn_file_id           -- ファイルＩＤ
     ,ov_file_data => lt_if_data_tab       -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
--
    -- エラーフラグ初期化
    lv_err_flag := cv_no;
    -- ワークテーブルカウンタの初期化
    ln_data_cnt := cn_0;
--
    -- 項目妥当性チェックLOOP(M-2.2)
    <<check_loop>>
    FOR ln_line_cnt IN 1..lt_if_data_tab.COUNT LOOP
--
      -- 対象件数取得
      gn_target_cnt := gn_target_cnt + 1;
--
      --==============================================================
      -- M-2.3 項目数のチェック
      --==============================================================
      -- データ項目数を格納
      ln_item_num := ( LENGTHB( lt_if_data_tab(ln_line_cnt) )
                   - ( LENGTHB( REPLACE(lt_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- 項目数が一致しない場合
      IF ( gn_item_num <> ln_item_num ) THEN
        -- メッセージ出力
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxwsh_13251    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_xxwsh_13229
                      ,iv_token_name2  => cv_tkn_count
                      ,iv_token_value2 => TO_CHAR(ln_item_num)
                      ,iv_token_name3  => cv_tkn_input_line_no
                      ,iv_token_value3 => TO_CHAR(ln_line_cnt)
                     );
        -- 出力に表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ログに表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- エラーフラグをYにする
        lv_err_flag := cv_yes;
      -- 項目数が一致する場合
      ELSE
        -- エラーフラグ(項目)の初期化
        lv_item_err_flag := cv_no;
        --==============================================================
        -- M-2.4 対象データ分割
        --==============================================================
        <<get_column_loop>>
        FOR ln_item_cnt IN 1..gn_item_num LOOP
          -- 変数に項目の値を格納
          lt_check_data_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(
                                               iv_char     => lt_if_data_tab(ln_line_cnt)  -- 分割元文字列
                                              ,iv_delim    => cv_msg_comma                 -- デリミタ文字
                                              ,in_part_num => ln_item_cnt                  -- 返却対象INDEX
                                            );
          --==============================================================
          -- M-2.5 必須/型/サイズチェック
          --==============================================================
          xxccp_common_pkg2.upload_item_check(
            iv_item_name    => gt_item_def_tab(ln_item_cnt).item_name          -- 項目名称
           ,iv_item_value   => lt_check_data_tab(ln_item_cnt)                  -- 項目の値
           ,in_item_len     => gt_item_def_tab(ln_item_cnt).item_length        -- 項目の長さ(整数部分)
           ,in_item_decimal => gt_item_def_tab(ln_item_cnt).decim              -- 項目の長さ（小数点以下）
           ,iv_item_nullflg => gt_item_def_tab(ln_item_cnt).item_essential     -- 必須フラグ
           ,iv_item_attr    => gt_item_def_tab(ln_item_cnt).item_attribute     -- 項目の属性
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- チェックエラーの場合
          IF ( lv_retcode <> cv_status_normal )  THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxcmn          -- アプリケーション短縮名
                           ,iv_name          =>  cv_msg_xxcmn_10639          -- メッセージコード
                           ,iv_token_name1   =>  cv_tkn_input_line_no        -- トークンコード1
                           ,iv_token_value1  =>  TO_CHAR(ln_line_cnt)        -- トークン値1
                           ,iv_token_name2   =>  cv_tkn_err_msg              -- トークンコード2
                           ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- トークン値2
                          );
             -- 出力に表示
             FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
             );
             -- ログに表示
             FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
               ,buff   => lv_errmsg
             );
             -- エラーフラグをYにする
             lv_err_flag      := cv_yes;
             -- 項目のエラーフラグをYにする
             lv_item_err_flag := cv_yes;
          END IF;
--
          --==============================================================
          -- M-2.6 数量項目のマイナス値チェック
          --==============================================================
          IF ( ln_item_cnt IN ( 4, 5, 6) ) THEN
            -- マイナス値のチェック
            IF ( INSTR( lt_check_data_tab(ln_item_cnt), cv_minus ) > 0 ) THEN
              -- トークン用のメッセージ編集
              lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh                      -- アプリケーション短縮名
                             ,iv_name          =>  cv_msg_xxwsh_13252                      -- メッセージコード
                             ,iv_token_name1   =>  cv_tkn_column                           -- トークンコード1
                             ,iv_token_value1  =>  gt_item_def_tab(ln_item_cnt).item_name  -- トークン値1
                            );
              lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxcmn          -- アプリケーション短縮名
                             ,iv_name          =>  cv_msg_xxcmn_10639          -- メッセージコード
                             ,iv_token_name1   =>  cv_tkn_input_line_no        -- トークンコード1
                             ,iv_token_value1  =>  TO_CHAR(ln_line_cnt)        -- トークン値1
                             ,iv_token_name2   =>  cv_tkn_err_msg              -- トークンコード2
                             ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- トークン値2
                            );
               -- 出力に表示
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               -- ログに表示
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.LOG
                 ,buff   => lv_errmsg
               );
               -- エラーフラグをYにする
               lv_err_flag      := cv_yes;
               -- 項目のエラーフラグをYにする
               lv_item_err_flag := cv_yes;
            END IF;
          END IF;
--
        END LOOP get_column_loop;
--
        -- 1行単位で各項目にエラーがない場合
        IF ( lv_item_err_flag = cv_no ) THEN
          --==============================================================
          --  M-2.7 出荷依頼更新アップロードワーク配列登録
          --==============================================================
          ln_data_cnt := ln_data_cnt + 1;
          gt_upload_work_tab(ln_data_cnt).line_number    := ln_data_cnt;
          gt_upload_work_tab(ln_data_cnt).request_no     := lt_check_data_tab(1);
          gt_upload_work_tab(ln_data_cnt).item_code      := lt_check_data_tab(2);
          gt_upload_work_tab(ln_data_cnt).conv_item_code := lt_check_data_tab(3);
          gt_upload_work_tab(ln_data_cnt).pallet_quantity:= lt_check_data_tab(4);
          gt_upload_work_tab(ln_data_cnt).layer_quantity := lt_check_data_tab(5);
          gt_upload_work_tab(ln_data_cnt).case_quantity  := lt_check_data_tab(6);
          gt_upload_work_tab(ln_data_cnt).request_id     := cn_request_id;
        END IF;
--
      END IF;
--
    END LOOP check_loop;
--
    -- 不要な配列をDELETE
    lt_check_data_tab.DELETE;
--
    -- 全データで1件もエラーがない場合
    IF ( lv_err_flag = cv_no ) THEN
      -- カウンタ初期化
      ln_data_cnt := cn_0;
      --==============================================================
      --  M-2.8 出荷依頼更新アップロードワーク登録
      --==============================================================
      BEGIN
        FORALL ln_data_cnt IN 1 .. gt_upload_work_tab.COUNT
          INSERT INTO xxwsh_order_upload_work VALUES gt_upload_work_tab(ln_data_cnt);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SQLERRM;
          RAISE ins_err_expt;
      END;
    -- 全データ1件でもエラーがある場合（ファイル内容不正）
    ELSE
      -- 警告終了とする。
      ov_retcode  := cv_status_warn;
      -- 対象件数＝スキップ件数とする
      gn_skip_cnt := gn_target_cnt;
    END IF;
--
    -- 不要な配列をDELETE
    gt_upload_work_tab.DELETE;
--
  EXCEPTION
    -- *** BLOBデータ変換エラー ***
    WHEN blob_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmn_10640            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(gn_file_id)
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 挿入エラー ***
    WHEN ins_err_expt THEN
      ov_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxwsh            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxwsh_13198            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_xxwsh_13230
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => lv_errmsg
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_request_data
   * Description      : 出荷依頼データ取得 (M-3)
   ***********************************************************************************/
  PROCEDURE get_ship_request_data(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_request_data'; -- プログラム名
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
    -- *** ローカルユーザー定義例外 ***
    data_skip_expt        EXCEPTION;   -- スキップデータ例外
--
    -- *** ローカル変数 ***
    lv_err_flag           VARCHAR2(1);    -- エラーフラグ
    lv_ret_code           VARCHAR2(1);    -- リターンコード(共通関数用)
    lv_err_code           VARCHAR2(20);   -- エラーメッセージコード(共通関数用)
    lv_err_msg            VARCHAR2(5000); -- エラーメッセージ(共通関数用)
    ln_result             NUMBER;         -- 処理結果(共通関数用)
    lv_exists             VARCHAR2(1);    -- データ存在確認用
    lv_error_token        VARCHAR2(20);   -- トークンメッセージ格納用
    ln_pallet_q_total     NUMBER;         -- パレットの総数
    ln_layer_q_total      NUMBER;         -- 段数の総数
    ln_line_case_q_total  NUMBER;         -- 明細のケース総数
    ln_line_q_total       NUMBER;         -- 明細の総数
    ln_max_case_of_pallet NUMBER;         -- パレット当り最大ケース数
    ln_pallet_quantity    NUMBER;         -- パレット数
    ln_surplus_of_pallet  NUMBER;         -- パレット数の余り
    ln_layer_quantity     NUMBER;         -- 段数
    ln_case_quantity      NUMBER;         -- ケース数
    ln_num_of_pallet      NUMBER;         -- パレット枚数
    ln_sum_weight         NUMBER;         -- 合計重量
    ln_sum_capacity       NUMBER;         -- 合計容積
    ln_sum_pallet_weight  NUMBER;         -- 合計パレット重量
    ln_ins_cnt            NUMBER := 0;    -- 更新用明細データ件数(配列用)
    ln_plan_item_cnt      NUMBER;         -- 計画商品件数
    lt_before_num_of_case xxcmn_item_mst2_v.num_of_cases%TYPE;  --変更前ケース入数
    ln_before_toral_qty   NUMBER;         -- 変更前の拠点依頼数量
--
    -- *** ローカル・カーソル ***
    -- ワークテーブル取得カーソル
    CURSOR get_work_cur
    IS
      SELECT  xwouw.line_number      line_number     -- 行No
             ,xwouw.request_no       request_no      -- 依頼No
             ,xwouw.item_code        item_code       -- 品目コード
             ,xwouw.conv_item_code   conv_item_code  -- 変更後品目コード
             ,xwouw.pallet_quantity  pallet_quantity -- パレット数
             ,xwouw.layer_quantity   layer_quantity  -- 段数
             ,xwouw.case_quantity    case_quantity   -- ケース数
      FROM    xxwsh_order_upload_work xwouw          -- 出荷依頼更新アップロードワークテーブル
      WHERE   xwouw.request_id = cn_request_id
      ORDER BY
              xwouw.request_no  --依頼No
      ;
--
    -- *** ローカル・レコード ***
    l_get_work_rec       get_work_cur%ROWTYPE;  -- カーソルデータレコード
    l_order_rec          g_order_rtype;         -- 出荷依頼データレコード
    l_order_init_rec     g_order_rtype;         -- 出荷依頼データレコード(初期化用)
    l_new_item_rec       g_new_item_rtype;      -- 変更後の品目データレコード
    l_new_item_init_rec  g_new_item_rtype;      -- 変更後の品目データレコード(初期化用)
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
    -- M-3.1 出荷依頼更新ワークテーブルデータ取得
    --==============================================================
    -- カーソルオープン
    OPEN get_work_cur;
    <<work_data_loop>>
    LOOP
--
      -- 初期化
      lv_err_flag           := cv_no;                -- エラーフラグ
      lv_ret_code           := cv_status_normal;     -- リターンコード(共通関数用)
      lv_err_code           := NULL;                 -- エラーメッセージコード(共通関数用)
      l_order_rec           := l_order_init_rec;     -- 出荷依頼データ
      l_new_item_rec        := l_new_item_init_rec;  -- 変更後の品目データ
      ln_pallet_q_total     := 0;                    -- パレットの総数
      ln_layer_q_total      := 0;                    -- 段数の総数
      ln_line_case_q_total  := 0;                    -- 明細のケース総数
      ln_line_q_total       := 0;                    -- 明細の総数
      ln_max_case_of_pallet := 0;                    -- パレット当り最大ケース数
      ln_pallet_quantity    := 0;                    -- パレット数
      ln_surplus_of_pallet  := 0;                    -- パレット数の余り
      ln_layer_quantity     := 0;                    -- 段数
      ln_case_quantity      := 0;                    -- ケース数
      ln_num_of_pallet      := 0;                    -- パレット枚数
      ln_sum_weight         := 0;                    -- 合計重量
      ln_sum_capacity       := 0;                    -- 合計容積
      ln_sum_pallet_weight  := 0;                    -- 合計パレット重量
      ln_before_toral_qty   := 0;                    -- 拠点依頼数量
--
      FETCH get_work_cur INTO l_get_work_rec;
      EXIT WHEN get_work_cur%NOTFOUND;
--
      BEGIN
        --==============================================================
        -- M-3.2-1 出荷依頼データ取得
        --==============================================================
        BEGIN
          SELECT  xott.transaction_type_name      transaction_type_name     -- 取引タイプ名
                 ,NVL( xlvv1.attribute1, cv_no )  status                    -- ステータス
                 ,NVL( xlvv2.attribute1, cv_no )  notif_status              -- 通知ステータス
                 ,xoha.order_header_id            order_header_id           -- 受注ヘッダアドオンID
                 ,xoha.request_no                 request_no                -- 依頼No
                 ,xoha.weight_capacity_class      weight_capacity_class     -- 重量容積区分
                 ,xoha.freight_charge_class       freight_charge_class      -- 賃区分運
                 ,xoha.schedule_ship_date         schedule_ship_date        -- 出荷予定日
                 ,xoha.schedule_arrival_date      schedule_arrival_date     -- 着荷予定日
                 ,xoha.based_weight               based_weight              -- 基本重量
                 ,xoha.mixed_no                   mixed_no                  -- 混載元No
                 ,xoha.head_sales_branch          head_sales_branch         -- 管轄拠点
                 ,xoha.deliver_to                 deliver_to                -- 出荷先
                 ,xoha.deliver_from               deliver_from              -- 出荷元保管場所
                 ,xoha.deliver_from_id            deliver_from_id           -- 出荷元ID
                 ,xola.rowid                      xola_rowid                -- ROWID
                 ,xola.order_line_id              order_line_id             -- 受注明細アドオンID
                 ,xola.automanual_reserve_class   automanual_reserve_class  -- 自動手動引当区分
                 ,xola.request_item_code          request_item_code         -- 依頼品目
                 ,xola.pallet_quantity            pallet_quantity           -- パレット数
                 ,xola.layer_quantity             layer_quantity            -- 段数
                 ,xola.case_quantity              case_quantity             -- ケース数
                 ,xola.shipped_quantity           shipped_quantity          -- 出荷実績数量
                 ,xola.based_request_quantity     based_request_quantity    -- 拠点依頼数量
          INTO    l_order_rec.transaction_type_name
                 ,l_order_rec.status
                 ,l_order_rec.notif_status
                 ,l_order_rec.order_header_id
                 ,l_order_rec.request_no
                 ,l_order_rec.weight_capacity_class
                 ,l_order_rec.freight_charge_class
                 ,l_order_rec.schedule_ship_date
                 ,l_order_rec.schedule_arrival_date
                 ,l_order_rec.based_weight
                 ,l_order_rec.mixed_no
                 ,l_order_rec.head_sales_branch
                 ,l_order_rec.deliver_to
                 ,l_order_rec.deliver_from
                 ,l_order_rec.deliver_from_id
                 ,l_order_rec.xola_rowid
                 ,l_order_rec.order_line_id
                 ,l_order_rec.automanual_reserve_class
                 ,l_order_rec.request_item_code
                 ,l_order_rec.pallet_quantity
                 ,l_order_rec.layer_quantity
                 ,l_order_rec.case_quantity
                 ,l_order_rec.shipped_quantity
                 ,l_order_rec.based_request_quantity
          FROM    xxwsh_order_headers_all      xoha  -- 受注ヘッダアドオン
                 ,xxwsh_order_lines_all        xola  -- 受注明細アドオン
                 ,xxwsh_oe_transaction_types_v xott  -- 受注タイプ情報VIEW
                 ,xxcmn_lookup_values2_v       xlvv1 -- クイックコード情報VIEW2①
                 ,xxcmn_lookup_values2_v       xlvv2 -- クイックコード情報VIEW2②
          WHERE   xoha.request_no                = l_get_work_rec.request_no
          AND     xoha.latest_external_flag      = cv_yes
          AND     xoha.order_header_id           = xola.order_header_id
          AND     xoha.order_type_id             = xott.transaction_type_id
          AND     xola.request_item_code         = l_get_work_rec.item_code
          AND     NVL( xola.delete_flag, cv_no ) = cv_no
          AND     xlvv1.lookup_type              = cv_lookup_t_status
          AND     xlvv1.lookup_code              = xoha.req_status
          AND     xlvv2.lookup_type              = cv_lookup_n_status
          AND     xlvv2.lookup_code              = xoha.notif_status
          ;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13199          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no           -- トークンコード1
                       ,iv_token_value1  =>  l_get_work_rec.request_no   -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_item_code            -- トークンコード2
                       ,iv_token_value2  =>  l_get_work_rec.item_code    -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_input_line_no        -- トークンコード3
                       ,iv_token_value3  =>  l_get_work_rec.line_number  -- トークン値3
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ
          RAISE data_skip_expt;
        END;
--
        --==============================================================
        -- M-3.2-2 任意項目のデータ設定
        --==============================================================
        -- 変更後品目がNULLの場合
        IF ( l_get_work_rec.conv_item_code IS NULL ) THEN
          -- 出荷依頼の依頼品目とする（品目の変更なし）
          l_get_work_rec.conv_item_code  := l_order_rec.request_item_code;
        END IF;
        -- パレット数がNULLの場合
        IF ( l_get_work_rec.pallet_quantity IS NULL ) THEN
          -- 出荷依頼のパレット数とする（パレット数の変更なし）
          l_get_work_rec.pallet_quantity := l_order_rec.pallet_quantity;
        END IF;
        -- 段数がNULLの場合
        IF ( l_get_work_rec.layer_quantity IS NULL ) THEN
          -- 出荷依頼の段数とする（段数の変更なし）
          l_get_work_rec.layer_quantity  := l_order_rec.layer_quantity;
        END IF;
        -- ケース数がNULLの場合
        IF ( l_get_work_rec.case_quantity IS NULL ) THEN
          -- 出荷依頼のケースとする（ケース数の変更なし）
          l_get_work_rec.case_quantity   := l_order_rec.case_quantity;
        END IF;
--
        --==============================================================
        -- M-3.3 妥当性チェック
        --==============================================================
--
        -- 3-1.OPM在庫会計期間のチェック
        IF ( gv_opm_close_period >= TO_CHAR( l_order_rec.schedule_ship_date, cv_yyyymm ) ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                    -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13238                                    -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no                                     -- トークンコード1
                       ,iv_token_value1  =>  l_order_rec.request_no                                -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_ship_date                                      -- トークンコード2
                       ,iv_token_value2  =>  TO_CHAR( l_order_rec.schedule_ship_date, cv_yyyymm )  -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_input_line_no                                  -- トークンコード3
                       ,iv_token_value3  =>  l_get_work_rec.line_number                            -- トークン値3
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立て、以降のチェックも実施
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-2.取引タイプのチェック
        BEGIN
          SELECT cv_yes    data_exists
          INTO   lv_exists
          FROM   xxcmn_lookup_values2_v xlvv
          WHERE  xlvv.lookup_type = cv_lookup_process_upload
          AND    xlvv.meaning     = l_order_rec.transaction_type_name
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13200          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no           -- トークンコード1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- トークンコード2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- トークン値2
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立て、以降のチェックも実施
          lv_err_flag := cv_yes;
        END;
--
        -- 3-3.ステータスのチェック
        IF ( l_order_rec.status <> cv_yes ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13201          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no           -- トークンコード1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- トークンコード2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- トークン値2
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立て、以降のチェックも実施
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-4.通知ステータスのチェック
        IF ( l_order_rec.notif_status <> cv_yes ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13202          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no           -- トークンコード1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- トークンコード2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- トークン値2
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立て、以降のチェックも実施
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-5.重量容積区分のチェック
        IF ( l_order_rec.weight_capacity_class <> cv_weight ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13203          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no           -- トークンコード1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- トークンコード2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- トークン値2
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立て、以降のチェックも実施
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-6.手動引当済みでないことのチェック
        IF ( l_order_rec.automanual_reserve_class = cv_manual ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13204          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no           -- トークンコード1
                       ,iv_token_value1  =>  l_order_rec.request_no      -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_line_no        -- トークンコード2
                       ,iv_token_value2  =>  l_get_work_rec.line_number  -- トークン値2
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立て、以降のチェックも実施
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-7.変更前の値と変更後の値が同一でないことをチェック
        IF (
              ( l_get_work_rec.conv_item_code  = l_order_rec.request_item_code )
              AND
              ( l_get_work_rec.pallet_quantity = l_order_rec.pallet_quantity )
              AND
              ( l_get_work_rec.layer_quantity  = l_order_rec.layer_quantity )
              AND
              ( l_get_work_rec.case_quantity   = l_order_rec.case_quantity )
            ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                         -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13205                         -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no                          -- トークンコード1
                       ,iv_token_value1  =>  l_order_rec.request_no                     -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_item_code                           -- トークンコード2
                       ,iv_token_value2  =>  l_get_work_rec.item_code                   -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_pallet_q                            -- トークンコード3
                       ,iv_token_value3  =>  TO_CHAR( l_get_work_rec.pallet_quantity )  -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_layer_q                             -- トークンコード4
                       ,iv_token_value4  =>  TO_CHAR( l_get_work_rec.layer_quantity )   -- トークン値5
                       ,iv_token_name5   =>  cv_tkn_case_q                              -- トークンコード4
                       ,iv_token_value5  =>  TO_CHAR( l_get_work_rec.case_quantity )    -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_input_line_no                       -- トークンコード6
                       ,iv_token_value6  =>  l_get_work_rec.line_number                 -- トークン値6
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立て、以降のチェックも実施
          lv_err_flag := cv_yes;
        END IF;
--
        -- 3-8.更新前の品目のチェック
        BEGIN
          SELECT  ximv.num_of_cases num_of_cases
          INTO    lt_before_num_of_case
          FROM    xxcmn_item_mst2_v        ximv
                 ,xxcmn_item_categories2_v xicv1
                 ,xxcmn_item_categories2_v xicv2
          WHERE   ximv.item_no                = l_order_rec.request_item_code
          AND     ximv.start_date_active     <= cd_sysdate
          AND     ximv.end_date_active       >= cd_sysdate
          AND     ximv.ship_class             = cv_ship_class_1       -- 出荷区分    ：出荷可
          AND     ximv.obsolete_class         = cv_obsolete_class_0   -- 廃止区分    ：廃止されていない
          AND     ximv.rate_class             = cv_rate_class_0       -- 率区分      ：標準原価
          AND     ximv.weight_capacity_class  = cv_weight             -- 重量容積区分：重量
          AND     (
                     (
                       ( ximv.item_id    = ximv.parent_item_id )
                       AND
                       ( ximv.sales_div  = cv_sales_div_1 )
                     )
                     OR
                     (
                       ( ximv.item_id   <> ximv.parent_item_id )
                     )
                  )                                                   -- 親品目で売上対象か子品目
          AND     ximv.item_id                = xicv1.item_id
          AND     xicv1.category_set_name     = gv_item_div_name      -- 品目区分
          AND     xicv1.segment1              = cv_item_div_5         -- 品目区分    ：製品
          AND     ximv.item_id                = xicv2.item_id
          AND     xicv2.category_set_name     = gv_product_div_name   -- 商品区分
          AND     xicv2.segment1              = cv_product_div_2      -- 商品区分    ：ドリンク
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- メッセージ編集
            lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh              -- アプリケーション短縮名
                         ,iv_name          =>  cv_msg_xxwsh_13206              -- メッセージコード
                         ,iv_token_name1   =>  cv_tkn_request_no               -- トークンコード1
                         ,iv_token_value1  =>  l_order_rec.request_no          -- トークン値1
                         ,iv_token_name2   =>  cv_tkn_item_code                -- トークンコード2
                         ,iv_token_value2  =>  l_order_rec.request_item_code   -- トークン値2
                         ,iv_token_name3   =>  cv_tkn_input_line_no            -- トークンコード3
                         ,iv_token_value3  =>  l_get_work_rec.line_number      -- トークン値3
                        );
            -- 出力に表示
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- ログに表示
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_errmsg
            );
            -- エラーフラグを立て、以降のチェックも実施
            lv_err_flag := cv_yes;
        END;
--
        -- 3-9.更新後の品目のチェック
        BEGIN
          SELECT  ximv.item_id            item_id             -- 品目ID
                 ,ximv.parent_item_id     parent_item_id      -- 親品目ID
                 ,ximv.inventory_item_id  inventory_item_id   -- INV品目ID
                 ,ximv.item_no            item_no             -- 品目コード
                 ,ximv.conv_unit          conv_unit           -- 入出庫換算単位
                 ,ximv.num_of_cases       num_of_cases        -- ケース入数
                 ,ximv.max_palette_steps  max_palette_steps   -- パレット当り最大段数
                 ,ximv.delivery_qty       delivery_qty        -- 配数
                 ,ximv.item_um            item_um             -- 単位
                 ,ximv.num_of_deliver     num_of_deliver      -- 出荷入数
          INTO    l_new_item_rec.item_id                      -- 品目ID
                 ,l_new_item_rec.parent_item_id               -- 親品目ID
                 ,l_new_item_rec.inventory_item_id            -- INV品目ID
                 ,l_new_item_rec.item_no                      -- 品目コード
                 ,l_new_item_rec.conv_unit                    -- 入出庫換算単位
                 ,l_new_item_rec.num_of_cases                 -- ケース入数
                 ,l_new_item_rec.max_palette_steps            -- パレット当り最大段数
                 ,l_new_item_rec.delivery_qty                 -- 配数
                 ,l_new_item_rec.item_um                      -- 単位
                 ,l_new_item_rec.num_of_deliver               -- 出荷入数
          FROM    xxcmn_item_mst2_v        ximv
                 ,xxcmn_item_categories2_v xicv1
                 ,xxcmn_item_categories2_v xicv2
          WHERE   ximv.item_no                = l_get_work_rec.conv_item_code
          AND     ximv.start_date_active     <= cd_sysdate
          AND     ximv.end_date_active       >= cd_sysdate
          AND     ximv.ship_class             = cv_ship_class_1       -- 出荷区分    ：出荷可
          AND     ximv.obsolete_class         = cv_obsolete_class_0   -- 廃止区分    ：廃止されていない
          AND     ximv.rate_class             = cv_rate_class_0       -- 率区分      ：標準原価
          AND     ximv.weight_capacity_class  = cv_weight             -- 重量容積区分：重量
          AND     (
                     (
                       ( ximv.item_id    = ximv.parent_item_id )
                       AND
                       ( ximv.sales_div  = cv_sales_div_1 )
                     )
                     OR
                     (
                       ( ximv.item_id   <> ximv.parent_item_id )
                     )
                  )                                                   -- 親品目で売上対象か子品目
          AND     ximv.item_id                = xicv1.item_id
          AND     xicv1.category_set_name     = gv_item_div_name      -- 品目区分
          AND     xicv1.segment1              = cv_item_div_5         -- 品目区分    ：製品
          AND     ximv.item_id                = xicv2.item_id
          AND     xicv2.category_set_name     = gv_product_div_name   -- 商品区分
          AND     xicv2.segment1              = cv_product_div_2      -- 商品区分    ：ドリンク
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- メッセージ編集
            lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh              -- アプリケーション短縮名
                         ,iv_name          =>  cv_msg_xxwsh_13207              -- メッセージコード
                         ,iv_token_name1   =>  cv_tkn_request_no               -- トークンコード1
                         ,iv_token_value1  =>  l_order_rec.request_no          -- トークン値1
                         ,iv_token_name2   =>  cv_tkn_item_code                -- トークンコード2
                         ,iv_token_value2  =>  l_get_work_rec.conv_item_code   -- トークン値2
                         ,iv_token_name3   =>  cv_tkn_input_line_no            -- トークンコード3
                         ,iv_token_value3  =>  l_get_work_rec.line_number      -- トークン値3
                        );
            -- 出力に表示
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- ログに表示
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_errmsg
            );
            -- 当チェック以降のエラーはデータスキップ例外とする
          RAISE data_skip_expt;
        END;
--
        --------------------------------------
        -- 3-10.変換後品目の妥当性チェック
        --------------------------------------
--
        -- 3-10-1.入出庫換算単位のNULLチェック
        IF ( l_new_item_rec.conv_unit IS NULL ) THEN
          -- トークン文言取得
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- アプリケーション短縮名
                             ,iv_name          =>  cv_msg_xxwsh_13244  -- メッセージコード
                            );
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh             -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13208             -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_column                  -- トークンコード1
                       ,iv_token_value1  =>  lv_error_token                 -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no              -- トークンコード2
                       ,iv_token_value2  =>  l_order_rec.request_no         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code               -- トークンコード3
                       ,iv_token_value3  =>  l_new_item_rec.item_no         -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_input_line_no           -- トークンコード4
                       ,iv_token_value4  =>  l_get_work_rec.line_number     -- トークン値4
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ例外とする
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-2.ケース入数のNULL、0チェック
        IF ( NVL( l_new_item_rec.num_of_cases, cn_0 ) = cn_0 ) THEN
          -- トークン文言取得
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- アプリケーション短縮名
                             ,iv_name          =>  cv_msg_xxwsh_13245  -- メッセージコード
                            );
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh             -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13208             -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_column                  -- トークンコード1
                       ,iv_token_value1  =>  lv_error_token                 -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no              -- トークンコード2
                       ,iv_token_value2  =>  l_order_rec.request_no         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code               -- トークンコード3
                       ,iv_token_value3  =>  l_new_item_rec.item_no         -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_input_line_no           -- トークンコード4
                       ,iv_token_value4  =>  l_get_work_rec.line_number     -- トークン値4
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ例外とする
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-3.パレット当り最大段数のNULL、0チェック
        IF ( NVL( l_new_item_rec.max_palette_steps, cn_0 ) = cn_0 ) THEN
          -- トークン文言取得
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- アプリケーション短縮名
                             ,iv_name          =>  cv_msg_xxwsh_13246  -- メッセージコード
                            );
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh             -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13208             -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_column                  -- トークンコード1
                       ,iv_token_value1  =>  lv_error_token                 -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no              -- トークンコード2
                       ,iv_token_value2  =>  l_order_rec.request_no         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code               -- トークンコード3
                       ,iv_token_value3  =>  l_new_item_rec.item_no         -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_input_line_no           -- トークンコード4
                       ,iv_token_value4  =>  l_get_work_rec.line_number     -- トークン値4
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ例外とする
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-4.配数のNULL、0チェック
        IF ( NVL( l_new_item_rec.delivery_qty, cn_0 ) = cn_0 ) THEN
          -- トークン文言取得
          lv_error_token := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxwsh  -- アプリケーション短縮名
                             ,iv_name          =>  cv_msg_xxwsh_13247  -- メッセージコード
                            );
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh           -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13208           -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_column                -- トークンコード1
                       ,iv_token_value1  =>  lv_error_token               -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no            -- トークンコード2
                       ,iv_token_value2  =>  l_order_rec.request_no       -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code             -- トークンコード3
                       ,iv_token_value3  =>  l_new_item_rec.item_no       -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_input_line_no         -- トークンコード4
                       ,iv_token_value4  =>  l_get_work_rec.line_number   -- トークン値4
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ例外とする
          RAISE data_skip_expt;
        END IF;
--
        -- 3-10-5.INV品目（営業側の品目）の対象チェック
        BEGIN
          SELECT  cv_yes  data_exisits
          INTO    lv_exists
          FROM    mtl_system_items_b  msib
          WHERE   msib.inventory_item_id              =  l_new_item_rec.inventory_item_id
          AND     msib.organization_id                =  gn_inv_org_id
          AND     msib.inventory_item_status_code     <> cv_inactive
          AND     msib.customer_order_enabled_flag    =  cv_yes  -- 顧客受注可能：Y
          AND     msib.mtl_transactions_enabled_flag  =  cv_yes  -- 取引可能    ：Y
          AND     msib.stock_enabled_flag             =  cv_yes  -- 在庫保有可能：Y
          AND     msib.returnable_flag                =  cv_yes  -- 返品可能    ：Y
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- メッセージ編集
            lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh           -- アプリケーション短縮名
                         ,iv_name          =>  cv_msg_xxwsh_13209           -- メッセージコード
                         ,iv_token_name1   =>  cv_tkn_request_no            -- トークンコード2
                         ,iv_token_value1  =>  l_order_rec.request_no       -- トークン値2
                         ,iv_token_name2   =>  cv_tkn_item_code             -- トークンコード3
                         ,iv_token_value2  =>  l_new_item_rec.item_no       -- トークン値3
                         ,iv_token_name3   =>  cv_tkn_input_line_no         -- トークンコード4
                         ,iv_token_value3  =>  l_get_work_rec.line_number   -- トークン値4
                        );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ例外とする
          RAISE data_skip_expt;
        END;
--
        -- 3-10-6.子品目・資材以外の場合の親品目の売上対象区分チェック(親品目の場合は3-9でチェック)
        IF (
             ( l_new_item_rec.item_id <> l_new_item_rec.parent_item_id )
             AND
             ( SUBSTRB( l_new_item_rec.item_no, 1, 1 ) NOT IN ( cv_item_code_5, cv_item_code_6 ) )
           ) THEN
          BEGIN
            SELECT  cv_yes  data_exisits
            INTO    lv_exists
            FROM    mtl_system_items_b  msib
                  , ic_item_mst_b       iimb_c
                  , ic_item_mst_b       iimb_p
                  , xxcmn_item_mst_b    ximb
            WHERE   msib.inventory_item_id  =       l_new_item_rec.inventory_item_id
            AND     msib.organization_id    =       gn_inv_org_id
            AND     msib.segment1           =       iimb_c.item_no
            AND     iimb_c.item_id          =       ximb.item_id
            AND     ximb.parent_item_id     =       iimb_p.item_id
            AND     iimb_p.attribute26      =       cv_sales_div_1
            AND     l_order_rec.schedule_arrival_date  BETWEEN ximb.start_date_active
                                                       AND     NVL(ximb.end_date_active, l_order_rec.schedule_arrival_date)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- メッセージ編集
              lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh           -- アプリケーション短縮名
                           ,iv_name          =>  cv_msg_xxwsh_13210           -- メッセージコード
                           ,iv_token_name1   =>  cv_tkn_request_no            -- トークンコード2
                           ,iv_token_value1  =>  l_order_rec.request_no       -- トークン値2
                           ,iv_token_name2   =>  cv_tkn_item_code             -- トークンコード3
                           ,iv_token_value2  =>  l_new_item_rec.item_no       -- トークン値3
                           ,iv_token_name3   =>  cv_tkn_input_line_no         -- トークンコード4
                           ,iv_token_value3  =>  l_get_work_rec.line_number   -- トークン値4
                          );
              -- 出力に表示
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              -- ログに表示
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
              -- データスキップ例外とする
              RAISE data_skip_expt;
          END;
        END IF;
--
        --==============================================================
        -- M-3.4 総数の計算
        --==============================================================
--
        -- 4-1.パレットの総数を取得(パレット数×配数×パレット当り最大段数)
        ln_pallet_q_total    := l_get_work_rec.pallet_quantity * l_new_item_rec.delivery_qty * l_new_item_rec.max_palette_steps;
--
        -- 4-2.段数の総数を取得(段数×配数)
        ln_layer_q_total     := l_get_work_rec.layer_quantity * l_new_item_rec.delivery_qty;
--
        -- 4-3.総数(ケース単位)を取得
        ln_line_case_q_total := ( ln_pallet_q_total + ln_layer_q_total + l_get_work_rec.case_quantity );
--
        -- 4-4.数量(明細)を取得(総数(ケース単位) ×ケース入数)
        ln_line_q_total      := ln_line_case_q_total * l_new_item_rec.num_of_cases;
--
        --==============================================================
        -- M-3.5 総数が出荷入数の正数倍かチェック(出荷入数がある場合のみ)
        --==============================================================
        IF ( l_new_item_rec.num_of_deliver IS NOT NULL ) THEN
          IF ( MOD( ln_line_q_total, l_new_item_rec.num_of_deliver ) <> cn_0 ) THEN
             -- メッセージ編集
             lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxwsh                        -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxwsh_13211                        -- メッセージコード
                          ,iv_token_name1   =>  cv_tkn_quantity                           -- トークンコード1
                          ,iv_token_value1  =>  TO_CHAR( ln_line_q_total )                -- トークン値1
                          ,iv_token_name2   =>  cv_tkn_num_of_deliver                     -- トークンコード2
                          ,iv_token_value2  =>  TO_CHAR( l_new_item_rec.num_of_deliver )  -- トークン値2
                          ,iv_token_name3   =>  cv_tkn_request_no                         -- トークンコード3
                          ,iv_token_value3  =>  l_order_rec.request_no                    -- トークン値3
                          ,iv_token_name4   =>  cv_tkn_item_code                          -- トークンコード4
                          ,iv_token_value4  =>  l_new_item_rec.item_no                    -- トークン値4
                          ,iv_token_name5   =>  cv_tkn_input_line_no                      -- トークンコード5
                          ,iv_token_value5  =>  l_get_work_rec.line_number                -- トークン値5
                         );
              -- 出力に表示
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              -- ログに表示
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
              -- データスキップ例外とする
              RAISE data_skip_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- M-3.6 パレット数・段数・ケース数の再計算
        --==============================================================
--
        -- 6-1.パレット当たりの最大ケース数(配数×パレット当り最大段数)
        ln_max_case_of_pallet := l_new_item_rec.delivery_qty * l_new_item_rec.max_palette_steps;
--
        -- 6-2.パレット数の取得
        IF ( ln_max_case_of_pallet <> cn_0 ) THEN
          -- パレット数(総数(ケース単位)÷パレット当り最大ケース数)
          ln_pallet_quantity    := TRUNC( ln_line_case_q_total / ln_max_case_of_pallet );
        ELSE
          -- パレット当たりの最大ケース数が0の場合はパレット数も0
          ln_pallet_quantity    := cn_0;  --パレット
        END IF;
        -- 再計算の結果パレット数が3桁を超える場合エラー
        IF ( LENGTHB( TO_CHAR( ln_pallet_quantity ) ) > 3 ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxwsh              -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxwsh_13212              -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_request_no               -- トークンコード1
                        ,iv_token_value1  =>  l_order_rec.request_no          -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_item_code                -- トークンコード2
                        ,iv_token_value2  =>  l_new_item_rec.item_no          -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_pallet_q                 -- トークンコード3
                        ,iv_token_value3  =>  TO_CHAR( ln_pallet_quantity )   -- トークン値3
                        ,iv_token_name4   =>  cv_tkn_input_line_no            -- トークンコード4
                        ,iv_token_value4  =>  l_get_work_rec.line_number      -- トークン値4
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ例外とする
          RAISE data_skip_expt;
        END IF;
--
        -- 6-3.段数の取得(パレット数の余り※1÷配数)
        ln_surplus_of_pallet := MOD( ln_line_case_q_total, ln_max_case_of_pallet ); --※1
        ln_layer_quantity    := TRUNC( ln_surplus_of_pallet / l_new_item_rec.delivery_qty);
--
        -- 6-4.ケース数の取得(パレット数の余りを配数で割った余り)
        ln_case_quantity     := MOD( ln_surplus_of_pallet, l_new_item_rec.delivery_qty );
--
        -- 6-5.パレット枚数の取得
        IF ( ln_surplus_of_pallet <> cn_0 ) THEN
          -- パレット枚数＋1（端数分のパレット）
          ln_num_of_pallet := ln_pallet_quantity + 1;
        ELSE
          ln_num_of_pallet := ln_pallet_quantity;
        END IF;
--
        -- 6-6.拠点依頼数量の再計算（変更前の拠点依頼数量÷変更前の品目のケース入数×変更後の品目のケース入数）
        ln_before_toral_qty := ( l_order_rec.based_request_quantity / lt_before_num_of_case ) * l_new_item_rec.num_of_cases;
--
        --==============================================================
        -- M-3.7 重量の再計算
        --==============================================================
--
        -- 共通関数「積載効率チェック(合計値算出)」により取得
        xxwsh_common910_pkg.calc_total_value(
           iv_item_no            =>  l_new_item_rec.item_no          -- 品目コード
          ,in_quantity           =>  ln_line_q_total                 -- 明細の総数
          ,ov_retcode            =>  lv_ret_code                     -- リターンコード
          ,ov_errmsg_code        =>  lv_err_code                     -- エラーメッセージコード
          ,ov_errmsg             =>  lv_err_msg                      -- エラーメッセージ
          ,on_sum_weight         =>  ln_sum_weight                   -- 合計重量
          ,on_sum_capacity       =>  ln_sum_capacity                 -- 合計容積
          ,on_sum_pallet_weight  =>  ln_sum_pallet_weight            -- 合計パレット重量
          ,id_standard_date      =>  l_order_rec.schedule_ship_date  -- 出荷予定日
        );
        -- リターンコードが正常でない場合
        IF ( lv_ret_code <> cv_status_normal ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13213                                          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no                                           -- トークンコード1
                       ,iv_token_value1  =>  l_get_work_rec.request_no                                   -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_ship_date                                            -- トークンコード2
                       ,iv_token_value2  =>  TO_CHAR( l_order_rec.schedule_ship_date, cv_yyyymmdd_sla )  -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code                                            -- トークンコード3
                       ,iv_token_value3  =>  l_new_item_rec.item_no                                      -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_quantity                                             -- トークンコード4
                       ,iv_token_value4  =>  TO_CHAR( ln_line_q_total )                                  -- トークン値4
                       ,iv_token_name5   =>  cv_tkn_input_line_no                                        -- トークンコード5
                       ,iv_token_value5  =>  l_get_work_rec.line_number                                  -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_err_msg                                              -- トークンコード6
                       ,iv_token_value6  =>  lv_err_msg                                                  -- トークン値6
                      );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- データスキップ例外とする
          RAISE data_skip_expt;
        END IF;
--
        --==============================================================
        -- M-3.8 明細更新用の配列に値を設定
        --==============================================================
--
        -- チェックでエラーがない場合
        IF ( lv_err_flag = cv_no ) THEN
          ln_ins_cnt := ln_ins_cnt + 1;
          gt_ship_line_data_tab(ln_ins_cnt).line_number                 :=  l_get_work_rec.line_number;              -- 行No
          gt_ship_line_data_tab(ln_ins_cnt).automanual_reserve_class    :=  l_order_rec.automanual_reserve_class;    -- 自動手動引当区分
          gt_ship_line_data_tab(ln_ins_cnt).order_header_id             :=  l_order_rec.order_header_id;             -- 受注ヘッダアドオンID
          gt_ship_line_data_tab(ln_ins_cnt).request_no                  :=  l_order_rec.request_no;                  -- 依頼No
          gt_ship_line_data_tab(ln_ins_cnt).mixed_no                    :=  l_order_rec.mixed_no;                    -- 混載元No
          gt_ship_line_data_tab(ln_ins_cnt).head_sales_branch           :=  l_order_rec.head_sales_branch;           -- 管轄拠点
          gt_ship_line_data_tab(ln_ins_cnt).deliver_to                  :=  l_order_rec.deliver_to;                  -- 出荷先
          gt_ship_line_data_tab(ln_ins_cnt).deliver_from                :=  l_order_rec.deliver_from;                -- 出荷元保管場所
          gt_ship_line_data_tab(ln_ins_cnt).deliver_from_id             :=  l_order_rec.deliver_from_id;             -- 出荷元ID
          gt_ship_line_data_tab(ln_ins_cnt).schedule_ship_date          :=  l_order_rec.schedule_ship_date;          -- 出庫予定日
          gt_ship_line_data_tab(ln_ins_cnt).schedule_arrival_date       :=  l_order_rec.schedule_arrival_date;       -- 着荷予定日
          gt_ship_line_data_tab(ln_ins_cnt).xola_rowid                  :=  l_order_rec.xola_rowid;                  -- 明細ROWID
          gt_ship_line_data_tab(ln_ins_cnt).order_line_id               :=  l_order_rec.order_line_id;               -- 受注明細アドオンID
          gt_ship_line_data_tab(ln_ins_cnt).shipping_inventory_item_id  :=  l_new_item_rec.inventory_item_id;        -- 出荷品目ID
          gt_ship_line_data_tab(ln_ins_cnt).shipping_item_code          :=  l_new_item_rec.item_no;                  -- 出荷品目
          gt_ship_line_data_tab(ln_ins_cnt).quantity                    :=  ln_line_q_total;                         -- 数量
          gt_ship_line_data_tab(ln_ins_cnt).uom_code                    :=  l_new_item_rec.item_um;                  -- 単位
          gt_ship_line_data_tab(ln_ins_cnt).shipped_quantity            :=  ( l_order_rec.shipped_quantity
                                                                              * l_new_item_rec.num_of_cases );       -- 出荷実績数量
          gt_ship_line_data_tab(ln_ins_cnt).based_request_quantity      :=  ln_before_toral_qty;                     -- 拠点実績数量
          gt_ship_line_data_tab(ln_ins_cnt).request_item_id             :=  l_new_item_rec.inventory_item_id;        -- 依頼品目ID
          gt_ship_line_data_tab(ln_ins_cnt).request_item_code           :=  l_new_item_rec.item_no;                  -- 依頼品目
          gt_ship_line_data_tab(ln_ins_cnt).po_number                   :=  NULL;                                    -- 発注NO
          gt_ship_line_data_tab(ln_ins_cnt).pallet_quantity             :=  ln_pallet_quantity;                      -- パレット数
          gt_ship_line_data_tab(ln_ins_cnt).layer_quantity              :=  ln_layer_quantity;                       -- 段数
          gt_ship_line_data_tab(ln_ins_cnt).case_quantity               :=  ln_case_quantity;                        -- ケース数
          gt_ship_line_data_tab(ln_ins_cnt).weight                      :=  ln_sum_weight;                           -- 重量
          gt_ship_line_data_tab(ln_ins_cnt).capacity                    :=  ln_sum_capacity;                         -- 容積
          gt_ship_line_data_tab(ln_ins_cnt).pallet_weight               :=  ln_sum_pallet_weight;                    -- パレット重量
          gt_ship_line_data_tab(ln_ins_cnt).pallet_qty                  :=  ln_num_of_pallet;                        -- パレット枚数
          gt_ship_line_data_tab(ln_ins_cnt).shipping_request_if_flg     :=  cv_no;                                   -- 出荷依頼インタフェース済フラグ
          gt_ship_line_data_tab(ln_ins_cnt).shipping_result_if_flg      :=  cv_no;                                   -- 出荷実績インタフェース済フラグ
          gt_ship_line_data_tab(ln_ins_cnt).last_updated_by             :=  cn_last_updated_by;                      -- 最終更新者
          gt_ship_line_data_tab(ln_ins_cnt).last_update_date            :=  cd_last_update_date;                     -- 最終更新日
          gt_ship_line_data_tab(ln_ins_cnt).last_update_login           :=  cn_last_update_login;                    -- 最終更新ログイン
          gt_ship_line_data_tab(ln_ins_cnt).request_id                  :=  cn_request_id;                           -- 要求ID
          gt_ship_line_data_tab(ln_ins_cnt).program_application_id      :=  cn_program_application_id;               -- コンカレント・プログラム・アプリケーションID
          gt_ship_line_data_tab(ln_ins_cnt).program_id                  :=  cn_program_id;                           -- コンカレント・プログラムID
          gt_ship_line_data_tab(ln_ins_cnt).program_update_date         :=  cd_program_update_date;                  -- プログラム更新日
        ELSE
           -- スキップ件数カウント
          gn_skip_cnt := gn_skip_cnt + 1;
          -- 1件でもスキップデータがある場合は警告とする
          ov_retcode  := cv_status_warn;
        END IF;
--
      EXCEPTION
        -- データスキップ例外
        WHEN data_skip_expt THEN
          -- スキップ件数カウント
          gn_skip_cnt := gn_skip_cnt + 1;
          -- 1件でもスキップデータがある場合は警告とする
          ov_retcode  := cv_status_warn;
        END;
--
    END LOOP work_data_loop;
--
    -- カーソルクローズ
    CLOSE get_work_cur;
--
    -- 初期化
    lv_err_flag := cv_no;
--
    --==============================================================
    -- M-3.9 物流担当用の妥当性チェック（メッセージ出力のみ）
    --==============================================================
    <<chk_emp_of_logi>>
    FOR i IN 1..gt_ship_line_data_tab.COUNT LOOP
--
      -- 初期化
      lv_ret_code      := cv_status_normal;
      lv_err_code      := NULL;
      lv_err_msg       := NULL;
      ln_result        := NULL;
      ln_plan_item_cnt := 0;
--
      -- 9-1.共通関数「物流構成アドオンのチェック」により物流構成の存在チェック
      lv_ret_code := xxwsh_common_pkg.chk_sourcing_rules(
                        it_item_code          =>  gt_ship_line_data_tab(i).shipping_item_code  -- 出荷品目
                       ,it_base_code          =>  gt_ship_line_data_tab(i).head_sales_branch   -- 管轄拠点
                       ,it_ship_to_code       =>  gt_ship_line_data_tab(i).deliver_to          -- 出荷先
                       ,it_delivery_whse_code =>  gt_ship_line_data_tab(i).deliver_from        -- 出庫元保管場所
                       ,id_standard_date      =>  gt_ship_line_data_tab(i).schedule_ship_date  -- 出荷予定日
                     );
      -- リターンコードが正常でない場合
      IF ( lv_ret_code <> cv_status_normal ) THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                       -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13231                                                       -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_request_no                                                        -- トークンコード1
                       ,iv_token_value1  =>  gt_ship_line_data_tab(i).request_no                                      -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_item_code                                                         -- トークンコード2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_hs_branch                                                         -- トークンコード3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_deliver_to                                                        -- トークンコード4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).deliver_to                                      -- トークン値4
                       ,iv_token_name5   =>  cv_tkn_deliver_from                                                      -- トークンコード5
                       ,iv_token_value5  =>  gt_ship_line_data_tab(i).deliver_from                                    -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_ship_date                                                         -- トークンコード6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- トークン値6
                       ,iv_token_name7   =>  cv_tkn_input_line_no                                                     -- トークンコード7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).line_number                                     -- トークン値7
                      );
        -- 出力に表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ログに表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- エラーフラグを立てる
        lv_err_flag := cv_yes;
      END IF;
--
      ----------------------------------------------------------
      -- 9-2.共通関数「出荷可否チェック」により出荷可否チェック
      ----------------------------------------------------------
--
      -- 9-2-1.出荷数制限(商品部)
      xxwsh_common910_pkg.check_shipping_judgment(
         iv_check_class      =>  cv_check_class_2                                     -- チェック方法(出荷数制限(商品部))
        ,iv_base_cd          =>  gt_ship_line_data_tab(i).head_sales_branch           -- 管轄拠点
        ,in_item_id          =>  gt_ship_line_data_tab(i).shipping_inventory_item_id  -- 出荷品目ID
        ,in_amount           =>  gt_ship_line_data_tab(i).quantity                    -- 明細の総数
        ,id_date             =>  gt_ship_line_data_tab(i).schedule_arrival_date       -- 着荷予定日
        ,in_deliver_from_id  =>  gt_ship_line_data_tab(i).deliver_from_id             -- 出荷元保管場所ID
        ,iv_request_no       =>  gt_ship_line_data_tab(i).request_no                  -- 依頼No
        ,ov_retcode          =>  lv_ret_code                                          -- リターンコード
        ,ov_errmsg_code      =>  lv_err_code                                          -- エラーメッセージコード
        ,ov_errmsg           =>  lv_err_msg                                           -- エラーメッセージ
        ,on_result           =>  ln_result                                            -- 処理結果
      );
      -- リターンコードが正常でない場合
      IF ( lv_ret_code <> cv_status_normal ) THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13248                                                          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- トークンコード1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13233                                                          -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- トークンコード2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- トークンコード3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- トークンコード4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- トークン値4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- トークンコード5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- トークンコード6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_arrival_date, cv_yyyymmdd_sla )  -- トークン値6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- トークンコード7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- トークン値7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- トークンコード8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- トークン値8
                       ,iv_token_name9   =>  cv_tkn_err_msg                                                              -- トークンコード9
                       ,iv_token_value9  =>  lv_err_msg                                                                  -- トークン値9
                      );
        -- 出力に表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ログに表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- エラーフラグを立てる
        lv_err_flag := cv_yes;
      -- 処理結果が正常でない場合
      ELSIF ( ln_result <> cn_ret_normal) THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13232                                                          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- トークンコード1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13233                                                          -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- トークンコード2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- トークンコード3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- トークンコード4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- トークン値4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- トークンコード5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- トークンコード6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_arrival_date, cv_yyyymmdd_sla )  -- トークン値6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- トークンコード7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- トークン値7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- トークンコード8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- トークン値8
                      );
        -- 出力に表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ログに表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- エラーフラグを立てる
        lv_err_flag := cv_yes;
      END IF;
--
      -- 9-2-2.出荷数制限(物流部)
      xxwsh_common910_pkg.check_shipping_judgment(
         iv_check_class      =>  cv_check_class_3                                     -- チェック方法(出荷数制限(物流部))
        ,iv_base_cd          =>  gt_ship_line_data_tab(i).head_sales_branch           -- 管轄拠点
        ,in_item_id          =>  gt_ship_line_data_tab(i).shipping_inventory_item_id  -- 出荷品目ID
        ,in_amount           =>  gt_ship_line_data_tab(i).quantity                    -- 明細の総数
        ,id_date             =>  gt_ship_line_data_tab(i).schedule_arrival_date       -- 着荷予定日
        ,in_deliver_from_id  =>  gt_ship_line_data_tab(i).deliver_from_id             -- 出荷元保管場所ID
        ,iv_request_no       =>  gt_ship_line_data_tab(i).request_no                  -- 依頼No
        ,ov_retcode          =>  lv_ret_code                                          -- リターンコード
        ,ov_errmsg_code      =>  lv_err_code                                          -- エラーメッセージコード
        ,ov_errmsg           =>  lv_err_msg                                           -- エラーメッセージ
        ,on_result           =>  ln_result                                            -- 処理結果
      );
      -- リターンコードが正常でない場合
      IF ( lv_ret_code <> cv_status_normal ) THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                       -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13248                                                       -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                          -- トークンコード1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13234                                                       -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                        -- トークンコード2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                      -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                         -- トークンコード3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                         -- トークンコード4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- トークン値4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                          -- トークンコード5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                             -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                         -- トークンコード6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- トークン値6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                      -- トークンコード7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                    -- トークン値7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                     -- トークンコード8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                     -- トークン値8
                       ,iv_token_name9   =>  cv_tkn_err_msg                                                           -- トークンコード9
                       ,iv_token_value9  =>  lv_err_msg                                                               -- トークン値9
                      );
        -- 出力に表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ログに表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- エラーフラグを立てる
        lv_err_flag := cv_yes;
      -- 処理結果が数量オーバーの場合
      ELSIF ( ln_result = cn_ret_num_over) THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13232                                                          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- トークンコード1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13234                                                          -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- トークンコード2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- トークンコード3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- トークンコード4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- トークン値4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- トークンコード5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- トークンコード6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )     -- トークン値6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- トークンコード7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- トークン値7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- トークンコード8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- トークン値8
                      );
        -- 出力に表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ログに表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- エラーフラグを立てる
        lv_err_flag := cv_yes;
      -- 処理結果が出荷停止日エラーの場合
      ELSIF ( ln_result = cn_ret_date_err) THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxwsh                                                          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxwsh_13235                                                          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_chk_type                                                             -- トークンコード1
                       ,iv_token_value1  =>  cv_msg_xxwsh_13234                                                          -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_request_no                                                           -- トークンコード2
                       ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_item_code                                                            -- トークンコード3
                       ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                                 -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_hs_branch                                                            -- トークンコード4
                       ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                                  -- トークン値4
                       ,iv_token_name5   =>  cv_tkn_quantity                                                             -- トークンコード5
                       ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                                -- トークン値5
                       ,iv_token_name6   =>  cv_tkn_base_date                                                            -- トークンコード6
                       ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )     -- トークン値6
                       ,iv_token_name7   =>  cv_tkn_deliver_from                                                         -- トークンコード7
                       ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                       -- トークン値7
                       ,iv_token_name8   =>  cv_tkn_input_line_no                                                        -- トークンコード8
                       ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                        -- トークン値8
                      );
        -- 出力に表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ログに表示
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- エラーフラグを立てる
        lv_err_flag := cv_yes;
      END IF;
--
      -- 9-2-3.出荷数制限(引取計画)の実施の為、計画商品件数を取得
      SELECT COUNT(xsrv.rowid)
      INTO   ln_plan_item_cnt
      FROM   xxcmn_sourcing_rules2_v xsrv
      WHERE  xsrv.base_code           = gt_ship_line_data_tab(i).head_sales_branch
      AND    xsrv.item_code           = gt_ship_line_data_tab(i).shipping_item_code
      AND    xsrv.plan_item_flag      = cv_plan_item_flag
      AND    xsrv.start_date_active  <= gt_ship_line_data_tab(i).schedule_ship_date
      AND    xsrv.end_date_active    >= gt_ship_line_data_tab(i).schedule_ship_date
      ;
--
      -- 計画商品件数がある場合のみ
      IF ( ln_plan_item_cnt >= cn_1 ) THEN
        -- 9-2-4.出荷数制限(引取計画)
        xxwsh_common910_pkg.check_shipping_judgment(
           iv_check_class      =>  cv_check_class_4                                     -- チェック方法(出荷数制限(引取計画商品))
          ,iv_base_cd          =>  gt_ship_line_data_tab(i).head_sales_branch           -- 管轄拠点
          ,in_item_id          =>  gt_ship_line_data_tab(i).shipping_inventory_item_id  -- 出荷品目ID
          ,in_amount           =>  gt_ship_line_data_tab(i).quantity                    -- 明細の総数
          ,id_date             =>  gt_ship_line_data_tab(i).schedule_ship_date          -- 出荷予定日
          ,in_deliver_from_id  =>  gt_ship_line_data_tab(i).deliver_from_id             -- 出荷元保管場所ID
          ,iv_request_no       =>  gt_ship_line_data_tab(i).request_no                  -- 依頼No
          ,ov_retcode          =>  lv_ret_code                                          -- リターンコード
          ,ov_errmsg_code      =>  lv_err_code                                          -- エラーメッセージコード
          ,ov_errmsg           =>  lv_err_msg                                           -- エラーメッセージ
          ,on_result           =>  ln_result                                            -- 処理結果
        );
        -- リターンコードが正常でない場合
        IF ( lv_ret_code <> cv_status_normal ) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh                                                       -- アプリケーション短縮名
                         ,iv_name          =>  cv_msg_xxwsh_13248                                                       -- メッセージコード
                         ,iv_token_name1   =>  cv_tkn_chk_type                                                          -- トークンコード1
                         ,iv_token_value1  =>  cv_msg_xxwsh_13237                                                       -- トークン値1
                         ,iv_token_name2   =>  cv_tkn_request_no                                                        -- トークンコード2
                         ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                      -- トークン値2
                         ,iv_token_name3   =>  cv_tkn_item_code                                                         -- トークンコード3
                         ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- トークン値3
                         ,iv_token_name4   =>  cv_tkn_hs_branch                                                         -- トークンコード4
                         ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- トークン値4
                         ,iv_token_name5   =>  cv_tkn_quantity                                                          -- トークンコード5
                         ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                             -- トークン値5
                         ,iv_token_name6   =>  cv_tkn_base_date                                                         -- トークンコード6
                         ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- トークン値6
                         ,iv_token_name7   =>  cv_tkn_deliver_from                                                      -- トークンコード7
                         ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                    -- トークン値7
                         ,iv_token_name8   =>  cv_tkn_input_line_no                                                     -- トークンコード8
                         ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                     -- トークン値8
                         ,iv_token_name9   =>  cv_tkn_err_msg                                                           -- トークンコード9
                         ,iv_token_value9  =>  lv_err_msg                                                               -- トークン値9
                        );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立てる
          lv_err_flag := cv_yes;
        -- 処理結果が正常でない場合
        ELSIF ( ln_result <> cn_ret_normal) THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxwsh                                                       -- アプリケーション短縮名
                         ,iv_name          =>  cv_msg_xxwsh_13236                                                       -- メッセージコード
                         ,iv_token_name1   =>  cv_tkn_chk_type                                                          -- トークンコード1
                         ,iv_token_value1  =>  cv_msg_xxwsh_13237                                                       -- トークン値1
                         ,iv_token_name2   =>  cv_tkn_request_no                                                        -- トークンコード2
                         ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no                                      -- トークン値2
                         ,iv_token_name3   =>  cv_tkn_item_code                                                         -- トークンコード3
                         ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code                              -- トークン値3
                         ,iv_token_name4   =>  cv_tkn_hs_branch                                                         -- トークンコード4
                         ,iv_token_value4  =>  gt_ship_line_data_tab(i).head_sales_branch                               -- トークン値4
                         ,iv_token_name5   =>  cv_tkn_quantity                                                          -- トークンコード5
                         ,iv_token_value5  =>  TO_CHAR( gt_ship_line_data_tab(i).quantity )                             -- トークン値5
                         ,iv_token_name6   =>  cv_tkn_base_date                                                         -- トークンコード6
                         ,iv_token_value6  =>  TO_CHAR( gt_ship_line_data_tab(i).schedule_ship_date, cv_yyyymmdd_sla )  -- トークン値6
                         ,iv_token_name7   =>  cv_tkn_deliver_from                                                      -- トークンコード7
                         ,iv_token_value7  =>  gt_ship_line_data_tab(i).deliver_from                                    -- トークン値7
                         ,iv_token_name8   =>  cv_tkn_input_line_no                                                     -- トークンコード8
                         ,iv_token_value8  =>  gt_ship_line_data_tab(i).line_number                                     -- トークン値8
                        );
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- エラーフラグを立てる
          lv_err_flag := cv_yes;
        END IF;
      END IF;
--
    END LOOP chk_emp_of_logi;
--
    -- 物流担当用の妥当性チェックでエラーがある場合も警告とする
    IF ( lv_err_flag = cv_yes ) THEN
      ov_retcode  := cv_status_warn;
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
      IF ( get_work_cur%ISOPEN ) THEN
        CLOSE get_work_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ship_request_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_order_data
   * Description      : 受注アドオン更新 (M-4)
   ***********************************************************************************/
  PROCEDURE upd_order_data(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_order_data'; -- プログラム名
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
    -- *** ローカルユーザー定義例外 ***
    data_skip_expt EXCEPTION;      -- スキップデータ例外
--
    -- *** ローカル変数 ***
    lv_dummy                     VARCHAR2(1);                                             -- ダミー(ロック用)
    ln_suc_line_cnt              NUMBER;                                                  -- 明細単位成功件数
    -- 受注アドオンヘッダへの登録用
    lt_sum_quantity              xxwsh_order_headers_all.sum_quantity%TYPE;               -- 合計数量
    lt_small_quantity            xxwsh_order_headers_all.small_quantity%TYPE;             -- 小口個数
    lt_label_quantity            xxwsh_order_headers_all.label_quantity%TYPE;             -- ラベル枚数
    lt_shipping_method_code      xxwsh_order_headers_all.shipping_method_code%TYPE;       -- 配送区分
    lt_based_weight              xxwsh_order_headers_all.based_weight%TYPE;               -- 基本重量
    lt_loading_efficiency_weight xxwsh_order_headers_all.loading_efficiency_weight%TYPE;  -- 重量積載効率
    lt_sum_weight                xxwsh_order_headers_all.sum_weight%TYPE;                 -- 積載重量合計
    lt_sum_capacity              xxwsh_order_headers_all.sum_capacity%TYPE;               -- 積載容積合計
    lt_sum_pallet_weight         xxwsh_order_headers_all.sum_pallet_weight%TYPE;          -- 合計パレット重量
    lt_pallet_sum_quantity       xxwsh_order_headers_all.pallet_sum_quantity%TYPE;        -- パレット合計枚数
    -- 共通関数・計算用
    lv_ret_code                  VARCHAR2(1);                                             -- リターンコード(共通関数用)
    lv_err_msg_code              VARCHAR2(4000);                                          -- エラーメッセージコード(共通関数用)
    lv_err_msg                   VARCHAR2(5000);                                          -- エラーメッセージ(共通関数用)
    ln_ship_cnv_quantity         NUMBER;                                                  -- 出荷単位換算数(小口個数計算用)
    ln_weight                    NUMBER;                                                  -- 重量合計(積載重量合計計算用)
    ln_l_e_weight_calc           NUMBER;                                                  -- 重量合計(重量積載効率取得用)
    lt_max_ship_methods          xxcmn_ship_methods.ship_method%TYPE;                     -- 最大配送区分(配送区分取得用)
    lt_drink_deadweight          xxcmn_ship_methods.drink_deadweight%TYPE;                -- ドリンク積載重量(基本重量計算用)
    lt_palette_max_qty           xxcmn_ship_methods.palette_max_qty%TYPE;                 -- パレット最大枚数(チェック用)
    lv_loading_over_class        VARCHAR2(1);                                             -- 積載オーバー区分(チェック用)
    -- 共通関数用(ダミー)
    lv_ship_m_dummy              xxcmn_ship_methods.ship_method%TYPE;                     -- 出荷方法
    lt_drink_d_dummy             xxcmn_ship_methods.drink_deadweight%TYPE;                -- ドリンク積載重量
    lt_leaf_d_dummy              xxcmn_ship_methods.leaf_deadweight%TYPE;                 -- リーフ積載重量
    lt_drink_c_dummy             xxcmn_ship_methods.drink_loading_capacity%TYPE;          -- ドリンク積載容積
    lt_leaf_c_dummy              xxcmn_ship_methods.leaf_loading_capacity%TYPE;           -- リーフ積載容積
    lt_palette_m_q_dummy         xxcmn_ship_methods.palette_max_qty%TYPE;                 -- パレット最大枚数
    lv_mixed_ship_m_dummy        VARCHAR2(256);                                           -- 混載配送区分
    ln_efficiency_w_dummy        NUMBER;                                                  -- 重量積載効率
    ln_efficiency_c_dummy        NUMBER;                                                  -- 容積積載効率
    -- 混載Noチェック用
    lt_based_w_mixed             xxwsh_order_headers_all.based_weight%TYPE;               -- 基本重量(基準混載)
    lt_sum_w_mixed               xxwsh_order_headers_all.sum_weight%TYPE;                 -- 積載重量合計(基準混載)
    lt_sum_pallet_w_mixed        xxwsh_order_headers_all.sum_pallet_weight%TYPE;          -- 合計パレット重量(基準混載)
    lt_small_amount_c_mixed      xxwsh_ship_method_v.small_amount_class%TYPE;             -- 小口区分(基準混載)
    ln_w_mixed_sum               NUMBER;                                                  -- 積載重量合計(混載No単位)
    ln_p_mixed_sum               NUMBER;                                                  -- 合計パレット重量(混載No単位)
    ln_chk_w_mixed_sum           NUMBER;                                                  -- 積載重量合計(計算用)
--
    -- *** ローカル・カーソル ***
    -- 出荷依頼取得用カーソル
    CURSOR get_ship_date_cur(
      it_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE
    )
    IS
      SELECT  xoha.order_header_id        order_header_id        -- 受注ヘッダアドオンID
             ,xoha.request_no             request_no             -- 依頼No
             ,xoha.freight_charge_class   freight_charge_class   -- 運賃区分
             ,xoha.deliver_from           deliver_from           -- 出荷元保管場所
             ,xoha.deliver_to             deliver_to             -- 出荷先
             ,xoha.prod_class             prod_class             -- 商品区分
             ,xoha.weight_capacity_class  weight_capacity_class  -- 重量容積区分
             ,xoha.shipping_method_code   shipping_method_code   -- 配送区分
             ,xoha.based_weight           based_weight           -- 基本重量
             ,xola.quantity               quantity               -- 数量
             ,xola.weight                 weight                 -- 重量
             ,xola.capacity               capacity               -- 容積
             ,xola.pallet_qty             pallet_qty             -- パレット枚数
             ,xola.pallet_weight          pallet_weight          -- パレット重量
             ,ximv.num_of_cases           num_of_cases           -- ケース入数
             ,ximv.num_of_deliver         num_of_deliver         -- 出荷入数
             ,xsmv.small_amount_class     small_amount_class     -- 小口区分
       FROM   xxwsh_order_headers_all xoha  -- 受注ヘッダアドオン
             ,xxwsh_order_lines_all   xola  -- 受注明細アドオン
             ,xxcmn_item_mst2_v       ximv  -- OPM品目情報VIEW2
             ,xxwsh_ship_method2_v    xsmv  -- 配送区分情報VIEW2
      WHERE   xoha.order_header_id           = it_order_header_id
      AND     xoha.order_header_id           = xola.order_header_id
      AND     NVL( xola.delete_flag, cv_no ) = cv_no
      AND     xola.request_item_code         = ximv.item_no
      AND     ximv.start_date_active        <= cd_sysdate
      AND     ximv.end_date_active          >= cd_sysdate
      AND     xoha.shipping_method_code      = xsmv.ship_method_code(+)
      AND     xsmv.start_date_active(+)     <= xoha.schedule_ship_date
      AND     NVL( xsmv.end_date_active(+), xoha.schedule_ship_date )
                                            >= xoha.schedule_ship_date
      ;
--
    -- *** ローカル・レコード ***
    l_get_ship_date_rec  get_ship_date_cur%ROWTYPE;  -- カーソルデータレコード
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    -- 明細件数の初期化
    ln_suc_line_cnt   := 0;
    --==============================================================
    -- M-4.1 配列のデータの取得
    --==============================================================
    <<upd_data_loop>>
    FOR i IN 1..gt_ship_line_data_tab.COUNT LOOP
--
      -- 初期化
      lv_ret_code     := cv_status_normal;
      lv_dummy        := NULL;
      lv_err_msg      := NULL;
      -- 明細件数カウント
      ln_suc_line_cnt := ln_suc_line_cnt + 1;
--
      -- セーブポイントの発行
      SAVEPOINT req_unit_save;
--
      BEGIN
--
        --==============================================================
        -- M-4.2 受注明細アドオンのロック
        --==============================================================
        BEGIN
          SELECT cv_yes  lock_ok
          INTO   lv_dummy
          FROM   xxwsh_order_lines_all xola
          WHERE  xola.rowid = gt_ship_line_data_tab(i).xola_rowid
          FOR UPDATE OF
                 xola.order_line_id
          NOWAIT
          ;
        EXCEPTION
          WHEN  global_lock_expt THEN
            -- メッセージ編集
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh                            -- アプリケーション短縮名
                           ,iv_name          =>  cv_msg_xxwsh_13214                            -- メッセージコード
                           ,iv_token_name1   =>  cv_tkn_table                                  -- トークンコード1
                           ,iv_token_value1  =>  cv_msg_xxwsh_13249                            -- トークン値1
                           ,iv_token_name2   =>  cv_tkn_request_no                             -- トークンコード2
                           ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no           -- トークン値2
                           ,iv_token_name3   =>  cv_tkn_item_code                              -- トークンコード3
                           ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code   -- トークン値3
                           ,iv_token_name4   =>  cv_tkn_input_line_no                          -- トークンコード4
                           ,iv_token_value4  =>  gt_ship_line_data_tab(i).line_number          -- トークン値4
                          );
            RAISE data_skip_expt;
        END;
--
        -- 自動引当済みの場合のみ
        IF ( gt_ship_line_data_tab(i).automanual_reserve_class  = cv_reserve_flag_auto ) THEN
          --=============================================================================
          -- M-4.3 共通関数「引当解除関数」により明細の引当を解除
          --=============================================================================
          lv_ret_code := xxwsh_common_pkg.cancel_reserve(
                            iv_biz_type    => cv_ship                                 -- 業務種別：1(出荷)
                           ,iv_request_no  => gt_ship_line_data_tab(i).request_no     -- 依頼No
                           ,in_line_id     => gt_ship_line_data_tab(i).order_line_id  -- 明細ID
                           ,ov_errmsg      => lv_err_msg                              -- エラーメッセージ
                         );
          -- リターンコードが正常でない場合
          IF ( lv_ret_code <> cv_status_normal ) THEN
            -- メッセージ編集
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh                            -- アプリケーション短縮名
                           ,iv_name          =>  cv_msg_xxwsh_13216                            -- メッセージコード
                           ,iv_token_name1   =>  cv_tkn_request_no                             -- トークンコード1
                           ,iv_token_value1  =>  gt_ship_line_data_tab(i).request_no           -- トークン値1
                           ,iv_token_name2   =>  cv_tkn_item_code                              -- トークンコード2
                           ,iv_token_value2  =>  gt_ship_line_data_tab(i).shipping_item_code   -- トークン値2
                           ,iv_token_name3   =>  cv_tkn_input_line_no                          -- トークンコード3
                           ,iv_token_value3  =>  gt_ship_line_data_tab(i).line_number          -- トークン値3
                           ,iv_token_name4   =>  cv_tkn_err_msg                                -- トークンコード4
                           ,iv_token_value4  =>  lv_err_msg                                    -- トークン値4
                          );
            RAISE data_skip_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- M-4.4 受注明細アドオンの更新
        --==============================================================
        BEGIN
          UPDATE  xxwsh_order_lines_all xola
          SET     xola.shipping_inventory_item_id  = gt_ship_line_data_tab(i).shipping_inventory_item_id
                 ,xola.shipping_item_code          = gt_ship_line_data_tab(i).shipping_item_code
                 ,xola.quantity                    = gt_ship_line_data_tab(i).quantity
                 ,xola.uom_code                    = gt_ship_line_data_tab(i).uom_code
                 ,xola.shipped_quantity            = gt_ship_line_data_tab(i).shipped_quantity
                 ,xola.based_request_quantity      = gt_ship_line_data_tab(i).based_request_quantity
                 ,xola.request_item_id             = gt_ship_line_data_tab(i).request_item_id
                 ,xola.request_item_code           = gt_ship_line_data_tab(i).request_item_code
                 ,xola.po_number                   = gt_ship_line_data_tab(i).po_number
                 ,xola.pallet_quantity             = gt_ship_line_data_tab(i).pallet_quantity
                 ,xola.layer_quantity              = gt_ship_line_data_tab(i).layer_quantity
                 ,xola.case_quantity               = gt_ship_line_data_tab(i).case_quantity
                 ,xola.weight                      = gt_ship_line_data_tab(i).weight
                 ,xola.capacity                    = gt_ship_line_data_tab(i).capacity
                 ,xola.pallet_qty                  = gt_ship_line_data_tab(i).pallet_qty
                 ,xola.pallet_weight               = gt_ship_line_data_tab(i).pallet_weight
                 ,xola.shipping_request_if_flg     = gt_ship_line_data_tab(i).shipping_request_if_flg
                 ,xola.shipping_result_if_flg      = gt_ship_line_data_tab(i).shipping_result_if_flg
                 ,xola.last_updated_by             = gt_ship_line_data_tab(i).last_updated_by
                 ,xola.last_update_date            = gt_ship_line_data_tab(i).last_update_date
                 ,xola.last_update_login           = gt_ship_line_data_tab(i).last_update_login
                 ,xola.request_id                  = gt_ship_line_data_tab(i).request_id
                 ,xola.program_application_id      = gt_ship_line_data_tab(i).program_application_id
                 ,xola.program_id                  = gt_ship_line_data_tab(i).program_id
                 ,xola.program_update_date         = gt_ship_line_data_tab(i).program_update_date
          WHERE   xola.rowid                       = gt_ship_line_data_tab(i).xola_rowid
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- メッセージ編集
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxwsh                            -- アプリケーション短縮名
                           ,iv_name          =>  cv_msg_xxwsh_13215                            -- メッセージコード
                           ,iv_token_name1   =>  cv_tkn_table                                  -- トークンコード1
                           ,iv_token_value1  =>  cv_msg_xxwsh_13249                            -- トークン値1
                           ,iv_token_name2   =>  cv_tkn_request_no                             -- トークンコード2
                           ,iv_token_value2  =>  gt_ship_line_data_tab(i).request_no           -- トークン値2
                           ,iv_token_name3   =>  cv_tkn_item_code                              -- トークンコード3
                           ,iv_token_value3  =>  gt_ship_line_data_tab(i).shipping_item_code   -- トークン値3
                           ,iv_token_name4   =>  cv_tkn_input_line_no                          -- トークンコード4
                           ,iv_token_value4  =>  gt_ship_line_data_tab(i).line_number          -- トークン値4
                           ,iv_token_name5   =>  cv_tkn_err_msg                                -- トークンコード5
                           ,iv_token_value5  =>  SQLERRM                                       -- トークン値5
                          );
            RAISE data_skip_expt;
        END;
--
        --==============================================================
        -- M-4.5 ヘッダ項目の再計算・妥当性チェック・更新(ヘッダブレーク処理)
        --==============================================================
        -- ヘッダIDが次レコードが存在し且つ異なる、もしくは最終レコードの場合(同一依頼の最終データの場合)
        IF (
             (
                ( gt_ship_line_data_tab.EXISTS(i+1) )
                AND
                ( gt_ship_line_data_tab(i).order_header_id <> gt_ship_line_data_tab(i+1).order_header_id )
             )
             OR
             ( NOT gt_ship_line_data_tab.EXISTS(i+1) )
           ) THEN
--
           -- 初期化
           lt_sum_quantity           := 0;  -- 合計数量
           ln_ship_cnv_quantity      := 0;  -- 出荷単位換算数
           lt_small_quantity         := 0;  -- 小口個数
           lt_label_quantity         := 0;  -- ラベル枚数
           lt_sum_weight             := 0;  -- 積載重量合計
           ln_weight                 := 0;  -- 積載重量合計計算用
           ln_l_e_weight_calc        := 0;  -- 重量積載効率取得用
           lt_sum_capacity           := 0;  -- 積載容積合計
           lt_sum_pallet_weight      := 0;  -- 合計パレット重量
           lt_pallet_sum_quantity    := 0;  -- 合計パレット枚数
--
           -- 5-1.受注情報を抽出
           OPEN  get_ship_date_cur(
                   gt_ship_line_data_tab(i).order_header_id
                 );
           <<get_ship_data_loop>>
           LOOP
--
             FETCH get_ship_date_cur INTO l_get_ship_date_rec;
             EXIT WHEN get_ship_date_cur%NOTFOUND;
--
             -- 5-2.合計数量の計算
             lt_sum_quantity := lt_sum_quantity + l_get_ship_date_rec.quantity;
--
             -- 5-3.小口個数の計算
--
             -- 出荷入数に値がある場合
             IF ( l_get_ship_date_rec.num_of_deliver IS NOT NULL )THEN
               -- 出荷入数 > 0 の場合
               IF ( l_get_ship_date_rec.num_of_deliver > cn_0 ) THEN
                 -- 出荷単位換算数(数量÷出荷入数)
                 ln_ship_cnv_quantity := l_get_ship_date_rec.quantity / l_get_ship_date_rec.num_of_deliver;
               ELSE
                 -- 出荷単位換算数(0)
                 ln_ship_cnv_quantity := 0;
               END IF;
             -- ケース入数に値がある場合
             ELSIF ( l_get_ship_date_rec.num_of_cases IS NOT NULL ) THEN
              -- ケース入数 > 0 の場合
               IF ( l_get_ship_date_rec.num_of_cases > cn_0 ) THEN
                 -- 出荷単位換算数(数量÷ケース入数)
                 ln_ship_cnv_quantity := l_get_ship_date_rec.quantity / l_get_ship_date_rec.num_of_cases;
               ELSE
                 -- 出荷単位換算数(0)
                 ln_ship_cnv_quantity := 0;
               END IF;
             -- 上記以外(数量)
             ELSE
               ln_ship_cnv_quantity := l_get_ship_date_rec.quantity;
             END IF;
--
             -- 小口個数(少数点以下切上げ)
             lt_small_quantity := lt_small_quantity + TRUNC( ln_ship_cnv_quantity + 0.9 );
--
             -- 5-4.ラベル枚数の計算
             lt_label_quantity := lt_label_quantity + TRUNC( ln_ship_cnv_quantity + 0.9 );
--
             -- 小口区分が1(小口)の場合(重量合計)
             IF ( l_get_ship_date_rec.small_amount_class = cv_amount_class_small ) THEN
               -- 重量合計(重量合計)
               ln_weight := l_get_ship_date_rec.weight;
             -- 小口区分が1(小口)以外の場合
             ELSE
               -- 重量合計(重量合計+パレット重量)
               ln_weight := l_get_ship_date_rec.weight + l_get_ship_date_rec.pallet_weight;
             END IF;
             -- 5-5.重量積載効率取得用の重量の計算
             ln_l_e_weight_calc := ln_l_e_weight_calc + ln_weight;
--
             -- 5-6.合計重量の計算
             lt_sum_weight   := lt_sum_weight + l_get_ship_date_rec.weight;
--
             -- 5-7.合計容積の計算
             lt_sum_capacity := lt_sum_capacity + l_get_ship_date_rec.capacity;
--
             -- 5-8.合計パレット重量
             lt_sum_pallet_weight := lt_sum_pallet_weight + l_get_ship_date_rec.pallet_weight;
--
             -- 5-9.パレット合計枚数
             lt_pallet_sum_quantity := lt_pallet_sum_quantity + l_get_ship_date_rec.pallet_qty;
--
           END LOOP get_ship_data_loop;
--
           -- カーソルクローズ
           CLOSE get_ship_date_cur;
--
           lt_max_ship_methods       := NULL;             -- 最大配送区分
           lt_drink_deadweight       := 0;                -- ドリンク積載重量
           lt_palette_max_qty        := 0;                -- パレット最大枚数
           lv_loading_over_class     := 0;                -- 積載オーバー区分
--
           -- 5-10.パレット最大枚数超過チェックと積載効率チェック(運賃区分がONの場合のみ)
           IF ( l_get_ship_date_rec.freight_charge_class = cv_freight_charge_on ) THEN
--
             -- 初期化
             lv_ret_code := cv_status_normal;
--
             -- 5-10-1. 共通関数「最大配送区分算出関数」より最大配送区分を取得
             lv_ret_code := xxwsh_common_pkg.get_max_ship_method(
                              iv_code_class1                 => cv_code_class_4                            -- 4(倉庫)
                             ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from           -- 出荷元保管場所
                             ,iv_code_class2                 => cv_code_class_9                            -- 9(配送先)
                             ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to             -- 出荷先
                             ,iv_prod_class                  => l_get_ship_date_rec.prod_class             -- 商品区分
                             ,iv_weight_capacity_class       => l_get_ship_date_rec.weight_capacity_class  -- 重量容積区分
                             ,iv_auto_process_type           => NULL                                       -- NULL(自動配車対象区分)
                             ,id_standard_date               => NULL                                       -- NULL(基準日)
                             ,ov_max_ship_methods            => lt_max_ship_methods                        -- 最大配送区分
                             ,on_drink_deadweight            => lt_drink_deadweight                        -- ドリンク積載重量
                             ,on_leaf_deadweight             => lt_leaf_d_dummy                            -- リーフ積載重量
                             ,on_drink_loading_capacity      => lt_drink_c_dummy                           -- ドリンク積載容積
                             ,on_leaf_loading_capacity       => lt_leaf_c_dummy                            -- リーフ積載容積
                             ,on_palette_max_qty             => lt_palette_m_q_dummy                       -- パレット最大枚数
                            );
             IF ( lv_ret_code <> cv_status_normal ) THEN
               -- メッセージ編集
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                         -- アプリケーション短縮名
                              ,iv_name          =>  cv_msg_xxwsh_13217                         -- メッセージコード
                              ,iv_token_name1   =>  cv_tkn_request_no                          -- トークンコード1
                              ,iv_token_value1  =>  l_get_ship_date_rec.request_no             -- トークン値1
                              ,iv_token_name2   =>  cv_tkn_deliver_from                        -- トークンコード2
                              ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from           -- トークン値2
                              ,iv_token_name3   =>  cv_tkn_deliver_to                          -- トークンコード3
                              ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to             -- トークン値3
                              ,iv_token_name4   =>  cv_tkn_prod_class                          -- トークンコード4
                              ,iv_token_value4  =>  l_get_ship_date_rec.prod_class             -- トークン値4
                              ,iv_token_name5   =>  cv_tkn_weight_class                        -- トークンコード5
                              ,iv_token_value5  =>  l_get_ship_date_rec.weight_capacity_class  -- トークン値5
                              ,iv_token_name6   =>  cv_tkn_err_code                            -- トークンコード6
                              ,iv_token_value6  =>  lv_ret_code                                -- トークン値6
                             );
               RAISE data_skip_expt;
             END IF;
--
             -- 初期化
             lv_ret_code := cv_status_normal;
--
             -- 5-10-2.共通関数「パレット最大枚数超過チェック」によりパレット最大枚数のチェックを実施(物流担当の為、メッセージの出力のみ)
             lv_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                              iv_code_class1                 => cv_code_class_4                   -- 4(倉庫)
                             ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from  -- 出荷元保管場所
                             ,iv_code_class2                 => cv_code_class_9                   -- 9(配送先)
                             ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to    -- 出荷先
                             ,id_standard_date               => NULL                              -- NULL(基準日)
                             ,iv_ship_methods                => lt_max_ship_methods               -- 最大配送区分
                             ,on_drink_deadweight            => lt_drink_d_dummy                  -- ドリンク積載重量
                             ,on_leaf_deadweight             => lt_leaf_d_dummy                   -- リーフ積載重量
                             ,on_drink_loading_capacity      => lt_drink_c_dummy                  -- ドリンク積載容積
                             ,on_leaf_loading_capacity       => lt_leaf_c_dummy                   -- リーフ積載容積
                             ,on_palette_max_qty             => lt_palette_max_qty                -- パレット最大枚数
                            );
             -- パレット最大枚数 < パレット合計枚数の場合
             IF ( lt_palette_max_qty < lt_pallet_sum_quantity ) THEN
               -- メッセージ編集
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                         -- アプリケーション短縮名
                              ,iv_name          =>  cv_msg_xxwsh_13239                         -- メッセージコード
                              ,iv_token_name1   =>  cv_tkn_request_no                          -- トークンコード1
                              ,iv_token_value1  =>  l_get_ship_date_rec.request_no             -- トークン値1
                              ,iv_token_name2   =>  cv_tkn_deliver_from                        -- トークンコード2
                              ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from           -- トークン値2
                              ,iv_token_name3   =>  cv_tkn_deliver_to                          -- トークンコード3
                              ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to             -- トークン値3
                              ,iv_token_name4   =>  cv_tkn_s_method_code                       -- トークンコード4
                              ,iv_token_value4  =>  lt_max_ship_methods                        -- トークン値4
                             );
               -- 出力に表示
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               -- ログに表示
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.LOG
                 ,buff   => lv_errmsg
               );
               -- 処理を警告とする
               ov_retcode      := cv_status_warn;
             END IF;
--
             -- 初期化
             lv_ret_code      := cv_status_normal;
             lv_err_msg_code  := NULL;
             lv_err_msg       := NULL;
--
             -- 5-10-3.共通関数「積載効率チェック(積載効率算出)」により積載効率チェックを実施(出荷依頼の配送区分でチェック)
             xxwsh_common910_pkg.calc_load_efficiency(
               in_sum_weight                  => ln_l_e_weight_calc                         -- 重量積載効率取得用の合計重量(5-5)
              ,in_sum_capacity                => NULL                                       -- NULL(合計容積)
              ,iv_code_class1                 => cv_code_class_4                            -- 4(倉庫)
              ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from           -- 出荷元保管場所
              ,iv_code_class2                 => cv_code_class_9                            -- 9(配送先)
              ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to             -- 出荷先
              ,iv_ship_method                 => l_get_ship_date_rec.shipping_method_code   -- 配送区分(受注)
              ,iv_prod_class                  => l_get_ship_date_rec.prod_class             -- 商品区分
              ,iv_auto_process_type           => NULL                                       -- NULL(自動配車対象区分)
              ,id_standard_date               => cd_sysdate                                 -- システム日付(基準日)
              ,ov_retcode                     => lv_ret_code                                -- リターン・コード
              ,ov_errmsg_code                 => lv_err_msg_code                            -- エラーメッセージコード
              ,ov_errmsg                      => lv_err_msg                                 -- エラーメッセージ
              ,ov_loading_over_class          => lv_loading_over_class                      -- 積載オーバー区分
              ,ov_ship_methods                => lv_ship_m_dummy                            -- 出荷方法
              ,on_load_efficiency_weight      => lt_loading_efficiency_weight               -- 重量積載効率
              ,on_load_efficiency_capacity    => ln_efficiency_c_dummy                      -- 容積積載効率
              ,ov_mixed_ship_method           => lv_mixed_ship_m_dummy                      -- 混載配送区分
             );
             IF ( lv_ret_code <> cv_status_normal ) THEN
               -- メッセージ編集
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                       -- アプリケーション短縮名
                              ,iv_name          =>  cv_msg_xxwsh_13218                       -- メッセージコード
                              ,iv_token_name1   =>  cv_tkn_request_no                        -- トークンコード1
                              ,iv_token_value1  =>  l_get_ship_date_rec.request_no           -- トークン値1
                              ,iv_token_name2   =>  cv_tkn_deliver_from                      -- トークンコード2
                              ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from         -- トークン値2
                              ,iv_token_name3   =>  cv_tkn_deliver_to                        -- トークンコード3
                              ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to           -- トークン値3
                              ,iv_token_name4   =>  cv_tkn_prod_class                        -- トークンコード4
                              ,iv_token_value4  =>  l_get_ship_date_rec.prod_class           -- トークン値4
                              ,iv_token_name5   =>  cv_tkn_s_method_code                     -- トークンコード5
                              ,iv_token_value5  =>  l_get_ship_date_rec.shipping_method_code -- トークン値5
                              ,iv_token_name6   =>  cv_tkn_base_date                         -- トークンコード6
                              ,iv_token_value6  =>  TO_CHAR(cd_sysdate, cv_yyyymmdd_sla )    -- トークン値6
                              ,iv_token_name7   =>  cv_tkn_err_msg                           -- トークンコード7
                              ,iv_token_value7  =>  lv_err_msg                               -- トークン値7
                             );
               RAISE data_skip_expt;
             END IF;
--
             -- 積載効率をオーバーしていない場合
             IF ( lv_loading_over_class <> cv_loading_over ) THEN
               -- 重量積載効率
               lt_loading_efficiency_weight := lt_loading_efficiency_weight;             -- 上記取得した重量積載効率
               -- 配送区分
               lt_shipping_method_code      := l_get_ship_date_rec.shipping_method_code; -- 受注の配送区分
               -- 基本重量
               lt_based_weight              := l_get_ship_date_rec.based_weight;         -- 受注の基本重量
             -- 積載効率をオーバーしている場合
             ELSE
--
               -- 初期化
               lv_ret_code      := cv_status_normal;
               lv_err_msg_code  := NULL;
               lv_err_msg       := NULL;
--
                -- 5-10-4.共通関数「積載効率チェック(積載効率算出)」により積載効率チェックを実施(最大の配送区分でチェック)
               xxwsh_common910_pkg.calc_load_efficiency(
                 in_sum_weight                  => ln_l_e_weight_calc                         -- 重量積載効率取得用の合計重量(5-5)
                ,in_sum_capacity                => NULL                                       -- NULL(合計容積)
                ,iv_code_class1                 => cv_code_class_4                            -- 4(倉庫)
                ,iv_entering_despatching_code1  => l_get_ship_date_rec.deliver_from           -- 出荷元保管場所
                ,iv_code_class2                 => cv_code_class_9                            -- 9(配送先)
                ,iv_entering_despatching_code2  => l_get_ship_date_rec.deliver_to             -- 出荷先
                ,iv_ship_method                 => lt_max_ship_methods                        -- 配送区分(最大配送区分)
                ,iv_prod_class                  => l_get_ship_date_rec.prod_class             -- 商品区分
                ,iv_auto_process_type           => NULL                                       -- NULL(自動配車対象区分)
                ,id_standard_date               => cd_sysdate                                 -- システム日付(基準日)
                ,ov_retcode                     => lv_ret_code                                -- リターン・コード
                ,ov_errmsg_code                 => lv_err_msg_code                            -- エラーメッセージコード
                ,ov_errmsg                      => lv_err_msg                                 -- エラーメッセージ
                ,ov_loading_over_class          => lv_loading_over_class                      -- 積載オーバー区分
                ,ov_ship_methods                => lv_ship_m_dummy                            -- 出荷方法
                ,on_load_efficiency_weight      => lt_loading_efficiency_weight               -- 重量積載効率
                ,on_load_efficiency_capacity    => ln_efficiency_c_dummy                      -- 容積積載効率
                ,ov_mixed_ship_method           => lv_mixed_ship_m_dummy                      -- 混載配送区分
               );
               IF ( lv_ret_code <> cv_status_normal ) THEN
                 -- メッセージ編集
                 lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application   =>  cv_appl_name_xxwsh                       -- アプリケーション短縮名
                                ,iv_name          =>  cv_msg_xxwsh_13218                       -- メッセージコード
                                ,iv_token_name1   =>  cv_tkn_request_no                        -- トークンコード1
                                ,iv_token_value1  =>  l_get_ship_date_rec.request_no           -- トークン値1
                                ,iv_token_name2   =>  cv_tkn_deliver_from                      -- トークンコード2
                                ,iv_token_value2  =>  l_get_ship_date_rec.deliver_from         -- トークン値2
                                ,iv_token_name3   =>  cv_tkn_deliver_to                        -- トークンコード3
                                ,iv_token_value3  =>  l_get_ship_date_rec.deliver_to           -- トークン値3
                                ,iv_token_name4   =>  cv_tkn_prod_class                        -- トークンコード4
                                ,iv_token_value4  =>  l_get_ship_date_rec.prod_class           -- トークン値4
                                ,iv_token_name5   =>  cv_tkn_s_method_code                     -- トークンコード5
                                ,iv_token_value5  =>  lt_max_ship_methods                      -- トークン値5
                                ,iv_token_name6   =>  cv_tkn_base_date                         -- トークンコード6
                                ,iv_token_value6  =>  TO_CHAR( cd_sysdate, cv_yyyymmdd_sla )   -- トークン値6
                                ,iv_token_name7   =>  cv_tkn_err_msg                           -- トークンコード7
                                ,iv_token_value7  =>  lv_err_msg                               -- トークン値7
                               );
                 RAISE data_skip_expt;
               END IF;
               -- 積載効率をオーバーしていない場合
               IF ( lv_loading_over_class <> cv_loading_over ) THEN
                 -- 重量積載効率
                 lt_loading_efficiency_weight := lt_loading_efficiency_weight;  -- 上記取得した重量積載効率
                 -- 配送区分
                 lt_shipping_method_code      := lt_max_ship_methods;           -- 最大配送区分
                 -- 基本重量
                 lt_based_weight              := lt_drink_deadweight;           -- ドリンク積載重量(5-9-1)
               -- 積載効率をオーバーしている場合
               ELSE
                 -- メッセージ編集
                 lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application   =>  cv_appl_name_xxwsh              -- アプリケーション短縮名
                                ,iv_name          =>  cv_msg_xxwsh_13219              -- メッセージコード
                                ,iv_token_name1   =>  cv_tkn_request_no               -- トークンコード1
                                ,iv_token_value1  =>  l_get_ship_date_rec.request_no  -- トークン値1
                                ,iv_token_name2   =>  cv_tkn_weight                   -- トークンコード2
                                ,iv_token_value2  =>  TO_CHAR( ln_l_e_weight_calc )   -- トークン値2
                               );
                 RAISE data_skip_expt;
               END IF;
             END IF;
           -- 運賃区分がOFFの場合
           ELSE
             -- 重量積載効率
             lt_loading_efficiency_weight := NULL;
             -- 配送区分
             lt_shipping_method_code      := NULL;
             -- 基本重量
             lt_based_weight              := NULL;
           END IF;
--
           -- 5-11.受注ヘッダアドオンのロック
           BEGIN
             SELECT cv_yes  lock_ok
             INTO   lv_dummy
             FROM   xxwsh_order_headers_all xoha
             WHERE  xoha.order_header_id = l_get_ship_date_rec.order_header_id
             FOR UPDATE OF
                    xoha.order_header_id
             NOWAIT
             ;
           EXCEPTION
             WHEN  global_lock_expt THEN
               -- メッセージ編集
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh              -- アプリケーション短縮名
                              ,iv_name          =>  cv_msg_xxwsh_13220              -- メッセージコード
                              ,iv_token_name1   =>  cv_tkn_table                    -- トークンコード1
                              ,iv_token_value1  =>  cv_msg_xxwsh_13250              -- トークン値1
                              ,iv_token_name2   =>  cv_tkn_request_no               -- トークンコード2
                              ,iv_token_value2  =>  l_get_ship_date_rec.request_no  -- トークン値2
                             );
               RAISE data_skip_expt;
           END;
--
           -- 5-12.受注ヘッダアドオンを更新
           BEGIN
             UPDATE  xxwsh_order_headers_all xoha
             SET     xoha.sum_quantity              = lt_sum_quantity               -- 合計数量
                    ,xoha.small_quantity            = lt_small_quantity             -- 小口個数
                    ,xoha.label_quantity            = lt_label_quantity             -- ラベル枚数
                    ,xoha.shipping_method_code      = lt_shipping_method_code       -- 配送区分
                    ,xoha.based_weight              = lt_based_weight               -- 基本重量
                    ,xoha.loading_efficiency_weight = lt_loading_efficiency_weight  -- 重量積載効率
                    ,xoha.sum_weight                = lt_sum_weight                 -- 積載重量合計
                    ,xoha.sum_capacity              = lt_sum_capacity               -- 積載容積合計
                    ,xoha.sum_pallet_weight         = lt_sum_pallet_weight          -- 合計パレット重量
                    ,xoha.pallet_sum_quantity       = lt_pallet_sum_quantity        -- パレット合計枚数
                    ,xoha.screen_update_date        = cd_last_update_date           -- 画面更新日時
                    ,xoha.screen_update_by          = cn_last_updated_by            -- 画面更新者
                    ,xoha.last_updated_by           = cn_last_updated_by            -- 最終更新者
                    ,xoha.last_update_date          = cd_last_update_date           -- 最終更新日
                    ,xoha.last_update_login         = cn_last_update_login          -- 最終更新ログイン
                    ,xoha.request_id                = cn_request_id                 -- 要求ID
                    ,xoha.program_application_id    = cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
                    ,xoha.program_id                = cn_program_id                 -- コンカレント・プログラムID
                    ,xoha.program_update_date       = cd_program_update_date        -- プログラム更新日
             WHERE   xoha.order_header_id           = l_get_ship_date_rec.order_header_id
             ;
           EXCEPTION
             WHEN OTHERS THEN
               -- メッセージ編集
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh              -- アプリケーション短縮名
                              ,iv_name          =>  cv_msg_xxwsh_13221              -- メッセージコード
                              ,iv_token_name1   =>  cv_tkn_table                    -- トークンコード1
                              ,iv_token_value1  =>  cv_msg_xxwsh_13250              -- トークン値1
                              ,iv_token_name2   =>  cv_tkn_request_no               -- トークンコード2
                              ,iv_token_value2  =>  l_get_ship_date_rec.request_no  -- トークン値2
                              ,iv_token_name3   =>  cv_tkn_err_msg                  -- トークンコード3
                              ,iv_token_value3  =>  SQLERRM                         -- トークン値3
                             );
               RAISE data_skip_expt;
           END;
--
           -- 初期化
           lv_ret_code      := cv_status_normal;
           lv_err_msg       := NULL;
--
           -- 5-13.共通関数「配車解除関数」により配車の解除を行います。(配車単位で重量オーバーの場合のみ解除)
           lv_ret_code := xxwsh_common_pkg.cancel_careers_schedule(
                            iv_biz_type     => cv_ship                         -- 1(出荷依頼)
                           ,iv_request_no   => l_get_ship_date_rec.request_no  -- 依頼No
                           ,iv_calcel_flag  => cv_cancel_flag_judge            -- 2(重量オーバーの場合のみ配車解除)
                           ,ov_errmsg       => lv_err_msg                      -- エラーメッセージ
                          );
           IF (  lv_ret_code <> cv_status_normal ) THEN
             -- メッセージ編集
             lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application   =>  cv_appl_name_xxwsh              -- アプリケーション短縮名
                            ,iv_name          =>  cv_msg_xxwsh_13222              -- メッセージコード
                            ,iv_token_name1   =>  cv_tkn_request_no               -- トークンコード1
                            ,iv_token_value1  =>  l_get_ship_date_rec.request_no  -- トークン値1
                            ,iv_token_name2   =>  cv_tkn_err_msg                  -- トークンコード2
                            ,iv_token_value2  =>  lv_err_msg                      -- トークン値2
                           );
             RAISE data_skip_expt;
           END IF;
--
           -- 5-14.拠点混載積載チェックを行います。(混載元Noに値がある場合のみ)
           IF ( gt_ship_line_data_tab(i).mixed_no IS NOT NULL ) THEN
--
             -- 初期化
             lt_based_w_mixed        := NULL;
             lt_sum_w_mixed          := NULL;
             lt_sum_pallet_w_mixed   := NULL;
             lt_small_amount_c_mixed := NULL;
             ln_chk_w_mixed_sum      := NULL;
--
             -- 5-14-1.混載元Noの依頼の情報を取得
             BEGIN
               SELECT  NVL( xoha.based_weight,      cn_0 )  based_weight        -- 基本重量
                      ,NVL( xoha.sum_weight,        cn_0 )  sum_weight          -- 積載重量合計
                      ,NVL( xoha.sum_pallet_weight, cn_0 )  sum_pallet_weight   -- 合計パレット重量
                      ,xhmv.small_amount_class              small_amount_class  -- 小口区分
               INTO    lt_based_w_mixed
                      ,lt_sum_w_mixed
                      ,lt_sum_pallet_w_mixed
                      ,lt_small_amount_c_mixed
               FROM    xxwsh_order_headers_all xoha
                      ,xxwsh_ship_method_v     xhmv
               WHERE   xoha.request_no           = gt_ship_line_data_tab(i).mixed_no
               AND     xoha.latest_external_flag = cv_yes
               AND     xoha.mixed_no             = xoha.request_no
               AND     xhmv.ship_method_code     = xoha.shipping_method_code
               ;
             EXCEPTION
               WHEN OTHERS THEN
                 -- メッセージ編集
                 lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application   =>  cv_appl_name_xxwsh                 -- アプリケーション短縮名
                                ,iv_name          =>  cv_msg_xxwsh_13240                 -- メッセージコード
                                ,iv_token_name1   =>  cv_tkn_request_no                  -- トークンコード1
                                ,iv_token_value1  =>  gt_ship_line_data_tab(i).mixed_no  -- トークン値1
                                ,iv_token_name2   =>  cv_tkn_err_msg                     -- トークンコード2
                                ,iv_token_value2  =>  SQLERRM                            -- トークン値2
                               );
                 RAISE data_skip_expt;
             END;
--
             -- 5-14-2.同一の混載Noの情報を取得
             SELECT  SUM(NVL(xoha.sum_weight,0))          -- 積載重量合計(混載No単位)
                    ,SUM(NVL(xoha.sum_pallet_weight,0))   -- 合計パレット重量(混載No単位)
             INTO    ln_w_mixed_sum
                    ,ln_p_mixed_sum
             FROM    xxwsh_order_headers_all xoha
             WHERE   xoha.mixed_no             =  gt_ship_line_data_tab(i).mixed_no
             AND     xoha.latest_external_flag =  cv_yes
             AND     xoha.mixed_no             <> xoha.request_no
             ;
--
             -- 5-14-3.同一の混載Noの積載重量のチェック
--
             -- 小口区分が小口の場合
             IF ( lt_small_amount_c_mixed = cv_amount_class_small ) THEN
               ln_chk_w_mixed_sum := lt_sum_w_mixed + ln_w_mixed_sum;  --パレット重量なし
             -- 小口区分が小口以外の場合
             ELSE
               ln_chk_w_mixed_sum := lt_sum_w_mixed + ln_w_mixed_sum + lt_sum_pallet_w_mixed + ln_p_mixed_sum;   --パレット重量あり
             END IF;
             -- 計算した積載重量合計 > 混載元の基本重量の場合
             IF ( ln_chk_w_mixed_sum > lt_based_w_mixed ) THEN
               -- メッセージ編集
               lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application   =>  cv_appl_name_xxwsh                 -- アプリケーション短縮名
                              ,iv_name          =>  cv_msg_xxwsh_13241                 -- メッセージコード
                              ,iv_token_name1   =>  cv_tkn_request_no                  -- トークンコード1
                              ,iv_token_value1  =>  gt_ship_line_data_tab(i).mixed_no  -- トークン値1
                              ,iv_token_name2   =>  cv_max_weight                      -- トークンコード2
                              ,iv_token_value2  =>  TO_CHAR( lt_based_w_mixed )        -- トークン値2
                              ,iv_token_name3   =>  cv_cur_weight                      -- トークンコード3
                              ,iv_token_value3  =>  TO_CHAR( ln_chk_w_mixed_sum )      -- トークン値3
                             );
               RAISE data_skip_expt;
             END IF;
--
           END IF;
--
          -- 成功件数カウント
          gn_normal_cnt   := gn_normal_cnt + ln_suc_line_cnt;
          -- 明細件数の初期化
          ln_suc_line_cnt := 0;
--
        END IF;
--
      EXCEPTION
        -- *** スキップデータ例外 ***
        WHEN data_skip_expt THEN
          -- 出力に表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ログに表示
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          -- スキップ件数カウント
          gn_skip_cnt     := gn_skip_cnt + ln_suc_line_cnt;
          -- 明細件数の初期化
          ln_suc_line_cnt := 0;
          -- 1件でもスキップデータがある場合は警告とする
          ov_retcode      := cv_status_warn;
          -- ロールバック
          ROLLBACK TO SAVEPOINT req_unit_save;
      END;
--
      -- 警告データがある場合、警告終了とする
      IF ( gn_skip_cnt > 0 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
    END LOOP upd_data_loop;
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
      IF ( get_ship_date_cur%ISOPEN ) THEN
        -- カーソルクローズ
        CLOSE get_ship_date_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_order_data;
--
  /**********************************************************************************
   * Procedure Name   : del_data
   * Description      : データ削除 (M-5)
   ***********************************************************************************/
  PROCEDURE del_data(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_data'; -- プログラム名
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
    -- *** ローカルユーザー定義例外 ***
    del_data_expt   EXCEPTION;     -- 削除エラー
    -- *** ローカル変数 ***
    lv_error_token  VARCHAR2(20);  -- トークンメッセージ格納用
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
    -- M-5.1 品目マスタ一括アップロードデータ削除
    --==============================================================
    BEGIN
      DELETE
      FROM   xxwsh_order_upload_work  xouw
      WHERE  xouw.request_id = cn_request_id
      ;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg      := SQLERRM;
        lv_error_token := cv_msg_xxwsh_13230;
        RAISE del_data_expt;
    END;
    --
    --==============================================================
    -- M-5.2 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      DELETE
      FROM  xxinv_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = gn_file_id
      ;
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg      := SQLERRM;
        lv_error_token := cv_msg_xxwsh_13226;
        RAISE del_data_expt;
    END;
  EXCEPTION
--
    WHEN del_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_name_xxwsh
                    ,iv_name          => cv_msg_xxwsh_13223
                    ,iv_token_name1   => cv_tkn_table     --パラメータ1(トークン)
                    ,iv_token_value1  => lv_error_token   --テーブル名
                    ,iv_token_name2   => cv_tkn_err_msg   --パラメータ2(トークン)
                    ,iv_token_value2  => lv_errmsg        --エラーメッセージ
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END del_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,     --   1.ファイルＩＤ
    iv_format     IN  VARCHAR2,     --   2.フォーマットパターン
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
    lv_warn_flag  VARCHAR2(1);
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_skip_cnt   := 0;
    -- ユーザ変数の初期化
    lv_warn_flag  := cv_no;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_file_id  => iv_file_id      -- ファイルＩＤ
      ,iv_format   => iv_format       -- フォーマットパターン
      ,ov_errbuf   => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードIFデータ取得(M-2)
    -- ===============================
    get_if_data(
       ov_errbuf   => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
--
    -- ===============================
    -- 出荷依頼データ取得(M-3)
    -- ===============================
    get_ship_request_data(
       ov_errbuf   => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
    -- ===============================
    -- 受注アドオン更新(M-4)
    -- ===============================
    upd_order_data(
       ov_errbuf   => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
    -- ===============================
    -- データ削除(M-5)
    -- ===============================
    del_data(
       ov_errbuf   => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 警告データがある場合は警告終了とする
    IF ( lv_warn_flag = cv_yes ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_id    IN  VARCHAR2,      --   1.ファイルＩＤ
    iv_format     IN  VARCHAR2       --   2.フォーマットパターン
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
       iv_file_id  -- ファイルＩＤ
      ,iv_format   -- フォーマットパターン
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- 件数設定
    gn_target_cnt := 0; -- 対象件数
    gn_normal_cnt := 0; -- 成功件数
    gn_skip_cnt   := 0; -- スキップ件数
    gn_error_cnt  := 1; -- エラー件数
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
END XXWSH400013C;
/
