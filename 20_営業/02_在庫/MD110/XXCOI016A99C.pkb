CREATE OR REPLACE PACKAGE BODY APPS.XXCOI016A99C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A99C(body)
 * Description      : ロット別出荷情報作成_移行用
 * MD.050           : -
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_tran_type          取引タイプ取得（ロット別取引TEMP登録処理またはA-12からの共通処理）
 *  ins_lot_tran_temp      ロット別取引TEMP登録処理（A-4またはA-17からの共通処理）
 *  reserve_process        引当処理（A-7からの共通処理）
 *  init                   初期処理(A-1)
 *  get_lock               ロック制御処理(A-2)
 *  get_reserve_data       引当対象データ取得処理(A-4)
 *  get_reserve_other_data 引当以外データ取得処理(A-17)
 *  chk_reserve_data       引当対象データチェック処理(A-5)
 *  get_item               子品目情報取得処理(A-6)
 *  inventory_reservation  引当対象在庫判定処理(A-7)
 *  chk_order              受注訂正チェック処理(A-8)
 *  ins_lot_transactions   ロット別取引明細登録処理(A-9)
 *  ref_lot_onhand         ロット別手持数量反映処理(A-10)
 *  ref_mst_lot_hold_info  ロット情報保持マスタ反映処理(A-11)
 *  ins_lot_reserve_info   ロット別引当情報登録処理(A-12)
 *  del_lot_reserve_info   ロット別引当情報削除処理(A-13)
 *  upd_lot_reserve_info   ロット別引当情報更新処理(A-14)
 *  upd_lot_reserve_info2  ロット別引当情報更新処理（出荷情報ステータス（受注番号単位））(A-15)
 *  upd_xcc                データ連携制御テーブル更新処理(A-18)
 *  submain                メイン処理プロシージャ
 *                           ロット別引当情報取得処理(A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/05/12    1.0   S.Yamashita       新規作成
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
  global_lock_expt          EXCEPTION; -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOI016A06C'; -- パッケージ名  -- 返品・訂正・過去データ用
-- Add Ver1.1 Start
  cv_pkg_name2              CONSTANT VARCHAR2(20) := 'XXCOI016B06C'; -- パッケージ名2 -- 引当用
-- Add Ver1.1 End
  -- アプリケーション短縮名
  cv_application            CONSTANT VARCHAR2(5)  := 'XXCOI';        -- アプリケーションXXCOI
  cv_application_xxcos      CONSTANT VARCHAR2(5)  := 'XXCOS';        -- アプリケーションXXCOS
  -- プロファイル
  cv_org_id                 CONSTANT VARCHAR2(30) := 'ORG_ID';                        -- MO:営業単位
  cv_organization_code      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- XXCOI:在庫組織コード
  cv_lot_reverse_mark       CONSTANT VARCHAR2(30) := 'XXCOI1_LOT_REVERSE_MARK';       -- XXCOI:ロット逆転記号
  cv_edi_order_source       CONSTANT VARCHAR2(30) := 'XXCOS1_EDI_ORDER_SOURCE';       -- XXCOS:EDI受注ソース
-- Add Ver1.1 Start
  cv_period_xxcoi016a06c1   CONSTANT VARCHAR2(30) := 'XXCOI1_PERIOD_XXCOI016A06C1';   -- XXCOI:引当データ取得期間
  cv_period_xxcoi016a06c5   CONSTANT VARCHAR2(30) := 'XXCOI1_PERIOD_XXCOI016A06C5';   -- XXCOI:返品・訂正・過去データ取得期間
-- Add Ver1.1 End
  -- クイックコード（タイプ）
  cv_priority_flag          CONSTANT VARCHAR2(30) := 'XXCOI1_PRIORITY_FLAG';          -- 優先ロケーション使用
  cv_lot_reversal_flag      CONSTANT VARCHAR2(30) := 'XXCOI1_LOT_REVERSAL_FLAG';      -- ロット逆転可否
  cv_xxcoi016a06_kbn        CONSTANT VARCHAR2(30) := 'XXCOI1_XXCOI016A06_KBN';        -- ロット別出荷情報作成判定区分
  cv_shipping_status        CONSTANT VARCHAR2(30) := 'XXCOI1_SHIPPING_STATUS';        -- 出荷情報ステータス
  cv_order_type_mst         CONSTANT VARCHAR2(30) := 'XXCOI1_ORDER_TYPE_MST_016_A06'; -- 受注タイプ特定マスタ_016_A06
  cv_no_inv_item_code       CONSTANT VARCHAR2(30) := 'XXCOS1_NO_INV_ITEM_CODE';       -- 非在庫品目
  cv_bargain_class          CONSTANT VARCHAR2(30) := 'XXCOS1_BARGAIN_CLASS';          -- 定番特売区分
  cv_sale_class_mst         CONSTANT VARCHAR2(30) := 'XXCOS1_SALE_CLASS_MST';         -- 売上区分特定マスタ
  cv_sale_class_mst_012a02  CONSTANT VARCHAR2(30) := 'XXCOS1_SALE_CLASS_MST_012_A02'; -- 売上区分特定マスタ_012_A02
  cv_red_black_flag         CONSTANT VARCHAR2(30) := 'XXCOS1_RED_BLACK_FLAG_007';     -- 赤黒フラグ
  -- クイックコード（コード）
  cv_xxcoi_016_a06          CONSTANT VARCHAR2(30) := 'XXCOI_016_A06%';                -- 受注タイプ特定
  cv_xxcos                  CONSTANT VARCHAR2(30) := 'XXCOS_%';                       -- コード
  -- メッセージ（COI）
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi_00011        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi_00032        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00032'; -- プロファイル値取得エラーメッセージ
  cv_msg_xxcoi_10130        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10130'; -- 従業員マスタ取得エラー
  cv_msg_xxcoi_10530        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10530'; -- 出荷情報ステータス名取得エラーメッセージ
  cv_msg_xxcoi_10531        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10531'; -- 着日逆転エラーメッセージ
  cv_msg_xxcoi_10532        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10532'; -- 着日過去日エラーメッセージ
  cv_msg_xxcoi_10533        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10533'; -- ロット別出荷情報作成（引当）コンカレント入力パラメータ1
  cv_msg_xxcoi_10534        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10534'; -- ロット別出荷情報作成（引当）コンカレント入力パラメータ2
  cv_msg_xxcoi_10535        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10535'; -- ロット別出荷情報作成（引当以外）コンカレント入力パラメータ1
  cv_msg_xxcoi_10536        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10536'; -- ロット別出荷情報作成（引当以外）コンカレント入力パラメータ2
  cv_msg_xxcoi_10537        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10537'; -- ロット別取引TEMP作成（返品訂正過去）メッセージ
  cv_msg_xxcoi_10538        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10538'; -- ロット別取引TEMP作成（仮確定後訂正）メッセージ
  cv_msg_xxcoi_10539        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10539'; -- 受注ヘッダID取得エラーメッセージ
  cv_msg_xxcoi_10540        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10540'; -- ロット別出荷情報作成処理対象データ無しメッセージ
  cv_msg_xxcoi_10541        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10541'; -- ロック対象保管場所存在エラーメッセージ
  cv_msg_xxcoi_10542        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10542'; -- ロット別出荷情報作成（保管場所指定あり）ロックエラーメッセージ
  cv_msg_xxcoi_10543        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10543'; -- ロット別出荷情報作成（保管場所指定なし）ロックエラーメッセージ
  cv_msg_xxcoi_10544        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10544'; -- 顧客別鮮度条件コード設定なしエラーメッセージ
  cv_msg_xxcoi_10545        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10545'; -- 共通関数エラーメッセージ
  cv_msg_xxcoi_10546        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10546'; -- 優先引当ロケーション存在エラーメッセージ
  cv_msg_xxcoi_10547        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10547'; -- 在庫数量不足エラーメッセージ
  cv_msg_xxcoi_10548        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10548'; -- ロット逆転エラーメッセージ
  cv_msg_xxcoi_10549        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10549'; -- ロット逆転（引当中）メッセージ
  cv_msg_xxcoi_10550        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10550'; -- 顧客鮮度条件エラーメッセージ
  cv_msg_xxcoi_10553        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10553'; -- 引当情報差異エラーメッセージ
  cv_msg_xxcoi_10554        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10554'; -- 赤黒フラグ取得エラーメッセージ
  cv_msg_xxcoi_10600        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10600'; -- ロット別手持数量存在エラーメッセージ
  cv_msg_xxcoi_10660        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10660'; -- ロット別取引TEMP作成対象なしメッセージ
  cv_msg_xxcoi_10662        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10662'; -- ロット別引当情報取消メッセージ
-- Mod Ver1.3 Start
  cv_msg_xxcoi_10703        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10703'; -- パラメータ必須エラーメッセージ
-- Mod Ver1.3 End
  -- メッセージ（COS）
  cv_msg_xxcos_00186        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00186'; -- 定番情報取得エラー
  cv_msg_xxcos_00187        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00187'; -- 特売情報取得エラー
  cv_msg_xxcos_11538        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-11538'; -- 受注ソース取得エラー
  cv_msg_xxcos_12005        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-12005'; -- 受注タイプ取得エラーメッセージ
  -- メッセージ（固定文字）
  cv_msg_xxcoi_10495        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10495'; -- ロット別取引明細作成
  cv_msg_xxcoi_10552        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10552'; -- 単位換算取得
  cv_msg_xxcoi_10559        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10559'; -- ロット別手持数量反映
  cv_msg_xxcoi_10560        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10560'; -- 鮮度条件基準日算出
  cv_msg_xxcoi_10561        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10561'; -- 引当可能数算出
  cv_msg_xxcoi_10562        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10562'; -- 品目情報導出（親／子）
  cv_msg_xxcoi_10563        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10563'; -- ロット情報保持マスタ反映
  -- トークン
  cv_tkn_pro_tok            CONSTANT VARCHAR2(20) := 'PRO_TOK';             -- プロファイル
  cv_tkn_org_code_tok       CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';        -- 在庫組織コード
  cv_tkn_order_source_name  CONSTANT VARCHAR2(20) := 'ORDER_SOURCE_NAME';   -- 受注ソース名
  cv_tkn_lookup_type        CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';         -- 参照タイプ
  cv_tkn_lookup_code        CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';         -- 参照コード
  cv_tkn_param1             CONSTANT VARCHAR2(20) := 'PARAM1';              -- パラメータ1
  cv_tkn_param2             CONSTANT VARCHAR2(20) := 'PARAM2';              -- パラメータ2
  cv_tkn_param3             CONSTANT VARCHAR2(20) := 'PARAM3';              -- パラメータ3
  cv_tkn_param4             CONSTANT VARCHAR2(20) := 'PARAM4';              -- パラメータ4
  cv_tkn_param5             CONSTANT VARCHAR2(20) := 'PARAM5';              -- パラメータ5
  cv_tkn_param6             CONSTANT VARCHAR2(20) := 'PARAM6';              -- パラメータ6
  cv_tkn_param7             CONSTANT VARCHAR2(20) := 'PARAM7';              -- パラメータ7
  cv_tkn_param8             CONSTANT VARCHAR2(20) := 'PARAM8';              -- パラメータ8
  cv_tkn_param9             CONSTANT VARCHAR2(20) := 'PARAM9';              -- パラメータ9
  cv_tkn_param10            CONSTANT VARCHAR2(20) := 'PARAM10';             -- パラメータ10
  cv_tkn_param_name1        CONSTANT VARCHAR2(20) := 'PARAM_NAME1';         -- パラメータ値1
  cv_tkn_param_name2        CONSTANT VARCHAR2(20) := 'PARAM_NAME2';         -- パラメータ値2
  cv_tkn_param_name3        CONSTANT VARCHAR2(20) := 'PARAM_NAME3';         -- パラメータ値3
  cv_tkn_param_name4        CONSTANT VARCHAR2(20) := 'PARAM_NAME4';         -- パラメータ値4
  cv_tkn_param_name5        CONSTANT VARCHAR2(20) := 'PARAM_NAME5';         -- パラメータ値5
  cv_tkn_param_name6        CONSTANT VARCHAR2(20) := 'PARAM_NAME6';         -- パラメータ値6
  cv_tkn_param_name7        CONSTANT VARCHAR2(20) := 'PARAM_NAME7';         -- パラメータ値7
  cv_tkn_param_name8        CONSTANT VARCHAR2(20) := 'PARAM_NAME8';         -- パラメータ値8
  cv_tkn_param_name9        CONSTANT VARCHAR2(20) := 'PARAM_NAME9';         -- パラメータ値9
  cv_tkn_param_name10       CONSTANT VARCHAR2(20) := 'PARAM_NAME10';        -- パラメータ値10
  cv_tkn_process            CONSTANT VARCHAR2(20) := 'PROCESS';             -- 処理
  cv_tkn_base_code          CONSTANT VARCHAR2(20) := 'BASE_CODE';           -- 拠点コード
  cv_tkn_subinventory_code  CONSTANT VARCHAR2(20) := 'SUBINVENTORY_CODE';   -- 保管場所コード
  cv_tkn_order_number       CONSTANT VARCHAR2(20) := 'ORDER_NUMBER';        -- 受注番号
  cv_tkn_order_number2      CONSTANT VARCHAR2(20) := 'ORDER_NUMBER_TARGET'; -- 引当中受注番号
  cv_tkn_line_number        CONSTANT VARCHAR2(20) := 'LINE_NUMBER';         -- 受注明細番号
  cv_tkn_chain_store_code   CONSTANT VARCHAR2(20) := 'CHAIN_STORE_CODE';    -- チェーン店コード
  cv_tkn_customer_code      CONSTANT VARCHAR2(20) := 'CUSTOMER_CODE';       -- 顧客コード
  cv_tkn_item_code          CONSTANT VARCHAR2(20) := 'ITEM_CODE';           -- 品目コード
  cv_tkn_order_quantity     CONSTANT VARCHAR2(20) := 'ORDER_QUANTITY';      -- 受注数量
  cv_tkn_quantity           CONSTANT VARCHAR2(20) := 'QUANTITY';            -- 数量
  cv_tkn_fresh_condition    CONSTANT VARCHAR2(20) := 'FRESH_CONDITION';     -- 鮮度条件
  cv_tkn_common_pkg         CONSTANT VARCHAR2(20) := 'COMMON_PKG';          -- 共通関数項目値
  cv_tkn_errmsg             CONSTANT VARCHAR2(20) := 'ERR_MSG';             -- エラーメッセージ
  cv_tkn_line_type          CONSTANT VARCHAR2(20) := 'LINE_TYPE';           -- 明細タイプ
  --
  cv_flag_y                 CONSTANT VARCHAR2(1)  := 'Y';
  cv_flag_n                 CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_c                 CONSTANT VARCHAR2(1)  := 'C';
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語
  -- 文字列
  cv_space                  CONSTANT VARCHAR2(1)  := ' ';     -- 半角スペース
  cv_under                  CONSTANT VARCHAR2(1)  := '_';     -- アンダースコア
  cv_dummy_item             CONSTANT VARCHAR2(5)  := 'DUMMY'; -- 判定用ダミー値
  -- 書式
  cv_yyyymmdd               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';            -- YYYY/MM/DD書式
  cv_yyyymmdd_hh24miss      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS'; -- YYYY/MM/DD HH24:MI:SS書式
  cv_weekno                 CONSTANT VARCHAR2(1)  := 'D';                     -- 曜日番号
  -- 顧客区分
  cv_customer_class_code_10 CONSTANT VARCHAR2(2)  := '10'; -- 顧客
  cv_customer_class_code_12 CONSTANT VARCHAR2(2)  := '12'; -- 上様顧客
  cv_customer_class_code_18 CONSTANT VARCHAR2(2)  := '18'; -- チェーン店
  -- 判定区分（パラメータから判定する判定）
  cv_kbn_1                  CONSTANT VARCHAR2(1)  := '1';  -- 引当
  cv_kbn_2                  CONSTANT VARCHAR2(1)  := '2';  -- 引当解除
  cv_kbn_3                  CONSTANT VARCHAR2(1)  := '3';  -- 出荷仮確定
  cv_kbn_4                  CONSTANT VARCHAR2(1)  := '4';  -- 出荷確定
  cv_kbn_5                  CONSTANT VARCHAR2(1)  := '5';  -- 返品・訂正・過去データ
  cv_kbn_6                  CONSTANT VARCHAR2(1)  := '6';  -- 仮確定後訂正
  -- 出荷情報ステータス
  cv_shipping_status_10     CONSTANT VARCHAR2(2)  := '10'; -- 引当未
  cv_shipping_status_20     CONSTANT VARCHAR2(2)  := '20'; -- 引当済
  cv_shipping_status_25     CONSTANT VARCHAR2(2)  := '25'; -- 出荷仮確定
  cv_shipping_status_30     CONSTANT VARCHAR2(2)  := '30'; -- 出荷確定
  -- 受注ステータス
  cv_entered                CONSTANT VARCHAR2(10) := 'ENTERED';   -- 入力中
  cv_booked                 CONSTANT VARCHAR2(10) := 'BOOKED';    -- 記帳済
  cv_cancelled              CONSTANT VARCHAR2(10) := 'CANCELLED'; -- 取消
  -- 受注タイプコード
  cv_order                  CONSTANT VARCHAR2(5)  := 'ORDER';
  cv_line                   CONSTANT VARCHAR2(5)  := 'LINE';
  cv_cancellation           CONSTANT VARCHAR2(15) := 'CANCELLATION';
  -- 曜日番号
  cv_weekno_sunday          CONSTANT VARCHAR2(1)  := '1'; -- 日曜日
  cv_weekno_monday          CONSTANT VARCHAR2(1)  := '2'; -- 月曜日
  cv_weekno_tuesday         CONSTANT VARCHAR2(1)  := '3'; -- 火曜日
  cv_weekno_wednesday       CONSTANT VARCHAR2(1)  := '4'; -- 水曜日
  cv_weekno_thursday        CONSTANT VARCHAR2(1)  := '5'; -- 木曜日
  cv_weekno_friday          CONSTANT VARCHAR2(1)  := '6'; -- 金曜日
  cv_weekno_saturday        CONSTANT VARCHAR2(1)  := '7'; -- 土曜日
  -- 取引区分（取引タイプ判定用）
  cv_tran_kbn_1             CONSTANT VARCHAR2(1)  := '1'; -- 受注
  cv_tran_kbn_2             CONSTANT VARCHAR2(1)  := '2'; -- 返品・返品訂正
  cv_tran_kbn_3             CONSTANT VARCHAR2(1)  := '3'; -- 訂正
  -- 処理区分（引当処理用）
  cv_process_kbn_1          CONSTANT VARCHAR2(1)  := '1'; -- 優先引当
  cv_process_kbn_2          CONSTANT VARCHAR2(1)  := '2'; -- 優先引当以外
  -- 営業生産区分
  cv_eigyo                  CONSTANT VARCHAR2(1)  := '1'; -- 営業
  -- 取消区分
  cv_cancel_kbn_0           CONSTANT VARCHAR2(1)  := '0'; -- 取消でない
  -- ロット別取引明細作成区分
  cv_lot_tran_kbn_0         CONSTANT VARCHAR2(1)  := '0'; -- ロット別取引明細未作成
  cv_lot_tran_kbn_1         CONSTANT VARCHAR2(1)  := '1'; -- ロット別取引明細作成済
  cv_lot_tran_kbn_9         CONSTANT VARCHAR2(1)  := '9'; -- 対象外（ロット別取引TEMPに作成）
  -- ロケーション
  cv_normal                 CONSTANT VARCHAR2(1)  := '1'; -- 通常ロケーション
  cv_priority               CONSTANT VARCHAR2(1)  := '2'; -- 優先引当ロケーション
  cv_dummy                  CONSTANT VARCHAR2(1)  := '3'; -- ダミーロケーション
  -- 赤黒フラグ
  cv_red                    CONSTANT VARCHAR2(1)  := '0'; -- 赤伝票
  cv_black                  CONSTANT VARCHAR2(1)  := '1'; -- 黒伝票
  -- 売上区分
  cv_sale_class_1           CONSTANT VARCHAR2(1)  := '1'; -- 通常
  cv_sale_class_2           CONSTANT VARCHAR2(1)  := '2'; -- 特売
  cv_sale_class_3           CONSTANT VARCHAR2(1)  := '3'; -- ベンダ売上
  cv_sale_class_4           CONSTANT VARCHAR2(1)  := '4'; -- 消化・VD消化
  cv_sale_class_5           CONSTANT VARCHAR2(1)  := '5'; -- 協賛
  cv_sale_class_6           CONSTANT VARCHAR2(1)  := '6'; -- 見本
  cv_sale_class_7           CONSTANT VARCHAR2(1)  := '7'; -- 広告宣伝費
  cv_sale_class_9           CONSTANT VARCHAR2(1)  := '9'; -- 補填商品の販売
  -- 定番特売区分
  cv_teiban                 CONSTANT VARCHAR2(2)  := '01';  -- 定番
  cv_tokubai                CONSTANT VARCHAR2(2)  := '02';  -- 特売
  -- 鮮度条件
  cv_cust_fresh_con_code_00 CONSTANT VARCHAR2(2)  := '00';  -- 一般
  -- 取引タイプ
  cv_tran_type_380          CONSTANT VARCHAR2(3)  := '380'; -- 出荷確定（引当）
  -- 引当時取引タイプコード
  cv_tran_type_code_170     CONSTANT VARCHAR2(3)  := '170'; -- 売上出庫
  cv_tran_type_code_180     CONSTANT VARCHAR2(3)  := '180'; -- 売上出庫振戻
  cv_tran_type_code_190     CONSTANT VARCHAR2(3)  := '190'; -- 返品
  cv_tran_type_code_200     CONSTANT VARCHAR2(3)  := '200'; -- 返品振戻
  cv_tran_type_code_320     CONSTANT VARCHAR2(3)  := '320'; -- 顧客見本出庫
  cv_tran_type_code_330     CONSTANT VARCHAR2(3)  := '330'; -- 顧客見本出庫振戻
  cv_tran_type_code_340     CONSTANT VARCHAR2(3)  := '340'; -- 顧客協賛見本出庫
  cv_tran_type_code_350     CONSTANT VARCHAR2(3)  := '350'; -- 顧客協賛見本出庫振戻
  cv_tran_type_code_360     CONSTANT VARCHAR2(3)  := '360'; -- 顧客広告宣伝費A自社商品
  cv_tran_type_code_370     CONSTANT VARCHAR2(3)  := '370'; -- 顧客広告宣伝費A自社商品振戻
  -- 符号区分
  cv_sign_div_0             CONSTANT VARCHAR2(1)  := '0';   -- 出庫
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  gt_item_info_tab          xxcoi_common_pkg.item_info_ttype; -- 品目情報格納配列
  --
  TYPE g_meaning_ttype IS TABLE OF fnd_lookup_values.meaning%TYPE INDEX BY PLS_INTEGER;
  gt_correct_tab            g_meaning_ttype;                -- 訂正受注タイプ格納配列
  gt_return_tab             g_meaning_ttype;                -- 返品受注タイプ格納配列
  --
  TYPE g_reserve_rtype IS RECORD(
      location_code           xxcoi_lot_reserve_info.location_code%TYPE
    , location_name           xxcoi_lot_reserve_info.location_name%TYPE
    , item_div                xxcoi_lot_reserve_info.item_div%TYPE
    , item_div_name           xxcoi_lot_reserve_info.item_div_name%TYPE
    , item_code               xxcoi_lot_reserve_info.item_code%TYPE
    , item_name               xxcoi_lot_reserve_info.item_name%TYPE
    , lot                     xxcoi_lot_reserve_info.lot%TYPE
    , difference_summary_code xxcoi_lot_reserve_info.difference_summary_code%TYPE
    , case_in_qty             xxcoi_lot_reserve_info.case_in_qty%TYPE
    , case_qty                xxcoi_lot_reserve_info.case_qty%TYPE
    , singly_qty              xxcoi_lot_reserve_info.singly_qty%TYPE
    , summary_qty             xxcoi_lot_reserve_info.summary_qty%TYPE
    , mark                    xxcoi_lot_reserve_info.mark%TYPE
    , item_id                 xxcoi_lot_reserve_info.item_id%TYPE
    , short_case_in_qty       xxcoi_lot_reserve_info.short_case_in_qty%TYPE
    , short_case_qty          xxcoi_lot_reserve_info.short_case_qty%TYPE
    , short_singly_qty        xxcoi_lot_reserve_info.short_singly_qty%TYPE
    , short_summary_qty       xxcoi_lot_reserve_info.short_summary_qty%TYPE
  );
  TYPE g_reserve_ttype      IS TABLE OF g_reserve_rtype INDEX BY PLS_INTEGER;
  gt_reserve_tab            g_reserve_ttype;
  --
  TYPE g_order_number_ttype IS TABLE OF xxcoi_lot_reserve_info.order_number%TYPE INDEX BY PLS_INTEGER;
  gt_order_number_tab       g_order_number_ttype;
  --
  TYPE g_lot_id_ttype IS TABLE OF xxcoi_lot_reserve_info.lot_reserve_info_id%TYPE INDEX BY PLS_INTEGER;
  gt_lot_id_tab             g_lot_id_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_debug_cnt              NUMBER                                                    DEFAULT 0;     -- デバッグログ出力用
  gn_target_10_cnt          NUMBER                                                    DEFAULT 0;     -- 対象件数（引当未）
  gn_target_20_cnt          NUMBER                                                    DEFAULT 0;     -- 対象件数（引当済）
  gn_normal_10_cnt          NUMBER                                                    DEFAULT 0;     -- 成功件数（引当未）
  gn_normal_20_cnt          NUMBER                                                    DEFAULT 0;     -- 成功件数（引当済）
  gn_create_temp_cnt        NUMBER                                                    DEFAULT 0;     -- ロット別取引TEMP作成件数
  gn_reserve_cnt            NUMBER                                                    DEFAULT 0;     -- 引当情報格納配列用添え字
  gv_retcode                VARCHAR2(1)                                               DEFAULT NULL;  -- 引当結果登録用判定コード
  gv_reserve_err_msg        VARCHAR2(16)                                              DEFAULT NULL;  -- 引当処理にてエラー発生時のメッセージコードを格納
  gb_warn_flag              BOOLEAN                                                   DEFAULT FALSE; -- 警告フラグ
  gd_process_date           DATE                                                      DEFAULT NULL;  -- 業務日付
  gd_last_deliver_lot       DATE                                                      DEFAULT NULL;  -- ロット情報保持マスタ_納品ロット
  gd_delivery_date          DATE                                                      DEFAULT NULL;  -- ロット情報保持マスタ_納品日
  gt_organization_code      mtl_parameters.organization_code%TYPE                     DEFAULT NULL;  -- 在庫組織コード
  gt_organization_id        mtl_parameters.organization_id%TYPE                       DEFAULT NULL;  -- 在庫組織ID
  gt_org_id                 fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- MO:営業単位
  gt_lot_reverse_mark       fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- XXCOI:ロット逆転記号
  gt_order_source_id        oe_order_sources.order_source_id%TYPE                     DEFAULT NULL;  -- EDI受注ソースID
-- Add Ver1.1 Start
  gt_period_xxcoi016a06c1   fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- XXCOI:引当データ取得期間
  gt_period_xxcoi016a06c5   fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- XXCOI:返品・訂正・過去データ取得期間
-- Add Ver1.1 End
  gt_teiban_name            fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- 定番特売区分：定番
  gt_tokubai_name           fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- 定番特売区分：特売
  gt_shipping_status_10     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- 出荷情報ステータス：引当未
  gt_shipping_status_20     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- 出荷情報ステータス：引当済
  gt_shipping_status_25     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- 出荷情報ステータス：出荷仮確定
  gt_shipping_status_30     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- 出荷情報ステータス：出荷確定済
  gt_employee_number        per_all_people_f.employee_number%TYPE                     DEFAULT NULL;  -- 従業員コード
  gv_employee_name          VARCHAR2(301)                                             DEFAULT NULL;  -- 従業員名
  gt_max_header_id          xxcoi_lot_reserve_info.header_id%TYPE                     DEFAULT NULL;  -- 受注ヘッダID
  gt_cust_fresh_con_code    xxcmm_cust_accounts.cust_fresh_con_code%TYPE              DEFAULT NULL;  -- 顧客別鮮度条件コード
  gt_order_case_in_qty      xxcoi_lot_reserve_info.case_in_qty%TYPE                   DEFAULT 0;     -- 受注入数
  gt_order_case_qty         xxcoi_lot_reserve_info.case_qty%TYPE                      DEFAULT 0;     -- 受注ケース数
  gt_order_singly_qty       xxcoi_lot_reserve_info.singly_qty%TYPE                    DEFAULT 0;     -- 受注バラ数
  gt_order_summary_qty      xxcoi_lot_reserve_info.summary_qty%TYPE                   DEFAULT 0;     -- 受注総数
  -- パラメータ
  gv_login_base_code        VARCHAR2(4)                                               DEFAULT NULL;  -- 拠点
  gd_delivery_date_from     DATE                                                      DEFAULT NULL;  -- 着日From
  gd_delivery_date_to       DATE                                                      DEFAULT NULL;  -- 着日To
  gv_login_chain_store_code VARCHAR2(4)                                               DEFAULT NULL;  -- チェーン店
  gv_login_customer_code    VARCHAR2(9)                                               DEFAULT NULL;  -- 顧客
  gv_customer_po_number     VARCHAR2(12)                                              DEFAULT NULL;  -- 顧客発注番号
  gv_subinventory_code      VARCHAR2(10)                                              DEFAULT NULL;  -- 保管場所
  gv_priority_flag          VARCHAR2(1)                                               DEFAULT NULL;  -- 優先ロケーション使用
  gv_lot_reversal_flag      VARCHAR2(1)                                               DEFAULT NULL;  -- ロット逆転可否
  gv_kbn                    VARCHAR2(1)                                               DEFAULT NULL;  -- 判定区分
  gt_base_name              xxcos_login_base_info_v.base_name%TYPE                    DEFAULT NULL;  -- 拠点名
  gt_xxcoi016a06_kbn        fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- 判定区分_内容
-- Add Ver1.3 Start
  TYPE g_del_id_ttype       IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  g_del_id_tab              g_del_id_ttype; -- ロット別引当情報削除情報
-- Add Ver1.3 End
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 引当対象取得カーソル
  CURSOR g_kbn_1_cur
  IS
    SELECT xtlri.slip_num                     AS slip_num                     -- 伝票No
         , xtlri.order_number                 AS order_number                 -- 受注番号
         , xtlri.whse_code                    AS whse_code                    -- 保管場所コード
         , xtlri.whse_name                    AS whse_name                    -- 保管場所名
         , xtlri.chain_code                   AS chain_code                   -- チェーン店コード
         , xtlri.chain_name                   AS chain_name                   -- チェーン店名
         , xtlri.cust_fresh_con_code_chain    AS cust_fresh_con_code_chain    -- 顧客別鮮度条件コード（チェーン店）
         , xtlri.shop_code                    AS shop_code                    -- 店舗コード
         , xtlri.shop_name                    AS shop_name                    -- 店舗名
         , xtlri.customer_code                AS customer_code                -- 顧客コード
         , xtlri.customer_name                AS customer_name                -- 顧客名
         , xtlri.cust_fresh_con_code_cust     AS cust_fresh_con_code_cust     -- 顧客別鮮度条件コード（顧客）
         , xtlri.center_code                  AS center_code                  -- センターコード
         , xtlri.center_name                  AS center_name                  -- センター名
         , xtlri.area_code                    AS area_code                    -- 地区コード
         , xtlri.area_name                    AS area_name                    -- 地区名
         , xtlri.shipped_date                 AS shipped_date                 -- 出荷日
         , xtlri.arrival_date                 AS arrival_date                 -- 着日
         , xtlri.parent_item_id               AS parent_item_id               -- 親品目ID
         , xtlri.parent_item_code             AS parent_item_code             -- 親品目コード
         , xtlri.parent_item_name             AS parent_item_name             -- 親品目名称
         , xtlri.item_code                    AS item_code                    -- 子品目コード
         , xtlri.regular_sale_class_line      AS regular_sale_class_line      -- 定番特売区分(明細)
         , xtlri.regular_sale_class_name_line AS regular_sale_class_name_line -- 定番特売区分名(明細)
         , xtlri.edi_received_date            AS edi_received_date            -- EDI受信日
         , xtlri.delivery_order_edi           AS delivery_order_edi           -- 配送順(EDI)
         , xtlri.before_ordered_quantity      AS before_ordered_quantity      -- 訂正前受注数量
         , xtlri.header_id                    AS header_id                    -- 受注ヘッダID
         , xtlri.line_id                      AS line_id                      -- 受注明細ID
         , xtlri.line_number                  AS line_number                  -- 受注明細番号
         , xtlri.line_type                    AS line_type                    -- 明細タイプ
         , xtlri.customer_id                  AS customer_id                  -- 顧客ID
         , xtlri.ordered_quantity             AS ordered_quantity             -- 受注数
         , xtlri.order_quantity_uom           AS order_quantity_uom           -- 受注単位
    FROM   xxcoi_tmp_lot_reserve_info xtlri
    ORDER BY xtlri.arrival_date
           , xtlri.chain_code
           , xtlri.shop_code
           , xtlri.customer_code
           , xtlri.order_number
           , xtlri.line_number
  ;
  -- 引当解除対象取得カーソル
  CURSOR g_kbn_2_cur
  IS
    SELECT xlri.rowid             AS xlri_rowid      -- ROWID
         , xlri.shipping_status   AS shipping_status -- 出荷情報ステータス
    FROM   xxcoi_lot_reserve_info xlri
    WHERE  xlri.shipping_status IN ( cv_shipping_status_10, cv_shipping_status_20 )
    AND    xlri.base_code       = gv_login_base_code
    AND    xlri.arrival_date   >= gd_delivery_date_from
    AND    xlri.arrival_date   <  gd_delivery_date_to + 1
    AND ( ( gv_login_chain_store_code IS NULL )
       OR ( xlri.chain_code     = gv_login_chain_store_code ) )
    AND ( ( gv_login_customer_code IS NULL )
       OR ( xlri.customer_code  = gv_login_customer_code ) )
    AND ( ( gv_customer_po_number IS NULL )
       OR ( xlri.slip_num       = gv_customer_po_number ) )
    AND EXISTS ( SELECT 1
                 FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                 WHERE  xtlrs.subinventory_code = xlri.whse_code )
  ;
  -- 出荷仮確定対象取得カーソル
  CURSOR g_kbn_3_cur
  IS
    SELECT xlri.lot_reserve_info_id           AS lot_reserve_info_id            -- ロット別引当情報ID
         , xlri.slip_num                      AS slip_num                       -- 伝票No
         , xlri.order_number                  AS order_number                   -- 受注番号
-- Add Ver1.3 Start
         , xlri.parent_shipping_status        AS parent_shipping_status         -- 出荷情報ステータス（受注番号単位）
-- Add Ver1.3 End
         , xlri.whse_code                     AS whse_code                      -- 保管場所コード
         , xlri.location_code                 AS location_code                  -- ロケーションコード
         , xlri.arrival_date                  AS arrival_date                   -- 着日
         , xlri.parent_item_id                AS parent_item_id                 -- 親品目ID
         , xlri.parent_item_code              AS parent_item_code               -- 親品目コード
         , xlri.item_id                       AS item_id                        -- 子品目ID
         , xlri.item_code                     AS item_code                      -- 子品目コード
         , xlri.lot                           AS lot                            -- ロット
         , xlri.difference_summary_code       AS difference_summary_code        -- 固有記号
         , xlri.case_in_qty                   AS case_in_qty                    -- 入数
         , xlri.case_qty                      AS case_qty                       -- ケース数
         , xlri.singly_qty                    AS singly_qty                     -- バラ数
         , xlri.summary_qty                   AS summary_qty                    -- 数量
         , xlri.header_id                     AS header_id                      -- 受注ヘッダID
         , xlri.line_id                       AS line_id                        -- 受注明細ID
         , xlri.customer_id                   AS customer_id                    -- 顧客ID
         , xlri.reserve_transaction_type_code AS reserve_transaction_type_code  -- 引当時取引タイプコード
         , xlri.ordered_quantity              AS ordered_quantity               -- 受注数量
    FROM   xxcoi_lot_reserve_info             xlri
-- Mod Ver1.3 Start
--    WHERE  xlri.parent_shipping_status = cv_shipping_status_20
    WHERE  xlri.parent_shipping_status IN ( cv_shipping_status_10, cv_shipping_status_20 )
-- Mod Ver1.3 End
    AND    xlri.base_code              = gv_login_base_code
    AND    xlri.arrival_date          >= gd_delivery_date_from
    AND    xlri.arrival_date          <  gd_delivery_date_to + 1
    AND ( ( gv_login_chain_store_code IS NULL )
       OR ( xlri.chain_code            = gv_login_chain_store_code ) )
    AND ( ( gv_login_customer_code IS NULL )
       OR ( xlri.customer_code         = gv_login_customer_code ) )
    AND ( ( gv_customer_po_number IS NULL )
       OR ( xlri.slip_num              = gv_customer_po_number ) )
    AND EXISTS ( SELECT 1
                 FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                 WHERE  xtlrs.subinventory_code = xlri.whse_code )
    ORDER BY xlri.order_number
  ;
-- Add Ver1.1 Start
  -- 出荷確定更新カーソル
  CURSOR g_kbn_4_2_cur
  IS
    SELECT xlri.lot_reserve_info_id AS lot_reserve_info_id
         , xlri.lot_tran_kbn        AS lot_tran_kbn
    FROM   xxcoi_lot_reserve_info   xlri
    WHERE  xlri.parent_shipping_status = cv_shipping_status_25
    AND    xlri.arrival_date           < gd_delivery_date_from + 1
  ;
-- Add Ver1.1 End
  -- 出荷確定対象取得カーソル
  CURSOR g_kbn_4_cur
  IS
    SELECT xlri.lot_reserve_info_id           AS lot_reserve_info_id
         , xlri.slip_num                      AS slip_num
         , xlri.order_number                  AS order_number
         , xlri.base_code                     AS base_code
         , xlri.whse_code                     AS whse_code
         , xlri.location_code                 AS location_code
         , xlri.arrival_date                  AS arrival_date
         , xlri.parent_item_id                AS parent_item_id
         , xlri.parent_item_code              AS parent_item_code
         , xlri.item_id                       AS item_id
         , xlri.item_code                     AS item_code
         , xlri.lot                           AS lot
         , xlri.difference_summary_code       AS difference_summary_code
         , xlri.case_in_qty                   AS case_in_qty
         , xlri.case_qty                      AS case_qty
         , xlri.singly_qty                    AS singly_qty
         , xlri.summary_qty                   AS summary_qty
         , xlri.header_id                     AS header_id
         , xlri.line_id                       AS line_id
         , xlri.customer_id                   AS customer_id
         , xlri.reserve_transaction_type_code AS reserve_transaction_type_code
         , xlri.ordered_quantity              AS ordered_quantity
    FROM   xxcoi_lot_reserve_info             xlri
-- Mod Ver1.1 Start
--    WHERE  xlri.parent_shipping_status = cv_shipping_status_25
    WHERE  xlri.parent_shipping_status = cv_shipping_status_30
    AND    xlri.lot_tran_kbn           = cv_lot_tran_kbn_1
    AND    xlri.request_id             = cn_request_id
-- Mod Ver1.1 End
    AND    xlri.arrival_date           < gd_delivery_date_from + 1
  ;
--
  /**********************************************************************************
   * Procedure Name   : get_tran_type
   * Description      : 取引タイプ取得（ロット別取引TEMP登録処理またはA-12からの共通処理）
   ***********************************************************************************/
  PROCEDURE get_tran_type(
      iv_tran_kbn                IN  VARCHAR2  -- 取引区分
    , iv_line_name               IN  VARCHAR2  -- 明細摘要
    , iv_sale_class              IN  VARCHAR2  -- 売上区分
    , ion_order_case_qty         IN OUT NUMBER -- ケース数
    , ion_order_singly_qty       IN OUT NUMBER -- バラ数
    , ion_after_quantity         IN OUT NUMBER -- 総数
    , ov_tran_type_code_temp     OUT VARCHAR2  -- 取引タイプコード
    , ov_tran_type_code          OUT VARCHAR2  -- 引当時取引タイプコード
    , ov_errbuf                  OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode                 OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg                  OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tran_type'; -- プログラム名
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
    -- *** ローカル変数 ***
    lt_red_black_flag          fnd_lookup_values.attribute1%TYPE                         DEFAULT NULL; -- 赤黒フラグ
    lt_tran_type_code_temp     xxcoi_lot_transactions_temp.transaction_type_code%TYPE    DEFAULT NULL; -- 取引タイプコード
    lt_tran_type_code          xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE DEFAULT NULL; -- 引当時取引タイプコード
--
    -- *** ローカルカーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 赤黒フラグ取得
    BEGIN
      SELECT flv.attribute1    AS attribute1
      INTO   lt_red_black_flag
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type                            = cv_red_black_flag
      AND    flv.meaning                                = iv_line_name
      AND    flv.language                               = ct_lang
      AND    flv.enabled_flag                           = cv_flag_y
      AND    flv.start_date_active                     <= gd_process_date
      AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- データ抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10554
                       , iv_token_name1  => cv_tkn_line_type
                       , iv_token_value1 => iv_line_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 返品・返品訂正
    IF ( iv_tran_kbn = cv_tran_kbn_2 ) THEN
      lt_tran_type_code_temp := cv_tran_type_380;
      -- 黒伝票
      IF ( lt_red_black_flag = cv_black ) THEN
        lt_tran_type_code    := cv_tran_type_code_190;
        -- 返品の黒は数量反転
        ion_order_case_qty   := ion_order_case_qty   * (-1);
        ion_order_singly_qty := ion_order_singly_qty * (-1);
        ion_after_quantity   := ion_after_quantity   * (-1);
      -- 赤伝票
      ELSIF ( lt_red_black_flag = cv_red ) THEN
        lt_tran_type_code    := cv_tran_type_code_200;
        -- 返品の赤はそのまま
        ion_order_case_qty   := ion_order_case_qty;
        ion_order_singly_qty := ion_order_singly_qty;
        ion_after_quantity   := ion_after_quantity;
      END IF;
    -- 受注・訂正
    ELSE
      lt_tran_type_code_temp := cv_tran_type_380;
      IF ( lt_red_black_flag = cv_black ) THEN
        IF ( iv_sale_class IN ( cv_teiban, cv_tokubai, cv_sale_class_1, cv_sale_class_2, cv_sale_class_3, cv_sale_class_4, cv_sale_class_9 ) ) THEN
          lt_tran_type_code := cv_tran_type_code_170;
        ELSIF ( iv_sale_class = cv_sale_class_6 ) THEN
          lt_tran_type_code := cv_tran_type_code_320;
        ELSIF ( iv_sale_class = cv_sale_class_5 ) THEN
          lt_tran_type_code := cv_tran_type_code_340;
        ELSIF ( iv_sale_class = cv_sale_class_7 ) THEN
          lt_tran_type_code := cv_tran_type_code_360;
        END IF;
        -- 受注の黒はそのまま
        ion_order_case_qty   := ion_order_case_qty;
        ion_order_singly_qty := ion_order_singly_qty;
        ion_after_quantity   := ion_after_quantity;
      ELSIF ( lt_red_black_flag = cv_red ) THEN
        IF ( iv_sale_class IN ( cv_teiban, cv_tokubai, cv_sale_class_1, cv_sale_class_2, cv_sale_class_3, cv_sale_class_4, cv_sale_class_9 ) ) THEN
          lt_tran_type_code := cv_tran_type_code_180;
        ELSIF ( iv_sale_class = cv_sale_class_6 ) THEN
          lt_tran_type_code := cv_tran_type_code_330;
        ELSIF ( iv_sale_class = cv_sale_class_5 ) THEN
          lt_tran_type_code := cv_tran_type_code_350;
        ELSIF ( iv_sale_class = cv_sale_class_7 ) THEN
          lt_tran_type_code := cv_tran_type_code_370;
        END IF;
        -- 受注の赤は数量反転
        ion_order_case_qty   := ion_order_case_qty   * (-1);
        ion_order_singly_qty := ion_order_singly_qty * (-1);
        ion_after_quantity   := ion_after_quantity   * (-1);
      END IF;
    END IF;
    --
    -- 戻り値
    ov_tran_type_code_temp := lt_tran_type_code_temp;
    ov_tran_type_code      := lt_tran_type_code;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_tran_type;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_tran_temp
   * Description      : ロット別取引TEMP登録処理（A-4またはA-17からの共通処理）
   ***********************************************************************************/
  PROCEDURE ins_lot_tran_temp(
      iv_tran_kbn           IN  VARCHAR2  -- 取引区分
    , in_header_id          IN  NUMBER    -- 受注ヘッダID
    , in_line_id            IN  NUMBER    -- 受注明細ID
    , iv_slip_num           IN  VARCHAR2  -- 伝票No
    , iv_order_number       IN  VARCHAR2  -- 受注番号
    , iv_line_number        IN  VARCHAR2  -- 受注明細号
    , id_arrival_date       IN  DATE      -- 着日
    , iv_parent_item_code   IN  VARCHAR2  -- 親品目コード
    , iv_item_code          IN  VARCHAR2  -- 子品目コード
    , in_parent_item_id     IN  NUMBER    -- 親品目ID
    , iv_order_quantity_uom IN  VARCHAR2  -- 受注単位
    , in_ordered_quantity   IN  NUMBER    -- 受注数量
    , iv_base_code          IN  VARCHAR2  -- 拠点コード
    , iv_subinventory_code  IN  VARCHAR2  -- 保管場所コード
    , iv_line_name          IN  VARCHAR2  -- 明細摘要
    , iv_sale_class         IN  VARCHAR2  -- 定番特売区分(明細)
    , iv_flow_status_code   IN  VARCHAR2  -- 明細ステータス
    , ov_errbuf             OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode            OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg             OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_tran_temp'; -- プログラム名
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
    -- *** ローカル変数 ***
    lt_item_code               mtl_system_items_b.segment1%TYPE                          DEFAULT NULL; -- 品目コード
    lt_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE                 DEFAULT NULL; -- 品目ID
    lt_after_uom_code          mtl_units_of_measure_tl.uom_code%TYPE                     DEFAULT NULL; -- 換算後単位コード
    ln_after_quantity          NUMBER                                                    DEFAULT 0;    -- 換算後数量
    ln_content                 NUMBER                                                    DEFAULT 0;    -- 受注入数
    ln_order_case_qty          NUMBER                                                    DEFAULT 0;    -- 受注ケース数
    ln_order_singly_qty        NUMBER                                                    DEFAULT 0;    -- 受注バラ数
    lt_tran_type_code_temp     xxcoi_lot_transactions_temp.transaction_type_code%TYPE    DEFAULT NULL; -- 取引タイプコード
    lt_tran_type_code          xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE DEFAULT NULL; -- 引当時取引タイプコード
    lt_trx_id                  xxcoi_lot_transactions_temp.transaction_id%TYPE           DEFAULT NULL; -- 取引ID
--
    -- *** ローカルカーソル ***
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
    -- 1．ロット別取引TEMP削除
    --==============================================================
    DELETE FROM xxcoi_lot_transactions_temp xltt
    WHERE xltt.source_code  = cv_pkg_name
    AND   xltt.relation_key = in_header_id || cv_under || in_line_id
    ;
    -- 取消の場合、削除のみ
    IF ( iv_flow_status_code = cv_cancelled ) THEN
      -- 仮確定後訂正の場合
      IF ( gv_kbn = cv_kbn_6 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10662
                       , iv_token_name1  => cv_tkn_order_number
                       , iv_token_value1 => iv_order_number
                       , iv_token_name2  => cv_tkn_line_number
                       , iv_token_value2 => iv_line_number
                     );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg
        );
      END IF;
    -- 取消以外の場合
    ELSE
      -- 子品目コードがNULLの場合
      IF ( iv_item_code IS NULL ) THEN
        lt_item_code         := iv_parent_item_code;
        lt_inventory_item_id := in_parent_item_id;
      ELSE
        lt_item_code         := iv_item_code;
        lt_inventory_item_id := NULL;
      END IF;
      --
      --==============================================================
      -- 2．単位換算取得
      --==============================================================
      xxcos_common_pkg.get_uom_cnv(
          iv_before_uom_code    => iv_order_quantity_uom -- 換算前単位コード
        , in_before_quantity    => in_ordered_quantity   -- 換算前数量
        , iov_item_code         => lt_item_code          -- 品目コード
        , iov_organization_code => gt_organization_code  -- 在庫組織コード
        , ion_inventory_item_id => lt_inventory_item_id  -- 品目ＩＤ
        , ion_organization_id   => gt_organization_id    -- 在庫組織ＩＤ
        , iov_after_uom_code    => lt_after_uom_code     -- 換算後単位コード
        , on_after_quantity     => ln_after_quantity     -- 換算後数量
        , on_content            => ln_content            -- 入数
        , ov_errbuf             => lv_errbuf             -- エラー・メッセージエラー       #固定#
        , ov_retcode            => lv_retcode            -- リターン・コード               #固定#
        , ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ   #固定#
      );
      -- リターンコードが正常以外の場合、エラー
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10545
                       , iv_token_name1  => cv_tkn_common_pkg
                       , iv_token_value1 => cv_msg_xxcoi_10552
                       , iv_token_name2  => cv_tkn_errmsg
                       , iv_token_value2 => lv_errmsg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      --==============================================================
      -- 3．入数取得
      --==============================================================
      -- 単位換算の入数は正しくないため取得
      SELECT TO_NUMBER(iimb.attribute11) AS attribute11
      INTO   ln_content
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no = lt_item_code
      ;
      -- ケース数・バラ数変換
      ln_order_case_qty   := TRUNC( ln_after_quantity / ln_content );
      ln_order_singly_qty := MOD( ln_after_quantity, ln_content );
      --
      --==============================================================
      -- 4．取引タイプ取得
      --==============================================================
      get_tran_type(
          iv_tran_kbn            => iv_tran_kbn            -- 取引区分
        , iv_line_name           => iv_line_name           -- 明細摘要
        , iv_sale_class          => iv_sale_class          -- 売上区分
        , ion_order_case_qty     => ln_order_case_qty      -- ケース数
        , ion_order_singly_qty   => ln_order_singly_qty    -- バラ数
        , ion_after_quantity     => ln_after_quantity      -- 総数
        , ov_tran_type_code_temp => lt_tran_type_code_temp -- 取引タイプコード
        , ov_tran_type_code      => lt_tran_type_code      -- 引当時取引タイプコード
        , ov_errbuf              => lv_errbuf              -- エラー・メッセージ
        , ov_retcode             => lv_retcode             -- リターン・コード
        , ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      --==============================================================
      -- 5．ロット別取引TEMP作成
      --==============================================================
      xxcoi_common_pkg.cre_lot_trx_temp(
          in_trx_set_id       => NULL                                   -- 取引セットID
        , iv_parent_item_code => iv_parent_item_code                    -- 親品目コード
        , iv_child_item_code  => iv_item_code                           -- 子品目コード
        , iv_lot              => NULL                                   -- ロット(賞味期限)
        , iv_diff_sum_code    => NULL                                   -- 固有記号
        , iv_trx_type_code    => lt_tran_type_code                      -- 取引タイプコード
        , id_trx_date         => id_arrival_date                        -- 取引日
        , iv_slip_num         => iv_slip_num                            -- 伝票No
        , in_case_in_qty      => ln_content                             -- 入数
        , in_case_qty         => ln_order_case_qty                      -- ケース数
        , in_singly_qty       => ln_order_singly_qty                    -- バラ数
        , in_summary_qty      => ln_after_quantity                      -- 取引数量
        , iv_base_code        => iv_base_code                           -- 拠点コード
        , iv_subinv_code      => iv_subinventory_code                   -- 保管場所コード
        , iv_tran_subinv_code => NULL                                   -- 転送先保管場所コード
        , iv_tran_loc_code    => NULL                                   -- 転送先ロケーションコード
        , iv_inout_code       => NULL                                   -- 入出庫コード
        , iv_source_code      => cv_pkg_name                            -- ソースコード
        , iv_relation_key     => in_header_id || cv_under || in_line_id -- 紐付けキー
        , on_trx_id           => lt_trx_id                              -- ロット別取引明細
        , ov_errbuf           => lv_errbuf                              -- エラーメッセージ
        , ov_retcode          => lv_retcode                             -- リターンコード
        , ov_errmsg           => lv_errmsg                              -- ユーザー・エラー・メッセージ
      );
      -- リターンコードが正常の場合
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 件数
        gn_create_temp_cnt := gn_create_temp_cnt + 1;
        -- 返品・訂正・過去データの場合
        IF ( gv_kbn = cv_kbn_5 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10537
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => iv_order_number
                         , iv_token_name2  => cv_tkn_line_number
                         , iv_token_value2 => iv_line_number
                       );
        -- 仮確定後訂正の場合
        ELSIF ( gv_kbn = cv_kbn_6 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10538
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => iv_order_number
                         , iv_token_name2  => cv_tkn_line_number
                         , iv_token_value2 => iv_line_number
                       );
        END IF;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg
        );
      -- リターンコードが正常以外の場合、エラー
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10545
                       , iv_token_name1  => cv_tkn_common_pkg
                       , iv_token_value1 => cv_msg_xxcoi_10495
                       , iv_token_name2  => cv_tkn_errmsg
                       , iv_token_value2 => lv_errmsg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_lot_tran_temp;
--
  /**********************************************************************************
   * Procedure Name   : reserve_process
   * Description      : 引当処理（A-7からの共通処理）
   ***********************************************************************************/
  PROCEDURE reserve_process(
      iv_process_kbn             IN  VARCHAR2  -- 処理区分
    , iv_subinventory_code       IN  VARCHAR2  -- 保管場所コード
    , iv_location_code           IN  VARCHAR2  -- ロケーションコード
    , iv_location_name           IN  VARCHAR2  -- ロケーション名
    , iv_item_div                IN  VARCHAR2  -- 商品区分
    , iv_item_div_name           IN  VARCHAR2  -- 商品区分名
    , in_item_id                 IN  NUMBER    -- 子品目ID
    , iv_item_code               IN  VARCHAR2  -- 子品目コード
    , iv_item_name               IN  VARCHAR2  -- 子品目名
    , iv_lot                     IN  VARCHAR2  -- ロット
    , iv_difference_summary_code IN  VARCHAR2  -- 固有記号
    , id_production_date         IN  DATE      -- 製造日
    , id_arrival_date            IN  DATE      -- 納品日
    , iv_order_number            IN  VARCHAR2  -- 受注番号
    , iv_customer_code           IN  VARCHAR2  -- 顧客コード
    , iv_parent_item_code        IN  VARCHAR2  -- 親品目コード
    , ion_short_case_qty         IN OUT NUMBER -- ケース数（不足数）
    , ion_short_singly_qty       IN OUT NUMBER -- バラ数（不足数）
    , ion_short_summary_qty      IN OUT NUMBER -- 総数（不足数）
    , ov_errbuf                  OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode                 OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg                  OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reserve_process'; -- プログラム名
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
    lv_reserve_err_msg         VARCHAR2(16)                                DEFAULT NULL; -- 引当処理にてエラー発生時のメッセージコードを格納
    ld_fresh_condition_date    DATE                                        DEFAULT NULL; -- 鮮度条件基準日
    lt_lot_reverse_mark        xxcoi_lot_reserve_info.mark%TYPE            DEFAULT NULL; -- 記号
    --
    lt_case_in_qty             xxcoi_lot_onhand_quantites.case_in_qty%TYPE DEFAULT 0;    -- 入数
    lt_case_qty                xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- ケース数（引当可能数）
    lt_singly_qty              xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- バラ数（引当可能数）
    lt_summary_qty             xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- 総数（引当可能数）
    --
    lt_reserve_case_qty        xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- ケース数（引当数）
    lt_reserve_singly_qty      xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- バラ数（引当数）
    lt_reserve_summary_qty     xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- 総数（引当数）
    --
    lt_short_case_qty          xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- ケース数（不足数）
    lt_short_singly_qty        xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- バラ数（不足数）
    lt_short_summary_qty       xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- 総数（不足数）
    --
    lt_after_case_qty          xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- ケース数（引当後数）
    lt_after_singly_qty        xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- バラ数（引当後数）
    lt_after_summary_qty       xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- 総数（引当後数）
--
    -- *** ローカルカーソル ***
    -- 引当中ロットカーソル
    CURSOR l_status_20_cur( iv_order_number     VARCHAR2
                          , iv_customer_code    VARCHAR2
                          , iv_parent_item_code VARCHAR2
                          , id_arrival_date     DATE
                          , iv_lot              VARCHAR2 )
    IS
      SELECT xlri.order_number      AS order_number
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status          IN (cv_shipping_status_20, cv_shipping_status_25)
      AND    xlri.order_number             <> iv_order_number
      AND    xlri.customer_code             = iv_customer_code
      AND    xlri.parent_item_code          = iv_parent_item_code
      AND    xlri.arrival_date              < id_arrival_date
      AND    TO_DATE(xlri.lot, cv_yyyymmdd) > TO_DATE(iv_lot, cv_yyyymmdd)
      ORDER BY xlri.order_number
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
    -- 初期化
    lt_short_case_qty    := ion_short_case_qty;
    lt_short_singly_qty  := ion_short_singly_qty;
    lt_short_summary_qty := ion_short_summary_qty;
    -- 引当可能数算出
    xxcoi_common_pkg.get_reserved_quantity(
        in_inv_org_id    => gt_organization_id         -- 在庫組織ID
      , iv_base_code     => gv_login_base_code         -- 拠点コード
      , iv_subinv_code   => iv_subinventory_code       -- 保管場所コード
      , iv_loc_code      => iv_location_code           -- ロケーションコード
      , in_child_item_id => in_item_id                 -- 子品目ID
      , iv_lot           => iv_lot                     -- ロット
      , iv_diff_sum_code => iv_difference_summary_code -- 固有記号
      , on_case_in_qty   => lt_case_in_qty             -- 入数
      , on_case_qty      => lt_case_qty                -- ケース数
      , on_singly_qty    => lt_singly_qty              -- バラ数
      , on_summary_qty   => lt_summary_qty             -- 取引数量
      , ov_errbuf        => lv_errbuf                  -- エラーメッセージ
      , ov_retcode       => lv_retcode                 -- リターンコード
      , ov_errmsg        => lv_errmsg                  -- ユーザー・エラー・メッセージ
    );
    -- リターンコードが正常以外の場合、エラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10561
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => '引当処理 引当可能数' ||
                  ' 入数：'             || lt_case_in_qty ||
                  ' ケース数：'         || lt_case_qty    ||
                  ' バラ数：'           || lt_singly_qty  ||
                  ' 取引数量：'         || lt_summary_qty
    );
    -- 引当可能数が存在する場合
    IF ( lt_summary_qty > 0 ) THEN
      -- 最新の納品日・ロットがNULLの場合は同一値を設定
      IF ( gd_last_deliver_lot IS NULL ) THEN
        gd_last_deliver_lot := TO_DATE(iv_lot, cv_yyyymmdd);
      END IF;
      IF ( gd_delivery_date IS NULL ) THEN
        gd_delivery_date    := id_arrival_date;
      END IF;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => '引当処理 ロット逆転判定' ||
                    ' 最新賞味期限：'         || TO_CHAR(gd_last_deliver_lot, cv_yyyymmdd) || ' 最新納品日：' || TO_CHAR(gd_delivery_date, cv_yyyymmdd) ||
                    ' 賞味期限：'             || iv_lot                                    || ' 納品日：'     || TO_CHAR(id_arrival_date, cv_yyyymmdd)
      );
      --
      -- ロット逆転判定
      --   ①最新納品日より前かつ最新ロット以前  ：意図的に行なえるパターン
      --   ②最新納品日より前かつ最新ロットより後：特売後の通常など、後から古いロットが着くパターンは記号を出力
      --   ③最新納品日と同日                    ：基本パターン。同日もロット逆転としない
      --   ④最新納品日より後かつ最新ロットより前：ロット逆転
      --                                            １．優先ロケーションまたは通常ロケーションかつロット逆転可：メッセージ出力は行い、引当する
      --                                            ２．通常ロケーションでロット逆転否：引当しない（ただしメッセージ出力は全ての品目で引当できなかった場合のみ）
      --   ⑤最新納品日より後かつ最新ロット以降  ：基本パターン
      IF    ( ( gd_delivery_date > id_arrival_date )  AND ( gd_last_deliver_lot >= TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        NULL;
      ELSIF ( ( gd_delivery_date > id_arrival_date )  AND ( gd_last_deliver_lot < TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        -- ロット逆転記号
        lt_lot_reverse_mark := gt_lot_reverse_mark;
      ELSIF ( gd_delivery_date = id_arrival_date ) THEN
        NULL;
      ELSIF ( ( gd_delivery_date < id_arrival_date ) AND ( gd_last_deliver_lot > TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        -- 優先ロケーションからの引当
        -- または 通常またはダミーロケーションからの引当でロット逆転可の場合はメッセージ出力で引当可能
        IF ( ( iv_process_kbn = cv_process_kbn_1 )
          OR ( ( iv_process_kbn = cv_process_kbn_2 ) AND ( gv_lot_reversal_flag = cv_flag_y ) ) ) THEN
          -- ロット逆転エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10548
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => iv_order_number
                         , iv_token_name2  => cv_tkn_customer_code
                         , iv_token_value2 => iv_customer_code
                         , iv_token_name3  => cv_tkn_item_code
                         , iv_token_value3 => iv_parent_item_code
                       );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg
          );
        ELSE
          lv_reserve_err_msg := cv_msg_xxcoi_10548;
          gv_reserve_err_msg := lv_reserve_err_msg;
        END IF;
      ELSIF ( ( gd_delivery_date < id_arrival_date ) AND ( gd_last_deliver_lot <= TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        NULL;
      END IF;
      --
      -- ロット逆転否の場合は引当を行なわないため、鮮度条件チェックも行なわない
      IF ( lv_reserve_err_msg IS NULL ) THEN
        -- 鮮度条件基準日算出
        xxcoi_common_pkg.get_fresh_condition_date(
           id_use_by_date          => TO_DATE(iv_lot, cv_yyyymmdd) -- 賞味期限
         , id_product_date         => id_production_date           -- 製造年月日
         , iv_fresh_condition      => gt_cust_fresh_con_code       -- 鮮度条件
         , od_fresh_condition_date => ld_fresh_condition_date      -- 鮮度条件基準日
         , ov_errbuf               => lv_errbuf                    -- エラーメッセージ
         , ov_retcode              => lv_retcode                   -- リターン・コード(0:正常、2:エラー)
         , ov_errmsg               => lv_errmsg                    -- ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '引当処理 鮮度条件基準日 ' || TO_CHAR(ld_fresh_condition_date, cv_yyyymmdd)
        );
        -- リターンコードが正常以外の場合、エラー
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10545
                         , iv_token_name1  => cv_tkn_common_pkg
                         , iv_token_value1 => cv_msg_xxcoi_10560
                         , iv_token_name2  => cv_tkn_errmsg
                         , iv_token_value2 => lv_errmsg
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        -- 納品日が鮮度条件基準日を満たしていない場合
        IF ( id_arrival_date >= ld_fresh_condition_date ) THEN
          -- 優先ロケーションからの引当の場合
          IF ( iv_process_kbn = cv_process_kbn_1 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10550
                           , iv_token_name1  => cv_tkn_order_number
                           , iv_token_value1 => iv_order_number
                           , iv_token_name2  => cv_tkn_item_code
                           , iv_token_value2 => iv_parent_item_code
                           , iv_token_name3  => cv_tkn_fresh_condition
                           , iv_token_value3 => gt_cust_fresh_con_code
                         );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg
            );
          ELSE
            lv_reserve_err_msg := cv_msg_xxcoi_10550;
            gv_reserve_err_msg := lv_reserve_err_msg;
          END IF;
        END IF;
      END IF;
      --
      -- ロット逆転否でロット逆転している、または、鮮度条件NGの場合は引当を行なわない
      --   ※優先ロケーションからの引当は、ロット逆転や鮮度条件NGであっても引当する
      --   ※通常またはダミーロケーションからの引当は、ロット逆転可であればロット逆転しても引当する
      IF ( lv_reserve_err_msg IS NULL ) THEN
        -- ケース数
        -- ケース数（不足数） = 0
        IF ( lt_short_case_qty = 0 ) THEN
          lt_reserve_case_qty := 0;           -- ケース数（引当数）
          lt_short_case_qty   := 0;           -- ケース数（不足数）
          lt_after_case_qty   := lt_case_qty; -- ケース数（引当後数）
        ELSE
          -- ケース数（不足数） >= 引当可能ケース数
          IF ( lt_short_case_qty >= lt_case_qty ) THEN
            lt_reserve_case_qty := lt_case_qty;                       -- ケース数（引当数）
            lt_short_case_qty   := lt_short_case_qty - lt_case_qty  ; -- ケース数（不足数）
            lt_after_case_qty   := 0;                                 -- ケース数（引当後数）
          -- ケース数（不足数）  < 引当可能ケース数
          ELSE
            lt_reserve_case_qty := lt_short_case_qty;                 -- ケース数（引当数）
            lt_short_case_qty   := 0;                                 -- ケース数（不足数）
            lt_after_case_qty   := lt_case_qty - lt_reserve_case_qty; -- ケース数（引当後数）
          END IF;
        END IF;
        --
        -- バラ数
        -- バラ数（不足数） = 0
        IF ( lt_short_singly_qty = 0 ) THEN
          lt_reserve_singly_qty := 0;           -- ケース数（引当数）
          lt_short_singly_qty   := 0;           -- ケース数（不足数）
          lt_after_singly_qty   := lt_singly_qty; -- ケース数（引当後数）
        ELSE
          -- バラ数（不足数） >= 引当可能バラ数
          IF ( lt_short_singly_qty >= lt_singly_qty ) THEN
            lt_reserve_singly_qty := lt_singly_qty;                       -- バラ数（引当数）
            lt_short_singly_qty   := lt_short_singly_qty - lt_singly_qty; -- バラ数（不足数）
            lt_after_singly_qty   := 0;                                   -- バラ数（引当後数）
            --
            -- バラ数（不足数）が存在し、ケース数に引当可能数が存在する場合
            IF ( ( lt_short_singly_qty > 0 ) AND ( lt_after_case_qty > 0 ) ) THEN
              lt_after_case_qty     := lt_after_case_qty - 1;                                          -- ケース数（引当後数）
              lt_reserve_singly_qty := lt_reserve_singly_qty + lt_short_singly_qty;                    -- バラ数（引当数）
              lt_after_singly_qty   := lt_after_singly_qty + ( lt_case_in_qty - lt_short_singly_qty ); -- バラ数（引当後数）
              lt_short_singly_qty   := 0;                                                              -- バラ数（不足数）
            END IF;
          -- バラ数（不足数） < 引当可能バラ数
          ELSE
            lt_reserve_singly_qty := lt_short_singly_qty;                   -- バラ数（引当数）
            lt_short_singly_qty   := 0;                                     -- バラ数（不足数）
            lt_after_singly_qty   := lt_singly_qty - lt_reserve_singly_qty; -- バラ数（引当後数）
          END IF;
        END IF;
        --
        -- ■総数
        lt_reserve_summary_qty := ( lt_case_in_qty * lt_reserve_case_qty ) + lt_reserve_singly_qty; -- 総数（引当数）
        lt_short_summary_qty   := ( lt_case_in_qty * lt_short_case_qty ) + lt_short_singly_qty;     -- 総数（不足数）
        lt_after_summary_qty   := ( lt_case_in_qty * lt_after_case_qty ) + lt_after_singly_qty;     -- 総数（引当後数）
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '引当処理 引当数' ||
                      ' 入数：'         || lt_case_in_qty         ||
                      ' ケース数：'     || lt_reserve_case_qty    ||
                      ' バラ数：'       || lt_reserve_singly_qty  ||
                      ' 取引数量：'     || lt_reserve_summary_qty
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '引当処理 不足数' ||
                      ' 入数：'         || lt_case_in_qty       ||
                      ' ケース数：'     || lt_short_case_qty    ||
                      ' バラ数：'       || lt_short_singly_qty  ||
                      ' 取引数量：'     || lt_short_summary_qty
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '引当処理 引当後在庫数' ||
                      ' 入数：'               || lt_case_in_qty       ||
                      ' ケース数：'           || lt_after_case_qty    ||
                      ' バラ数：'             || lt_after_singly_qty  ||
                      ' 取引数量：'           || lt_after_summary_qty
        );
        --
        -- 引当情報格納配列：ロット別引当情報への登録内容
        IF ( lt_reserve_summary_qty > 0 ) THEN
          gn_reserve_cnt                                         := gn_reserve_cnt + 1;
          gt_reserve_tab(gn_reserve_cnt).location_code           := iv_location_code;
          gt_reserve_tab(gn_reserve_cnt).location_name           := iv_location_name;
          gt_reserve_tab(gn_reserve_cnt).item_div                := iv_item_div;
          gt_reserve_tab(gn_reserve_cnt).item_div_name           := iv_item_div_name;
          gt_reserve_tab(gn_reserve_cnt).item_code               := iv_item_code;
          gt_reserve_tab(gn_reserve_cnt).item_name               := iv_item_name;
          gt_reserve_tab(gn_reserve_cnt).lot                     := iv_lot;
          gt_reserve_tab(gn_reserve_cnt).difference_summary_code := iv_difference_summary_code;
          gt_reserve_tab(gn_reserve_cnt).case_in_qty             := lt_case_in_qty;
          gt_reserve_tab(gn_reserve_cnt).case_qty                := lt_reserve_case_qty;
          gt_reserve_tab(gn_reserve_cnt).singly_qty              := lt_reserve_singly_qty;
          gt_reserve_tab(gn_reserve_cnt).summary_qty             := lt_reserve_summary_qty;
          gt_reserve_tab(gn_reserve_cnt).mark                    := lt_lot_reverse_mark;
          gt_reserve_tab(gn_reserve_cnt).item_id                 := in_item_id;
          IF ( lt_short_summary_qty <> 0 ) THEN
            gt_reserve_tab(gn_reserve_cnt).short_case_in_qty     := lt_case_in_qty;
          ELSE
            gt_reserve_tab(gn_reserve_cnt).short_case_in_qty     := 0;
          END IF;
          gt_reserve_tab(gn_reserve_cnt).short_case_qty          := lt_short_case_qty;
          gt_reserve_tab(gn_reserve_cnt).short_singly_qty        := lt_short_singly_qty;
          gt_reserve_tab(gn_reserve_cnt).short_summary_qty       := lt_short_summary_qty;
          --
          -- 引当中ロットのロット逆転メッセージ出力
          << status_20_loop >>
          FOR l_status_20_rec IN l_status_20_cur( iv_order_number     => iv_order_number
                                                , iv_customer_code    => iv_customer_code
                                                , iv_parent_item_code => iv_parent_item_code
                                                , id_arrival_date     => id_arrival_date
                                                , iv_lot              => iv_lot ) LOOP
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10549
                           , iv_token_name1  => cv_tkn_order_number2
                           , iv_token_value1 => l_status_20_rec.order_number
                           , iv_token_name2  => cv_tkn_order_number
                           , iv_token_value2 => iv_order_number
                           , iv_token_name3  => cv_tkn_customer_code
                           , iv_token_value3 => iv_customer_code
                           , iv_token_name4  => cv_tkn_item_code
                           , iv_token_value4 => iv_parent_item_code
                         );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg
            );
          END LOOP status_20_loop;
          --
        END IF;
        --
      ELSE
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '引当処理 引当実施NG' || ' エラーコード：' || lv_reserve_err_msg
        );
      END IF;
      --
    ELSE
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => '引当処理 引当実施NG 引当可能数0'
      );
    END IF;
    --
    -- 戻す
    ion_short_case_qty    := lt_short_case_qty;
    ion_short_singly_qty  := lt_short_singly_qty;
    ion_short_summary_qty := lt_short_summary_qty;
--
  EXCEPTION
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
  END reserve_process;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_login_base_code        IN  VARCHAR2 -- 拠点
    , iv_delivery_date_from     IN  VARCHAR2 -- 着日From
    , iv_delivery_date_to       IN  VARCHAR2 -- 着日To
    , iv_login_chain_store_code IN  VARCHAR2 -- チェーン店
    , iv_login_customer_code    IN  VARCHAR2 -- 顧客
    , iv_customer_po_number     IN  VARCHAR2 -- 顧客発注番号
    , iv_subinventory_code      IN  VARCHAR2 -- 保管場所
    , iv_priority_flag          IN  VARCHAR2 -- 優先ロケーション使用
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ロット逆転可否
    , iv_kbn                    IN  VARCHAR2 -- 判定区分
    , ov_errbuf                 OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode                OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg                 OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_errmsg2              VARCHAR2(5000);                                                   -- ユーザー・エラー・メッセージ2
    lt_edi_order_source     fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- EDI受注ソース
    lt_chain_store_name     hz_parties.party_name%TYPE                          DEFAULT NULL; -- チェーン店名
    lt_customer_name        hz_parties.party_name%TYPE                          DEFAULT NULL; -- 顧客名
    lt_subinventory_name    mtl_secondary_inventories.description%TYPE          DEFAULT NULL; -- 保管場所名
    lt_priority_flag        fnd_lookup_values.meaning%TYPE                      DEFAULT NULL; -- 優先ロケーション使用_内容
    lt_lot_reversal_flag    fnd_lookup_values.meaning%TYPE                      DEFAULT NULL; -- ロット逆転可否_内容
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- パラメータをグローバル変数に保持
    gv_login_base_code        := iv_login_base_code;                                   -- 拠点
    gd_delivery_date_from     := TO_DATE(iv_delivery_date_from, cv_yyyymmdd_hh24miss); -- 着日From
    gd_delivery_date_to       := TO_DATE(iv_delivery_date_to, cv_yyyymmdd_hh24miss);   -- 着日To
    gv_login_chain_store_code := iv_login_chain_store_code;                            -- チェーン店
    gv_login_customer_code    := iv_login_customer_code;                               -- 顧客
    gv_customer_po_number     := iv_customer_po_number;                                -- 顧客発注番号
    gv_subinventory_code      := iv_subinventory_code;                                 -- 保管場所
    gv_priority_flag          := iv_priority_flag;                                     -- 優先ロケーション使用
    gv_lot_reversal_flag      := iv_lot_reversal_flag;                                 -- ロット逆転可否
    gv_kbn                    := iv_kbn;                                               -- 判定区分
--
    --==============================================================
    -- 1．業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application
                     , iv_name        => cv_msg_xxcoi_00011
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 着日がNULLの場合
    IF ( gd_delivery_date_from IS NULL ) THEN
      gd_delivery_date_from := gd_process_date;
      gd_delivery_date_to   := gd_process_date;
    END IF;
--
    --==============================================================
    -- 2．在庫組織ID取得
    --==============================================================
    -- プロファイル取得
    gt_organization_code := FND_PROFILE.VALUE(cv_organization_code);
    --
    IF ( gt_organization_code IS NULL ) THEN
      -- 在庫組織コード取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00005
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 在庫組織ID取得
    gt_organization_id := xxcoi_common_pkg.get_organization_id(gt_organization_code);
    --
    IF ( gt_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00006
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => gt_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 3．営業単位取得
    --==============================================================
    gt_org_id := FND_PROFILE.VALUE(cv_org_id);
    --
    IF ( gt_org_id IS NULL ) THEN
      -- プロファイル値取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_org_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4．ロット逆転記号取得
    --==============================================================
    gt_lot_reverse_mark := FND_PROFILE.VALUE(cv_lot_reverse_mark);
    --
    IF ( gt_lot_reverse_mark IS NULL ) THEN
      -- プロファイル値取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_lot_reverse_mark
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 5．EDI受注ソース取得
    --==============================================================
    -- プロファイル取得
    lt_edi_order_source := FND_PROFILE.VALUE(cv_edi_order_source);
    --
    IF ( lt_edi_order_source IS NULL ) THEN
      -- プロファイル値取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_edi_order_source
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 受注ソースID取得
    BEGIN
      SELECT oos.order_source_id AS order_source_id
      INTO   gt_order_source_id
      FROM   oe_order_sources    oos
      WHERE  oos.name = lt_edi_order_source
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 受注ソース取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_xxcos
                       , iv_name         => cv_msg_xxcos_11538
                       , iv_token_name1  => cv_tkn_order_source_name
                       , iv_token_value1 => lt_edi_order_source
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
-- Add Ver1.1 Start
    --==============================================================
    --    引当データ取得期間
    --==============================================================
    BEGIN
      gt_period_xxcoi016a06c1 := TO_NUMBER(FND_PROFILE.VALUE(cv_period_xxcoi016a06c1));
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_00032
                       , iv_token_name1  => cv_tkn_pro_tok
                       , iv_token_value1 => cv_period_xxcoi016a06c1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    IF ( gt_period_xxcoi016a06c1 IS NULL ) THEN
      -- プロファイル値取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_period_xxcoi016a06c1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --    返品・訂正・過去データ取得期間
    --==============================================================
    BEGIN
      gt_period_xxcoi016a06c5 := TO_NUMBER(FND_PROFILE.VALUE(cv_period_xxcoi016a06c5));
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_00032
                       , iv_token_name1  => cv_tkn_pro_tok
                       , iv_token_value1 => cv_period_xxcoi016a06c5
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    IF ( gt_period_xxcoi016a06c5 IS NULL ) THEN
      -- プロファイル値取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_period_xxcoi016a06c5
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Add Ver1.1 End
--
    --==============================================================
    -- 6．定番特売区分名取得
    --==============================================================
    -- 定番
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gt_teiban_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type                            = cv_bargain_class
      AND    flv.attribute1                             = cv_flag_y
      AND    flv.language                               = ct_lang
      AND    flv.enabled_flag                           = cv_flag_y
      AND    flv.start_date_active                     <= gd_process_date
      AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 定番情報取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_xxcos
                       , iv_name         => cv_msg_xxcos_00186
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- 特売
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gt_tokubai_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type                            = cv_bargain_class
      AND    flv.attribute1                             = cv_flag_n
      AND    flv.language                               = ct_lang
      AND    flv.enabled_flag                           = cv_flag_y
      AND    flv.start_date_active                     <= gd_process_date
      AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 特売情報取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_xxcos
                       , iv_name         => cv_msg_xxcos_00187
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 7．訂正受注タイプ名取得
    --==============================================================
    -- 返品、返品訂正
    SELECT flv.meaning       AS meaning
    BULK COLLECT INTO gt_return_tab
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type                            = cv_order_type_mst
    AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
    AND    flv.attribute2                             = cv_flag_y
    AND    flv.language                               = ct_lang
    AND    flv.enabled_flag                           = cv_flag_y
    AND    flv.start_date_active                     <= gd_process_date
    AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
    ;
    --
    IF ( gt_return_tab.COUNT = 0 ) THEN
      -- 受注タイプ取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_xxcos
                     , iv_name         => cv_msg_xxcos_12005
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 訂正
    SELECT flv.meaning       AS meaning
    BULK COLLECT INTO gt_correct_tab
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type                            = cv_order_type_mst
    AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
    AND    flv.attribute1                             = cv_flag_y
    AND    flv.language                               = ct_lang
    AND    flv.enabled_flag                           = cv_flag_y
    AND    flv.start_date_active                     <= gd_process_date
    AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
    ;
    --
    IF ( gt_correct_tab.COUNT = 0 ) THEN
      -- 受注タイプ取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_xxcos
                     , iv_name         => cv_msg_xxcos_12005
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 8．拠点名取得
    --==============================================================
    -- 拠点が設定されている場合
    IF ( gv_login_base_code IS NOT NULL ) THEN
      SELECT xlbiv.base_name         AS base_name
      INTO   gt_base_name
      FROM   xxcos_login_base_info_v xlbiv
      WHERE  xlbiv.base_code = gv_login_base_code
      ;
    END IF;
--
    --==============================================================
    -- 9．チェーン店名取得
    --==============================================================
    -- チェーン店が設定されている場合
    IF ( gv_login_chain_store_code IS NOT NULL ) THEN
      SELECT hp.party_name       AS chain_store_name
      INTO   lt_chain_store_name
      FROM   hz_cust_accounts    hca
           , hz_parties          hp
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.party_id            = hp.party_id
      AND    xca.chain_store_code IN
               ( SELECT DISTINCT xca1.chain_store_code AS chain_store_code
                 FROM   hz_cust_accounts               hca1
                      , xxcmm_cust_accounts            xca1
                      , xxcos_login_base_info_v        xlbiv
                 WHERE  hca1.cust_account_id     = xca1.customer_id
                 AND    xca1.delivery_base_code  = xlbiv.base_code
                 AND    hca1.customer_class_code IN ( cv_customer_class_code_10, cv_customer_class_code_12 )
                 AND    xca1.delivery_base_code  = gv_login_base_code )
      AND    hca.customer_class_code = cv_customer_class_code_18
      AND    xca.chain_store_code    = gv_login_chain_store_code
      ;
    END IF;
--
    --==============================================================
    -- 10．顧客名取得
    --==============================================================
    -- 顧客が設定されている場合
    IF ( gv_login_customer_code IS NOT NULL ) THEN
      SELECT hp.party_name       AS customer_name
      INTO   lt_customer_name
      FROM   hz_cust_accounts    hca
           , hz_parties          hp
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.party_id            = hp.party_id
      AND    hca.customer_class_code IN ( cv_customer_class_code_10, cv_customer_class_code_12 )
      AND    xca.delivery_base_code  = gv_login_base_code
      AND    hca.account_number      = gv_login_customer_code
      ;
    END IF;
--
    --==============================================================
    -- 11．保管場所名取得
    --==============================================================
    -- 保管場所が設定されている場合
    IF ( gv_subinventory_code IS NOT NULL ) THEN
      SELECT msi.description           AS subinventory_name
      INTO   lt_subinventory_name
      FROM   mtl_secondary_inventories msi
           , xxcoi_base_info2_v        xbiv
      WHERE  msi.attribute7                             = xbiv.base_code
      AND    msi.attribute14                            = cv_flag_y
      AND    msi.organization_id                        = gt_organization_id
      AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
      AND    xbiv.focus_base_code                       = gv_login_base_code
      AND    msi.secondary_inventory_name               = gv_subinventory_code
      ;
    END IF;
--
    --==============================================================
    -- 12．優先ロケーション使用取得
    --==============================================================
    -- 引当の場合
    IF ( gv_kbn = cv_kbn_1 ) THEN
      lt_priority_flag := xxcoi_common_pkg.get_meaning(
                              iv_lookup_type => cv_priority_flag
                            , iv_lookup_code => gv_priority_flag
                          );
    END IF;
--
    --==============================================================
    -- 13．ロット逆転可否取得
    --==============================================================
    -- 引当の場合
    IF ( gv_kbn = cv_kbn_1 ) THEN
      lt_lot_reversal_flag := xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type => cv_lot_reversal_flag
                                , iv_lookup_code => gv_lot_reversal_flag
                              );
    END IF;
--
    --==============================================================
    -- 14．判定区分取得
    --==============================================================
    gt_xxcoi016a06_kbn := xxcoi_common_pkg.get_meaning(
                              iv_lookup_type => cv_xxcoi016a06_kbn
                            , iv_lookup_code => gv_kbn
                          );
--
    --==============================================================
    -- 15．出荷情報ステータス取得
    --==============================================================
    -- 引当の場合
    IF ( gv_kbn = cv_kbn_1 ) THEN
      -- 引当未
      gt_shipping_status_10 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_10
                            );
      --
      IF ( gt_shipping_status_10 IS NULL ) THEN
        -- 出荷情報ステータス名取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_10
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- 引当済
      gt_shipping_status_20 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_20
                            );
      --
      IF ( gt_shipping_status_20 IS NULL ) THEN
        -- 出荷情報ステータス名取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_20
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
    -- 出荷仮確定の場合
    ELSIF ( gv_kbn = cv_kbn_3 ) THEN
      -- 出荷仮確定
      gt_shipping_status_25 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_25
                            );
      --
      IF ( gt_shipping_status_25 IS NULL ) THEN
        -- 出荷情報ステータス名取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_25
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    -- 出荷確定の場合
    ELSIF ( gv_kbn = cv_kbn_4 ) THEN
      -- 出荷確定済
      gt_shipping_status_30 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_30
                            );
      --
      IF ( gt_shipping_status_30 IS NULL ) THEN
        -- 出荷情報ステータス名取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_30
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 16．着日チェック
    --==============================================================
    -- 着日From-Toの逆転チェック
    IF ( gd_delivery_date_from > gd_delivery_date_to ) THEN
      -- 着日逆転エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10531
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- Mod Ver1.3 Start
--    -- 引当または引当解除の場合
--    IF ( ( gv_kbn = cv_kbn_1 ) OR ( gv_kbn = cv_kbn_2 ) ) THEN
    -- 引当の場合
    IF ( gv_kbn = cv_kbn_1 ) THEN
-- Mod Ver1.3 End
      -- 着日Fromまたは着日Toの業務日付より過去日チェック
      IF ( ( gd_delivery_date_from < gd_process_date )
        OR ( gd_delivery_date_to < gd_process_date ) ) THEN
        -- 着日過去日エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10532
                       , iv_token_name1  => cv_tkn_process
                       , iv_token_value1 => gt_xxcoi016a06_kbn
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
-- 2015/05/12 移行用 Del Start
-- Mod Ver1.3 Start
--    --==============================================================
--    --     必須チェック
--    --==============================================================
--    -- 随時実行（拠点コードが指定されている）の場合
--    IF ( gv_login_base_code IS NOT NULL ) THEN
--      -- チェーン店or顧客or顧客発注番号のいずれも指定されていない場合
--      IF (  ( gv_login_chain_store_code IS NULL )
--        AND ( gv_login_customer_code IS NULL )
--        AND ( gv_customer_po_number IS NULL ) ) THEN
--        -- パラメータ必須エラーメッセージ
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application
--                       , iv_name         => cv_msg_xxcoi_10703
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      END IF;
--    END IF;
-- Mod Ver1.3 End
-- 2015/05/12 移行用 Del End
--
    --==============================================================
    -- 17．コンカレント入力パラメータメッセージ出力
    --==============================================================
    -- 引当の場合
    IF ( gv_kbn = cv_kbn_1 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application                              -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcoi_10533                          -- メッセージコード
                     , iv_token_name1  => cv_tkn_param1                               -- トークンコード1
                     , iv_token_value1 => gv_login_base_code                          -- トークン値1
                     , iv_token_name2  => cv_tkn_param_name1                          -- トークンコード2
                     , iv_token_value2 => gt_base_name                                -- トークン値2
                     , iv_token_name3  => cv_tkn_param2                               -- トークンコード3
                     , iv_token_value3 => TO_CHAR(gd_delivery_date_from, cv_yyyymmdd) -- トークン値3
                     , iv_token_name4  => cv_tkn_param3                               -- トークンコード4
                     , iv_token_value4 => TO_CHAR(gd_delivery_date_to, cv_yyyymmdd)   -- トークン値4
                     , iv_token_name5  => cv_tkn_param4                               -- トークンコード5
                     , iv_token_value5 => gv_login_chain_store_code                   -- トークン値5
                     , iv_token_name6  => cv_tkn_param_name4                          -- トークンコード6
                     , iv_token_value6 => lt_chain_store_name                         -- トークン値6
                     , iv_token_name7  => cv_tkn_param5                               -- トークンコード7
                     , iv_token_value7 => gv_login_customer_code                      -- トークン値7
                     , iv_token_name8  => cv_tkn_param_name5                          -- トークンコード8
                     , iv_token_value8 => lt_customer_name                            -- トークン値8
                     , iv_token_name9  => cv_tkn_param6                               -- トークンコード9
                     , iv_token_value9 => gv_customer_po_number                       -- トークン値9
                   );
      lv_errmsg2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application                             -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcoi_10534                         -- メッセージコード
                      , iv_token_name1  => cv_tkn_param7                              -- トークンコード1
                      , iv_token_value1 => gv_subinventory_code                       -- トークン値1
                      , iv_token_name2  => cv_tkn_param_name7                         -- トークンコード2
                      , iv_token_value2 => lt_subinventory_name                       -- トークン値2
                      , iv_token_name3  => cv_tkn_param8                              -- トークンコード3
                      , iv_token_value3 => gv_priority_flag                           -- トークン値3
                      , iv_token_name4  => cv_tkn_param_name8                         -- トークンコード4
                      , iv_token_value4 => lt_priority_flag                           -- トークン値4
                      , iv_token_name5  => cv_tkn_param9                              -- トークンコード5
                      , iv_token_value5 => gv_lot_reversal_flag                       -- トークン値5
                      , iv_token_name6  => cv_tkn_param_name9                         -- トークンコード6
                      , iv_token_value6 => lt_lot_reversal_flag                       -- トークン値6
                      , iv_token_name7  => cv_tkn_param10                             -- トークンコード7
                      , iv_token_value7 => gv_kbn                                     -- トークン値7
                      , iv_token_name8  => cv_tkn_param_name10                        -- トークンコード8
                      , iv_token_value8 => gt_xxcoi016a06_kbn                         -- トークン値8
                    );
    -- 引当解除、出荷仮確定、出荷確定、返品・訂正・過去データ、仮確定後訂正の場合
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application                              -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcoi_10535                          -- メッセージコード
                     , iv_token_name1  => cv_tkn_param1                               -- トークンコード1
                     , iv_token_value1 => gv_login_base_code                          -- トークン値1
                     , iv_token_name2  => cv_tkn_param_name1                          -- トークンコード2
                     , iv_token_value2 => gt_base_name                                -- トークン値2
                     , iv_token_name3  => cv_tkn_param2                               -- トークンコード3
                     , iv_token_value3 => TO_CHAR(gd_delivery_date_from, cv_yyyymmdd) -- トークン値3
                     , iv_token_name4  => cv_tkn_param3                               -- トークンコード4
                     , iv_token_value4 => TO_CHAR(gd_delivery_date_to, cv_yyyymmdd)   -- トークン値4
                     , iv_token_name5  => cv_tkn_param4                               -- トークンコード5
                     , iv_token_value5 => gv_login_chain_store_code                   -- トークン値5
                     , iv_token_name6  => cv_tkn_param_name4                          -- トークンコード6
                     , iv_token_value6 => lt_chain_store_name                         -- トークン値6
                     , iv_token_name7  => cv_tkn_param5                               -- トークンコード7
                     , iv_token_value7 => gv_login_customer_code                      -- トークン値7
                     , iv_token_name8  => cv_tkn_param_name5                          -- トークンコード8
                     , iv_token_value8 => lt_customer_name                            -- トークン値8
                     , iv_token_name9  => cv_tkn_param6                               -- トークンコード9
                     , iv_token_value9 => gv_customer_po_number                       -- トークン値9
                   );
      lv_errmsg2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application                             -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcoi_10536                         -- メッセージコード
                      , iv_token_name1  => cv_tkn_param7                              -- トークンコード1
                      , iv_token_value1 => gv_subinventory_code                       -- トークン値1
                      , iv_token_name2  => cv_tkn_param_name7                         -- トークンコード2
                      , iv_token_value2 => lt_subinventory_name                       -- トークン値2
                      , iv_token_name3  => cv_tkn_param8                              -- トークンコード3
                      , iv_token_value3 => gv_kbn                                     -- トークン値3
                      , iv_token_name4  => cv_tkn_param_name8                         -- トークンコード4
                      , iv_token_value4 => gt_xxcoi016a06_kbn                         -- トークン値4
                    );
    END IF;
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg2
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => lv_errmsg2
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => ''
    );
--
    --==============================================================
    -- 18．従業員情報取得
    --==============================================================
    -- 引当の場合
    IF ( gv_kbn = cv_kbn_1 ) THEN
      BEGIN
        SELECT papf.employee_number                                         AS employee_number
             , papf.per_information18 || cv_space || papf.per_information19 AS employee_name
        INTO   gt_employee_number
             , gv_employee_name
        FROM   fnd_user         fu
             , per_all_people_f papf
        WHERE  fu.employee_id             = papf.person_id
        AND    papf.effective_start_date <= gd_process_date
        AND    papf.effective_end_date   >= gd_process_date
        AND    fu.user_id                 = cn_created_by
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- 従業員マスタ取得エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application => cv_application
                         , iv_name        => cv_msg_xxcoi_10130
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : get_lock
   * Description      : ロック制御処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_lock(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy                NUMBER DEFAULT 0; -- ダミー値
    ln_cnt                  NUMBER DEFAULT 0; -- 件数
    -- ロック対象保管場所格納定義
    TYPE l_subinventory_code_ttype IS TABLE OF mtl_secondary_inventories.secondary_inventory_name%TYPE INDEX BY PLS_INTEGER;
    -- ロック対象保管場所格納配列
    l_subinventory_code_tab l_subinventory_code_ttype;
    -- ロット別引当ロック制御テーブル登録用格納配列
    l_ins_lock_control_tab  l_subinventory_code_ttype;
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
    -- 1．ロック対象判別
    --==============================================================
    -- 保管場所指定あり
    IF ( gv_subinventory_code IS NOT NULL ) THEN
      l_subinventory_code_tab(1) := gv_subinventory_code;
    -- 保管場所指定なし
    ELSE
      SELECT msi.secondary_inventory_name AS secondary_inventory_name
      BULK COLLECT INTO l_subinventory_code_tab
      FROM   mtl_secondary_inventories    msi
      WHERE  msi.attribute14     = cv_flag_y
      AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
      AND    msi.organization_id = gt_organization_id
      AND    msi.attribute7      = gv_login_base_code
      ;
      -- 保管場所が取得できない場合
      IF ( l_subinventory_code_tab.COUNT = 0 ) THEN
        -- ロック対象保管場所存在エラーメッセージエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10541
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gv_login_base_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 2．ロット別引当ロック制御テーブルチェック
    --==============================================================
    -- 存在チェックループ
    << ins_chk_loop >>
    FOR i IN 1 .. l_subinventory_code_tab.COUNT LOOP
      BEGIN
        SELECT 1
        INTO   ln_dummy
        FROM   xxcoi_lot_lock_control xllc
        WHERE  xllc.organization_id   = gt_organization_id
        AND    xllc.base_code         = gv_login_base_code
        AND    xllc.subinventory_code = l_subinventory_code_tab(i)
        ;
      EXCEPTION
        -- 取得できない保管場所のみ、新規登録するため保持
        WHEN NO_DATA_FOUND THEN
          ln_cnt                         := ln_cnt + 1;
          l_ins_lock_control_tab(ln_cnt) := l_subinventory_code_tab(i);
      END;
    END LOOP ins_chk_loop;
--
    --==============================================================
    -- 3．ロット別引当ロック制御テーブル登録
    --==============================================================
    -- 登録件数が存在する場合
    IF ( ln_cnt > 0 ) THEN
      -- 登録ループ
      << ins_target_loop >>
      FOR i IN 1 .. l_ins_lock_control_tab.COUNT LOOP
        BEGIN
          INSERT INTO xxcoi_lot_lock_control(
              lot_lock_control_id                -- ロット別引当ロック制御ID
            , organization_id                    -- 在庫組織ID
            , base_code                          -- 拠点コード
            , subinventory_code                  -- 保管場所コード
            , created_by                         -- 作成者
            , creation_date                      -- 作成日
            , last_updated_by                    -- 最終更新者
            , last_update_date                   -- 最終更新日
            , last_update_login                  -- 最終更新ログイン
            , request_id                         -- 要求ID
            , program_application_id             -- プログラムアプリケーションID
            , program_id                         -- プログラムID
            , program_update_date                -- プログラム更新日
          ) VALUES (
              xxcoi_lot_lock_control_s01.NEXTVAL -- ロット別引当ロック制御ID
            , gt_organization_id                 -- 在庫組織ID
            , gv_login_base_code                 -- 拠点コード
            , l_ins_lock_control_tab(i)          -- 保管場所コード
            , cn_created_by                      -- 作成者
            , cd_creation_date                   -- 作成日
            , cn_last_updated_by                 -- 最終更新者
            , cd_last_update_date                -- 最終更新日
            , cn_last_update_login               -- 最終更新ログイン
            , cn_request_id                      -- 要求ID
            , cn_program_application_id          -- プログラムアプリケーションID
            , cn_program_id                      -- プログラムID
            , cd_program_update_date             -- プログラム更新日
          );
        EXCEPTION
          -- 一意制約違反
          WHEN DUP_VAL_ON_INDEX THEN
            -- 保管場所指定あり
            IF ( gv_subinventory_code IS NOT NULL ) THEN
              -- ロット別出荷情報作成（保管場所指定あり）ロックエラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application
                             , iv_name         => cv_msg_xxcoi_10542
                             , iv_token_name1  => cv_tkn_subinventory_code
                             , iv_token_value1 => gv_subinventory_code
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            -- 保管場所指定なし
            ELSE
              -- ロット別出荷情報作成（保管場所指定なし）ロックエラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application
                             , iv_name         => cv_msg_xxcoi_10543
                             , iv_token_name1  => cv_tkn_base_code
                             , iv_token_value1 => gv_login_base_code
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            END IF;
        END;
      END LOOP ins_target_loop;
      --
      -- 全件登録後にCOMMIT
      COMMIT;
      --
    END IF;
--
    --==============================================================
    -- 4．ロット別引当ロック制御テーブルロック取得
    --==============================================================
    -- ロックループ
    -- 登録したデータを含めて全件ロック取得
    << lock_loop >>
    FOR i IN 1 .. l_subinventory_code_tab.COUNT LOOP
      BEGIN
        -- ロック取得
        SELECT 1
        INTO   ln_dummy
        FROM   xxcoi_lot_lock_control xllc
        WHERE  xllc.organization_id   = gt_organization_id
        AND    xllc.base_code         = gv_login_base_code
        AND    xllc.subinventory_code = l_subinventory_code_tab(i)
        FOR UPDATE NOWAIT
        ;
        -- ロット別引当保管場所一時表登録
        INSERT INTO xxcoi_tmp_lot_reserve_subinv(
          subinventory_code -- 保管場所コード
        ) VALUES (
          l_subinventory_code_tab(i)
        );
      EXCEPTION
        -- ロック取得に失敗
        WHEN global_lock_expt THEN
          -- 保管場所指定あり
          IF ( gv_subinventory_code IS NOT NULL ) THEN
            -- ロット別出荷情報作成（保管場所指定あり）ロックエラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10542
                           , iv_token_name1  => cv_tkn_subinventory_code
                           , iv_token_value1 => gv_subinventory_code
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          -- 保管場所指定なし
          ELSE
            -- ロット別出荷情報作成（保管場所指定なし）ロックエラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10543
                           , iv_token_name1  => cv_tkn_base_code
                           , iv_token_value1 => gv_login_base_code
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
      END;
    END LOOP lock_loop;
    -- デバッグ用
    SELECT COUNT(1)
    INTO   gn_debug_cnt
    FROM   xxcoi_tmp_lot_reserve_subinv
    ;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-2.4 ロット別引当保管場所一時表登録件数：' || gn_debug_cnt
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_data
   * Description      : 引当対象データ取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_reserve_data(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_reserve_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt                     NUMBER                                                       DEFAULT NULL; -- ダミー値
    lt_sale_class              xxcoi_tmp_lot_reserve_info.regular_sale_class_line%TYPE      DEFAULT NULL; -- 定番特売区分(明細)
    lt_sale_class_name         xxcoi_tmp_lot_reserve_info.regular_sale_class_name_line%TYPE DEFAULT NULL; -- 定番特売区分名(明細)
    lt_delivery_order_edi      xxcoi_tmp_lot_reserve_info.delivery_order_edi%TYPE           DEFAULT NULL; -- 配送順(EDI)
-- Add Ver1.3 Start
    ln_cursor_no               NUMBER                                                       DEFAULT NULL; -- カーソル判定
-- Add Ver1.3 End
--
    -- *** ローカルカーソル ***
    -- 引当対象データ取得カーソル
    CURSOR l_kbn_1_cur
    IS
      SELECT /*+ LEADING(ooha oola) */
             ooha.header_id                                AS header_id                 -- 受注ヘッダID
           , ottt1.name                                    AS header_name               -- 受注タイプ名称
           , ooha.cust_po_number                           AS slip_num                  -- 伝票No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- 受注番号
           , ooha.order_source_id                          AS order_source_id           -- 受注ソースID
           , xca2.chain_store_code                         AS chain_code                -- チェーン店コード
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- チェーン店名
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- 顧客別鮮度条件コード（チェーン店）
           , xca1.store_code                               AS shop_code                 -- 店舗コード
           , xca1.cust_store_name                          AS shop_name                 -- 店舗名
           , hca1.cust_account_id                          AS cust_account_id           -- 顧客ID
           , hca1.account_number                           AS customer_code             -- 顧客コード
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- 顧客名
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- 顧客別鮮度条件コード（顧客）
           , xca1.deli_center_code                         AS center_code               -- センターコード
           , xca1.deli_center_name                         AS center_name               -- センター名
           , xca1.edi_district_code                        AS area_code                 -- 地区コード
           , xca1.edi_district_name                        AS area_name                 -- 地区名
           , oola.line_id                                  AS line_id                   -- 受注明細ID
           , oola.line_number                              AS line_number               -- 受注明細番号
           , oola.inventory_item_id                        AS parent_item_id            -- 親品目ID
           , iimb.item_no                                  AS parent_item_code          -- 親品目コード
           , ximb.item_short_name                          AS parent_item_name          -- 親品目名
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- 売上区分
           , oola.attribute6                               AS item_code                 -- 子品目コード
           , oola.ordered_quantity                         AS ordered_quantity          -- 受注数量
           , oola.order_quantity_uom                       AS order_quantity_uom        -- 受注単位
           , oola.schedule_ship_date                       AS schedule_ship_date        -- 出荷日
           , TRUNC(oola.request_date)                      AS arrival_date              -- 着日
           , oola.subinventory                             AS whse_code                 -- 保管場所コード
           , msi.description                               AS whse_name                 -- 保管場所名
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- 外部システム受注番号
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- 外部システム受注明細番号
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- 配送順（月、水、金）
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- 配送順（火、木、土）
           , ottt2.name                                    AS line_name                 -- 明細タイプ
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code           = cv_booked
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                  > gt_max_header_id
-- Add Ver1.1 Start
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
-- Add Ver1.1 End
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( hca1.account_number            = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( ooha.cust_po_number            = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
    ;
-- Add Ver1.3 Start
    -- 引当対象データ取得カーソル2
    CURSOR l_kbn_11_cur
    IS
      SELECT /*+ LEADING(xca1) */
             ooha.header_id                                AS header_id                 -- 受注ヘッダID
           , ottt1.name                                    AS header_name               -- 受注タイプ名称
           , ooha.cust_po_number                           AS slip_num                  -- 伝票No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- 受注番号
           , ooha.order_source_id                          AS order_source_id           -- 受注ソースID
           , xca2.chain_store_code                         AS chain_code                -- チェーン店コード
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- チェーン店名
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- 顧客別鮮度条件コード（チェーン店）
           , xca1.store_code                               AS shop_code                 -- 店舗コード
           , xca1.cust_store_name                          AS shop_name                 -- 店舗名
           , hca1.cust_account_id                          AS cust_account_id           -- 顧客ID
           , hca1.account_number                           AS customer_code             -- 顧客コード
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- 顧客名
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- 顧客別鮮度条件コード（顧客）
           , xca1.deli_center_code                         AS center_code               -- センターコード
           , xca1.deli_center_name                         AS center_name               -- センター名
           , xca1.edi_district_code                        AS area_code                 -- 地区コード
           , xca1.edi_district_name                        AS area_name                 -- 地区名
           , oola.line_id                                  AS line_id                   -- 受注明細ID
           , oola.line_number                              AS line_number               -- 受注明細番号
           , oola.inventory_item_id                        AS parent_item_id            -- 親品目ID
           , iimb.item_no                                  AS parent_item_code          -- 親品目コード
           , ximb.item_short_name                          AS parent_item_name          -- 親品目名
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- 売上区分
           , oola.attribute6                               AS item_code                 -- 子品目コード
           , oola.ordered_quantity                         AS ordered_quantity          -- 受注数量
           , oola.order_quantity_uom                       AS order_quantity_uom        -- 受注単位
           , oola.schedule_ship_date                       AS schedule_ship_date        -- 出荷日
           , TRUNC(oola.request_date)                      AS arrival_date              -- 着日
           , oola.subinventory                             AS whse_code                 -- 保管場所コード
           , msi.description                               AS whse_name                 -- 保管場所名
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- 外部システム受注番号
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- 外部システム受注明細番号
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- 配送順（月、水、金）
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- 配送順（火、木、土）
           , ottt2.name                                    AS line_name                 -- 明細タイプ
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code           = cv_booked
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                  > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND    xca1.chain_store_code           = gv_login_chain_store_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
    ;
    -- 引当対象データ取得カーソル3
    CURSOR l_kbn_12_cur
    IS
      SELECT /*+ LEADING(hca1) */
             ooha.header_id                                AS header_id                 -- 受注ヘッダID
           , ottt1.name                                    AS header_name               -- 受注タイプ名称
           , ooha.cust_po_number                           AS slip_num                  -- 伝票No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- 受注番号
           , ooha.order_source_id                          AS order_source_id           -- 受注ソースID
           , xca2.chain_store_code                         AS chain_code                -- チェーン店コード
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- チェーン店名
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- 顧客別鮮度条件コード（チェーン店）
           , xca1.store_code                               AS shop_code                 -- 店舗コード
           , xca1.cust_store_name                          AS shop_name                 -- 店舗名
           , hca1.cust_account_id                          AS cust_account_id           -- 顧客ID
           , hca1.account_number                           AS customer_code             -- 顧客コード
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- 顧客名
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- 顧客別鮮度条件コード（顧客）
           , xca1.deli_center_code                         AS center_code               -- センターコード
           , xca1.deli_center_name                         AS center_name               -- センター名
           , xca1.edi_district_code                        AS area_code                 -- 地区コード
           , xca1.edi_district_name                        AS area_name                 -- 地区名
           , oola.line_id                                  AS line_id                   -- 受注明細ID
           , oola.line_number                              AS line_number               -- 受注明細番号
           , oola.inventory_item_id                        AS parent_item_id            -- 親品目ID
           , iimb.item_no                                  AS parent_item_code          -- 親品目コード
           , ximb.item_short_name                          AS parent_item_name          -- 親品目名
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- 売上区分
           , oola.attribute6                               AS item_code                 -- 子品目コード
           , oola.ordered_quantity                         AS ordered_quantity          -- 受注数量
           , oola.order_quantity_uom                       AS order_quantity_uom        -- 受注単位
           , oola.schedule_ship_date                       AS schedule_ship_date        -- 出荷日
           , TRUNC(oola.request_date)                      AS arrival_date              -- 着日
           , oola.subinventory                             AS whse_code                 -- 保管場所コード
           , msi.description                               AS whse_name                 -- 保管場所名
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- 外部システム受注番号
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- 外部システム受注明細番号
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- 配送順（月、水、金）
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- 配送順（火、木、土）
           , ottt2.name                                    AS line_name                 -- 明細タイプ
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code           = cv_booked
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                  > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND    hca1.account_number             = gv_login_customer_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
    ;
-- Add Ver1.3 End
    -- EDI情報取得カーソル
    CURSOR l_edi_cur( iv_order_number      VARCHAR2
                    , iv_order_line_number VARCHAR2 )
    IS
      SELECT xeh.edi_received_date AS edi_received_date
           , xeh.ar_sale_class     AS ar_sale_class
      FROM   xxcos_edi_headers     xeh
           , xxcos_edi_lines       xel
      WHERE  xel.edi_header_info_id           = xeh.edi_header_info_id
      AND    xeh.order_connection_number      = iv_order_number
      AND    xel.order_connection_line_number = iv_order_line_number
    ;
    l_edi_rec               l_edi_cur%ROWTYPE;
-- Add Ver1.3 Start
    l_kbn_1_rec             l_kbn_1_cur%ROWTYPE;
-- Add Ver1.3 End
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
    -- 1．引当対象データ取得
    --==============================================================
-- Mod Ver1.3 End
--    -- 引当ループ
--    << kbn_1_loop >>
--    FOR l_kbn_1_rec IN l_kbn_1_cur LOOP
    -- 顧客発注番号が指定された場合
    -- またはチェーン店コードと顧客コードがともに指定されていない場合
    IF ( ( gv_customer_po_number IS NOT NULL )
      OR ( gv_login_chain_store_code IS NULL ) AND ( gv_login_customer_code IS NULL ) ) THEN
       ln_cursor_no := 1;
       OPEN l_kbn_1_cur;
    ELSE
      -- 顧客が指定されていない場合
      IF ( gv_login_customer_code IS NULL ) THEN
        ln_cursor_no := 2;
        OPEN l_kbn_11_cur;
      -- 顧客が指定されている場合
      ELSE
        ln_cursor_no := 3;
        OPEN l_kbn_12_cur;
      END IF;
    END IF;
    --
    -- 引当ループ
    << kbn_1_loop >>
    LOOP
    -- 顧客発注番号が指定された場合
    -- またはチェーン店コードと顧客コードがともに指定されていない場合
    IF ( ln_cursor_no = 1 ) THEN
      FETCH l_kbn_1_cur INTO l_kbn_1_rec;
      EXIT WHEN l_kbn_1_cur%NOTFOUND;
    ELSE
      -- 顧客が指定されていない場合
      IF ( ln_cursor_no = 2 ) THEN
        FETCH l_kbn_11_cur INTO l_kbn_1_rec;
        EXIT WHEN l_kbn_11_cur%NOTFOUND;
      -- 顧客が指定されている場合
      ELSE
        FETCH l_kbn_12_cur INTO l_kbn_1_rec;
        EXIT WHEN l_kbn_12_cur%NOTFOUND;
      END IF;
    END IF;
-- Mod Ver1.3 End
      -- 初期化
      lt_sale_class                        := NULL;
      lt_sale_class_name                   := NULL;
      lt_delivery_order_edi                := NULL;
      --
      --==============================================================
      -- 2,3,4．EDI情報取得、定番特売区分設定、訂正前受注数量取得、配送順(EDI)取得
      --==============================================================
      -- EDI受注の場合
      IF ( l_kbn_1_rec.order_source_id = gt_order_source_id ) THEN
        OPEN l_edi_cur( iv_order_number      => l_kbn_1_rec.orig_sys_document_ref
                      , iv_order_line_number => l_kbn_1_rec.orig_sys_line_ref );
        FETCH l_edi_cur INTO l_edi_rec;
        CLOSE l_edi_cur;
        -- 定番特売区分(明細)変数設定
        lt_sale_class := l_edi_rec.ar_sale_class;
        -- 定番特売区分名(明細)変数設定
        IF ( l_edi_rec.ar_sale_class IN ( cv_teiban, cv_sale_class_1 ) ) THEN
          lt_sale_class      := cv_teiban;
          lt_sale_class_name := gt_teiban_name;
        ELSIF ( l_edi_rec.ar_sale_class IN ( cv_tokubai, cv_sale_class_2 ) ) THEN
          lt_sale_class      := cv_tokubai;
          lt_sale_class_name := gt_tokubai_name;
        ELSE
          lt_sale_class      := NULL;
          lt_sale_class_name := NULL;
        END IF;
      END IF;
      --
      -- EDI受注以外またはEDI受注でNULLの場合
      IF ( ( l_kbn_1_rec.order_source_id <> gt_order_source_id )
        OR ( ( l_kbn_1_rec.order_source_id = gt_order_source_id ) AND ( lt_sale_class IS NULL ) ) ) THEN
        -- 定番特売区分(明細)変数設定
        lt_sale_class := l_kbn_1_rec.sale_class;
        -- 定番特売区分名(明細)変数設定
        IF ( l_kbn_1_rec.sale_class = cv_sale_class_1 ) THEN
          lt_sale_class      := cv_teiban;
          lt_sale_class_name := gt_teiban_name;
        ELSIF ( l_kbn_1_rec.sale_class = cv_sale_class_2 ) THEN
          lt_sale_class      := cv_tokubai;
          lt_sale_class_name := gt_tokubai_name;
        ELSE
          lt_sale_class_name := NULL;
        END IF;
      END IF;
      --
      -- 配送順(EDI)変数設定
      IF ( TO_CHAR(l_kbn_1_rec.arrival_date, cv_weekno) IN ( cv_weekno_monday, cv_weekno_wednesday, cv_weekno_friday ) ) THEN
        lt_delivery_order_edi := l_kbn_1_rec.delivery_order1;
      ELSIF ( TO_CHAR(l_kbn_1_rec.arrival_date, cv_weekno) IN ( cv_weekno_tuesday, cv_weekno_thursday, cv_weekno_saturday ) ) THEN
        lt_delivery_order_edi := l_kbn_1_rec.delivery_order2;
      ELSE
        lt_delivery_order_edi := NULL;
      END IF;
      --
      --
      --==============================================================
      -- 5．ロット別引当情報一時表登録更新
      --==============================================================
      INSERT INTO xxcoi_tmp_lot_reserve_info(
          slip_num                              -- 伝票No
        , order_number                          -- 受注番号
        , whse_code                             -- 保管場所コード
        , whse_name                             -- 保管場所名
        , chain_code                            -- チェーン店コード
        , chain_name                            -- チェーン店名
        , cust_fresh_con_code_chain             -- 顧客別鮮度条件コード（チェーン店）
        , shop_code                             -- 店舗コード
        , shop_name                             -- 店舗名
        , customer_code                         -- 顧客コード
        , customer_name                         -- 顧客名
        , cust_fresh_con_code_cust              -- 顧客別鮮度条件コード（顧客）
        , center_code                           -- センターコード
        , center_name                           -- センター名
        , area_code                             -- 地区コード
        , area_name                             -- 地区名
        , shipped_date                          -- 出荷日
        , arrival_date                          -- 着日
        , parent_item_id                        -- 親品目ID
        , parent_item_code                      -- 親品目コード
        , parent_item_name                      -- 親品目名称
        , item_code                             -- 子品目コード
        , regular_sale_class_line               -- 定番特売区分(明細)
        , regular_sale_class_name_line          -- 定番特売区分名(明細)
        , edi_received_date                     -- EDI受信日
        , delivery_order_edi                    -- 配送順(EDI)
        , before_ordered_quantity               -- 訂正前受注数量
        , header_id                             -- 受注ヘッダID
        , line_id                               -- 受注明細ID
        , line_number                           -- 受注明細番号
        , line_type                             -- 明細タイプ
        , customer_id                           -- 顧客ID
        , ordered_quantity                      -- 受注数
        , order_quantity_uom                    -- 受注単位
      ) VALUES (
          l_kbn_1_rec.slip_num                  -- 伝票No
        , l_kbn_1_rec.order_number              -- 受注番号
        , l_kbn_1_rec.whse_code                 -- 保管場所コード
        , l_kbn_1_rec.whse_name                 -- 保管場所名
        , l_kbn_1_rec.chain_code                -- チェーン店コード
        , l_kbn_1_rec.chain_name                -- チェーン店名
        , l_kbn_1_rec.cust_fresh_con_code_chain -- 顧客別鮮度条件コード（チェーン店）
        , l_kbn_1_rec.shop_code                 -- 店舗コード
        , l_kbn_1_rec.shop_name                 -- 店舗名
        , l_kbn_1_rec.customer_code             -- 顧客コード
        , l_kbn_1_rec.customer_name             -- 顧客名
        , l_kbn_1_rec.cust_fresh_con_code_cust  -- 顧客別鮮度条件コード（顧客）
        , l_kbn_1_rec.center_code               -- センターコード
        , l_kbn_1_rec.center_name               -- センター名
        , l_kbn_1_rec.area_code                 -- 地区コード
        , l_kbn_1_rec.area_name                 -- 地区名
        , l_kbn_1_rec.schedule_ship_date        -- 出荷日
        , l_kbn_1_rec.arrival_date              -- 着日
        , l_kbn_1_rec.parent_item_id            -- 親品目ID
        , l_kbn_1_rec.parent_item_code          -- 親品目コード
        , l_kbn_1_rec.parent_item_name          -- 親品目名称
        , l_kbn_1_rec.item_code                 -- 子品目コード
        , lt_sale_class                         -- 定番特売区分(明細)
        , lt_sale_class_name                    -- 定番特売区分名(明細)
        , l_edi_rec.edi_received_date           -- EDI受信日
        , lt_delivery_order_edi                 -- 配送順(EDI)
        , NULL                                  -- 訂正前受注数量
        , l_kbn_1_rec.header_id                 -- 受注ヘッダID
        , l_kbn_1_rec.line_id                   -- 受注明細ID
        , l_kbn_1_rec.line_number               -- 受注明細番号
        , l_kbn_1_rec.line_name                 -- 明細タイプ
        , l_kbn_1_rec.cust_account_id           -- 顧客ID
        , l_kbn_1_rec.ordered_quantity          -- 受注数
        , l_kbn_1_rec.order_quantity_uom        -- 受注単位
      );
    END LOOP kbn_1_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( l_kbn_1_cur%ISOPEN ) THEN
        CLOSE l_kbn_1_cur;
-- Add Ver1.3 Start
      ELSIF ( l_kbn_11_cur%ISOPEN ) THEN
        CLOSE l_kbn_11_cur;
      ELSIF ( l_kbn_12_cur%ISOPEN ) THEN
        CLOSE l_kbn_12_cur;
-- Add Ver1.3 End
      END IF;
      IF ( l_edi_cur%ISOPEN ) THEN
        CLOSE l_edi_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_reserve_data;
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_other_data
   * Description      : 引当以外データ取得処理(A-17)
   ***********************************************************************************/
  PROCEDURE get_reserve_other_data(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_reserve_other_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_lot_tran_cnt            NUMBER      DEFAULT 0;    -- ロット別取引明細件数
    lv_tran_kbn                VARCHAR2(1) DEFAULT NULL; -- 取引区分
-- Add Ver1.3 Start
    ln_cursor_no               NUMBER      DEFAULT NULL; -- カーソル判定
-- Add Ver1.3 End
--
    -- *** ローカルカーソル ***
    -- 引当以外データ取得カーソル
    CURSOR l_kbn_4_cur
    IS
      SELECT /*+ LEADING(ooha oola) */
             ooha.header_id                                AS header_id                 -- 受注ヘッダID
           , ottt1.name                                    AS header_name               -- 受注タイプ名称
           , ooha.cust_po_number                           AS slip_num                  -- 伝票No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- 受注番号
           , ooha.order_source_id                          AS order_source_id           -- 受注ソースID
           , xca2.chain_store_code                         AS chain_code                -- チェーン店コード
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- チェーン店名
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- 顧客別鮮度条件コード（チェーン店）
           , xca1.store_code                               AS shop_code                 -- 店舗コード
           , xca1.cust_store_name                          AS shop_name                 -- 店舗名
           , hca1.cust_account_id                          AS cust_account_id           -- 顧客ID
           , hca1.account_number                           AS customer_code             -- 顧客コード
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- 顧客名
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- 顧客別鮮度条件コード（顧客）
           , xca1.deli_center_code                         AS center_code               -- センターコード
           , xca1.deli_center_name                         AS center_name               -- センター名
           , xca1.edi_district_code                        AS area_code                 -- 地区コード
           , xca1.edi_district_name                        AS area_name                 -- 地区名
           , oola.line_id                                  AS line_id                   -- 受注明細ID
           , oola.line_number                              AS line_number               -- 受注明細番号
           , oola.inventory_item_id                        AS parent_item_id            -- 親品目ID
           , iimb.item_no                                  AS parent_item_code          -- 親品目コード
           , ximb.item_short_name                          AS parent_item_name          -- 親品目名
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- 売上区分
           , oola.attribute6                               AS item_code                 -- 子品目コード
           , oola.ordered_quantity                         AS ordered_quantity          -- 受注数量
           , oola.order_quantity_uom                       AS order_quantity_uom        -- 受注単位
           , oola.schedule_ship_date                       AS schedule_ship_date        -- 出荷日
           , TRUNC(oola.request_date)                      AS arrival_date              -- 着日
           , msi.attribute7                                AS base_code                 -- 拠点コード
           , oola.subinventory                             AS whse_code                 -- 保管場所コード
           , msi.description                               AS whse_name                 -- 保管場所名
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- 外部システム受注番号
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- 外部システム受注明細番号
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- 配送順（月、水、金）
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- 配送順（火、木、土）
           , ottt2.name                                    AS line_name                 -- 明細タイプ
           , oola.flow_status_code                         AS flow_status_code          -- 明細ステータス
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code          <> cv_entered
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                 > gt_max_header_id
-- Add Ver1.1 Start
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
-- Add Ver1.1 End
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( hca1.account_number            = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( ooha.cust_po_number            = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
      ORDER BY ooha.order_number
             , oola.line_number
    ;
-- Add Ver1.3 Start
    -- 引当以外データ取得カーソル2
    CURSOR l_kbn_41_cur
    IS
      SELECT /*+ LEADING(xca1) */
             ooha.header_id                                AS header_id                 -- 受注ヘッダID
           , ottt1.name                                    AS header_name               -- 受注タイプ名称
           , ooha.cust_po_number                           AS slip_num                  -- 伝票No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- 受注番号
           , ooha.order_source_id                          AS order_source_id           -- 受注ソースID
           , xca2.chain_store_code                         AS chain_code                -- チェーン店コード
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- チェーン店名
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- 顧客別鮮度条件コード（チェーン店）
           , xca1.store_code                               AS shop_code                 -- 店舗コード
           , xca1.cust_store_name                          AS shop_name                 -- 店舗名
           , hca1.cust_account_id                          AS cust_account_id           -- 顧客ID
           , hca1.account_number                           AS customer_code             -- 顧客コード
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- 顧客名
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- 顧客別鮮度条件コード（顧客）
           , xca1.deli_center_code                         AS center_code               -- センターコード
           , xca1.deli_center_name                         AS center_name               -- センター名
           , xca1.edi_district_code                        AS area_code                 -- 地区コード
           , xca1.edi_district_name                        AS area_name                 -- 地区名
           , oola.line_id                                  AS line_id                   -- 受注明細ID
           , oola.line_number                              AS line_number               -- 受注明細番号
           , oola.inventory_item_id                        AS parent_item_id            -- 親品目ID
           , iimb.item_no                                  AS parent_item_code          -- 親品目コード
           , ximb.item_short_name                          AS parent_item_name          -- 親品目名
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- 売上区分
           , oola.attribute6                               AS item_code                 -- 子品目コード
           , oola.ordered_quantity                         AS ordered_quantity          -- 受注数量
           , oola.order_quantity_uom                       AS order_quantity_uom        -- 受注単位
           , oola.schedule_ship_date                       AS schedule_ship_date        -- 出荷日
           , TRUNC(oola.request_date)                      AS arrival_date              -- 着日
           , msi.attribute7                                AS base_code                 -- 拠点コード
           , oola.subinventory                             AS whse_code                 -- 保管場所コード
           , msi.description                               AS whse_name                 -- 保管場所名
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- 外部システム受注番号
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- 外部システム受注明細番号
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- 配送順（月、水、金）
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- 配送順（火、木、土）
           , ottt2.name                                    AS line_name                 -- 明細タイプ
           , oola.flow_status_code                         AS flow_status_code          -- 明細ステータス
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code          <> cv_entered
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                 > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND    xca1.chain_store_code          = gv_login_chain_store_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
      ORDER BY ooha.order_number
             , oola.line_number
    ;
    -- 引当以外データ取得カーソル2
    CURSOR l_kbn_42_cur
    IS
      SELECT /*+ LEADING(hca1) */
             ooha.header_id                                AS header_id                 -- 受注ヘッダID
           , ottt1.name                                    AS header_name               -- 受注タイプ名称
           , ooha.cust_po_number                           AS slip_num                  -- 伝票No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- 受注番号
           , ooha.order_source_id                          AS order_source_id           -- 受注ソースID
           , xca2.chain_store_code                         AS chain_code                -- チェーン店コード
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- チェーン店名
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- 顧客別鮮度条件コード（チェーン店）
           , xca1.store_code                               AS shop_code                 -- 店舗コード
           , xca1.cust_store_name                          AS shop_name                 -- 店舗名
           , hca1.cust_account_id                          AS cust_account_id           -- 顧客ID
           , hca1.account_number                           AS customer_code             -- 顧客コード
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- 顧客名
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- 顧客別鮮度条件コード（顧客）
           , xca1.deli_center_code                         AS center_code               -- センターコード
           , xca1.deli_center_name                         AS center_name               -- センター名
           , xca1.edi_district_code                        AS area_code                 -- 地区コード
           , xca1.edi_district_name                        AS area_name                 -- 地区名
           , oola.line_id                                  AS line_id                   -- 受注明細ID
           , oola.line_number                              AS line_number               -- 受注明細番号
           , oola.inventory_item_id                        AS parent_item_id            -- 親品目ID
           , iimb.item_no                                  AS parent_item_code          -- 親品目コード
           , ximb.item_short_name                          AS parent_item_name          -- 親品目名
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- 売上区分
           , oola.attribute6                               AS item_code                 -- 子品目コード
           , oola.ordered_quantity                         AS ordered_quantity          -- 受注数量
           , oola.order_quantity_uom                       AS order_quantity_uom        -- 受注単位
           , oola.schedule_ship_date                       AS schedule_ship_date        -- 出荷日
           , TRUNC(oola.request_date)                      AS arrival_date              -- 着日
           , msi.attribute7                                AS base_code                 -- 拠点コード
           , oola.subinventory                             AS whse_code                 -- 保管場所コード
           , msi.description                               AS whse_name                 -- 保管場所名
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- 外部システム受注番号
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- 外部システム受注明細番号
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- 配送順（月、水、金）
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- 配送順（火、木、土）
           , ottt2.name                                    AS line_name                 -- 明細タイプ
           , oola.flow_status_code                         AS flow_status_code          -- 明細ステータス
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code          <> cv_entered
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                 > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND    hca1.account_number             = gv_login_customer_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
      ORDER BY ooha.order_number
             , oola.line_number
    ;
    l_kbn_4_rec             l_kbn_4_cur%ROWTYPE;
-- Add Ver1.3 End
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
    -- 1．引当以外データ取得
    --==============================================================
-- Mod Ver1.3 End
--    -- 引当以外ループ
--    << kbn_4_loop >>
--    FOR l_kbn_4_rec IN l_kbn_4_cur LOOP
    -- 顧客発注番号が指定された場合
    -- またはチェーン店コードと顧客コードがともに指定されていない場合
    IF ( ( gv_customer_po_number IS NOT NULL )
      OR ( gv_login_chain_store_code IS NULL ) AND ( gv_login_customer_code IS NULL ) ) THEN
      ln_cursor_no := 1;
      OPEN l_kbn_4_cur;
    ELSE
      -- 顧客が指定されていない場合
      IF ( gv_login_customer_code IS NULL ) THEN
        ln_cursor_no := 2;
        OPEN l_kbn_41_cur;
      -- 顧客が指定されている場合
      ELSE
        ln_cursor_no := 3;
        OPEN l_kbn_42_cur;
      END IF;
    END IF;
    --
    -- 引当以外ループ
    << kbn_4_loop >>
    LOOP
    -- 顧客発注番号が指定された場合
    -- またはチェーン店コードと顧客コードがともに指定されていない場合
    IF ( ln_cursor_no = 1 ) THEN
      FETCH l_kbn_4_cur INTO l_kbn_4_rec;
      EXIT WHEN l_kbn_4_cur%NOTFOUND;
    ELSE
      -- 顧客が指定されていない場合
      IF ( ln_cursor_no = 2 ) THEN
        FETCH l_kbn_41_cur INTO l_kbn_4_rec;
        EXIT WHEN l_kbn_41_cur%NOTFOUND;
      -- 顧客が指定されている場合
      ELSE
        FETCH l_kbn_42_cur INTO l_kbn_4_rec;
        EXIT WHEN l_kbn_42_cur%NOTFOUND;
      END IF;
    END IF;
-- Mod Ver1.3 End
      -- 初期化
      ln_lot_tran_cnt := 0;
      lv_tran_kbn     := NULL;
      --==============================================================
      -- 2．受注タイプ判定
      --==============================================================
      -- 2-1．受注タイプが「返品」「返品訂正」の場合
      --      ※返品、返品訂正、百貨店返品、百貨店返品訂正
      << return_loop >>
      FOR i IN 1 .. gt_return_tab.COUNT LOOP
        IF ( l_kbn_4_rec.header_name = gt_return_tab(i) ) THEN
          lv_tran_kbn := cv_tran_kbn_2;
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => '返品'        ||
                        ' 受注番号：' || l_kbn_4_rec.order_number ||
                        ' 明細番号：' || l_kbn_4_rec.line_number
          );
          --
          EXIT return_loop;
        END IF;
      END LOOP return_loop;
      --
      -- 2-2．受注タイプが「訂正」の場合
      --      ※通常訂正、見本訂正、広告宣伝費訂正、百貨店訂正、百貨店見本訂正
      IF ( lv_tran_kbn IS NULL ) THEN
        << correct_loop >>
        FOR i IN 1 .. gt_correct_tab.COUNT LOOP
          IF ( l_kbn_4_rec.header_name = gt_correct_tab(i) ) THEN
            lv_tran_kbn := cv_tran_kbn_3;
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '訂正'        ||
                          ' 受注番号：' || l_kbn_4_rec.order_number ||
                          ' 明細番号：' || l_kbn_4_rec.line_number
            );
            --
            EXIT correct_loop;
          END IF;
        END LOOP correct_loop;
      END IF;
      --
      -- 2-3．受注の場合
      --      ※通常受注、見本、広告宣伝費、百貨店受注、百貨店見本
      IF ( ( lv_tran_kbn IS NULL ) AND ( l_kbn_4_rec.arrival_date < gd_process_date ) ) THEN
        lv_tran_kbn := cv_tran_kbn_1;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '受注'        ||
                      ' 受注番号：' || l_kbn_4_rec.order_number ||
                      ' 明細番号：' || l_kbn_4_rec.line_number
        );
      END IF;
      -- 登録対象の場合
      IF ( lv_tran_kbn IS NOT NULL ) THEN
        -- ロット別取引明細件数
        SELECT COUNT(1)
        INTO   ln_lot_tran_cnt
        FROM   xxcoi_lot_transactions xlt
        WHERE  xlt.source_code  = cv_pkg_name
        AND    xlt.relation_key = l_kbn_4_rec.header_id || cv_under || l_kbn_4_rec.line_id
        ;
        -- ロット別取引明細が存在しない場合
        IF ( ln_lot_tran_cnt = 0 ) THEN
          -- ロット別取引TEMP登録処理
          ins_lot_tran_temp(
              iv_tran_kbn           => lv_tran_kbn                    -- 取引区分
            , in_header_id          => l_kbn_4_rec.header_id          -- 受注ヘッダID
            , in_line_id            => l_kbn_4_rec.line_id            -- 受注明細ID
            , iv_slip_num           => l_kbn_4_rec.slip_num           -- 伝票No
            , iv_order_number       => l_kbn_4_rec.order_number       -- 受注番号
            , iv_line_number        => l_kbn_4_rec.line_number        -- 受注明細番号
            , id_arrival_date       => l_kbn_4_rec.arrival_date       -- 着日
            , iv_parent_item_code   => l_kbn_4_rec.parent_item_code   -- 親品目コード
            , iv_item_code          => l_kbn_4_rec.item_code          -- 子品目コード
            , in_parent_item_id     => l_kbn_4_rec.parent_item_id     -- 品目ID
            , iv_order_quantity_uom => l_kbn_4_rec.order_quantity_uom -- 受注単位
            , in_ordered_quantity   => l_kbn_4_rec.ordered_quantity   -- 受注数量
            , iv_base_code          => l_kbn_4_rec.base_code          -- 拠点コード
            , iv_subinventory_code  => l_kbn_4_rec.whse_code          -- 保管場所コード
            , iv_line_name          => l_kbn_4_rec.line_name          -- 明細摘要
            , iv_sale_class         => l_kbn_4_rec.sale_class         -- 定番特売区分(明細)
            , iv_flow_status_code   => l_kbn_4_rec.flow_status_code   -- 明細ステータス
            , ov_errbuf             => lv_errbuf                      -- エラー・メッセージ
            , ov_retcode            => lv_retcode                     -- リターン・コード
            , ov_errmsg             => lv_errmsg                      -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSE
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => 'A-17 ロット別取引明細存在' ||
                        ' 受注番号：'               || l_kbn_4_rec.order_number ||
                        ' 受注明細番号：'           || l_kbn_4_rec.line_number
          );
        END IF;
      ELSE
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '登録対象外'  ||
                      ' 受注番号：' || l_kbn_4_rec.order_number ||
                      ' 明細番号：' || l_kbn_4_rec.line_number
        );
      END IF;
      --
    END LOOP kbn_4_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( l_kbn_4_cur%ISOPEN ) THEN
        CLOSE l_kbn_4_cur;
-- Add Ver1.3 Start
      ELSIF ( l_kbn_41_cur%ISOPEN ) THEN
        CLOSE l_kbn_41_cur;
      ELSIF ( l_kbn_42_cur%ISOPEN ) THEN
        CLOSE l_kbn_42_cur;
-- Add Ver1.3 End
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_reserve_other_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_reserve_data
   * Description      : 引当対象データチェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE chk_reserve_data(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- 引当レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_reserve_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    ld_last_deliver_lot_e   DATE DEFAULT NULL; -- 納品ロット_生産
    ld_delivery_date_e      DATE DEFAULT NULL; -- 納品日_生産
    ld_last_deliver_lot_s   DATE DEFAULT NULL; -- 納品ロット_営業
    ld_delivery_date_s      DATE DEFAULT NULL; -- 納品日_営業
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
    -- 1．顧客別鮮度条件コードチェック
    --==============================================================
    IF (  ( it_kbn_1_rec.cust_fresh_con_code_chain IS NULL )
      AND ( it_kbn_1_rec.cust_fresh_con_code_cust IS NULL ) ) THEN
      -- 鮮度条件は「00:一般」で引当する
      gt_cust_fresh_con_code := cv_cust_fresh_con_code_00;
    ELSE
      -- 顧客別鮮度条件コード（顧客）が設定されている場合は顧客
      IF ( it_kbn_1_rec.cust_fresh_con_code_cust IS NOT NULL ) THEN
        gt_cust_fresh_con_code := it_kbn_1_rec.cust_fresh_con_code_cust;
      -- 顧客別鮮度条件コード（顧客）が設定されていない場合はチェーン店
      ELSE
        gt_cust_fresh_con_code := it_kbn_1_rec.cust_fresh_con_code_chain;
      END IF;
    END IF;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-5 顧客別鮮度条件コード：' || gt_cust_fresh_con_code
    );
--
    --==============================================================
    -- 2．ロット情報保持マスタ取得
    --==============================================================
    BEGIN
      SELECT TO_DATE(xmlhi.last_deliver_lot_e, cv_yyyymmdd) AS last_deliver_lot_e -- 納品ロット_営業
           , xmlhi.delivery_date_e                          AS delivery_date_e    -- 納品日_営業
           , TO_DATE(xmlhi.last_deliver_lot_s, cv_yyyymmdd) AS last_deliver_lot_s -- 納品ロット_生産
           , xmlhi.delivery_date_s                          AS delivery_date_s    -- 納品日_生産
      INTO   ld_last_deliver_lot_e
           , ld_delivery_date_e
           , ld_last_deliver_lot_s
           , ld_delivery_date_s
      FROM   xxcoi_mst_lot_hold_info  xmlhi
      WHERE  xmlhi.customer_id    = it_kbn_1_rec.customer_id
      AND    xmlhi.parent_item_id = it_kbn_1_rec.parent_item_id
      ;
      -- 保持日付判定：納品日が新しい方を設定する
      IF ( ( ld_delivery_date_s IS NULL )
        OR ( ld_delivery_date_e > ld_delivery_date_s )
        OR ( ld_delivery_date_e = ld_delivery_date_s ) AND ( ld_last_deliver_lot_e >= ld_last_deliver_lot_s ) ) THEN
        gd_last_deliver_lot := ld_last_deliver_lot_e;
        gd_delivery_date    := ld_delivery_date_e;
      ELSE
        gd_last_deliver_lot := ld_last_deliver_lot_s;
        gd_delivery_date    := ld_delivery_date_s;
      END IF;
      --
    EXCEPTION
      -- 取得できない場合（新規の顧客や品目）は、後続で設定するためNULLとしておく
      WHEN NO_DATA_FOUND THEN
        gd_last_deliver_lot := NULL;
        gd_delivery_date    := NULL;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_reserve_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item
   * Description      : 子品目情報取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_item(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- 引当レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item'; -- プログラム名
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
    -- *** ローカル変数 ***
    --
    lt_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- 品目ID
    lt_item_code               mtl_system_items_b.segment1%TYPE          DEFAULT NULL; -- 品目コード
    lt_after_uom_code          mtl_units_of_measure_tl.uom_code%TYPE     DEFAULT NULL; -- 換算後単位コード
    ln_after_quantity          NUMBER                                    DEFAULT 0;    -- 換算後数量
    ln_content                 NUMBER                                    DEFAULT 0;    -- 入数
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
    -- 1．子品目情報取得
    --==============================================================
    xxcoi_common_pkg.get_parent_child_item_info(
        id_date           => it_kbn_1_rec.arrival_date   -- 日付
      , in_inv_org_id     => gt_organization_id          -- 在庫組織ID
      , in_parent_item_id => it_kbn_1_rec.parent_item_id -- 親品目ID
      , in_child_item_id  => NULL                        -- 子品目ID
      , ot_item_info_tab  => gt_item_info_tab            -- 品目情報（テーブル型）
      , ov_errbuf         => lv_errbuf                   -- エラーメッセージ
      , ov_retcode        => lv_retcode                  -- リターンコード
      , ov_errmsg         => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    -- リターンコードが正常以外の場合、エラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10562
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    -- 2．ロット別引当子品目一時表削除
    --==============================================================
    DELETE FROM xxcoi_tmp_lot_reserve_item xtlri
    ;
    --
    --==============================================================
    -- 3．ロット別引当子品目一時表登録
    --==============================================================
    -- 子品目コードがNULLの場合（受注が親品目しかない場合）
    IF ( it_kbn_1_rec.item_code IS NULL ) THEN
      -- 親品目登録ループ
      << ins_parent_item_loop >>
      FOR i IN 1 .. gt_item_info_tab.COUNT LOOP
        INSERT INTO xxcoi_tmp_lot_reserve_item(
            item_id       -- 子品目ID
          , item_code     -- 子品目コード
          , item_name     -- 子品目名称
          , item_div      -- 商品区分
          , item_div_name -- 商品区分名
        ) VALUES (
            gt_item_info_tab(i).item_id
          , gt_item_info_tab(i).item_no
          , gt_item_info_tab(i).item_short_name
          , gt_item_info_tab(i).item_kbn
          , gt_item_info_tab(i).item_kbn_name
        );
      END LOOP ins_parent_item_loop;
      -- 変数設定
      lt_inventory_item_id := it_kbn_1_rec.parent_item_id;
      lt_item_code         := it_kbn_1_rec.parent_item_code;
    -- 子品目コードがNOT NULLの場合
    ELSE
      -- 子品目登録ループ
      << ins_item_loop >>
      FOR i IN 1 .. gt_item_info_tab.COUNT LOOP
        -- 子コードと一致するデータのみ、登録・変数設定してループを抜ける
        IF ( gt_item_info_tab(i).item_no = it_kbn_1_rec.item_code ) THEN
          INSERT INTO xxcoi_tmp_lot_reserve_item(
              item_id       -- 子品目ID
            , item_code     -- 子品目コード
            , item_name     -- 子品目名称
            , item_div      -- 商品区分
            , item_div_name -- 商品区分名
          ) VALUES (
              gt_item_info_tab(i).item_id
            , gt_item_info_tab(i).item_no
            , gt_item_info_tab(i).item_short_name
            , gt_item_info_tab(i).item_kbn
            , gt_item_info_tab(i).item_kbn_name
          );
          --
          lt_inventory_item_id := gt_item_info_tab(i).item_id;
          lt_item_code         := gt_item_info_tab(i).item_no;
          --
          EXIT ins_item_loop;
          --
        END IF;
      END LOOP ins_item_loop;
    END IF;
    --
    -- 配列削除
    gt_item_info_tab.DELETE;
    --
    -- デバッグ用
    SELECT COUNT(1)
    INTO   gn_debug_cnt
    FROM   xxcoi_tmp_lot_reserve_item
    ;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-6.3 ロット別引当子品目一時表登録件数：' || gn_debug_cnt
    );
--
    --==============================================================
    -- 4．単位換算取得
    --==============================================================
    -- 単位換算取得
    xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => it_kbn_1_rec.order_quantity_uom -- 換算前単位コード
      , in_before_quantity    => it_kbn_1_rec.ordered_quantity   -- 換算前数量
      , iov_item_code         => lt_item_code                    -- 品目コード
      , iov_organization_code => gt_organization_code            -- 在庫組織コード
      , ion_inventory_item_id => lt_inventory_item_id            -- 品目ＩＤ
      , ion_organization_id   => gt_organization_id              -- 在庫組織ＩＤ
      , iov_after_uom_code    => lt_after_uom_code               -- 換算後単位コード
      , on_after_quantity     => ln_after_quantity               -- 換算後数量
      , on_content            => ln_content                      -- 入数
      , ov_errbuf             => lv_errbuf                       -- エラー・メッセージエラー       #固定#
      , ov_retcode            => lv_retcode                      -- リターン・コード               #固定#
      , ov_errmsg             => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
    );
    -- リターンコードが正常以外の場合、エラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10552
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 5．入数取得
    --==============================================================
    -- 単位換算の入数は正しくないため取得
    SELECT TO_NUMBER(iimb.attribute11) AS attribute11
    INTO   ln_content
    FROM   ic_item_mst_b iimb
    WHERE  iimb.item_no = lt_item_code
    ;
    gt_order_case_in_qty  := ln_content;
    -- ケース数・バラ数変換
    gt_order_case_qty   := TRUNC( ln_after_quantity / ln_content );
    gt_order_singly_qty := MOD( ln_after_quantity, ln_content );
    -- 総数
    gt_order_summary_qty := ln_after_quantity;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-6.4 受注情報' ||
                  ' 受注番号：'    || it_kbn_1_rec.order_number                       ||
                  ' 品目コード：'  || lt_item_code                                    ||
                  ' 着日：'        || TO_CHAR(it_kbn_1_rec.arrival_date, cv_yyyymmdd) ||
                  ' 入数：'        || gt_order_case_in_qty                            ||
                  ' ケース数：'    || gt_order_case_qty                               ||
                  ' バラ数：'      || gt_order_singly_qty                             ||
                  ' 総数：'        || gt_order_summary_qty
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_item;
--
  /**********************************************************************************
   * Procedure Name   : inventory_reservation
   * Description      : 引当対象在庫判定処理(A-7)
   ***********************************************************************************/
  PROCEDURE inventory_reservation(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- 引当レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inventory_reservation'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_priority_cnt            NUMBER                                          DEFAULT 0;    -- 優先引当ロケーションレコード件数
    ln_location_cnt            NUMBER                                          DEFAULT 0;    -- 通常またはダミーロケーションレコード件数
    --
    lt_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE       DEFAULT NULL; -- 品目ID
    lt_item_code               mtl_system_items_b.segment1%TYPE                DEFAULT NULL; -- 品目コード
    lt_item_name               xxcmn_item_mst_b.item_short_name%TYPE           DEFAULT NULL; -- 品目名称
    lt_item_kbn                mtl_categories_vl.segment1%TYPE                 DEFAULT NULL; -- 商品区分
    lt_item_kbn_name           mtl_categories_vl.description%TYPE              DEFAULT NULL; -- 商品区分名
    --
    lt_location_code           xxcoi_mst_warehouse_location.location_code%TYPE DEFAULT NULL; -- ロケーションコード
    lt_location_name           xxcoi_mst_warehouse_location.location_name%TYPE DEFAULT NULL; -- ロケーション名
    --
    lt_short_case_qty          xxcoi_lot_onhand_quantites.case_qty%TYPE        DEFAULT 0;    -- ケース数（不足数）
    lt_short_singly_qty        xxcoi_lot_onhand_quantites.singly_qty%TYPE      DEFAULT 0;    -- バラ数（不足数）
    lt_short_summary_qty       xxcoi_lot_onhand_quantites.summary_qty%TYPE     DEFAULT 0;    -- 総数（不足数）
--
    -- *** ローカルカーソル ***
    -- 優先ロケーションカーソル
    CURSOR l_priority_cur( iv_whse_code     VARCHAR2
                         , iv_location_code VARCHAR2 )
    IS
      SELECT xtlri.item_id                              AS item_id                 -- 子品目ID
           , xtlri.item_code                            AS item_code               -- 子品目コード
           , xtlri.item_name                            AS item_name               -- 子品目名称
           , xtlri.item_div                             AS item_div                -- 商品区分
           , xtlri.item_div_name                        AS item_div_name           -- 商品区分名
           , xloq.subinventory_code                     AS subinventory_code       -- 保管場所コード
           , xloq.location_code                         AS location_code           -- ロケーションコード
           , xloq.lot                                   AS lot                     -- ロット
           , xloq.difference_summary_code               AS difference_summary_code -- 固有記号
           , TO_DATE(xloq.production_date, cv_yyyymmdd) AS production_date         -- 製造日
      FROM   xxcoi_lot_onhand_quantites   xloq
           , xxcoi_tmp_lot_reserve_item   xtlri
      WHERE  xloq.organization_id   = gt_organization_id
      AND    xloq.base_code         = gv_login_base_code
      AND    xloq.subinventory_code = iv_whse_code
      AND    xloq.location_code     = iv_location_code
      AND    xloq.child_item_id     = xtlri.item_id
      ORDER BY xloq.lot
             , xtlri.item_code
             , xloq.difference_summary_code
    ;
    -- 通常またはダミーロケーションカーソル
    CURSOR l_location_cur( iv_whse_code VARCHAR2 )
    IS
      SELECT xtlri.item_id                              AS item_id                 -- 子品目ID
           , xtlri.item_code                            AS item_code               -- 子品目コード
           , xtlri.item_name                            AS item_name               -- 子品目名称
           , xtlri.item_div                             AS item_div                -- 商品区分
           , xtlri.item_div_name                        AS item_div_name           -- 商品区分名
           , xloq.subinventory_code                     AS subinventory_code       -- 保管場所コード
           , xloq.location_code                         AS location_code           -- ロケーションコード
           , ( SELECT xwlmv.location_name
               FROM   xxcoi_warehouse_location_mst_v xwlmv
               WHERE  xwlmv.organization_id   = xloq.organization_id
               AND    xwlmv.base_code         = xloq.base_code
               AND    xwlmv.subinventory_code = xloq.subinventory_code
               AND    xwlmv.location_code     = xloq.location_code
             )                                          AS location_name           -- ロケーション名
           , xmwlv.priority                             AS priority                -- 優先順位
           , xloq.lot                                   AS lot                     -- ロット
           , xloq.difference_summary_code               AS difference_summary_code -- 固有記号
           , TO_DATE(xloq.production_date, cv_yyyymmdd) AS production_date         -- 製造日
      FROM   xxcoi_lot_onhand_quantites                 xloq
           , xxcoi_tmp_lot_reserve_item                 xtlri
           , ( SELECT xmwl.organization_id         AS organization_id
                    , xmwl.base_code               AS base_code
                    , xmwl.subinventory_code       AS subinventory_code
                    , xmwl.location_code           AS location_code
                    , MIN(xmwl.priority)           AS priority
               FROM   xxcoi_mst_warehouse_location xmwl
               WHERE  xmwl.location_type IN ( cv_normal, cv_dummy )
               GROUP BY xmwl.organization_id
                      , xmwl.base_code
                      , xmwl.subinventory_code
                      , xmwl.location_code )       xmwlv
      WHERE  xloq.organization_id   = xmwlv.organization_id
      AND    xloq.base_code         = xmwlv.base_code
      AND    xloq.subinventory_code = xmwlv.subinventory_code
      AND    xloq.location_code     = xmwlv.location_code
      AND    xloq.child_item_id     = xtlri.item_id
      AND    xloq.organization_id   = gt_organization_id
      AND    xloq.base_code         = gv_login_base_code
      AND    xloq.subinventory_code = iv_whse_code
      ORDER BY xloq.lot
             , xmwlv.priority
             , xtlri.item_code
             , xloq.difference_summary_code
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
    -- 初期化
    gv_reserve_err_msg   := NULL;
    lt_short_case_qty    := gt_order_case_qty;    -- ケース数（不足数）
    lt_short_singly_qty  := gt_order_singly_qty;  -- バラ数（不足数）
    lt_short_summary_qty := gt_order_summary_qty; -- 総数（不足数）
    --
    --==============================================================
    -- 1．優先ロケーションからの引当
    --==============================================================
    -- 優先ロケーション使用がYの場合、優先引当ロケーションからの引当
    IF ( gv_priority_flag = cv_flag_y ) THEN
      -- 1-1．優先引当ロケーション取得
      BEGIN
        SELECT xmwl.location_code             AS location_code -- ロケーショコード
             , xmwl.location_name             AS location_name -- ロケーション名
        INTO   lt_location_code
             , lt_location_name
        FROM   xxcoi_warehouse_location_mst_v xmwl
        WHERE  xmwl.organization_id   = gt_organization_id
        AND    xmwl.base_code         = gv_login_base_code
        AND    xmwl.subinventory_code = it_kbn_1_rec.whse_code
        AND    xmwl.location_type     = cv_priority
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 優先引当ロケーション存在エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10546
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_subinventory_code
                         , iv_token_value2 => it_kbn_1_rec.whse_code
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- 1-2．優先引当ロケーションからの引当
      << priority_loop >>
      FOR l_priority_rec IN l_priority_cur( iv_whse_code     => it_kbn_1_rec.whse_code
                                          , iv_location_code => lt_location_code ) LOOP
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-7.1 優先ロケーション情報' ||
                      ' 保管場所コード：'          || l_priority_rec.subinventory_code                     ||
                      ' ロケーションコード：'      || l_priority_rec.location_code                         ||
                      ' 子品目コード：'            || l_priority_rec.item_code                             ||
                      ' 賞味期限：'                || l_priority_rec.lot                                   ||
                      ' 固有記号：'                || l_priority_rec.difference_summary_code               ||
                      ' 製造日：'                  || TO_CHAR(l_priority_rec.production_date, cv_yyyymmdd)
        );
        -- レコード件数
        ln_priority_cnt := ln_priority_cnt + 1;
        -- 引当処理
        reserve_process(
            iv_process_kbn             => cv_process_kbn_1                       -- 処理区分
          , iv_subinventory_code       => l_priority_rec.subinventory_code       -- 保管場所コード
          , iv_location_code           => l_priority_rec.location_code           -- ロケーションコード
          , iv_location_name           => lt_location_name                       -- ロケーション名
          , iv_item_div                => l_priority_rec.item_div                -- 商品区分
          , iv_item_div_name           => l_priority_rec.item_div_name           -- 商品区分名
          , in_item_id                 => l_priority_rec.item_id                 -- 子品目ID
          , iv_item_code               => l_priority_rec.item_code               -- 子品目コード
          , iv_item_name               => l_priority_rec.item_name               -- 子品目名
          , iv_lot                     => l_priority_rec.lot                     -- ロット
          , iv_difference_summary_code => l_priority_rec.difference_summary_code -- 固有記号
          , id_production_date         => l_priority_rec.production_date         -- 製造日
          , id_arrival_date            => it_kbn_1_rec.arrival_date              -- 納品日
          , iv_order_number            => it_kbn_1_rec.order_number              -- 受注番号
          , iv_customer_code           => it_kbn_1_rec.customer_code             -- 顧客コード
          , iv_parent_item_code        => it_kbn_1_rec.parent_item_code          -- 親品目コード
          , ion_short_case_qty         => lt_short_case_qty                      -- ケース数（不足数）
          , ion_short_singly_qty       => lt_short_singly_qty                    -- バラ数（不足数）
          , ion_short_summary_qty      => lt_short_summary_qty                   -- 総数（不足数）
          , ov_errbuf                  => lv_errbuf                              -- エラー・メッセージ
          , ov_retcode                 => lv_retcode                             -- リターン・コード
          , ov_errmsg                  => lv_errmsg                              -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- 受注数に達する or 取得した分を全て完了した場合にループを抜ける
        IF ( lt_short_summary_qty = 0 ) THEN
          EXIT priority_loop;
        END IF;
        --
      END LOOP priority_loop;
      --
    END IF;
--
    --==============================================================
    -- 2．通常ロケーションまたはダミーロケーションからの引当
    --==============================================================
    -- 優先ロケーション使用がNの場合 
    -- または 優先ロケーションからの引当後に不足数（引当できていない受注数）が存在する場合
    IF ( ( gv_priority_flag = cv_flag_n )
      OR ( lt_short_summary_qty > 0 ) ) THEN
      -- 2-1．通常またはダミーロケーションからの引当
      << location_loop >>
      FOR l_location_rec IN l_location_cur( iv_whse_code => it_kbn_1_rec.whse_code ) LOOP
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-7.2 ロケーション情報' ||
                      ' 保管場所コード：'      || l_location_rec.subinventory_code                     ||
                      ' ロケーションコード：'  || l_location_rec.location_code                         ||
                      ' 子品目コード：'        || l_location_rec.item_code                             ||
                      ' 賞味期限：'            || l_location_rec.lot                                   ||
                      ' 固有記号：'            || l_location_rec.difference_summary_code               ||
                      ' 製造日：'              || TO_CHAR(l_location_rec.production_date, cv_yyyymmdd)
        );
        -- レコード件数
        ln_location_cnt := ln_location_cnt + 1;
        -- 引当処理
        reserve_process(
            iv_process_kbn             => cv_process_kbn_2                       -- 処理区分
          , iv_subinventory_code       => l_location_rec.subinventory_code       -- 保管場所コード
          , iv_location_code           => l_location_rec.location_code           -- ロケーションコード
          , iv_location_name           => l_location_rec.location_name           -- ロケーション名
          , iv_item_div                => l_location_rec.item_div                -- 商品区分
          , iv_item_div_name           => l_location_rec.item_div_name           -- 商品区分名
          , in_item_id                 => l_location_rec.item_id                 -- 子品目ID
          , iv_item_code               => l_location_rec.item_code               -- 子品目コード
          , iv_item_name               => l_location_rec.item_name               -- 子品目名
          , iv_lot                     => l_location_rec.lot                     -- ロット
          , iv_difference_summary_code => l_location_rec.difference_summary_code -- 固有記号
          , id_production_date         => l_location_rec.production_date         -- 製造日
          , id_arrival_date            => it_kbn_1_rec.arrival_date              -- 納品日
          , iv_order_number            => it_kbn_1_rec.order_number              -- 受注番号
          , iv_customer_code           => it_kbn_1_rec.customer_code             -- 顧客コード
          , iv_parent_item_code        => it_kbn_1_rec.parent_item_code          -- 親品目コード
          , ion_short_case_qty         => lt_short_case_qty                      -- ケース数（不足数）
          , ion_short_singly_qty       => lt_short_singly_qty                    -- バラ数（不足数）
          , ion_short_summary_qty      => lt_short_summary_qty                   -- 総数（不足数）
          , ov_errbuf                  => lv_errbuf                              -- エラー・メッセージ
          , ov_retcode                 => lv_retcode                             -- リターン・コード
          , ov_errmsg                  => lv_errmsg                              -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- 受注数に達する or 取得した分を全て完了した場合にループを抜ける
        IF ( lt_short_summary_qty = 0 ) THEN
          EXIT location_loop;
        END IF;
        --
      END LOOP location_loop;
      --
    END IF;
--
    --==============================================================
    -- 3．メッセージ出力
    --==============================================================
    -- 取得した分を全て完了した後に不足数（引当できていない受注数）が存在する場合
    IF ( lt_short_summary_qty > 0 ) THEN
      -- 子品目コードがNULLの場合（受注が親品目しかない場合）は、親品目
      -- 子品目コードがNOT NULLの場合は、子品目
      SELECT item_id       AS item_id
           , item_code     AS item_code
           , item_name     AS item_name
           , item_div      AS item_div
           , item_div_name AS item_div_name
      INTO   lt_inventory_item_id
           , lt_item_code
           , lt_item_name
           , lt_item_kbn
           , lt_item_kbn_name
      FROM   xxcoi_tmp_lot_reserve_item
      WHERE  ROWNUM = 1
      ;
      IF ( it_kbn_1_rec.item_code IS NULL ) THEN
        lt_item_code         := it_kbn_1_rec.parent_item_code;
        lt_inventory_item_id := it_kbn_1_rec.parent_item_id;
        lt_item_name         := it_kbn_1_rec.parent_item_name;
      END IF;
      --
      -- 引当対象の保管場所にロット別手持数量が存在しない場合
      IF ( ( ln_priority_cnt = 0 ) AND ( ln_location_cnt = 0 ) ) THEN
        -- 引当情報格納配列：ロット別引当情報への登録内容
        gn_reserve_cnt                                         := gn_reserve_cnt + 1;
        gt_reserve_tab(gn_reserve_cnt).location_code           := NULL;
        gt_reserve_tab(gn_reserve_cnt).location_name           := NULL;
        gt_reserve_tab(gn_reserve_cnt).item_div                := lt_item_kbn;
        gt_reserve_tab(gn_reserve_cnt).item_div_name           := lt_item_kbn_name;
        gt_reserve_tab(gn_reserve_cnt).item_code               := lt_item_code;
        gt_reserve_tab(gn_reserve_cnt).item_name               := lt_item_name;
        gt_reserve_tab(gn_reserve_cnt).lot                     := NULL;
        gt_reserve_tab(gn_reserve_cnt).difference_summary_code := NULL;
        gt_reserve_tab(gn_reserve_cnt).case_in_qty             := NULL;
        gt_reserve_tab(gn_reserve_cnt).case_qty                := NULL;
        gt_reserve_tab(gn_reserve_cnt).singly_qty              := NULL;
        gt_reserve_tab(gn_reserve_cnt).summary_qty             := NULL;
        gt_reserve_tab(gn_reserve_cnt).mark                    := NULL;
        gt_reserve_tab(gn_reserve_cnt).item_id                 := lt_inventory_item_id;
        gt_reserve_tab(gn_reserve_cnt).short_case_in_qty       := gt_order_case_in_qty;
        gt_reserve_tab(gn_reserve_cnt).short_case_qty          := gt_order_case_qty;
        gt_reserve_tab(gn_reserve_cnt).short_singly_qty        := gt_order_singly_qty;
        gt_reserve_tab(gn_reserve_cnt).short_summary_qty       := gt_order_summary_qty;
        -- ロット別手持数量存在エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10600
                       , iv_token_name1  => cv_tkn_order_number
                       , iv_token_value1 => it_kbn_1_rec.order_number
                       , iv_token_name2  => cv_tkn_subinventory_code
                       , iv_token_value2 => it_kbn_1_rec.whse_code
                       , iv_token_name3  => cv_tkn_item_code
                       , iv_token_value3 => lt_item_code
                     );
      -- ロット別手持数量は存在するが、引当できていない数量が存在する場合
      ELSE
        -- 受注数と不足数が一致する（1件も引当できていない場合）場合
        IF ( gn_reserve_cnt = 0 ) THEN
          -- 引当情報格納配列：ロット別引当情報への登録内容
          gn_reserve_cnt                                         := gn_reserve_cnt + 1;
          gt_reserve_tab(gn_reserve_cnt).location_code           := NULL;
          gt_reserve_tab(gn_reserve_cnt).location_name           := NULL;
          gt_reserve_tab(gn_reserve_cnt).item_div                := lt_item_kbn;
          gt_reserve_tab(gn_reserve_cnt).item_div_name           := lt_item_kbn_name;
          gt_reserve_tab(gn_reserve_cnt).item_code               := lt_item_code;
          gt_reserve_tab(gn_reserve_cnt).item_name               := lt_item_name;
          gt_reserve_tab(gn_reserve_cnt).lot                     := NULL;
          gt_reserve_tab(gn_reserve_cnt).difference_summary_code := NULL;
          gt_reserve_tab(gn_reserve_cnt).case_in_qty             := NULL;
          gt_reserve_tab(gn_reserve_cnt).case_qty                := NULL;
          gt_reserve_tab(gn_reserve_cnt).singly_qty              := NULL;
          gt_reserve_tab(gn_reserve_cnt).summary_qty             := NULL;
          gt_reserve_tab(gn_reserve_cnt).mark                    := NULL;
          gt_reserve_tab(gn_reserve_cnt).item_id                 := lt_inventory_item_id;
          gt_reserve_tab(gn_reserve_cnt).short_case_in_qty       := gt_order_case_in_qty;
          gt_reserve_tab(gn_reserve_cnt).short_case_qty          := gt_order_case_qty;
          gt_reserve_tab(gn_reserve_cnt).short_singly_qty        := gt_order_singly_qty;
          gt_reserve_tab(gn_reserve_cnt).short_summary_qty       := gt_order_summary_qty;
        END IF;
        -- 引当処理にてチェックエラーはない場合
        IF ( gv_reserve_err_msg IS NULL ) THEN
          -- 在庫数量不足エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10547
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_item_code
                         , iv_token_value2 => lt_item_code
                         , iv_token_name3  => cv_tkn_order_quantity
                         , iv_token_value3 => gt_order_summary_qty
                         , iv_token_name4  => cv_tkn_quantity
                         , iv_token_value4 => lt_short_summary_qty
                       );
        ELSIF ( gv_reserve_err_msg = cv_msg_xxcoi_10548 ) THEN
          -- ロット逆転エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10548
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_customer_code
                         , iv_token_value2 => it_kbn_1_rec.customer_code
                         , iv_token_name3  => cv_tkn_item_code
                         , iv_token_value3 => it_kbn_1_rec.parent_item_code
                       );
        ELSIF ( gv_reserve_err_msg = cv_msg_xxcoi_10550 ) THEN
          -- 顧客鮮度条件エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10550
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_item_code
                         , iv_token_value2 => it_kbn_1_rec.parent_item_code
                         , iv_token_name3  => cv_tkn_fresh_condition
                         , iv_token_value3 => gt_cust_fresh_con_code
                       );
        END IF;
      END IF;
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
      -- 警告フラグ
      gb_warn_flag := TRUE;
      -- 警告で返す
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END inventory_reservation;
--
  /**********************************************************************************
   * Procedure Name   : chk_order
   * Description      : 受注訂正チェック処理(A-8)
   ***********************************************************************************/
  PROCEDURE chk_order(
      iv_order_number           IN  VARCHAR2 -- 受注番号
-- Add Ver1.3 Start
    , iv_parent_shipping_status IN VARCHAR2 -- 出荷情報ステータス（受注番号単位）
-- Add Ver1.3 End
    , ov_errbuf                 OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode                OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg                 OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_order'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_lot_tran_cnt            NUMBER                                    DEFAULT 0;     -- ロット別取引明細件数
    ln_subinv_cnt              NUMBER                                    DEFAULT 0;     -- 保管場所チェック件数
    ln_ins_cnt                 NUMBER                                    DEFAULT 0;     -- ロット別取引TEMP登録件数
    ln_dummy                   NUMBER                                    DEFAULT NULL;  -- ダミー値
    lb_chk_flag                BOOLEAN                                   DEFAULT FALSE; -- 修正ありフラグ
    lt_parent_item_id          oe_order_lines_all.inventory_item_id%TYPE DEFAULT NULL;  -- 品目コード
    lt_subinventory            oe_order_lines_all.subinventory%TYPE      DEFAULT NULL;  -- 保管場所コード
    lt_after_uom_code          mtl_units_of_measure_tl.uom_code%TYPE     DEFAULT NULL;  -- 換算後単位コード
    ln_after_quantity          NUMBER                                    DEFAULT 0;     -- 換算後数量
    ln_order_summary_qty       NUMBER                                    DEFAULT 0;     -- 換算後数量総数
-- Add Ver1.2 Start
    ln_order_summary_qty2      NUMBER                                    DEFAULT 0;     -- 換算後数量総数2
    ln_subinv_cnt2             NUMBER                                    DEFAULT 0;     -- 保管場所チェック件数
-- Add Ver1.2 End
    -- *** ローカルカーソル ***
    -- 受注カーソル
    CURSOR l_order_cur( in_order_number NUMBER )
    IS
      SELECT ooha.header_id                                AS header_id                 -- 受注ヘッダID
           , ooha.cust_po_number                           AS slip_num                  -- 伝票No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- 受注番号
           , ooha.order_source_id                          AS order_source_id           -- 受注ソースID
           , xca2.chain_store_code                         AS chain_code                -- チェーン店コード
           , hca1.cust_account_id                          AS cust_account_id           -- 顧客ID
           , hca1.account_number                           AS customer_code             -- 顧客コード
           , oola.line_id                                  AS line_id                   -- 受注明細ID
           , oola.line_number                              AS line_number               -- 受注明細番号
           , oola.inventory_item_id                        AS parent_item_id            -- 親品目ID
           , iimb.item_no                                  AS parent_item_code          -- 親品目コード
           , ximb.item_short_name                          AS parent_item_name          -- 親品目名
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- 売上区分
           , oola.attribute6                               AS item_code                 -- 子品目コード
           , oola.ordered_quantity                         AS ordered_quantity          -- 受注数量
           , oola.order_quantity_uom                       AS order_quantity_uom        -- 受注単位
           , oola.schedule_ship_date                       AS schedule_ship_date        -- 出荷日
           , TRUNC(oola.request_date)                      AS arrival_date              -- 着日
           , msi.attribute7                                AS base_code                 -- 拠点コード
           , oola.subinventory                             AS whse_code                 -- 保管場所コード
           , ottt2.name                                    AS line_name                 -- 明細タイプ
           , oola.flow_status_code                         AS flow_status_code          -- 明細ステータス
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND    ooha.order_number               = in_order_number
      ORDER BY oola.line_number
    ;
    -- 引当情報（ヘッダ）カーソル
    CURSOR l_reserve_cur( in_header_id      NUMBER
                        , in_parent_item_id NUMBER )
    IS
      SELECT DISTINCT
             xlri.slip_num          AS slip_num     -- 伝票No
           , xlri.customer_id       AS customer_id  -- 顧客ID
           , xlri.arrival_date      AS arrival_date -- 着日
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.header_id      = in_header_id
      AND    xlri.parent_item_id = in_parent_item_id
    ;
    -- 受注親品目総数取得カーソル
    CURSOR l_parent_item_cur( in_order_number      NUMBER
                            , in_inventory_item_id NUMBER
                            , iv_subinventory      VARCHAR2 )
    IS
      SELECT oola.ordered_quantity   AS ordered_quantity   -- 受注数量
           , oola.order_quantity_uom AS order_quantity_uom -- 受注単位
      FROM   oe_order_headers_all    ooha
           , oe_order_lines_all      oola
      WHERE  ooha.header_id         = oola.header_id
      AND    ooha.org_id            = gt_org_id
      AND    oola.flow_status_code <> cv_cancelled
      AND    ooha.order_number      = in_order_number
      AND    oola.inventory_item_id = in_inventory_item_id
      AND    oola.subinventory      = iv_subinventory
    ;
    -- 引当親品目総数取得カーソル
    CURSOR l_reserve_item_cur( in_header_id      NUMBER
                             , in_parent_item_id NUMBER
                             , iv_subinventory   VARCHAR2 )
    IS
      SELECT NVL(SUM(xlri.summary_qty), 0)  AS summary_qty  -- 引当総数
      FROM   xxcoi_lot_reserve_info         xlri
      WHERE  xlri.header_id      = in_header_id
      AND    xlri.parent_item_id = in_parent_item_id
      AND    xlri.whse_code      = iv_subinventory
    ;
-- Add Ver1.2 Start
    -- 引当親品目総数取得カーソル2
    CURSOR l_reserve_item2_cur( in_header_id     NUMBER
                             , in_parent_item_id NUMBER
                             , iv_subinventory   VARCHAR2 )
    IS
      SELECT NVL(SUM(xlri.summary_qty), 0)  AS summary_qty  -- 引当総数
      FROM   xxcoi_lot_reserve_info         xlri
      WHERE  xlri.header_id      = in_header_id
      AND    xlri.parent_item_id = in_parent_item_id
      AND    xlri.whse_code      = iv_subinventory
    ;
-- Add Ver1.2 End
    -- ロット別引当情報更新用カーソル
    CURSOR l_upd_reserve_cur( in_header_id NUMBER
                            , in_line_id   NUMBER )
    IS
      SELECT xlri.lot_reserve_info_id  AS lot_reserve_info_id
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.header_id = in_header_id
      AND    xlri.line_id   = in_line_id
    ;
    l_reserve_rec          l_reserve_cur%ROWTYPE;
    l_parent_item_rec      l_parent_item_cur%ROWTYPE;
    l_reserve_item_rec     l_reserve_item_cur%ROWTYPE;
-- Add Ver1.2 Start
    l_reserve_item2_rec    l_reserve_item2_cur%ROWTYPE;
-- Add Ver1.2 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    gt_lot_id_tab.DELETE;
    --
    --==============================================================
    -- 1．受注取得
    --==============================================================
    -- 受注取得ループ
    << order_loop >>
    FOR l_order_rec IN l_order_cur( in_order_number => TO_NUMBER(iv_order_number) ) LOOP
      -- 初期化
      ln_lot_tran_cnt := 0;
      lb_chk_flag     := FALSE;
      l_reserve_rec   := NULL;
      --
      -- 出荷仮確定の場合、チェックなし
      -- 仮確定後訂正の場合、ロット別取引明細の存在チェック
      IF ( gv_kbn = cv_kbn_6 ) THEN
        SELECT COUNT(1)
        INTO   ln_lot_tran_cnt
        FROM   xxcoi_lot_transactions xlt
        WHERE  xlt.source_code  = cv_pkg_name
        AND    xlt.relation_key = l_order_rec.header_id || cv_under || l_order_rec.line_id
        ;
      END IF;
      --
      -- ロット別取引明細が存在する場合
      IF ( ln_lot_tran_cnt > 0 ) THEN
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-8 ロット別取引明細存在' ||
                      ' 受注番号：'              || l_order_rec.order_number ||
                      ' 受注明細番号：'          || l_order_rec.line_number
        );
      -- ロット別取引明細が存在しない場合
      ELSE
        --
        --==============================================================
        -- 2．修正受注チェック
        --==============================================================
        -- 引当情報（ヘッダ）取得
        OPEN l_reserve_cur( in_header_id      => l_order_rec.header_id
                          , in_parent_item_id => l_order_rec.parent_item_id );
        FETCH l_reserve_cur INTO l_reserve_rec;
        CLOSE l_reserve_cur;
        -- 受注と引当が相違する場合（ヘッダ）
        IF ( ( l_order_rec.slip_num        <> l_reserve_rec.slip_num )
          OR ( l_order_rec.cust_account_id <> l_reserve_rec.customer_id )
          OR ( l_order_rec.arrival_date    <> l_reserve_rec.arrival_date ) ) THEN
          -- 修正あり
          lb_chk_flag := TRUE;
        END IF;
        --
        IF ( lb_chk_flag = FALSE ) THEN
          -- 初期化
          ln_order_summary_qty := 0;
          -- 設定
          lt_parent_item_id    := l_order_rec.parent_item_id;
          lt_subinventory      := l_order_rec.whse_code;
          --
          -- 受注親品目総数取得ループ
          << parent_item_loop >>
          FOR l_parent_item_rec IN l_parent_item_cur( in_order_number      => TO_NUMBER(l_order_rec.order_number)
                                                    , in_inventory_item_id => lt_parent_item_id
                                                    , iv_subinventory      => lt_subinventory ) LOOP
            -- 初期化
            ln_after_quantity    := 0;
            -- 単位換算取得
            xxcos_common_pkg.get_uom_cnv(
                iv_before_uom_code    => l_parent_item_rec.order_quantity_uom -- 換算前単位コード
              , in_before_quantity    => l_parent_item_rec.ordered_quantity   -- 換算前数量
              , iov_item_code         => l_order_rec.parent_item_code         -- 品目コード
              , iov_organization_code => gt_organization_code                 -- 在庫組織コード
              , ion_inventory_item_id => lt_parent_item_id                    -- 品目ＩＤ
              , ion_organization_id   => gt_organization_id                   -- 在庫組織ＩＤ
              , iov_after_uom_code    => lt_after_uom_code                    -- 換算後単位コード
              , on_after_quantity     => ln_after_quantity                    -- 換算後数量
              , on_content            => ln_dummy                             -- 入数
              , ov_errbuf             => lv_errbuf                            -- エラー・メッセージエラー       #固定#
              , ov_retcode            => lv_retcode                           -- リターン・コード               #固定#
              , ov_errmsg             => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
            );
            -- リターンコードが正常以外の場合、エラー
            IF ( lv_retcode <> cv_status_normal ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application
                             , iv_name         => cv_msg_xxcoi_10545
                             , iv_token_name1  => cv_tkn_common_pkg
                             , iv_token_value1 => cv_msg_xxcoi_10552
                             , iv_token_name2  => cv_tkn_errmsg
                             , iv_token_value2 => lv_errmsg
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
            --
            -- 親品目コードの総数合算
            ln_order_summary_qty := ln_order_summary_qty + ln_after_quantity;
            --
          END LOOP parent_item_loop;
          --
          -- 引当親品目総数取得
          OPEN l_reserve_item_cur( in_header_id      => l_order_rec.header_id
                                 , in_parent_item_id => lt_parent_item_id
                                 , iv_subinventory   => lt_subinventory );
          FETCH l_reserve_item_cur INTO l_reserve_item_rec;
          CLOSE l_reserve_item_cur;
          --
          --==============================================================
          -- 2．修正受注チェック
          --==============================================================
-- Add Ver1.3 Start
          -- 出荷仮確定かつ
          -- 出荷情報ステータス（受注番号単位）が引当未の場合
          IF (  ( gv_kbn = cv_kbn_3 )
            AND ( iv_parent_shipping_status = cv_shipping_status_10 ) ) THEN
            -- 受注の総数が0の場合（取消されている場合）
            IF ( ln_order_summary_qty = 0 ) THEN
              -- 指定された保管場所と一致する場合
              IF ( gv_subinventory_code = lt_subinventory ) THEN
                -- ロット別引当情報削除用ループ
                << del_reserve_loop >>
                FOR l_del_reserve_rec IN l_upd_reserve_cur( in_header_id => l_order_rec.header_id
                                                          , in_line_id   => l_order_rec.line_id ) LOOP
                  -- 同一IDを取得していない場合
                  IF ( g_del_id_tab.EXISTS( l_del_reserve_rec.lot_reserve_info_id ) = FALSE ) THEN
                    -- IDを保持
                    g_del_id_tab( l_del_reserve_rec.lot_reserve_info_id ) := 1;
                    --
                    FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                      , buff   => 'A-8 削除 ロット別引当情報ID ' || l_del_reserve_rec.lot_reserve_info_id
                    );
                  END IF;
                  --
                END LOOP del_reserve_loop;
              END IF;
            -- 受注の総数が0ではなく
            ELSE
              -- 受注と引当の総数が相違しない場合
              IF ( ln_order_summary_qty <> l_reserve_item_rec.summary_qty ) THEN
                -- 指定された保管場所と一致する場合、修正あり警告
                IF ( gv_subinventory_code = lt_subinventory ) THEN
                  -- 修正あり
                  lb_chk_flag := TRUE;
                -- 指定された保管場所と一致しない場合
                ELSE
                  -- ロット別引当情報削除用ループ
                  << del_reserve_loop >>
                  FOR l_del_reserve_rec IN l_upd_reserve_cur( in_header_id => l_order_rec.header_id
                                                            , in_line_id   => l_order_rec.line_id ) LOOP
                    -- 同一IDを取得していない場合
                    IF ( g_del_id_tab.EXISTS( l_del_reserve_rec.lot_reserve_info_id ) = FALSE ) THEN
                      -- IDを保持
                      g_del_id_tab( l_del_reserve_rec.lot_reserve_info_id ) := 1;
                      --
                      FND_FILE.PUT_LINE(
                          which  => FND_FILE.LOG
                        , buff   => 'A-8 削除 ロット別引当情報ID ' || l_del_reserve_rec.lot_reserve_info_id
                      );
                    END IF;
                    --
                  END LOOP del_reserve_loop;
                END IF;
              END IF;
            END IF;
          -- 出荷情報ステータス（受注番号単位）が引当済の場合
          -- または仮確定後訂正の場合
          ELSE
-- Add Ver1.3 End
            -- 受注と引当の総数が相違する場合
            IF ( ln_order_summary_qty <> l_reserve_item_rec.summary_qty ) THEN
-- Mod Ver1.2 Start
--              -- 修正あり
--              lb_chk_flag := TRUE;
--              --
--              -- 倉庫管理対象で無ければ削除のみ
--              SELECT COUNT(1)                     AS cnt
--              INTO   ln_subinv_cnt
--              FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
--              WHERE  xtlrs.subinventory_code = lt_subinventory
--              ;
--              IF ( ln_subinv_cnt = 0 ) THEN
--                l_order_rec.flow_status_code := cv_cancelled;
--              END IF;
              -- 保管場所指定の場合
              IF ( gv_subinventory_code IS NOT NULL ) THEN
                -- 指定された保管場所と一致する場合、修正あり警告
                IF ( gv_subinventory_code = lt_subinventory ) THEN
                  -- 修正あり
                  lb_chk_flag := TRUE;
                -- 指定された保管場所と一致しない場合
                ELSE
                  -- 初期化
                  ln_order_summary_qty2 := 0;
                  -- 受注親品目総数取得ループ
                  << parent_item_loop2 >>
                  FOR l_parent_item_rec IN l_parent_item_cur( in_order_number      => TO_NUMBER(l_order_rec.order_number)
                                                            , in_inventory_item_id => lt_parent_item_id
                                                            , iv_subinventory      => gv_subinventory_code ) LOOP
                    -- 初期化
                    ln_after_quantity    := 0;
                    -- 単位換算取得
                    xxcos_common_pkg.get_uom_cnv(
                        iv_before_uom_code    => l_parent_item_rec.order_quantity_uom -- 換算前単位コード
                      , in_before_quantity    => l_parent_item_rec.ordered_quantity   -- 換算前数量
                      , iov_item_code         => l_order_rec.parent_item_code         -- 品目コード
                      , iov_organization_code => gt_organization_code                 -- 在庫組織コード
                      , ion_inventory_item_id => lt_parent_item_id                    -- 品目ＩＤ
                      , ion_organization_id   => gt_organization_id                   -- 在庫組織ＩＤ
                      , iov_after_uom_code    => lt_after_uom_code                    -- 換算後単位コード
                      , on_after_quantity     => ln_after_quantity                    -- 換算後数量
                      , on_content            => ln_dummy                             -- 入数
                      , ov_errbuf             => lv_errbuf                            -- エラー・メッセージエラー       #固定#
                      , ov_retcode            => lv_retcode                           -- リターン・コード               #固定#
                      , ov_errmsg             => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
                    );
                    -- リターンコードが正常以外の場合、エラー
                    IF ( lv_retcode <> cv_status_normal ) THEN
                      lv_errmsg := xxccp_common_pkg.get_msg(
                                       iv_application  => cv_application
                                     , iv_name         => cv_msg_xxcoi_10545
                                     , iv_token_name1  => cv_tkn_common_pkg
                                     , iv_token_value1 => cv_msg_xxcoi_10552
                                     , iv_token_name2  => cv_tkn_errmsg
                                     , iv_token_value2 => lv_errmsg
                                   );
                      lv_errbuf := lv_errmsg;
                      RAISE global_api_expt;
                    END IF;
                    --
                    -- 親品目コードの総数合算
                    ln_order_summary_qty2 := ln_order_summary_qty2 + ln_after_quantity;
                    --
                  END LOOP parent_item_loop2;
                  --
                  -- 引当親品目総数取得2
                  OPEN l_reserve_item2_cur( in_header_id      => l_order_rec.header_id
                                          , in_parent_item_id => lt_parent_item_id
                                          , iv_subinventory   => gv_subinventory_code );
                  FETCH l_reserve_item2_cur INTO l_reserve_item2_rec;
                  CLOSE l_reserve_item2_cur;
                  --
                  -- 受注数量があり、指定された保管場所で受注と引当が違う
                  IF ( ( ( l_reserve_item_rec.summary_qty > 0 ) OR ( l_reserve_item2_rec.summary_qty > 0 ) )
                    AND  ( ln_order_summary_qty2 <> l_reserve_item2_rec.summary_qty ) ) THEN
                    -- 修正あり
                    lb_chk_flag := TRUE;
                  END IF;
                END IF;
              -- 保管場所指定なしの場合
              ELSE
                ln_subinv_cnt := 0;
                -- 倉庫管理対象のチェック
                SELECT COUNT(1)                     AS cnt
                INTO   ln_subinv_cnt
                FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                WHERE  xtlrs.subinventory_code = lt_subinventory
                ;
                -- 倉庫管理対象で無ければ削除のみ（倉庫管理対象を変更された場合を考慮）
                IF ( ln_subinv_cnt = 0 ) THEN
                  l_order_rec.flow_status_code := cv_cancelled;
                -- 倉庫管理対象の場合、修正あり警告
                ELSE
                  -- 修正あり
                  lb_chk_flag := TRUE;
                END IF;
              END IF;
-- Mod Ver1.2 End
            END IF;
-- Add Ver1.3 Start
          END IF;
-- Add Ver1.3 End
        END IF;
        --
        -- 修正がある場合
        IF ( lb_chk_flag = TRUE ) THEN
          -- 出荷仮確定の場合
          IF ( gv_kbn = cv_kbn_3 ) THEN
            -- 引当情報差異エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10553
                           , iv_token_name1  => cv_tkn_order_number
                           , iv_token_value1 => l_order_rec.order_number
                           , iv_token_name2  => cv_tkn_line_number
                           , iv_token_value2 => l_order_rec.line_number
                         );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg
            );
            -- 警告で返す
            ov_retcode   := cv_status_warn;
            gb_warn_flag := TRUE;
          -- 仮確定後訂正の場合
          ELSIF ( gv_kbn = cv_kbn_6 ) THEN
-- Mod Ver1.2 Start
            -- 保管場所指定の場合
            IF ( gv_subinventory_code IS NOT NULL ) THEN
              -- 倉庫管理対象のチェック
              SELECT COUNT(1)                     AS cnt
              INTO   ln_subinv_cnt2
              FROM   mtl_secondary_inventories    msi
              WHERE  msi.attribute14     = cv_flag_y
              AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
              AND    msi.organization_id = gt_organization_id
              AND    msi.secondary_inventory_name = lt_subinventory
              ;
              -- 倉庫管理対象で無ければ削除のみ（倉庫管理対象を変更された場合を考慮）
              IF ( ln_subinv_cnt2 = 0 ) THEN
                l_order_rec.flow_status_code := cv_cancelled;
              END IF;
            END IF;
-- Mod Ver1.2 End
            -- ロット別取引TEMP登録処理
            ins_lot_tran_temp(
                iv_tran_kbn           => cv_tran_kbn_1                  -- 取引区分
              , in_header_id          => l_order_rec.header_id          -- 受注ヘッダID
              , in_line_id            => l_order_rec.line_id            -- 受注明細ID
              , iv_slip_num           => l_order_rec.slip_num           -- 伝票No
              , iv_order_number       => l_order_rec.order_number       -- 受注番号
              , iv_line_number        => l_order_rec.line_number        -- 受注明細番号
              , id_arrival_date       => l_order_rec.arrival_date       -- 着日
              , iv_parent_item_code   => l_order_rec.parent_item_code   -- 親品目コード
              , iv_item_code          => l_order_rec.item_code          -- 子品目コード
              , in_parent_item_id     => l_order_rec.parent_item_id     -- 品目ID
              , iv_order_quantity_uom => l_order_rec.order_quantity_uom -- 受注単位
              , in_ordered_quantity   => l_order_rec.ordered_quantity   -- 受注数量
              , iv_base_code          => l_order_rec.base_code          -- 拠点コード
              , iv_subinventory_code  => l_order_rec.whse_code          -- 保管場所コード
              , iv_line_name          => l_order_rec.line_name          -- 明細摘要
              , iv_sale_class         => l_order_rec.sale_class         -- 定番特売区分(明細)
              , iv_flow_status_code   => l_order_rec.flow_status_code   -- 明細ステータス
              , ov_errbuf             => lv_errbuf                      -- エラー・メッセージ
              , ov_retcode            => lv_retcode                     -- リターン・コード
              , ov_errmsg             => lv_errmsg                      -- ユーザー・エラー・メッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            --
            -- ロット別引当情報更新用ループ
            << upd_reserve_loop >>
            FOR l_upd_reserve_rec IN l_upd_reserve_cur( in_header_id => l_order_rec.header_id
                                                      , in_line_id   => l_order_rec.line_id ) LOOP
              ln_ins_cnt := ln_ins_cnt + 1;
              gt_lot_id_tab(ln_ins_cnt) := l_upd_reserve_rec.lot_reserve_info_id;
            END LOOP upd_reserve_loop;
          END IF;
          --
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => 'A-8 差異あり'    ||
                        ' 受注番号：'     || l_order_rec.order_number ||
                        ' 受注明細番号：' || l_order_rec.line_number
          );
          IF  ( l_order_rec.slip_num <> l_reserve_rec.slip_num ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '伝票No：' || l_order_rec.slip_num  || ' ' || l_reserve_rec.slip_num
            );
          ELSIF ( l_order_rec.cust_account_id <> l_reserve_rec.customer_id ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '顧客ID：' || l_order_rec.cust_account_id  || ' ' || l_reserve_rec.customer_id
            );
          ELSIF  ( l_order_rec.arrival_date <> l_reserve_rec.arrival_date ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '着日：' || TO_CHAR(l_order_rec.arrival_date, cv_yyyymmdd)  || ' ' || TO_CHAR(l_reserve_rec.arrival_date, cv_yyyymmdd)
            );
          ELSIF  ( NVL(ln_order_summary_qty, 0) <> NVL(l_reserve_item_rec.summary_qty, 0) ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
-- Mod Ver1.2 Start
--              , buff   => '受注数量：' || ln_order_summary_qty  || ' ' || l_reserve_item_rec.summary_qty
              , buff   => '受注数量：' || ln_order_summary_qty  || ' ' || l_reserve_item_rec.summary_qty || ' ' || ln_order_summary_qty2 || ' ' || NVL(l_reserve_item2_rec.summary_qty, 0)
-- Mod Ver1.2 End
            );
          END IF;
        ELSE
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => 'A-8 差異なし'    ||
                        ' 受注番号：'     || l_order_rec.order_number ||
                        ' 受注明細番号：' || l_order_rec.line_number
          );
        END IF;
      END IF;
    END LOOP xtlri_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( l_order_cur%ISOPEN ) THEN
        CLOSE l_order_cur;
      END IF;
      IF ( l_reserve_cur%ISOPEN ) THEN
        CLOSE l_reserve_cur;
      END IF;
      IF ( l_parent_item_cur%ISOPEN ) THEN
        CLOSE l_parent_item_cur;
      END IF;
      IF ( l_reserve_item_cur%ISOPEN ) THEN
        CLOSE l_reserve_item_cur;
      END IF;
-- Add Ver1.2 Start
      IF ( l_reserve_item2_cur%ISOPEN ) THEN
        CLOSE l_reserve_item2_cur;
      END IF;
-- Add Ver1.2 End
      IF ( l_upd_reserve_cur%ISOPEN ) THEN
        CLOSE l_upd_reserve_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END chk_order;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_transactions
   * Description      : ロット別取引明細登録処理(A-9)
   ***********************************************************************************/
  PROCEDURE ins_lot_transactions(
      it_kbn_4_rec IN  g_kbn_4_cur%ROWTYPE -- 出荷確定レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_transactions'; -- プログラム名
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
    lt_trx_id               xxcoi_lot_transactions.transaction_id%TYPE DEFAULT NULL; -- 取引ID
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
    -- 1．ロット別取引明細作成
    --==============================================================
    xxcoi_common_pkg.cre_lot_trx(
        in_trx_set_id            => NULL                                                       -- 取引セットID
      , iv_parent_item_code      => it_kbn_4_rec.parent_item_code                              -- 親品目コード
      , iv_child_item_code       => it_kbn_4_rec.item_code                                     -- 子品目コード
      , iv_lot                   => it_kbn_4_rec.lot                                           -- ロット(賞味期限)
      , iv_diff_sum_code         => it_kbn_4_rec.difference_summary_code                       -- 固有記号
      , iv_trx_type_code         => it_kbn_4_rec.reserve_transaction_type_code                 -- 取引タイプコード
      , id_trx_date              => it_kbn_4_rec.arrival_date                                  -- 取引日
      , iv_slip_num              => it_kbn_4_rec.slip_num                                      -- 伝票No
      , in_case_in_qty           => it_kbn_4_rec.case_in_qty                                   -- 入数
      , in_case_qty              => it_kbn_4_rec.case_qty * (-1)                               -- ケース数
      , in_singly_qty            => it_kbn_4_rec.singly_qty * (-1)                             -- バラ数
      , in_summary_qty           => it_kbn_4_rec.summary_qty * (-1)                            -- 取引数量
      , iv_base_code             => it_kbn_4_rec.base_code                                     -- 拠点コード
      , iv_subinv_code           => it_kbn_4_rec.whse_code                                     -- 保管場所コード
      , iv_loc_code              => it_kbn_4_rec.location_code                                 -- ロケーションコード
      , iv_tran_subinv_code      => NULL                                                       -- 転送先保管場所コード
      , iv_tran_loc_code         => NULL                                                       -- 転送先ロケーションコード
      , iv_sign_div              => cv_sign_div_0                                              -- 符号区分
      , iv_source_code           => cv_pkg_name                                                -- ソースコード
      , iv_relation_key          => it_kbn_4_rec.header_id || cv_under || it_kbn_4_rec.line_id -- 紐付けキー
      , iv_reason                => NULL                                                       -- 事由
      , iv_reserve_trx_type_code => NULL                                                       -- 引当時取引タイプコード
      , on_trx_id                => lt_trx_id                                                  -- ロット別取引明細
      , ov_errbuf                => lv_errbuf                                                  -- エラーメッセージ
      , ov_retcode               => lv_retcode                                                 -- リターンコード
      , ov_errmsg                => lv_errmsg                                                  -- ユーザー・エラー・メッセージ
    );
    -- リターンコードが正常以外の場合、エラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10495
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_lot_transactions;
--
  /**********************************************************************************
   * Procedure Name   : ref_lot_onhand
   * Description      : ロット別手持数量反映処理(A-10)
   ***********************************************************************************/
  PROCEDURE ref_lot_onhand(
      it_kbn_4_rec IN  g_kbn_4_cur%ROWTYPE -- 出荷確定レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ref_lot_onhand'; -- プログラム名
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
    -- 1．ロット別手持数量反映
    --==============================================================
    xxcoi_common_pkg.ins_upd_del_lot_onhand(
        in_inv_org_id    => gt_organization_id                   -- 在庫組織ID
      , iv_base_code     => it_kbn_4_rec.base_code               -- 拠点コード
      , iv_subinv_code   => it_kbn_4_rec.whse_code               -- 保管場所コード
      , iv_loc_code      => it_kbn_4_rec.location_code           -- ロケーションコード
      , in_child_item_id => it_kbn_4_rec.item_id                 -- 子品目ID
      , iv_lot           => it_kbn_4_rec.lot                     -- ロット(賞味期限)
      , iv_diff_sum_code => it_kbn_4_rec.difference_summary_code -- 固有記号
      , in_case_in_qty   => it_kbn_4_rec.case_in_qty             -- 入数
      , in_case_qty      => it_kbn_4_rec.case_qty * (-1)         -- ケース数
      , in_singly_qty    => it_kbn_4_rec.singly_qty * (-1)       -- バラ数
      , in_summary_qty   => it_kbn_4_rec.summary_qty * (-1)      -- 取引数量
      , ov_errbuf        => lv_errbuf                            -- エラーメッセージ
      , ov_retcode       => lv_retcode                           -- リターンコード
      , ov_errmsg        => lv_errmsg                            -- ユーザー・エラー・メッセージ
    );
    -- リターンコードが正常以外の場合、エラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10559
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ref_lot_onhand;
--
  /**********************************************************************************
   * Procedure Name   : ref_mst_lot_hold_info
   * Description      : ロット情報保持マスタ反映処理(A-11)
   ***********************************************************************************/
  PROCEDURE ref_mst_lot_hold_info(
      it_kbn_3_rec IN  g_kbn_3_cur%ROWTYPE -- 出荷確定レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ref_mst_lot_hold_info'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 1．ロット情報保持マスタ反映
    --==============================================================
    xxcoi_common_pkg.ins_upd_lot_hold_info(
        in_customer_id    => it_kbn_3_rec.customer_id    -- 顧客ID
      , in_deliver_to_id  => NULL                        -- 出荷先ID
      , in_parent_item_id => it_kbn_3_rec.parent_item_id -- 親品目ID
      , iv_deliver_lot    => it_kbn_3_rec.lot            -- 納品ロット
      , id_delivery_date  => it_kbn_3_rec.arrival_date   -- 納品日
      , iv_e_s_kbn        => cv_eigyo                    -- 営業生産区分
      , iv_cancel_kbn     => cv_cancel_kbn_0             -- 取消区分
      , ov_errbuf         => lv_errbuf                   -- エラーメッセージ
      , ov_retcode        => lv_retcode                  -- リターンコード
      , ov_errmsg         => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    -- リターンコードが正常以外の場合、エラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10563
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ref_mst_lot_hold_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_reserve_info
   * Description      : ロット別引当情報登録処理(A-12)
   ***********************************************************************************/
  PROCEDURE ins_lot_reserve_info(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- 引当レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_reserve_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_dummy                VARCHAR(3)                                                DEFAULT NULL; -- ダミー値
    ln_dummy                NUMBER                                                    DEFAULT NULL; -- ダミー値
    lt_red_black_flag       fnd_lookup_values.attribute1%TYPE                         DEFAULT NULL; -- 赤黒フラグ
    lt_shipping_status      xxcoi_lot_reserve_info.shipping_status%TYPE               DEFAULT NULL; -- 出荷情報ステータス
    lt_shipping_status_name xxcoi_lot_reserve_info.shipping_status_name%TYPE          DEFAULT NULL; -- 出荷情報ステータス名
    lt_tran_type_code       xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE DEFAULT NULL; -- 引当時取引タイプコード
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
    -- 1．ロット別引当情報登録
    --==============================================================
    IF ( gv_retcode = cv_status_normal ) THEN
      -- 取引タイプ取得
      get_tran_type(
          iv_tran_kbn            => cv_tran_kbn_1                        -- 取引区分
        , iv_line_name           => it_kbn_1_rec.line_type               -- 明細摘要
        , iv_sale_class          => it_kbn_1_rec.regular_sale_class_line -- 売上区分
        , ion_order_case_qty     => ln_dummy                             -- ケース数
        , ion_order_singly_qty   => ln_dummy                             -- バラ数
        , ion_after_quantity     => ln_dummy                             -- 総数
        , ov_tran_type_code_temp => lv_dummy                             -- 取引タイプコード
        , ov_tran_type_code      => lt_tran_type_code                    -- 引当時取引タイプコード
        , ov_errbuf              => lv_errbuf                            -- エラー・メッセージ
        , ov_retcode             => lv_retcode                           -- リターン・コード
        , ov_errmsg              => lv_errmsg                            -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 出荷情報ステータス設定
    -- 引当正常時
    IF ( gv_retcode = cv_status_normal ) THEN
      lt_shipping_status      := cv_shipping_status_20;
      lt_shipping_status_name := gt_shipping_status_20;
    -- 引当失敗時
    ELSE
      lt_shipping_status      := cv_shipping_status_10;
      lt_shipping_status_name := gt_shipping_status_10;
    END IF;
--
    -- ロット別引当情報登録ループ
    << ins_lot_reserve_loop >>
    FOR i IN 1 .. gt_reserve_tab.COUNT LOOP
      INSERT INTO xxcoi_lot_reserve_info(
          lot_reserve_info_id                       -- ロット別引当情報ID
        , slip_num                                  -- 伝票No
        , order_number                              -- 受注番号
        , org_id                                    -- 営業単位
        , parent_shipping_status                    -- 出荷情報ステータス(受注番号単位)
        , parent_shipping_status_name               -- 出荷情報ステータス名称(受注番号単位)
        , base_code                                 -- 拠点コード
        , base_name                                 -- 拠点名
        , whse_code                                 -- 保管場所コード
        , whse_name                                 -- 保管場所名
        , location_code                             -- ロケーションコード
        , location_name                             -- ロケーション名称
        , shipping_status                           -- 出荷情報ステータス
        , shipping_status_name                      -- 出荷情報ステータス名称
        , chain_code                                -- チェーン店コード
        , chain_name                                -- チェーン店名
        , shop_code                                 -- 店舗コード
        , shop_name                                 -- 店舗名
        , customer_code                             -- 顧客コード
        , customer_name                             -- 顧客名
        , center_code                               -- センターコード
        , center_name                               -- センター名
        , area_code                                 -- 地区コード
        , area_name                                 -- 地区名称
        , shipped_date                              -- 出荷日
        , arrival_date                              -- 着日
        , item_div                                  -- 商品区分
        , item_div_name                             -- 商品区分名
        , parent_item_code                          -- 親品目コード
        , parent_item_name                          -- 親品目名称
        , item_code                                 -- 子品目コード
        , item_name                                 -- 子品目名称
        , lot                                       -- ロット
        , difference_summary_code                   -- 固有記号
        , case_in_qty                               -- 入数
        , case_qty                                  -- ケース数
        , singly_qty                                -- バラ数
        , summary_qty                               -- 数量
        , regular_sale_class_line                   -- 定番特売区分(明細)
        , regular_sale_class_name_line              -- 定番特売区分名(明細)
        , edi_received_date                         -- EDI受信日
        , delivery_order_edi                        -- 配送順(EDI)
        , before_ordered_quantity                   -- 訂正前受注数量
        , reserve_performer_code                    -- 引当実行者コード
        , reserve_performer_name                    -- 引当実行者名
        , mark                                      -- 記号
        , lot_tran_kbn                              -- ロット別取引明細作成区分
        , header_id                                 -- 受注ヘッダID
        , line_id                                   -- 受注明細ID
        , customer_id                               -- 顧客ID
        , parent_item_id                            -- 親品目ID
        , item_id                                   -- 子品目ID
        , reserve_transaction_type_code             -- 引当時取引タイプコード
        , order_quantity_uom                        -- 受注単位
        , ordered_quantity                          -- 受注数量
        , short_case_in_qty                         -- 入数（不足数）
        , short_case_qty                            -- ケース数（不足数）
        , short_singly_qty                          -- バラ数（不足数）
        , short_summary_qty                         -- 数量（不足数）
        , created_by                                -- 作成者
        , creation_date                             -- 作成日
        , last_updated_by                           -- 最終更新者
        , last_update_date                          -- 最終更新日
        , last_update_login                         -- 最終更新ログイン
        , request_id                                -- 要求ID
        , program_application_id                    -- プログラムアプリケーションID
        , program_id                                -- プログラムID
        , program_update_date                       -- プログラム更新日
      ) VALUES (
          xxcoi_lot_reserve_info_s01.NEXTVAL        -- ロット別引当情報ID
        , it_kbn_1_rec.slip_num                     -- 伝票No
        , it_kbn_1_rec.order_number                 -- 受注番号
        , gt_org_id                                 -- 営業単位
        , NULL                                      -- 出荷情報ステータス(受注番号単位)
        , NULL                                      -- 出荷情報ステータス名称(受注番号単位)
        , gv_login_base_code                        -- 拠点コード
        , gt_base_name                              -- 拠点名
        , it_kbn_1_rec.whse_code                    -- 保管場所コード
        , it_kbn_1_rec.whse_name                    -- 保管場所名
        , gt_reserve_tab(i).location_code           -- ロケーションコード
        , gt_reserve_tab(i).location_name           -- ロケーション名称
        , lt_shipping_status                        -- 出荷情報ステータス
        , lt_shipping_status_name                   -- 出荷情報ステータス名称
        , it_kbn_1_rec.chain_code                   -- チェーン店コード
        , it_kbn_1_rec.chain_name                   -- チェーン店名
        , it_kbn_1_rec.shop_code                    -- 店舗コード
        , it_kbn_1_rec.shop_name                    -- 店舗名
        , it_kbn_1_rec.customer_code                -- 顧客コード
        , it_kbn_1_rec.customer_name                -- 顧客名
        , it_kbn_1_rec.center_code                  -- センターコード
        , it_kbn_1_rec.center_name                  -- センター名
        , it_kbn_1_rec.area_code                    -- 地区コード
        , it_kbn_1_rec.area_name                    -- 地区名称
        , it_kbn_1_rec.shipped_date                 -- 出荷日
        , it_kbn_1_rec.arrival_date                 -- 着日
        , gt_reserve_tab(i).item_div                -- 商品区分
        , gt_reserve_tab(i).item_div_name           -- 商品区分名
        , it_kbn_1_rec.parent_item_code             -- 親品目コード
        , it_kbn_1_rec.parent_item_name             -- 親品目名称
        , gt_reserve_tab(i).item_code               -- 子品目コード
        , gt_reserve_tab(i).item_name               -- 子品目名称
        , gt_reserve_tab(i).lot                     -- ロット
        , gt_reserve_tab(i).difference_summary_code -- 固有記号
        , gt_reserve_tab(i).case_in_qty             -- 入数
        , gt_reserve_tab(i).case_qty                -- ケース数
        , gt_reserve_tab(i).singly_qty              -- バラ数
        , gt_reserve_tab(i).summary_qty             -- 数量
        , it_kbn_1_rec.regular_sale_class_line      -- 定番特売区分(明細)
        , it_kbn_1_rec.regular_sale_class_name_line -- 定番特売区分名(明細)
        , it_kbn_1_rec.edi_received_date            -- EDI受信日
        , it_kbn_1_rec.delivery_order_edi           -- 配送順(EDI)
        , gt_order_summary_qty                      -- 訂正前受注数量：出荷調整を行えるよう、引当時点の受注数量を設定する
        , gt_employee_number                        -- 引当実行者コード
        , gv_employee_name                          -- 引当実行者名
        , gt_reserve_tab(i).mark                    -- 記号
        , cv_lot_tran_kbn_0                         -- ロット別取引明細作成区分
        , it_kbn_1_rec.header_id                    -- 受注ヘッダID
        , it_kbn_1_rec.line_id                      -- 受注明細ID
        , it_kbn_1_rec.customer_id                  -- 顧客ID
        , it_kbn_1_rec.parent_item_id               -- 親品目ID
        , gt_reserve_tab(i).item_id                 -- 子品目ID
        , lt_tran_type_code                         -- 引当時取引タイプコード
        , it_kbn_1_rec.order_quantity_uom           -- 受注単位
        , it_kbn_1_rec.ordered_quantity             -- 受注数量
        , gt_reserve_tab(i).short_case_in_qty       -- 入数（不足数）
        , gt_reserve_tab(i).short_case_qty          -- ケース数（不足数）
        , gt_reserve_tab(i).short_singly_qty        -- バラ数（不足数）
        , gt_reserve_tab(i).short_summary_qty       -- 数量（不足数）
        , cn_created_by                             -- 作成者
        , cd_creation_date                          -- 作成日
        , cn_last_updated_by                        -- 最終更新者
        , cd_last_update_date                       -- 最終更新日
        , cn_last_update_login                      -- 最終更新ログイン
        , cn_request_id                             -- 要求ID
        , cn_program_application_id                 -- プログラムアプリケーションID
        , cn_program_id                             -- プログラムID
        , cd_program_update_date                    -- プログラム更新日
      );
      -- デバッグ用
      IF ( gv_retcode = cv_status_normal ) THEN
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-12.3 ロット別引当情報登録→引当済' ||
                      ' 受注番号：'                         || it_kbn_1_rec.order_number     ||
                      ' 親品目コード：'                     || it_kbn_1_rec.parent_item_code ||
                      ' 子品目コード：'                     || gt_reserve_tab(i).item_code
        );
      ELSE
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-12.3 ロット別引当情報登録→引当未' ||
                      ' 受注番号：'                         || it_kbn_1_rec.order_number     ||
                      ' 親品目コード：'                     || it_kbn_1_rec.parent_item_code ||
                      ' 子品目コード：'                     || gt_reserve_tab(i).item_code
        );
      END IF;
    END LOOP ins_lot_reserve_loop;
    --
    -- 成功件数設定
    IF ( gv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_normal_cnt + 1;
    -- 失敗件数設定
    ELSE
      gn_warn_cnt   := gn_warn_cnt + 1;
    END IF;
    --
    -- 配列削除・添え字初期化
    gn_reserve_cnt := 0;
    gt_reserve_tab.DELETE;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : del_lot_reserve_info
   * Description      : ロット別引当情報削除処理(A-13)
   ***********************************************************************************/
  PROCEDURE del_lot_reserve_info(
      it_kbn_2_rec IN  g_kbn_2_cur%ROWTYPE -- 引当解除レコード
    , ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lot_reserve_info'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 対象件数設定
    -- 引当未
    IF ( it_kbn_2_rec.shipping_status = cv_shipping_status_10 ) THEN
      gn_target_10_cnt := gn_target_10_cnt + 1;
    -- 引当済
    ELSIF ( it_kbn_2_rec.shipping_status = cv_shipping_status_20 ) THEN
      gn_target_20_cnt := gn_target_20_cnt + 1;
    END IF;
    --
    --==============================================================
    -- 1．ロット別引当情報削除
    --==============================================================
    DELETE FROM xxcoi_lot_reserve_info xlri
    WHERE       xlri.rowid = it_kbn_2_rec.xlri_rowid
    ;
    -- 成功件数設定
    -- 引当未
    IF ( it_kbn_2_rec.shipping_status = cv_shipping_status_10 ) THEN
      gn_normal_10_cnt := gn_normal_10_cnt + 1;
    -- 引当済
    ELSIF ( it_kbn_2_rec.shipping_status = cv_shipping_status_20 ) THEN
      gn_normal_20_cnt := gn_normal_20_cnt + 1;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_reserve_info
   * Description      : ロット別引当情報更新処理(A-14)
   ***********************************************************************************/
  PROCEDURE upd_lot_reserve_info(
      iv_lot_tran_kbn        IN  VARCHAR2 -- ロット別取引明細作成区分
    , in_lot_reserve_info_id IN  NUMBER   -- ロット別引当情報ID
    , ov_errbuf              OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode             OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg              OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_reserve_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    lt_parent_shipping_status       xxcoi_lot_reserve_info.parent_shipping_status%TYPE      DEFAULT NULL; -- 出荷情報ステータス
    lt_parent_shipping_status_name  xxcoi_lot_reserve_info.parent_shipping_status_name%TYPE DEFAULT NULL; -- 出荷情報ステータス名
    lt_lot_tran_kbn                 xxcoi_lot_reserve_info.lot_tran_kbn%TYPE                DEFAULT NULL; -- ロット別取引明細作成区分
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 出荷仮確定、出荷確定の場合
    IF ( ( gv_kbn = cv_kbn_3 ) OR ( gv_kbn = cv_kbn_4 ) ) THEN
      -- 出荷仮確定の場合
      IF ( gv_kbn = cv_kbn_3 ) THEN
        lt_parent_shipping_status      := cv_shipping_status_25;
        lt_parent_shipping_status_name := gt_shipping_status_25;
      -- 出荷確定の場合
      ELSIF ( gv_kbn = cv_kbn_4 ) THEN
        lt_parent_shipping_status      := cv_shipping_status_30;
        lt_parent_shipping_status_name := gt_shipping_status_30;
        -- 未作成の場合
        IF ( iv_lot_tran_kbn = cv_lot_tran_kbn_0 ) THEN
          lt_lot_tran_kbn              := cv_lot_tran_kbn_1;
        END IF;
      END IF;
      --==============================================================
      -- 1．ロット別引当情報更新（出荷仮確定、出荷確定）
      --==============================================================
      UPDATE xxcoi_lot_reserve_info xlri
      SET    xlri.parent_shipping_status      = lt_parent_shipping_status             -- 出荷情報ステータス（受注番号単位）
           , xlri.parent_shipping_status_name = lt_parent_shipping_status_name        -- 出荷情報ステータス名（受注番号単位）
           , xlri.shipping_status             = lt_parent_shipping_status             -- 出荷情報ステータス
           , xlri.shipping_status_name        = lt_parent_shipping_status_name        -- 出荷情報ステータス名
           , xlri.lot_tran_kbn                = CASE WHEN lt_lot_tran_kbn IS NOT NULL
                                                     THEN lt_lot_tran_kbn
                                                     ELSE xlri.lot_tran_kbn
                                                END                                   -- ロット別取引明細作成区分
           , xlri.last_updated_by             = cn_last_updated_by                   -- 最終更新者
           , xlri.last_update_date            = cd_last_update_date                  -- 最終更新日
           , xlri.last_update_login           = cn_last_update_login                 -- 最終更新ログイン
           , xlri.request_id                  = cn_request_id                        -- 要求ID
           , xlri.program_application_id      = cn_program_application_id            -- プログラムアプリケーションID
           , xlri.program_id                  = cn_program_id                        -- プログラムID
           , xlri.program_update_date         = cd_program_update_date               -- プログラム更新日
      WHERE  xlri.lot_reserve_info_id         = in_lot_reserve_info_id               -- ロット別引当情報ID
      ;
    -- 仮確定後訂正の場合
    ELSIF ( gv_kbn = cv_kbn_6 ) THEN
      --==============================================================
      -- 2．ロット別引当情報更新（仮確定後訂正）
      --==============================================================
      << upd_id_loop >>
      FOR i IN 1 .. gt_lot_id_tab.COUNT LOOP
        UPDATE xxcoi_lot_reserve_info xlri
        SET    xlri.lot_tran_kbn                = cv_lot_tran_kbn_9         -- ロット別取引明細作成区分
             , xlri.last_updated_by             = cn_last_updated_by        -- 最終更新者
             , xlri.last_update_date            = cd_last_update_date       -- 最終更新日
             , xlri.last_update_login           = cn_last_update_login      -- 最終更新ログイン
             , xlri.request_id                  = cn_request_id             -- 要求ID
             , xlri.program_application_id      = cn_program_application_id -- プログラムアプリケーションID
             , xlri.program_id                  = cn_program_id             -- プログラムID
             , xlri.program_update_date         = cd_program_update_date    -- プログラム更新日
        WHERE  xlri.lot_reserve_info_id         = gt_lot_id_tab(i)          -- ロット別引当情報ID
        ;
      END LOOP upd_id_loop;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_reserve_info2
   * Description      : ロット別引当情報更新処理（出荷情報ステータス（受注番号単位））(A-15)
   ***********************************************************************************/
  PROCEDURE upd_lot_reserve_info2(
      ov_errbuf    OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_reserve_info2'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- 出荷情報ステータス特定型
    TYPE l_shipping_status_rec IS RECORD(
        order_number        xxcoi_lot_reserve_info.order_number%TYPE     -- 受注番号
      , shipping_status     xxcoi_lot_reserve_info.shipping_status%TYPE  -- 出荷情報ステータス
    );
    TYPE l_shipping_status_type IS TABLE OF l_shipping_status_rec INDEX BY BINARY_INTEGER;
    l_shipping_status_tab   l_shipping_status_type;
    -- *** ローカルカーソル ***
    -- 受注番号カーソル
    CURSOR l_order_number_cur( in_request_id NUMBER )
    IS
      SELECT DISTINCT
             xlri.order_number      AS order_number
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.request_id = in_request_id
      ORDER BY xlri.order_number
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
    -- 1．出荷情報ステータス特定
    --==============================================================
    << order_number_loop >>
    FOR l_order_number_rec IN l_order_number_cur( in_request_id => cn_request_id ) LOOP
      -- 受注番号と出荷情報ステータス単位：引当済→引当未の順でソート
      SELECT xlri.order_number      AS order_number
           , xlri.shipping_status   AS shipping_status
      BULK COLLECT INTO l_shipping_status_tab
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status IN ( cv_shipping_status_10, cv_shipping_status_20 )
      AND    xlri.order_number = l_order_number_rec.order_number
      GROUP BY xlri.order_number
             , xlri.shipping_status
      ORDER BY xlri.order_number
             , xlri.shipping_status DESC
      ;
      --==============================================================
      -- 2．ロット別引当情報更新（引当未、引当済）
      --==============================================================
      -- 更新ループ
      << upd_loop >>
      FOR i IN 1 .. l_shipping_status_tab.COUNT LOOP
        -- 次レコードが無い場合（受注番号が切り替わった場合）
        IF ( l_shipping_status_tab.NEXT(i) IS NULL ) THEN
          -- 現行レコードの値で更新
          UPDATE xxcoi_lot_reserve_info xlri
          SET    xlri.parent_shipping_status      = l_shipping_status_tab(i).shipping_status               -- 出荷情報ステータス（受注番号単位）
               , xlri.parent_shipping_status_name = DECODE( l_shipping_status_tab(i).shipping_status
                                                          , cv_shipping_status_10, gt_shipping_status_10
                                                          , cv_shipping_status_20, gt_shipping_status_20 ) -- 出荷情報ステータス名（受注番号単位）
               , xlri.last_updated_by             = cn_last_updated_by                                     -- 最終更新者
               , xlri.last_update_date            = cd_last_update_date                                    -- 最終更新日
               , xlri.last_update_login           = cn_last_update_login                                   -- 最終更新ログイン
               , xlri.request_id                  = cn_request_id                                          -- 要求ID
               , xlri.program_application_id      = cn_program_application_id                              -- プログラムアプリケーションID
               , xlri.program_id                  = cn_program_id                                          -- プログラムID
               , xlri.program_update_date         = cd_program_update_date                                 -- プログラム更新日
          WHERE  xlri.order_number                = l_shipping_status_tab(i).order_number                  -- 受注番号
          ;
        END IF;
        --
      END LOOP upd_loop;
      --
    END LOOP order_number_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_lot_reserve_info2;
--
  /**********************************************************************************
   * Procedure Name   : upd_xcc
   * Description      : データ連携制御テーブル更新処理(A-18)
   ***********************************************************************************/
  PROCEDURE upd_xcc(
      ov_errbuf              OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode             OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg              OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xcc'; -- プログラム名
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
    -- *** ローカル変数 ***
    lt_transaction_id        xxcoi_cooperation_control.transaction_id%TYPE DEFAULT NULL; -- 受注ヘッダID
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- Mod Ver1.1 Start
--    --==============================================================
--    -- 1．受注ヘッダID取得
--    --==============================================================
--    SELECT MAX(ooha.header_id)  AS header_id
--    INTO   lt_transaction_id
--    FROM   oe_order_headers_all ooha
--    WHERE  ooha.header_id > gt_max_header_id
--    AND    ooha.org_id     = gt_org_id
--    ;
--    --==============================================================
--    -- 2．データ連携制御テーブル更新
--    --==============================================================
--    UPDATE xxcoi_cooperation_control xcc
--    SET    xcc.last_cooperation_date  = gd_process_date           -- 業務日付
--         , xcc.transaction_id         = lt_transaction_id         -- 受注ヘッダID
--         , xcc.last_updated_by        = cn_last_updated_by        -- 最終更新者
--         , xcc.last_update_date       = cd_last_update_date       -- 最終更新日
--         , xcc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
--         , xcc.request_id             = cn_request_id             -- 要求ID
--         , xcc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
--         , xcc.program_id             = cn_program_id             -- プログラムID
--         , xcc.program_update_date    = cd_program_update_date    -- プログラム更新日
--    WHERE  xcc.program_short_name     = cv_pkg_name
--    ;
    -- 出荷確定の場合
    IF ( gv_kbn = cv_kbn_4 ) THEN
      --==============================================================
      -- 1．受注ヘッダID取得
      --==============================================================
      SELECT MIN(ooha.header_id)  AS header_id
      INTO   lt_transaction_id
      FROM   oe_order_headers_all ooha
           , oe_order_lines_all   oola
      WHERE  ooha.header_id     = oola.header_id
      AND    ooha.org_id        = gt_org_id
      AND    ooha.ordered_date >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1))
      AND    ooha.ordered_date <  gd_process_date + 1
      AND    oola.request_date >= gd_process_date + 1
      ;
      --==============================================================
      -- 2．データ連携制御テーブル更新
      --==============================================================
      UPDATE xxcoi_cooperation_control xcc
      SET    xcc.last_cooperation_date  = gd_process_date           -- 業務日付
           , xcc.transaction_id         = CASE WHEN ( lt_transaction_id IS NOT NULL )
                                               THEN lt_transaction_id - 1
                                               ELSE xcc.transaction_id
                                          END                       -- 受注ヘッダID
           , xcc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           , xcc.last_update_date       = cd_last_update_date       -- 最終更新日
           , xcc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           , xcc.request_id             = cn_request_id             -- 要求ID
           , xcc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           , xcc.program_id             = cn_program_id             -- プログラムID
           , xcc.program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE  xcc.program_short_name     = cv_pkg_name2
      ;
    -- 返品・訂正・過去データの場合
    ELSIF ( gv_kbn = cv_kbn_5 ) THEN
      --==============================================================
      -- 1．受注ヘッダID取得
      --==============================================================
      SELECT MIN(ooha.header_id)  AS header_id
      INTO   lt_transaction_id
      FROM   oe_order_headers_all ooha
      WHERE  ooha.org_id         = gt_org_id
      AND    ooha.ordered_date  >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1))
      AND    ooha.ordered_date  <  gd_process_date + 1
      ;
      --==============================================================
      -- 2．データ連携制御テーブル更新
      --==============================================================
      UPDATE xxcoi_cooperation_control xcc
      SET    xcc.last_cooperation_date  = gd_process_date           -- 業務日付
           , xcc.transaction_id         = CASE WHEN ( lt_transaction_id IS NOT NULL )
                                               THEN lt_transaction_id - 1
                                               ELSE xcc.transaction_id
                                          END                       -- 受注ヘッダID
           , xcc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           , xcc.last_update_date       = cd_last_update_date       -- 最終更新日
           , xcc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           , xcc.request_id             = cn_request_id             -- 要求ID
           , xcc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           , xcc.program_id             = cn_program_id             -- プログラムID
           , xcc.program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE  xcc.program_short_name     = cv_pkg_name
      ;
    END IF;
-- Mod Ver1.1 End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_xcc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf                 OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode                OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg                 OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
    , iv_login_base_code        IN  VARCHAR2 -- 拠点
    , iv_delivery_date_from     IN  VARCHAR2 -- 着日From
    , iv_delivery_date_to       IN  VARCHAR2 -- 着日To
    , iv_login_chain_store_code IN  VARCHAR2 -- チェーン店
    , iv_login_customer_code    IN  VARCHAR2 -- 顧客
    , iv_customer_po_number     IN  VARCHAR2 -- 顧客発注番号
    , iv_subinventory_code      IN  VARCHAR2 -- 保管場所
    , iv_priority_flag          IN  VARCHAR2 -- 優先ロケーション使用
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ロット逆転可否
    , iv_kbn                    IN  VARCHAR2 -- 判定区分
  )
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
    lt_order_number         xxcoi_tmp_lot_reserve_info.order_number%TYPE DEFAULT NULL; -- 受注番号
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
    gn_target_cnt      := 0; -- 対象件数
    gn_normal_cnt      := 0; -- 正常件数
    gn_warn_cnt        := 0; -- スキップ件数
    gn_error_cnt       := 0; -- エラー件数
    gn_target_10_cnt   := 0; -- 対象件数（引当未）
    gn_target_20_cnt   := 0; -- 対象件数（引当済）
    gn_normal_10_cnt   := 0; -- 成功件数（引当未）
    gn_normal_20_cnt   := 0; -- 成功件数（引当済）
    gn_create_temp_cnt := 0; -- ロット別取引TEMP作成件数
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
        iv_login_base_code        => iv_login_base_code        -- 拠点
      , iv_delivery_date_from     => iv_delivery_date_from     -- 着日From
      , iv_delivery_date_to       => iv_delivery_date_to       -- 着日To
      , iv_login_chain_store_code => iv_login_chain_store_code -- チェーン店
      , iv_login_customer_code    => iv_login_customer_code    -- 顧客
      , iv_customer_po_number     => iv_customer_po_number     -- 顧客発注番号
      , iv_subinventory_code      => iv_subinventory_code      -- 保管場所
      , iv_priority_flag          => iv_priority_flag          -- 優先ロケーション使用
      , iv_lot_reversal_flag      => iv_lot_reversal_flag      -- ロット逆転可否
      , iv_kbn                    => iv_kbn                    -- 判定区分
      , ov_errbuf                 => lv_errbuf                 -- エラー・メッセージ
      , ov_retcode                => lv_retcode                -- リターン・コード
      , ov_errmsg                 => lv_errmsg                 -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 拠点コードがNOT NULLの場合（随時実行）
    IF ( gv_login_base_code IS NOT NULL ) THEN
      -- ===============================================
      -- ロック制御処理(A-2)
      -- ===============================================
      get_lock(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================================
    -- ロット別引当情報取得処理(A-3)
    -- ===============================================
    -- 各A-4処理の前で実施
--
    -- 引当の場合
    IF ( gv_kbn = cv_kbn_1 ) THEN
      --==============================================================
      -- 1．受注ヘッダID取得
      --==============================================================
-- Mod Ver1.1 Start
--      SELECT MAX(xlri.header_id)    AS header_id
--      INTO   gt_max_header_id
--      FROM   xxcoi_lot_reserve_info xlri
--      WHERE  xlri.parent_shipping_status = cv_shipping_status_30
--      AND    xlri.base_code              = gv_login_base_code
--      AND    xlri.arrival_date           < gd_delivery_date_from
--      AND    xlri.header_id IS NOT NULL
--      ;
--      --
--      IF ( gt_max_header_id IS NULL ) THEN
--        -- 受注ヘッダID取得エラーメッセージ
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application
--                       , iv_name         => cv_msg_xxcoi_10539
--                       , iv_token_name1  => cv_tkn_base_code
--                       , iv_token_value1 => gv_login_base_code
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END IF;
      BEGIN
        SELECT xcc.transaction_id        AS transaction_id
        INTO   gt_max_header_id
        FROM   xxcoi_cooperation_control xcc
        WHERE  xcc.program_short_name = cv_pkg_name2
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 受注ヘッダID取得エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10539
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
-- Mod Ver1.1 End
      --
      --==============================================================
      -- 2．引当対象外データ取得登録
      --==============================================================
      INSERT INTO xxcoi_tmp_lot_reserve_na(
          header_id -- ヘッダID
        , line_id   -- 明細ID
      )
      SELECT DISTINCT
             xlri.header_id         AS header_id
           , xlri.line_id           AS line_id
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status IN ( cv_shipping_status_20, cv_shipping_status_25, cv_shipping_status_30 )
      AND    xlri.base_code        = gv_login_base_code
      AND    xlri.arrival_date    >= gd_delivery_date_from
      AND    xlri.arrival_date    <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xlri.chain_code      = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( xlri.customer_code   = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( xlri.slip_num        = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = xlri.whse_code )
      AND    xlri.header_id IS NOT NULL
      ;
      -- デバッグ用
      SELECT COUNT(1)
      INTO   gn_debug_cnt
      FROM   xxcoi_tmp_lot_reserve_na
      ;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.2 ロット別引当対象外一時表登録件数：' || gn_debug_cnt
      );
      --
      --==============================================================
      -- 3．引当未データ削除取得登録
      --==============================================================
      DELETE FROM xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status  = cv_shipping_status_10
      AND    xlri.base_code        = gv_login_base_code
      AND    xlri.arrival_date    >= gd_delivery_date_from
      AND    xlri.arrival_date    <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xlri.chain_code      = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( xlri.customer_code   = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( xlri.slip_num        = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = xlri.whse_code )
      ;
      -- デバッグ用
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.3 引当未データ削除件数：' || SQL%ROWCOUNT
      );
      --
      -- ===============================================
      -- 引当対象データ取得処理(A-4)
      -- ===============================================
      get_reserve_data(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- 引当対象ループ
      << kbn_1_loop >>
      FOR l_kbn_1_rec IN g_kbn_1_cur LOOP
        -- 初期化
        gv_retcode := cv_status_normal;
        -- 対象件数設定
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ===============================================
        -- 引当対象データチェック処理(A-5)
        -- ===============================================
        chk_reserve_data(
            it_kbn_1_rec => l_kbn_1_rec -- 引当レコード
          , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- 子品目情報取得処理(A-6)
        -- ===============================================
        get_item(
            it_kbn_1_rec => l_kbn_1_rec -- 引当レコード
          , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- 引当対象在庫判定処理(A-7)
        -- ===============================================
        inventory_reservation(
            it_kbn_1_rec => l_kbn_1_rec -- 引当レコード
          , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          gv_retcode := cv_status_warn;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- ロット別引当情報登録処理(A-12)
        -- ===============================================
        ins_lot_reserve_info(
            it_kbn_1_rec => l_kbn_1_rec -- 引当レコード
          , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP kbn_1_loop;
      --
      -- 対象件数が存在する場合
      IF ( gn_target_cnt > 0 ) THEN
        -- ===============================================
        -- ロット別引当情報更新処理（出荷情報ステータス（受注番号単位））(A-15)
        -- ===============================================
        upd_lot_reserve_info2(
            ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
--
    -- 引当解除の場合
    ELSIF ( gv_kbn = cv_kbn_2 ) THEN
      --==============================================================
      -- 1．引当解除対象データ取得
      --==============================================================
      -- 引当解除ループ
      << kbn_2_loop >>
      FOR l_kbn_2_rec IN g_kbn_2_cur LOOP
        -- ===============================================
        -- ロット別引当情報削除処理(A-13)
        -- ===============================================
        del_lot_reserve_info(
            it_kbn_2_rec => l_kbn_2_rec -- 引当解除レコード
          , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP kbn_2_loop;
--
    -- 出荷仮確定の場合
    ELSIF ( gv_kbn = cv_kbn_3 ) THEN
      --==============================================================
      -- 1．出荷仮確定対象データ取得
      --==============================================================
      -- 出荷仮確定ループ
      << kbn_3_loop >>
      FOR l_kbn_3_rec IN g_kbn_3_cur LOOP
        -- 対象件数設定
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- 受注ヘッダIDが未設定（引当情報訂正アップロードでの新規登録）
        IF ( l_kbn_3_rec.header_id IS NULL ) THEN
          -- 初期化
          gv_retcode      := cv_status_normal;
        -- 受注ヘッダIDが設定されており、初回レコードまたは受注番号が切り替わった場合
        ELSIF ( ( l_kbn_3_rec.header_id IS NOT NULL )
          AND   ( ( lt_order_number IS NULL ) OR ( lt_order_number <> l_kbn_3_rec.order_number ) ) ) THEN
          -- 初期化
          gv_retcode      := cv_status_normal;
          -- 受注番号設定
          lt_order_number := l_kbn_3_rec.order_number;
          --
          -- ===============================================
          -- 受注訂正チェック処理(A-8)
          -- ===============================================
          -- 当処理内で同一受注番号のレコードを全てチェックする
          chk_order(
              iv_order_number           => l_kbn_3_rec.order_number -- 受注番号
-- Add Ver1.3 Start
            , iv_parent_shipping_status => l_kbn_3_rec.parent_shipping_status -- 出荷情報ステータス（受注番号単位）
-- Add Ver1.3 End
            , ov_errbuf                 => lv_errbuf                -- エラー・メッセージ
            , ov_retcode                => lv_retcode               -- リターン・コード
            , ov_errmsg                 => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            gv_retcode := cv_status_warn;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
        -- 同一受注番号のレコードが正常の場合
        -- チェックはA-8で実施済
        IF ( gv_retcode = cv_status_normal ) THEN
-- Add Ver1.3 Start
          -- IDを保持している場合
          IF ( g_del_id_tab.EXISTS( l_kbn_3_rec.lot_reserve_info_id ) ) THEN
            -- ロット別引当情報削除
            DELETE FROM xxcoi_lot_reserve_info xlri
            WHERE  xlri.lot_reserve_info_id = l_kbn_3_rec.lot_reserve_info_id
            ;
          ELSE
-- Add Ver1.3 End
            -- ===============================================
            -- ロット情報保持マスタ反映処理(A-11)
            -- ===============================================
            ref_mst_lot_hold_info(
                it_kbn_3_rec => l_kbn_3_rec -- 出荷確定レコード
              , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
              , ov_retcode   => lv_retcode  -- リターン・コード
              , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            --
            -- ===============================================
            -- ロット別引当情報更新処理(A-14)
            -- ===============================================
            upd_lot_reserve_info(
                iv_lot_tran_kbn        => NULL                            -- ロット別取引明細作成区分
              , in_lot_reserve_info_id => l_kbn_3_rec.lot_reserve_info_id -- ロット別引当情報ID
              , ov_errbuf              => lv_errbuf                       -- エラー・メッセージ
              , ov_retcode             => lv_retcode                      -- リターン・コード
              , ov_errmsg              => lv_errmsg                       -- ユーザー・エラー・メッセージ
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
-- Add Ver1.3 Start
          END IF;
-- Add Ver1.3 End
          --
          -- 件数設定
          -- 正常時
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          -- 失敗時
          gn_warn_cnt   := gn_warn_cnt + 1;
        END IF;
      END LOOP kbn_3_loop;
--
    -- 出荷確定の場合
    ELSIF ( gv_kbn = cv_kbn_4 ) THEN
-- Mod Ver1.1 Start
--      -- 出荷確定ループ
--      << kbn_4_loop >>
--      FOR l_kbn_4_rec IN g_kbn_4_cur LOOP
--        -- 対象件数設定
--        gn_target_cnt := gn_target_cnt + 1;
      -- 出荷確定更新ループ
      << kbn_4_2_loop >>
      FOR l_kbn_4_2_rec IN g_kbn_4_2_cur LOOP
        -- 対象件数設定
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ===============================================
        -- ロット別引当情報更新処理(A-14)
        -- ===============================================
        upd_lot_reserve_info(
            iv_lot_tran_kbn        => l_kbn_4_2_rec.lot_tran_kbn        -- ロット別取引明細作成区分
          , in_lot_reserve_info_id => l_kbn_4_2_rec.lot_reserve_info_id -- ロット別引当情報ID
          , ov_errbuf              => lv_errbuf                         -- エラー・メッセージ
          , ov_retcode             => lv_retcode                        -- リターン・コード
          , ov_errmsg              => lv_errmsg                         -- ユーザー・エラー・メッセージ
        );
      END LOOP kbn_4_2_loop;
-- Mod Ver1.1 End
      --
      -- 出荷確定ループ
      << kbn_4_loop >>
      FOR l_kbn_4_rec IN g_kbn_4_cur LOOP
-- Del Ver1.1 Start
--        -- 未作成の場合
--        IF ( l_kbn_4_rec.lot_tran_kbn = cv_lot_tran_kbn_0 ) THEN
-- Del Ver1.1 End
        -- ===============================================
        -- ロット別取引明細登録処理(A-9)
        -- ===============================================
        ins_lot_transactions(
            it_kbn_4_rec => l_kbn_4_rec -- 出荷確定レコード
          , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- ロット別手持数量反映処理(A-10)
        -- ===============================================
        ref_lot_onhand(
            it_kbn_4_rec => l_kbn_4_rec -- 出荷確定レコード
          , ov_errbuf    => lv_errbuf   -- エラー・メッセージ
          , ov_retcode   => lv_retcode  -- リターン・コード
          , ov_errmsg    => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
-- Mod Ver1.1 Start
--          --
--        END IF;
--        -- ===============================================
--        -- ロット別引当情報更新処理(A-14)
--        -- ===============================================
--        upd_lot_reserve_info(
--            iv_lot_tran_kbn        => l_kbn_4_rec.lot_tran_kbn        -- ロット別取引明細作成区分
--          , in_lot_reserve_info_id => l_kbn_4_rec.lot_reserve_info_id -- ロット別引当情報ID
--          , ov_errbuf              => lv_errbuf                       -- エラー・メッセージ
--          , ov_retcode             => lv_retcode                      -- リターン・コード
--          , ov_errmsg              => lv_errmsg                       -- ユーザー・エラー・メッセージ
--        );
-- Mod Ver1.1 End
        -- 正常時
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP kbn_4_loop;
-- Add Ver1.1 Start
      -- ===============================================
      -- データ連携制御テーブル更新処理(A-18)
      -- ===============================================
      upd_xcc(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- Add Ver1.1 End
--
    -- 返品・訂正・過去データ
    ELSIF ( gv_kbn = cv_kbn_5 ) THEN
      --==============================================================
      -- 1．受注ヘッダID取得
      --==============================================================
-- Mod Ver1.1 Start
--      -- 拠点コードがNULLの場合（定期実行）
--      IF ( gv_login_base_code IS NULL ) THEN
--        BEGIN
--          SELECT xcc.transaction_id        AS transaction_id
--          INTO   gt_max_header_id
--          FROM   xxcoi_cooperation_control xcc
--          WHERE  xcc.program_short_name = cv_pkg_name
--          ;
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            -- 受注ヘッダID取得エラーメッセージ
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                             iv_application  => cv_application
--                           , iv_name         => cv_msg_xxcoi_10539
--                           , iv_token_name1  => cv_tkn_base_code
--                           , iv_token_value1 => gv_login_base_code
--                         );
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
--        END;
      BEGIN
        SELECT xcc.transaction_id        AS transaction_id
        INTO   gt_max_header_id
        FROM   xxcoi_cooperation_control xcc
        WHERE  xcc.program_short_name = cv_pkg_name
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 受注ヘッダID取得エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10539
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- 拠点コードがNULLの場合（定期実行）
      IF ( gv_login_base_code IS NULL ) THEN
-- Mod Ver1.1 End
        -- ロット別引当保管場所一時表登録
        INSERT INTO xxcoi_tmp_lot_reserve_subinv(
          subinventory_code -- 保管場所コード
        )
        SELECT msi.secondary_inventory_name AS secondary_inventory_name
        FROM   mtl_secondary_inventories    msi
        WHERE  msi.attribute14     = cv_flag_y
        AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
        AND    msi.organization_id = gt_organization_id
        ;
        -- デバッグ用
        SELECT COUNT(1)
        INTO   gn_debug_cnt
        FROM   xxcoi_tmp_lot_reserve_subinv
        ;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-3 ロット別引当保管場所一時表登録件数：' || gn_debug_cnt
        );
-- Del Ver1.1 Start
--      -- 拠点コードがNOT NULLの場合（随時実行）
--      ELSE
--        SELECT MAX(xlri.header_id)    AS header_id
--        INTO   gt_max_header_id
--        FROM   xxcoi_lot_reserve_info xlri
--        WHERE  xlri.parent_shipping_status = cv_shipping_status_30
--        AND    xlri.base_code              = gv_login_base_code
--        AND    xlri.arrival_date           < gd_delivery_date_from
--        AND    xlri.header_id IS NOT NULL
--        ;
--        --
--        IF ( gt_max_header_id IS NULL ) THEN
--          -- 受注ヘッダID取得エラーメッセージ
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_application
--                         , iv_name         => cv_msg_xxcoi_10539
--                         , iv_token_name1  => cv_tkn_base_code
--                         , iv_token_value1 => gv_login_base_code
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
-- Del Ver1.1 End
      END IF;
      --
      --==============================================================
      -- 2．引当データ取得登録
      --==============================================================
      INSERT INTO xxcoi_tmp_lot_reserve_na(
          header_id -- ヘッダID
        , line_id   -- 明細ID
      )
      SELECT DISTINCT
             xlri.header_id         AS header_id
           , xlri.line_id           AS line_id
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.base_code        = gv_login_base_code
      AND    xlri.arrival_date    >= gd_delivery_date_from
      AND    xlri.arrival_date    <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xlri.chain_code      = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( xlri.customer_code   = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( xlri.slip_num        = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = xlri.whse_code )
      AND    xlri.header_id IS NOT NULL
      ;
      -- デバッグ用
      SELECT COUNT(1)
      INTO   gn_debug_cnt
      FROM   xxcoi_tmp_lot_reserve_na
      ;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.2 引当対象外件数：' || gn_debug_cnt
      );
      --
      -- ===============================================
      -- 引当以外データ取得処理(A-17)
      -- ===============================================
      get_reserve_other_data(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- 拠点コードがNULLの場合（定期実行）
      IF ( gv_login_base_code IS NULL ) THEN
        -- ===============================================
        -- データ連携制御テーブル更新処理(A-18)
        -- ===============================================
        upd_xcc(
            ov_errbuf  => lv_errbuf  -- エラー・メッセージ
          , ov_retcode => lv_retcode -- リターン・コード
          , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    -- 仮確定後訂正の場合
    ELSIF ( gv_kbn = cv_kbn_6 ) THEN
      --==============================================================
      -- 6．出荷仮確定データ取得
      --==============================================================
      -- 拠点コードがNOT NULLの場合（随時実行）
      IF ( gv_login_base_code IS NOT NULL ) THEN
        SELECT DISTINCT
               xlri.order_number          AS order_number
        BULK COLLECT INTO gt_order_number_tab
        FROM   xxcoi_lot_reserve_info     xlri
        WHERE  xlri.shipping_status  = cv_shipping_status_25
        AND    xlri.base_code        = gv_login_base_code
        AND    xlri.arrival_date    >= gd_delivery_date_from
        AND    xlri.arrival_date    <  gd_delivery_date_to + 1
        AND ( ( gv_login_chain_store_code IS NULL )
           OR ( xlri.chain_code      = gv_login_chain_store_code ) )
        AND ( ( gv_login_customer_code IS NULL )
           OR ( xlri.customer_code   = gv_login_customer_code ) )
        AND ( ( gv_customer_po_number IS NULL )
           OR ( xlri.slip_num        = gv_customer_po_number ) )
        AND EXISTS ( SELECT 1
                     FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                     WHERE  xtlrs.subinventory_code = xlri.whse_code )
        AND    xlri.header_id IS NOT NULL
        ORDER BY xlri.order_number
        ;
      -- 拠点コードがNULLの場合（定期実行）
      ELSE
        SELECT DISTINCT
               xlri.order_number          AS order_number
        BULK COLLECT INTO gt_order_number_tab
        FROM   xxcoi_lot_reserve_info     xlri
        WHERE  xlri.shipping_status  = cv_shipping_status_25
        AND    xlri.arrival_date    >= gd_delivery_date_from
        AND    xlri.arrival_date    <  gd_delivery_date_to + 1
        AND    xlri.header_id IS NOT NULL
        ;
        --
        -- ロット別引当保管場所一時表登録
        INSERT INTO xxcoi_tmp_lot_reserve_subinv(
          subinventory_code -- 保管場所コード
        )
        SELECT msi.secondary_inventory_name AS secondary_inventory_name
        FROM   mtl_secondary_inventories    msi
        WHERE  msi.attribute14     = cv_flag_y
        AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
        AND    msi.organization_id = gt_organization_id
        ;
        -- デバッグ用
        SELECT COUNT(1)
        INTO   gn_debug_cnt
        FROM   xxcoi_tmp_lot_reserve_subinv
        ;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-3 ロット別引当保管場所一時表登録件数：' || gn_debug_cnt
        );
      END IF;
      -- デバッグ用
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.6 出荷仮確定件数：' || gt_order_number_tab.COUNT
      );
      --
      -- 対象0件メッセージを非表示するため
      gn_target_cnt := gt_order_number_tab.COUNT;
      --
      << g_kbn_6_loop>>
      FOR i IN 1 .. gt_order_number_tab.COUNT LOOP
        -- ===============================================
        -- 受注訂正チェック処理(A-8)
        -- ===============================================
        chk_order(
            iv_order_number           => gt_order_number_tab(i) -- 受注番号
-- Add Ver1.3 Start
          , iv_parent_shipping_status => NULL                   -- 出荷情報ステータス（受注番号単位）
-- Add Ver1.3 End
          , ov_errbuf                 => lv_errbuf              -- エラー・メッセージ
          , ov_retcode                => lv_retcode             -- リターン・コード
          , ov_errmsg                 => lv_errmsg              -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ロット別取引TEMPを登録した場合
        IF ( gt_lot_id_tab.COUNT > 0 ) THEN
          -- ===============================================
          -- ロット別引当情報更新処理(A-14)
          -- ===============================================
          upd_lot_reserve_info(
              iv_lot_tran_kbn        => NULL       -- ロット別取引明細作成区分
            , in_lot_reserve_info_id => NULL       -- ロット別引当情報ID
            , ov_errbuf              => lv_errbuf  -- エラー・メッセージ
            , ov_retcode             => lv_retcode -- リターン・コード
            , ov_errmsg              => lv_errmsg  -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
      END LOOP g_kbn_6_loop;
      --
      -- 出荷仮確定データは存在するが、ロット別取引TEMP作成件数は0件の場合
      IF ( ( gn_target_cnt > 0 ) AND ( gn_create_temp_cnt = 0 ) ) THEN
        -- 処理対象データ無しメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10660
                     );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg
        );
      END IF;
    END IF;
--
    -- 対象件数0件の場合
    IF ( ( gn_target_cnt = 0 ) AND ( gn_target_10_cnt = 0 ) AND ( gn_target_20_cnt = 0 ) AND ( gn_create_temp_cnt = 0 ) ) THEN
      -- 処理対象データ無しメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10540
                     , iv_token_name1  => cv_tkn_process
                     , iv_token_value1 => gt_xxcoi016a06_kbn
                   );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
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
      IF ( g_kbn_1_cur%ISOPEN ) THEN
        CLOSE g_kbn_1_cur;
      ELSIF ( g_kbn_2_cur%ISOPEN ) THEN
        CLOSE g_kbn_2_cur;
      ELSIF ( g_kbn_3_cur%ISOPEN ) THEN
        CLOSE g_kbn_3_cur;
      ELSIF ( g_kbn_4_cur%ISOPEN ) THEN
        CLOSE g_kbn_4_cur;
      END IF;
-- Mod Ver1.1 Start
      IF ( g_kbn_4_2_cur%ISOPEN ) THEN
        CLOSE g_kbn_4_2_cur;
      END IF;
-- Mod Ver1.1 End
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
      errbuf                    OUT VARCHAR2 -- エラーメッセージ #固定#
    , retcode                   OUT VARCHAR2 -- エラーコード     #固定#
    , iv_login_base_code        IN  VARCHAR2 -- 拠点
    , iv_delivery_date_from     IN  VARCHAR2 -- 着日From
    , iv_delivery_date_to       IN  VARCHAR2 -- 着日To
    , iv_login_chain_store_code IN  VARCHAR2 -- チェーン店
    , iv_login_customer_code    IN  VARCHAR2 -- 顧客
    , iv_customer_po_number     IN  VARCHAR2 -- 顧客発注番号
    , iv_subinventory_code      IN  VARCHAR2 -- 保管場所
    , iv_priority_flag          IN  VARCHAR2 -- 優先ロケーション使用
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ロット逆転可否
    , iv_kbn                    IN  VARCHAR2 -- 判定区分
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
    -- アプリケーション短縮名
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    -- メッセージ
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_msg_xxcoi_10555 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10555'; -- 対象件数（引当未）件数メッセージ
    cv_msg_xxcoi_10556 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10556'; -- 成功件数（引当未）件数メッセージ
    cv_msg_xxcoi_10557 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10557'; -- 対象件数（引当済）件数メッセージ
    cv_msg_xxcoi_10558 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10558'; -- 成功件数（引当済）件数メッセージ
    cv_msg_xxcoi_10569 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10569'; -- 失敗件数メッセージ
    cv_msg_xxcoi_10551 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10551'; -- ロット別取引TEMP作成件数メッセージ
    -- トークン
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
        ov_errbuf                 => lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      , ov_retcode                => lv_retcode                -- リターン・コード             --# 固定 #
      , ov_errmsg                 => lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
      , iv_login_base_code        => iv_login_base_code        -- 拠点
      , iv_delivery_date_from     => iv_delivery_date_from     -- 着日From
      , iv_delivery_date_to       => iv_delivery_date_to       -- 着日To
      , iv_login_chain_store_code => iv_login_chain_store_code -- チェーン店
      , iv_login_customer_code    => iv_login_customer_code    -- 顧客
      , iv_customer_po_number     => iv_customer_po_number     -- 顧客発注番号
      , iv_subinventory_code      => iv_subinventory_code      -- 保管場所
      , iv_priority_flag          => iv_priority_flag          -- 優先ロケーション使用
      , iv_lot_reversal_flag      => iv_lot_reversal_flag      -- ロット逆転可否
      , iv_kbn                    => iv_kbn                    -- 判定区分
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- エラー時のROLLBACK
      ROLLBACK;
      -- エラー件数設定
      gn_error_cnt := 1;
    END IF;
--
    -- エラー件数が存在する場合
    IF ( gn_error_cnt > 0 ) THEN
      -- エラー時の件数設定
      gn_target_cnt      := 0;
      gn_normal_cnt      := 0;
      gn_warn_cnt        := 0;
      gn_target_10_cnt   := 0;
      gn_normal_10_cnt   := 0;
      gn_target_20_cnt   := 0;
      gn_normal_20_cnt   := 0;
      gn_create_temp_cnt := 0;
      -- 終了ステータスをエラーにする
      lv_retcode := cv_status_error;
    -- エラー件数が0件で、警告件数が存在または警告フラグがTRUEの場合
    ELSIF ( ( gn_error_cnt = 0 )
      AND   ( ( gn_warn_cnt > 0 ) OR ( gb_warn_flag = TRUE ) ) ) THEN
      -- 終了ステータスを警告にする
      lv_retcode := cv_status_warn;
    -- エラー件数、警告件数が存在しない場合
    ELSE
      -- 終了ステータスを正常にする
      lv_retcode := cv_status_normal;
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 引当または出荷確定の場合
    IF ( ( gv_kbn = cv_kbn_1 ) OR ( gv_kbn = cv_kbn_3 ) OR ( gv_kbn = cv_kbn_4 ) ) THEN
      -- 対象件数出力
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
      -- 成功件数出力
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
      -- 失敗件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10569
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    -- 引当解除の場合
    ELSIF ( gv_kbn = cv_kbn_2 ) THEN
      -- 対象件数（引当未）出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10555
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_target_10_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 成功件数（引当未）出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10556
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_normal_10_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 対象件数（引当済）出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10557
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_target_20_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 成功件数（引当済）出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10558
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_normal_20_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    -- 返品・訂正・過去データ、仮確定後訂正の場合
    ELSIF ( ( gv_kbn = cv_kbn_5 ) OR ( gv_kbn = cv_kbn_6 ) ) THEN
      -- ロット別取引TEMP作成件数
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10551
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_create_temp_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    -- エラー件数出力
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
                      iv_application => cv_appl_short_name
                    , iv_name        => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCOI016A99C;
/
