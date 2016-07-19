CREATE OR REPLACE PACKAGE BODY xxwip730001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip730001c(body)
 * Description      : 支払運賃データ自動作成
 * MD.050           : 運賃計算（トランザクション） T_MD050_BPO_730
 * MD.070           : 支払運賃データ自動作成 T_MD070_BPO_73A
 * Version          : 1.28
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_param_proc         パラメータチェック処理(A-1)
 *  get_init               関連データ取得(A-2) 運賃用締日情報取得(A-3)
 *  get_deliv_lock         ロック取得(A-4)
 *  get_delivmst_lock      ロック取得(運賃関連マスタ)   2009/04/07 add
 *
 *  get_order              受注実績情報抽出(A-5)
 *  get_order_other        受注関連情報抽出
 *    get_order_ship         受注配送区分情報VIEW抽出(A-6)
 *    get_order_distance     受注配送距離アドオンマスタ抽出(A-7)
 *    get_order_company      受注運賃用運送業者アドオンマスタ抽出(A-8)
 *
 *  get_order_line         受注明細アドオン抽出(A-9)
 *    get_order_line_item    受注OPM品目情報VIEW抽出(A-10)
 *    get_order_line_calc    受注個数/数量算出(A-11)
 *    get_order_line_sum     受注個数/数量集計(A-12)
 *  set_order_deliv_line   受注運賃明細アドオンPL/SQL表格納(A-13)
 *
 *  get_move               移動実績情報抽出(A-14)
 *  get_move_other         移動関連情報抽出
 *    get_move_ship          移動配送区分情報VIEW抽出(A-15)
 *    get_move_distance      移動配送距離アドオンマスタ抽出(A-16)
 *    get_move_company       移動運賃用運送業者アドオンマスタ抽出(A-17)
 *
 *  get_move_line          移動明細アドオン抽出(A-18)
 *    get_move_line_item     移動OPM品目情報VIEW抽出(A-19)
 *    get_move_line_calc     移動個数/数量算出(A-20)
 *    get_move_line_sum      移動個数/数量集計(A-21)
 *  set_move_deliv_line    移動運賃明細アドオンPL/SQL表格納(A-22)
 *
 *  insert_deliv_line      運賃明細アドオン一括登録(A-23)
 *  update_deliv_line_calc 運賃明細アドオン一括再計算更新(A-24)
 *  update_deliv_line_desc 運賃明細アドオン一括適用更新(A-25)
 *
 *  get_carcan_req_no         配車解除対象依頼No抽出(A-25-1)
 *  get_carcan_deliv_no       配車解除配送No抽出(A-25-2)
 *  delete_carcan_req_no      配車解除依頼No削除(A-25-3)
 *  check_carcan_deliv_no     配車解除配送No存在確認(A-25-4)
 *  update_carcan_deliv_line  配車解除運賃明細アドオン更新(A-25-4)
 *  delete_carcan_deliv_head  配車解除運賃ヘッダアドオン削除(A-25-5)
 *
 *  get_delinov_line_desc  運賃明細アドオン対象配送No抽出(A-26)
 *  get_deliv_line         運賃明細アドオン抽出(A-27)
 *    get_deliv_mix_calc     運賃明細混載数算出(A-28)
 *    get_deliv_fare_calc    運賃算出(A-29)
 *  set_deliv_head         運賃ヘッダアドオンPL/SQL表格納(A-30)
 *
 *  get_carriers_schedule  配車配送計画抽出(A-31)
 *     ×set_carri_deliv_head   配車のみ運賃ヘッダアドオンPL/SQL表格納(A-32)
 *  set_carri_deliv_head   伝票なし配車PL/SQL表格納
 *
 *  insert_deliv_head      運賃ヘッダアドオン一括登録(A-33)
 *  update_deliv_head      運賃ヘッダアドオン一括更新(A-34)
 *  delete_deliv_head      運賃ヘッダアドオン一括削除(A-35)
 *  update_deliv_cntl      運賃計算コントロール更新処理(A-36)
 *
 *  get_exch_deliv_line    洗替運賃明細アドオン抽出(A-37)
 *  set_exch_deliv_line    洗替運賃明細アドオンPL/SQL表格納(A-38)
 *  update_exch_deliv_line 洗替運賃明細アドオン一括更新(A-39)
 *
 *  get_exch_delino        洗替運賃明細アドオン対象配送No抽出(A-40)
 *  get_exch_deliv_line_h  洗替運賃明細アドオン抽出(A-41)
 *  set_exch_deliv_head_h  洗替運賃ヘッダアドオン明細項目更新用PL/SQL表格納(A-42)
 *
 *  update_exch_deliv_head_h 洗替運賃ヘッダアドオン明細項目一括更新(A-43)
 *
 *  get_exch_deliv_other   運賃ヘッダ関連 抽出
 *    get_exch_deliv_head    洗替運賃ヘッダアドオン抽出(A-44)
 *    get_exch_deliv_charg   洗替運賃アドオンマスタ抽出(A-45)
 *  set_exch_deliv_hate    洗替運賃ヘッダアドオンPL/SQL表格納(A-46)
 *
 *  update_exch_deliv_head 洗替運賃アドオンマスタ一括更新(A-47)
 *  delete_exch_deliv_head 洗替運賃アドオンマスタ一括削除(A-48)
 *  delete_exch_deliv_mst  洗替運賃マスタ一括更新(A-48-1)
 *  delete_deli_cleaning   配車組換削除(A-35-2)
 *
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/01    1.0  Oracle 野村       初回作成
 *  2008/05/27    1.1  Oracle 野村       結合障害 混載処理
 *  2008/06/25    1.2  Oracle 野村       TE080指摘事項 反映
 *  2008/07/15    1.3  Oracle 野村       ST障害#452対応（切上対応含む）
 *  2008/07/16    1.4  Oracle 野村       ST障害#455対応
 *  2008/07/17    1.5  Oracle 野村       変更要求#96、#98対応
 *  2008/08/04    1.6  Oracle 山根       内部課題#187対応
 *  2008/08/25    1.7  Oracle 野村       ST事前確認障害
 *  2008/09/12    1.8  Oracle 野村       TE080指摘事項15対応 区分設定見直対応
 *  2008/10/21    1.9  Oracle 野村       T_S_572 統合#392対応
 *  2008/10/27    1.10 Oracle 野村       統合#436対応
 *  2008/10/31    1.11 Oracle 野村       統合#531対応
 *  2008/11/07    1.12 Oracle 野村       統合#584対応
 *  2008/11/25    1.13 Oracle 吉田       本番#104対応
 *  2008/11/28    1.14 Oracle 椎名       本番#201対応
 *  2008/12/09    1.15 Oracle 野村       本番#595対応
 *  2008/12/10    1.16 Oracle 野村       本番#401対応
 *  2008/12/24    1.17 Oracle 野村       本番#323対応
 *  2008/12/26    1.18 Oracle 野村       本番#323対応（ログ対応）
 *  2008/12/29    1.19 Oracle 野村       本番#882対応
 *  2009/01/23    1.20 Oracle 野村       本番#1074対応
 *  2009/02/03    1.21 Oracle 野村       本番#1017対応
 *  2009/02/09    1.22 Oracle 野村       本番#1017対応
 *  2009/04/07    1.23 Oracle 野村       本番#432対応
 *  2009/04/30    1.24 Oracle 野村       本番#432対応
 *  2009/05/07    1.25 Oracle 野村       本番#432対応
 *  2009/05/14    1.26 Oracle 野村       本番#432対応
 *  2009/05/29    1.27 Oracle 野村       本番#1505対応
 *  2016/06/22    1.28 SCSK 仁木         E_本稼動_13659対応
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
  -- ユーザー定義例外
  -- ===============================
  lock_expt                  EXCEPTION;  -- ロック取得例外
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
  func_inv_expt              EXCEPTION;
  PRAGMA EXCEPTION_INIT(func_inv_expt, -20001);    -- ファンクションエラー
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwip730001c'; -- パッケージ名
--
  -- アプリケーション短縮名
  gv_xxcmn_msg_kbn            CONSTANT VARCHAR2(5) := 'XXCMN';
  gv_xxwip_msg_kbn            CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- プロファイル
  gv_prof_debug_flg   CONSTANT VARCHAR2(50) := 'XXWIP_730001C_DEBUG';  -- プロファイル：デバッグフラグ
  gv_debug_on         CONSTANT VARCHAR2(1) := '1';  -- デバッグ ON
  gv_debug_off        CONSTANT VARCHAR2(1) := '0';  -- デバッグ OFF
--
  -- メッセージ番号(XXCMN)
  gv_xxcmn_msg_okcnt          CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; -- 成功件数
  gv_xxcmn_msg_notfnd         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- 対象データなし
  gv_xxcmn_msg_toomny         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10137'; -- 対象データが複数
  gv_xxcmn_msg_para           CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- パラメータエラー
  gv_xxcom_noprof_err         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- プロファイル取得エラー
  gv_xxwip_msg_lock_err       CONSTANT VARCHAR2(15) := 'APP-XXWIP-10029'; -- テーブルロックエラー
  gv_xxwip_msg_deliv_line     CONSTANT VARCHAR2(15) := 'APP-XXWIP-00009'; -- 運賃明細アドオン処理件数
  gv_xxwip_msg_deliv_ins      CONSTANT VARCHAR2(15) := 'APP-XXWIP-00010'; -- 運賃ヘッダアドオン処理件数
  gv_xxwip_msg_deliv_del      CONSTANT VARCHAR2(15) := 'APP-XXWIP-00011'; -- 運賃ヘッダアドオン削除件数
--
  -- メッセー内容（名称）
  gv_deliverys_ctrl           CONSTANT VARCHAR2(50) := '運賃計算用コントロールアドオン';
  gv_exchange_type            CONSTANT VARCHAR2(50) := '洗替区分';
  gv_deliverys                CONSTANT VARCHAR2(50) := '運賃ヘッダアドオン';
  gv_delivery_lines           CONSTANT VARCHAR2(50) := '運賃明細アドオン';
  gv_item_mst2_v              CONSTANT VARCHAR2(50) := 'OPM品目情報VIEW2';
  gv_order_headers_all        CONSTANT VARCHAR2(50) := '受注明細アドオン';
  gv_mov_req_instr_lines      CONSTANT VARCHAR2(50) := '移動依頼/指示明細アドオン';
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
  gv_delivery_company         CONSTANT VARCHAR2(50) := '運賃用運送業者マスタ';
  gv_delivery_distance        CONSTANT VARCHAR2(50) := '配送距離マスタ';
  gv_delivery_charges         CONSTANT VARCHAR2(50) := '運賃マスタ';
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
  -- トークン
  gv_tkn_parameter            CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_tkn_value                CONSTANT VARCHAR2(10) := 'VALUE';
  gv_tkn_table                CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key                  CONSTANT VARCHAR2(10) := 'KEY';
  gv_tkn_cnt                  CONSTANT VARCHAR2(10) := 'CNT';
  gv_tkn_ng_profile           CONSTANT VARCHAR2(10) := 'NG_PROFILE';
--
  -- 対象_対象外区分
  gv_target_y                 CONSTANT VARCHAR2(1) := '1';
  gv_target_n                 CONSTANT VARCHAR2(1) := '0';
  -- YESNO区分
  gv_ktg_yes                  CONSTANT VARCHAR2(1) := 'Y';
  gv_ktg_no                   CONSTANT VARCHAR2(1) := 'N';
--
  -- コンカレントNo(運賃計算用コントロール)
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
--  gv_con_no_deliv             CONSTANT VARCHAR2(1) := '1';  -- 1:支払運賃データ自動作成
  gv_con_no_deliv_lef         CONSTANT VARCHAR2(1) := '1';  -- 1:運賃計算（リーフ）
  gv_con_no_deliv_drk         CONSTANT VARCHAR2(1) := '2';  -- 2:運賃計算（ドリンク）
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
  -- 支払請求区分
  gv_pay                      CONSTANT VARCHAR2(1) := '1';  -- 1:支払
  gv_claim                    CONSTANT VARCHAR2(1) := '2';  -- 2:請求
  -- 商品区分
  gv_prod_class_lef           CONSTANT VARCHAR2(1) := '1';  -- 1:リーフ
  gv_prod_class_drk           CONSTANT VARCHAR2(1) := '2';  -- 2:ドリンク
  -- 小口区分
  gv_small_sum_yes            CONSTANT VARCHAR2(1) := '1';  -- 1:小口
  gv_small_sum_no             CONSTANT VARCHAR2(1) := '0';  -- 0:車立
  -- 支払判断区分
  gv_pay_judg_g               CONSTANT VARCHAR2(1) := '1';  -- 1:発日
  gv_pay_judg_c               CONSTANT VARCHAR2(1) := '2';  -- 2:着日
  -- 出荷支給区分
  gv_shipping                 CONSTANT VARCHAR2(1) := '1';  -- 1:出荷指示
  gv_shikyu                   CONSTANT VARCHAR2(1) := '2';  -- 2:支給依頼
  gv_kuragae                  CONSTANT VARCHAR2(1) := '3';  -- 3:倉替返品
  -- 重量容積区分
  gv_weight                   CONSTANT VARCHAR2(1) := '1';  -- 1:重量
  gv_capacity                 CONSTANT VARCHAR2(1) := '2';  -- 2:容積
  -- コード区分
  gv_code_move                CONSTANT VARCHAR2(1) := '1';  -- 1:倉庫
  gv_code_shikyu              CONSTANT VARCHAR2(1) := '2';  -- 2:取引先
  gv_code_ship                CONSTANT VARCHAR2(1) := '3';  -- 3:配送先
  -- タイプ（処理種別（配車）と同じ）
  gv_type_ship                CONSTANT VARCHAR2(1) := '1';  -- 1:出荷
  gv_type_shikyu              CONSTANT VARCHAR2(1) := '2';  -- 2:支給
  gv_type_move                CONSTANT VARCHAR2(1) := '3';  -- 3:移動
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
--
  -- 配車タイプ
  gv_car_normal               CONSTANT VARCHAR2(1) := '1';  -- 1:通常配車
  gv_carcan_target_y          CONSTANT VARCHAR2(1) := '2';  -- 2:伝票なし配車（リーフ小口）
  gv_carcan_target_n          CONSTANT VARCHAR2(1) := '3';  -- 3:伝票なし配車（リーフ小口以外）
--
  -- 伝票なし配車区分
  gv_non_slip_nml             CONSTANT VARCHAR2(1) := '1';  -- 1:通常配車
  gv_non_slip_slp             CONSTANT VARCHAR2(1) := '2';  -- 2:伝票なし配車
  gv_non_slip_can             CONSTANT VARCHAR2(1) := '3';  -- 3:伝票なし配車解除
--
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- *****************************
  -- * 受注実績 関連
  -- *****************************
  -- 受注実績情報 抽出項目
  TYPE order_inf_rec IS RECORD(
      order_header_id               xxwsh_order_headers_all.order_header_id%TYPE              -- 受注ヘッダアドオンID
    , request_no                    xxwsh_order_headers_all.request_no%TYPE                   -- 依頼No
    , slip_number                   xxwsh_order_headers_all.slip_number%TYPE                  -- 送り状No
    , delivery_no                   xxwsh_order_headers_all.delivery_no%TYPE                  -- 配送No
    , result_freight_carrier_code   xxwsh_order_headers_all.result_freight_carrier_code%TYPE  -- 運送業者_実績
    , deliver_from                  xxwsh_order_headers_all.deliver_from%TYPE                 -- 出荷元保管場所
    , result_shipping_method_code   xxwsh_order_headers_all.result_shipping_method_code%TYPE  -- 配送区分_実績
    , deliver_to_code_class         VARCHAR2(1)                                               -- 配送先コード区分
    , result_deliver_to             xxwsh_order_headers_all.result_deliver_to%TYPE            -- 出荷先_実績
    , payments_judgment_classe      xxwip_delivery_company.payments_judgment_classe%TYPE      -- 支払判断区分(運賃)
    , shipped_date                  xxwsh_order_headers_all.shipped_date%TYPE                 -- 出荷日
    , arrival_date                  xxwsh_order_headers_all.arrival_date%TYPE                 -- 着荷日
    , judgement_date                DATE                                                      -- 判断日
    , prod_class                    xxwsh_order_headers_all.prod_class%TYPE                   -- 商品区分
    , weight_capacity_class         xxwsh_order_headers_all.weight_capacity_class%TYPE        -- 重量容積区分
    , small_quantity                xxwsh_order_headers_all.small_quantity%TYPE               -- 小口個数
    , order_type                    VARCHAR2(1)                                               -- タイプ
    , no_cont_freight_class         xxwsh_order_headers_all.no_cont_freight_class%TYPE        -- 契約外運賃区分
    , transfer_location_code        xxwsh_order_headers_all.transfer_location_code%TYPE       -- 振替先
    , shipping_instructions         VARCHAR2(40)                                              -- 出荷指示(40)
    , small_amount_class            xxwsh_ship_method_v.small_amount_class%TYPE               -- 配送区分：小口区分
    , mixed_class                   xxwsh_ship_method_v.mixed_class%TYPE                      -- 配送区分：混載区分
    , ref_small_amount_class        VARCHAR2(1)                                               -- 配送区分：リーフ小口区分
    , post_distance                 xxwip_delivery_distance.post_distance%TYPE                -- 配送距離：車立距離
    , small_distance                xxwip_delivery_distance.small_distance%TYPE               -- 配送距離：小口距離
    , consolid_add_distance         xxwip_delivery_distance.consolid_add_distance%TYPE        -- 配送距離：混載割増距離
    , actual_distance               xxwip_delivery_distance.actual_distance%TYPE              -- 配送距離：実際距離
    , small_weight                  xxwip_delivery_company.small_weight%TYPE                  -- 運送業者：小口重量
    , pay_picking_amount            xxwip_delivery_company.pay_picking_amount%TYPE            -- 運送業者：支払ピッキング単価
    , qty                           xxwip_deliverys.qty1%TYPE                                 -- 個数
    , delivery_weight               xxwip_deliverys.delivery_weight1%TYPE                     -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
    , sum_pallet_weight             xxwsh_order_headers_all.sum_pallet_weight%TYPE            -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
  );
--
  -- 対象データ情報を格納するテーブル型の定義
  TYPE order_inf_tbl IS TABLE OF order_inf_rec INDEX BY PLS_INTEGER;
  gt_order_inf_tab   order_inf_tbl;
--
  -- 受注明細情報 抽出項目
  TYPE order_line_inf_rec IS RECORD(
      order_header_id               xxwsh_order_lines_all.order_header_id%TYPE      -- 受注ヘッダアドオンID
    , shipping_item_code            xxwsh_order_lines_all.shipping_item_code%TYPE   -- 出荷品目
    , shipped_quantity              xxwsh_order_lines_all.shipped_quantity%TYPE     -- 出荷実績数量
  );
  TYPE order_line_inf_tbl IS TABLE OF order_line_inf_rec INDEX BY PLS_INTEGER;
--
  -- *****************************
  -- * 移動実績 関連
  -- *****************************
  -- 移動実績情報 抽出項目
  TYPE move_inf_rec IS RECORD(
      mov_hdr_id                    xxinv_mov_req_instr_headers.mov_hdr_id%TYPE                   -- 移動ヘッダID
    , mov_num                       xxinv_mov_req_instr_headers.mov_num%TYPE                      -- 移動番号
    , slip_number                   xxinv_mov_req_instr_headers.slip_number%TYPE                  -- 送り状No
    , delivery_no                   xxinv_mov_req_instr_headers.delivery_no%TYPE                  -- 配送No
    , actual_freight_carrier_code   xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE  -- 運送業者_実績
    , shipped_locat_code            xxinv_mov_req_instr_headers.shipped_locat_code%TYPE           -- 出庫元保管場所
    , shipping_method_code          xxinv_mov_req_instr_headers.shipping_method_code%TYPE         -- 配送区分
    , deliver_to_code_class         VARCHAR2(1)                                                   -- 配送先コード区分
    , ship_to_locat_code            xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE           -- 入庫先保管場所
    , payments_judgment_classe      xxwip_delivery_company.payments_judgment_classe%TYPE          -- 支払判断区分(運賃)
    , actual_ship_date              xxinv_mov_req_instr_headers.actual_ship_date%TYPE             -- 出庫実績日
    , actual_arrival_date           xxinv_mov_req_instr_headers.actual_arrival_date%TYPE          -- 入庫実績日
    , judgement_date                DATE                                                          -- 判断日
    , item_class                    xxinv_mov_req_instr_headers.item_class%TYPE                   -- 商品区分
    , weight_capacity_class         xxinv_mov_req_instr_headers.weight_capacity_class%TYPE        -- 重量容積区分
    , small_quantity                xxinv_mov_req_instr_headers.small_quantity%TYPE               -- 小口個数
    , sum_quantity                  xxinv_mov_req_instr_headers.sum_quantity%TYPE                 -- 合計数量
    , order_type                    VARCHAR2(1)                                                   -- タイプ
    , no_cont_freight_class         xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE        -- 契約外運賃区分
    , transfer_location_code        VARCHAR2(4)                                                   -- 振替先
    , description                   VARCHAR2(40)                                                  -- 摘要
    , small_amount_class            xxwsh_ship_method_v.small_amount_class%TYPE               -- 配送区分：小口区分
    , mixed_class                   xxwsh_ship_method_v.mixed_class%TYPE                      -- 配送区分：混載区分
    , ref_small_amount_class        VARCHAR2(1)                                               -- 配送区分：リーフ小口区分
    , post_distance                 xxwip_delivery_distance.post_distance%TYPE                -- 配送距離：車立距離
    , small_distance                xxwip_delivery_distance.small_distance%TYPE               -- 配送距離：小口距離
    , consolid_add_distance         xxwip_delivery_distance.consolid_add_distance%TYPE        -- 配送距離：混載割増距離
    , actual_distance               xxwip_delivery_distance.actual_distance%TYPE              -- 配送距離：実際距離
    , small_weight                  xxwip_delivery_company.small_weight%TYPE                  -- 運送業者：小口重量
    , pay_picking_amount            xxwip_delivery_company.pay_picking_amount%TYPE            -- 運送業者：支払ピッキング単価
    , qty                           xxwip_deliverys.qty1%TYPE                                 -- 個数
    , delivery_weight               xxwip_deliverys.delivery_weight1%TYPE                     -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
    , sum_pallet_weight             xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE        -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
  );
--
  -- 対象データ情報を格納するテーブル型の定義
  TYPE move_inf_tbl IS TABLE OF move_inf_rec INDEX BY PLS_INTEGER;
  gt_move_inf_tab   move_inf_tbl;
--
  -- 移動依頼/指示明細情報 抽出項目
  TYPE move_line_inf_rec IS RECORD(
      mov_hdr_id                  xxinv_mov_req_instr_lines.mov_hdr_id%TYPE         -- 移動ヘッダID
    , item_id                     xxinv_mov_req_instr_lines.item_id%TYPE            -- OPM品目ID
    , shipped_quantity            xxinv_mov_req_instr_lines.shipped_quantity%TYPE   -- 出荷実績数量
  );
  TYPE move_line_inf_tbl IS TABLE OF move_line_inf_rec INDEX BY PLS_INTEGER;
--
  -- *****************************
  -- * 運賃明細アドオン 関連
  -- *****************************
  -- 運賃明細アドオン 配送No 抽出項目
  TYPE delivno_deliv_line_rec IS RECORD(
      delivery_no         xxwip_delivery_lines.delivery_no%TYPE       -- 配送No
    , distance            xxwip_delivery_lines.actual_distance%TYPE   -- 最長距離（最大）
    , qty                 xxwip_delivery_lines.qty%TYPE               -- 個数（合計）
    , delivery_weight     xxwip_delivery_lines.delivery_weight%TYPE   -- 重量（合計）
  );
  TYPE delivno_deliv_line_tbl IS TABLE OF delivno_deliv_line_rec INDEX BY PLS_INTEGER;
  gt_delivno_deliv_line_tab   delivno_deliv_line_tbl;
--
  -- 運賃明細アドオン 抽出項目
  TYPE deliv_line_rec IS RECORD(
      delivery_company_code       xxwip_delivery_lines.delivery_company_code%TYPE   -- 運送業者
    , delivery_no                 xxwip_delivery_lines.delivery_no%TYPE             -- 配送No
    , invoice_no                  xxwip_delivery_lines.invoice_no%TYPE              -- 送り状No
    , payments_judgment_classe    xxwip_delivery_lines.payments_judgment_classe%TYPE-- 支払判断区分
    , ship_date                   xxwip_delivery_lines.ship_date%TYPE               -- 出庫日
    , arrival_date                xxwip_delivery_lines.arrival_date%TYPE            -- 到着日
    , judgement_date              xxwip_delivery_lines.judgement_date%TYPE          -- 判断日
    , goods_classe                xxwip_delivery_lines.goods_classe%TYPE            -- 商品区分
    , mixed_code                  xxwip_delivery_lines.mixed_code%TYPE              -- 混載区分
    , dellivary_classe            xxwip_delivery_lines.dellivary_classe%TYPE        -- 配送区分
    , whs_code                    xxwip_delivery_lines.whs_code%TYPE                -- 代表出庫倉庫コード
    , code_division               xxwip_delivery_lines.code_division%TYPE           -- 代表配送先コード区分
    , shipping_address_code       xxwip_delivery_lines.shipping_address_code%TYPE   -- 代表配送先コード
    , order_type                  xxwip_delivery_lines.order_type%TYPE              -- 代表タイプ
    , weight_capacity_class       xxwip_delivery_lines.weight_capacity_class%TYPE   -- 重量容積区分
    , actual_distance             xxwip_delivery_lines.actual_distance%TYPE         -- 最長実際距離
    , outside_contract            xxwip_delivery_lines.outside_contract%TYPE        -- 契約外区分
    , description                 xxwip_delivery_lines.description%TYPE             -- 振替先
    , consolid_qty                xxwip_deliverys.consolid_qty%TYPE                 -- 混載数
    , small_weight                xxwip_delivery_company.small_weight%TYPE          -- 小口重量
    , pay_picking_amount          xxwip_delivery_company.pay_picking_amount%TYPE    -- 支払ピッキング単価
    , shipping_expenses           xxwip_delivery_charges.shipping_expenses%TYPE     -- 運送費
    , leaf_consolid_add           xxwip_delivery_charges.leaf_consolid_add%TYPE     -- リーフ混載割増
    , consolid_surcharge          xxwip_deliverys.consolid_surcharge%TYPE           -- 混載割増金額
    , picking_charge              xxwip_deliverys.picking_charge%TYPE               -- ピッキング料
  );
--
  TYPE deliv_line_tbl IS TABLE OF deliv_line_rec INDEX BY PLS_INTEGER;
  gt_deliv_line_tab   deliv_line_tbl;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
--
  -- 配車解除対象データ 抽出項目
  TYPE carcan_info_rec IS RECORD(
      results_type    VARCHAR2(1)                              -- タイプ
    , request_no      xxwsh_order_headers_all.request_no%TYPE  -- 依頼No（移動番号）
  );
--
  --  配車解除対象データ情報を格納するテーブル型の定義
  TYPE carcan_info_tbl IS TABLE OF carcan_info_rec INDEX BY PLS_INTEGER;
  gt_carcan_info_tab   carcan_info_tbl;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
  -- PL/SQL表型
  -- 運賃明細アドオンID
  TYPE line_deliv_lines_id_type   IS TABLE OF xxwip_delivery_lines.delivery_lines_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE line_request_no_type       IS TABLE OF xxwip_delivery_lines.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 送り状No
  TYPE line_invoice_no_type       IS TABLE OF xxwip_delivery_lines.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送No
  TYPE line_deliv_no_type         IS TABLE OF xxwip_delivery_lines.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- リーフ小口区分
  TYPE line_small_lot_cls_type    IS TABLE OF xxwip_delivery_lines.small_lot_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- 運送業者
  TYPE line_deliv_cmpny_cd_type   IS TABLE OF xxwip_delivery_lines.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 出庫倉庫コード
  TYPE line_whs_code_type         IS TABLE OF xxwip_delivery_lines.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送区分
  TYPE line_delliv_cls_type       IS TABLE OF xxwip_delivery_lines.dellivary_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送先コード区分
  TYPE line_code_division_type    IS TABLE OF xxwip_delivery_lines.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送先コード
  TYPE line_ship_addr_cd_type     IS TABLE OF xxwip_delivery_lines.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払判断区分
  TYPE line_pay_judg_cls_type     IS TABLE OF xxwip_delivery_lines.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 出庫日
  TYPE line_ship_date_type        IS TABLE OF xxwip_delivery_lines.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 到着日
  TYPE line_arrival_date_type     IS TABLE OF xxwip_delivery_lines.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 報告日
  TYPE line_report_date_type      IS TABLE OF xxwip_delivery_lines.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 判断日
  TYPE line_judg_date_type        IS TABLE OF xxwip_delivery_lines.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE line_goods_cls_type        IS TABLE OF xxwip_delivery_lines.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量容積区分
  TYPE line_weight_cap_cls_type   IS TABLE OF xxwip_delivery_lines.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- 距離
  TYPE line_ditnc_type            IS TABLE OF xxwip_delivery_lines.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 実際距離
  TYPE line_actual_dstnc_type     IS TABLE OF xxwip_delivery_lines.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 個数
  TYPE line_qty_type              IS TABLE OF xxwip_delivery_lines.qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量
  TYPE line_deliv_weight_type     IS TABLE OF xxwip_delivery_lines.delivery_weight%TYPE
  INDEX BY BINARY_INTEGER;
  -- タイプ
  TYPE line_order_type_type       IS TABLE OF xxwip_delivery_lines.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- 混載区分
  TYPE line_mixed_code_type       IS TABLE OF xxwip_delivery_lines.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 契約外区分
  TYPE line_outside_cntrct_type   IS TABLE OF xxwip_delivery_lines.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替先
  TYPE line_trans_locat_type      IS TABLE OF xxwip_delivery_lines.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- 摘要
  TYPE line_description_type      IS TABLE OF xxwip_delivery_lines.description%TYPE
  INDEX BY BINARY_INTEGER;
--
  -- 運賃明細アドオン 登録用変数定義
  i_line_deliv_lines_id_tab   line_deliv_lines_id_type;     -- 運賃明細アドオンID
  i_line_request_no_tab       line_request_no_type;         -- 依頼No
  i_line_invoice_no_tab       line_invoice_no_type;         -- 送り状No
  i_line_deliv_no_tab         line_deliv_no_type;           -- 配送No
  i_line_small_lot_cls_tab    line_small_lot_cls_type;      -- リーフ小口区分
  i_line_deliv_cmpny_cd_tab   line_deliv_cmpny_cd_type;     -- 運送業者
  i_line_whs_code_tab         line_whs_code_type;           -- 出庫倉庫コード
  i_line_delliv_cls_tab       line_delliv_cls_type;         -- 配送区分
  i_line_code_division_tab    line_code_division_type;      -- 配送先コード区分
  i_line_ship_addr_cd_tab     line_ship_addr_cd_type;       -- 配送先コード
  i_line_pay_judg_cls_tab     line_pay_judg_cls_type;       -- 支払判断区分
  i_line_ship_date_tab        line_ship_date_type;          -- 出庫日
  i_line_arrival_date_tab     line_arrival_date_type;       -- 到着日
  i_line_report_date_tab      line_report_date_type;        -- 報告日
  i_line_judg_date_tab        line_judg_date_type;          -- 判断日
  i_line_goods_cls_tab        line_goods_cls_type;          -- 商品区分
  i_line_weight_cap_cls_tab   line_weight_cap_cls_type;     -- 重量容積区分
  i_line_ditnc_tab            line_ditnc_type;              -- 距離
  i_line_actual_dstnc_tab     line_actual_dstnc_type;       -- 実際距離
  i_line_qty_tab              line_qty_type;                -- 個数
  i_line_deliv_weight_tab     line_deliv_weight_type;       -- 重量
  i_line_order_tab_tab        line_order_type_type;         -- タイプ
  i_line_mixed_code_tab       line_mixed_code_type;         -- 混載区分
  i_line_outside_cntrct_tab   line_outside_cntrct_type;     -- 契約外区分
  i_line_trans_locat_tab      line_trans_locat_type;        -- 振替先
  i_line_description_tab      line_description_type;        -- 摘要
--
  -- 運賃明細アドオン 再計算更新用変数定義
  us_line_request_no_tab       line_request_no_type;         -- 依頼No
  us_line_invoice_no_tab       line_invoice_no_type;         -- 送り状No
  us_line_deliv_no_tab         line_deliv_no_type;           -- 配送No
  us_line_small_lot_cls_tab    line_small_lot_cls_type;      -- リーフ小口区分
  us_line_deliv_cmpny_cd_tab   line_deliv_cmpny_cd_type;     -- 運送業者
  us_line_whs_code_tab         line_whs_code_type;           -- 出庫倉庫コード
  us_line_delliv_cls_tab       line_delliv_cls_type;         -- 配送区分
  us_line_code_division_tab    line_code_division_type;      -- 配送先コード区分
  us_line_ship_addr_cd_tab     line_ship_addr_cd_type;       -- 配送先コード
  us_line_pay_judg_cls_tab     line_pay_judg_cls_type;       -- 支払判断区分
  us_line_ship_date_tab        line_ship_date_type;          -- 出庫日
  us_line_arrival_date_tab     line_arrival_date_type;       -- 到着日
  us_line_judg_date_tab        line_judg_date_type;          -- 判断日
  us_line_goods_cls_tab        line_goods_cls_type;          -- 商品区分
  us_line_weight_cap_cls_tab   line_weight_cap_cls_type;     -- 重量容積区分
  us_line_ditnc_tab            line_ditnc_type;              -- 距離
  us_line_actual_dstnc_tab     line_actual_dstnc_type;       -- 実際距離
  us_line_qty_tab              line_qty_type;                -- 個数
  us_line_deliv_weight_tab     line_deliv_weight_type;       -- 重量
  us_line_order_tab_tab        line_order_type_type;         -- タイプ
  us_line_mixed_code_tab       line_mixed_code_type;         -- 混載区分
  us_line_outside_cntrct_tab   line_outside_cntrct_type;     -- 契約外区分
  us_line_trans_locat_tab      line_trans_locat_type;        -- 振替先
  us_line_description_tab      line_description_type;        -- 摘要
--
  -- 運賃明細アドオン 摘要更新用変数定義
  ut_line_request_no_tab       line_request_no_type;         -- 依頼No
  ut_line_description_tab      line_description_type;        -- 摘要
--
  -- *****************************
  -- * 運賃ヘッダアドオン 関連
  -- *****************************
  -- PL/SQL表型
  -- 運賃ヘッダーアドオンID
  TYPE head_deliv_head_id_type        IS TABLE OF xxwip_deliverys.deliverys_header_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 運送業者
  TYPE head_deliv_cmpny_cd_type       IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送No
  TYPE head_deliv_no_type             IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 送り状No
  TYPE head_invoice_no_type           IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払請求区分
  TYPE head_p_b_classe_type           IS TABLE OF xxwip_deliverys.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払判断区分
  TYPE head_pay_judg_cls_type         IS TABLE OF xxwip_deliverys.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 出庫日
  TYPE head_ship_date_type            IS TABLE OF xxwip_deliverys.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 到着日
  TYPE head_arrival_date_type         IS TABLE OF xxwip_deliverys.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 報告日
  TYPE head_report_date_type          IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 判断日
  TYPE head_judg_date_type            IS TABLE OF xxwip_deliverys.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE head_goods_cls_type            IS TABLE OF xxwip_deliverys.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 混載区分
  TYPE head_mixed_cd_type             IS TABLE OF xxwip_deliverys.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求運賃
  TYPE head_charg_amount_type         IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 契約運賃
  TYPE head_contract_rate_type        IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- 差額
  TYPE head_balance_type              IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 合計
  TYPE head_total_amount_type         IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 諸料金
  TYPE head_many_rate_type            IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- 最長距離
  TYPE head_distance_type             IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送区分
  TYPE head_deliv_cls_type            IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 代表出庫倉庫コード
  TYPE head_whs_cd_type               IS TABLE OF xxwip_deliverys.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 代表配送先コード区分
  TYPE head_cd_dvsn_type              IS TABLE OF xxwip_deliverys.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- 代表配送先コード
  TYPE head_ship_addr_cd_type         IS TABLE OF xxwip_deliverys.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 個数１
  TYPE head_qty1_type                 IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- 個数２
  TYPE head_qty2_type                 IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量１
  TYPE head_deliv_wght1_type          IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量２
  TYPE head_deliv_wght2_type          IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- 混載割増金額
  TYPE head_cnsld_srhrg_type          IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- 最長実際距離
  TYPE head_actual_ditnc_type         IS TABLE OF xxwip_deliverys.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 通行料
  TYPE head_cong_chrg_type            IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ピッキング料
  TYPE head_pick_charge_type          IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- 混載数
  TYPE head_consolid_qty_type         IS TABLE OF xxwip_deliverys.consolid_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- 代表タイプ
  TYPE head_order_type_type           IS TABLE OF xxwip_deliverys.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量容積区分
  TYPE head_wigh_cpcty_cls_type       IS TABLE OF xxwip_deliverys.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- 契約外区分
  TYPE head_out_cont_type             IS TABLE OF xxwip_deliverys.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- 差異区分
  TYPE head_output_flag_type          IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払確定区分
  TYPE head_defined_flag_type         IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払確定戻
  TYPE head_return_flag_type          IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 画面更新有無区分
  TYPE head_fm_upd_flg_type           IS TABLE OF xxwip_deliverys.form_update_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替先
  TYPE head_trans_lcton_type          IS TABLE OF xxwip_deliverys.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- 外部業者変更回数
  TYPE head_out_up_cnt_type           IS TABLE OF xxwip_deliverys.outside_up_count%TYPE
  INDEX BY BINARY_INTEGER;
  -- 運賃摘要
  TYPE head_description_type          IS TABLE OF xxwip_deliverys.description%TYPE
  INDEX BY BINARY_INTEGER;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
  -- 配車タイプ
  TYPE head_dispatch_type_type        IS TABLE OF xxwip_deliverys.dispatch_type%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
  -- 運賃ヘッダアドオン 登録用変数定義
  i_head_deliv_head_id_tab      head_deliv_head_id_type;   -- 運賃ヘッダーアドオンID
  i_head_deliv_cmpny_cd_tab     head_deliv_cmpny_cd_type;  -- 運送業者
  i_head_deliv_no_tab           head_deliv_no_type;        -- 配送No
  i_head_invoice_no_tab         head_invoice_no_type;      -- 送り状No
  i_head_p_b_classe_tab         head_p_b_classe_type;      -- 支払請求区分
  i_head_pay_judg_cls_tab       head_pay_judg_cls_type;    -- 支払判断区分
  i_head_ship_date_tab          head_ship_date_type;       -- 出庫日
  i_head_arrival_date_tab       head_arrival_date_type;    -- 到着日
  i_head_report_date_tab        head_report_date_type;     -- 報告日
  i_head_judg_date_tab          head_judg_date_type;       -- 判断日
  i_head_goods_cls_tab          head_goods_cls_type;       -- 商品区分
  i_head_mixed_cd_tab           head_mixed_cd_type;        -- 混載区分
  i_head_charg_amount_tab       head_charg_amount_type;    -- 請求運賃
  i_head_contract_rate_tab      head_contract_rate_type;   -- 契約運賃
  i_head_balance_tab            head_balance_type;         -- 差額
  i_head_total_amount_tab       head_total_amount_type;    -- 合計
  i_head_many_rate_tab          head_many_rate_type;       -- 諸料金
  i_head_distance_tab           head_distance_type;        -- 最長距離
  i_head_deliv_cls_tab          head_deliv_cls_type;       -- 配送区分
  i_head_whs_cd_tab             head_whs_cd_type;          -- 代表出庫倉庫コード
  i_head_cd_dvsn_tab            head_cd_dvsn_type;         -- 代表配送先コード区分
  i_head_ship_addr_cd_tab       head_ship_addr_cd_type;    -- 代表配送先コード
  i_head_qty1_tab               head_qty1_type;            -- 個数１
  i_head_qty2_tab               head_qty2_type;            -- 個数２
  i_head_deliv_wght1_tab        head_deliv_wght1_type;     -- 重量１
  i_head_deliv_wght2_tab        head_deliv_wght2_type;     -- 重量２
  i_head_cnsld_srhrg_tab        head_cnsld_srhrg_type;     -- 混載割増金額
  i_head_actual_ditnc_tab       head_actual_ditnc_type;    -- 最長実際距離
  i_head_cong_chrg_tab          head_cong_chrg_type;       -- 通行料
  i_head_pick_charge_tab        head_pick_charge_type;     -- ピッキング料
  i_head_consolid_qty_tab       head_consolid_qty_type;    -- 混載数
  i_head_order_type_tab         head_order_type_type;      -- 代表タイプ
  i_head_wigh_cpcty_cls_tab     head_wigh_cpcty_cls_type;  -- 重量容積区分
  i_head_out_cont_tab           head_out_cont_type;        -- 契約外区分
  i_head_output_flag_tab        head_output_flag_type;     -- 差異区分
  i_head_defined_flag_tab       head_defined_flag_type;    -- 支払確定区分
  i_head_return_flag_tab        head_return_flag_type;     -- 支払確定戻
  i_head_fm_upd_flg_tab         head_fm_upd_flg_type;      -- 画面更新有無区分
  i_head_trans_lcton_tab        head_trans_lcton_type;     -- 振替先
  i_head_out_up_cnt_tab         head_out_up_cnt_type;      -- 外部業者変更回数
  i_head_description_tab        head_description_type;     -- 運賃摘要
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
  i_head_dispatch_type_tab        head_dispatch_type_type;     -- 配車タイプ
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
  -- 運賃ヘッダアドオン 更新用変数定義
  u_head_deliv_cmpny_cd_tab     head_deliv_cmpny_cd_type;  -- 運送業者
  u_head_deliv_no_tab           head_deliv_no_type;        -- 配送No
  u_head_invoice_no_tab         head_invoice_no_type;      -- 送り状No
  u_head_pay_judg_cls_tab       head_pay_judg_cls_type;    -- 支払判断区分
  u_head_ship_date_tab          head_ship_date_type;       -- 出庫日
  u_head_arrival_date_tab       head_arrival_date_type;    -- 到着日
  u_head_judg_date_tab          head_judg_date_type;       -- 判断日
  u_head_goods_cls_tab          head_goods_cls_type;       -- 商品区分
  u_head_mixed_cd_tab           head_mixed_cd_type;        -- 混載区分
  u_head_contract_rate_tab      head_contract_rate_type;   -- 契約運賃
  u_head_balance_tab            head_balance_type;         -- 差額
  u_head_total_amount_tab       head_total_amount_type;    -- 合計
  u_head_distance_tab           head_distance_type;        -- 最長距離
  u_head_deliv_cls_tab          head_deliv_cls_type;       -- 配送区分
  u_head_whs_cd_tab             head_whs_cd_type;          -- 代表出庫倉庫コード
  u_head_cd_dvsn_tab            head_cd_dvsn_type;         -- 代表配送先コード区分
  u_head_ship_addr_cd_tab       head_ship_addr_cd_type;    -- 代表配送先コード
  u_head_qty1_tab               head_qty1_type;            -- 個数１
  u_head_deliv_wght1_tab        head_deliv_wght1_type;     -- 重量１
  u_head_cnsld_srhrg_tab        head_cnsld_srhrg_type;     -- 混載割増金額
  u_head_actual_ditnc_tab       head_actual_ditnc_type;    -- 最長実際距離
  u_head_pick_charge_tab        head_pick_charge_type;     -- ピッキング料
  u_head_consolid_qty_tab       head_consolid_qty_type;    -- 混載数
  u_head_order_type_tab         head_order_type_type;      -- 代表タイプ
  u_head_wigh_cpcty_cls_tab     head_wigh_cpcty_cls_type;  -- 重量容積区分
  u_head_out_cont_tab           head_out_cont_type;        -- 契約外区分
  u_head_trans_lcton_tab        head_trans_lcton_type;     -- 振替先
  u_head_output_flag_tab        head_output_flag_type;     -- 差異区分
  u_head_defined_flag_tab       head_defined_flag_type;    -- 支払確定区分
  u_head_return_flag_tab        head_return_flag_type;     -- 支払確定戻
--
  -- 運賃ヘッダアドオン 削除用変数定義
  d_head_deliv_no_tab           head_deliv_no_type;        -- 配送No
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
--
  --  配車解除 制御用変数定義
  carcan_request_no_tab       line_request_no_type;      -- 依頼No
  carcan_deliv_no_tab         line_deliv_no_type;        -- 配送No
  u_can_request_no_tab        line_request_no_type;      -- 依頼No（更新用）
  d_can_deliv_no_tab          line_deliv_no_type;        -- 配送No（削除用）
  -- 伝票なし配車 解除
  d_slip_head_deliv_no_tab    head_deliv_no_type;        -- 配送No（削除用）
--
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
  -- *****************************
  -- * 配車配送計画 関連
  -- *****************************
  -- 配車配送計画 抽出項目
  TYPE carriers_schedule_rec IS RECORD(
    -- 運送業者
      delivery_company_code  xxwsh_carriers_schedule.result_freight_carrier_code%TYPE
    -- 配送No
    , delivery_no            xxwsh_carriers_schedule.delivery_no%TYPE
    -- 出庫日
    , ship_date              xxwsh_carriers_schedule.shipped_date%TYPE
    -- 到着日
    , arrival_date           xxwsh_carriers_schedule.arrival_date%TYPE
    -- 配送区分
    , dellivary_classe       xxwsh_carriers_schedule.result_shipping_method_code%TYPE
    -- 代表出庫倉庫コード
    , whs_code               xxwsh_carriers_schedule.deliver_from%TYPE
    -- 代表配送先コード区分
    , code_division          xxwsh_carriers_schedule.deliver_to_code_class%TYPE
    -- 代表配送先コード
    , shipping_address_code  xxwsh_carriers_schedule.deliver_to%TYPE
    -- 重量容積区分
    , weight_capacity_class  xxwsh_carriers_schedule.weight_capacity_class%TYPE
    -- 支払判断区分
    , payments_judgment_classe xxwip_deliverys.payments_judgment_classe%TYPE
    -- 判断日
    , judgement_date         xxwip_deliverys.judgement_date%TYPE
    -- 混載区分
    , mixed_code             xxwip_deliverys.mixed_code%TYPE
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
    , transaction_type      xxwsh_carriers_schedule.transaction_type%TYPE -- 処理種別（配車）
    , prod_class            xxwip_deliverys.goods_classe%TYPE             -- 商品区分
    , non_slip_class        xxwsh_carriers_schedule.non_slip_class%TYPE   -- 伝票なし配車区分
    , slip_number           xxwip_deliverys.invoice_no%TYPE               -- 送り状No
    , small_quantity        xxwsh_carriers_schedule.small_quantity%TYPE   -- 小口個数
    , small_amount_class    xxwsh_ship_method_v.small_amount_class%TYPE   -- 小口区分
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
  );
--
  TYPE carriers_schedule_tbl IS TABLE OF carriers_schedule_rec INDEX BY PLS_INTEGER;
  gt_carriers_schedule_tab   carriers_schedule_tbl;
--
  -- *****************************
  -- * 洗替 関連
  -- *****************************
  -- 洗替時 運賃明細アドオン 抽出項目
  TYPE exch_deliv_line_rec IS RECORD(
      request_no             xxwip_delivery_lines.request_no%TYPE                -- 依頼No
    , small_lot_class        xxwip_delivery_lines.small_lot_class%TYPE           -- リーフ小口区分
    , goods_classe           xxwip_delivery_lines.goods_classe%TYPE              -- 商品区分
    , weight_capacity_class  xxwip_delivery_lines.weight_capacity_class%TYPE     -- 重量容積区分
    , qty                    xxwip_delivery_lines.qty%TYPE                       -- 個数
    , delivery_weight        xxwip_delivery_lines.delivery_weight%TYPE           -- 重量
    , mixed_code             xxwip_delivery_lines.mixed_code%TYPE                -- 混載区分
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
    , judgement_date         xxwip_delivery_lines.judgement_date%TYPE            -- 判断日
    , distance               xxwip_delivery_lines.distance%TYPE                  -- 距離
    , xdl_actual_distance    xxwip_delivery_lines.actual_distance%TYPE           -- 実際距離
    , dellivary_classe       xxwip_delivery_lines.dellivary_classe%TYPE          -- 配送区分
    , distance_chk           VARCHAR2(1)                                         -- 配送距離フラグ
    , company_chk            VARCHAR2(1)                                         -- 運送業者フラグ
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
    , post_distance          xxwip_delivery_distance.post_distance%TYPE          -- 車立距離
    , small_distance         xxwip_delivery_distance.small_distance%TYPE         -- 小口距離
    , consolid_add_distance  xxwip_delivery_distance.consolid_add_distance%TYPE  -- 混載距離
    , actual_distance        xxwip_delivery_distance.actual_distance%TYPE        -- 実際距離
    , small_weight           xxwip_delivery_company.small_weight%TYPE            -- 小口重量
  );
--
  TYPE exch_deliv_line_tbl IS TABLE OF exch_deliv_line_rec INDEX BY PLS_INTEGER;
  gt_exch_deliv_line_tab   exch_deliv_line_tbl;
--
  -- 洗替 運賃明細アドオン 更新用変数定義
  ue_line_request_no_tab       line_request_no_type;         -- 依頼No
  ue_line_ditnc_tab            line_ditnc_type;              -- 距離
  ue_line_actual_dstnc_tab     line_actual_dstnc_type;       -- 実際距離
  ue_line_deliv_weight_tab     line_deliv_weight_type;       -- 重量
--
  -- 洗替 運賃明細アドオン 配送No 抽出項目
  TYPE exch_delivno_line_rec IS RECORD(
      delivery_no         xxwip_delivery_lines.delivery_no%TYPE       -- 配送No
    , distance            xxwip_delivery_lines.distance%TYPE          -- 最長距離（最大）
    , actual_distance     xxwip_delivery_lines.actual_distance%TYPE   -- 実際距離
    , delivery_weight     xxwip_delivery_lines.delivery_weight%TYPE   -- 重量（合計）
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 start *----------*
    , qty                      xxwip_delivery_lines.qty%TYPE          -- 数量（合計）
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 end   *----------*
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
    , invoice_no               xxwip_delivery_lines.invoice_no%TYPE               -- 送り状No
    , payments_judgment_classe xxwip_delivery_lines.payments_judgment_classe%TYPE -- 支払判断区分
    , ship_date                xxwip_delivery_lines.ship_date%TYPE                -- 出庫日
    , arrival_date             xxwip_delivery_lines.arrival_date%TYPE             -- 入庫日
    , judgement_date           xxwip_delivery_lines.judgement_date%TYPE           -- 判断日
    , mixed_code               xxwip_delivery_lines.mixed_code%TYPE               -- 混載区分
    , dellivary_classe         xxwip_delivery_lines.dellivary_classe%TYPE         -- 配送区分
    , whs_code                 xxwip_delivery_lines.whs_code%TYPE                 -- 出庫倉庫コード
    , code_division            xxwip_delivery_lines.code_division%TYPE            -- 配送先コード区分
    , shipping_address_code    xxwip_delivery_lines.shipping_address_code%TYPE    -- 配送先コード
    , order_type               xxwip_delivery_lines.order_type%TYPE               -- タイプ
    , outside_contract         xxwip_delivery_lines.outside_contract%TYPE         -- 契約外区分
    , transfer_location        xxwip_delivery_lines.transfer_location%TYPE        -- 振替先
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
  );
  TYPE exch_delivno_line_tbl IS TABLE OF exch_delivno_line_rec INDEX BY PLS_INTEGER;
  gt_exch_delivno_line_tab   exch_delivno_line_tbl;
--
  -- 洗替 運賃ヘッダアドオン 更新用変数定義
  ue_head_deliv_no_tab           head_deliv_no_type;        -- 配送No
  ue_head_distance_tab           head_distance_type;        -- 最長距離
  ue_head_deliv_wght1_tab        head_deliv_wght1_type;     -- 重量１
  ue_head_actual_ditnc_tab       head_actual_ditnc_type;    -- 最長実際距離
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 start *----------*
  ue_head_actual_qty1_tab        head_qty1_type;            -- 数量１
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 end   *----------*
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
  ue_head_invoice_no_tab         head_invoice_no_type;      -- 送り状No
  ue_head_pay_judg_cls_tab       head_pay_judg_cls_type;    -- 支払判断区分
  ue_head_ship_date_tab          head_ship_date_type;       -- 出庫日
  ue_head_arrival_date_tab       head_arrival_date_type;    -- 到着日
  ue_head_judg_date_tab          head_judg_date_type;       -- 判断日
  ue_head_mixed_cd_tab           head_mixed_cd_type;        -- 混載区分
  ue_head_deliv_cls_tab          head_deliv_cls_type;       -- 配送区分
  ue_head_whs_cd_tab             head_whs_cd_type;          -- 代表出庫倉庫コード
  ue_head_cd_dvsn_tab            head_cd_dvsn_type;         -- 代表配送先コード区分
  ue_head_ship_addr_cd_tab       head_ship_addr_cd_type;    -- 代表配送先コード
  ue_head_order_type_tab         head_order_type_type;      -- 代表タイプ
  ue_head_out_cont_tab           head_out_cont_type;        -- 契約外区分
  ue_head_trans_lcton_tab        head_trans_lcton_type;     -- 振替先
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
  -- 洗替時 運賃ヘッダアドオン 抽出項目
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
/*****
  TYPE exch_deliv_rec IS RECORD(
      delivery_company_code xxwip_deliverys.delivery_company_code%TYPE  -- 運送業者
    , delivery_no           xxwip_deliverys.delivery_no%TYPE            -- 配送No
    , p_b_classe            xxwip_deliverys.p_b_classe%TYPE             -- 支払請求区分
    , judgement_date        xxwip_deliverys.judgement_date%TYPE         -- 判断日
    , goods_classe          xxwip_deliverys.goods_classe%TYPE           -- 商品区分
    , mixed_code            xxwip_deliverys.mixed_code%TYPE             -- 混載区分
    , charged_amount        xxwip_deliverys.charged_amount%TYPE         -- 請求運賃
    , many_rate             xxwip_deliverys.many_rate%TYPE              -- 諸料金
    , distance              xxwip_deliverys.distance%TYPE               -- 最長距離
    , delivery_classe       xxwip_deliverys.delivery_classe%TYPE        -- 配送区分
    , qty1                  xxwip_deliverys.qty1%TYPE                   -- 個数１
    , delivery_weight1      xxwip_deliverys.delivery_weight1%TYPE       -- 重量１
    , consolid_surcharge    xxwip_deliverys.consolid_surcharge%TYPE     -- 混載割増金額
    , consolid_qty          xxwip_deliverys.consolid_qty%TYPE           -- 混載数
    , output_flag           xxwip_deliverys.output_flag%TYPE            -- 差異区分
    , defined_flag          xxwip_deliverys.defined_flag%TYPE           -- 支払確定区分
    , return_flag           xxwip_deliverys.return_flag%TYPE            -- 支払確定戻
    , pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE -- 運送：支払ピッキング単価
    , shipping_expenses     xxwip_delivery_charges.shipping_expenses%TYPE  -- 運賃：運送費
    , leaf_consolid_add     xxwip_delivery_charges.leaf_consolid_add%TYPE  -- 運賃：リーフ混載割増
--2008/08/04 Add ↓
    , actual_distance       xxwip_deliverys.actual_distance%TYPE        -- 最長実際距離
    , whs_code              xxwip_deliverys.whs_code%TYPE               -- 代表出庫倉庫コード
    , code_division         xxwip_deliverys.code_division%TYPE          -- 代表配送先コード区分
    , shipping_address_code xxwip_deliverys.shipping_address_code%TYPE  -- 代表配送先コード
    , dispatch_type         xxwip_deliverys.dispatch_type%TYPE          -- 配車タイプ
--2008/08/04 Add ↑
  );
*****/
  -- 洗替時 運賃ヘッダアドオン 抽出項目
  TYPE exch_deliv_rec IS RECORD(
      delivery_company_code xxwip_deliverys.delivery_company_code%TYPE  -- 運送業者
    , delivery_no           xxwip_deliverys.delivery_no%TYPE            -- 配送No
    , p_b_classe            xxwip_deliverys.p_b_classe%TYPE             -- 支払請求区分
    , ship_date             xxwip_deliverys.ship_date%TYPE              -- 出庫日
    , judgement_date        xxwip_deliverys.judgement_date%TYPE         -- 判断日
    , goods_classe          xxwip_deliverys.goods_classe%TYPE           -- 商品区分
    , mixed_code            xxwip_deliverys.mixed_code%TYPE             -- 混載区分
    , charged_amount        xxwip_deliverys.charged_amount%TYPE         -- 請求運賃
    , many_rate             xxwip_deliverys.many_rate%TYPE              -- 諸料金
    , distance              xxwip_deliverys.distance%TYPE               -- 最長距離
    , delivery_classe       xxwip_deliverys.delivery_classe%TYPE        -- 配送区分
    , qty1                  xxwip_deliverys.qty1%TYPE                   -- 個数１
    , delivery_weight1      xxwip_deliverys.delivery_weight1%TYPE       -- 重量１
    , consolid_surcharge    xxwip_deliverys.consolid_surcharge%TYPE     -- 混載割増金額
    , consolid_qty          xxwip_deliverys.consolid_qty%TYPE           -- 混載数
    , output_flag           xxwip_deliverys.output_flag%TYPE            -- 差異区分
    , defined_flag          xxwip_deliverys.defined_flag%TYPE           -- 支払確定区分
    , return_flag           xxwip_deliverys.return_flag%TYPE            -- 支払確定戻
    , actual_distance       xxwip_deliverys.actual_distance%TYPE        -- 最長実際距離
    , whs_code              xxwip_deliverys.whs_code%TYPE               -- 代表出庫倉庫コード
    , code_division         xxwip_deliverys.code_division%TYPE          -- 代表配送先コード区分
    , shipping_address_code xxwip_deliverys.shipping_address_code%TYPE  -- 代表配送先コード
    , dispatch_type         xxwip_deliverys.dispatch_type%TYPE          -- 配車タイプ
    , picking_charge        xxwip_deliverys.picking_charge%TYPE         -- 支払ピッキング料
    , contract_rate         xxwip_deliverys.contract_rate%TYPE          -- 契約運賃
    , last_update_date      xxwip_deliverys.last_update_date%TYPE       -- 最終更新日
    , pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE      -- 運送：支払ピッキング単価
    , pay_change_flg        xxwip_delivery_company.pay_change_flg%TYPE          -- 運送：支払変更フラグ
    , small_amount_class    xxwsh_ship_method_v.small_amount_class%TYPE         -- 配送区分：小口区分
    , post_distance         xxwip_delivery_distance.post_distance%TYPE          -- 配送：車立距離
    , small_distance        xxwip_delivery_distance.small_distance%TYPE         -- 配送：小口距離
    , consolid_add_distance xxwip_delivery_distance.consolid_add_distance%TYPE  -- 配送：混載距離
    , dis_actual_distance   xxwip_delivery_distance.actual_distance%TYPE        -- 配送：実際距離
    , distance_change_flg   xxwip_delivery_distance.change_flg%TYPE             -- 配送：変更フラグ
    , shipping_expenses     xxwip_delivery_charges.shipping_expenses%TYPE       -- 運賃：運送費
    , leaf_consolid_add     xxwip_delivery_charges.leaf_consolid_add%TYPE       -- 運賃：リーフ混載割増
    , charg_shp_change_flg  xxwip_delivery_charges.change_flg%TYPE              -- 運賃：変更フラグ
    , charg_lrf_change_flg  xxwip_delivery_charges.change_flg%TYPE              -- 運賃：変更フラグ
  );
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
  TYPE exch_deliv_tbl IS TABLE OF exch_deliv_rec INDEX BY PLS_INTEGER;
  gt_exch_deliv_tab   exch_deliv_tbl;
--
  -- 洗替時 運賃ヘッダアドオン 更新用変数定義
  ueh_head_deliv_no_tab           head_deliv_no_type;         -- 配送No
  ueh_head_contract_rate_tab      head_contract_rate_type;    -- 契約運賃
  ueh_head_balance_tab            head_balance_type;          -- 差額
  ueh_head_total_amount_tab       head_total_amount_type;     -- 合計
  ueh_head_cnsld_srhrg_tab        head_cnsld_srhrg_type;      -- 混載割増金額
  ueh_head_pick_charge_tab        head_pick_charge_type;      -- ピッキング料
  ueh_head_output_flag_tab        head_output_flag_type;      -- 差異区分
  ueh_head_defined_flag_tab       head_defined_flag_type;     -- 支払確定区分
  ueh_head_return_flag_tab        head_return_flag_type;      -- 支払確定戻
--2008/08/04 Add ↓
  ueh_head_distance_type_tab      head_distance_type;         -- 最長距離
  ueh_head_actual_ditnc_type_tab  head_actual_ditnc_type;     -- 最長実際距離
--2008/08/04 Add ↑
--
  -- 洗替時 運賃ヘッダアドオン 削除用変数定義
  deh_head_deliv_no_tab           head_deliv_no_type;          -- 配送No
--
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） START #####
  -- 削除データ格納
  TYPE t_delete_data_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_delete_data_msg     t_delete_data_msg ;
  gn_delete_data_idx     NUMBER := 0 ;
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） END   #####
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_debug_flg           VARCHAR2(1);        -- デバッグフラグ
--
  gd_sysdate             DATE;              -- システム日付
  gn_user_id             NUMBER;            -- ユーザID
  gn_login_id            NUMBER;            -- 最終更新ログイン
  gn_conc_request_id     NUMBER;            -- 要求ID
  gn_prog_appl_id        NUMBER;            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id     NUMBER;            -- コンカレント・プログラムID
--
  gd_last_process_date   DATE;              -- 前回処理日付
  gv_closed_day          VARCHAR2(1);       -- 締日判定
  gd_target_date         DATE;              -- 締め前日付
--
  gn_deliv_line_ins_cnt      NUMBER := 0;            -- 運賃明細アドオン登録件数
  gn_deliv_ins_cnt           NUMBER := 0;            -- 運賃ヘッダアドオン登録件数
  gn_deliv_del_cnt           NUMBER := 0;            -- 運賃ヘッダアドオン登録件数
--
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
  gv_prod_div            VARCHAR2(1);       -- 商品区分
  gv_con_no_deliv        VARCHAR2(1);       -- コンカレントNo
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
--
  /**********************************************************************************
   * Procedure Name   : chk_param_proc
   * Description      : パラメータチェック処理(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param_proc(
    iv_exchange_type   IN         VARCHAR2,     -- 洗替区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param_proc'; -- プログラム名
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
    ln_count NUMBER;   -- チェック用カウンター
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- チェック用カウンターの初期化
    ln_count := 0;
--
    -- 入力パラメータの存在チェック
    SELECT COUNT(1) CNT                -- カウント
    INTO   ln_count
    FROM   xxcmn_lookup_values_v xlv   -- クイックコード情報VIEW
    WHERE  xlv.lookup_type = 'XXCMN_YESNO'
    AND    xlv.lookup_code = iv_exchange_type
    AND    ROWNUM          = 1;
--
    -- 洗い替え区分が存在しない場合
    IF (ln_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                            gv_xxcmn_msg_para,
                                            gv_tkn_parameter,
                                            gv_exchange_type,
                                            gv_tkn_value,
                                           iv_exchange_type);
      lv_errbuf := lv_errmsg;
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
  END chk_param_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_init
   * Description      : 関連データ取得(A-2,3)
   ***********************************************************************************/
  PROCEDURE get_init(
    iv_exchange_type IN         VARCHAR2,     -- 洗替区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
    iv_prod_div      IN         VARCHAR2,     -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_init'; -- プログラム名
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
    lv_close_type VARCHAR2(1);
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ****************************************************
    -- プロファイル：支払運賃データ自動作成 デバッグフラグ
    -- ****************************************************
    gv_debug_flg := FND_PROFILE.VALUE(gv_prof_debug_flg);
    -- プロファイルが取得できない場合はエラー
    IF (gv_debug_flg IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            gv_prof_debug_flg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_sysdate          := SYSDATE;                    -- システム日時
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ログインユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ログインID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- コンカレント要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
    -- 入力項目.商品区分をグローバル変数に格納
    gv_prod_div         := iv_prod_div;                -- 商品区分
--
    -- 商品区分からコンカレントNo取得
   IF ( gv_prod_div = gv_prod_class_lef ) THEN
     gv_con_no_deliv := gv_con_no_deliv_lef;  -- リーフ
   ELSE
     gv_con_no_deliv := gv_con_no_deliv_drk;  -- ドリンク
   END IF;
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
    -- **************************************************
    -- *** 運賃計算用コントロールより前回処理日付を取得
    -- **************************************************
    BEGIN
      SELECT xdc.last_process_date    -- 前回処理日付
      INTO   gd_last_process_date
      FROM   xxwip_deliverys_ctrl xdc -- 運賃計算用コントロールアドオン
      WHERE  xdc.concurrent_no = gv_con_no_deliv
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_notfnd,
                                              gv_tkn_table,
                                              gv_deliverys_ctrl,
                                              gv_tkn_key,
                                              gv_con_no_deliv);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN   --*** データ複数取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_toomny,
                                              gv_tkn_table,
                                              gv_deliverys_ctrl,
                                              gv_tkn_key,
                                              gv_con_no_deliv);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN lock_expt THEN       --*** ロック取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                              gv_xxwip_msg_lock_err,
                                              gv_tkn_table,
                                              gv_deliverys_ctrl);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** 運賃用締日設定
    -- **************************************************
    -- 前月運賃締め後 判定
    xxwip_common3_pkg.check_lastmonth_close(
      lv_close_type,   -- 締め区分(Y:締日前、N:締日後)
      lv_errbuf,       -- エラー・メッセージ
      lv_retcode,      -- リターン・コード
      lv_errmsg);      -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 締め前日付設定
    IF (lv_close_type = gv_ktg_yes) THEN
      -- システム日付の前月の初日を設定
      gd_target_date := ADD_MONTHS(FND_DATE.STRING_TO_DATE(
                          TO_CHAR(gd_sysdate, 'YYYYMM') || '01', 'YYYYMMDD'), -1);
--
    ELSIF (lv_close_type = gv_ktg_no) THEN
      -- システム日付の初日を設定
      gd_target_date := FND_DATE.STRING_TO_DATE(TO_CHAR(gd_sysdate, 'YYYYMM') || '01', 'YYYYMMDD');
    END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_init：前回処理日時：' || 
                                      TO_CHAR(gd_last_process_date, 'YYYY/MM/DD HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_init：締日        ：' || 
                                      TO_CHAR(gd_target_date, 'YYYY/MM/DD HH24:MI:SS'));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_init;
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_lock
   * Description      : ロック取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_deliv_lock(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lock'; -- プログラム名
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
    lb_retcd          BOOLEAN;
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
    -- **************************************************
    -- *** テーブルロック処理(運賃ヘッダアドオン)
    -- **************************************************
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_xxwip_msg_kbn,
                                              'xxwip_deliverys');
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                            gv_xxwip_msg_lock_err,
                                            gv_tkn_table,
                                            gv_deliverys);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** テーブルロック処理(運賃明細アドオン)
    -- **************************************************
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_xxwip_msg_kbn,
                                              'xxwip_delivery_lines');
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                            gv_xxwip_msg_lock_err,
                                            gv_tkn_table,
                                            gv_delivery_lines);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
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
  END get_deliv_lock;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
  /**********************************************************************************
   * Procedure Name   : get_delivmst_lock
   * Description      : ロック取得(運賃関連マスタ)
   ***********************************************************************************/
  PROCEDURE get_delivmst_lock(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lock'; -- プログラム名
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
    lb_retcd          BOOLEAN;
--
    -- *** ローカル・カーソル ***
    --運賃用運送業者マスタ
    CURSOR get_xdco_cur
    IS
      SELECT  xdco.delivery_company_id AS delivery_company_id
      FROM    xxwip_delivery_company xdco
      WHERE   xdco.pay_change_flg = gv_target_y  -- 支払変更フラグ
      FOR UPDATE NOWAIT
      ;
--
    -- 配送距離マスタ
    CURSOR get_xddi_cur
    IS
      SELECT  xdd.delivery_distance_id AS delivery_distance_id
      FROM    xxwip_delivery_distance xdd
      WHERE   xdd.change_flg     = gv_target_y      -- 変更フラグ
      FOR UPDATE NOWAIT
      ;
--
    -- 運賃マスタ
    CURSOR get_xdch_cur
    IS
      SELECT  xdch.delivery_charges_id AS delivery_charges_id
      FROM    xxwip_delivery_charges xdch
      WHERE   xdch.p_b_classe    = gv_pay
      AND     xdch.change_flg    = gv_target_y      -- 変更フラグ
      FOR UPDATE NOWAIT
      ;
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
    -- **************************************************
    -- *** ロック取得（運賃用運送業者マスタ）
    -- **************************************************
      BEGIN
        <<get_xdco_loop>>
        FOR loop_cnt IN get_xdco_cur LOOP
          EXIT;
        END LOOP get_xdco_loop;
      EXCEPTION
        --*** ロック取得エラー ***
        WHEN lock_expt THEN
          -- エラーメッセージ取得
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                                gv_xxwip_msg_lock_err,
                                                gv_tkn_table,
                                                gv_delivery_company);
          lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    -- **************************************************
    -- *** ロック取得（配送距離マスタ）
    -- **************************************************
      BEGIN
        <<get_xddi_loop>>
        FOR loop_cnt IN get_xddi_cur LOOP
          EXIT;
        END LOOP get_xddi_loop;
      EXCEPTION
        --*** ロック取得エラー ***
        WHEN lock_expt THEN
          -- エラーメッセージ取得
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                                gv_xxwip_msg_lock_err,
                                                gv_tkn_table,
                                                gv_delivery_distance);
          lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    -- **************************************************
    -- *** ロック取得（運賃マスタ）
    -- **************************************************
      BEGIN
        <<get_xdch_loop>>
        FOR loop_cnt IN get_xdch_cur LOOP
          EXIT;
        END LOOP get_xdch_loop;
      EXCEPTION
        --*** ロック取得エラー ***
        WHEN lock_expt THEN
          -- エラーメッセージ取得
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                                gv_xxwip_msg_lock_err,
                                                gv_tkn_table,
                                                gv_delivery_charges);
          lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
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
  END get_delivmst_lock;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
  /**********************************************************************************
   * Procedure Name   : get_order
   * Description      : 受注実績情報抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_order(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--

-- ##### 20081125 Ver.1.13 本番#104対応 START #####
    -- 受注実績情報 抽出
    /*SELECT  xoha.order_header_id                  -- 受注ヘッダアドオンID
          , xoha.request_no                       -- 依頼No
          , xoha.slip_number                      -- 送り状No
          , xoha.delivery_no                      -- 配送No
          , xoha.result_freight_carrier_code      -- 運送業者_実績
          , xoha.deliver_from                     -- 出荷元保管場所
          , xoha.result_shipping_method_code      -- 配送区分_実績
          , CASE xotv.shipping_shikyu_class       -- 配送コード区分
            WHEN gv_shipping THEN gv_code_ship    --   出荷支給区分 3：配送先
            WHEN gv_shikyu   THEN gv_code_shikyu  --                2：取引先
            END
-- ##### 20080625 Ver.1.2 支給配送先対応 START #####
--          , xoha.result_deliver_to                -- 出荷先_実績
          , CASE xotv.shipping_shikyu_class       -- 配送コード区分
            WHEN gv_shipping THEN xoha.result_deliver_to  -- 出荷先_実績
            WHEN gv_shikyu   THEN xoha.vendor_site_code   -- 取引先サイト
            END
-- ##### 20080625 Ver.1.2 支給配送先対応 END   #####
          , xdec.payments_judgment_classe         -- 支払判断区分(運賃)
          , xoha.shipped_date                     -- 出荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--  着荷日を設定、NULLの場合は着荷予定日を設定
--          , xoha.arrival_date                     -- 着荷日
          , NVL(xoha.arrival_date, xoha.schedule_arrival_date)  -- 着荷日(着荷予定日)
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
          , CASE xdec.payments_judgment_classe    -- 判断日
            WHEN gv_pay_judg_g THEN xoha.shipped_date -- 発日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--            WHEN gv_pay_judg_c THEN xoha.arrival_date -- 着日
            WHEN gv_pay_judg_c THEN NVL(xoha.arrival_date, xoha.schedule_arrival_date) -- 着日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
            END
          , xoha.prod_class                       -- 商品区分
          , xoha.weight_capacity_class            -- 重量容積区分
          , xoha.small_quantity                   -- 小口個数
          , CASE xotv.shipping_shikyu_class       -- タイプ
            WHEN gv_shipping  THEN gv_type_ship   --   １：出荷
            WHEN gv_shikyu    THEN gv_type_shikyu --   ２：支給
            END
          , xoha.no_cont_freight_class            -- 契約外運賃区分
          , xoha.transfer_location_code           -- 振替先
          , SUBSTRB(xoha.shipping_instructions, 1, 40) -- 出荷指示(40)
          , NULL                                  -- 小口区分
          , NULL                                  -- 混載区分
          , NULL                                  -- リーフ小口区分
          , NULL                                  -- 配送距離：車立距離
          , NULL                                  -- 配送距離：小口距離
          , NULL                                  -- 配送距離：混載割増距離
          , NULL                                  -- 配送距離：実際距離
          , NULL                                  -- 小口重量
          , NULL                                  -- 支払ピッキング単価
          , NULL                                  -- 個数
          , NULL                                  -- 重量
    BULK COLLECT INTO gt_order_inf_tab
    FROM  xxwsh_order_headers_all        xoha,      -- 受注ヘッダアドオン
          xxwsh_oe_transaction_types2_v  xotv,    -- 受注タイプ情報VIEW2
          xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
    WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
    AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
--
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--  着荷日が設定されていなくても、抽出対象とする。
-- （着荷予定日もしくは着荷日が設定されていることが前提）
    AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
      OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
--
    AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
    AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
    AND   xoha.delivery_no  IS NOT NULL                   -- 配送No
    AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
    AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
    AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
    AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
    AND   xoha.order_type_id       = xotv.transaction_type_id -- 受注タイプID
    AND   (
            ((xdec.payments_judgment_classe = gv_pay_judg_g)    -- 支払判断区分（発日）
            AND (xoha.shipped_date >=  gd_target_date))         -- 出荷日
          OR
            ((xdec.payments_judgment_classe = gv_pay_judg_c)    -- 支払判断区分（着日）
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--            AND (xoha.arrival_date >=  gd_target_date))         -- 着荷日
            AND (NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                             >=  gd_target_date)) -- 着荷日(着荷予定日)
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
          )
    AND (
-- ##### 20080625 Ver.1.2 支給配送先対応 START #####
--          (xotv.shipping_shikyu_class  = gv_shipping)         -- 出荷依頼
          ((xotv.shipping_shikyu_class  = gv_shipping)         -- 出荷依頼
          AND  (xoha.result_deliver_to  IS NOT NULL))          -- 出荷先_実績
-- ##### 20080625 Ver.1.2 支給配送先対応 END   #####
        OR
          ((xotv.shipping_shikyu_class  = gv_shikyu)            -- 支給依頼
          AND (xotv.auto_create_po_class = '0'))                -- 自動作成発注区分「NO」
        )
    AND (
          ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
          AND  (xoha.last_update_date <= gd_sysdate))
        OR (xoha.request_no IN (SELECT xola.request_no
                              FROM xxwsh_order_lines_all xola    -- 受注明細アドオン
                              WHERE (xola.last_update_date > gd_last_process_date)  -- 受注明細：前回処理日付
                              AND   (xola.last_update_date <= gd_sysdate)))
        );*/
        
    -- 受注実績情報 抽出
    SELECT
      order_info.order_header_id
     ,order_info.request_no
     ,order_info.slip_number
     ,order_info.delivery_no
     ,order_info.result_freight_carrier_code
     ,order_info.deliver_from
     ,order_info.result_shipping_method_code
     ,order_info.deliver_to_code_class
     ,order_info.result_deliver_to
     ,order_info.payments_judgment_classe
     ,order_info.shipped_date
     ,order_info.arrival_date
     ,order_info.judgement_date
     ,order_info.prod_class
     ,order_info.weight_capacity_class
     ,order_info.small_quantity
     ,order_info.order_type
     ,order_info.no_cont_freight_class
     ,order_info.transfer_location_code
     ,order_info.shipping_instructions
     ,order_info.small_amount_class
     ,order_info.mixed_class
     ,order_info.ref_small_amount_class
     ,order_info.post_distance
     ,order_info.small_distance
     ,order_info.consolid_add_distance
     ,order_info.actual_distance
     ,order_info.small_weight
     ,order_info.pay_picking_amount
     ,order_info.qty
     ,order_info.delivery_weight
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
     ,order_info.sum_pallet_weight
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
    BULK COLLECT INTO gt_order_inf_tab
    FROM (
      -- 着日基準_支給依頼
      SELECT /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- 受注ヘッダアドオンID
            , xoha.request_no                     request_no                   -- 依頼No
            , xoha.slip_number                    slip_number                  -- 送り状No
            , xoha.delivery_no                    delivery_no                  -- 配送No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- 運送業者_実績
            , xoha.deliver_from                   deliver_from                 -- 出荷元保管場所
            , xoha.result_shipping_method_code    result_shipping_method_code  -- 配送区分_実績
            , gv_code_shikyu                      deliver_to_code_class        -- 配送先コード区分
            , xoha.vendor_site_code               result_deliver_to            -- 出荷先_実績
            , xdec.payments_judgment_classe       payments_judgment_classe     -- 支払判断区分(運賃)
            , xoha.shipped_date                   shipped_date                 -- 出荷日
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- 着荷日(着荷予定日)
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) judgement_date  -- 判断日
            , xoha.prod_class                     prod_class                   -- 商品区分
            , xoha.weight_capacity_class          weight_capacity_class        -- 重量容積区分
-- ##### 20080717 Ver.1.15 本番#595対応 START #####
--            , xoha.small_quantity                 small_quantity               -- 小口個数
            , NVL(xoha.small_quantity, 0)           small_quantity               -- 小口個数
-- ##### 20080717 Ver.1.15 本番#595対応 END   #####
            , gv_type_shikyu                      order_type                   -- タイプ
            , xoha.no_cont_freight_class          no_cont_freight_class        -- 契約外運賃区分
            , xoha.transfer_location_code         transfer_location_code       -- 振替先
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- 出荷指示(40)
            , NULL                                small_amount_class           -- 小口区分
            , NULL                                mixed_class                  -- 混載区分
            , NULL                                ref_small_amount_class       -- リーフ小口区分
            , NULL                                post_distance                -- 配送距離：車立距離
            , NULL                                small_distance               -- 配送距離：小口距離
            , NULL                                consolid_add_distance        -- 配送距離：混載割増距離
            , NULL                                actual_distance              -- 配送距離：実際距離
            , NULL                                small_weight                 -- 小口重量
            , NULL                                pay_picking_amount           -- 支払ピッキング単価
            , NULL                                qty                          -- 個数
            , NULL                                delivery_weight              -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- 受注ヘッダアドオン
            oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
            xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
      WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
--    着荷日が設定されていなくても、抽出対象とする。
--   （着荷予定日もしくは着荷日が設定されていることが前提）
      AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
      AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
      AND   xoha.delivery_no  IS NOT NULL                   -- 配送No
      AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
      AND   xoha.order_type_id       = otta.transaction_type_id -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xoha.prod_class          = gv_prod_div                          -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xdec.payments_judgment_classe = gv_pay_judg_c    -- 支払判断区分（着日）
      AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                               >=  gd_target_date -- 着荷日(着荷予定日)
      AND   otta.attribute1  = gv_shikyu             -- 支給依頼
      AND   otta.attribute3 = '0'                     -- 自動作成発注区分「NO」
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- 積載重量合計の整数部が7桁以上の場合は出力しない
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- 着日基準_出荷依頼
      SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- 受注ヘッダアドオンID
            , xoha.request_no                     request_no                   -- 依頼No
            , xoha.slip_number                    slip_number                  -- 送り状No
            , xoha.delivery_no                    delivery_no                  -- 配送No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- 運送業者_実績
            , xoha.deliver_from                   deliver_from                 -- 出荷元保管場所
            , xoha.result_shipping_method_code    result_shipping_method_code  -- 配送区分_実績
            , gv_code_ship                        deliver_to_code_class        -- 配送先コード区分
            , xoha.result_deliver_to              result_deliver_to-- 出荷先_実績
            , xdec.payments_judgment_classe       payments_judgment_classe     -- 支払判断区分(運賃)
            , xoha.shipped_date                   shipped_date                 -- 出荷日
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- 着荷日(着荷予定日)
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) judgement_date   -- 判断日
            , xoha.prod_class                     prod_class                   -- 商品区分
            , xoha.weight_capacity_class          weight_capacity_class        -- 重量容積区分
-- ##### 20080717 Ver.1.15 本番#595対応 START #####
--            , xoha.small_quantity                 small_quantity               -- 小口個数
            , NVL(xoha.small_quantity, 0)           small_quantity               -- 小口個数
-- ##### 20080717 Ver.1.15 本番#595対応 END   #####
            , gv_type_ship                        order_type                   -- タイプ
            , xoha.no_cont_freight_class          no_cont_freight_class        -- 契約外運賃区分
            , xoha.transfer_location_code         transfer_location_code       -- 振替先
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- 出荷指示(40)
            , NULL                                small_amount_class           -- 小口区分
            , NULL                                mixed_class                  -- 混載区分
            , NULL                                ref_small_amount_class       -- リーフ小口区分
            , NULL                                post_distance                -- 配送距離：車立距離
            , NULL                                small_distance               -- 配送距離：小口距離
            , NULL                                consolid_add_distance        -- 配送距離：混載割増距離
            , NULL                                actual_distance              -- 配送距離：実際距離
            , NULL                                small_weight                 -- 小口重量
            , NULL                                pay_picking_amount           -- 支払ピッキング単価
            , NULL                                qty                          -- 個数
            , NULL                                delivery_weight              -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- 受注ヘッダアドオン
            oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
            xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
      WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
--    着荷日が設定されていなくても、抽出対象とする。
--   （着荷予定日もしくは着荷日が設定されていることが前提）
      AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
      AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
      AND   xoha.delivery_no  IS NOT NULL                   -- 配送No
      AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
      AND   xoha.order_type_id       = otta.transaction_type_id             -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xoha.prod_class          = gv_prod_div                          -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xdec.payments_judgment_classe = gv_pay_judg_c    -- 支払判断区分（着日）
      AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                               >=  gd_target_date -- 着荷日(着荷予定日)
      AND   otta.attribute1   = gv_shipping                       -- 出荷依頼
      AND   xoha.result_deliver_to  IS NOT NULL                             -- 出荷先_実績
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- 積載重量合計の整数部が7桁以上の場合は出力しない
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- 発日基準_支給依頼
      SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- 受注ヘッダアドオンID
            , xoha.request_no                     request_no                   -- 依頼No
            , xoha.slip_number                    slip_number                  -- 送り状No
            , xoha.delivery_no                    delivery_no                  -- 配送No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- 運送業者_実績
            , xoha.deliver_from                   deliver_from                 -- 出荷元保管場所
            , xoha.result_shipping_method_code    result_shipping_method_code  -- 配送区分_実績
            , gv_code_shikyu                      deliver_to_code_class        -- 配送先コード区分
            , xoha.vendor_site_code               result_deliver_to            -- 出荷先_実績
            , xdec.payments_judgment_classe       payments_judgment_classe     -- 支払判断区分(運賃)
            , xoha.shipped_date                   shipped_date                 -- 出荷日
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- 着荷日(着荷予定日)
            ,xoha.shipped_date                    judgement_date               -- 判断日
            , xoha.prod_class                     prod_class                   -- 商品区分
            , xoha.weight_capacity_class          weight_capacity_class        -- 重量容積区分
-- ##### 20080717 Ver.1.15 本番#595対応 START #####
--            , xoha.small_quantity                 small_quantity               -- 小口個数
            , NVL(xoha.small_quantity, 0)           small_quantity               -- 小口個数
-- ##### 20080717 Ver.1.15 本番#595対応 END   #####
            , gv_type_shikyu                      order_type                   -- タイプ
            , xoha.no_cont_freight_class          no_cont_freight_class        -- 契約外運賃区分
            , xoha.transfer_location_code         transfer_location_code       -- 振替先
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- 出荷指示(40)
            , NULL                                small_amount_class           -- 小口区分
            , NULL                                mixed_class                  -- 混載区分
            , NULL                                ref_small_amount_class       -- リーフ小口区分
            , NULL                                post_distance                -- 配送距離：車立距離
            , NULL                                small_distance               -- 配送距離：小口距離
            , NULL                                consolid_add_distance        -- 配送距離：混載割増距離
            , NULL                                actual_distance              -- 配送距離：実際距離
            , NULL                                small_weight                 -- 小口重量
            , NULL                                pay_picking_amount           -- 支払ピッキング単価
            , NULL                                qty                          -- 個数
            , NULL                                delivery_weight              -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- 受注ヘッダアドオン
            oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
            xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
      WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
--    着荷日が設定されていなくても、抽出対象とする。
--   （着荷予定日もしくは着荷日が設定されていることが前提）
      AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
      AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
      AND   xoha.delivery_no  IS NOT NULL                   -- 配送No
      AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
      AND   xoha.order_type_id       = otta.transaction_type_id -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xoha.prod_class          = gv_prod_div                          -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xdec.payments_judgment_classe = gv_pay_judg_g    -- 支払判断区分（発日）
      AND   xoha.shipped_date >=  gd_target_date             -- 出荷日
      AND   otta.attribute1  = gv_shikyu          -- 支給依頼
      AND   otta.attribute3 = '0'                  -- 自動作成発注区分「NO」
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- 積載重量合計の整数部が7桁以上の場合は出力しない
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- 発日基準_出荷依頼
      SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- 受注ヘッダアドオンID
            , xoha.request_no                     request_no                   -- 依頼No
            , xoha.slip_number                    slip_number                  -- 送り状No
            , xoha.delivery_no                    delivery_no                  -- 配送No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- 運送業者_実績
            , xoha.deliver_from                   deliver_from                 -- 出荷元保管場所
            , xoha.result_shipping_method_code    result_shipping_method_code  -- 配送区分_実績
            , gv_code_ship                        deliver_to_code_class        -- 配送先コード区分
            , xoha.result_deliver_to              result_deliver_to            -- 出荷先_実績
            , xdec.payments_judgment_classe       payments_judgment_classe     -- 支払判断区分(運賃)
            , xoha.shipped_date                   shipped_date                 -- 出荷日
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- 着荷日(着荷予定日)
            , xoha.shipped_date                   judgement_date               -- 判断日
            , xoha.prod_class                     prod_class                   -- 商品区分
            , xoha.weight_capacity_class          weight_capacity_class        -- 重量容積区分
-- ##### 20080717 Ver.1.15 本番#595対応 START #####
--            , xoha.small_quantity                 small_quantity               -- 小口個数
            , NVL(xoha.small_quantity, 0)           small_quantity               -- 小口個数
-- ##### 20080717 Ver.1.15 本番#595対応 END   #####
            ,gv_type_ship                         order_type                   -- タイプ
            , xoha.no_cont_freight_class          no_cont_freight_class        -- 契約外運賃区分
            , xoha.transfer_location_code         transfer_location_code       -- 振替先
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- 出荷指示(40)
            , NULL                                small_amount_class           -- 小口区分
            , NULL                                mixed_class                  -- 混載区分
            , NULL                                ref_small_amount_class       -- リーフ小口区分
            , NULL                                post_distance                -- 配送距離：車立距離
            , NULL                                small_distance               -- 配送距離：小口距離
            , NULL                                consolid_add_distance        -- 配送距離：混載割増距離
            , NULL                                actual_distance              -- 配送距離：実際距離
            , NULL                                small_weight                 -- 小口重量
            , NULL                                pay_picking_amount           -- 支払ピッキング単価
            , NULL                                qty                          -- 個数
            , NULL                                delivery_weight              -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- 受注ヘッダアドオン
            oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
            xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
      WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
--    着荷日が設定されていなくても、抽出対象とする。
--   （着荷予定日もしくは着荷日が設定されていることが前提）
      AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
      AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
      AND   xoha.delivery_no  IS NOT NULL                   -- 配送No
      AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
      AND   xoha.order_type_id       = otta.transaction_type_id -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xoha.prod_class          = gv_prod_div                          -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xdec.payments_judgment_classe = gv_pay_judg_g    -- 支払判断区分（発日）
      AND   xoha.shipped_date >=  gd_target_date             -- 出荷日
      AND   otta.attribute1  = gv_shipping        -- 出荷依頼
      AND   xoha.result_deliver_to  IS NOT NULL              -- 出荷先_実績
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- 積載重量合計の整数部が7桁以上の場合は出力しない
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      ) order_info
      ;
-- ##### 20081125 Ver.1.13 本番#104対応 END #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order：受注実績抽出件数：' || TO_CHAR(gt_order_inf_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_order;
--
  /**********************************************************************************
   * Procedure Name   : get_order_other
   * Description      : 受注関連情報抽出(A-6)
   ***********************************************************************************/
  PROCEDURE get_order_other(
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_other'; -- プログラム名
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
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- 配送区分
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- 配送距離
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- 運賃用運送業者
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
    -- 対象データ無の場合
    IF (gt_order_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<order_loop>>
    FOR ln_index IN  gt_order_inf_tab.FIRST.. gt_order_inf_tab.LAST LOOP
--
      -- **************************************************
      -- ***  配送区分情報取得(A-6)
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_order_inf_tab(ln_index).result_shipping_method_code, -- 配送区分
        gt_order_inf_tab(ln_index).judgement_date,              -- 判断日
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 小口区分設定
      gt_order_inf_tab(ln_index).small_amount_class := lr_ship_method_tab.small_amount_class;
      -- 混載区分設定
      gt_order_inf_tab(ln_index).mixed_class        := lr_ship_method_tab.mixed_class;
      -- リーフ小口区分設定（商品区分＝リーフ、小口区分＝小口）
      IF ((gt_order_inf_tab(ln_index).prod_class = gv_prod_class_lef)
        AND (gt_order_inf_tab(ln_index).small_amount_class = gv_small_sum_yes)) THEN
        -- YESを設定
        gt_order_inf_tab(ln_index).ref_small_amount_class := gv_ktg_yes;
--
      ELSE
        -- NOを設定
        gt_order_inf_tab(ln_index).ref_small_amount_class := gv_ktg_no;
      END IF;
--
      -- **************************************************
      -- ***  配送距離アドオンマスタ抽出(A-7)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_distance(
        gt_order_inf_tab(ln_index).prod_class,                    -- 商品区分
        gt_order_inf_tab(ln_index).result_freight_carrier_code,   -- 運送業者
        gt_order_inf_tab(ln_index).deliver_from,                  -- 出庫倉庫
        gt_order_inf_tab(ln_index).deliver_to_code_class ,        -- コード区分
        gt_order_inf_tab(ln_index).result_deliver_to,             -- 配送先コード
        gt_order_inf_tab(ln_index).judgement_date,                -- 判断日
        lr_delivery_distance_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 車立距離
      gt_order_inf_tab(ln_index).post_distance := lr_delivery_distance_tab.post_distance;
      -- 小口距離
      gt_order_inf_tab(ln_index).small_distance  := lr_delivery_distance_tab.small_distance;
      -- 混載割増距離
      gt_order_inf_tab(ln_index).consolid_add_distance  := 
                            lr_delivery_distance_tab.consolid_add_distance;
      -- 実際距離
      gt_order_inf_tab(ln_index).actual_distance := lr_delivery_distance_tab.actual_distance;
--
      -- **************************************************
      -- ***  運賃用運送業者アドオンマスタ抽出(A-8)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_company(
        gt_order_inf_tab(ln_index).prod_class,                  -- 商品区分
        gt_order_inf_tab(ln_index).result_freight_carrier_code, -- 運送業者
        gt_order_inf_tab(ln_index).judgement_date,              -- 判断日
        lr_delivery_company_tab,                                -- 運賃用運送業者レコード
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 小口重量
      gt_order_inf_tab(ln_index).small_weight       := lr_delivery_company_tab.small_weight;
      -- 支払ピッキング単価
      gt_order_inf_tab(ln_index).pay_picking_amount := lr_delivery_company_tab.pay_picking_amount;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：********** 受注関連情報抽出 **********：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：***** 依頼No   *****：' || gt_order_inf_tab(ln_index).request_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：***** 運送業者 *****：' || gt_order_inf_tab(ln_index).result_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：***** 配送No   *****：' || gt_order_inf_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：小口区分      ：' || gt_order_inf_tab(ln_index).small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：混載区分      ：' || gt_order_inf_tab(ln_index).mixed_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：リーフ小口区分：' || gt_order_inf_tab(ln_index).ref_small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：車立距離      ：' || TO_CHAR(gt_order_inf_tab(ln_index).post_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：小口距離      ：' || TO_CHAR(gt_order_inf_tab(ln_index).small_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：混載割増距離  ：' || TO_CHAR(gt_order_inf_tab(ln_index).consolid_add_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：実際距離      ：' || TO_CHAR(gt_order_inf_tab(ln_index).actual_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：小口重量          ：' || TO_CHAR(gt_order_inf_tab(ln_index).small_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other：支払ピッキング単価：' || TO_CHAR(gt_order_inf_tab(ln_index).pay_picking_amount));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP order_loop;
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
  END get_order_other;
--
  /**********************************************************************************
   * Procedure Name   : get_order_line
   * Description      : 受注明細アドオン抽出(A-9)
   ***********************************************************************************/
  PROCEDURE get_order_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_line'; -- プログラム名
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
    lt_order_line_inf_tab    order_line_inf_tbl;     --受注明細
--
    ln_item_id        xxcmn_item_mst2_v.item_id%TYPE;       -- 品目ID
    ln_num_of_cases   xxcmn_item_mst2_v.num_of_cases%TYPE;  -- ケース入り数
    ln_conv_unit      xxcmn_item_mst2_v.conv_unit%TYPE;     -- 入出庫換算単位
    ln_unit           xxcmn_item_mst2_v.unit%TYPE;          -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
    ln_capacity       xxcmn_item_mst2_v.capacity%TYPE;      -- 容積
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
--
    ln_qty                           xxwip_deliverys.qty1%TYPE;             -- 個数
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--    ln_delivery_weight               xxwip_deliverys.delivery_weight1%TYPE; -- 重量
    ln_delivery_weight               NUMBER;                                -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
    ln_sum_qty                       xxwip_deliverys.qty1%TYPE;             -- 個数（合計）
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--    ln_sum_delivery_weight           xxwip_deliverys.delivery_weight1%TYPE; -- 重量（合計）
    ln_sum_delivery_weight           NUMBER;                                -- 重量（合計）
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：********** 受注明細アドオン抽出 **********');
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    -- 対象データ無の場合
    IF (gt_order_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<order_loop>>
    FOR ln_index IN  gt_order_inf_tab.FIRST.. gt_order_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：********** 受注ヘッダアドオン抽出 **********：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：依頼No   ：' || gt_order_inf_tab(ln_index).request_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：運送業者 ：' || gt_order_inf_tab(ln_index).result_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：配送No   ：' || gt_order_inf_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  受注明細アドオン抽出(A-9)
      -- **************************************************
      -- 変数初期化
      lt_order_line_inf_tab.DELETE;
--
      SELECT  xola.order_header_id                  -- 受注ヘッダアドオンID
            , xola.shipping_item_code               -- 出荷品目
-- ##### 20080625 Ver.1.2 出荷実績数量NULL対応 START #####
/***
            , xola.shipped_quantity                 -- 出荷実績数量
***/
            , NVL(xola.shipped_quantity, 0)          -- 出荷実績数量
-- ##### 20080625 Ver.1.2 出荷実績数量NULL対応 END   #####
      BULK COLLECT INTO lt_order_line_inf_tab
      FROM  xxwsh_order_lines_all          xola     -- 受注明細アドオン
      WHERE xola.order_header_id = 
                gt_order_inf_tab(ln_index).order_header_id  -- 受注ヘッダアドオンID
      AND   NVL(xola.delete_flag, gv_ktg_no)  = gv_ktg_no;  -- 削除フラグ
--
      -- 合計値 初期化
      ln_sum_qty             := 0;  -- 個数（合計）
      ln_sum_delivery_weight := 0;  -- 重量（合計）
--
      -- 対象データ無の場合
      IF (lt_order_line_inf_tab.COUNT = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                      gv_xxcmn_msg_notfnd,
                                      gv_tkn_table,
                                      gv_order_headers_all,
                                      gv_tkn_key,
                                      gt_order_inf_tab(ln_index).order_header_id);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      <<order_line_loop>>
      FOR ln_line_index IN  lt_order_line_inf_tab.FIRST.. lt_order_line_inf_tab.LAST LOOP
--
        -- **************************************************
        -- ***  受注OPM品目情報VIEW抽出(A-10)
        -- **************************************************
        -- 変数初期化
        ln_num_of_cases := NULL;        -- ケース入り数
        ln_conv_unit    := NULL;        -- 入出庫換算単位
        ln_unit         := NULL;        -- 重量
--
        -- 入出庫換算単位、ケース入り数、重量 取得
        BEGIN
          SELECT ximv.item_id         -- 品目ID
               , ximv.num_of_cases    -- ケース入り数
               , ximv.conv_unit       -- 入出庫換算単位
               , ximv.unit            -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
               , ximv.capacity        -- 容積
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
          INTO   ln_item_id
               , ln_num_of_cases
               , ln_conv_unit
               , ln_unit
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
               , ln_capacity
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
          FROM   xxcmn_item_mst2_v    ximv    -- OPM品目情報VIEW2
          WHERE  ximv.item_no = 
                 lt_order_line_inf_tab(ln_line_index).shipping_item_code -- 品目コード
          AND    gt_order_inf_tab(ln_index).judgement_date >= ximv.start_date_active  -- 適用開始日
          AND    gt_order_inf_tab(ln_index).judgement_date <= ximv.end_date_active;   -- 適用終了日
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                          gv_xxcmn_msg_notfnd,
                                          gv_tkn_table,
                                          gv_item_mst2_v,
                                          gv_tkn_key,
                                          lt_order_line_inf_tab(ln_line_index).shipping_item_code);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                          gv_xxcmn_msg_toomny,
                                          gv_tkn_table,
                                          gv_item_mst2_v,
                                          gv_tkn_key,
                                          lt_order_line_inf_tab(ln_line_index).shipping_item_code);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- **************************************************
        -- ***  受注個数／重量算出(A-11)
        -- **************************************************
        -- 変数初期化
        ln_qty              := 0;
        ln_delivery_weight  := 0;
--
        -- *** 個数 算出 ***
        -- リーフ小口区分 ＝ Y の場合
        IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          -- 個数に小口個数を設定
          ln_qty := gt_order_inf_tab(ln_index).small_quantity;
--
        -- リーフ小口区分 ＝ N の場合
        ELSE
          -- 個数に deliv_rcv_ship_conv_qty の戻り値を設定
          ln_qty := xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                        lt_order_line_inf_tab(ln_line_index).shipping_item_code -- 品目コード
                      , lt_order_line_inf_tab(ln_line_index).shipped_quantity); -- 数量
        END IF;
--
        -- *** 重量 算出 ***
        -- リーフ小口区分 ＝ Y 且つ 重量容積区分 ＝ 容積の場合
        IF ((gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes )
          AND (gt_order_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          -- 上記算出の個数 × 小口重量
          ln_delivery_weight :=
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--                ln_qty * gt_order_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--                CEIL(ln_qty * gt_order_inf_tab(ln_index).small_weight);
                ln_qty * gt_order_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
--
        -- 上記以外
        ELSE
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
          -- 重量容積区分＝「容積」の場合
          IF (gt_order_inf_tab(ln_index).weight_capacity_class = gv_capacity) THEN
            -- 容積 × 出荷実績数量（切上）×1000000
            ln_delivery_weight :=
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--                  CEIL(ln_capacity * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000000);
                  ln_capacity * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000000;
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
--
          -- 重量容積区分＝「重量」の場合
          ELSE
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
            -- 重量 × 出荷実績数量（切上）
            ln_delivery_weight :=
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--                ROUND(ln_unit * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000);
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--                  CEIL(ln_unit * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000);
                  ln_unit * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000;
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
--
          END IF;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：********** 受注明細アドオン **********：' || TO_CHAR(ln_line_index));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：受注ヘッダアドオンID ：' || lt_order_line_inf_tab(ln_line_index).order_header_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：出荷品目             ：' || lt_order_line_inf_tab(ln_line_index).shipping_item_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：出荷実績数量         ：' || lt_order_line_inf_tab(ln_line_index).shipped_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：***** 条件 *****');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：リーフ小口区分：' || gt_order_inf_tab(ln_index).ref_small_amount_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：重量容積区分  ：' || gt_order_inf_tab(ln_index).weight_capacity_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：***** OPM品目 *****');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：品目ID        ：' || ln_item_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：ケース入り数  ：' || TO_CHAR(ln_num_of_cases));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：入出庫換算単位：' || ln_conv_unit);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：重量          ：' || TO_CHAR(ln_unit));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：容積          ：' || TO_CHAR(ln_capacity));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：***** 算出結果 *****');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：個数         ：' || TO_CHAR(ln_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：重量         ：' || TO_CHAR(ln_delivery_weight));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  受注個数／重量集計(A-12)
        -- **************************************************
        -- 個数（合計）
        -- リーフ小口区分 ＝ Y の場合
        IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          ln_sum_qty := ln_qty;
        ELSE
          ln_sum_qty := ln_sum_qty + ln_qty;
        END IF;
--
        -- 重量（合計）
        -- リーフ小口区分 ＝ Y 且つ 重量容積区分 ＝ 容積の場合
        IF ((gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes )
          AND (gt_order_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          ln_sum_delivery_weight := ln_delivery_weight;
        ELSE
          ln_sum_delivery_weight := ln_sum_delivery_weight + ln_delivery_weight;
        END IF;
--
      END LOOP order_line_loop;
--
      -- 合計（個数、重量）設定
      gt_order_inf_tab(ln_index).qty              := ln_sum_qty;
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--      gt_order_inf_tab(ln_index).delivery_weight  := ln_sum_delivery_weight;
--
      -- 重量容積区分＝「重量」・小口区分＝「車立」の場合
      IF   ((gt_order_inf_tab(ln_index).weight_capacity_class = gv_weight)
        AND (gt_order_inf_tab(ln_index).small_amount_class    = gv_small_sum_no)) THEN
        -- 明細重量をサマリし小数点以下第一を切上し、合計パレット重量を加算
        gt_order_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1)) + 
                                                     gt_order_inf_tab(ln_index).sum_pallet_weight ;
--
      -- 上記以外
      ELSE
        -- 明細重量をサマリし小数点以下第一を切上
        gt_order_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1));
      END IF;
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：********** 受注個数／重量集計 **********');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：個数（合計）：' || TO_CHAR(gt_order_inf_tab(ln_index).qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：重量（合計）：' || TO_CHAR(gt_order_inf_tab(ln_index).delivery_weight));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP order_loop;
--
  EXCEPTION
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
    WHEN func_inv_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
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
  END get_order_line;
--
  /**********************************************************************************
   * Procedure Name   : set_order_deliv_line
   * Description      : 受注運賃明細アドオンPL/SQL表格納(A-13)
   ***********************************************************************************/
  PROCEDURE set_order_deliv_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_deliv_line'; -- プログラム名
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
    lv_delivery_company_code  xxwip_delivery_lines.delivery_company_code%TYPE;  -- 運送業者
    lv_whs_code               xxwip_delivery_lines.whs_code%TYPE;               -- 出庫倉庫
    lv_shipping_address_code  xxwip_delivery_lines.shipping_address_code%TYPE;  -- 配送先コード
    lv_dellivary_classe       xxwip_delivery_lines.dellivary_classe%TYPE;       -- 配送区分
    ln_qty                    xxwip_delivery_lines.qty%TYPE;                    -- 個数
    ln_delivery_weight        xxwip_delivery_lines.delivery_weight%TYPE;        -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
    ld_ship_date              xxwip_delivery_lines.ship_date%TYPE;              -- 出荷日
    ld_arrival_date           xxwip_delivery_lines.arrival_date%TYPE;           -- 着荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
    lv_payments_judgment_classe   xxwip_delivery_lines.payments_judgment_classe%TYPE; -- 支払判断区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
    lv_delivery_no            xxwip_delivery_lines.delivery_no%TYPE;            -- 配送No
    ln_deli_cnt               NUMBER;
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
--
    ln_deliv_line_flg         VARCHAR2(1);      -- 受注明細アドオン 存在フラグ Y:有 N:無
--
    ln_line_insert_cnt        NUMBER;           -- 登録用PL/SQL表 件数
    ln_line_calc_update_cnt   NUMBER;           -- 再計算更新用PL/SQL表 件数
    ln_line_des_update_cnt    NUMBER;           -- 摘要登録用PL/SQL表 件数
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
    -- 件数初期化
    ln_line_insert_cnt      := 0 ;  -- 登録用PL/SQL表 件数
    ln_line_calc_update_cnt := 0 ;  -- 再計算更新用PL/SQL表 件数
    ln_line_des_update_cnt  := 0 ;  -- 摘要登録用PL/SQL表 件数
--
    -- 対象データ無の場合
    IF (gt_order_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<order_loop>>
    FOR ln_index IN  gt_order_inf_tab.FIRST.. gt_order_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：********** 受注運賃明細アドオンPL/SQL表格納 **********：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：依頼No   ：' || gt_order_inf_tab(ln_index).request_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：運送業者 ：' || gt_order_inf_tab(ln_index).result_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：配送No   ：' || gt_order_inf_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
      -- **************************************************
      -- ***  運賃ヘッダアドオン抽出
      -- **************************************************
      -- 存在フラグ初期化
      ln_deliv_line_flg := gv_ktg_yes;
--
      BEGIN
        SELECT  xwdl.delivery_company_code  -- 運送業者
              , xwdl.whs_code               -- 出庫倉庫
              , xwdl.shipping_address_code  -- 配送先コード
              , xwdl.dellivary_classe       -- 配送区分
              , xwdl.qty                    -- 個数
              , xwdl.delivery_weight        -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
              , xwdl.ship_date              -- 出荷日
              , xwdl.arrival_date           -- 着荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
              , xwdl.delivery_no            -- 配送No
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
              , payments_judgment_classe    -- 支払判断区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
        INTO    lv_delivery_company_code
              , lv_whs_code
              , lv_shipping_address_code
              , lv_dellivary_classe
              , ln_qty
              , ln_delivery_weight
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
              , ld_ship_date                -- 出荷日
              , ld_arrival_date             -- 着荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
              , lv_delivery_no              -- 配送No
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
              , lv_payments_judgment_classe   -- 支払判断区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
        FROM   xxwip_delivery_lines xwdl    -- 運賃明細アドオン
        WHERE  xwdl.request_no = gt_order_inf_tab(ln_index).request_no; -- 依頼No
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
          -- 存在フラグ Y を設定
          ln_deliv_line_flg := gv_ktg_no;
--
        WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                        gv_xxcmn_msg_toomny,
                                        gv_tkn_table,
                                        gv_delivery_lines,
                                        gv_tkn_key,
                                        gt_order_inf_tab(ln_index).request_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：********** 運賃ヘッダアドオン **********：' || ln_deliv_line_flg);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：運送業者     ：' || lv_delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：出庫倉庫     ：' || lv_whs_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：配送先コード ：' || lv_shipping_address_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：配送区分     ：' || lv_dellivary_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：個数         ：' || TO_CHAR(ln_qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：重量         ：' || TO_CHAR(ln_delivery_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：出荷日       ：' || TO_CHAR(ld_ship_date    ,'YYYY/MM/DD'));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：着荷日       ：' || TO_CHAR(ld_arrival_date ,'YYYY/MM/DD'));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：配送No       ：' || lv_delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：支払判断区分 ：' || lv_payments_judgment_classe);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
--
      -- **************************************************
      -- ***  配送Noの変更による削除処理
      -- **************************************************
      -- 運賃明細アドオンが存在する場合
      IF (ln_deliv_line_flg = gv_ktg_yes) THEN
        -- 運賃明細の配送Noと実績の配送Noが異なる場合
        IF (gt_order_inf_tab(ln_index).delivery_no <> lv_delivery_no) THEN
          -- 旧配送Noの件数取得
          BEGIN
            SELECT  COUNT(delivery_no)
            INTO    ln_deli_cnt
            FROM    xxwip_delivery_lines xwdl           -- 運賃明細アドオン
            WHERE   xwdl.delivery_no = lv_delivery_no;  -- 配送No
          END;
  --
          -- 旧配送Noが運賃明細に1件の場合
          -- 複数件の場合は混載、集約であるため、削除しない
          IF ( ln_deli_cnt = 1 ) THEN
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：配送組替 旧DELETE：' ||
                                                                  lv_delivery_no || '->' ||
                                          gt_order_inf_tab(ln_index).delivery_no);
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
            -- 運賃ヘッダより削除する
            BEGIN
              -- 対象配送Noを削除する
              DELETE FROM xxwip_deliverys
              WHERE delivery_no = lv_delivery_no;
            END;
          END IF;
        END IF;
      END IF;
--
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
--
      -- **************************************************
      -- ***  運賃明細アドオンにデータが存在しない場合
      -- **************************************************
      IF (ln_deliv_line_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line：運賃明細アドオン INSERT');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 登録用PL/SQL表 件数
        ln_line_insert_cnt  := ln_line_insert_cnt + 1;
--
        -- 運賃明細登録用PL/SQL表 設定
        -- 運賃明細アドオンID
        i_line_deliv_lines_id_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).order_header_id;
        -- 依頼No
        i_line_request_no_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).request_no;
        -- 送り状No
        i_line_invoice_no_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).slip_number;
        -- 配送No
        i_line_deliv_no_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).delivery_no;
        -- リーフ小口区分
        i_line_small_lot_cls_tab(ln_line_insert_cnt)   := 
                        gt_order_inf_tab(ln_index).ref_small_amount_class;
         -- 運送業者
        i_line_deliv_cmpny_cd_tab(ln_line_insert_cnt)  := 
                        gt_order_inf_tab(ln_index).result_freight_carrier_code;
        -- 出庫倉庫コード
        i_line_whs_code_tab(ln_line_insert_cnt)        := 
                        gt_order_inf_tab(ln_index).deliver_from;
         -- 配送区分
        i_line_delliv_cls_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).result_shipping_method_code;
        -- 配送先コード区分
        i_line_code_division_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).deliver_to_code_class;
        -- 配送先コード
        i_line_ship_addr_cd_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).result_deliver_to;
        -- 支払判断区分
        i_line_pay_judg_cls_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).payments_judgment_classe;
        -- 出庫日
        i_line_ship_date_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).shipped_date;  
        -- 到着日
        i_line_arrival_date_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).arrival_date;
        -- 報告日
        i_line_report_date_tab(ln_line_insert_cnt)  := NULL;
        -- 判断日
        i_line_judg_date_tab(ln_line_insert_cnt)  := gt_order_inf_tab(ln_index).judgement_date;
        -- 商品区分
        i_line_goods_cls_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).prod_class;
        -- 重量容積区分
        i_line_weight_cap_cls_tab(ln_line_insert_cnt)  := 
                      gt_order_inf_tab(ln_index).weight_capacity_class;
--
        -- リーフ小口区分 ＝ Yの場合
        IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
            -- 小口距離
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
-- 小口区分=「小口」は小口距離、「車立」は車立距離を設定
        -- 商品区分 ＝ リーフ   又は 
        -- 商品区分 ＝ ドリンク 且つ、混載区分 ＜＞ 混載 の場合
--        ELSIF (
--                  (gt_order_inf_tab(ln_index).prod_class = gv_prod_class_lef)
--                OR    
--                  ((gt_order_inf_tab(ln_index).prod_class = gv_prod_class_drk)
--                  AND (gt_order_inf_tab(ln_index).mixed_class <> gv_target_y))
--              ) THEN
          -- 車立距離
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance;
--
        -- 上記以外
--        ELSE
--
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
          -- 車立距離（明細へは混載割増距離を加算しない）
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance +
--                                                  gt_order_inf_tab(ln_index).consolid_add_distance;
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
        ELSE
          -- 小口区分＝「小口」の場合
          IF (gt_order_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
            -- 小口距離を設定
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
          -- 小口区分＝「車立」の場合
          ELSE
            -- 車立て距離を設定
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance;
          END IF;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
        END IF;
--
        -- 実際距離
        i_line_actual_dstnc_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).actual_distance;
        -- 個数
        i_line_qty_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).qty;
        -- 重量
        i_line_deliv_weight_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).delivery_weight;
        -- タイプ
        i_line_order_tab_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).order_type;
        -- 混載区分
        i_line_mixed_code_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).mixed_class;
        -- 契約外区分
        i_line_outside_cntrct_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).no_cont_freight_class;
        -- 振替先
        i_line_trans_locat_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).transfer_location_code;
        -- 摘要
        i_line_description_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).shipping_instructions;
--
      -- **************************************************
      -- ***  運賃明細アドオンにデータが存在する場合
      -- **************************************************
      ELSE
        -- **************************************************
        -- ***  登録されている内容より再計算が必要な場合
        -- **************************************************
        --   対象項目：運送業者、出庫倉庫、配送先コード、配送区分、配送No、個数、重量、出庫日、入庫日、支払判断区分
-- ##### 20090123 Ver.1.20 本番#1074 START #####
-- 更新時の条件をなくし、変更があった場合は更新するように修正
/*****
        IF ((gt_order_inf_tab(ln_index).result_freight_carrier_code  <> lv_delivery_company_code )
          OR (gt_order_inf_tab(ln_index).deliver_from                 <> lv_whs_code              )
          OR (gt_order_inf_tab(ln_index).result_deliver_to            <> lv_shipping_address_code )
          OR (gt_order_inf_tab(ln_index).result_shipping_method_code  <> lv_dellivary_classe      )
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
          OR (gt_order_inf_tab(ln_index).delivery_no                  <> lv_delivery_no           )
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
          OR (gt_order_inf_tab(ln_index).shipped_date  <>  ld_ship_date     )
          OR (gt_order_inf_tab(ln_index).arrival_date  <>  ld_arrival_date  )
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
          OR (gt_order_inf_tab(ln_index).payments_judgment_classe  <>  lv_payments_judgment_classe  )
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
          OR (gt_order_inf_tab(ln_index).qty                          <> ln_qty                   )
          OR (gt_order_inf_tab(ln_index).delivery_weight              <> ln_delivery_weight       )) THEN
*****/
-- ##### 20090123 Ver.1.20 本番#1074 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：運賃明細アドオン UPDATE 再計算');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 再計算更新用PL/SQL表 件数
          ln_line_calc_update_cnt   := ln_line_calc_update_cnt + 1;
--
          -- 運賃明細アドオン
          -- 依頼No
          us_line_request_no_tab(ln_line_calc_update_cnt) := 
                          gt_order_inf_tab(ln_index).request_no;
          -- 送り状No
          us_line_invoice_no_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).slip_number;
          -- 配送No
          us_line_deliv_no_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).delivery_no;
          -- リーフ小口区分
          us_line_small_lot_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).ref_small_amount_class;
          -- 運送業者
          us_line_deliv_cmpny_cd_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).result_freight_carrier_code;
          -- 出庫倉庫コード
          us_line_whs_code_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).deliver_from;
          -- 配送区分
          us_line_delliv_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).result_shipping_method_code;
          -- 配送先コード区分
          us_line_code_division_tab(ln_line_calc_update_cnt)  :=
                                          gt_order_inf_tab(ln_index).deliver_to_code_class;
          -- 配送先コード
          us_line_ship_addr_cd_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).result_deliver_to;
          -- 支払判断区分
          us_line_pay_judg_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).payments_judgment_classe;
          -- 出庫日
          us_line_ship_date_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).shipped_date;
          -- 到着日
          us_line_arrival_date_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).arrival_date;
          -- 判断日
          us_line_judg_date_tab(ln_line_calc_update_cnt)         := 
                                          gt_order_inf_tab(ln_index).judgement_date;
          -- 商品区分
          us_line_goods_cls_tab(ln_line_calc_update_cnt)  := 
                                          gt_order_inf_tab(ln_index).prod_class;
          -- 重量容積区分
          us_line_weight_cap_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).weight_capacity_class;
--
          -- リーフ小口区分 ＝ Yの場合
          IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
            -- 小口距離
            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
-- 小口区分=「小口」は小口距離、「車立」は車立距離を設定
          -- 商品区分 ＝ リーフ   又は 
          -- 商品区分 ＝ ドリンク 且つ、混載区分 ＜＞ 混載 の場合
--          ELSIF (
--                    (gt_order_inf_tab(ln_index).prod_class = gv_prod_class_lef)
--                  OR    
--                    ((gt_order_inf_tab(ln_index).prod_class = gv_prod_class_drk)
--                    AND (gt_order_inf_tab(ln_index).mixed_class <> gv_target_y))
--                ) THEN
            -- 車立距離
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).post_distance;
--
          -- 上記以外
--          ELSE
--
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
          -- 車立距離（明細へは混載割増距離を加算しない）
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := 
--                                    gt_order_inf_tab(ln_index).post_distance +
--                                    gt_order_inf_tab(ln_index).consolid_add_distance;
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
          ELSE
            -- 小口区分＝「小口」の場合
            IF (gt_order_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
              -- 小口距離を設定
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
            -- 小口区分＝「車立」の場合
            ELSE
              -- 車立て距離を設定
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).post_distance;
            END IF;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
          END IF;
--
          -- 実際距離
          us_line_actual_dstnc_tab(ln_line_calc_update_cnt) := 
                                            gt_order_inf_tab(ln_index).actual_distance;
          -- 個数
          us_line_qty_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).qty;
          -- 重量
          us_line_deliv_weight_tab(ln_line_calc_update_cnt) := 
                                            gt_order_inf_tab(ln_index).delivery_weight;
          -- タイプ
          us_line_order_tab_tab(ln_line_calc_update_cnt)  := gt_order_inf_tab(ln_index).order_type;
          -- 混載区分
          us_line_mixed_code_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).mixed_class;
          -- 契約外区分
          us_line_outside_cntrct_tab(ln_line_calc_update_cnt) := 
                                                gt_order_inf_tab(ln_index).no_cont_freight_class;
          -- 振替先
          us_line_trans_locat_tab(ln_line_calc_update_cnt) := 
                                                gt_order_inf_tab(ln_index).transfer_location_code;
          -- 摘要
          us_line_description_tab(ln_line_calc_update_cnt) := 
                                                gt_order_inf_tab(ln_index).shipping_instructions;
--
        -- **************************************************
        -- ***  登録されている内容より再計算が必要でない場合
        -- **************************************************
-- ##### 20090123 Ver.1.20 本番#1074 START #####
-- 適用のみの更新処理は廃止する
/*****
        ELSE
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line：運賃明細アドオン UPDATE 摘要');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 摘要登録用PL/SQL表 件数
          ln_line_des_update_cnt := ln_line_des_update_cnt + 1;
--
          -- 運賃明細アドオン
          -- 依頼No
          ut_line_request_no_tab(ln_line_des_update_cnt)  := gt_order_inf_tab(ln_index).request_no;
          -- 摘要
          ut_line_description_tab(ln_line_des_update_cnt) := 
                                gt_order_inf_tab(ln_index).shipping_instructions;
--
        END IF;
*****/
-- ##### 20090123 Ver.1.20 本番#1074 END   #####
      END IF;
--
    END LOOP order_loop;
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
  END set_order_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : get_move
   * Description      : 移動実績情報抽出(A-14)
   ***********************************************************************************/
  PROCEDURE get_move(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- ##### 20081125 Ver.1.13 本番#104対応 START #####
    -- 移動実績情報 抽出
    /*SELECT    xmrih.mov_hdr_id                                    -- 移動ヘッダID
            , xmrih.mov_num                                       -- 移動番号
            , xmrih.slip_number                                   -- 送り状No
            , xmrih.delivery_no                                   -- 配送No
            , xmrih.actual_freight_carrier_code                   -- 運送業者_実績
            , xmrih.shipped_locat_code                            -- 出庫元保管場所
            , xmrih.actual_shipping_method_code                   -- 配送区分
            , gv_code_move                                        -- 配送先コード区分（３：倉庫）
            , xmrih.ship_to_locat_code                            -- 入庫先保管場所
            , xdec.payments_judgment_classe                       -- 支払判断区分(運賃)
            , xmrih.actual_ship_date                              -- 出庫実績日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--            , xmrih.actual_arrival_date                           -- 入庫実績日
            , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) -- 入庫実績日(入庫予定日)
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
            , CASE xdec.payments_judgment_classe                  -- 判断日
              WHEN gv_pay_judg_g  THEN xmrih.actual_ship_date     --   発日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--              WHEN gv_pay_judg_c  THEN xmrih.actual_arrival_date  --   着日
              WHEN gv_pay_judg_c  THEN NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date)  -- 着日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
              END
            , xmrih.item_class                                    -- 商品区分
            , xmrih.weight_capacity_class                         -- 重量容積区分
            , xmrih.small_quantity                                -- 小口個数
            , xmrih.sum_quantity                                  -- 合計数量
            , gv_type_move                                        -- タイプ（３：移動）
            , xmrih.no_cont_freight_class                         -- 契約外運賃区分
            , NULL                                                -- 振替先
            , SUBSTRB(xmrih.description, 1, 40)                   -- 摘要（40）
            , NULL                                                -- 配送区分：小口区分
            , NULL                                                -- 配送区分：混載区分
            , NULL                                                -- 配送区分：リーフ小口区分
            , NULL                                                -- 配送距離：車立距離
            , NULL                                                -- 配送距離：小口距離
            , NULL                                                -- 配送距離：混載割増距離
            , NULL                                                -- 配送距離：実際距離
            , NULL                                                -- 運送業者：小口重量
            , NULL                                                -- 運送業者：支払ピッキング単価
            , NULL                                                -- 個数
            , NULL                                                -- 重量
    BULK COLLECT INTO gt_move_inf_tab
    FROM  xxinv_mov_req_instr_headers    xmrih,   -- 移動依頼/指示ヘッダ(アドオン)
          xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
    WHERE xmrih.actual_ship_date IS NOT NULL            -- 出庫実績日
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
--
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--    AND   xmrih.actual_arrival_date IS NOT NULL         -- 入庫実績日
    AND  (xmrih.actual_arrival_date IS NOT NULL           -- 入庫実績日
      OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- 入庫予定日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
--
    AND   xmrih.actual_shipping_method_code IS NOT NULL -- 配送区分_実績
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
    AND   xmrih.actual_freight_carrier_code IS NOT NULL -- 運送業者_実績
    AND   xmrih.delivery_no IS NOT NULL                 -- 配送No
    AND   xmrih.item_class = xdec.goods_classe                              -- 商品区分
    AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- 運送業者
    AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- 適用開始日
    AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- 適用終了日
    AND   (
            ((xdec.payments_judgment_classe = gv_pay_judg_g)      -- 支払判断区分（発日）
            AND (xmrih.actual_ship_date    >=  gd_target_date))   -- 出庫実績日
          OR
            ((xdec.payments_judgment_classe = gv_pay_judg_c)      -- 支払判断区分（着日）
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--            AND (xmrih.actual_arrival_date >=  gd_target_date))   -- 入庫実績日
            AND (NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                              >=  gd_target_date)) -- 入庫実績日(入庫予定日)
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
          )
    AND (
          ((xmrih.last_update_date    > gd_last_process_date)   -- 移動ヘッダ：前回処理日付
          AND (xmrih.last_update_date <= gd_sysdate))
        OR (xmrih.mov_hdr_id IN (SELECT xmril.mov_hdr_id
                              FROM xxinv_mov_req_instr_lines  xmril                 -- 移動依頼/指示明細(アドオン)
                              WHERE (xmril.last_update_date > gd_last_process_date) -- 移動明細：前回処理日付
                              AND   (xmril.last_update_date <= gd_sysdate)))
        )*/
--
    -- 移動実績情報 抽出
    SELECT
      move_info.mov_hdr_id
     ,move_info.mov_num
     ,move_info.slip_number
     ,move_info.delivery_no
     ,move_info.actual_freight_carrier_code
     ,move_info.shipped_locat_code
     ,move_info.shipping_method_code
     ,move_info.deliver_to_code_class
     ,move_info.ship_to_locat_code
     ,move_info.payments_judgment_classe
     ,move_info.actual_ship_date
     ,move_info.actual_arrival_date
     ,move_info.judgement_date
     ,move_info.item_class
     ,move_info.weight_capacity_class
     ,move_info.small_quantity
     ,move_info.sum_quantity
     ,move_info.order_type
     ,move_info.no_cont_freight_class
     ,move_info.transfer_location_code
     ,move_info.description
     ,move_info.small_amount_class
     ,move_info.mixed_class
     ,move_info.ref_small_amount_class
     ,move_info.post_distance
     ,move_info.small_distance
     ,move_info.consolid_add_distance
     ,move_info.actual_distance
     ,move_info.small_weight
     ,move_info.pay_picking_amount
     ,move_info.qty
     ,move_info.delivery_weight
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
     ,move_info.sum_pallet_weight
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
    BULK COLLECT INTO gt_move_inf_tab
    FROM (
      -- 着日
      SELECT /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
                xmrih.mov_hdr_id                                  mov_hdr_id                 -- 移動ヘッダID
              , xmrih.mov_num                                     mov_num                    -- 移動番号
              , xmrih.slip_number                                 slip_number                -- 送り状No
              , xmrih.delivery_no                                 delivery_no                -- 配送No
              , xmrih.actual_freight_carrier_code                 actual_freight_carrier_code  -- 運送業者_実績
              , xmrih.shipped_locat_code                          shipped_locat_code         -- 出庫元保管場所
              , xmrih.actual_shipping_method_code                 shipping_method_code       -- 配送区分
              , gv_code_move                                      deliver_to_code_class      -- 配送先コード区分（３：倉庫）
              , xmrih.ship_to_locat_code                          ship_to_locat_code         -- 入庫先保管場所
              , xdec.payments_judgment_classe                     payments_judgment_classe   -- 支払判断区分(運賃)
              , xmrih.actual_ship_date                            actual_ship_date           -- 出庫実績日
              , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) actual_arrival_date -- 入庫実績日(入庫予定日)
              , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) judgement_date   -- 判断日
              , xmrih.item_class                                  item_class                 -- 商品区分
              , xmrih.weight_capacity_class                       weight_capacity_class      -- 重量容積区分
-- ##### 20080717 Ver.1.15 本番#595対応 START #####
---              , xmrih.small_quantity                              small_quantity             -- 小口個数
              , NVL(xmrih.small_quantity, 0)                         small_quantity             -- 小口個数
-- ##### 20080717 Ver.1.15 本番#595対応 END   #####
              , xmrih.sum_quantity                                sum_quantity               -- 合計数量
              , gv_type_move                                      order_type                 -- タイプ（３：移動）
              , xmrih.no_cont_freight_class                       no_cont_freight_class      -- 契約外運賃区分
              , NULL                                              transfer_location_code     -- 振替先
              , SUBSTRB(xmrih.description, 1, 40)                 description                -- 摘要（40）
              , NULL                                              small_amount_class         -- 配送区分：小口区分
              , NULL                                              mixed_class                -- 配送区分：混載区分
              , NULL                                              ref_small_amount_class     -- 配送区分：リーフ小口区分
              , NULL                                              post_distance              -- 配送距離：車立距離
              , NULL                                              small_distance             -- 配送距離：小口距離
              , NULL                                              consolid_add_distance      -- 配送距離：混載割増距離
              , NULL                                              actual_distance            -- 配送距離：実際距離
              , NULL                                              small_weight               -- 運送業者：小口重量
              , NULL                                              pay_picking_amount         -- 運送業者：支払ピッキング単価
              , NULL                                              qty                        -- 個数
              , NULL                                              delivery_weight            -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
              , NVL(xmrih.sum_pallet_weight, 0)                   sum_pallet_weight          -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
      FROM  xxinv_mov_req_instr_headers    xmrih,   -- 移動依頼/指示ヘッダ(アドオン)
            xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
      WHERE xmrih.actual_ship_date IS NOT NULL            -- 出庫実績日
      AND  (xmrih.actual_arrival_date IS NOT NULL           -- 入庫実績日
        OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- 入庫予定日
      AND   xmrih.actual_shipping_method_code IS NOT NULL -- 配送区分_実績
      AND   xmrih.actual_freight_carrier_code IS NOT NULL -- 運送業者_実績
      AND   xmrih.delivery_no IS NOT NULL                 -- 配送No
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xmrih.item_class = gv_prod_div                                    -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xmrih.item_class = xdec.goods_classe                              -- 商品区分
      AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- 適用終了日
      AND   xdec.payments_judgment_classe = gv_pay_judg_c                     -- 支払判断区分（着日）
      AND   NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                                >=  gd_target_date          -- 入庫実績日(入庫予定日)
      AND (
            ((xmrih.last_update_date    > gd_last_process_date)   -- 移動ヘッダ：前回処理日付
            AND (xmrih.last_update_date <= gd_sysdate))
          OR (EXISTS (SELECT 1
                      FROM   xxinv_mov_req_instr_lines  xmril                 -- 移動依頼/指示明細(アドオン)
                      WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                      AND    xmril.last_update_date > gd_last_process_date -- 移動明細：前回処理日付
                      AND    xmril.last_update_date <= gd_sysdate
                      AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- 積載重量合計の整数部が7桁以上の場合は出力しない
      AND   LENGTHB(TRUNC(NVL(xmrih.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- 発日
      SELECT /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
                xmrih.mov_hdr_id                                  mov_hdr_id                 -- 移動ヘッダID
              , xmrih.mov_num                                     mov_num                    -- 移動番号
              , xmrih.slip_number                                 slip_number                -- 送り状No
              , xmrih.delivery_no                                 delivery_no                -- 配送No
              , xmrih.actual_freight_carrier_code                 actual_freight_carrier_code  -- 運送業者_実績
              , xmrih.shipped_locat_code                          shipped_locat_code         -- 出庫元保管場所
              , xmrih.actual_shipping_method_code                 shipping_method_code       -- 配送区分
              , gv_code_move                                      deliver_to_code_class      -- 配送先コード区分（３：倉庫）
              , xmrih.ship_to_locat_code                          ship_to_locat_code         -- 入庫先保管場所
              , xdec.payments_judgment_classe                     payments_judgment_classe   -- 支払判断区分(運賃)
              , xmrih.actual_ship_date                            actual_ship_date           -- 出庫実績日
              , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) actual_arrival_date -- 入庫実績日(入庫予定日)
              , xmrih.actual_ship_date                            judgement_date             -- 判断日
              , xmrih.item_class                                  item_class                 -- 商品区分
              , xmrih.weight_capacity_class                       weight_capacity_class      -- 重量容積区分
-- ##### 20080717 Ver.1.15 本番#595対応 START #####
--              , xmrih.small_quantity                              small_quantity             -- 小口個数
              , NVL(xmrih.small_quantity, 0)                        small_quantity             -- 小口個数
-- ##### 20080717 Ver.1.15 本番#595対応 END   #####
              , xmrih.sum_quantity                                sum_quantity               -- 合計数量
              , gv_type_move                                      order_type                 -- タイプ（３：移動）
              , xmrih.no_cont_freight_class                       no_cont_freight_class      -- 契約外運賃区分
              , NULL                                              transfer_location_code     -- 振替先
              , SUBSTRB(xmrih.description, 1, 40)                 description                -- 摘要（40）
              , NULL                                              small_amount_class         -- 配送区分：小口区分
              , NULL                                              mixed_class                -- 配送区分：混載区分
              , NULL                                              ref_small_amount_class     -- 配送区分：リーフ小口区分
              , NULL                                              post_distance              -- 配送距離：車立距離
              , NULL                                              small_distance             -- 配送距離：小口距離
              , NULL                                              consolid_add_distance      -- 配送距離：混載割増距離
              , NULL                                              actual_distance            -- 配送距離：実際距離
              , NULL                                              small_weight               -- 運送業者：小口重量
              , NULL                                              pay_picking_amount         -- 運送業者：支払ピッキング単価
              , NULL                                              qty                        -- 個数
              , NULL                                              delivery_weight            -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
              , NVL(xmrih.sum_pallet_weight, 0)                   sum_pallet_weight          -- 合計パレット重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
      FROM  xxinv_mov_req_instr_headers    xmrih,   -- 移動依頼/指示ヘッダ(アドオン)
            xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
      WHERE xmrih.actual_ship_date IS NOT NULL            -- 出庫実績日
      AND  (xmrih.actual_arrival_date IS NOT NULL           -- 入庫実績日
        OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- 入庫予定日
      AND   xmrih.actual_shipping_method_code IS NOT NULL -- 配送区分_実績
      AND   xmrih.actual_freight_carrier_code IS NOT NULL -- 運送業者_実績
      AND   xmrih.delivery_no IS NOT NULL                 -- 配送No
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xmrih.item_class = gv_prod_div                                    -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xmrih.item_class = xdec.goods_classe                              -- 商品区分
      AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- 適用終了日
      AND   xdec.payments_judgment_classe = gv_pay_judg_g                     -- 支払判断区分（発日）
      AND   xmrih.actual_ship_date    >=  gd_target_date                      -- 出庫実績日
      AND (
            ((xmrih.last_update_date    > gd_last_process_date)   -- 移動ヘッダ：前回処理日付
            AND (xmrih.last_update_date <= gd_sysdate))
          OR (EXISTS (SELECT 1
                      FROM   xxinv_mov_req_instr_lines  xmril                 -- 移動依頼/指示明細(アドオン)
                      WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                      AND    xmril.last_update_date > gd_last_process_date -- 移動明細：前回処理日付
                      AND    xmril.last_update_date <= gd_sysdate
                      AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- 積載重量合計の整数部が7桁以上の場合は出力しない
      AND   LENGTHB(TRUNC(NVL(xmrih.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      ) move_info
      ;
-- ##### 20081125 Ver.1.13 本番#104対応 END #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move：移動実績情報抽出：' || TO_CHAR(gt_move_inf_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_move;
--
  /**********************************************************************************
   * Procedure Name   : get_move_other
   * Description      : 移動関連情報抽出
   ***********************************************************************************/
  PROCEDURE get_move_other(
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_other'; -- プログラム名
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
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- 配送区分
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- 配送距離
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- 運賃用運送業者
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
    -- 対象データ無の場合
    IF (gt_move_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<move_loop>>
    FOR ln_index IN  gt_move_inf_tab.FIRST.. gt_move_inf_tab.LAST LOOP
--
      -- **************************************************
      -- ***  配送区分情報取得(A-15)
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_move_inf_tab(ln_index).shipping_method_code, -- 配送区分
        gt_move_inf_tab(ln_index).judgement_date,       -- 判断日
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 小口区分設定
      gt_move_inf_tab(ln_index).small_amount_class := lr_ship_method_tab.small_amount_class;
      -- 混載区分設定
      gt_move_inf_tab(ln_index).mixed_class        := lr_ship_method_tab.mixed_class;
      -- リーフ小口区分設定（商品区分＝リーフ、小口区分＝小口）
      IF ((gt_move_inf_tab(ln_index).item_class = gv_prod_class_lef)
        AND (gt_move_inf_tab(ln_index).small_amount_class = gv_small_sum_yes)) THEN
        -- YESを設定
        gt_move_inf_tab(ln_index).ref_small_amount_class := gv_ktg_yes;
--
      ELSE
        -- NOを設定
        gt_move_inf_tab(ln_index).ref_small_amount_class := gv_ktg_no;
      END IF;
--
      -- **************************************************
      -- ***  配送距離アドオンマスタ抽出(A-17)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_distance(
        gt_move_inf_tab(ln_index).item_class,                   -- 商品区分
        gt_move_inf_tab(ln_index).actual_freight_carrier_code,  -- 運送業者
        gt_move_inf_tab(ln_index).shipped_locat_code,           -- 出庫倉庫
        gt_move_inf_tab(ln_index).deliver_to_code_class ,       -- コード区分
        gt_move_inf_tab(ln_index).ship_to_locat_code,           -- 配送先コード
        gt_move_inf_tab(ln_index).judgement_date,               -- 判断日
        lr_delivery_distance_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 車立距離
      gt_move_inf_tab(ln_index).post_distance := 
                                      lr_delivery_distance_tab.post_distance;
      -- 小口距離
      gt_move_inf_tab(ln_index).small_distance := lr_delivery_distance_tab.small_distance;
      -- 混載割増距離
      gt_move_inf_tab(ln_index).consolid_add_distance  := 
                                      lr_delivery_distance_tab.consolid_add_distance;
      -- 実際距離
      gt_move_inf_tab(ln_index).actual_distance := lr_delivery_distance_tab.actual_distance;
--
      -- **************************************************
      -- ***  運賃用運送業者アドオンマスタ抽出(A-8)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_company(
        gt_move_inf_tab(ln_index).item_class,                   -- 商品区分
        gt_move_inf_tab(ln_index).actual_freight_carrier_code,  -- 運送業者
        gt_move_inf_tab(ln_index).judgement_date,               -- 判断日
        lr_delivery_company_tab,                                -- 運賃用運送業者レコード
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 小口重量
      gt_move_inf_tab(ln_index).small_weight  := lr_delivery_company_tab.small_weight;
      -- 支払ピッキング単価
      gt_move_inf_tab(ln_index).pay_picking_amount := lr_delivery_company_tab.pay_picking_amount;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：++++++++++ 移動関連情報抽出 ++++++++++：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：+++++ 移動番号 +++++：' || gt_move_inf_tab(ln_index).mov_num);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：+++++ 運送業者 +++++：' || gt_move_inf_tab(ln_index).actual_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：+++++ 配送No   +++++：' || gt_move_inf_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：小口区分      ：' || gt_move_inf_tab(ln_index).small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：混載区分      ：' || gt_move_inf_tab(ln_index).mixed_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：リーフ小口区分：' || gt_move_inf_tab(ln_index).ref_small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：車立距離      ：' || TO_CHAR(gt_move_inf_tab(ln_index).post_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：小口距離      ：' || TO_CHAR(gt_move_inf_tab(ln_index).small_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：混載割増距離  ：' || TO_CHAR(gt_move_inf_tab(ln_index).consolid_add_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：実際距離      ：' || TO_CHAR(gt_move_inf_tab(ln_index).actual_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：小口重量          ：' || TO_CHAR(gt_move_inf_tab(ln_index).small_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other：支払ピッキング単価：' || TO_CHAR(gt_move_inf_tab(ln_index).pay_picking_amount));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP move_loop;
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
  END get_move_other;
--
  /**********************************************************************************
   * Procedure Name   : get_move_line
   * Description      : 移動明細アドオン抽出(A-18)
   ***********************************************************************************/
  PROCEDURE get_move_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_line'; -- プログラム名
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
    lt_move_line_inf_tab    move_line_inf_tbl;     --移動依頼／指示明細
--
    ln_item_id        xxcmn_item_mst2_v.item_id%TYPE;       -- 品目ID
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
    ln_item_no        xxcmn_item_mst2_v.item_no%TYPE;       -- 品目コード
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
    ln_num_of_cases   xxcmn_item_mst2_v.num_of_cases%TYPE;  -- ケース入り数
    ln_conv_unit      xxcmn_item_mst2_v.conv_unit%TYPE;     -- 入出庫換算単位
    ln_unit           xxcmn_item_mst2_v.unit%TYPE;          -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
    ln_capacity       xxcmn_item_mst2_v.capacity%TYPE;      -- 容積
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
--
    ln_qty                     xxwip_deliverys.qty1%TYPE;             -- 個数
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--    ln_delivery_weight         xxwip_deliverys.delivery_weight1%TYPE; -- 重量
    ln_delivery_weight         NUMBER;                                -- 重量
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
    ln_sum_qty                 xxwip_deliverys.qty1%TYPE;             -- 個数（合計）
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--    ln_sum_delivery_weight     xxwip_deliverys.delivery_weight1%TYPE; -- 重量（合計）
    ln_sum_delivery_weight     NUMBER;                                -- 重量（合計）
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：++++++++++ 移動明細アドオン抽出 ++++++++++');
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    -- 対象データ無の場合
    IF (gt_move_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<mover_loop>>
    FOR ln_index IN  gt_move_inf_tab.FIRST.. gt_move_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：++++++++++ 移動依頼/指示ヘッダ ++++++++++：' || TO_CHAR(ln_index));
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：移動番号 ：' || gt_move_inf_tab(ln_index).mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：運送業者 ：' || gt_move_inf_tab(ln_index).actual_freight_carrier_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：配送No   ：' || gt_move_inf_tab(ln_index).delivery_no);
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  移動明細アドオン抽出(A-18)
      -- **************************************************
      -- 変数初期化
      lt_move_line_inf_tab.DELETE;
--
      SELECT  xmril.mov_hdr_id                  -- 移動ヘッダID
            , xmril.item_id                     -- 品目ID
-- ##### 20080625 Ver.1.2 出荷実績数量NULL対応 START #####
/***
            , xmril.shipped_quantity            -- 出荷実績数量
***/
            , NVL(xmril.shipped_quantity, 0)    -- 出荷実績数量
-- ##### 20080625 Ver.1.2 出荷実績数量NULL対応 END   #####
      BULK COLLECT INTO lt_move_line_inf_tab
      FROM  xxinv_mov_req_instr_lines   xmril       -- 移動依頼/指示明細アドオン
      WHERE xmril.mov_hdr_id = gt_move_inf_tab(ln_index).mov_hdr_id -- 移動ヘッダID
      AND   NVL(xmril.delete_flg, gv_ktg_no)  = gv_ktg_no;          -- 取消フラグ
--
      -- 合計値 初期化
      ln_sum_qty             := 0;  -- 個数（合計）
      ln_sum_delivery_weight := 0;  -- 重量（合計）
--
      -- 対象データ無の場合
      IF (lt_move_line_inf_tab.COUNT = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                      gv_xxcmn_msg_notfnd,
                                      gv_tkn_table,
                                      gv_mov_req_instr_lines,
                                      gv_tkn_key,
                                      gt_move_inf_tab(ln_index).mov_num);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      <<move_line_loop>>
      FOR ln_line_index IN  lt_move_line_inf_tab.FIRST.. lt_move_line_inf_tab.LAST LOOP
--
        -- **************************************************
        -- ***  移動OPM品目情報VIEW抽出(A-19)
        -- **************************************************
        -- 変数初期化
        ln_num_of_cases := NULL;        -- ケース入り数
        ln_conv_unit    := NULL;        -- 入出庫換算単位
        ln_unit         := NULL;        -- 重量
--
        -- 入出庫換算単位、ケース入り数、重量 取得
        BEGIN
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--          SELECT ximv.item_id         -- 品目ID
          SELECT ximv.item_no         -- 品目コード
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
               , ximv.num_of_cases    -- ケース入り数
               , ximv.conv_unit       -- 入出庫換算単位
               , ximv.unit            -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
               , ximv.capacity        -- 容積
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
 -- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--         INTO   ln_item_id
         INTO   ln_item_no
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
               , ln_num_of_cases
               , ln_conv_unit
               , ln_unit
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
               , ln_capacity
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
          FROM   xxcmn_item_mst2_v    ximv    -- OPM品目情報VIEW2
          WHERE  ximv.item_id = lt_move_line_inf_tab(ln_line_index).item_id         -- 品目ID
          AND    gt_move_inf_tab(ln_index).judgement_date >= ximv.start_date_active -- 適用開始日
          AND    gt_move_inf_tab(ln_index).judgement_date <= ximv.end_date_active;  -- 適用終了日
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_notfnd,
                                                  gv_tkn_table,
                                                  gv_item_mst2_v,
                                                  gv_tkn_key,
                                                  lt_move_line_inf_tab(ln_line_index).item_id);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN TOO_MANY_ROWS THEN   --*** データ複数取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_item_mst2_v,
                                                  gv_tkn_key,
                                                  lt_move_line_inf_tab(ln_line_index).item_id);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- **************************************************
        -- ***  移動個数/数量算出(A-20)
        -- **************************************************
        -- 変数初期化
        ln_qty              := 0;
        ln_delivery_weight  := 0;
--
        -- *** 個数 算出 ***
        -- リーフ小口区分 ＝ Y の場合
        IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          -- 個数に小口個数を設定
          ln_qty := gt_move_inf_tab(ln_index).small_quantity;
--
        -- リーフ小口区分 ＝ N の場合
        ELSE
          -- 個数に合計数量を設定
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--          ln_qty := gt_move_inf_tab(ln_index).sum_quantity;
          ln_qty := xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                        ln_item_no                                             -- 品目コード
                      , lt_move_line_inf_tab(ln_line_index).shipped_quantity); -- 数量
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
        END IF;
--
        -- *** 重量 算出 ***
        -- リーフ小口区分 ＝ Y 且つ、重量容積区分 ＝ 容積 の場合
        IF ((gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes)
          AND (gt_move_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          -- 上記算出の個数 × 小口重量
          ln_delivery_weight :=
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--                ln_qty * gt_move_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--                CEIL(ln_qty * gt_move_inf_tab(ln_index).small_weight);
                ln_qty * gt_move_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
--
        -- 上記以外
        ELSE
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
          -- 重量容積区分＝「容積」の場合
          IF (gt_move_inf_tab(ln_index).weight_capacity_class = gv_capacity) THEN
            -- 容積 × 出荷実績数量（切上）
            ln_delivery_weight :=
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--                CEIL(ln_capacity * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000000);
                ln_capacity * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000000;
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
--
          -- 重量容積区分＝「重量」の場合
          ELSE
            -- 重量 × 出荷実績数量（切上）
            ln_delivery_weight :=
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--                ROUND(ln_unit * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000);
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--                CEIL(ln_unit * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000);
                ln_unit * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000;
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
          END IF;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：++++++++++ 移動依頼/指示明細アドオン ++++++++++：' || TO_CHAR(ln_line_index));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：移動ヘッダID ：' || lt_move_line_inf_tab(ln_line_index).mov_hdr_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：OPM品目ID    ：' || lt_move_line_inf_tab(ln_line_index).item_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：出荷実績数量 ：' || lt_move_line_inf_tab(ln_line_index).shipped_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：+++++ 条件 +++++');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：リーフ小口区分：' || gt_move_inf_tab(ln_index).ref_small_amount_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：重量容積区分  ：' || gt_move_inf_tab(ln_index).weight_capacity_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：+++++ OPM品目 +++++');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：品目ID        ：' || lt_move_line_inf_tab(ln_line_index).item_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：ケース入り数  ：' || TO_CHAR(ln_num_of_cases));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：入出庫換算単位：' || ln_conv_unit);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：重量          ：' || TO_CHAR(ln_unit));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：容積          ：' || TO_CHAR(ln_capacity));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：+++++ 算出結果 +++++');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：個数         ：' || TO_CHAR(ln_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：重量         ：' || TO_CHAR(ln_delivery_weight));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  移動個数/数量集計(A-21)
        -- **************************************************
        -- 個数（合計）
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--        ln_sum_qty := ln_qty;
        -- リーフ小口区分 ＝ Y の場合
        IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          ln_sum_qty := ln_qty;
        ELSE
          ln_sum_qty := ln_sum_qty + ln_qty;
        END IF;
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
--
        -- 重量（合計）
        -- リーフ小口区分 ＝ Y 且つ、重量容積区分 ＝ 容積 の場合
        IF ((gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes)
          AND (gt_move_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          ln_sum_delivery_weight := ln_delivery_weight;
        ELSE
          ln_sum_delivery_weight := ln_sum_delivery_weight + ln_delivery_weight;
        END IF;
--
      END LOOP move_line_loop;
--
      -- 合計（個数、重量）設定
      gt_move_inf_tab(ln_index).qty              := ln_sum_qty;
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--      gt_move_inf_tab(ln_index).delivery_weight  := ln_sum_delivery_weight;
--
      -- 重量容積区分＝「重量」小口区分＝「車立」の場合
      IF   ((gt_move_inf_tab(ln_index).weight_capacity_class = gv_weight)
        AND (gt_move_inf_tab(ln_index).small_amount_class    = gv_small_sum_no)) THEN
        -- 明細重量をサマリし小数点以下第一を切上し、合計パレット重量を加算
        gt_move_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1)) + 
                                                      gt_move_inf_tab(ln_index).sum_pallet_weight;
--
      -- 上記以外
      ELSE
        -- 明細重量をサマリし小数点以下第一を切上
        gt_move_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1));
      END IF;
--
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：++++++++++ 移動個数／重量集計 ++++++++++');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：個数（合計）：' || TO_CHAR(gt_move_inf_tab(ln_index).qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line：重量（合計）：' || TO_CHAR(gt_move_inf_tab(ln_index).delivery_weight));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP mover_loop;
--
  EXCEPTION
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
    WHEN func_inv_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
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
  END get_move_line;
--
  /**********************************************************************************
   * Procedure Name   : set_move_deliv_line
   * Description      : 移動運賃明細アドオンPL/SQL表格納(A-22)
   ***********************************************************************************/
  PROCEDURE set_move_deliv_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_move_deliv_line'; -- プログラム名
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
    lv_delivery_company_code  xxwip_delivery_lines.delivery_company_code%TYPE;  -- 運送業者
    lv_whs_code               xxwip_delivery_lines.whs_code%TYPE;               -- 出庫倉庫
    lv_shipping_address_code  xxwip_delivery_lines.shipping_address_code%TYPE;  -- 配送先コード
    lv_dellivary_classe       xxwip_delivery_lines.dellivary_classe%TYPE;       -- 配送区分
    ln_qty                    xxwip_delivery_lines.qty%TYPE;                    -- 個数
    ln_delivery_weight        xxwip_delivery_lines.delivery_weight%TYPE;        -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
    ld_ship_date              xxwip_delivery_lines.ship_date%TYPE;              -- 出荷日
    ld_arrival_date           xxwip_delivery_lines.arrival_date%TYPE;           -- 着荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
    lv_payments_judgment_classe   xxwip_delivery_lines.payments_judgment_classe%TYPE; -- 支払判断区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
    lv_delivery_no            xxwip_delivery_lines.delivery_no%TYPE;            -- 配送No
    ln_deli_cnt               NUMBER;
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
--
    ln_deliv_line_flg         VARCHAR2(1);      -- 受注明細アドオン 存在フラグ Y:有 N:無
--
    ln_line_insert_cnt        NUMBER;           -- 登録用PL/SQL表 件数
    ln_line_calc_update_cnt   NUMBER;           -- 再計算更新用PL/SQL表 件数
    ln_line_des_update_cnt    NUMBER;           -- 摘要登録用PL/SQL表 件数
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
    -- 件数初期化
    ln_line_insert_cnt      := i_line_deliv_lines_id_tab.COUNT ;  -- 登録用PL/SQL表 件数
    ln_line_calc_update_cnt := us_line_request_no_tab.COUNT ;     -- 再計算更新用PL/SQL表 件数
    ln_line_des_update_cnt  := ut_line_request_no_tab.COUNT ;     -- 摘要登録用PL/SQL表 件数
--
    -- 対象データ無の場合
    IF (gt_move_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<move_loop>>
    FOR ln_index IN  gt_move_inf_tab.FIRST.. gt_move_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：++++++++++ 移動運賃明細アドオンPL/SQL表格納 ++++++++++：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：移動番号 ：' || gt_move_inf_tab(ln_index).mov_num);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：運送業者 ：' || gt_move_inf_tab(ln_index).actual_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：配送No   ：' || gt_move_inf_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  運賃ヘッダアドオン抽出
      -- **************************************************
      -- 存在フラグ初期化
      ln_deliv_line_flg := gv_ktg_yes;
--
      BEGIN
        SELECT  xwdl.delivery_company_code  -- 運送業者
              , xwdl.whs_code               -- 出庫倉庫
              , xwdl.shipping_address_code  -- 配送先コード
              , xwdl.dellivary_classe       -- 配送区分
              , xwdl.qty                    -- 個数
              , xwdl.delivery_weight        -- 重量
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
              , xwdl.ship_date              -- 出荷日
              , xwdl.arrival_date           -- 着荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
              , xwdl.delivery_no            -- 配送No
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
              , payments_judgment_classe    -- 支払判断区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
        INTO    lv_delivery_company_code
              , lv_whs_code
              , lv_shipping_address_code
              , lv_dellivary_classe
              , ln_qty
              , ln_delivery_weight
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
              , ld_ship_date                -- 出荷日
              , ld_arrival_date             -- 着荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
              , lv_delivery_no              -- 配送No
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
              , lv_payments_judgment_classe -- 支払判断区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
        FROM   xxwip_delivery_lines xwdl    -- 運賃明細アドオン
        WHERE  xwdl.request_no = gt_move_inf_tab(ln_index).mov_num; -- 移動番号
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
          -- 存在フラグ Y を設定
          ln_deliv_line_flg := gv_ktg_no;
--
        WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_move_inf_tab(ln_index).mov_num);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：++++++++++ 運賃ヘッダアドオン ++++++++++：' || ln_deliv_line_flg);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：運送業者     ：' || lv_delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：出庫倉庫     ：' || lv_whs_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：配送先コード ：' || lv_shipping_address_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：配送区分     ：' || lv_dellivary_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：個数         ：' || TO_CHAR(ln_qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：重量         ：' || TO_CHAR(ln_delivery_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：出荷日       ：' || TO_CHAR(ld_ship_date    ,'YYYY/MM/DD'));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：着荷日       ：' || TO_CHAR(ld_arrival_date ,'YYYY/MM/DD'));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
--
      -- **************************************************
      -- ***  配送Noの変更による削除処理
      -- **************************************************
      -- 運賃明細アドオンが存在する場合
      IF (ln_deliv_line_flg = gv_ktg_yes) THEN
        -- 運賃明細の配送Noと実績の配送Noが異なる場合
        IF (gt_move_inf_tab(ln_index).delivery_no <> lv_delivery_no) THEN
          -- 旧配送Noの件数取得
          BEGIN
            SELECT  COUNT(delivery_no)
            INTO    ln_deli_cnt
            FROM    xxwip_delivery_lines xwdl           -- 運賃明細アドオン
            WHERE   xwdl.delivery_no = lv_delivery_no;  -- 配送No
          END;
--
          -- 旧配送Noが運賃明細に1件の場合
          -- 複数件の場合は混載、集約であるため、削除しない
          IF ( ln_deli_cnt = 1 ) THEN
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：配送組替 旧DELETE：' ||
                                                                  lv_delivery_no || '->' ||
                                          gt_move_inf_tab(ln_index).delivery_no);
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
            -- 運賃ヘッダより削除する
            BEGIN
              -- 対象配送Noを削除する
              DELETE FROM xxwip_deliverys
              WHERE delivery_no = lv_delivery_no;
            END;
          END IF;
        END IF;
      END IF;
--
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
      -- **************************************************
      -- ***  運賃明細アドオンにデータが存在しない場合
      -- **************************************************
      IF (ln_deliv_line_flg = gv_ktg_no) THEN
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：運賃明細アドオン INSERT');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 登録用PL/SQL表 件数
        ln_line_insert_cnt  := ln_line_insert_cnt + 1;
--
        -- 運賃明細登録用PL/SQL表 設定
        -- 依頼No
        i_line_request_no_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).mov_num;
        -- 送り状No
        i_line_invoice_no_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).slip_number;
        -- 配送No
        i_line_deliv_no_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).delivery_no;
        -- リーフ小口区分
        i_line_small_lot_cls_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).ref_small_amount_class;
        -- 運送業者
        i_line_deliv_cmpny_cd_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).actual_freight_carrier_code;
        -- 出庫倉庫コード
        i_line_whs_code_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).shipped_locat_code;
        -- 配送区分
        i_line_delliv_cls_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).shipping_method_code;
        -- 配送先コード区分
        i_line_code_division_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).deliver_to_code_class;
        -- 配送先コード
        i_line_ship_addr_cd_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).ship_to_locat_code;
        -- 支払判断区分
        i_line_pay_judg_cls_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).payments_judgment_classe;
        -- 出庫日
        i_line_ship_date_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).actual_ship_date;
        -- 到着日
        i_line_arrival_date_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).actual_arrival_date;
        -- 報告日
        i_line_report_date_tab(ln_line_insert_cnt) := NULL;
        -- 判断日
        i_line_judg_date_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).judgement_date;
        -- 商品区分
        i_line_goods_cls_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).item_class;
        -- 重量容積区分
        i_line_weight_cap_cls_tab(ln_line_insert_cnt)  := 
                                            gt_move_inf_tab(ln_index).weight_capacity_class;
--
        -- リーフ小口区分 ＝ Yの場合
        IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
            -- 小口距離
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
        -- 商品区分 ＝ リーフ   又は 
        -- 商品区分 ＝ ドリンク 且つ、混載区分 ＜＞ 混載 の場合
--        ELSIF (
--                  (gt_move_inf_tab(ln_index).item_class = gv_prod_class_lef)
--                OR    
--                  ((gt_move_inf_tab(ln_index).item_class = gv_prod_class_drk)
--                  AND (gt_move_inf_tab(ln_index).mixed_class <> gv_target_y))
--              ) THEN
          -- 車立距離
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance;
--
        -- 上記以外
--        ELSE
--
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
          -- 車立距離1（明細は混載割増距離を加算しない）
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance +
--                                                  gt_move_inf_tab(ln_index).consolid_add_distance;
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
--
        ELSE
          -- 小口区分＝「小口」の場合
          IF (gt_move_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
            -- 小口距離を設定
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
          -- 小口区分＝「車立」の場合
          ELSE
            -- 車立て距離を設定
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance;
          END IF;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
        END IF;
--
        -- 実際距離
        i_line_actual_dstnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).actual_distance;
        -- 個数
        i_line_qty_tab(ln_line_insert_cnt)             := gt_move_inf_tab(ln_index).qty;
        -- 重量
        i_line_deliv_weight_tab(ln_line_insert_cnt)    := gt_move_inf_tab(ln_index).delivery_weight;
        -- タイプ
        i_line_order_tab_tab(ln_line_insert_cnt)       := gt_move_inf_tab(ln_index).order_type;
        -- 混載区分
        i_line_mixed_code_tab(ln_line_insert_cnt)      := gt_move_inf_tab(ln_index).mixed_class;
        -- 契約外区分
        i_line_outside_cntrct_tab(ln_line_insert_cnt)  := 
                                                  gt_move_inf_tab(ln_index).no_cont_freight_class;
        -- 振替先
        i_line_trans_locat_tab(ln_line_insert_cnt)     := 
                                                  gt_move_inf_tab(ln_index).transfer_location_code;
        -- 摘要
        i_line_description_tab(ln_line_insert_cnt)     := gt_move_inf_tab(ln_index).description;
--
      -- **************************************************
      -- ***  運賃明細アドオンにデータが存在する場合
      -- **************************************************
      ELSE
        -- **************************************************
        -- ***  登録されている内容より再計算が必要な場合
        -- **************************************************
        --   対象項目：運送業者、出庫倉庫、配送先コード、配送区分、個数、重量、出庫日、入庫日、支払判断区分
-- ##### 20090123 Ver.1.20 本番#1074 START #####
-- 更新時の条件をなくし、変更があった場合は更新するように修正
/*****
        IF ((gt_move_inf_tab(ln_index).actual_freight_carrier_code <> lv_delivery_company_code )
          OR (gt_move_inf_tab(ln_index).shipped_locat_code   <> lv_whs_code              )
          OR (gt_move_inf_tab(ln_index).ship_to_locat_code   <> lv_shipping_address_code )
          OR (gt_move_inf_tab(ln_index).shipping_method_code <> lv_dellivary_classe      )
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
          OR (gt_move_inf_tab(ln_index).delivery_no          <> lv_delivery_no      )
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
          OR (gt_move_inf_tab(ln_index).actual_ship_date     <> ld_ship_date    )
          OR (gt_move_inf_tab(ln_index).actual_arrival_date  <> ld_arrival_date )
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
          OR (gt_move_inf_tab(ln_index).payments_judgment_classe  <> lv_payments_judgment_classe )
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
          OR (gt_move_inf_tab(ln_index).qty                  <> ln_qty                   )
          OR (gt_move_inf_tab(ln_index).delivery_weight      <> ln_delivery_weight       )) THEN
*****/
-- ##### 20090123 Ver.1.20 本番#1074 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：運賃明細アドオン UPDATE 再計算');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 再計算更新用PL/SQL表 件数
          ln_line_calc_update_cnt   := ln_line_calc_update_cnt + 1;
--
          -- 運賃明細アドオン
          -- 依頼No
          us_line_request_no_tab(ln_line_calc_update_cnt)        := 
                                            gt_move_inf_tab(ln_index).mov_num;
          -- 送り状No
          us_line_invoice_no_tab(ln_line_calc_update_cnt)        := 
                                            gt_move_inf_tab(ln_index).slip_number;
          -- 配送No
          us_line_deliv_no_tab(ln_line_calc_update_cnt)          := 
                                            gt_move_inf_tab(ln_index).delivery_no;
          -- リーフ小口区分
          us_line_small_lot_cls_tab(ln_line_calc_update_cnt)     := 
                                            gt_move_inf_tab(ln_index).ref_small_amount_class;
          -- 運送業者
          us_line_deliv_cmpny_cd_tab(ln_line_calc_update_cnt)    := 
                                            gt_move_inf_tab(ln_index).actual_freight_carrier_code;
          -- 出庫倉庫コード
          us_line_whs_code_tab(ln_line_calc_update_cnt)          := 
                                            gt_move_inf_tab(ln_index).shipped_locat_code;
          -- 配送区分
          us_line_delliv_cls_tab(ln_line_calc_update_cnt)        := 
                                            gt_move_inf_tab(ln_index).shipping_method_code;
          -- 配送先コード区分
          us_line_code_division_tab(ln_line_calc_update_cnt)     := 
                                            gt_move_inf_tab(ln_index).deliver_to_code_class;
          -- 配送先コード区分
          us_line_ship_addr_cd_tab(ln_line_calc_update_cnt)      := 
                                            gt_move_inf_tab(ln_index).ship_to_locat_code;
          -- 支払判断区分
          us_line_pay_judg_cls_tab(ln_line_calc_update_cnt)      := 
                                            gt_move_inf_tab(ln_index).payments_judgment_classe;
          -- 出庫日
          us_line_ship_date_tab(ln_line_calc_update_cnt)         := 
                                            gt_move_inf_tab(ln_index).actual_ship_date;
          -- 到着日
          us_line_arrival_date_tab(ln_line_calc_update_cnt)      := 
                                            gt_move_inf_tab(ln_index).actual_arrival_date;
          -- 判断日
          us_line_judg_date_tab(ln_line_calc_update_cnt)         := 
                                            gt_move_inf_tab(ln_index).judgement_date;
          -- 商品区分
          us_line_goods_cls_tab(ln_line_calc_update_cnt)         := 
                                            gt_move_inf_tab(ln_index).item_class;
          -- 重量容積区分
          us_line_weight_cap_cls_tab(ln_line_calc_update_cnt)    := 
                                            gt_move_inf_tab(ln_index).weight_capacity_class;
--
          -- リーフ小口区分 ＝ Yの場合
          IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
              -- 小口距離
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
          -- 商品区分 ＝ リーフ   又は 
          -- 商品区分 ＝ ドリンク 且つ、混載区分 ＜＞ 混載 の場合
--          ELSIF (
--                  (gt_move_inf_tab(ln_index).item_class = gv_prod_class_lef)
--                OR    
--                  ((gt_move_inf_tab(ln_index).item_class = gv_prod_class_drk)
--                  AND (gt_move_inf_tab(ln_index).mixed_class <> gv_target_y))
--              ) THEN
            -- 車立距離
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance;
--
          -- 上記以外
--          ELSE
--
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
            -- 車立距離1（明細は混載割増距離を加算しない）
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance +
--                                                    gt_move_inf_tab(ln_index).consolid_add_distance;
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
--
          ELSE
            -- 小口区分＝「小口」の場合
            IF (gt_move_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
              -- 小口距離を設定
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
            -- 小口区分＝「車立」の場合
            ELSE
              -- 車立て距離を設定
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance;
            END IF;
--
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
          END IF;
--
          -- 実際距離
          us_line_actual_dstnc_tab(ln_line_calc_update_cnt)      := 
                                                  gt_move_inf_tab(ln_index).actual_distance;
          -- 個数
          us_line_qty_tab(ln_line_calc_update_cnt)               := 
                                                  gt_move_inf_tab(ln_index).qty;
          -- 重量
          us_line_deliv_weight_tab(ln_line_calc_update_cnt)      := 
                                                  gt_move_inf_tab(ln_index).delivery_weight;
          -- タイプ
          us_line_order_tab_tab(ln_line_calc_update_cnt)         := 
                                                  gt_move_inf_tab(ln_index).order_type;
          -- 混載区分
          us_line_mixed_code_tab(ln_line_calc_update_cnt)        := 
                                                  gt_move_inf_tab(ln_index).mixed_class;
          -- 契約外区分
          us_line_outside_cntrct_tab(ln_line_calc_update_cnt)    := 
                                                  gt_move_inf_tab(ln_index).no_cont_freight_class;
          -- 振替先
          us_line_trans_locat_tab(ln_line_calc_update_cnt)       := 
                                                  gt_move_inf_tab(ln_index).transfer_location_code;
          -- 摘要
          us_line_description_tab(ln_line_calc_update_cnt)       := 
                                                  gt_move_inf_tab(ln_index).description;
--
        -- **************************************************
        -- ***  登録されている内容より再計算が必要でない場合
        -- **************************************************
-- ##### 20090123 Ver.1.20 本番#1074 START #####
-- 適用のみの更新処理は廃止する
/*****
        ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line：運賃明細アドオン UPDATE 摘要');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 摘要登録用PL/SQL表 件数
          ln_line_des_update_cnt := ln_line_des_update_cnt + 1;
--
          -- 運賃明細アドオン
          -- 依頼No
          ut_line_request_no_tab(ln_line_des_update_cnt)  := 
                              gt_move_inf_tab(ln_index).mov_num;
          -- 摘要
          ut_line_description_tab(ln_line_des_update_cnt) := gt_move_inf_tab(ln_index).description;
--
        END IF;
*****/
-- ##### 20090123 Ver.1.20 本番#1074 END   #####
      END IF;
--
    END LOOP move_loop;
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
  END set_move_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : insert_deliv_line
   * Description      : 運賃明細アドオン一括登録(A-23)
   ***********************************************************************************/
  PROCEDURE insert_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_deliv_line'; -- プログラム名
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
    IF (i_line_request_no_tab.COUNT <> 0) THEN 
--
      -- **************************************************
      -- * 運賃明細アドオン 登録
      -- **************************************************
      FORALL ln_index IN i_line_request_no_tab.FIRST .. i_line_request_no_tab.LAST
        INSERT INTO xxwip_delivery_lines
        ( delivery_lines_id           -- 運賃明細アドオンID
        , request_no                  -- 依頼No
        , invoice_no                  -- 送り状No
        , delivery_no                 -- 配送No
        , small_lot_class             -- リーフ小口区分
        , delivery_company_code       -- 運送業者
        , whs_code                    -- 出庫倉庫コード
        , dellivary_classe            -- 配送区分
        , code_division               -- 配送先コード区分
        , shipping_address_code       -- 配送先コード
        , payments_judgment_classe    -- 支払判断区分
        , ship_date                   -- 出庫日
        , arrival_date                -- 到着日
        , report_date                 -- 報告日
        , judgement_date              -- 判断日
        , goods_classe                -- 商品区分
        , weight_capacity_class       -- 重量容積区分
        , distance                    -- 距離
        , actual_distance             -- 実際距離
        , qty                         -- 個数
        , delivery_weight             -- 重量
        , order_type                  -- タイプ
        , mixed_code                  -- 混載区分
        , outside_contract            -- 契約外区分
        , transfer_location           -- 振替先
        , description                 -- 摘要
        , created_by                  -- 作成者
        , creation_date               -- 作成日
        , last_updated_by             -- 最終更新者
        , last_update_date            -- 最終更新日
        , last_update_login           -- 最終更新ログイン
        , request_id                  -- 要求ID
        , program_application_id      -- コンカレント・プログラム・アプリケーションID
        , program_id                  -- コンカレント・プログラムID
        , program_update_date         -- プログラム更新日
        ) VALUES (
          xxwip_delivery_lines_id_s1.NEXTVAL    -- 運賃明細アドオンID
        , i_line_request_no_tab(ln_index)       -- 依頼No
        , i_line_invoice_no_tab(ln_index)       -- 送り状No
        , i_line_deliv_no_tab(ln_index)         -- 配送No
        , i_line_small_lot_cls_tab(ln_index)    -- リーフ小口区分
        , i_line_deliv_cmpny_cd_tab(ln_index)   -- 運送業者
        , i_line_whs_code_tab(ln_index)         -- 出庫倉庫コード
        , i_line_delliv_cls_tab(ln_index)       -- 配送区分
        , i_line_code_division_tab(ln_index)    -- 配送先コード区分
        , i_line_ship_addr_cd_tab(ln_index)     -- 配送先コード
        , i_line_pay_judg_cls_tab(ln_index)     -- 支払判断区分
        , i_line_ship_date_tab(ln_index)        -- 出庫日
        , i_line_arrival_date_tab(ln_index)     -- 到着日
        , i_line_report_date_tab(ln_index)      -- 報告日
        , i_line_judg_date_tab(ln_index)        -- 判断日
        , i_line_goods_cls_tab(ln_index)        -- 商品区分
        , i_line_weight_cap_cls_tab(ln_index)   -- 重量容積区分
        , i_line_ditnc_tab(ln_index)            -- 距離
        , i_line_actual_dstnc_tab(ln_index)     -- 実際距離
        , i_line_qty_tab(ln_index)              -- 個数
        , i_line_deliv_weight_tab(ln_index)     -- 重量
        , i_line_order_tab_tab(ln_index)        -- タイプ
        , i_line_mixed_code_tab(ln_index)       -- 混載区分
        , i_line_outside_cntrct_tab(ln_index)   -- 契約外区分
        , i_line_trans_locat_tab(ln_index)      -- 振替先
        , i_line_description_tab(ln_index)      -- 摘要
        , gn_user_id                            -- 作成者
        , gd_sysdate                            -- 作成日
        , gn_user_id                            -- 最終更新者
        , gd_sysdate                            -- 最終更新日
        , gn_login_id                           -- 最終更新ログイン
        , gn_conc_request_id                    -- 要求ID
        , gn_prog_appl_id                       -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
        , gn_conc_program_id                    -- コンカレント・プログラムID
        , gd_sysdate);                          -- プログラム更新日
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
--
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
  END insert_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_line_calc
   * Description      : 運賃明細アドオン一括再計算更新(A-24)
   ***********************************************************************************/
  PROCEDURE update_deliv_line_calc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_deliv_line_calc'; -- プログラム名
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
    IF (us_line_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃明細アドオン 再計算 更新
      -- **************************************************
      FORALL ln_index IN us_line_request_no_tab.FIRST .. us_line_request_no_tab.LAST
        UPDATE xxwip_delivery_lines       -- 運賃明細アドオン
        SET     invoice_no                = us_line_invoice_no_tab(ln_index)      -- 送り状No
              , delivery_no               = us_line_deliv_no_tab(ln_index)        -- 配送No
              , small_lot_class           = us_line_small_lot_cls_tab(ln_index)   -- リーフ小口区分
              , delivery_company_code     = us_line_deliv_cmpny_cd_tab(ln_index)  -- 運送業者
              , whs_code                  = us_line_whs_code_tab(ln_index)        -- 出庫倉庫コード
              , dellivary_classe          = us_line_delliv_cls_tab(ln_index)      -- 配送区分
              , code_division             = us_line_code_division_tab(ln_index)   -- 配送先コード区分
              , shipping_address_code     = us_line_ship_addr_cd_tab(ln_index)    -- 配送先コード
              , payments_judgment_classe  = us_line_pay_judg_cls_tab(ln_index)    -- 支払判断区分
              , ship_date                 = us_line_ship_date_tab(ln_index)       -- 出庫日
              , arrival_date              = us_line_arrival_date_tab(ln_index)    -- 到着日
              , judgement_date            = us_line_judg_date_tab(ln_index)       -- 判断日
              , goods_classe              = us_line_goods_cls_tab(ln_index)       -- 商品区分
              , weight_capacity_class     = us_line_weight_cap_cls_tab(ln_index)  -- 重量容積区分
              , distance                  = us_line_ditnc_tab(ln_index)           -- 距離
              , actual_distance           = us_line_actual_dstnc_tab(ln_index)    -- 実際距離
              , qty                       = us_line_qty_tab(ln_index)             -- 個数
              , delivery_weight           = us_line_deliv_weight_tab(ln_index)    -- 重量
              , order_type                = us_line_order_tab_tab(ln_index)       -- タイプ
              , mixed_code                = us_line_mixed_code_tab(ln_index)      -- 混載区分
              , outside_contract          = us_line_outside_cntrct_tab(ln_index)  -- 契約外区分
              , transfer_location         = us_line_trans_locat_tab(ln_index)     -- 振替先
              , description               = us_line_description_tab(ln_index)     -- 摘要
              , last_updated_by           = gn_user_id                 -- 最終更新者
              , last_update_date          = gd_sysdate                 -- 最終更新日
              , last_update_login         = gn_login_id                -- 最終更新ログイン
              , request_id                = gn_conc_request_id         -- 要求ID
              , program_application_id    = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
              , program_id                = gn_conc_program_id         -- コンカレント・プログラムID
              , program_update_date       = gd_sysdate                 -- プログラム更新日
        WHERE  request_no = us_line_request_no_tab(ln_index);
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
--
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
  END update_deliv_line_calc;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_line_desc
   * Description      : 運賃明細アドオン一括適用更新(A-25)
   ***********************************************************************************/
  PROCEDURE update_deliv_line_desc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_deliv_line_desc'; -- プログラム名
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
    IF (ut_line_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃明細アドオン 適用 更新
      -- **************************************************
      FORALL ln_index IN ut_line_request_no_tab.FIRST .. ut_line_request_no_tab.LAST
        UPDATE xxwip_delivery_lines       -- 運賃明細アドオン
        SET     description               = ut_line_description_tab(ln_index)   -- 摘要
              , last_updated_by           = gn_user_id           -- 最終更新者
              , last_update_date          = gd_sysdate           -- 最終更新日
              , last_update_login         = gn_login_id          -- 最終更新ログイン
              , request_id                = gn_conc_request_id   -- 要求ID
              , program_application_id    = gn_prog_appl_id      -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
              , program_id                = gn_conc_program_id   -- コンカレント・プログラムID
              , program_update_date       = gd_sysdate           -- プログラム更新日
        WHERE  request_no = ut_line_request_no_tab(ln_index);
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
--
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
  END update_deliv_line_desc;
--
--
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START ##### 
-- 以降は配車解除対応の新規プロシージャー
  /**********************************************************************************
   * Procedure Name   : get_carcan_req_no
   * Description      : 配車解除対象依頼No抽出(A-25-1)
   ***********************************************************************************/
  PROCEDURE get_carcan_req_no(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_carcan_req_no'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- * 受注実績、支給実績、移動実績の
    -- * 配車解除されたデータ抽出
    -- * 〔対象データ〕
    -- * 実績項目が設定されていて、配送NoがNULLのデータ
    -- **************************************************
-- ##### 20081125 Ver.1.13 本番#104対応 START #####
    /*SELECT  carcan.results_type         -- タイプ
          , carcan.request_no           -- 依頼No（移動番号）
    BULK COLLECT INTO gt_carcan_info_tab
    FROM
      (
        -- ==================================================
        -- 配車解除された受注実績、支給実績情報 抽出
        -- ==================================================
        SELECT  CASE xotv.shipping_shikyu_class       -- タイプ
                WHEN gv_shipping  THEN gv_type_ship   --   １：出荷
                WHEN gv_shikyu    THEN gv_type_shikyu --   ２：支給
                END                   AS results_type
              , xoha.request_no       AS request_no   -- 依頼No
        FROM  xxwsh_order_headers_all        xoha,    -- 受注ヘッダアドオン
              xxwsh_oe_transaction_types2_v  xotv,    -- 受注タイプ情報VIEW2
              xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
        WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--        AND   xoha.arrival_date IS NOT NULL                   -- 着荷日
-- （着荷予定日もしくは着荷日が設定されていることが前提）
        AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
        AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
        AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
        AND   xoha.delivery_no  IS NULL                       -- 配送No
        -- 運賃用運送業者
        AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
        AND   (
                ((xdec.payments_judgment_classe = gv_pay_judg_g)    -- 支払判断区分（発日）
                AND (xoha.shipped_date >=  gd_target_date))         -- 出荷日
              OR
                ((xdec.payments_judgment_classe = gv_pay_judg_c)    -- 支払判断区分（着日）
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--                AND (xoha.arrival_date >=  gd_target_date))         -- 着荷日
                AND (NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                                 >=  gd_target_date)) -- 着荷日(着荷予定日)
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
              )
        -- 受注タイプ情報VIEW2
        AND   xoha.order_type_id       = xotv.transaction_type_id -- 受注タイプID
        AND (
              ((xotv.shipping_shikyu_class  = gv_shipping)         -- 出荷依頼
              AND  (xoha.result_deliver_to  IS NOT NULL))          -- 出荷先_実績
            OR
              ((xotv.shipping_shikyu_class  = gv_shikyu)            -- 支給依頼
              AND (xotv.auto_create_po_class = '0'))                -- 自動作成発注区分「NO」
            )
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
              AND  (xoha.last_update_date <= gd_sysdate))
            OR (xoha.request_no IN (SELECT xola.request_no
                                  FROM xxwsh_order_lines_all xola    -- 受注明細アドオン
                                  WHERE (xola.last_update_date > gd_last_process_date)  -- 受注明細：前回処理日付
                                  AND   (xola.last_update_date <= gd_sysdate)))
            )
        UNION ALL
        -- ==================================================
        -- 配車解除された移動実績情報 抽出
        -- ==================================================
        SELECT    gv_type_move        AS results_type   -- タイプ（移動）
                , xmrih.mov_num       AS request_no     -- 移動番号
        FROM  xxinv_mov_req_instr_headers    xmrih,     -- 移動依頼/指示ヘッダ(アドオン)
              xxwip_delivery_company         xdec       -- 運賃用運送業者アドオンマスタ
        WHERE xmrih.actual_ship_date IS NOT NULL            -- 出庫実績日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--        AND   xmrih.actual_arrival_date IS NOT NULL         -- 入庫実績日
        AND  (xmrih.actual_arrival_date IS NOT NULL           -- 入庫実績日
          OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- 入庫予定日
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
        AND   xmrih.actual_shipping_method_code IS NOT NULL -- 配送区分_実績
        AND   xmrih.actual_freight_carrier_code IS NOT NULL -- 運送業者_実績
        AND   xmrih.delivery_no IS NULL                     -- 配送No
        AND   xmrih.item_class = xdec.goods_classe                              -- 商品区分
        AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- 運送業者
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- 適用開始日
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- 適用終了日
        AND   (
                ((xdec.payments_judgment_classe = gv_pay_judg_g)      -- 支払判断区分（発日）
                AND (xmrih.actual_ship_date    >=  gd_target_date))   -- 出庫実績日
              OR
                ((xdec.payments_judgment_classe = gv_pay_judg_c)      -- 支払判断区分（着日）
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 START #####
--                AND (xmrih.actual_arrival_date >=  gd_target_date))   -- 入庫実績日
                AND (NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                                  >=  gd_target_date)) -- 入庫実績日(入庫予定日)
-- ##### 20081021 Ver.1.9 T_S_572 統合#392対応 END   #####
              )
       AND (
              ((xmrih.last_update_date    > gd_last_process_date)   -- 移動ヘッダ：前回処理日付
              AND (xmrih.last_update_date <= gd_sysdate))
            OR (xmrih.mov_hdr_id IN (SELECT xmril.mov_hdr_id
                                  FROM xxinv_mov_req_instr_lines  xmril                 -- 移動依頼/指示明細(アドオン)
                                  WHERE (xmril.last_update_date > gd_last_process_date) -- 移動明細：前回処理日付
                                  AND   (xmril.last_update_date <= gd_sysdate)))
            )
      ) carcan;*/
--
    SELECT  carcan.results_type         -- タイプ
          , carcan.request_no           -- 依頼No（移動番号）
    BULK COLLECT INTO gt_carcan_info_tab
    FROM
      (
        -- ==================================================
        -- 配車解除された受注実績、支給実績情報 抽出
        -- ==================================================
        -- 着日_支給依頼
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
        SELECT  /*+ leading(xoha otta ) use_nl(xoha otta ) */
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
                gv_type_shikyu        AS results_type
              , xoha.request_no       AS request_no   -- 依頼No
        FROM  xxwsh_order_headers_all        xoha,    -- 受注ヘッダアドオン
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--              oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
--              xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
              oe_transaction_types_all       otta    -- 受注タイプ情報VIEW2
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
-- （着荷予定日もしくは着荷日が設定されていることが前提）
        AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
--        AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xoha.delivery_no  IS NULL                       -- 配送No
        -- 運賃用運送業者
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
--        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
--        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
--        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
--        AND   xdec.payments_judgment_classe = gv_pay_judg_c    -- 支払判断区分（着日）
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                                 >=  gd_target_date -- 着荷日(着荷予定日)
        -- 受注タイプ情報VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND   xoha.prod_class          = gv_prod_div              -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
        AND   otta.attribute1  = gv_shikyu            -- 支給依頼
        AND   otta.attribute3  = '0'                -- 自動作成発注区分「NO」
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- 着日_出荷依頼
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
        SELECT  /*+ leading(xoha otta ) use_nl(xoha otta ) */
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
                gv_type_ship          AS results_type
              , xoha.request_no       AS request_no   -- 依頼No
        FROM  xxwsh_order_headers_all        xoha,    -- 受注ヘッダアドオン
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--              oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
--              xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
              oe_transaction_types_all       otta     -- 受注タイプ情報VIEW2
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
-- （着荷予定日もしくは着荷日が設定されていることが前提）
        AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
--        AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xoha.delivery_no  IS NULL                       -- 配送No
        -- 運賃用運送業者
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
--        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
--        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
--        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
--        AND   xdec.payments_judgment_classe = gv_pay_judg_c                   -- 支払判断区分（着日）
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                                 >=  gd_target_date           -- 着荷日(着荷予定日)
        -- 受注タイプ情報VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id   -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND   xoha.prod_class          = gv_prod_div                -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
        AND   otta.attribute1  = gv_shipping             -- 出荷依頼
        AND   xoha.result_deliver_to  IS NOT NULL                   -- 出荷先_実績
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- 発日_支給依頼
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
        SELECT  /*+ leading(xoha otta ) use_nl(xoha otta ) */
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
                gv_type_shikyu        AS results_type
              , xoha.request_no       AS request_no   -- 依頼No
        FROM  xxwsh_order_headers_all        xoha,    -- 受注ヘッダアドオン
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--              oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
--              xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
              oe_transaction_types_all       otta     -- 受注タイプ情報VIEW2
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
-- （着荷予定日もしくは着荷日が設定されていることが前提）
        AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
--        AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xoha.delivery_no  IS NULL                       -- 配送No
        -- 運賃用運送業者
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
--        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
--        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
--        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
--        AND   xdec.payments_judgment_classe = gv_pay_judg_g                   -- 支払判断区分（発日）
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xoha.shipped_date >=  gd_target_date                            -- 出荷日
        -- 受注タイプ情報VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND   xoha.prod_class          = gv_prod_div              -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
        AND   otta.attribute1  = gv_shikyu            -- 支給依頼
        AND   otta.attribute3 = '0'                -- 自動作成発注区分「NO」
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- 発日_出荷依頼
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
        SELECT  /*+ leading(xoha otta ) use_nl(xoha otta ) */
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
                gv_type_ship          AS results_type
              , xoha.request_no       AS request_no   -- 依頼No
        FROM  xxwsh_order_headers_all        xoha,    -- 受注ヘッダアドオン
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--              oe_transaction_types_all       otta,    -- 受注タイプ情報VIEW2
--              xxwip_delivery_company         xdec     -- 運賃用運送業者アドオンマスタ
              oe_transaction_types_all       otta     -- 受注タイプ情報VIEW2
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        WHERE xoha.latest_external_flag = 'Y'                 -- 最新フラグ 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- 出荷日
-- （着荷予定日もしくは着荷日が設定されていることが前提）
        AND   (xoha.arrival_date           IS NOT NULL    -- 着荷日
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- 着荷予定日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.result_shipping_method_code IS NOT NULL    -- 配送区分_実績
--        AND   xoha.result_freight_carrier_code IS NOT NULL    -- 運送業者_実績
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xoha.delivery_no  IS NULL                       -- 配送No
        -- 運賃用運送業者
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xoha.prod_class = xdec.goods_classe                             -- 商品区分
--        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- 運送業者
--        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- 適用開始日
--        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- 適用終了日
--        AND   xdec.payments_judgment_classe = gv_pay_judg_g                   -- 支払判断区分（発日）
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xoha.shipped_date >=  gd_target_date                            -- 出荷日
        -- 受注タイプ情報VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id -- 受注タイプID
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND   xoha.prod_class          = gv_prod_div              -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
        AND   otta.attribute1  = gv_shipping           -- 出荷依頼
        AND   xoha.result_deliver_to  IS NOT NULL                 -- 出荷先_実績
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- 受注ヘッダ：前回処理日付
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- 受注明細アドオン
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- 受注明細：前回処理日付
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- ==================================================
        -- 配車解除された移動実績情報 抽出
        -- ==================================================
        -- 着日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        SELECT /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
        SELECT /*+ leading (xmrih ) use_nl (xmrih ) */
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
                  gv_type_move        AS results_type   -- タイプ（移動）
                , xmrih.mov_num       AS request_no     -- 移動番号
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        FROM  xxinv_mov_req_instr_headers    xmrih,     -- 移動依頼/指示ヘッダ(アドオン)
--              xxwip_delivery_company         xdec       -- 運賃用運送業者アドオンマスタ
        FROM  xxinv_mov_req_instr_headers    xmrih      -- 移動依頼/指示ヘッダ(アドオン)
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        WHERE xmrih.actual_ship_date IS NOT NULL            -- 出庫実績日
        AND  (xmrih.actual_arrival_date IS NOT NULL           -- 入庫実績日
          OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- 入庫予定日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xmrih.actual_shipping_method_code IS NOT NULL -- 配送区分_実績
--        AND   xmrih.actual_freight_carrier_code IS NOT NULL -- 運送業者_実績
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xmrih.delivery_no IS NULL                     -- 配送No
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xmrih.item_class = xdec.goods_classe                              -- 商品区分
--        AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- 運送業者
--        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- 適用開始日
--        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- 適用終了日
--        AND   xdec.payments_judgment_classe = gv_pay_judg_c                     -- 支払判断区分（着日）
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND   xmrih.item_class = gv_prod_div                                      -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
        AND   NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                                  >=  gd_target_date            -- 入庫実績日(入庫予定日)
       AND (
              ((xmrih.last_update_date    > gd_last_process_date)   -- 移動ヘッダ：前回処理日付
              AND (xmrih.last_update_date <= gd_sysdate))
            OR (EXISTS (SELECT 1
                        FROM   xxinv_mov_req_instr_lines  xmril                 -- 移動依頼/指示明細(アドオン)
                        WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                        AND    xmril.last_update_date > gd_last_process_date -- 移動明細：前回処理日付
                        AND    xmril.last_update_date <= gd_sysdate
                        AND    ROWNUM = 1))
            )
        UNION ALL
        -- 発日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        SELECT  /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
        SELECT  /*+ leading (xmrih ) use_nl (xmrih ) */
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
                  gv_type_move        AS results_type   -- タイプ（移動）
                , xmrih.mov_num       AS request_no     -- 移動番号
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        FROM  xxinv_mov_req_instr_headers    xmrih,     -- 移動依頼/指示ヘッダ(アドオン)
--              xxwip_delivery_company         xdec       -- 運賃用運送業者アドオンマスタ
        FROM  xxinv_mov_req_instr_headers    xmrih      -- 移動依頼/指示ヘッダ(アドオン)
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        WHERE xmrih.actual_ship_date IS NOT NULL            -- 出庫実績日
        AND  (xmrih.actual_arrival_date IS NOT NULL           -- 入庫実績日
          OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- 入庫予定日
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xmrih.actual_shipping_method_code IS NOT NULL -- 配送区分_実績
--        AND   xmrih.actual_freight_carrier_code IS NOT NULL -- 運送業者_実績
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
        AND   xmrih.delivery_no IS NULL                     -- 配送No
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 start *----------*
--        AND   xmrih.item_class = xdec.goods_classe                              -- 商品区分
--        AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- 運送業者
--        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- 適用開始日
--        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- 適用終了日
--        AND   xdec.payments_judgment_classe = gv_pay_judg_g                     -- 支払判断区分（発日）
-- *----------* 2009/05/29 Ver.1.27 本番#1505対応 end   *----------*
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND   xmrih.item_class = gv_prod_div                                      -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
        AND   xmrih.actual_ship_date    >=  gd_target_date                      -- 出庫実績日
       AND (
              ((xmrih.last_update_date    > gd_last_process_date)   -- 移動ヘッダ：前回処理日付
              AND (xmrih.last_update_date <= gd_sysdate))
            OR (EXISTS (SELECT 1
                        FROM   xxinv_mov_req_instr_lines  xmril                 -- 移動依頼/指示明細(アドオン)
                        WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                        AND    xmril.last_update_date > gd_last_process_date -- 移動明細：前回処理日付
                        AND    xmril.last_update_date <= gd_sysdate
                        AND    ROWNUM = 1))
            )
      ) carcan;
-- ##### 20081125 Ver.1.13 本番#104対応 END #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_req_no：配車解除件数：' || TO_CHAR(gt_carcan_info_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_carcan_req_no;
--
  /**********************************************************************************
   * Procedure Name   : get_carcan_deliv_no
   * Description      : 配車解除配送No抽出(A-25-2)
   ***********************************************************************************/
  PROCEDURE get_carcan_deliv_no(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_carcan_deliv_no'; -- プログラム名
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
    cv_deliv_n    CONSTANT VARCHAR2(1) := '0'; -- 重複なし
    cv_deliv_y    CONSTANT VARCHAR2(1) := '1'; -- 重複あり
--
    -- *** ローカル変数 ***
    ln_deliv        NUMBER;         -- 配送Noのカウンタ
    ln_deliv_flg    VARCHAR2(1);    -- 配送No重複フラグ
                                    --    0:重複なし
                                    --    1:重複あり
--
    -- *** ローカル・カーソル ***
    CURSOR cu_carcan_data
      ( p_request_no  xxwip_delivery_lines.request_no%TYPE )
    IS
      SELECT  xdl.delivery_no               -- 配送No
      FROM    xxwip_delivery_lines    xdl   -- 運賃明細アドオン
      WHERE   xdl.request_no = p_request_no -- 依頼No
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- * 依頼Noに対応した配送No抽出
    -- **************************************************
    -- 初期設定
    ln_deliv := 0;
--
    -- 配車解除の依頼Noループ
    <<req_date_loop>>
    FOR ln_index IN  gt_carcan_info_tab.FIRST.. gt_carcan_info_tab.LAST LOOP
--
        -- 依頼No
        carcan_request_no_tab(ln_index) := gt_carcan_info_tab(ln_index).request_no;
--
      -- 配車解除の配送No抽出ループ
      <<carcan_data_loop>>
      FOR re_carcan_data IN cu_carcan_data
        ( p_request_no => gt_carcan_info_tab(ln_index).request_no ) LOOP
--
        -- 配送No重複フラグ初期化（重複なし）
        ln_deliv_flg := cv_deliv_n;

        IF (carcan_deliv_no_tab.COUNT = 0 ) THEN
          -- 配送Noのカウンタインクリメント
          ln_deliv := ln_deliv + 1;
          -- 配送Noを設定
          carcan_deliv_no_tab(ln_deliv) := re_carcan_data.delivery_no ;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no：配送No（' 
                                              || TO_CHAR(ln_deliv) 
                                              || '）：' 
                                              || carcan_deliv_no_tab(ln_deliv));
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        ELSE
          -- 配送No重複チェックループ
          <<deliv_data_loop>>
          FOR ln_deliv_ind IN  carcan_deliv_no_tab.FIRST.. carcan_deliv_no_tab.LAST LOOP
--
            -- 今までの配送Noと今回の配送Noを比較
            IF (re_carcan_data.delivery_no = carcan_deliv_no_tab(ln_deliv_ind)) THEN
              -- 重複ありを設定
              ln_deliv_flg := cv_deliv_y;
            END IF;
          END LOOP carcan_data_loop ;
--
          -- 配送No重複チェック
          IF (ln_deliv_flg = cv_deliv_n) THEN
            -- 配送Noのカウンタインクリメント
            ln_deliv := ln_deliv + 1;
            -- 配送Noを設定
            carcan_deliv_no_tab(ln_deliv) := re_carcan_data.delivery_no ;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no：配送No（' 
                                              || TO_CHAR(ln_deliv) 
                                              || '）：' 
                                              || carcan_deliv_no_tab(ln_deliv));
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          END IF;
        END IF;
      END LOOP carcan_data_loop ;
    END LOOP req_date_loop;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no：配車解除された配送Noの件数：' || TO_CHAR(carcan_deliv_no_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_carcan_deliv_no;
--
  /**********************************************************************************
   * Procedure Name   : delete_carcan_req_no
   * Description      : 配車解除依頼No削除(A-25-3)
   ***********************************************************************************/
  PROCEDURE delete_carcan_req_no(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_carcan_req_no'; -- プログラム名
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
    IF (carcan_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃明細アドオン 配車解除 依頼No 削除
      -- **************************************************
      FORALL ln_index IN carcan_request_no_tab.FIRST .. carcan_request_no_tab.LAST
        DELETE FROM  xxwip_delivery_lines                     -- 運賃明細アドオン
        WHERE   request_no = carcan_request_no_tab(ln_index)  -- 配送No
      ;
--
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
  END delete_carcan_req_no;
--
  /**********************************************************************************
   * Procedure Name   : check_carcan_deliv_no
   * Description      : 配車解除配送No存在確認(A-25-4)
   ***********************************************************************************/
  PROCEDURE check_carcan_deliv_no(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_carcan_deliv_no'; -- プログラム名
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
    ln_deliv_no_cnt       NUMBER;
    ln_del_deliv_no_cnt   NUMBER;
    ln_upd_req_no_cnt     NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR cu_carcan_deliv_data
      ( p_delivery_no  xxwip_delivery_lines.delivery_no%TYPE )
    IS
      SELECT  xdl.request_no                    -- 依頼No
      FROM    xxwip_delivery_lines    xdl       -- 運賃明細アドオン
      WHERE   xdl.delivery_no = p_delivery_no   -- 配送No
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- * 依頼Noに対応した配送No抽出
    -- **************************************************
    -- 各カウンタ初期化
    ln_deliv_no_cnt     := 0;
    ln_del_deliv_no_cnt := 0;
    ln_upd_req_no_cnt   := 0;
--
    -- 0件の場合はチェックしない
    IF (carcan_deliv_no_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    -- 配車解除の配送Noループ
    <<deliv_date_loop>>
    FOR ln_index IN  carcan_deliv_no_tab.FIRST.. carcan_deliv_no_tab.LAST LOOP
--
      -- 運賃明細アドオンに配送Noが存在するか確認
-- ##### 20081125 MOD 本番#104 START #####
      --SELECT  COUNT(*)
      SELECT  COUNT(1)
-- ##### 20081125 MOD 本番#104 END #####
      INTO    ln_deliv_no_cnt
      FROM    xxwip_delivery_lines
      WHERE   DELIVERY_NO = carcan_deliv_no_tab(ln_index);
--
      -- 存在しない場合
      IF (ln_deliv_no_cnt = 0) THEN
        -- 存在しない場合、対象の配送Noを設定
        ln_del_deliv_no_cnt := ln_del_deliv_no_cnt + 1;
        d_can_deliv_no_tab(ln_del_deliv_no_cnt) := carcan_deliv_no_tab(ln_index);
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no：運賃明細に存在しない：配送No：' || d_can_deliv_no_tab(ln_del_deliv_no_cnt));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- 存在する場合
      ELSE
        -- 配車解除の配送No抽出ループ
        <<carcan_data_loop>>
        FOR re_carcan_deliv_data IN cu_carcan_deliv_data
            ( p_delivery_no => carcan_deliv_no_tab(ln_index) ) LOOP
--
          -- 存在する場合、抽出した依頼Noを設定
          ln_upd_req_no_cnt := ln_upd_req_no_cnt + 1;
          u_can_request_no_tab(ln_upd_req_no_cnt) := re_carcan_deliv_data.request_no;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no：運賃明細に存在する：依頼No：' || u_can_request_no_tab(ln_upd_req_no_cnt));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
--
        END LOOP carcan_data_loop ;
      END IF;


    END LOOP deliv_date_loop;
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
  END check_carcan_deliv_no;
--
  /**********************************************************************************
   * Procedure Name   : update_carcan_deliv_line
   * Description      : 配車解除運賃明細アドオン更新(A-25-5)
   ***********************************************************************************/
  PROCEDURE update_carcan_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_carcan_deliv_line'; -- プログラム名
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
    IF (u_can_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃明細アドオン 最終更新日 更新
      -- **************************************************
      FORALL ln_index IN u_can_request_no_tab.FIRST .. u_can_request_no_tab.LAST
        UPDATE xxwip_delivery_lines       -- 運賃明細アドオン
        SET     last_updated_by           = gn_user_id           -- 最終更新者
              , last_update_date          = gd_sysdate           -- 最終更新日
              , last_update_login         = gn_login_id          -- 最終更新ログイン
              , request_id                = gn_conc_request_id   -- 要求ID
              , program_application_id    = gn_prog_appl_id      -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
              , program_id                = gn_conc_program_id   -- コンカレント・プログラムID
              , program_update_date       = gd_sysdate           -- プログラム更新日
        WHERE  request_no = u_can_request_no_tab(ln_index);
--
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
  END update_carcan_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : delete_carcan_deliv_head
   * Description      : 配車解除運賃ヘッダアドオン削除(A-25-6)
   ***********************************************************************************/
  PROCEDURE delete_carcan_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_carcan_deliv_head'; -- プログラム名
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
    IF (d_can_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃ヘッダアドオン 配車解除 配送No 削除
      -- **************************************************
      FORALL ln_index IN d_can_deliv_no_tab.FIRST .. d_can_deliv_no_tab.LAST
        DELETE FROM  xxwip_deliverys                        -- 運賃ヘッダアドオン
        WHERE   delivery_no = d_can_deliv_no_tab(ln_index)  -- 配送No
      ;
--
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
  END delete_carcan_deliv_head;
--
-- 配車解除対応の新規プロシージャーはここまで
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
--
  /**********************************************************************************
   * Procedure Name   : get_delinov_line_desc
   * Description      : 運賃明細アドオン対象配送No抽出(A-26)
   ***********************************************************************************/
  PROCEDURE get_delinov_line_desc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_line_delino'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- ##### 20080537 MOD 結合障害 混載処理 START #####
/***
    -- 運賃明細アドオン 配送No抽出
    SELECT  xdl.delivery_no             -- 配送No
          , MAX(xdl.distance)           -- 最長距離
          , SUM(xdl.qty)                -- 個数
          , SUM(xdl.delivery_weight)    -- 重量
    BULK COLLECT INTO gt_delivno_deliv_line_tab
    FROM   xxwip_delivery_lines    xdl          -- 運賃明細アドオン
    WHERE  xdl.last_update_date =  gd_sysdate   -- 最終更新日
    GROUP BY xdl.delivery_no                    -- 配送No（集約）
    ORDER BY xdl.delivery_no;                   -- 配送No（順序）
***/
    -- 運賃明細アドオン 配送No抽出
    SELECT  xdl.delivery_no             -- 配送No
          , MAX(xdl.distance)           -- 最長距離
          , SUM(xdl.qty)                -- 個数
          , SUM(xdl.delivery_weight)    -- 重量
    BULK COLLECT INTO gt_delivno_deliv_line_tab
    FROM   xxwip_delivery_lines    xdl  -- 運賃明細アドオン
    WHERE  xdl.delivery_no IN ( SELECT  xdl.delivery_no                     -- 配送No
                                FROM    xxwip_delivery_lines    xdl         -- 運賃明細アドオン
                                WHERE   xdl.last_update_date =  gd_sysdate  -- 最終更新日
                                GROUP BY xdl.delivery_no)                   -- 配送No
    GROUP BY xdl.delivery_no    -- 配送No（集約）
    ORDER BY xdl.delivery_no;   -- 配送No（順序）
--
-- ##### 20080537 MOD 結合障害 混載処理 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line_delino：運賃明細アドオン対象配送No抽出 件数：' ||
                                                    TO_CHAR(gt_delivno_deliv_line_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_delinov_line_desc;
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_line
   * Description      : 運賃明細アドオン抽出(A-27)
   ***********************************************************************************/
  PROCEDURE get_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_line'; -- プログラム名
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
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- 運賃用運送業者
    lr_delivery_charges_tab   xxwip_common3_pkg.delivery_charges_rec;   -- 運賃
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- 配送距離
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
    ln_deliv_no_cnt           NUMBER;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ無の場合
    IF (gt_delivno_deliv_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<delivno_loop>>
    FOR ln_index IN  gt_delivno_deliv_line_tab.FIRST.. gt_delivno_deliv_line_tab.LAST LOOP
--
      -- **************************************************
      -- * 運賃明細アドオン 抽出
      -- **************************************************
        BEGIN
          SELECT   delivery_company_code     -- 運送業者
                 , delivery_no               -- 配送No
                 , invoice_no                -- 送り状No
                 , payments_judgment_classe  -- 支払判断区分
                 , ship_date                 -- 出庫日
                 , arrival_date              -- 到着日
                 , judgement_date            -- 判断日
                 , goods_classe              -- 商品区分
                 , mixed_code                -- 混載区分
                 , dellivary_classe          -- 配送区分
                 , whs_code                  -- 代表出庫倉庫コード
                 , code_division             -- 代表配送先コード区分
                 , shipping_address_code     -- 代表配送先コード
                 , order_type                -- 代表タイプ
                 , weight_capacity_class     -- 重量容積区分
                 , actual_distance           -- 最長実際距離
                 , outside_contract          -- 契約外区分
                 , transfer_location         -- 振替先
                 , NULL                      -- 混載数
                 , NULL                      -- 小口重量
                 , NULL                      -- 支払ピッキング単価
                 , NULL                      -- 運送費
                 , NULL                      -- リーフ混載割増
                 , NULL                      -- 混載割増金額
                 , NULL                      -- ピッキング料
          INTO  gt_deliv_line_tab(ln_index)
          FROM
            (
              SELECT  delivery_company_code     -- 運送業者
                    , delivery_no               -- 配送No
                    , invoice_no                -- 送り状No
                    , payments_judgment_classe  -- 支払判断区分
                    , ship_date                 -- 出庫日
                    , arrival_date              -- 到着日
                    , judgement_date            -- 判断日
                    , goods_classe              -- 商品区分
                    , mixed_code                -- 混載区分
                    , dellivary_classe          -- 配送区分
                    , whs_code                  -- 代表出庫倉庫コード
                    , code_division             -- 代表配送先コード区分
                    , shipping_address_code     -- 代表配送先コード
                    , order_type                -- 代表タイプ
                    , weight_capacity_class     -- 重量容積区分
                    , actual_distance           -- 最長実際距離
                    , outside_contract          -- 契約外区分
                    , transfer_location         -- 振替先
              FROM   xxwip_delivery_lines    xdl        -- 運賃明細アドオン
              WHERE  xdl.delivery_no  = gt_delivno_deliv_line_tab(ln_index).delivery_no -- 配送No
              AND    xdl.distance     = gt_delivno_deliv_line_tab(ln_index).distance    -- 最長距離
-- ##### 20080715 Ver.1.4 ST障害#455対応 START #####
--              ORDER BY xdl.delivery_no                    -- 配送No（順序）
              ORDER BY xdl.request_no                       -- 依頼No（順序）
-- ##### 20080715 Ver.1.4 ST障害#455対応 END   #####
            ) max_deliv_line
        WHERE ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_notfnd,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_delivno_deliv_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_delivno_deliv_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：########## 運賃明細アドオン抽出 ##########：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：運送業者：' || gt_deliv_line_tab(ln_index).delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：配送No  ：' || gt_deliv_line_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：最長距離：' || TO_CHAR(gt_delivno_deliv_line_tab(ln_index).distance));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
      -- 商品区分＝「ドリンク」且つ、混載区分＝「混載」の場合
      IF ((gt_deliv_line_tab(ln_index).goods_classe = gv_prod_class_drk)
        AND (gt_deliv_line_tab(ln_index).mixed_code = gv_target_y)) THEN
--
        -- **************************************************
        -- * 配送距離マスタ抽出
        -- **************************************************
        xxwip_common3_pkg.get_delivery_distance(
          gt_deliv_line_tab(ln_index).goods_classe,           -- 商品区分
          gt_deliv_line_tab(ln_index).delivery_company_code,  -- 運送業者
          gt_deliv_line_tab(ln_index).whs_code,               -- 出庫倉庫
          gt_deliv_line_tab(ln_index).code_division ,         -- コード区分
          gt_deliv_line_tab(ln_index).shipping_address_code,  -- 配送先コード
          gt_deliv_line_tab(ln_index).judgement_date,         -- 判断日
          lr_delivery_distance_tab,
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 車立距離 ＋ 混載割増距離を再設定
        gt_delivno_deliv_line_tab(ln_index).distance := lr_delivery_distance_tab.post_distance +
                                                        lr_delivery_distance_tab.consolid_add_distance;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：########## 配送距離マスタ抽出 ドリンク混載のみ ##########：' || TO_CHAR(ln_index));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：商品区分      ：' || gt_deliv_line_tab(ln_index).goods_classe);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：混載区分      ：' || gt_deliv_line_tab(ln_index).mixed_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：車立距離      ：' || TO_CHAR(lr_delivery_distance_tab.post_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：小口距離      ：' || TO_CHAR(lr_delivery_distance_tab.small_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：混載割増距離  ：' || TO_CHAR(lr_delivery_distance_tab.consolid_add_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：実際距離      ：' || TO_CHAR(lr_delivery_distance_tab.actual_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：最長距離（再設定）：' || TO_CHAR(gt_delivno_deliv_line_tab(ln_index).distance));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      END IF;
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
--
      -- **************************************************
      -- * 運賃明細混載数算出（A-28）
      -- **************************************************
      BEGIN
-- ##### 20081125 Ver.1.13 本番#104対応 START   #####
        --SELECT COUNT(*)
        SELECT COUNT(1)
-- ##### 20081125 Ver.1.13 本番#104対応 START   #####
        INTO   ln_deliv_no_cnt
        FROM
          (
            SELECT  xdl.delivery_no           as delivery_no
                  , xdl.code_division         as code_division
                  , xdl.shipping_address_code as shipping_address_code
            FROM    xxwip_delivery_lines    xdl          -- 運賃明細アドオン
            WHERE   xdl.delivery_no = gt_delivno_deliv_line_tab(ln_index).delivery_no    -- 配送No
            GROUP BY  xdl.delivery_no                   -- 配送No          （集約）
                    , xdl.code_division                 -- 配送先コード区分（集約）
                    , xdl.shipping_address_code        -- 配送先コード    （集約）
          ) deliv_line;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_notfnd,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- 混載区分 ＝ 混載 の場合
      IF (gt_deliv_line_tab(ln_index).mixed_code = gv_target_y) THEN
        -- 混載数に 取得件数－１ を設定
        gt_deliv_line_tab(ln_index).consolid_qty := ln_deliv_no_cnt -1;
--
      -- 上記以外の場合
      ELSE
        -- 混載数に０を設定
        gt_deliv_line_tab(ln_index).consolid_qty := 0;
      END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：##### 運賃明細混載数算出 #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：混載区分：' || gt_deliv_line_tab(ln_index).mixed_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：混載数  ：' || TO_CHAR(gt_deliv_line_tab(ln_index).consolid_qty));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- * 運賃算出（A-29）
      -- **************************************************
      -- 運賃用運送業者アドオンマスタ 抽出
      xxwip_common3_pkg.get_delivery_company(
        gt_deliv_line_tab(ln_index).goods_classe,           -- 商品区分
        gt_deliv_line_tab(ln_index).delivery_company_code,  -- 運送業者
        gt_deliv_line_tab(ln_index).judgement_date,         -- 判断日
        lr_delivery_company_tab,                            -- 運賃用運送業者レコード
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- *** 小口重量 ***
      gt_deliv_line_tab(ln_index).small_weight      := lr_delivery_company_tab.small_weight;
      -- *** 支払ピッキング単価 ***
      gt_deliv_line_tab(ln_index).pay_picking_amount:= lr_delivery_company_tab.pay_picking_amount;
--
      -- 運賃アドオンマスタ抽出
      xxwip_common3_pkg.get_delivery_charges(
        gv_pay,                                                 -- 支払請求区分
        gt_deliv_line_tab(ln_index).goods_classe,               -- 商品区分
        gt_deliv_line_tab(ln_index).delivery_company_code,      -- 運送業者
        gt_deliv_line_tab(ln_index).dellivary_classe,           -- 配送区分
        gt_delivno_deliv_line_tab(ln_index).distance,           -- 運賃距離
        gt_delivno_deliv_line_tab(ln_index).delivery_weight,    -- 重量
        gt_deliv_line_tab(ln_index).judgement_date,             -- 判断日
        lr_delivery_charges_tab,                                -- 運賃アドオンレコード
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- *** 運送費 ***
      gt_deliv_line_tab(ln_index).shipping_expenses := 
                          lr_delivery_charges_tab.shipping_expenses;
      -- *** リーフ混載割増 ***
      gt_deliv_line_tab(ln_index).leaf_consolid_add := 
                          lr_delivery_charges_tab.leaf_consolid_add;
--
      -- *** 混載割増金額 ***
      -- 商品区分＝リーフ、且つ、混載区分＝混載 の場合
      IF ((gt_deliv_line_tab(ln_index).goods_classe = gv_prod_class_lef)
        AND (gt_deliv_line_tab(ln_index).mixed_code = gv_target_y)) THEN
        -- リーフ混載割増 × 混載数
        gt_deliv_line_tab(ln_index).consolid_surcharge  := 
                                    gt_deliv_line_tab(ln_index).leaf_consolid_add *
                                    gt_deliv_line_tab(ln_index).consolid_qty;
      ELSE
        gt_deliv_line_tab(ln_index).consolid_surcharge  := 0;
      END IF;
--
      -- *** ピッキング料 ***
      -- 個数 × 支払ピッキング単価
      gt_deliv_line_tab(ln_index).picking_charge  := 
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--                                    ROUND(gt_delivno_deliv_line_tab(ln_index).qty *
--                                    gt_deliv_line_tab(ln_index).pay_picking_amount);
                                    CEIL(gt_delivno_deliv_line_tab(ln_index).qty *
                                    gt_deliv_line_tab(ln_index).pay_picking_amount);
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：########## 運賃算出 ##########');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：小口重量          ：' || TO_CHAR(gt_deliv_line_tab(ln_index).small_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：支払ピッキング単価：' || TO_CHAR(gt_deliv_line_tab(ln_index).pay_picking_amount));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：##### 運賃アドオンマスタ #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：運送費        ：' || TO_CHAR(gt_deliv_line_tab(ln_index).shipping_expenses));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：リーフ混載割増：' || TO_CHAR(gt_deliv_line_tab(ln_index).leaf_consolid_add));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：##### 条件 #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：商品区分：' || gt_deliv_line_tab(ln_index).goods_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：混載区分：' || gt_deliv_line_tab(ln_index).mixed_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：個数    ：' || TO_CHAR(gt_delivno_deliv_line_tab(ln_index).qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：##### 算出結果 #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：混載割増金額：' || TO_CHAR(gt_deliv_line_tab(ln_index).consolid_surcharge));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line：ピッキング料：' || TO_CHAR(gt_deliv_line_tab(ln_index).picking_charge));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP delivno_loop;
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
  END get_deliv_line;
--
--
  /**********************************************************************************
   * Procedure Name   : set_deliv_head
   * Description      : 運賃ヘッダアドオンPL/SQL表格納(A-30)
   ***********************************************************************************/
  PROCEDURE set_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_deliv_head'; -- プログラム名
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
    lv_charged_amount   xxwip_deliverys.charged_amount%TYPE;  -- 請求運賃
    lv_many_rate        xxwip_deliverys.many_rate%TYPE;       -- 諸料金
    lv_defined_flag     xxwip_deliverys.defined_flag%TYPE;    -- 支払確定区分
    lv_return_flag      xxwip_deliverys.return_flag%TYPE;     -- 支払確定戻
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
    lt_delivery_company_code      xxwip_deliverys.delivery_company_code%TYPE;     -- 運送業者
    lt_delivery_no                xxwip_deliverys.delivery_no%TYPE;               -- 配送No
    lt_payments_judgment_classe   xxwip_deliverys.payments_judgment_classe%TYPE;  -- 支払判断区分
    lt_ship_date                  xxwip_deliverys.ship_date%TYPE;                 -- 出庫日
    lt_arrival_date               xxwip_deliverys.arrival_date%TYPE;              -- 到着日
    lt_judgement_date             xxwip_deliverys.judgement_date%TYPE;            -- 判断日
    lt_goods_classe               xxwip_deliverys.goods_classe%TYPE;              -- 商品区分
    lt_mixed_code                 xxwip_deliverys.mixed_code%TYPE;                -- 混載区分
    lt_contract_rate              xxwip_deliverys.contract_rate%TYPE;             -- 契約運賃
    lt_balance                    xxwip_deliverys.balance%TYPE;                   -- 差額
    lt_total_amount               xxwip_deliverys.total_amount%TYPE;              -- 合計
    lt_distance                   xxwip_deliverys.distance%TYPE;                  -- 最長距離
    lt_delivery_classe            xxwip_deliverys.delivery_classe%TYPE;           -- 配送区分
    lt_whs_code                   xxwip_deliverys.whs_code%TYPE;                  -- 代表出庫倉庫コード
    lt_code_division              xxwip_deliverys.code_division%TYPE;             -- 代表配送先コード区分
    lt_shipping_address_code      xxwip_deliverys.shipping_address_code%TYPE;     -- 代表配送先コード
    lt_qty1                       xxwip_deliverys.qty1%TYPE;                      -- 個数１
    lt_delivery_weight1           xxwip_deliverys.delivery_weight1%TYPE;          -- 重量１
    lt_consolid_surcharge         xxwip_deliverys.consolid_surcharge%TYPE;        -- 混載割増金額
    lt_actual_distance            xxwip_deliverys.actual_distance%TYPE;           -- 最長実際距離
    lt_picking_charge             xxwip_deliverys.picking_charge%TYPE;            -- ピッキング料
    lt_consolid_qty               xxwip_deliverys.consolid_qty%TYPE;              -- 混載数
    lt_order_type                 xxwip_deliverys.order_type%TYPE;                -- 代表タイプ
    lt_weight_capacity_class      xxwip_deliverys.weight_capacity_class%TYPE;     -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
    ln_deliv_flg        VARCHAR2(1);    -- 受注ヘッダアドオン 存在フラグ Y:有 N:無
--
    ln_insert_cnt   NUMBER;  -- 登録用PL/SQL表 件数
    ln_update_cnt   NUMBER;  -- 更新用PL/SQL表 件数
    ln_delete_cnt   NUMBER;  -- 削除用PL/SQL表 件数
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
    -- 件数初期化
    ln_insert_cnt   := 0;
    ln_update_cnt   := 0;
    ln_delete_cnt   := 0;
--
    -- 対象データ無の場合
    IF (gt_deliv_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_deliv_line_tab.FIRST.. gt_deliv_line_tab.LAST LOOP
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：########## 受注明細アドオン #####：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：運送業者：' || gt_deliv_line_tab(ln_index).delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：配送No  ：' || gt_deliv_line_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  運賃ヘッダアドオン抽出
      -- **************************************************
      -- 存在フラグ初期化
      ln_deliv_flg := gv_ktg_no;
--
      BEGIN
        SELECT  xd.charged_amount   -- 請求運賃
              , xd.many_rate        -- 諸料金
              , xd.defined_flag     -- 支払確定区分
              , xd.return_flag      -- 支払確定戻
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
              , xd.delivery_company_code      -- 運送業者
              , xd.delivery_no                -- 配送No
              , xd.payments_judgment_classe   -- 支払判断区分
              , xd.ship_date                  -- 出庫日
              , xd.arrival_date               -- 到着日
              , xd.judgement_date             -- 判断日
              , xd.goods_classe               -- 商品区分
              , xd.mixed_code                 -- 混載区分
              , xd.contract_rate              -- 契約運賃
              , xd.balance                    -- 差額
              , xd.total_amount               -- 合計
              , xd.distance                   -- 最長距離
              , xd.delivery_classe            -- 配送区分
              , xd.whs_code                   -- 代表出庫倉庫コード
              , xd.code_division              -- 代表配送先コード区分
              , xd.shipping_address_code      -- 代表配送先コード
              , xd.qty1                       -- 個数１
              , xd.delivery_weight1           -- 重量１
              , xd.consolid_surcharge         -- 混載割増金額
              , xd.actual_distance            -- 最長実際距離
              , xd.picking_charge             -- ピッキング料
              , xd.consolid_qty               -- 混載数
              , xd.order_type                 -- 代表タイプ
              , xd.weight_capacity_class      -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
        INTO    lv_charged_amount
              , lv_many_rate
              , lv_defined_flag
              , lv_return_flag
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
              , lt_delivery_company_code      -- 運送業者
              , lt_delivery_no                -- 配送No
              , lt_payments_judgment_classe   -- 支払判断区分
              , lt_ship_date                  -- 出庫日
              , lt_arrival_date               -- 到着日
              , lt_judgement_date             -- 判断日
              , lt_goods_classe               -- 商品区分
              , lt_mixed_code                 -- 混載区分
              , lt_contract_rate              -- 契約運賃
              , lt_balance                    -- 差額
              , lt_total_amount               -- 合計
              , lt_distance                   -- 最長距離
              , lt_delivery_classe            -- 配送区分
              , lt_whs_code                   -- 代表出庫倉庫コード
              , lt_code_division              -- 代表配送先コード区分
              , lt_shipping_address_code      -- 代表配送先コード
              , lt_qty1                       -- 個数１
              , lt_delivery_weight1           -- 重量１
              , lt_consolid_surcharge         -- 混載割増金額
              , lt_actual_distance            -- 最長実際距離
              , lt_picking_charge             -- ピッキング料
              , lt_consolid_qty               -- 混載数
              , lt_order_type                 -- 代表タイプ
              , lt_weight_capacity_class      -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
        FROM   xxwip_deliverys      xd      -- 運賃ヘッダアドオン
        WHERE  xd.delivery_no = gt_deliv_line_tab(ln_index).delivery_no -- 配送No
        AND    xd.p_b_classe  = gv_pay ;                  -- 支払請求区分（支払）
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
          -- 存在フラグ Y を設定
          ln_deliv_flg := gv_ktg_yes;
--
        WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_deliverys,
                                                gv_tkn_key,
                                                gv_pay || ',' ||
                                                gt_deliv_line_tab(ln_index).delivery_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：########## 運賃ヘッダアドオン抽出 ##########：' || ln_deliv_flg);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：請求運賃    ：' || TO_CHAR(lv_charged_amount));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：諸料金      ：' || TO_CHAR(lv_many_rate));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：支払確定区分：' || lv_defined_flag);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：支払確定戻  ：' || lv_return_flag);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  運賃ヘッダアドオンにデータが存在しない場合
      -- **************************************************
      IF (ln_deliv_flg = gv_ktg_yes) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：運賃ヘッダアドオン INSERT');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 登録用PL/SQL表 件数
        ln_insert_cnt  := ln_insert_cnt + 1;
--
        -- 運送業者
        i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := 
                                    gt_deliv_line_tab(ln_index).delivery_company_code ;
        -- 配送No
        i_head_deliv_no_tab(ln_insert_cnt)       := gt_deliv_line_tab(ln_index).delivery_no ;
        -- 送り状No
        i_head_invoice_no_tab(ln_insert_cnt)     := gt_deliv_line_tab(ln_index).invoice_no ;
        -- 支払請求区分（支払）
        i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
        -- 支払判断区分
        i_head_pay_judg_cls_tab(ln_insert_cnt)   := 
                                    gt_deliv_line_tab(ln_index).payments_judgment_classe ;
        -- 出庫日
        i_head_ship_date_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).ship_date ;
        -- 到着日
        i_head_arrival_date_tab(ln_insert_cnt)   := gt_deliv_line_tab(ln_index).arrival_date ;
        -- 報告日
        i_head_report_date_tab(ln_insert_cnt)    := NULL ;
        -- 判断日
        i_head_judg_date_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).judgement_date ;
        -- 商品区分
        i_head_goods_cls_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).goods_classe ;
        -- 混載区分
        i_head_mixed_cd_tab(ln_insert_cnt)       := gt_deliv_line_tab(ln_index).mixed_code ;
        -- 請求運賃
        i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;
        -- 契約運賃
        i_head_contract_rate_tab(ln_insert_cnt)  := gt_deliv_line_tab(ln_index).shipping_expenses ;
        -- 諸料金
        i_head_many_rate_tab(ln_insert_cnt)      := NULL ;
        -- 最長距離
        i_head_distance_tab(ln_insert_cnt)       := gt_delivno_deliv_line_tab(ln_index).distance ;
        -- 配送区分
        i_head_deliv_cls_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).dellivary_classe ;
        -- 代表出庫倉庫コード
        i_head_whs_cd_tab(ln_insert_cnt)         := gt_deliv_line_tab(ln_index).whs_code ;
        -- 代表配送先コード区分
        i_head_cd_dvsn_tab(ln_insert_cnt)        := gt_deliv_line_tab(ln_index).code_division ;
        -- 代表配送先コード
        i_head_ship_addr_cd_tab(ln_insert_cnt)   := 
                                    gt_deliv_line_tab(ln_index).shipping_address_code ;
        -- 個数１
        i_head_qty1_tab(ln_insert_cnt)           := gt_delivno_deliv_line_tab(ln_index).qty ;
        -- 個数２
        i_head_qty2_tab(ln_insert_cnt)           := NULL ;
        -- 重量１
        i_head_deliv_wght1_tab(ln_insert_cnt)    := 
                                    gt_delivno_deliv_line_tab(ln_index).delivery_weight ;
        -- 重量２
        i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;
        -- 混載割増金額
        i_head_cnsld_srhrg_tab(ln_insert_cnt)    := gt_deliv_line_tab(ln_index).consolid_surcharge ;
        -- 最長実際距離
        i_head_actual_ditnc_tab(ln_insert_cnt)   := gt_deliv_line_tab(ln_index).actual_distance ;
        -- 通行料
        i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;
        -- ピッキング料
        i_head_pick_charge_tab(ln_insert_cnt)    := gt_deliv_line_tab(ln_index).picking_charge ;
        -- 混載数
        i_head_consolid_qty_tab(ln_insert_cnt)   := gt_deliv_line_tab(ln_index).consolid_qty ;
        -- 代表タイプ
        i_head_order_type_tab(ln_insert_cnt)     := gt_deliv_line_tab(ln_index).order_type ;
        -- 重量容積区分
        i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := 
                                    gt_deliv_line_tab(ln_index).weight_capacity_class ;
        -- 契約外区分
        i_head_out_cont_tab(ln_insert_cnt)       := gt_deliv_line_tab(ln_index).outside_contract ;
        i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;   -- 差異区分
        i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no ;    -- 支払確定区分
        i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no ;    -- 支払確定戻
        i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no ;    -- 画面更新有無区分
        -- 振替先
        i_head_trans_lcton_tab(ln_insert_cnt)    := gt_deliv_line_tab(ln_index).description ;
        -- 外部業者変更回数
        i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;
        -- 運賃摘要
        i_head_description_tab(ln_insert_cnt)    := NULL ;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
        -- 配車タイプ（通常配車）
        i_head_dispatch_type_tab(ln_insert_cnt) := gv_car_normal;
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
        -- 合計（運送費＋混載割増金額＋ピッキング料）
        i_head_total_amount_tab(ln_insert_cnt)   := 
                                      gt_deliv_line_tab(ln_index).shipping_expenses +
                                      gt_deliv_line_tab(ln_index).consolid_surcharge +
                                      gt_deliv_line_tab(ln_index).picking_charge ;
        -- 差額（合計 × -1）
        i_head_balance_tab(ln_insert_cnt)        := 
                                      (gt_deliv_line_tab(ln_index).shipping_expenses +
                                       gt_deliv_line_tab(ln_index).consolid_surcharge +
                                       gt_deliv_line_tab(ln_index).picking_charge) * -1 ;
--
      -- **************************************************
      -- ***  運賃ヘッダアドオンにデータが存在する場合
      -- **************************************************
      ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：運賃ヘッダアドオン UPDATE');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 更新用PL/SQL表 件数
        ln_update_cnt   := ln_update_cnt + 1;
--
        -- 運送業者
        u_head_deliv_cmpny_cd_tab(ln_update_cnt):= 
                              gt_deliv_line_tab(ln_index).delivery_company_code ;
        -- 配送No
        u_head_deliv_no_tab(ln_update_cnt)      := gt_deliv_line_tab(ln_index).delivery_no ;
        -- 送り状No
        u_head_invoice_no_tab(ln_update_cnt)    := gt_deliv_line_tab(ln_index).invoice_no ;
        -- 支払判断区分
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
-- 誤り修正
--        u_head_pay_judg_cls_tab(ln_update_cnt)  := gv_pay ;
        u_head_pay_judg_cls_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).payments_judgment_classe ;
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
        -- 出庫日
        u_head_ship_date_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).ship_date ;
        -- 到着日
        u_head_arrival_date_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).arrival_date ;
        -- 判断日
        u_head_judg_date_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).judgement_date ;
        -- 商品区分
        u_head_goods_cls_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).goods_classe ;
        -- 混載区分
        u_head_mixed_cd_tab(ln_update_cnt)      := gt_deliv_line_tab(ln_index).mixed_code ;
        -- 契約運賃
        u_head_contract_rate_tab(ln_update_cnt) := gt_deliv_line_tab(ln_index).shipping_expenses;
        -- 最長距離
        u_head_distance_tab(ln_update_cnt)      := gt_delivno_deliv_line_tab(ln_index).distance ;
        -- 配送区分
        u_head_deliv_cls_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).dellivary_classe ;
        -- 代表出庫倉庫コード
        u_head_whs_cd_tab(ln_update_cnt)        := gt_deliv_line_tab(ln_index).whs_code ;
        -- 代表配送先コード区分
        u_head_cd_dvsn_tab(ln_update_cnt)       := gt_deliv_line_tab(ln_index).code_division ;
        -- 代表配送先コード
        u_head_ship_addr_cd_tab(ln_update_cnt)  := 
                              gt_deliv_line_tab(ln_index).shipping_address_code ;
        -- 個数１
        u_head_qty1_tab(ln_update_cnt)          := gt_delivno_deliv_line_tab(ln_index).qty ;
        -- 重量１
        u_head_deliv_wght1_tab(ln_update_cnt)   := gt_delivno_deliv_line_tab(ln_index).delivery_weight ;
        -- 混載割増金額
        u_head_cnsld_srhrg_tab(ln_update_cnt)   := gt_deliv_line_tab(ln_index).consolid_surcharge ;
        -- 最長実際距離
        u_head_actual_ditnc_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).actual_distance ;
        -- ピッキング料
        u_head_pick_charge_tab(ln_update_cnt)   := gt_deliv_line_tab(ln_index).picking_charge ;
        -- 混載数
        u_head_consolid_qty_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).consolid_qty ;
        -- 代表タイプ
        u_head_order_type_tab(ln_update_cnt)    := gt_deliv_line_tab(ln_index).order_type ;
        -- 重量容積区分
        u_head_wigh_cpcty_cls_tab(ln_update_cnt):= 
                              gt_deliv_line_tab(ln_index).weight_capacity_class ;
        -- 契約外区分
        u_head_out_cont_tab(ln_update_cnt)      := gt_deliv_line_tab(ln_index).outside_contract ;
        -- 振替先
        u_head_trans_lcton_tab(ln_update_cnt)   := gt_deliv_line_tab(ln_index).description ;
--
        -- 合計（運送費＋混載割増運賃＋ピッキング料＋諸料金）
        u_head_total_amount_tab(ln_update_cnt)        := 
                                      gt_deliv_line_tab(ln_index).shipping_expenses +
                                      gt_deliv_line_tab(ln_index).consolid_surcharge +
                                      gt_deliv_line_tab(ln_index).picking_charge +
                                                          NVL(lv_many_rate, 0) ;
        -- 差額（請求運賃 － 合計）
        u_head_balance_tab(ln_update_cnt)             := 
                                      NVL(lv_charged_amount, 0) -
                                      (gt_deliv_line_tab(ln_index).shipping_expenses +
                                      gt_deliv_line_tab(ln_index).consolid_surcharge +
                                      gt_deliv_line_tab(ln_index).picking_charge +
                                      NVL(lv_many_rate, 0)) ;
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
        -- 請求運賃 ＝ NULL の場合
        IF (lv_charged_amount IS NULL) THEN
          -- Y を設定
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
--
        -- 請求運賃 ＝ NULL以外、且つ、差額＝0 以外の場合
        ELSIF ((lv_charged_amount IS NOT NULL)
          AND (u_head_balance_tab(ln_update_cnt) <> 0)) THEN
          -- Y を設定
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
--
        -- 上記以外
        ELSE
          -- N を設定
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_no ;
        END IF;
        -- *** 支払確定区分 ***
        IF (u_head_output_flag_tab(ln_update_cnt) = gv_ktg_yes) THEN
          -- N を設定
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_no ;
        ELSE
          -- Y を設定
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_yes ;
        END IF;
*****/
--
        -- *** 差異区分 ***
        IF (u_head_balance_tab(ln_update_cnt) <> 0) THEN
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
        ELSE
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_no ;
        END IF;
--
        -- *** 支払確定区分 ***
        -- 請求金額 IS NULL の場合
        IF (lv_charged_amount IS NULL) THEN
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_no ;
--
        -- 差異区分 = Y の場合
        ELSIF (u_head_output_flag_tab(ln_update_cnt) = gv_ktg_yes) THEN
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_no ;
--
        -- 上記以外の場合
        ELSE
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_yes ;
        END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
        -- *** 支払確定戻 ***
        -- 元の支払確定区分 ＝ Y の場合
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--        IF ((lv_defined_flag = gv_ktg_yes) 
--          AND ( u_head_balance_tab(ln_update_cnt) <> 0) ) THEN
        IF (lv_defined_flag = gv_ktg_yes) THEN
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
          -- Y を設定
          u_head_return_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
        -- 元の支払確定区分 ＝ Y、且つ、今回の支払確定区分 = N の場合
        ELSIF ((lv_defined_flag = gv_ktg_yes)
          AND ( u_head_balance_tab(ln_update_cnt) = 0) ) THEN
          -- N を設定
          u_head_return_flag_tab(ln_update_cnt)   := gv_ktg_no ;
        -- 上記以外の場合
        ELSE
          -- 登録済みの支払確定戻 を設定
          u_head_return_flag_tab(ln_update_cnt)   := lv_return_flag ;
*****/
--
        -- 上記以外の場合
        ELSE
          u_head_return_flag_tab(ln_update_cnt)   := gv_ktg_no ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
        END IF;
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
        -- 削除用PL/SQL表 登録
        -- 差額 <> 0 または、契約運賃 = 0 の場合
        IF (u_head_balance_tab(ln_update_cnt) <> 0)
          OR (gt_deliv_line_tab(ln_index).shipping_expenses = 0 ) THEN
*****/
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
        -- 請求データ削除条件の追加
        IF   (lt_delivery_company_code    <> u_head_deliv_cmpny_cd_tab(ln_update_cnt))    -- 運送業者
          OR (lt_delivery_no              <> u_head_deliv_no_tab(ln_update_cnt))          -- 配送No
          OR (lt_payments_judgment_classe <> u_head_pay_judg_cls_tab(ln_update_cnt))  -- 支払判断区分
          OR (lt_ship_date                <> u_head_ship_date_tab(ln_update_cnt))         -- 出庫日
          OR (lt_arrival_date             <> u_head_arrival_date_tab(ln_update_cnt))      -- 到着日
          OR (lt_judgement_date           <> u_head_judg_date_tab(ln_update_cnt))         -- 判断日
          OR (lt_goods_classe             <> u_head_goods_cls_tab(ln_update_cnt))         -- 商品区分
          OR (lt_mixed_code               <> u_head_mixed_cd_tab(ln_update_cnt))          -- 混載区分
          OR (lt_contract_rate            <> u_head_contract_rate_tab(ln_update_cnt))     -- 契約運賃
          OR (lt_balance                  <> u_head_balance_tab(ln_update_cnt))           -- 差額
          OR (lt_total_amount             <> u_head_total_amount_tab(ln_update_cnt))      -- 合計
          OR (lt_distance                 <> u_head_distance_tab(ln_update_cnt))          -- 最長距離
          OR (lt_delivery_classe          <> u_head_deliv_cls_tab(ln_update_cnt))         -- 配送区分
          OR (lt_whs_code                 <> u_head_whs_cd_tab(ln_update_cnt))            -- 代表出庫倉庫コード
          OR (lt_code_division            <> u_head_cd_dvsn_tab(ln_update_cnt))           -- 代表配送先コード区分
          OR (lt_shipping_address_code    <> u_head_ship_addr_cd_tab(ln_update_cnt))      -- 代表配送先コード
          OR (lt_qty1                     <> u_head_qty1_tab(ln_update_cnt))              -- 個数１
          OR (lt_delivery_weight1         <> u_head_deliv_wght1_tab(ln_update_cnt))       -- 重量１
          OR (lt_consolid_surcharge       <> u_head_cnsld_srhrg_tab(ln_update_cnt))       -- 混載割増金額
          OR (lt_actual_distance          <> u_head_actual_ditnc_tab(ln_update_cnt))      -- 最長実際距離
          OR (lt_picking_charge           <> u_head_pick_charge_tab(ln_update_cnt))       -- ピッキング料
          OR (lt_consolid_qty             <> u_head_consolid_qty_tab(ln_update_cnt))      -- 混載数
          OR (lt_order_type               <> u_head_order_type_tab(ln_update_cnt))        -- 代表タイプ
          OR (lt_weight_capacity_class    <> u_head_wigh_cpcty_cls_tab(ln_update_cnt))    -- 重量容積区分
        THEN
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：運賃ヘッダアドオン DELETE');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：運送業者             ：' || lt_delivery_company_code   || ' <> ' || u_head_deliv_cmpny_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：配送No               ：' || lt_delivery_no             || ' <> ' || u_head_deliv_no_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：支払判断区分         ：' || lt_payments_judgment_classe|| ' <> ' || u_head_pay_judg_cls_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：出庫日               ：' || TO_CHAR(lt_ship_date,'YYYY/MM/DD')     || ' <> ' ||
                                                                                         TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：到着日               ：' || TO_CHAR(lt_arrival_date,'YYYY/MM/DD')  || ' <> ' ||  
                                                                                         TO_CHAR(u_head_arrival_date_tab(ln_update_cnt),'YYYY/MM/DD'));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：判断日               ：' || TO_CHAR(lt_judgement_date,'YYYY/MM/DD')|| ' <> ' || 
                                                                                         TO_CHAR(u_head_judg_date_tab(ln_update_cnt),'YYYY/MM/DD'));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：商品区分             ：' || lt_goods_classe            || ' <> ' ||  u_head_goods_cls_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：混載区分             ：' || lt_mixed_code              || ' <> ' ||  u_head_mixed_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：契約運賃             ：' || TO_CHAR(lt_contract_rate)  || ' <> ' ||  TO_CHAR(u_head_contract_rate_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：差額                 ：' || TO_CHAR(lt_balance)        || ' <> ' ||  TO_CHAR(u_head_balance_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：合計                 ：' || TO_CHAR(lt_total_amount)   || ' <> ' ||  TO_CHAR(u_head_total_amount_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：最長距離             ：' || TO_CHAR(lt_distance)       || ' <> ' ||  TO_CHAR(u_head_distance_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：配送区分             ：' || lt_delivery_classe         || ' <> ' ||  u_head_deliv_cls_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：代表出庫倉庫コード   ：' || lt_whs_code                || ' <> ' ||  u_head_whs_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：代表配送先コード区分 ：' || lt_code_division           || ' <> ' ||  u_head_cd_dvsn_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：代表配送先コード     ：' || lt_shipping_address_code   || ' <> ' ||  u_head_ship_addr_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：個数１               ：' || TO_CHAR(lt_qty1)               || ' <> ' ||  TO_CHAR(u_head_qty1_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：重量１               ：' || TO_CHAR(lt_delivery_weight1)   || ' <> ' ||  TO_CHAR(u_head_deliv_wght1_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：混載割増金額         ：' || TO_CHAR(lt_consolid_surcharge) || ' <> ' ||  TO_CHAR(u_head_cnsld_srhrg_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：最長実際距離         ：' || TO_CHAR(lt_actual_distance)    || ' <> ' ||  TO_CHAR(u_head_actual_ditnc_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：ピッキング料         ：' || TO_CHAR(lt_picking_charge)     || ' <> ' ||  TO_CHAR(u_head_pick_charge_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：混載数               ：' || TO_CHAR(lt_consolid_qty)       || ' <> ' ||  TO_CHAR(u_head_consolid_qty_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：代表タイプ           ：' || lt_order_type                  || ' <> ' ||  u_head_order_type_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head：重量容積区分         ：' || lt_weight_capacity_class       || ' <> ' ||  u_head_wigh_cpcty_cls_tab(ln_update_cnt));
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 削除用PL/SQL表 件数
          ln_delete_cnt   := ln_delete_cnt + 1;
          -- 配送No
          d_head_deliv_no_tab(ln_delete_cnt)  := gt_deliv_line_tab(ln_index).delivery_no ;
--
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） START #####
          -- 実績変更による削除 ログ出力用領域格納
          gn_delete_data_idx := gn_delete_data_idx + 1;
-- ##### 20081229 Ver.1.19 本番#882対応 START #####
--          gt_delete_data_msg(gn_delete_data_idx) :=  d_head_deliv_no_tab(ln_delete_cnt);
          gt_delete_data_msg(gn_delete_data_idx) :=  u_head_deliv_no_tab(ln_update_cnt)     || '  ' ;  -- 配送No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || u_head_deliv_cmpny_cd_tab(ln_update_cnt) || '  ' ; -- 運送業者
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'); -- 出荷日
-- ##### 20081229 Ver.1.19 本番#882対応 END   #####
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） END   #####
--
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
        END IF;
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
        END IF;
*****/
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
      END IF;
--
    END LOOP deliv_loop;
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
  END set_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : get_carriers_schedule
   * Description      : 配車配送計画抽出(A-31)
   ***********************************************************************************/
  PROCEDURE get_carriers_schedule(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_carriers_schedule'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 配車配送計画 抽出
    /*SELECT    xcs.result_freight_carrier_code       -- 運送業者
            , xcs.delivery_no                       -- 配送No
            , xcs.shipped_date                      -- 出庫日
            , xcs.arrival_date                      -- 到着日
            , xcs.result_shipping_method_code       -- 配送区分
            , xcs.deliver_from                      -- 代表出庫倉庫コード
            , xcs.deliver_to_code_class             -- 代表配送先コード区分
            , xcs.deliver_to                        -- 代表配送先コード
            , xcs.weight_capacity_class             -- 重量容積区分
            , xdec.payments_judgment_classe         -- 支払判断区分
            , CASE xdec.payments_judgment_classe    -- 支払判断区分
              WHEN gv_pay_judg_g  THEN xcs.shipped_date -- 発日：出荷日
              WHEN gv_pay_judg_c  THEN xcs.arrival_date -- 着日：着荷日
              END
            , xott2v.mixed_class                    -- 混載区分
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
            , xcs.transaction_type                  -- 処理種別
            , xcs.prod_class                        -- 商品区分
            , xcs.non_slip_class                    -- 伝票なし配車区分
            , xcs.slip_number                       -- 送り状No
-- ##### 20081031 Ver.1.11 統合#531対応 START #####
--            , xcs.small_quantity                    -- 小口個数
            , NVL(xcs.small_quantity, 0)            -- 小口個数
-- ##### 20081031 Ver.1.11 統合#531対応 END   #####
            , xott2v.small_amount_class             -- 小口区分
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
    BULK COLLECT INTO gt_carriers_schedule_tab
    FROM  xxwsh_carriers_schedule       xcs,        -- 配車配送計画（アドオン）
          xxwsh_ship_method2_v          xott2v,     -- 配送区分情報VIEW2
          xxwip_delivery_company        xdec        -- 運賃用運送業者アドオンマスタ
    WHERE xcs.shipped_date IS NOT NULL              -- 出荷日
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
--    AND   gv_prod_class_lef = xdec.goods_classe                         -- 商品区分（リーフ固定）
    AND   xcs.arrival_date                IS NOT NULL -- 着荷日
    AND   xcs.result_freight_carrier_code IS NOT NULL -- 運送業者_実績
    AND   xcs.result_shipping_method_code IS NOT NULL -- 配送区分_実績
    AND   xcs.non_slip_class IN ( gv_non_slip_slp     --  伝票なし配車
                                , gv_non_slip_can)    --  伝票なし配車解除
    AND   xcs.prod_class          = xdec.goods_classe                   -- 商品区分
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
    AND   xcs.result_freight_carrier_code = xdec.delivery_company_code  -- 運送業者
    AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                  -- 適用開始日
    AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                  -- 適用終了日
    AND   xcs.result_shipping_method_code = xott2v.ship_method_code     -- 配送区分
    AND   xott2v.start_date_active  <= TRUNC(gd_sysdate)                -- 有効開始日
    AND   NVL(xott2v.end_date_active,TO_DATE('99991231','YYYYMMDD'))
                                     >= TRUNC(gd_sysdate)                -- 有効終了日
    AND   (
            ((xdec.payments_judgment_classe = gv_pay_judg_g)      -- 支払判断区分（発日）
            AND (xcs.shipped_date >=  gd_target_date))            -- 出荷日
          OR
            ((xdec.payments_judgment_classe = gv_pay_judg_c)      -- 支払判断区分（着日）
            AND (xcs.arrival_date >=  gd_target_date))            -- 着荷日
          )
    AND ((xcs.last_update_date > gd_last_process_date)            -- 前回処理日付
          AND  (xcs.last_update_date <= gd_sysdate));*/   
--
    SELECT
      car_info.result_freight_carrier_code
     ,car_info.delivery_no
     ,car_info.shipped_date
     ,car_info.arrival_date
     ,car_info.result_shipping_method_code
     ,car_info.deliver_from
     ,car_info.deliver_to_code_class
     ,car_info.deliver_to
     ,car_info.weight_capacity_class
     ,car_info.payments_judgment_classe
     ,car_info.judgment_date
     ,car_info.mixed_class
     ,car_info.transaction_type
     ,car_info.prod_class
     ,car_info.non_slip_class
     ,car_info.slip_number
     ,car_info.small_quantity
     ,car_info.small_amount_class
    BULK COLLECT INTO gt_carriers_schedule_tab
    FROM (
      -- 着日
      SELECT    xcs.result_freight_carrier_code      result_freight_carrier_code -- 運送業者
              , xcs.delivery_no                      delivery_no -- 配送No
              , xcs.shipped_date                     shipped_date -- 出庫日
              , xcs.arrival_date                     arrival_date -- 到着日
              , xcs.result_shipping_method_code      result_shipping_method_code -- 配送区分
              , xcs.deliver_from                     deliver_from -- 代表出庫倉庫コード
              , xcs.deliver_to_code_class            deliver_to_code_class -- 代表配送先コード区分
              , xcs.deliver_to                       deliver_to -- 代表配送先コード
              , xcs.weight_capacity_class            weight_capacity_class -- 重量容積区分
              , xdec.payments_judgment_classe        payments_judgment_classe -- 支払判断区分
              , xcs.arrival_date                     judgment_date -- 判断日
              , xott2v.mixed_class                   mixed_class -- 混載区分
              , xcs.transaction_type                 transaction_type -- 処理種別
              , xcs.prod_class                       prod_class -- 商品区分
              , xcs.non_slip_class                   non_slip_class -- 伝票なし配車区分
              , xcs.slip_number                      slip_number -- 送り状No
              , NVL(xcs.small_quantity, 0)           small_quantity -- 小口個数
              , xott2v.small_amount_class            small_amount_class -- 小口区分
      FROM  xxwsh_carriers_schedule       xcs,        -- 配車配送計画（アドオン）
            xxwsh_ship_method2_v          xott2v,     -- 配送区分情報VIEW2
            xxwip_delivery_company        xdec        -- 運賃用運送業者アドオンマスタ
      WHERE xcs.shipped_date IS NOT NULL              -- 出荷日        -- 商品区分（リーフ固定）
      AND   xcs.arrival_date                IS NOT NULL -- 着荷日
      AND   xcs.result_freight_carrier_code IS NOT NULL -- 運送業者_実績
      AND   xcs.result_shipping_method_code IS NOT NULL -- 配送区分_実績
      AND   xcs.non_slip_class IN ( gv_non_slip_slp     --  伝票なし配車
                                  , gv_non_slip_can)    --  伝票なし配車解除
      AND   xcs.prod_class          = xdec.goods_classe                   -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xcs.prod_class          = gv_prod_div                         -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xcs.result_freight_carrier_code = xdec.delivery_company_code  -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                  -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                  -- 適用終了日
      AND   xcs.result_shipping_method_code = xott2v.ship_method_code     -- 配送区分
      AND   xott2v.start_date_active  <= TRUNC(gd_sysdate)                -- 有効開始日
      AND   NVL(xott2v.end_date_active,TO_DATE('99991231','YYYYMMDD'))
                                       >= TRUNC(gd_sysdate)                -- 有効終了日
      AND   xdec.payments_judgment_classe = gv_pay_judg_c      -- 支払判断区分（着日）
      AND   xcs.arrival_date >=  gd_target_date                -- 着荷日
      AND ((xcs.last_update_date > gd_last_process_date)            -- 前回処理日付
            AND  (xcs.last_update_date <= gd_sysdate))
      UNION ALL
      -- 発日
      SELECT    xcs.result_freight_carrier_code      result_freight_carrier_code -- 運送業者
              , xcs.delivery_no                      delivery_no -- 配送No
              , xcs.shipped_date                     shipped_date -- 出庫日
              , xcs.arrival_date                     arrival_date -- 到着日
              , xcs.result_shipping_method_code      result_shipping_method_code -- 配送区分
              , xcs.deliver_from                     deliver_from -- 代表出庫倉庫コード
              , xcs.deliver_to_code_class            deliver_to_code_class -- 代表配送先コード区分
              , xcs.deliver_to                       deliver_to -- 代表配送先コード
              , xcs.weight_capacity_class            weight_capacity_class -- 重量容積区分
              , xdec.payments_judgment_classe        payments_judgment_classe -- 支払判断区分
              , xcs.shipped_date                     judgment_date-- 判断日
              , xott2v.mixed_class                   mixed_class -- 混載区分
              , xcs.transaction_type                 transaction_type -- 処理種別
              , xcs.prod_class                       prod_class -- 商品区分
              , xcs.non_slip_class                   non_slip_class -- 伝票なし配車区分
              , xcs.slip_number                      slip_number -- 送り状No
              , NVL(xcs.small_quantity, 0)           small_quantity -- 小口個数
              , xott2v.small_amount_class            small_amount_class -- 小口区分
      FROM  xxwsh_carriers_schedule       xcs,        -- 配車配送計画（アドオン）
            xxwsh_ship_method2_v          xott2v,     -- 配送区分情報VIEW2
            xxwip_delivery_company        xdec        -- 運賃用運送業者アドオンマスタ
      WHERE xcs.shipped_date IS NOT NULL              -- 出荷日        -- 商品区分（リーフ固定）
      AND   xcs.arrival_date                IS NOT NULL -- 着荷日
      AND   xcs.result_freight_carrier_code IS NOT NULL -- 運送業者_実績
      AND   xcs.result_shipping_method_code IS NOT NULL -- 配送区分_実績
      AND   xcs.non_slip_class IN ( gv_non_slip_slp     --  伝票なし配車
                                  , gv_non_slip_can)    --  伝票なし配車解除
      AND   xcs.prod_class          = xdec.goods_classe                   -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND   xcs.prod_class          = gv_prod_div                         -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      AND   xcs.result_freight_carrier_code = xdec.delivery_company_code  -- 運送業者
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                  -- 適用開始日
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                  -- 適用終了日
      AND   xcs.result_shipping_method_code = xott2v.ship_method_code     -- 配送区分
      AND   xott2v.start_date_active  <= TRUNC(gd_sysdate)                -- 有効開始日
      AND   NVL(xott2v.end_date_active,TO_DATE('99991231','YYYYMMDD'))
                                       >= TRUNC(gd_sysdate)                -- 有効終了日
      AND   xdec.payments_judgment_classe = gv_pay_judg_g      -- 支払判断区分（発日）
      AND   xcs.shipped_date >=  gd_target_date                -- 出荷日
      AND ((xcs.last_update_date > gd_last_process_date)            -- 前回処理日付
            AND  (xcs.last_update_date <= gd_sysdate))
      ) car_info
    ;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carriers_schedule：伝票なし配車 抽出件数：' || TO_CHAR(gt_carriers_schedule_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_carriers_schedule;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
-- A-32の処理を組換え
--
  /**********************************************************************************
   * Procedure Name   : set_carri_deliv_head
   * Description      : 伝票なし配車PL/SQL表格納 (A-32)
   ***********************************************************************************/
  PROCEDURE set_carri_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_carri_deliv_head'; -- プログラム名
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
    lv_delivery_no          xxwip_deliverys.delivery_no%TYPE;         -- 配送No
    lv_many_rate            xxwip_deliverys.many_rate%TYPE;           -- 諸料金
    lv_consolid_surcharge   xxwip_deliverys.consolid_surcharge%TYPE;  -- 混載割増金額
    lv_charged_amount       xxwip_deliverys.charged_amount%TYPE;      -- 請求金額
    lv_defined_flag         xxwip_deliverys.defined_flag%TYPE;        -- 支払確定区分
    lv_return_flag          xxwip_deliverys.return_flag%TYPE;         -- 支払確定戻
--
    lv_code_division    xxwip_deliverys.code_division%TYPE;   -- コード区分
--
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
    lt_delivery_company_code      xxwip_deliverys.delivery_company_code%TYPE;     -- 運送業者
    lt_delivery_no                xxwip_deliverys.delivery_no%TYPE;               -- 配送No
    lt_payments_judgment_classe   xxwip_deliverys.payments_judgment_classe%TYPE;  -- 支払判断区分
    lt_ship_date                  xxwip_deliverys.ship_date%TYPE;                 -- 出庫日
    lt_arrival_date               xxwip_deliverys.arrival_date%TYPE;              -- 到着日
    lt_judgement_date             xxwip_deliverys.judgement_date%TYPE;            -- 判断日
    lt_goods_classe               xxwip_deliverys.goods_classe%TYPE;              -- 商品区分
    lt_mixed_code                 xxwip_deliverys.mixed_code%TYPE;                -- 混載区分
    lt_contract_rate              xxwip_deliverys.contract_rate%TYPE;             -- 契約運賃
    lt_balance                    xxwip_deliverys.balance%TYPE;                   -- 差額
    lt_total_amount               xxwip_deliverys.total_amount%TYPE;              -- 合計
    lt_distance                   xxwip_deliverys.distance%TYPE;                  -- 最長距離
    lt_delivery_classe            xxwip_deliverys.delivery_classe%TYPE;           -- 配送区分
    lt_whs_code                   xxwip_deliverys.whs_code%TYPE;                  -- 代表出庫倉庫コード
    lt_code_division              xxwip_deliverys.code_division%TYPE;             -- 代表配送先コード区分
    lt_shipping_address_code      xxwip_deliverys.shipping_address_code%TYPE;     -- 代表配送先コード
    lt_qty1                       xxwip_deliverys.qty1%TYPE;                      -- 個数１
    lt_delivery_weight1           xxwip_deliverys.delivery_weight1%TYPE;          -- 重量１
    lt_consolid_surcharge         xxwip_deliverys.consolid_surcharge%TYPE;        -- 混載割増金額
    lt_actual_distance            xxwip_deliverys.actual_distance%TYPE;           -- 最長実際距離
    lt_picking_charge             xxwip_deliverys.picking_charge%TYPE;            -- ピッキング料
    lt_consolid_qty               xxwip_deliverys.consolid_qty%TYPE;              -- 混載数
    lt_order_type                 xxwip_deliverys.order_type%TYPE;                -- 代表タイプ
    lt_weight_capacity_class      xxwip_deliverys.weight_capacity_class%TYPE;     -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
    -- 運賃系マスタ 取得用
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- 運賃用運送業者
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- 配送距離
    lr_delivery_charges_tab   xxwip_common3_pkg.delivery_charges_rec;   -- 運賃
--
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
    ln_distance                   xxwip_deliverys.distance%TYPE;                  -- 最長距離
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
--
    ln_del_can_cnt    NUMBER;   -- 伝票なし配車解除 カウンタ
    ln_insert_cnt     NUMBER;   -- 登録用PL/SQL表 件数
    ln_update_cnt     NUMBER;   -- 更新用PL/SQL表 件数
    ln_delete_cnt     NUMBER;   -- 削除用PL/SQL表 件数
--
    ln_weight         NUMBER;   -- 重量
    ln_deliv_flg      VARCHAR2(1);  -- 運賃ヘッダアドオン 存在フラグ Y:有 N:無
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
    -- 対象データ無の場合
    IF (gt_carriers_schedule_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    -- カウンター初期値設定
    ln_del_can_cnt  := 0;
    ln_insert_cnt   := i_head_deliv_no_tab.COUNT;
    ln_update_cnt   := u_head_deliv_no_tab.COUNT;
    ln_delete_cnt   := d_head_deliv_no_tab.COUNT;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_carriers_schedule_tab.FIRST.. gt_carriers_schedule_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$$$$$$ 伝票なし配車 処理 $$$$$$$$$$：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：伝票なし配車区分：' || gt_carriers_schedule_tab(ln_index).non_slip_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：商品区分        ：' || gt_carriers_schedule_tab(ln_index).prod_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：小口区分        ：' || gt_carriers_schedule_tab(ln_index).small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：重量容積区分    ：' || gt_carriers_schedule_tab(ln_index).weight_capacity_class);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- *******************************************************************************************
      -- *** 「伝票なし配車解除」の場合
      -- *******************************************************************************************
      IF (gt_carriers_schedule_tab(ln_index).non_slip_class = gv_non_slip_can) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$ 伝票なし配車解除！ $$$$$');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：配送No：'|| gt_carriers_schedule_tab(ln_index).delivery_no);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 運賃ヘッダ伝票なし配車削除用PL/SQL表へ格納
        ln_del_can_cnt := ln_del_can_cnt + 1;
        d_slip_head_deliv_no_tab(ln_del_can_cnt) := gt_carriers_schedule_tab(ln_index).delivery_no;
--
      -- *******************************************************************************************
      -- *** 以下の条件の場合
      -- ***   伝票なし配車区分 ＝「伝票なし配車」
      -- ***   商品区分         ＝「リーフ」
      -- ***   小口区分         ＝「小口」
      -- *******************************************************************************************
      ELSIF ((gt_carriers_schedule_tab(ln_index).non_slip_class       = gv_non_slip_slp   )
        AND  (gt_carriers_schedule_tab(ln_index).prod_class           = gv_prod_class_lef )
        AND  (gt_carriers_schedule_tab(ln_index).small_amount_class   = gv_small_sum_yes  )) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$ 伝票なし配車（リーフ小口）運賃計算対象！ $$$$$');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：配送No：'|| gt_carriers_schedule_tab(ln_index).delivery_no);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  運賃用運送業者アドオンマスタ抽出
        -- **************************************************
        xxwip_common3_pkg.get_delivery_company(
          gt_carriers_schedule_tab(ln_index).prod_class,             -- 商品区分
          gt_carriers_schedule_tab(ln_index).delivery_company_code,  -- 運送業者
          gt_carriers_schedule_tab(ln_index).judgement_date,         -- 判断日
          lr_delivery_company_tab,                                   -- 運賃用運送業者レコード
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$ 運賃用運送業者アドオンマスタ抽出 $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：小口重量          ：'|| TO_CHAR(lr_delivery_company_tab.small_weight));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：支払ピッキング単価：'|| TO_CHAR(lr_delivery_company_tab.pay_picking_amount));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  配送距離アドオンマスタ抽出
        -- **************************************************
        -- 代表配送先コード区分変換
        xxwip_common3_pkg.change_code_division(
          gt_carriers_schedule_tab(ln_index).code_division, -- 代表配送先コード区分
          lv_code_division,                                 -- コード区分（運賃用）
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 配送距離アドオンマスタ抽出
        xxwip_common3_pkg.get_delivery_distance(
          gt_carriers_schedule_tab(ln_index).prod_class,            -- 商品区分
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- 運送業者
          gt_carriers_schedule_tab(ln_index).whs_code,              -- 出庫倉庫
          lv_code_division ,                                        -- コード区分
          gt_carriers_schedule_tab(ln_index).shipping_address_code, -- 配送先コード
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- 判断日
          lr_delivery_distance_tab,                                 -- 配送距離アドオンマスタレコード
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$ 配送距離アドオンマスタ抽出 $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：車立距離    ：'|| TO_CHAR(lr_delivery_distance_tab.post_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：小口距離    ：'|| TO_CHAR(lr_delivery_distance_tab.small_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：混載割増距離：'|| TO_CHAR(lr_delivery_distance_tab.consolid_add_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：実際距離    ：'|| TO_CHAR(lr_delivery_distance_tab.actual_distance));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  運賃アドオンマスタ抽出
        -- **************************************************
        -- 重量算出（小口個数×小口重量）
-- ##### 20090203 Ver.1.21 本番#1017対応 START #####
--        ln_weight := gt_carriers_schedule_tab(ln_index).small_quantity *
--                                          lr_delivery_company_tab.small_weight;
        ln_weight := CEIL(TRUNC(gt_carriers_schedule_tab(ln_index).small_quantity *
                                          lr_delivery_company_tab.small_weight, 1));
-- ##### 20090203 Ver.1.21 本番#1017対応 END   #####
--
        xxwip_common3_pkg.get_delivery_charges(
          gv_pay,                                                   -- 支払請求区分
          gt_carriers_schedule_tab(ln_index).prod_class,            -- 商品区分
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- 運送業者
          gt_carriers_schedule_tab(ln_index).dellivary_classe,      -- 配送区分
          lr_delivery_distance_tab.small_distance,                  -- 運賃距離（小口距離）
          ln_weight,                                                -- 重量
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- 判断日
          lr_delivery_charges_tab,                                  -- 運賃アドオンレコード
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$ 運賃アドオンマスタ抽出 $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運送費        ：'|| TO_CHAR(lr_delivery_charges_tab.shipping_expenses));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：リーフ混載割増：'|| TO_CHAR(lr_delivery_charges_tab.leaf_consolid_add));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  運賃ヘッダアドオン抽出
        -- **************************************************
        -- 存在フラグ初期化
        ln_deliv_flg := gv_ktg_yes;
--
        BEGIN
          SELECT  xd.delivery_no        -- 配送No
                , xd.many_rate          -- 諸料金
                , consolid_surcharge    -- 混載割増金額
                , charged_amount        -- 請求金額
                , xd.defined_flag       -- 支払確定区分
                , xd.return_flag        -- 支払確定戻
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
                , xd.delivery_company_code      -- 運送業者
                , xd.delivery_no                -- 配送No
                , xd.payments_judgment_classe   -- 支払判断区分
                , xd.ship_date                  -- 出庫日
                , xd.arrival_date               -- 到着日
                , xd.judgement_date             -- 判断日
                , xd.goods_classe               -- 商品区分
                , xd.mixed_code                 -- 混載区分
                , xd.contract_rate              -- 契約運賃
                , xd.balance                    -- 差額
                , xd.total_amount               -- 合計
                , xd.distance                   -- 最長距離
                , xd.delivery_classe            -- 配送区分
                , xd.whs_code                   -- 代表出庫倉庫コード
                , xd.code_division              -- 代表配送先コード区分
                , xd.shipping_address_code      -- 代表配送先コード
                , xd.qty1                       -- 個数１
                , xd.delivery_weight1           -- 重量１
                , xd.consolid_surcharge         -- 混載割増金額
                , xd.actual_distance            -- 最長実際距離
                , xd.picking_charge             -- ピッキング料
                , xd.consolid_qty               -- 混載数
                , xd.order_type                 -- 代表タイプ
                , xd.weight_capacity_class      -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
          INTO    lv_delivery_no
                , lv_many_rate
                , lv_consolid_surcharge
                , lv_charged_amount
                , lv_defined_flag
                , lv_return_flag
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
                , lt_delivery_company_code      -- 運送業者
                , lt_delivery_no                -- 配送No
                , lt_payments_judgment_classe   -- 支払判断区分
                , lt_ship_date                  -- 出庫日
                , lt_arrival_date               -- 到着日
                , lt_judgement_date             -- 判断日
                , lt_goods_classe               -- 商品区分
                , lt_mixed_code                 -- 混載区分
                , lt_contract_rate              -- 契約運賃
                , lt_balance                    -- 差額
                , lt_total_amount               -- 合計
                , lt_distance                   -- 最長距離
                , lt_delivery_classe            -- 配送区分
                , lt_whs_code                   -- 代表出庫倉庫コード
                , lt_code_division              -- 代表配送先コード区分
                , lt_shipping_address_code      -- 代表配送先コード
                , lt_qty1                       -- 個数１
                , lt_delivery_weight1           -- 重量１
                , lt_consolid_surcharge         -- 混載割増金額
                , lt_actual_distance            -- 最長実際距離
                , lt_picking_charge             -- ピッキング料
                , lt_consolid_qty               -- 混載数
                , lt_order_type                 -- 代表タイプ
                , lt_weight_capacity_class      -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
          FROM   xxwip_deliverys      xd      -- 運賃ヘッダアドオン
          WHERE  xd.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no -- 配送No
          AND    xd.p_b_classe = gv_pay ;                           -- 支払請求区分（支払）
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
            -- 存在フラグ Y を設定
            ln_deliv_flg := gv_ktg_no;
--
          WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_deliverys,
                                                  gv_tkn_key,
                                                  gv_pay || ',' ||
                                                  gt_carriers_schedule_tab(ln_index).delivery_no);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$ 運賃ヘッダアドオン $：' || ln_deliv_flg);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：配送No      ：'|| lv_delivery_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：諸料金      ：'|| TO_CHAR(lv_many_rate));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：混載金額    ：'|| TO_CHAR(lv_consolid_surcharge));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：請求金額    ：'|| TO_CHAR(lv_charged_amount));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：支払確定区分：'|| lv_defined_flag);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：支払確定戻  ：'|| lv_return_flag);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 運賃ヘッダアドオンにデータが存在しない場合
        IF (ln_deliv_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン INSERT');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- **************************************************
          -- ***  伝票なし配車（リーフ小口）登録
          -- **************************************************
          -- 登録用PL/SQL表 件数
          ln_insert_cnt  := ln_insert_cnt + 1;
--
          -- 運送業者
          i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- 配送No
          i_head_deliv_no_tab(ln_insert_cnt)       := gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- 送り状No
          i_head_invoice_no_tab(ln_insert_cnt)     := gt_carriers_schedule_tab(ln_index).slip_number ;
          -- 支払請求区分
          i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
          -- 支払判断区分
          i_head_pay_judg_cls_tab(ln_insert_cnt)   := gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- 出庫日
          i_head_ship_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- 到着日
          i_head_arrival_date_tab(ln_insert_cnt)   := gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- 報告日
          i_head_report_date_tab(ln_insert_cnt)    := NULL ;
          -- 判断日
          i_head_judg_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- 商品区分
          i_head_goods_cls_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).prod_class ;
          -- 混載区分
          i_head_mixed_cd_tab(ln_insert_cnt)       := gt_carriers_schedule_tab(ln_index).mixed_code  ;
          -- 請求運賃
          i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;
          -- 契約運賃
          i_head_contract_rate_tab(ln_insert_cnt)  := lr_delivery_charges_tab.shipping_expenses ;
--
          -- ピッキング料（支払ピッキング単価×小口個数）
          i_head_pick_charge_tab(ln_insert_cnt)    := lr_delivery_company_tab.pay_picking_amount *  
                                                      gt_carriers_schedule_tab(ln_index).small_quantity ;
--
          -- 合計（契約運賃＋ピッキング料）
          i_head_total_amount_tab(ln_insert_cnt)   := lr_delivery_charges_tab.shipping_expenses +
                                                      i_head_pick_charge_tab(ln_insert_cnt);
--
          -- 差額（合計 × -1）
          i_head_balance_tab(ln_insert_cnt)        := i_head_total_amount_tab(ln_insert_cnt) * -1 ;
--
          i_head_many_rate_tab(ln_insert_cnt)      := NULL ;  -- 諸料金
          -- 最長距離
          i_head_distance_tab(ln_insert_cnt)       := lr_delivery_distance_tab.small_distance ;
          -- 配送区分
          i_head_deliv_cls_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- 代表出庫倉庫コード
          i_head_whs_cd_tab(ln_insert_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
          -- 代表配送先コード区分
          i_head_cd_dvsn_tab(ln_insert_cnt)        := lv_code_division;
          -- 代表配送先コード
          i_head_ship_addr_cd_tab(ln_insert_cnt)   := gt_carriers_schedule_tab(ln_index).shipping_address_code;
          -- 個数１
          i_head_qty1_tab(ln_insert_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
          i_head_qty2_tab(ln_insert_cnt)           := NULL ;        -- 個数２
          -- 重量１
          i_head_deliv_wght1_tab(ln_insert_cnt)    := ln_weight ;
          i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;        -- 重量２
          i_head_cnsld_srhrg_tab(ln_insert_cnt)    := 0 ;           -- 混載割増金額
          -- 最長実際距離
          i_head_actual_ditnc_tab(ln_insert_cnt)   := lr_delivery_distance_tab.actual_distance ;
          i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;        -- 通行料
          i_head_consolid_qty_tab(ln_insert_cnt)   := 0 ;           -- 混載数
          -- 代表タイプ
          i_head_order_type_tab(ln_insert_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- 重量容積区分
          i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          i_head_out_cont_tab(ln_insert_cnt)       := NULL ;        -- 契約外区分
          i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;  -- 差異区分
          i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no  ;  -- 支払確定区分
          i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no  ;  -- 支払確定戻
          i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no  ;  -- 画面更新有無区分
          i_head_trans_lcton_tab(ln_insert_cnt)    := NULL ;        -- 振替先
          i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;           -- 外部業者変更回数
          i_head_description_tab(ln_insert_cnt)    := NULL ;        -- 運賃摘要
          -- 配車タイプ（伝票なし配車（リーフ小口））
          i_head_dispatch_type_tab(ln_insert_cnt)  := gv_carcan_target_y;
--
        -- 運賃ヘッダアドオンにデータが存在する場合
        ELSE
          -- **************************************************
          -- ***  伝票なし配車（リーフ小口）更新
          -- **************************************************
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン UPDATE');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 更新用PL/SQL表 件数
          ln_update_cnt   := ln_update_cnt + 1;
--
          -- 運送業者
          u_head_deliv_cmpny_cd_tab(ln_update_cnt) := gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- 配送No
          u_head_deliv_no_tab(ln_update_cnt)       := gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- 送り状No
          u_head_invoice_no_tab(ln_update_cnt)     := gt_carriers_schedule_tab(ln_index).slip_number ;
          -- 支払判断区分
          u_head_pay_judg_cls_tab(ln_update_cnt)   := gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- 出庫日
          u_head_ship_date_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- 到着日
          u_head_arrival_date_tab(ln_update_cnt)   := gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- 判断日
          u_head_judg_date_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- 商品区分
          u_head_goods_cls_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).prod_class ;
          -- 混載区分
          u_head_mixed_cd_tab(ln_update_cnt)       := gt_carriers_schedule_tab(ln_index).mixed_code ;
          -- 契約運賃
          u_head_contract_rate_tab(ln_update_cnt)  := lr_delivery_charges_tab.shipping_expenses ;
--
          -- ピッキング料（支払ピッキング単価×小口個数）
          u_head_pick_charge_tab(ln_update_cnt)    := lr_delivery_company_tab.pay_picking_amount *  
                                                      gt_carriers_schedule_tab(ln_index).small_quantity ;
--
          -- 合計（契約運賃 ＋ ピッキング料 ＋ 混載割増金額 ＋ 諸料金 ）
          u_head_total_amount_tab(ln_update_cnt)   := u_head_contract_rate_tab(ln_update_cnt) +
                                                      u_head_pick_charge_tab(ln_update_cnt)   +
                                                      NVL(lv_consolid_surcharge,0)            +
                                                      NVL(lv_many_rate,0) ;
          -- 差額（請求金額 － 合計）
          u_head_balance_tab(ln_update_cnt)        := NVL(lv_charged_amount,0) -
                                                      u_head_total_amount_tab(ln_update_cnt);
          -- 最長距離
          u_head_distance_tab(ln_update_cnt)       := lr_delivery_distance_tab.small_distance ;
          -- 配送区分
          u_head_deliv_cls_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- 代表出庫倉庫コード
          u_head_whs_cd_tab(ln_update_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
          -- 代表配送先コード区分
          u_head_cd_dvsn_tab(ln_update_cnt)        := lv_code_division;
          -- 代表配送先コード
          u_head_ship_addr_cd_tab(ln_update_cnt)   := gt_carriers_schedule_tab(ln_index).shipping_address_code;
          -- 個数１
          u_head_qty1_tab(ln_update_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
          -- 重量１
          u_head_deliv_wght1_tab(ln_update_cnt)    := ln_weight ;
          -- 混載割増金額
          u_head_cnsld_srhrg_tab(ln_update_cnt)    := lv_consolid_surcharge ;
          -- 最長実際距離
          u_head_actual_ditnc_tab(ln_update_cnt)   := lr_delivery_distance_tab.actual_distance  ;
          u_head_consolid_qty_tab(ln_update_cnt)   := 0 ;    -- 混載数
          -- 代表タイプ
          u_head_order_type_tab(ln_update_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- 重量容積区分
          u_head_wigh_cpcty_cls_tab(ln_update_cnt) := gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          u_head_out_cont_tab(ln_update_cnt)       := NULL ; -- 契約外区分
          u_head_trans_lcton_tab(ln_update_cnt)    := NULL ; -- 振替先
          -- 差異区分
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_yes;
          ELSE
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_no;
          END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
          ELSE
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_yes;
          END IF;
*****/
          -- 支払確定区分
          -- 請求金額 IS NULL の場合
          IF (lv_charged_amount IS NULL ) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- 差異区分 = Y の場合
          ELSIF (u_head_output_flag_tab(ln_update_cnt) = gv_ktg_yes) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- 上記以外の場合
          ELSE
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_yes;
          END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
-- ##### 20080805 Ver.1.5 ST事前確認障害 START #####
--          u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- 支払確定戻
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          IF ((lv_defined_flag = gv_ktg_yes) AND (u_head_balance_tab(ln_update_cnt) <> 0)) THEN
          -- 元の支払確定区分＝Y の場合
          IF (lv_defined_flag = gv_ktg_yes) THEN
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_yes ;  -- 支払確定戻
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          -- 元の支払確定区分＝Y 且つ、差額 = 0 の場合
          ELSIF ((lv_defined_flag = gv_ktg_yes) AND (u_head_balance_tab(ln_update_cnt) = 0)) THEN
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_no ;  -- 支払確定戻
          -- 上記以外の場合
          ELSE
            u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- 支払確定戻
*****/
--
          -- 上記以外の場合
          ELSE
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_no ;  -- 支払確定戻
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
          END IF;
-- ##### 20080805 Ver.1.5 ST事前確認障害 END   #####
--
          -- **************************************************
          -- ** 差額が0以外の配送Noの請求情報は全て削除対象
          -- **************************************************
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/***** 条件削除
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
*****/
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
          -- 請求データ削除条件の追加
          IF   (lt_delivery_company_code    <> u_head_deliv_cmpny_cd_tab(ln_update_cnt) ) -- 運送業者
            OR (lt_delivery_no              <> u_head_deliv_no_tab(ln_update_cnt)       ) -- 配送No
            OR (lt_payments_judgment_classe <> u_head_pay_judg_cls_tab(ln_update_cnt)   ) -- 支払判断区分
            OR (lt_ship_date                <> u_head_ship_date_tab(ln_update_cnt)      ) -- 出庫日
            OR (lt_arrival_date             <> u_head_arrival_date_tab(ln_update_cnt)   ) -- 到着日
            OR (lt_judgement_date           <> u_head_judg_date_tab(ln_update_cnt)      ) -- 判断日
            OR (lt_goods_classe             <> u_head_goods_cls_tab(ln_update_cnt)      ) -- 商品区分
            OR (lt_mixed_code               <> u_head_mixed_cd_tab(ln_update_cnt)       ) -- 混載区分
            OR (lt_contract_rate            <> u_head_contract_rate_tab(ln_update_cnt)  ) -- 契約運賃
            OR (lt_balance                  <> u_head_balance_tab(ln_update_cnt)        ) -- 差額
            OR (lt_total_amount             <> u_head_total_amount_tab(ln_update_cnt)   ) -- 合計
            OR (lt_distance                 <> u_head_distance_tab(ln_update_cnt)       ) -- 最長距離
            OR (lt_delivery_classe          <> u_head_deliv_cls_tab(ln_update_cnt)      ) -- 配送区分
            OR (lt_whs_code                 <> u_head_whs_cd_tab(ln_update_cnt)         ) -- 代表出庫倉庫コード
            OR (lt_code_division            <> u_head_cd_dvsn_tab(ln_update_cnt)        ) -- 代表配送先コード区分
            OR (lt_shipping_address_code    <> u_head_ship_addr_cd_tab(ln_update_cnt)   ) -- 代表配送先コード
            OR (lt_qty1                     <> u_head_qty1_tab(ln_update_cnt)           ) -- 個数１
            OR (lt_delivery_weight1         <> u_head_deliv_wght1_tab(ln_update_cnt)    ) -- 重量１
            OR (lt_consolid_surcharge       <> u_head_cnsld_srhrg_tab(ln_update_cnt)    ) -- 混載割増金額
            OR (lt_actual_distance          <> u_head_actual_ditnc_tab(ln_update_cnt)   ) -- 最長実際距離
            OR (lt_picking_charge           <> u_head_pick_charge_tab(ln_update_cnt)    ) -- ピッキング料
            OR (lt_consolid_qty             <> u_head_consolid_qty_tab(ln_update_cnt)   ) -- 混載数
            OR (lt_order_type               <> u_head_order_type_tab(ln_update_cnt)     ) -- 代表タイプ
            OR (lt_weight_capacity_class    <> u_head_wigh_cpcty_cls_tab(ln_update_cnt) ) -- 重量容積区分
          THEN
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン DELETE');
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
            -- 削除用PL/SQL表 件数インクリメント
            ln_delete_cnt   := ln_delete_cnt + 1;
            -- 配送No
            d_head_deliv_no_tab(ln_delete_cnt)  := gt_carriers_schedule_tab(ln_index).delivery_no ;
--
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） START #####
          -- 実績変更による削除 ログ出力用領域格納
          gn_delete_data_idx := gn_delete_data_idx + 1;
-- ##### 20081229 Ver.1.19 本番#882対応 START #####
--          gt_delete_data_msg(gn_delete_data_idx) :=  d_head_deliv_no_tab(ln_delete_cnt);
          gt_delete_data_msg(gn_delete_data_idx) :=  u_head_deliv_no_tab(ln_update_cnt)     || '  ' ;  -- 配送No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || u_head_deliv_cmpny_cd_tab(ln_update_cnt) || '  ' ; -- 運送業者
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'); -- 出荷日
-- ##### 20081229 Ver.1.19 本番#882対応 END   #####
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） END   #####
--
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
          END IF;
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          END IF;
*****/
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
        END IF;
--
      -- *******************************************************************************************
      -- 上記以外（伝票なし配車（リーフ小口以外）
      -- *******************************************************************************************
      ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$ 伝票なし配車（リーフ小口以外）！ $$$$$');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：配送No：' || gt_carriers_schedule_tab(ln_index).delivery_no);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--
        -- **************************************************
        -- ***  配送距離アドオンマスタ抽出
        -- **************************************************
        -- 代表配送先コード区分変換
        xxwip_common3_pkg.change_code_division(
          gt_carriers_schedule_tab(ln_index).code_division, -- 代表配送先コード区分
          lv_code_division,                                 -- コード区分（運賃用）
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 配送距離アドオンマスタ抽出
        xxwip_common3_pkg.get_delivery_distance(
          gt_carriers_schedule_tab(ln_index).prod_class,            -- 商品区分
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- 運送業者
          gt_carriers_schedule_tab(ln_index).whs_code,              -- 出庫倉庫
          lv_code_division ,                                        -- コード区分
          gt_carriers_schedule_tab(ln_index).shipping_address_code, -- 配送先コード
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- 判断日
          lr_delivery_distance_tab,                                 -- 配送距離アドオンマスタレコード
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$ 配送距離アドオンマスタ抽出 $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：車立距離    ：'|| TO_CHAR(lr_delivery_distance_tab.post_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：小口距離    ：'|| TO_CHAR(lr_delivery_distance_tab.small_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：混載割増距離：'|| TO_CHAR(lr_delivery_distance_tab.consolid_add_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：実際距離    ：'|| TO_CHAR(lr_delivery_distance_tab.actual_distance));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  運賃アドオンマスタ抽出
        -- **************************************************
        -- 重量算出（0にて抽出）
        ln_weight := 0;
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
        -- 距離設定
        -- 小口区分＝「小口」の場合
        IF (gt_carriers_schedule_tab(ln_index).small_amount_class   = gv_small_sum_yes) THEN
          ln_distance := lr_delivery_distance_tab.small_distance;
        -- 小口区分＝「車立」の場合
        ELSE
          ln_distance := lr_delivery_distance_tab.post_distance;
        END IF;
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
--
        xxwip_common3_pkg.get_delivery_charges(
          gv_pay,                                                   -- 支払請求区分
          gt_carriers_schedule_tab(ln_index).prod_class,            -- 商品区分
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- 運送業者
          gt_carriers_schedule_tab(ln_index).dellivary_classe,      -- 配送区分
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
--          lr_delivery_distance_tab.post_distance,                   -- 運賃距離（車立距離）
          ln_distance,                                              -- 運賃距離（車立距離）
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
          ln_weight,                                                -- 重量（0にて）
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- 判断日
          lr_delivery_charges_tab,                                  -- 運賃アドオンレコード
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$ 運賃アドオンマスタ抽出 $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運送費        ：'|| TO_CHAR(lr_delivery_charges_tab.shipping_expenses));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：リーフ混載割増：'|| TO_CHAR(lr_delivery_charges_tab.leaf_consolid_add));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
        -- **************************************************
        -- ***  運賃ヘッダアドオン抽出
        -- **************************************************
        -- 存在フラグ初期化
        ln_deliv_flg := gv_ktg_yes;
--
        BEGIN
          SELECT  xd.delivery_no        -- 配送No
                , xd.many_rate          -- 諸料金
                , xd.charged_amount     -- 請求金額
                , xd.defined_flag       -- 支払確定区分
                , xd.return_flag        -- 支払確定戻
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
                , xd.delivery_company_code      -- 運送業者
                , xd.delivery_no                -- 配送No
                , xd.payments_judgment_classe   -- 支払判断区分
                , xd.ship_date                  -- 出庫日
                , xd.arrival_date               -- 到着日
                , xd.judgement_date             -- 判断日
                , xd.goods_classe               -- 商品区分
                , xd.mixed_code                 -- 混載区分
                , xd.contract_rate              -- 契約運賃
                , xd.balance                    -- 差額
                , xd.total_amount               -- 合計
                , xd.distance                   -- 最長距離
                , xd.delivery_classe            -- 配送区分
                , xd.whs_code                   -- 代表出庫倉庫コード
                , xd.code_division              -- 代表配送先コード区分
                , xd.shipping_address_code      -- 代表配送先コード
                , xd.qty1                       -- 個数１
                , xd.delivery_weight1           -- 重量１
                , xd.consolid_surcharge         -- 混載割増金額
                , xd.actual_distance            -- 最長実際距離
                , xd.picking_charge             -- ピッキング料
                , xd.consolid_qty               -- 混載数
                , xd.order_type                 -- 代表タイプ
                , xd.weight_capacity_class      -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
          INTO    lv_delivery_no
                , lv_many_rate
                , lv_charged_amount
                , lv_defined_flag
                , lv_return_flag
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
                , lt_delivery_company_code      -- 運送業者
                , lt_delivery_no                -- 配送No
                , lt_payments_judgment_classe   -- 支払判断区分
                , lt_ship_date                  -- 出庫日
                , lt_arrival_date               -- 到着日
                , lt_judgement_date             -- 判断日
                , lt_goods_classe               -- 商品区分
                , lt_mixed_code                 -- 混載区分
                , lt_contract_rate              -- 契約運賃
                , lt_balance                    -- 差額
                , lt_total_amount               -- 合計
                , lt_distance                   -- 最長距離
                , lt_delivery_classe            -- 配送区分
                , lt_whs_code                   -- 代表出庫倉庫コード
                , lt_code_division              -- 代表配送先コード区分
                , lt_shipping_address_code      -- 代表配送先コード
                , lt_qty1                       -- 個数１
                , lt_delivery_weight1           -- 重量１
                , lt_consolid_surcharge         -- 混載割増金額
                , lt_actual_distance            -- 最長実際距離
                , lt_picking_charge             -- ピッキング料
                , lt_consolid_qty               -- 混載数
                , lt_order_type                 -- 代表タイプ
                , lt_weight_capacity_class      -- 重量容積区分
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
          FROM   xxwip_deliverys      xd      -- 運賃ヘッダアドオン
          WHERE  xd.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no -- 配送No
          AND    xd.p_b_classe = gv_pay ;                           -- 支払請求区分（支払）
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
            -- 存在フラグ Y を設定
            ln_deliv_flg := gv_ktg_no;
--
          WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_deliverys,
                                                  gv_tkn_key,
                                                  gv_pay || ',' ||
                                                  gt_carriers_schedule_tab(ln_index).delivery_no);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$ 運賃ヘッダアドオン $：' || ln_deliv_flg);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：配送No      ：'|| lv_delivery_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：諸料金      ：'|| TO_CHAR(lv_many_rate));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：支払確定区分：'|| lv_defined_flag);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：支払確定戻  ：'|| lv_return_flag);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 運賃ヘッダアドオンにデータが存在しない場合
        IF (ln_deliv_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン INSERT');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- **************************************************
          -- ***  伝票なし配車（リーフ小口以外）登録
          -- **************************************************
          -- 登録用PL/SQL表 件数
          ln_insert_cnt  := ln_insert_cnt + 1;
--
          -- 運送業者
          i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- 配送No
          i_head_deliv_no_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- 送り状No
          i_head_invoice_no_tab(ln_insert_cnt)     := 
                            gt_carriers_schedule_tab(ln_index).slip_number ;
          -- 支払請求区分
          i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
          -- 支払判断区分
          i_head_pay_judg_cls_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- 出庫日
          i_head_ship_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- 到着日
          i_head_arrival_date_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- 報告日
          i_head_report_date_tab(ln_insert_cnt)    := NULL ;
          -- 判断日
          i_head_judg_date_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- 商品区分
          i_head_goods_cls_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).prod_class ;
          -- 混載区分
          i_head_mixed_cd_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).mixed_code  ;
          i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;  -- 請求運賃
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          i_head_contract_rate_tab(ln_insert_cnt)  := 0 ;     -- 契約運賃
          i_head_balance_tab(ln_insert_cnt)        := 0 ;     -- 差額
          i_head_total_amount_tab(ln_insert_cnt)   := 0 ;     -- 合計
*****/
          -- 契約運賃（重量=0にて運送費抽出）
          i_head_contract_rate_tab(ln_insert_cnt)  := lr_delivery_charges_tab.shipping_expenses;
--
          -- 差額（合計 × -1）
          i_head_balance_tab(ln_insert_cnt)        := i_head_contract_rate_tab(ln_insert_cnt) * -1 ;
          -- 合計（運送費）
          i_head_total_amount_tab(ln_insert_cnt)   := i_head_contract_rate_tab(ln_insert_cnt) ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          i_head_many_rate_tab(ln_insert_cnt)      := NULL ;  -- 諸料金
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          i_head_distance_tab(ln_insert_cnt)       := 0 ;     -- 最長距離
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
          -- 最長距離（車立距離 or 小口距離）
--          i_head_distance_tab(ln_insert_cnt)       := lr_delivery_distance_tab.post_distance ;
          i_head_distance_tab(ln_insert_cnt) := ln_distance;
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####

-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          -- 配送区分
          i_head_deliv_cls_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- 代表出庫倉庫コード
          i_head_whs_cd_tab(ln_insert_cnt)         := 
                            gt_carriers_schedule_tab(ln_index).whs_code;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            i_head_cd_dvsn_tab(ln_insert_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
*****/
          -- 代表配送先コード区分
          i_head_cd_dvsn_tab(ln_insert_cnt) := lv_code_division;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          -- 代表配送先コード
          i_head_ship_addr_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          i_head_qty1_tab(ln_insert_cnt)           := 0 ;           -- 個数１
          -- 個数１（小口個数を設定）
          i_head_qty1_tab(ln_insert_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          i_head_qty2_tab(ln_insert_cnt)           := NULL ;        -- 個数２
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          i_head_deliv_wght1_tab(ln_insert_cnt)    := 0 ;           -- 重量１
          i_head_deliv_wght1_tab(ln_insert_cnt)    := ln_weight ;           -- 重量１
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;        -- 重量２
          i_head_cnsld_srhrg_tab(ln_insert_cnt)    := 0 ;           -- 混載割増金額
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          i_head_actual_ditnc_tab(ln_insert_cnt)   := 0 ;           -- 最長実際距離
          -- 最長実際距離
          i_head_actual_ditnc_tab(ln_insert_cnt)   := lr_delivery_distance_tab.actual_distance ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;        -- 通行料
          i_head_pick_charge_tab(ln_insert_cnt)    := 0 ;           -- ピッキング料
          i_head_consolid_qty_tab(ln_insert_cnt)   := 0 ;           -- 混載数
          -- 代表タイプ
          i_head_order_type_tab(ln_insert_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- 重量容積区分
          i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          i_head_out_cont_tab(ln_insert_cnt)       := NULL ;        -- 契約外区分
          i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;  -- 差異区分
          i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no  ;  -- 支払確定区分
          i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no  ;  -- 支払確定戻
          i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no  ;  -- 画面更新有無区分
          i_head_trans_lcton_tab(ln_insert_cnt)    := NULL ;        -- 振替先
          i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;           -- 外部業者変更回数
          i_head_description_tab(ln_insert_cnt)    := NULL ;        -- 運賃摘要
          -- 配車タイプ（伝票なし配車（リーフ小口以外））
          i_head_dispatch_type_tab(ln_insert_cnt) := gv_carcan_target_n;
--
        -- 運賃ヘッダアドオンにデータが存在する場合
        ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン UPDATE＆DELETE');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- **************************************************
          -- ***  伝票なし配車（リーフ小口以外）更新
          -- **************************************************
          -- 更新用PL/SQL表 件数
          ln_update_cnt   := ln_update_cnt + 1;
--
          -- 運送業者
          u_head_deliv_cmpny_cd_tab(ln_update_cnt) := 
                                gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- 配送No
          u_head_deliv_no_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- 送り状No
          u_head_invoice_no_tab(ln_update_cnt)     := 
                                gt_carriers_schedule_tab(ln_index).slip_number ;
          -- 支払判断区分
          u_head_pay_judg_cls_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- 出庫日
          u_head_ship_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).ship_date ;
          -- 到着日
          u_head_arrival_date_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- 判断日
          u_head_judg_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- 商品区分
          u_head_goods_cls_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).prod_class ;
          -- 混載区分
          u_head_mixed_cd_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).mixed_code ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          u_head_contract_rate_tab(ln_update_cnt)  := 0 ;    -- 契約運賃
          -- 差額（請求金額 － 諸料金）
          u_head_balance_tab(ln_update_cnt)        := NVL(lv_charged_amount, 0) - NVL(lv_many_rate, 0) ;
          u_head_total_amount_tab(ln_update_cnt)   := NVL(lv_many_rate, 0) ;    -- 合計
*****/
          -- 契約運賃（重量=0にて運送費抽出）
          u_head_contract_rate_tab(ln_update_cnt)  := lr_delivery_charges_tab.shipping_expenses ;
--
          -- 合計（運送費 + 諸料金）
          u_head_total_amount_tab(ln_update_cnt)   := lr_delivery_charges_tab.shipping_expenses +
                                                      NVL(lv_many_rate, 0) ;
--
          -- 差額（請求金額 － 合計）
          u_head_balance_tab(ln_update_cnt)        := NVL(lv_charged_amount, 0) - 
                                                      u_head_total_amount_tab(ln_update_cnt) ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          u_head_distance_tab(ln_update_cnt)       := 0 ;    -- 最長距離
-- ##### 20090209 Ver.1.22 本番#1107対応 START #####
          -- 最長距離（車立距離 or 小口距離）
--          u_head_distance_tab(ln_update_cnt)       := lr_delivery_distance_tab.post_distance  ;
          u_head_distance_tab(ln_update_cnt) := ln_distance;
-- ##### 20090209 Ver.1.22 本番#1107対応 END   #####
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
          -- 配送区分
          u_head_deliv_cls_tab(ln_update_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- 代表出庫倉庫コード
          u_head_whs_cd_tab(ln_update_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            u_head_cd_dvsn_tab(ln_update_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
*****/
          -- 代表配送先コード区分
          u_head_cd_dvsn_tab(ln_update_cnt) := lv_code_division;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          -- 代表配送先コード
          u_head_ship_addr_cd_tab(ln_update_cnt) :=
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
--
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          u_head_qty1_tab(ln_update_cnt)           := 0 ;    -- 個数１
--          u_head_deliv_wght1_tab(ln_update_cnt)    := 0 ;    -- 重量１
          -- 個数１
          u_head_qty1_tab(ln_update_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
          -- 重量１
          u_head_deliv_wght1_tab(ln_update_cnt)    := ln_weight ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
          u_head_cnsld_srhrg_tab(ln_update_cnt)    := 0 ;    -- 混載割増金額
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          u_head_actual_ditnc_tab(ln_update_cnt)   := 0 ;    -- 最長実際距離
          -- 最長実際距離
          u_head_actual_ditnc_tab(ln_update_cnt)   := lr_delivery_distance_tab.actual_distance ;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
          u_head_pick_charge_tab(ln_update_cnt)    := 0 ;    -- ピッキング料
          u_head_consolid_qty_tab(ln_update_cnt)   := 0 ;    -- 混載数
          -- 代表タイプ
          u_head_order_type_tab(ln_update_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- 重量容積区分
          u_head_wigh_cpcty_cls_tab(ln_update_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          u_head_out_cont_tab(ln_update_cnt)       := NULL ; -- 契約外区分
          u_head_trans_lcton_tab(ln_update_cnt)    := NULL ; -- 振替先
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
/*****
          u_head_output_flag_tab(ln_update_cnt)    := gv_ktg_yes;       -- 差異区分
          u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;        -- 支払確定区分
*****/
          -- 差異区分
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_yes;
          ELSE
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_no;
          END IF;
--
          -- 支払確定区分
          --   請求運賃 IS NULL の場合
          IF (lv_charged_amount IS NULL ) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- 差異区分 = Y の場合
          ELSIF  (u_head_output_flag_tab(ln_update_cnt)  = gv_ktg_yes) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- 差異区分 = N の場合
          ELSE
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_yes;
          END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
-- ##### 20080805 Ver.1.5 ST事前確認障害 START #####
--          u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- 支払確定戻
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--          IF (lv_defined_flag = gv_ktg_yes) THEN
          -- 元の支払確定区分 ＝ Y の場合
          IF  (lv_defined_flag = gv_ktg_yes) THEN
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_yes ;  -- 支払確定戻
--
          -- 上記以外の場合
          ELSE
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_no ;  -- 支払確定戻
          END IF;
-- ##### 20080805 Ver.1.5 ST事前確認障害 END   #####
--
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
          -- 請求データ削除条件の追加
          IF   (lt_delivery_company_code    <> u_head_deliv_cmpny_cd_tab(ln_update_cnt) ) -- 運送業者
            OR (lt_delivery_no              <> u_head_deliv_no_tab(ln_update_cnt)       ) -- 配送No
            OR (lt_payments_judgment_classe <> u_head_pay_judg_cls_tab(ln_update_cnt)   ) -- 支払判断区分
            OR (lt_ship_date                <> u_head_ship_date_tab(ln_update_cnt)      ) -- 出庫日
            OR (lt_arrival_date             <> u_head_arrival_date_tab(ln_update_cnt)   ) -- 到着日
            OR (lt_judgement_date           <> u_head_judg_date_tab(ln_update_cnt)      ) -- 判断日
            OR (lt_goods_classe             <> u_head_goods_cls_tab(ln_update_cnt)      ) -- 商品区分
            OR (lt_mixed_code               <> u_head_mixed_cd_tab(ln_update_cnt)       ) -- 混載区分
            OR (lt_contract_rate            <> u_head_contract_rate_tab(ln_update_cnt)  ) -- 契約運賃
            OR (lt_balance                  <> u_head_balance_tab(ln_update_cnt)        ) -- 差額
            OR (lt_total_amount             <> u_head_total_amount_tab(ln_update_cnt)   ) -- 合計
            OR (lt_distance                 <> u_head_distance_tab(ln_update_cnt)       ) -- 最長距離
            OR (lt_delivery_classe          <> u_head_deliv_cls_tab(ln_update_cnt)      ) -- 配送区分
            OR (lt_whs_code                 <> u_head_whs_cd_tab(ln_update_cnt)         ) -- 代表出庫倉庫コード
            OR (lt_code_division            <> u_head_cd_dvsn_tab(ln_update_cnt)        ) -- 代表配送先コード区分
            OR (lt_shipping_address_code    <> u_head_ship_addr_cd_tab(ln_update_cnt)   ) -- 代表配送先コード
            OR (lt_qty1                     <> u_head_qty1_tab(ln_update_cnt)           ) -- 個数１
            OR (lt_delivery_weight1         <> u_head_deliv_wght1_tab(ln_update_cnt)    ) -- 重量１
            OR (lt_consolid_surcharge       <> u_head_cnsld_srhrg_tab(ln_update_cnt)    ) -- 混載割増金額
            OR (lt_actual_distance          <> u_head_actual_ditnc_tab(ln_update_cnt)   ) -- 最長実際距離
            OR (lt_picking_charge           <> u_head_pick_charge_tab(ln_update_cnt)    ) -- ピッキング料
            OR (lt_consolid_qty             <> u_head_consolid_qty_tab(ln_update_cnt)   ) -- 混載数
            OR (lt_order_type               <> u_head_order_type_tab(ln_update_cnt)     ) -- 代表タイプ
            OR (lt_weight_capacity_class    <> u_head_wigh_cpcty_cls_tab(ln_update_cnt) ) -- 重量容積区分
          THEN
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン DELETE');
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
            -- **************************************************
            -- ** 更新対象となった配送Noはの請求情報は全て削除対象
            -- **************************************************
            -- 削除用PL/SQL表 件数インクリメント
            ln_delete_cnt   := ln_delete_cnt + 1;
            -- 配送No
            d_head_deliv_no_tab(ln_delete_cnt)  := gt_carriers_schedule_tab(ln_index).delivery_no ;
--
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） START #####
          -- 実績変更による削除 ログ出力用領域格納
          gn_delete_data_idx := gn_delete_data_idx + 1;
-- ##### 20081229 Ver.1.19 本番#882対応 START #####
--          gt_delete_data_msg(gn_delete_data_idx) :=  d_head_deliv_no_tab(ln_delete_cnt);
          gt_delete_data_msg(gn_delete_data_idx) :=  u_head_deliv_no_tab(ln_update_cnt)     || '  ' ;  -- 配送No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || u_head_deliv_cmpny_cd_tab(ln_update_cnt) || '  ' ; -- 運送業者
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'); -- 出荷日
-- ##### 20081229 Ver.1.19 本番#882対応 END   #####
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） END   #####
--
-- ##### 20081224 Ver.1.17 本番#323対応 START #####
          END IF;
-- ##### 20081224 Ver.1.17 本番#323対応 END   #####
--
        END IF;
--
      END IF;
--
    END LOOP deliv_loop;
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
  END set_carri_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : set_carri_deliv_head
   * Description      : 配車のみ運賃ヘッダアドオンPL/SQL表格納(A-32)
   ***********************************************************************************/
/***** ここからプロシージャ丸ごとコメントアウト *****
  PROCEDURE set_carri_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_carri_deliv_head'; -- プログラム名
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
    lv_delivery_no      xxwip_deliverys.delivery_no%TYPE;   -- 配送No
    lv_output_flag      xxwip_deliverys.output_flag%TYPE;   -- 諸料金
    lv_defined_flag     xxwip_deliverys.defined_flag%TYPE;  -- 支払確定区分
    lv_return_flag      xxwip_deliverys.return_flag%TYPE;   -- 支払確定戻
--
    ln_order_flg        VARCHAR2(1);    -- 受注ヘッダアドオン 存在フラグ Y:有 N:無
    ln_move_flg         VARCHAR2(1);    -- 受注明細アドオン   存在フラグ Y:有 N:無
    ln_deliv_flg        VARCHAR2(1);    -- 運賃ヘッダアドオン 存在フラグ Y:有 N:無
--
    ln_order_cnt        NUMBER;   -- 受注ヘッダアドオン 件数
    ln_move_cnt         NUMBER;   -- 受注明細アドオン   件数
--
    ln_insert_cnt   NUMBER;  -- 登録用PL/SQL表 件数
    ln_update_cnt   NUMBER;  -- 更新用PL/SQL表 件数
    ln_delete_cnt   NUMBER;  -- 削除用PL/SQL表 件数
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
    -- 件数初期化
    ln_insert_cnt   := i_head_deliv_no_tab.COUNT;
    ln_update_cnt   := u_head_deliv_no_tab.COUNT;
    ln_delete_cnt   := d_head_deliv_no_tab.COUNT;
--
    -- 対象データ無の場合
    IF (gt_carriers_schedule_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_carriers_schedule_tab.FIRST.. gt_carriers_schedule_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$$$$$$ 配車配送計画 存在確認 $$$$$$$$$$：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運送業者 ：' || gt_carriers_schedule_tab(ln_index).delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：配送No   ：' || gt_carriers_schedule_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  受注ヘッダアドオン 存在確認
      -- **************************************************
      -- 変数初期化
      ln_order_cnt := 0;
--
      SELECT  COUNT(xoha.delivery_no)   -- 配送No
      INTO    ln_order_cnt
      FROM   xxwsh_order_headers_all  xoha  -- 受注ヘッダアドオン
      WHERE  xoha.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no; -- 配送No
--
      IF (ln_order_cnt = 0) THEN
        ln_deliv_flg := gv_ktg_no;
      ELSE
        ln_deliv_flg := gv_ktg_yes;
      END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$ 受注ヘッダ 存在確認 $$$$$：' || ln_deliv_flg);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  移動依頼/指示ヘッダアドオン 存在確認
      -- **************************************************
      -- 変数初期化
      ln_move_cnt := 0;
--
      SELECT  COUNT(xmrih.delivery_no)            -- 配送No
      INTO    ln_move_cnt
      FROM   xxinv_mov_req_instr_headers  xmrih   -- 移動依頼/指示ヘッダアドオン
      WHERE  xmrih.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no; -- 配送No
--
      IF (ln_move_cnt = 0) THEN
        ln_move_flg := gv_ktg_no;
      ELSE
        ln_move_flg := gv_ktg_yes;
      END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$ 移動ヘッダ 存在確認 $$$$$：' || ln_move_flg);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- 受注ヘッダアドオン、移動依頼/指示ヘッダアドオンに存在しない場合
      IF ((ln_deliv_flg = gv_ktg_no) AND (ln_deliv_flg = gv_ktg_no)) THEN
--
        -- **************************************************
        -- ***  運賃ヘッダアドオン抽出
        -- **************************************************
        -- 存在フラグ初期化
        ln_deliv_flg := gv_ktg_yes;
--
        BEGIN
          SELECT  xd.delivery_no        -- 配送No
                , xd.output_flag        -- 諸料金
                , xd.defined_flag       -- 支払確定区分
                , xd.return_flag        -- 支払確定戻
          INTO    lv_delivery_no
                , lv_output_flag
                , lv_defined_flag
                , lv_return_flag
          FROM   xxwip_deliverys      xd      -- 運賃ヘッダアドオン
          WHERE  xd.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no -- 配送No
          AND    xd.p_b_classe = gv_pay ;                           -- 支払請求区分（支払）
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
            -- 存在フラグ Y を設定
            ln_deliv_flg := gv_ktg_no;
--
          WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_deliverys,
                                                  gv_tkn_key,
                                                  gv_pay || ',' ||
                                                  gt_carriers_schedule_tab(ln_index).delivery_no);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：$$$$$ 運賃ヘッダアドオン $$$$$：' || ln_deliv_flg);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：配送No      ：'|| lv_delivery_no);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：諸料金      ：'|| TO_CHAR(lv_output_flag));
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：支払確定区分：'|| lv_defined_flag);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：支払確定戻  ：'|| lv_return_flag);
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  運賃ヘッダアドオンにデータが存在しない場合
        -- **************************************************
        IF (ln_deliv_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン INSERT');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 登録用PL/SQL表 件数
          ln_insert_cnt  := ln_insert_cnt + 1;
--
          -- 運送業者
          i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- 配送No
          i_head_deliv_no_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- 送り状No
          i_head_invoice_no_tab(ln_insert_cnt)     := NULL ;
          -- 支払請求区分
          i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
          -- 支払判断区分
          i_head_pay_judg_cls_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- 出庫日
          i_head_ship_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- 到着日
          i_head_arrival_date_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- 報告日
          i_head_report_date_tab(ln_insert_cnt)    := NULL ;
          -- 判断日
          i_head_judg_date_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).judgement_date ;
          i_head_goods_cls_tab(ln_insert_cnt)      := NULL ;  -- 商品区分
          -- 混載区分
          i_head_mixed_cd_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).mixed_code  ;
          i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;  -- 請求運賃
          i_head_contract_rate_tab(ln_insert_cnt)  := 0 ;     -- 契約運賃
          i_head_balance_tab(ln_insert_cnt)        := 0 ;     -- 差額
          i_head_total_amount_tab(ln_insert_cnt)   := 0 ;     -- 合計
          i_head_many_rate_tab(ln_insert_cnt)      := NULL ;  -- 諸料金
          i_head_distance_tab(ln_insert_cnt)       := 0 ;     -- 最長距離
          -- 配送区分
          i_head_deliv_cls_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- 代表出庫倉庫コード
          i_head_whs_cd_tab(ln_insert_cnt)         := 
                            gt_carriers_schedule_tab(ln_index).whs_code;
          -- 代表配送先コード区分
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            i_head_cd_dvsn_tab(ln_insert_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 代表配送先コード
          i_head_ship_addr_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
          i_head_qty1_tab(ln_insert_cnt)           := 0 ;           -- 個数１
          i_head_qty2_tab(ln_insert_cnt)           := NULL ;        -- 個数２
          i_head_deliv_wght1_tab(ln_insert_cnt)    := 0 ;           -- 重量１
          i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;        -- 重量２
          i_head_cnsld_srhrg_tab(ln_insert_cnt)    := 0 ;           -- 混載割増金額
          i_head_actual_ditnc_tab(ln_insert_cnt)   := 0 ;           -- 最長実際距離
          i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;        -- 通行料
          i_head_pick_charge_tab(ln_insert_cnt)    := 0 ;           -- ピッキング料
          i_head_consolid_qty_tab(ln_insert_cnt)   := 0 ;           -- 混載数
          i_head_order_type_tab(ln_insert_cnt)     := NULL ;        -- 代表タイプ
          -- 重量容積区分
          i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          i_head_out_cont_tab(ln_insert_cnt)       := NULL ;        -- 契約外区分
          i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;  -- 差異区分
          i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no  ;  -- 支払確定区分
          i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no  ;  -- 支払確定戻
          i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no  ;  -- 画面更新有無区分
          i_head_trans_lcton_tab(ln_insert_cnt)    := NULL ;        -- 振替先
          i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;           -- 外部業者変更回数
          i_head_description_tab(ln_insert_cnt)    := NULL ;        -- 運賃摘要
--
        -- **************************************************
        -- ***  運賃ヘッダアドオンにデータが存在する場合
        -- **************************************************
        ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head：運賃ヘッダアドオン UPDATE＆DELETE');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- 更新用PL/SQL表 件数
          ln_update_cnt   := ln_update_cnt + 1;
--
          -- 運送業者
          u_head_deliv_cmpny_cd_tab(ln_update_cnt) := 
                                gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- 配送No
          u_head_deliv_no_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).delivery_no ;
          u_head_invoice_no_tab(ln_update_cnt)     := NULL ; -- 送り状No
          -- 支払判断区分
          u_head_pay_judg_cls_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- 出庫日
          u_head_ship_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).ship_date ;
          -- 到着日
          u_head_arrival_date_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- 判断日
          u_head_judg_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).judgement_date ;
          u_head_goods_cls_tab(ln_update_cnt)      := NULL ; -- 商品区分
          -- 混載区分
          u_head_mixed_cd_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).mixed_code ;
          u_head_contract_rate_tab(ln_update_cnt)  := 0 ;    -- 契約運賃
          u_head_balance_tab(ln_update_cnt)        := 0 ;    -- 差額
          u_head_total_amount_tab(ln_update_cnt)   := 0 ;    -- 合計
          u_head_distance_tab(ln_update_cnt)       := 0 ;    -- 最長距離
          -- 配送区分
          u_head_deliv_cls_tab(ln_update_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- 代表出庫倉庫コード
          u_head_whs_cd_tab(ln_update_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
--
          -- 代表配送先コード
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            u_head_cd_dvsn_tab(ln_update_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
          -- 代表配送先コード
          u_head_ship_addr_cd_tab(ln_update_cnt) :=
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          u_head_qty1_tab(ln_update_cnt)           := 0 ;    -- 個数１
          u_head_deliv_wght1_tab(ln_update_cnt)    := 0 ;    -- 重量１
          u_head_cnsld_srhrg_tab(ln_update_cnt)    := 0 ;    -- 混載割増金額
          u_head_actual_ditnc_tab(ln_update_cnt)   := 0 ;    -- 最長実際距離
          u_head_pick_charge_tab(ln_update_cnt)    := 0 ;    -- ピッキング料
          u_head_consolid_qty_tab(ln_update_cnt)   := 0 ;    -- 混載数
          u_head_order_type_tab(ln_update_cnt)     := NULL ; -- 代表タイプ
          -- 重量容積区分
          u_head_wigh_cpcty_cls_tab(ln_update_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          u_head_out_cont_tab(ln_update_cnt)       := NULL ; -- 契約外区分
          u_head_trans_lcton_tab(ln_update_cnt)    := NULL ; -- 振替先
          u_head_output_flag_tab(ln_update_cnt)    := gv_ktg_yes;       -- 差異区分
          u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;        -- 支払確定区分
          u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- 支払確定戻
--
          -- 更新対象となった配送Noはの請求情報は全て削除対象
          -- 削除用PL/SQL表 件数インクリメント
          ln_delete_cnt   := ln_delete_cnt + 1;
          -- 配送No
          d_head_deliv_no_tab(ln_delete_cnt)  := gt_deliv_line_tab(ln_index).delivery_no ;
--
        END IF;
--
      END IF;
--
    END LOOP deliv_loop;
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
  END set_carri_deliv_head;
***** ここまでプロシージャ丸ごとコメントアウト*****/

-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
  /**********************************************************************************
   * Procedure Name   : insert_deliv_head
   * Description      : 運賃ヘッダアドオン一括登録(A-33)
   ***********************************************************************************/
  PROCEDURE insert_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_deliv_head'; -- プログラム名
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
    IF (i_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃ヘッダアドオン 登録
      -- **************************************************
      FORALL ln_index IN i_head_deliv_no_tab.FIRST .. i_head_deliv_no_tab.LAST
        INSERT INTO xxwip_deliverys
        ( deliverys_header_id         -- 運賃ヘッダーアドオンID
        , delivery_company_code       -- 運送業者
        , delivery_no                 -- 配送No
        , invoice_no                  -- 送り状No
        , p_b_classe                  -- 支払請求区分
        , payments_judgment_classe    -- 支払判断区分
        , ship_date                   -- 出庫日
        , arrival_date                -- 到着日
        , report_date                 -- 報告日
        , judgement_date              -- 判断日
        , goods_classe                -- 商品区分
        , mixed_code                  -- 混載区分
        , charged_amount              -- 請求運賃
        , contract_rate               -- 契約運賃
        , balance                     -- 差額
        , total_amount                -- 合計
        , many_rate                   -- 諸料金
        , distance                    -- 最長距離
        , delivery_classe             -- 配送区分
        , whs_code                    -- 代表出庫倉庫コード
        , code_division               -- 代表配送先コード区分
        , shipping_address_code       -- 代表配送先コード
        , qty1                        -- 個数１
        , qty2                        -- 個数２
        , delivery_weight1            -- 重量１
        , delivery_weight2            -- 重量２
        , consolid_surcharge          -- 混載割増金額
        , actual_distance             -- 最長実際距離
        , congestion_charge           -- 通行料
        , picking_charge              -- ピッキング料
        , consolid_qty                -- 混載数
        , order_type                  -- 代表タイプ
        , weight_capacity_class       -- 重量容積区分
        , outside_contract            -- 契約外区分
        , output_flag                 -- 差異区分
        , defined_flag                -- 支払確定区分
        , return_flag                 -- 支払確定戻
        , form_update_flag            -- 画面更新有無区分
        , transfer_location           -- 振替先
        , outside_up_count            -- 外部業者変更回数
        , description                 -- 運賃摘要
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
        , dispatch_type               -- 配車タイプ
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
        , created_by                  -- 作成者
        , creation_date               -- 作成日
        , last_updated_by             -- 最終更新者
        , last_update_date            -- 最終更新日
        , last_update_login           -- 最終更新ログイン
        , request_id                  -- 要求ID
        , program_application_id      -- コンカレント・プログラム・アプリケーションID
        , program_id                  -- コンカレント・プログラムID
        , program_update_date         -- プログラム更新日
        ) VALUES (
          xxwip_deliverys_id_s1.NEXTVAL         -- 運賃ヘッダーアドオンID
        , i_head_deliv_cmpny_cd_tab(ln_index)   -- 運送業者
        , i_head_deliv_no_tab(ln_index)         -- 配送No
        , i_head_invoice_no_tab(ln_index)       -- 送り状No
        , i_head_p_b_classe_tab(ln_index)       -- 支払請求区分
        , i_head_pay_judg_cls_tab(ln_index)     -- 支払判断区分
        , i_head_ship_date_tab(ln_index)        -- 出庫日
        , i_head_arrival_date_tab(ln_index)     -- 到着日
        , i_head_report_date_tab(ln_index)      -- 報告日
        , i_head_judg_date_tab(ln_index)        -- 判断日
        , i_head_goods_cls_tab(ln_index)        -- 商品区分
        , i_head_mixed_cd_tab(ln_index)         -- 混載区分
        , i_head_charg_amount_tab(ln_index)     -- 請求運賃
        , i_head_contract_rate_tab(ln_index)    -- 契約運賃
        , i_head_balance_tab(ln_index)          -- 差額
        , i_head_total_amount_tab(ln_index)     -- 合計
        , i_head_many_rate_tab(ln_index)        -- 諸料金
        , i_head_distance_tab(ln_index)         -- 最長距離
        , i_head_deliv_cls_tab(ln_index)        -- 配送区分
        , i_head_whs_cd_tab(ln_index)           -- 代表出庫倉庫コード
        , i_head_cd_dvsn_tab(ln_index)          -- 代表配送先コード区分
        , i_head_ship_addr_cd_tab(ln_index)     -- 代表配送先コード
        , i_head_qty1_tab(ln_index)             -- 個数１
        , i_head_qty2_tab(ln_index)             -- 個数２
        , i_head_deliv_wght1_tab(ln_index)      -- 重量１
        , i_head_deliv_wght2_tab(ln_index)      -- 重量２
        , i_head_cnsld_srhrg_tab(ln_index)      -- 混載割増金額
        , i_head_actual_ditnc_tab(ln_index)     -- 最長実際距離
        , i_head_cong_chrg_tab(ln_index)        -- 通行料
        , i_head_pick_charge_tab(ln_index)      -- ピッキング料
        , i_head_consolid_qty_tab(ln_index)     -- 混載数
        , i_head_order_type_tab(ln_index)       -- 代表タイプ
        , i_head_wigh_cpcty_cls_tab(ln_index)   -- 重量容積区分
        , i_head_out_cont_tab(ln_index)         -- 契約外区分
        , i_head_output_flag_tab(ln_index)      -- 差異区分
        , i_head_defined_flag_tab(ln_index)     -- 支払確定区分
        , i_head_return_flag_tab(ln_index)      -- 支払確定戻
        , i_head_fm_upd_flg_tab(ln_index)       -- 画面更新有無区分
        , i_head_trans_lcton_tab(ln_index)      -- 振替先
        , i_head_out_up_cnt_tab(ln_index)       -- 外部業者変更回数
        , i_head_description_tab(ln_index)      -- 運賃摘要
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
        , i_head_dispatch_type_tab(ln_index)    -- 配車タイプ
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
        , gn_user_id                            -- 作成者
        , gd_sysdate                            -- 作成日
        , gn_user_id                            -- 最終更新者
        , gd_sysdate                            -- 最終更新日
        , gn_login_id                           -- 最終更新ログイン
        , gn_conc_request_id                    -- 要求ID
        , gn_prog_appl_id                       -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
        , gn_conc_program_id                    -- コンカレント・プログラムID
        , gd_sysdate);                          -- プログラム更新日
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_ins_cnt := gn_deliv_ins_cnt + SQL%ROWCOUNT;
--
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
  END insert_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_head
   * Description      : 運賃ヘッダアドオン一括更新(A-34)
   ***********************************************************************************/
  PROCEDURE update_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_deliv_head'; -- プログラム名
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
    IF (u_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃ヘッダアドオン 更新
      -- **************************************************
      FORALL ln_index IN u_head_deliv_no_tab.FIRST .. u_head_deliv_no_tab.LAST
        UPDATE xxwip_deliverys            -- 運賃ヘッダアドオン
        SET     delivery_company_code     = u_head_deliv_cmpny_cd_tab(ln_index)-- 運送業者
              , delivery_no               = u_head_deliv_no_tab(ln_index)      -- 配送No
              , invoice_no                = u_head_invoice_no_tab(ln_index)    -- 送り状No
              , payments_judgment_classe  = u_head_pay_judg_cls_tab(ln_index)  -- 支払判断区分
              , ship_date                 = u_head_ship_date_tab(ln_index)     -- 出庫日
              , arrival_date              = u_head_arrival_date_tab(ln_index)  -- 到着日
              , judgement_date            = u_head_judg_date_tab(ln_index)     -- 判断日
              , goods_classe              = u_head_goods_cls_tab(ln_index)     -- 商品区分
              , mixed_code                = u_head_mixed_cd_tab(ln_index)      -- 混載区分
              , contract_rate             = u_head_contract_rate_tab(ln_index) -- 契約運賃
              , balance                   = u_head_balance_tab(ln_index)       -- 差額
              , total_amount              = u_head_total_amount_tab(ln_index)  -- 合計
              , distance                  = u_head_distance_tab(ln_index)      -- 最長距離
              , delivery_classe           = u_head_deliv_cls_tab(ln_index)     -- 配送区分
              , whs_code                  = u_head_whs_cd_tab(ln_index)        -- 代表出庫倉庫コード
              , code_division             = u_head_cd_dvsn_tab(ln_index)       -- 代表配送先コード区分
              , shipping_address_code     = u_head_ship_addr_cd_tab(ln_index)  -- 代表配送先コード
              , qty1                      = u_head_qty1_tab(ln_index)          -- 個数１
              , delivery_weight1          = u_head_deliv_wght1_tab(ln_index)   -- 重量１
              , consolid_surcharge        = u_head_cnsld_srhrg_tab(ln_index)   -- 混載割増金額
              , actual_distance           = u_head_actual_ditnc_tab(ln_index)  -- 最長実際距離
              , picking_charge            = u_head_pick_charge_tab(ln_index)   -- ピッキング料
              , consolid_qty              = u_head_consolid_qty_tab(ln_index)  -- 混載数
              , order_type                = u_head_order_type_tab(ln_index)    -- 代表タイプ
              , weight_capacity_class     = u_head_wigh_cpcty_cls_tab(ln_index)-- 重量容積区分
              , outside_contract          = u_head_out_cont_tab(ln_index)      -- 契約外区分
              , transfer_location         = u_head_trans_lcton_tab(ln_index)   -- 振替先
              , output_flag               = u_head_output_flag_tab(ln_index)   -- 差異区分
              , defined_flag              = u_head_defined_flag_tab(ln_index)  -- 支払確定区分
              , return_flag               = u_head_return_flag_tab(ln_index)   -- 支払確定戻
              , last_updated_by           = gn_user_id                 -- 最終更新者
              , last_update_date          = gd_sysdate                 -- 最終更新日
              , last_update_login         = gn_login_id                -- 最終更新ログイン
              , request_id                = gn_conc_request_id         -- 要求ID
              , program_application_id    = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
              , program_id                = gn_conc_program_id         -- コンカレント・プログラムID
              , program_update_date       = gd_sysdate                 -- プログラム更新日
        WHERE   delivery_no = u_head_deliv_no_tab(ln_index)       -- 配送No
        AND     p_b_classe  = gv_pay;                             -- 支払請求区分
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_ins_cnt := gn_deliv_ins_cnt + SQL%ROWCOUNT;
--
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
  END update_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : delete_deliv_head
   * Description      : 運賃ヘッダアドオン一括削除(A-35)
   ***********************************************************************************/
  PROCEDURE delete_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_deliv_head'; -- プログラム名
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
    IF (d_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃ヘッダアドオン 削除
      -- **************************************************
      FORALL ln_index IN d_head_deliv_no_tab.FIRST .. d_head_deliv_no_tab.LAST
        DELETE FROM  xxwip_deliverys  -- 運賃ヘッダアドオン
        WHERE   delivery_no = d_head_deliv_no_tab(ln_index) -- 配送No
        AND     p_b_classe  = gv_claim;                     -- 支払請求区分（請求）
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
--
    END IF;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
    IF (d_slip_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃ヘッダアドオン 削除（伝票なし配車 支払・請求が対象）
      -- **************************************************
      FORALL ln_index IN d_slip_head_deliv_no_tab.FIRST .. d_slip_head_deliv_no_tab.LAST
        DELETE FROM  xxwip_deliverys  -- 運賃ヘッダアドオン
        WHERE   delivery_no = d_slip_head_deliv_no_tab(ln_index); -- 配送No
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） START #####
-- 件数は追加しない
--      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） END   #####
--
    END IF;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
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
  END delete_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_cntl
   * Description      : 運賃計算コントロール更新処理(A-36)
   ***********************************************************************************/
  PROCEDURE update_deliv_cntl(
    iv_exchange_type IN         VARCHAR2,     -- 洗い替え区分
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_deliv_ctrl_proc'; -- プログラム名
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
    -- 入力パラメータ.洗い替え区分 = 「NO」の場合
    IF (iv_exchange_type = gv_ktg_no) THEN
--
      -- 運賃計算用コントロールの前回処理日付を更新
      UPDATE xxwip_deliverys_ctrl xdc   -- 運賃計算用コントロールアドオン
      SET    xdc.last_process_date      = gd_sysdate         -- 前回処理日付
            ,xdc.last_updated_by        = gn_user_id         -- 最終更新者
            ,xdc.last_update_date       = gd_sysdate         -- 最終更新日
            ,xdc.last_update_login      = gn_login_id        -- 最終更新ログイン
            ,xdc.request_id             = gn_conc_request_id -- 要求ID
            ,xdc.program_application_id = gn_prog_appl_id    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            ,xdc.program_id             = gn_conc_program_id -- コンカレント・プログラムID
            ,xdc.program_update_date    = gd_sysdate         -- プログラム更新日
      WHERE  xdc.concurrent_no          = gv_con_no_deliv;
--
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
  END update_deliv_cntl;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_line
   * Description      : 洗替運賃明細アドオン抽出(A-37)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_line'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 運賃明細アドオン 抽出
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
/***** 取得SQL変更
    SELECT    xdl.request_no                      -- 依頼No
            , xdl.small_lot_class                 -- リーフ小口区分
            , xdl.goods_classe                    -- 商品区分
            , xdl.weight_capacity_class           -- 重量容積区分
            , xdl.qty                             -- 個数
            , xdl.delivery_weight                 -- 重量
            , xdl.mixed_code                      -- 混載区分
            , NVL(xdd.post_distance, 0)           -- 配送距離：車立距離
            , NVL(xdd.small_distance, 0)          -- 配送距離：小口距離
            , NVL(xdd.consolid_add_distance, 0)   -- 配送距離：混載距離
            , NVL(xdd.actual_distance, 0)         -- 配送距離：実際距離
            , NVL(xdc.small_weight, 0)      -- 運送業者：小口重量
    BULK COLLECT INTO gt_exch_deliv_line_tab
    FROM  xxwip_delivery_lines        xdl,      -- 運賃明細アドオン
          xxwip_delivery_distance     xdd,      -- 配送距離アドオンマスタ
          xxwip_delivery_company      xdc       -- 運賃用運送業者アドオンマスタ
    WHERE xdl.judgement_date >= gd_target_date                        -- 判断日 >= 締日
    AND   xdl.goods_classe            = xdd.goods_classe(+)           -- 配送距離：商品区分
    AND   xdl.delivery_company_code   = xdd.delivery_company_code(+)  -- 配送距離：運送業者
    AND   xdl.whs_code                = xdd.origin_shipment(+)        -- 配送距離：出庫倉庫
    AND   xdl.code_division           = xdd.code_division(+)          -- 配送距離：コード区分
    AND   xdl.shipping_address_code   = xdd.shipping_address_code(+)  -- 配送距離：配送先コード
    AND   TRUNC(xdl.judgement_date)  >= xdd.start_date_active(+)      -- 配送距離：適用開始日
    AND   TRUNC(xdl.judgement_date)  <= xdd.end_date_active(+)        -- 配送距離：適用終了日
    AND   xdl.goods_classe            = xdc.goods_classe(+)           -- 運送業者：商品区分
    AND   xdl.delivery_company_code   = xdc.delivery_company_code(+)  -- 運送業者：運送業者
    AND   TRUNC(xdl.judgement_date)   >= xdc.start_date_active(+)     -- 運送業者：適用開始日
    AND   TRUNC(xdl.judgement_date)  <= xdc.end_date_active(+)        -- 運送業者：適用終了日
    ORDER BY xdl.request_no;
*****/
    SELECT    xdl.request_no                    request_no            -- 依頼No
            , xdl.small_lot_class               small_lot_class       -- リーフ小口区分
            , xdl.goods_classe                  goods_classe          -- 商品区分
            , xdl.weight_capacity_class         weight_capacity_class -- 重量容積区分
            , xdl.qty                           qty                   -- 個数
            , xdl.delivery_weight               delivery_weight       -- 重量
            , xdl.mixed_code                    mixed_code            -- 混載区分
            , xdl.judgement_date                judgement_date        -- 判断日
            , xdl.distance                      distance              -- 距離
            , xdl.actual_distance               xdl_actual_distance   -- 実際距離
            , xdl.dellivary_classe              dellivary_classe      -- 配送区分
            , xdd.change_flg                    distance_chk          -- 配送距離フラグ（1:対象あり 0:対象なし）
            , xdc.pay_change_flg                company_chk           -- 運送業者フラグ（1:対象あり 0:対象なし）
            , xdd.post_distance                 post_distance         -- 配送距離：車立距離
            , xdd.small_distance                small_distance        -- 配送距離：小口距離
            , xdd.consolid_add_distance         consolid_add_distance -- 配送距離：混載距離
            , xdd.actual_distance               actual_distance       -- 配送距離：実際距離
            , xdc.small_weight                  small_weight          -- 運送業者：小口重量
    BULK COLLECT INTO gt_exch_deliv_line_tab
    FROM
          (
            -- *** 運賃明細アドオン－配送距離マスタ ***
            SELECT  xdl.request_no                        -- 依頼No
                  , xdl.judgement_date                    -- 判断日
                  , xdl.goods_classe                      -- 商品区分
                  , xdl.delivery_company_code             -- 運送業者
                  , xdl.whs_code                          -- 出庫倉庫
                  , xdl.code_division                     -- コード区分
                  , xdl.shipping_address_code             -- 配送先コード
            FROM  xxwip_delivery_lines        xdl     -- 運賃明細アドオン
                , xxwip_delivery_distance     xdd     -- 配送距離アドオンマスタ
            WHERE xdl.judgement_date         >= gd_target_date                -- 判断日 >= 締日
            AND   xdl.goods_classe            = xdd.goods_classe              -- 配送距離：商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
            AND   xdl.goods_classe            = gv_prod_div                   -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
            AND   xdl.delivery_company_code   = xdd.delivery_company_code     -- 配送距離：運送業者
            AND   xdl.whs_code                = xdd.origin_shipment           -- 配送距離：出庫倉庫
            AND   xdl.code_division           = xdd.code_division             -- 配送距離：コード区分
            AND   xdl.shipping_address_code   = xdd.shipping_address_code     -- 配送距離：配送先コード
            AND   TRUNC(xdl.judgement_date)  >= xdd.start_date_active         -- 配送距離：適用開始日
            AND   TRUNC(xdl.judgement_date)  <= xdd.end_date_active           -- 配送距離：適用終了日
            AND   change_flg                  = gv_target_y                   -- 支払変更フラグ
            UNION
            -- *** 運賃明細アドオン－運賃用運送業者マスタ ***
            SELECT  xdl.request_no                        -- 依頼No
                  , xdl.judgement_date                    -- 判断日
                  , xdl.goods_classe                      -- 商品区分
                  , xdl.delivery_company_code             -- 運送業者
                  , xdl.whs_code                          -- 出庫倉庫
                  , xdl.code_division                     -- コード区分
                  , xdl.shipping_address_code             -- 配送先コード
            FROM  xxwip_delivery_lines        xdl     -- 運賃明細アドオン
                , xxwip_delivery_company      xdc     -- 運賃用運送業者アドオンマスタ
            WHERE xdl.judgement_date         >= gd_target_date                -- 判断日 >= 締日
            AND   xdl.goods_classe            = xdc.goods_classe              -- 運送業者：商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
            AND   xdl.goods_classe            = gv_prod_div                   -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
            AND   xdl.delivery_company_code   = xdc.delivery_company_code     -- 運送業者：運送業者
            AND   TRUNC(xdl.judgement_date)  >= xdc.start_date_active         -- 運送業者：適用開始日
            AND   TRUNC(xdl.judgement_date)  <= xdc.end_date_active           -- 運送業者：適用終了日
            AND   pay_change_flg              = gv_target_y                   -- 支払変更フラグ
          ) xd_req
          , xxwip_delivery_lines        xdl     -- 運賃明細アドオン
          , xxwip_delivery_company      xdc     -- 運賃用運送業者アドオンマスタ
          , xxwip_delivery_distance     xdd     -- 配送距離アドオンマスタ
    WHERE xd_req.request_no              = xdl.request_no                -- 依頼No
    AND   xd_req.goods_classe            = xdd.goods_classe(+)           -- 配送距離：商品区分
    AND   xd_req.delivery_company_code   = xdd.delivery_company_code(+)  -- 配送距離：運送業者
    AND   xd_req.whs_code                = xdd.origin_shipment(+)        -- 配送距離：出庫倉庫
    AND   xd_req.code_division           = xdd.code_division(+)          -- 配送距離：コード区分
    AND   xd_req.shipping_address_code   = xdd.shipping_address_code(+)  -- 配送距離：配送先コード
    AND   TRUNC(xd_req.judgement_date)  >= xdd.start_date_active(+)      -- 配送距離：適用開始日
    AND   TRUNC(xd_req.judgement_date)  <= xdd.end_date_active(+)        -- 配送距離：適用終了日
    AND   xd_req.goods_classe            = xdc.goods_classe(+)           -- 運送業者：商品区分
    AND   xd_req.delivery_company_code   = xdc.delivery_company_code(+)  -- 運送業者：運送業者
    AND   TRUNC(xd_req.judgement_date)   >= xdc.start_date_active(+)     -- 運送業者：適用開始日
    AND   TRUNC(xd_req.judgement_date)  <= xdc.end_date_active(+)        -- 運送業者：適用終了日
    ORDER BY xd_req.request_no;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_line：洗替運賃明細アドオン抽出：' || TO_CHAR(gt_exch_deliv_line_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_exch_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : set_exch_deliv_line
   * Description      : 洗替運賃明細アドオンPL/SQL表格納(A-38)
   ***********************************************************************************/
  PROCEDURE set_exch_deliv_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_exch_deliv_line'; -- プログラム名
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
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- 配送区分
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
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
    -- 対象データ無の場合
    IF (gt_exch_deliv_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_line_loop>>
    FOR ln_index IN  gt_exch_deliv_line_tab.FIRST.. gt_exch_deliv_line_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：%%%%%%%%%% 洗替 運賃明細アドオン %%%%%%%%%%：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：依頼No：' || gt_exch_deliv_line_tab(ln_index).request_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- **************************************************
      -- ***  配送区分情報取得
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_exch_deliv_line_tab(ln_index).dellivary_classe,  -- 配送区分
        gt_exch_deliv_line_tab(ln_index).judgement_date,    -- 判断日
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
      -- *** 依頼No ***
      ue_line_request_no_tab(ln_index)    := gt_exch_deliv_line_tab(ln_index).request_no ;
--
      -- *** 距離 ***
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- 配送距離マスタが洗替対象の場合
      IF (gt_exch_deliv_line_tab(ln_index).distance_chk = gv_target_y) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：%%% 配送距離マスタ 洗替対象 %%%：' || TO_CHAR(ln_index));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
        -- リーフ小口区分 = Y の場合
        IF (gt_exch_deliv_line_tab(ln_index).small_lot_class = gv_ktg_yes) THEN
          -- 小口距離を設定
          ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).small_distance ;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
/***** 条件変更の為、コメントアウト
        -- 商品区分 ＝ リーフ   又は 
        -- 商品区分 ＝ ドリンク 且つ、混載区分 ＜＞ 混載 の場合
        ELSIF (
                  (gt_exch_deliv_line_tab(ln_index).goods_classe = gv_prod_class_lef)
                OR    
                  ((gt_exch_deliv_line_tab(ln_index).goods_classe = gv_prod_class_drk)
                  AND (gt_exch_deliv_line_tab(ln_index).mixed_code <> gv_target_y))
              ) THEN
          -- 車立距離を設定
          ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).post_distance ;
--
        -- 上記以外の場合
        ELSE
--
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
        -- 車立距離（明細は混載割増距離を加算しない）
--        ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).post_distance +
--                                        gt_exch_deliv_line_tab(ln_index).consolid_add_distance;
          ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
--
*****/
        -- 上記以外の場合
        ELSE
            -- 小口区分＝「小口」の場合
            IF (lr_ship_method_tab.small_amount_class = gv_small_sum_yes) THEN
              -- 小口距離を設定
              ue_line_ditnc_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).small_distance;
--
            -- 小口区分＝「車立」の場合
            ELSE
              -- 車立て距離を設定
              ue_line_ditnc_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).post_distance;
            END IF;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
        END IF;
--
        -- *** 実際距離 ***
        ue_line_actual_dstnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).actual_distance ;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- 配送距離マスタが洗替対象外の場合、設定されているそのままの値を設定
      ELSE
        -- 距離
        ue_line_ditnc_tab(ln_index)         := gt_exch_deliv_line_tab(ln_index).distance;
        -- 実際距離
        ue_line_actual_dstnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).xdl_actual_distance;
--
      END IF;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- 運送業者マスタが洗替対象の場合
      IF (gt_exch_deliv_line_tab(ln_index).company_chk = gv_target_y) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：%%% 運送業者マスタ 洗替対象 %%%：' || TO_CHAR(ln_index));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
        -- *** 重量 ***
        -- リーフ小口区分 = Y 、且つ、重量容積区分=容積 の場合
        IF (gt_exch_deliv_line_tab(ln_index).small_lot_class = gv_ktg_yes) THEN
          -- 個数 × 小口重量
          ue_line_deliv_weight_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).qty *
                                                gt_exch_deliv_line_tab(ln_index).small_weight;
        ELSE
          -- 重量
          ue_line_deliv_weight_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).delivery_weight;
        END IF;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- 運送業者マスタが洗替対象外の場合、設定されているそのままの値を設定
      ELSE
        -- 重量
        ue_line_deliv_weight_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).delivery_weight;
      END IF;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：依頼No        ：' || gt_exch_deliv_line_tab(ln_index).request_no           );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：リーフ小口区分：' || gt_exch_deliv_line_tab(ln_index).small_lot_class      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：商品区分      ：' || gt_exch_deliv_line_tab(ln_index).goods_classe         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：重量容積区分  ：' || gt_exch_deliv_line_tab(ln_index).weight_capacity_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：個数          ：' || gt_exch_deliv_line_tab(ln_index).qty                  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：重量          ：' || gt_exch_deliv_line_tab(ln_index).delivery_weight      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：混載区分      ：' || gt_exch_deliv_line_tab(ln_index).mixed_code           );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：距離          ：' || gt_exch_deliv_line_tab(ln_index). distance            );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：実際距離      ：' || gt_exch_deliv_line_tab(ln_index).xdl_actual_distance  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：配送距離フラグ：' || gt_exch_deliv_line_tab(ln_index).distance_chk         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：運送業者フラグ：' || gt_exch_deliv_line_tab(ln_index).company_chk          );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：配：車立距離  ：' || gt_exch_deliv_line_tab(ln_index).post_distance        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：配：小口距離  ：' || gt_exch_deliv_line_tab(ln_index).small_distance       );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：配：混載距離  ：' || gt_exch_deliv_line_tab(ln_index).consolid_add_distance);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：配：実際距離  ：' || gt_exch_deliv_line_tab(ln_index).actual_distance      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line：運：小口重量  ：' || gt_exch_deliv_line_tab(ln_index).small_weight         );
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP deliv_line_loop;
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
  END set_exch_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : update_exch_deliv_line
   * Description      : 洗替運賃明細アドオン一括更新(A-39)
   ***********************************************************************************/
  PROCEDURE update_exch_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_exch_deliv_line'; -- プログラム名
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
    IF (ue_line_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃明細アドオン 更新
      -- **************************************************
      FORALL ln_index IN ue_line_request_no_tab.FIRST .. ue_line_request_no_tab.LAST
      UPDATE xxwip_delivery_lines       -- 運賃明細アドオン
        SET     distance                  = ue_line_ditnc_tab(ln_index)         -- 距離
              , actual_distance           = ue_line_actual_dstnc_tab(ln_index)  -- 実際距離
              , delivery_weight           = ue_line_deliv_weight_tab(ln_index)  -- 重量
              , last_updated_by           = gn_user_id                 -- 最終更新者
              , last_update_date          = gd_sysdate                 -- 最終更新日
              , last_update_login         = gn_login_id                -- 最終更新ログイン
              , request_id                = gn_conc_request_id         -- 要求ID
              , program_application_id    = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
              , program_id                = gn_conc_program_id         -- コンカレント・プログラムID
              , program_update_date       = gd_sysdate                 -- プログラム更新日
        WHERE  request_no = ue_line_request_no_tab(ln_index);           -- 依頼No
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
--
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
  END update_exch_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_delino
   * Description      : 洗替運賃明細アドオン対象配送No抽出(A-40)
   ***********************************************************************************/
  PROCEDURE get_exch_delino(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_delino'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 運賃明細アドオン 配送No抽出
    BEGIN
      SELECT  xdl.delivery_no             -- 配送No
            , MAX(xdl.distance)           -- 最長距離
            , NULL                        -- 実際距離
            , SUM(xdl.delivery_weight)    -- 重量
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 start *----------*
            , SUM(xdl.qty)                -- 数量
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 end   *----------*
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
            , NULL                        -- 送り状No
            , NULL                        -- 支払判断区分
            , NULL                        -- 出庫日
            , NULL                        -- 入庫日
            , NULL                        -- 判断日
            , NULL                        -- 混載区分
            , NULL                        -- 配送区分
            , NULL                        -- 出庫倉庫コード
            , NULL                        -- 配送先コード区分
            , NULL                        -- 配送先コード
            , NULL                        -- タイプ
            , NULL                        -- 契約外区分
            , NULL                        -- 振替先
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
      BULK COLLECT INTO gt_exch_delivno_line_tab
      FROM   xxwip_delivery_lines    xdl                -- 運賃明細アドオン
      WHERE  xdl.judgement_date >= gd_target_date       -- 判断日 >= 締め日
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- 明細の洗い替え処理で対象となった依頼Noのみを本処理の対象とする
      AND    EXISTS (SELECT 'x'
                     FROM   xxwip_delivery_lines xdl_ex
                     WHERE  xdl_ex.delivery_no      = xdl.delivery_no -- 配送No
                     AND    xdl_ex.last_update_date = gd_sysdate      -- 最終更新日（明細洗替時に更新したもの）
                    )
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
      GROUP BY xdl.delivery_no                          -- 配送No（集約）
      ORDER BY xdl.delivery_no;                         -- 配送No（順序）
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_notfnd,
                                              gv_tkn_table,
                                              gv_delivery_lines,
                                              gv_tkn_key,
                                              TO_CHAR(gd_target_date,'YYYY/MM/DD HH24:MI:SS'));
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_toomny,
                                              gv_tkn_table,
                                              gv_delivery_lines,
                                              gv_tkn_key,
                                              TO_CHAR(gd_target_date,'YYYY/MM/DD HH24:MI:SS'));
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_delino：洗替運賃明細アドオン対象配送No抽出' || TO_CHAR(gt_exch_delivno_line_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_exch_delino;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_line_h
   * Description      : 洗替運賃明細アドオン抽出(A-41)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_line_h(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_line_h'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ無の場合
    IF (gt_exch_delivno_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<delivno_loop>>
    FOR ln_index IN  gt_exch_delivno_line_tab.FIRST.. gt_exch_delivno_line_tab.LAST LOOP
--
      -- **************************************************
      -- * 運賃明細アドオン 抽出
      -- **************************************************
      BEGIN
-- ##### 20080715 Ver.1.4 ST障害#455対応 START #####
--        SELECT  xdl.actual_distance     -- 実際距離
--        INTO    gt_exch_delivno_line_tab(ln_index).actual_distance
--        FROM    xxwip_delivery_lines    xdl        -- 運賃明細アドオン
--        WHERE   xdl.delivery_no = gt_exch_delivno_line_tab(ln_index).delivery_no  -- 配送No
--        AND     xdl.distance    = gt_exch_delivno_line_tab(ln_index).distance;    -- 距離
--      -- 最長距離と等しい運賃明細アドオンの実際距離取得
        -- 同一レコードが存在する場合は
        SELECT  max_deliv_line.actual_distance                      -- 実際距離
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
              , max_deliv_line.invoice_no                           -- 送り状No
              , max_deliv_line.payments_judgment_classe             -- 支払判断区分
              , max_deliv_line.ship_date                            -- 出庫日
              , max_deliv_line.arrival_date                         -- 入庫日
              , max_deliv_line.judgement_date                       -- 判断日
              , max_deliv_line.mixed_code                           -- 混載区分
              , max_deliv_line.dellivary_classe                     -- 配送区分
              , max_deliv_line.whs_code                             -- 出庫倉庫コード
              , max_deliv_line.code_division                        -- 配送先コード区分
              , max_deliv_line.shipping_address_code                -- 配送先コード
              , max_deliv_line.order_type                           -- タイプ
              , max_deliv_line.outside_contract                     -- 契約外区分
              , max_deliv_line.transfer_location                    -- 振替先
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
        INTO    gt_exch_delivno_line_tab(ln_index).actual_distance
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
              , gt_exch_delivno_line_tab(ln_index).invoice_no               -- 送り状No
              , gt_exch_delivno_line_tab(ln_index).payments_judgment_classe -- 支払判断区分
              , gt_exch_delivno_line_tab(ln_index).ship_date                -- 出庫日
              , gt_exch_delivno_line_tab(ln_index).arrival_date             -- 入庫日
              , gt_exch_delivno_line_tab(ln_index).judgement_date           -- 判断日
              , gt_exch_delivno_line_tab(ln_index).mixed_code               -- 混載区分
              , gt_exch_delivno_line_tab(ln_index).dellivary_classe         -- 配送区分
              , gt_exch_delivno_line_tab(ln_index).whs_code                 -- 出庫倉庫コード
              , gt_exch_delivno_line_tab(ln_index).code_division            -- 配送先コード区分
              , gt_exch_delivno_line_tab(ln_index).shipping_address_code    -- 配送先コード
              , gt_exch_delivno_line_tab(ln_index).order_type               -- タイプ
              , gt_exch_delivno_line_tab(ln_index).outside_contract         -- 契約外区分
              , gt_exch_delivno_line_tab(ln_index).transfer_location        -- 振替先
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
        FROM
          (
            SELECT  xdl.actual_distance           -- 実際距離
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
                  , xdl.invoice_no                -- 送り状No
                  , xdl.payments_judgment_classe  -- 支払判断区分
                  , xdl.ship_date                 -- 出庫日
                  , xdl.arrival_date              -- 入庫日
                  , xdl.judgement_date            -- 判断日
                  , xdl.mixed_code                -- 混載区分
                  , xdl.dellivary_classe          -- 配送区分
                  , xdl.whs_code                  -- 出庫倉庫コード
                  , xdl.code_division             -- 配送先コード区分
                  , xdl.shipping_address_code     -- 配送先コード
                  , xdl.order_type                -- タイプ
                  , xdl.outside_contract          -- 契約外区分
                  , xdl.transfer_location         -- 振替先
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
            FROM    xxwip_delivery_lines    xdl                                       -- 運賃明細アドオン
            WHERE   xdl.delivery_no = gt_exch_delivno_line_tab(ln_index).delivery_no  -- 配送No
            AND     xdl.distance    = gt_exch_delivno_line_tab(ln_index).distance     -- 距離
            ORDER BY xdl.request_no                                                   -- 依頼No（順序）
          ) max_deliv_line
        WHERE ROWNUM = 1;
-- ##### 20080715 Ver.1.4 ST障害#455対応 END   #####
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** データ取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_notfnd,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_exch_delivno_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_exch_delivno_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN TOO_MANY_ROWS THEN   -- *** データ複数取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_exch_delivno_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_exch_delivno_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
    END LOOP delivno_loop;
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
  END get_exch_deliv_line_h;
--
  /**********************************************************************************
   * Procedure Name   : set_exch_deliv_line
   * Description      : 洗替運賃ヘッダアドオン明細項目更新用PL/SQL表格納(A-42)
   ***********************************************************************************/
  PROCEDURE set_exch_deliv_head_h(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_exch_deliv_head_h'; -- プログラム名
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
    -- 対象データ無の場合
    IF (gt_exch_delivno_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_line_loop>>
    FOR ln_index IN  gt_exch_delivno_line_tab.FIRST.. gt_exch_delivno_line_tab.LAST LOOP
--
      -- 配送No
      ue_head_deliv_no_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).delivery_no;
      -- 最長距離
      ue_head_distance_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).distance;
      -- 重量１
      ue_head_deliv_wght1_tab(ln_index)   := gt_exch_delivno_line_tab(ln_index).delivery_weight;
      -- 最長実際距離
      ue_head_actual_ditnc_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).actual_distance;
--
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 start *----------*
      -- 数量１
      ue_head_actual_qty1_tab(ln_index)   := gt_exch_delivno_line_tab(ln_index).qty;
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 end   *----------*
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- 送り状No
      ue_head_invoice_no_tab(ln_index)    := gt_exch_delivno_line_tab(ln_index).invoice_no;
      -- 支払判断区分
      ue_head_pay_judg_cls_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).payments_judgment_classe;
      -- 出庫日
      ue_head_ship_date_tab(ln_index)     := gt_exch_delivno_line_tab(ln_index).ship_date;
      -- 入庫日
      ue_head_arrival_date_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).arrival_date;
      -- 判断日
      ue_head_judg_date_tab(ln_index)     := gt_exch_delivno_line_tab(ln_index).judgement_date;
      -- 混載区分
      ue_head_mixed_cd_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).mixed_code;
      -- 配送区分
      ue_head_deliv_cls_tab(ln_index)     := gt_exch_delivno_line_tab(ln_index).dellivary_classe;
      -- 出庫倉庫コード
      ue_head_whs_cd_tab(ln_index)        := gt_exch_delivno_line_tab(ln_index).whs_code;
      -- 配送先コード区分
      ue_head_cd_dvsn_tab(ln_index)       := gt_exch_delivno_line_tab(ln_index).code_division;
      -- 配送先コード
      ue_head_ship_addr_cd_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).shipping_address_code;
      -- タイプ
      ue_head_order_type_tab(ln_index)    := gt_exch_delivno_line_tab(ln_index).order_type;
      -- 契約外区分
      ue_head_out_cont_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).outside_contract;
      -- 振替先
      ue_head_trans_lcton_tab(ln_index)   := gt_exch_delivno_line_tab(ln_index).transfer_location;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：%%%%%%%%%% 洗替運賃ヘッダアドオン明細項目 %%%%%%%%%%：' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：配送No          ：' || gt_exch_delivno_line_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：距離            ：' || gt_exch_delivno_line_tab(ln_index).distance);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：実際距離        ：' || gt_exch_delivno_line_tab(ln_index).actual_distance);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：重量            ：' || gt_exch_delivno_line_tab(ln_index).delivery_weight);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：数量            ：' || gt_exch_delivno_line_tab(ln_index).qty);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：送り状No        ：' || gt_exch_delivno_line_tab(ln_index).invoice_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：支払判断区分    ：' || gt_exch_delivno_line_tab(ln_index).payments_judgment_classe );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：出庫日          ：' || gt_exch_delivno_line_tab(ln_index).ship_date);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：入庫日          ：' || gt_exch_delivno_line_tab(ln_index).arrival_date);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：判断日          ：' || gt_exch_delivno_line_tab(ln_index).judgement_date);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：混載区分        ：' || gt_exch_delivno_line_tab(ln_index).mixed_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：配送区分        ：' || gt_exch_delivno_line_tab(ln_index).dellivary_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：出庫倉庫コード  ：' || gt_exch_delivno_line_tab(ln_index).whs_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：配送先コード区分：' || gt_exch_delivno_line_tab(ln_index).code_division);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：配送先コード    ：' || gt_exch_delivno_line_tab(ln_index).shipping_address_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：タイプ          ：' || gt_exch_delivno_line_tab(ln_index).order_type);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：契約外区分      ：' || gt_exch_delivno_line_tab(ln_index).outside_contract);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h：振替先          ：' || gt_exch_delivno_line_tab(ln_index).transfer_location);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP deliv_line_loop;
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
  END set_exch_deliv_head_h;
--
  /**********************************************************************************
   * Procedure Name   : update_exch_deliv_head_h
   * Description      : 洗替運賃ヘッダアドオン明細項目一括更新(A-43)
   ***********************************************************************************/
  PROCEDURE update_exch_deliv_head_h(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_exch_deliv_head_h'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- * 運賃ヘッダアドオン 更新
    -- **************************************************
    FORALL ln_index IN ue_head_deliv_no_tab.FIRST .. ue_head_deliv_no_tab.LAST
      UPDATE xxwip_deliverys          -- 運賃ヘッダアドオン
      SET     distance                  = ue_head_distance_tab(ln_index)       -- 最長距離
            , delivery_weight1          = ue_head_deliv_wght1_tab(ln_index)    -- 重量１
            , actual_distance           = ue_head_actual_ditnc_tab(ln_index)   -- 最長実際距離
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 start *----------*
            , qty1                      = ue_head_actual_qty1_tab(ln_index)    -- 数量１
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 end   *----------*
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
            , invoice_no                = ue_head_invoice_no_tab(ln_index)     -- 送り状No
            , payments_judgment_classe  = ue_head_pay_judg_cls_tab(ln_index)   -- 支払判断区分
            , ship_date                 = ue_head_ship_date_tab(ln_index)      -- 出庫日
            , arrival_date              = ue_head_arrival_date_tab(ln_index)   -- 入庫日
            , judgement_date            = ue_head_judg_date_tab(ln_index)      -- 判断日
            , mixed_code                = ue_head_mixed_cd_tab(ln_index)       -- 混載区分
            , delivery_classe           = ue_head_deliv_cls_tab(ln_index)      -- 配送区分
            , whs_code                  = ue_head_whs_cd_tab(ln_index)         -- 出庫倉庫コード
            , code_division             = ue_head_cd_dvsn_tab(ln_index)        -- 配送先コード区分
            , shipping_address_code     = ue_head_ship_addr_cd_tab(ln_index)   -- 配送先コード
            , order_type                = ue_head_order_type_tab(ln_index)     -- タイプ
            , outside_contract          = ue_head_out_cont_tab(ln_index)       -- 契約外区分
            , transfer_location         = ue_head_trans_lcton_tab(ln_index)    -- 振替先
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
            , last_updated_by           = gn_user_id                  -- 最終更新者
            , last_update_date          = gd_sysdate                  -- 最終更新日
            , last_update_login         = gn_login_id                 -- 最終更新ログイン
            , request_id                = gn_conc_request_id          -- 要求ID
            , program_application_id    = gn_prog_appl_id             -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            , program_id                = gn_conc_program_id          -- コンカレント・プログラムID
            , program_update_date       = gd_sysdate                  -- プログラム更新日
      WHERE  delivery_no = ue_head_deliv_no_tab(ln_index)             -- 配送No
      AND    p_b_classe  = gv_pay ;                                   -- 支払請求区分（支払）
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
  END update_exch_deliv_head_h;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_head
   * Description      : 洗替運賃ヘッダアドオン抽出(A-44)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_head'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
/***** SQL見直し
    -- 運賃ヘッダアドオン 抽出
    SELECT    xd.delivery_company_code  -- 運送業者
            , xd.delivery_no            -- 配送No
            , xd.p_b_classe             -- 支払請求区分
            , xd.judgement_date         -- 判断日
            , xd.goods_classe           -- 商品区分
            , xd.mixed_code             -- 混載区分
            , xd.charged_amount         -- 請求運賃
            , xd.many_rate              -- 諸料金
            , xd.distance               -- 最長距離
            , xd.delivery_classe        -- 配送区分
            , xd.qty1                   -- 個数１
            , xd.delivery_weight1       -- 重量１
            , xd.consolid_surcharge     -- 混載割増金額
            , xd.consolid_qty           -- 混載数
            , xd.output_flag            -- 差異区分
            , xd.defined_flag           -- 支払確定区分
            , xd.return_flag            -- 支払確定戻
            , NVL(xdec.pay_picking_amount, 0) -- 運送業者：支払ピッキング単価
            , NULL                            -- 運賃：運送費
            , NULL                            -- 運賃：リーフ混載割増
--2008/08/04 Add 
            , xd.actual_distance        -- 最長実際距離
            , xd.whs_code               -- 代表出庫倉庫コード
            , xd.code_division          -- 代表配送先コード区分
            , xd.shipping_address_code  -- 代表配送先コード
            , xd.dispatch_type          -- 配車タイプ
--2008/08/04 Add ↑
    BULK COLLECT INTO gt_exch_deliv_tab
    FROM  xxwip_deliverys         xd,   -- 運賃ヘッダアドオン
          xxwip_delivery_company  xdec  -- 運賃用運送業者アドオンマスタ
    WHERE xd.p_b_classe = gv_pay                      -- 支払請求区分（支払）
    AND   xd.judgement_date >= gd_target_date         -- 判断日 >= 締め日
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
--    AND   xd.goods_classe IS NOT NULL                 -- 商品区分
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
***** 伝票なし配車は全て再計算対象とする
    AND   xd.dispatch_type          IN (gv_car_normal, gv_carcan_target_y)  -- 配車タイプ
                                                                            --   1：通常配車
                                                                            --   2：伝票なし配車（リーフ小口）
*****
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
    AND   xd.goods_classe           = xdec.goods_classe(+)          -- 商品区分
    AND   xd.delivery_company_code  = xdec.delivery_company_code(+) -- 運送業者
    AND   TRUNC(xd.judgement_date) >= xdec.start_date_active(+)     -- 適用開始日
    AND   TRUNC(xd.judgement_date) <= xdec.end_date_active(+)       -- 適用終了日
    ORDER BY delivery_no;
*****/
    -- 運賃ヘッダアドオン 抽出
    SELECT    xd.delivery_company_code  -- 運送業者
            , xd.delivery_no            -- 配送No
            , xd.p_b_classe             -- 支払請求区分
            , xd.ship_date              -- 出庫日
            , xd.judgement_date         -- 判断日
            , xd.goods_classe           -- 商品区分
            , xd.mixed_code             -- 混載区分
            , xd.charged_amount         -- 請求運賃
            , xd.many_rate              -- 諸料金
            , xd.distance               -- 最長距離
            , xd.delivery_classe        -- 配送区分
            , xd.qty1                   -- 個数１
            , xd.delivery_weight1       -- 重量１
            , xd.consolid_surcharge     -- 混載割増金額
            , xd.consolid_qty           -- 混載数
            , xd.output_flag            -- 差異区分
            , xd.defined_flag           -- 支払確定区分
            , xd.return_flag            -- 支払確定戻
            , xd.actual_distance        -- 最長実際距離
            , xd.whs_code               -- 代表出庫倉庫コード
            , xd.code_division          -- 代表配送先コード区分
            , xd.shipping_address_code  -- 代表配送先コード
            , xd.dispatch_type          -- 配車タイプ
            , xd.picking_charge         -- 支払ピッキング料
            , xd.contract_rate          -- 契約運賃
            , xd.last_update_date       -- 最終更新日
            , NULL                      -- 運送：支払ピッキング単価
            , NULL                      -- 運送：支払変更フラグ
            , NULL                      -- 配送区分：小口区分
            , NULL                      -- 配送：車立距離
            , NULL                      -- 配送：小口距離
            , NULL                      -- 配送：混載距離
            , NULL                      -- 配送：実際距離
            , NULL                      -- 配送：変更フラグ
            , NULL                      -- 運賃：運送費
            , NULL                      -- 運賃：リーフ混載割増
            , NULL                      -- 運賃：運賃変更フラグ
            , NULL                      -- 運賃：混載変更フラグ
    BULK COLLECT INTO gt_exch_deliv_tab
    FROM  xxwip_deliverys         xd    -- 運賃ヘッダアドオン
    WHERE xd.p_b_classe      = gv_pay                 -- 支払請求区分（支払）
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
    AND   xd.goods_classe    = gv_prod_div            -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
    AND   xd.judgement_date >= gd_target_date         -- 判断日 >= 締め日
    ORDER BY delivery_no;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_head：洗替運賃ヘッダアドオン抽出：' || TO_CHAR(gt_exch_deliv_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_exch_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_charg
   * Description      : 洗替運賃アドオンマスタ抽出(A-45)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_charg(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_charg'; -- プログラム名
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
    lr_delivery_charges_tab   xxwip_common3_pkg.delivery_charges_rec;   -- 運賃
--2008/08/04 Add ↓
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- 配送距離
--2008/08/04 Add ↑
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- 運賃用運送業者
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- 配送区分
--
    lt_actual_distance        xxwip_delivery_lines.actual_distance%TYPE;-- 最長実際距離
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ無の場合
    IF (gt_exch_deliv_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_exch_deliv_tab.FIRST.. gt_exch_deliv_tab.LAST LOOP
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- **************************************************
      -- ***  運賃用運送業者アドオンマスタ抽出
      -- **************************************************
      xxwip_common3_pkg.get_delivery_company(
        gt_exch_deliv_tab(ln_index).goods_classe,           -- 商品区分
        gt_exch_deliv_tab(ln_index).delivery_company_code,  -- 運送業者
        gt_exch_deliv_tab(ln_index).judgement_date,         -- 判断日
        lr_delivery_company_tab,                            -- 運賃用運送業者レコード
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ***** 支払ピッキング単価設定 *****
      gt_exch_deliv_tab(ln_index).pay_picking_amount  := lr_delivery_company_tab.pay_picking_amount;
      -- ***** 支払変更フラグ *****
      gt_exch_deliv_tab(ln_index).pay_change_flg      := lr_delivery_company_tab.pay_change_flg;
--
      -- **************************************************
      -- ***  配送区分情報取得
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_exch_deliv_tab(ln_index).delivery_classe,  -- 配送区分
        gt_exch_deliv_tab(ln_index).judgement_date,   -- 判断日
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ***** 小口区分 *****
      gt_exch_deliv_tab(ln_index).small_amount_class  := lr_ship_method_tab.small_amount_class;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
--2008/08/04 Add ↓
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--      IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
      -- 全てのケースにおいて取得し直す
--      IF (gt_exch_deliv_tab(ln_index).dispatch_type IN (gv_carcan_target_y, 
--                                                        gv_carcan_target_n)) THEN
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
      -- **************************************************
      -- ***  配送距離アドオンマスタ抽出
      -- **************************************************
      xxwip_common3_pkg.get_delivery_distance(
        gt_exch_deliv_tab(ln_index).goods_classe,           -- 商品区分
        gt_exch_deliv_tab(ln_index).delivery_company_code,  -- 運送業者
        gt_exch_deliv_tab(ln_index).whs_code,               -- 出庫倉庫
        gt_exch_deliv_tab(ln_index).code_division,          -- コード区分
        gt_exch_deliv_tab(ln_index).shipping_address_code,  -- 配送先コード
        gt_exch_deliv_tab(ln_index).judgement_date,         -- 判断日
        lr_delivery_distance_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
/***** 条件関係なく設定するように修正
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
--        gt_exch_deliv_tab(ln_index).distance        := lr_delivery_distance_tab.small_distance;
        -- 伝票なし配車（リーフ小口）の場合
        IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
          -- 小口距離を設定
          gt_exch_deliv_tab(ln_index).distance        := lr_delivery_distance_tab.small_distance;
--
        -- 伝票なし配車（リーフ小口以外）の場合
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
--        ELSE
        ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_n) THEN
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
          -- 車立距離を設定
          gt_exch_deliv_tab(ln_index).distance        := lr_delivery_distance_tab.post_distance;
--
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
        -- 通常配車の場合
        ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_car_normal) THEN
          -- 商品区分＝「ドリンク」且つ混載区分＝「混載」の場合
          IF ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_drk )
            AND (gt_exch_deliv_tab(ln_index).mixed_code = gv_target_y )) THEN
--
            -- 車立距離＋混載割増距離
            gt_exch_deliv_tab(ln_index).distance := lr_delivery_distance_tab.post_distance +
                                                    lr_delivery_distance_tab.consolid_add_distance ;
          END IF;
--
          -- 上記で設定した条件以外は既に設定されている最長距離で更新する
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
--
        END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
        -- 最長実際距離
        gt_exch_deliv_tab(ln_index).actual_distance := lr_delivery_distance_tab.actual_distance;
-- ##### 20081027 Ver.1.10 統合#436対応 START #####
--      END IF;
-- ##### 20081027 Ver.1.10 統合#436対応 END   #####
--2008/08/04 Add ↑
*****/
      -- ***** 車立距離 *****
      gt_exch_deliv_tab(ln_index).post_distance         := lr_delivery_distance_tab.post_distance;
      -- ***** 小口距離 *****
      gt_exch_deliv_tab(ln_index).small_distance        := lr_delivery_distance_tab.small_distance;
      -- ***** 混載距離 *****
      gt_exch_deliv_tab(ln_index).consolid_add_distance := lr_delivery_distance_tab.consolid_add_distance;
      -- ***** 実際距離 *****
      gt_exch_deliv_tab(ln_index).actual_distance       := lr_delivery_distance_tab.actual_distance;
      -- ***** 変更フラグ *****
      gt_exch_deliv_tab(ln_index).distance_change_flg   := lr_delivery_distance_tab.change_flg;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
      -- **************************************************
      -- * 運賃アドオンマスタ抽出
      -- **************************************************
-- *----------* 2009/05/14 Ver.1.26 本番#432対応 start *----------*
      -- 変更フラグがON、明細が更新されている場合のみ、
      --   運賃マスタより取得する条件の距離を配送距離マスタより設定する。
      IF  ((gt_exch_deliv_tab(ln_index).distance_change_flg = gv_target_y)
        OR (gt_exch_deliv_tab(ln_index).last_update_date    = gd_sysdate )) THEN
-- *----------* 2009/05/14 Ver.1.26 本番#432対応 end   *----------*
--
        -- 商品区分 = 「ドリンク」且つ、混載区分 = 「混載」の場合
        IF  ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_drk)
          AND(gt_exch_deliv_tab(ln_index).mixed_code   = gv_target_y      )) THEN
          -- 車立距離＋混載割増距離
          lt_actual_distance := gt_exch_deliv_tab(ln_index).post_distance +
                                                  gt_exch_deliv_tab(ln_index).consolid_add_distance;
        ELSE
--
          -- 伝票なし配車（リーフ小口）の場合
          IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
-- *----------* 2009/05/14 Ver.1.26 本番#432対応 start *----------*
--          lt_actual_distance := gt_exch_deliv_tab(ln_index).distance;
            lt_actual_distance := gt_exch_deliv_tab(ln_index).small_distance;
-- *----------* 2009/05/14 Ver.1.26 本番#432対応 end   *----------*
--
          -- 伝票なし配車（リーフ小口以外）の場合
          ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_n) THEN
--
            -- 小口区分 =「小口」の場合
            IF (gt_exch_deliv_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
              -- 小口距離を設定
              lt_actual_distance := gt_exch_deliv_tab(ln_index).small_distance;
--
            -- 小口区分 =「車立」の場合
            ELSE
              -- 車立距離を設定
              lt_actual_distance := gt_exch_deliv_tab(ln_index).post_distance;
            END IF;
--
          -- 通常配車の場合
          ELSE
            -- 変更無の為、取得した最長距離を設定
            lt_actual_distance := gt_exch_deliv_tab(ln_index).distance;
          END IF;
        END IF;
-- *----------* 2009/05/14 Ver.1.26 本番#432対応 start *----------*
      ELSE
        -- 変更無の為、取得した最長距離を設定
        lt_actual_distance := gt_exch_deliv_tab(ln_index).distance;
      END IF;
-- *----------* 2009/05/14 Ver.1.26 本番#432対応 end   *----------*
--
      xxwip_common3_pkg.get_delivery_charges(
        gt_exch_deliv_tab(ln_index).p_b_classe,             -- 支払請求区分
        gt_exch_deliv_tab(ln_index).goods_classe,           -- 商品区分
        gt_exch_deliv_tab(ln_index).delivery_company_code,  -- 運送業者
        gt_exch_deliv_tab(ln_index).delivery_classe,        -- 配送区分
        lt_actual_distance,                                 -- 運賃距離
        gt_exch_deliv_tab(ln_index).delivery_weight1,       -- 重量
        gt_exch_deliv_tab(ln_index).judgement_date,         -- 判断日
        lr_delivery_charges_tab,                            -- 運賃アドオンレコード
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- *** 運送費 ***
      gt_exch_deliv_tab(ln_index).shipping_expenses := lr_delivery_charges_tab.shipping_expenses;
      -- *** リーフ混載割増 ***
      gt_exch_deliv_tab(ln_index).leaf_consolid_add := lr_delivery_charges_tab.leaf_consolid_add;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
      -- *** 運賃・変更フラグ ***
      gt_exch_deliv_tab(ln_index).charg_shp_change_flg := lr_delivery_charges_tab.shipping_change_flg;
      -- *** 混載・変更フラグ ***
      gt_exch_deliv_tab(ln_index).charg_lrf_change_flg := lr_delivery_charges_tab.leaf_change_flg;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        -- 運送業者、配送距離、運賃マスタの変更フラグが'1'の場合はPL/SQL表へ格納する
        IF  (( gt_exch_deliv_tab(ln_index).pay_change_flg       = gv_target_y )
          OR ( gt_exch_deliv_tab(ln_index).distance_change_flg  = gv_target_y )
          OR ( gt_exch_deliv_tab(ln_index).charg_shp_change_flg = gv_target_y )
          OR ( gt_exch_deliv_tab(ln_index).charg_lrf_change_flg = gv_target_y )) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：********** 洗替運賃アドオンマスタ抽出(対象のみ) **********：'|| TO_CHAR(ln_index));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：運送業者：' || gt_exch_deliv_tab(ln_index).delivery_company_code);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：配送No  ：' || gt_exch_deliv_tab(ln_index).delivery_no);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：支払ピッキング単価：' || gt_exch_deliv_tab(ln_index).pay_picking_amount);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：支払変更フラグ    ：' || gt_exch_deliv_tab(ln_index).pay_change_flg);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：小口区分          ：' || gt_exch_deliv_tab(ln_index).small_amount_class);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：車立距離          ：' || gt_exch_deliv_tab(ln_index).post_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：小口距離          ：' || gt_exch_deliv_tab(ln_index).small_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：混載距離          ：' || gt_exch_deliv_tab(ln_index).consolid_add_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：実際距離          ：' || gt_exch_deliv_tab(ln_index).actual_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：距離 変更フラグ   ：' || gt_exch_deliv_tab(ln_index).distance_change_flg);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：運送費            ：' || gt_exch_deliv_tab(ln_index).shipping_expenses);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：リーフ混載割増    ：' || gt_exch_deliv_tab(ln_index).leaf_consolid_add);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：運賃 変更フラグ   ：' || gt_exch_deliv_tab(ln_index).charg_shp_change_flg);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg：混載 変更フラグ   ：' || gt_exch_deliv_tab(ln_index).charg_lrf_change_flg);
        END IF;
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP deliv_loop;
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
  END get_exch_deliv_charg;
--
  /**********************************************************************************
   * Procedure Name   : set_exch_deliv_hate
   * Description      : 洗替運賃ヘッダアドオンPL/SQL表格納(A-46)
   ***********************************************************************************/
  PROCEDURE set_exch_deliv_hate(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_exch_deliv_hate'; -- プログラム名
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
    ln_delete_cnt   NUMBER;       -- 削除件数
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
    ln_target_cnt   NUMBER;       -- 洗替対象件数
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
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
    -- 変数初期化
    ln_delete_cnt := 0 ;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
    ln_target_cnt := 0 ;
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
    -- 対象データ無の場合
    IF (gt_exch_deliv_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_exch_deliv_tab.FIRST.. gt_exch_deliv_tab.LAST LOOP
--
      -- **************************************************
      -- * 更新用PL/SQL表 設定
      -- **************************************************
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
/***** PL/SQL表格納処理全面変更の為コメントアウト
      -- 配送No
      ueh_head_deliv_no_tab(ln_index)       := gt_exch_deliv_tab(ln_index).delivery_no ;
      -- 契約運賃
      ueh_head_contract_rate_tab(ln_index)  := gt_exch_deliv_tab(ln_index).shipping_expenses ;
--
      -- *** 混載割増金額 ***
      -- 商品区分 = リーフ、且つ、混載区分 = 混載 の場合
      IF ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_lef )
        AND (gt_exch_deliv_tab(ln_index).mixed_code = gv_target_y)) THEN
        -- リーフ混載割増 × 混載数
        ueh_head_cnsld_srhrg_tab(ln_index)  := gt_exch_deliv_tab(ln_index).leaf_consolid_add *
                                                  gt_exch_deliv_tab(ln_index).consolid_qty;
      ELSE
        -- 混載割増金額
        ueh_head_cnsld_srhrg_tab(ln_index)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
      END IF;
--
      -- *** ピッキング料 ***
      -- 個数 × 支払ピッキング単価
-- ##### 20080715 Ver.1.3 ST障害#452対応 START #####
--      ueh_head_pick_charge_tab(ln_index)  := ROUND(gt_exch_deliv_tab(ln_index).qty1 *
--                                              gt_exch_deliv_tab(ln_index).pay_picking_amount);
      ueh_head_pick_charge_tab(ln_index)  := CEIL(gt_exch_deliv_tab(ln_index).qty1 *
                                              gt_exch_deliv_tab(ln_index).pay_picking_amount);
-- ##### 20080715 Ver.1.3 ST障害#452対応 END   #####
--
      -- *** 合計 ***
      -- 契約運賃＋混載割増金額＋ピッキング料＋諸料金
      ueh_head_total_amount_tab(ln_index) :=  gt_exch_deliv_tab(ln_index).shipping_expenses +
-- ##### 20081107 Ver.1.12 統合#584対応 START #####
--                                              gt_exch_deliv_tab(ln_index).consolid_surcharge +
                                              ueh_head_cnsld_srhrg_tab(ln_index) +
-- ##### 20081107 Ver.1.12 統合#584対応 END   #####
                                              ueh_head_pick_charge_tab(ln_index) +
                                              NVL(gt_exch_deliv_tab(ln_index).many_rate,0);
--
      -- *** 差額 ***
      -- 請求運賃－合計
      ueh_head_balance_tab(ln_index)  :=  NVL(gt_exch_deliv_tab(ln_index).charged_amount, 0) -
                                            ueh_head_total_amount_tab(ln_index);
--
      -- *** 差異区分 ***
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
*****
      -- 請求運賃 = NULLの場合
      IF (gt_exch_deliv_tab(ln_index).charged_amount IS NULL) THEN
        -- Y を設定
        ueh_head_output_flag_tab(ln_index) := gv_ktg_yes ;
--
      -- 請求運賃 <> NULL、且つ、差額 = 0場合
      ELSIF ((gt_exch_deliv_tab(ln_index).charged_amount IS NOT NULL)
        AND  (ueh_head_balance_tab(ln_index) = 0)) THEN
        -- N を設定
        ueh_head_output_flag_tab(ln_index) := gv_ktg_no ;
--
      -- 上記以外の場合
      ELSE
        -- Y を設定
        ueh_head_output_flag_tab(ln_index) := gv_ktg_yes ;
      END IF;
*****
      -- 差額≠０の場合
      IF (ueh_head_balance_tab(ln_index) <> 0) THEN
        ueh_head_output_flag_tab(ln_index) := gv_ktg_yes ;
      -- 差額＝０の場合
      ELSE
        ueh_head_output_flag_tab(ln_index) := gv_ktg_no ;
      END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
      -- *** 支払確定区分 ***
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
*****
      -- 差異区分 = N の場合
      IF (ueh_head_output_flag_tab(ln_index) = gv_ktg_no) THEN
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_yes;
--
      -- 差異区分 = Y の場合
      ELSE
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_no;
      END IF;
*****
      -- 請求金額＝NULL
      IF (gt_exch_deliv_tab(ln_index).charged_amount IS NULL) THEN
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_no;
      -- 差異区分＝YES
      ELSIF (ueh_head_output_flag_tab(ln_index) = gv_ktg_yes) THEN
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_no;
      -- 差異区分＝NO
      ELSE
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_yes;
      END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
      -- *** 支払確定戻 ***
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 START #####
*****
      -- 元の支払確定区分 = Y 且つ 設定する支払確定区分 = N の場合
      IF ((gt_exch_deliv_tab(ln_index).defined_flag = gv_ktg_yes )
        AND (ueh_head_defined_flag_tab(ln_index) = gv_ktg_no)) THEN
        -- Y を設定
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_yes ;
--
      -- 上記以外の場合
      ELSE
        -- N を設定
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_no ;
      END IF;
*****
      -- 元の支払確定区分 = Y の場合
      IF (gt_exch_deliv_tab(ln_index).defined_flag = gv_ktg_yes ) THEN
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_yes ;
      -- 元の支払確定区分 = N の場合
      ELSE
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_no ;
      END IF;
-- ##### 20080912 Ver.1.8 TE080指摘事項15対応 区分設定見直対応 END   #####
--
--2008/08/04 Add ↓
      ueh_head_distance_type_tab(ln_index)     := gt_exch_deliv_tab(ln_index).distance;
      ueh_head_actual_ditnc_type_tab(ln_index) := gt_exch_deliv_tab(ln_index).actual_distance;
--2008/08/04 Add ↑
--
      -- **************************************************
      -- * 削除用PL/SQL表 設定
      -- **************************************************
      -- 差異区分 = Y の場合
      IF (ueh_head_output_flag_tab(ln_index) = gv_ktg_yes) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate：********** 洗替 削除用PL/SQL表 設定 **********：'|| TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate：配送No：' || gt_exch_deliv_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        --削除用 PL/SQL表に設定
        ln_delete_cnt := ln_delete_cnt + 1;
        deh_head_deliv_no_tab(ln_delete_cnt) := gt_exch_deliv_tab(ln_index).delivery_no;
      END IF;
--
*****/
      -- 運送業者、配送距離、運賃マスタの変更フラグが'1'
      --   もしくは運賃明細が更新されている場合はPL/SQL表へ格納する
      IF  (( gt_exch_deliv_tab(ln_index).pay_change_flg      = gv_target_y )
        OR ( gt_exch_deliv_tab(ln_index).distance_change_flg = gv_target_y )
        OR ( gt_exch_deliv_tab(ln_index).charg_shp_change_flg = gv_target_y )
-- *----------* 2009/04/30 Ver.1.24 本番#432対応 start *----------*
--        OR ( gt_exch_deliv_tab(ln_index).charg_lrf_change_flg = gv_target_y )) THEN
        OR ( gt_exch_deliv_tab(ln_index).charg_lrf_change_flg = gv_target_y )
        OR ( gt_exch_deliv_tab(ln_index).last_update_date     = gd_sysdate   )) THEN
-- *----------* 2009/04/30 Ver.1.24 本番#432対応 end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate：洗替対象  配送No：' || gt_exch_deliv_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- 対象件数 カウントUP
        ln_target_cnt := ln_target_cnt + 1;
--
        -- ***** 配送No *****
        ueh_head_deliv_no_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).delivery_no ;
--
        -- ***** 支払ピッキング料 *****
        -- 運賃用運送業者マスタ 支払変更フラグ = '1'の場合
        --   もしくは運賃明細が更新されている場合は、支払ピッキング料を再計算する。
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 start *----------*
--        IF (gt_exch_deliv_tab(ln_index).pay_change_flg = gv_target_y) THEN
        IF   ((gt_exch_deliv_tab(ln_index).pay_change_flg   = gv_target_y)
          OR  (gt_exch_deliv_tab(ln_index).last_update_date = gd_sysdate )) THEN
-- *----------* 2009/05/07 Ver.1.25 本番#432対応 end   *----------*
          -- 個数 × 支払ピッキング単価
          ueh_head_pick_charge_tab(ln_target_cnt)  := CEIL(gt_exch_deliv_tab(ln_index).qty1 *
                                                      gt_exch_deliv_tab(ln_index).pay_picking_amount);
--
        -- 運賃用運送業者マスタ 支払変更フラグ = '1'以外の場合
        ELSE
          -- 取得した、支払ピッキング料を設定
          ueh_head_pick_charge_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).picking_charge;
        END IF;
--
--
        -- ***** 距離・実際距離 *****
        -- 配送距離マスタ 変更フラグ = '1'の場合
        IF  ((gt_exch_deliv_tab(ln_index).distance_change_flg = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).last_update_date    = gd_sysdate )) THEN
--
          -- 伝票なし配車（リーフ小口）の場合
          IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
            -- 小口距離を設定
            ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).small_distance;
--
          -- 伝票なし配車（リーフ小口以外）の場合
          ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_n) THEN
--
            -- 小口区分 = 「小口」 の場合
            IF (gt_exch_deliv_tab(ln_index).small_amount_class = gv_small_sum_yes ) THEN
              -- 小口距離を設定
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).small_distance;
--
            -- 小口区分 = 「車立」 の場合
            ELSE
              -- 車立距離を設定
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).post_distance;
            END IF;
--
            -- 車立距離を設定
            ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).post_distance;
--
          -- 通常配車の場合
          ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_car_normal) THEN
--
            -- 商品区分 = 「ドリンク」且つ、混載区分 = 「混載」の場合
            IF ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_drk)
             AND(gt_exch_deliv_tab(ln_index).mixed_code   = gv_target_y      )) THEN
              -- 車立距離＋混載割増距離
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).post_distance +
                                                      gt_exch_deliv_tab(ln_index).consolid_add_distance;
            ELSE
              -- 変更無の為、取得した最長距離を設定
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).distance;
            END IF;
--
          END IF;
          -- 実際距離を設定
          ueh_head_actual_ditnc_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).dis_actual_distance;
--
        -- 配送距離マスタ 変更フラグ = '1'以外の場合
        ELSE
          -- 変更無の為、取得した最長距離、実際最長距離を設定
          ueh_head_distance_type_tab(ln_target_cnt)     := gt_exch_deliv_tab(ln_index).distance;
          ueh_head_actual_ditnc_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).actual_distance;
        END IF;
--
--
        -- ***** 契約運賃・混載割増金額 *****
        -- 配送距離マスタ 変更フラグ = '1'
        --   又は、運賃マスタ 運賃変更フラグ・混載変更フラグ = '1'、
        --   又は、最終更新日が明細更新した日時と同じ場合
        IF  ((gt_exch_deliv_tab(ln_index).distance_change_flg   = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).charg_shp_change_flg  = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).charg_lrf_change_flg  = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).last_update_date      = gd_sysdate )) THEN
--
          --    配送距離マスタ 変更フラグ = '1' 
          -- or 運賃変更フラグ = '1' の場合
          -- or 運賃明細更新対象の場合
          IF  ((gt_exch_deliv_tab(ln_index).distance_change_flg   = gv_target_y)
            OR (gt_exch_deliv_tab(ln_index).charg_shp_change_flg  = gv_target_y) 
            OR (gt_exch_deliv_tab(ln_index).last_update_date      = gd_sysdate )) THEN
            -- 契約運賃
            ueh_head_contract_rate_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).shipping_expenses ;
          ELSE
            -- 変更無の為、取得した契約運賃を設定
            ueh_head_contract_rate_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).contract_rate ;
          END IF;
--
          -- 混載変更フラグ = '1' の場合
          IF (( gt_exch_deliv_tab(ln_index).charg_lrf_change_flg  = gv_target_y)
            OR (gt_exch_deliv_tab(ln_index).last_update_date      = gd_sysdate )) THEN
            -- 商品区分 = リーフ、且つ、混載区分 = 混載 の場合
            IF  (( gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_lef )
              AND (gt_exch_deliv_tab(ln_index).mixed_code = gv_target_y         )) THEN
              -- リーフ混載割増 × 混載数
              ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).leaf_consolid_add *
                                                          gt_exch_deliv_tab(ln_index).consolid_qty;
            ELSE
              -- リーフ混載以外の為、取得した混載割増金額を設定
              ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
            END IF;
          ELSE
            -- 変更無の為、取得した混載割増金額を設定
            ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
          END IF;
--
        -- 運賃マスタ 変更フラグ = '1'以外の場合
        ELSE
          -- 変更無の為、取得した契約運賃を設定
          ueh_head_contract_rate_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).contract_rate ;
          -- 変更無の為、取得した混載割増金額を設定
          ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
        END IF;
--
--
        -- ***** 合計 *****
        -- 契約運賃 + 混載割増金額 + 支払ピッキング料 + 諸料金
        ueh_head_total_amount_tab(ln_target_cnt) :=  ueh_head_contract_rate_tab(ln_target_cnt) +
                                                ueh_head_cnsld_srhrg_tab(ln_target_cnt) +
                                                ueh_head_pick_charge_tab(ln_target_cnt) +
                                                NVL(gt_exch_deliv_tab(ln_index).many_rate,0);
--
        -- *** 差額 ***
        -- 請求運賃 － 合計
        ueh_head_balance_tab(ln_target_cnt)  :=  NVL(gt_exch_deliv_tab(ln_index).charged_amount, 0) -
                                            ueh_head_total_amount_tab(ln_target_cnt);
--
        -- *** 差異区分 ***
        -- 差額≠０の場合
        IF (ueh_head_balance_tab(ln_target_cnt) <> 0) THEN
          ueh_head_output_flag_tab(ln_target_cnt) := gv_ktg_yes ;
        -- 差額＝０の場合
        ELSE
          ueh_head_output_flag_tab(ln_target_cnt) := gv_ktg_no ;
        END IF;
--
        -- *** 支払確定区分 ***
        -- 請求金額 = NULL の場合
        IF (gt_exch_deliv_tab(ln_index).charged_amount IS NULL) THEN
          ueh_head_defined_flag_tab(ln_target_cnt) :=  gv_ktg_no;
        -- 差異区分 = YES の場合
        ELSIF (ueh_head_output_flag_tab(ln_target_cnt) = gv_ktg_yes) THEN
          ueh_head_defined_flag_tab(ln_target_cnt) :=  gv_ktg_no;
        -- 差異区分 = NO の場合
        ELSE
          ueh_head_defined_flag_tab(ln_target_cnt) :=  gv_ktg_yes;
        END IF;
--
        -- *** 支払確定戻 ***
        ueh_head_return_flag_tab(ln_target_cnt)  := gv_ktg_no ;
--
        -- **************************************************
        -- * 削除用PL/SQL表 設定
        -- **************************************************
        -- 差異区分 = Y の場合
        IF (ueh_head_output_flag_tab(ln_target_cnt) = gv_ktg_yes) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate：*** 洗替 削除用PL/SQL表 設定 ：'|| TO_CHAR(ln_index) || '配送No：' || gt_exch_deliv_tab(ln_index).delivery_no);
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          --削除用 PL/SQL表に設定
          ln_delete_cnt := ln_delete_cnt + 1;
          deh_head_deliv_no_tab(ln_delete_cnt) := gt_exch_deliv_tab(ln_index).delivery_no;

          -- 実績変更による削除 ログ出力用領域格納
          gn_delete_data_idx := gn_delete_data_idx + 1;
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_exch_deliv_tab(ln_index).delivery_no     || '  ' ;  -- 配送No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || gt_exch_deliv_tab(ln_index).delivery_company_code || '  ' ; -- 運送業者
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(gt_exch_deliv_tab(ln_index).ship_date, 'YYYY/MM/DD'); -- 出荷日
--
        END IF;
--
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
    END LOOP deliv_loop;
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
  END set_exch_deliv_hate;
--
  /**********************************************************************************
   * Procedure Name   : update_exch_deliv_head
   * Description      : 洗替運賃アドオンマスタ一括更新(A-47)
   ***********************************************************************************/
  PROCEDURE update_exch_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_exch_deliv_head'; -- プログラム名
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
    IF (ueh_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃ヘッダアドオン 更新
      -- **************************************************
      FORALL ln_index IN ueh_head_deliv_no_tab.FIRST .. ueh_head_deliv_no_tab.LAST
      UPDATE xxwip_deliverys            -- 運賃ヘッダアドオン
        SET     contract_rate           = ueh_head_contract_rate_tab(ln_index)-- 契約運賃
              , balance                 = ueh_head_balance_tab(ln_index)      -- 差額
              , total_amount            = ueh_head_total_amount_tab(ln_index) -- 合計
              , consolid_surcharge      = ueh_head_cnsld_srhrg_tab(ln_index)  -- 混載割増金額
              , picking_charge          = ueh_head_pick_charge_tab(ln_index)  -- ピッキング料
              , output_flag             = ueh_head_output_flag_tab(ln_index)  -- 差異区分
              , defined_flag            = ueh_head_defined_flag_tab(ln_index) -- 支払確定区分
              , return_flag             = ueh_head_return_flag_tab(ln_index)  -- 支払確定戻
--2008/08/04 Add ↓
              , distance                = ueh_head_distance_type_tab(ln_index)     -- 最長距離
              , actual_distance         = ueh_head_actual_ditnc_type_tab(ln_index) -- 最長実際距離
--2008/08/04 Add ↑
              , last_updated_by         = gn_user_id                 -- 最終更新者
              , last_update_date        = gd_sysdate                 -- 最終更新日
              , last_update_login       = gn_login_id                -- 最終更新ログイン
              , request_id              = gn_conc_request_id         -- 要求ID
              , program_application_id  = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
              , program_id              = gn_conc_program_id         -- コンカレント・プログラムID
              , program_update_date     = gd_sysdate                 -- プログラム更新日
        WHERE   delivery_no = ueh_head_deliv_no_tab(ln_index)        -- 配送No
        AND     p_b_classe  = gv_pay;                                -- 支払請求区分
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_ins_cnt := gn_deliv_ins_cnt + SQL%ROWCOUNT;
--
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
  END update_exch_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : delete_exch_deliv_head
   * Description      : 洗替運賃アドオンマスタ一括削除(A-48)
   ***********************************************************************************/
  PROCEDURE delete_exch_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_exch_deliv_head'; -- プログラム名
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
    IF (deh_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * 運賃ヘッダアドオン 削除
      -- **************************************************
      FORALL ln_index IN deh_head_deliv_no_tab.FIRST .. deh_head_deliv_no_tab.LAST
      DELETE FROM  xxwip_deliverys  -- 運賃ヘッダアドオン
        WHERE   delivery_no = deh_head_deliv_no_tab(ln_index) -- 配送No
        AND     p_b_classe  = gv_claim;                       -- 支払請求区分（請求）
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
--
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
  END delete_exch_deliv_head;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
--
  /**********************************************************************************
   * Procedure Name   : delete_exch_deliv_mst
   * Description      : 洗替運賃マスタ一括更新(A-48-1)
   ***********************************************************************************/
  PROCEDURE delete_exch_deliv_mst(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_exch_deliv_mst'; -- プログラム名
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
    --
    -- 洗替完了後、各マスタのフラグを'0'に更新する
    --
--
    --運賃用運送業者マスタ
      UPDATE xxwip_delivery_company xdco
      SET    xdco.pay_change_flg          = gv_target_n                -- 支払変更フラグ（N）
           , xdco.last_updated_by         = gn_user_id                 -- 最終更新者
           , xdco.last_update_date        = gd_sysdate                 -- 最終更新日
           , xdco.last_update_login       = gn_login_id                -- 最終更新ログイン
           , xdco.request_id              = gn_conc_request_id         -- 要求ID
           , xdco.program_application_id  = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
           , xdco.program_id              = gn_conc_program_id         -- コンカレント・プログラムID
           , xdco.program_update_date     = gd_sysdate                 -- プログラム更新日
      WHERE  xdco.pay_change_flg = gv_target_y   -- 支払変更フラグ
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND  xdco.goods_classe            = gv_prod_div                -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      ;
--
    -- 配送距離マスタ
      UPDATE  xxwip_delivery_distance xdd
      SET     xdd.change_flg              = gv_target_n                -- 変更フラグ（N）
            , xdd.last_updated_by         = gn_user_id                 -- 最終更新者
            , xdd.last_update_date        = gd_sysdate                 -- 最終更新日
            , xdd.last_update_login       = gn_login_id                -- 最終更新ログイン
            , xdd.request_id              = gn_conc_request_id         -- 要求ID
            , xdd.program_application_id  = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            , xdd.program_id              = gn_conc_program_id         -- コンカレント・プログラムID
            , xdd.program_update_date     = gd_sysdate                 -- プログラム更新日
      WHERE   xdd.change_flg = gv_target_y      -- 変更フラグ
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND   xdd.goods_classe            = gv_prod_div                -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      ;
--
    -- 運賃マスタ
      UPDATE  xxwip_delivery_charges xdch
      SET     xdch.change_flg = gv_target_n                             -- 変更フラグ（N）
            , xdch.last_updated_by         = gn_user_id                 -- 最終更新者
            , xdch.last_update_date        = gd_sysdate                 -- 最終更新日
            , xdch.last_update_login       = gn_login_id                -- 最終更新ログイン
            , xdch.request_id              = gn_conc_request_id         -- 要求ID
            , xdch.program_application_id  = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            , xdch.program_id              = gn_conc_program_id         -- コンカレント・プログラムID
            , xdch.program_update_date     = gd_sysdate                 -- プログラム更新日
      WHERE   xdch.change_flg = gv_target_y      -- 変更フラグ（Y）
      AND     xdch.p_b_classe = gv_pay           -- 支払請求区分:支払
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      AND     xdch.goods_classe            = gv_prod_div                -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
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
  END delete_exch_deliv_mst;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
  /**********************************************************************************
   * Procedure Name   : delete_deli_cleaning
   * Description      : 配車組換削除(A-35-2)
   ***********************************************************************************/
  PROCEDURE delete_deli_cleaning(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_deli_cleaning'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
      -- **************************************************
      -- * 通常配車、且つ、運賃ヘッダに存在して、
      -- *            運賃明細に存在しない配送Noを削除
      -- **************************************************
      DELETE FROM  xxwip_deliverys xd        -- 運賃ヘッダアドオン
        WHERE  xd.dispatch_type = gv_car_normal  -- 通常配車
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
        AND    xd.goods_classe  = gv_prod_div    -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
        AND    NOT EXISTS (SELECT 'x'
                           FROM   xxwip_delivery_lines xdl
                           WHERE  xd.delivery_no = xdl.delivery_no);
--
      -- **************************************************
      -- 件数設定
      -- **************************************************
-- ##### 20081229 Ver.1.19 本番#882対応 START #####
-- 配車組換による削除件数はカウントしない
--      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
-- ##### 20081229 Ver.1.19 本番#882対応 END   #####
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
  END delete_deli_cleaning;
--
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_exchange_type  IN         VARCHAR2,     -- 洗い替え区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
    iv_prod_div       IN         VARCHAR2,     -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_message    VARCHAR2(5000);  -- メッセージ出力
    lv_target_flg VARCHAR2(1);     -- 対象データ有無フラグ 0:無し、1:有り
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =========================================
    -- パラメータチェック処理(C-1)
    -- =========================================
    chk_param_proc(
      iv_exchange_type,  -- 洗い替え区分
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 関連データ取得(C-2)
    -- =========================================
    get_init(
      iv_exchange_type,  -- 洗い替え区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      iv_prod_div,       -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ロック取得(A-4)
    -- =========================================
    get_deliv_lock(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 洗替区分 = N の場合
    IF (iv_exchange_type = gv_ktg_no) THEN
--
      -- =========================================
      -- 受注実績情報抽出(A-5)
      -- =========================================
      get_order(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 受注関連情報抽出(A-6)
      -- =========================================
      get_order_other(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 受注明細アドオン抽出(A-9)
      -- =========================================
      get_order_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 受注運賃明細アドオンPL/SQL表格納(A-13)
      -- =========================================
      set_order_deliv_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 移動実績情報抽出(A-14)
      -- =========================================
      get_move(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 移動関連情報抽出
      -- =========================================
      get_move_other(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 移動明細アドオン抽出(A-18)
      -- =========================================
      get_move_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 移動運賃明細アドオンPL/SQL表格納(A-22)
      -- =========================================
      set_move_deliv_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃明細アドオン一括登録(A-23)
      -- =========================================
      insert_deliv_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃明細アドオン一括再計算更新(A-24)
      -- =========================================
      update_deliv_line_calc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃明細アドオン一括適用更新(A-25)
      -- =========================================
      update_deliv_line_desc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 START #####
      -- =========================================
      -- 配車解除対象依頼No抽出(A-25-1)
      -- =========================================
      get_carcan_req_no(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 配車解除データが存在する場合のみ
      IF (gt_carcan_info_tab.COUNT <> 0) THEN
        -- =========================================
        -- 配車解除配送No抽出(A-25-2)
        -- =========================================
        get_carcan_deliv_no(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
        -- =========================================
        -- 配車解除依頼No削除(A-25-3)
        -- =========================================
        delete_carcan_req_no(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- 配車解除配送No存在確認(A-25-4)
        -- =========================================
        check_carcan_deliv_no(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- 配車解除運賃明細アドオン更新(A-25-5)
        -- =========================================
        update_carcan_deliv_line(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- 配車解除運賃ヘッダアドオン削除(A-25-6)
        -- =========================================
        delete_carcan_deliv_head(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
-- ##### 20080717 Ver.1.5 変更要求96,98 END   #####
--
      -- =========================================
      -- 運賃明細アドオン対象配送No抽出(A-26)
      -- =========================================
      get_delinov_line_desc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃明細アドオン抽出(A-27)
      -- =========================================
      get_deliv_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃ヘッダアドオンPL/SQL表格納(A-30)
      -- =========================================
      set_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 配車配送計画抽出(A-31)
      -- =========================================
      get_carriers_schedule(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 配車のみ運賃ヘッダアドオンPL/SQL表格納(A-32)
      -- =========================================
      set_carri_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃ヘッダアドオン一括登録(A-33)
      -- =========================================
      insert_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃ヘッダアドオン一括更新(A-34)
      -- =========================================
      update_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃ヘッダアドオン一括削除(A-35)
      -- =========================================
      delete_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- ##### 20081210 Ver.1.16 本番#401対応 START #####
      -- =========================================
      -- 配車組換削除
      -- =========================================
      delete_deli_cleaning(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- ##### 20081210 Ver.1.16 本番#401対応 END   #####
--
      -- =========================================
      -- 運賃計算コントロール更新処理(A-36)
      -- =========================================
      update_deliv_cntl(
        iv_exchange_type,  -- 洗い替え区分
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- 洗替区分 = Y の場合
    ELSE
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
--
      -- =========================================
      -- ロック取得（運賃関連マスタ）
      -- =========================================
      get_delivmst_lock(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
      -- =========================================
      -- 洗替運賃明細アドオン抽出(A-37)
      -- =========================================
      get_exch_deliv_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃明細アドオンPL/SQL表格納(A-38)
      -- =========================================
      set_exch_deliv_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃明細アドオン一括更新(A-39)
      -- =========================================
      update_exch_deliv_line(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃明細アドオン対象配送No抽出(A-40)
      -- =========================================
      get_exch_delino(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃明細アドオン抽出(A-41)
      -- =========================================
      get_exch_deliv_line_h(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃ヘッダアドオン明細項目更新用PL/SQL表格納(A-42)
      -- =========================================
      set_exch_deliv_head_h(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃ヘッダアドオン明細項目一括更新(A-43)
      -- =========================================
      update_exch_deliv_head_h(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃ヘッダアドオン抽出(A-44)
      -- =========================================
      get_exch_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃アドオンマスタ抽出(A-45)
      -- =========================================
      get_exch_deliv_charg(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃ヘッダアドオンPL/SQL表格納(A-46)
      -- =========================================
      set_exch_deliv_hate(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃アドオンマスタ一括更新(A-47)
      -- =========================================
      update_exch_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 洗替運賃アドオンマスタ一括削除(A-48)
      -- =========================================
      delete_exch_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 start *----------*
--
      -- =========================================
      -- 洗替運賃マスタ一括更新
      -- =========================================
      delete_exch_deliv_mst(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 本番#432対応 end   *----------*
--
    END IF;
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
    errbuf            OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode           OUT NOCOPY VARCHAR2,      --   リターン・コード    --# 固定 #
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
--    iv_exchange_type  IN         VARCHAR2       --   荒い替え区分
    iv_exchange_type  IN         VARCHAR2,      --   洗替区分
    iv_prod_div       IN         VARCHAR2       --   商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
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
    lv_message VARCHAR2(5000);  -- ユーザー・メッセージ
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
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MM:SS'));
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
    submain(
      iv_exchange_type,  -- 洗い替え区分
-- ##### Ver.1.28 E_本稼動_13659対応 START #####
      iv_prod_div,       -- 商品区分
-- ##### Ver.1.28 E_本稼動_13659対応 END   #####
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- =========================================
    -- メッセージ出力(C-16)
    -- =========================================
--
    -- 運賃ヘッダアドオン処理件数メッセージ
    lv_message := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn, gv_xxwip_msg_deliv_ins);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 成功件数出力
    lv_message := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn, gv_xxcmn_msg_okcnt,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_deliv_ins_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 運賃明細アドオン処理件数メッセージ
    lv_message := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn, gv_xxwip_msg_deliv_line);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 成功件数出力
    lv_message := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn, gv_xxcmn_msg_okcnt,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_deliv_line_ins_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 運賃ヘッダ請求削除件数メッセージ
    lv_message := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn, gv_xxwip_msg_deliv_del);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 成功件数出力
    lv_message := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn, gv_xxcmn_msg_okcnt,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_deliv_del_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） START #####
    -- 削除データ ログ出力
    IF ( gn_delete_data_idx <> 0 ) THEN
--
      -- タイトル表示
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- 空行
-- ##### 20081229 Ver.1.19 本番#882対応 START #####
--      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '削除配送No          ') ;
--      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '--------------------') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '配送No        運送  発日       ') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '-------------------------------') ;
-- ##### 20081229 Ver.1.19 本番#882対応 END   #####
--
      FOR i IN 1..gn_delete_data_idx LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gt_delete_data_msg(i)) ;
      END LOOP ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- 空行
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;  -- 区切り文字列出力
--
    END IF;
-- ##### 20081226 Ver.1.18 本番#323対応（ログ対応） END   #####
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
END xxwip730001c;
/
