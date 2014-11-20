create or replace PACKAGE BODY xxwsh600002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600002c(body)
 * Description      : 入出庫配送計画情報抽出処理
 * MD.050           : T_MD050_BPO_601_配車配送計画
 * MD.070           : T_MD070_BPO_60E_入出庫配送計画情報抽出処理
 * Version          : 1.33
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_chk_param          パラメータチェック             (E-01)
 *  prc_get_profile        プロファイル取得               (E-02)
 *  prc_chk_multi          多重起動チェック               -- PT2-2_17指摘71対応 追加
 *  prc_del_temp_data      テーブル削除                   (E-03)
 *  prc_del_tmptable_data  テンポラリテーブルデータ削除   -- PT2-2_17指摘71対応 追加
 *  prc_ins_temp_table     中間テーブル登録
 *  prc_get_main_data      メインデータ抽出               (E-04)
 *  prc_get_can_data       取消データ抽出                 -- TE080_600指摘#27対応 追加
 *  prc_get_zero_can_data  依頼数量ゼロ取消データ抽出     -- 統合#143対応 追加
 *  prc_cre_head_data      ヘッダデータ作成
 *  prc_cre_dtl_data       明細データ作成
 *  prc_create_ins_data    通知済情報作成処理             (E-05)
 *  prc_create_can_data    変更前情報取消データ作成処理   (E-06)
 *  prc_ins_temp_data      一括登録処理                   (E-07)
 *  prc_out_csv_data       ＣＳＶ出力処理                 (E-08,E-09,E-10)
 *  prc_ins_out_data       変更前情報削除処理             (E-11,E-12)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/01    1.0   M.Ikeda          新規作成
 *  2008/06/04    1.1   N.Yoshida        移動ロット詳細紐付け対応
 *  2008/06/05    1.2   M.Hokkanji       結合テスト用暫定対応:CSV出力処理の出力場所を変更
 *                                       中間テーブル登録データ抽出する際、配車配送計画ア
 *                                       ドオンにデータが存在しない場合でもデータを出力さ
 *                                       れるように修正
 *  2008/06/06    1.3   M.HOKKANJI       ＣＳＶ出力処理でエラー発生時にF_CLOSE_ALLしているのを
 *                                       個別にクローズするように変更
 *  2008/06/06    1.4   M.HOKKANJI       結合テスト440不具合対応#66
 *  2008/06/06    1.5   M.HOKKANJI       結合テスト440不具合対応#65
 *  2008/06/11    1.6   M.NOMURA         結合テスト WF対応
 *  2008/06/12    1.7   M.NOMURA         結合テスト 不具合対応#9
 *  2008/06/16    1.8   M.NOMURA         結合テスト 440 不具合対応#64
 *  2008/06/18    1.9   M.HOKKANJI       システムテスト不具合対応#147,#187
 *  2008/06/23    1.10  M.NOMURA         システムテスト不具合対応#217
 *  2008/06/27    1.11  M.NOMURA         システムテスト不具合対応#303
 *  2008/07/04    1.12  M.NOMURA         システムテスト不具合対応#390
 *  2008/07/16    1.13  Oracle 山根 一浩 I_S_192,T_S_443,指摘240対応
 *  2008/08/04    1.14  M.NOMURA         追加結合不具合対応
 *  2008/08/12    1.15  N.Fukuda         課題#32対応
 *  2008/08/12    1.15  N.Fukuda         課題#48(変更要求#164)対応
 *  2008/09/01    1.16  Y.Yamamoto       PT 2-2_17 指摘17対応
 *  2008/09/09    1.17  N.Fukuda         TE080_600指摘#30対応
 *  2008/09/10    1.17  N.Fukuda         参照Viewの変更(パーティから顧客に変更)
 *  2008/09/19    1.18  M.Nomura         T_S_453 460 468対応
 *  2008/09/25    1.19  M.Nomura         TE080_600指摘#31対応
 *  2008/09/25    1.20  M.Nomura         統合#26対応
 *  2008/10/06    1.21  M.Nomura         統合#306対応
 *  2008/10/07    1.22  M.Nomura         TE080_600指摘#27対応
 *  2008/10/14    1.23  M.Nomura         PT2-2_17指摘71対応
 *  2008/10/20    1.24  M.Nomura         統合#417対応
 *  2008/10/23    1.25  M.Nomura         T_S_440対応
 *  2008/10/28    1.26  M.Nomura         統合#143対応
 *  2008/11/12    1.27  M.Nomura         統合#626対応
 *  2008/11/27    1.28  M.Nomura         本番177対応
 *  2009/01/13    1.29  H.Itou           本番971対応
 *  2009/01/26    1.30  N.Yoshida        本番1017対応
 *  2009/02/09    1.31  M.Nomura         本番1082対応
 *  2009/04/23    1.32  H.Itou           本番1398対応
 *  <<営業C/O後>>
 *  2009/12/03    1.33  Marushita        本番276対応
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
  PRAGMA EXCEPTION_INIT( ex_lock_error, -54 ) ;
--
  -- ==============================================================================================
  -- グローバル定数
  -- ==============================================================================================
  --------------------------------------------------
  -- パッケージ名
  --------------------------------------------------
  gc_pkg_name           CONSTANT VARCHAR2(100)  := 'xxwsh600002c';
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
  -- 予定確定区分
  gc_fix_class_y        CONSTANT VARCHAR2(1) := '1' ;   -- 予定
  gc_fix_class_k        CONSTANT VARCHAR2(1) := '2' ;   -- 確定
  -- ステータス
  gc_req_status_syu_1   CONSTANT VARCHAR2(2) := '01' ;  -- 入力中
  gc_req_status_syu_2   CONSTANT VARCHAR2(2) := '02' ;  -- 拠点確定
  gc_req_status_syu_3   CONSTANT VARCHAR2(2) := '03' ;  -- 締め済み
  gc_req_status_syu_4   CONSTANT VARCHAR2(2) := '04' ;  -- 出荷実績計上済
  gc_req_status_syu_5   CONSTANT VARCHAR2(2) := '99' ;  -- 取消
  gc_req_status_shi_1   CONSTANT VARCHAR2(2) := '05' ;  -- 入力中
  gc_req_status_shi_2   CONSTANT VARCHAR2(2) := '06' ;  -- 入力完了
  gc_req_status_shi_3   CONSTANT VARCHAR2(2) := '07' ;  -- 受領済
  gc_req_status_shi_4   CONSTANT VARCHAR2(2) := '08' ;  -- 出荷実績計上済
  gc_req_status_shi_5   CONSTANT VARCHAR2(2) := '99' ;  -- 取消
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
  -- Ｙ／Ｎフラグ
  gc_yes_no_y           CONSTANT VARCHAR2(1) := 'Y' ;   -- Ｙ
  gc_yes_no_n           CONSTANT VARCHAR2(1) := 'N' ;   -- Ｎ
  -- 運賃区分
-- 
-- M.Hokkanji Ver1.4 START
--  gc_freight_class_y    CONSTANT VARCHAR2(1) := 'Y' ;   -- 対象
--  gc_freight_class_n    CONSTANT VARCHAR2(1) := 'N' ;   -- 対象外
  gc_freight_class_y    CONSTANT VARCHAR2(1) := '1' ;   -- 対象
  gc_freight_class_n    CONSTANT VARCHAR2(1) := '0' ;   -- 対象外
-- M.Hokkanji Ver1.4 END
  --EOS管理区分
  gc_manage_eos_y       CONSTANT VARCHAR2(1) := '1' ;   -- EOS業者
  gc_manage_eos_n       CONSTANT VARCHAR2(1) := '0' ;   -- EOS以外
  --出荷支給区分
  gc_sp_class_ship        CONSTANT VARCHAR2(1)  := '1' ;    -- 出荷依頼
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- 支給依頼
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- 移動（プログラム内限定）
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
-- ##### 2009/04/23 Ver.1.32 本番#1398対応 START #####
  -- マスタステータス
  gc_status_active        CONSTANT VARCHAR2(1) := 'A' ;     -- 有効
  gc_status_inactive      CONSTANT VARCHAR2(1) := 'I' ;     -- 無効
-- ##### 2009/04/23 Ver.1.32 本番#1398対応 END   #####
  --------------------------------------------------
  -- 登録値
  --------------------------------------------------
  -- 明細削除フラグ
  gc_delete_flag_y          CONSTANT VARCHAR2(1) := '1' ;   -- 削除
  gc_delete_flag_n          CONSTANT VARCHAR2(1) := '0' ;   -- 未削除
  -- データタイプ
  gc_data_type_syu_ins      CONSTANT VARCHAR2(1) := '1' ;   -- 出荷：登録
  gc_data_type_shi_ins      CONSTANT VARCHAR2(1) := '2' ;   -- 支給：登録
  gc_data_type_mov_ins      CONSTANT VARCHAR2(1) := '3' ;   -- 移動：登録
  gc_data_type_syu_can      CONSTANT VARCHAR2(1) := '7' ;   -- 出荷：取消
  gc_data_type_shi_can      CONSTANT VARCHAR2(1) := '8' ;   -- 支給：取消
  gc_data_type_mov_can      CONSTANT VARCHAR2(1) := '9' ;   -- 移動：取消
  -- 運賃区分
  gc_freight_class_ins_y    CONSTANT VARCHAR2(1) := '1' ;   -- 対象
  gc_freight_class_ins_n    CONSTANT VARCHAR2(1) := '0' ;   -- 対象外
  -- データ種別
  gc_data_class_syu_s       CONSTANT VARCHAR2(3) := '110' ;   -- 出荷：出荷依頼
  gc_data_class_syu_h       CONSTANT VARCHAR2(3) := '140' ;   -- 出荷：配送依頼
  gc_data_class_shi_s       CONSTANT VARCHAR2(3) := '100' ;   -- 支給：出荷依頼
  gc_data_class_shi_h       CONSTANT VARCHAR2(3) := '160' ;   -- 支給：配送依頼
  gc_data_class_mov_s       CONSTANT VARCHAR2(3) := '120' ;   -- 移動：出荷依頼
  gc_data_class_mov_h       CONSTANT VARCHAR2(3) := '150' ;   -- 移動：配送依頼
  gc_data_class_mov_n       CONSTANT VARCHAR2(3) := '130' ;   -- 移動：移動入庫
  -- ステータス
  gc_status_y               CONSTANT VARCHAR2(2) := '01' ;    -- 予定
  gc_status_k               CONSTANT VARCHAR2(2) := '02' ;    -- 確定
  -- データ区分
  gc_data_class_ins         CONSTANT VARCHAR2(1) := '0' ;     -- 追加
-- M.Hokkanji Ver1.4 START
--  gc_data_class_del         CONSTANT VARCHAR2(1) := '2' ;     -- 削除
  gc_data_class_del         CONSTANT VARCHAR2(1) := '1' ;     -- 削除
-- M.Hokkanji Ver1.4 END
  -- ワークフロー区分
  gc_wf_class_gai           CONSTANT VARCHAR2(1) := '1' ;     -- 外部倉庫
  gc_wf_class_uns           CONSTANT VARCHAR2(1) := '2' ;     -- 運送業者
  gc_wf_class_tor           CONSTANT VARCHAR2(1) := '3' ;     -- 取引先
  gc_wf_class_hht           CONSTANT VARCHAR2(1) := '4' ;     -- HHTサーバー
  gc_wf_class_sys           CONSTANT VARCHAR2(1) := '5' ;     -- 現営業システム
  gc_wf_class_syo           CONSTANT VARCHAR2(1) := '6' ;     -- 職責
--
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
  -- XXCMN：商品区分(セキュリティ)
  gv_prof_item_div_security   CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV_SECURITY';
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
--
  --------------------------------------------------
  -- その他
  --------------------------------------------------
  gc_time_default           CONSTANT VARCHAR2(4) := '0000' ;    -- 時間デフォルト値
  gc_time_min               CONSTANT VARCHAR2(5) := '00:00' ;   -- 時間最小値
  gc_time_max               CONSTANT VARCHAR2(5) := '23:59' ;   -- 時間最大値
--
-- ##### 20080611 Ver.1.6 WF対応 START #####
  gc_wf_ope_div             CONSTANT VARCHAR2(2) := '09'; -- Workflow通知先（09:外部倉庫入出庫）
-- ##### 20080611 Ver.1.6 WF対応 END   #####
--
  -- ==============================================================================================
  -- グローバル変数
  -- ==============================================================================================
  gd_effective_date   DATE ;    -- マスタ絞込み日付
  gd_date_from        DATE ;    -- 基準日付From
  gd_date_to          DATE ;    -- 基準日付To
  gn_prof_del_date    NUMBER ;  -- 削除基準日数
--
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
  gd_ship_date_from   DATE ;    -- 出庫日From
  gd_ship_date_to     DATE ;    -- 出庫日To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
--  gv_filetimes        VARCHAR2(14);   -- YYYYMMDDHH24MISS形式
  gv_filetimes        VARCHAR2(15);   -- YYYYMMDDHH24MISSFF形式
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
--
-- ##### 20080611 Ver.1.6 WF対応 START #####
  gr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec ;   -- ファイル情報のレコードの定義
-- ##### 20080611 Ver.1.6 WF対応 END   #####
--
  gn_created_by               NUMBER ;  -- 作成者
  gn_last_updated_by          NUMBER ;  -- 最終更新者
  gn_last_update_login        NUMBER ;  -- 最終更新ログイン
  gn_request_id               NUMBER ;  -- 要求ID
  gn_program_application_id   NUMBER ;  -- コンカレント・プログラム・アプリケーションID
  gn_program_id               NUMBER ;  -- コンカレント・プログラムID
--
  gn_out_cnt_syu              NUMBER := 0 ;   -- 出力件数：出荷
  gn_out_cnt_shi              NUMBER := 0 ;   -- 出力件数：支給
  gn_out_cnt_mov              NUMBER := 0 ;   -- 出力件数：移動
--
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
  gv_item_div_security        VARCHAR2(100);
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
-- ##### 20090113 Ver.1.29 本番#971対応 START #####
  gd_min_date        DATE; -- MIN日付
  gd_max_date        DATE; -- MAX日付
-- ##### 20090113 Ver.1.29 本番#971対応 END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
  -- 多重起動確認用
  gv_date_fix          VARCHAR2(20);  -- 確定通知実施日
  gv_fix_from          VARCHAR2(10);  -- 確定通知実施時間From
  gv_fix_to            VARCHAR2(10);  -- 確定通知実施時間To
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
  --------------------------------------------------
  -- デバッグ用
  --------------------------------------------------
  gv_debug_txt                VARCHAR2(1000) ;
  gv_debug_cnt                NUMBER := 0 ;
--
  -- ==============================================================================================
  -- レコード型宣言
  -- ==============================================================================================
  --------------------------------------------------
  -- 入力パラメータ格納用
  --------------------------------------------------
  TYPE rec_param_data  IS RECORD
    (
      dept_code_01      VARCHAR2(4)   -- 01 : 部署_01
     ,dept_code_02      VARCHAR2(4)   -- 02 : 部署_02(2008/07/16 Add)
     ,dept_code_03      VARCHAR2(4)   -- 03 : 部署_03(2008/07/16 Add)
     ,dept_code_04      VARCHAR2(4)   -- 04 : 部署_04(2008/07/16 Add)
     ,dept_code_05      VARCHAR2(4)   -- 05 : 部署_05(2008/07/16 Add)
     ,dept_code_06      VARCHAR2(4)   -- 06 : 部署_06(2008/07/16 Add)
     ,dept_code_07      VARCHAR2(4)   -- 07 : 部署_07(2008/07/16 Add)
     ,dept_code_08      VARCHAR2(4)   -- 08 : 部署_08(2008/07/16 Add)
     ,dept_code_09      VARCHAR2(4)   -- 09 : 部署_09(2008/07/16 Add)
     ,dept_code_10      VARCHAR2(4)   -- 10 : 部署_10(2008/07/16 Add)
     ,fix_class         VARCHAR2(1)   -- 02 : 予定確定区分
     ,date_cutoff       VARCHAR2(20)  -- 03 : 締め実施日
     ,cutoff_from       VARCHAR2(10)  -- 04 : 締め実施時間From
     ,cutoff_to         VARCHAR2(10)  -- 05 : 締め実施時間To
     ,date_fix          VARCHAR2(20)  -- 06 : 確定通知実施日
     ,fix_from          VARCHAR2(10)  -- 07 : 確定通知実施時間From
     ,fix_to            VARCHAR2(10)  -- 08 : 確定通知実施時間To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
     ,ship_date_from    VARCHAR2(10)  --    : 出庫日From
     ,ship_date_to      VARCHAR2(10)  --    : 出庫日To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
    ) ;
  gr_param              rec_param_data ;
--
  --------------------------------------------------
  -- 中間テーブル格納用
  --------------------------------------------------
  TYPE rec_main_data  IS RECORD
    (
      line_number               xxwsh_stock_delivery_info_tmp2.line_number%TYPE
     ,line_delete_flag          xxwsh_stock_delivery_info_tmp2.line_delete_flag%TYPE
     ,prev_notif_status         xxwsh_stock_delivery_info_tmp2.prev_notif_status%TYPE
     ,data_type                 xxwsh_stock_delivery_info_tmp2.data_type%TYPE
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
     ,eos_shipped_to_locat      xxwsh_stock_delivery_info_tmp2.eos_shipped_to_locat%TYPE
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
     ,eos_shipped_locat         xxwsh_stock_delivery_info_tmp2.eos_shipped_locat%TYPE
     ,eos_freight_carrier       xxwsh_stock_delivery_info_tmp2.eos_freight_carrier%TYPE
     ,delivery_no               xxwsh_stock_delivery_info_tmp2.delivery_no%TYPE
     ,request_no                xxwsh_stock_delivery_info_tmp2.request_no%TYPE
     ,head_sales_branch         xxwsh_stock_delivery_info_tmp2.head_sales_branch%TYPE
     ,head_sales_branch_name    xxwsh_stock_delivery_info_tmp2.head_sales_branch_name%TYPE
     ,shipped_locat_code        xxwsh_stock_delivery_info_tmp2.shipped_locat_code%TYPE
     ,shipped_locat_name        xxwsh_stock_delivery_info_tmp2.shipped_locat_name%TYPE
     ,ship_to_locat_code        xxwsh_stock_delivery_info_tmp2.ship_to_locat_code%TYPE
     ,ship_to_locat_name        xxwsh_stock_delivery_info_tmp2.ship_to_locat_name%TYPE
     ,freight_carrier_code      xxwsh_stock_delivery_info_tmp2.freight_carrier_code%TYPE
     ,freight_carrier_name      xxwsh_stock_delivery_info_tmp2.freight_carrier_name%TYPE
     ,deliver_to                xxwsh_stock_delivery_info_tmp2.deliver_to%TYPE
     ,deliver_to_name           xxwsh_stock_delivery_info_tmp2.deliver_to_name%TYPE
     ,schedule_ship_date        xxwsh_stock_delivery_info_tmp2.schedule_ship_date%TYPE
     ,schedule_arrival_date     xxwsh_stock_delivery_info_tmp2.schedule_arrival_date%TYPE
     ,shipping_method_code      xxwsh_stock_delivery_info_tmp2.shipping_method_code%TYPE
     ,weight                    xxwsh_stock_delivery_info_tmp2.weight%TYPE
     ,mixed_no                  xxwsh_stock_delivery_info_tmp2.mixed_no%TYPE
     ,collected_pallet_qty      xxwsh_stock_delivery_info_tmp2.collected_pallet_qty%TYPE
     ,freight_charge_class      xxwsh_stock_delivery_info_tmp2.freight_charge_class%TYPE
     ,arrival_time_from         xxwsh_stock_delivery_info_tmp2.arrival_time_from%TYPE
     ,arrival_time_to           xxwsh_stock_delivery_info_tmp2.arrival_time_to%TYPE
     ,cust_po_number            xxwsh_stock_delivery_info_tmp2.cust_po_number%TYPE
     ,description               xxwsh_stock_delivery_info_tmp2.description%TYPE
     ,pallet_sum_quantity_out   xxwsh_stock_delivery_info_tmp2.pallet_sum_quantity_out%TYPE
     ,pallet_sum_quantity_in    xxwsh_stock_delivery_info_tmp2.pallet_sum_quantity_in%TYPE
     ,report_dept               xxwsh_stock_delivery_info_tmp2.report_dept%TYPE
     ,prod_class                xxwsh_stock_delivery_info_tmp2.prod_class%TYPE
     ,item_class                xxwsh_stock_delivery_info_tmp2.item_class%TYPE
     ,item_code                 xxwsh_stock_delivery_info_tmp2.item_code%TYPE
     ,item_name                 xxwsh_stock_delivery_info_tmp2.item_name%TYPE
     ,item_uom_code             xxwsh_stock_delivery_info_tmp2.item_uom_code%TYPE
     ,conv_unit                 xxwsh_stock_delivery_info_tmp2.conv_unit%TYPE
     ,item_quantity             xxwsh_stock_delivery_info_tmp2.item_quantity%TYPE
     ,case_quantity             xxwsh_stock_delivery_info_tmp2.case_quantity%TYPE
     ,lot_class                 xxwsh_stock_delivery_info_tmp2.lot_class%TYPE
     ,line_id                   xxwsh_stock_delivery_info_tmp2.line_id%TYPE
     ,item_id                   xxwsh_stock_delivery_info_tmp2.item_id%TYPE
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
     ,notif_date                xxwsh_stock_delivery_info_tmp2.notif_date%TYPE
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
     ,mov_lot_dtl_id            xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
    ) ;
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER ;
  gt_main_data  tab_main_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
--
  TYPE rec_can_data  IS RECORD
    (
      request_no                xxwsh_stock_delivery_info_tmp2.request_no%TYPE
    ) ;
  TYPE tab_can_data IS TABLE OF rec_can_data INDEX BY BINARY_INTEGER ;
  gt_can_data  tab_can_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
--
  TYPE rec_zero_can_data  IS RECORD
    (
      request_no                xxwsh_stock_delivery_info_tmp2.request_no%TYPE
    ) ;
  TYPE tab_zero_can_data IS TABLE OF rec_zero_can_data INDEX BY BINARY_INTEGER ;
  gt_zero_can_data  tab_zero_can_data ;
--
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
--
  -- 多重起動チェック用 要求ID取得用
  TYPE rec_multi_data  IS RECORD
    (
      request_id        NUMBER(15,0)
    ) ;
  TYPE tab_multi_data IS TABLE OF rec_multi_data INDEX BY BINARY_INTEGER ;
  gt_multi_data  tab_multi_data ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
  --------------------------------------------------
  -- 通知済情報格納用
  --------------------------------------------------
  TYPE t_corporation_name        IS TABLE OF
       xxwsh_stock_delivery_info_tmp.corporation_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_class              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.data_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_transfer_branch_no      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.transfer_branch_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_delivery_no             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_request_no              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.request_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve                 IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.head_sales_branch%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch_name  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.head_sales_branch_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_code      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.shipped_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_name      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.shipped_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_code      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.ship_to_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_name      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.ship_to_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_code    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_name    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.freight_carrier_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to_name         IS TABLE OF
       xxwsh_stock_delivery_info_tmp.deliver_to_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_ship_date      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_arrival_date   IS TABLE OF
       xxwsh_stock_delivery_info_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipping_method_code    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.shipping_method_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_weight                  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.weight%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_mixed_no                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.mixed_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_collected_pallet_qty    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_from       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.arrival_time_from%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_to         IS TABLE OF
       xxwsh_stock_delivery_info_tmp.arrival_time_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_cust_po_number          IS TABLE OF
       xxwsh_stock_delivery_info_tmp.cust_po_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_description             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.description%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_status                  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.status%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_charge_class    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.freight_charge_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_pallet_sum_quantity     IS TABLE OF
       xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve1                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve1%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve2                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve2%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve3                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve3%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve4                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve4%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_report_dept             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.report_dept%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_code               IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_name               IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_uom_code           IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_quantity           IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_no                  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_date                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_best_bfr_date           IS TABLE OF
       xxwsh_stock_delivery_info_tmp.best_bfr_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_sign                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_sign%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_quantity            IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_new_modify_del_class    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.new_modify_del_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_update_date             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.update_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_line_number             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.line_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_type               IS TABLE OF
       xxwsh_stock_delivery_info_tmp.data_type%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_eos_shipped_locat       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_eos_freight_carrier     IS TABLE OF
       xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_eos_csv_output          IS TABLE OF
       xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
  TYPE t_notif_date              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.notif_date%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
  TYPE t_target_request_id       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.target_request_id%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
  gt_corporation_name        t_corporation_name ;
  gt_data_class              t_data_class ;
  gt_transfer_branch_no      t_transfer_branch_no ;
  gt_delivery_no             t_delivery_no ;
  gt_request_no              t_request_no ;
  gt_reserve                 t_reserve ;
  gt_head_sales_branch       t_head_sales_branch ;
  gt_head_sales_branch_name  t_head_sales_branch_name ;
  gt_shipped_locat_code      t_shipped_locat_code ;
  gt_shipped_locat_name      t_shipped_locat_name ;
  gt_ship_to_locat_code      t_ship_to_locat_code ;
  gt_ship_to_locat_name      t_ship_to_locat_name ;
  gt_freight_carrier_code    t_freight_carrier_code ;
  gt_freight_carrier_name    t_freight_carrier_name ;
  gt_deliver_to              t_deliver_to ;
  gt_deliver_to_name         t_deliver_to_name ;
  gt_schedule_ship_date      t_schedule_ship_date ;
  gt_schedule_arrival_date   t_schedule_arrival_date ;
  gt_shipping_method_code    t_shipping_method_code ;
  gt_weight                  t_weight ;
  gt_mixed_no                t_mixed_no ;
  gt_collected_pallet_qty    t_collected_pallet_qty ;
  gt_arrival_time_from       t_arrival_time_from ;
  gt_arrival_time_to         t_arrival_time_to ;
  gt_cust_po_number          t_cust_po_number ;
  gt_description             t_description ;
  gt_status                  t_status ;
  gt_freight_charge_class    t_freight_charge_class ;
  gt_pallet_sum_quantity     t_pallet_sum_quantity ;
  gt_reserve1                t_reserve1 ;
  gt_reserve2                t_reserve2 ;
  gt_reserve3                t_reserve3 ;
  gt_reserve4                t_reserve4 ;
  gt_report_dept             t_report_dept ;
  gt_item_code               t_item_code ;
  gt_item_name               t_item_name ;
  gt_item_uom_code           t_item_uom_code ;
  gt_item_quantity           t_item_quantity ;
  gt_lot_no                  t_lot_no ;
  gt_lot_date                t_lot_date ;
  gt_best_bfr_date           t_best_bfr_date ;
  gt_lot_sign                t_lot_sign ;
  gt_lot_quantity            t_lot_quantity ;
  gt_new_modify_del_class    t_new_modify_del_class ;
  gt_update_date             t_update_date ;
  gt_line_number             t_line_number ;
  gt_data_type               t_data_type ;
  gt_eos_shipped_locat       t_eos_shipped_locat ;
  gt_eos_freight_carrier     t_eos_freight_carrier ;
  gt_eos_csv_output          t_eos_csv_output ;
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
  gt_notif_date              t_notif_date ;
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
  gt_target_request_id       t_target_request_id ;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
  gn_cre_idx    NUMBER := 0 ;
--
  -- 警告メッセージ用配列変数
  TYPE t_worm_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_worm_msg     t_worm_msg ;
  gn_wrm_idx      NUMBER := 0 ;
--
-- ##### 20081023 Ver.1.25 T_S_440対応 START #####
  -- 通知先情報（結果レポート出力用）
  TYPE t_notif_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_notif_msg     t_notif_msg ;
  gn_notif_idx      NUMBER := 0 ;
-- ##### 20081023 Ver.1.25 T_S_440対応 END   #####
--
  /***********************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : パラメータチェック(E-01)
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
    lc_p_name_date_cutoff   CONSTANT VARCHAR2(50) := '締め実施日' ;
    lc_p_name_time_cutoff   CONSTANT VARCHAR2(50) := '締め実施時間' ;
    lc_p_name_date_fix      CONSTANT VARCHAR2(50) := '確定通知実施日' ;
    lc_p_name_time_fix      CONSTANT VARCHAR2(50) := '確定通知実施時間' ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
    lc_p_name_shipdateF     CONSTANT VARCHAR2(50) := '出庫日From' ;
    lc_p_name_shipdateT     CONSTANT VARCHAR2(50) := '出庫日To' ;
    lc_p_name_shipdate      CONSTANT VARCHAR2(50) := '出庫日' ;
    lc_msg_code_03          CONSTANT VARCHAR2(50) := 'APP-XXWSH-11114' ;  -- 日付範囲エラーメッセージ
    lc_tok_name_02          CONSTANT VARCHAR2(50) := 'DATE_NAME' ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
    lc_msg_code_01          CONSTANT VARCHAR2(50) := 'APP-XXWSH-11251' ;  -- 未入力
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
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
    lv_tok_name       VARCHAR2(100) ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_param_error    EXCEPTION ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
    ex_param_error_02 EXCEPTION ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
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
    -- 予定確定区分が「予定」の場合
    -- ====================================================
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
--
-- ##### 20090113 Ver.1.29 本番#971対応 START #####
--      gr_param.date_cutoff := NVL( gr_param.date_cutoff, TO_CHAR( SYSDATE, 'YYYY/MM/DD' ) ) ;
--      gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff ) ;
--      gd_date_from      := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff || gr_param.cutoff_from ) ;
--      gd_date_to        := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff || gr_param.cutoff_to ) ;
--
      -- 締め実施日指定なしの場合
      IF (gr_param.date_cutoff IS NULL) THEN
        gd_effective_date := TRUNC(SYSDATE); -- 基準日(SYSDATE)
        gd_date_from      := gd_min_date;    -- 締め日時FROM
        gd_date_to        := gd_max_date;    -- 締め日時TO
--
      -- 締め実施日指定ありの場合
      ELSE
        gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff ) ;
        gd_date_from      := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff || gr_param.cutoff_from ) ;
        gd_date_to        := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff || gr_param.cutoff_to ) ;
      END IF;
-- ##### 20090113 Ver.1.29 本番#971対応 END   #####
--
      -- ----------------------------------------------------
      -- 逆転チェック
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_02 ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
      lv_tok_name := lc_tok_name ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
      IF ( gd_date_from > gd_date_to ) THEN
        lv_tok_val := lc_p_name_time_cutoff ;
        RAISE ex_param_error ;
      END IF ;
--
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
      -- ----------------------------------------------------
      -- 必須チェック
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_01 ;
      lv_tok_name := lc_tok_name ;
      -- 出庫日From
      IF ( gr_param.ship_date_from IS NULL ) THEN
        lv_tok_val  := lc_p_name_shipdateF ;
        RAISE ex_param_error ;
      END IF ;
--
      -- 出庫日To
      IF ( gr_param.ship_date_to IS NULL ) THEN
        lv_tok_val  := lc_p_name_shipdateT ;
        RAISE ex_param_error ;
      END IF ;
--
      -- 出庫日From
      gd_ship_date_from := FND_DATE.CANONICAL_TO_DATE( gr_param.ship_date_from ) ;
      -- 出庫日To
      gd_ship_date_to   := FND_DATE.CANONICAL_TO_DATE( gr_param.ship_date_to ) ;
--
      -- ----------------------------------------------------
      -- 日付範囲エラーメッセージ
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_03 ;
      lv_tok_name := lc_tok_name_02 ;
      IF ( gd_ship_date_from > gd_ship_date_to ) THEN
        lv_tok_val := lc_p_name_shipdate ;
        RAISE ex_param_error ;
      END IF ;
--
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
--
    -- ====================================================
    -- 予定確定区分が「確定」の場合
    -- ====================================================
    ELSE
      -- ----------------------------------------------------
      -- 必須チェック
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_01 ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
      lv_tok_name := lc_tok_name ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
-- ##### 20090113 Ver.1.29 本番#971対応 START #####
--      -- 確定通知実施日
--      IF ( gr_param.date_fix IS NULL ) THEN
--        lv_tok_val  := lc_p_name_date_fix ;
--        RAISE ex_param_error ;
--      END IF ;
--      gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix ) ;
--      gd_date_from      := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_from ) ;
--      gd_date_to        := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_to ) ;
--
      -- 確定通知実施日指定なしの場合
      IF (gr_param.date_fix IS NULL) THEN
        gd_effective_date := TRUNC(SYSDATE); -- 基準日(SYSDATE)
        gd_date_from      := gd_min_date;    -- 確定通知実施日FROM
        gd_date_to        := gd_max_date;    -- 確定通知実施日TO
      ELSE
        gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix ) ;
        gd_date_from      := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_from ) ;
        gd_date_to        := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_to ) ;
      END IF;
-- ##### 20090113 Ver.1.29 本番#971対応 END   #####
--
      -- ----------------------------------------------------
      -- 逆転チェック
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_02 ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
      lv_tok_name := lc_tok_name ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
      IF ( gd_date_from > gd_date_to ) THEN
        lv_tok_val := lc_p_name_date_fix ;
        RAISE ex_param_error ;
      END IF ;
--
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
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
--                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_name1    => lv_tok_name
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
                     ,iv_token_value1   => lv_tok_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
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
   * Description      : プロファイル取得(E-02)
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
    lc_prof_name    CONSTANT VARCHAR2(50) := 'XXWSH_PURGE_PERIOD_601' ;
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-11953' ;
    lc_tok_name     CONSTANT VARCHAR2(50) := 'PROF_NAME' ;
    lc_tok_val      CONSTANT VARCHAR2(50) := 'XXWSH: 通知済情報パージ処理対象期間_配車配送計画' ;
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
    lc_tok_val2     CONSTANT VARCHAR2(50) := '商品区分（セキュリティ）' ;
    lv_tok_val      VARCHAR2(50);
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
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

-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
  -- ====================================================
  -- 初期処理
  -- ====================================================
  --ファイル名タイムスタンプ取得
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
--  gv_filetimes  := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
    gv_filetimes  := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF1');
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
    -- ====================================================
    -- プロファイル取得
    -- ====================================================
    gn_prof_del_date := FND_PROFILE.VALUE( lc_prof_name ) ;
    IF ( gn_prof_del_date IS NULL ) THEN
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
      lv_tok_val := lc_tok_val;
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
      RAISE ex_prof_error ;
    END IF ;
--
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
    -- 商品区分（セキュリティ）取得
    gv_item_div_security := FND_PROFILE.VALUE(gv_prof_item_div_security);
    IF (gv_item_div_security IS NULL) THEN
      lv_tok_val := lc_tok_val2;
      RAISE ex_prof_error ;
    END IF;
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
--
-- ##### 20090113 Ver.1.29 本番#971対応 START #####
    -- MIN日付
    gd_min_date := TRUNC(SYSDATE) - gn_prof_del_date + 1; -- システム日付 - 通知済情報パージ処理対象期間_配車配送計画 + 1
--
    -- MAX日付
    gd_max_date := TRUNC(SYSDATE) + 2 - 1/24/60/60; -- 翌日の23:59:59
-- ##### 20090113 Ver.1.29 本番#971対応 END   #####
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
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
                     ,iv_token_value1   => lv_tok_val
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
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
--##### 固定例外処理部 END   #######################################################################
  END prc_get_profile ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_multi
   * Description      : 多重起動チェック
   ***********************************************************************************************/
  PROCEDURE prc_chk_multi
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_multi' ; -- プログラム名
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
    lc_msg_code CONSTANT VARCHAR2(50) := 'APP-XXWSH-11901' ;  -- 多重起動
    lc_tok_name CONSTANT VARCHAR2(50) := 'REQ_ID' ;
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
    lv_tkn_val        VARCHAR2(100) ;
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_multi_error     EXCEPTION ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
  -- ==============================================================
  -- コンカレントプログラムIDより起動中の同じプログラムを検索する
  --  以下の条件に全て含まれる場合は多重起動と判断する
  --   ・部署01～10の中で現在起動している部署と同じ部署が存在する
  --   ・確定通知日実施日が同じ
  --   ・確定通知日実施時間のFrom-Toにしての時間が含まれる
  -- ==============================================================
  SELECT request_id
  BULK COLLECT INTO gt_multi_data
  FROM   fnd_concurrent_requests fcr
  WHERE  fcr.phase_code = 'R'           -- 実行中
  -- プログラムIDよりコンカレントIDを取得
  AND  exists (select 'x' 
                FROM  fnd_concurrent_programs fcp1
                    , fnd_concurrent_programs fcp2
                WHERE fcp1.concurrent_program_id = fcr.concurrent_program_id
                AND   fcp1.executable_id         = fcp2.executable_id
                AND   fcp2.concurrent_program_id = gn_program_id        -- コンカレントプログラムID
                )
  -- 部署01
  AND (gr_param.dept_code_01 IN ( fcr.argument1, fcr.argument2, 
                                  fcr.argument3, fcr.argument4, 
                                  fcr.argument5, fcr.argument6, 
                                  fcr.argument7, fcr.argument8, 
                                  fcr.argument9, fcr.argument10)
    -- 部署02（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_02, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署03（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_03, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署04（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_04, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署05（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_05, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署06（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_06, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署07（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_07, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署08（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_08, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署09（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_09, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- 部署10（NULLの場合は 部署01と比較）
    OR NVL(gr_param.dept_code_10, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10))
  -- 予定確定区分
  AND fcr.argument11 = '2'  -- 確定
  -- 確定通知実施日
  AND fcr.argument15 = gv_date_fix
  AND 
    -- 確定通知実施時間From
    (
      ( FND_DATE.STRING_TO_DATE(fcr.argument16, 'HH24:MI') <= FND_DATE.STRING_TO_DATE(gv_fix_from, 'HH24:MI')
    AND FND_DATE.STRING_TO_DATE(fcr.argument17, 'HH24:MI') >= FND_DATE.STRING_TO_DATE(gv_fix_from, 'HH24:MI'))
  OR
    -- 確定通知実施時間To
      ( FND_DATE.STRING_TO_DATE(fcr.argument16, 'HH24:MI') <= FND_DATE.STRING_TO_DATE(gv_fix_to, 'HH24:MI')
    AND FND_DATE.STRING_TO_DATE(fcr.argument17, 'HH24:MI') >= FND_DATE.STRING_TO_DATE(gv_fix_to, 'HH24:MI'))
    )
  -- 自分の要求IDよりも古いものを対象
  AND request_id < gn_request_id
  ;
--
  -- データが存在した場合
  IF ( gt_multi_data.COUNT <> 0 ) THEN
--
    -- 初期設定
    lv_tkn_val := NULL;
--
    <<msg_loop>>
    FOR i IN 1..gt_multi_data.COUNT LOOP
      -- 2つ以上存在する場合は区切り文字に , を付与
      IF ( i > 1 ) THEN
        lv_tkn_val := lv_tkn_val || ',' ;
      END IF;
      -- 要求IDをトークンに格納
      lv_tkn_val := lv_tkn_val || gt_multi_data(i).request_id;
    END LOOP msg_loop;
--
    -- 多重起動エラーとする
    RAISE ex_multi_error;
  END IF;
--
  EXCEPTION
    -- ============================================================================================
    -- 多重起動エラー
    -- ============================================================================================
    WHEN ex_multi_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_value1   => lv_tkn_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
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
--##### 固定例外処理部 END   #######################################################################
  END prc_chk_multi ;
--
  /************************************************************************************************
   * Procedure Name   : prc_del_tmptable_data
   * Description      : テンポラリテーブルデータ削除
   ************************************************************************************************/
  PROCEDURE prc_del_tmptable_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_del_tmptable_data' ; -- プログラム名
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
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
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
    -- データ削除
    -- ====================================================
    -- 要求IDをキーに削除
    DELETE FROM xxwsh_stock_delivery_info_tmp  
    WHERE target_request_id = gn_request_id;
--
    -- 要求IDをキーに削除
    DELETE FROM xxwsh_stock_delivery_info_tmp2 
    WHERE target_request_id = gn_request_id;
--
  EXCEPTION
--
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_del_tmptable_data ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
  /************************************************************************************************
   * Procedure Name   : prc_del_temp_data
   * Description      : データ削除(E-03)
   ************************************************************************************************/
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
    -- 入出庫配送計画情報中間テーブル
    ----------------------------------------
    CURSOR cu_del_table_01
    IS
      SELECT xsdit.request_no
      FROM xxwsh_stock_delivery_info_tmp xsdit
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
      WHERE  xsdit.notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FOR UPDATE NOWAIT
    ;
    ----------------------------------------
    -- データ抽出用中間テーブル
    ----------------------------------------
    CURSOR cu_del_table_02
    IS
      SELECT xsdit2.request_no
      FROM xxwsh_stock_delivery_info_tmp2 xsdit2
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
      WHERE xsdit2.notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FOR UPDATE NOWAIT
    ;
    ----------------------------------------
    -- 通知済入出庫配送計画情報（アドオン）
    ----------------------------------------
    CURSOR cu_del_table_03
    IS
      SELECT xndi.request_no
      FROM xxwsh_notif_delivery_info xndi
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      WHERE TRUNC( xndi.last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date
      WHERE  xndi.last_update_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1
-- 2008/09/01 v1.16 update Y.Yamamoto end
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
    <<get_lock_03>>
    FOR re_del_table_03 IN cu_del_table_03 LOOP
      EXIT ;
    END LOOP get_lock_03 ;
--
    -- ====================================================
    -- データ削除
    -- ====================================================
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
/*****
    DELETE FROM xxwsh_stock_delivery_info_tmp ;
    DELETE FROM xxwsh_stock_delivery_info_tmp2 ;
*****/
    -- 確定通知日時のパージ日数以前を削除
    DELETE FROM xxwsh_stock_delivery_info_tmp  
    WHERE  notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1 ;
--
    -- 確定通知日時のパージ日数以前を削除
    DELETE FROM xxwsh_stock_delivery_info_tmp2 
    WHERE  notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1 ;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
    DELETE FROM xxwsh_notif_delivery_info
-- 2008/09/01 v1.16 update Y.Yamamoto start
--    WHERE TRUNC( last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date ;
    WHERE  last_update_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1 ;
-- 2008/09/01 v1.16 update Y.Yamamoto end
--
  EXCEPTION
    -- =============================================================================================
    -- ロック取得エラー
    -- =============================================================================================
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
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_del_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_table
   * Description      : 中間テーブル登録
   ************************************************************************************************/
  PROCEDURE prc_ins_temp_table
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_temp_table' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ==================================================
    -- 変数定義
    -- ==================================================
    lv_cnt    NUMBER := 0 ;
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
    -- 中間テーブル登録
    -- ====================================================
-- 2008/09/01 v1.16 update Y.Yamamoto start
    -- ====================================================
    -- パフォーマンス対応のため、1つのSQLを予定確定区分ごとに分割
    -- 予定確定区分が「予定」の場合
    -- ====================================================
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
--
    INSERT INTO xxwsh_stock_delivery_info_tmp2
      -- ===========================================================================================
      -- 出荷データＳＱＬ
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:明細番号
            ,xola.order_line_id                       -- 02:明細ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:明細削除フラグ
            ,xoha.req_status                          -- 04:ステータス
            ,xoha.notif_status                        -- 05:通知ステータス
            ,xoha.prev_notif_status                   -- 06:前回通知ステータス
            ,CASE
               WHEN xoha.req_status = gc_req_status_syu_5 THEN gc_data_type_syu_can
               ELSE gc_data_type_syu_ins
             END                                      -- 07:データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
            ,NULL                                     -- XX:EOS宛先（入庫倉庫）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
            ,xil.eos_detination                       -- 08:EOS宛先（出庫倉庫）
            ,xc.eos_detination                        -- 09:EOS宛先（運送業者）
            ,xoha.delivery_no                         -- 10:配送No
            ,xoha.request_no                          -- 11:依頼No
            --,xp.party_number                          -- 12:拠点コード   -- 2008/09/10 参照View変更 Del
            --,xp.party_name                            -- 13:管轄拠点名称 -- 2008/09/10 参照View変更 Del
            ,xca.party_number                         -- 12:拠点コード     -- 2008/09/10 参照View変更 Add
            ,xca.party_name                           -- 13:管轄拠点名称   -- 2008/09/10 参照View変更 Add
            ,xil.segment1                             -- 14:出庫倉庫コード
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:出庫倉庫名称
            ,NULL                                     -- 16:入庫倉庫コード
            ,NULL                                     -- 17:入庫倉庫名称
            ,xc.party_number                          -- 18:運送業者コード
            ,xc.party_name                            -- 19:運送業者名
            --,xps.party_site_number                    -- 20:配送先コード  -- 2008/09/10 参照View変更 Del
            --,xps.party_site_full_name                 -- 21:配送先名      -- 2008/09/10 参照View変更 Del
            ,xcas.party_site_number                   -- 20:配送先コード    -- 2008/09/10 参照View変更 Add
            ,xcas.party_site_full_name                -- 21:配送先名        -- 2008/09/10 参照View変更 Add
            ,xoha.schedule_ship_date                  -- 22:発日
            ,xoha.schedule_arrival_date               -- 23:着日
            ,xlv.lookup_code                          -- 24:配送区分
            ,CASE
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6              = gc_small_method_y THEN xoha.sum_weight      --2008/08/12 Del 課題#48(変更#164)
               AND  xlv.attribute6              = gc_small_method_y THEN NVL(xoha.sum_weight,0) --2008/08/12 Add 課題#48(変更#164)
-- M.HOKKANJI Ver1.2 START
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xoha.sum_weight,0)
                                                                      + NVL(xoha.sum_pallet_weight,0)
--               AND  xlv.attribute6             <> gc_small_method_y THEN xoha.sum_weight
--                                                                      + xoha.sum_pallet_weight
-- M.HOKKANJI Ver1.2 END
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN xoha.sum_capacity      --2008/08/12 Del 課題#48(変更#164)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN NVL(xoha.sum_capacity,0) --2008/08/12 Add 課題#48(変更#164)
             END                                      -- 25:重量／容積
            ,xoha.mixed_no                            -- 26:混載元依頼No
            ,xoha.collected_pallet_qty                -- 27:ﾊﾟﾚｯﾄ回収枚数
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:運賃区分
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:着荷時間指定From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:着荷時間指定To
            ,xoha.cust_po_number                      -- 31:顧客発注番号
            ,xoha.shipping_instructions               -- 32:摘要
            ,xoha.pallet_sum_quantity                 -- 33:ﾊﾟﾚｯﾄ使用枚数（出）
            ,NULL                                     -- 34:ﾊﾟﾚｯﾄ使用枚数（入）
            ,xoha.instruction_dept                    -- 35:報告部署
            ,xic.prod_class_code                      -- 36:商品区分
            ,xic.item_class_code                      -- 37:品目区分
            ,xim.item_no                              -- 38:品目コード
            ,xim.item_id                              -- 39:品目ID
            ,xim.item_name                            -- 40:品目名
            ,xim.item_um                              -- 41:単位
            ,xim.conv_unit                            -- 42:入出庫換算単位
-- ##### 20081127 Ver.1.28 本番177対応 START #####
--            ,xola.quantity                            -- 43:数量
            ,CASE
               WHEN xoha.req_status = gc_req_status_syu_5 THEN 0
               ELSE xola.quantity                       -- 43:数量
             END                                      -- 07:データタイプ
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
            ,xim.num_of_cases                         -- 44:ケース入数
            ,xim.lot_ctl                              -- 45:ロット使用
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xoha.notif_date                          --   :確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
            ,gn_request_id                            --   :要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,oe_transaction_types_all   otta      -- 受注タイプ
          ,xxcmn_item_locations_v     xil       -- OPM保管場所情報VIEW
          ,xxcmn_carriers2_v          xc        -- 運送業者情報VIEW2
          --,xxcmn_party_sites2_v       xps       -- パーティサイト情報VIEW2（配送先）-- 2008/09/10 参照View変更 Del
          ,xxcmn_cust_acct_sites2_v   xcas      -- 顧客サイト情報VIEW2                -- 2008/09/10 参照View変更 Add
          --,xxcmn_parties2_v           xp        -- パーティ情報VIEW2（拠点）        -- 2008/09/10 参照View変更 Del
          ,xxcmn_cust_accounts2_v     xca       -- 顧客情報VIEW2                      -- 2008/09/10 参照View変更 Add
          ,xxwsh_carriers_schedule    xcs       -- 配車配送計画アドオン
          ,xxcmn_lookup_values2_v     xlv       -- クイックコード情報VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM品目情報VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM品目カテゴリ割当VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM品目カテゴリ割当VIEW5
          ,(SELECT distinct xtc.concurrent_id
              FROM xxwsh_tightening_control xtc
             WHERE xtc.tightening_date BETWEEN gd_date_from
                                           AND gd_date_to
           ) xtci
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- 品目
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- 受注明細
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
-- ##### 20081127 Ver.1.28 本番177対応 START #####
-- 削除フラグの条件はここではしない
--      AND   xola.delete_flag     = gc_yes_no_n    -- 削除フラグ = N
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
      ----------------------------------------------------------------------------------------------
      -- 配送配車計画
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
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
      -- 2008/09/10 参照View変更 Del End --------------------------------
      -- 2008/09/10 参照View変更 Add Start --------------------------------
      AND   xcas.base_code      = xca.party_number
      AND   gd_effective_date  BETWEEN xcas.start_date_active
                               AND     NVL( xcas.end_date_active, gd_effective_date )
-- ##### 2009/04/23 Ver.1.32 本番#1398対応 START #####
--      AND   xoha.deliver_to_id = xcas.party_site_id
      AND   xoha.deliver_to        = xcas.party_site_number  -- IDは付け替わる可能性があるので、コードで参照
      AND   xcas.party_site_status = gc_status_active        -- サイトステータスが有効なもの
-- ##### 2009/04/23 Ver.1.32 本番#1398対応 END   #####
      -- 2008/09/10 参照View変更 Add End --------------------------------
      ----------------------------------------------------------------------------------------------
      -- 運送業者
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- 保管場所
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/***** EOS宛先による条件削除
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS業者
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 受注タイプ
      AND   otta.attribute1    = gc_sp_class_ship     -- 出荷依頼
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      AND   xoha.latest_external_flag = gc_yes_no_y             -- 最新
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
      AND   xoha.prod_class           = gv_item_div_security    -- 商品区分（セキュリティ）
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
      AND   xoha.req_status           IN( gc_req_status_syu_3   -- 締め済
                                         ,gc_req_status_syu_5 ) -- 取消
-- ##### 20090113 Ver.1.29 本番#971対応 START #####
      AND   xoha.schedule_ship_date BETWEEN gd_ship_date_from AND gd_ship_date_to -- 出庫日From To
-- ##### 20090113 Ver.1.29 本番#971対応 END   #####
-- M.HOKKANJI Ver1.9 START
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND  ((gr_param.fix_class = gc_fix_class_y
--              AND EXISTS ( SELECT xic.concurrent_id
--                             FROM xxwsh_tightening_control xic
--                            WHERE xic.concurrent_id = xoha.tightening_program_id
--                              AND xic.tightening_date BETWEEN gd_date_from
--                                                          AND gd_date_to
--                         )
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
      AND   xoha.tightening_program_id = xtci.concurrent_id
-- 2008/09/01 v1.16 update Y.Yamamoto end
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- 支給データＳＱＬ
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:明細番号
            ,xola.order_line_id                       -- 02:明細ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:明細削除フラグ
            ,xoha.req_status                          -- 04:ステータス
            ,xoha.notif_status                        -- 05:通知ステータス
            ,xoha.prev_notif_status                   -- 06:前回通知ステータス
            ,CASE
               WHEN xoha.req_status = gc_req_status_shi_5 THEN gc_data_type_shi_can
               ELSE gc_data_type_shi_ins
             END                                      -- 07:データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
            ,NULL                                     -- XX:EOS宛先（入庫倉庫）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
            ,xil.eos_detination                       -- 08:EOS宛先（出庫倉庫）
            ,xc.eos_detination                        -- 09:EOS宛先（運送業者）
            ,xoha.delivery_no                         -- 10:配送No
            ,xoha.request_no                          -- 11:依頼No
            ,NULL                                     -- 12:拠点コード
            ,NULL                                     -- 13:管轄拠点名称
            ,xil.segment1                             -- 14:出庫倉庫コード
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:出庫倉庫名称
            ,NULL                                     -- 16:入庫倉庫コード
            ,NULL                                     -- 17:入庫倉庫名称
            ,xc.party_number                          -- 18:運送業者コード
            ,xc.party_name                            -- 19:運送業者名
            ,xvs.vendor_site_code                     -- 20:配送先コード
            ,xvs.vendor_site_name                     -- 21:配送先名
            ,xoha.schedule_ship_date                  -- 22:発日
            ,xoha.schedule_arrival_date               -- 23:着日
            ,xlv.lookup_code                          -- 24:配送区分
            ,CASE
               --2008/08/12 Start 課題#48(変更#164) ----------------------------------------------
               --WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN xoha.sum_weight
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN xoha.sum_capacity
               WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN NVL(xoha.sum_weight,0)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN NVL(xoha.sum_capacity,0)
               --2008/08/12 End 課題#48(変更#164) ------------------------------------------------
             END                                      -- 25:重量／容積
            ,xoha.mixed_no                            -- 26:混載元依頼No
            ,xoha.collected_pallet_qty                -- 27:ﾊﾟﾚｯﾄ回収枚数
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:運賃区分
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:着荷時間指定From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:着荷時間指定To
            ,xoha.cust_po_number                      -- 31:顧客発注番号
            ,xoha.shipping_instructions               -- 32:摘要
            ,xoha.pallet_sum_quantity                 -- 33:ﾊﾟﾚｯﾄ使用枚数（出）
            ,NULL                                     -- 34:ﾊﾟﾚｯﾄ使用枚数（入）
            ,xoha.instruction_dept                    -- 35:報告部署
            ,xic.prod_class_code                      -- 36:商品区分
            ,xic.item_class_code                      -- 37:品目区分
            ,xim.item_no                              -- 38:品目コード
            ,xim.item_id                              -- 39:品目ID
            ,xim.item_name                            -- 40:品目名
            ,xim.item_um                              -- 41:単位
            ,xim.conv_unit                            -- 42:入出庫換算単位
-- ##### 20081127 Ver.1.28 本番177対応 START #####
            ,CASE
               WHEN xoha.req_status = gc_req_status_shi_5 THEN 0
               ELSE xola.quantity                     -- 43:数量
             END                                      -- 07:データタイプ
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
            ,xim.num_of_cases                         -- 44:ケース入数
            ,xim.lot_ctl                              -- 45:ロット使用
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xoha.notif_date                          --   :確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
            ,gn_request_id                            --   :要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,oe_transaction_types_all   otta      -- 受注タイプ
          ,xxcmn_item_locations_v     xil       -- OPM保管場所情報VIEW
          ,xxcmn_carriers2_v          xc        -- 運送業者情報VIEW2
          ,xxcmn_vendor_sites_v       xvs       -- 仕入先サイト情報VIEW2
          ,xxwsh_carriers_schedule    xcs       -- 配車配送計画アドオン
          ,xxcmn_lookup_values2_v     xlv       -- クイックコード情報VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM品目情報VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM品目カテゴリ割当VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM品目カテゴリ割当VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- 品目
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- 受注明細
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
-- ##### 20081127 Ver.1.28 本番177対応 START #####
-- 削除フラグの条件はここではしない
--      AND   xola.delete_flag     = gc_yes_no_n      -- 削除フラグ = N
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
      ----------------------------------------------------------------------------------------------
      -- 配送配車計画
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- 配送先
      AND   gd_effective_date   BETWEEN xvs.start_date_active
                                AND     NVL( xvs.end_date_active, gd_effective_date )
      AND   xoha.vendor_site_id = xvs.vendor_site_id
      ----------------------------------------------------------------------------------------------
      -- 運送業者
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- 保管場所
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/***** EOS宛先による条件削除
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS業者
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 受注タイプ
      AND   otta.attribute1    = gc_sp_class_prov     -- 支給依頼
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      AND   xoha.latest_external_flag = gc_yes_no_y             -- 最新
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
      AND   xoha.prod_class           = gv_item_div_security    -- 商品区分（セキュリティ）
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
      AND   xoha.req_status           IN( gc_req_status_shi_3   -- 受領済
                                         ,gc_req_status_shi_5 ) -- 取消
--
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
      ----------------------------------------------------------------------------------------------
      -- 出庫日From To
      AND   xoha.schedule_ship_date BETWEEN gd_ship_date_from AND gd_ship_date_to
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
--
-- M.HOKKANJI Ver1.9 START
-- 2008/09/01 v1.16 delete Y.Yamamoto start
      -- パラメータが確定の場合のみ日付を参照
--      AND  ((gr_param.fix_class = gc_fix_class_y
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
-- 2008/09/01 v1.16 delete Y.Yamamoto end
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- 移動データＳＱＬ
      -- ===========================================================================================
      SELECT xmril.line_number                        -- 01:明細番号
            ,xmril.mov_line_id                        -- 02:明細ID
            ,CASE
               WHEN xmril.delete_flg = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:明細削除フラグ
            ,xmrih.status                             -- 04:ステータス
            ,xmrih.notif_status                       -- 05:通知ステータス
            ,xmrih.prev_notif_status                  -- 06:前回通知ステータス
            ,CASE
               WHEN xmrih.status = gc_req_status_syu_5 THEN gc_data_type_mov_can
               ELSE gc_data_type_mov_ins
             END                                      -- 07:データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
            ,xil2.eos_detination                      -- XX:EOS宛先（入庫倉庫）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
            ,xil1.eos_detination                      -- 08:EOS宛先（出庫倉庫）
            ,xc.eos_detination                        -- 09:EOS宛先（運送業者）
            ,xmrih.delivery_no                        -- 10:配送No
            ,xmrih.mov_num                            -- 11:依頼No
            ,NULL                                     -- 12:拠点コード
            ,NULL                                     -- 13:管轄拠点名称
            ,xil1.segment1                            -- 14:出庫倉庫コード
            ,SUBSTRB( xil1.description, 1, 20 )       -- 15:出庫倉庫名称
            ,xil2.segment1                            -- 16:入庫倉庫コード
            ,SUBSTRB( xil2.description, 1, 20 )       -- 17:入庫倉庫名称
            ,xc.party_number                          -- 18:運送業者コード
            ,xc.party_name                            -- 19:運送業者名
            ,NULL                                     -- 20:配送先コード
            ,NULL                                     -- 21:配送先名
            ,xmrih.schedule_ship_date                 -- 22:発日
            ,xmrih.schedule_arrival_date              -- 23:着日
            ,xlv.lookup_code                          -- 24:配送区分
            ,CASE
-- M.HOKKANJI Ver1.2 START
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6               = gc_small_method_y THEN xmrih.sum_weight      --2008/08/12 Del 課題#48(変更#164)
               AND  xlv.attribute6               = gc_small_method_y THEN NVL(xmrih.sum_weight,0) --2008/08/12 Add 課題#48(変更#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xmrih.sum_weight,0)
                                                                    + NVL(xmrih.sum_pallet_weight,0)
                                                                    
               --WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity      --2008/08/12 Del 課題#48(変更#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN NVL(xmrih.sum_capacity,0) --2008/08/12 Add 課題#48(変更#164)
/*
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6               = gc_wc_class_j THEN xmrih.sum_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6              <> gc_wc_class_j THEN xmrih.sum_weight
                                                                    + xmrih.sum_pallet_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity
*/
-- M.HOKKANJI Ver1.2 END
             END                                      -- 25:重量／容積
            ,NULL                                     -- 26:混載元依頼No
            ,xmrih.collected_pallet_qty               -- 27:ﾊﾟﾚｯﾄ回収枚数
            ,CASE
               WHEN xmrih.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END                                                -- 28:運賃区分
            ,NVL( xmrih.arrival_time_from, gc_time_default )    -- 29:着荷時間指定From
            ,NVL( xmrih.arrival_time_to  , gc_time_default )    -- 30:着荷時間指定To
            ,NULL                                     -- 31:顧客発注番号
            ,xmrih.description                        -- 32:摘要
            --,xmrih.out_pallet_qty                     -- 33:ﾊﾟﾚｯﾄ使用枚数（出） -- 2008/09/09 TE080_600指摘#30 Del
            --,xmrih.in_pallet_qty                      -- 34:ﾊﾟﾚｯﾄ使用枚数（入） -- 2008/09/09 TE080_600指摘#30 Del
            ,xmrih.pallet_sum_quantity                  -- 33:ﾊﾟﾚｯﾄ使用枚数（出） -- 2008/09/09 TE080_600指摘#30 Add
            ,xmrih.pallet_sum_quantity                  -- 34:ﾊﾟﾚｯﾄ使用枚数（入） -- 2008/09/09 TE080_600指摘#30 Add
            ,xmrih.instruction_post_code              -- 35:報告部署
            ,xic.prod_class_code                      -- 36:商品区分
            ,xic.item_class_code                      -- 37:品目区分
            ,xim.item_no                              -- 38:品目コード
            ,xim.item_id                              -- 39:品目ID
            ,xim.item_name                            -- 40:品目名
            ,xim.item_um                              -- 41:単位
            ,xim.conv_unit                            -- 42:入出庫換算単位
-- ##### 20081127 Ver.1.28 本番177対応 START #####
            ,CASE
               WHEN xmrih.status = gc_req_status_syu_5 THEN 0
               ELSE xmril.instruct_qty                       -- 43:数量
             END                                      -- 07:データタイプ
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
            ,xim.num_of_cases                         -- 44:ケース入数
            ,xim.lot_ctl                              -- 45:ロット使用
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xmrih.notif_date                         --   :確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
            ,gn_request_id                            --   :要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FROM xxinv_mov_req_instr_headers    xmrih     -- 移動依頼指示ヘッダアドオン
          ,xxinv_mov_req_instr_lines      xmril     -- 移動依頼指示明細アドオン
          ,xxcmn_item_locations_v         xil1      -- OPM保管場所情報VIEW（配送元）
          ,xxcmn_item_locations_v         xil2      -- OPM保管場所情報VIEW（配送先）
          ,xxcmn_carriers2_v              xc        -- 運送業者情報VIEW2
          ,xxwsh_carriers_schedule        xcs       -- 配車配送計画アドオン
          ,xxcmn_lookup_values2_v         xlv       -- クイックコード情報VIEW2
          ,xxcmn_item_mst2_v              xim       -- OPM品目情報VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM品目カテゴリ割当VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM品目カテゴリ割当VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- 品目
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xmril.item_id           = xim.item_id
      ----------------------------------------------------------------------------------------------
      -- 移動依頼指示明細
      AND   xmrih.mov_hdr_id = xmril.mov_hdr_id
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
-- ##### 20081127 Ver.1.28 本番177対応 START #####
-- 削除フラグの条件はここではしない
--      AND   xmril.delete_flg = gc_yes_no_n          -- 削除フラグ = N
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
      ----------------------------------------------------------------------------------------------
      -- 配送配車計画
-- M.HOKKANJI Ver1.2 START
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date)
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xmrih.delivery_no = xcs.delivery_no(+)
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xmrih.delivery_no = xcs.delivery_no
*/
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- 運送業者
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xmrih.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
/***
      -- 保管場所（配送先）
      AND   xil2.eos_control_type  = gc_manage_eos_y    -- EOS業者
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 保管場所（配送元）
      AND   xil1.eos_control_type  = gc_manage_eos_y    -- EOS業者
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
***/
      -- 保管場所（配送先）
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 保管場所（配送元）
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/***** EOS宛先による条件削除
      AND   (xil1.eos_control_type  = gc_manage_eos_y   -- EOS業者（配送先）
          OR xil2.eos_control_type  = gc_manage_eos_y)  -- EOS業者（配送元）
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
      -- 移動依頼指示ヘッダ
      AND   xmrih.mov_type    = gc_mov_type_y           -- 積送あり
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
      AND   xmrih.item_class  = gv_item_div_security    -- 商品区分（セキュリティ）
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
      AND   xmrih.status      IN( gc_mov_status_cmp     -- 依頼済
                                 ,gc_mov_status_adj     -- 調整中
                                 ,gc_mov_status_ccl )   -- 取消
      ---- パラメータが「実績」の場合のみ
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, gd_date_from
--                                      , gc_fix_class_k, xmrih.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
      AND   gd_date_from BETWEEN gd_date_from
                             AND gd_date_to
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
      ----------------------------------------------------------------------------------------------
      -- 出庫日From To
      AND   xmrih.schedule_ship_date BETWEEN gd_ship_date_from AND gd_ship_date_to
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
-- 2008/09/01 v1.16 update Y.Yamamoto end
      ;
    -- ====================================================
    -- 予定確定区分が「確定」の場合
    -- ====================================================
    ELSIF ( gr_param.fix_class = gc_fix_class_k ) THEN
    INSERT INTO xxwsh_stock_delivery_info_tmp2
      -- ===========================================================================================
      -- 出荷データＳＱＬ
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:明細番号
            ,xola.order_line_id                       -- 02:明細ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:明細削除フラグ
            ,xoha.req_status                          -- 04:ステータス
            ,xoha.notif_status                        -- 05:通知ステータス
            ,xoha.prev_notif_status                   -- 06:前回通知ステータス
            ,CASE
               WHEN xoha.req_status = gc_req_status_syu_5 THEN gc_data_type_syu_can
               ELSE gc_data_type_syu_ins
             END                                      -- 07:データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
            ,NULL                                     -- XX:EOS宛先（入庫倉庫）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
            ,xil.eos_detination                       -- 08:EOS宛先（出庫倉庫）
            ,xc.eos_detination                        -- 09:EOS宛先（運送業者）
            ,xoha.delivery_no                         -- 10:配送No
            ,xoha.request_no                          -- 11:依頼No
            --,xp.party_number                          -- 12:拠点コード   -- 2008/09/10 参照View変更 Del
            --,xp.party_name                            -- 13:管轄拠点名称 -- 2008/09/10 参照View変更 Del
            ,xca.party_number                          -- 12:拠点コード    -- 2008/09/10 参照View変更 Add
            ,xca.party_name                            -- 13:管轄拠点名称  -- 2008/09/10 参照View変更 Add
            ,xil.segment1                             -- 14:出庫倉庫コード
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:出庫倉庫名称
            ,NULL                                     -- 16:入庫倉庫コード
            ,NULL                                     -- 17:入庫倉庫名称
            ,xc.party_number                          -- 18:運送業者コード
            ,xc.party_name                            -- 19:運送業者名
            --,xps.party_site_number                    -- 20:配送先コード -- 2008/09/10 参照View変更 Del
            --,xps.party_site_full_name                 -- 21:配送先名     -- 2008/09/10 参照View変更 Del
            ,xcas.party_site_number                   -- 20:配送先コード   -- 2008/09/10 参照View変更 Add
            ,xcas.party_site_full_name                -- 21:配送先名       -- 2008/09/10 参照View変更 Add
            ,xoha.schedule_ship_date                  -- 22:発日
            ,xoha.schedule_arrival_date               -- 23:着日
            ,xlv.lookup_code                          -- 24:配送区分
            ,CASE
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6              = gc_small_method_y THEN xoha.sum_weight      --2008/08/12 Del 課題#48(変更#164)
               AND  xlv.attribute6              = gc_small_method_y THEN NVL(xoha.sum_weight,0) --2008/08/12 Add 課題#48(変更#164)
-- M.HOKKANJI Ver1.2 START
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xoha.sum_weight,0)
                                                                      + NVL(xoha.sum_pallet_weight,0)
--               AND  xlv.attribute6             <> gc_small_method_y THEN xoha.sum_weight
--                                                                      + xoha.sum_pallet_weight
-- M.HOKKANJI Ver1.2 END
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN xoha.sum_capacity      --2008/08/12 Del 課題#48(変更#164)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN NVL(xoha.sum_capacity,0) --2008/08/12 Add 課題#48(変更#164)
             END                                      -- 25:重量／容積
            ,xoha.mixed_no                            -- 26:混載元依頼No
            ,xoha.collected_pallet_qty                -- 27:ﾊﾟﾚｯﾄ回収枚数
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:運賃区分
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:着荷時間指定From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:着荷時間指定To
            ,xoha.cust_po_number                      -- 31:顧客発注番号
            ,xoha.shipping_instructions               -- 32:摘要
            ,xoha.pallet_sum_quantity                 -- 33:ﾊﾟﾚｯﾄ使用枚数（出）
            ,NULL                                     -- 34:ﾊﾟﾚｯﾄ使用枚数（入）
            ,xoha.instruction_dept                    -- 35:報告部署
            ,xic.prod_class_code                      -- 36:商品区分
            ,xic.item_class_code                      -- 37:品目区分
            ,xim.item_no                              -- 38:品目コード
            ,xim.item_id                              -- 39:品目ID
            ,xim.item_name                            -- 40:品目名
            ,xim.item_um                              -- 41:単位
            ,xim.conv_unit                            -- 42:入出庫換算単位
-- ##### 20081127 Ver.1.28 本番177対応 START #####
            ,CASE
               WHEN xoha.req_status = gc_req_status_syu_5 THEN 0
               ELSE xola.quantity                            -- 43:数量
             END                                      -- 07:データタイプ
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
            ,xim.num_of_cases                         -- 44:ケース入数
            ,xim.lot_ctl                              -- 45:ロット使用
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xoha.notif_date                          --   :確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
            ,gn_request_id                            --   :要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,oe_transaction_types_all   otta      -- 受注タイプ
          ,xxcmn_item_locations_v     xil       -- OPM保管場所情報VIEW
          ,xxcmn_carriers2_v          xc        -- 運送業者情報VIEW2
          --,xxcmn_party_sites2_v       xps       -- パーティサイト情報VIEW2（配送先）-- 2008/09/10 参照View変更 Del
          ,xxcmn_cust_acct_sites2_v   xcas      -- 顧客サイト情報VIEW2                -- 2008/09/10 参照View変更 Add
          --,xxcmn_parties2_v           xp        -- パーティ情報VIEW2（拠点）        -- 2008/09/10 参照View変更 Del
          ,xxcmn_cust_accounts2_v     xca       -- 顧客情報VIEW2                      -- 2008/09/10 参照View変更 Add
          ,xxwsh_carriers_schedule    xcs       -- 配車配送計画アドオン
          ,xxcmn_lookup_values2_v     xlv       -- クイックコード情報VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM品目情報VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM品目カテゴリ割当VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM品目カテゴリ割当VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- 品目
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- 受注明細
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
-- ##### 20081127 Ver.1.28 本番177対応 START #####
-- 削除フラグの条件はここではしない
--      AND   xola.delete_flag     = gc_yes_no_n      -- 削除フラグ = N
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
      ----------------------------------------------------------------------------------------------
      -- 配送配車計画
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- 配送先
      --AND   gd_effective_date  BETWEEN xp.start_date_active                         -- 2008/09/10 参照View変更 Del
      --                         AND     NVL( xp.end_date_active, gd_effective_date ) -- 2008/09/10 参照View変更 Del
      AND   gd_effective_date  BETWEEN xca.start_date_active                          -- 2008/09/10 参照View変更 Add
                               AND     NVL( xca.end_date_active, gd_effective_date )  -- 2008/09/10 参照View変更 Add
      -- 2008/09/10 参照View変更 Del Start ----------------------------------
      --AND   xps.base_code      = xp.party_number
      --AND   gd_effective_date  BETWEEN xps.start_date_active
      --                         AND     NVL( xps.end_date_active, gd_effective_date )
      --AND   xoha.deliver_to_id = xps.party_site_id
      -- 2008/09/10 参照View変更 Del End ----------------------------------
      -- 2008/09/10 参照View変更 Add Start ----------------------------------
      AND   xcas.base_code      = xca.party_number
      AND   gd_effective_date  BETWEEN xcas.start_date_active
                               AND     NVL( xcas.end_date_active, gd_effective_date )
-- ##### 2009/04/23 Ver.1.32 本番#1398対応 START #####
--      AND   xoha.deliver_to_id = xcas.party_site_id
      AND   xoha.deliver_to        = xcas.party_site_number  -- IDは付け替わる可能性があるので、コードで参照
      AND   xcas.party_site_status = gc_status_active        -- サイトステータスが有効なもの
-- ##### 2009/04/23 Ver.1.32 本番#1398対応 END   #####
      -- 2008/09/10 参照View変更 Add End ----------------------------------
      ----------------------------------------------------------------------------------------------
      -- 運送業者
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- 保管場所
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/***** EOS宛先による条件削除
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS業者
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 受注タイプ
      AND   otta.attribute1    = gc_sp_class_ship     -- 出荷依頼
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      AND   xoha.latest_external_flag = gc_yes_no_y             -- 最新
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
      AND   xoha.prod_class           = gv_item_div_security    -- 商品区分（セキュリティ）
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
      AND   xoha.req_status           IN( gc_req_status_syu_3   -- 締め済
                                         ,gc_req_status_syu_5 ) -- 取消
-- M.HOKKANJI Ver1.9 START
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND  ((gr_param.fix_class = gc_fix_class_y
--              AND EXISTS ( SELECT xic.concurrent_id
--                             FROM xxwsh_tightening_control xic
--                            WHERE xic.concurrent_id = xoha.tightening_program_id
--                              AND xic.tightening_date BETWEEN gd_date_from
--                                                          AND gd_date_to
--                         )
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
      AND xoha.notif_date BETWEEN gd_date_from
                              AND gd_date_to
-- 2008/09/01 v1.16 update Y.Yamamoto end
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- 支給データＳＱＬ
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:明細番号
            ,xola.order_line_id                       -- 02:明細ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:明細削除フラグ
            ,xoha.req_status                          -- 04:ステータス
            ,xoha.notif_status                        -- 05:通知ステータス
            ,xoha.prev_notif_status                   -- 06:前回通知ステータス
            ,CASE
               WHEN xoha.req_status = gc_req_status_shi_5 THEN gc_data_type_shi_can
               ELSE gc_data_type_shi_ins
             END                                      -- 07:データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
            ,NULL                                     -- XX:EOS宛先（入庫倉庫）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
            ,xil.eos_detination                       -- 08:EOS宛先（出庫倉庫）
            ,xc.eos_detination                        -- 09:EOS宛先（運送業者）
            ,xoha.delivery_no                         -- 10:配送No
            ,xoha.request_no                          -- 11:依頼No
            ,NULL                                     -- 12:拠点コード
            ,NULL                                     -- 13:管轄拠点名称
            ,xil.segment1                             -- 14:出庫倉庫コード
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:出庫倉庫名称
            ,NULL                                     -- 16:入庫倉庫コード
            ,NULL                                     -- 17:入庫倉庫名称
            ,xc.party_number                          -- 18:運送業者コード
            ,xc.party_name                            -- 19:運送業者名
            ,xvs.vendor_site_code                     -- 20:配送先コード
            ,xvs.vendor_site_name                     -- 21:配送先名
            ,xoha.schedule_ship_date                  -- 22:発日
            ,xoha.schedule_arrival_date               -- 23:着日
            ,xlv.lookup_code                          -- 24:配送区分
            ,CASE
               --2008/08/12 Start 課題#48(変更#164) ----------------------------------------------
               --WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN xoha.sum_weight
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN xoha.sum_capacity
               WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN NVL(xoha.sum_weight,0)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN NVL(xoha.sum_capacity,0)
               --2008/08/12 End 課題#48(変更#164) ------------------------------------------------
             END                                      -- 25:重量／容積
            ,xoha.mixed_no                            -- 26:混載元依頼No
            ,xoha.collected_pallet_qty                -- 27:ﾊﾟﾚｯﾄ回収枚数
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:運賃区分
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:着荷時間指定From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:着荷時間指定To
            ,xoha.cust_po_number                      -- 31:顧客発注番号
            ,xoha.shipping_instructions               -- 32:摘要
            ,xoha.pallet_sum_quantity                 -- 33:ﾊﾟﾚｯﾄ使用枚数（出）
            ,NULL                                     -- 34:ﾊﾟﾚｯﾄ使用枚数（入）
            ,xoha.instruction_dept                    -- 35:報告部署
            ,xic.prod_class_code                      -- 36:商品区分
            ,xic.item_class_code                      -- 37:品目区分
            ,xim.item_no                              -- 38:品目コード
            ,xim.item_id                              -- 39:品目ID
            ,xim.item_name                            -- 40:品目名
            ,xim.item_um                              -- 41:単位
            ,xim.conv_unit                            -- 42:入出庫換算単位
-- ##### 20081127 Ver.1.28 本番177対応 START #####
            ,CASE
               WHEN xoha.req_status = gc_req_status_shi_5 THEN 0
               ELSE xola.quantity                            -- 43:数量
             END                                      -- 07:データタイプ
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
            ,xim.num_of_cases                         -- 44:ケース入数
            ,xim.lot_ctl                              -- 45:ロット使用
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xoha.notif_date                          --   :確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
            ,gn_request_id                            --   :要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,oe_transaction_types_all   otta      -- 受注タイプ
          ,xxcmn_item_locations_v     xil       -- OPM保管場所情報VIEW
          ,xxcmn_carriers2_v          xc        -- 運送業者情報VIEW2
          ,xxcmn_vendor_sites_v       xvs       -- 仕入先サイト情報VIEW2
          ,xxwsh_carriers_schedule    xcs       -- 配車配送計画アドオン
          ,xxcmn_lookup_values2_v     xlv       -- クイックコード情報VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM品目情報VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM品目カテゴリ割当VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM品目カテゴリ割当VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- 品目
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- 受注明細
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
-- ##### 20081127 Ver.1.28 本番177対応 START #####
-- 削除フラグの条件はここではしない
--      AND   xola.delete_flag     = gc_yes_no_n      -- 削除フラグ = N
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
      ----------------------------------------------------------------------------------------------
      -- 配送配車計画
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- 配送先
      AND   gd_effective_date   BETWEEN xvs.start_date_active
                                AND     NVL( xvs.end_date_active, gd_effective_date )
      AND   xoha.vendor_site_id = xvs.vendor_site_id
      ----------------------------------------------------------------------------------------------
      -- 運送業者
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- 保管場所
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/***** EOS宛先による条件削除
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS業者
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 受注タイプ
      AND   otta.attribute1    = gc_sp_class_prov     -- 支給依頼
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      AND   xoha.latest_external_flag = gc_yes_no_y             -- 最新
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
      AND   xoha.prod_class           = gv_item_div_security    -- 商品区分（セキュリティ）
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
      AND   xoha.req_status           IN( gc_req_status_shi_3   -- 受領済
                                         ,gc_req_status_shi_5 ) -- 取消
-- M.HOKKANJI Ver1.9 START
      -- パラメータが確定の場合のみ日付を参照
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND  ((gr_param.fix_class = gc_fix_class_y
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
      AND   xoha.notif_date BETWEEN gd_date_from
                                AND gd_date_to
-- 2008/09/01 v1.16 update Y.Yamamoto end
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- 移動データＳＱＬ
      -- ===========================================================================================
      SELECT xmril.line_number                        -- 01:明細番号
            ,xmril.mov_line_id                        -- 02:明細ID
            ,CASE
               WHEN xmril.delete_flg = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:明細削除フラグ
            ,xmrih.status                             -- 04:ステータス
            ,xmrih.notif_status                       -- 05:通知ステータス
            ,xmrih.prev_notif_status                  -- 06:前回通知ステータス
            ,CASE
               WHEN xmrih.status = gc_req_status_syu_5 THEN gc_data_type_mov_can
               ELSE gc_data_type_mov_ins
             END                                      -- 07:データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
            ,xil2.eos_detination                      -- XX:EOS宛先（入庫倉庫）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
            ,xil1.eos_detination                      -- 08:EOS宛先（出庫倉庫）
            ,xc.eos_detination                        -- 09:EOS宛先（運送業者）
            ,xmrih.delivery_no                        -- 10:配送No
            ,xmrih.mov_num                            -- 11:依頼No
            ,NULL                                     -- 12:拠点コード
            ,NULL                                     -- 13:管轄拠点名称
            ,xil1.segment1                            -- 14:出庫倉庫コード
            ,SUBSTRB( xil1.description, 1, 20 )       -- 15:出庫倉庫名称
            ,xil2.segment1                            -- 16:入庫倉庫コード
            ,SUBSTRB( xil2.description, 1, 20 )       -- 17:入庫倉庫名称
            ,xc.party_number                          -- 18:運送業者コード
            ,xc.party_name                            -- 19:運送業者名
            ,NULL                                     -- 20:配送先コード
            ,NULL                                     -- 21:配送先名
            ,xmrih.schedule_ship_date                 -- 22:発日
            ,xmrih.schedule_arrival_date              -- 23:着日
            ,xlv.lookup_code                          -- 24:配送区分
            ,CASE
-- M.HOKKANJI Ver1.2 START
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6               = gc_small_method_y THEN xmrih.sum_weight      --2008/08/12 Del 課題#48(変更#164)
               AND  xlv.attribute6               = gc_small_method_y THEN NVL(xmrih.sum_weight,0) --2008/08/12 Add 課題#48(変更#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xmrih.sum_weight,0)
                                                                    + NVL(xmrih.sum_pallet_weight,0)
                                                                    
               --WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity      --2008/08/12 Del 課題#48(変更#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN NVL(xmrih.sum_capacity,0) --2008/08/12 Add 課題#48(変更#164)
/*
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6               = gc_wc_class_j THEN xmrih.sum_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6              <> gc_wc_class_j THEN xmrih.sum_weight
                                                                    + xmrih.sum_pallet_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity
*/
-- M.HOKKANJI Ver1.2 END
             END                                      -- 25:重量／容積
            ,NULL                                     -- 26:混載元依頼No
            ,xmrih.collected_pallet_qty               -- 27:ﾊﾟﾚｯﾄ回収枚数
            ,CASE
               WHEN xmrih.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END                                                -- 28:運賃区分
            ,NVL( xmrih.arrival_time_from, gc_time_default )    -- 29:着荷時間指定From
            ,NVL( xmrih.arrival_time_to  , gc_time_default )    -- 30:着荷時間指定To
            ,NULL                                     -- 31:顧客発注番号
            ,xmrih.description                        -- 32:摘要
            --,xmrih.out_pallet_qty                     -- 33:ﾊﾟﾚｯﾄ使用枚数（出）  -- 2008/09/09 TE080_600指摘#30 Del
            --,xmrih.in_pallet_qty                      -- 34:ﾊﾟﾚｯﾄ使用枚数（入）  -- 2008/09/09 TE080_600指摘#30 Del
            ,xmrih.pallet_sum_quantity                  -- 33:ﾊﾟﾚｯﾄ使用枚数（出）  -- 2008/09/09 TE080_600指摘#30 Add
            ,xmrih.pallet_sum_quantity                  -- 34:ﾊﾟﾚｯﾄ使用枚数（入）  -- 2008/09/09 TE080_600指摘#30 Add
            ,xmrih.instruction_post_code              -- 35:報告部署
            ,xic.prod_class_code                      -- 36:商品区分
            ,xic.item_class_code                      -- 37:品目区分
            ,xim.item_no                              -- 38:品目コード
            ,xim.item_id                              -- 39:品目ID
            ,xim.item_name                            -- 40:品目名
            ,xim.item_um                              -- 41:単位
            ,xim.conv_unit                            -- 42:入出庫換算単位
-- ##### 20081127 Ver.1.28 本番177対応 START #####
            ,CASE
               WHEN xmrih.status = gc_req_status_syu_5 THEN 0
               ELSE xmril.instruct_qty                       -- 43:数量
             END                                      -- 07:データタイプ
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
            ,xim.num_of_cases                         -- 44:ケース入数
            ,xim.lot_ctl                              -- 45:ロット使用
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xmrih.notif_date                         --   :確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
            ,gn_request_id                            --   :要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
      FROM xxinv_mov_req_instr_headers    xmrih     -- 移動依頼指示ヘッダアドオン
          ,xxinv_mov_req_instr_lines      xmril     -- 移動依頼指示明細アドオン
          ,xxcmn_item_locations_v         xil1      -- OPM保管場所情報VIEW（配送元）
          ,xxcmn_item_locations_v         xil2      -- OPM保管場所情報VIEW（配送先）
          ,xxcmn_carriers2_v              xc        -- 運送業者情報VIEW2
          ,xxwsh_carriers_schedule        xcs       -- 配車配送計画アドオン
          ,xxcmn_lookup_values2_v         xlv       -- クイックコード情報VIEW2
          ,xxcmn_item_mst2_v              xim       -- OPM品目情報VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM品目カテゴリ割当VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM品目カテゴリ割当VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- 品目
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xmril.item_id           = xim.item_id
      ----------------------------------------------------------------------------------------------
      -- 移動依頼指示明細
      AND   xmrih.mov_hdr_id = xmril.mov_hdr_id
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
-- ##### 20081127 Ver.1.28 本番177対応 START #####
-- 削除フラグの条件はここではしない
--      AND   xmril.delete_flg = gc_yes_no_n        -- 削除フラグ = N
-- ##### 20081127 Ver.1.28 本番177対応 END   #####
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
      ----------------------------------------------------------------------------------------------
      -- 配送配車計画
-- M.HOKKANJI Ver1.2 START
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date)
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xmrih.delivery_no = xcs.delivery_no(+)
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xmrih.delivery_no = xcs.delivery_no
*/
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- 運送業者
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xmrih.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
/***
      -- 保管場所（配送先）
      AND   xil2.eos_control_type  = gc_manage_eos_y    -- EOS業者
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 保管場所（配送元）
      AND   xil1.eos_control_type  = gc_manage_eos_y    -- EOS業者
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
***/
      -- 保管場所（配送先）
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- 保管場所（配送元）
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/***** EOS宛先による条件削除
      AND   (xil1.eos_control_type  = gc_manage_eos_y   -- EOS業者（配送先）
          OR xil2.eos_control_type  = gc_manage_eos_y)  -- EOS業者（配送元）
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
      -- 移動依頼指示ヘッダ
      AND   xmrih.mov_type    = gc_mov_type_y           -- 積送あり
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 START #####
      AND   xmrih.item_class  = gv_item_div_security    -- 商品区分（セキュリティ）
-- ##### 20080612 Ver.1.7 商品セキュリティ対応 END   #####
      AND   xmrih.status      IN( gc_mov_status_cmp     -- 依頼済
                                 ,gc_mov_status_adj     -- 調整中
                                 ,gc_mov_status_ccl )   -- 取消
      ---- パラメータが「実績」の場合のみ
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, gd_date_from
--                                      , gc_fix_class_k, xmrih.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
      AND   xmrih.notif_date BETWEEN gd_date_from
                                 AND gd_date_to
-- 2008/09/01 v1.16 update Y.Yamamoto end
      ;
    END IF;
-- 2008/09/01 v1.16 Y.Yamamoto End
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_ins_temp_table ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_main_data
   * Description      : メインデータ抽出(E-04)
   ************************************************************************************************/
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
    -- 変数宣言
    -- ==================================================
    lv_sql            VARCHAR2(32000) ;
    lv_select         VARCHAR2(32000) ;
    lv_from           VARCHAR2(32000) ;
    lv_where          VARCHAR2(32000) ;
    lv_order          VARCHAR2(32000) ;
--
    -- ==================================================
    -- ＲＥＦカーソル宣言
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    cu_ref      ref_cursor ;
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
    -- ＳＥＬＥＣＴ句
    -- ====================================================
    lv_select := ' SELECT'
              ||    ' wsdit2.line_number'               -- 明細番号
              ||    ',wsdit2.line_delete_flag'          -- 明細削除フラグ
              ||    ',wsdit2.prev_notif_status'         -- 前回通知ステータス
              ||    ',wsdit2.data_type'                 -- データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
              ||    ',wsdit2.eos_shipped_to_locat'      -- EOS宛先（入庫倉庫）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
              ||    ',wsdit2.eos_shipped_locat'         -- EOS宛先（出庫倉庫）
              ||    ',wsdit2.eos_freight_carrier'       -- EOS宛先（運送業者）
              ||    ',wsdit2.delivery_no'               -- 配送No
              ||    ',wsdit2.request_no'                -- 依頼No
              ||    ',wsdit2.head_sales_branch'         -- 拠点コード
              ||    ',wsdit2.head_sales_branch_name'    -- 管轄拠点名称
              ||    ',wsdit2.shipped_locat_code'        -- 出庫倉庫コード
              ||    ',wsdit2.shipped_locat_name'        -- 出庫倉庫名称
              ||    ',wsdit2.ship_to_locat_code'        -- 入庫倉庫コード
              ||    ',wsdit2.ship_to_locat_name'        -- 入庫倉庫名称
              ||    ',wsdit2.freight_carrier_code'      -- 運送業者コード
              ||    ',wsdit2.freight_carrier_name'      -- 運送業者名
              ||    ',wsdit2.deliver_to'                -- 配送先コード
              ||    ',wsdit2.deliver_to_name'           -- 配送先名
              ||    ',wsdit2.schedule_ship_date'        -- 発日
              ||    ',wsdit2.schedule_arrival_date'     -- 着日
              ||    ',wsdit2.shipping_method_code'      -- 配送区分
              ||    ',wsdit2.weight'                    -- 重量/容積
              ||    ',wsdit2.mixed_no'                  -- 混載元依頼№
              ||    ',wsdit2.collected_pallet_qty'      -- パレット回収枚数
              ||    ',wsdit2.freight_charge_class'      -- 運賃区分
              ||    ',wsdit2.arrival_time_from'         -- 着荷時間指定(FROM)
              ||    ',wsdit2.arrival_time_to'           -- 着荷時間指定(TO)
              ||    ',wsdit2.cust_po_number'            -- 顧客発注番号
              ||    ',wsdit2.description'               -- 摘要
              ||    ',wsdit2.pallet_sum_quantity_out'   -- パレット使用枚数（出）
              ||    ',wsdit2.pallet_sum_quantity_in'    -- パレット使用枚数（入）
              ||    ',wsdit2.report_dept'               -- 報告部署
              ||    ',wsdit2.prod_class'                -- 商品区分
              ||    ',wsdit2.item_class'                -- 品目区分
              ||    ',wsdit2.item_code'                 -- 品目コード
              ||    ',wsdit2.item_name'                 -- 品目名
              ||    ',wsdit2.item_uom_code'             -- 単位
              ||    ',wsdit2.conv_unit'                 -- 入出庫換算単位
              ||    ',wsdit2.item_quantity'             -- 数量
              ||    ',wsdit2.case_quantity'             -- ケース入数
              ||    ',wsdit2.lot_class'                 -- ロット管理区分
              ||    ',wsdit2.line_id'                   -- 明細ID
              ||    ',wsdit2.item_id'                   -- 品目ID
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
              ||    ',wsdit2.notif_date'                -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
              ||    ',imld.mov_lot_dtl_id'              -- ロット詳細ID
              ;
    -- ====================================================
    -- ＦＲＯＭ句
    -- ====================================================
    lv_from := ' FROM xxwsh_stock_delivery_info_tmp2 wsdit2, ' 
-- ##### 20080627 Ver.1.12 ST障害No390 START #####
/*****
                   || 'xxinv_mov_lot_details imld';
*****/
             || ' ( SELECT   mov_lot_dtl_id as mov_lot_dtl_id '
             || '          , mov_line_id    as mov_line_id '
             || '   FROM   xxinv_mov_lot_details '
             || '   WHERE  document_type_code     IN ( '
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
-- ##### 20081023 Ver.1.25 レコードタイプ指示のみ対応 START #####
             || '   AND    record_type_code = ' || gc_rec_type_inst
-- ##### 20081023 Ver.1.25 レコードタイプ指示のみ対応 END   #####
             || ' ) imld '
              ;
-- ##### 20080627 Ver.1.12 ST障害No390 END   #####
--
    -- ====================================================
    -- ＷＨＥＲＥ句
    -- ====================================================
    -------------------------------------------------------
    -- 予定確定区分が「予定」の場合
    -------------------------------------------------------
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
      lv_where := ' WHERE '
          || ' ('
            || ' wsdit2.data_type IN( ''' || gc_data_type_syu_ins || ''''
                                 || ',''' || gc_data_type_shi_ins || ''''
                                 || ',''' || gc_data_type_mov_ins || ''' )'
          || ' )'
          || ' AND'
          || ' ('
            || ' ('
            || '     wsdit2.notif_status      = ''' || gc_notif_status_n || ''''  -- 未通知
            || ' AND wsdit2.prev_notif_status IS NULL'                            -- ＮＵＬＬ
            || ' )'
            || ' OR'
            || ' ('
            || '     wsdit2.notif_status      = ''' || gc_notif_status_r || ''''  -- 再通知
            || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_c || ''''  -- 確定通知
            || ' )'
          || ' )'
          ;
--
    -------------------------------------------------------
    -- 予定確定区分が「確定」の場合
    -------------------------------------------------------
    ELSIF ( gr_param.fix_class = gc_fix_class_k ) THEN
      lv_where := ' WHERE '
          || ' (('
            || ' ( wsdit2.data_type IN( ''' || gc_data_type_syu_ins || ''''
                                   || ',''' || gc_data_type_shi_ins || ''''
                                   || ',''' || gc_data_type_mov_ins || ''')'
            || ' AND wsdit2.notif_status      = ''' || gc_notif_status_c || ''''  -- 確定通知済
            || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_n || ''')' -- 未通知
            || ' AND  NOT EXISTS'
                      || '( SELECT 1'
                      || '  FROM xxwsh_notif_delivery_info xndi'
-- 2008/09/01 v1.16 update Y.Yamamoto start
--                      || '  WHERE xndi.request_no = wsdit2.request_no )'
                      || '  WHERE xndi.request_no = wsdit2.request_no '
                      || '  AND   rownum <= 1 )'
-- 2008/09/01 v1.16 update Y.Yamamoto end
          || ' )'
          || ' OR'
          || ' (   wsdit2.notif_status      = ''' || gc_notif_status_c || ''''  -- 確定通知済
          || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_r || ''''  -- 再通知要
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
--          || ' ))'
          || ' )'
              -- トランザクションの確定通知実施日時が、通知済入出庫配送計画情報より以前の場合は除外
              || ' AND  NOT EXISTS'
                        || '( SELECT 1'
                        || '  FROM xxwsh_notif_delivery_info xndi'
                        || '  WHERE xndi.request_no  = wsdit2.request_no '
                        || '  AND   xndi.notif_date >= wsdit2.notif_date '
                        || '  AND   rownum <= 1 )'
          || ' )'
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
          ;
--
    END IF ;
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
    -------------------------------------------------------
    -- EOS宛先条件（入庫・出庫・運送業者のEOS宛先いずれかが設定されていたら）
    -------------------------------------------------------
    lv_where := lv_where
            || ' AND ( wsdit2.eos_shipped_to_locat IS NOT NULL   '  -- EOS宛先（入庫倉庫）
            || '    OR wsdit2.eos_shipped_locat    IS NOT NULL   '  -- EOS宛先（出庫倉庫）
            || '    OR wsdit2.eos_freight_carrier  IS NOT NULL ) '  -- EOS宛先（運送業者）
            ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
--
    -------------------------------------------------------
    -- 移動ロット詳細と結合
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.line_id = imld.mov_line_id (+) '
-- ##### 20080627 Ver.1.12 ST障害No390 START #####
/*****
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
             || ' AND imld.document_type_code IN ('
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
*****/
-- ##### 20080627 Ver.1.12 ST障害No390 END #####
             ;
--
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
    -------------------------------------------------------
    -- 数量が0以上の明細が対象
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.item_quantity > 0 '
              ;
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
--
    -------------------------------------------------------
    -- パラメータ．部署
    -------------------------------------------------------
-- 2008/07/16 Add ↓
    lv_where := lv_where
             || ' AND ((wsdit2.report_dept = ''' || gr_param.dept_code_01 || ''')';
--
    IF (gr_param.dept_code_02 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_02 || ''')';
    END IF;
    IF (gr_param.dept_code_03 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_03 || ''')';
    END IF;
    IF (gr_param.dept_code_04 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_04 || ''')';
    END IF;
    IF (gr_param.dept_code_05 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_05 || ''')';
    END IF;
    IF (gr_param.dept_code_06 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_06 || ''')';
    END IF;
    IF (gr_param.dept_code_07 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_07 || ''')';
    END IF;
    IF (gr_param.dept_code_08 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_08 || ''')';
    END IF;
    IF (gr_param.dept_code_09 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_09 || ''')';
    END IF;
    IF (gr_param.dept_code_10 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_10 || ''')';
    END IF;
--
    lv_where := lv_where || ')';
-- 2008/07/16 Add ↑
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    -------------------------------------------------------
    -- 要求ID
    -------------------------------------------------------
    lv_where := lv_where || ' AND wsdit2.target_request_id = ' || TO_CHAR(gn_request_id) || ' ' ;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
    -- ====================================================
    -- ＯＲＤＥＲ ＢＹ句
    -- ====================================================
    lv_order  := ' ORDER BY '
              || '   wsdit2.data_type'
              || '  ,wsdit2.request_no'
              || '  ,wsdit2.line_number'
              ;
--
    -- ====================================================
    -- ＳＱＬ文生成
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_order ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    OPEN cu_ref FOR lv_sql ;
    FETCH cu_ref BULK COLLECT INTO gt_main_data ;
    CLOSE cu_ref ;
--
    IF ( gt_main_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- 対象データなし
    -- =============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_get_main_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
--   取消データ取得処理 追加
--     メインデータ抽出処理にて条件に変更があった場合は取り消しデータ抽出にも変更が必要となります
--
  /************************************************************************************************
   * Procedure Name   : prc_get_can_data
   * Description      : 取消データ抽出
   ************************************************************************************************/
  PROCEDURE prc_get_can_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_can_data' ; -- プログラム名
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
    -- 変数宣言
    -- ==================================================
    lv_sql            VARCHAR2(32000) ;
    lv_select         VARCHAR2(32000) ;
    lv_from           VARCHAR2(32000) ;
    lv_where          VARCHAR2(32000) ;
    lv_order          VARCHAR2(32000) ;
-- ##### 20081028 Ver.1.26 対応もれ対応対応 START #####
    lv_group          VARCHAR2(32000) ;
-- ##### 20081028 Ver.1.26 対応もれ対応対応 END   #####
--
    -- ==================================================
    -- ＲＥＦカーソル宣言
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    cu_ref      ref_cursor ;
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
    -- ＳＥＬＥＣＴ句
    -- ====================================================
    lv_select := ' SELECT '
              ||    ' wsdit2.request_no '   -- 依頼No
              ;
    -- ====================================================
    -- ＦＲＯＭ句
    -- ====================================================
    lv_from := ' FROM xxwsh_stock_delivery_info_tmp2 wsdit2, ' 
             || ' ( SELECT   mov_lot_dtl_id as mov_lot_dtl_id '
             || '          , mov_line_id    as mov_line_id '
             || '   FROM   xxinv_mov_lot_details '
             || '   WHERE  document_type_code     IN ( '
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
-- ##### 20081028 Ver.1.26 対応もれ対応 START #####
             || '   AND    record_type_code = '   || gc_rec_type_inst
-- ##### 20081028 Ver.1.26 対応もれ対応 END   #####
             || ' ) imld '
              ;
--
    -- ====================================================
    -- ＷＨＥＲＥ句
    -- ====================================================
    lv_where := ' WHERE '
        || ' (   wsdit2.notif_status      = ''' || gc_notif_status_c || ''''  -- 確定通知済
        || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_r || ''''  -- 再通知要
        || ' )'
        ;
--
    -------------------------------------------------------
    -- EOS宛先条件（入庫・出庫・運送業者のEOS宛先全てがNULLの場合）
    -------------------------------------------------------
    lv_where := lv_where
            || ' AND  wsdit2.eos_shipped_to_locat IS NULL  '  -- EOS宛先（入庫倉庫）
            || ' AND  wsdit2.eos_shipped_locat    IS NULL  '  -- EOS宛先（出庫倉庫）
            || ' AND  wsdit2.eos_freight_carrier  IS NULL  '  -- EOS宛先（運送業者）
            ;
--
    -------------------------------------------------------
    -- 移動ロット詳細と結合
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.line_id = imld.mov_line_id (+) '
             ;
--
    -------------------------------------------------------
    -- パラメータ．部署
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND ((wsdit2.report_dept = ''' || gr_param.dept_code_01 || ''')';
--
    IF (gr_param.dept_code_02 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_02 || ''')';
    END IF;
    IF (gr_param.dept_code_03 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_03 || ''')';
    END IF;
    IF (gr_param.dept_code_04 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_04 || ''')';
    END IF;
    IF (gr_param.dept_code_05 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_05 || ''')';
    END IF;
    IF (gr_param.dept_code_06 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_06 || ''')';
    END IF;
    IF (gr_param.dept_code_07 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_07 || ''')';
    END IF;
    IF (gr_param.dept_code_08 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_08 || ''')';
    END IF;
    IF (gr_param.dept_code_09 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_09 || ''')';
    END IF;
    IF (gr_param.dept_code_10 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_10 || ''')';
    END IF;
--
    lv_where := lv_where || ')';
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    -------------------------------------------------------
    -- 要求ID
    -------------------------------------------------------
    lv_where := lv_where || ' AND wsdit2.target_request_id = ' || TO_CHAR(gn_request_id) || ' ' ;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
-- ##### 20081028 Ver.1.26 対応もれ対応対応 START #####
    -- ====================================================
    -- ＧＲＯＵＰ ＢＹ句
    -- ====================================================
    lv_group := ' GROUP BY '
            ||  ' wsdit2.request_no ';
-- ##### 20081028 Ver.1.26 対応もれ対応対応 END   #####
--
-- ##### 20081028 Ver.1.26 対応もれ対応対応 START #####
    -- ====================================================
    -- ＯＲＤＥＲ ＢＹ句
    -- ====================================================
--    lv_order  := ' ORDER BY '
--              || '   wsdit2.data_type'
--              || '  ,wsdit2.request_no'
--              || '  ,wsdit2.line_number'
--              ;
    lv_order  := ' ORDER BY '
              || '  wsdit2.request_no '
              ;
-- ##### 20081028 Ver.1.26 対応もれ対応対応 END   #####
--
    -- ====================================================
    -- ＳＱＬ文生成
    -- ====================================================
-- ##### 20081028 Ver.1.26 対応もれ対応対応 START #####
--    lv_sql := lv_select || lv_from || lv_where || lv_order ;
    lv_sql := lv_select || lv_from || lv_where || lv_group || lv_order ;
-- ##### 20081028 Ver.1.26 対応もれ対応対応 END   #####
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    OPEN cu_ref FOR lv_sql ;
    FETCH cu_ref BULK COLLECT INTO gt_can_data ;
    CLOSE cu_ref ;
--
    IF ( gt_can_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- 対象データなし
    -- =============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_get_can_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
--
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
--   全ての明細が0の依頼に対する取消データ取得処理 追加
--     メインデータ抽出処理にて条件に変更があった場合は取り消しデータ抽出にも変更が必要となります
--
  /************************************************************************************************
   * Procedure Name   : prc_get_zero_can_data
   * Description      : 依頼数量0の取消データ抽出
   ************************************************************************************************/
  PROCEDURE prc_get_zero_can_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_zero_can_data' ; -- プログラム名
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
    -- 変数宣言
    -- ==================================================
    lv_main_sql       VARCHAR2(32000) ;
    lv_sql            VARCHAR2(32000) ;
    lv_select         VARCHAR2(32000) ;
    lv_from           VARCHAR2(32000) ;
    lv_where          VARCHAR2(32000) ;
    lv_order          VARCHAR2(32000) ;
    lv_group          VARCHAR2(32000) ;
--
    -- ==================================================
    -- ＲＥＦカーソル宣言
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    cu_ref      ref_cursor ;
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
    -- インライン ＳＥＬＥＣＴ句
    -- ====================================================
    lv_select := ' SELECT'
              ||    '  wsdit2.request_no         AS request_no   '  -- 依頼No
              ||    ', SUM(wsdit2.item_quantity) AS sum_quantity '  -- 数量（依頼の総数量）
              ;
    -- ====================================================
    -- ＦＲＯＭ句
    -- ====================================================
    lv_from := ' FROM xxwsh_stock_delivery_info_tmp2 wsdit2, ' 
             || ' ( SELECT   mov_lot_dtl_id as mov_lot_dtl_id '
             || '          , mov_line_id    as mov_line_id '
             || '   FROM   xxinv_mov_lot_details '
             || '   WHERE  document_type_code     IN ( '
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
             || '   AND    record_type_code = ' || gc_rec_type_inst
             || ' ) imld '
              ;
--
    -- ====================================================
    -- ＷＨＥＲＥ句
    -- ====================================================
    -------------------------------------------------------
    -- 予定確定区分が「確定」
    -------------------------------------------------------
    lv_where := ' WHERE '
        || '     wsdit2.notif_status      = ''' || gc_notif_status_c || ''' '  -- 確定通知済
        || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_r || ''' '  -- 再通知要
        ;
--
    -------------------------------------------------------
    -- EOS宛先条件（入庫・出庫・運送業者のEOS宛先いずれかが設定されていたら）
    -------------------------------------------------------
    lv_where := lv_where
            || ' AND ( wsdit2.eos_shipped_to_locat IS NOT NULL   '  -- EOS宛先（入庫倉庫）
            || '    OR wsdit2.eos_shipped_locat    IS NOT NULL   '  -- EOS宛先（出庫倉庫）
            || '    OR wsdit2.eos_freight_carrier  IS NOT NULL ) '  -- EOS宛先（運送業者）
            ;
--
    -------------------------------------------------------
    -- 移動ロット詳細と結合
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.line_id = imld.mov_line_id (+) '
             ;
--
    -------------------------------------------------------
    -- パラメータ．部署
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND ((wsdit2.report_dept = ''' || gr_param.dept_code_01 || ''')';
--
    IF (gr_param.dept_code_02 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_02 || ''')';
    END IF;
    IF (gr_param.dept_code_03 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_03 || ''')';
    END IF;
    IF (gr_param.dept_code_04 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_04 || ''')';
    END IF;
    IF (gr_param.dept_code_05 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_05 || ''')';
    END IF;
    IF (gr_param.dept_code_06 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_06 || ''')';
    END IF;
    IF (gr_param.dept_code_07 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_07 || ''')';
    END IF;
    IF (gr_param.dept_code_08 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_08 || ''')';
    END IF;
    IF (gr_param.dept_code_09 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_09 || ''')';
    END IF;
    IF (gr_param.dept_code_10 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_10 || ''')';
    END IF;
--
    lv_where := lv_where || ')';
--
    -------------------------------------------------------
    -- 要求ID
    -------------------------------------------------------
    lv_where := lv_where || ' AND wsdit2.target_request_id = ' || TO_CHAR(gn_request_id) || ' ' ;
--
    -- ====================================================
    -- ＧＲＯＵＰ ＢＹ句
    -- ====================================================
    lv_group := ' GROUP BY '
            ||  ' wsdit2.request_no ';
--
    -- ====================================================
    -- ＯＲＤＥＲ ＢＹ句
    -- ====================================================
    lv_order  := ' ORDER BY '
              || '  wsdit2.request_no '
              ;
--
    -- ====================================================
    -- ＳＱＬ文生成
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_group || lv_order ;
--
    -- ====================================================
    -- メイン ＳＥＬＥＣＴ 生成
    -- ====================================================
    lv_main_sql := ' SELECT g_req.request_no '
                || ' FROM ( ' || lv_sql  || ' ) g_req '
                || ' WHERE g_req.sum_quantity = 0 '
                ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    OPEN cu_ref FOR lv_main_sql ;
    FETCH cu_ref BULK COLLECT INTO gt_zero_can_data ;
    CLOSE cu_ref ;
--
    IF ( gt_zero_can_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- 対象データなし
    -- =============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_get_zero_can_data ;
--
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
--
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_head_data
   * Description      : ヘッダデータ作成
   ************************************************************************************************/
  PROCEDURE prc_cre_head_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_stock_delivery_info_tmp.data_class%TYPE
     ,iv_pallet_sum_quantity  IN  xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
     ,iv_eos_shipped_locat    IN  xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
     ,iv_eos_csv_output       IN  xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE
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
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_corporation_name     CONSTANT VARCHAR2(100) := 'ITOEN' ;
    lc_transfer_branch_no_h CONSTANT VARCHAR2(100) := '10' ;    -- ヘッダ
    lc_reserve              CONSTANT VARCHAR2(100) := '000000000000' ;
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
    gt_corporation_name(gn_cre_idx)       := lc_corporation_name ;                -- 会社名
    gt_data_class(gn_cre_idx)             := iv_data_class ;                      -- データ種別
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_h ;            -- 伝送用枝番
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ;           -- 配送No
    gt_request_no(gn_cre_idx)             := ir_main_data.request_no ;            -- 依頼No
    gt_reserve(gn_cre_idx)                := lc_reserve ;                         -- 予備
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
    gt_mixed_no(gn_cre_idx)               := ir_main_data.mixed_no ;              -- 混載元依頼No
    gt_collected_pallet_qty(gn_cre_idx)   := ir_main_data.collected_pallet_qty ;  -- ﾊﾟﾚｯﾄ回収枚数
    gt_arrival_time_from(gn_cre_idx)      := ir_main_data.arrival_time_from ;     -- 着荷時間From
    gt_arrival_time_to(gn_cre_idx)        := ir_main_data.arrival_time_to ;       -- 着荷時間To
    gt_cust_po_number(gn_cre_idx)         := ir_main_data.cust_po_number ;        -- 顧客発注番号
    gt_description(gn_cre_idx)            := ir_main_data.description ;           -- 摘要
--
    -- ステータス
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
      gt_status(gn_cre_idx) := gc_status_y ;
    ELSE
      gt_status(gn_cre_idx) := gc_status_k ;
    END IF ;
--
    gt_freight_charge_class(gn_cre_idx)   := ir_main_data.freight_charge_class ;-- 運賃区分
    gt_pallet_sum_quantity(gn_cre_idx)    := iv_pallet_sum_quantity ;           -- ﾊﾟﾚｯﾄ使用枚数
    gt_reserve1(gn_cre_idx)               := NULL ;                             -- 予備１
    gt_reserve2(gn_cre_idx)               := NULL ;                             -- 予備２
    gt_reserve3(gn_cre_idx)               := NULL ;                             -- 予備３
    gt_reserve4(gn_cre_idx)               := NULL ;                             -- 予備４
    gt_report_dept(gn_cre_idx)            := ir_main_data.report_dept ;         -- 報告部署
    gt_item_code(gn_cre_idx)              := NULL ;                             -- 品目コード
    gt_item_name(gn_cre_idx)              := NULL ;                             -- 品目名
    gt_item_uom_code(gn_cre_idx)          := NULL ;                             -- 品目単位
    gt_item_quantity(gn_cre_idx)          := NULL ;                             -- 品目数量
    gt_lot_no(gn_cre_idx)                 := NULL ;                             -- ロット番号
    gt_lot_date(gn_cre_idx)               := NULL ;                             -- 製造日
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                             -- 賞味期限
    gt_lot_sign(gn_cre_idx)               := NULL ;                             -- 固有記号
    gt_lot_quantity(gn_cre_idx)           := NULL ;                             -- ロット数量
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;                -- データ区分
    gt_update_date(gn_cre_idx)            := SYSDATE ;                          -- 更新日時
    gt_line_number(gn_cre_idx)            := NULL ;                             -- 明細番号
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;           -- データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
/***
    gt_eos_shipped_locat(gn_cre_idx)      := ir_main_data.eos_shipped_locat ;   -- EOS宛先：出庫倉庫
***/
    gt_eos_shipped_locat(gn_cre_idx)      := iv_eos_shipped_locat ;             -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
    gt_eos_freight_carrier(gn_cre_idx)    := ir_main_data.eos_freight_carrier ; -- EOS宛先：運送業者
    gt_eos_csv_output(gn_cre_idx)         := iv_eos_csv_output ;                -- EOS宛先：CSV
--
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
    gt_notif_date(gn_cre_idx)             := ir_main_data.notif_date ;          -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    gt_target_request_id(gn_cre_idx)      := gn_request_id;                     -- 要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_cre_head_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_dtl_data
   * Description      : 明細データ作成
   ************************************************************************************************/
  PROCEDURE prc_cre_dtl_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_stock_delivery_info_tmp.data_class%TYPE
     ,iv_item_uom_code        IN  xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE
     ,iv_item_quantity        IN  xxwsh_stock_delivery_info_tmp.item_quantity%TYPE
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
     ,iv_eos_shipped_locat    IN  xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
     ,iv_eos_csv_output       IN  xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE
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
    -- 定数宣言
    -- ==================================================
    lc_corporation_name     CONSTANT VARCHAR2(100) := 'ITOEN' ;
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- 明細
    lc_reserve              CONSTANT VARCHAR2(100) := '000000000000' ;
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_doc_type             xxinv_mov_lot_details.document_type_code%TYPE ;
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
    gt_corporation_name(gn_cre_idx)       := lc_corporation_name ;              -- 会社名
    gt_data_class(gn_cre_idx)             := iv_data_class ;                    -- データ種別
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_d ;          -- 伝送用枝番
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ;         -- 配送No
    gt_request_no(gn_cre_idx)             := ir_main_data.request_no ;          -- 依頼No
    gt_reserve(gn_cre_idx)                := NULL ;                             -- 予備
    gt_head_sales_branch(gn_cre_idx)      := NULL ;                             -- 拠点コード
    gt_head_sales_branch_name(gn_cre_idx) := NULL ;                             -- 管轄拠点名称
    gt_shipped_locat_code(gn_cre_idx)     := NULL ;                             -- 出庫倉庫コード
    gt_shipped_locat_name(gn_cre_idx)     := NULL ;                             -- 出庫倉庫名称
    gt_ship_to_locat_code(gn_cre_idx)     := NULL ;                             -- 入庫倉庫コード
    gt_ship_to_locat_name(gn_cre_idx)     := NULL ;                             -- 入庫倉庫名称
    gt_freight_carrier_code(gn_cre_idx)   := NULL ;                             -- 運送業者コード
    gt_freight_carrier_name(gn_cre_idx)   := NULL ;                             -- 運送業者名
    gt_deliver_to(gn_cre_idx)             := NULL ;                             -- 配送先コード
    gt_deliver_to_name(gn_cre_idx)        := NULL ;                             -- 配送先名
    gt_schedule_ship_date(gn_cre_idx)     := NULL ;                             -- 発日
    gt_schedule_arrival_date(gn_cre_idx)  := NULL ;                             -- 着日
    gt_shipping_method_code(gn_cre_idx)   := NULL ;                             -- 配送区分
    gt_weight(gn_cre_idx)                 := NULL ;                             -- 重量/容積
    gt_mixed_no(gn_cre_idx)               := NULL ;                             -- 混載元依頼No
    gt_collected_pallet_qty(gn_cre_idx)   := NULL ;                             -- ﾊﾟﾚｯﾄ回収枚数
    gt_arrival_time_from(gn_cre_idx)      := NULL ;                             -- 着荷時間From
    gt_arrival_time_to(gn_cre_idx)        := NULL ;                             -- 着荷時間To
    gt_cust_po_number(gn_cre_idx)         := NULL ;                             -- 顧客発注番号
    gt_description(gn_cre_idx)            := NULL ;                             -- 摘要
    gt_status(gn_cre_idx)                 := NULL ;                             -- ステータス
    gt_freight_charge_class(gn_cre_idx)   := NULL ;                             -- 運賃区分
    gt_pallet_sum_quantity(gn_cre_idx)    := NULL ;                             -- ﾊﾟﾚｯﾄ使用枚数
    gt_reserve1(gn_cre_idx)               := NULL ;                             -- 予備１
    gt_reserve2(gn_cre_idx)               := NULL ;                             -- 予備２
    gt_reserve3(gn_cre_idx)               := NULL ;                             -- 予備３
    gt_reserve4(gn_cre_idx)               := NULL ;                             -- 予備４
    gt_report_dept(gn_cre_idx)            := NULL ;                             -- 報告部署
    gt_item_code(gn_cre_idx)              := ir_main_data.item_code ;           -- 品目コード
    gt_item_name(gn_cre_idx)              := ir_main_data.item_name ;           -- 品目名
    gt_item_uom_code(gn_cre_idx)          := iv_item_uom_code ;                 -- 品目単位
    gt_item_quantity(gn_cre_idx)          := iv_item_quantity ;                 -- 品目数量
    gt_lot_no(gn_cre_idx)                 := NULL ;                             -- ロット番号
    gt_lot_date(gn_cre_idx)               := NULL ;                             -- 製造日
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                             -- 賞味期限
    gt_lot_sign(gn_cre_idx)               := NULL ;                             -- 固有記号
    gt_lot_quantity(gn_cre_idx)           := NULL ;                             -- ロット数量
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;                -- データ区分
    gt_update_date(gn_cre_idx)            := SYSDATE ;                          -- 更新日時
    gt_line_number(gn_cre_idx)            := ir_main_data.line_number ;         -- 明細番号
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;           -- データタイプ
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
/***
    gt_eos_shipped_locat(gn_cre_idx)      := ir_main_data.eos_shipped_locat ;   -- EOS宛先：出庫倉庫
***/
    gt_eos_shipped_locat(gn_cre_idx)      := iv_eos_shipped_locat ;             -- EOS宛先
    
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
    gt_eos_freight_carrier(gn_cre_idx)    := ir_main_data.eos_freight_carrier ; -- EOS宛先：運送業者
    gt_eos_csv_output(gn_cre_idx)         := iv_eos_csv_output ;                -- EOS宛先：CSV
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
    gt_notif_date(gn_cre_idx)             := ir_main_data.notif_date ;          -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    gt_target_request_id(gn_cre_idx)      := gn_request_id;                     -- 要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
    -------------------------------------------------------
    -- ロット管理品の場合
    -------------------------------------------------------
    IF ( ir_main_data.lot_class = gc_lot_ctl_y ) THEN
      -- 出荷データの場合
      IF ( iv_data_class IN( gc_data_class_syu_s
                            ,gc_data_class_syu_h ) ) THEN
--
        lv_doc_type := gc_doc_type_ship ;
--
      -- 支給データの場合
      ELSIF ( iv_data_class IN( gc_data_class_shi_s
                               ,gc_data_class_shi_h ) ) THEN
--
        lv_doc_type := gc_doc_type_prov ;
--
      -- 移動データの場合
      ELSIF ( iv_data_class IN( gc_data_class_mov_s
                            ,gc_data_class_mov_h 
                            ,gc_data_class_mov_n ) ) THEN
--
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
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
      -------------------------------------------------------
      -- ロット数量換算
      -------------------------------------------------------
      -- 出荷の場合
      IF ( ir_main_data.data_type = gc_data_type_syu_ins ) THEN
--
        -- 入出庫換算単位≠NULLの場合の換算
        IF (ir_main_data.conv_unit IS NOT NULL) THEN
          -- ロット数量 ÷ ケース入り数
          gt_lot_quantity(gn_cre_idx) := gt_lot_quantity(gn_cre_idx)
                                            / ir_main_data.case_quantity ;
          --gt_lot_quantity(gn_cre_idx) := TRUNC( gt_lot_quantity(gn_cre_idx), 3 ) ; --2008/08/12 Del 課題#32
--
        END IF;
--
      -- 移動の場合（ドリンク製品のみ）
      ELSIF (   ( ir_main_data.data_type  = gc_data_type_mov_ins )
            AND ( ir_main_data.prod_class = gc_prod_class_d      ) 
            AND ( ir_main_data.item_class = gc_item_class_i      ) ) THEN
        -- 入出庫換算単位≠NULLの場合
        IF (ir_main_data.conv_unit IS NOT NULL) THEN
          -- ロット数量 ÷ ケース入り数
          gt_lot_quantity(gn_cre_idx) := gt_lot_quantity(gn_cre_idx)
                                            / ir_main_data.case_quantity ;
          --gt_lot_quantity(gn_cre_idx) := TRUNC( gt_lot_quantity(gn_cre_idx), 3 ) ; --2008/08/12 Del 課題#32
        END IF ;
      END IF;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
--
    END IF ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_cre_dtl_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_ins_data
   * Description      : 通知済情報作成処理(E-05)
   ************************************************************************************************/
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
    lc_msg_code_eos         CONSTANT VARCHAR2(50) := 'APP-XXWSH-11908' ;
    lc_msg_code_case        CONSTANT VARCHAR2(50) := 'APP-XXWSH-11904' ;
    lc_tok_name_eos         CONSTANT VARCHAR2(50) := 'REQ_NO' ;
    lc_tok_name_case        CONSTANT VARCHAR2(50) := 'ITEM_ID' ;
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
    lv_eos_shipped_to_locat xxwsh_stock_delivery_info_tmp2.eos_shipped_to_locat%TYPE ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
    lv_eos_shipped_locat    xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE ;
    lv_eos_freight_carrier  xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE ;
    lv_eos_csv_output       xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE ;
    lv_pallet_sum_quantity  xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE ;
    lv_item_uom_code        xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE ;
    lv_item_quantity        xxwsh_stock_delivery_info_tmp.item_quantity%TYPE ;
--
    lv_eos_wrk              xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE;
--
    lv_tok_val              VARCHAR2(50) ;
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_eos_error            EXCEPTION ;   -- ＥＯＳ宛先エラー
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
    -- =============================================================================================
    -- 初期処理
    -- =============================================================================================
    -------------------------------------------------------
    -- ＥＯＳ宛先の退避
    -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
    lv_eos_shipped_to_locat := gt_main_data(in_idx).eos_shipped_to_locat ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
    lv_eos_shipped_locat    := gt_main_data(in_idx).eos_shipped_locat ;
    lv_eos_freight_carrier  := gt_main_data(in_idx).eos_freight_carrier ;
--
    -- =============================================================================================
    -- エラーハンドリング
    -- =============================================================================================
    -------------------------------------------------------
    -- ＥＯＳ宛先チェック
    -------------------------------------------------------
    lv_tok_val := gt_main_data(in_idx).request_no ;
-- M.Hokkanji Ver1.5 START
-- 運送業者がNULLの場合もエラーにしないように修正
--    IF ( lv_eos_freight_carrier IS NULL ) THEN
--      RAISE ex_eos_error ;
--    END IF ;
-- M.Hokkanji Ver1.5 END
--
    -------------------------------------------------------
    -- ケース入り数チェック
    -------------------------------------------------------
    lv_tok_val := gt_main_data(in_idx).item_code ;
    -- 出荷の場合
    IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
      -- 入出庫換算単位≠NULLの場合
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
        -- ケース入り数の値がない場合
        IF ( NVL( gt_main_data(in_idx).case_quantity, 0 ) = 0 ) THEN
          RAISE ex_case_quant_error ;
        END IF ;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
      END IF ;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
--
    -- 移動の場合（ドリンク製品のみ）
    ELSIF (   ( gt_main_data(in_idx).data_type  = gc_data_type_mov_ins )
          AND ( gt_main_data(in_idx).prod_class = gc_prod_class_d      ) 
          AND ( gt_main_data(in_idx).item_class = gc_item_class_i      ) ) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
      -- 入出庫換算単位≠NULLの場合
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
        -- ケース入り数の値がない場合
        IF ( NVL( gt_main_data(in_idx).case_quantity, 0 ) = 0 ) THEN
          RAISE ex_case_quant_error ;
        END IF ;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
      END IF ;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
    END IF ;
--
    -- =============================================================================================
    -- 出荷依頼データ作成
    -- =============================================================================================
    lv_eos_csv_output := lv_eos_shipped_locat ;   -- ＥＯＳ宛先（ＣＳＶ）
    -------------------------------------------------------
    -- データタイプ：出荷
    -------------------------------------------------------
    IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
      -------------------------------------------------------
      -- 可変項目編集
      -------------------------------------------------------
      lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;  -- パレット使用枚数
--
      -- 品目単位
      lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                              ,gt_main_data(in_idx).item_uom_code ) ;
      -- 品目数量
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
      -- 入出庫換算単位≠NULLの場合
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
        lv_item_quantity := gt_main_data(in_idx).item_quantity
                          / gt_main_data(in_idx).case_quantity ;
        --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;       --2008/08/12 Del 課題#32
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
      -- 入出庫換算単位＝NULLの場合
      ELSE
        lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- 品目数量
      END IF;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
      -- 出庫倉庫のEOS宛先が設定されている場合
      IF (lv_eos_shipped_locat IS NOT NULL) THEN
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
--
        -------------------------------------------------------
        -- ヘッダデータの作成
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
              ,iv_data_class           => gc_data_class_syu_s      -- データ種別
              ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
              ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
              ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
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
        -- 明細の削除フラグが「Y」の場合、明細データを作成しない。
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_syu_s      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
      END IF ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
--
    -------------------------------------------------------
    -- データタイプ：支給
    -------------------------------------------------------
    ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_shi_ins ) THEN
      -------------------------------------------------------
      -- 可変項目編集
      -------------------------------------------------------
      lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;  -- パレット使用枚数
      lv_item_uom_code       := gt_main_data(in_idx).item_uom_code  ;           -- 品目単位
      lv_item_quantity       := gt_main_data(in_idx).item_quantity ;            -- 品目数量
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
      -- 出庫倉庫のEOS宛先が設定されている場合
      IF (lv_eos_shipped_locat IS NOT NULL) THEN
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
        -------------------------------------------------------
        -- ヘッダデータの作成
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_shi_s      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
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
        -- 明細の削除フラグが「Y」の場合、明細データを作成しない。
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_shi_s      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
      END IF ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
--
    -------------------------------------------------------
    -- データタイプ：移動
    -------------------------------------------------------
    ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_mov_ins ) THEN
      -------------------------------------------------------
      -- 可変項目編集
      -------------------------------------------------------
      -- ドリンク製品の場合
      IF (   ( gt_main_data(in_idx).prod_class = gc_prod_class_d )
         AND ( gt_main_data(in_idx).item_class = gc_item_class_i ) ) THEN
--
        -- 品目単位
        lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                                ,gt_main_data(in_idx).item_uom_code ) ;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
        -- 入出庫換算単位≠NULLの場合
        IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
          -- 品目数量
          lv_item_quantity := gt_main_data(in_idx).item_quantity
                            / gt_main_data(in_idx).case_quantity ;
          --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;       --2008/08/12 Del 課題#32
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
        -- 入出庫換算単位＝NULLの場合
        ELSE
          lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- 品目数量
        END IF;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
--
      ELSE
--
        lv_item_uom_code := gt_main_data(in_idx).item_uom_code  ;   -- 品目単位
        lv_item_quantity := gt_main_data(in_idx).item_quantity  ;   -- 品目数量
--
      END IF ;
--
      -------------------------------------------------------
      -- ヘッダデータの作成
      -------------------------------------------------------
      IF ( iv_break_flg = gc_yes_no_y ) THEN
        -------------------------------------------------------
        -- 移動出庫の作成
        -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        -- EOS宛先（出庫倉庫）が設定されている場合
        IF (gt_main_data(in_idx).eos_shipped_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_locat ;   -- ＥＯＳ宛先（ＣＳＶ）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_s      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
--
        -------------------------------------------------------
        -- 移動入庫の作成
        -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        -- EOS宛先（入庫倉庫）が設定されている場合
        IF (gt_main_data(in_idx).eos_shipped_to_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_to_locat ;   -- ＥＯＳ宛先（ＣＳＶ）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_in ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_n      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_to_locat  -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
      END IF ;
--
      -- 明細の削除フラグが「Y」の場合、明細データを作成しない。
      IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          -------------------------------------------------------
          -- 明細データの作成（移動出庫）
          -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        -- EOS宛先（出庫倉庫）が設定されている場合
        IF (gt_main_data(in_idx).eos_shipped_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_locat ;   -- ＥＯＳ宛先（ＣＳＶ）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_s      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat      => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
        -------------------------------------------------------
        -- 明細データの作成（移動入庫）
        -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        -- EOS宛先（入庫倉庫）が設定されている場合
        IF (gt_main_data(in_idx).eos_shipped_to_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_to_locat ;   -- ＥＯＳ宛先（ＣＳＶ）
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_n      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_to_locat  -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
      END IF ;
--
    END IF ;
--
    -- =============================================================================================
    -- 配送依頼データ作成
    -- =============================================================================================
    lv_eos_csv_output := lv_eos_freight_carrier ;   -- ＥＯＳ宛先（ＣＳＶ）
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
/***
       AND ( lv_eos_freight_carrier <> lv_eos_shipped_locat ) ) THEN
***/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/*****
    IF (   ( lv_eos_freight_carrier IS NOT NULL             )
       AND ( lv_eos_freight_carrier <> NVL(lv_eos_shipped_locat   ,lv_eos_shipped_to_locat))
       AND ( lv_eos_freight_carrier <> NVL(lv_eos_shipped_to_locat, lv_eos_shipped_locat))) THEN
*****/
    -- 運送業者のEOS宛先が設定せれていて、出庫のEOSと異なる場合
    --   配送依頼データを出力する
    --   入庫倉庫と同一の場合は、配送依頼を出力する
    IF  ( lv_eos_freight_carrier  IS NOT NULL )
-- ##### 20081006 Ver.1.21 統合#306対応 START #####
/*****
    AND ((lv_eos_shipped_locat    IS NULL) OR ( lv_eos_freight_carrier <> lv_eos_shipped_locat))
    AND ((lv_eos_shipped_to_locat IS NULL) OR ( lv_eos_freight_carrier <> lv_eos_shipped_to_locat)) THEN
*****/
    AND ((lv_eos_shipped_locat IS NULL) OR ( lv_eos_freight_carrier <> lv_eos_shipped_locat )) THEN
-- ##### 20081006 Ver.1.21 統合#306対応 END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
      -------------------------------------------------------
      -- データタイプ：出荷
      -------------------------------------------------------
      IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
        -------------------------------------------------------
        -- 可変項目編集
        -------------------------------------------------------
        lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
--
        -- 品目単位
        lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                                ,gt_main_data(in_idx).item_uom_code ) ;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
      -- 入出庫換算単位≠NULLの場合
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
        lv_item_quantity := gt_main_data(in_idx).item_quantity
                          / gt_main_data(in_idx).case_quantity ;
        --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;      --2008/08/12 Del 課題#32
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
      -- 入出庫換算単位＝NULLの場合
      ELSE
        lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- 品目数量
      END IF;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
--
        -------------------------------------------------------
        -- ヘッダデータの作成
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_syu_h      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat   -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
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
        -- 明細の削除フラグが「Y」の場合、明細データを作成しない。
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_syu_h      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
--
      -------------------------------------------------------
      -- データタイプ：支給
      -------------------------------------------------------
      ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_shi_ins ) THEN
        -------------------------------------------------------
        -- 可変項目編集
        -------------------------------------------------------
        lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
        lv_item_uom_code       := gt_main_data(in_idx).item_uom_code  ;           -- 品目単位
        lv_item_quantity       := gt_main_data(in_idx).item_quantity ;            -- 品目数量
--
        -------------------------------------------------------
        -- ヘッダデータの作成
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_shi_h      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
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
        -- 明細の削除フラグが「Y」の場合、明細データを作成しない。
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_shi_h      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
--
      -------------------------------------------------------
      -- データタイプ：移動
      -------------------------------------------------------
      ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_mov_ins ) THEN
        -------------------------------------------------------
        -- 可変項目編集
        -------------------------------------------------------
      -- ドリンク製品の場合
      IF (   ( gt_main_data(in_idx).prod_class = gc_prod_class_d )
         AND ( gt_main_data(in_idx).item_class = gc_item_class_i ) ) THEN
--
        -- 品目単位
        lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                                ,gt_main_data(in_idx).item_uom_code ) ;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
        -- 入出庫換算単位≠NULLの場合
        IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
          -- 品目数量
          lv_item_quantity := gt_main_data(in_idx).item_quantity
                            / gt_main_data(in_idx).case_quantity ;
          --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;      --2008/08/12 Del 課題#32
-- ##### 20080627 Ver.1.11 ロット数量換算対応 START #####
--
        -- 入出庫換算単位＝NULLの場合
        ELSE
          lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- 品目数量
        END IF;
-- ##### 20080627 Ver.1.11 ロット数量換算対応 END   #####
--
      ELSE
--
        lv_item_uom_code := gt_main_data(in_idx).item_uom_code  ;   -- 品目単位
        lv_item_quantity := gt_main_data(in_idx).item_quantity  ;   -- 品目数量
--
      END IF ;
--
        -------------------------------------------------------
        -- ヘッダデータの作成
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          -------------------------------------------------------
          -- 移動出庫の作成
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_h      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
/***
          -------------------------------------------------------
          -- 移動入庫の作成
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_in ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_n      -- データ種別
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- パレット使用枚数
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
***/
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
        END IF ;
--
        -- 明細の削除フラグが「Y」の場合、明細データを作成しない。
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          -------------------------------------------------------
          -- 明細データの作成（移動出庫）
          -------------------------------------------------------
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_h      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS宛先
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS宛先対応 START #####
/***
          -------------------------------------------------------
          -- 明細データの作成（移動入庫）
          -------------------------------------------------------
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- 対象データ
             ,iv_data_class           => gc_data_class_mov_n      -- データ種別
             ,iv_item_uom_code        => lv_item_uom_code         -- 品目単位
             ,iv_item_quantity        => lv_item_quantity         -- 品目数量
             ,iv_eos_csv_output       => lv_eos_csv_output        -- ＥＯＳ宛先（ＣＳＶ）
             ,ov_errbuf               => lv_errbuf                -- エラー・メッセージ
             ,ov_retcode              => lv_retcode               -- リターン・コード
             ,ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
***/
-- ##### 20080623 Ver.1.9 EOS宛先対応 END   #####
        END IF ;
--
      END IF ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- ＥＯＳ宛先エラー
    -- =============================================================================================
    WHEN ex_eos_error THEN
      -- エラーメッセージ取得
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code_eos
                       ,iv_token_name1    => lc_tok_name_eos
                       ,iv_token_value1   => lv_tok_val
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
    -- =============================================================================================
    -- ケース入り数エラー
    -- =============================================================================================
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
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_create_ins_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_can_data
   * Description      : 変更前情報取消データ作成処理(E-06)
   ************************************************************************************************/
  PROCEDURE prc_create_can_data
    (
      iv_request_no           IN  xxwsh_stock_delivery_info_tmp.request_no%TYPE
     ,iv_eos_shipped_locat    IN  xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
     ,iv_eos_freight_carrier  IN  xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_can_data' ; -- プログラム名
-- ##### 20080612 Ver.1.8 440不具合対応#68 START #####
    lc_transfer_branch_no_h     CONSTANT VARCHAR2(100) := '10' ;    -- ヘッダ
-- ##### 20080612 Ver.1.8 440不具合対応#68 END   #####
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
      (
        p_request_no            xxwsh_stock_delivery_info_tmp.request_no%TYPE
       ,p_eos_shipped_locat     xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
       ,p_eos_freight_carrier   xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE
      )
    IS
      SELECT xndi.corporation_name            -- 会社名
            ,xndi.data_class                  -- データ種別
            ,xndi.transfer_branch_no          -- 伝送用枝番
            ,xndi.delivery_no                 -- 配送No
            ,xndi.request_no                  -- 依頼No
            ,xndi.reserve                     -- 予備
            ,xndi.head_sales_branch           -- 拠点コード
            ,xndi.head_sales_branch_name      -- 管轄拠点名称
            ,xndi.shipped_locat_code          -- 出庫倉庫コード
            ,xndi.shipped_locat_name          -- 出庫倉庫名称
            ,xndi.ship_to_locat_code          -- 入庫倉庫コード
            ,xndi.ship_to_locat_name          -- 入庫倉庫名称
            ,xndi.freight_carrier_code        -- 運送業者コード
            ,xndi.freight_carrier_name        -- 運送業者名
            ,xndi.deliver_to                  -- 配送先コード
            ,xndi.deliver_to_name             -- 配送先名
            ,xndi.schedule_ship_date          -- 発日
            ,xndi.schedule_arrival_date       -- 着日
            ,xndi.shipping_method_code        -- 配送区分
            ,xndi.weight                      -- 重量/容積
            ,xndi.mixed_no                    -- 混載元依頼№
            ,xndi.collected_pallet_qty        -- パレット回収枚数
            ,xndi.arrival_time_from           -- 着荷時間指定(FROM)
            ,xndi.arrival_time_to             -- 着荷時間指定(TO)
            ,xndi.cust_po_number              -- 顧客発注番号
            ,xndi.description                 -- 摘要
            ,xndi.status                      -- ステータス
            ,xndi.freight_charge_class        -- 運賃区分
            ,xndi.pallet_sum_quantity         -- パレット使用枚数
            ,xndi.reserve1                    -- 予備１
            ,xndi.reserve2                    -- 予備２
            ,xndi.reserve3                    -- 予備３
            ,xndi.reserve4                    -- 予備４
            ,xndi.report_dept                 -- 報告部署
            ,xndi.item_code                   -- 品目コード
            ,xndi.item_name                   -- 品目名
            ,xndi.item_uom_code               -- 品目単位
            ,xndi.item_quantity               -- 品目数量
            ,xndi.lot_no                      -- ロット番号
            ,xndi.lot_date                    -- 製造日
            ,xndi.best_bfr_date               -- 賞味期限
            ,xndi.lot_sign                    -- 固有記号
            ,xndi.lot_quantity                -- ロット数量
            ,xndi.new_modify_del_class        -- データ区分
            ,xndi.update_date                 -- 更新日時
            ,xndi.line_number                 -- 明細番号
            ,xndi.data_type                   -- データタイプ
            ,xndi.eos_shipped_locat           -- EOS宛先（出庫倉庫）
            ,xndi.eos_freight_carrier         -- EOS宛先（運送業者）
            ,xndi.eos_csv_output              -- EOS宛先（CSV出力）
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xndi.notif_date                  -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
      FROM xxwsh_notif_delivery_info  xndi
      WHERE xndi.request_no = p_request_no
      ORDER BY xndi.request_no                -- 依頼No
              ,xndi.transfer_branch_no        -- 伝送用枝番
              ,xndi.line_number               -- 明細番号
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
    -- 取消データ作成
    -- ====================================================
    <<can_data_loop>>
    FOR re_can_data IN cu_can_data
      ( p_request_no            => iv_request_no
       ,p_eos_shipped_locat     => iv_eos_shipped_locat
       ,p_eos_freight_carrier   => iv_eos_freight_carrier ) LOOP
--
      gn_cre_idx := gn_cre_idx + 1 ;
--
      gt_corporation_name(gn_cre_idx)       := re_can_data.corporation_name ;
      gt_data_class(gn_cre_idx)             := re_can_data.data_class ;
      gt_transfer_branch_no(gn_cre_idx)     := re_can_data.transfer_branch_no ;
      gt_delivery_no(gn_cre_idx)            := re_can_data.delivery_no ;
      gt_request_no(gn_cre_idx)             := re_can_data.request_no ;
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
-- ##### 20080612 Ver.1.8 440不具合対応#68 START #####
      -- 伝送用枝番が「ヘッダ」の場合
      IF (re_can_data.transfer_branch_no =lc_transfer_branch_no_h) THEN
        gt_item_quantity(gn_cre_idx)          := NULL ;
      ELSE
        gt_item_quantity(gn_cre_idx)          := 0 ;
      END IF;
-- ##### 20080612 Ver.1.8 440不具合対応#68 END   #####
--
      gt_lot_no(gn_cre_idx)                 := re_can_data.lot_no ;
      gt_lot_date(gn_cre_idx)               := re_can_data.lot_date ;
      gt_best_bfr_date(gn_cre_idx)          := re_can_data.best_bfr_date ;
      gt_lot_sign(gn_cre_idx)               := re_can_data.lot_sign ;
--
-- ##### 20080612 Ver.1.8 440不具合対応#68 START #####
      -- 伝送用枝番が「ヘッダ」の場合
      IF (re_can_data.transfer_branch_no =lc_transfer_branch_no_h) THEN
        gt_lot_quantity(gn_cre_idx)           := NULL ;
      ELSE
        gt_lot_quantity(gn_cre_idx)           := 0 ;
      END IF;
-- ##### 20080612 Ver.1.8 440不具合対応#68 END   #####
--
      gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_del ;
      gt_update_date(gn_cre_idx)            := SYSDATE ;
      gt_line_number(gn_cre_idx)            := re_can_data.line_number ;
      gt_data_type(gn_cre_idx)              := re_can_data.data_type ;
      gt_eos_shipped_locat(gn_cre_idx)      := re_can_data.eos_shipped_locat ;
      gt_eos_freight_carrier(gn_cre_idx)    := re_can_data.eos_freight_carrier ;
      gt_eos_csv_output(gn_cre_idx)         := re_can_data.eos_csv_output ;
--
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
      gt_notif_date(gn_cre_idx)             := re_can_data.notif_date ;
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    gt_target_request_id(gn_cre_idx)      := gn_request_id;                     -- 要求ID
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
--
    END LOOP can_data_loop ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_create_can_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_data
   * Description      : 一括登録処理(E-07)
   ************************************************************************************************/
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
      INSERT INTO xxwsh_stock_delivery_info_tmp
        (
          corporation_name                                  -- 会社名
         ,data_class                                        -- データ種別
         ,transfer_branch_no                                -- 伝送用枝番
         ,delivery_no                                       -- 配送No
         ,request_no                                        -- 依頼No
         ,reserve                                           -- 予備
         ,head_sales_branch                                 -- 拠点コード
         ,head_sales_branch_name                            -- 管轄拠点名称
         ,shipped_locat_code                                -- 出庫倉庫コード
         ,shipped_locat_name                                -- 出庫倉庫名称
         ,ship_to_locat_code                                -- 入庫倉庫コード
         ,ship_to_locat_name                                -- 入庫倉庫名称
         ,freight_carrier_code                              -- 運送業者コード
         ,freight_carrier_name                              -- 運送業者名
         ,deliver_to                                        -- 配送先コード
         ,deliver_to_name                                   -- 配送先名
         ,schedule_ship_date                                -- 発日
         ,schedule_arrival_date                             -- 着日
         ,shipping_method_code                              -- 配送区分
         ,weight                                            -- 重量/容積
         ,mixed_no                                          -- 混載元依頼№
         ,collected_pallet_qty                              -- パレット回収枚数
         ,arrival_time_from                                 -- 着荷時間指定(FROM)
         ,arrival_time_to                                   -- 着荷時間指定(TO)
         ,cust_po_number                                    -- 顧客発注番号
         ,description                                       -- 摘要
         ,status                                            -- ステータス
         ,freight_charge_class                              -- 運賃区分
         ,pallet_sum_quantity                               -- パレット使用枚数
         ,reserve1                                          -- 予備１
         ,reserve2                                          -- 予備２
         ,reserve3                                          -- 予備３
         ,reserve4                                          -- 予備４
         ,report_dept                                       -- 報告部署
         ,item_code                                         -- 品目コード
         ,item_name                                         -- 品目名
         ,item_uom_code                                     -- 品目単位
         ,item_quantity                                     -- 品目数量
         ,lot_no                                            -- ロット番号
         ,lot_date                                          -- 製造日
         ,best_bfr_date                                     -- 賞味期限
         ,lot_sign                                          -- 固有記号
         ,lot_quantity                                      -- ロット数量
         ,new_modify_del_class                              -- データ区分
         ,update_date                                       -- 更新日時
         ,line_number                                       -- 明細番号
         ,data_type                                         -- データタイプ
         ,eos_shipped_locat                                 -- EOS宛先（出庫倉庫）
         ,eos_freight_carrier                               -- EOS宛先（運送業者）
         ,eos_csv_output                                    -- EOS宛先（CSV出力）
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
         ,notif_date                                        -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
         ,target_request_id                                 -- 要求ID
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
        )
      VALUES
        (
          gt_corporation_name(ln_cnt)             -- 会社名
         ,gt_data_class(ln_cnt)                   -- データ種別
         ,gt_transfer_branch_no(ln_cnt)           -- 伝送用枝番
         ,gt_delivery_no(ln_cnt)                  -- 配送No
         ,gt_request_no(ln_cnt)                   -- 依頼No
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
         ,gt_best_bfr_date(ln_cnt)                -- 賞味期限
         ,gt_lot_sign(ln_cnt)                     -- 固有記号
         ,gt_lot_quantity(ln_cnt)                 -- ロット数量
         ,gt_new_modify_del_class(ln_cnt)         -- データ区分
         ,gt_update_date(ln_cnt)                  -- 更新日時
         ,gt_line_number(ln_cnt)                  -- 明細番号
         ,gt_data_type(ln_cnt)                    -- データタイプ
         ,gt_eos_shipped_locat(ln_cnt)            -- EOS宛先（出庫倉庫）
         ,gt_eos_freight_carrier(ln_cnt)          -- EOS宛先（運送業者）
         ,gt_eos_csv_output(ln_cnt)               -- EOS宛先（CSV出力）
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
         ,gt_notif_date(ln_cnt)                   -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
         ,gt_target_request_id(ln_cnt)            -- 要求ID
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
        ) ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_ins_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_out_csv_data
   * Description      : ＣＳＶ出力処理(E-08,E-09)
   ************************************************************************************************/
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
-- M.Hokkanji Ver1.4 START
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- 明細
-- M.Hokkanji Ver1.4 END
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
    cv_cr         CONSTANT VARCHAR2(1)  := CHR(13); -- 改行コード
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
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
--
-- ##### 20080611 Ver.1.6 WF対応 START #####
    lv_dir              VARCHAR2(150) ;         -- ディレクトリ
    lv_file_name        VARCHAR2(150) ;         -- ファイル名
-- ##### 20080611 Ver.1.6 WF対応 END   #####
--
-- M.Hokkanji Ver1.5 START
    lt_new_modify_del_class xxwsh_stock_delivery_info_tmp.new_modify_del_class%TYPE;
-- M.Hokkanji Ver1.5 END
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    ----------------------------------------
    -- ＥＯＳ宛先
    ----------------------------------------
    CURSOR cu_eos_data
    IS
      SELECT DISTINCT xsdit.eos_csv_output
      FROM  xxwsh_stock_delivery_info_tmp    xsdit
-- ##### 20081020 Ver.1.24 統合#417対応 START #####
      WHERE xsdit.target_request_id = gn_request_id    -- 要求ID
-- ##### 20081020 Ver.1.24 統合#417対応 END   #####
      ORDER BY xsdit.eos_csv_output
    ;
    ----------------------------------------
    -- ＥＯＳ宛先
    ----------------------------------------
    CURSOR cu_out_data
      ( p_eos_csv_output    xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE )
    IS
      SELECT xsdit.corporation_name         -- 会社名
            ,xsdit.data_class               -- データ種別
            ,xsdit.transfer_branch_no       -- 伝送用枝番
            ,xsdit.delivery_no              -- 配送No
            ,xsdit.request_no               -- 依頼No
            ,xsdit.reserve                  -- 予備
            ,xsdit.head_sales_branch        -- 拠点コード
            ,xsdit.head_sales_branch_name   -- 管轄拠点名称
            ,xsdit.shipped_locat_code       -- 出庫倉庫コード
            ,xsdit.shipped_locat_name       -- 出庫倉庫名称
            ,xsdit.ship_to_locat_code       -- 入庫倉庫コード
            ,xsdit.ship_to_locat_name       -- 入庫倉庫名称
            ,xsdit.freight_carrier_code     -- 運送業者コード
            ,xsdit.freight_carrier_name     -- 運送業者名
            ,xsdit.deliver_to               -- 配送先コード
            ,xsdit.deliver_to_name          -- 配送先名
            ,xsdit.schedule_ship_date       -- 発日
            ,xsdit.schedule_arrival_date    -- 着日
            ,xsdit.shipping_method_code     -- 配送区分
            ,xsdit.weight                   -- 重量/容積
            ,xsdit.mixed_no                 -- 混載元依頼№
            ,xsdit.collected_pallet_qty     -- パレット回収枚数
            ,xsdit.arrival_time_from        -- 着荷時間指定(FROM)
            ,xsdit.arrival_time_to          -- 着荷時間指定(TO)
            ,xsdit.cust_po_number           -- 顧客発注番号
            ,xsdit.description              -- 摘要
            ,xsdit.status                   -- ステータス
            ,xsdit.freight_charge_class     -- 運賃区分
            ,xsdit.pallet_sum_quantity      -- パレット使用枚数
            ,xsdit.reserve1                 -- 予備１
            ,xsdit.reserve2                 -- 予備２
            ,xsdit.reserve3                 -- 予備３
            ,xsdit.reserve4                 -- 予備４
            ,xsdit.report_dept              -- 報告部署
            ,xsdit.item_code                -- 品目コード
            ,xsdit.item_name                -- 品目名
            ,xsdit.item_uom_code            -- 品目単位
            ,xsdit.item_quantity            -- 品目数量
            ,xsdit.lot_no                   -- ロット番号
            ,xsdit.lot_date                 -- 製造日
            ,xsdit.best_bfr_date            -- 賞味期限
            ,xsdit.lot_sign                 -- 固有記号
            ,xsdit.lot_quantity             -- ロット数量
            ,xsdit.new_modify_del_class     -- データ区分
            ,xsdit.update_date              -- 更新日時
            ,xsdit.line_number              -- 明細番号
            ,xsdit.data_type                -- データタイプ
            ,xsdit.eos_shipped_locat        -- EOS宛先（出庫倉庫）
            ,xsdit.eos_freight_carrier      -- EOS宛先（運送業者）
            ,xsdit.eos_csv_output           -- EOS宛先（CSV出力）
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,xsdit.notif_date               -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
      FROM xxwsh_stock_delivery_info_tmp    xsdit
      WHERE xsdit.eos_csv_output = p_eos_csv_output
-- ##### 20081020 Ver.1.24 統合#417対応 START #####
      AND  xsdit.target_request_id = gn_request_id    -- 要求ID
-- ##### 20081020 Ver.1.24 統合#417対応 END   #####
      ORDER BY xsdit.new_modify_del_class   DESC    -- データ区分   （降順）
              ,xsdit.data_type                      -- データタイプ （昇順）
              ,xsdit.data_class                     -- データ種別   （昇順）
              ,xsdit.request_no                     -- 依頼No       （昇順）
              ,xsdit.transfer_branch_no             -- 伝送用枝番   （昇順）
              ,xsdit.line_number                    -- 明細番号     （昇順）
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
    -- ＥＯＳ宛先（ＣＳＶ）データ抽出
    -- ====================================================
    <<eos_loop>>
    FOR re_eos_data IN cu_eos_data LOOP
--
      -- ====================================================
      -- 出力データ抽出
      -- ====================================================
      <<out_loop>>
      FOR re_out_data IN cu_out_data
        ( p_eos_csv_output => re_eos_data.eos_csv_output ) LOOP
-- M.Hokkanji Ver1.4 START
        IF (re_out_data.transfer_branch_no = lc_transfer_branch_no_d ) THEN
          lt_new_modify_del_class := re_out_data.new_modify_del_class;
        ELSE
          lt_new_modify_del_class := NULL;
        END IF;
-- M.Hokkanji Ver1.4 END
--
-- ##### 20080611 Ver.1.6 WF対応 START #####
--
        -- ====================================================
        -- ファイルOPEN チェック
        -- ====================================================
        IF ( UTL_FILE.IS_OPEN(lf_file_hand) = FALSE) THEN
--
          -------------------------------------------------------
          -- ワークフロー情報取得：処理区分
          -------------------------------------------------------
          lv_wf_ope_div := gc_wf_ope_div;
--
          -------------------------------------------------------
          -- ワークフロー情報取得：対象
          -------------------------------------------------------
          -- EOS宛先（CSV出力）＝ EOS宛先（出庫倉庫）の場合
          IF ( re_out_data.eos_csv_output = re_out_data.eos_shipped_locat ) THEN
            -- 外部倉庫
            lv_wf_class := gc_wf_class_gai ;
--
          -- EOS宛先（CSV出力）≠ EOS宛先（出庫倉庫）の場合
          ELSE
            -- 運送業者
            lv_wf_class := gc_wf_class_uns ;
          END IF ;
--
          -------------------------------------------------------
          -- ワークフロー情報取得：宛先
          -------------------------------------------------------
          lv_wf_notification := re_out_data.eos_csv_output;
--
          -------------------------------------------------------
          -- ワークフロー関連情報取得
          -------------------------------------------------------
          xxwsh_common3_pkg.get_wsh_wf_info(  
                            iv_wf_ope_div       => lv_wf_ope_div      -- 処理区分
                          , iv_wf_class         => lv_wf_class        -- 対象
                          , iv_wf_notification  => lv_wf_notification -- 宛先
                          , or_wf_whs_rec       => gr_wf_whs_rec      -- ファイル情報
                          , ov_errbuf           => lv_errbuf          -- エラー・メッセージ
                          , ov_retcode          => lv_retcode         -- リターン・コード
                          , ov_errmsg           => lv_errmsg);        -- ユーザー・エラー・メッセージ
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
--
          -------------------------------------------------------
          -- ファイル出力情報設定
          -------------------------------------------------------
          -- ディレクトリ
          lv_dir        :=  gr_wf_whs_rec.directory;
          -- ファイル名（処理区分'-'EOS宛先'_'YYYYMMDDHH24MISS'_'クイックコードファイル名）
          lv_file_name  :=  lv_wf_ope_div               || '-' || 
                            re_out_data.eos_csv_output  || '_' || 
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
--                            gv_filetimes                || '_' ||
                            gv_filetimes                ||
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
                            gr_wf_whs_rec.file_name ;
--
-- ##### 20081112 Ver.1.27 統合#626対応 START #####
          -- WFオーナーを起動ユーザへ変更
          gr_wf_whs_rec.wf_owner := gv_exec_user;
-- ##### 20081112 Ver.1.27 統合#626対応 END   #####
--
          -------------------------------------------------------
          -- ＵＴＬファイルオープン
          -------------------------------------------------------
          lf_file_hand := UTL_FILE.FOPEN( lv_dir         -- ディレクトリ
                                         ,lv_file_name  -- ファイル名
                                         ,'w') ;        -- モード（上書）
--
        END IF;
-- ##### 20080611 Ver.1.6 WF対応 END   #####
--
        -- ====================================================
        -- 出力文字列編集
        -- ====================================================
        lv_csv_text := re_out_data.corporation_name         || ','    -- 会社名
                    || re_out_data.data_class               || ','    -- データ種別
                    || re_out_data.transfer_branch_no       || ','    -- 伝送用枝番
                    || re_out_data.delivery_no              || ','    -- 配送No
                    || re_out_data.request_no               || ','    -- 依頼No
                    || re_out_data.reserve                  || ','    -- 予備
                    || re_out_data.head_sales_branch        || ','    -- 拠点コード
                    || REPLACE(re_out_data.head_sales_branch_name,',') || ','    -- 管轄拠点名称
                    || re_out_data.shipped_locat_code       || ','    -- 出庫倉庫コード
                    || REPLACE(re_out_data.shipped_locat_name,',')     || ','    -- 出庫倉庫名称
                    || re_out_data.ship_to_locat_code       || ','    -- 入庫倉庫コード
                    || REPLACE(re_out_data.ship_to_locat_name,',')     || ','    -- 入庫倉庫名称
                    || re_out_data.freight_carrier_code     || ','    -- 運送業者コード
                    || REPLACE(re_out_data.freight_carrier_name,',')   || ','    -- 運送業者名
                    || re_out_data.deliver_to               || ','    -- 配送先コード
                    || REPLACE(re_out_data.deliver_to_name,',')        || ','    -- 配送先名
                    || TO_CHAR( re_out_data.schedule_ship_date   , 'YYYY/MM/DD' ) || ','
                    || TO_CHAR( re_out_data.schedule_arrival_date, 'YYYY/MM/DD' ) || ','
                    || re_out_data.shipping_method_code     || ','    -- 配送区分
                    --|| re_out_data.weight                   || ','    -- 重量/容積 --2008/08/12 Del 課題#48(変更#164)
-- 2009/01/26 v1.30 N.Yoshida UPDATE START
--                    || CEIL(TRUNC(re_out_data.weight,3))    || ','    -- 重量/容積   --2008/08/12 Add 課題#48(変更#164)
                    || TRUNC(re_out_data.weight + 0.9)      || ','    -- 重量/容積
-- 2009/01/26 v1.30 N.Yoshida UPDATE END
                    || re_out_data.mixed_no                 || ','    -- 混載元依頼№
                    || re_out_data.collected_pallet_qty     || ','    -- パレット回収枚数
                    || re_out_data.arrival_time_from        || ','    -- 着荷時間指定(FROM)
                    || re_out_data.arrival_time_to          || ','    -- 着荷時間指定(TO)
-- ##### 20091203 Ver1.33 本番#276 START #####
--                    || re_out_data.cust_po_number           || ','    -- 顧客発注番号
                    || REPLACE(re_out_data.cust_po_number,',')         || ','    -- 顧客発注番号
-- ##### 20091203 Ver1.33 本番#276 END #####
                    || REPLACE(re_out_data.description,',')            || ','    -- 摘要
                    || re_out_data.status                   || ','    -- ステータス
                    || re_out_data.freight_charge_class     || ','    -- 運賃区分
                    || re_out_data.pallet_sum_quantity      || ','    -- パレット使用枚数
                    || re_out_data.reserve1                 || ','    -- 予備１
                    || re_out_data.reserve2                 || ','    -- 予備２
                    || re_out_data.reserve3                 || ','    -- 予備３
                    || re_out_data.reserve4                 || ','    -- 予備４
                    || re_out_data.report_dept              || ','    -- 報告部署
                    || re_out_data.item_code                || ','    -- 品目コード
                    || REPLACE(re_out_data.item_name,',')              || ','    -- 品目名
                    || re_out_data.item_uom_code            || ','    -- 品目単位
                    --|| re_out_data.item_quantity            || ','    -- 品目数量 --2008/08/12 Del 課題#32
-- ##### 20090209 Ver.1.31 本番1082対応 START #####
--                    || CEIL(TRUNC(re_out_data.item_quantity,3)) || ','  -- 品目数量 --2008/08/12 Add 課題#32
                    || TRUNC(re_out_data.item_quantity + 0.0009 ,3) || ',' -- 品目数量（小数点以下3位まで有効（第四位を切上））
-- ##### 20090209 Ver.1.31 本番1082対応 END   #####
                    || re_out_data.lot_no                   || ','    -- ロット番号
                    || TO_CHAR( re_out_data.lot_date     , 'YYYY/MM/DD' ) || ','
                    || TO_CHAR( re_out_data.best_bfr_date, 'YYYY/MM/DD' ) || ','
                    || re_out_data.lot_sign                 || ','    -- 固有記号
                    --|| re_out_data.lot_quantity             || ','    -- ロット数量 --2008/08/12 Del 課題#32
-- ##### 20090209 Ver.1.31 本番1082対応 START #####
--                    || CEIL(TRUNC(re_out_data.lot_quantity,3)) || ','   -- ロット数量 --2008/08/12 Add 課題#32
                    || TRUNC(re_out_data.lot_quantity+ 0.0009 ,3) || ','   -- ロット数量（小数点以下3位まで有効（第四位を切上））
-- ##### 20090209 Ver.1.31 本番1082対応 END   #####
-- M.Hokkanji Ver1.4 STRAT
                    || lt_new_modify_del_class              || ','    -- データ区分
--                    || re_out_data.new_modify_del_class     || ','    -- データ区分
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
--                    || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' );
                    || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' )
                    || cv_cr;                                         -- 改行コード(CR)
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
--
--                    || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' ) || ','
--                    || re_out_data.line_number              || ','    -- 明細番号
--                    || re_out_data.data_type                || ','    -- データタイプ
--                    || re_out_data.eos_shipped_locat        || ','    -- EOS宛先（出庫倉庫）
--                    || re_out_data.eos_freight_carrier      || ','    -- EOS宛先（運送業者）
--                    || re_out_data.eos_csv_output                     -- EOS宛先（CSV出力）
--                    ;
-- M.Hokkanji Ver1.4 END
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
        IF ( re_out_data.data_type IN( gc_data_type_syu_ins
                                      ,gc_data_type_syu_can ) ) THEN
          gn_out_cnt_syu := gn_out_cnt_syu + 1 ;
--
        -------------------------------------------------------
        -- 支給データ
        -------------------------------------------------------
        ELSIF ( re_out_data.data_type IN( gc_data_type_shi_ins
                                         ,gc_data_type_shi_can ) ) THEN
          gn_out_cnt_shi := gn_out_cnt_shi + 1 ;
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
-- ##### 20080611 Ver.1.6 WF対応 START #####
      -- ====================================================
      -- ワークフロー通知
      -- ====================================================
      xxwsh_common3_pkg.wf_whs_start( 
                    ir_wf_whs_rec => gr_wf_whs_rec      -- ワークフロー関連情報
                   ,iv_filename   => lv_file_name       -- ファイル名
                   ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ
                   ,ov_retcode    => lv_retcode         -- リターン・コード
                   ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
-- ##### 20080611 Ver.1.6 WF対応 END   #####
--
-- ##### 20081023 Ver.1.25 T_S_440対応 START #####
      -- ====================================================
      -- 通知先情報作成
      -- ====================================================
      -- 件数インクリメント
      gn_notif_idx := gn_notif_idx + 1;
--
      -- EOS宛先設定(EOSの後ろに幅調整のため全角SPASE設定)
      gt_notif_msg(gn_notif_idx) := gr_wf_whs_rec.wf_notification || '　　　　';
--
      -- 通知先設定
      IF (gr_wf_whs_rec.user_cd01 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || gr_wf_whs_rec.user_cd01;
      END IF;
      IF (gr_wf_whs_rec.user_cd02 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd02;
      END IF;
      IF (gr_wf_whs_rec.user_cd03 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd03;
      END IF;
      IF (gr_wf_whs_rec.user_cd04 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd04;
      END IF;
      IF (gr_wf_whs_rec.user_cd05 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd05;
      END IF;
      IF (gr_wf_whs_rec.user_cd06 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd06;
      END IF;
      IF (gr_wf_whs_rec.user_cd07 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd07;
      END IF;
      IF (gr_wf_whs_rec.user_cd08 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd08;
      END IF;
      IF (gr_wf_whs_rec.user_cd09 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd09;
      END IF;
      IF (gr_wf_whs_rec.user_cd10 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd10;
      END IF;
-- ##### 20081023 Ver.1.25 T_S_440対応 END   #####
--
    END LOOP eos_loop ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- M.HOKKANJI Ver1.3 START
--      UTL_FILE.FCLOSE_ALL ;
      IF ( UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
-- M.HOKKANJI Ver1.3 END
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- M.HOKKANJI Ver1.3 START
--      UTL_FILE.FCLOSE_ALL ;
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
-- M.HOKKANJI Ver1.3 END
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- M.HOKKANJI Ver1.3 START
--      UTL_FILE.FCLOSE_ALL ;
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
-- M.HOKKANJI Ver1.3 END
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_out_csv_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_out_data
   * Description      : 通知済みデータ登録処理(E-11,E-12)
   ************************************************************************************************/
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
    -- 変数宣言
    -- ==================================================
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    ----------------------------------------
    -- 削除対象データ
    ----------------------------------------
    CURSOR cu_del_data
    IS
      SELECT xndi.request_no
      FROM xxwsh_notif_delivery_info    xndi
      WHERE xndi.request_no IN
        ( SELECT DISTINCT xsdit.request_no
          FROM   xxwsh_stock_delivery_info_tmp    xsdit
          WHERE  xsdit.new_modify_del_class = gc_data_class_del 
-- ##### 20081020 Ver.1.24 統合#417対応 START #####
          AND  xsdit.target_request_id = gn_request_id)    -- 要求ID
-- ##### 20081020 Ver.1.24 統合#417対応 END   #####
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
      FROM xxwsh_notif_delivery_info xndi
      WHERE xndi.request_no = re_del_data.request_no
      ;
    END LOOP delete_loop ;
--
    -- ====================================================
    -- ＣＳＶ出力データ登録
    -- ====================================================
    INSERT INTO xxwsh_notif_delivery_info
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            (   notif_delivery_info_id    -- 通知済入出庫配送計画情報ID
              , corporation_name          -- 会社名
              , data_class                -- データ種別
              , transfer_branch_no        -- 伝送用枝番
              , delivery_no               -- 配送No
              , request_no                -- 依頼No
              , reserve                   -- 予備
              , head_sales_branch         -- 拠点コード
              , head_sales_branch_name    -- 管轄拠点名称
              , shipped_locat_code        -- 出庫倉庫コード
              , shipped_locat_name        -- 出庫倉庫名称
              , ship_to_locat_code        -- 入庫倉庫コード
              , ship_to_locat_name        -- 入庫倉庫名称
              , freight_carrier_code      -- 運送業者コード
              , freight_carrier_name      -- 運送業者名
              , deliver_to                -- 配送先コード
              , deliver_to_name           -- 配送先名
              , schedule_ship_date        -- 発日
              , schedule_arrival_date     -- 着日
              , shipping_method_code      -- 配送区分
              , weight                    -- 重量/容積
              , mixed_no                  -- 混載元依頼№
              , collected_pallet_qty      -- パレット回収枚数
              , arrival_time_from         -- 着荷時間指定(FROM)
              , arrival_time_to           -- 着荷時間指定(TO)
              , cust_po_number            -- 顧客発注番号
              , description               -- 摘要
              , status                    -- ステータス
              , freight_charge_class      -- 運賃区分
              , pallet_sum_quantity       -- パレット使用枚数
              , reserve1                  -- 予備１
              , reserve2                  -- 予備２
              , reserve3                  -- 予備３
              , reserve4                  -- 予備４
              , report_dept               -- 報告部署
              , item_code                 -- 品目コード
              , item_name                 -- 品目名
              , item_uom_code             -- 品目単位
              , item_quantity             -- 品目数量
              , lot_no                    -- ロット番号
              , lot_date                  -- 製造日
              , best_bfr_date             -- 賞味期限
              , lot_sign                  -- 固有記号
              , lot_quantity              -- ロット数量
              , new_modify_del_class      -- データ区分
              , update_date               -- 更新日時
              , line_number               -- 明細番号
              , data_type                 -- データタイプ
              , eos_shipped_locat         -- EOS宛先(出庫倉庫)
              , eos_freight_carrier       -- EOS宛先(運送業者)
              , eos_csv_output            -- EOS宛先(CSV出力)
              , notif_date                -- 確定通知実施日時
              , created_by                -- 作成者
              , creation_date             -- 作成日
              , last_updated_by           -- 最終更新者
              , last_update_date          -- 最終更新日
              , last_update_login         -- 最終更新ログイン
              , request_id                -- 要求ID
              , program_application_id    -- コンカレント・プログラム・アプリケーションID
              , program_id                -- コンカレント・プログラムID
              , program_update_date       -- プログラム更新日
            )
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
      SELECT xxwsh_notif_delivery_info_s1.NEXTVAL   -- 通知済入出庫配送計画情報ID
            ,corporation_name         -- 会社名
            ,data_class               -- データ種別
            ,transfer_branch_no       -- 伝送用枝番
            ,delivery_no              -- 配送No
            ,request_no               -- 依頼No
            ,reserve                  -- 予備
            ,head_sales_branch        -- 拠点コード
            ,head_sales_branch_name   -- 管轄拠点名称
            ,shipped_locat_code       -- 出庫倉庫コード
            ,shipped_locat_name       -- 出庫倉庫名称
            ,ship_to_locat_code       -- 入庫倉庫コード
            ,ship_to_locat_name       -- 入庫倉庫名称
            ,freight_carrier_code     -- 運送業者コード
            ,freight_carrier_name     -- 運送業者名
            ,deliver_to               -- 配送先コード
            ,deliver_to_name          -- 配送先名
            ,schedule_ship_date       -- 発日
            ,schedule_arrival_date    -- 着日
            ,shipping_method_code     -- 配送区分
            ,weight                   -- 重量/容積
            ,mixed_no                 -- 混載元依頼№
            ,collected_pallet_qty     -- パレット回収枚数
            ,arrival_time_from        -- 着荷時間指定(FROM)
            ,arrival_time_to          -- 着荷時間指定(TO)
            ,cust_po_number           -- 顧客発注番号
            ,description              -- 摘要
            ,status                   -- ステータス
            ,freight_charge_class     -- 運賃区分
            ,pallet_sum_quantity      -- パレット使用枚数
            ,reserve1                 -- 予備１
            ,reserve2                 -- 予備２
            ,reserve3                 -- 予備３
            ,reserve4                 -- 予備４
            ,report_dept              -- 報告部署
            ,item_code                -- 品目コード
            ,item_name                -- 品目名
            ,item_uom_code            -- 品目単位
            ,item_quantity            -- 品目数量
            ,lot_no                   -- ロット番号
            ,lot_date                 -- 製造日
            ,best_bfr_date            -- 賞味期限
            ,lot_sign                 -- 固有記号
            ,lot_quantity             -- ロット数量
            ,new_modify_del_class     -- データ区分
            ,update_date              -- 更新日時
            ,line_number              -- 明細番号
            ,data_type                -- データタイプ
            ,eos_shipped_locat        -- EOS宛先（出庫倉庫）
            ,eos_freight_carrier      -- EOS宛先（運送業者）
            ,eos_csv_output           -- EOS宛先（CSV出力）
-- ##### 20080925 Ver.1.20 統合#26対応 START #####
            ,notif_date               -- 確定通知実施日時
-- ##### 20080925 Ver.1.20 統合#26対応 END   #####
            ,gn_created_by               -- 作成者
            ,SYSDATE                     -- 作成日
            ,gn_last_updated_by          -- 最終更新者
            ,SYSDATE                     -- 最終更新日
            ,gn_last_update_login        -- 最終更新ログイン
            ,gn_request_id               -- 要求ID
            ,gn_program_application_id   -- コンカレント・プログラム・アプリケーションID
            ,gn_program_id               -- コンカレント・プログラムID
            ,SYSDATE                     -- プログラム更新日
      FROM xxwsh_stock_delivery_info_tmp    xsdit
      WHERE xsdit.new_modify_del_class = gc_data_class_ins
-- ##### 20081020 Ver.1.24 統合#417対応 START #####
      AND  xsdit.target_request_id     = gn_request_id    -- 要求ID
-- ##### 20081020 Ver.1.24 統合#417対応 END   #####
    ;
--
  EXCEPTION
    -- =============================================================================================
    -- ロック取得エラー
    -- =============================================================================================
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
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_ins_out_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_dept_code_01     IN  VARCHAR2          -- 01 : 部署_01
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : 部署_02(2008/07/16 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : 部署_03(2008/07/16 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : 部署_04(2008/07/16 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : 部署_05(2008/07/16 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : 部署_06(2008/07/16 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : 部署_07(2008/07/16 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : 部署_08(2008/07/16 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : 部署_09(2008/07/16 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : 部署_10(2008/07/16 Add)
     ,iv_fix_class        IN  VARCHAR2          -- 11 : 予定確定区分
     ,iv_date_cutoff      IN  VARCHAR2          -- 12 : 締め実施日
     ,iv_cutoff_from      IN  VARCHAR2          -- 13 : 締め実施時間From
     ,iv_cutoff_to        IN  VARCHAR2          -- 14 : 締め実施時間To
     ,iv_date_fix         IN  VARCHAR2          -- 15 : 確定通知実施日
     ,iv_fix_from         IN  VARCHAR2          -- 16 : 確定通知実施時間From
     ,iv_fix_to           IN  VARCHAR2          -- 17 : 確定通知実施時間To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
     ,iv_ship_date_from   IN  VARCHAR2          -- 18 : 出庫日From
     ,iv_ship_date_to     IN  VARCHAR2          -- 19 : 出庫日To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
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
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
    lc_msg_code       CONSTANT VARCHAR2(30) := 'APP-XXWSH-11856' ;
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
    -- ==================================================
    -- ローカル変数
    -- ==================================================
    lv_temp_request_no    xxwsh_stock_delivery_info_tmp2.request_no%TYPE := '*' ;
    lv_break_flg          VARCHAR2(1) := gc_yes_no_n ;
    lv_error_flg          VARCHAR2(1) := gc_yes_no_n ;
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
    lv_main_data_flg      VARCHAR2(1) := gc_yes_no_n ;
    lv_can_data_flg       VARCHAR2(1) := gc_yes_no_n ;
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
    lv_zero_can_data_flg  VARCHAR2(1) := gc_yes_no_n ;
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
--
    lv_errbuf             VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode            VARCHAR2(1);     -- リターン・コード
    lv_errmsg             VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    -- 警告処理用 バッファ
    lv_errbuf2            VARCHAR2(5000);  -- エラー・メッセージ
    lv_errmsg2            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
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
    -- =============================================================================================
    -- 初期処理
    -- =============================================================================================
    --------------------------------------------------
    -- グローバル変数の初期化
    --------------------------------------------------
    gn_out_cnt_syu := 0 ;   -- 出力件数：出荷
    gn_out_cnt_shi := 0 ;   -- 出力件数：支給
    gn_out_cnt_mov := 0 ;   -- 出力件数：移動
--
    --------------------------------------------------
    -- パラメータ格納
    --------------------------------------------------
    gr_param.dept_code_01 := iv_dept_code_01 ;                      -- 01 : 部署_01
    gr_param.dept_code_02 := iv_dept_code_02 ;                      -- 02 : 部署_02(2008/07/16 Add)
    gr_param.dept_code_03 := iv_dept_code_03 ;                      -- 03 : 部署_03(2008/07/16 Add)
    gr_param.dept_code_04 := iv_dept_code_04 ;                      -- 04 : 部署_04(2008/07/16 Add)
    gr_param.dept_code_05 := iv_dept_code_05 ;                      -- 05 : 部署_05(2008/07/16 Add)
    gr_param.dept_code_06 := iv_dept_code_06 ;                      -- 06 : 部署_06(2008/07/16 Add)
    gr_param.dept_code_07 := iv_dept_code_07 ;                      -- 07 : 部署_07(2008/07/16 Add)
    gr_param.dept_code_08 := iv_dept_code_08 ;                      -- 08 : 部署_08(2008/07/16 Add)
    gr_param.dept_code_09 := iv_dept_code_09 ;                      -- 09 : 部署_09(2008/07/16 Add)
    gr_param.dept_code_10 := iv_dept_code_10 ;                      -- 10 : 部署_10(2008/07/16 Add)
    gr_param.fix_class   := iv_fix_class ;                          -- 11 : 予定確定区分
    gr_param.date_cutoff := SUBSTR( iv_date_cutoff, 1, 10 ) ;       -- 12 : 締め実施日
    gr_param.cutoff_from := NVL( iv_cutoff_from, gc_time_min ) ;    -- 13 : 締め実施時間From
    gr_param.cutoff_to   := NVL( iv_cutoff_to  , gc_time_max ) ;    -- 14 : 締め実施時間To
    gr_param.date_fix    := SUBSTR( iv_date_fix   , 1, 10 ) ;       -- 15 : 確定通知実施日
    gr_param.fix_from    := NVL( iv_fix_from, gc_time_min ) ;       -- 16 : 確定通知実施時間From
    gr_param.fix_to      := NVL( iv_fix_to  , gc_time_max ) ;       -- 17 : 確定通知実施時間To
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    -- 多重起動確認用（時間に秒を入れる前に設定）
    gv_date_fix :=  iv_date_fix;        -- 確定通知実施日
    gv_fix_from :=  gr_param.fix_from;  -- 確定通知実施時間From
    gv_fix_to   :=  gr_param.fix_to;    -- 確定通知実施時間To
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
    gr_param.cutoff_from := ' ' || gr_param.cutoff_from || ':00' ;
    gr_param.cutoff_to   := ' ' || gr_param.cutoff_to   || ':00' ;
    gr_param.fix_from    := ' ' || gr_param.fix_from    || ':00' ;
    gr_param.fix_to      := ' ' || gr_param.fix_to      || ':00' ;
--
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
    gr_param.ship_date_from := SUBSTR(iv_ship_date_from, 1, 10) ;   -- 出庫日From
    gr_param.ship_date_to   := SUBSTR(iv_ship_date_to,   1, 10) ;   -- 出庫日To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
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
-- ##### 20090113 Ver.1.29 本番#971対応 START #####
--    -- =============================================================================================
--    -- E-01 パラメータチェック
--    -- =============================================================================================
--    prc_chk_param
--      (
--        ov_errbuf   => lv_errbuf
--       ,ov_retcode  => lv_retcode
--       ,ov_errmsg   => lv_errmsg
--      ) ;
--    IF ( lv_retcode = gv_status_error ) THEN
--      gn_error_cnt := gn_error_cnt + 1 ;
--      RAISE global_process_expt;
--    END IF ;
----
--    -- =============================================================================================
--    -- E-02 プロファイル取得
--    -- =============================================================================================
--    prc_get_profile
--      (
--        ov_errbuf   => lv_errbuf
--       ,ov_retcode  => lv_retcode
--       ,ov_errmsg   => lv_errmsg
--      ) ;
--    IF ( lv_retcode = gv_status_error ) THEN
--      gn_error_cnt := gn_error_cnt + 1 ;
--      RAISE global_process_expt;
--    END IF ;
----
    -- =============================================================================================
    -- E-02 プロファイル取得
    -- =============================================================================================
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
    -- =============================================================================================
    -- E-01 パラメータチェック
    -- =============================================================================================
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
-- ##### 20090113 Ver.1.29 本番#971対応 END #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    -- 予定確定区分：確定 の場合
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN
      -- ===========================================================================================
      -- 多重起動チェック
      -- ===========================================================================================
      prc_chk_multi
        (
          ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
        RAISE global_process_expt;
      END IF ;
    END IF;
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
    -- =============================================================================================
    -- E-03 データ削除
    -- =============================================================================================
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
    -- =============================================================================================
    -- 中間テーブル登録
    -- =============================================================================================
    prc_ins_temp_table
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
    -- =============================================================================================
    -- E-04 メインデータ抽出
    -- =============================================================================================
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
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
--      RAISE ex_worn ;
      lv_main_data_flg := gc_yes_no_y;
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
    END IF ;
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
--
    -- 予定確定区分：確定 の場合
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN
      -- ===========================================================================================
      --  取消データ抽出
      -- ===========================================================================================
      prc_get_can_data
        (
          ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg
        ) ;
      -- エラー発生時
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
        RAISE global_process_expt;
      -- 警告発生時
      ELSIF ( lv_retcode = gv_status_warn ) THEN
        gn_warn_cnt := gn_warn_cnt + 1 ;
        -- 取消データ抽出 データなし
        lv_can_data_flg := gc_yes_no_y;
      END IF ;
--
    -- 予定確定区分：予定 の場合
    ELSE
      -- 予定の場合は抽出しないので、データ無を無条件に設定
      lv_can_data_flg := gc_yes_no_y;
    END IF ;
--
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
--
    -- 予定確定区分：確定 の場合
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN
      -- ===========================================================================================
      --  取消データ抽出
      -- ===========================================================================================
      prc_get_zero_can_data
        (
          ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg
        ) ;
      -- エラー発生時
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
        RAISE global_process_expt;
      -- 警告発生時
      ELSIF ( lv_retcode = gv_status_warn ) THEN
        gn_warn_cnt := gn_warn_cnt + 1 ;
        -- 取消データ抽出 データなし
        lv_zero_can_data_flg := gc_yes_no_y;
      END IF ;
--
    -- 予定確定区分：予定 の場合
    ELSE
      -- 予定の場合は抽出しないので、データ無を無条件に設定
      lv_zero_can_data_flg := gc_yes_no_y;
    END IF ;
--
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
--
    -- メインデータ抽出、取消データ抽出、明細数量０の取消データ抽出
    -- で共にデータが存在しない場合
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
--    IF ((lv_main_data_flg = gc_yes_no_y) 
--      AND (lv_can_data_flg = gc_yes_no_y)) THEN
    IF ((lv_main_data_flg       = gc_yes_no_y) 
      AND (lv_can_data_flg      = gc_yes_no_y)
      AND (lv_zero_can_data_flg = gc_yes_no_y)) THEN
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
      -- データなしメッセージ
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                      ,iv_name          => lc_msg_code
                    ) ;
      lv_errbuf  := lv_errmsg;
      RAISE ex_worn ;
    END IF;
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
    -- メインデータが存在した場合のみ通知情報作成する
    IF (lv_main_data_flg = gc_yes_no_n) THEN
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
    <<main_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      gn_target_cnt := gn_target_cnt + 1 ;
--
      ----------------------------------------------------------------------------------------------
      -- 依頼Ｎｏブレイクフラグの設定
      ----------------------------------------------------------------------------------------------
      IF ( lv_temp_request_no = gt_main_data(i).request_no ) THEN
        lv_break_flg := gc_yes_no_n ;
      ELSE
        lv_break_flg       := gc_yes_no_y ;
        lv_error_flg       := gc_yes_no_n ;
        lv_temp_request_no := gt_main_data(i).request_no ;
      END IF ;
--
      -- ===========================================================================================
      -- E-05 通知済情報作成処理
      -- ===========================================================================================
      IF (   ( lv_error_flg                     = gc_yes_no_n             )         -- エラー無し
         AND ( gt_main_data(i).data_type       IN( gc_data_type_syu_ins             -- 出荷：登録
                                                  ,gc_data_type_shi_ins             -- 支給：登録
                                                  ,gc_data_type_mov_ins ) ) ) THEN  -- 移動：登録
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
--
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          gn_wrm_idx              := gn_wrm_idx + 1 ;
          gt_worm_msg(gn_wrm_idx) := lv_errmsg ;
--
          lv_error_flg := gc_yes_no_y ;
--
        END IF ;
--
      END IF ;
--
      -- ===========================================================================================
      -- E-06 変更前情報取消データ作成処理
      -- ===========================================================================================
      IF (   ( lv_error_flg                      = gc_yes_no_n       )    -- エラー無し
         AND ( lv_break_flg                      = gc_yes_no_y       )    -- 依頼Ｎｏブレイク
         AND ( gr_param.fix_class                = gc_fix_class_k    )    -- 予定確定区分：確定
         AND ( gt_main_data(i).prev_notif_status = gc_notif_status_r )    -- 前回通知ＳＴ：再通知要
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 START #####
/***** 再通知要の場合は登録されている、無条件で通知済み全てに対して、取消のデータを作成する
         AND ( gt_main_data(i).eos_shipped_locat   IS NOT NUll )          -- 出ＥＯＳ宛先：NOT NULL
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468対応 END   #####
-- M.Hokkanji Ver1.5 START
             ) THEN
--         AND ( gt_main_data(i).eos_freight_carrier IS NOT NUll ) ) THEN   -- 運ＥＯＳ宛先：NOT NULL
-- M.Hokkanji Ver1.5 END
        prc_create_can_data
          (
            iv_request_no           => gt_main_data(i).request_no
           ,iv_eos_shipped_locat    => gt_main_data(i).eos_shipped_locat
           ,iv_eos_freight_carrier  => gt_main_data(i).eos_freight_carrier
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
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
    END IF;
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 START #####
--
    -- 取消データが存在した場合のみ取消データ作成処理を実行する
    IF (( gr_param.fix_class  =   gc_fix_class_k)       -- 予定確定区分：確定
      AND  ( lv_can_data_flg  =   gc_yes_no_n )) THEN   -- 取消データが存在する場合
--
      -- ===========================================================================================
      -- E-06 変更前情報取消データ作成処理（取消データ抽出での対象データ）
      -- ===========================================================================================
      <<can_loop>>
      FOR i IN 1..gt_can_data.COUNT LOOP
--
        prc_create_can_data
          (
            iv_request_no           => gt_can_data(i).request_no -- 依頼No
            ,iv_eos_shipped_locat   => NULL                      -- 使用しないためNULL
            ,iv_eos_freight_carrier => NULL                      -- 使用しないためNULL
            ,ov_errbuf              => lv_errbuf
            ,ov_retcode             => lv_retcode
            ,ov_errmsg              => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
--
      END LOOP can_loop ;
--
    END IF ;
--
-- ##### 20081028 Ver.1.26 統合#143対応 START #####
--
    -- 依頼数量ゼロ取消データ抽出の取消データが存在した場合のみ取消データ作成処理を実行する
    IF (( gr_param.fix_class  =   gc_fix_class_k)       -- 予定確定区分：確定
      AND  ( lv_zero_can_data_flg  =   gc_yes_no_n )) THEN   -- 依頼数量ゼロ取消データが存在する場合
--
      -- ===========================================================================================
      -- E-06 変更前情報取消データ作成処理（依頼数量ゼロ取消データ抽出での対象データ）
      -- ===========================================================================================
      <<zero_can_loop>>
      FOR i IN 1..gt_zero_can_data.COUNT LOOP
--
        prc_create_can_data
          (
            iv_request_no           => gt_zero_can_data(i).request_no -- 依頼No
            ,iv_eos_shipped_locat   => NULL                      -- 使用しないためNULL
            ,iv_eos_freight_carrier => NULL                      -- 使用しないためNULL
            ,ov_errbuf              => lv_errbuf
            ,ov_retcode             => lv_retcode
            ,ov_errmsg              => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
--
      END LOOP zero_can_loop ;
--
    END IF ;
--
-- ##### 20081028 Ver.1.26 統合#143対応 END   #####
--
    -- 抽出データが存在しても、通知データが存在しない場合、ワーニングで終了とする
    IF ( gn_cre_idx = 0 ) THEN
      -- データなしメッセージ
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                      ,iv_name          => lc_msg_code
                    ) ;
      lv_errbuf  := lv_errmsg;
--
      RAISE ex_worn ;
    END IF;
-- ##### 20081007 Ver.1.22 TE080_600指摘#27対応 END   #####
--
    -- =============================================================================================
    -- E-07 一括登録処理
    -- =============================================================================================
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
    -- =============================================================================================
    -- E-09 ＣＳＶ出力処理
    -- =============================================================================================
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
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN    -- 予定確定区分：確定
      -- ===========================================================================================
      -- E-12 変更前情報削除処理
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
    END IF ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
    -- =============================================================================================
    -- テンポラリテーブルデータ削除
    -- =============================================================================================
    prc_del_tmptable_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
--
  EXCEPTION
    -- =============================================================================================
    -- 警告処理
    -- =============================================================================================
    WHEN ex_worn THEN
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
      -- ===========================================================================================
      -- テンポラリテーブルデータ削除
      -- ===========================================================================================
      -- 対象データが存在しない場合もtmp2にはデータが存在する場合が在るので
      --     ここにて削除処理を実施
      prc_del_tmptable_data
        (
          ov_errbuf   => lv_errbuf2
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg2
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
--
        -- 削除処理エラーのメッセージ設定
        ov_errmsg  := lv_errmsg2;
        ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf2,1,5000);
        ov_retcode := gv_status_error;
      ELSE
--
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := lv_errbuf ;
        ov_retcode := gv_status_warn;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 START #####
--
      END IF;
-- ##### 20081014 Ver.1.23 PT2-2_17指摘71対応 END   #####
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
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : 部署_02(2008/07/16 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : 部署_03(2008/07/16 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : 部署_04(2008/07/16 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : 部署_05(2008/07/16 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : 部署_06(2008/07/16 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : 部署_07(2008/07/16 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : 部署_08(2008/07/16 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : 部署_09(2008/07/16 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : 部署_10(2008/07/16 Add)
     ,iv_fix_class        IN  VARCHAR2          -- 11 : 予定確定区分
     ,iv_date_cutoff      IN  VARCHAR2          -- 12 : 締め実施日
     ,iv_cutoff_from      IN  VARCHAR2          -- 13 : 締め実施時間From
     ,iv_cutoff_to        IN  VARCHAR2          -- 14 : 締め実施時間To
     ,iv_date_fix         IN  VARCHAR2          -- 15 : 確定通知実施日
     ,iv_fix_from         IN  VARCHAR2          -- 16 : 確定通知実施時間From
     ,iv_fix_to           IN  VARCHAR2          -- 17 : 確定通知実施時間To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
     ,iv_ship_date_from   IN  VARCHAR2          -- 18 : 出庫日From
     ,iv_ship_date_to     IN  VARCHAR2          -- 19 : 出庫日To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
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
        iv_dept_code_01     => iv_dept_code_01 -- 01 : 部署_01
       ,iv_dept_code_02     => iv_dept_code_02 -- 02 : 部署_02(2008/07/16 Add)
       ,iv_dept_code_03     => iv_dept_code_03 -- 03 : 部署_03(2008/07/16 Add)
       ,iv_dept_code_04     => iv_dept_code_04 -- 04 : 部署_04(2008/07/16 Add)
       ,iv_dept_code_05     => iv_dept_code_05 -- 05 : 部署_05(2008/07/16 Add)
       ,iv_dept_code_06     => iv_dept_code_06 -- 06 : 部署_06(2008/07/16 Add)
       ,iv_dept_code_07     => iv_dept_code_07 -- 07 : 部署_07(2008/07/16 Add)
       ,iv_dept_code_08     => iv_dept_code_08 -- 08 : 部署_08(2008/07/16 Add)
       ,iv_dept_code_09     => iv_dept_code_09 -- 09 : 部署_09(2008/07/16 Add)
       ,iv_dept_code_10     => iv_dept_code_10 -- 10 : 部署_10(2008/07/16 Add)
       ,iv_fix_class        => iv_fix_class    -- 11 : 予定確定区分
       ,iv_date_cutoff      => iv_date_cutoff  -- 12 : 締め実施日
       ,iv_cutoff_from      => iv_cutoff_from  -- 13 : 締め実施時間From
       ,iv_cutoff_to        => iv_cutoff_to    -- 14 : 締め実施時間To
       ,iv_date_fix         => iv_date_fix     -- 15 : 確定通知実施日
       ,iv_fix_from         => iv_fix_from     -- 16 : 確定通知実施時間From
       ,iv_fix_to           => iv_fix_to       -- 17 : 確定通知実施時間To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
       ,iv_ship_date_from   => iv_ship_date_from  -- 18 : 出庫日From
       ,iv_ship_date_to     => iv_ship_date_to    -- 19 : 出庫日To
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_01 　　　　　　：' || iv_dept_code_01   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_02 　　　　　　：' || iv_dept_code_02   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_03 　　　　　　：' || iv_dept_code_03   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_04 　　　　　　：' || iv_dept_code_04   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_05 　　　　　　：' || iv_dept_code_05   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_06 　　　　　　：' || iv_dept_code_06   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_07 　　　　　　：' || iv_dept_code_07   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_08 　　　　　　：' || iv_dept_code_08   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_09 　　　　　　：' || iv_dept_code_09   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　部署_10 　　　　　　：' || iv_dept_code_10   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　予定確定区分　　　　：' || iv_fix_class   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　締め実施日　　　　　：' || iv_date_cutoff ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　締め実施時間From　　：' || iv_cutoff_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　締め実施時間To　　　：' || iv_cutoff_to   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　確定通知実施日　　　：' || iv_date_fix    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　確定通知実施時間From：' || iv_fix_from    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　確定通知実施時間To　：' || iv_fix_to      ) ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 START #####
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　出庫日From　　　　　：' || iv_ship_date_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　出庫日To　　　　　　：' || iv_ship_date_to   ) ;
-- ##### 20080925 Ver.1.19 TE080_600指摘#31対応 END   #####
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
--
-- ##### 20081023 Ver.1.25 T_S_440対応 START #####
    -- 通知先のメッセージ出力
    IF ( gn_notif_idx <> 0 ) THEN
--
      -- タイトル表示
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- 空行
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, 'ＥＯＳ宛先　通知ユーザー') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '------------------------') ;
--
      FOR i IN 1..gn_notif_idx LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gt_notif_msg(i) ) ;
      END LOOP ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- 空行
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;  -- 区切り文字列出力
--
    END IF;
-- ##### 20081023 Ver.1.25 T_S_440対応 END   #####
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　出荷：' || TO_CHAR( gn_out_cnt_syu, 'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　支給：' || TO_CHAR( gn_out_cnt_shi, 'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '　移動：' || TO_CHAR( gn_out_cnt_mov, 'FM999,999,990' ) ) ;
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
END xxwsh600002c ;
/
