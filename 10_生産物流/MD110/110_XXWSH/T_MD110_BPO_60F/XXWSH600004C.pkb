create or replace PACKAGE BODY xxwsh600004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH600004C(body)
 * Description      : ＨＨＴ入出庫配車確定情報抽出処理
 * MD.050           : T_MD050_BPO_601_配車配送計画
 * MD.070           : T_MD070_BPO_60F_ＨＨＴ入出庫配車確定情報抽出処理
 * Version          : 1.20
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_chk_param          パラメータチェック             (F-01)
 *  prc_get_profile        プロファイル取得               (F-02)
 *  prc_del_temp_data      テーブル削除                   (F-03)
 *  prc_get_main_data      メインデータ抽出               (F-04)
 *  prc_cre_head_data      ヘッダデータ作成
 *  prc_cre_dtl_data       明細データ作成
 *  prc_create_ins_data    通知済情報作成処理             (F-05)
 *  prc_create_can_data    変更前情報取消データ作成処理   (F-06)
 *  prc_ins_temp_data      一括登録処理                   (F-07)
 *  prc_out_csv_data       ＣＳＶ出力処理                 (F-08)
 *  prc_ins_out_data       通知済みデータ登録処理         (F-09,F-10)
 *  prc_put_err_log        混載エラーログ出力処理         (F-11)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/02    1.0   M.Ikeda          新規作成
 *  2008/06/04    1.1   N.Yoshida        移動ロット詳細紐付け対応
 *  2008/06/11    1.2   M.Hokkanji       配車が組まれていない場合でも出力されるように修正
 *  2008/06/12    1.3   M.Nomura         結合テスト 不具合対応#7
 *  2008/06/17    1.4   M.Hokkanji       システムテスト 不具合対応#153
 *  2008/06/19    1.5   M.Nomura         システムテスト 不具合対応#193
 *  2008/06/27    1.6   M.Nomura         システムテスト 不具合対応#303
 *  2008/07/04    1.7   M.Nomura         システムテスト 不具合対応#193 2回目
 *  2008/07/17    1.8   Oracle 山根 一浩 I_S_192,T_S_443,指摘240対応
 *  2008/07/22    1.9   N.Fukuda         I_S_001対応(予備1を引取/小口区分で使用する)
 *  2008/08/08    1.10  Oracle 山根 一浩 TE080_400指摘#83,課題#32
 *  2008/08/11    1.10  N.Fukuda         指示部署の抽出条件SQLの不具合対応
 *  2008/08/12    1.10  N.Fukuda         課題#48(変更要求#164)対応
 *  2008/08/29    1.11  N.Fukuda         TE080_600指摘#27(1)対応(全部明細取消のパターン)
 *  2008/08/29    1.11  N.Fukuda         TE080_600指摘#27(3)対応(一部明細取消のパターン)
 *  2008/08/29    1.11  N.Fukuda         TE080_600指摘#28対応
 *  2008/08/29    1.11  N.Fukuda         TE080_600指摘#29対応(TE080_400指摘#83の再修正)
 *  2008/08/29    1.12  N.Fukuda         取消ヘッダに品目数量・ロット数量に0がセットされている
 *  2008/09/09    1.13  N.Fukuda         TE080_600指摘#30対応
 *  2008/09/10    1.13  N.Fukuda         参照Viewの変更(パーティから顧客に変更)
 *  2008/09/25    1.14  M.Nomura         統合#26対応
 *  2008/10/07    1.15  M.Nomura         TE080_600指摘#27対応
 *  2008/11/07    1.16  N.Fukuda         統合指摘#143対応
 *  2009/01/26    1.17  N.Yoshida        本番1017対応、本番#1044対応
 *  2009/02/09    1.18  M.Nomura         本番#1082対応
 *  2009/04/24    1.19  H.Itou           本番#1398対応
 *  <<営業C/O後>>
 *  2009/12/03    1.20  Marushita        本番276対応
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  -- ==============================================================================================
  -- ユーザー定義例外
  -- ==============================================================================================
  -- ロック取得例外
  ex_lock_error    EXCEPTION ;
  file_exists_expt EXCEPTION ;
  PRAGMA EXCEPTION_INIT( ex_lock_error, -54 ) ;
--
  -- ==============================================================================================
  -- グローバル定数
  -- ==============================================================================================
  --------------------------------------------------
  -- パッケージ名
  --------------------------------------------------
  gc_pkg_name           CONSTANT VARCHAR2(100)  := 'XXWSH600004C';
--
  --------------------------------------------------
  -- アプリケーション短縮名
  --------------------------------------------------
  gc_appl_sname_cmn     CONSTANT VARCHAR2(100)  := 'XXCMN' ;    -- マスタ共通
  gc_appl_sname_wsh     CONSTANT VARCHAR2(100)  := 'XXWSH' ;    -- 出荷
--
  --------------------------------------------------
  -- クイックコード（タイプ）
  --------------------------------------------------
  gc_lookup_ship_method     CONSTANT VARCHAR2(50) := 'XXCMN_SHIP_METHOD' ; -- 配送区分
  --------------------------------------------------
  -- クイックコード（値）
  --------------------------------------------------
  -- ステータス
  gc_req_status_syu_1   CONSTANT VARCHAR2(2) := '01' ;  -- 入力中
  gc_req_status_syu_2   CONSTANT VARCHAR2(2) := '02' ;  -- 拠点確定
  gc_req_status_syu_3   CONSTANT VARCHAR2(2) := '03' ;  -- 締め済み
  gc_req_status_syu_4   CONSTANT VARCHAR2(2) := '04' ;  -- 出荷実績計上済
  gc_req_status_syu_5   CONSTANT VARCHAR2(2) := '99' ;  -- 取消
  -- 通知ステータス
  gc_notif_status_n     CONSTANT VARCHAR2(2) := '10' ;  -- 未通知
  gc_notif_status_r     CONSTANT VARCHAR2(2) := '20' ;  -- 再通知要
  gc_notif_status_c     CONSTANT VARCHAR2(2) := '40' ;  -- 確定通知済
  -- 重量容積区分
  gc_wc_class_j         CONSTANT VARCHAR2(1) := '1' ;   -- 重量
  gc_wc_class_y         CONSTANT VARCHAR2(1) := '2' ;   -- 容積
  -- 小口区分
  gc_small_method_y     CONSTANT VARCHAR2(1) := '1' ;   -- 小口
  gc_small_method_n     CONSTANT VARCHAR2(1) := '0' ;   -- 小口以外
--
  /* 2008/08/08 Mod ↓
  -- 2008/07/22 I_S_001 Add Start --------------------------
  -- 引取/小口区分（予備１）
  gc_small_class        CONSTANT VARCHAR2(1) := '1' ;   -- 小口
  gc_takeback_class     CONSTANT VARCHAR2(1) := '2' ;   -- 引取
  -- 2008/07/22 I_S_001 Add End -----------------------------
  2008/08/08 Mod ↑ */
--
  -- 2008/08/29 TE080_600指摘#29対応(TE080_400指摘#83の再修正) Del Start ---------
  ---- 引取/小口区分（予備１）
  --gc_small_class        CONSTANT VARCHAR2(1) := '0' ;   -- 小口
  --gc_takeback_class     CONSTANT VARCHAR2(1) := '1' ;   -- 引取
  -- 2008/08/29 TE080_600指摘#29対応(TE080_400指摘#83の再修正) Del End ----------
--
  -- 2008/08/29 TE080_600指摘#29対応(TE080_400指摘#83の再修正) Add Start --------
  -- 引取/小口区分（予備１）
  gc_takeback_class     CONSTANT VARCHAR2(1) := '1' ;   -- 引取
  gc_small_class        CONSTANT VARCHAR2(1) := '2' ;   -- 小口
  -- 2008/08/29 TE080_600指摘#29対応(TE080_400指摘#83の再修正) Add End ----------
--
  -- Ｙ／Ｎフラグ
  gc_yes_no_y           CONSTANT VARCHAR2(1) := 'Y' ;   -- Ｙ
  gc_yes_no_n           CONSTANT VARCHAR2(1) := 'N' ;   -- Ｎ
  -- 運賃区分
-- M.Hokkanji Ver1.2 START
  gc_freight_class_y    CONSTANT VARCHAR2(1) := '1' ;   -- 対象
  gc_freight_class_n    CONSTANT VARCHAR2(1) := '0' ;   -- 対象外
--  gc_freight_class_y    CONSTANT VARCHAR2(1) := 'Y' ;   -- 対象
--  gc_freight_class_n    CONSTANT VARCHAR2(1) := 'N' ;   -- 対象外
-- M.Hokkanji Ver1.2 END
  --出荷支給区分
  gc_sp_class_ship      CONSTANT VARCHAR2(1)  := '1' ;    -- 出荷依頼
  gc_sp_class_move      CONSTANT VARCHAR2(1)  := '3' ;    -- 移動（プログラム内限定）
  -- 内外倉庫区分
  gc_whse_io_div_i      CONSTANT VARCHAR2(1)  := '1' ;    -- 内部倉庫
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 START #####
  gc_whse_io_div_o      CONSTANT VARCHAR2(1)  := '2' ;    -- 外部倉庫
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 END   #####
  -- 移動ステータス
  gc_mov_status_req       CONSTANT VARCHAR2(2)  := '01' ;   -- 依頼中
  gc_mov_status_cmp       CONSTANT VARCHAR2(2)  := '02' ;   -- 依頼済
  gc_mov_status_adj       CONSTANT VARCHAR2(2)  := '03' ;   -- 調整中
  gc_mov_status_del       CONSTANT VARCHAR2(2)  := '04' ;   -- 出庫報告有
  gc_mov_status_stc       CONSTANT VARCHAR2(2)  := '05' ;   -- 入庫報告有
  gc_mov_status_dsr       CONSTANT VARCHAR2(2)  := '06' ;   -- 入出庫報告有
  gc_mov_status_ccl       CONSTANT VARCHAR2(2)  := '99' ;   -- 取消
  -- 移動タイプ
  gc_mov_type_y           CONSTANT VARCHAR2(1)  := '1' ;    -- 積送あり
  gc_mov_type_n           CONSTANT VARCHAR2(1)  := '2' ;    -- 積送なし
  -- 商品区分
  gc_prod_class_r         CONSTANT VARCHAR2(1)  := '1' ;    -- リーフ
  gc_prod_class_d         CONSTANT VARCHAR2(1)  := '2' ;    -- ドリンク
  -- 品目区分
  gc_item_class_g         CONSTANT VARCHAR2(1)  := '1' ;    -- 原料
  gc_item_class_s         CONSTANT VARCHAR2(1)  := '2' ;    -- 資材
  gc_item_class_h         CONSTANT VARCHAR2(1)  := '4' ;    -- 半製品
  gc_item_class_i         CONSTANT VARCHAR2(1)  := '5' ;    -- 製品
  -- ロット管理
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ロット管理あり
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ロット管理なし
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_ship        CONSTANT VARCHAR2(2) := '10' ;    -- 出荷指示
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;    -- 移動
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;    -- 支給指示
  gc_doc_type_prod        CONSTANT VARCHAR2(2) := '40' ;    -- 生産指示
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- 指示
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- 出庫実績
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- 入庫実績
  gc_rec_type_tron        CONSTANT VARCHAR2(2) := '40' ;    -- 投入済
  -- ロットマスタ：有効フラグ
  gc_inactive_ind_y       CONSTANT VARCHAR2(1) := '0' ;     -- 有効
  -- ロットマスタ：削除フラグ
  gc_delete_mark_y        CONSTANT VARCHAR2(1) := '0' ;     -- 未削除
--
-- ##### 2009/04/24 Ver.1.19 本番#1398対応 START #####
  -- マスタステータス
  gc_status_active        CONSTANT VARCHAR2(1) := 'A' ;     -- 有効
  gc_status_inactive      CONSTANT VARCHAR2(1) := 'I' ;     -- 無効
-- ##### 2009/04/24 Ver.1.19 本番#1398対応 END   #####
  --------------------------------------------------
  -- 登録値
  --------------------------------------------------
  gc_corporation_name       CONSTANT VARCHAR2(100) := 'ITOEN' ;
  gc_reserve                CONSTANT VARCHAR2(100) := '000000000000' ;
  -- 明細削除フラグ
  gc_delete_flag_y          CONSTANT VARCHAR2(1) := '1' ;   -- 削除
  gc_delete_flag_n          CONSTANT VARCHAR2(1) := '0' ;   -- 未削除
  -- データタイプ
  gc_data_type_syu_ins      CONSTANT VARCHAR2(1) := '1' ;   -- 出荷：登録
  gc_data_type_mov_ins      CONSTANT VARCHAR2(1) := '3' ;   -- 移動：登録
  gc_data_type_syu_can      CONSTANT VARCHAR2(1) := '7' ;   -- 出荷：取消 -- 2008/08/29 TE080_600指摘#27(1) Add
  gc_data_type_mov_can      CONSTANT VARCHAR2(1) := '9' ;   -- 移動：取消 -- 2008/08/29 TE080_600指摘#27(1) Add
  -- 運賃区分
  gc_freight_class_ins_y    CONSTANT VARCHAR2(1) := '1' ;   -- 対象
  gc_freight_class_ins_n    CONSTANT VARCHAR2(1) := '0' ;   -- 対象外
  -- データ種別
  gc_data_class_syu_s       CONSTANT VARCHAR2(3) := '110' ;   -- 出荷：出荷依頼
  gc_data_class_mov_s       CONSTANT VARCHAR2(3) := '120' ;   -- 移動：出荷依頼
  gc_data_class_mov_n       CONSTANT VARCHAR2(3) := '130' ;   -- 移動：移動入庫
  -- ステータス
  gc_status_y               CONSTANT VARCHAR2(2) := '01' ;    -- 予定
  gc_status_k               CONSTANT VARCHAR2(2) := '02' ;    -- 確定
  -- データ区分
  gc_data_class_ins         CONSTANT VARCHAR2(1) := '0' ;     -- 追加
-- M.Hokkanji Ver1.2 START
--  gc_data_class_del         CONSTANT VARCHAR2(1) := '2' ;     -- 削除
-- ##### 20080612 Ver.1.2 データ区分削除コード対応 START #####
--  gc_data_class_del         CONSTANT VARCHAR2(1) := '2' ;     -- 削除
  gc_data_class_del         CONSTANT VARCHAR2(1) := '1' ;     -- 削除
-- ##### 20080612 Ver.1.2 データ区分削除コード対応 START #####
  gc_product_flg_1          CONSTANT VARCHAR2(1) := '1' ;     -- 製品
  gc_product_flg_0          CONSTANT VARCHAR2(1) := '0' ;     -- 製品以外
-- M.Hokkanji Ver1.2 END
  -- ワークフロー区分
  gc_wf_class_gai           CONSTANT VARCHAR2(1) := '1' ;     -- 外部倉庫
  gc_wf_class_uns           CONSTANT VARCHAR2(1) := '2' ;     -- 運送業者
  gc_wf_class_tor           CONSTANT VARCHAR2(1) := '3' ;     -- 取引先
  gc_wf_class_hht           CONSTANT VARCHAR2(1) := '4' ;     -- HHTサーバー
  gc_wf_class_sys           CONSTANT VARCHAR2(1) := '5' ;     -- 現営業システム
  gc_wf_class_syo           CONSTANT VARCHAR2(1) := '6' ;     -- 職責
--
  --------------------------------------------------
  -- その他
  --------------------------------------------------
  gc_time_default           CONSTANT VARCHAR2(4) := '0000' ;    -- 時間デフォルト値
  gc_time_min               CONSTANT VARCHAR2(5) := '00:00' ;   -- 時間最小値
  gc_time_max               CONSTANT VARCHAR2(5) := '23:59' ;   -- 時間最大値
--
  -- ==============================================================================================
  -- グローバル変数
  -- ==============================================================================================
  gd_effective_date   DATE ;    -- マスタ絞込み日付
  gd_date_from        DATE ;    -- 基準日付From
  gd_date_to          DATE ;    -- 基準日付To
--
  --------------------------------------------------
  -- プロファイル
  --------------------------------------------------
  gn_prof_del_date            NUMBER ;          -- 削除基準日数
  gv_prof_put_file_name       VARCHAR2(100) ;   -- 出力ファイル名
  gv_prof_put_file_path       VARCHAR2(100) ;   -- 出力ファイルディレクトリ
  gv_prof_type_plan           VARCHAR2(100) ;   -- 引取変更           -- 2008/07/22 I_S_001 Add
--
  gr_outbound_rec     xxcmn_common_pkg.outbound_rec ;   -- ファイル情報のレコードの定義
--
  --------------------------------------------------
  -- ＷＨＯカラム
  --------------------------------------------------
  gn_created_by               NUMBER ;  -- 作成者
  gn_last_updated_by          NUMBER ;  -- 最終更新者
  gn_last_update_login        NUMBER ;  -- 最終更新ログイン
  gn_request_id               NUMBER ;  -- 要求ID
  gn_program_application_id   NUMBER ;  -- コンカレント・プログラム・アプリケーションID
  gn_program_id               NUMBER ;  -- コンカレント・プログラムID
--
  gn_out_cnt_syu              NUMBER DEFAULT 0 ;   -- 出力件数：出荷
  gn_out_cnt_mov              NUMBER DEFAULT 0 ;   -- 出力件数：移動
--
  --------------------------------------------------
  -- デバッグ用
  --------------------------------------------------
  gv_debug_txt                VARCHAR2(1000) ;
  gv_debug_cnt                NUMBER DEFAULT 0 ;
--
  -- ==============================================================================================
  -- レコード型宣言
  -- ==============================================================================================
  --------------------------------------------------
  -- 入力パラメータ格納用
  --------------------------------------------------
  TYPE rec_param_data  IS RECORD
    (
      dept_code_01      VARCHAR2(4)   -- 01 : 部署
     ,dept_code_02      VARCHAR2(4)   -- 02 : 部署(2008/07/17 Add)
     ,dept_code_03      VARCHAR2(4)   -- 03 : 部署(2008/07/17 Add)
     ,dept_code_04      VARCHAR2(4)   -- 04 : 部署(2008/07/17 Add)
     ,dept_code_05      VARCHAR2(4)   -- 05 : 部署(2008/07/17 Add)
     ,dept_code_06      VARCHAR2(4)   -- 06 : 部署(2008/07/17 Add)
     ,dept_code_07      VARCHAR2(4)   -- 07 : 部署(2008/07/17 Add)
     ,dept_code_08      VARCHAR2(4)   -- 08 : 部署(2008/07/17 Add)
     ,dept_code_09      VARCHAR2(4)   -- 09 : 部署(2008/07/17 Add)
     ,dept_code_10      VARCHAR2(4)   -- 10 : 部署(2008/07/17 Add)
     ,date_fix          VARCHAR2(20)  -- 11 : 確定通知実施日
     ,fix_from          VARCHAR2(10)  -- 12 : 確定通知実施時間From
     ,fix_to            VARCHAR2(10)  -- 13 : 確定通知実施時間To
    ) ;
  gr_param              rec_param_data ;
--
  --------------------------------------------------
  -- 中間テーブル格納用
  --------------------------------------------------
  TYPE rec_main_data  IS RECORD
    (
      line_number               xxwsh_hht_stock_deliv_info_tmp.line_number%TYPE
     ,line_id                   xxinv_mov_lot_details.mov_line_id%TYPE
     ,prev_notif_status         VARCHAR2(2)
     ,data_type                 xxwsh_hht_stock_deliv_info_tmp.data_type%TYPE
     ,delivery_no               xxwsh_hht_stock_deliv_info_tmp.delivery_no%TYPE
     ,request_no                xxwsh_hht_stock_deliv_info_tmp.request_no%TYPE
     ,head_sales_branch         xxwsh_hht_stock_deliv_info_tmp.head_sales_branch%TYPE
     ,head_sales_branch_name    xxwsh_hht_stock_deliv_info_tmp.head_sales_branch_name%TYPE
     ,shipped_locat_code        xxwsh_hht_stock_deliv_info_tmp.shipped_locat_code%TYPE
     ,shipped_locat_name        xxwsh_hht_stock_deliv_info_tmp.shipped_locat_name%TYPE
     ,ship_to_locat_code        xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_code%TYPE
     ,ship_to_locat_name        xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_name%TYPE
     ,freight_carrier_code      xxwsh_hht_stock_deliv_info_tmp.freight_carrier_code%TYPE
     ,freight_carrier_name      xxwsh_hht_stock_deliv_info_tmp.freight_carrier_name%TYPE
     ,deliver_to                xxwsh_hht_stock_deliv_info_tmp.deliver_to%TYPE
     ,deliver_to_name           xxwsh_hht_stock_deliv_info_tmp.deliver_to_name%TYPE
     ,schedule_ship_date        xxwsh_hht_stock_deliv_info_tmp.schedule_ship_date%TYPE
     ,schedule_arrival_date     xxwsh_hht_stock_deliv_info_tmp.schedule_arrival_date%TYPE
     ,shipping_method_code      xxwsh_hht_stock_deliv_info_tmp.shipping_method_code%TYPE
     ,weight                    xxwsh_hht_stock_deliv_info_tmp.weight%TYPE
     ,mixed_no                  xxwsh_hht_stock_deliv_info_tmp.mixed_no%TYPE
     ,collected_pallet_qty      xxwsh_hht_stock_deliv_info_tmp.collected_pallet_qty%TYPE
     ,freight_charge_class      xxwsh_hht_stock_deliv_info_tmp.freight_charge_class%TYPE
     ,arrival_time_from         xxwsh_hht_stock_deliv_info_tmp.arrival_time_from%TYPE
     ,arrival_time_to           xxwsh_hht_stock_deliv_info_tmp.arrival_time_to%TYPE
     ,cust_po_number            xxwsh_hht_stock_deliv_info_tmp.cust_po_number%TYPE
     ,description               xxwsh_hht_stock_deliv_info_tmp.description%TYPE
     ,pallet_quantity_o         xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE
     ,pallet_quantity_i         xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE
     ,report_dept               xxwsh_hht_stock_deliv_info_tmp.report_dept%TYPE
     ,item_code                 xxwsh_hht_stock_deliv_info_tmp.item_code%TYPE
     ,item_id                   xxinv_mov_lot_details.item_id%TYPE
     ,item_name                 xxwsh_hht_stock_deliv_info_tmp.item_name%TYPE
     ,item_uom_code             xxwsh_hht_stock_deliv_info_tmp.item_uom_code%TYPE
     ,conv_unit                 xxcmn_item_mst2_v.conv_unit%TYPE
     ,item_quantity             xxwsh_hht_stock_deliv_info_tmp.item_quantity%TYPE
     ,num_of_cases              xxcmn_item_mst2_v.num_of_cases%TYPE
     ,lot_ctl                   xxcmn_item_mst2_v.lot_ctl%TYPE
     ,line_delete_flag          VARCHAR2(1)
     ,mov_lot_dtl_id            xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
-- ##### 20080619 1.5 ST不具合#193 START #####
     ,out_whse_inout_div        xxcmn_item_locations_v.whse_inside_outside_div%TYPE   -- 出 倉庫 内外倉庫区分
     ,in_whse_inout_div         xxcmn_item_locations_v.whse_inside_outside_div%TYPE   -- 入 倉庫 内外倉庫区分
-- ##### 20080619 1.5 ST不具合#193 END   #####
     ,reserve1         xxwsh_hht_stock_deliv_info_tmp.reserve1%TYPE   -- 引取/小口区分（予備１） -- 2008/07/22 I_S_001 Add
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
     ,notif_date         xxwsh_hht_stock_deliv_info_tmp.notif_date%TYPE -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
     ,sum_quantity              xxwsh_hht_stock_deliv_info_tmp.item_quantity%TYPE     -- 2008/11/07 統合指摘#143 Add
    ) ;
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER ;
  gt_main_data  tab_main_data ;
--
  --------------------------------------------------
  -- 通知済情報格納用
  --------------------------------------------------
  TYPE t_corporation_name        IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.corporation_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_class              IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.data_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_transfer_branch_no      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.transfer_branch_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_delivery_no             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_request_no              IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.request_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve                 IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch       IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.head_sales_branch%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch_name  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.head_sales_branch_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_code      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.shipped_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_name      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.shipped_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_code      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_name      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_code    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_name    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.freight_carrier_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to              IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to_name         IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.deliver_to_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_ship_date      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_arrival_date   IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipping_method_code    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.shipping_method_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_weight                  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.weight%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_mixed_no                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.mixed_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_collected_pallet_qty    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_from       IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.arrival_time_from%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_to         IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.arrival_time_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_cust_po_number          IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.cust_po_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_description             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.description%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_status                  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.status%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_charge_class    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.freight_charge_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_pallet_sum_quantity     IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve1                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve1%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve2                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve2%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve3                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve3%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve4                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve4%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_report_dept             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.report_dept%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_code               IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_name               IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_uom_code           IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_uom_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_quantity           IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_no                  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_date                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_sign                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_sign%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_best_bfr_date           IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.best_bfr_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_quantity            IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_new_modify_del_class    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.new_modify_del_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_update_date             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.update_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_line_number             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.line_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_type               IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.data_type%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
  TYPE t_notif_date              IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.notif_date%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
  gt_corporation_name         t_corporation_name ;
  gt_data_class               t_data_class ;
  gt_transfer_branch_no       t_transfer_branch_no ;
  gt_delivery_no              t_delivery_no ;
  gt_requesgt_no              t_request_no ;
  gt_reserve                  t_reserve ;
  gt_head_sales_branch        t_head_sales_branch ;
  gt_head_sales_branch_name   t_head_sales_branch_name ;
  gt_shipped_locat_code       t_shipped_locat_code ;
  gt_shipped_locat_name       t_shipped_locat_name ;
  gt_ship_to_locat_code       t_ship_to_locat_code ;
  gt_ship_to_locat_name       t_ship_to_locat_name ;
  gt_freight_carrier_code     t_freight_carrier_code ;
  gt_freight_carrier_name     t_freight_carrier_name ;
  gt_deliver_to               t_deliver_to ;
  gt_deliver_to_name          t_deliver_to_name ;
  gt_schedule_ship_date       t_schedule_ship_date ;
  gt_schedule_arrival_date    t_schedule_arrival_date ;
  gt_shipping_method_code     t_shipping_method_code ;
  gt_weight                   t_weight ;
  gt_mixed_no                 t_mixed_no ;
  gt_collected_pallet_qty     t_collected_pallet_qty ;
  gt_arrival_time_from        t_arrival_time_from ;
  gt_arrival_time_to          t_arrival_time_to ;
  gt_cust_po_number           t_cust_po_number ;
  gt_description              t_description ;
  gt_status                   t_status ;
  gt_freight_charge_class     t_freight_charge_class ;
  gt_pallet_sum_quantity      t_pallet_sum_quantity ;
  gt_reserve1                 t_reserve1 ;
  gt_reserve2                 t_reserve2 ;
  gt_reserve3                 t_reserve3 ;
  gt_reserve4                 t_reserve4 ;
  gt_report_dept              t_report_dept ;
  gt_item_code                t_item_code ;
  gt_item_name                t_item_name ;
  gt_item_uom_code            t_item_uom_code ;
  gt_item_quantity            t_item_quantity ;
  gt_lot_no                   t_lot_no ;
  gt_lot_date                 t_lot_date ;
  gt_lot_sign                 t_lot_sign ;
  gt_best_bfr_date            t_best_bfr_date ;
  gt_lot_quantity             t_lot_quantity ;
  gt_new_modify_del_class     t_new_modify_del_class ;
  gt_update_date              t_update_date ;
  gt_line_number              t_line_number ;
  gt_data_type                t_data_type ;
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
  gt_notif_date                t_notif_date ;
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
  gn_cre_idx                  NUMBER DEFAULT 0 ;
--
  -- 警告メッセージ用配列変数
  TYPE t_worm_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_worm_msg     t_worm_msg ;
  gn_wrm_idx      NUMBER := 0 ;
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : パラメータチェック(F-01)
   ***********************************************************************************************/
  PROCEDURE prc_chk_param
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_param' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_p_name_time_fix      CONSTANT VARCHAR2(50) := '確定通知実施時間' ;
    lc_msg_code_02          CONSTANT VARCHAR2(50) := 'APP-XXWSH-11905' ;  -- 時間逆転
    lc_tok_name             CONSTANT VARCHAR2(50) := 'PARAMETER' ;
--
    lc_date_format          CONSTANT VARCHAR2(50) := 'YYYY/MM/DD HH24:MI:SS' ;
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
    lv_tok_val        VARCHAR2(100) ;
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_param_error    EXCEPTION ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 逆転チェック
    -- ====================================================
    lv_msg_code := lc_msg_code_02 ;
    IF ( gd_date_from > gd_date_to ) THEN
      lv_tok_val := lc_p_name_time_fix ;
      RAISE ex_param_error ;
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- パラメータエラー
    -- ============================================================================================
    WHEN ex_param_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lv_msg_code
                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_value1   => lv_tok_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_chk_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_profile
   * Description      : プロファイル取得(F-02)
   ***********************************************************************************************/
  PROCEDURE prc_get_profile
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_profile' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_prof_name_period       CONSTANT VARCHAR2(50) := 'XXWSH_PURGE_PERIOD_601' ;
    lc_prof_name_file_name    CONSTANT VARCHAR2(50) := 'XXWSH_OB_IF_FILENAME_601F' ;
    lc_prof_name_file_path    CONSTANT VARCHAR2(50) := 'XXWSH_OB_IF_DEST_PATH_601F' ;
    lc_prof_name_type_plan    CONSTANT VARCHAR2(50) := 'XXWSH_TRAN_TYPE_PLAN' ;    -- 2008/07/22 I_S_001 Add
--
    lc_msg_code               CONSTANT VARCHAR2(50) := 'APP-XXWSH-11953' ;
    lc_tok_name               CONSTANT VARCHAR2(50) := 'PROF_NAME' ;
    lc_tok_val_period         CONSTANT VARCHAR2(100)
        := 'XXWSH: 通知済情報パージ処理対象期間_配車配送計画' ;
    lc_tok_val_name           CONSTANT VARCHAR2(100)
        := 'XXWSH:CSVファイル名_HHT入出庫配車確定情報抽出' ;
    lc_tok_val_path           CONSTANT VARCHAR2(100)
        := 'XXWSH:CSVファイル出力先ディレクトリパス_HHT入出庫配車確定情報抽出' ;
    lc_tok_val_type_plan      CONSTANT VARCHAR2(100)    -- 2008/07/22 I_S_001 Add
        := 'XXWSH:引取変更' ;                           -- 2008/07/22 I_S_001 Add
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_toc_val        VARCHAR2(100) ;
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_prof_error     EXCEPTION ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- プロファイル取得
    -- ====================================================
    -------------------------------------------------------
    -- 削除基準日数
    -------------------------------------------------------
    gn_prof_del_date := FND_PROFILE.VALUE( lc_prof_name_period ) ;
    IF ( gn_prof_del_date IS NULL ) THEN
      lv_toc_val := lc_tok_val_period ;
      RAISE ex_prof_error ;
    END IF ;
    -------------------------------------------------------
    -- 出力ファイル名
    -------------------------------------------------------
    gv_prof_put_file_name := FND_PROFILE.VALUE( lc_prof_name_file_name ) ;
    IF ( gv_prof_put_file_name IS NULL ) THEN
      lv_toc_val := lc_tok_val_name ;
      RAISE ex_prof_error ;
    END IF ;
    -------------------------------------------------------
    -- 出力ファイルディレクトリ
    -------------------------------------------------------
    gv_prof_put_file_path := FND_PROFILE.VALUE( lc_prof_name_file_path ) ;
    IF ( gv_prof_put_file_path IS NULL ) THEN
      lv_toc_val := lc_tok_val_path ;
      RAISE ex_prof_error ;
    END IF ;
--
    -- 2008/07/22 I_S_001 Add Start----------------------------------
    -------------------------------------------------------
    -- 引取変更
    -------------------------------------------------------
    gv_prof_type_plan := FND_PROFILE.VALUE( lc_prof_name_type_plan ) ;
    IF ( gv_prof_type_plan IS NULL ) THEN
      lv_toc_val := lc_tok_val_type_plan ;
      RAISE ex_prof_error ;
    END IF ;
    -- 2008/07/22 I_S_001 Add End -----------------------------------
--
  EXCEPTION
    -- ============================================================================================
    -- プロファイル取得エラー
    -- ============================================================================================
    WHEN ex_prof_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_value1   => lv_toc_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_get_profile ;
--
  /************************************************************************************************
   * Procedure Name   : prc_del_temp_data
   * Description      : データ削除(F-03)
   ***********************************************************************************************/
  PROCEDURE prc_del_temp_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_del_temp_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-12853' ;
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    ----------------------------------------
    -- HHT入出庫配車確定情報中間テーブル
    ----------------------------------------
    CURSOR cu_del_table_01
    IS
      SELECT xhsdit.request_no
      FROM xxwsh_hht_stock_deliv_info_tmp xhsdit
      FOR UPDATE NOWAIT
    ;
    ----------------------------------------
    -- HHT通知済入出庫配車確定情報
    ----------------------------------------
    CURSOR cu_del_table_02
    IS
      SELECT xhdi.hht_delivery_info_id
      FROM xxwsh_hht_delivery_info xhdi
      WHERE TRUNC( xhdi.last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ロック取得
    -- ====================================================
    <<get_lock_01>>
    FOR re_del_table_01 IN cu_del_table_01 LOOP
      EXIT ;
    END LOOP get_lock_01 ;
    <<get_lock_02>>
    FOR re_del_table_02 IN cu_del_table_02 LOOP
      EXIT ;
    END LOOP get_lock_02 ;
--
    -- ====================================================
    -- データ削除
    -- ====================================================
    DELETE FROM xxwsh_hht_stock_deliv_info_tmp ;
    DELETE FROM xxwsh_hht_delivery_info
    WHERE TRUNC( last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date ;
--
  EXCEPTION
    -- ============================================================================================
    -- ロック取得エラー
    -- ============================================================================================
    WHEN ex_lock_error THEN
      -- エラーメッセージ取得
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_del_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_main_data
   * Description      : メインデータ抽出(F-04)
   ***********************************************************************************************/
  PROCEDURE prc_get_main_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_main_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_msg_code       CONSTANT VARCHAR2(30) := 'APP-XXWSH-11856' ;
--
    -- ==================================================
    -- カーソル定義
    -- ==================================================
    CURSOR cu_main
    IS
      SELECT main.line_number                 -- 01:明細番号
            ,main.line_id                     -- 02:明細ＩＤ
            ,main.prev_notif_status           -- 03:前回通知ステータス
            ,main.data_type                   -- 04:データタイプ
            ,main.delivery_no                 -- 05:配送No
            ,main.request_no                  -- 06:依頼No
            ,main.head_sales_branch           -- 07:拠点コード
            ,main.head_sales_branch_name      -- 08:管轄拠点名称
            ,main.shipped_locat_code          -- 09:出庫倉庫コード
            ,main.shipped_locat_name          -- 10:出庫倉庫名称
            ,main.ship_to_locat_code          -- 11:入庫倉庫コード
            ,main.ship_to_locat_name          -- 12:入庫倉庫名称
            ,main.freight_carrier_code        -- 13:運送業者コード
            ,main.freight_carrier_name        -- 14:運送業者名
            ,main.deliver_to                  -- 15:配送先コード
            ,main.deliver_to_name             -- 16:配送先名
            ,main.schedule_ship_date          -- 17:発日
            ,main.schedule_arrival_date       -- 18:着日
            ,main.shipping_method_code        -- 19:配送区分
            ,main.weight                      -- 20:重量／容積
            ,main.mixed_no                    -- 21:混載元依頼No
            ,main.collected_pallet_qty        -- 22:ﾊﾟﾚｯﾄ回収枚数
            ,main.freight_charge_class        -- 23:運賃区分
            ,main.arrival_time_from           -- 24:着荷時間指定From
            ,main.arrival_time_to             -- 25:着荷時間指定To
            ,main.cust_po_number              -- 26:顧客発注番号
            ,main.description                 -- 27:摘要
            ,main.pallet_quantity_o           -- 28:ﾊﾟﾚｯﾄ使用枚数：出
            ,main.pallet_quantity_i           -- 29:ﾊﾟﾚｯﾄ使用枚数：入
            ,main.report_dept                 -- 30:報告部署
            ,main.item_code                   -- 31:品目コード
            ,main.item_id                     -- 32:品目ID
            ,main.item_name                   -- 33:品目名
            ,main.item_uom_code               -- 34:単位
            ,main.conv_unit                   -- 35:入出庫換算単位
            ,main.item_quantity               -- 36:品目数量
            ,main.num_of_cases                -- 37:ケース入数
            ,main.lot_ctl                     -- 38:ロット使用
            ,main.line_delete_flag            -- 39:明細削除フラグ
            ,main.mov_lot_dtl_id              -- 40:ロット詳細ID
-- ##### 20080619 1.5 ST不具合#193 START #####
            ,out_whse_inout_div               -- 42:内外倉庫区分：出
            ,in_whse_inout_div                -- 41:内外倉庫区分：入
-- ##### 20080619 1.5 ST不具合#193 END   #####
            ,reserve1                         -- 43:小口/引取区分（予備１）
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
            ,main.notif_date                  --   :確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
            ,sum_quantity                     -- 依頼Noごとの明細数量合計値      2008/11/07 統合指摘#143 Add
      FROM
        (
        -- ========================================================================================
        -- 出荷データＳＱＬ
        -- ========================================================================================
        SELECT xola.order_line_number             AS line_number
              ,xola.order_line_id                 AS line_id
              ,xoha.prev_notif_status             AS prev_notif_status
              --,gc_data_type_syu_ins               AS data_type  -- 2008/08/29 TE080_600指摘#27(1) Del
              -- 2008/08/29 TE080_600指摘#27(1) Add Start --------------------------
              ,CASE
                 WHEN xoha.req_status = gc_req_status_syu_5 THEN gc_data_type_syu_can
                 ELSE gc_data_type_syu_ins
               END                                AS data_type
              -- 2008/08/29 TE080_600指摘#27(1) Add End ----------------------------
              ,xoha.delivery_no                   AS delivery_no
              ,xoha.request_no                    AS request_no
              --,xp.party_number                    AS head_sales_branch      -- 2008/09/10 参照View変更 Del
              --,xp.party_name                      AS head_sales_branch_name -- 2008/09/10 参照View変更 Del
              ,xca.party_number                    AS head_sales_branch       -- 2008/09/10 参照View変更 Add
              ,xca.party_name                      AS head_sales_branch_name  -- 2008/09/10 参照View変更 Add
              ,xil.segment1                       AS shipped_locat_code
              ,SUBSTRB( xil.description, 1, 20 )  AS shipped_locat_name
              ,NULL                               AS ship_to_locat_code
              ,NULL                               AS ship_to_locat_name
              ,xc.party_number                    AS freight_carrier_code
              ,xc.party_name                      AS freight_carrier_name
              --,xps.party_site_number              AS deliver_to        -- 2008/09/10 参照View変更 Del
              --,xps.party_site_full_name           AS deliver_to_name   -- 2008/09/10 参照View変更 Del
              ,xcas.party_site_number             AS deliver_to          -- 2008/09/10 参照View変更 Add
              ,xcas.party_site_full_name          AS deliver_to_name     -- 2008/09/10 参照View変更 Add
              ,xoha.schedule_ship_date            AS schedule_ship_date
              ,xoha.schedule_arrival_date         AS schedule_arrival_date
              ,xlv.lookup_code                    AS shipping_method_code
              ,CASE
                 WHEN xoha.weight_capacity_class  = gc_wc_class_j
                 --AND  xlv.attribute6              = gc_small_method_y THEN xoha.sum_weight      -- 2008/08/12 Del
                 AND  xlv.attribute6              = gc_small_method_y THEN NVL(xoha.sum_weight,0) -- 2008/08/12 Add
                 WHEN xoha.weight_capacity_class  = gc_wc_class_j
-- M.Hokkanji Ver1.2 START
                 AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xoha.sum_weight,0)
                                                                                   + NVL(xoha.sum_pallet_weight,0)
--                 AND  xlv.attribute6             <> gc_small_method_y THEN xoha.sum_weight
--                                                                         + xoha.sum_pallet_weight
-- M.Hokkanji Ver1.2 END

                 --WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN xoha.sum_capacity      -- 2008/08/12 Del
                 WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN NVL(xoha.sum_capacity,0) -- 2008/08/12 Add
               END                                AS weight
              ,xoha.mixed_no                      AS mixed_no
              ,xoha.collected_pallet_qty          AS collected_pallet_qty
              ,CASE xoha.freight_charge_class
                 WHEN gc_freight_class_y THEN gc_freight_class_ins_y
                 ELSE                         gc_freight_class_ins_n
               END                                AS freight_charge_class
              ,NVL( xoha.arrival_time_from, gc_time_default ) AS arrival_time_from
              ,NVL( xoha.arrival_time_to  , gc_time_default ) AS arrival_time_to
              ,xoha.cust_po_number                AS cust_po_number
              ,xoha.shipping_instructions         AS description
              ,xoha.pallet_sum_quantity           AS pallet_quantity_o
              ,NULL                               AS pallet_quantity_i
              ,xoha.instruction_dept              AS report_dept
              ,xim.item_no                        AS item_code
              ,xim.item_id                        AS item_id
              ,xim.item_name                      AS item_name
              ,xim.item_um                        AS item_uom_code
              ,xim.conv_unit                      AS conv_unit
              ,xola.quantity                      AS item_quantity
              ,xim.num_of_cases                   AS num_of_cases
              ,xim.lot_ctl                        AS lot_ctl
              ,CASE xola.delete_flag
                 WHEN gc_yes_no_y THEN gc_delete_flag_y
                 ELSE                  gc_delete_flag_n
               END                                AS line_delete_flag
              ,imld.mov_lot_dtl_id                AS mov_lot_dtl_id
-- ##### 20080619 1.5 ST不具合#193 START #####
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 START #####
--              ,NULL                                 AS out_whse_inout_div   -- 内外倉庫区分：出
--              ,NULL                                 AS in_whse_inout_div    -- 内外倉庫区分：入
--   出庫元倉庫の内外倉庫区分は設定する
              ,xil.whse_inside_outside_div          AS out_whse_inout_div   -- 内外倉庫区分：出
              ,gc_whse_io_div_o                     AS in_whse_inout_div    -- 内外倉庫区分：入（デフォルト外部とする）
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 END   #####
-- ##### 20080619 1.5 ST不具合#193 END   #####
              -- 2008/07/22 I_S_001 Add Start ------------------------------------------
              ,CASE xottv.transaction_type_name
                 WHEN gv_prof_type_plan THEN gc_takeback_class       --引取
                 ELSE                  gc_small_class                --小口
               END                                AS reserve1        -- 引取/小口区分（予備１）
               -- 2008/07/22 I_S_001 Add End -------------------------------------------
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
              ,xoha.notif_date                    AS notif_date   -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
              -- 2008/11/07 統合指摘#143 Add Start --------------------------------------------------
              ,SUM(NVL(xola.quantity,0))
                OVER (PARTITION BY xoha.request_no) AS sum_quantity       -- 依頼Noごとの明細数量合計値を算出
              -- 2008/11/07 統合指摘#143 Add End ----------------------------------------------------
        FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
            --,oe_transaction_types_all   otta      -- 受注タイプ           -- 2008/07/22 I_S_001 Del
            ,xxwsh_oe_transaction_types2_v   xottv  -- 受注タイプ情報View２ -- 2008/07/22 I_S_001 Add
            ,xxcmn_item_locations_v     xil       -- OPM保管場所情報VIEW
            ,xxcmn_carriers2_v          xc        -- 運送業者情報VIEW2
            --,xxcmn_party_sites2_v       xps       -- パーティサイト情報VIEW2（配送先）-- 2008/09/10 参照View変更 Del
            ,xxcmn_cust_acct_sites2_v   xcas      -- 顧客サイト情報VIEW2                -- 2008/09/10 参照View変更 Add
            --,xxcmn_parties2_v           xp        -- パーティ情報VIEW2（拠点）        -- 2008/09/10 参照View変更 Del
            ,xxcmn_cust_accounts2_v     xca       -- 顧客情報VIEW2                      -- 2008/09/10 参照View変更 Add
            ,xxwsh_carriers_schedule    xcs       -- 配車配送計画アドオン
-- M.HOKKANJI Ver1.2 START
--            ,xxcmn_lookup_values_v      xlv       -- クイックコード情報VIEW
            ,xxcmn_lookup_values2_v     xlv       -- クイックコード情報VIEW2
-- M.HOKKANJI Ver1.2 END
            ,xxcmn_item_mst2_v          xim       -- OPM品目情報VIEW2
            ,xxinv_mov_lot_details      imld      -- 移動ロット詳細
        WHERE
        --------------------------------------------------------------------------------------------
        -- 品目
              gd_effective_date       BETWEEN xim.start_date_active
                                      AND     NVL( xim.end_date_active, gd_effective_date )
        AND   xola.shipping_item_code = xim.item_no
        -------------------------------------------------------------------------------------------
        -- 受注明細
        AND   xoha.order_header_id = xola.order_header_id
        AND   xola.delete_flag     = gc_yes_no_n   -- 削除フラグ         -- 2008/11/07 統合指摘#143 Add
        -------------------------------------------------------------------------------------------
        -- 配送配車計画
-- M.HOKKANJI Ver1.2 START
/*
        AND   xlv.lookup_type   = gc_lookup_ship_method
        AND   xcs.delivery_type = xlv.lookup_code
        AND   xoha.delivery_no  = xcs.delivery_no
*/
        AND   gd_effective_date BETWEEN xlv.start_date_active(+)
                                AND     NVL( xlv.end_date_active(+), gd_effective_date )
        AND   xlv.enabled_flag(+)  = gc_yes_no_y
        AND   xlv.lookup_type(+)   = gc_lookup_ship_method
        AND   xcs.delivery_type    = xlv.lookup_code(+)
        AND   xoha.delivery_no     = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
        -------------------------------------------------------------------------------------------
        -- 配送先
        --AND   gd_effective_date  BETWEEN xp.start_date_active                         -- 2008/09/10 参照View変更 Del
        --                         AND     NVL( xp.end_date_active, gd_effective_date ) -- 2008/09/10 参照View変更 Del
        AND   gd_effective_date  BETWEEN xca.start_date_active                          -- 2008/09/10 参照View変更 Add
                                 AND     NVL( xca.end_date_active, gd_effective_date )  -- 2008/09/10 参照View変更 Add
        -- 2008/09/10 参照View変更 Del Start -------------------------------
        --AND   xps.base_code      = xp.party_number
        --AND   gd_effective_date  BETWEEN xps.start_date_active
        --                         AND     NVL( xps.end_date_active, gd_effective_date )
        --AND   xoha.deliver_to_id = xps.party_site_id
        -- 2008/09/10 参照View変更 Del End -------------------------------
        -- 2008/09/10 参照View変更 Add Start -------------------------------
        AND   xcas.base_code      = xca.party_number
        AND   gd_effective_date  BETWEEN xcas.start_date_active
                                 AND     NVL( xcas.end_date_active, gd_effective_date )
-- ##### 2009/04/24 Ver.1.19 本番#1398対応 START #####
--        AND   xoha.deliver_to_id = xcas.party_site_id
        AND   xoha.deliver_to        = xcas.party_site_number  -- IDは付け替わる可能性があるので、コードで参照
        AND   xcas.party_site_status = gc_status_active        -- サイトステータスが有効なもの
-- ##### 2009/04/24 Ver.1.19 本番#1398対応 END   #####
        -- 2008/09/10 参照View変更 Add End -------------------------------
        -------------------------------------------------------------------------------------------
        -- 運送業者
-- M.HOKKANJI Ver1.2 START
--        AND   gd_effective_date BETWEEN xc.start_date_active
--                                AND     NVL( xc.end_date_active, gd_effective_date )
--        AND   xoha.career_id    = xc.party_id
        AND   gd_effective_date BETWEEN xc.start_date_active(+)
                                AND     NVL( xc.end_date_active(+), gd_effective_date )
        AND   xoha.career_id    = xc.party_id(+)
-- M.HOKKANJI Ver1.2 END
        -------------------------------------------------------------------------------------------
        -- 保管場所
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 START #####
--    内外区分は条件から取り除く
--        AND   xil.whse_inside_outside_div = gc_whse_io_div_i            -- 内部倉庫
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 END   #####
        AND   xoha.deliver_from_id        = xil.inventory_location_id
        -------------------------------------------------------------------------------------------
        -- 受注タイプ
        --AND   otta.attribute1    = gc_sp_class_ship            -- 出荷依頼  -- 2008/07/22 I_S_001 Del
        --AND   xoha.order_type_id = otta.transaction_type_id                 -- 2008/07/22 I_S_001 Del
        AND   xottv.shipping_shikyu_class  = gc_sp_class_ship    -- 出荷依頼  -- 2008/07/22 I_S_001 Add
        AND   xoha.order_type_id = xottv.transaction_type_id                  -- 2008/07/22 I_S_001 Add
        -------------------------------------------------------------------------------------------
        -- 受注ヘッダアドオン
        AND   NOT EXISTS
                ( SELECT 1
                  FROM xxwsh_order_lines_all      xola_w  -- 受注明細アドオン
                      ,xxcmn_item_mst2_v          xim_w   -- OPM品目情報VIEW2
                      ,xxcmn_item_categories5_v   xic_w   -- OPM品目カテゴリ割当VIEW4
                  WHERE xola_w.order_header_id = xoha.order_header_id
                  AND   xim_w.item_no          = xola_w.shipping_item_code
                  AND   gd_effective_date      BETWEEN xim_w.start_date_active
                                               AND     NVL( xim_w.end_date_active
                                                           ,gd_effective_date )
                  AND   xic_w.item_id          = xim_w.item_id
                  AND   xic_w.prod_class_code  = gc_prod_class_r
                  AND   xic_w.item_class_code <> gc_item_class_i  -- 製品以外
                )
        AND   (
                (   xoha.notif_status          = gc_notif_status_c      -- 確定通知済
                AND xoha.prev_notif_status     = gc_notif_status_n      -- 未通知
                AND xola.quantity              > 0                      -- 明細数量 > 0  -- 2008/11/07 統合指摘#143 Add
                AND xoha.req_status            = gc_req_status_syu_3    -- 締め済        -- 2008/08/29 TE080_600指摘#27(1) Add
                AND NOT EXISTS
                      ( SELECT 1
                        FROM xxwsh_hht_delivery_info  xhdi
                        WHERE xhdi.request_no = xoha.request_no )
                )
              OR
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
                (
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
                (   xoha.notif_status          = gc_notif_status_c      -- 確定通知済
                AND xoha.prev_notif_status     = gc_notif_status_r      -- 再通知要
                AND xoha.req_status           IN (gc_req_status_syu_3   -- 締め済  -- 2008/08/29 TE080_600指摘#27(1) Add
                                                 ,gc_req_status_syu_5)  -- 取消    -- 2008/08/29 TE080_600指摘#27(1) Add
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
              -- トランザクションの確定通知実施日時が、通知済入出庫配送計画情報より以前の場合は除外
                AND NOT EXISTS
                      ( SELECT 1
                        FROM xxwsh_hht_delivery_info  xhdi
                        WHERE xhdi.request_no  = xoha.request_no
                        AND   xhdi.notif_date >= xoha.notif_date )
                )
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
                )
              )
        --AND   xoha.req_status                  = gc_req_status_syu_3    -- 締め済  -- 2008/08/29 TE080_600指摘#27(1) Del
        AND   xoha.notif_date           BETWEEN gd_date_from AND gd_date_to
        AND   xoha.latest_external_flag = gc_yes_no_y             -- 最新
        AND   xoha.prod_class           = gc_prod_class_r         -- リーフ
        -- 2008/08/11 Del Start 指示部署の抽出条件SQLの不具合対応 -----------------------------------------------
        --AND   ((xoha.instruction_dept   = gr_param.dept_code_01)  -- 指示部署
        -- OR   ((gr_param.dept_code_02 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_02))
        -- OR   ((gr_param.dept_code_03 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_03))
        -- OR   ((gr_param.dept_code_04 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_04))
        -- OR   ((gr_param.dept_code_05 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_05))
        -- OR   ((gr_param.dept_code_06 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_06))
        -- OR   ((gr_param.dept_code_07 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_07))
        -- OR   ((gr_param.dept_code_08 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_08))
        -- OR   ((gr_param.dept_code_09 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_09))
        -- OR   ((gr_param.dept_code_10 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_10)))
        -- 2008/08/11 Del End 指示部署の抽出条件SQLの不具合対応 -----------------------------------------------
        -- 2008/08/11 Add Start 指示部署の抽出条件SQLの不具合対応 -----------------------------------------------
        AND xoha.instruction_dept IN (gr_param.dept_code_01,   -- 01は必須入力
                                      gr_param.dept_code_02,   -- 02～10は任意入力
                                      gr_param.dept_code_03,
                                      gr_param.dept_code_04,
                                      gr_param.dept_code_05,
                                      gr_param.dept_code_06,
                                      gr_param.dept_code_07,
                                      gr_param.dept_code_08,
                                      gr_param.dept_code_09,
                                      gr_param.dept_code_10)
        -- 2008/08/11 Add End 指示部署の抽出条件SQLの不具合対応 -----------------------------------------------
        AND   xola.order_line_id        = imld.mov_line_id (+)    -- ロット詳細ID
-- ##### 20080704 Ver.1.7 ST障害No193 2回目 START #####
        AND   gc_doc_type_ship          = imld.document_type_code (+)   -- 文書タイプ
-- ##### 20080704 Ver.1.7 ST障害No193 2回目 END   #####
        UNION ALL
        -- ========================================================================================
        -- 移動データＳＱＬ
        -- ========================================================================================
        SELECT xmril.line_number                  AS line_number
              ,xmril.mov_line_id                  AS line_id
              ,xmrih.prev_notif_status            AS prev_notif_status
              --,gc_data_type_mov_ins               AS data_type  -- 2008/08/29 TE080_600指摘#27(1) Del
              -- 2008/08/29 TE080_600指摘#27 Add Start ----------------------------
              ,CASE
                 WHEN xmrih.status = gc_mov_status_ccl THEN gc_data_type_mov_can
                 ELSE gc_data_type_mov_ins
               END                                AS data_type
              -- 2008/08/29 TE080_600指摘#27 Add End ------------------------------
              ,xmrih.delivery_no                  AS delivery_no
              ,xmrih.mov_num                      AS request_no
              ,NULL                               AS head_sales_branch
              ,NULL                               AS head_sales_branch_name
              ,xil1.segment1                      AS shipped_locat_code
              ,SUBSTRB( xil1.description, 1, 20 ) AS shipped_locat_name
              ,xil2.segment1                      AS ship_to_locat_code
              ,SUBSTRB( xil2.description, 1, 20 ) AS ship_to_locat_name
              ,xc.party_number                    AS freight_carrier_code
              ,xc.party_name                      AS freight_carrier_name
              ,NULL                               AS deliver_to
              ,NULL                               AS deliver_to_name
              ,xmrih.schedule_ship_date           AS schedule_ship_date
              ,xmrih.schedule_arrival_date        AS schedule_arrival_date
              ,xlv.lookup_code                    AS shipping_method_code
              ,CASE
-- M.Hokkanji Ver1.2 START
--                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
--                 AND  xlv.attribute6               = gc_wc_class_j THEN xmrih.sum_weight
--                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
--                 AND  xlv.attribute6              <> gc_wc_class_j THEN xmrih.sum_weight
--                                                                      + xmrih.sum_pallet_weight
                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
                 --AND  xlv.attribute6               = gc_small_method_y THEN xmrih.sum_weight      --2008/08/12 Del
                 AND  xlv.attribute6               = gc_small_method_y THEN NVL(xmrih.sum_weight,0) --2008/08/12 Add
                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
                 AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xmrih.sum_weight,0)
                                                                      + NVL(xmrih.sum_pallet_weight,0)
-- M.Hokkanji Ver1.2 END
                 --WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity       --2008/08/12 Del
                 WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN NVL(xmrih.sum_capacity,0)  --2008/08/12 Add
               END                                AS weight
              ,NULL                               AS mixed_no
              ,xmrih.collected_pallet_qty         AS collected_pallet_qty
              ,CASE xmrih.freight_charge_class
                 WHEN gc_freight_class_y THEN gc_freight_class_ins_y
                 ELSE                         gc_freight_class_ins_n
               END                                AS freight_charge_class
              ,NVL( xmrih.arrival_time_from, gc_time_default ) AS arrival_time_from
              ,NVL( xmrih.arrival_time_to  , gc_time_default ) AS arrival_time_to
              ,NULL                               AS cust_po_number
              ,xmrih.description                  AS description
              --,xmrih.out_pallet_qty               AS pallet_quantity_o  -- 2008/09/09 TE080_600指摘#30 Del
              --,xmrih.in_pallet_qty                AS pallet_quantity_i  -- 2008/09/09 TE080_600指摘#30 Del
              ,xmrih.pallet_sum_quantity          AS pallet_quantity_o    -- 2008/09/09 TE080_600指摘#30 Add
              ,xmrih.pallet_sum_quantity          AS pallet_quantity_i    -- 2008/09/09 TE080_600指摘#30 Add
              ,xmrih.instruction_post_code        AS report_dept
              ,xim.item_no                        AS item_code
              ,xim.item_id                        AS item_id
              ,xim.item_name                      AS item_name
              ,xim.item_um                        AS item_uom_code
-- 2009/01/26 v1.17 N.Yoshida UPDATE START
--              ,NULL                               AS conv_unit
              ,xim.conv_unit                      AS conv_unit
              ,xmril.instruct_qty                 AS item_quantity
--              ,NULL                               AS num_of_cases
              ,xim.num_of_cases                   AS num_of_cases
-- 2009/01/26 v1.17 N.Yoshida UPDATE END
              ,xim.lot_ctl                        AS lot_ctl
              ,CASE xmril.delete_flg
                 WHEN  gc_yes_no_y THEN gc_delete_flag_y
                 ELSE                   gc_delete_flag_n
               END                                AS line_delete_flag
              ,imld.mov_lot_dtl_id                AS mov_lot_dtl_id
-- ##### 20080619 1.5 ST不具合#193 START #####
              ,xil1.whse_inside_outside_div       AS out_whse_inout_div   -- 内外倉庫区分：出
              ,xil2.whse_inside_outside_div       AS in_whse_inout_div    -- 内外倉庫区分：入
-- ##### 20080619 1.5 ST不具合#193 END   #####
              ,NULL                               AS reserve1  -- 引取/小口区分（予備１）-- 2008/07/22 I_S_001 Add
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
              ,xmrih.notif_date                   AS notif_date   -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
              -- 2008/11/07 統合指摘#143 Add Start --------------------------------------------------
              ,SUM(NVL(xmril.instruct_qty,0))
                OVER (PARTITION BY xmrih.mov_num) AS sum_quantity       -- 移動Noごとの明細数量合計値を算出
              -- 2008/11/07 統合指摘#143 Add End ----------------------------------------------------
        FROM xxinv_mov_req_instr_headers    xmrih     -- 移動依頼指示ヘッダアドオン
            ,xxinv_mov_req_instr_lines      xmril     -- 移動依頼指示明細アドオン
            ,xxcmn_item_locations_v         xil1      -- OPM保管場所情報VIEW（配送元）
            ,xxcmn_item_locations_v         xil2      -- OPM保管場所情報VIEW（配送先）
            ,xxcmn_carriers2_v              xc        -- 運送業者情報VIEW2
            ,xxwsh_carriers_schedule        xcs       -- 配車配送計画アドオン
-- M.Hokkanji Ver1,2 START
--            ,xxcmn_lookup_values_v          xlv       -- クイックコード情報VIEW2
            ,xxcmn_lookup_values2_v         xlv       -- クイックコード情報VIEW2
-- M.Hokkanji Ver1,2 END
            ,xxcmn_item_mst2_v              xim       -- OPM品目情報VIEW2
            ,xxinv_mov_lot_details         imld       -- 移動ロット詳細
        WHERE
        -------------------------------------------------------------------------------------------
        -- 品目
              gd_effective_date   BETWEEN xim.start_date_active
                                  AND     NVL( xim.end_date_active, gd_effective_date )
        AND   xmril.item_id       = xim.item_id
        -------------------------------------------------------------------------------------------
        -- 移動依頼指示明細
        AND   xmrih.mov_hdr_id = xmril.mov_hdr_id
        AND   xmril.delete_flg = gc_yes_no_n          -- 削除フラグ        -- 2008/11/07 統合指摘#143 Add
        -------------------------------------------------------------------------------------------
        -- 配送配車計画
-- M.Hokkanji Ver1.2 START
--        AND   xlv.lookup_type   = gc_lookup_ship_method
--        AND   xcs.delivery_type = xlv.lookup_code
--        AND   xmrih.delivery_no = xcs.delivery_no
        AND   gd_effective_date BETWEEN xlv.start_date_active(+)
                              AND     NVL( xlv.end_date_active(+), gd_effective_date )
        AND   xlv.enabled_flag(+)  = gc_yes_no_y
        AND   xlv.lookup_type(+)   = gc_lookup_ship_method
        AND   xcs.delivery_type    = xlv.lookup_code(+)
        AND   xmrih.delivery_no    = xcs.delivery_no(+)
        -------------------------------------------------------------------------------------------
        -- 運送業者
--        AND   gd_effective_date BETWEEN xc.start_date_active
--                                AND     NVL( xc.end_date_active, gd_effective_date )
--        AND   xmrih.career_id   = xc.party_id
        AND   gd_effective_date BETWEEN xc.start_date_active(+)
                                AND     NVL( xc.end_date_active(+), gd_effective_date )
        AND   xmrih.career_id   = xc.party_id(+)
-- M.Hokkanji Ver1.2 END
--
        -------------------------------------------------------------------------------------------
        -- 保管場所（配送先）
        AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
        -------------------------------------------------------------------------------------------
        -- 保管場所（配送元）
        AND   xmrih.shipped_locat_id = xil1.inventory_location_id
        -------------------------------------------------------------------------------------------
-- ##### 20080619 1.5 ST不具合#193 START #####
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 START #####
/***** 内外倉庫区分の条件を取り除く
        AND
        (
          (xil2.whse_inside_outside_div = gc_whse_io_div_i)
          OR
          (xil1.whse_inside_outside_div = gc_whse_io_div_i)
        )
*****/
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 END   #####
-- ##### 20080619 1.5 ST不具合#193 END   #####
        -------------------------------------------------------------------------------------------
--
        -- 移動依頼指示ヘッダ
        AND   NOT EXISTS
                ( SELECT 1
                  FROM xxinv_mov_req_instr_lines  xmril_w   -- 受注明細アドオン
                      ,xxcmn_item_mst2_v          xim_w     -- OPM品目情報VIEW2
                      ,xxcmn_item_categories5_v   xic_w     -- OPM品目カテゴリ割当VIEW4
                  WHERE xmril_w.mov_hdr_id     = xmrih.mov_hdr_id
                  AND   xim_w.item_id          = xmril_w.item_id
                  AND   gd_effective_date      BETWEEN xim_w.start_date_active
                                               AND     NVL( xim_w.end_date_active
                                                           ,gd_effective_date )
                  AND   xic_w.item_id          = xim_w.item_id
                  AND   xic_w.prod_class_code  = gc_prod_class_r
                  AND   xic_w.item_class_code <> gc_item_class_i  -- 製品以外
                )
        AND   (
                (   xmrih.notif_status        = gc_notif_status_c       -- 確定通知済
                AND xmrih.prev_notif_status   = gc_notif_status_n       -- 未通知
                AND xmril.instruct_qty        > 0                       -- 明細数量 > 0  -- 2008/11/07 統合指摘#143 Add
                AND xmrih.status              IN( gc_mov_status_cmp     -- 依頼済        -- 2008/08/29 TE080_600指摘#27(1) Add
                                                 ,gc_mov_status_adj )   -- 調整中        -- 2008/08/29 TE080_600指摘#27(1) Add
                AND NOT EXISTS
                      ( SELECT 1
                        FROM xxwsh_hht_delivery_info  xhdi
                        WHERE xhdi.request_no = xmrih.mov_num )
                )
              OR
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
                (
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
                (   xmrih.notif_status        = gc_notif_status_c       -- 確定通知済
                AND xmrih.prev_notif_status   = gc_notif_status_r       -- 再通知要
                AND xmrih.status              IN( gc_mov_status_cmp     -- 依頼済  -- 2008/08/29 TE080_600指摘#27(1) Add
                                                 ,gc_mov_status_adj     -- 調整中  -- 2008/08/29 TE080_600指摘#27(1) Add
                                                 ,gc_mov_status_ccl )   -- 取消    -- 2008/08/29 TE080_600指摘#27(1) Add
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
              -- トランザクションの確定通知実施日時が、通知済入出庫配送計画情報より以前の場合は除外
                AND NOT EXISTS
                      ( SELECT 1
                        FROM xxwsh_hht_delivery_info  xhdi
                        WHERE xhdi.request_no  = xmrih.mov_num
                        AND   xhdi.notif_date >= xmrih.notif_date )
                )
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
                )
              )
        --AND   xmrih.status               IN( gc_mov_status_cmp      -- 依頼済  -- 2008/08/29 TE080_600指摘#27(1) Del
        --                                    ,gc_mov_status_adj )    -- 調整中  -- 2008/08/29 TE080_600指摘#27(1) Del
        AND   xmrih.notif_date            BETWEEN gd_date_from AND gd_date_to
        AND   xmrih.mov_type              = gc_mov_type_y           -- 積送あり
        AND   xmrih.item_class            = gc_prod_class_r         -- リーフ
-- M.Hokkanji Ver1.2 START
--        AND   xmrih.product_flg           = gc_yes_no_y             -- 製品識別
        AND   xmrih.product_flg           = gc_product_flg_1        -- 製品識別(製品)
-- M.Hokkanji Ver1.2 END
        -- 2008/08/11 Del Start 指示部署の抽出条件SQLの不具合対応 -------------------------------------
        --AND   ((xmrih.instruction_post_code = gr_param.dept_code_01) -- 指示部署
        -- OR   ((gr_param.dept_code_02 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_02))
        -- OR   ((gr_param.dept_code_03 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_03))
        -- OR   ((gr_param.dept_code_04 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_04))
        -- OR   ((gr_param.dept_code_05 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_05))
        -- OR   ((gr_param.dept_code_06 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_06))
        -- OR   ((gr_param.dept_code_07 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_07))
        -- OR   ((gr_param.dept_code_08 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_08))
        -- OR   ((gr_param.dept_code_09 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_09))
        -- OR   ((gr_param.dept_code_10 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_10)))
        -- 2008/08/11 Del End 指示部署の抽出条件SQLの不具合対応 -------------------------------------
        -- 2008/08/11 Add Start 指示部署の抽出条件SQLの不具合対応 -------------------------------------
        AND xmrih.instruction_post_code IN (gr_param.dept_code_01,  -- 01は必須入力
                                            gr_param.dept_code_02,  -- 02～10は任意入力
                                            gr_param.dept_code_03,
                                            gr_param.dept_code_04,
                                            gr_param.dept_code_05,
                                            gr_param.dept_code_06,
                                            gr_param.dept_code_07,
                                            gr_param.dept_code_08,
                                            gr_param.dept_code_09,
                                            gr_param.dept_code_10)
        -- 2008/08/11 Add End 指示部署の抽出条件SQLの不具合対応 -------------------------------------
        AND   xmril.mov_line_id           = imld.mov_line_id (+)    -- ロット詳細ID
-- ##### 20080704 Ver.1.7 ST障害No193 2回目 START #####
        AND   gc_doc_type_move            = imld.document_type_code (+) -- 文書タイプ
-- ##### 20080704 Ver.1.7 ST障害No193 2回目 END   #####
        ) main
    ;
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_no_data        EXCEPTION ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    OPEN cu_main ;
    FETCH cu_main BULK COLLECT INTO gt_main_data ;
    CLOSE cu_main ;
--
    IF ( gt_main_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- 対象データなし
    -- ============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--
--##### 固定例外処理部 START ######################################################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_get_main_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_head_data
   * Description      : ヘッダデータ作成
   ***********************************************************************************************/
  PROCEDURE prc_cre_head_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_hht_stock_deliv_info_tmp.data_class%TYPE
     ,iv_pallet_sum_quantity  IN  xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_cre_head_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
-- M.Hokkanji Ver 1.2 START
    lc_transfer_branch_no_h CONSTANT VARCHAR2(100) := '10' ;    -- ヘッダ
-- M.Hokkanji Ver 1.2 END
--
--
  BEGIN
    -- ==================================================
    -- 配列インデックス編集
    -- ==================================================
    gn_cre_idx := gn_cre_idx + 1 ;
--
    -- ==================================================
    -- 項目編集処理
    -- ==================================================
    gt_corporation_name(gn_cre_idx)       := gc_corporation_name ;                -- 会社名
    gt_data_class(gn_cre_idx)             := iv_data_class ;                      -- データ種別
-- M.Hokkanji Ver 1.2 START
--    gt_transfer_branch_no(gn_cre_idx)     := '10' ;                               -- 伝送用枝番
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_h ;            -- 伝送用枝番
-- M.Hokkanji Ver 1.2 END
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ;           -- 配送No
    gt_requesgt_no(gn_cre_idx)            := ir_main_data.request_no ;            -- 依頼No
    gt_reserve(gn_cre_idx)                := gc_reserve ;                         -- 予備
    gt_head_sales_branch(gn_cre_idx)      := ir_main_data.head_sales_branch ;     -- 拠点コード
    gt_head_sales_branch_name(gn_cre_idx) := ir_main_data.head_sales_branch_name ;-- 管轄拠点名称
    gt_shipped_locat_code(gn_cre_idx)     := ir_main_data.shipped_locat_code ;    -- 出庫倉庫コード
    gt_shipped_locat_name(gn_cre_idx)     := ir_main_data.shipped_locat_name ;    -- 出庫倉庫名称
    gt_ship_to_locat_code(gn_cre_idx)     := ir_main_data.ship_to_locat_code ;    -- 入庫倉庫コード
    gt_ship_to_locat_name(gn_cre_idx)     := ir_main_data.ship_to_locat_name ;    -- 入庫倉庫名称
    gt_freight_carrier_code(gn_cre_idx)   := ir_main_data.freight_carrier_code ;  -- 運送業者コード
    gt_freight_carrier_name(gn_cre_idx)   := ir_main_data.freight_carrier_name ;  -- 運送業者名
    gt_deliver_to(gn_cre_idx)             := ir_main_data.deliver_to ;            -- 配送先コード
    gt_deliver_to_name(gn_cre_idx)        := ir_main_data.deliver_to_name ;       -- 配送先名
    gt_schedule_ship_date(gn_cre_idx)     := ir_main_data.schedule_ship_date ;    -- 発日
    gt_schedule_arrival_date(gn_cre_idx)  := ir_main_data.schedule_arrival_date ; -- 着日
    gt_shipping_method_code(gn_cre_idx)   := ir_main_data.shipping_method_code ;  -- 配送区分
    gt_weight(gn_cre_idx)                 := ir_main_data.weight ;                -- 重量/容積
    gt_mixed_no(gn_cre_idx)               := ir_main_data.mixed_no ;              -- 混載元依頼№
    gt_collected_pallet_qty(gn_cre_idx)   := ir_main_data.collected_pallet_qty ;  -- ﾊﾟﾚｯﾄ回収枚数
    gt_arrival_time_from(gn_cre_idx)      := ir_main_data.arrival_time_from ;     -- 着荷時間FROM
    gt_arrival_time_to(gn_cre_idx)        := ir_main_data.arrival_time_to ;       -- 着荷時間TO
    gt_cust_po_number(gn_cre_idx)         := ir_main_data.cust_po_number ;        -- 顧客発注番号
    gt_description(gn_cre_idx)            := ir_main_data.description ;           -- 摘要
    gt_status(gn_cre_idx)                 := '02' ;                               -- ステータス
    gt_freight_charge_class(gn_cre_idx)   := ir_main_data.freight_charge_class ;  -- 運賃区分
    gt_pallet_sum_quantity(gn_cre_idx)    := iv_pallet_sum_quantity ;             -- ﾊﾟﾚｯﾄ使用枚数
    --gt_reserve1(gn_cre_idx)               := NULL ;                 -- 予備１                 -- 2008/07/22 I_S_001 Del
    gt_reserve1(gn_cre_idx)               := ir_main_data.reserve1;   -- 引取/小口区分（予備１）-- 2008/07/22 I_S_001 Add
    gt_reserve2(gn_cre_idx)               := NULL ;                               -- 予備２
    gt_reserve3(gn_cre_idx)               := NULL ;                               -- 予備３
    gt_reserve4(gn_cre_idx)               := NULL ;                               -- 予備４
    gt_report_dept(gn_cre_idx)            := ir_main_data.report_dept ;           -- 報告部署
    gt_item_code(gn_cre_idx)              := NULL ;                               -- 品目コード
    gt_item_name(gn_cre_idx)              := NULL ;                               -- 品目名
    gt_item_uom_code(gn_cre_idx)          := NULL ;                               -- 品目単位
    gt_item_quantity(gn_cre_idx)          := NULL ;                               -- 品目数量
    gt_lot_no(gn_cre_idx)                 := NULL ;                               -- ロット番号
    gt_lot_date(gn_cre_idx)               := NULL ;                               -- 製造日
    gt_lot_sign(gn_cre_idx)               := NULL ;                               -- 固有記号
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                               -- 賞味期限
    gt_lot_quantity(gn_cre_idx)           := NULL ;                               -- ロット数量
-- M.Hokkanji Ver1.2 START
--    gt_new_modify_del_class(gn_cre_idx)   := '0' ;                                -- データ区分
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;                  -- データ区分
-- M.Hokkanji Ver1.2 END
    gt_update_date(gn_cre_idx)            := SYSDATE ;                            -- 更新日時
    gt_line_number(gn_cre_idx)            := NULL ;                               -- 明細番号
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;             -- データタイプ
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
    gt_notif_date(gn_cre_idx)             := ir_main_data.notif_date ;            -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
--
  EXCEPTION
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_cre_head_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_dtl_data
   * Description      : 明細データ作成
   ***********************************************************************************************/
  PROCEDURE prc_cre_dtl_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_stock_delivery_info_tmp.data_class%TYPE
     ,iv_item_uom_code        IN  xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE
     ,iv_item_quantity        IN  xxwsh_stock_delivery_info_tmp.item_quantity%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_cre_dtl_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_doc_type             xxinv_mov_lot_details.document_type_code%TYPE ;
-- M.Hokkanji Ver1.2 START
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- 明細
-- M.Hokkanji Ver1.2 END
--
  BEGIN
    -- ==================================================
    -- 配列インデックス編集
    -- ==================================================
    gn_cre_idx := gn_cre_idx + 1 ;
--
    -- ==================================================
    -- 項目編集処理
    -- ==================================================
    gt_corporation_name(gn_cre_idx)       := gc_corporation_name ;      -- 会社名
    gt_data_class(gn_cre_idx)             := iv_data_class ;            -- データ種別
-- M.Hokkanji Ver1.2 START
--    gt_transfer_branch_no(gn_cre_idx)     := '20' ;                     -- 伝送用枝番
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_d ;  -- 伝送用枝番
-- M.Hokkanji Ver1.2 END
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ; -- 配送No
    gt_requesgt_no(gn_cre_idx)            := ir_main_data.request_no ;  -- 依頼No
-- M.Hokkanji Ver1.4 START
--    gt_reserve(gn_cre_idx)                := gc_reserve ;               -- 予備
    gt_reserve(gn_cre_idx)                := NULL ;                     -- 予備
-- M.Hokkanji Ver1.4 END
    gt_head_sales_branch(gn_cre_idx)      := NULL ;                     -- 拠点コード
    gt_head_sales_branch_name(gn_cre_idx) := NULL ;                     -- 管轄拠点名称
    gt_shipped_locat_code(gn_cre_idx)     := NULL ;                     -- 出庫倉庫コード
    gt_shipped_locat_name(gn_cre_idx)     := NULL ;                     -- 出庫倉庫名称
    gt_ship_to_locat_code(gn_cre_idx)     := NULL ;                     -- 入庫倉庫コード
    gt_ship_to_locat_name(gn_cre_idx)     := NULL ;                     -- 入庫倉庫名称
    gt_freight_carrier_code(gn_cre_idx)   := NULL ;                     -- 運送業者コード
    gt_freight_carrier_name(gn_cre_idx)   := NULL ;                     -- 運送業者名
    gt_deliver_to(gn_cre_idx)             := NULL ;                     -- 配送先コード
    gt_deliver_to_name(gn_cre_idx)        := NULL ;                     -- 配送先名
    gt_schedule_ship_date(gn_cre_idx)     := NULL ;                     -- 発日
    gt_schedule_arrival_date(gn_cre_idx)  := NULL ;                     -- 着日
    gt_shipping_method_code(gn_cre_idx)   := NULL ;                     -- 配送区分
    gt_weight(gn_cre_idx)                 := NULL ;                     -- 重量/容積
    gt_mixed_no(gn_cre_idx)               := NULL ;                     -- 混載元依頼№
    gt_collected_pallet_qty(gn_cre_idx)   := NULL ;                     -- ﾊﾟﾚｯﾄ回収枚数
    gt_arrival_time_from(gn_cre_idx)      := NULL ;                     -- 着荷時間指定(FROM)
    gt_arrival_time_to(gn_cre_idx)        := NULL ;                     -- 着荷時間指定(TO)
    gt_cust_po_number(gn_cre_idx)         := NULL ;                     -- 顧客発注番号
    gt_description(gn_cre_idx)            := NULL ;                     -- 摘要
    gt_status(gn_cre_idx)                 := NULL ;                     -- ステータス
    gt_freight_charge_class(gn_cre_idx)   := NULL ;                     -- 運賃区分
    gt_pallet_sum_quantity(gn_cre_idx)    := NULL ;                     -- ﾊﾟﾚｯﾄ使用枚数
    gt_reserve1(gn_cre_idx)               := NULL ;                     -- 予備１
    gt_reserve2(gn_cre_idx)               := NULL ;                     -- 予備２
    gt_reserve3(gn_cre_idx)               := NULL ;                     -- 予備３
    gt_reserve4(gn_cre_idx)               := NULL ;                     -- 予備４
    gt_report_dept(gn_cre_idx)            := NULL ;                     -- 報告部署
    gt_item_code(gn_cre_idx)              := ir_main_data.item_code ;   -- 品目コード
    gt_item_name(gn_cre_idx)              := ir_main_data.item_name ;   -- 品目名
    gt_item_uom_code(gn_cre_idx)          := iv_item_uom_code ;         -- 品目単位
    gt_item_quantity(gn_cre_idx)          := iv_item_quantity ;         -- 品目数量
    gt_lot_no(gn_cre_idx)                 := NULL ;                     -- ロット番号
    gt_lot_date(gn_cre_idx)               := NULL ;                     -- 製造日
    gt_lot_sign(gn_cre_idx)               := NULL ;                     -- 固有記号
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                     -- 賞味期限
    gt_lot_quantity(gn_cre_idx)           := NULL ;                     -- ロット数量
-- M.Hokkanji Ver1.2 START
--    gt_new_modify_del_class(gn_cre_idx)   := '0' ;                      -- データ区分
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;        -- データ区分
-- M.Hokkanji Ver1.2 END
    gt_update_date(gn_cre_idx)            := SYSDATE ;                  -- 更新日時
    gt_line_number(gn_cre_idx)            := ir_main_data.line_number ; -- 明細番号
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;   -- データタイプ
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
    gt_notif_date(gn_cre_idx)             := ir_main_data.notif_date ;            -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
--
    -------------------------------------------------------
    -- ロット管理品の場合
    -------------------------------------------------------
    IF ( ir_main_data.lot_ctl = gc_lot_ctl_y ) THEN
      -- 出荷データの場合
      IF ( iv_data_class = gc_data_class_syu_s ) THEN
        lv_doc_type := gc_doc_type_ship ;
--
      -- 移動データの場合
      ELSE
        lv_doc_type := gc_doc_type_move ;
--
      END IF ;
--
      -- ロット情報抽出
      BEGIN
        SELECT ilm.lot_no
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute3 )
              ,ilm.attribute2
              ,xmld.actual_quantity
        INTO   gt_lot_no(gn_cre_idx)           -- ロット番号
              ,gt_lot_date(gn_cre_idx)         -- 製造日
              ,gt_best_bfr_date(gn_cre_idx)    -- 賞味期限
              ,gt_lot_sign(gn_cre_idx)         -- 固有記号
              ,gt_lot_quantity(gn_cre_idx)     -- ロット数量
        FROM xxinv_mov_lot_details    xmld    -- 移動ロット詳細アドオン
            ,ic_lots_mst              ilm     -- ＯＰＭロットマスタ
        WHERE ilm.inactive_ind  = gc_inactive_ind_y   -- 0：有効
        AND   ilm.delete_mark   = gc_delete_mark_y    -- 0：未削除
        AND   xmld.lot_id       = ilm.lot_id
        AND   xmld.document_type_code = lv_doc_type
        AND   xmld.record_type_code   = gc_rec_type_inst    -- 10：指示
        AND   xmld.item_id            = ir_main_data.item_id
        AND   xmld.mov_line_id        = ir_main_data.line_id
        AND   xmld.mov_lot_dtl_id     = ir_main_data.mov_lot_dtl_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_lot_no(gn_cre_idx)        := NULL ;     -- ロット番号
          gt_lot_date(gn_cre_idx)      := NULL ;     -- 製造日
          gt_best_bfr_date(gn_cre_idx) := NULL ;     -- 賞味期限
          gt_lot_sign(gn_cre_idx)      := NULL ;     -- 固有記号
          gt_lot_quantity(gn_cre_idx)  := NULL ;     -- ロット数量
      END ;
--
-- ##### 20080627 Ver.1.6 ロット数量換算対応 START #####
      -------------------------------------------------------
      -- ロット数量換算
      -------------------------------------------------------
    -- 出荷の場合
-- 2009/01/26 v1.17 N.Yoshida UPDATE START
--    IF ( ir_main_data.data_type = gc_data_type_syu_ins ) THEN
--
        -- 入出庫換算単位≠NULLの場合
        IF (ir_main_data.conv_unit IS NOT NULL) THEN
          -- ロット数量 ÷ ケース入り数
          gt_lot_quantity(gn_cre_idx) := gt_lot_quantity(gn_cre_idx)
                                           / ir_main_data.num_of_cases ;
--2008/08/08 Mod ↓
--          gt_lot_quantity(gn_cre_idx) := TRUNC( gt_lot_quantity(gn_cre_idx), 3 ) ;
--2008/08/08 Mod ↑
        END IF ;
--    END IF ;
-- 2009/01/26 v1.17 N.Yoshida UPDATE END
-- ##### 20080627 Ver.1.6 ロット数量換算対応 END   #####
--
    END IF ;
--
  EXCEPTION
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_cre_dtl_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_ins_data
   * Description      : 通知済情報作成処理(F-05)
   ***********************************************************************************************/
  PROCEDURE prc_create_ins_data
    (
      in_idx          IN  NUMBER            -- 対象データ配列インデックス
     ,iv_break_flg    IN  VARCHAR2          -- 依頼Ｎｏブレイクフラグ
     ,ov_errbuf       OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode      OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg       OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_ins_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_msg_code_case        CONSTANT VARCHAR2(50) := 'APP-XXWSH-11904' ;
    lc_tok_name_case        CONSTANT VARCHAR2(50) := 'ITEM_ID' ;
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_pallet_sum_quantity  xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE ;
    lv_item_uom_code        xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE ;
    lv_item_quantity        xxwsh_stock_delivery_info_tmp.item_quantity%TYPE ;
--
    lv_tok_val              VARCHAR2(50) ;
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_case_quant_error     EXCEPTION ;   -- ケース入り数エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ============================================================================================
    -- エラーハンドリング
    -- ============================================================================================
    -------------------------------------------------------
    -- ケース入り数チェック
    -------------------------------------------------------
    -- 出荷の場合で、入出庫換算単位の設定がある場合
-- 2009/01/26 v1.17 N.Yoshida UPDATE START
--    IF (   ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins )
--       AND ( gt_main_data(in_idx).conv_unit IS NOT NULL            ) ) THEN
    IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- 2009/01/26 v1.17 N.Yoshida UPDATE END
      -- ケース入り数の値がない場合
      IF ( NVL( gt_main_data(in_idx).num_of_cases, 0 ) = 0 ) THEN
        lv_tok_val := gt_main_data(in_idx).item_code ;
        RAISE ex_case_quant_error ;
      END IF ;
    END IF ;
--
    -- ============================================================================================
    -- データタイプ：出荷
    -- ============================================================================================
    IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
      -------------------------------------------------------
      -- 可変項目編集
      -------------------------------------------------------
      -- パレット使用枚数
      lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_quantity_o ;
--
      -- 品目単位
      lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                              ,gt_main_data(in_idx).item_uom_code ) ;
      -- 品目数量
      IF gt_main_data(in_idx).conv_unit IS NULL THEN
        lv_item_quantity := gt_main_data(in_idx).item_quantity ;
      ELSE
        lv_item_quantity := gt_main_data(in_idx).item_quantity
                          / gt_main_data(in_idx).num_of_cases ;
--2008/08/08 Mod ↓
--        lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;
--2008/08/08 Mod ↑
      END IF ;
--
      -------------------------------------------------------
      -- ヘッダデータの作成
      -------------------------------------------------------
      IF ( iv_break_flg = gc_yes_no_y )
        AND ( gt_main_data(in_idx).sum_quantity > 0 )           -- 2008/11/07 統合指摘#143 Add
      THEN
        prc_cre_head_data
          (
            ir_main_data            => gt_main_data(in_idx)     -- 対象データ
           ,iv_data_class           => gc_data_class_syu_s      -- データ種別
           ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
           ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode              => lv_retcode               -- リターン・コード
           ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_api_expt;
        END IF ;
      END IF ;
      -------------------------------------------------------
      -- 明細データの作成
      -------------------------------------------------------
      -- 明細の削除フラグが「Y」の場合、明細データを作成しない。            -- 2008/08/29 TE080_600指摘#27(3) Add
      IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n )       -- 2008/08/29 TE080_600指摘#27(3) Add
        AND ( gt_main_data(in_idx).item_quantity  > 0 )                     -- 2008/11/07 統合指摘#143 Add
      THEN
--
       prc_cre_dtl_data
          (
            ir_main_data            => gt_main_data(in_idx)     -- 対象データ
           ,iv_data_class           => gc_data_class_syu_s      -- データ種別
           ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
           ,iv_item_quantity        => lv_item_quantity         -- 品目数量
           ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode              => lv_retcode               -- リターン・コード
           ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_api_expt;
        END IF ;
      END IF ;        -- 2008/08/29 TE080_600指摘#27(3) Add
--
    -- ============================================================================================
    -- データタイプ：移動
    -- ============================================================================================
    ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_mov_ins ) THEN
      -------------------------------------------------------
      -- 可変項目編集
      -------------------------------------------------------
-- 2009/01/26 v1.17 N.Yoshida UPDATE START
--      lv_item_uom_code := gt_main_data(in_idx).item_uom_code  ;   -- 品目単位
--      lv_item_quantity := gt_main_data(in_idx).item_quantity  ;   -- 品目数量
--
      -- 品目単位
      lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                              ,gt_main_data(in_idx).item_uom_code ) ;
      -- 品目数量
      IF gt_main_data(in_idx).conv_unit IS NULL THEN
        lv_item_quantity := gt_main_data(in_idx).item_quantity ;
      ELSE
        lv_item_quantity := gt_main_data(in_idx).item_quantity
                          / gt_main_data(in_idx).num_of_cases ;
      END IF ;
-- 2009/01/26 v1.17 N.Yoshida UPDATE END
--
      -------------------------------------------------------
      -- ヘッダデータの作成
      -------------------------------------------------------
      IF ( iv_break_flg = gc_yes_no_y )
        AND ( gt_main_data(in_idx).sum_quantity > 0 )           -- 2008/11/07 統合指摘#143 Add
      THEN
--
-- ##### 20080619 1.5 ST不具合#193 START #####
        -- 内外倉庫区分が内部倉庫の場合
        IF (gt_main_data(in_idx).out_whse_inout_div = gc_whse_io_div_i) THEN
-- ##### 20080619 1.5 ST不具合#193 END   #####
          -------------------------------------------------------
          -- 移動出庫の作成
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_quantity_o ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_s      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080619 1.5 ST不具合#193 START #####
        END IF;
-- ##### 20080619 1.5 ST不具合#193 END   #####
--
-- ##### 20080619 1.5 ST不具合#193 START #####
        -- 内外倉庫区分が内部倉庫の場合
        IF (gt_main_data(in_idx).in_whse_inout_div = gc_whse_io_div_i) THEN
-- ##### 20080619 1.5 ST不具合#193 END   #####
          -------------------------------------------------------
          -- 移動入庫の作成
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_quantity_i ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_n      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080619 1.5 ST不具合#193 START #####
        END IF;
-- ##### 20080619 1.5 ST不具合#193 END   #####
--
      END IF ;
--
      -- 明細の削除フラグが「Y」の場合、明細データを作成しない。            -- 2008/08/29 TE080_600指摘#27(3) Add
      IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n )       -- 2008/08/29 TE080_600指摘#27(3) Add
        AND ( gt_main_data(in_idx).item_quantity  > 0 )                     -- 2008/11/07 統合指摘#143 Add
      THEN
--
        -- ##### 20080619 1.5 ST不具合#193 START #####
        -- 内外倉庫区分が内部倉庫の場合
        IF (gt_main_data(in_idx).out_whse_inout_div = gc_whse_io_div_i) THEN
        -- ##### 20080619 1.5 ST不具合#193 END   #####
          -------------------------------------------------------
          -- 明細データの作成（移動出庫）
          -------------------------------------------------------
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_s      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        -- ##### 20080619 1.5 ST不具合#193 START #####
        END IF;
        -- ##### 20080619 1.5 ST不具合#193 END   #####
--
        -- ##### 20080619 1.5 ST不具合#193 START #####
        -- 内外倉庫区分が内部倉庫の場合
        IF (gt_main_data(in_idx).in_whse_inout_div = gc_whse_io_div_i) THEN
        -- ##### 20080619 1.5 ST不具合#193 END   #####
          -------------------------------------------------------
          -- 明細データの作成（移動入庫）
          -------------------------------------------------------
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_n      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        -- ##### 20080619 1.5 ST不具合#193 START #####
        END IF;
        -- ##### 20080619 1.5 ST不具合#193 END   #####
--
      END IF ;  -- 2008/08/29 TE080_600指摘#27(3) Add
--
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- ケース入り数エラー
    -- ============================================================================================
    WHEN ex_case_quant_error THEN
      -- エラーメッセージ取得
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code_case
                       ,iv_token_name1    => lc_tok_name_case
                       ,iv_token_value1   => lv_tok_val
                      ) ;
      ov_errmsg    := lv_errmsg ;
      ov_errbuf    := lv_errmsg ;
      ov_retcode   := gv_status_error ;
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_create_ins_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_can_data
   * Description      : 変更前情報取消データ作成処理(F-06)
   ***********************************************************************************************/
  PROCEDURE prc_create_can_data
    (
      iv_request_no           IN  xxwsh_stock_delivery_info_tmp.request_no%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_can_data' ; -- プログラム名
--
    lc_transfer_branch_no_h     CONSTANT VARCHAR2(100) := '10' ;    -- ヘッダ -- 2008/08/29 取消ヘッダに品目数量・ロット数量に0がセットされている Add
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    CURSOR cu_can_data
      ( p_request_no  xxwsh_hht_delivery_info.request_no%TYPE )
    IS
      SELECT xhdi.corporation_name
            ,xhdi.data_class
            ,xhdi.transfer_branch_no
            ,xhdi.delivery_no
            ,xhdi.request_no
            ,xhdi.reserve
            ,xhdi.head_sales_branch
            ,xhdi.head_sales_branch_name
            ,xhdi.shipped_locat_code
            ,xhdi.shipped_locat_name
            ,xhdi.ship_to_locat_code
            ,xhdi.ship_to_locat_name
            ,xhdi.freight_carrier_code
            ,xhdi.freight_carrier_name
            ,xhdi.deliver_to
            ,xhdi.deliver_to_name
            ,xhdi.schedule_ship_date
            ,xhdi.schedule_arrival_date
            ,xhdi.shipping_method_code
            ,xhdi.weight
            ,xhdi.mixed_no
            ,xhdi.collected_pallet_qty
            ,xhdi.arrival_time_from
            ,xhdi.arrival_time_to
            ,xhdi.cust_po_number
            ,xhdi.description
            ,xhdi.status
            ,xhdi.freight_charge_class
            ,xhdi.pallet_sum_quantity
            ,xhdi.reserve1
            ,xhdi.reserve2
            ,xhdi.reserve3
            ,xhdi.reserve4
            ,xhdi.report_dept
            ,xhdi.item_code
            ,xhdi.item_name
            ,xhdi.item_uom_code
            ,xhdi.item_quantity
            ,xhdi.lot_no
            ,xhdi.lot_date
            ,xhdi.best_bfr_date
            ,xhdi.lot_sign
            ,xhdi.lot_quantity
            ,xhdi.new_modify_del_class
            ,xhdi.update_date
            ,xhdi.line_number
            ,xhdi.data_type
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
            ,xhdi.notif_date
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
      FROM xxwsh_hht_delivery_info    xhdi
      WHERE xhdi.request_no = p_request_no
      ORDER BY xhdi.request_no                -- 依頼No
              ,xhdi.transfer_branch_no        -- 伝送用枝番
              ,xhdi.line_number               -- 明細番号
    ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 取消データ作成
    -- ====================================================
    <<can_data_loop>>
    FOR re_can_data IN cu_can_data
      ( p_request_no            => iv_request_no ) LOOP
--
      gn_cre_idx := gn_cre_idx + 1 ;
--
      gt_corporation_name(gn_cre_idx)       := re_can_data.corporation_name ;
      gt_data_class(gn_cre_idx)             := re_can_data.data_class ;
      gt_transfer_branch_no(gn_cre_idx)     := re_can_data.transfer_branch_no ;
      gt_delivery_no(gn_cre_idx)            := re_can_data.delivery_no ;
      gt_requesgt_no(gn_cre_idx)            := re_can_data.request_no ;
      gt_reserve(gn_cre_idx)                := re_can_data.reserve ;
      gt_head_sales_branch(gn_cre_idx)      := re_can_data.head_sales_branch ;
      gt_head_sales_branch_name(gn_cre_idx) := re_can_data.head_sales_branch_name ;
      gt_shipped_locat_code(gn_cre_idx)     := re_can_data.shipped_locat_code ;
      gt_shipped_locat_name(gn_cre_idx)     := re_can_data.shipped_locat_name ;
      gt_ship_to_locat_code(gn_cre_idx)     := re_can_data.ship_to_locat_code ;
      gt_ship_to_locat_name(gn_cre_idx)     := re_can_data.ship_to_locat_name ;
      gt_freight_carrier_code(gn_cre_idx)   := re_can_data.freight_carrier_code ;
      gt_freight_carrier_name(gn_cre_idx)   := re_can_data.freight_carrier_name ;
      gt_deliver_to(gn_cre_idx)             := re_can_data.deliver_to ;
      gt_deliver_to_name(gn_cre_idx)        := re_can_data.deliver_to_name ;
      gt_schedule_ship_date(gn_cre_idx)     := re_can_data.schedule_ship_date ;
      gt_schedule_arrival_date(gn_cre_idx)  := re_can_data.schedule_arrival_date ;
      gt_shipping_method_code(gn_cre_idx)   := re_can_data.shipping_method_code ;
      gt_weight(gn_cre_idx)                 := re_can_data.weight ;
      gt_mixed_no(gn_cre_idx)               := re_can_data.mixed_no ;
      gt_collected_pallet_qty(gn_cre_idx)   := re_can_data.collected_pallet_qty ;
      gt_arrival_time_from(gn_cre_idx)      := re_can_data.arrival_time_from ;
      gt_arrival_time_to(gn_cre_idx)        := re_can_data.arrival_time_to ;
      gt_cust_po_number(gn_cre_idx)         := re_can_data.cust_po_number ;
      gt_description(gn_cre_idx)            := re_can_data.description ;
      gt_status(gn_cre_idx)                 := re_can_data.status ;
      gt_freight_charge_class(gn_cre_idx)   := re_can_data.freight_charge_class ;
      gt_pallet_sum_quantity(gn_cre_idx)    := re_can_data.pallet_sum_quantity ;
      gt_reserve1(gn_cre_idx)               := re_can_data.reserve1 ;
      gt_reserve2(gn_cre_idx)               := re_can_data.reserve2 ;
      gt_reserve3(gn_cre_idx)               := re_can_data.reserve3 ;
      gt_reserve4(gn_cre_idx)               := re_can_data.reserve4 ;
      gt_report_dept(gn_cre_idx)            := re_can_data.report_dept ;
      gt_item_code(gn_cre_idx)              := re_can_data.item_code ;
      gt_item_name(gn_cre_idx)              := re_can_data.item_name ;
      gt_item_uom_code(gn_cre_idx)          := re_can_data.item_uom_code ;
--
      --gt_item_quantity(gn_cre_idx)          := 0 ; -- 2008/08/29 取消ヘッダに品目数量・ロット数量に0がセットされている Del
      -- 2008/08/29 取消ヘッダに品目数量・ロット数量に0がセットされている Add Start -----------------
      IF (re_can_data.transfer_branch_no =lc_transfer_branch_no_h) THEN  -- 伝送用枝番が「ヘッダ」の場合
        gt_item_quantity(gn_cre_idx)          := NULL ;
      ELSE
        gt_item_quantity(gn_cre_idx)          := 0 ;
      END IF;
      -- 2008/08/29 取消ヘッダに品目数量・ロット数量に0がセットされている Add End -------------------
--
      gt_lot_no(gn_cre_idx)                 := re_can_data.lot_no ;
      gt_lot_date(gn_cre_idx)               := re_can_data.lot_date ;
      gt_lot_sign(gn_cre_idx)               := re_can_data.lot_sign ;
      gt_best_bfr_date(gn_cre_idx)          := re_can_data.best_bfr_date ;
--
      --gt_lot_quantity(gn_cre_idx)           := 0 ;  -- 2008/08/29 取消ヘッダに品目数量・ロット数量に0がセットされている Del
      -- 2008/08/29 取消ヘッダに品目数量・ロット数量に0がセットされている Add Start -----------------
      IF (re_can_data.transfer_branch_no =lc_transfer_branch_no_h) THEN  -- 伝送用枝番が「ヘッダ」の場合
        gt_lot_quantity(gn_cre_idx)           := NULL ;
      ELSE
        gt_lot_quantity(gn_cre_idx)           := 0 ;
      END IF;
      -- 2008/08/29 取消ヘッダに品目数量・ロット数量に0がセットされている Add End -------------------
--
-- M.Hokkanji Ver1.2 START
--      gt_new_modify_del_class(gn_cre_idx)   := '2' ;
      gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_del ;
-- M.Hokkanji Ver1.2 END
      gt_update_date(gn_cre_idx)            := SYSDATE ;
      gt_line_number(gn_cre_idx)            := re_can_data.line_number ;
      gt_data_type(gn_cre_idx)              := re_can_data.data_type ;
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
      gt_notif_date(gn_cre_idx)             := re_can_data.notif_date ; -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
--
    END LOOP can_data_loop ;
--
  EXCEPTION
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_create_can_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_data
   * Description      : 一括登録処理(F-07)
   ***********************************************************************************************/
  PROCEDURE prc_ins_temp_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_temp_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    ln_cnt    NUMBER := 0 ;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 一括登録処理
    -- ====================================================
    FORALL ln_cnt IN 1..gn_cre_idx
      INSERT INTO xxwsh_hht_stock_deliv_info_tmp
        (
          corporation_name                        -- 会社名
         ,data_class                              -- データ種別
         ,transfer_branch_no                      -- 伝送用枝番
         ,delivery_no                             -- 配送No
         ,request_no                              -- 依頼No
         ,reserve                                 -- 予備
         ,head_sales_branch                       -- 拠点コード
         ,head_sales_branch_name                  -- 管轄拠点名称
         ,shipped_locat_code                      -- 出庫倉庫コード
         ,shipped_locat_name                      -- 出庫倉庫名称
         ,ship_to_locat_code                      -- 入庫倉庫コード
         ,ship_to_locat_name                      -- 入庫倉庫名称
         ,freight_carrier_code                    -- 運送業者コード
         ,freight_carrier_name                    -- 運送業者名
         ,deliver_to                              -- 配送先コード
         ,deliver_to_name                         -- 配送先名
         ,schedule_ship_date                      -- 発日
         ,schedule_arrival_date                   -- 着日
         ,shipping_method_code                    -- 配送区分
         ,weight                                  -- 重量/容積
         ,mixed_no                                -- 混載元依頼№
         ,collected_pallet_qty                    -- パレット回収枚数
         ,arrival_time_from                       -- 着荷時間指定(FROM)
         ,arrival_time_to                         -- 着荷時間指定(TO)
         ,cust_po_number                          -- 顧客発注番号
         ,description                             -- 摘要
         ,status                                  -- ステータス
         ,freight_charge_class                    -- 運賃区分
         ,pallet_sum_quantity                     -- パレット使用枚数
         ,reserve1                                -- 予備１
         ,reserve2                                -- 予備２
         ,reserve3                                -- 予備３
         ,reserve4                                -- 予備４
         ,report_dept                             -- 報告部署
         ,item_code                               -- 品目コード
         ,item_name                               -- 品目名
         ,item_uom_code                           -- 品目単位
         ,item_quantity                           -- 品目数量
         ,lot_no                                  -- ロット番号
         ,lot_date                                -- 製造日
         ,lot_sign                                -- 固有記号
         ,best_bfr_date                           -- 賞味期限
         ,lot_quantity                            -- ロット数量
         ,new_modify_del_class                    -- データ区分
         ,update_date                             -- 更新日時
         ,line_number                             -- 明細番号
         ,data_type                               -- データタイプ
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
         ,notif_date                              -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
        )
      VALUES
        (
          gt_corporation_name(ln_cnt)             -- 会社名
         ,gt_data_class(ln_cnt)                   -- データ種別
         ,gt_transfer_branch_no(ln_cnt)           -- 伝送用枝番
         ,gt_delivery_no(ln_cnt)                  -- 配送No
         ,gt_requesgt_no(ln_cnt)                  -- 依頼No
         ,gt_reserve(ln_cnt)                      -- 予備
         ,gt_head_sales_branch(ln_cnt)            -- 拠点コード
         ,gt_head_sales_branch_name(ln_cnt)       -- 管轄拠点名称
         ,gt_shipped_locat_code(ln_cnt)           -- 出庫倉庫コード
         ,gt_shipped_locat_name(ln_cnt)           -- 出庫倉庫名称
         ,gt_ship_to_locat_code(ln_cnt)           -- 入庫倉庫コード
         ,gt_ship_to_locat_name(ln_cnt)           -- 入庫倉庫名称
         ,gt_freight_carrier_code(ln_cnt)         -- 運送業者コード
         ,gt_freight_carrier_name(ln_cnt)         -- 運送業者名
         ,gt_deliver_to(ln_cnt)                   -- 配送先コード
         ,gt_deliver_to_name(ln_cnt)              -- 配送先名
         ,gt_schedule_ship_date(ln_cnt)           -- 発日
         ,gt_schedule_arrival_date(ln_cnt)        -- 着日
         ,gt_shipping_method_code(ln_cnt)         -- 配送区分
         ,gt_weight(ln_cnt)                       -- 重量/容積
         ,gt_mixed_no(ln_cnt)                     -- 混載元依頼№
         ,gt_collected_pallet_qty(ln_cnt)         -- パレット回収枚数
         ,gt_arrival_time_from(ln_cnt)            -- 着荷時間指定(FROM)
         ,gt_arrival_time_to(ln_cnt)              -- 着荷時間指定(TO)
         ,gt_cust_po_number(ln_cnt)               -- 顧客発注番号
         ,gt_description(ln_cnt)                  -- 摘要
         ,gt_status(ln_cnt)                       -- ステータス
         ,gt_freight_charge_class(ln_cnt)         -- 運賃区分
         ,gt_pallet_sum_quantity(ln_cnt)          -- パレット使用枚数
         ,gt_reserve1(ln_cnt)                     -- 予備１
         ,gt_reserve2(ln_cnt)                     -- 予備２
         ,gt_reserve3(ln_cnt)                     -- 予備３
         ,gt_reserve4(ln_cnt)                     -- 予備４
         ,gt_report_dept(ln_cnt)                  -- 報告部署
         ,gt_item_code(ln_cnt)                    -- 品目コード
         ,gt_item_name(ln_cnt)                    -- 品目名
         ,gt_item_uom_code(ln_cnt)                -- 品目単位
         ,gt_item_quantity(ln_cnt)                -- 品目数量
         ,gt_lot_no(ln_cnt)                       -- ロット番号
         ,gt_lot_date(ln_cnt)                     -- 製造日
         ,gt_lot_sign(ln_cnt)                     -- 固有記号
         ,gt_best_bfr_date(ln_cnt)                -- 賞味期限
         ,gt_lot_quantity(ln_cnt)                 -- ロット数量
         ,gt_new_modify_del_class(ln_cnt)         -- データ区分
         ,gt_update_date(ln_cnt)                  -- 更新日時
         ,gt_line_number(ln_cnt)                  -- 明細番号
         ,gt_data_type(ln_cnt)                    -- データタイプ
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
         ,gt_notif_date(ln_cnt)                   -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
        ) ;
--
  EXCEPTION
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_ins_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_out_csv_data
   * Description      : ＣＳＶ出力処理(F-08)
   ***********************************************************************************************/
  PROCEDURE prc_out_csv_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_csv_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_lookup_wf_notif    CONSTANT VARCHAR2(100) := 'XXCMN_WF_NOTIFICATION' ;   -- Workflow通知先
    lc_lookup_wf_info     CONSTANT VARCHAR2(100) := 'XXCMN_WF_INFO' ;           -- Workflow情報
-- M.Hokkanji Ver1.2 START
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- 明細
-- M.Hokkanji Ver1.2 END
--
    -- 2008/07/17 Add ↓
    lv_file_name    CONSTANT VARCHAR2(200) := 'HHT入出庫配車確定情報ファイル';
    lv_tkn_name     CONSTANT VARCHAR2(100) := 'NAME';
    -- 2008/07/17 Add ↑
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    -- ワークフロー関連
    lv_wf_ope_div       VARCHAR2(100) ;         -- 処理区分
    lv_wf_class         VARCHAR2(100) ;         -- 対象
    lv_wf_notification  VARCHAR2(100) ;         -- 宛先
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言
    lv_csv_text         VARCHAR2(32000) ;
-- M.Hokkanji Ver1.2 START
    lt_new_modify_del_class xxwsh_stock_delivery_info_tmp.new_modify_del_class%TYPE;
-- M.Hokkanji Ver1.2 END
--
    -- 2008/07/17 Add ↓
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- 2008/07/17 Add ↑
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    CURSOR cu_out_data
    IS
      SELECT xhsdit.corporation_name          -- 会社名
            ,xhsdit.data_class                -- データ種別
            ,xhsdit.transfer_branch_no        -- 伝送用枝番
            ,xhsdit.delivery_no               -- 配送No
            ,xhsdit.request_no                -- 依頼No
            ,xhsdit.reserve                   -- 予備
            ,xhsdit.head_sales_branch         -- 拠点コード
            ,xhsdit.head_sales_branch_name    -- 管轄拠点名称
            ,xhsdit.shipped_locat_code        -- 出庫倉庫コード
            ,xhsdit.shipped_locat_name        -- 出庫倉庫名称
            ,xhsdit.ship_to_locat_code        -- 入庫倉庫コード
            ,xhsdit.ship_to_locat_name        -- 入庫倉庫名称
            ,xhsdit.freight_carrier_code      -- 運送業者コード
            ,xhsdit.freight_carrier_name      -- 運送業者名
            ,xhsdit.deliver_to                -- 配送先コード
            ,xhsdit.deliver_to_name           -- 配送先名
            ,xhsdit.schedule_ship_date        -- 発日
            ,xhsdit.schedule_arrival_date     -- 着日
            ,xhsdit.shipping_method_code      -- 配送区分
            ,xhsdit.weight                    -- 重量/容積
            ,xhsdit.mixed_no                  -- 混載元依頼№
            ,xhsdit.collected_pallet_qty      -- パレット回収枚数
            ,xhsdit.arrival_time_from         -- 着荷時間指定(FROM)
            ,xhsdit.arrival_time_to           -- 着荷時間指定(TO)
            ,xhsdit.cust_po_number            -- 顧客発注番号
            ,xhsdit.description               -- 摘要
            ,xhsdit.status                    -- ステータス
            ,xhsdit.freight_charge_class      -- 運賃区分
            ,xhsdit.pallet_sum_quantity       -- パレット使用枚数
            ,xhsdit.reserve1                  -- 予備１
            ,xhsdit.reserve2                  -- 予備２
            ,xhsdit.reserve3                  -- 予備３
            ,xhsdit.reserve4                  -- 予備４
            ,xhsdit.report_dept               -- 報告部署
            ,xhsdit.item_code                 -- 品目コード
            ,xhsdit.item_name                 -- 品目名
            ,xhsdit.item_uom_code             -- 品目単位
            ,xhsdit.item_quantity             -- 品目数量
            ,xhsdit.lot_no                    -- ロット番号
            ,xhsdit.lot_date                  -- 製造日
            ,xhsdit.lot_sign                  -- 固有記号
            ,xhsdit.best_bfr_date             -- 賞味期限
            ,xhsdit.lot_quantity              -- ロット数量
            ,xhsdit.new_modify_del_class      -- データ区分
            ,xhsdit.update_date               -- 更新日時
            ,xhsdit.line_number               -- 明細番号
            ,xhsdit.data_type                 -- データタイプ
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
            ,xhsdit.notif_date                -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
      FROM xxwsh_hht_stock_deliv_info_tmp   xhsdit
      ORDER BY xhsdit.new_modify_del_class   DESC   -- データ区分   （降順）
              ,xhsdit.data_type                     -- データタイプ （昇順）
              ,xhsdit.data_class                    -- データ種別   （昇順）
              ,xhsdit.request_no                    -- 依頼No       （昇順）
              ,xhsdit.transfer_branch_no            -- 伝送用枝番   （昇順）
              ,xhsdit.line_number                   -- 明細番号     （昇順）
    ;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- 2008/07/17 Add ↓
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR(gv_prof_put_file_path,
                      gv_prof_put_file_name,
                      lb_retcd,
                      ln_file_size,
                      ln_block_size);
--
    -- ファイル存在
    IF (lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10602',
                                            lv_tkn_name,
                                            lv_file_name);
      lv_errbuf := lv_errmsg;
      RAISE file_exists_expt;
    END IF;
    -- 2008/07/17 Add ↑
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_prof_put_file_path
                       ,gv_prof_put_file_name
                       ,'w'
                      ) ;
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
    <<out_loop>>
    FOR re_out_data IN cu_out_data LOOP
-- M.Hokkanji Ver1.2 START
        IF (re_out_data.transfer_branch_no = lc_transfer_branch_no_d ) THEN
          lt_new_modify_del_class := re_out_data.new_modify_del_class;
        ELSE
          lt_new_modify_del_class := NULL;
        END IF;
-- M.Hokkanji Ver1.2 END
      -- ====================================================
      -- 出力文字列編集
      -- ====================================================
      lv_csv_text := re_out_data.corporation_name         || ','  -- 会社名
                  || re_out_data.data_class               || ','  -- データ種別
                  || re_out_data.transfer_branch_no       || ','  -- 伝送用枝番
                  || re_out_data.delivery_no              || ','  -- 配送No
                  || re_out_data.request_no               || ','  -- 依頼No
                  || re_out_data.reserve                  || ','  -- 予備
                  || re_out_data.head_sales_branch        || ','  -- 拠点コード
                  || REPLACE(re_out_data.head_sales_branch_name,',')   || ','  -- 管轄拠点名称
                  || re_out_data.shipped_locat_code       || ','  -- 出庫倉庫コード
                  || REPLACE(re_out_data.shipped_locat_name,',')       || ','  -- 出庫倉庫名称
                  || re_out_data.ship_to_locat_code       || ','  -- 入庫倉庫コード
                  || REPLACE(re_out_data.ship_to_locat_name,',')       || ','  -- 入庫倉庫名称
                  || re_out_data.freight_carrier_code     || ','  -- 運送業者コード
                  || REPLACE(re_out_data.freight_carrier_name,',')     || ','  -- 運送業者名
                  || re_out_data.deliver_to               || ','  -- 配送先コード
                  || REPLACE(re_out_data.deliver_to_name,',')          || ','  -- 配送先名
                  || TO_CHAR( re_out_data.schedule_ship_date   , 'YYYY/MM/DD' ) || ','  -- 発日
                  || TO_CHAR( re_out_data.schedule_arrival_date, 'YYYY/MM/DD' ) || ','  -- 着日
                  || re_out_data.shipping_method_code     || ','  -- 配送区分
                  -- 2008/08/12 Start ----------------------------------------------
                  --|| re_out_data.weight                   || ','  -- 重量/容積
-- 2009/01/26 v1.17 N.Yoshida UPDATE START
--                  || CEIL(TRUNC(re_out_data.weight,3))    || ','  -- 重量/容積
                  || TRUNC(re_out_data.weight + 0.9)      || ','  -- 重量/容積
-- 2009/01/26 v1.17 N.Yoshida UPDATE END
                  -- 2008/08/12 End ----------------------------------------------
                  || re_out_data.mixed_no                 || ','  -- 混載元依頼№
                  || re_out_data.collected_pallet_qty     || ','  -- パレット回収枚数
                  || re_out_data.arrival_time_from        || ','  -- 着荷時間指定(FROM)
                  || re_out_data.arrival_time_to          || ','  -- 着荷時間指定(TO)
-- ##### 20091203 Ver1.20 本番#276 START #####
--                  || re_out_data.cust_po_number           || ','  -- 顧客発注番号
                  || REPLACE(re_out_data.cust_po_number,',')           || ','  -- 顧客発注番号
-- ##### 20091203 Ver1.20 本番#276 END   #####
                  || REPLACE(re_out_data.description,',')              || ','  -- 摘要
                  || re_out_data.status                   || ','  -- ステータス
                  || re_out_data.freight_charge_class     || ','  -- 運賃区分
                  || re_out_data.pallet_sum_quantity      || ','  -- パレット使用枚数
                  || re_out_data.reserve1                 || ','  -- 予備１
                  || re_out_data.reserve2                 || ','  -- 予備２
                  || re_out_data.reserve3                 || ','  -- 予備３
                  || re_out_data.reserve4                 || ','  -- 予備４
                  || re_out_data.report_dept              || ','  -- 報告部署
                  || re_out_data.item_code                || ','  -- 品目コード
                  || REPLACE(re_out_data.item_name,',')                || ','  -- 品目名
                  || re_out_data.item_uom_code            || ','  -- 品目単位
--2008/08/08 Mod ↓
--                  || re_out_data.item_quantity            || ','  -- 品目数量
-- ##### 20090209 Ver.1.18 本番1082対応 START #####
--                  || CEIL(TRUNC(re_out_data.item_quantity,3))            || ','  -- 品目数量
                  || TRUNC(re_out_data.item_quantity + 0.0009 ,3)      || ','  -- 品目数量（小数点以下3位まで有効（第四位を切上））
-- ##### 20090209 Ver.1.18 本番1082対応 END   #####
--2008/08/08 Mod ↑
                  || re_out_data.lot_no                   || ','                -- ロット番号
-- M.Hokkanji Ver1.4 START
                  || TO_CHAR( re_out_data.lot_date     , 'YYYY/MM/DD' ) || ','  -- 製造日
                  || TO_CHAR( re_out_data.best_bfr_date, 'YYYY/MM/DD' ) || ','  -- 賞味期限
                  || re_out_data.lot_sign                 || ','                -- 固有記号
--                  || TO_CHAR( re_out_data.lot_date     , 'YYYY/MM/DD' ) || ','  -- 製造日
--                  || re_out_data.lot_sign                 || ','                -- 固有記号
--                  || TO_CHAR( re_out_data.best_bfr_date, 'YYYY/MM/DD' ) || ','  -- 賞味期限
--2008/08/08 Mod ↓
--                  || re_out_data.lot_quantity             || ','                -- ロット数量
-- ##### 20090209 Ver.1.18 本番1082対応 START #####
--                  || CEIL(TRUNC(re_out_data.lot_quantity,3)) || ','                -- ロット数量
                  || TRUNC(re_out_data.lot_quantity + 0.0009, 3) || ',' -- ロット数量（小数点以下3位まで有効（第四位を切上））
-- ##### 20090209 Ver.1.18 本番1082対応 END   #####
--2008/08/08 Mod ↑
-- M.Hokkanji Ver1.4 END
-- M.Hokkanji Ver1.2 START
--                  || re_out_data.new_modify_del_class     || ','  -- データ区分
                  || lt_new_modify_del_class              || ','  -- データ区分
                  || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' ) ;
--                  || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' ) || ','
--                  || re_out_data.line_number              || ','  -- 明細番号
--                  || re_out_data.data_type                        -- データタイプ
--                  ;
-- M.Hokkanji Ver1.2 END
--
      -- ====================================================
      -- ＣＳＶ出力
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
      -- ====================================================
      -- 処理件数カウントアップ
      -- ====================================================
      -------------------------------------------------------
      -- 出荷データ
      -------------------------------------------------------
      IF ( re_out_data.data_type = gc_data_type_syu_ins ) THEN
        gn_out_cnt_syu := gn_out_cnt_syu + 1 ;
--
      -------------------------------------------------------
      -- 移動データ
      -------------------------------------------------------
      ELSE
        gn_out_cnt_mov := gn_out_cnt_mov + 1 ;
--
      END IF ;
--
    END LOOP out_loop ;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
  EXCEPTION
    WHEN file_exists_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      UTL_FILE.FCLOSE_ALL ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      UTL_FILE.FCLOSE_ALL ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      UTL_FILE.FCLOSE_ALL ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_out_csv_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_out_data
   * Description      : 通知済みデータ登録処理(F-09,F-10)
   ***********************************************************************************************/
  PROCEDURE prc_ins_out_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_out_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-12853' ;
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    ----------------------------------------
    -- 削除対象データ
    ----------------------------------------
    CURSOR cu_del_data
    IS
      SELECT xhdi.request_no
      FROM xxwsh_hht_delivery_info    xhdi
      WHERE xhdi.request_no IN
        ( SELECT DISTINCT xhsdit.request_no
          FROM   xxwsh_hht_stock_deliv_info_tmp   xhsdit
          WHERE  xhsdit.new_modify_del_class = gc_data_class_del )
      FOR UPDATE NOWAIT
    ;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ロック取得・変更前データ削除
    -- ====================================================
    <<delete_loop>>
    FOR re_del_data IN cu_del_data LOOP
      DELETE
      FROM xxwsh_hht_delivery_info    xhdi
      WHERE xhdi.request_no = re_del_data.request_no
      ;
    END LOOP delete_loop ;
--
    -- ====================================================
    -- ＣＳＶ出力データ登録
    -- ====================================================
    INSERT INTO xxwsh_hht_delivery_info
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
              (   hht_delivery_info_id           -- HHT通知済入出庫配車確定情報ＩＤ
                , corporation_name               -- 会社名
                , data_class                     -- データ種別
                , transfer_branch_no             -- 伝送用枝番
                , delivery_no                    -- 配送No
                , request_no                     -- 依頼No
                , reserve                        -- 予備
                , head_sales_branch              -- 拠点コード
                , head_sales_branch_name         -- 管轄拠点名称
                , shipped_locat_code             -- 出庫倉庫コード
                , shipped_locat_name             -- 出庫倉庫名称
                , ship_to_locat_code             -- 入庫倉庫コード
                , ship_to_locat_name             -- 入庫倉庫名称
                , freight_carrier_code           -- 運送業者コード
                , freight_carrier_name           -- 運送業者名
                , deliver_to                     -- 配送先コード
                , deliver_to_name                -- 配送先名
                , schedule_ship_date             -- 発日
                , schedule_arrival_date          -- 着日
                , shipping_method_code           -- 配送区分
                , weight                         -- 重量/容積
                , mixed_no                       -- 混載元依頼№
                , collected_pallet_qty           -- パレット回収枚数
                , arrival_time_from              -- 着荷時間指定(FROM)
                , arrival_time_to                -- 着荷時間指定(TO)
                , cust_po_number                 -- 顧客発注番号
                , description                    -- 摘要
                , status                         -- ステータス
                , freight_charge_class           -- 運賃区分
                , pallet_sum_quantity            -- パレット使用枚数
                , reserve1                       -- 予備１
                , reserve2                       -- 予備２
                , reserve3                       -- 予備３
                , reserve4                       -- 予備４
                , report_dept                    -- 報告部署
                , item_code                      -- 品目コード
                , item_name                      -- 品目名
                , item_uom_code                  -- 品目単位
                , item_quantity                  -- 品目数量
                , lot_no                         -- ロット番号
                , lot_date                       -- 製造日
                , best_bfr_date                  -- 賞味期限
                , lot_sign                       -- 固有記号
                , lot_quantity                   -- ロット数量
                , new_modify_del_class           -- データ区分
                , update_date                    -- 更新日時
                , line_number                    -- 明細番号
                , data_type                      -- データタイプ
                , notif_date                     -- 確定通知実施日時
                , created_by                     -- 作成者
                , creation_date                  -- 作成日
                , last_updated_by                -- 最終更新者
                , last_update_date               -- 最終更新日
                , last_update_login              -- 最終更新ログイン
                , request_id                     -- 要求ID
                , program_application_id         -- コンカレント・プログラム・アプリケーションID
                , program_id                     -- コンカレント・プログラムID
                , program_update_date            -- プログラム更新日
              )
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
      SELECT xxwsh_hht_delivery_info_s1.NEXTVAL
            ,xhsdit.corporation_name          -- 会社名
            ,xhsdit.data_class                -- データ種別
            ,xhsdit.transfer_branch_no        -- 伝送用枝番
            ,xhsdit.delivery_no               -- 配送No
            ,xhsdit.request_no                -- 依頼No
            ,xhsdit.reserve                   -- 予備
            ,xhsdit.head_sales_branch         -- 拠点コード
            ,xhsdit.head_sales_branch_name    -- 管轄拠点名称
            ,xhsdit.shipped_locat_code        -- 出庫倉庫コード
            ,xhsdit.shipped_locat_name        -- 出庫倉庫名称
            ,xhsdit.ship_to_locat_code        -- 入庫倉庫コード
            ,xhsdit.ship_to_locat_name        -- 入庫倉庫名称
            ,xhsdit.freight_carrier_code      -- 運送業者コード
            ,xhsdit.freight_carrier_name      -- 運送業者名
            ,xhsdit.deliver_to                -- 配送先コード
            ,xhsdit.deliver_to_name           -- 配送先名
            ,xhsdit.schedule_ship_date        -- 発日
            ,xhsdit.schedule_arrival_date     -- 着日
            ,xhsdit.shipping_method_code      -- 配送区分
            ,xhsdit.weight                    -- 重量/容積
            ,xhsdit.mixed_no                  -- 混載元依頼№
            ,xhsdit.collected_pallet_qty      -- パレット回収枚数
            ,xhsdit.arrival_time_from         -- 着荷時間指定(FROM)
            ,xhsdit.arrival_time_to           -- 着荷時間指定(TO)
            ,xhsdit.cust_po_number            -- 顧客発注番号
            ,xhsdit.description               -- 摘要
            ,xhsdit.status                    -- ステータス
            ,xhsdit.freight_charge_class      -- 運賃区分
            ,xhsdit.pallet_sum_quantity       -- パレット使用枚数
            ,xhsdit.reserve1                  -- 予備１
            ,xhsdit.reserve2                  -- 予備２
            ,xhsdit.reserve3                  -- 予備３
            ,xhsdit.reserve4                  -- 予備４
            ,xhsdit.report_dept               -- 報告部署
            ,xhsdit.item_code                 -- 品目コード
            ,xhsdit.item_name                 -- 品目名
            ,xhsdit.item_uom_code             -- 品目単位
            ,xhsdit.item_quantity             -- 品目数量
            ,xhsdit.lot_no                    -- ロット番号
            ,xhsdit.lot_date                  -- 製造日
            ,xhsdit.best_bfr_date             -- 賞味期限
            ,xhsdit.lot_sign                  -- 固有記号
            ,xhsdit.lot_quantity              -- ロット数量
            ,xhsdit.new_modify_del_class      -- データ区分
            ,xhsdit.update_date               -- 更新日時
            ,xhsdit.line_number               -- 明細番号
            ,xhsdit.data_type                 -- データタイプ
-- ##### 20080925 Ver.1.14 統合#26対応 START #####
            ,xhsdit.notif_date                -- 確定通知実施日時
-- ##### 20080925 Ver.1.14 統合#26対応 END   #####
            ,gn_created_by                    -- 作成者
            ,SYSDATE                          -- 作成日
            ,gn_last_updated_by               -- 最終更新者
            ,SYSDATE                          -- 最終更新日
            ,gn_last_update_login             -- 最終更新ログイン
            ,gn_request_id                    -- 要求ID
            ,gn_program_application_id        -- コンカレント・プログラム・アプリケーションID
            ,gn_program_id                    -- コンカレント・プログラムID
            ,SYSDATE                          -- プログラム更新日
      FROM xxwsh_hht_stock_deliv_info_tmp   xhsdit
      WHERE xhsdit.new_modify_del_class = gc_data_class_ins
    ;
--
  EXCEPTION
    -- ============================================================================================
    -- ロック取得エラー
    -- ============================================================================================
    WHEN ex_lock_error THEN
      -- エラーメッセージ取得
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_ins_out_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_put_err_log
   * Description      : 混載エラーログ出力処理(F-11)
   ***********************************************************************************************/
  PROCEDURE prc_put_err_log
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_put_err_log' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-11958' ;
    lc_tok_name_1   CONSTANT VARCHAR2(50) := 'DELI_NO' ;
    lc_tok_name_2   CONSTANT VARCHAR2(50) := 'REQ_NO' ;
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    ----------------------------------------
    -- ログ出力対象データ
    ----------------------------------------
    CURSOR cu_log_data
    IS
      SELECT main.delivery_no
            ,main.request_no
      FROM
        (
          SELECT xoha.delivery_no             AS delivery_no          -- 配送Ｎｏ
                ,xoha.request_no              AS request_no           -- 依頼Ｎｏ
                ,SUM( CASE xic.item_class_code
                        WHEN gc_item_class_i THEN 1
                        ELSE 0
                      END )                   AS cnt_item             -- 製品の件数
                ,SUM( CASE xic.item_class_code
                        WHEN gc_item_class_i THEN 0
                        ELSE 1
                      END )                   AS cnt_else             -- 製品以外の件数
          FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
              ,xxwsh_order_lines_all      xola    -- 受注明細アドオン
              ,xxcmn_item_mst2_v          xim     -- OPM品目情報VIEW2
              ,xxcmn_item_categories5_v   xic     -- OPM品目カテゴリ割当VIEW4
          WHERE
          -----------------------------------------------------------------------------------------
          -- 品目
          -----------------------------------------------------------------------------------------
                xim.item_id             = xic.item_id
          AND   gd_effective_date       BETWEEN xim.start_date_active
                                        AND     NVL( xim.end_date_active ,gd_effective_date )
          AND   xola.shipping_item_code = xim.item_no
          -----------------------------------------------------------------------------------------
          -- 受注明細
          -----------------------------------------------------------------------------------------
          AND   xoha.order_header_id = xola.order_header_id
          -----------------------------------------------------------------------------------------
          -- 受注ヘッダアドオン
          -----------------------------------------------------------------------------------------
          AND   (
                  (   xoha.req_status            = gc_req_status_syu_3    -- 締め済
                  AND xoha.notif_status          = gc_notif_status_c      -- 確定通知済
                  AND xoha.prev_notif_status     = gc_notif_status_n      -- 未通知
                  AND xola.quantity              > 0                      -- 明細数量 > 0   -- 2008/11/07 統合指摘#143 Add
                  AND NOT EXISTS
                        ( SELECT 1
                          FROM xxwsh_hht_delivery_info  xhdi
                          WHERE xhdi.request_no = xoha.request_no )
                  )
                OR
                  (   xoha.notif_status          = gc_notif_status_c      -- 確定通知済
                  AND xoha.prev_notif_status     = gc_notif_status_r   )  -- 再通知要
                )
          AND   xoha.req_status                 = gc_req_status_syu_3   -- 締め済
          AND   xoha.notif_date           BETWEEN gd_date_from AND gd_date_to
          AND   xoha.latest_external_flag = gc_yes_no_y             -- 最新
          AND   xoha.prod_class           = gc_prod_class_r         -- リーフ
          AND   ((xoha.instruction_dept   = gr_param.dept_code_01)  -- 指示部署
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_02,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_03,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_04,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_05,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_06,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_07,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_08,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_09,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_10,xoha.instruction_dept)))
          GROUP BY xoha.delivery_no
                  ,xoha.request_no
          ORDER BY xoha.delivery_no
                  ,xoha.request_no
        ) main
      WHERE main.cnt_item > 0
      AND   main.cnt_else > 0
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ログ出力
    -- ====================================================
    <<log_loop>>
    FOR re_log_data IN cu_log_data LOOP
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                       ,iv_token_name1    => lc_tok_name_1
                       ,iv_token_name2    => lc_tok_name_2
                       ,iv_token_value1   => re_log_data.delivery_no
                       ,iv_token_value2   => re_log_data.request_no
                      ) ;
      gn_wrm_idx              := gn_wrm_idx + 1 ;
      gt_worm_msg(gn_wrm_idx) := lv_errmsg ;
      ov_retcode              := gv_status_warn ;
    END LOOP log_loop ;
--
  EXCEPTION
--##### 固定例外処理部 START ######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   ######################################################################
  END prc_put_err_log ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_dept_code_01     IN  VARCHAR2          -- 01 : 部署_01
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : 部署_02(2008/07/17 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : 部署_03(2008/07/17 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : 部署_04(2008/07/17 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : 部署_05(2008/07/17 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : 部署_06(2008/07/17 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : 部署_07(2008/07/17 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : 部署_08(2008/07/17 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : 部署_09(2008/07/17 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : 部署_10(2008/07/17 Add)
     ,iv_date_fix         IN  VARCHAR2          -- 11 : 確定通知実施日
     ,iv_fix_from         IN  VARCHAR2          -- 12 : 確定通知実施時間From
     ,iv_fix_to           IN  VARCHAR2          -- 13 : 確定通知実施時間To
     ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
--
    -- ==================================================
    -- ローカル変数
    -- ==================================================
    lv_temp_request_no    xxwsh_stock_delivery_info_tmp2.request_no%TYPE := '*' ;
    lv_break_flg          VARCHAR2(1) := gc_yes_no_n ;
    lv_error_flg          VARCHAR2(1) := gc_yes_no_n ;
--
    lv_errbuf             VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode            VARCHAR2(1);     -- リターン・コード
    lv_errmsg             VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_worn               EXCEPTION ;
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
    ov_retcode := gv_status_normal;
--###########################  固定部 END   ############################
--
    -- ============================================================================================
    -- 初期処理
    -- ============================================================================================
    --------------------------------------------------
    -- グローバル変数の初期化
    --------------------------------------------------
    gn_out_cnt_syu := 0 ;   -- 出力件数：出荷
    gn_out_cnt_mov := 0 ;   -- 出力件数：移動
--
    --------------------------------------------------
    -- パラメータ格納
    --------------------------------------------------
    gr_param.dept_code_01 := iv_dept_code_01 ;                  -- 01 : 部署_01
    gr_param.dept_code_02 := iv_dept_code_02 ;                  -- 02 : 部署_02(2008/07/17 Add)
    gr_param.dept_code_03 := iv_dept_code_03 ;                  -- 03 : 部署_03(2008/07/17 Add)
    gr_param.dept_code_04 := iv_dept_code_04 ;                  -- 04 : 部署_04(2008/07/17 Add)
    gr_param.dept_code_05 := iv_dept_code_05 ;                  -- 05 : 部署_05(2008/07/17 Add)
    gr_param.dept_code_06 := iv_dept_code_06 ;                  -- 06 : 部署_06(2008/07/17 Add)
    gr_param.dept_code_07 := iv_dept_code_07 ;                  -- 07 : 部署_07(2008/07/17 Add)
    gr_param.dept_code_08 := iv_dept_code_08 ;                  -- 08 : 部署_08(2008/07/17 Add)
    gr_param.dept_code_09 := iv_dept_code_09 ;                  -- 09 : 部署_09(2008/07/17 Add)
    gr_param.dept_code_10 := iv_dept_code_10 ;                  -- 10 : 部署_10(2008/07/17 Add)
    gr_param.date_fix     := SUBSTR( iv_date_fix   , 1, 10 ) ;  -- 11 : 確定通知実施日
    gr_param.fix_from     := NVL( iv_fix_from, gc_time_min ) ;  -- 12 : 確定通知実施時間From
    gr_param.fix_to       := NVL( iv_fix_to  , gc_time_max ) ;  -- 13 : 確定通知実施時間To
--
    gr_param.fix_from     := ' ' || gr_param.fix_from    || ':00' ;
    gr_param.fix_to       := ' ' || gr_param.fix_to      || ':59' ;
--
    --------------------------------------------------
    -- 基準日の設定
    --------------------------------------------------
    gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix ) ;
    gd_date_from  := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_from ) ;
    gd_date_to    := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_to ) ;
--
    --------------------------------------------------
    -- ＷＨＯカラム取得
    --------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- 作成者
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- 最終更新者
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- ＣＰ・アプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- コンカレント・プログラムID
--
    -- ============================================================================================
    -- F-01 パラメータチェック
    -- ============================================================================================
    prc_chk_param
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-02 プロファイル取得
    -- ============================================================================================
    prc_get_profile
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-03 データ削除
    -- ============================================================================================
    prc_del_temp_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-04 メインデータ抽出
    -- ============================================================================================
    prc_get_main_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    -- エラー発生時
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
--
    -- 警告発生時
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      gn_warn_cnt := gn_warn_cnt + 1 ;
      RAISE ex_worn ;
--
    END IF ;
--
    <<main_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      gn_target_cnt := gn_target_cnt + 1 ;
--
      ---------------------------------------------------------------------------------------------
      -- 依頼Ｎｏブレイクフラグの設定
      ---------------------------------------------------------------------------------------------
      IF ( lv_temp_request_no = gt_main_data(i).request_no ) THEN
        lv_break_flg := gc_yes_no_n ;
      ELSE
        lv_break_flg       := gc_yes_no_y ;
        lv_temp_request_no := gt_main_data(i).request_no ;
      END IF ;
--
      -- ==========================================================================================
      -- F-05 通知済情報作成処理
      -- ==========================================================================================
      --IF ( gt_main_data(i).line_delete_flag = gc_delete_flag_n ) THEN              -- 2008/08/27 TE080_600指摘#28 Del
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 START #####
/*****
      IF ( gt_main_data(i).data_type IN( gc_data_type_syu_ins         -- 出荷：登録  -- 2008/08/29 TE080_600指摘#27(1) Add
                                        ,gc_data_type_mov_ins) ) THEN -- 移動：登録  -- 2008/08/29 TE080_600指摘#27(1) Add
*****/
      -- 出荷、移動のデータ且つ、出庫又は、入庫の内外倉庫区分が内の場合、通知情報を作成
      IF ( gt_main_data(i).data_type IN( gc_data_type_syu_ins ,gc_data_type_mov_ins )) -- 出荷、移動登録
        AND ((gt_main_data(i).out_whse_inout_div = gc_whse_io_div_i ) 
          OR (gt_main_data(i).in_whse_inout_div    = gc_whse_io_div_i )) THEN
-- ##### 20081007 Ver.1.15 TE080_600指摘#27対応 END   #####
--
        prc_create_ins_data
          (
            in_idx        => i
            ,iv_break_flg  => lv_break_flg
            ,ov_errbuf     => lv_errbuf
            ,ov_retcode    => lv_retcode
            ,ov_errmsg     => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
      END IF ;
--
      -- ==========================================================================================
      -- F-06 変更前情報取消データ作成処理
      -- ==========================================================================================
      IF (   ( lv_break_flg                      = gc_yes_no_y       )        -- 依頼Ｎｏブレイク
         AND ( gt_main_data(i).prev_notif_status = gc_notif_status_r ) ) THEN -- 前回通知：再通知要
        prc_create_can_data
          (
            iv_request_no           => gt_main_data(i).request_no
           ,ov_errbuf               => lv_errbuf
           ,ov_retcode              => lv_retcode
           ,ov_errmsg               => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
--
      END IF ;
--
    END LOOP main_loop ;
--
    -- ============================================================================================
    -- F-07 一括登録処理
    -- ============================================================================================
    prc_ins_temp_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-08 ＣＳＶ出力処理
    -- ============================================================================================
    prc_out_csv_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ===========================================================================================
    -- F-09,F-10 通知済みデータ登録処理
    -- ===========================================================================================
    prc_ins_out_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ===========================================================================================
    -- F-11 混載エラーログ出力処理
    -- ===========================================================================================
    prc_put_err_log
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
--
    -- 警告発生時
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      gn_warn_cnt := gn_warn_cnt + 1 ;
      RAISE ex_worn ;
--
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- 警告処理
    -- ============================================================================================
    WHEN ex_worn THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf ;
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf              OUT NOCOPY VARCHAR2   -- エラー・メッセージ  --# 固定 #
     ,retcode             OUT NOCOPY VARCHAR2   -- リターン・コード    --# 固定 #
     ,iv_dept_code_01     IN  VARCHAR2          -- 01 : 部署_01
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : 部署_02(2008/07/17 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : 部署_03(2008/07/17 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : 部署_04(2008/07/17 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : 部署_05(2008/07/17 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : 部署_06(2008/07/17 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : 部署_07(2008/07/17 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : 部署_08(2008/07/17 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : 部署_09(2008/07/17 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : 部署_10(2008/07/17 Add)
     ,iv_date_fix         IN  VARCHAR2          -- 02 : 確定通知実施日
     ,iv_fix_from         IN  VARCHAR2          -- 03 : 確定通知実施時間From
     ,iv_fix_to           IN  VARCHAR2          -- 04 : 確定通知実施時間To
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain
      (
        iv_dept_code_01     => iv_dept_code_01 -- 01 : 部署
       ,iv_dept_code_02     => iv_dept_code_02 -- 02 : 部署(2008/07/17 Add)
       ,iv_dept_code_03     => iv_dept_code_03 -- 03 : 部署(2008/07/17 Add)
       ,iv_dept_code_04     => iv_dept_code_04 -- 04 : 部署(2008/07/17 Add)
       ,iv_dept_code_05     => iv_dept_code_05 -- 05 : 部署(2008/07/17 Add)
       ,iv_dept_code_06     => iv_dept_code_06 -- 06 : 部署(2008/07/17 Add)
       ,iv_dept_code_07     => iv_dept_code_07 -- 07 : 部署(2008/07/17 Add)
       ,iv_dept_code_08     => iv_dept_code_08 -- 08 : 部署(2008/07/17 Add)
       ,iv_dept_code_09     => iv_dept_code_09 -- 09 : 部署(2008/07/17 Add)
       ,iv_dept_code_10     => iv_dept_code_10 -- 10 : 部署(2008/07/17 Add)
       ,iv_date_fix         => iv_date_fix     -- 11 : 確定通知実施日
       ,iv_fix_from         => iv_fix_from     -- 12 : 確定通知実施時間From
       ,iv_fix_to           => iv_fix_to       -- 13 : 確定通知実施時間To
       ,ov_errbuf           => lv_errbuf       -- エラー・メッセージ
       ,ov_retcode          => lv_retcode      -- リターン・コード
       ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ
      ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    -- エラー発生時
    IF ( lv_retcode = gv_status_error ) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    -- 警告発生時
    IF (   ( lv_retcode = gv_status_warn )
       AND ( lv_errmsg IS NOT NULL       ) ) THEN
      FND_FILE.PUT_LINE( FND_FILE.LOG   , lv_errbuf ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg ) ;
    END IF;
--
    -- ====================================================
    -- コンカレントログの出力
    -- ====================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
--
    -------------------------------------------------------
    -- 入力パラメータ
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '入力パラメータ' );
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_01 　　　　　　：' || iv_dept_code_01) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_02 　　　　　　：' || iv_dept_code_02) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_03 　　　　　　：' || iv_dept_code_03) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_04 　　　　　　：' || iv_dept_code_04) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_05 　　　　　　：' || iv_dept_code_05) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_06 　　　　　　：' || iv_dept_code_06) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_07 　　　　　　：' || iv_dept_code_07) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_08 　　　　　　：' || iv_dept_code_08) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_09 　　　　　　：' || iv_dept_code_09) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_10 　　　　　　：' || iv_dept_code_10) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　確定通知実施日　　　：' || iv_date_fix    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　確定通知実施時間From：' || iv_fix_from    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　確定通知実施時間To　：' || iv_fix_to      ) ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
--
    -------------------------------------------------------
    -- 警告メッセージ
    -------------------------------------------------------
    IF ( gn_wrm_idx <> 0 ) THEN
      FOR i IN 1..gn_wrm_idx LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gt_worm_msg(i) ) ;
      END LOOP ;
--
      lv_retcode := gv_status_warn ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
--
    END IF ;
--
    -------------------------------------------------------
    -- 処理件数
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, 'ＣＳＶ出力件数' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　出荷：' || TO_CHAR( gn_out_cnt_syu, 'FM999,999,990' ));
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　移動：' || TO_CHAR( gn_out_cnt_mov, 'FM999,999,990' ));
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
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
END xxwsh600004c ;
/
