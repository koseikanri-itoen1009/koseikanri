CREATE OR REPLACE PACKAGE BODY xxwsh600005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600005c(body)
 * Description      : 確定ブロック処理
 * MD.050           : 出荷依頼 T_MD050_BPO_601
 * MD.070           : 確定ブロック処理  T_MD070_BPO_60D
 * Version          : 1.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *  check_parameter        入力パラメータチェック
 *  get_profile            プロファイル取得
 *  ins_temp_data          中間テーブル登録
 *  get_confirm_block_header 出荷・支給・移動情報ヘッダ抽出処理
 *  get_confirm_block_line   出荷・支給・移動情報明細抽出処理
 *  chk_reserved           引当処理済チェック処理
 *  chk_mixed_prod         出荷明細 製品混在チェック処理
 *  chk_carrier            配車済チェック処理
 *  set_checked_data       チェック済データ PL/SQL表格納処理
 *  set_upd_data           通知ステータス更新用PL／SQL表 格納処理
 *  upd_notif_status       通知ステータス 一括更新処理
 *  purge_tbl              中間テーブルパージ処理
 *  ins_upd_lot_hold_info  ロット情報保持マスタ反映処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/18    1.0  Oracle 上原正好   初回作成
 *  2008/06/16    1.1  Oracle 野村正幸   結合障害 #9対応
 *  2008/06/19    1.2  Oracle 上原正好   ST障害 #178対応
 *  2008/06/24    1.3  Oracle 上原正好   配送L/Tアドオンのリレーションに配送区分を追加
 *  2008/08/04    1.4  Oracle 二瓶大輔   結合テスト不具合対応(T_TE080_BPO_400#160)
 *                                       カテゴリ情報VIEW変更
 *  2008/08/07    1.5  Oracle 大橋孝郎   結合出荷テスト(出荷追加_30)修正
 *  2008/09/04    1.6  Oracle 野村正幸   統合#45 対応
 *  2008/09/10    1.7  Oracle 福田直樹   統合#45の再修正(配送L/Tに関する条件をLT2に入れ忘れ)
 *  2008/12/01    1.8  SCS    伊藤ひとみ 本番#148対応
 *  2008/12/02    1.9  SCS    菅原大輔   本番#148対応
 *  2009/08/18    1.10 SCS    伊藤ひとみ 本番#1581対応(営業システム:特別横持マスタ対応)
 *  2014/12/24    1.11 SCSK   鈴木康徳   E_本稼動_12237    倉庫管理システム対応（ロット情報保持マスタ反映処理を追加）
 *  2015/03/19    1.12 SCSK   仁木重人   E_本稼動_12237 不具合対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0'; -- 正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1'; -- 警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2'; -- エラー
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C'; -- ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G'; -- ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E'; -- ステータス(エラー)
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
--
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
-- 2008/12/01 H.Itou Add Start 本番障害#148
  --*** スキップ例外 ***
  skip_expt                 EXCEPTION;
-- 2008/12/01 H.Itou Add End
  --*** 処理対象データなし例外 ***
  global_no_data_found_expt EXCEPTION;
-- ##### 20080616 1.1 結合障害 #9対応 START #####
  ex_worn                   EXCEPTION ;
-- ##### 20080616 1.1 結合障害 #9対応 END   #####
  --*** ロックエラー例外 ***
  global_lock_error_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_error_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwsh600005c';
                                                                 -- パッケージ名
  gv_cons_msg_kbn_wsh         CONSTANT VARCHAR2(100) := 'XXWSH';
                                                                 -- アプリケーション短縮名
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
  gv_cons_msg_kbn_cmn         CONSTANT VARCHAR2(100) := 'XXCMN';
                                                                 -- アプリケーション短縮名 XXCMN
-- 2009/08/18 H.Itou Add End
  gv_prof_item_div_security   CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV_SECURITY';
                                                                 -- XXCMN：商品区分(セキュリティ)
  gv_line_feed                CONSTANT VARCHAR2(1)   := CHR(10);
                                                                 -- 改行コード
  gv_single_quote             CONSTANT VARCHAR2(2)   := '''';
                                                                 -- シングルコート
  gv_ship_class_1             CONSTANT VARCHAR2(15)  := '1';
                                                                 -- 出荷依頼
  gv_ship_class_2             CONSTANT VARCHAR2(15)  := '2';
                                                                 -- 支給指示
  -- 受注カテゴリ
  gv_order_cat_o              CONSTANT VARCHAR2(10) := 'ORDER' ;
  -- 出荷支給区分
  gv_sp_class_ship            CONSTANT VARCHAR2(1)  := '1' ;    -- 出荷依頼
  gv_sp_class_prov            CONSTANT VARCHAR2(1)  := '2' ;    -- 支給指示
  -- 移動ステータス
  gv_mov_status_req           CONSTANT VARCHAR2(2)  := '01' ;   -- 依頼中
  gv_mov_status_cmp           CONSTANT VARCHAR2(2)  := '02' ;   -- 依頼済
  gv_mov_status_adj           CONSTANT VARCHAR2(2)  := '03' ;   -- 調整中
  gv_mov_status_del           CONSTANT VARCHAR2(2)  := '04' ;   -- 出庫報告有
  gv_mov_status_stc           CONSTANT VARCHAR2(2)  := '05' ;   -- 入庫報告有
  gv_mov_status_dsr           CONSTANT VARCHAR2(2)  := '06' ;   -- 入出庫報告有
  gv_mov_status_ccl           CONSTANT VARCHAR2(2)  := '99' ;   -- 取消
  -- 移動タイプ
  gc_mov_type_y               CONSTANT VARCHAR2(1)  := '1' ;    -- 積送あり
  gc_mov_type_n               CONSTANT VARCHAR2(1)  := '2' ;    -- 積送なし
  -- 出庫形態
--  gv_transaction_type_id_ship CONSTANT VARCHAR2(100)  := '1033' ;    -- 出荷依頼
  gv_transaction_type_name_ship CONSTANT VARCHAR2(100)  := '出荷依頼' ;    -- 出荷依頼
  -- 処理種別（確定ブロック）
  gv_proc_fix_block_ship      CONSTANT VARCHAR2(1) := '1';    -- 出荷依頼
  gv_proc_fix_block_prov      CONSTANT VARCHAR2(1) := '2';    -- 支給指示
  gv_proc_fix_block_move      CONSTANT VARCHAR2(1) := '3';    -- 移動指示
  gv_proc_fix_block_ship_move CONSTANT VARCHAR2(1) := '4';    -- 出荷依頼/移動指示
  gv_proc_fix_block_prov_move CONSTANT VARCHAR2(1) := '5';    -- 支給指示/移動指示
  gv_sales_code               CONSTANT VARCHAR2(1) := '1'; -- クイックコード「コード区分」「拠点」
  gv_whse_code                CONSTANT VARCHAR2(1) := '4'; -- クイックコード「コード区分」「倉庫」
  gv_deliver_to               CONSTANT VARCHAR2(1) := '9'; -- クイックコード「コード区分」「配送先」
  -- YesNo区分
  gc_yn_div_y                 CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n                 CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- OnOff区分
  gc_onoff_div_on             CONSTANT VARCHAR2(3)  := 'ON' ;    -- ON
  gc_onoff_div_off            CONSTANT VARCHAR2(3)  := 'OFF' ;    -- OFF
  -- ステータス
  gc_req_status_s_inp         CONSTANT VARCHAR2(2)  := '01' ;   -- 入力中
  gc_req_status_s_cmpa        CONSTANT VARCHAR2(2)  := '02' ;   -- 拠点確定
  gc_req_status_s_cmpb        CONSTANT VARCHAR2(2)  := '03' ;   -- 締め済み
  gc_req_status_s_cmpc        CONSTANT VARCHAR2(2)  := '04' ;   -- 出荷実績計上済
  gc_req_status_p_inp         CONSTANT VARCHAR2(2)  := '05' ;   -- 入力中
  gc_req_status_p_cmpa        CONSTANT VARCHAR2(2)  := '06' ;   -- 入力完了
  gc_req_status_p_cmpb        CONSTANT VARCHAR2(2)  := '07' ;   -- 受領済
  gc_req_status_p_cmpc        CONSTANT VARCHAR2(2)  := '08' ;   -- 出荷実績計上済
  gc_req_status_p_ccl         CONSTANT VARCHAR2(2)  := '99' ;   -- 取消
  -- 通知ステータス
  gc_notif_status_unnotif     CONSTANT VARCHAR2(2)  := '10' ;   -- 未通知
  gc_notif_status_renotif     CONSTANT VARCHAR2(2)  := '20' ;   -- 再通知要
  gc_notif_status_notifed     CONSTANT VARCHAR2(2)  := '40' ;   -- 確定通知済
 -- 品目区分
  gv_cons_item_product        CONSTANT VARCHAR2(1)   := '5';    -- 「製品」
 -- 製品識別区分
  gv_cons_product_class       CONSTANT VARCHAR2(1)   := '1';    -- 「製品」
  -- 商品区分
  gv_prod_class_leaf          CONSTANT VARCHAR2(1) :=  '1';    -- 商品区分「リーフ」
  gv_prod_class_drink         CONSTANT VARCHAR2(1) :=  '2';    -- 商品区分「ドリンク」
  -- データ区分
  gc_data_class_order         CONSTANT VARCHAR2(1)  := '1' ;   -- 出荷依頼
  gc_data_class_prov          CONSTANT VARCHAR2(1)  := '2' ;   -- 支給指示
  gc_data_class_move          CONSTANT VARCHAR2(1)  := '3' ;   -- 移動指示
  gc_data_class_order_cncl    CONSTANT VARCHAR2(1)  := '8' ;   -- 出荷取消
  gc_data_class_prov_cncl     CONSTANT VARCHAR2(1)  := '9' ;   -- 支給取消
  -- 運賃区分
  gv_freight_charge_class_on  CONSTANT VARCHAR2(1) :=  '1';    -- 運賃区分「対象」
  gv_freight_charge_class_off CONSTANT VARCHAR2(1) :=  '0';    -- 運賃区分「対象外」
-- add start 1.5
  gv_d1_whse_flg_1            CONSTANT VARCHAR2(1) :=  '1';    -- D+1倉庫フラグ「対象」
-- add end 1.5
  -- レコードタイプ
  gv_record_type_code_plan    CONSTANT VARCHAR2(2) :=  '10';   -- 指示
  -- エラーメッセージ
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
  -- 特別横持更新関数
  gv_process_type_plus        CONSTANT VARCHAR2(1) :=  '0';    -- 処理区分 0：加算
  gv_process_type_minus       CONSTANT VARCHAR2(1) :=  '1';    -- 処理区分 1：減算
-- 2009/08/18 H.Itou Add End
  gv_output_msg               CONSTANT VARCHAR2(100) := 'APP-XXWSH-01701';
                                                             -- 出力件数
  gv_input_date_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11851';
                                                             -- 入力パラメータ出庫予定日入力エラー
  gv_input_format_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11852';
                                                             -- 入力パラメータ書式エラー
  gv_check_line_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11853';
                                                             -- 配車済・引当処理済チェックエラー
  gv_need_input_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11854';
                                                             -- 入力パラメータ未入力エラー
  gv_lock_err                 CONSTANT VARCHAR2(100) := 'APP-XXWSH-11855';
                                                             -- ロックエラー
  gv_no_data_found_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-11856';
                                                             -- 処理対象データなしエラー
  gv_profile_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-11857';
                                                             -- プロファイル取得エラー
-- 2008/12/01 H.Itou Add Start 本番障害#148
  gv_check_line_err2          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11858';
                                                             -- 配車済・引当処理済チェックエラー２
-- 2008/12/01 H.Itou Add End
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
  gv_process_err              CONSTANT VARCHAR2(100) := 'APP-XXCMN-05002';
                                                             -- 処理失敗
-- 2009/08/18 H.Itou Add End
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
  gv_inv_org_code_err         CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
                                                             -- 在庫組織コード取得エラーメッセージ
  gv_inv_org_id_err           CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; 
                                                             -- 在庫組織ID取得エラーメッセージ
-- 2015/03/19 V1.12 Del START
--  gv_process_date_err         CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011'; 
--                                                             -- 業務日付取得エラーメッセージ
-- 2015/03/19 V1.12 Del END
  gv_customer_id_err          CONSTANT VARCHAR2(15) := 'APP-XXWSH-13187';
                                                             -- 顧客導出（受注アドオン）取得エラー
  gv_item_pc_err              CONSTANT VARCHAR2(15) := 'APP-XXWSH-13188';
                                                             -- 品目情報取得エラー
-- 2015/03/19 V1.12 Mod START
--  gv_item_tst_err             CONSTANT VARCHAR2(15) := 'APP-XXWSH-10025';
  gv_item_tst_err             CONSTANT VARCHAR2(15) := 'APP-XXWSH-13190';
-- 2015/03/19 V1.12 Mod END
                                                             -- 賞味期限取得エラー
  gv_lot_mst_upd_err          CONSTANT VARCHAR2(15) := 'APP-XXWSH-13189';
                                                             -- ロット情報保持マスタ反映エラー
--
  -- トークン
  gv_param1_token             CONSTANT VARCHAR2(6)  := 'PARAM1';      -- 参照値トークン
  gv_param2_token             CONSTANT VARCHAR2(6)  := 'PARAM2';      -- 参照値トークン
  gv_param3_token             CONSTANT VARCHAR2(6)  := 'PARAM3';      -- 参照値トークン
  gv_param4_token             CONSTANT VARCHAR2(6)  := 'PARAM4';      -- 参照値トークン
  gv_param5_token             CONSTANT VARCHAR2(6)  := 'PARAM5';      -- 参照値トークン
-- 2015/03/19 V1.12 Mod START
--  gv_param_data               CONSTANT VARCHAR2(6)  := 'DATA';      -- 参照値トークン
  gv_order_line_id            CONSTANT VARCHAR2(13) := 'ORDER_LINE_ID'; -- 受注明細IDトークン
-- 2015/03/19 V1.12 Mod END
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
  gv_cnst_tkn_para            CONSTANT VARCHAR2(100) := 'PARAMETER';
                                                             -- 入力パラメータ名
  gv_cnst_tkn_para2           CONSTANT VARCHAR2(100) := 'PARAMETER2';
                                                             -- 入力パラメータ名2
  gv_cnst_tkn_date            CONSTANT VARCHAR2(100) := 'DATE';
                                                             -- 出庫日
  gv_cnst_tkn_prof            CONSTANT VARCHAR2(100) := 'PROF_NAME';
                                                             -- プロファイル名
  gv_cnst_tkn_check_kbn       CONSTANT VARCHAR2(100) := 'CHECK_KBN';
                                                             -- チェック区分
  gv_cnst_tkn_delivery_no     CONSTANT VARCHAR2(100) := 'DELIVERY_NO';
                                                             -- 配送No
  gv_cnst_tkn_request_no      CONSTANT VARCHAR2(100) := 'REQUEST_NO';
                                                             -- 依頼No
  gv_cnst_tkn_item_no         CONSTANT VARCHAR2(100) := 'ITEM_NO';
                                                             -- 品目No
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
  gv_cnst_tkn_process         CONSTANT VARCHAR2(100) := 'PROCESS';
                                                             -- 処理名
-- 2009/08/18 H.Itou Add End
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
  gv_tkn_pro_tok               CONSTANT VARCHAR2(20) := 'PRO_TOK';        -- プロファイル名
  gv_tkn_org_code_tok          CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';   -- 在庫組織コード
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
  -- トークン
  gv_tkn_item_div_security    CONSTANT VARCHAR2(100) := 'XXCMN：商品区分(セキュリティ)';
  gv_tkn_dept_code            CONSTANT VARCHAR2(100) := '部署';
  gv_tkn_shipping_biz_type    CONSTANT VARCHAR2(100) := '処理種別';
  gv_tkn_transaction_type_id  CONSTANT VARCHAR2(100) := '出庫形態';
  gv_tkn_lead_time_day_01     CONSTANT VARCHAR2(100) := '生産物流LT1';
  gv_tkn_lt1_ship_date_from   CONSTANT VARCHAR2(100) := '生産物流LT1/出荷依頼/出庫日From';
  gv_tkn_lt1_ship_date_to     CONSTANT VARCHAR2(100) := '生産物流LT1/出荷依頼/出庫日To';
  gv_tkn_lead_time_day_02     CONSTANT VARCHAR2(100) := '生産物流LT2';
  gv_tkn_lt2_ship_date_from   CONSTANT VARCHAR2(100) := '生産物流LT2/出荷依頼/出庫日From';
  gv_tkn_lt2_ship_date_to     CONSTANT VARCHAR2(100) := '生産物流LT2/出荷依頼/出庫日To';
  gv_tkn_ship_date_from       CONSTANT VARCHAR2(100) := '出庫日From';
  gv_tkn_ship_date_to         CONSTANT VARCHAR2(100) := '出庫日To';
  gv_tkn_move_ship_date_from  CONSTANT VARCHAR2(100) := '移動/出庫日From';
  gv_tkn_move_ship_date_to    CONSTANT VARCHAR2(100) := '移動/出庫日To';
  gv_tkn_prov_ship_date_from  CONSTANT VARCHAR2(100) := '支給/出庫日From';
  gv_tkn_prov_ship_date_to    CONSTANT VARCHAR2(100) := '支給/出庫日To';
  gv_tkn_reserved_err         CONSTANT VARCHAR2(100) := '引当エラー';
  gv_tkn_carrier_err          CONSTANT VARCHAR2(100) := '配車エラー';
  gv_tkn_reserved_carrier_err CONSTANT VARCHAR2(100) := '引当及び配車エラー';
  gv_tkn_mixed_prod_err       CONSTANT VARCHAR2(100) := '出荷依頼製品混在';
-- 2008/12/01 H.Itou Add Start 本番障害#148
  gv_tkn_reserved02_err       CONSTANT VARCHAR2(100) := '引当エラー２';
-- 2008/12/01 H.Itou Add End
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
  gv_tkn_upd_assignment       CONSTANT VARCHAR2(100) := '割当セットAPI起動';
                                                             -- 処理名
-- 2009/08/18 H.Itou Add End
--
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
-- 2015/03/19 V1.12 Del START
--  -- 賞味期限
--  gv_item_tst                 CONSTANT VARCHAR2(8)  := '賞味期限';
-- 2015/03/19 V1.12 Del END
  -- プロファイル名
  gv_xxcoi1_organization_code CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:在庫組織コード
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      dept_code              VARCHAR2(4),  -- 部署
      shipping_biz_type      VARCHAR2(2),  -- 処理種別
      transaction_type_id    VARCHAR2(4),  -- 出庫形態
      lead_time_day_01       NUMBER,       -- 生産物流LT1
      lt1_ship_date_from     DATE,         -- 生産物流LT1/出荷依頼/出庫日From
      lt1_ship_date_to       DATE,         -- 生産物流LT1/出荷依頼/出庫日To
      lead_time_day_02       NUMBER,       -- 生産物流LT2
      lt2_ship_date_from     DATE,         -- 生産物流LT2/出荷依頼/出庫日From
      lt2_ship_date_to       DATE,         -- 生産物流LT2/出荷依頼/出庫日To
      ship_date_from         DATE,         -- 出庫日From
      ship_date_to           DATE,         -- 出庫日To
      move_ship_date_from    DATE,         -- 移動/出庫日From
      move_ship_date_to      DATE,         -- 移動/出庫日To
      prov_ship_date_from    DATE,         -- 支給/出庫日From
      prov_ship_date_to      DATE,         -- 支給/出庫日To
      block_01               VARCHAR2(2),  -- ブロック１
      block_02               VARCHAR2(2),  -- ブロック２
      block_03               VARCHAR2(2),  -- ブロック３
      shipped_locat_code     VARCHAR2(4)   -- 出庫元
    ) ;
  -- ヘッダ中間テーブル登録用レコード変数
  TYPE rec_temp_tab_data IS RECORD
    (
     data_class           xxwsh.xxwsh_confirm_block_tmp.data_class%TYPE           -- データ区分
    ,whse_code            xxwsh.xxwsh_confirm_block_tmp.whse_code%TYPE            -- 保管倉庫コード
    ,header_id            xxwsh.xxwsh_confirm_block_tmp.header_id%TYPE            -- ヘッダID
    ,notif_status         xxwsh.xxwsh_confirm_block_tmp.notif_status%TYPE         -- 通知ステータス
    ,prod_class           xxwsh.xxwsh_confirm_block_tmp.prod_class%TYPE           -- 商品区分
    ,item_class           xxwsh.xxwsh_confirm_block_tmp.item_class%TYPE           -- 品目区分
    ,delivery_no          xxwsh.xxwsh_confirm_block_tmp.delivery_no%TYPE          -- 配送No
    ,request_no           xxwsh.xxwsh_confirm_block_tmp.request_no%TYPE           -- 依頼No
    ,freight_charge_class xxwsh.xxwsh_confirm_block_tmp.freight_charge_class%TYPE -- 運賃区分
    ,d1_whse_code         xxwsh.xxwsh_confirm_block_tmp.d1_whse_code%TYPE         -- D+1倉庫フラグ
    ,base_date            xxwsh.xxwsh_confirm_block_tmp.base_date%TYPE            -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
    ,deliver_to_id        xxwsh.xxwsh_confirm_block_tmp.deliver_to_id%TYPE        -- 出荷先ID
    ,result_deliver_to_id xxwsh.xxwsh_confirm_block_tmp.result_deliver_to_id%TYPE -- 出荷先_実績ID
    ,arrival_date         xxwsh.xxwsh_confirm_block_tmp.arrival_date%TYPE         -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
    ) ;
  TYPE rec_temp_tab_data_tab IS TABLE OF rec_temp_tab_data INDEX BY PLS_INTEGER;
--
  -- 明細抽出データ格納用レコード変数
  TYPE rec_get_data_line IS RECORD
    (
      order_header_id   NUMBER     -- 受注ヘッダID
     ,order_line_id     NUMBER     -- 受注明細ID
     ,quantity          NUMBER     -- 数量
     ,reserved_quantity NUMBER     -- 引当数
     ,lot_ctl           VARCHAR2(2)   -- ロット管理区分
     ,item_class_code   VARCHAR2(2)   -- 品目区分
-- 2008/12/01 H.Itou Add Start 本番障害#148
     ,item_code         xxcmn_item_mst_v.item_no%TYPE -- 品目NO
-- 2008/12/01 H.Itou Add End
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
     ,shipping_inventory_item_id NUMBER  -- 出荷品目ID
     ,line_id                    NUMBER  -- 明細ID
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
    ) ;
  TYPE rec_get_data_line_tab IS TABLE OF rec_get_data_line INDEX BY PLS_INTEGER;
--
  -- チェック済データ格納用レコード変数
  TYPE rec_checked_data IS RECORD
    (
     data_class            xxwsh.xxwsh_confirm_block_tmp.data_class%TYPE       -- データ区分
    ,delivery_no           xxwsh.xxwsh_confirm_block_tmp.delivery_no%TYPE      -- 配送No
    ,request_no            xxwsh.xxwsh_confirm_block_tmp.request_no%TYPE       -- 依頼No
    ,notif_status          xxwsh.xxwsh_confirm_block_tmp.notif_status%TYPE     -- 通知ステータス
    ) ;
  TYPE rec_checked_data_tab IS TABLE OF rec_checked_data INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param                rec_param_data ;      -- パラメータ
  gr_chk_header_data_tab  rec_temp_tab_data_tab; -- チェック用ヘッダデータ群
  gr_chk_line_data_tab    rec_get_data_line_tab; -- チェック用明細データ群
  gr_chk_line_data_tab_cncl  rec_get_data_line_tab; -- チェック用明細データ群
  gr_checked_data_tab     rec_checked_data_tab;   -- チェック済データ格納用データ群
  gr_upd_data_tab         rec_checked_data_tab;   -- 更新データ格納用データ群
  -- 入力パラメータ格納用
  gv_lt1_ship_date_from   VARCHAR2(20);     -- 生産物流LT1/出荷依頼/出庫日From
  gv_lt1_ship_date_to     VARCHAR2(20);     -- 生産物流LT1/出荷依頼/出庫日To
  gv_lt2_ship_date_from   VARCHAR2(20);     -- 生産物流LT2/出荷依頼/出庫日From
  gv_lt2_ship_date_to     VARCHAR2(20);     -- 生産物流LT2/出荷依頼/出庫日To
  gv_ship_date_from       VARCHAR2(20);     -- 出庫日From
  gv_ship_date_to         VARCHAR2(20);     -- 出庫日To
  gv_move_ship_date_from  VARCHAR2(20);     -- 移動/出庫日From
  gv_move_ship_date_to    VARCHAR2(20);     -- 移動/出庫日To
  gv_prov_ship_date_from  VARCHAR2(20);     -- 支給/出庫日From
  gv_prov_ship_date_to    VARCHAR2(20);     -- 支給/出庫日To
  gn_cnt_line             NUMBER ;   -- 明細件数
  gn_cnt_line_cncl        NUMBER ;   -- 取消明細件数
  gn_cnt_prod             NUMBER ;   -- 製品件数
  gn_cnt_no_prod          NUMBER ;   -- 製品以外件数
  gn_cnt_upd              NUMBER ;   -- 更新用データ件数
-- 2008/12/01 H.Itou Add Start 本番障害#148
  gn_cnt_chk_data         NUMBER ;   -- チェック済データ格納カウント
-- 2008/12/01 H.Itou Add End
  gn_cnt_upd_ship         NUMBER ;   -- 出荷更新件数
  gn_cnt_upd_prov         NUMBER ;   -- 支給更新件数
  gn_cnt_upd_move         NUMBER ;   -- 移動更新件数
  gv_data_found_flg       VARCHAR2(3) ;   -- 処理対象データありフラグ
  gv_err_flg_resv         VARCHAR2(3) ;   -- 引当エラーフラグ
  gv_err_flg_resv2        VARCHAR2(3) ;   -- 引当エラーフラグ２
  gv_err_flg_whse         VARCHAR2(3) ;   -- 倉庫エラーフラグ
  gv_err_flg_carr         VARCHAR2(3) ;   -- 配車エラーフラグ
  gv_war_flg_carr_mixed   VARCHAR2(3) ;   -- 配車出荷依頼製品混在ワーニングフラグ
  -- WHOカラム
  gt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- 作成者、最終更新者
  gt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- 最終更新ログイン
  gt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- 要求ID
  gt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- アプリケーションID
  gt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- プログラムID
--
  gv_transaction_type_id_ship VARCHAR2(4) ;   -- 出庫形態
  gv_item_div_security       VARCHAR2(100);
  -- 出荷依頼締め管理情報抽出用
  gt_order_type_id           XXWSH_TIGHTENING_CONTROL.ORDER_TYPE_ID%TYPE;
                                                                         -- 受注タイプID
  gt_deliver_from            XXWSH_TIGHTENING_CONTROL.DELIVER_FROM%TYPE;
                                                                         -- 出荷元保管場所
  gt_prod_class_type         XXWSH_TIGHTENING_CONTROL.PROD_CLASS%TYPE;
                                                                         -- 商品区分
  gt_sales_branch_category   XXWSH_TIGHTENING_CONTROL.SALES_BRANCH_CATEGORY%TYPE;
                                                                         -- 拠点カテゴリ
  gt_lead_time_day           XXWSH_TIGHTENING_CONTROL.LEAD_TIME_DAY%TYPE;
                                                                         -- 生産物流LT/引取変更LT
  gt_schedule_ship_date      XXWSH_TIGHTENING_CONTROL.SCHEDULE_SHIP_DATE%TYPE;
                                                                         -- 出荷予定日
  gt_tighten_release_class   XXWSH_TIGHTENING_CONTROL.TIGHTEN_RELEASE_CLASS%TYPE;
                                                                         -- 締め／解除区分
  gt_base_record_class       XXWSH_TIGHTENING_CONTROL.BASE_RECORD_CLASS%TYPE;
                                                                         -- 基準レコード区分
  gt_system_date             DATE;                                       -- システム日付
--
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
  gd_process_date            DATE;   -- 業務日付
  gt_inv_org_code            mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
  gt_inv_org_id              mtl_parameters.organization_id%TYPE;    -- 在庫組織ID
  gn_ins_upd_lot_info_cnt    NUMBER;                                 -- ロット情報保持マスタ登録更新件数
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : D-1  入力パラメータチェック
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    -- ************************************
    -- ***  出庫形態(出荷依頼)取得      ***
    -- ************************************
    SELECT transaction_type_id 
      INTO gv_transaction_type_id_ship 
      FROM XXWSH_OE_TRANSACTION_TYPES2_V
      WHERE transaction_type_name = gv_transaction_type_name_ship;
    IF gv_transaction_type_id_ship IS NULL THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_profile_err   -- プロファイル取得エラー
                                                ,gv_cnst_tkn_prof    -- トークン'PROF_NAME'
                                                ,gv_tkn_transaction_type_id)   -- '出庫形態'
                                                ,1
                                                ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
--
    -- ************************************
    -- ***  入力パラメータ必須チェック  ***
    -- ************************************
    -- 部署の入力がない場合はエラーとする
    IF (gr_param.dept_code IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                                ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                                ,gv_tkn_dept_code)   -- '部署'
                                                ,1
                                                ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 処理種別の入力がない場合はエラーとする
    IF (gr_param.shipping_biz_type IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                                ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                                ,gv_tkn_shipping_biz_type)   -- '処理種別'
                                                ,1
                                                ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- -----------------------------------------------------
    -- 処理種別が「出荷依頼」又は「出荷依頼/移動伝票」の場合
    -- -----------------------------------------------------
    IF (gr_param.shipping_biz_type IN (gv_proc_fix_block_ship,gv_proc_fix_block_ship_move)) THEN
      -- 出庫形態の入力がない場合はエラーとする
      IF (gr_param.transaction_type_id IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                ,gv_tkn_transaction_type_id)   -- '出庫形態'
                                ,1
                                ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      -- -----------------------------------------------------
      -- 出庫形態が「出荷依頼」の場合
      -- -----------------------------------------------------
      ELSIF (gr_param.transaction_type_id = gv_transaction_type_id_ship) THEN
        -- 生産物流LT1または生産物流LT2のどちらかが入力されていない場合はエラーとする
        IF (gr_param.lead_time_day_01 IS NULL AND gr_param.lead_time_day_02 IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                                ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                                ,gv_tkn_lead_time_day_01)   -- '生産物流LT1'
                                                ,1
                                                ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- 生産物流LT1が入力されている場合
      -- -----------------------------------------------------
      IF (gr_param.lead_time_day_01 IS NOT NULL) THEN
        -- 生産物流LT1/出荷依頼/出庫日Fromが入力されていない場合はエラーとする
        IF (gv_lt1_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_lt1_ship_date_from)  -- '生産物流LT1/出荷依頼/出庫日From'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- 日付型(YYYY/MM/DD)に変換して格納
          -- ==============================================================
          gr_param.lt1_ship_date_from := FND_DATE.STRING_TO_DATE( gv_lt1_ship_date_from
                                                                                  ,'YYYY/MM/DD');
          IF (gr_param.lt1_ship_date_from IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                   ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                   ,gv_tkn_lt1_ship_date_from
                                                               -- '生産物流LT1/出荷依頼/出庫日From'
                                   ,gv_cnst_tkn_date    -- トークン'DATE'
                                   ,TO_CHAR(gv_lt1_ship_date_from))
                                                               -- '生産物流LT1/出荷依頼/出庫日From'
                                   ,1
                                   ,5000);
            -- エラーリターン＆処理中止
            RAISE global_api_expt;
          END IF;
        END IF;
        -- 生産物流LT1/出荷依頼/出庫日Toが入力されていない場合はエラーとする
        IF (gv_lt1_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_lt1_ship_date_to)  -- '生産物流LT1/出荷依頼/出庫日To'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- 日付型(YYYY/MM/DD)に変換して格納
          -- ==============================================================
          gr_param.lt1_ship_date_to  := FND_DATE.STRING_TO_DATE( gv_lt1_ship_date_to
                                                                                ,'YYYY/MM/DD');
          IF (gr_param.lt1_ship_date_to IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                   ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                   ,gv_tkn_lt1_ship_date_to  -- '生産物流LT1/出荷依頼/出庫日To'
                                   ,gv_cnst_tkn_date    -- トークン'DATE'
                                   ,TO_CHAR(gv_lt1_ship_date_to))
                                                             -- '生産物流LT1/出荷依頼/出庫日To'
                                   ,1
                                   ,5000);
            -- エラーリターン＆処理中止
            RAISE global_api_expt;
          END IF;
        END IF;
        -- 生産物流LT1/出荷依頼/出庫日Fromと生産物流LT1/出荷依頼/出庫日Toが逆転していたらエラー
        IF (gr_param.lt1_ship_date_from > gr_param.lt1_ship_date_to) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_date_err    -- 入力パラメータ書式エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_lt1_ship_date_to  -- '生産物流LT1/出荷依頼/出庫日To'
                                 ,gv_cnst_tkn_para2    -- トークン'PRAMETER2'
                                 ,gv_tkn_lt1_ship_date_from)  -- '生産物流LT1/出荷依頼/出庫日From'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- 生産物流LT2が入力されている場合
      -- -----------------------------------------------------
      IF (gr_param.lead_time_day_02 IS NOT NULL) THEN
        -- 生産物流LT2/出荷依頼/出庫日Fromが入力されていない場合はエラーとする
        IF (gv_lt2_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_lt2_ship_date_from)  -- '生産物流LT2/出荷依頼/出庫日From'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- 日付型(YYYY/MM/DD)に変換して格納
          -- ==============================================================
          gr_param.lt2_ship_date_from := FND_DATE.STRING_TO_DATE( gv_lt2_ship_date_from
                                                                                  ,'YYYY/MM/DD');
          IF (gr_param.lt2_ship_date_from IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                   ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                   ,gv_tkn_lt2_ship_date_from
                                                               -- '生産物流LT2/出荷依頼/出庫日From'
                                   ,gv_cnst_tkn_date    -- トークン'DATE'
                                   ,TO_CHAR(gv_lt2_ship_date_from))
                                                               -- '生産物流LT2/出荷依頼/出庫日From'
                                   ,1
                                   ,5000);
            -- エラーリターン＆処理中止
            RAISE global_api_expt;
          END IF;
        END IF;
        -- 生産物流LT2/出荷依頼/出庫日Toが入力されていない場合はエラーとする
        IF (gv_lt2_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_lt2_ship_date_to)  -- '生産物流LT2/出荷依頼/出庫日To'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- 日付型(YYYY/MM/DD)に変換して格納
          -- ==============================================================
          gr_param.lt2_ship_date_to  := FND_DATE.STRING_TO_DATE( gv_lt2_ship_date_to
                                                                                ,'YYYY/MM/DD');
          IF (gr_param.lt2_ship_date_to IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                   ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                   ,gv_tkn_lt2_ship_date_to  -- '生産物流LT2/出荷依頼/出庫日To'
                                   ,gv_cnst_tkn_date    -- トークン'DATE'
                                   ,TO_CHAR(gv_lt2_ship_date_to))
                                                             -- '生産物流LT2/出荷依頼/出庫日To'
                                   ,1
                                   ,5000);
            -- エラーリターン＆処理中止
            RAISE global_api_expt;
          END IF;
        END IF;
        -- 生産物流LT2/出荷依頼/出庫日Fromと生産物流LT2/出荷依頼/出庫日Toが逆転していたらエラー
        IF (gr_param.lt2_ship_date_from > gr_param.lt2_ship_date_to) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_date_err    -- 入力パラメータ書式エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_lt2_ship_date_to  -- '生産物流LT2/出荷依頼/出庫日T0'
                                 ,gv_cnst_tkn_para2    -- トークン'PRAMETER2'
                                 ,gv_tkn_lt2_ship_date_from)  -- '生産物流LT2/出荷依頼/出庫日From'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- 出庫形態が「出荷依頼」以外の場合
      -- -----------------------------------------------------
      IF (gr_param.transaction_type_id <> gv_transaction_type_id_ship) THEN
        -- 出庫日Fromが入力されていない場合はエラーとする
        IF (gv_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_ship_date_from)  -- '出庫日From'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- 日付型(YYYY/MM/DD)に変換して格納
          -- ==============================================================
          gr_param.ship_date_from := FND_DATE.STRING_TO_DATE( gv_ship_date_from,'YYYY/MM/DD');
          IF (gr_param.ship_date_from IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                   ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                   ,gv_tkn_ship_date_from        -- '出庫日From'
                                   ,gv_cnst_tkn_date    -- トークン'DATE'
                                   ,TO_CHAR(gv_ship_date_from))  -- '出庫日From'
                                   ,1
                                   ,5000);
            -- エラーリターン＆処理中止
            RAISE global_api_expt;
          END IF;
        END IF;
        -- 出庫日Toが入力されていない場合はエラーとする
        IF (gv_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_ship_date_to)  -- '出庫日To'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- 日付型(YYYY/MM/DD)に変換して格納
          -- ==============================================================
          gr_param.ship_date_to := FND_DATE.STRING_TO_DATE( gv_ship_date_to,'YYYY/MM/DD');
          IF (gr_param.ship_date_to IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                   ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                   ,gv_tkn_ship_date_to        -- '出庫日To'
                                   ,gv_cnst_tkn_date    -- トークン'DATE'
                                   ,TO_CHAR(gv_ship_date_to))  -- '出庫日To'
                                   ,1
                                   ,5000);
            -- エラーリターン＆処理中止
            RAISE global_api_expt;
          END IF;
        END IF;
        -- 出庫日Fromと出庫日Toが逆転していたらエラー
        IF (gr_param.ship_date_from > gr_param.ship_date_to) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_date_err    -- 入力パラメータ書式エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_ship_date_to  -- '出庫日From'
                                 ,gv_cnst_tkn_para2    -- トークン'PRAMETER2'
                                 ,gv_tkn_ship_date_from)  -- '出庫日To'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
    -- -----------------------------------------------------
    -- 処理種別が「支給指示」又は「支給指示/移動指示」の場合
    -- -----------------------------------------------------
    IF (gr_param.shipping_biz_type IN (gv_proc_fix_block_prov,gv_proc_fix_block_prov_move)) THEN
      -- 支給/出庫日Fromが入力されていない場合はエラーとする
      IF (gv_prov_ship_date_from IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- 入力パラメータ未入力エラー
                               ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                               ,gv_tkn_prov_ship_date_from)  -- '支給/出庫日From'
                               ,1
                               ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- 日付型(YYYY/MM/DD)に変換して格納
        -- ==============================================================
        gr_param.prov_ship_date_from := FND_DATE.STRING_TO_DATE( gv_prov_ship_date_from
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.prov_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_prov_ship_date_from        -- '支給/出庫日From'
                                 ,gv_cnst_tkn_date    -- トークン'DATE'
                                 ,TO_CHAR(gv_prov_ship_date_from))  -- '支給/出庫日From'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
      -- 支給/出庫日Toが入力されていない場合はエラーとする
      IF (gv_prov_ship_date_to IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- 入力パラメータ未入力エラー
                               ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                               ,gv_tkn_prov_ship_date_to)  -- '支給/出庫日To'
                               ,1
                               ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- 日付型(YYYY/MM/DD)に変換して格納
        -- ==============================================================
        gr_param.prov_ship_date_to := FND_DATE.STRING_TO_DATE( gv_prov_ship_date_to
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.prov_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_prov_ship_date_to        -- '支給/出庫日To'
                                 ,gv_cnst_tkn_date    -- トークン'DATE'
                                 ,TO_CHAR(gv_prov_ship_date_to))  -- '支給/出庫日To'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
      -- 支給/出庫日Fromと支給/出庫日Toが逆転していたらエラー
      IF (gr_param.prov_ship_date_from > gr_param.prov_ship_date_to) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_input_date_err    -- 入力パラメータ書式エラー
                               ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                               ,gv_tkn_prov_ship_date_to  -- '支給/出庫日To'
                               ,gv_cnst_tkn_para2    -- トークン'PRAMETER2'
                               ,gv_tkn_prov_ship_date_from)  -- '支給/出庫日From'
                               ,1
                               ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      END IF;
    END IF;
    -- -----------------------------------------------------
    -- 処理種別が「移動指示」又は又は「出荷依頼/移動指示「支給指示/移動指示」の場合
    -- -----------------------------------------------------
    IF (gr_param.shipping_biz_type IN (gv_proc_fix_block_move,gv_proc_fix_block_ship_move
                                                             ,gv_proc_fix_block_prov_move)) THEN
      -- 移動/出庫日Fromが入力されていない場合はエラーとする
      IF (gv_move_ship_date_from IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- 入力パラメータ未入力エラー
                               ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                               ,gv_tkn_move_ship_date_from)  -- '移動/出庫日From'
                               ,1
                               ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- 日付型(YYYY/MM/DD)に変換して格納
        -- ==============================================================
        gr_param.move_ship_date_from := FND_DATE.STRING_TO_DATE( gv_move_ship_date_from
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.move_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_move_ship_date_from        -- '移動/出庫日From'
                                 ,gv_cnst_tkn_date    -- トークン'DATE'
                                 ,TO_CHAR(gv_move_ship_date_from))  -- '移動/出庫日From'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
      -- 移動/出庫日Toが入力されていない場合はエラーとする
      IF (gv_move_ship_date_to IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- 入力パラメータ未入力エラー
                               ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                               ,gv_tkn_move_ship_date_to)  -- '移動/出庫日To'
                               ,1
                               ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- 日付型(YYYY/MM/DD)に変換して格納
        -- ==============================================================
        gr_param.move_ship_date_to := FND_DATE.STRING_TO_DATE( gv_move_ship_date_to
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.move_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- 入力パラメータ未入力エラー
                                 ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                                 ,gv_tkn_move_ship_date_to        -- '移動/出庫日To'
                                 ,gv_cnst_tkn_date    -- トークン'DATE'
                                 ,TO_CHAR(gv_move_ship_date_to))  -- '移動/出庫日To'
                                 ,1
                                 ,5000);
          -- エラーリターン＆処理中止
          RAISE global_api_expt;
        END IF;
      END IF;
      -- 移動/出庫日Fromと移動/出庫日Toが逆転していたらエラー
      IF (gr_param.move_ship_date_from > gr_param.move_ship_date_to) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_input_date_err    -- 入力パラメータ書式エラー
                               ,gv_cnst_tkn_para    -- トークン'PRAMETER'
                               ,gv_tkn_move_ship_date_to  -- '移動/出庫日To'
                               ,gv_cnst_tkn_para2    -- トークン'PRAMETER2'
                               ,gv_tkn_move_ship_date_from)  -- '移動/出庫日From'
                               ,1
                               ,5000);
        -- エラーリターン＆処理中止
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : D-2 プロファイル取得
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
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
    -- 商品区分（セキュリティ）取得
    gv_item_div_security := FND_PROFILE.VALUE(gv_prof_item_div_security);
    IF (gv_item_div_security IS NULL) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh,gv_profile_err
                                                         ,'PROF_NAME',gv_tkn_item_div_security);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
    --==============================================================
    -- 在庫組織コード取得
    --==============================================================
    gt_inv_org_code := FND_PROFILE.VALUE( gv_xxcoi1_organization_code );
    IF ( gt_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_cons_msg_kbn_wsh
                    ,iv_name         => gv_inv_org_code_err
                    ,iv_token_name1  => gv_tkn_pro_tok              -- プロファイル名
                    ,iv_token_value1 => gv_xxcoi1_organization_code
                   );
-- 2015/03/19 V1.12 Mod START
--      RAISE global_process_expt;
      RAISE global_api_expt;
-- 2015/03/19 V1.12 Mod END
    END IF;
--
    --==============================================================
    -- 在庫組織ID取得
    --==============================================================
    gt_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => gt_inv_org_code
                 );
    IF ( gt_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_cons_msg_kbn_wsh
                    ,iv_name         => gv_inv_org_id_err
                    ,iv_token_name1  => gv_tkn_org_code_tok -- 在庫組織コード
                    ,iv_token_value1 => gt_inv_org_code
                   );
-- 2015/03/19 V1.12 Mod START
--      RAISE global_process_expt;
      RAISE global_api_expt;
-- 2015/03/19 V1.12 Mod END
    END IF;
--
-- 2015/03/19 V1.12 Del START
--    --==============================================================
--    -- 業務日付取得
--    --==============================================================
--    gd_process_date := xxccp_common_pkg2.get_process_date;
--    IF ( gd_process_date IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => gv_cons_msg_kbn_wsh
--                    ,iv_name         => gv_process_date_err
--                   );
--      RAISE global_process_expt;
--    END IF;
-- 2015/03/19 V1.12 Del End
--
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
--
  EXCEPTION
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
  END get_profile;
--
  /***********************************************************************************************
   * Procedure Name   : ins_temp_data
   * Description      : 中間テーブル登録
   ***********************************************************************************************/
  PROCEDURE ins_temp_data
    (
      ir_temp_tab_tab   IN     rec_temp_tab_data_tab -- 中間テーブル登録データ群
     ,ov_errbuf         OUT    VARCHAR2             -- エラー・メッセージ
     ,ov_retcode        OUT    VARCHAR2             -- リターン・コード
     ,ov_errmsg         OUT    VARCHAR2             -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'ins_temp_data' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 中間テーブル登録
    -- ====================================================
    <<ins_temp_loop>>
    FOR i IN ir_temp_tab_tab.FIRST .. ir_temp_tab_tab.LAST LOOP
      INSERT INTO xxwsh.xxwsh_confirm_block_tmp
        (
          data_class              -- データ区分
         ,whse_code               -- 保管倉庫コード
         ,header_id               -- ヘッダID
         ,notif_status            -- 通知ステータス
         ,prod_class              -- 商品区分
         ,item_class              -- 品目区分
         ,delivery_no             -- 配送No
         ,request_no              -- 依頼No
         ,freight_charge_class    -- 運賃区分
         ,d1_whse_code            -- D+1倉庫フラグ
         ,base_date               -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
         ,deliver_to_id           -- 出荷先ID
         ,result_deliver_to_id    -- 出荷先_実績ID
         ,arrival_date            -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
         ,created_by              -- 作成者
         ,creation_date           -- 作成日
         ,last_updated_by         -- 最終更新者
         ,last_update_date        -- 最終更新日
         ,request_id              -- 要求ID
         ,program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,program_id              -- コンカレント・プログラムID
        )
      VALUES
        (
          SUBSTRB( ir_temp_tab_tab(i).data_class  , 1, 1  )   -- データ区分
         ,SUBSTRB( ir_temp_tab_tab(i).whse_code  , 1, 4  )   -- 保管倉庫コード
         ,ir_temp_tab_tab(i).header_id    -- ヘッダID
         ,SUBSTRB( ir_temp_tab_tab(i).notif_status  , 1, 3  )  -- 通知ステータス
         ,SUBSTRB( ir_temp_tab_tab(i).prod_class    , 1, 2  )  -- 商品区分
         ,SUBSTRB( ir_temp_tab_tab(i).item_class    , 1, 2  ) -- 品目区分
         ,SUBSTRB( ir_temp_tab_tab(i).delivery_no   , 1, 12  ) -- 配送No
         ,SUBSTRB( ir_temp_tab_tab(i).request_no    , 1, 12  ) -- 依頼No
         ,SUBSTRB( ir_temp_tab_tab(i).freight_charge_class , 1, 1  ) -- 運賃区分
         ,SUBSTRB( ir_temp_tab_tab(i).d1_whse_code   , 1, 1  ) -- D+1倉庫フラグ
         ,ir_temp_tab_tab(i).base_date                         -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
         ,ir_temp_tab_tab(i).deliver_to_id                     -- 出荷先ID
         ,ir_temp_tab_tab(i).result_deliver_to_id              -- 出荷先_実績ID
         ,ir_temp_tab_tab(i).arrival_date                      -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
         ,gt_user_id                                           -- 作成者
         ,gt_system_date                                       -- 作成日
         ,gt_user_id                                           -- 最終更新者
         ,gt_system_date                                       -- 更新日
         ,gt_conc_request_id                                   -- 要求ID
         ,gt_prog_appl_id                                      -- アプリケーションID
         ,gt_conc_program_id                                   -- プログラムID
        ) ;
    END LOOP ins_temp_loop;
--
    -- ====================================================
    -- アウトパラメータセット
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    エラー・メッセージ           --# 固定 #
    ov_retcode := lv_retcode ;    --    リターン・コード             --# 固定 #
    ov_errmsg  := lv_errmsg ;     --    ユーザー・エラー・メッセージ --# 固定 #
--
  EXCEPTION
--##### 固定例外処理部 START ######################################################################
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
--##### 固定例外処理部 END   ######################################################################
  END ins_temp_data;
--
  /**********************************************************************************
   * Procedure Name   : get_confirm_block_header
   * Description      : D-3  出荷・支給・移動情報ヘッダ抽出処理
   ***********************************************************************************/
  PROCEDURE get_confirm_block_header(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_confirm_block_header'; -- プログラム名
    cv_order_category_code   CONSTANT VARCHAR2(5)    := 'ORDER'; -- 受注カテゴリ「受注」
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
    lr_temp_tab             rec_temp_tab_data ;   -- 中間テーブル登録用レコード変数
    lr_temp_tab_tab       rec_temp_tab_data_tab ;   -- 中間テーブル登録用レコード変数
--
    -- *** ローカル・カーソル ***
-- ##### 20080904 1.6 統合#45 対応 START #####
/********** カーソル定義変更によりコメントアウト
    CURSOR cur_sel_order_a(lv_code_class2 VARCHAR2)
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
        END                              AS data_class -- データ区分「出荷依頼：1」「出荷取消：8」
           , xil2v.segment1              AS whse_code       -- 保管倉庫コード
           , xoha.order_header_id        AS order_header_id  -- 受注ヘッダアドオンID
           , xoha.notif_status           AS notif_status    -- 通知ステータス
           , xoha.prod_class             AS prod_class    -- 商品区分
           , NULL                        AS item_class      -- 品目区分
           , xoha.delivery_no            AS delivery_no      -- 配送NO
           , xoha.request_no             AS request_no      -- 依頼NO
           , xoha.freight_charge_class   AS freight_charge_class      -- 運賃区分
           , xil2v.d1_whse_code          AS d1_whse_code      -- D+1倉庫フラグ
           , gr_param.lt1_ship_date_from AS base_date      -- 基準日
      FROM xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
           xxwsh_oe_transaction_types2_v      xott2v,       -- 受注タイプ
           xxcmn_item_locations2_v            xil2v,    -- OPM保管場所情報
-- 2008/08/04 D.Nihei MOD START
--           xxcmn_delivery_lt2_v               xdl2v       -- 配送L/Tアドオン
           (SELECT entering_despatching_code1
                  ,entering_despatching_code2
                  ,code_class1
                  ,code_class2
                  ,leaf_lead_time_day
                  ,drink_lead_time_day
                  ,lt_start_date_active
                  ,lt_end_date_active
            FROM   xxcmn_delivery_lt2_v    -- 配送L/Tアドオン
            GROUP BY entering_despatching_code1
                  ,entering_despatching_code2
                  ,code_class1
                  ,code_class2
                  ,leaf_lead_time_day
                  ,drink_lead_time_day
                  ,lt_start_date_active
                  ,lt_end_date_active)        xdl2v       -- 配送L/Tアドオン
-- 2008/08/04 D.Nihei MOD END
      WHERE
      -- プロファイル．商品区分
           xoha.prod_class               = gv_item_div_security
      -- パラメータ条件．部署
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- 適用日
      AND   gr_param.lt1_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.lt1_ship_date_from )
      -- パラメータ条件．出庫元
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- パラメータ条件．ブロック１・２・３
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- 受注タイプ
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- 出荷依頼
      AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship     -- 出荷依頼
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- 出荷：締済み
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- 未通知
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- 再通知要
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- 出荷：取消
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- 再通知要
          )
      -- パラメータ条件．生産物流LT1/出荷依頼/出庫日FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.lt1_ship_date_from
                                    AND  NVL( gr_param.lt1_ship_date_to, xoha.schedule_ship_date )
      ---------------------------------------------------------------------------------------------
      -- 配送L/Tアドオン
      ---------------------------------------------------------------------------------------------
      AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
      AND   xoha.deliver_to         =  xdl2v.entering_despatching_code2
-- 2008/08/04 D.Nihei DEL START
--      -- Add start 2008/06/24 uehara
--      AND   xoha.shipping_method_code = xdl2v.ship_method
--      -- Add end 2008/06/24 uehara
-- 2008/08/04 D.Nihei DEL END
      AND   xdl2v.code_class1          =  gv_whse_code
      AND   xdl2v.code_class2          =  lv_code_class2 -- コード区分(1:拠点 9:配送先)
      -- パラメータ条件．生産物流LT1
      AND   CASE gv_item_div_security
              WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
              WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
            END = gr_param.lead_time_day_01
      -- 適用日
      AND   gr_param.lt1_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                  AND NVL( xdl2v.lt_end_date_active, gr_param.lt1_ship_date_from )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
**********/
    ----------------------------------------------------------------------------------------------
    -- ＜抽出条件(A)＞出荷依頼 生産物流LT1指定の場合
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_order_a
    IS
      SELECT  lt1_date.data_class            -- データ区分「出荷依頼：1」「出荷取消：8」
           ,  lt1_date.whse_code             -- 保管倉庫コード
           ,  lt1_date.order_header_id       -- 受注ヘッダアドオンID
           ,  lt1_date.notif_status          -- 通知ステータス
           ,  lt1_date.prod_class            -- 商品区分
           ,  lt1_date.item_class            -- 品目区分
           ,  lt1_date.delivery_no           -- 配送NO
           ,  lt1_date.request_no            -- 依頼NO
           ,  lt1_date.freight_charge_class  -- 運賃区分
           ,  lt1_date.d1_whse_code          -- D+1倉庫フラグ
           ,  lt1_date.base_date             -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
           ,  lt1_date.deliver_to_id         -- 出荷先ID
           ,  lt1_date.result_deliver_to_id  -- 出荷先_実績ID
           ,  lt1_date.arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
      FROM 
        (
          -- ＜抽出条件(A)＞配送先
          SELECT
            CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
                 WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
            END                              AS data_class            -- データ区分「出荷依頼：1」「出荷取消：8」
               , xil2v.segment1              AS whse_code             -- 保管倉庫コード
               , xoha.order_header_id        AS order_header_id       -- 受注ヘッダアドオンID
               , xoha.notif_status           AS notif_status          -- 通知ステータス
               , xoha.prod_class             AS prod_class            -- 商品区分
               , NULL                        AS item_class            -- 品目区分
               , xoha.delivery_no            AS delivery_no           -- 配送NO
               , xoha.request_no             AS request_no            -- 依頼NO
               , xoha.freight_charge_class   AS freight_charge_class  -- 運賃区分
               , xil2v.d1_whse_code          AS d1_whse_code          -- D+1倉庫フラグ
               , gr_param.lt1_ship_date_from AS base_date             -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
               , xoha.deliver_to_id          AS deliver_to_id         -- 出荷先ID
               , xoha.result_deliver_to_id   AS result_deliver_to_id  -- 出荷先_実績ID
               , xoha.schedule_arrival_date  AS arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
          FROM xxwsh_order_headers_all            xoha,               -- 受注ヘッダアドオン
               xxwsh_oe_transaction_types2_v      xott2v,             -- 受注タイプ
               xxcmn_item_locations2_v            xil2v,              -- OPM保管場所情報
               (SELECT entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active
                FROM   xxcmn_delivery_lt2_v         -- 配送L/Tアドオン
                GROUP BY entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active)        xdl2v       -- 配送L/Tアドオン
          WHERE
          -- プロファイル．商品区分
               xoha.prod_class               = gv_item_div_security
          -- パラメータ条件．部署
          AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
          ---------------------------------------------------------------------------------------------
          -- ＯＰＭ保管場所
          ---------------------------------------------------------------------------------------------
          AND  xoha.deliver_from          = xil2v.segment1
          -- 適用日
          AND   gr_param.lt1_ship_date_from BETWEEN xil2v.date_from
                                      AND NVL( xil2v.date_to, gr_param.lt1_ship_date_from )
          -- パラメータ条件．出庫元
          AND   ( xil2v.segment1          = gr_param.shipped_locat_code
          -- パラメータ条件．ブロック１・２・３
          OR      xil2v.distribution_block = gr_param.block_01
          OR      xil2v.distribution_block = gr_param.block_02
          OR      xil2v.distribution_block = gr_param.block_03
          OR    (   gr_param.shipped_locat_code IS NULL
                AND gr_param.block_01           IS NULL
                AND gr_param.block_02           IS NULL
                AND gr_param.block_03           IS NULL))
          ---------------------------------------------------------------------------------------------
          -- 受注タイプ
          ---------------------------------------------------------------------------------------------
          AND   xott2v.order_category_code  = gv_order_cat_o
          AND   xott2v.shipping_shikyu_class = gv_sp_class_ship             -- 出荷依頼
          AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship   -- 出荷依頼
          AND   xoha.order_type_id          = xott2v.transaction_type_id
          ---------------------------------------------------------------------------------------------
          -- 受注ヘッダアドオン
          ---------------------------------------------------------------------------------------------
          AND ((  xoha.req_status             = gc_req_status_s_cmpb            -- 出荷：締済み
              AND (     xoha.notif_status           = gc_notif_status_unnotif       -- 未通知
                  OR    xoha.notif_status           = gc_notif_status_renotif ))    -- 再通知要
          OR  (  xoha.req_status             = gc_req_status_p_ccl              -- 出荷：取消
              AND   xoha.notif_status           = gc_notif_status_renotif )         -- 再通知要
              )
          -- パラメータ条件．生産物流LT1/出荷依頼/出庫日FromTo
          AND   xoha.schedule_ship_date BETWEEN gr_param.lt1_ship_date_from
                                        AND  NVL( gr_param.lt1_ship_date_to, xoha.schedule_ship_date )
          ---------------------------------------------------------------------------------------------
          -- 配送L/Tアドオン
          ---------------------------------------------------------------------------------------------
          AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
          AND   xoha.deliver_to         =  xdl2v.entering_despatching_code2
          AND   xdl2v.code_class1          =  gv_whse_code
          AND   xdl2v.code_class2          =  gv_deliver_to -- コード区分(9:配送先)
          -- パラメータ条件．生産物流LT1
          AND   CASE gv_item_div_security
                  WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
                  WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
                END = gr_param.lead_time_day_01
          -- 適用日
          AND   gr_param.lt1_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                      AND NVL( xdl2v.lt_end_date_active, gr_param.lt1_ship_date_from )
          UNION
          -- ＜抽出条件(A)＞拠点
          SELECT
            CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
                 WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
            END                              AS data_class            -- データ区分「出荷依頼：1」「出荷取消：8」
               , xil2v.segment1              AS whse_code             -- 保管倉庫コード
               , xoha.order_header_id        AS order_header_id       -- 受注ヘッダアドオンID
               , xoha.notif_status           AS notif_status          -- 通知ステータス
               , xoha.prod_class             AS prod_class            -- 商品区分
               , NULL                        AS item_class            -- 品目区分
               , xoha.delivery_no            AS delivery_no           -- 配送NO
               , xoha.request_no             AS request_no            -- 依頼NO
               , xoha.freight_charge_class   AS freight_charge_class  -- 運賃区分
               , xil2v.d1_whse_code          AS d1_whse_code          -- D+1倉庫フラグ
               , gr_param.lt1_ship_date_from AS base_date             -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
               , xoha.deliver_to_id          AS deliver_to_id         -- 出荷先ID
               , xoha.result_deliver_to_id   AS result_deliver_to_id  -- 出荷先_実績ID
               , xoha.schedule_arrival_date  AS arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
          FROM xxwsh_order_headers_all            xoha,               -- 受注ヘッダアドオン
               xxwsh_oe_transaction_types2_v      xott2v,             -- 受注タイプ
               xxcmn_item_locations2_v            xil2v,              -- OPM保管場所情報
               (SELECT entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active
                FROM   xxcmn_delivery_lt2_v         -- 配送L/Tアドオン
                GROUP BY entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active)        xdl2v       -- 配送L/Tアドオン
          WHERE
          -- プロファイル．商品区分
               xoha.prod_class               = gv_item_div_security
          -- パラメータ条件．部署
          AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
          ---------------------------------------------------------------------------------------------
          -- ＯＰＭ保管場所
          ---------------------------------------------------------------------------------------------
          AND  xoha.deliver_from          = xil2v.segment1
          -- 適用日
          AND   gr_param.lt1_ship_date_from BETWEEN xil2v.date_from
                                      AND NVL( xil2v.date_to, gr_param.lt1_ship_date_from )
          -- パラメータ条件．出庫元
          AND   ( xil2v.segment1          = gr_param.shipped_locat_code
          -- パラメータ条件．ブロック１・２・３
          OR      xil2v.distribution_block = gr_param.block_01
          OR      xil2v.distribution_block = gr_param.block_02
          OR      xil2v.distribution_block = gr_param.block_03
          OR    (   gr_param.shipped_locat_code IS NULL
                AND gr_param.block_01           IS NULL
                AND gr_param.block_02           IS NULL
                AND gr_param.block_03           IS NULL))
          ---------------------------------------------------------------------------------------------
          -- 受注タイプ
          ---------------------------------------------------------------------------------------------
          AND   xott2v.order_category_code  = gv_order_cat_o
          AND   xott2v.shipping_shikyu_class = gv_sp_class_ship             -- 出荷依頼
          AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship   -- 出荷依頼
          AND   xoha.order_type_id          = xott2v.transaction_type_id
          ---------------------------------------------------------------------------------------------
          -- 受注ヘッダアドオン
          ---------------------------------------------------------------------------------------------
          AND ((  xoha.req_status             = gc_req_status_s_cmpb            -- 出荷：締済み
              AND (     xoha.notif_status           = gc_notif_status_unnotif       -- 未通知
                  OR    xoha.notif_status           = gc_notif_status_renotif ))    -- 再通知要
          OR  (  xoha.req_status             = gc_req_status_p_ccl              -- 出荷：取消
              AND   xoha.notif_status           = gc_notif_status_renotif )         -- 再通知要
              )
          -- パラメータ条件．生産物流LT1/出荷依頼/出庫日FromTo
          AND   xoha.schedule_ship_date BETWEEN gr_param.lt1_ship_date_from
                                        AND  NVL( gr_param.lt1_ship_date_to, xoha.schedule_ship_date )
          ---------------------------------------------------------------------------------------------
          -- 配送L/Tアドオン
          ---------------------------------------------------------------------------------------------
          AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
          AND   xoha.head_sales_branch  =  xdl2v.entering_despatching_code2
          AND   xdl2v.code_class1          =  gv_whse_code
          AND   xdl2v.code_class2          =  gv_sales_code -- コード区分(1:拠点)
          -- パラメータ条件．生産物流LT1
          AND   CASE gv_item_div_security
                  WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
                  WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
                END = gr_param.lead_time_day_01
          -- 適用日
          AND   gr_param.lt1_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                      AND NVL( xdl2v.lt_end_date_active, gr_param.lt1_ship_date_from )
          ---------------------------------------------------------------------------------------------
          -- 配送L/Tアドオン（配送先で登録されていないこと）
          ---------------------------------------------------------------------------------------------
          AND NOT EXISTS (  SELECT  'X'
                            FROM    xxcmn_delivery_lt2_v  e_xdl2v       -- 配送L/Tアドオン
                            WHERE   e_xdl2v.code_class1                 = gv_whse_code
                            AND     e_xdl2v.entering_despatching_code1  = xoha.deliver_from
                            AND     e_xdl2v.code_class2                 = gv_deliver_to
                            AND     e_xdl2v.entering_despatching_code2  = xoha.deliver_to
                            AND     gr_param.lt1_ship_date_from BETWEEN e_xdl2v.lt_start_date_active 
                                            AND NVL( e_xdl2v.lt_end_date_active, gr_param.lt1_ship_date_from )
                         )
        ) lt1_date,
        xxwsh_order_headers_all xoha_lock
      WHERE lt1_date.order_header_id = xoha_lock.order_header_id
      FOR UPDATE OF xoha_lock.order_header_id NOWAIT
      ;
-- ##### 20080904 1.6 統合#45 対応 END   #####
--
-- ##### 20080904 1.6 統合#45 対応 START #####
/**********  カーソル定義変更によりコメントアウト
    CURSOR cur_sel_order_b(lv_code_class2 VARCHAR2)
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
        END                              AS data_class -- データ区分「出荷依頼：1」「出荷取消：8」
           , xil2v.segment1              AS whse_code       -- 保管倉庫コード
           , xoha.order_header_id        AS order_header_id  -- 受注ヘッダアドオンID
           , xoha.notif_status           AS notif_status    -- 通知ステータス
           , xoha.prod_class             AS prod_class    -- 商品区分
           , NULL                        AS item_class      -- 品目区分
           , xoha.delivery_no            AS delivery_no      -- 配送NO
           , xoha.request_no             AS request_no      -- 依頼NO
           , xoha.freight_charge_class   AS freight_charge_class      -- 運賃区分
           , xil2v.d1_whse_code           AS d1_whse_code      -- D+1倉庫フラグ
           , gr_param.lt2_ship_date_from AS base_date      -- 基準日
      FROM xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
           xxwsh_oe_transaction_types2_v      xott2v,       -- 受注タイプ
           xxcmn_item_locations2_v            xil2v,    -- OPM保管場所情報
-- 2008/08/04 D.Nihei MOD START
--           xxcmn_delivery_lt2_v               xdl2v       -- 配送L/Tアドオン
           (SELECT entering_despatching_code1
                  ,entering_despatching_code2
                  ,code_class1
                  ,code_class2
                  ,leaf_lead_time_day
                  ,drink_lead_time_day
                  ,lt_start_date_active
                  ,lt_end_date_active
            FROM   xxcmn_delivery_lt2_v    -- 配送L/Tアドオン
            GROUP BY entering_despatching_code1
                  ,entering_despatching_code2
                  ,code_class1
                  ,code_class2
                  ,leaf_lead_time_day
                  ,drink_lead_time_day
                  ,lt_start_date_active
                  ,lt_end_date_active)        xdl2v       -- 配送L/Tアドオン
-- 2008/08/04 D.Nihei MOD END
      WHERE
      -- プロファイル．商品区分
           xoha.prod_class               = gv_item_div_security
      -- パラメータ条件．部署
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- 適用日
      AND   gr_param.lt2_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.lt2_ship_date_from )
      -- パラメータ条件．出庫元
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- パラメータ条件．ブロック１・２・３
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- 受注タイプ
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- 出荷依頼
      AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship     -- 出荷依頼
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- 出荷：締済み
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- 未通知
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- 再通知要
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- 出荷：取消
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- 再通知要
          )
      -- パラメータ条件．生産物流LT2/出荷依頼/出庫日FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.lt2_ship_date_from
                                    AND  NVL( gr_param.lt2_ship_date_to, xoha.schedule_ship_date )
      ---------------------------------------------------------------------------------------------
      -- 配送L/Tアドオン
      ---------------------------------------------------------------------------------------------
      AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
      AND   xoha.deliver_to         =  xdl2v.entering_despatching_code2
-- 2008/08/04 D.Nihei DEL START
--      -- Add start 2008/06/24 uehara
--      AND   xoha.shipping_method_code = xdl2v.ship_method
--      -- Add end 2008/06/24 uehara
-- 2008/08/04 D.Nihei DEL END
      AND   xdl2v.code_class1          =  gv_whse_code
      AND   xdl2v.code_class2          =  lv_code_class2 -- コード区分(1:拠点 9:配送先)
      -- パラメータ条件．生産物流LT2
      AND   CASE gv_item_div_security
              WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
              WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
            END = gr_param.lead_time_day_02
      -- 適用日
      AND   gr_param.lt2_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                  AND NVL( xdl2v.lt_end_date_active, gr_param.lt2_ship_date_from )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
**********/
    ----------------------------------------------------------------------------------------------
    -- ＜抽出条件(B)＞出荷依頼 生産物流LT2指定の場合
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_order_b
    IS
      SELECT  lt1_date.data_class            -- データ区分「出荷依頼：1」「出荷取消：8」
           ,  lt1_date.whse_code             -- 保管倉庫コード
           ,  lt1_date.order_header_id       -- 受注ヘッダアドオンID
           ,  lt1_date.notif_status          -- 通知ステータス
           ,  lt1_date.prod_class            -- 商品区分
           ,  lt1_date.item_class            -- 品目区分
           ,  lt1_date.delivery_no           -- 配送NO
           ,  lt1_date.request_no            -- 依頼NO
           ,  lt1_date.freight_charge_class  -- 運賃区分
           ,  lt1_date.d1_whse_code          -- D+1倉庫フラグ
           ,  lt1_date.base_date             -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
           ,  lt1_date.deliver_to_id         -- 出荷先ID
           ,  lt1_date.result_deliver_to_id  -- 出荷先_実績ID
           ,  lt1_date.arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
      FROM 
        (
          -- ＜抽出条件(B)＞配送先
          SELECT
            CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
                 WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
            END                              AS data_class -- データ区分「出荷依頼：1」「出荷取消：8」
               , xil2v.segment1              AS whse_code       -- 保管倉庫コード
               , xoha.order_header_id        AS order_header_id  -- 受注ヘッダアドオンID
               , xoha.notif_status           AS notif_status    -- 通知ステータス
               , xoha.prod_class             AS prod_class    -- 商品区分
               , NULL                        AS item_class      -- 品目区分
               , xoha.delivery_no            AS delivery_no      -- 配送NO
               , xoha.request_no             AS request_no      -- 依頼NO
               , xoha.freight_charge_class   AS freight_charge_class      -- 運賃区分
               , xil2v.d1_whse_code          AS d1_whse_code      -- D+1倉庫フラグ
               , gr_param.lt2_ship_date_from AS base_date      -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
               , xoha.deliver_to_id          AS deliver_to_id         -- 出荷先ID
               , xoha.result_deliver_to_id   AS result_deliver_to_id  -- 出荷先_実績ID
               , xoha.schedule_arrival_date  AS arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
          FROM xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
               xxwsh_oe_transaction_types2_v      xott2v,       -- 受注タイプ
               xxcmn_item_locations2_v            xil2v,    -- OPM保管場所情報
               (SELECT entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active
                FROM   xxcmn_delivery_lt2_v    -- 配送L/Tアドオン
                GROUP BY entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active)        xdl2v       -- 配送L/Tアドオン
          WHERE
          -- プロファイル．商品区分
               xoha.prod_class               = gv_item_div_security
          -- パラメータ条件．部署
          AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
          ---------------------------------------------------------------------------------------------
          -- ＯＰＭ保管場所
          ---------------------------------------------------------------------------------------------
          AND  xoha.deliver_from          = xil2v.segment1
          -- 適用日
          AND   gr_param.lt2_ship_date_from BETWEEN xil2v.date_from
                                      AND NVL( xil2v.date_to, gr_param.lt2_ship_date_from )
          -- パラメータ条件．出庫元
          AND   ( xil2v.segment1          = gr_param.shipped_locat_code
          -- パラメータ条件．ブロック１・２・３
          OR      xil2v.distribution_block = gr_param.block_01
          OR      xil2v.distribution_block = gr_param.block_02
          OR      xil2v.distribution_block = gr_param.block_03
          OR    (   gr_param.shipped_locat_code IS NULL
                AND gr_param.block_01           IS NULL
                AND gr_param.block_02           IS NULL
                AND gr_param.block_03           IS NULL))
          ---------------------------------------------------------------------------------------------
          -- 受注タイプ
          ---------------------------------------------------------------------------------------------
          AND   xott2v.order_category_code  = gv_order_cat_o
          AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- 出荷依頼
          AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship     -- 出荷依頼
          AND   xoha.order_type_id          = xott2v.transaction_type_id
          ---------------------------------------------------------------------------------------------
          -- 受注ヘッダアドオン
          ---------------------------------------------------------------------------------------------
          AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- 出荷：締済み
              AND (     xoha.notif_status           = gc_notif_status_unnotif    -- 未通知
                  OR    xoha.notif_status           = gc_notif_status_renotif ))   -- 再通知要
          OR  (  xoha.req_status             = gc_req_status_p_ccl      -- 出荷：取消
              AND   xoha.notif_status           = gc_notif_status_renotif )   -- 再通知要
              )
          -- パラメータ条件．生産物流LT2/出荷依頼/出庫日FromTo
          AND   xoha.schedule_ship_date BETWEEN gr_param.lt2_ship_date_from
                                        AND  NVL( gr_param.lt2_ship_date_to, xoha.schedule_ship_date )
          ---------------------------------------------------------------------------------------------
          -- 配送L/Tアドオン
          ---------------------------------------------------------------------------------------------
          AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
          AND   xoha.deliver_to         =  xdl2v.entering_despatching_code2
          AND   xdl2v.code_class1          =  gv_whse_code
          AND   xdl2v.code_class2          =  gv_deliver_to -- コード区分(9:配送先)
          -- パラメータ条件．生産物流LT2
          AND   CASE gv_item_div_security
                  WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
                  WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
                END = gr_param.lead_time_day_02
          -- 適用日
          AND   gr_param.lt2_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                      AND NVL( xdl2v.lt_end_date_active, gr_param.lt2_ship_date_from )
          UNION
          -- ＜抽出条件(B)＞拠点
          SELECT
            CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
                 WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
            END                              AS data_class -- データ区分「出荷依頼：1」「出荷取消：8」
               , xil2v.segment1              AS whse_code       -- 保管倉庫コード
               , xoha.order_header_id        AS order_header_id  -- 受注ヘッダアドオンID
               , xoha.notif_status           AS notif_status    -- 通知ステータス
               , xoha.prod_class             AS prod_class    -- 商品区分
               , NULL                        AS item_class      -- 品目区分
               , xoha.delivery_no            AS delivery_no      -- 配送NO
               , xoha.request_no             AS request_no      -- 依頼NO
               , xoha.freight_charge_class   AS freight_charge_class      -- 運賃区分
               , xil2v.d1_whse_code          AS d1_whse_code      -- D+1倉庫フラグ
               , gr_param.lt2_ship_date_from AS base_date      -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
               , xoha.deliver_to_id          AS deliver_to_id         -- 出荷先ID
               , xoha.result_deliver_to_id   AS result_deliver_to_id  -- 出荷先_実績ID
               , xoha.schedule_arrival_date  AS arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
          FROM xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
               xxwsh_oe_transaction_types2_v      xott2v,       -- 受注タイプ
               xxcmn_item_locations2_v            xil2v,    -- OPM保管場所情報
               (SELECT entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active
                FROM   xxcmn_delivery_lt2_v    -- 配送L/Tアドオン
                GROUP BY entering_despatching_code1
                      ,entering_despatching_code2
                      ,code_class1
                      ,code_class2
                      ,leaf_lead_time_day
                      ,drink_lead_time_day
                      ,lt_start_date_active
                      ,lt_end_date_active)        xdl2v       -- 配送L/Tアドオン
          WHERE
          -- プロファイル．商品区分
               xoha.prod_class               = gv_item_div_security
          -- パラメータ条件．部署
          AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
          ---------------------------------------------------------------------------------------------
          -- ＯＰＭ保管場所
          ---------------------------------------------------------------------------------------------
          AND  xoha.deliver_from          = xil2v.segment1
          -- 適用日
          AND   gr_param.lt2_ship_date_from BETWEEN xil2v.date_from
                                      AND NVL( xil2v.date_to, gr_param.lt2_ship_date_from )
          -- パラメータ条件．出庫元
          AND   ( xil2v.segment1          = gr_param.shipped_locat_code
          -- パラメータ条件．ブロック１・２・３
          OR      xil2v.distribution_block = gr_param.block_01
          OR      xil2v.distribution_block = gr_param.block_02
          OR      xil2v.distribution_block = gr_param.block_03
          OR    (   gr_param.shipped_locat_code IS NULL
                AND gr_param.block_01           IS NULL
                AND gr_param.block_02           IS NULL
                AND gr_param.block_03           IS NULL))
          ---------------------------------------------------------------------------------------------
          -- 受注タイプ
          ---------------------------------------------------------------------------------------------
          AND   xott2v.order_category_code  = gv_order_cat_o
          AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- 出荷依頼
          AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship     -- 出荷依頼
          AND   xoha.order_type_id          = xott2v.transaction_type_id
          ---------------------------------------------------------------------------------------------
          -- 受注ヘッダアドオン
          ---------------------------------------------------------------------------------------------
          AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- 出荷：締済み
              AND (     xoha.notif_status           = gc_notif_status_unnotif    -- 未通知
                  OR    xoha.notif_status           = gc_notif_status_renotif ))   -- 再通知要
          OR  (  xoha.req_status             = gc_req_status_p_ccl      -- 出荷：取消
              AND   xoha.notif_status           = gc_notif_status_renotif )   -- 再通知要
              )
          -- パラメータ条件．生産物流LT2/出荷依頼/出庫日FromTo
          AND   xoha.schedule_ship_date BETWEEN gr_param.lt2_ship_date_from
                                        AND  NVL( gr_param.lt2_ship_date_to, xoha.schedule_ship_date )
          ---------------------------------------------------------------------------------------------
          -- 配送L/Tアドオン
          ---------------------------------------------------------------------------------------------
          AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
          AND   xoha.head_sales_branch  =  xdl2v.entering_despatching_code2
          AND   xdl2v.code_class1          =  gv_whse_code
          AND   xdl2v.code_class2          =  gv_sales_code -- コード区分(1:拠点)
          -- パラメータ条件．生産物流LT2
          AND   CASE gv_item_div_security
                  WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
                  WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
                END = gr_param.lead_time_day_02
          -- 適用日
          AND   gr_param.lt2_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                      AND NVL( xdl2v.lt_end_date_active, gr_param.lt2_ship_date_from )
          -- 2008/09/10 統合#45の再修正(配送L/Tに関する条件をLT2に入れ忘れ) Add Start -----------------
          ---------------------------------------------------------------------------------------------
          -- 配送L/Tアドオン（配送先で登録されていないこと）
          ---------------------------------------------------------------------------------------------
          AND NOT EXISTS (  SELECT  'X'
                            FROM    xxcmn_delivery_lt2_v  e_xdl2v       -- 配送L/Tアドオン
                            WHERE   e_xdl2v.code_class1                 = gv_whse_code
                            AND     e_xdl2v.entering_despatching_code1  = xoha.deliver_from
                            AND     e_xdl2v.code_class2                 = gv_deliver_to
                            AND     e_xdl2v.entering_despatching_code2  = xoha.deliver_to
                            AND     gr_param.lt2_ship_date_from BETWEEN e_xdl2v.lt_start_date_active 
                                            AND NVL( e_xdl2v.lt_end_date_active, gr_param.lt2_ship_date_from )
                         )
          -- 2008/09/10 統合#45の再修正(配送L/Tに関する条件をLT2に入れ忘れ) Add End -------------------
        ) lt1_date,
        xxwsh_order_headers_all xoha_lock
      WHERE lt1_date.order_header_id = xoha_lock.order_header_id
      FOR UPDATE OF xoha_lock.order_header_id NOWAIT
      ;
-- ##### 20080904 1.6 統合#45 対応 END   #####
--
    ----------------------------------------------------------------------------------------------
    -- ＜抽出条件(C)＞出庫形態が出荷依頼以外の場合
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_order_c
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
        END                             AS data_class   -- データ区分「出荷依頼：1」「出荷取消：8」
           , xil2v.segment1             AS whse_code       -- 保管倉庫コード
           , xoha.order_header_id       AS order_header_id  -- 受注ヘッダアドオンID
           , xoha.notif_status          AS notif_status    -- 通知ステータス
           , xoha.prod_class            AS prod_class    -- 商品区分
           , NULL                       AS item_class      -- 品目区分
           , xoha.delivery_no           AS delivery_no      -- 配送NO
           , xoha.request_no            AS request_no      -- 依頼NO
           , xoha.freight_charge_class  AS freight_charge_class      -- 運賃区分
           , xil2v.d1_whse_code         AS d1_whse_code      -- D+1倉庫フラグ
           , gr_param.ship_date_from    AS base_date      -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
           , xoha.deliver_to_id         AS deliver_to_id         -- 出荷先ID
           , xoha.result_deliver_to_id  AS result_deliver_to_id  -- 出荷先_実績ID
           , xoha.schedule_arrival_date AS arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
      FROM xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
           xxwsh_oe_transaction_types2_v      xott2v,       -- 受注タイプ
           xxcmn_item_locations2_v            xil2v    -- OPM保管場所情報
      WHERE
      -- プロファイル．商品区分
           xoha.prod_class               = gv_item_div_security
      -- パラメータ条件．部署
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- 適用日
      AND   gr_param.ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.ship_date_from )
      -- パラメータ条件．出庫元
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- パラメータ条件．ブロック１・２・３
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- 受注タイプ
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- 出荷依頼
      AND   xott2v.transaction_type_id  = gr_param.transaction_type_id -- パラメータ条件．出庫形態
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- 出荷：締済み
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- 未通知
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- 再通知要
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- 出荷：取消
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- 再通知要
          )
      -- パラメータ条件．出庫日FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.ship_date_from
                                    AND     NVL( gr_param.ship_date_to, xoha.schedule_ship_date )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
    ----------------------------------------------------------------------------------------------
    -- ＜抽出条件(D)＞支給指示の場合
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_prov_d
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_p_cmpb THEN gc_data_class_prov
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_prov_cncl
        END                               AS data_class -- データ区分「支給指示：2」「支給取消：9」
           , xil2v.segment1               AS whse_code       -- 保管倉庫コード
           , xoha.order_header_id         AS order_header_id  -- 受注ヘッダアドオンID
           , xoha.notif_status            AS notif_status    -- 通知ステータス
           , xoha.prod_class              AS prod_class    -- 商品区分
           , NULL                         AS item_class      -- 品目区分
           , xoha.delivery_no             AS delivery_no      -- 配送NO
           , xoha.request_no              AS request_no      -- 依頼NO
           , xoha.freight_charge_class    AS freight_charge_class      -- 運賃区分
           , xil2v.d1_whse_code           AS d1_whse_code      -- D+1倉庫フラグ
           , gr_param.prov_ship_date_from AS base_date      -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
           , xoha.deliver_to_id           AS deliver_to_id         -- 出荷先ID
           , xoha.result_deliver_to_id    AS result_deliver_to_id  -- 出荷先_実績ID
           , xoha.schedule_arrival_date   AS arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
      FROM xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
           xxwsh_oe_transaction_types2_v      xott2v,       -- 受注タイプ
           xxcmn_item_locations2_v             xil2v    -- OPM保管場所情報
      WHERE
      -- プロファイル．商品区分
           xoha.prod_class               = gv_item_div_security
      -- パラメータ条件．部署
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- 適用日
      AND   gr_param.prov_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.prov_ship_date_from )
      -- パラメータ条件．出庫元
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- パラメータ条件．ブロック１・２・３
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- 受注タイプ
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_prov     -- 支給指示
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_p_cmpb    -- 支給：受領済
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- 未通知
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- 再通知要
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- 支給：取消
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- 再通知要
          )
      -- パラメータ条件．支給/出庫日FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.prov_ship_date_from
                                    AND NVL( gr_param.prov_ship_date_to, xoha.schedule_ship_date )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
    ----------------------------------------------------------------------------------------------
    -- 移動情報の場合
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_move
    IS
      SELECT gc_data_class_move           AS data_class       -- データ区分：3
           , xil2v.segment1               AS whse_code       -- 保管倉庫コード
           , xmrih.mov_hdr_id             AS order_header_id  -- 受注ヘッダアドオンID
           , xmrih.notif_status           AS notif_status    -- 通知ステータス
           , xmrih.item_class             AS prod_class    -- 商品区分
           , xmrih.product_flg            AS item_class      -- 品目区分(製品識別区分)
           , xmrih.delivery_no            AS delivery_no      -- 配送NO
           , xmrih.mov_num                AS request_no      -- 依頼NO
           , xmrih.freight_charge_class   AS freight_charge_class      -- 運賃区分
           , xil2v.d1_whse_code           AS d1_whse_code      -- D+1倉庫フラグ
           , gr_param.move_ship_date_from AS base_date      -- 基準日
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
           , NULL                         AS deliver_to_id         -- 出荷先ID
           , NULL                         AS result_deliver_to_id  -- 出荷先_実績ID
           , NULL                         AS arrival_date          -- 着荷日
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
      FROM xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダアドオン
          ,xxcmn_item_locations2_v        xil2v     -- ＯＰＭ保管場所マスタ
      WHERE
      -- プロファイル．商品区分
           xmrih.item_class               = gv_item_div_security
      -- パラメータ条件．指示部署
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ---------------------------------------------------------------------------------------------
      AND  xmrih.shipped_locat_code          = xil2v.segment1
      -- 適用日
      AND   gr_param.move_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.move_ship_date_from )
      -- パラメータ条件．出庫元
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- パラメータ条件．ブロック１・２・３
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- 移動依頼/指示ヘッダアドオン
      ---------------------------------------------------------------------------------------------
      AND (( xmrih.status              IN( gv_mov_status_cmp       -- 依頼済
                                         ,gv_mov_status_adj )     -- 調整中
      AND   xmrih.mov_type              = gc_mov_type_y           -- 積送あり
          AND (     xmrih.notif_status           = gc_notif_status_unnotif    -- 未通知
              OR    xmrih.notif_status           = gc_notif_status_renotif ))   -- 再通知要
      OR  (  xmrih.status             = gc_req_status_p_ccl      -- 取消
          AND   xmrih.mov_type              = gc_mov_type_y           -- 積送あり
          AND   xmrih.notif_status           = gc_notif_status_renotif )   -- 再通知要
      )
      -- パラメータ条件．移動/出庫日FromTo
      AND   xmrih.schedule_ship_date BETWEEN gr_param.move_ship_date_from
                                    AND NVL( gr_param.move_ship_date_to, xmrih.schedule_ship_date )
      FOR UPDATE OF xmrih.mov_hdr_id NOWAIT
     ;
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
    -- ***************************************
    --------------------------------------------------
    -- 入力パラメータ[処理種別]が出荷依頼または出荷依頼/移動指示の場合
    --------------------------------------------------
    IF (gr_param.shipping_biz_type IN ( gv_proc_fix_block_ship,gv_proc_fix_block_ship_move )) THEN
      --------------------------------------------------
      -- 入力パラメータ[出庫形態]が出荷依頼の場合
      --------------------------------------------------
      IF (gr_param.transaction_type_id = gv_transaction_type_id_ship) THEN
        --------------------------------------------------
        -- 入力パラメータ[生産物流LT1]が指定ありの場合
        --------------------------------------------------
        IF (gr_param.lead_time_day_01 IS NOT NULL) THEN
          --------------------------------------------------
          --＜抽出条件(A)＞
          --------------------------------------------------
-- ##### 20080904 1.6 統合#45 対応 START #####
--          OPEN cur_sel_order_a(gv_deliver_to);
          -- カーソルオープン
          OPEN cur_sel_order_a;
-- ##### 20080904 1.6 統合#45 対応 END   #####
          -- バルクフェッチ
          FETCH cur_sel_order_a BULK COLLECT INTO lr_temp_tab_tab;
          -- カーソルクローズ
          CLOSE cur_sel_order_a;
-- ##### 20080904 1.6 統合#45 対応 START #####
/********** 不要の為コメントアウト
          -- コード区分：配送先で取得件数が0の場合、コード区分：拠点で検索
          IF lr_temp_tab_tab.COUNT = 0 THEN
            -- カーソルオープン(コード区分：拠点)
            OPEN cur_sel_order_a(gv_sales_code);
            -- バルクフェッチ
            FETCH cur_sel_order_a BULK COLLECT INTO lr_temp_tab_tab;
            -- カーソルクローズ
            CLOSE cur_sel_order_a;
          END IF;
**********/
-- ##### 20080904 1.6 統合#45 対応 END   #####
          -- 処理対象データありの場合
          IF lr_temp_tab_tab.COUNT > 0 THEN
            gv_data_found_flg := gc_onoff_div_on;   -- 処理対象データあり
            --------------------------------------------------
            -- 中間テーブル登録
            --------------------------------------------------
            ins_temp_data
              (
                ir_temp_tab_tab   => lr_temp_tab_tab
               ,ov_errbuf         => lv_errbuf
               ,ov_retcode        => lv_retcode
               ,ov_errmsg         => lv_errmsg
              ) ;
          END IF;
            IF ( lv_retcode = gv_status_error ) THEN
              -- MOD START 2008/06/23 UEHARA
--              RAISE global_process_expt ;
              RAISE global_api_others_expt ;
              -- MOD END 2008/06/23
            END IF ;
        END IF;
        --------------------------------------------------
        -- 入力パラメータ[生産物流LT2]が指定ありの場合
        --------------------------------------------------
        IF (gr_param.lead_time_day_02 IS NOT NULL) THEN
          --------------------------------------------------
          --＜抽出条件(B)＞
          --------------------------------------------------
-- ##### 20080904 1.6 統合#45 対応 START #####
--          OPEN cur_sel_order_b(gv_deliver_to);
          -- カーソルオープン
          OPEN cur_sel_order_b;
-- ##### 20080904 1.6 統合#45 対応 END   #####
          -- バルクフェッチ
          FETCH cur_sel_order_b BULK COLLECT INTO lr_temp_tab_tab;
          -- カーソルクローズ
          CLOSE cur_sel_order_b;
-- ##### 20080904 1.6 統合#45 対応 START #####
/********** 不要の為コメントアウト
          -- コード区分：配送先で取得件数が0の場合、コード区分：拠点で検索
          IF lr_temp_tab_tab.COUNT = 0 THEN
            -- カーソルオープン(コード区分：拠点)
            OPEN cur_sel_order_b(gv_sales_code);
            -- バルクフェッチ
            FETCH cur_sel_order_b BULK COLLECT INTO lr_temp_tab_tab;
            -- カーソルクローズ
            CLOSE cur_sel_order_b;
          END IF;
**********/
-- ##### 20080904 1.6 統合#45 対応 END   #####
          -- 処理対象データありの場合
          IF lr_temp_tab_tab.COUNT > 0 THEN
            gv_data_found_flg := gc_onoff_div_on;   -- 処理対象データあり
            --------------------------------------------------
            -- 中間テーブル登録
            --------------------------------------------------
            ins_temp_data
              (
                ir_temp_tab_tab   => lr_temp_tab_tab
               ,ov_errbuf         => lv_errbuf
               ,ov_retcode        => lv_retcode
               ,ov_errmsg         => lv_errmsg
              ) ;
            IF ( lv_retcode = gv_status_error ) THEN
              -- MOD START 2008/06/23 UEHARA
--              RAISE global_process_expt ;
              RAISE global_api_others_expt ;
              -- MOD END 2008/06/23
            END IF ;
          END IF;
        END IF;
      --------------------------------------------------
      -- 入力パラメータ[出庫形態]が出荷依頼以外の場合
      --------------------------------------------------
      ELSIF (gr_param.transaction_type_id <> gv_transaction_type_id_ship) THEN
        --------------------------------------------------
        --＜抽出条件(C)＞
        --------------------------------------------------
        -- カーソルオープン
        OPEN cur_sel_order_c;
        -- バルクフェッチ
        FETCH cur_sel_order_c BULK COLLECT INTO lr_temp_tab_tab;
        -- カーソルクローズ
        CLOSE cur_sel_order_c;
          -- 処理対象データありの場合
          IF lr_temp_tab_tab.COUNT > 0 THEN
            gv_data_found_flg := gc_onoff_div_on;   -- 処理対象データあり
          --------------------------------------------------
          -- 中間テーブル登録
          --------------------------------------------------
          ins_temp_data
            (
              ir_temp_tab_tab   => lr_temp_tab_tab
             ,ov_errbuf         => lv_errbuf
             ,ov_retcode        => lv_retcode
             ,ov_errmsg         => lv_errmsg
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            -- MOD START 2008/06/23 UEHARA
--            RAISE global_process_expt ;
            RAISE global_api_others_expt ;
            -- MOD END 2008/06/23
          END IF ;
        END IF;
      END IF;
    --------------------------------------------------
    -- 入力パラメータ[処理種別]が支給指示または支給指示/移動指示の場合
    --------------------------------------------------
    ELSIF (gr_param.shipping_biz_type IN (gv_proc_fix_block_prov,gv_proc_fix_block_prov_move)) THEN
      --------------------------------------------------
      --＜抽出条件(D)＞
      --------------------------------------------------
      -- カーソルオープン
      OPEN cur_sel_prov_d;
      -- バルクフェッチ
      FETCH cur_sel_prov_d BULK COLLECT INTO lr_temp_tab_tab;
      -- カーソルクローズ
      CLOSE cur_sel_prov_d;
      -- 処理対象データありの場合
      IF lr_temp_tab_tab.COUNT > 0 THEN
        gv_data_found_flg := gc_onoff_div_on;   -- 処理対象データあり
        --------------------------------------------------
        -- 中間テーブル登録
        --------------------------------------------------
        ins_temp_data
          (
            ir_temp_tab_tab   => lr_temp_tab_tab
           ,ov_errbuf         => lv_errbuf
           ,ov_retcode        => lv_retcode
           ,ov_errmsg         => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          -- MOD START 2008/06/23 UEHARA
--          RAISE global_process_expt ;
          RAISE global_api_others_expt ;
          -- MOD END 2008/06/23
        END IF;
      END IF;
    END IF;
    --------------------------------------------------
    -- 入力パラメータ[処理種別]が移動指示または出荷依頼/移動指示または支給指示/移動指示の場合
    --------------------------------------------------
    IF (gr_param.shipping_biz_type IN ( gv_proc_fix_block_move,gv_proc_fix_block_ship_move
                                                              ,gv_proc_fix_block_prov_move )) THEN
      --------------------------------------------------
      --移動情報 ヘッダ抽出処理
      --------------------------------------------------
      -- カーソルオープン
      OPEN cur_sel_move;
      -- バルクフェッチ
      FETCH cur_sel_move BULK COLLECT INTO lr_temp_tab_tab;
      -- カーソルクローズ
      CLOSE cur_sel_move;
      -- 処理対象データありの場合
      IF lr_temp_tab_tab.COUNT > 0 THEN
        gv_data_found_flg := gc_onoff_div_on;   -- 処理対象データあり
        --------------------------------------------------
        -- 中間テーブル登録
        --------------------------------------------------
        ins_temp_data
          (
            ir_temp_tab_tab   => lr_temp_tab_tab
           ,ov_errbuf         => lv_errbuf
           ,ov_retcode        => lv_retcode
           ,ov_errmsg         => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          -- MOD START 2008/06/23 UEHARA
--          RAISE global_process_expt ;
          RAISE global_api_others_expt ;
          -- MOD END 2008/06/23
        END IF;
      END IF;
    END IF;
    -- 処理対象データなしの場合
    IF (gv_data_found_flg = gc_onoff_div_off) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                             ,gv_no_data_found_err)   -- 処理対象データなしエラー
                             ,1
                             ,5000);
      -- エラーリターン＆処理中止
      RAISE global_no_data_found_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理対象データなし例外ハンドラ ***
    WHEN global_no_data_found_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
-- ##### 20080616 1.1 結合障害 #9対応 START #####
--      ov_retcode := gv_status_error;
      ov_retcode := gv_status_warn;
-- ##### 20080616 1.1 結合障害 #9対応 END   #####
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_error_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                             ,gv_lock_err)   -- ロックエラー
                             ,1
                             ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
--      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_confirm_block_header;
--
  /**********************************************************************************
   * Procedure Name   : get_confirm_block_line
   * Description      : D-4  出荷・支給・移動情報明細抽出処理
   ***********************************************************************************/
  PROCEDURE get_confirm_block_line(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_confirm_block_line'; -- プログラム名
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
    lr_temp_tab           rec_temp_tab_data ;   -- 中間テーブル登録用レコード変数
    lr_temp_tab_tab       rec_temp_tab_data_tab ;   -- 中間テーブル登録用レコード変数
--
    -- *** ローカル・カーソル ***
    --------------------------------------------------
    -- 出荷・支給情報 明細抽出カーソル
    --------------------------------------------------
    CURSOR cur_sel_order_line(ln_cnt NUMBER)
    IS
      SELECT
             xola.order_header_id       AS order_header_id      -- 受注ヘッダID
           , xola.order_line_id         AS order_line_id        -- 受注明細ID
--           , xola.quantity              AS quantity             -- 数量
--           , xola.reserved_quantity     AS reserved_quantity    -- 引当数
           , NVL(xola.quantity,0)       AS quantity             -- 数量
           , NVL(xola.reserved_quantity,0) AS reserved_quantity    -- 引当数
           , ximv.lot_ctl               AS lot_ctl    -- ロット管理区分
           , xicv.item_class_code       AS item_class_code      -- 品目区分
-- 2008/12/01 H.Itou Add Start 本番障害#148
           , xola.shipping_item_code    AS item_code            -- 品目NO
-- 2008/12/01 H.Itou Add End
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
           , xola.shipping_inventory_item_id AS shipping_inventory_item_id -- 出荷品目ID
           , xola.line_id                    AS line_id                    -- 明細ID
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
      FROM xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,xxcmn_item_mst2_v          ximv      -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories5_v   xicv      -- ＯＰＭ品目カテゴリ割当情報VIEW5
      WHERE
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ品目
      ---------------------------------------------------------------------------------------------
      -- パラメータ条件．品目区分
            ximv.item_id            = xicv.item_id
      AND   trunc(gr_chk_header_data_tab(ln_cnt).base_date) BETWEEN ximv.start_date_active
                AND NVL( ximv.end_date_active, trunc(gr_chk_header_data_tab(ln_cnt).base_date) )
      AND   xola.shipping_item_code = ximv.item_no
      ---------------------------------------------------------------------------------------------
      -- 受注明細アドオン
      ---------------------------------------------------------------------------------------------
      AND   NVL(xola.delete_flag,gc_yn_div_n) <> gc_yn_div_y          -- 未削除
      AND   xola.order_header_id                 = gr_chk_header_data_tab(ln_cnt).header_id
      FOR UPDATE OF xola.order_line_id NOWAIT
     ;
    --------------------------------------------------
    -- 移動情報 明細抽出カーソル
    --------------------------------------------------
    CURSOR cur_sel_move_line(ln_cnt NUMBER)
    IS
      SELECT
             xmril.mov_hdr_id                          AS order_header_id      -- 移動ヘッダID
           , xmril.mov_line_id                         AS order_line_id        -- 移動明細ID
--           , xmril.instruct_qty                        AS quantity             -- 指示数量
--           , xmril.reserved_quantity                   AS reserved_quantity    -- 引当数
           , NVL(xmril.instruct_qty,0)                 AS quantity             -- 指示数量
           , NVL(xmril.reserved_quantity,0)            AS reserved_quantity    -- 引当数
           , ximv.lot_ctl                              AS lot_ctl              -- ロット管理区分
           , gr_chk_header_data_tab(ln_cnt).item_class AS item_class_code      -- 品目区分
-- 2008/12/01 H.Itou Add Start 本番障害#148
           , xmril.item_code                           AS item_code            -- 品目NO
-- 2008/12/01 H.Itou Add End
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
           , NULL                                      AS shipping_inventory_item_id -- 出荷品目ID
           , NULL                                      AS line_id                    -- 明細ID
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
      FROM xxinv_mov_req_instr_lines    xmril     -- 移動依頼/指示明細アドオン
          ,xxcmn_item_mst2_v            ximv      -- ＯＰＭ品目情報VIEW2
      WHERE
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ品目
      ---------------------------------------------------------------------------------------------
      -- パラメータ条件．品目区分
            xmril.item_id            = ximv.item_id
      AND   trunc(gr_chk_header_data_tab(ln_cnt).base_date) BETWEEN ximv.start_date_active
                    AND NVL( ximv.end_date_active, trunc(gr_chk_header_data_tab(ln_cnt).base_date))
      ---------------------------------------------------------------------------------------------
      -- 移動依頼/指示明細アドオン
      ---------------------------------------------------------------------------------------------
      AND   NVL(xmril.delete_flg,gc_yn_div_n) <> gc_yn_div_y          -- 未削除
      AND   xmril.mov_hdr_id                 = gr_chk_header_data_tab(ln_cnt).header_id
      FOR UPDATE OF xmril.mov_line_id NOWAIT
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
    -- ***************************************
    --------------------------------------------------
    -- データ区分が出荷依頼・支給指示の場合
    --------------------------------------------------
    IF (gr_chk_header_data_tab(ln_cnt).data_class IN
                               ( gc_data_class_order,gc_data_class_prov )) THEN
      -- カーソルオープン
      OPEN cur_sel_order_line(ln_cnt);
      -- バルクフェッチ
      FETCH cur_sel_order_line BULK COLLECT INTO gr_chk_line_data_tab;
      -- カーソルクローズ
      CLOSE cur_sel_order_line;
    --------------------------------------------------
    -- データ区分が移動指示の場合
    --------------------------------------------------
    ELSIF (gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_move) THEN
      -- カーソルオープン
      OPEN cur_sel_move_line(ln_cnt);
      -- バルクフェッチ
      FETCH cur_sel_move_line BULK COLLECT INTO gr_chk_line_data_tab;
      -- カーソルクローズ
      CLOSE cur_sel_move_line;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( cur_sel_order_line%ISOPEN ) THEN
        CLOSE cur_sel_order_line ;
      END IF ;
      IF ( cur_sel_move_line%ISOPEN ) THEN
        CLOSE cur_sel_move_line ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( cur_sel_order_line%ISOPEN ) THEN
        CLOSE cur_sel_order_line ;
      END IF ;
      IF ( cur_sel_move_line%ISOPEN ) THEN
        CLOSE cur_sel_move_line ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cur_sel_order_line%ISOPEN ) THEN
        CLOSE cur_sel_order_line ;
      END IF ;
      IF ( cur_sel_move_line%ISOPEN ) THEN
        CLOSE cur_sel_move_line ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_confirm_block_line;
--
  /**********************************************************************************
   * Procedure Name   : chk_reserved
   * Description      : D-5  引当処理済チェック処理
   ***********************************************************************************/
  PROCEDURE chk_reserved(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_reserved'; -- プログラム名
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
    ln_lot_cnt NUMBER;
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
    -- ***************************************
-- 2008/12/01 H.Itou Add Start 本番#148
-- 2008/12/02 D.Sugahara Mod Start 本番#148
    -- 引当数に値がある場合かつ0でない場合
--    IF (gr_chk_line_data_tab(gn_cnt_line).reserved_quantity IS NOT NULL) THEN
    IF (gr_chk_line_data_tab(gn_cnt_line).reserved_quantity IS NOT NULL) AND 
       (gr_chk_line_data_tab(gn_cnt_line).reserved_quantity != 0)    THEN
-- 2008/12/02 D.Sugahara Mod End 本番#148
      -- 移動ロット詳細(指示)があるかチェック
      SELECT COUNT(1) cnt  -- 移動ロット詳細(指示)件数
      INTO   ln_lot_cnt
      FROM   xxinv_mov_lot_details  xmld -- 移動ロット詳細
      WHERE  xmld.mov_line_id      = gr_chk_line_data_tab(gn_cnt_line).order_line_id -- 明細ID
      AND    xmld.record_type_code = gv_record_type_code_plan                        -- 指示
      AND    ROWNUM                = 1
      ;
--
      -- 移動ロット詳細(指示)がない場合
      IF (ln_lot_cnt = 0) THEN
        -- エラーメッセージ取得
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       gv_cons_msg_kbn_wsh  -- アプリケーション名:XXWSH
                      ,gv_check_line_err2   -- メッセージコード:引当処理済チェックエラー
                      ,gv_cnst_tkn_check_kbn,   gv_tkn_reserved02_err                        -- トークンCHECK_KBN:引当エラー２
                      ,gv_cnst_tkn_delivery_no, gr_chk_header_data_tab(ln_cnt).delivery_no   -- トークンDELIVERY_NO:配送No
                      ,gv_cnst_tkn_request_no,  gr_chk_header_data_tab(ln_cnt).request_no    -- トークンREQUEST_NO:依頼No
                      ,gv_cnst_tkn_item_no,     gr_chk_line_data_tab(gn_cnt_line).item_code  -- トークンITEM_NO:品目No
                      );
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
        gv_err_flg_resv2 := gc_onoff_div_on; -- 引当エラーフラグ2をONにする。
        RAISE skip_expt;
      END IF;
    END IF;
--
-- 2008/12/01 H.Itou Add End
    -- データ区分が'1'出荷依頼
    IF (((gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order)
      -- 品目区分が'5'製品
      AND (gr_chk_line_data_tab(gn_cnt_line).item_class_code = gv_cons_item_product)
      -- 商品区分が'2'ドリンク
      AND ((gr_chk_header_data_tab(ln_cnt).prod_class = gv_prod_class_drink)
      -- もしくは、商品区分が'1'リーフでD+1倉庫フラグが'1'
      OR  (gr_chk_header_data_tab(ln_cnt).prod_class = gv_prod_class_leaf)
-- mod start 1.5
--        AND (gr_chk_header_data_tab(ln_cnt).d1_whse_code = gc_yn_div_y)))
        AND (gr_chk_header_data_tab(ln_cnt).d1_whse_code = gv_d1_whse_flg_1)))
-- mod end 4.5
    -- データ区分が'2'支給指示
    OR (gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_prov)
    -- データ区分が'3'移動指示
    OR ((gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_move)
      -- 品目区分(製品識別区分)が'1'製品
      AND (gr_chk_line_data_tab(gn_cnt_line).item_class_code = gv_cons_product_class)
      -- 商品区分が'2'ドリンク
      AND (gr_chk_header_data_tab(ln_cnt).prod_class = gv_prod_class_drink))
    ) THEN
      -- 数量と引当数量が異なる場合はエラーフラグを加算する。
      IF (gr_chk_line_data_tab(gn_cnt_line).quantity
          <> gr_chk_line_data_tab(gn_cnt_line).reserved_quantity) THEN
        gv_err_flg_resv := gc_onoff_div_on; -- 引当エラーフラグをONにする。
        gv_err_flg_whse := gc_onoff_div_on; -- 倉庫エラーフラグをONにする。
      END IF;
    END IF;
--
  EXCEPTION
--
-- 2008/12/01 H.Itou Add Start 本番障害#148
    WHEN skip_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;  -- 終了ステータス：警告
-- 2008/12/01 H.Itou Add End
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
  END chk_reserved;
--
  /**********************************************************************************
   * Procedure Name   : chk_mixed_prod
   * Description      : D-6  出荷明細 製品混在チェック処理
   ***********************************************************************************/
  PROCEDURE chk_mixed_prod(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_mixed_prod'; -- プログラム名
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
    -- ***************************************
    IF (gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order) THEN
      --------------------------------------------------
      -- 品目区分が'5'製品の場合は製品件数を加算
      --------------------------------------------------
      IF (gr_chk_line_data_tab(gn_cnt_line).item_class_code = gv_cons_item_product) THEN
        gn_cnt_prod    := gn_cnt_prod +1;
      --------------------------------------------------
      -- 品目区分が'5'製品以外の場合は製品以外件数を加算
      --------------------------------------------------
      ELSE
        gn_cnt_no_prod := gn_cnt_no_prod +1;
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
  END chk_mixed_prod;
--
  /**********************************************************************************
   * Procedure Name   : chk_carrier
   * Description      : D-7  配車済チェック処理
   ***********************************************************************************/
  PROCEDURE chk_carrier(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_carrier'; -- プログラム名
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
    -- ***************************************
    ---------------------------------------------------------
    -- データ区分が'1'出荷依頼'2'支給指示'3'移動指示の場合
    ---------------------------------------------------------
    IF ((gr_chk_header_data_tab(ln_cnt).data_class IN (gc_data_class_order,gc_data_class_prov
                                                                          ,gc_data_class_move))
    ---------------------------------------------------------
    -- 運賃区分=対象の場合
    ---------------------------------------------------------
    AND (gr_chk_header_data_tab(ln_cnt).freight_charge_class = gv_freight_charge_class_on)
    ---------------------------------------------------------
    -- 配送NOがNULLまたは'0'の場合
    ---------------------------------------------------------
    AND (NVL(gr_chk_header_data_tab(ln_cnt).delivery_no,'0') = '0')) THEN
      -- 配車エラーフラグをONにする。
      gv_err_flg_carr := gc_onoff_div_on;
      -- 倉庫エラーフラグをONにする。
      gv_err_flg_whse := gc_onoff_div_on;
    END IF;
    ---------------------------------------------------------
    -- データ区分が'1'出荷依頼'の場合
    ---------------------------------------------------------
    IF ((gr_chk_header_data_tab(ln_cnt).data_class in (gc_data_class_order))
    ---------------------------------------------------------
    -- 製品件数>0かつ製品以外>0の場合
    ---------------------------------------------------------
    AND (gn_cnt_prod > 0) AND (gn_cnt_no_prod > 0)) THEN
      -- 配車出荷依頼製品混在ワーニングフラグをONにする。
      gv_war_flg_carr_mixed := gc_onoff_div_on;
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
  END chk_carrier;
--
  /**********************************************************************************
   * Procedure Name   : set_checked_data
   * Description      : D-8  チェック済データ PL/SQL表格納処理
   ***********************************************************************************/
  PROCEDURE set_checked_data(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_checked_data'; -- プログラム名
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
    -- ***************************************
    ---------------------------------------------------------
    -- チェック済データ格納用レコード変数に格納
    ---------------------------------------------------------
-- 2008/12/01 H.Itou Add Start 本番障害#148
    gn_cnt_chk_data := gn_cnt_chk_data + 1;
-- 2008/12/01 H.Itou Add End
-- 2008/12/01 H.Itou Mod Start 本番障害#148
--    gr_checked_data_tab(ln_cnt).data_class   := gr_chk_header_data_tab(ln_cnt).data_class;
--                                                                                  -- データ区分
--    gr_checked_data_tab(ln_cnt).delivery_no  := gr_chk_header_data_tab(ln_cnt).delivery_no;
--                                                                                  -- 配送NO
--    gr_checked_data_tab(ln_cnt).request_no   := gr_chk_header_data_tab(ln_cnt).request_no;
--                                                                                  -- 依頼NO
--    gr_checked_data_tab(ln_cnt).notif_status := gr_chk_header_data_tab(ln_cnt).notif_status;
--                                                                                  -- 通知ステータス
    gr_checked_data_tab(gn_cnt_chk_data).data_class   := gr_chk_header_data_tab(ln_cnt).data_class;
                                                                                  -- データ区分
    gr_checked_data_tab(gn_cnt_chk_data).delivery_no  := gr_chk_header_data_tab(ln_cnt).delivery_no;
                                                                                  -- 配送NO
    gr_checked_data_tab(gn_cnt_chk_data).request_no   := gr_chk_header_data_tab(ln_cnt).request_no;
                                                                                  -- 依頼NO
    gr_checked_data_tab(gn_cnt_chk_data).notif_status := gr_chk_header_data_tab(ln_cnt).notif_status;
                                                                                  -- 通知ステータス
-- 2008/12/01 H.Itou Mod End 本番障害#148
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
  END set_checked_data;
--
  /**********************************************************************************
   * Procedure Name   : set_upd_data
   * Description      : D-10  通知ステータス更新用PL／SQL表 格納処理
   ***********************************************************************************/
  PROCEDURE set_upd_data(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upd_data'; -- プログラム名
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
    ln_cnt   NUMBER;
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
    -- ***************************************
    ln_cnt := 1;
    <<set_upd_data_loop>>
    FOR ln_cnt IN gr_checked_data_tab.FIRST .. gr_checked_data_tab.LAST LOOP
      -- 更新用データ件数を加算
      gn_cnt_upd := gn_cnt_upd + 1 ;
      ---------------------------------------------------------
      -- 更新データ格納用レコードに格納
      ---------------------------------------------------------
      gr_upd_data_tab(gn_cnt_upd).data_class   := gr_checked_data_tab(ln_cnt).data_class;
                                                                                  -- データ区分
      gr_upd_data_tab(gn_cnt_upd).delivery_no  := gr_checked_data_tab(ln_cnt).delivery_no;
                                                                                  -- 配送NO
      gr_upd_data_tab(gn_cnt_upd).request_no   := gr_checked_data_tab(ln_cnt).request_no;
                                                                                  -- 依頼NO
      gr_upd_data_tab(gn_cnt_upd).notif_status := gr_checked_data_tab(ln_cnt).notif_status;
                                                                                  -- 通知ステータス
    END LOOP set_upd_data_loop;
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
  END set_upd_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_notif_status
   * Description      : D-12  通知ステータス 一括更新処理
   ***********************************************************************************/
  PROCEDURE upd_notif_status(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_notif_status'; -- プログラム名
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
    ln_cnt   NUMBER;
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
    -- ***************************************
    ln_cnt := 1;
    <<upd_notif_status_loop>>
    FOR ln_cnt IN gr_upd_data_tab.FIRST .. gr_upd_data_tab.LAST LOOP
      ---------------------------------------------------------
      -- データ区分が'1'出荷依頼'2'支給指示'8''9'取消データの場合
      ---------------------------------------------------------
      IF (gr_upd_data_tab(ln_cnt).data_class
        IN (gc_data_class_order,gc_data_class_prov,
            gc_data_class_order_cncl,gc_data_class_prov_cncl)) THEN
        ---------------------------------------------------------
        -- 受注ヘッダアドオン更新
        ---------------------------------------------------------
        UPDATE xxwsh_order_headers_all
        SET    notif_status            = gc_notif_status_notifed      -- 通知ステータス：確定通知済
              ,prev_notif_status       = gr_upd_data_tab(ln_cnt).notif_status -- 前回通知ステータス
              ,notif_date              = gt_system_date          -- 確定通知実施日時
              ,last_updated_by         = gt_user_id     -- 最終更新者
              ,last_update_date        = gt_system_date    -- 最終更新日
              ,last_update_login       = gt_login_id   -- 最終更新ログイン
              ,request_id              = gt_conc_request_id          -- 要求ID
              ,program_application_id  = gt_prog_appl_id
                                                    -- コンカレント・プログラム・アプリケーションID
              ,program_id              = gt_conc_program_id   -- コンカレント・プログラムID
              ,program_update_date     = gt_system_date   -- プログラム更新日
        WHERE  (delivery_no         = gr_upd_data_tab(ln_cnt).delivery_no   -- 配送NO
            OR NVL(gr_upd_data_tab(ln_cnt).delivery_no,0) = 0)
           AND request_no          = gr_upd_data_tab(ln_cnt).request_no     -- 依頼NO
        ;
        -- 更新件数を加算
        IF (gr_upd_data_tab(ln_cnt).data_class
              IN (gc_data_class_order,gc_data_class_order_cncl) ) THEN
          gn_cnt_upd_ship := gn_cnt_upd_ship + 1;  -- 出荷更新件数
        ELSIF (gr_upd_data_tab(ln_cnt).data_class
              IN (gc_data_class_prov,gc_data_class_prov_cncl) ) THEN
          gn_cnt_upd_prov := gn_cnt_upd_prov + 1;  -- 支給更新件数
        END IF;
      ---------------------------------------------------------
      -- データ区分が'3'移動指示の場合
      ---------------------------------------------------------
      ELSIF (gr_upd_data_tab(ln_cnt).data_class IN (gc_data_class_move)) THEN
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
        ---------------------------------------------------------
        -- 割当セットAPI起動
        ---------------------------------------------------------
        xxcop_common_pkg2.upd_assignment(
          iv_mov_num      => gr_upd_data_tab(ln_cnt).request_no  -- 移動番号
         ,iv_process_type => gv_process_type_plus                -- 処理区分(0：加算、1：減算)
         ,ov_errbuf       => lv_errbuf                           --   エラー・メッセージ           --# 固定 #
         ,ov_retcode      => lv_retcode                          --   リターン・コード             --# 固定 #
         ,ov_errmsg       => lv_errmsg                           --   ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合、処理終了
        IF (lv_retcode = gv_status_error) THEN
          -- エラーメッセージ取得
          lv_errmsg := xxcmn_common_pkg.get_msg(
                         gv_cons_msg_kbn_cmn                        -- アプリケーション名:XXCMN
                        ,gv_process_err                             -- メッセージコード:処理失敗
                        ,gv_cnst_tkn_process ,gv_tkn_upd_assignment -- トークン:PROCESS = 割当セットAPI起動
                      );
          lv_errmsg := lv_errmsg || ' (移動番号:' || gr_upd_data_tab(ln_cnt).request_no || ')';
          RAISE global_api_expt;
        END IF;
-- 2009/08/18 H.Itou Add End
        ---------------------------------------------------------
        -- 移動依頼/指示ヘッダアドオン更新
        ---------------------------------------------------------
        UPDATE xxinv_mov_req_instr_headers
        SET    notif_status            = gc_notif_status_notifed      -- 通知ステータス：確定通知済
              ,prev_notif_status       = gr_upd_data_tab(ln_cnt).notif_status -- 前回通知ステータス
              ,notif_date              = gt_system_date          -- 確定通知実施日時
              ,last_updated_by         = gt_user_id     -- 最終更新者
              ,last_update_date        = gt_system_date    -- 最終更新日
              ,last_update_login       = gt_login_id   -- 最終更新ログイン
              ,request_id              = gt_conc_request_id          -- 要求ID
              ,program_application_id  = gt_prog_appl_id
                                                    -- コンカレント・プログラム・アプリケーションID
              ,program_id              = gt_conc_program_id   -- コンカレント・プログラムID
              ,program_update_date     = gt_system_date   -- プログラム更新日
        WHERE  (delivery_no         = gr_upd_data_tab(ln_cnt).delivery_no   -- 配送NO
            OR NVL(gr_upd_data_tab(ln_cnt).delivery_no,0) = 0)
           AND mov_num             = gr_upd_data_tab(ln_cnt).request_no     -- 移動番号
        ;
        -- 更新件数を加算
        gn_cnt_upd_move := gn_cnt_upd_move + 1;  -- 移動更新件数
      END IF;
    END LOOP upd_notif_status_loop;
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
  END upd_notif_status;
--
  /**********************************************************************************
   * Procedure Name   : purge_tbl
   * Description      : D-13  中間テーブルパージ処理
   ***********************************************************************************/
  PROCEDURE purge_tbl
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_tbl'; -- プログラム名
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
      -- 確定ブロック用中間テーブル 対象データ削除
      DELETE FROM   xxwsh.xxwsh_confirm_block_tmp -- 確定ブロック用中間テーブル
      WHERE created_by = gt_user_id                    -- 作成者、最終更新者
        AND request_id = gt_conc_request_id            -- 要求ID
        AND program_application_id = gt_prog_appl_id   -- アプリケーションID
        AND program_id = gt_conc_program_id            -- プログラムID
      ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END purge_tbl;
--
--
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
--
 /**********************************************************************************
  * Procedure Name   : ins_upd_lot_hold_info
  * Description      : D-14 ロット情報保持マスタ反映処理
  ***********************************************************************************/
  PROCEDURE ins_upd_lot_hold_info(
    ln_cnt        IN  NUMBER,              --   データindex(header)
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'ins_upd_lot_hold_info';
                                                                            -- プログラム名
    ct_document_type_10  CONSTANT xxinv_mov_lot_details.document_type_code%TYPE := '10'; 
                                                                            -- 文書タイプ：10(出荷依頼)
    ct_record_type_01    CONSTANT xxinv_mov_lot_details.record_type_code%TYPE := '10'; 
                                                                            -- レコードタイプ：01(指示)
    cv_cancel_kbn_0      CONSTANT VARCHAR2(1) := '0';
                                                                            -- 取消区分：'0'(取消以外)
    cv_cancel_kbn_1      CONSTANT VARCHAR2(1) := '1';
                                                                            -- 取消区分：'1'(取消)
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
    cv_e_s_kbn_2      CONSTANT VARCHAR2(1) := '2';  -- 営業生産区分（生産）
    cn_num_1          CONSTANT NUMBER      :=  1;   -- テーブルデータ取得用：1
    cv_status_a       CONSTANT VARCHAR2(1) := 'A';  -- 顧客ステータス_有効
    cv_class_10       CONSTANT VARCHAR2(2) := '10'; -- 顧客区分_10
--
    -- *** ローカル変数 ***
    lt_deliver_to_id  xxwsh_order_headers_all.result_deliver_to_id%TYPE; -- 出荷先_実績ID
    lt_customer_id    hz_cust_accounts.cust_account_id%TYPE;             -- 顧客ID
    lt_child_item_id  mtl_system_items_b.inventory_item_id%TYPE;         -- 子品目ID
    lt_deliver_lot    xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE;   -- 納品ロット
    lt_delivery_date  xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;      -- 納品日
    lt_item_info_tab  xxcoi_common_pkg.item_info_ttype;                  -- 品目情報（テーブル型）
    lt_order_line_id  xxwsh_order_lines_all.order_line_id%TYPE;          -- 受注明細ID
    lt_customer_class_code hz_cust_accounts.customer_class_code%TYPE;    -- 顧客区分
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
-- 2015/03/19 V1.12 Add START
    -- 引当数がNULLまたは0の場合は処理スキップ
    IF (NVL(gr_chk_line_data_tab(gn_cnt_line).reserved_quantity ,0) = 0)
    THEN
      RAISE skip_expt;
    END IF;
-- 2015/03/19 V1.12 Add END
    -- ローカル変数初期化
    lt_deliver_to_id  := NULL;
    lt_customer_id    := NULL;
    lt_child_item_id  := NULL;
    lt_deliver_lot    := NULL;
    lt_delivery_date  := NULL;
--
    -- 各変数へカーソルの取得値を代入
    lt_deliver_to_id  := gr_chk_header_data_tab(ln_cnt).deliver_to_id;     -- 出荷先_実績ID
    lt_delivery_date  := gr_chk_header_data_tab(ln_cnt).arrival_date;             -- 納品日
    --
    IF gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order THEN
      lt_child_item_id  := gr_chk_line_data_tab(gn_cnt_line).shipping_inventory_item_id;        -- 子品目ID
      lt_order_line_id  := gr_chk_line_data_tab(gn_cnt_line).order_line_id;
    ELSIF gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order_cncl THEN
      lt_child_item_id  := gr_chk_line_data_tab_cncl(gn_cnt_line_cncl).shipping_inventory_item_id;        -- 子品目ID
      lt_order_line_id  := gr_chk_line_data_tab_cncl(gn_cnt_line_cncl).order_line_id;
    END IF;
--
      BEGIN
        SELECT hca.cust_account_id cust_account_id,            -- 顧客ID
               hca.customer_class_code                         -- 顧客区分
        INTO   lt_customer_id,
               lt_customer_class_code
        FROM   hz_cust_accounts hca,                           -- 顧客マスタ
               hz_parties       hp,                            -- パーティマスタ
               hz_party_sites   hps                            -- パーティサイトマスタ
        WHERE  hps.party_site_id       = lt_deliver_to_id      -- パーティサイトID
        AND    hps.party_id            = hp.party_id
        AND    hp.party_id             = hca.party_id
        AND    hca.status              = cv_status_a           -- ステータス
        ;
      --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                  gv_cons_msg_kbn_wsh,      -- 'XXWSH'
                  gv_customer_id_err,       -- 顧客導出（受注アドオン）取得エラー
                  gv_param1_token,          -- トークン'PARAM1'
                  lt_deliver_to_id);        -- 出荷先_実績ID
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
    -- 顧客区分が'10'の場合のみ後続の処理実行
    IF lt_customer_class_code = cv_class_10 THEN
      -- 在庫共通関数「品目コード導出（親／子）」より、親品目の品目情報を取得
      xxcoi_common_pkg.get_parent_child_item_info(
         id_date           => TRUNC(sysdate),         -- 日付
         in_inv_org_id     => gt_inv_org_id,          -- 在庫組織ID
         in_parent_item_id => NULL,                   -- 親品目ID
         in_child_item_id  => lt_child_item_id,       -- 子品目ID（出荷品目ID）
         ot_item_info_tab  => lt_item_info_tab,       -- 品目情報
         ov_errbuf         => lv_errbuf,              -- エラー・メッセージ           --# 固定 #
         ov_retcode        => lv_retcode,             -- リターン・コード             --# 固定 #
         ov_errmsg         => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode <> gv_status_normal ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                gv_cons_msg_kbn_wsh, -- 'XXWSH'
                gv_item_pc_err,      -- 親品目情報取得エラー
                gv_param1_token,     -- トークン'PARAM1'
                gt_inv_org_id,       -- 在庫組織ID
                gv_param2_token,     -- トークン'PARAM2'
                lt_child_item_id);   -- 子品目ID（出荷品目ID）
        lv_errbuf := lv_errmsg;
--
        RAISE global_api_expt;
      END IF;
--
      -- 納品ロット情報（賞味期限）取得
-- 2015/03/19 V1.12 Del START
--      BEGIN
-- 2015/03/19 V1.12 Del END
        SELECT TO_CHAR( MAX( info.taste_term ), 'YYYY/MM/DD' )
        INTO   lt_deliver_lot
        FROM(
          SELECT TO_DATE( ilm.attribute3, 'YYYY/MM/DD' ) taste_term
          FROM   ic_lots_mst             ilm,      -- OPMロットマスタ
                 xxinv_mov_lot_details   xmld      -- 移動ロット詳細
          WHERE  ilm.lot_id                = xmld.lot_id              -- OPMロットID
          AND    ilm.item_id               = xmld.item_id             -- OPM品目ID
          AND    xmld.document_type_code   = ct_document_type_10      -- 文書タイプ
          AND    xmld.record_type_code     = ct_record_type_01        -- レコードタイプ
          AND    xmld.mov_line_id          = lt_order_line_id   -- 明細ID
        ) info
        ;
        IF ( lt_deliver_lot IS NULL ) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                  gv_cons_msg_kbn_wsh, -- 'XXWSH'
                  gv_item_tst_err,     -- 賞味期限取得エラー
-- 2015/03/19 V1.12 Mod START
--                  gv_param_data,       -- トークン'DATA'
--                  gv_item_tst);        -- 賞味期限
                  gv_order_line_id,    -- トークン'ORDER_LINE_ID'
                  lt_order_line_id     -- 受注明細ID
                  );
-- 2015/03/19 V1.12 Mod END
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
-- 2015/03/19 V1.12 Del START
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := xxcmn_common_pkg.get_msg(
--                  gv_cons_msg_kbn_wsh, -- 'XXWSH'
--                  gv_item_tst_err,     -- 賞味期限取得エラー
--                  gv_param_data,       -- トークン'DATA'
--                  gv_item_tst);        -- 賞味期限
--          lv_errbuf := lv_errmsg;
----
--          RAISE global_api_expt;
--      END;
-- 2015/03/19 V1.12 Del END
--
      -- 在庫共通関数「ロット情報保持マスタ反映」より、出荷情報をロット情報保持マスタへ反映
      -- 取消以外の場合
      IF gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order THEN
        xxcoi_common_pkg.ins_upd_lot_hold_info(
           in_customer_id    => lt_customer_id,                     -- 顧客ID
           in_deliver_to_id  => lt_deliver_to_id,                   -- 出荷先ID
           in_parent_item_id => lt_item_info_tab(cn_num_1).item_id, -- 親品目ID
           iv_deliver_lot    => lt_deliver_lot,                     -- 納品ロット（賞味期限）
           id_delivery_date  => lt_delivery_date,                   -- 納品日（着荷日）
           iv_e_s_kbn        => cv_e_s_kbn_2,                       -- 営業生産区分（生産）
           iv_cancel_kbn     => cv_cancel_kbn_0,                    -- 取消区分
           ov_errbuf         => lv_errbuf,              -- エラー・メッセージ           --# 固定 #
           ov_retcode        => lv_retcode,             -- リターン・コード             --# 固定 #
           ov_errmsg         => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
      -- 取消の場合
      ELSIF gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order_cncl THEN
        xxcoi_common_pkg.ins_upd_lot_hold_info(
           in_customer_id    => lt_customer_id,                     -- 顧客ID
           in_deliver_to_id  => lt_deliver_to_id,                   -- 出荷先ID
           in_parent_item_id => lt_item_info_tab(cn_num_1).item_id, -- 親品目ID
           iv_deliver_lot    => lt_deliver_lot,                     -- 納品ロット（賞味期限）
           id_delivery_date  => lt_delivery_date,                   -- 納品日（着荷日）
           iv_e_s_kbn        => cv_e_s_kbn_2,                       -- 営業生産区分（生産）
           iv_cancel_kbn     => cv_cancel_kbn_1,                    -- 取消区分
           ov_errbuf         => lv_errbuf,              -- エラー・メッセージ           --# 固定 #
           ov_retcode        => lv_retcode,             -- リターン・コード             --# 固定 #
           ov_errmsg         => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
      END IF;
--
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                gv_cons_msg_kbn_wsh,      -- 'XXWSH'
                gv_lot_mst_upd_err,       -- ロット情報保持マスタ反映エラー
                gv_param1_token,          -- トークン'PARAM1'
                lt_customer_id,           -- 顧客ID
                gv_param2_token,          -- トークン'PARAM2'
                lt_item_info_tab(cn_num_1).item_id, -- 親品目ID
                gv_param3_token,          -- トークン'PARAM3'
                lt_deliver_lot,           -- 納品ロット（賞味期限）
                gv_param4_token,          -- トークン'PARAM4'
                lt_delivery_date,         -- 納品日（着荷日）
                gv_param5_token,          -- トークン'PARAM5'
                lv_errbuf);               -- エラー・メッセージ
        lv_errbuf := lv_errmsg;
--
        RAISE global_api_expt;
      ELSE
        gn_ins_upd_lot_info_cnt := gn_ins_upd_lot_info_cnt + 1;
      END IF;
--
    END IF;
  EXCEPTION
--
-- 2015/03/19 V1.12 Add START
    WHEN skip_expt THEN
      -- 何も処理せずにスキップ
      NULL;
-- 2015/03/19 V1.12 Add End
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
  END ins_upd_lot_hold_info;
--
  /**********************************************************************************
   * Procedure Name   : get_confirm_block_line_cncl
   * Description      : D-15  出荷取消情報明細抽出処理
   ***********************************************************************************/
  PROCEDURE get_confirm_block_line_cncl(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_confirm_block_line_cncl'; -- プログラム名
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
    lr_temp_tab           rec_temp_tab_data ;   -- 中間テーブル登録用レコード変数
    lr_temp_tab_tab       rec_temp_tab_data_tab ;   -- 中間テーブル登録用レコード変数
--
    -- *** ローカル・カーソル ***
    --------------------------------------------------
    -- 出荷取消明細抽出カーソル
    --------------------------------------------------
    CURSOR cur_sel_order_line_cncl(ln_cnt NUMBER)
    IS
      SELECT
             xola.order_header_id       AS order_header_id      -- 受注ヘッダID
           , xola.order_line_id         AS order_line_id        -- 受注明細ID
           , NVL(xola.quantity,0)       AS quantity             -- 数量
           , NVL(xola.reserved_quantity,0) AS reserved_quantity    -- 引当数
           , ximv.lot_ctl               AS lot_ctl    -- ロット管理区分
           , xicv.item_class_code       AS item_class_code      -- 品目区分
           , xola.shipping_item_code    AS item_code            -- 品目NO
           , xola.shipping_inventory_item_id AS shipping_inventory_item_id -- 出荷品目ID
           , xola.line_id                    AS line_id                    -- 明細ID
      FROM xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,xxcmn_item_mst2_v          ximv      -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories5_v   xicv      -- ＯＰＭ品目カテゴリ割当情報VIEW5
      WHERE
      ---------------------------------------------------------------------------------------------
      -- ＯＰＭ品目
      ---------------------------------------------------------------------------------------------
      -- パラメータ条件．品目区分
            ximv.item_id            = xicv.item_id
      AND   trunc(gr_chk_header_data_tab(ln_cnt).base_date) BETWEEN ximv.start_date_active
                AND NVL( ximv.end_date_active, trunc(gr_chk_header_data_tab(ln_cnt).base_date) )
      AND   xola.shipping_item_code = ximv.item_no
      ---------------------------------------------------------------------------------------------
      -- 受注明細アドオン
      ---------------------------------------------------------------------------------------------
      AND   NVL(xola.delete_flag,gc_yn_div_n) = gc_yn_div_y          -- 未削除
      AND   xola.order_header_id                 = gr_chk_header_data_tab(ln_cnt).header_id
      FOR UPDATE OF xola.order_line_id NOWAIT
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
    -- ***************************************
    -- カーソルオープン
    OPEN cur_sel_order_line_cncl(ln_cnt);
    -- バルクフェッチ
    FETCH cur_sel_order_line_cncl BULK COLLECT INTO gr_chk_line_data_tab_cncl;
    -- カーソルクローズ
    CLOSE cur_sel_order_line_cncl;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( cur_sel_order_line_cncl%ISOPEN ) THEN
        CLOSE cur_sel_order_line_cncl ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( cur_sel_order_line_cncl%ISOPEN ) THEN
        CLOSE cur_sel_order_line_cncl ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cur_sel_order_line_cncl%ISOPEN ) THEN
        CLOSE cur_sel_order_line_cncl ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_confirm_block_line_cncl;
--
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_dept_code              IN VARCHAR2,          -- 部署
    iv_shipping_biz_type      IN VARCHAR2,          -- 処理種別
    iv_transaction_type_id    IN VARCHAR2,          -- 出庫形態
    iv_lead_time_day_01       IN VARCHAR2,          -- 生産物流LT1
    iv_lt1_ship_date_from     IN VARCHAR2,          -- 生産物流LT1/出荷依頼/出庫日From
    iv_lt1_ship_date_to       IN VARCHAR2,          -- 生産物流LT1/出荷依頼/出庫日To
    iv_lead_time_day_02       IN VARCHAR2,          -- 生産物流LT2
    iv_lt2_ship_date_from     IN VARCHAR2,          -- 生産物流LT2/出荷依頼/出庫日From
    iv_lt2_ship_date_to       IN VARCHAR2,          -- 生産物流LT2/出荷依頼/出庫日To
    iv_ship_date_from         IN VARCHAR2,          -- 出庫日From
    iv_ship_date_to           IN VARCHAR2,          -- 出庫日To
    iv_move_ship_date_from    IN VARCHAR2,          -- 移動/出庫日From
    iv_move_ship_date_to      IN VARCHAR2,          -- 移動/出庫日To
    iv_prov_ship_date_from    IN VARCHAR2,          -- 支給/出庫日From
    iv_prov_ship_date_to      IN VARCHAR2,          -- 支給/出庫日To
    iv_block_01               IN VARCHAR2,          -- ブロック１
    iv_block_02               IN VARCHAR2,          -- ブロック２
    iv_block_03               IN VARCHAR2,          -- ブロック３
    iv_shipped_locat_code     IN VARCHAR2,          -- 出庫元
    ov_errbuf                 OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    ln_cnt NUMBER;
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ヘッダ取得用カーソル
    CURSOR cur_get_confirm_block_tmp
    IS
      SELECT *
      FROM  xxwsh.xxwsh_confirm_block_tmp -- 確定ブロック用中間テーブル
      WHERE created_by = gt_user_id                    -- 作成者、最終更新者
        AND request_id = gt_conc_request_id            -- 要求ID
        AND program_application_id = gt_prog_appl_id   -- アプリケーションID
        AND program_id = gt_conc_program_id            -- プログラムID
      ORDER BY whse_code,header_id
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- グローバル変数の初期化
    gv_lt1_ship_date_from        := 0;
    gv_lt1_ship_date_to          := 0;
    gv_lt2_ship_date_from        := 0;
    gv_lt2_ship_date_to          := 0;
    gv_ship_date_from            := 0;
    gv_ship_date_to              := 0;
    gv_move_ship_date_from       := 0;
    gv_move_ship_date_to         := 0;
    gv_prov_ship_date_from       := 0;
    gv_prov_ship_date_to         := 0;
    gn_cnt_upd         := 0;                    -- 更新用データ件数
    gn_cnt_chk_data    := 0;                    -- チェック済データ格納カウント
    gn_cnt_upd_ship    := 0;                    -- 出荷更新件数
    gn_cnt_upd_prov    := 0;                    -- 支給更新件数
    gn_cnt_upd_move    := 0;                    -- 移動更新件数
-- 2008/12/01 H.Itou Add Start 本番障害#148
    gn_warn_cnt        := 0;                    -- 警告件数
-- 2008/12/01 H.Itou Add End
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
    gn_ins_upd_lot_info_cnt   := 0;             -- ロット情報保持マスタ登録更新
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
    gr_chk_header_data_tab.DELETE;
    -- エラーフラグの初期化
    gv_data_found_flg     := gc_onoff_div_off;   -- 処理対象データありフラグ
    gv_err_flg_resv       := gc_onoff_div_off;   -- 引当エラーフラグ
-- 2008/12/01 H.Itou Add Start 本番障害#148
    gv_err_flg_resv2      := gc_onoff_div_off;   -- 引当エラーフラグ2
-- 2008/12/01 H.Itou Add End
    gv_err_flg_carr       := gc_onoff_div_off;   -- 配車エラーフラグ
    gv_war_flg_carr_mixed := gc_onoff_div_off;   -- 配車出荷依頼製品混在ワーニングフラグ
    gv_err_flg_whse       := gc_onoff_div_off;   -- 倉庫エラーフラグ
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
    gr_param.dept_code           := iv_dept_code;           -- 部署
    gr_param.shipping_biz_type   := iv_shipping_biz_type;   -- 処理種別
    gr_param.transaction_type_id := iv_transaction_type_id; -- 出庫形態
    gr_param.lead_time_day_01    := TO_NUMBER(iv_lead_time_day_01);    -- 生産物流LT1
    gv_lt1_ship_date_from        := iv_lt1_ship_date_from;  -- 生産物流LT1/出荷依頼/出庫日From
    gv_lt1_ship_date_to          := iv_lt1_ship_date_to;    -- 生産物流LT1/出荷依頼/出庫日To
    gr_param.lead_time_day_02    := TO_NUMBER(iv_lead_time_day_02);    -- 生産物流LT2
    gv_lt2_ship_date_from        := iv_lt2_ship_date_from;  -- 生産物流LT2/出荷依頼/出庫日From
    gv_lt2_ship_date_to          := iv_lt2_ship_date_to;    -- 生産物流LT2/出荷依頼/出庫日To
    gv_ship_date_from            := iv_ship_date_from;      -- 出庫日From
    gv_ship_date_to              := iv_ship_date_to;        -- 出庫日To
    gv_move_ship_date_from       := iv_move_ship_date_from; -- 移動/出庫日From
    gv_move_ship_date_to         := iv_move_ship_date_to;   -- 移動/出庫日To
    gv_prov_ship_date_from       := iv_prov_ship_date_from; -- 支給/出庫日From
    gv_prov_ship_date_to         := iv_prov_ship_date_to;   -- 支給/出庫日To
    gr_param.block_01            := iv_block_01;            -- ブロック１
    gr_param.block_02            := iv_block_02;            -- ブロック２
    gr_param.block_03            := iv_block_03;            -- ブロック３
    gr_param.shipped_locat_code  := iv_shipped_locat_code;  -- 出庫元
--
    -- WHOカラム取得
    gt_user_id          := FND_GLOBAL.USER_ID;          -- 作成者、最終更新者
    gt_login_id         := FND_GLOBAL.LOGIN_ID;         -- 最終更新ログイン
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- アプリケーションID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- プログラムID
--
    gt_system_date      := SYSDATE;                     -- システム日付
--
    ln_cnt := 0;
    -- ===============================================
    -- D-1  入力パラメータチェック
    -- ===============================================
    check_parameter(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- D-2  プロファイル取得処理
    -- ===============================================
    get_profile(
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================================
    -- D-3  出荷・支給・移動情報ヘッダ抽出処理
    -- ===============================================
    get_confirm_block_header(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    <<header_loop>>
    FOR re_header IN cur_get_confirm_block_tmp LOOP
      --------------------------------------------------
      -- 保管倉庫コードがブレイク時（一つ前で取得の保管倉庫コードと異なる場合）
      --------------------------------------------------
      IF (ln_cnt > 0 ) THEN
        IF (re_header.whse_code <> gr_chk_header_data_tab(ln_cnt).whse_code) THEN
          --------------------------------------------------
          -- 同一倉庫内にエラーがない場合
          --------------------------------------------------
          IF (gv_err_flg_whse = gc_onoff_div_off) THEN
          -- ===============================================
          -- D-10  通知ステータス更新用PL／SQL表 格納処理
          -- ===============================================
            set_upd_data(
              lv_errbuf,          -- エラー・メッセージ           --# 固定 #
              lv_retcode,         -- リターン・コード             --# 固定 #
              lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              --(エラー処理)
              RAISE global_process_expt;
            ELSIF (lv_retcode = gv_status_warn) THEN
              ov_retcode := lv_retcode;
            END IF;
          END IF;
          -- ===============================================
          -- D-11  チェック済データ格納用PL／SQL表 初期化処理
          -- ===============================================
          gr_checked_data_tab.DELETE;
          gv_err_flg_whse := gc_onoff_div_off; -- 倉庫エラーフラグ
        END IF;
      END IF;
--
      ln_cnt := ln_cnt + 1;
      --------------------------------------------------
      -- 抽出データ格納
      --------------------------------------------------
      gr_chk_header_data_tab(ln_cnt).data_class           := re_header.data_class          ;
      gr_chk_header_data_tab(ln_cnt).whse_code            := re_header.whse_code           ;
      gr_chk_header_data_tab(ln_cnt).header_id            := re_header.header_id           ;
      gr_chk_header_data_tab(ln_cnt).notif_status         := re_header.notif_status        ;
      gr_chk_header_data_tab(ln_cnt).prod_class           := re_header.prod_class          ;
      gr_chk_header_data_tab(ln_cnt).item_class           := re_header.item_class          ;
      gr_chk_header_data_tab(ln_cnt).delivery_no          := re_header.delivery_no         ;
      gr_chk_header_data_tab(ln_cnt).request_no           := re_header.request_no          ;
      gr_chk_header_data_tab(ln_cnt).freight_charge_class := re_header.freight_charge_class;
      gr_chk_header_data_tab(ln_cnt).d1_whse_code         := re_header.d1_whse_code        ;
      gr_chk_header_data_tab(ln_cnt).base_date            := re_header.base_date           ;
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
      gr_chk_header_data_tab(ln_cnt).deliver_to_id        := re_header.deliver_to_id;
      gr_chk_header_data_tab(ln_cnt).result_deliver_to_id := re_header.result_deliver_to_id;
      gr_chk_header_data_tab(ln_cnt).arrival_date         := re_header.arrival_date;
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
--
      -- ===============================================
      -- D-4  出荷・支給・移動情報明細抽出処理
      -- ===============================================
      get_confirm_block_line(
        ln_cnt,             --
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = gv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
-- ##### 20080616 1.1 結合障害 #9対応 START #####
        RAISE ex_worn ;
-- ##### 20080616 1.1 結合障害 #9対応 END   #####
      END IF;
--
      -- エラーフラグの初期化
      gv_err_flg_resv := gc_onoff_div_off;       -- 引当エラーフラグ
-- 2008/12/01 H.Itou Add Start 本番障害#148
      gv_err_flg_resv2 := gc_onoff_div_off;      -- 引当エラーフラグ2
-- 2008/12/01 H.Itou Add End
      gv_err_flg_carr := gc_onoff_div_off;       -- 配車エラーフラグ
      gv_war_flg_carr_mixed := gc_onoff_div_off; -- 配車出荷依頼製品混在ワーニングフラグ
--
      -- 明細件数の初期化
      gn_cnt_line    := 0; -- 明細件数
      gn_cnt_prod    := 0; -- 製品件数
      gn_cnt_no_prod := 0; -- 製品以外件数
      IF gr_chk_line_data_tab.COUNT > 0 THEN
        <<line_loop>>
        FOR i IN gr_chk_line_data_tab.FIRST .. gr_chk_line_data_tab.LAST LOOP
          gn_cnt_line := gn_cnt_line + 1;
          -- ===============================================
          -- D-5  引当処理済チェック処理
          -- ===============================================
          chk_reserved(
            ln_cnt,             --
            lv_errbuf,          -- エラー・メッセージ           --# 固定 #
            lv_retcode,         -- リターン・コード             --# 固定 #
            lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = gv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          ELSIF (lv_retcode = gv_status_warn) THEN
            ov_retcode := lv_retcode;
-- 2008/12/01 H.Itou Mod Start 本番障害#148
--          END IF;
          -- 正常の場合、D-6の処理実行。
          ELSE
-- 2008/12/01 H.Itou Mod End
            -- ===============================================
            -- D-6  出荷明細 製品混在チェック処理
            -- ===============================================
            chk_mixed_prod(
              ln_cnt,             --
              lv_errbuf,          -- エラー・メッセージ           --# 固定 #
              lv_retcode,         -- リターン・コード             --# 固定 #
              lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              --(エラー処理)
              RAISE global_process_expt;
            ELSIF (lv_retcode = gv_status_warn) THEN
              ov_retcode := lv_retcode;
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
            ELSE
              -- ===============================================
              -- D-14  ロット情報保持マスタ 更新処理
              -- ===============================================
              -- データ区分が'1'（出荷依頼）の場合のみ処理実行
              IF gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order THEN
                ins_upd_lot_hold_info(
                  ln_cnt,             --
                  lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                  lv_retcode,         -- リターン・コード             --# 固定 #
                  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
                );
                IF (lv_retcode = gv_status_error) THEN
                  --(エラー処理)
                  RAISE global_process_expt;
                ELSIF (lv_retcode = gv_status_warn) THEN
                  ov_retcode := lv_retcode;
                END IF;
              END IF;
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
            END IF;
-- 2008/12/01 H.Itou Mod Start 本番障害#148
          END IF;
-- 2008/12/01 H.Itou Mod End
        END LOOP line_loop;
      END IF;
--
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
      -- ===============================================
      -- D-15  出荷取消情報明細抽出処理
      -- ===============================================
      -- データ区分が'8'（出荷取消）の場合のみ処理実行
      IF gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order_cncl THEN
        get_confirm_block_line_cncl(
          ln_cnt,             --
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = gv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
          RAISE ex_worn ;
        END IF;
  --
        -- 明細件数の初期化
        gn_cnt_line_cncl    := 0; -- 明細件数
        --
        IF gr_chk_line_data_tab_cncl.COUNT > 0 THEN
          <<cncl_line_loop>>
          FOR i IN gr_chk_line_data_tab_cncl.FIRST .. gr_chk_line_data_tab_cncl.LAST LOOP
            gn_cnt_line_cncl := gn_cnt_line_cncl + 1;
            -- ===============================================
            -- D-14  ロット情報保持マスタ 更新処理
            -- ===============================================
            ins_upd_lot_hold_info(
              ln_cnt,             --
              lv_errbuf,          -- エラー・メッセージ           --# 固定 #
              lv_retcode,         -- リターン・コード             --# 固定 #
              lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              --(エラー処理)
              RAISE global_process_expt;
            ELSIF (lv_retcode = gv_status_warn) THEN
              ov_retcode := lv_retcode;
            END IF;
          END LOOP cncl_line_loop;
        END IF;
      --
      END IF;
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
-- 2008/12/01 H.Itou Add Start 本番障害#148
      -- 引当エラーフラグ２がONの場合、後続処理(確定処理)実行
      IF (gv_err_flg_resv2 = gc_onoff_div_off) THEN
-- 2008/12/01 H.Itou Add End
        -- ===============================================
        -- D-7  配車済チェック処理
        -- ===============================================
        chk_carrier(
          ln_cnt,             --
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = gv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
  --
        ---------------------------------------------------------
        -- 引当エラーフラグがOFFかつ配車エラーフラグがOFFの場合
        ---------------------------------------------------------
        IF ((gv_err_flg_resv = gc_onoff_div_off) AND (gv_err_flg_carr = gc_onoff_div_off)) THEN
          -- ===============================================
          -- D-8  チェック済データ PL/SQL表格納処理
          -- ===============================================
          set_checked_data(
            ln_cnt,             --
            lv_errbuf,          -- エラー・メッセージ           --# 固定 #
            lv_retcode,         -- リターン・コード             --# 固定 #
            lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = gv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          ELSIF (lv_retcode = gv_status_warn) THEN
            ov_retcode := lv_retcode;
          END IF;
        -- ===============================================
        -- D-9  チェックエラーログ 出力処理
        -- ===============================================
        ---------------------------------------------------------
        -- 引当エラーフラグがONの場合
        ---------------------------------------------------------
        ELSIF ((gv_err_flg_resv = gc_onoff_div_on) AND (gv_err_flg_carr = gc_onoff_div_off)) THEN
          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                                       gv_cons_msg_kbn_wsh -- 'XXWSH'
                                      ,gv_check_line_err   -- 引当処理済チェックエラー
                                      ,gv_cnst_tkn_check_kbn    -- トークン'CHECK_KBN'
                                      ,gv_tkn_reserved_err   -- '引当エラー'
                                      ,gv_cnst_tkn_delivery_no -- トークン'DELIVERY_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '配送No'
                                      ,gv_cnst_tkn_request_no  -- トークン'REQUEST_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '依頼No'
                                      ,1
                                      ,5000);
          -- メッセージ出力
          FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
          ov_retcode := gv_status_warn; -- 終了ステータス：警告
        ---------------------------------------------------------
        -- 配車エラーフラグがONの場合
        ---------------------------------------------------------
        ELSIF ((gv_err_flg_resv = gc_onoff_div_off) AND (gv_err_flg_carr = gc_onoff_div_on)) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_cons_msg_kbn_wsh -- 'XXWSH'
                                      ,gv_check_line_err   -- 引当処理済チェックエラー
                                      ,gv_cnst_tkn_check_kbn    -- トークン'CHECK_KBN'
                                      ,gv_tkn_carrier_err   -- '配車エラー'
                                      ,gv_cnst_tkn_delivery_no -- トークン'DELIVERY_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '配送No'
                                      ,gv_cnst_tkn_request_no  -- トークン'REQUEST_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '依頼No'
                                      ,1
                                      ,5000);
          -- メッセージ出力
          FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
          ov_retcode := gv_status_warn; -- 終了ステータス：警告
        ---------------------------------------------------------
        -- 引当エラーフラグがONかつ配車エラーフラグがONの場合
        ---------------------------------------------------------
        ELSIF ((gv_err_flg_resv = gc_onoff_div_on) AND (gv_err_flg_carr = gc_onoff_div_on)) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_cons_msg_kbn_wsh -- 'XXWSH'
                                      ,gv_check_line_err   -- 引当処理済チェックエラー
                                      ,gv_cnst_tkn_check_kbn    -- トークン'CHECK_KBN'
                                      ,gv_tkn_reserved_carrier_err   -- '引当及び配車エラー'
                                      ,gv_cnst_tkn_delivery_no -- トークン'DELIVERY_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '配送No'
                                      ,gv_cnst_tkn_request_no  -- トークン'REQUEST_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '依頼No'
                                      ,1
                                      ,5000);
          -- メッセージ出力
          FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
          ov_retcode := gv_status_warn; -- 終了ステータス：警告
        END IF;
        ---------------------------------------------------------
        -- 配車出荷依頼製品混在ワーニングフラグがONの場合
        ---------------------------------------------------------
        IF (gv_war_flg_carr_mixed = gc_onoff_div_on) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_cons_msg_kbn_wsh -- 'XXWSH'
                                      ,gv_check_line_err   -- 引当処理済チェックエラー
                                      ,gv_cnst_tkn_check_kbn    -- トークン'CHECK_KBN'
                                      ,gv_tkn_mixed_prod_err   -- '出荷依頼製品混在'
                                      ,gv_cnst_tkn_delivery_no -- トークン'DELIVERY_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '配送No'
                                      ,gv_cnst_tkn_request_no  -- トークン'REQUEST_NO'
                                      ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '依頼No'
                                      ,1
                                      ,5000);
          -- メッセージ出力
          FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
          ov_retcode := gv_status_warn; -- 終了ステータス：警告
        END IF;
-- 2008/12/01 H.Itou Add Start 本番障害#148
      END IF;
-- 2008/12/01 H.Itou Add End
--
    END LOOP header_loop;
--
    IF gr_checked_data_tab.COUNT > 0 THEN
      --------------------------------------------------
      -- 同一倉庫内にエラーがない場合
      --------------------------------------------------
      IF (gv_err_flg_whse = gc_onoff_div_off) THEN
        -- ===============================================
        -- D-10  通知ステータス更新用PL／SQL表 格納処理
        -- ===============================================
        set_upd_data(
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = gv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
      END IF;
    END IF;
--
    IF gr_upd_data_tab.COUNT > 0 THEN
      -- ===============================================
      -- D-12  通知ステータス 一括更新処理
      -- ===============================================
      upd_notif_status(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = gv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
    END IF;
--
    -- ===============================================
    -- D-13  中間テーブルパージ処理
    -- ===============================================
    purge_tbl(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
--
-- ##### 20080616 1.1 結合障害 #9対応 START #####
    -- =============================================================================================
    -- 警告処理
    -- =============================================================================================
    WHEN ex_worn THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf ;
      ov_retcode := gv_status_warn;
-- ##### 20080616 1.1 結合障害 #9対応 END   #####
--
    --*** 数値型に変換できなかった場合=TO_NUMBER() ***
    WHEN VALUE_ERROR THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode :=   gv_status_error;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,  -- エラーメッセージ #固定#
    retcode                   OUT NOCOPY VARCHAR2,  -- エラーコード     #固定#
    iv_dept_code              IN VARCHAR2,          -- 部署
    iv_shipping_biz_type      IN VARCHAR2,          -- 処理種別
    iv_transaction_type_id    IN VARCHAR2,          -- 出庫形態
    iv_lead_time_day_01       IN VARCHAR2,          -- 生産物流LT1
    iv_lt1_ship_date_from     IN VARCHAR2,          -- 生産物流LT1/出荷依頼/出庫日From
    iv_lt1_ship_date_to       IN VARCHAR2,          -- 生産物流LT1/出荷依頼/出庫日To
    iv_lead_time_day_02       IN VARCHAR2,          -- 生産物流LT2
    iv_lt2_ship_date_from     IN VARCHAR2,          -- 生産物流LT2/出荷依頼/出庫日From
    iv_lt2_ship_date_to       IN VARCHAR2,          -- 生産物流LT2/出荷依頼/出庫日To
    iv_ship_date_from         IN VARCHAR2,          -- 出庫日From
    iv_ship_date_to           IN VARCHAR2,          -- 出庫日To
    iv_move_ship_date_from    IN VARCHAR2,          -- 移動/出庫日From
    iv_move_ship_date_to      IN VARCHAR2,          -- 移動/出庫日To
    iv_prov_ship_date_from    IN VARCHAR2,          -- 支給/出庫日From
    iv_prov_ship_date_to      IN VARCHAR2,          -- 支給/出庫日To
    iv_block_01               IN VARCHAR2,          -- ブロック１
    iv_block_02               IN VARCHAR2,          -- ブロック２
    iv_block_03               IN VARCHAR2,          -- ブロック３
    iv_shipped_locat_code     IN VARCHAR2           -- 出庫元
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
  submain(
    iv_dept_code,           -- 部署
    iv_shipping_biz_type,   -- 処理種別
    iv_transaction_type_id, -- 出庫形態
    iv_lead_time_day_01,    -- 生産物流LT1
    iv_lt1_ship_date_from,  -- 生産物流LT1/出荷依頼/出庫日From
    iv_lt1_ship_date_to,    -- 生産物流LT1/出荷依頼/出庫日To
    iv_lead_time_day_02,    -- 生産物流LT2
    iv_lt2_ship_date_from,  -- 生産物流LT2/出荷依頼/出庫日From
    iv_lt2_ship_date_to,    -- 生産物流LT2/出荷依頼/出庫日To
    iv_ship_date_from,      -- 出庫日From
    iv_ship_date_to,        -- 出庫日To
    iv_move_ship_date_from, -- 移動/出庫日From
    iv_move_ship_date_to,   -- 移動/出庫日To
    iv_prov_ship_date_from, -- 支給/出庫日From
    iv_prov_ship_date_to,   -- 支給/出庫日To
    iv_block_01,            -- ブロック１
    iv_block_02,            -- ブロック２
    iv_block_03,            -- ブロック３
    iv_shipped_locat_code,  -- 出庫元
    lv_errbuf,              -- エラー・メッセージ           --# 固定 #
    lv_retcode,             -- リターン・コード             --# 固定 #
    lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
  );
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
    -- ====================================================
    -- コンカレントログの出力
    -- ====================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
--
    -------------------------------------------------------
    -- 入力パラメータ
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '入力パラメータ' );
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '部署                            ：' || iv_dept_code           ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '処理種別                        ：' || iv_shipping_biz_type   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '出庫形態                        ：' || iv_transaction_type_id ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '生産物流LT1                     ：' || iv_lead_time_day_01    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '生産物流LT1/出荷依頼/出庫日From ：' || iv_lt1_ship_date_from  ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '生産物流LT1/出荷依頼/出庫日To   ：' || iv_lt1_ship_date_to    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '生産物流LT2                     ：' || iv_lead_time_day_02    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '生産物流LT2/出荷依頼/出庫日From ：' || iv_lt2_ship_date_from  ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '生産物流LT2/出荷依頼/出庫日To   ：' || iv_lt2_ship_date_to    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '出庫日From                      ：' || iv_ship_date_from      ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '出庫日To                        ：' || iv_ship_date_to        ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '移動/出庫日From                 ：' || iv_move_ship_date_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '移動/出庫日To                   ：' || iv_move_ship_date_to   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '支給/出庫日From                 ：' || iv_prov_ship_date_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '支給/出庫日To                   ：' || iv_prov_ship_date_to   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                'ブロック１                      ：' || iv_block_01            ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                'ブロック２                      ：' || iv_block_02            ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                'ブロック３                      ：' || iv_block_03            ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '出庫元                          ：' || iv_shipped_locat_code  ) ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
--
    -------------------------------------------------------
    -- 処理件数
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '処理件数' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'  出荷    ：' || TO_CHAR( gn_cnt_upd_ship,'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'  支給    ：' || TO_CHAR( gn_cnt_upd_prov,'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'  移動    ：' || TO_CHAR( gn_cnt_upd_move,'FM999,999,990' ) ) ;
-- 2014/12/24 E_本稼動_12237 V1.11 Add START
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'  ロット情報保持マスタ    ：' || TO_CHAR( gn_ins_upd_lot_info_cnt,'FM999,999,990' ) ) ;
-- 2014/12/24 E_本稼動_12237 V1.11 Add END
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
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
END xxwsh600005c;
/
