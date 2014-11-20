CREATE OR REPLACE PACKAGE BODY xxpo940004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940004C(body)
 * Description      : 仕入・有償・移動情報抽出処理
 * MD.050           : 生産物流共通                  T_MD050_BPO_940
 * MD.070           : 仕入・有償・移動情報抽出処理  T_MD070_BPO_94D
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  replace_sep            文字列内のカンマ削除
 *  decimal_round_up       小数点の指定位置での切り上げ
 *  parameter_disp         パラメータの出力
 *  parameter_check        パラメータチェック               (D-1)
 *  pha_sel_proc           発注情報検索処理                 (D-3)
 *  oha_sel_proc           支給情報検索処理                 (D-4)
 *  mov_sel_proc           移動情報検索処理                 (D-5)
 *  put_csv_data           CSVファイルへのデータ出力
 *  csv_file_proc          CSVファイル出力                  (D-6)
 *  workflow_start         ワークフロー通知処理             (D-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/10    1.0   Oracle 山根 一浩 初回作成
 *  2008/08/20    1.1   Oracle 山根 一浩 T_S_593,T_TE080_BPO_940 指摘6,指摘7,指摘8,指摘9対応
 *  2008/09/02    1.2   Oracle 山根 一浩 T_S_626,T_TE080_BPO_940 指摘10対応
 *  2008/09/18    1.3   Oracle 大橋 孝郎 T_S_460対応
 *  2008/11/26    1.4   Oracle 吉田 夏樹 本番#113対応
 *  2009/02/04    1.5   Oracle 吉田 夏樹 本番#15対応
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo940004c'; -- パッケージ名
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';        -- アプリケーション短縮名
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';       -- アプリケーション短縮名
--
  -- データ種別
  gv_data_class_pha CONSTANT VARCHAR2(3) := '520'; -- 発注情報
  gv_data_class_oha CONSTANT VARCHAR2(3) := '530'; -- 支給情報
  gv_data_class_mov CONSTANT VARCHAR2(3) := '540'; -- 移動情報
--
  gv_sec_class_home CONSTANT VARCHAR2(1) := '1';   -- 伊藤園ユーザータイプ
  gv_sec_class_vend CONSTANT VARCHAR2(1) := '2';   -- 取引先ユーザータイプ
  gv_sec_class_extn CONSTANT VARCHAR2(1) := '3';   -- 外部倉庫ユーザータイプ
  gv_sec_class_quay CONSTANT VARCHAR2(1) := '4';   -- 東洋埠頭ユーザータイプ
--
  gv_drop_ship_type_ship   CONSTANT VARCHAR2(1) := '2';         -- 出荷
  gv_weight_class          CONSTANT VARCHAR2(1) := '1';         -- 重量
  gv_capacity_class        CONSTANT VARCHAR2(1) := '2';         -- 容積
  gv_lot_ctl_on            CONSTANT VARCHAR2(1) := '1';         -- ロット管理品
  gv_document_type_code_20 CONSTANT VARCHAR2(2) := '20';        -- 移動
  gv_document_type_code_30 CONSTANT VARCHAR2(2) := '30';        -- 支給指示
  gv_record_type_code_10   CONSTANT VARCHAR2(2) := '10';        -- 指示
  gv_record_type_code_20   CONSTANT VARCHAR2(2) := '20';        -- 出庫実績
  gv_record_type_code_30   CONSTANT VARCHAR2(2) := '30';        -- 入庫実績
  gv_shipping_shikyu_class CONSTANT VARCHAR2(1) := '2';         -- 支給依頼
  gv_rcv_pay_ctg_05        CONSTANT VARCHAR2(2) := '05';        -- 有償返品
  gv_rcv_pay_ctg_06        CONSTANT VARCHAR2(2) := '06';        -- 仕入返品
  gv_flg_on                CONSTANT VARCHAR2(1) := '1';
  gv_status_on             CONSTANT VARCHAR2(1) := 'A';
  gv_enabled_flag_on       CONSTANT VARCHAR2(1) := 'Y';
  gv_external_flag_on      CONSTANT VARCHAR2(1) := 'Y';
  gv_ship_method           CONSTANT VARCHAR2(30) := 'XXCMN_SHIP_METHOD';
  gv_transaction_type_name CONSTANT VARCHAR2(30) := '仕入有償';
  gv_company_name          CONSTANT VARCHAR2(10) := 'ITOEN';
--
  -- トークン
  gv_tkn_number_94d_01    CONSTANT VARCHAR2(15) := 'APP-XXPO-10156';  -- プロファイル取得エラー
  gv_tkn_number_94d_02    CONSTANT VARCHAR2(15) := 'APP-XXPO-10102';  -- 不正なﾊﾟﾗﾒｰﾀ1
  gv_tkn_number_94d_03    CONSTANT VARCHAR2(15) := 'APP-XXPO-10104';  -- 不正なﾊﾟﾗﾒｰﾀ3
  gv_tkn_number_94d_04    CONSTANT VARCHAR2(15) := 'APP-XXPO-10105';  -- 不正なﾊﾟﾗﾒｰﾀ4
  gv_tkn_number_94d_05    CONSTANT VARCHAR2(15) := 'APP-XXPO-10026';  -- データ未取得メッセージ
  gv_tkn_number_94d_06    CONSTANT VARCHAR2(15) := 'APP-XXPO-10155';  -- パラメータエラー
  gv_tkn_number_94d_07    CONSTANT VARCHAR2(15) := 'APP-XXPO-30022';  -- パラメータ受取
--
  gv_tkn_number_94d_50    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10113';  -- ファイルパス不正ｴﾗｰ
  gv_tkn_number_94d_51    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10114';  -- ファイル名不正ｴﾗｰ
  gv_tkn_number_94d_52    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10115';  -- ファイルアクセス権限ｴﾗｰ
  gv_tkn_number_94d_53    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10119';  -- ファイルパスNULLｴﾗｰ
  gv_tkn_number_94d_54    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10120';  -- ファイル名NULLｴﾗｰ
  gv_tkn_number_94d_55    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10117';  -- Workflow起動ｴﾗｰ
--
  gv_tkn_name             CONSTANT VARCHAR2(15) := 'NAME';
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAM_NAME';
  gv_tkn_param_value      CONSTANT VARCHAR2(15) := 'PARAM_VALUE';
  gv_tkn_error_param      CONSTANT VARCHAR2(15) := 'ERROR_PARAM';
  gv_tkn_error_value      CONSTANT VARCHAR2(15) := 'ERROR_VALUE';
  gv_tkn_param            CONSTANT VARCHAR2(15) := 'PARAM';
  gv_tkn_data             CONSTANT VARCHAR2(15) := 'DATA';
  gv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';
--
  gv_status_null     CONSTANT VARCHAR2(2) := '00';
  gv_xxinv_status_01 CONSTANT VARCHAR2(2) := '01';   -- 依頼中
  gv_xxinv_status_02 CONSTANT VARCHAR2(2) := '02';   -- 依頼済
  gv_xxinv_status_03 CONSTANT VARCHAR2(2) := '03';   -- 調整中
  gv_xxinv_status_04 CONSTANT VARCHAR2(2) := '04';   -- 出庫報告有
  gv_xxinv_status_05 CONSTANT VARCHAR2(2) := '05';   -- 入庫報告有
  gv_xxinv_status_06 CONSTANT VARCHAR2(2) := '06';   -- 入出庫報告有
  gv_xxinv_status_07 CONSTANT VARCHAR2(2) := '99';   -- 取消
/* 2008/07/28 Mod ↓
  gv_xxpo_status_01  CONSTANT VARCHAR2(2) := '05';   -- 入力中
  gv_xxpo_status_02  CONSTANT VARCHAR2(2) := '06';   -- 入力完了
  gv_xxpo_status_03  CONSTANT VARCHAR2(2) := '07';   -- 受領済
  gv_xxpo_status_04  CONSTANT VARCHAR2(2) := '08';   -- 出荷実績計上済
  gv_xxpo_status_05  CONSTANT VARCHAR2(2) := '99';   -- 取消
2008/07/28 Mod ↑ */
  gv_xxpo_status_01  CONSTANT VARCHAR2(2) := '15';   -- 発注作成中
  gv_xxpo_status_02  CONSTANT VARCHAR2(2) := '20';   -- 発注作成済
  gv_xxpo_status_03  CONSTANT VARCHAR2(2) := '25';   -- 受入あり
  gv_xxpo_status_04  CONSTANT VARCHAR2(2) := '30';   -- 数量確定済
  gv_xxpo_status_05  CONSTANT VARCHAR2(2) := '35';   -- 金額確定済
  gv_xxpo_status_06  CONSTANT VARCHAR2(2) := '99';   -- 取消
--
  gv_xxwsh_status_01 CONSTANT VARCHAR2(2) := '01';   -- 入力中
  gv_xxwsh_status_02 CONSTANT VARCHAR2(2) := '02';   -- 拠点確定
  gv_xxwsh_status_03 CONSTANT VARCHAR2(2) := '03';   -- 締め済み
  gv_xxwsh_status_04 CONSTANT VARCHAR2(2) := '04';   -- 出荷実績計上済
  gv_xxwsh_status_05 CONSTANT VARCHAR2(2) := '06';   -- 入力完了
  gv_xxwsh_status_06 CONSTANT VARCHAR2(2) := '07';   -- 受領済
  gv_xxwsh_status_07 CONSTANT VARCHAR2(2) := '99';   -- 取消
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  TYPE masters_rec IS RECORD(
    sel_tbl_id           NUMBER,       -- テーブルID
    company_name         VARCHAR2(5),  -- 会社名
    data_class           VARCHAR2(3),  -- データ種別
    seq_no               NUMBER,       -- 伝送用枝番
    ship_no              VARCHAR2(12), -- 配送No.
    request_no           VARCHAR2(12), -- 依頼No.
    relation_no          VARCHAR2(12), -- 関連No.
    base_request_no      VARCHAR2(12), -- コピー元No.   2008/09/02 Add
    base_ship_no         VARCHAR2(12), -- 元配送No.
    vendor_code          VARCHAR2(4),  -- 取引先コード
    vendor_name          VARCHAR2(60), -- 取引先名
    vendor_s_name        VARCHAR2(20), -- 取引先略名
    mediation_code       VARCHAR2(4),  -- 斡旋者コード
    mediation_name       VARCHAR2(60), -- 斡旋者名
    mediation_s_name     VARCHAR2(20), -- 斡旋者略名
    whse_code            VARCHAR2(4),  -- 倉庫コード
    whse_name            VARCHAR2(60), -- 倉庫名
    whse_s_name          VARCHAR2(20), -- 倉庫略名
    vendor_site_code     VARCHAR2(9),  -- 配送先コード
    vendor_site_name     VARCHAR2(60), -- 配送先名
    vendor_site_s_name   VARCHAR2(20), -- 配送先略名
    zip                  VARCHAR2(10), -- 郵便番号
    address              VARCHAR2(60), -- 住所
    phone                VARCHAR2(15), -- 電話番号
    carrier_code         VARCHAR2(4),  -- 運送業者コード
    carrier_name         VARCHAR2(60), -- 運送業者名
    carrier_s_name       VARCHAR2(20), -- 運送業者略名
    ship_date            DATE,         -- 出庫日
    arrival_date         DATE,         -- 入庫日
    arrival_time_from    VARCHAR2(5),  -- 着荷時間FROM
    arrival_time_to      VARCHAR2(5),  -- 着荷時間TO
    method_code          VARCHAR2(2),  -- 配送区分
    div_a                VARCHAR2(1),  -- 区分Ａ
    div_b                VARCHAR2(1),  -- 区分Ｂ
    div_c                VARCHAR2(1),  -- 区分Ｃ
    instruction_dept     VARCHAR2(4),  -- 指示部署コード
    request_dept         VARCHAR2(4),  -- 依頼部署コード
    status               VARCHAR2(2),  -- ステータス
    notif_status         VARCHAR2(2),  -- 通知ステータス
    div_d                VARCHAR2(30), -- 区分Ｄ
    div_e                VARCHAR2(1),  -- 区分Ｅ
    div_f                VARCHAR2(1),  -- 区分Ｆ
    div_g                VARCHAR2(1),  -- 区分Ｇ
    div_h                VARCHAR2(1),  -- 区分Ｈ
    info_a               VARCHAR2(10), -- 情報Ａ
    info_b               VARCHAR2(7),  -- 情報Ｂ
    info_c               VARCHAR2(60), -- 情報Ｃ
    info_d               VARCHAR2(20), -- 情報Ｄ
    info_e               VARCHAR2(10), -- 情報Ｅ
    head_description     VARCHAR2(60), -- 摘要(ヘッダ)
    line_description     VARCHAR2(60), -- 摘要(明細)
    line_num             VARCHAR2(3),  -- 明細No.
    item_no              VARCHAR2(7),  -- 品目コード
    item_name            VARCHAR2(60), -- 品目名
    item_s_name          VARCHAR2(20), -- 品目略名
    futai_code           VARCHAR2(1),  -- 付帯
    lot_no               VARCHAR2(10), -- ロットNo
    lot_date             DATE,         -- 製造日
    best_bfr_date        DATE,         -- 賞味期限
    lot_sign             VARCHAR2(6),  -- 固有記号
    request_qty          NUMBER,       -- 依頼数
    instruct_qty         NUMBER,       -- 指示数
    num_of_deliver       NUMBER,       -- 出庫数
    ship_to_qty          NUMBER,       -- 入庫数
    fix_qty              NUMBER,       -- 確定数
    item_um              VARCHAR2(3),  -- 単位
    weight_capacity      NUMBER,       -- 重量容積
    frequent_qty         NUMBER,       -- 入数
    frequent_factory     VARCHAR2(4),  -- 工場コード
    div_i                VARCHAR2(1),  -- 区分Ｉ
    div_j                VARCHAR2(1),  -- 区分Ｊ
    div_k                VARCHAR2(1),  -- 区分Ｋ
    designate_date       DATE,         -- 日付指定
    info_f               VARCHAR2(4),  -- 情報Ｆ
    info_g               VARCHAR2(2),  -- 情報Ｇ
    info_h               VARCHAR2(10), -- 情報Ｈ
    info_i               VARCHAR2(10), -- 情報Ｉ
    info_j               VARCHAR2(10), -- 情報Ｊ
-- 2008/07/31 Mod ↓
/*
    info_k               VARCHAR2(10), -- 情報Ｋ
    info_l               VARCHAR2(10), -- 情報Ｌ
*/
    info_k               VARCHAR2(20), -- 情報Ｋ
    info_l               VARCHAR2(20), -- 情報Ｌ
-- 2008/07/31 Mod ↑
    info_m               VARCHAR2(7),  -- 情報Ｍ
    info_n               VARCHAR2(10), -- 情報Ｎ
    info_o               VARCHAR2(2),  -- 情報Ｏ
    info_p               VARCHAR2(2),  -- 情報Ｐ
    info_q               VARCHAR2(2),  -- 情報Ｑ
    amt_a                VARCHAR2(20), -- お金Ａ
    amt_b                VARCHAR2(20), -- お金Ｂ
    amt_c                VARCHAR2(20), -- お金Ｃ
    amt_d                VARCHAR2(20), -- お金Ｄ
    amt_e                VARCHAR2(20), -- お金Ｅ
    amt_f                VARCHAR2(20), -- お金Ｆ
    amt_g                VARCHAR2(20), -- お金Ｇ
    amt_h                VARCHAR2(20), -- お金Ｈ
    amt_i                VARCHAR2(20), -- お金Ｉ
    amt_j                VARCHAR2(20), -- お金Ｊ
--
    description          VARCHAR2(60), -- 摘要(明細)
    update_date_h        DATE,         -- 更新日時(ヘッダ)
    update_date_l        DATE,         -- 更新日時(明細)
--
    v_seq_no             VARCHAR2(3),  -- 伝送用枝番(文字列)
--
    v_ship_date          VARCHAR2(10), -- 出庫日(文字列)YYYY/MM/DD
    v_arrival_date       VARCHAR2(10), -- 入庫日(文字列)YYYY/MM/DD
    v_lot_date           VARCHAR2(10), -- 製造日(文字列)YYYY/MM/DD
    v_best_bfr_date      VARCHAR2(10), -- 賞味期限(文字列)YYYY/MM/DD
    v_designate_date     VARCHAR2(10), -- 日付指定(文字列)YYYY/MM/DD
    v_update_date        VARCHAR2(19), -- 更新日時(文字列)YYYY/MM/DD HH:MI:SS
    v_update_date_h      VARCHAR2(19), -- 更新日時(文字列)YYYY/MM/DD HH:MI:SS
    v_update_date_l      VARCHAR2(19), -- 更新日時(文字列)YYYY/MM/DD HH:MI:SS
--
    exec_flg             NUMBER        -- 処理フラグ
  );
--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;     -- 各マスタへ登録するデータ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_wf_ope_div               VARCHAR2(150); --  1.処理区分          (必須)
  gv_wf_class                 VARCHAR2(150); --  2.対象              (必須)
  gv_wf_notification          VARCHAR2(150); --  3.宛先              (必須)
  gv_data_class               VARCHAR2(20);  --  4.データ種別        (必須)
  gv_ship_no_from             VARCHAR2(20);  --  5.配送No.FROM       (任意)
  gv_ship_no_to               VARCHAR2(20);  --  6.配送No.TO         (任意)
  gv_req_no_from              VARCHAR2(20);  --  7.依頼No.FROM       (任意)
  gv_req_no_to                VARCHAR2(20);  --  8.依頼No.TO         (任意)
  gv_vendor_code              VARCHAR2(20);  --  9.取引先            (任意)
  gv_mediation                VARCHAR2(20);  -- 10.斡旋者            (任意)
  gv_location_code            VARCHAR2(20);  -- 11.出庫倉庫          (任意)
  gv_arvl_code                VARCHAR2(20);  -- 12.入庫倉庫          (任意)
  gv_vendor_site_code         VARCHAR2(20);  -- 13.配送先            (任意)
  gv_carrier_code             VARCHAR2(20);  -- 14.運送業者          (任意)
  gv_ship_date_from           VARCHAR2(10);  -- 15.納入日/出庫日FROM (必須)
  gv_ship_date_to             VARCHAR2(10);  -- 16.納入日/出庫日TO   (必須)
  gv_arrival_date_from        VARCHAR2(10);  -- 17.入庫日FROM        (任意)
  gv_arrival_date_to          VARCHAR2(10);  -- 18.入庫日TO          (任意)
  gv_instruction_dept         VARCHAR2(20);  -- 19.指示部署          (任意)
  gv_item_no                  VARCHAR2(20);  -- 20.品目              (任意)
  gv_update_time_from         VARCHAR2(20);  -- 21.更新日時FROM      (任意)
  gv_update_time_to           VARCHAR2(20);  -- 22.更新日時TO        (任意)
  gv_prod_class               VARCHAR2(20);  -- 23.商品区分          (任意)
  gv_item_class               VARCHAR2(20);  -- 24.品目区分          (任意)
  gv_sec_class                VARCHAR2(20);  -- 25.セキュリティ区分  (必須)
--
  gd_ship_date_from           DATE;          -- 納入日/出庫日FROM
  gd_ship_date_to             DATE;          -- 納入日/出庫日TO
  gd_arrival_date_from        DATE;          -- 入庫日FROM
  gd_arrival_date_to          DATE;          -- 入庫日TO
  gd_update_time_from         DATE;          -- 更新日時FROM
  gd_update_time_to           DATE;          -- 更新日時TO
--
  gv_sch_file_name            VARCHAR2(2000);          -- 対象ファイル名
--
  gn_user_id                  NUMBER;                  -- ユーザID
  gd_sys_date                 DATE;                    -- 当日日付
  gn_person_id                fnd_user.employee_id%TYPE;
--
  gv_min_date                 VARCHAR2(10);            -- 最小日付
  gv_max_date                 VARCHAR2(10);            -- 最大日付
--
  gr_outbound_rec             xxcmn_common_pkg.outbound_rec; -- outbound関連データ
--
  /***********************************************************************************
   * Function Name    : replace_sep
   * Description      : 文字列内にカンマが存在する場合削除する
   ***********************************************************************************/
  FUNCTION replace_sep(
    iv_moji_str  IN VARCHAR2)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'replace_sep'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_sep_com    CONSTANT VARCHAR2(1) := ',';
--
    -- *** ローカル変数 ***
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
    IF (INSTR(iv_moji_str,lv_sep_com) <> 0) THEN
      RETURN REPLACE(iv_moji_str,lv_sep_com);
    ELSE
      RETURN iv_moji_str;
    END IF;
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
  END replace_sep;
--
  /***********************************************************************************
   * Function Name    : decimal_round_up
   * Description      : 小数点の指定位置での切り上げを行う
   ***********************************************************************************/
  FUNCTION decimal_round_up(
    in_moji_num  IN NUMBER,
    in_pnt       IN NUMBER)
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'decimal_round_up'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ln_num        CONSTANT NUMBER := 0.5;
--
    -- *** ローカル変数 ***
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
--
    IF (in_moji_num IS NOT NULL) THEN
      -- 小数点以下あり
      IF (MOD(in_moji_num,FLOOR(in_moji_num)) > 0) THEN
        RETURN ROUND(in_moji_num+(ln_num / POWER(10,in_pnt)),in_pnt);
      ELSE
        RETURN in_moji_num;
      END IF;
    ELSE
      RETURN in_moji_num;
    END IF;
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
  END decimal_round_up;
--
  /**********************************************************************************
   * Procedure Name   : parameter_disp
   * Description      : パラメータの出力
   ***********************************************************************************/
  PROCEDURE parameter_disp(
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_disp';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_wf_ope_div_n           CONSTANT VARCHAR2(100) := '処理区分          ';
    lv_wf_class_n             CONSTANT VARCHAR2(100) := '対象              ';
    lv_wf_notification_n      CONSTANT VARCHAR2(100) := '宛先              ';
    lv_data_class_n           CONSTANT VARCHAR2(100) := 'データ種別        ';
    lv_ship_no_from_n         CONSTANT VARCHAR2(100) := '配送No FROM       ';
    lv_ship_no_to_n           CONSTANT VARCHAR2(100) := '配送No TO         ';
    lv_req_no_from_n          CONSTANT VARCHAR2(100) := '依頼No FROM       ';
    lv_req_no_to_n            CONSTANT VARCHAR2(100) := '依頼No TO         ';
    lv_vendor_id_n            CONSTANT VARCHAR2(100) := '取引先            ';
    lv_mediation_n            CONSTANT VARCHAR2(100) := '斡旋者            ';
    lv_location_code_n        CONSTANT VARCHAR2(100) := '出庫倉庫          ';
    lv_arvl_code_n            CONSTANT VARCHAR2(100) := '入庫倉庫          ';
    lv_vendor_site_id_n       CONSTANT VARCHAR2(100) := '配送先            ';
    lv_carrier_code_n         CONSTANT VARCHAR2(100) := '運送業者          ';
    lv_ship_date_from_n       CONSTANT VARCHAR2(100) := '納入日/出庫日FROM ';
    lv_ship_date_to_n         CONSTANT VARCHAR2(100) := '納入日/出庫日TO   ';
    lv_arvl_date_from_n       CONSTANT VARCHAR2(100) := '入庫日FROM        ';
    lv_arvl_date_to_n         CONSTANT VARCHAR2(100) := '入庫日TO          ';
    lv_inst_dept_n            CONSTANT VARCHAR2(100) := '指示部署          ';
    lv_item_no_n              CONSTANT VARCHAR2(100) := '品目              ';
    lv_upd_time_from_n        CONSTANT VARCHAR2(100) := '更新日時FROM      ';
    lv_upd_time_to_n          CONSTANT VARCHAR2(100) := '更新日時TO        ';
    lv_prod_class_n           CONSTANT VARCHAR2(100) := '商品区分          ';
    lv_item_class_n           CONSTANT VARCHAR2(100) := '品目区分          ';
    lv_sec_class_n            CONSTANT VARCHAR2(100) := 'セキュリティ区分  ';
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
--
    -- 処理区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_wf_ope_div_n,
                                          gv_tkn_data,
                                          gv_wf_ope_div);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 対象
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_wf_class_n,
                                          gv_tkn_data,
                                          gv_wf_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 宛先
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_wf_notification_n,
                                          gv_tkn_data,
                                          gv_wf_notification);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- データ種別
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_data_class_n,
                                          gv_tkn_data,
                                          gv_data_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 配送No FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_no_from_n,
                                          gv_tkn_data,
                                          gv_ship_no_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 配送No TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_no_to_n,
                                          gv_tkn_data,
                                          gv_ship_no_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 依頼No FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_req_no_from_n,
                                          gv_tkn_data,
                                          gv_req_no_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 依頼No TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_req_no_to_n,
                                          gv_tkn_data,
                                          gv_req_no_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 取引先
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_vendor_id_n,
                                          gv_tkn_data,
                                          gv_vendor_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 斡旋者
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_mediation_n,
                                          gv_tkn_data,
                                          gv_mediation);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 出庫倉庫
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_location_code_n,
                                          gv_tkn_data,
                                          gv_location_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 入庫倉庫
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_arvl_code_n,
                                          gv_tkn_data,
                                          gv_arvl_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 配送先
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_vendor_site_id_n,
                                          gv_tkn_data,
                                          gv_vendor_site_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 運送業者
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_carrier_code_n,
                                          gv_tkn_data,
                                          gv_carrier_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 納入日/出庫日FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_date_from_n,
                                          gv_tkn_data,
                                          gv_ship_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 納入日/出庫日TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_date_to_n,
                                          gv_tkn_data,
                                          gv_ship_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 入庫日FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_arvl_date_from_n,
                                          gv_tkn_data,
                                          gv_arrival_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 入庫日TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_arvl_date_to_n,
                                          gv_tkn_data,
                                          gv_arrival_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 指示部署
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_inst_dept_n,
                                          gv_tkn_data,
                                          gv_instruction_dept);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 品目
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_item_no_n,
                                          gv_tkn_data,
                                          gv_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 更新日時FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_upd_time_from_n,
                                          gv_tkn_data,
                                          gv_update_time_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 更新日時TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_upd_time_to_n,
                                          gv_tkn_data,
                                          gv_update_time_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 商品区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_prod_class_n,
                                          gv_tkn_data,
                                          gv_prod_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 品目区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_item_class_n,
                                          gv_tkn_data,
                                          gv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- セキュリティ区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_sec_class_n,
                                          gv_tkn_data,
                                          gv_sec_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END parameter_disp;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(D-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_wf_ope_div        IN            VARCHAR2,  --  1.処理区分          (必須)
    iv_wf_class          IN            VARCHAR2,  --  2.対象              (必須)
    iv_wf_notification   IN            VARCHAR2,  --  3.宛先              (必須)
    iv_data_class        IN            VARCHAR2,  --  4.データ種別        (必須)
    iv_ship_no_from      IN            VARCHAR2,  --  5.配送No.FROM       (任意)
    iv_ship_no_to        IN            VARCHAR2,  --  6.配送No.TO         (任意)
    iv_req_no_from       IN            VARCHAR2,  --  7.依頼No.FROM       (任意)
    iv_req_no_to         IN            VARCHAR2,  --  8.依頼No.TO         (任意)
    iv_vendor_code       IN            VARCHAR2,  --  9.取引先            (任意)
    iv_mediation         IN            VARCHAR2,  -- 10.斡旋者            (任意)
    iv_location_code     IN            VARCHAR2,  -- 11.出庫倉庫          (任意)
    iv_arvl_code         IN            VARCHAR2,  -- 12.入庫倉庫          (任意)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.配送先            (任意)
    iv_carrier_code      IN            VARCHAR2,  -- 14.運送業者          (任意)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.納入日/出庫日FROM (必須)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.納入日/出庫日TO   (必須)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.入庫日FROM        (任意)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.入庫日TO          (任意)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.指示部署          (任意)
    iv_item_no           IN            VARCHAR2,  -- 20.品目              (任意)
    iv_update_time_from  IN            VARCHAR2,  -- 21.更新日時FROM      (任意)
    iv_update_time_to    IN            VARCHAR2,  -- 22.更新日時TO        (任意)
    iv_prod_class        IN            VARCHAR2,  -- 23.商品区分          (任意)
    iv_item_class        IN            VARCHAR2,  -- 24.品目区分          (任意)
    iv_sec_class         IN            VARCHAR2,  -- 25.セキュリティ区分  (必須)
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_check';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_wf_ope_div_n           CONSTANT VARCHAR2(100) := '処理区分';
    lv_wf_class_n             CONSTANT VARCHAR2(100) := '対象';
    lv_wf_notification_n      CONSTANT VARCHAR2(100) := '宛先';
    lv_data_class_n           CONSTANT VARCHAR2(100) := 'データ種別';
    lv_ship_no_from_n         CONSTANT VARCHAR2(100) := '配送No FROM';
    lv_ship_no_to_n           CONSTANT VARCHAR2(100) := '配送No TO';
    lv_req_no_from_n          CONSTANT VARCHAR2(100) := '依頼No FROM';
    lv_req_no_to_n            CONSTANT VARCHAR2(100) := '依頼No TO';
    lv_vendor_id_n            CONSTANT VARCHAR2(100) := '取引先';
    lv_mediation_n            CONSTANT VARCHAR2(100) := '斡旋者';
    lv_location_code_n        CONSTANT VARCHAR2(100) := '出庫倉庫';
    lv_arvl_code_n            CONSTANT VARCHAR2(100) := '入庫倉庫';
    lv_vendor_site_id_n       CONSTANT VARCHAR2(100) := '配送先';
    lv_carrier_code_n         CONSTANT VARCHAR2(100) := '運送業者';
    lv_ship_date_from_n       CONSTANT VARCHAR2(100) := '納入日/出庫日FROM';
    lv_ship_date_to_n         CONSTANT VARCHAR2(100) := '納入日/出庫日TO';
    lv_arvl_date_from_n       CONSTANT VARCHAR2(100) := '入庫日FROM';
    lv_arvl_date_to_n         CONSTANT VARCHAR2(100) := '入庫日TO';
    lv_inst_dept_n            CONSTANT VARCHAR2(100) := '指示部署';
    lv_item_no_n              CONSTANT VARCHAR2(100) := '品目';
    lv_upd_time_from_n        CONSTANT VARCHAR2(100) := '更新日時FROM';
    lv_upd_time_to_n          CONSTANT VARCHAR2(100) := '更新日時TO';
    lv_prod_class_n           CONSTANT VARCHAR2(100) := '商品区分';
    lv_item_class_n           CONSTANT VARCHAR2(100) := '品目区分';
    lv_sec_class_n            CONSTANT VARCHAR2(100) := 'セキュリティ区分';
    lv_max_date_name          CONSTANT VARCHAR2(100) := 'MAX日付';
    lv_min_date_name          CONSTANT VARCHAR2(100) := 'MIN日付';
--
    lv_min_time               CONSTANT VARCHAR2(8)   := '00:00:00';
    lv_max_time               CONSTANT VARCHAR2(8)   := '23:59:59';
--
    -- *** ローカル変数 ***
    lv_update_time_from       VARCHAR2(20);
    lv_update_time_to         VARCHAR2(20);
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
    -- 必須項目チェック
    -- 処理区分
    IF (iv_wf_ope_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_wf_ope_div_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 対象
    IF (iv_wf_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_wf_class_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 宛先
    IF (iv_wf_notification IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_wf_notification_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- データ種別
    IF (iv_data_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_data_class_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 納入日/出庫日FROM
    IF (iv_ship_date_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_ship_date_from_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 納入日/出庫日TO
    IF (iv_ship_date_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_ship_date_to_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- セキュリティ区分
    IF (iv_sec_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_sec_class_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 妥当性チェック
    -- データ種別
    IF ((iv_data_class <> gv_data_class_mov)
     AND (iv_data_class <> gv_data_class_oha)
     AND (iv_data_class <> gv_data_class_pha)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_06,
                                            gv_tkn_error_param,
                                            lv_data_class_n,
                                            gv_tkn_error_value,
                                            iv_data_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 納入日/出庫日
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--    gd_ship_date_to := FND_DATE.STRING_TO_DATE(iv_ship_date_to,'YYYY/MM/DD');
    gd_ship_date_to := FND_DATE.STRING_TO_DATE(iv_ship_date_to,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
    IF (gd_ship_date_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_03,
                                            gv_tkn_param_value,
                                            iv_ship_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--    gd_ship_date_from := FND_DATE.STRING_TO_DATE(iv_ship_date_from,'YYYY/MM/DD');
    gd_ship_date_from := FND_DATE.STRING_TO_DATE(iv_ship_date_from,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
    IF (gd_ship_date_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_03,
                                            gv_tkn_param_value,
                                            iv_ship_date_from);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gd_ship_date_from > gd_ship_date_to) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_04);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 入庫日
    IF (iv_arrival_date_to IS NOT NULL) THEN
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--      gd_arrival_date_to := FND_DATE.STRING_TO_DATE(iv_arrival_date_to,'YYYY/MM/DD');
      gd_arrival_date_to := FND_DATE.STRING_TO_DATE(iv_arrival_date_to,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
      IF (gd_arrival_date_to IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_arrival_date_to);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (iv_arrival_date_from IS NOT NULL) THEN
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--      gd_arrival_date_from := FND_DATE.STRING_TO_DATE(iv_arrival_date_from,'YYYY/MM/DD');
      gd_arrival_date_from := FND_DATE.STRING_TO_DATE(iv_arrival_date_from,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
      IF (gd_arrival_date_from IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_arrival_date_from);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF ((iv_arrival_date_from IS NOT NULL) AND (iv_arrival_date_to IS NOT NULL)) THEN
      IF (gd_arrival_date_from > gd_arrival_date_to) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF ((iv_req_no_from IS NOT NULL) AND (iv_req_no_to IS NOT NULL)) THEN
      IF (iv_req_no_from > iv_req_no_to) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 更新日時
    IF (iv_update_time_from IS NOT NULL) THEN
      lv_update_time_from := iv_update_time_from;
      IF (LENGTH(lv_update_time_from) = 10) THEN
        lv_update_time_from := lv_update_time_from || ' ' || lv_min_time;
      END IF;
      gd_update_time_from := FND_DATE.STRING_TO_DATE(lv_update_time_from,'YYYY/MM/DD HH24:MI:SS');
      IF (gd_update_time_from IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_update_time_from);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (iv_update_time_to IS NOT NULL) THEN
      lv_update_time_to   := iv_update_time_to;
      IF (LENGTH(lv_update_time_to) = 10) THEN
        lv_update_time_to := lv_update_time_to || ' ' || lv_max_time;
      END IF;
      gd_update_time_to   := FND_DATE.STRING_TO_DATE(lv_update_time_to,'YYYY/MM/DD HH24:MI:SS');
      IF (gd_update_time_to IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_update_time_to);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF ((iv_update_time_from IS NOT NULL) AND (iv_update_time_to IS NOT NULL)) THEN
      IF (gd_update_time_from > gd_update_time_to) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --最大日付取得
    gv_max_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_01,
                                            gv_tkn_name,
                                            lv_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --最小日付取得
    gv_min_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MIN_DATE'),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_01,
                                            gv_tkn_name,
                                            lv_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gn_user_id             := FND_GLOBAL.USER_ID;
    gd_sys_date            := SYSDATE;
--
    SELECT employee_id
    INTO   gn_person_id
    FROM   fnd_user
    WHERE  user_id = gn_user_id
    AND    ROWNUM = 1;
--
    gv_wf_ope_div        := iv_wf_ope_div;
    gv_wf_class          := iv_wf_class;
    gv_wf_notification   := iv_wf_notification;
    gv_data_class        := iv_data_class;
    gv_ship_no_from      := iv_ship_no_from;
    gv_ship_no_to        := iv_ship_no_to;
    gv_req_no_from       := iv_req_no_from;
    gv_req_no_to         := iv_req_no_to;
    gv_vendor_code       := iv_vendor_code;
    gv_mediation         := iv_mediation;
    gv_location_code     := iv_location_code;
    gv_arvl_code         := iv_arvl_code;
    gv_vendor_site_code  := iv_vendor_site_code;
    gv_carrier_code      := iv_carrier_code;
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--    gv_ship_date_from    := iv_ship_date_from;
--    gv_ship_date_to      := iv_ship_date_to;
--    gv_arrival_date_from := iv_arrival_date_from;
--    gv_arrival_date_to   := iv_arrival_date_to;
    gv_ship_date_from    := TO_CHAR(gd_ship_date_from, 'YYYY/MM/DD');
    gv_ship_date_to      := TO_CHAR(gd_ship_date_to, 'YYYY/MM/DD');
    gv_arrival_date_from := TO_CHAR(gd_arrival_date_from, 'YYYY/MM/DD');
    gv_arrival_date_to   := TO_CHAR(gd_arrival_date_to, 'YYYY/MM/DD');
-- 2009/02/04 v1.5 N.Yoshida Mod End
    gv_instruction_dept  := iv_instruction_dept;
    gv_item_no           := iv_item_no;
    gv_update_time_from  := iv_update_time_from;
    gv_update_time_to    := iv_update_time_to;
    gv_prod_class        := iv_prod_class;
    gv_item_class        := iv_item_class;
    gv_sec_class         := iv_sec_class;
--
    -- WFに関連する情報を取得
    xxcmn_common_pkg.get_outbound_info(
      gv_wf_ope_div,               -- 処理区分
      gv_wf_class,                 -- 対象
      gv_wf_notification,          -- 宛先
      gr_outbound_rec,             -- outbound関連データ
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- パラメータ出力
    parameter_disp(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
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
--#####################################  固定部 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : pha_sel_proc
   * Description      : 発注情報検索処理(D-3)
   ***********************************************************************************/
  PROCEDURE pha_sel_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pha_sel_proc'; -- プログラム名
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
    mst_rec         masters_rec;
    ln_cnt          NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
/* 2008/09/02 Mod ↓
      SELECT pha.po_header_id as sel_tbl_id                 -- テーブルID
2008/09/02 Mod ↑ */
      SELECT TO_CHAR(pha.po_header_id) || '1' as sel_tbl_id -- テーブルID
            ,gv_company_name as company_name                -- 会社名
            ,gv_data_class_pha as data_class                -- データ種別
            ,NULL as ship_no                                -- 配送No.
            ,pha.segment1 as request_no                     -- 依頼No.
            ,pha.attribute9 as relation_no                  -- 関連No.
            ,NULL as base_request_no                        -- コピー元No.    2008/09/02 Add
            ,NULL as base_ship_no                           -- 元配送No.
            ,xvv1.segment1 as vendor_code                   -- 取引先コード
            ,xvv1.vendor_full_name as vendor_name           -- 取引先名
            ,xvv1.vendor_short_name as vendor_s_name        -- 取引先略名
            ,xvv2.segment1 as mediation_code                -- 斡旋者コード
            ,xvv2.vendor_full_name as mediation_name        -- 斡旋者名
            ,xvv2.vendor_short_name as mediation_s_name     -- 斡旋者略名
            ,pha.attribute5 as whse_code                    -- 倉庫コード
            ,xilv.description as whse_name                  -- 倉庫名
            ,xilv.short_name as whse_s_name                 -- 倉庫略名
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    pha.attribute7,
                    NULL) as vendor_site_code               -- 配送先コード
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.party_site_full_name,
                    NULL) as vendor_site_name               -- 配送先名
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.party_site_short_name,
                    NULL) as vendor_site_s_name             -- 配送先略名
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.zip,
                    NULL) as zip                            -- 郵便番号
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.address_line1||xpsv.address_line2,
                    NULL) as address                        -- 住所
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.phone,
                    NULL) as phone                          -- 電話番号
            ,NULL as carrier_code                           -- 運送業者コード
            ,NULL as carrier_name                           -- 運送業者名
            ,NULL as carrier_s_name                         -- 運送業者略名
            ,pha.attribute4 as ship_date                    -- 出庫日
            ,pha.attribute4 as arrival_date                 -- 入庫日
            ,NULL as arrival_time_from                      -- 着荷時間FROM
            ,NULL as arrival_time_to                        -- 着荷時間TO
            ,NULL as method_code                            -- 配送区分
            ,NULL as div_a                                  -- 区分Ａ(運賃区分)
            ,pha.attribute6 as div_b                        -- 区分Ｂ(直送区分)
            ,NULL as div_c                                  -- 区分Ｃ(重量容積区分)
            ,pha.attribute10 as instruction_dept            -- 指示部署コード
            ,xpha.requested_department_code as request_dept -- 依頼部署コード
            ,pha.attribute1 as status                       -- ステータス
            ,NULL as notif_status                           -- 通知ステータス
            ,pha.attribute11 as div_d                       -- 区分Ｄ(発注区分)
            ,pha.attribute2 as div_e                        -- 区分Ｅ(仕入先承諾要求区分)
            ,xpha.order_approved_flg as div_f               -- 区分Ｆ(発注承諾フラグ)
            ,xpha.purchase_approved_flg as div_g            -- 区分Ｇ(仕入承諾フラグ)
            ,xprh.change_flag as div_h                      -- 区分Ｈ(変更フラグ)
            ,NULL as info_a                                 -- 情報Ａ
            ,NULL as info_b                                 -- 情報Ｂ
            ,NULL as info_c                                 -- 情報Ｃ
            ,NULL as info_d                                 -- 情報Ｄ
            ,NULL as info_e                                 -- 情報Ｅ
            ,pha.attribute15 as head_description            -- 摘要(ヘッダ)
            ,pla.attribute15 as line_description            -- 摘要(明細)
            ,pla.line_num                                   -- 明細No.
            ,ximv.item_no                                   -- 品目コード
            ,ximv.item_name                                 -- 品目名
            ,ximv.item_short_name as item_s_name            -- 品目略称
            ,pla.attribute3 as futai_code                   -- 付帯
            ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                    pla.attribute1,
                    NULL) as lot_no                         -- ロットNo
            ,ilm.attribute1 as lot_date                     -- 製造日
            ,ilm.attribute3 as best_bfr_date                -- 賞味期限
            ,ilm.attribute2 as lot_sign                     -- 固有記号
            ,pla.attribute11 as request_qty                 -- 依頼数
            ,pla.attribute11 as instruct_qty                -- 指示数
            ,pla.attribute6 as num_of_deliver               -- 出庫数
            ,pla.attribute7 as ship_to_qty                  -- 入庫数
            ,pla.attribute7 as fix_qty                      -- 確定数
            ,pla.attribute10 as item_um                     -- 単位
            ,NULL as weight_capacity                        -- 重量容積
            ,pla.attribute4 as frequent_qty                 -- 入数
            ,pla.attribute2 as frequent_factory             -- 工場コード
            ,pla.attribute13 as div_i                       -- 区分Ｉ(数量確定フラグ)
            ,pla.attribute14 as div_j                       -- 区分Ｊ(金額確定フラグ)
            ,pla.cancel_flag as div_k                       -- 区分Ｋ(取消フラグ)
            ,pla.attribute9 as designate_date               -- 日付指定
            ,ilm.attribute11 as info_f                      -- 情報Ｆ(年度)
            ,ilm.attribute12 as info_g                      -- 情報Ｇ(産地コード)
            ,ilm.attribute14 as info_h                      -- 情報Ｈ(Ｒ１)
            ,ilm.attribute15 as info_i                      -- 情報Ｉ(Ｒ２)
            ,ilm.attribute19 as info_j                      -- 情報Ｊ(Ｒ３)
            ,ilm.attribute20 as info_k                      -- 情報Ｋ(製造工場)
            ,ilm.attribute21 as info_l                      -- 情報Ｌ(製造ロット)
            ,plla.attribute10 as info_m                     -- 情報Ｍ(元品目コード)
            ,plla.attribute11 as info_n                     -- 情報Ｎ(元ロット)
            ,ilm.attribute9 as info_o                       -- 情報Ｏ(仕入形態)
            ,ilm.attribute10 as info_p                      -- 情報Ｐ(茶期区分)
            ,ilm.attribute13 as info_q                      -- 情報Ｑ(タイプ)
            ,pla.unit_price as amt_a                        -- お金Ａ(単価)
            ,plla.attribute1 as amt_b                       -- お金Ｂ(粉引率)
            ,plla.attribute2 as amt_c                       -- お金Ｃ(粉引後単価)
            ,plla.attribute3 as amt_d                       -- お金Ｄ(口銭区分)
            ,plla.attribute4 as amt_e                       -- お金Ｅ(口銭)
            ,plla.attribute5 as amt_f                       -- お金Ｆ(預り口銭金額)
            ,plla.attribute6 as amt_g                       -- お金Ｇ(賦課金区分)
            ,plla.attribute7 as amt_h                       -- お金Ｈ(賦課金)
            ,plla.attribute8 as amt_i                       -- お金Ｉ(賦課金額)
            ,plla.attribute9 as amt_j                       -- お金Ｊ(粉引後金額)
            ,pha.last_update_date as update_date_h          -- 最終更新日(ヘッダ)
            ,pla.last_update_date as update_date_l          -- 最終更新日(明細)
      FROM   po_headers_all           pha  -- 発注ヘッダ
            ,po_lines_all             pla  -- 発注明細
            ,po_line_locations_all    plla -- 発注納入明細
            ,xxpo_headers_all         xpha -- 発注ヘッダ(アドオン)
            ,ic_lots_mst              ilm  -- OPMロットマスタ
            ,xxpo_requisition_headers xprh -- 発注依頼ヘッダ(アドオン)
            ,xxcmn_item_mst2_v        ximv -- OPM品目情報VIEW2
            ,xxcmn_item_categories4_v xicv -- OPM品目カテゴリ割当情報VIEW4
            ,xxcmn_item_locations2_v  xilv -- OPM保管場所情報VIEW2
            ,xxcmn_vendors2_v         xvv1 -- 仕入先情報VIEW2
            ,xxcmn_vendors2_v         xvv2 -- 仕入先情報VIEW2
            ,xxcmn_party_sites2_v     xpsv -- パーティサイト情報VIEW2
      WHERE  pha.po_header_id      = pla.po_header_id
      AND    pla.po_line_id        = plla.po_line_id
      AND    pha.segment1          = xpha.po_header_number 
      AND    pha.segment1          = xprh.po_header_number(+)
      AND    pha.attribute5        = xilv.segment1
      AND    pla.item_id           = ximv.inventory_item_id
      AND    ximv.item_id          = xicv.item_id
      AND    pla.attribute1        = ilm.lot_no
      AND    ilm.item_id           = ximv.item_id
      AND    pha.vendor_id         = xvv1.vendor_id
      AND    pha.attribute3        = xvv2.vendor_id(+)
      AND    pha.attribute7        = xpsv.party_site_number(+)
-- ステータス
      -- 2008/07/30 Mod ↓
/*
      AND    NVL(pha.attribute1,gv_status_null) IN (
                 gv_xxpo_status_02                    -- 発注作成済:20
                ,gv_xxpo_status_03                    -- 受入あり:25
                ,gv_xxpo_status_04                    -- 数量確定済:30
                ,gv_xxpo_status_05                    -- 金額確定済:35
                ,gv_xxpo_status_06                    -- 取消:99
             )
*/
      AND    NVL(pha.attribute1,gv_status_null) >= gv_xxpo_status_02  -- 発注作成済:20以降
      -- 2008/07/30 Mod ↑
-- 依頼No
      AND    ((gv_req_no_from IS NULL) OR (pha.segment1 >= gv_req_no_from))
      AND    ((gv_req_no_to IS NULL)   OR (pha.segment1 <= gv_req_no_to))
-- 取引先
      AND    ((gv_vendor_code IS NULL) OR (xvv1.segment1 = gv_vendor_code))
-- 斡旋者
      AND    ((gv_mediation IS NULL) OR (xvv2.segment1 = gv_mediation))
-- 入庫倉庫
      AND    ((gv_arvl_code IS NULL) OR (pha.attribute5 = gv_arvl_code))
-- 納入日(必須)
      AND    pha.attribute4 >= gv_ship_date_from
      AND    pha.attribute4 <= gv_ship_date_to
-- 指示部署
      AND    ((gv_instruction_dept IS NULL) OR (pha.attribute10 = gv_instruction_dept))
-- 品目
      AND    ((gv_item_no IS NULL) OR (ximv.item_no = gv_item_no))
-- 更新日時
      AND    ((gd_update_time_from IS NULL) OR (pha.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (pha.last_update_date <= gd_update_time_to))
      AND    ((gd_update_time_from IS NULL) OR (pla.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (pla.last_update_date <= gd_update_time_to))
-- 商品区分
      AND    ((gv_prod_class IS NULL) OR (xicv.prod_class_code   = gv_prod_class))
-- 品目区分
      AND    ((gv_item_class IS NULL) OR (xicv.item_class_code   = gv_item_class))
-- OPM品目情報VIEW2
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') BETWEEN ximv.start_date_active
      AND     ximv.end_date_active
-- OPM保管場所情報VIEW2
      AND     xilv.date_from <= FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD')
      AND     (xilv.date_to >= FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD')
       OR      xilv.date_to IS NULL)
      AND     xilv.disable_date IS NULL
-- 仕入先情報VIEW2
      AND     xvv1.inactive_date IS NULL
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') BETWEEN xvv1.start_date_active
      AND     xvv1.end_date_active
-- 仕入先情報VIEW2
      AND     xvv2.inactive_date IS NULL
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') 
      BETWEEN NVL(xvv2.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xvv2.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- パーティサイト情報VIEW2
      AND     NVL(xpsv.party_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_acct_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_site_uses_status,gv_status_on) = gv_status_on
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') 
      BETWEEN NVL(xpsv.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xpsv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- セキュリティ区分
      AND    (
-- 伊藤園ユーザータイプ
              (gv_sec_class = gv_sec_class_home)
-- 取引先ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_vend
               AND    (xvv1.segment1 IN
                 (SELECT papf.attribute4           -- 取引先コード(仕入先コード)
                  FROM   fnd_user           fu              -- ユーザーマスタ
                        ,per_all_people_f   papf            -- 従業員マスタ
                  WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ユーザーID
                OR     xvv2.segment1 IN
                 (SELECT papf.attribute4           -- 取引先コード(仕入先コード)
                  FROM   fnd_user           fu              -- ユーザーマスタ
                        ,per_all_people_f   papf            -- 従業員マスタ
                  WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id))            -- ユーザーID
              )
-- 外部倉庫ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_extn
               AND    pha.attribute5 IN
                 (SELECT xilv.segment1                -- 保管倉庫コード
                  FROM   fnd_user               fu          -- ユーザーマスタ
                        ,per_all_people_f       papf        -- 従業員マスタ
                        ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- 仕入先コード
                  AND    fu.user_id                 = gn_user_id)            -- ユーザーID
              )
-- 東洋埠頭ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_quay
               AND    (
                       pha.attribute5 IN (
                          SELECT xilv.segment1                -- 保管倉庫コード
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
               OR      pha.attribute5 IN (
-- 2008/11/26 Mod ↓
-- 2008/07/30 Mod ↓
--                          SELECT xilv.frequent_whse           -- 代表倉庫
--                          SELECT xilv.frequent_whse_code      -- 主管倉庫
                          SELECT xilv2.segment1
-- 2008/07/30 Mod ↑
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    xilv.segment1              = xilv2.frequent_whse_code  -- 小倉庫の絞込み
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
-- 2008/11/26 Mod ↑
                      )
              )
             )
-- 2008/09/02 Mod ↓
/*
-- ソート順
      ORDER BY pha.attribute4                                      -- 入庫日
              ,xvv1.segment1                                       -- 取引先コード
              ,pha.attribute5                                      -- 倉庫コード
              ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                      pha.attribute7,NULL)                         -- 配送先コード
              ,pha.segment1                                        -- 依頼No.
              ,pla.line_num                                        -- 明細No.
              ,ximv.item_no                                        -- 品目コード
              ,pla.attribute3                                      -- 付帯コード
              ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                      pla.attribute1,NULL)                         -- ロット
              ,ilm.attribute1                                      -- 製造日
              ,ilm.attribute3                                      -- 賞味期限
              ,ilm.attribute2                                      -- 固有記号
*/
      UNION ALL
      SELECT xrart.rcv_rtn_number || '2' as sel_tbl_id      -- テーブルID
            ,gv_company_name as company_name                -- 会社名
            ,gv_data_class_pha as data_class                -- データ種別
            ,NULL as ship_no                                -- 配送No.
            ,xrart.supply_requested_number as request_no    -- 依頼No.
            ,xrart.source_document_number as relation_no    -- 関連No.
            ,NULL as base_request_no                        -- コピー元No.
            ,NULL as base_ship_no                           -- 元配送No.
            ,xvv.segment1 as vendor_code                    -- 取引先コード
            ,xvv.vendor_full_name as vendor_name            -- 取引先名
            ,xvv.vendor_short_name as vendor_s_name         -- 取引先略名
            ,DECODE(xrart.assen_vendor_id,NULL,
                    NULL,
                    xvv.segment1) as mediation_code         -- 斡旋者コード
            ,DECODE(xrart.assen_vendor_id,NULL,
                    NULL,
                    xvv.vendor_full_name) as mediation_name -- 斡旋者名
            ,DECODE(xrart.assen_vendor_id,NULL,
                    NULL,
                    xvv.segment1) as mediation_s_name       -- 斡旋者略名
            ,xrart.location_code as whse_code               -- 倉庫コード
            ,xilv.description as whse_name                  -- 倉庫名
            ,xilv.short_name as whse_s_name                 -- 倉庫略名
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xrart.delivery_code,
                    NULL) as vendor_site_code               -- 配送先コード
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.party_site_full_name,
                    NULL) as vendor_site_name               -- 配送先名
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.party_site_short_name,
                    NULL) as vendor_site_s_name             -- 配送先略名
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.zip,
                    NULL) as zip                            -- 郵便番号
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.address_line1||xpsv.address_line2,
                    NULL) as address                        -- 住所
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.phone,
                    NULL) as phone                          -- 電話番号
            ,NULL as carrier_code                           -- 運送業者コード
            ,NULL as carrier_name                           -- 運送業者名
            ,NULL as carrier_s_name                         -- 運送業者略名
            ,TO_CHAR(xrart.txns_date,'YYYY/MM/DD') as ship_date                   -- 出庫日
            ,TO_CHAR(xrart.txns_date,'YYYY/MM/DD') as arrival_dat                 -- 入庫日
            ,NULL as arrival_time_from                      -- 着荷時間FROM
            ,NULL as arrival_time_to                        -- 着荷時間TO
            ,NULL as method_code                            -- 配送区分
            ,NULL as div_a                                  -- 区分Ａ
            ,xrart.drop_ship_type as div_b                  -- 区分Ｂ
            ,NULL as div_c                                  -- 区分Ｃ
            ,xrart.department_code as instruction_dept      -- 指示部署コード
            ,NULL as request_dept                           -- 依頼部署コード
            ,NULL as status                                 -- ステータス
            ,NULL as notif_status                           -- 通知ステータス
            ,xrart.txns_type as div_d                       -- 区分Ｄ
            ,NULL as div_e                                  -- 区分Ｅ
            ,NULL as div_f                                  -- 区分Ｆ
            ,NULL as div_g                                  -- 区分Ｇ
            ,NULL as div_h                                  -- 区分Ｈ
            ,NULL as info_a                                 -- 情報Ａ
            ,NULL as info_b                                 -- 情報Ｂ
            ,NULL as info_c                                 -- 情報Ｃ
            ,NULL as info_d                                 -- 情報Ｄ
            ,NULL as info_e                                 -- 情報Ｅ
            ,xrart.header_description as head_description   -- 摘要(ヘッダ)
            ,xrart.line_description as line_description     -- 摘要(明細)
            ,xrart.rcv_rtn_line_number as line_num          -- 明細No.
            ,ximv.item_no                                   -- 品目コード
            ,ximv.item_name                                 -- 品目名
            ,ximv.item_short_name as item_s_name            -- 品目略称
            ,xrart.futai_code                               -- 付帯
            ,DECODE(ximv.lot_ctl,gv_lot_ctl_on, 
                    xrart.lot_number,
                    NULL) as lot_no                         -- ロットNo.
            ,ilm.attribute1 as lot_date                     -- 製造日
            ,ilm.attribute3 as best_bfr_date                -- 賞味期限
            ,ilm.attribute2 as lot_sign                     -- 固有記号
            ,TO_CHAR(xrart.rcv_rtn_quantity) as request_qty          -- 依頼数
            ,TO_CHAR(xrart.rcv_rtn_quantity) as instruct_qty         -- 指示数
            ,TO_CHAR(xrart.rcv_rtn_quantity) as num_of_deliver       -- 出庫数
            ,TO_CHAR(xrart.rcv_rtn_quantity) as ship_to_qty          -- 入庫数
            ,TO_CHAR(xrart.rcv_rtn_quantity) as fix_qty              -- 確定数
            ,xrart.rcv_rtn_uom as item_um                   -- 単位
            ,NULL as weight_capacity                        -- 重量容積
            ,TO_CHAR(xrart.conversion_factor) as frequent_qty        -- 入数
            ,xrart.factory_code as frequent_factory         -- 工場コード
            ,NULL as div_i                                  -- 区分Ｉ
            ,NULL as div_j                                  -- 区分Ｊ
            ,NULL as div_k                                  -- 区分Ｋ
            ,NULL as designate_date                         -- 日付指定
            ,ilm.attribute11 as info_f                      -- 情報Ｆ
            ,ilm.attribute12 as info_g                      -- 情報Ｇ
            ,ilm.attribute14 as info_h                      -- 情報Ｈ
            ,ilm.attribute15 as info_i                      -- 情報Ｉ
            ,ilm.attribute19 as info_j                      -- 情報Ｊ
            ,ilm.attribute20 as info_k                      -- 情報Ｋ
            ,ilm.attribute21 as info_l                      -- 情報Ｌ
            ,NULL as info_m                                 -- 情報Ｍ
            ,NULL as info_n                                 -- 情報Ｎ
            ,ilm.attribute9 as info_o                       -- 情報Ｏ
            ,ilm.attribute10 as info_p                      -- 情報Ｐ
            ,ilm.attribute13 as info_q                      -- 情報Ｑ
            ,xrart.unit_price as amt_a                      -- お金Ａ
            ,TO_CHAR(xrart.kobiki_rate) as amt_b                     -- お金Ｂ
            ,TO_CHAR(xrart.kobki_converted_unit_price) as amt_c      -- お金Ｃ
            ,xrart.kousen_type as amt_d                     -- お金Ｄ
            ,TO_CHAR(xrart.kousen_rate_or_unit_price) as amt_e       -- お金Ｅ
            ,TO_CHAR(xrart.kousen_price) as amt_f                    -- お金Ｆ
            ,xrart.fukakin_type as amt_g                    -- お金Ｇ
            ,TO_CHAR(xrart.fukakin_rate_or_unit_price) as amt_h      -- お金Ｈ
            ,TO_CHAR(xrart.fukakin_price) as amt_i                   -- お金Ｉ
            ,TO_CHAR(xrart.kobki_converted_price) as amt_j           -- お金Ｊ
            ,xrart.last_update_date as update_date_h        -- 最終更新日(ヘッダ)
            ,xrart.last_update_date as update_date_l        -- 最終更新日(明細)
      FROM   xxpo_rcv_and_rtn_txns    xrart  -- 受入返品実績(アドオン)
            ,xxcmn_vendors2_v         xvv    -- 仕入先情報VIEW
            ,xxcmn_item_locations2_v  xilv   -- OPM保管場所情報VIEW
            ,xxcmn_party_sites2_v     xpsv   -- パーティサイト情報VIEW
            ,xxcmn_item_mst2_v        ximv   -- OPM品目情報VIEW
            ,xxcmn_item_categories4_v xicv   -- OPM品目カテゴリ割当情報VIEW4
            ,ic_lots_mst              ilm    -- OPMロットマスタ
      WHERE  xrart.vendor_id       = xvv.vendor_id             -- 取引先ID
      AND    xrart.vendor_code     = xvv.segment1              -- 取引先コード
      AND    xrart.assen_vendor_id = xvv.vendor_id(+)          -- 仕入先ID
      AND    xrart.location_code   = xilv.segment1             -- 入出庫先コード
      AND    xrart.delivery_code   = xpsv.ship_to_no(+)        -- 配送先コード
      AND    xrart.item_id         = ximv.item_id              -- 品目ID
      AND    xrart.lot_id          = ilm.lot_id                -- ロットID
      AND    xrart.item_id         = ilm.item_id               -- 品目ID
      AND    ximv.item_id          = xicv.item_id
-- 依頼No
      AND    ((gv_req_no_from IS NULL) OR (xrart.supply_requested_number >= gv_req_no_from))
      AND    ((gv_req_no_to IS NULL)   OR (xrart.supply_requested_number <= gv_req_no_to))
-- 取引先
      AND    ((gv_vendor_code IS NULL) OR (xvv.segment1 = gv_vendor_code))
-- 斡旋者
      AND    ((gv_mediation IS NULL) OR (xrart.assen_vendor_code = gv_mediation))
-- 入庫倉庫
      AND    ((gv_arvl_code IS NULL) OR (xrart.location_code = gv_arvl_code))
-- 納入日(必須)
      AND    xrart.txns_date >= FND_DATE.STRING_TO_DATE(gv_ship_date_from,'YYYY/MM/DD')
      AND    xrart.txns_date <= FND_DATE.STRING_TO_DATE(gv_ship_date_to,'YYYY/MM/DD')
-- 指示部署
      AND    ((gv_instruction_dept IS NULL) OR (xrart.department_code = gv_instruction_dept))
-- 品目
      AND    ((gv_item_no IS NULL) OR (xrart.item_code = gv_item_no))
-- 更新日時
      AND    ((gd_update_time_from IS NULL) OR (xrart.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (xrart.last_update_date <= gd_update_time_to))
      AND    ((gd_update_time_from IS NULL) OR (xrart.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (xrart.last_update_date <= gd_update_time_to))
-- 商品区分
      AND    ((gv_prod_class IS NULL) OR (xicv.prod_class_code   = gv_prod_class))
-- 品目区分
      AND    ((gv_item_class IS NULL) OR (xicv.item_class_code   = gv_item_class))
-- OPM品目情報VIEW2
      AND     xrart.txns_date BETWEEN ximv.start_date_active AND ximv.end_date_active
-- OPM保管場所情報VIEW2
      AND     xilv.date_from <= xrart.txns_date
      AND     (xilv.date_to >= xrart.txns_date OR xilv.date_to IS NULL)
      AND     xilv.disable_date IS NULL
-- 仕入先情報VIEW2
      AND     xvv.inactive_date IS NULL
      AND     xrart.txns_date 
      BETWEEN NVL(xvv.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xvv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- パーティサイト情報VIEW2
      AND     NVL(xpsv.party_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_acct_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_site_uses_status,gv_status_on) = gv_status_on
      AND     xrart.txns_date 
      BETWEEN NVL(xpsv.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xpsv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- セキュリティ区分
      AND    (
-- 伊藤園ユーザータイプ
              (gv_sec_class = gv_sec_class_home)
-- 取引先ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_vend
               AND    xvv.segment1 IN
                 (SELECT papf.attribute4           -- 取引先コード(仕入先コード)
                  FROM   fnd_user           fu              -- ユーザーマスタ
                        ,per_all_people_f   papf            -- 従業員マスタ
                  WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ユーザーID
              )
-- 外部倉庫ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_extn
               AND    xrart.location_code IN
                 (SELECT xilv.segment1                -- 保管倉庫コード
                  FROM   fnd_user               fu          -- ユーザーマスタ
                        ,per_all_people_f       papf        -- 従業員マスタ
                        ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- 仕入先コード
                  AND    fu.user_id                 = gn_user_id)            -- ユーザーID
              )
-- 東洋埠頭ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_quay
               AND    (
                       xrart.location_code IN (
                          SELECT xilv.segment1                -- 保管倉庫コード
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
               OR      xrart.location_code IN (
-- 2008/11/26 Mod ↓
--                          SELECT xilv.frequent_whse_code      -- 主管倉庫
                          SELECT xilv2.segment1       -- 東洋埠頭子倉庫
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    xilv.segment1              = xilv2.frequent_whse_code   -- 子倉庫の絞込み
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
-- 2008/11/26 Mod ↑
                      )
              )
             )
-- ソート順
      ORDER BY 27,                   -- 入庫日
               9,                    -- 取引先コード
               15,                   -- 倉庫コード
               18,                   -- 配送先コード
               5,                    -- 依頼No.
               51,                   -- 明細No.
               52,                   -- 品目コード
               55,                   -- 付帯コード
               56,                   -- ロット
               57,                   -- 製造日
               58,                   -- 賞味期限
               59                    -- 固有記号
-- 2008/09/02 Mod ↑
      ;
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
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
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.sel_tbl_id         := lr_mst_data_rec.sel_tbl_id;         -- テーブルID
      mst_rec.company_name       := lr_mst_data_rec.company_name;       -- 会社名
      mst_rec.data_class         := lr_mst_data_rec.data_class;         -- データ種別
      mst_rec.ship_no            := lr_mst_data_rec.ship_no;            -- 配送No.
      mst_rec.request_no         := lr_mst_data_rec.request_no;         -- 依頼No.
      mst_rec.relation_no        := lr_mst_data_rec.relation_no;        -- 関連No.
      mst_rec.base_request_no    := lr_mst_data_rec.base_request_no;    -- コピー元No.   2008/09/02 Add
      mst_rec.base_ship_no       := lr_mst_data_rec.base_ship_no;       -- 元配送No.
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;        -- 取引先コード
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;        -- 取引先名
      mst_rec.vendor_s_name      := lr_mst_data_rec.vendor_s_name;      -- 取引先略名
      mst_rec.mediation_code     := lr_mst_data_rec.mediation_code;     -- 斡旋者コード
      mst_rec.mediation_name     := lr_mst_data_rec.mediation_name;     -- 斡旋者名
      mst_rec.mediation_s_name   := lr_mst_data_rec.mediation_s_name;   -- 斡旋者略名
      mst_rec.whse_code          := lr_mst_data_rec.whse_code;          -- 倉庫コード
      mst_rec.whse_name          := lr_mst_data_rec.whse_name;          -- 倉庫名
      mst_rec.whse_s_name        := lr_mst_data_rec.whse_s_name;        -- 倉庫略名
      mst_rec.vendor_site_code   := lr_mst_data_rec.vendor_site_code;   -- 配送先コード
      mst_rec.vendor_site_name   := lr_mst_data_rec.vendor_site_name;   -- 配送先名
      mst_rec.vendor_site_s_name := lr_mst_data_rec.vendor_site_s_name; -- 配送先略名
      mst_rec.zip                := lr_mst_data_rec.zip;                -- 郵便番号
      mst_rec.address            := lr_mst_data_rec.address;            -- 住所
      mst_rec.phone              := lr_mst_data_rec.phone;              -- 電話番号
      mst_rec.carrier_code       := lr_mst_data_rec.carrier_code;       -- 運送業者コード
      mst_rec.carrier_name       := lr_mst_data_rec.carrier_name;       -- 運送業者名
      mst_rec.carrier_s_name     := lr_mst_data_rec.carrier_s_name;     -- 運送業者略名
      mst_rec.v_ship_date        := lr_mst_data_rec.ship_date;          -- 出庫日
      mst_rec.v_arrival_date     := lr_mst_data_rec.arrival_date;       -- 入庫日
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;  -- 着荷時間FROM
      mst_rec.arrival_time_to    := lr_mst_data_rec.arrival_time_to;    -- 着荷時間TO
      mst_rec.method_code        := lr_mst_data_rec.method_code;        -- 配送区分
      mst_rec.div_a              := lr_mst_data_rec.div_a;              -- 区分Ａ
      mst_rec.div_b              := lr_mst_data_rec.div_b;              -- 区分Ｂ
      mst_rec.div_c              := lr_mst_data_rec.div_c;              -- 区分Ｃ
      mst_rec.instruction_dept   := lr_mst_data_rec.instruction_dept;   -- 指示部署コード
      mst_rec.request_dept       := lr_mst_data_rec.request_dept;       -- 依頼部署コード
      mst_rec.status             := lr_mst_data_rec.status;             -- ステータス
      mst_rec.notif_status       := lr_mst_data_rec.notif_status;       -- 通知ステータス
      mst_rec.div_d              := lr_mst_data_rec.div_d;              -- 区分Ｄ
      mst_rec.div_e              := lr_mst_data_rec.div_e;              -- 区分Ｅ
      mst_rec.div_f              := lr_mst_data_rec.div_f;              -- 区分Ｆ
      mst_rec.div_g              := lr_mst_data_rec.div_g;              -- 区分Ｇ
      mst_rec.div_h              := lr_mst_data_rec.div_h;              -- 区分Ｈ
      mst_rec.info_a             := lr_mst_data_rec.info_a;             -- 情報Ａ
      mst_rec.info_b             := lr_mst_data_rec.info_b;             -- 情報Ｂ
      mst_rec.info_c             := lr_mst_data_rec.info_c;             -- 情報Ｃ
      mst_rec.info_d             := lr_mst_data_rec.info_d;             -- 情報Ｄ
      mst_rec.info_e             := lr_mst_data_rec.info_e;             -- 情報Ｅ
      mst_rec.head_description   := lr_mst_data_rec.head_description;   -- 摘要(ヘッダ)
      mst_rec.line_description   := lr_mst_data_rec.line_description;   -- 摘要(明細)
      mst_rec.line_num           := lr_mst_data_rec.line_num;           -- 明細No.
      mst_rec.item_no            := lr_mst_data_rec.item_no;            -- 品目コード
      mst_rec.item_name          := lr_mst_data_rec.item_name;          -- 品目名
      mst_rec.item_s_name        := lr_mst_data_rec.item_s_name;        -- 品目略名
      mst_rec.futai_code         := lr_mst_data_rec.futai_code;         -- 付帯
      mst_rec.lot_no             := lr_mst_data_rec.lot_no;             -- ロットNo
      mst_rec.v_lot_date         := lr_mst_data_rec.lot_date;           -- 製造日
      mst_rec.v_best_bfr_date    := lr_mst_data_rec.best_bfr_date;      -- 賞味期限
      mst_rec.lot_sign           := SUBSTR(lr_mst_data_rec.lot_sign,1,6); -- 固有記号
      mst_rec.request_qty        := TO_NUMBER(lr_mst_data_rec.request_qty);        -- 依頼数
      mst_rec.instruct_qty       := TO_NUMBER(lr_mst_data_rec.instruct_qty);       -- 指示数
      mst_rec.num_of_deliver     := TO_NUMBER(lr_mst_data_rec.num_of_deliver);     -- 出庫数
      mst_rec.ship_to_qty        := TO_NUMBER(lr_mst_data_rec.ship_to_qty);        -- 入庫数
      mst_rec.fix_qty            := TO_NUMBER(lr_mst_data_rec.fix_qty);            -- 確定数
      mst_rec.item_um            := SUBSTR(lr_mst_data_rec.item_um,1,3);  -- 単位
      mst_rec.weight_capacity    := TO_NUMBER(lr_mst_data_rec.weight_capacity);    -- 重量容積
      mst_rec.frequent_qty       := TO_NUMBER(lr_mst_data_rec.frequent_qty);       -- 入数
      mst_rec.frequent_factory   := SUBSTR(lr_mst_data_rec.frequent_factory,1,4); -- 工場コード
      mst_rec.div_i              := SUBSTR(lr_mst_data_rec.div_i,1,1);  -- 区分Ｉ
      mst_rec.div_j              := SUBSTR(lr_mst_data_rec.div_j,1,1);  -- 区分Ｊ
      mst_rec.div_k              := lr_mst_data_rec.div_k;              -- 区分Ｋ
      mst_rec.v_designate_date   := lr_mst_data_rec.designate_date;     -- 日付指定
/* 2008/08/20 Mod ↓
      mst_rec.amt_a              := lr_mst_data_rec.amt_a;              -- お金Ａ
2008/08/20 Mod ↑ */
      mst_rec.update_date_h      := lr_mst_data_rec.update_date_h;      -- 最終更新日(ヘッダ)
      mst_rec.update_date_l      := lr_mst_data_rec.update_date_l;      -- 最終更新日(明細)
--
      -- 伊藤園ユーザー、取引先ユーザー
      IF (gv_sec_class IN (gv_sec_class_home,gv_sec_class_vend)) THEN
        mst_rec.info_f             := SUBSTR(lr_mst_data_rec.info_f,1,4);  -- 情報Ｆ
        mst_rec.info_g             := SUBSTR(lr_mst_data_rec.info_g,1,2);  -- 情報Ｇ
        mst_rec.info_h             := SUBSTR(lr_mst_data_rec.info_h,1,10); -- 情報Ｈ
        mst_rec.info_i             := SUBSTR(lr_mst_data_rec.info_i,1,10); -- 情報Ｉ
        mst_rec.info_j             := SUBSTR(lr_mst_data_rec.info_j,1,10); -- 情報Ｊ
        mst_rec.info_k             := SUBSTR(lr_mst_data_rec.info_k,1,10); -- 情報Ｋ
        mst_rec.info_l             := SUBSTR(lr_mst_data_rec.info_l,1,10); -- 情報Ｌ
        mst_rec.info_m             := SUBSTR(lr_mst_data_rec.info_m,1,7);  -- 情報Ｍ
        mst_rec.info_n             := SUBSTR(lr_mst_data_rec.info_n,1,10); -- 情報Ｎ
        mst_rec.info_o             := SUBSTR(lr_mst_data_rec.info_o,1,2);  -- 情報Ｏ
        mst_rec.info_p             := SUBSTR(lr_mst_data_rec.info_p,1,2);  -- 情報Ｐ
        mst_rec.info_q             := SUBSTR(lr_mst_data_rec.info_q,1,2);  -- 情報Ｑ
        mst_rec.amt_a              := SUBSTR(lr_mst_data_rec.amt_a,1,20);  -- お金Ａ 2008/08/20 Mod
        mst_rec.amt_b              := SUBSTR(lr_mst_data_rec.amt_b,1,20);  -- お金Ｂ
        mst_rec.amt_c              := SUBSTR(lr_mst_data_rec.amt_c,1,20);  -- お金Ｃ
        mst_rec.amt_d              := SUBSTR(lr_mst_data_rec.amt_d,1,20);  -- お金Ｄ
        mst_rec.amt_e              := SUBSTR(lr_mst_data_rec.amt_e,1,20);  -- お金Ｅ
        mst_rec.amt_f              := SUBSTR(lr_mst_data_rec.amt_f,1,20);  -- お金Ｆ
        mst_rec.amt_g              := SUBSTR(lr_mst_data_rec.amt_g,1,20);  -- お金Ｇ
        mst_rec.amt_h              := SUBSTR(lr_mst_data_rec.amt_h,1,20);  -- お金Ｈ
        mst_rec.amt_i              := SUBSTR(lr_mst_data_rec.amt_i,1,20);  -- お金Ｉ
        mst_rec.amt_j              := SUBSTR(lr_mst_data_rec.amt_j,1,20);  -- お金Ｊ
--
      ELSE
        mst_rec.info_f             := NULL;              -- 情報Ｆ
        mst_rec.info_g             := NULL;              -- 情報Ｇ
        mst_rec.info_h             := NULL;              -- 情報Ｈ
        mst_rec.info_i             := NULL;              -- 情報Ｉ
        mst_rec.info_j             := NULL;              -- 情報Ｊ
        mst_rec.info_k             := NULL;              -- 情報Ｋ
        mst_rec.info_l             := NULL;              -- 情報Ｌ
        mst_rec.info_m             := NULL;              -- 情報Ｍ
        mst_rec.info_n             := NULL;              -- 情報Ｎ
        mst_rec.info_o             := NULL;              -- 情報Ｏ
        mst_rec.info_p             := NULL;              -- 情報Ｐ
        mst_rec.info_q             := NULL;              -- 情報Ｑ
        mst_rec.amt_a              := NULL;              -- お金Ａ 2008/08/20 Mod
        mst_rec.amt_b              := NULL;              -- お金Ｂ
        mst_rec.amt_c              := NULL;              -- お金Ｃ
        mst_rec.amt_d              := NULL;              -- お金Ｄ
        mst_rec.amt_e              := NULL;              -- お金Ｅ
        mst_rec.amt_f              := NULL;              -- お金Ｆ
        mst_rec.amt_g              := NULL;              -- お金Ｇ
        mst_rec.amt_h              := NULL;              -- お金Ｈ
        mst_rec.amt_i              := NULL;              -- お金Ｉ
        mst_rec.amt_j              := NULL;              -- お金Ｊ
      END IF;
--
      -- 数値、日付を文字列に変換する
      mst_rec.v_update_date_h := TO_CHAR(mst_rec.update_date_h,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_update_date_l := TO_CHAR(mst_rec.update_date_l,'YYYY/MM/DD HH24:MI:SS');
--
      gt_master_tbl(ln_cnt) := mst_rec;
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END pha_sel_proc;
--
  /**********************************************************************************
   * Procedure Name   : oha_sel_proc
   * Description      : 支給情報検索処理(D-4)
   ***********************************************************************************/
  PROCEDURE oha_sel_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'oha_sel_proc'; -- プログラム名
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
    mst_rec         masters_rec;
    ln_cnt          NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
      SELECT xoha.order_header_id as sel_tbl_id                -- テーブルID
            ,gv_company_name as company_name                   -- 会社名
            ,gv_data_class_oha as data_class                   -- データ種別
            ,xoha.delivery_no as ship_no                       -- 配送No.
            ,xoha.request_no                                   -- 依頼No.
            ,DECODE(xotv.transaction_type_name,gv_transaction_type_name,
                    xoha.po_no,
                    NULL) as relation_no                       -- 関連No.
            ,xoha.base_request_no                              -- コピー元No.    2008/09/02 Add
            ,xoha.prev_delivery_no as base_ship_no             -- 元配送No.
            ,xoha.vendor_code                                  -- 取引先コード
            ,xvv.vendor_full_name as vendor_name               -- 取引先名
            ,xvv.vendor_short_name as vendor_s_name            -- 取引先略名
            ,NULL as mediation_code                            -- 斡旋者コード
            ,NULL as mediation_name                            -- 斡旋者名
            ,NULL as mediation_s_name                          -- 斡旋者略名
            ,xoha.deliver_from as whse_code                    -- 倉庫コード
            ,xilv.whse_name as whse_name                       -- 倉庫名
            ,xilv.short_name as whse_s_name                    -- 倉庫略名
            ,xoha.vendor_site_code                             -- 配送先コード
            ,xvsv.vendor_site_name                             -- 配送先名
            ,xvsv.vendor_site_short_name as vendor_site_s_name -- 配送先略名
            ,xvsv.zip                                          -- 郵便番号
            ,xvsv.address_line1||xvsv.address_line2 as address -- 住所
            ,xvsv.phone                                        -- 電話番号
            ,NVL(xoha.result_freight_carrier_code,
                 xoha.freight_carrier_code) as carrier_code    -- 運送業者コード
            ,xcv.party_name as carrier_name                    -- 運送業者名
            ,xcv.party_short_name as carrier_s_name            -- 運送業者略名
            ,NVL(xoha.shipped_date,
                 xoha.schedule_ship_date) as ship_date         -- 出庫日(YYYY/MM/DD)
            ,NVL(xoha.arrival_date,
                 xoha.schedule_arrival_date) as arrival_date   -- 入庫日(YYYY/MM/DD)
            ,xoha.arrival_time_from                            -- 着荷時間FROM
            ,xoha.arrival_time_to                              -- 着荷時間TO
            ,NVL(xoha.result_shipping_method_code,
                 xoha.shipping_method_code) as method_code     -- 配送区分
            ,xoha.freight_charge_class as div_a                -- 区分Ａ
            ,xoha.takeback_class as div_b                      -- 区分Ｂ
            ,xoha.weight_capacity_class as div_c               -- 区分Ｃ
            ,xoha.instruction_dept                             -- 指示部署コード
            ,xoha.performance_management_dept as request_dept  -- 依頼部署コード
            ,xoha.req_status as status                         -- ステータス
            ,xoha.notif_status                                 -- 通知ステータス
            ,xotv.transaction_type_name as div_d               -- 区分Ｄ
            ,NULL as div_e                                     -- 区分Ｅ
            ,NULL as div_f                                     -- 区分Ｆ
            ,NULL as div_g                                     -- 区分Ｇ
            ,xoha.new_modify_flg as div_h                      -- 区分Ｈ
            ,xoha.designated_production_date as info_a         -- 情報Ａ(製造日)
            ,xoha.designated_item_code as info_b               -- 情報Ｂ(製造品目コード)
            ,ximv2.item_name as info_c                         -- 情報Ｃ(製造品目名)
            ,ximv2.item_short_name as info_d                   -- 情報Ｄ(製造品目略名)
            ,xoha.designated_branch_no as info_e               -- 情報Ｅ(製造番号)
            ,xoha.shipping_instructions as head_description    -- 摘要(ヘッダ)
            ,xola.line_description                             -- 摘要(明細)
            ,NULL as line_num                                  -- 明細No.
            ,xola.shipping_item_code as item_no                -- 品目コード
            ,ximv1.item_name                                   -- 品目名
            ,ximv1.item_short_name as item_s_name              -- 品目略名
            ,xola.futai_code                                   -- 付帯
            ,xmldv.lot_no                                      -- ロットNo
            ,xmldv.lot_date                                    -- 製造日
            ,xmldv.best_bfr_date                               -- 賞味期限
            ,xmldv.lot_sign                                    -- 固有記号
            ,xola.based_request_quantity as request_qty        -- 依頼数
-- 2008/08/20 Mod ↓
/*
            ,xmldv.instruct_qty                                -- 指示数
            ,xmldv.num_of_deliver                              -- 出庫数
            ,xmldv.ship_to_qty                                 -- 入庫数
            ,xmldv.fix_qty                                     -- 確定数
*/
            ,DECODE(xmldv.lot_no,NULL,
                    xola.quantity,
                    xmldv.instruct_qty
                   ) as instruct_qty                           -- 指示数
            ,DECODE(xmldv.lot_no,NULL,
                    xola.shipped_quantity,
                    xmldv.num_of_deliver
                   ) as num_of_deliver                         -- 出庫数
            ,DECODE(xmldv.lot_no,NULL,
                    xola.ship_to_quantity,
                    xmldv.ship_to_qty
                   ) as ship_to_qty                            -- 入庫数
            ,DECODE(xmldv.lot_no,NULL,
                    xola.shipped_quantity,
                    xmldv.fix_qty
                   ) as fix_qty                                -- 確定数
-- 2008/08/20 Mod ↑
            ,xola.uom_code as item_um                          -- 単位
            ,DECODE(xoha.weight_capacity_class,
                    gv_weight_class,  xola.weight,
                    gv_capacity_class,xola.capacity,
                    NULL) as weight_capacity                   -- 重量容積
            ,DECODE(ximv1.lot_ctl,gv_lot_ctl_on,
                    xmldv.frequent_qty,
                    NULL
                   ) as frequent_qty                           -- 入数
            ,NULL as frequent_factory                          -- 工場コード
            ,NULL as div_i                                     -- 区分Ｉ
            ,NULL as div_j                                     -- 区分Ｊ
-- 2008/08/20 Mod ↓
/*
            ,NULL as div_k                                     -- 区分Ｋ
*/
            ,xola.delete_flag as div_k                         -- 区分Ｋ
-- 2008/08/20 Mod ↑
            ,NULL as designate_date                            -- 日付指定
            ,NULL as info_f                                    -- 情報Ｆ
            ,NULL as info_g                                    -- 情報Ｇ
            ,NULL as info_h                                    -- 情報Ｈ
            ,NULL as info_i                                    -- 情報Ｉ
            ,NULL as info_j                                    -- 情報Ｊ
            ,NULL as info_k                                    -- 情報Ｋ
            ,NULL as info_l                                    -- 情報Ｌ
            ,NULL as info_m                                    -- 情報Ｍ
            ,NULL as info_n                                    -- 情報Ｎ
            ,NULL as info_o                                    -- 情報Ｏ
            ,NULL as info_p                                    -- 情報Ｐ
            ,NULL as info_q                                    -- 情報Ｑ
            ,xola.unit_price as amt_a                          -- お金Ａ
            ,NULL as amt_b                                     -- お金Ｂ
            ,NULL as amt_c                                     -- お金Ｃ
            ,NULL as amt_d                                     -- お金Ｄ
            ,NULL as amt_e                                     -- お金Ｅ
            ,NULL as amt_f                                     -- お金Ｆ
            ,NULL as amt_g                                     -- お金Ｇ
            ,NULL as amt_h                                     -- お金Ｈ
            ,NULL as amt_i                                     -- お金Ｉ
            ,NULL as amt_j                                     -- お金Ｊ
            ,xoha.last_update_date as update_date_h            -- 更新日時(ヘッダ)
            ,xola.last_update_date as update_date_l            -- 更新日時(明細)
      FROM   xxwsh_order_headers_all       xoha   -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all         xola   -- 受注明細アドオン
            ,(
              SELECT xmld.mov_line_id
                    ,xmld.lot_id
                    ,xmld.item_id
                    ,ilm.attribute1 as lot_date                        -- 製造日
                    ,ilm.attribute3 as best_bfr_date                   -- 賞味期限
                    ,ilm.attribute2 as lot_sign                        -- 固有記号
                    ,ilm.attribute6 as frequent_qty                    -- 入数
                    ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                            ilm.lot_no,
                            NULL) as lot_no                            -- ロットNo
-- 2008/08/20 Mod ↓
/*
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_10,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as instruct_qty                         -- 指示数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as num_of_deliver                       -- 出庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_30,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as ship_to_qty                          -- 入庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as fix_qty                              -- 確定数
*/
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_10,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as instruct_qty                     -- 指示数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as num_of_deliver                   -- 出庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_30,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as ship_to_qty                      -- 入庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as fix_qty                          -- 確定数
-- 2008/08/20 Mod ↑
              FROM   xxinv_mov_lot_details         xmld   -- 移動ロット詳細(アドオン)
                    ,ic_lots_mst                   ilm    -- OPMロットマスタ
                    ,xxcmn_item_mst2_v             ximv   -- OPM品目情報VIEW2
              WHERE  xmld.lot_id          = ilm.lot_id(+)
              AND    xmld.item_id         = ilm.item_id(+)
              AND    xmld.item_id         = ximv.item_id
              GROUP BY xmld.mov_line_id
                      ,xmld.lot_id
                      ,xmld.item_id
                      ,ilm.lot_id
                      ,ilm.item_id
                      ,ilm.attribute1
                      ,ilm.attribute3
                      ,ilm.attribute2
                      ,ilm.attribute6
                      ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                              ilm.lot_no,
                              NULL)
             ) xmldv
            ,xxcmn_vendors2_v              xvv    -- 仕入先情報VIEW2
            ,xxcmn_vendor_sites2_v         xvsv   -- 仕入先サイト情報VIEW2
            ,xxcmn_item_locations2_v       xilv   -- OPM保管場所情報VIEW2
            ,xxcmn_item_mst2_v             ximv1  -- OPM品目情報VIEW2
            ,xxcmn_item_mst2_v             ximv2  -- OPM品目情報VIEW2
            ,xxcmn_item_categories4_v      xicv   -- OPM品目カテゴリ割当情報VIEW4
            ,xxcmn_carriers2_v             xcv    -- 運送業者情報VIEW2
            ,xxcmn_lookup_values2_v        xlvv   -- クイックコード情報VIEW2
            ,xxwsh_oe_transaction_types2_v xotv   -- 受注タイプ情報VIEW2
      WHERE xoha.order_header_id            = xola.order_header_id
      AND   xoha.order_type_id              = xotv.transaction_type_id
      AND   xotv.shipping_shikyu_class      = gv_shipping_shikyu_class
      AND   xotv.ship_sikyu_rcv_pay_ctg     IN (gv_rcv_pay_ctg_05             -- 有償返品:'05'
                                               ,gv_rcv_pay_ctg_06)            -- 仕入返品:'06'
      AND   xola.order_line_id              = xmldv.mov_line_id(+)
      AND   xola.shipping_inventory_item_id = ximv1.inventory_item_id
      AND   xoha.designated_item_id         = ximv2.inventory_item_id(+)
      AND   xlvv.lookup_code(+)             = NVL(xoha.result_shipping_method_code,
                                                  xoha.shipping_method_code)
      AND   xlvv.lookup_type(+)             = gv_ship_method
      AND   xoha.deliver_from               = xilv.segment1
      AND   xoha.vendor_site_id             = xvsv.vendor_site_id
      AND   xcv.party_number(+)             = NVL(xoha.result_freight_carrier_code,
                                                  xoha.freight_carrier_code)
      AND   xoha.vendor_id                  = xvv.vendor_id
      AND   xicv.item_id                    = ximv1.item_id
      AND   xoha.latest_external_flag       = gv_external_flag_on             -- 最新フラグ:'Y'
-- ステータス
      -- 2008/07/30 Mod ↓
/*
      AND    NVL(xoha.req_status,gv_status_null) IN (
              gv_xxwsh_status_05            -- 入力完了:06
             ,gv_xxwsh_status_06            -- 受領済:07
             ,gv_xxwsh_status_07            -- 取消:99
             )
*/
      AND    NVL(xoha.req_status,gv_status_null) >= gv_xxwsh_status_05     -- 入力完了:06以降
      -- 2008/07/30 Mod ↑
-- 配送No
      AND   ((gv_ship_no_from IS NULL) OR (xoha.delivery_no >= gv_ship_no_from))
      AND   ((gv_ship_no_to IS NULL)   OR (xoha.delivery_no <= gv_ship_no_to))
-- 依頼No
      AND   ((gv_req_no_from IS NULL) OR (xoha.request_no >= gv_req_no_from))
      AND   ((gv_req_no_to IS NULL)   OR (xoha.request_no <= gv_req_no_to))
-- 取引先
      AND   ((gv_vendor_code IS NULL) OR (xoha.vendor_code = gv_vendor_code))
-- 出庫倉庫
      AND   ((gv_location_code IS NULL) OR (xoha.deliver_from = gv_location_code))
-- 配送先
      AND   ((gv_vendor_site_code IS NULL) OR (xoha.vendor_site_code = gv_vendor_site_code))
-- 運送業者
      AND   ((gv_carrier_code IS NULL) OR (xoha.freight_carrier_code = gv_carrier_code))
-- 納入日/出庫日(必須)
      AND    NVL(xoha.shipped_date,xoha.schedule_ship_date) >= gd_ship_date_from
      AND    NVL(xoha.shipped_date,xoha.schedule_ship_date) <= gd_ship_date_to
-- 入庫日
      AND   ((gd_arrival_date_from IS NULL)
       OR    (NVL(xoha.arrival_date,xoha.schedule_arrival_date) >= gd_arrival_date_from))
      AND   ((gd_arrival_date_to IS NULL)
       OR    (NVL(xoha.arrival_date,xoha.schedule_arrival_date) <= gd_arrival_date_to))
-- 指示部署
      AND   ((gv_instruction_dept IS NULL) OR (xoha.instruction_dept = gv_instruction_dept))
-- 品目
      AND   ((gv_item_no IS NULL) OR (ximv1.item_no = gv_item_no))
-- 更新日時
      AND   ((gd_update_time_from IS NULL) OR (xoha.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xoha.last_update_date <= gd_update_time_to))
      AND   ((gd_update_time_from IS NULL) OR (xola.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xola.last_update_date <= gd_update_time_to))
-- 商品区分
      AND   ((gv_prod_class IS NULL) OR (xicv.prod_class_code       = gv_prod_class))
-- 品目区分
      AND   ((gv_item_class IS NULL) OR (xicv.item_class_code       = gv_item_class))
-- 受注タイプ情報VIEW2
      AND   TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xotv.start_date_active
      AND   NVL(xotv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- クイックコード情報VIEW2
      AND   (xlvv.lookup_code IS NULL
       OR   ((xlvv.start_date_active <= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
       OR      xlvv.start_date_active IS NULL)
      AND    (xlvv.end_date_active >= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
       OR      xlvv.end_date_active IS NULL)
      AND     xlvv.enabled_flag = gv_enabled_flag_on))
-- OPM品目情報VIEW(1)
      AND    TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN ximv1.start_date_active
      AND    ximv1.end_date_active
-- OPM品目情報VIEW(2)
      AND    (ximv2.inventory_item_id IS NULL
       OR    (TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN ximv2.start_date_active
      AND     ximv2.end_date_active))
-- 仕入先情報VIEW2
      AND    xvv.inactive_date IS NULL
      AND    TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xvv.start_date_active
      AND    xvv.end_date_active
-- OPM保管場所情報VIEW2
      AND    xilv.date_from <= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
      AND    (xilv.date_to >= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
       OR     xilv.date_to IS NULL)
      AND    xilv.disable_date IS NULL
-- 仕入先サイト情報VIEW2
      AND    xvsv.inactive_date IS NULL
      AND    TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xvsv.start_date_active
      AND    xvsv.end_date_active
-- 運送業者情報VIEW2
      AND    (xcv.party_number IS NULL
      OR      (TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xcv.start_date_active
      AND      xcv.end_date_active))
-- セキュリティ区分
      AND    (
-- 伊藤園ユーザータイプ
              (gv_sec_class = gv_sec_class_home)
-- 取引先ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_vend
               AND    xoha.vendor_code IN
                 (SELECT papf.attribute4              -- 取引先コード(仕入先コード)
                  FROM   fnd_user           fu              -- ユーザーマスタ
                        ,per_all_people_f   papf            -- 従業員マスタ
                  WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ユーザーID
              )
-- 外部倉庫ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_extn
               AND    xoha.deliver_from IN
                 (SELECT xilv.segment1                -- 保管倉庫コード
                  FROM   fnd_user               fu          -- ユーザーマスタ
                        ,per_all_people_f       papf        -- 従業員マスタ
                        ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- 仕入先コード
                  AND    fu.user_id                 = gn_user_id)            -- ユーザーID
              )
-- 東洋埠頭ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_quay
               AND    (
                       xoha.deliver_from IN (
                          SELECT xilv.segment1                -- 保管倉庫コード
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
               OR      xoha.deliver_from IN (
-- 2008/11/26 Mod ↓
-- 2008/07/30 Mod ↓
--                          SELECT xilv.frequent_whse           -- 代表倉庫
--                          SELECT xilv.frequent_whse_code      -- 主管倉庫
                          SELECT xilv2.segment1      -- 東洋埠頭子倉庫
-- 2008/07/30 Mod ↑
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    xilv.segment1              = xilv2.frequent_whse_code  -- 子倉庫の絞込み
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
-- 2008/11/26 Mod ↑
                      )
              )
             )
-- ソート順
      ORDER BY NVL(xoha.shipped_date,
                   xoha.schedule_ship_date)               -- 出庫日
              ,NVL(xoha.arrival_date,
                   xoha.schedule_arrival_date)            -- 入庫日
              ,xoha.deliver_from                          -- 倉庫コード
              ,xoha.vendor_code                           -- 取引先コード
              ,xoha.vendor_site_code                      -- 配送先コード
              ,xoha.delivery_no                           -- 配送No.
              ,xoha.request_no                            -- 依頼No.
              ,xoha.designated_branch_no                  -- 製造枝番
              ,xola.shipping_item_code                    -- 品目コード
              ,xola.futai_code                            -- 付帯コード
              ,xmldv.lot_no                               -- ロットNo
              ,xmldv.lot_date                             -- 製造日
              ,xmldv.best_bfr_date                        -- 賞味期限
              ,xmldv.lot_sign                             -- 固有記号
      ;
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
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
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.sel_tbl_id         := lr_mst_data_rec.sel_tbl_id;         -- テーブルID
      mst_rec.company_name       := lr_mst_data_rec.company_name;       -- 会社名
      mst_rec.data_class         := lr_mst_data_rec.data_class;         -- データ種別
      mst_rec.ship_no            := lr_mst_data_rec.ship_no;            -- 配送No.
      mst_rec.request_no         := lr_mst_data_rec.request_no;         -- 依頼No.
      mst_rec.relation_no        := lr_mst_data_rec.relation_no;        -- 関連No.
      mst_rec.base_request_no    := lr_mst_data_rec.base_request_no;    -- コピー元No.   2008/09/02 Add
      mst_rec.base_ship_no       := lr_mst_data_rec.base_ship_no;       -- 元配送No.
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;        -- 取引先コード
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;        -- 取引先名
      mst_rec.vendor_s_name      := lr_mst_data_rec.vendor_s_name;      -- 取引先略名
      mst_rec.mediation_code     := lr_mst_data_rec.mediation_code;     -- 斡旋者コード
      mst_rec.mediation_name     := lr_mst_data_rec.mediation_name;     -- 斡旋者名
      mst_rec.mediation_s_name   := lr_mst_data_rec.mediation_s_name;   -- 斡旋者略名
      mst_rec.whse_code          := lr_mst_data_rec.whse_code;          -- 倉庫コード
      mst_rec.whse_name          := lr_mst_data_rec.whse_name;          -- 倉庫名
      mst_rec.whse_s_name        := lr_mst_data_rec.whse_s_name;        -- 倉庫略名
      mst_rec.vendor_site_code   := lr_mst_data_rec.vendor_site_code;   -- 配送先コード
      mst_rec.vendor_site_name   := lr_mst_data_rec.vendor_site_name;   -- 配送先名
      mst_rec.vendor_site_s_name := lr_mst_data_rec.vendor_site_s_name; -- 配送先略名
      mst_rec.zip                := lr_mst_data_rec.zip;                -- 郵便番号
      mst_rec.address            := lr_mst_data_rec.address;            -- 住所
      mst_rec.phone              := lr_mst_data_rec.phone;              -- 電話番号
      mst_rec.carrier_code       := lr_mst_data_rec.carrier_code;       -- 運送業者コード
      mst_rec.carrier_name       := lr_mst_data_rec.carrier_name;       -- 運送業者名
      mst_rec.carrier_s_name     := lr_mst_data_rec.carrier_s_name;     -- 運送業者略名
      mst_rec.ship_date          := lr_mst_data_rec.ship_date;          -- 出庫日
      mst_rec.arrival_date       := lr_mst_data_rec.arrival_date;       -- 入庫日
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;  -- 着荷時間FROM
      mst_rec.arrival_time_to    := lr_mst_data_rec.arrival_time_to;    -- 着荷時間TO
      mst_rec.method_code        := lr_mst_data_rec.method_code;        -- 配送区分
      mst_rec.div_a              := lr_mst_data_rec.div_a;              -- 区分Ａ
      mst_rec.div_b              := lr_mst_data_rec.div_b;              -- 区分Ｂ
      mst_rec.div_c              := lr_mst_data_rec.div_c;              -- 区分Ｃ
      mst_rec.instruction_dept   := lr_mst_data_rec.instruction_dept;   -- 指示部署コード
      mst_rec.request_dept       := lr_mst_data_rec.request_dept;       -- 依頼部署コード
      mst_rec.status             := lr_mst_data_rec.status;             -- ステータス
      mst_rec.notif_status       := lr_mst_data_rec.notif_status;       -- 通知ステータス
      mst_rec.div_d              := lr_mst_data_rec.div_d;              -- 区分Ｄ
      mst_rec.div_e              := lr_mst_data_rec.div_e;              -- 区分Ｅ
      mst_rec.div_f              := lr_mst_data_rec.div_f;              -- 区分Ｆ
      mst_rec.div_g              := lr_mst_data_rec.div_g;              -- 区分Ｇ
      mst_rec.div_h              := lr_mst_data_rec.div_h;              -- 区分Ｈ
      mst_rec.info_a             := TO_CHAR(lr_mst_data_rec.info_a,'YYYY/MM/DD');  -- 情報Ａ
      mst_rec.info_b             := lr_mst_data_rec.info_b;             -- 情報Ｂ
      mst_rec.info_c             := lr_mst_data_rec.info_c;             -- 情報Ｃ
      mst_rec.info_d             := lr_mst_data_rec.info_d;             -- 情報Ｄ
      mst_rec.info_e             := lr_mst_data_rec.info_e;             -- 情報Ｅ
      mst_rec.head_description   := lr_mst_data_rec.head_description;   -- 摘要(ヘッダ)
      mst_rec.line_description   := lr_mst_data_rec.line_description;   -- 摘要(明細)
      mst_rec.line_num           := lr_mst_data_rec.line_num;           -- 明細No.
      mst_rec.item_no            := lr_mst_data_rec.item_no;            -- 品目コード
      mst_rec.item_name          := lr_mst_data_rec.item_name;          -- 品目名
      mst_rec.item_s_name        := lr_mst_data_rec.item_s_name;        -- 品目略名
      mst_rec.futai_code         := lr_mst_data_rec.futai_code;         -- 付帯
      mst_rec.lot_no             := lr_mst_data_rec.lot_no;             -- ロットNo
      mst_rec.v_lot_date         := lr_mst_data_rec.lot_date;           -- 製造日
      mst_rec.v_best_bfr_date    := lr_mst_data_rec.best_bfr_date;      -- 賞味期限
      mst_rec.lot_sign           := lr_mst_data_rec.lot_sign;           -- 固有記号
      mst_rec.request_qty        := lr_mst_data_rec.request_qty;        -- 依頼数
      mst_rec.instruct_qty       := lr_mst_data_rec.instruct_qty;       -- 指示数
      mst_rec.num_of_deliver     := lr_mst_data_rec.num_of_deliver;     -- 出庫数
      mst_rec.ship_to_qty        := lr_mst_data_rec.ship_to_qty;        -- 入庫数
      mst_rec.fix_qty            := lr_mst_data_rec.fix_qty;            -- 確定数
      mst_rec.item_um            := lr_mst_data_rec.item_um;            -- 単位
      mst_rec.weight_capacity    := lr_mst_data_rec.weight_capacity;    -- 重量容積
      mst_rec.frequent_qty       := TO_NUMBER(lr_mst_data_rec.frequent_qty); -- 入数
      mst_rec.frequent_factory   := lr_mst_data_rec.frequent_factory;   -- 工場コード
      mst_rec.div_i              := lr_mst_data_rec.div_i;              -- 区分Ｉ
      mst_rec.div_j              := lr_mst_data_rec.div_j;              -- 区分Ｊ
      mst_rec.div_k              := lr_mst_data_rec.div_k;              -- 区分Ｋ
      mst_rec.v_designate_date   := lr_mst_data_rec.designate_date;     -- 日付指定
-- 2008/08/20 Mod ↓
/*
      mst_rec.amt_a              := TO_CHAR(lr_mst_data_rec.amt_a);     -- お金Ａ
*/
      IF (gv_sec_class IN (gv_sec_class_home,gv_sec_class_vend)) THEN
        mst_rec.amt_a            := lr_mst_data_rec.amt_a;              -- お金Ａ
--
      ELSE
        mst_rec.amt_a            := NULL;              -- お金Ａ
      END IF;
-- 2008/08/20 Mod ↑
      mst_rec.update_date_h      := lr_mst_data_rec.update_date_h;      -- 最終更新日(ヘッダ)
      mst_rec.update_date_l      := lr_mst_data_rec.update_date_l;      -- 最終更新日(明細)
--
      -- 数値、日付を文字列に変換する
      mst_rec.v_ship_date       := TO_CHAR(mst_rec.ship_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.v_update_date_h   := TO_CHAR(mst_rec.update_date_h,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_update_date_l   := TO_CHAR(mst_rec.update_date_l,'YYYY/MM/DD HH24:MI:SS');
--
      gt_master_tbl(ln_cnt) := mst_rec;
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END oha_sel_proc;
--
  /**********************************************************************************
   * Procedure Name   : mov_sel_proc
   * Description      : 移動情報検索処理(D-5)
   ***********************************************************************************/
  PROCEDURE mov_sel_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_sel_proc'; -- プログラム名
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
    mst_rec         masters_rec;
    ln_cnt          NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
      SELECT xmrh.mov_hdr_id as sel_tbl_id                      -- テーブルID
            ,gv_company_name as company_name                    -- 会社名
            ,gv_data_class_mov as data_class                    -- データ種別
            ,xmrh.delivery_no as ship_no                        -- 配送No.
            ,xmrh.mov_num as request_no                         -- 依頼No.
            ,NULL as relation_no                                -- 関連No.
            ,NULL as base_request_no                            -- コピー元No.    2008/09/02 Add
            ,xmrh.prev_delivery_no as base_ship_no              -- 元配送No.
            ,NULL as vendor_code                                -- 取引先コード
            ,NULL as vendor_name                                -- 取引先名
            ,NULL as vendor_s_name                              -- 取引先略名
            ,NULL as mediation_code                             -- 斡旋者コード
            ,NULL as mediation_name                             -- 斡旋者名
            ,NULL as mediation_s_name                           -- 斡旋者略名
            ,xmrh.shipped_locat_code as whse_code               -- 倉庫コード
            ,xilv1.description as whse_name                     -- 倉庫名
            ,xilv1.short_name as whse_s_name                    -- 倉庫略名
            ,xmrh.ship_to_locat_code as vendor_site_code        -- 配送先コード
            ,xilv2.description as vendor_site_name              -- 配送先名
            ,xilv2.short_name as vendor_site_s_name             -- 配送先略名
            ,xlv.zip                                            -- 郵便番号
            ,xlv.address_line1 as address                       -- 住所
            ,xlv.phone                                          -- 電話番号
            ,NVL(xmrh.freight_carrier_code,
                 xmrh.actual_freight_carrier_code) as carrier_code -- 運送業者コード
            ,xcv.party_name as carrier_name                     -- 運送業者名
            ,xcv.party_short_name as carrier_s_name             -- 運送業者略名
            ,NVL(xmrh.actual_ship_date,
                 xmrh.schedule_ship_date) as ship_date          -- 出庫日(YYYY/MM/DD)
            ,NVL(xmrh.actual_arrival_date,
                 xmrh.schedule_arrival_date) as arrival_date    -- 入庫日(YYYY/MM/DD)
            ,xmrh.arrival_time_from                             -- 着荷時間FROM
            ,xmrh.arrival_time_to                               -- 着荷時間TO
            ,NVL(xmrh.actual_shipping_method_code,
                 xmrh.shipping_method_code) as method_code      -- 配送区分
            ,xmrh.freight_charge_class as div_a                 -- 区分Ａ(運賃区分)
            ,xmrh.no_cont_freight_class as div_b                -- 区分Ｂ(契約外運賃区分)
            ,xmrh.weight_capacity_class as div_c                -- 区分Ｃ(重量容積区分)
            ,xmrh.instruction_post_code as instruction_dept     -- 指示部署コード
            ,NULL as request_dept                               -- 依頼部署コード
            ,xmrh.status                                        -- ステータス
            ,xmrh.notif_status                                  -- 通知ステータス
            ,xmrh.mov_type as div_d                             -- 区分Ｄ(移動タイプ)
            ,NULL as div_e                                      -- 区分Ｅ
            ,NULL as div_f                                      -- 区分Ｆ
            ,NULL as div_g                                      -- 区分Ｇ
            ,xmrh.new_modify_flg as div_h                       -- 区分Ｈ(修正フラグ)
            ,xmrh.pallet_sum_quantity as info_a                 -- 情報Ａ(パレット使用枚数)
            ,xmrh.collected_pallet_qty as info_b                -- 情報Ｂ(パレット回収枚数)
            ,NULL as info_c                                     -- 情報Ｃ
            ,NULL as info_d                                     -- 情報Ｄ
            ,NULL as info_e                                     -- 情報Ｅ
            ,xmrh.description as head_description               -- 摘要(ヘッダ)
            ,NULL as line_description                           -- 摘要(明細)
            ,xmrl.line_number as line_num                       -- 明細No.
            ,xmrl.item_code as item_no                          -- 品目コード
            ,ximv.item_name                                     -- 品目名
            ,ximv.item_short_name as item_s_name                -- 品目略名
            ,NULL as futai_code                                 -- 付帯
            ,xmldv.lot_no                                       -- ロットNo
            ,xmldv.lot_date                                     -- 製造日
            ,xmldv.best_bfr_date                                -- 賞味期限
            ,xmldv.lot_sign                                     -- 固有記号
            ,xmrl.request_qty                                   -- 依頼数
-- 2008/08/20 Mod ↓
/*
            ,xmldv.instruct_qty                                 -- 指示数
            ,xmldv.num_of_deliver                               -- 出庫数
            ,xmldv.ship_to_qty                                  -- 入庫数
            ,xmldv.fix_qty                                      -- 確定数
*/
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.instruct_qty,
                    xmldv.instruct_qty
                   ) as instruct_qty                            -- 指示数
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.shipped_quantity,
                    xmldv.num_of_deliver
                   ) as num_of_deliver                          -- 出庫数
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.ship_to_quantity,
                    xmldv.ship_to_qty
                   ) as ship_to_qty                             -- 入庫数
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.shipped_quantity,
                    xmldv.fix_qty
                   ) as fix_qty                                 -- 確定数
-- 2008/08/20 Mod ↑
            ,xmrl.uom_code as item_um                           -- 単位
            ,DECODE(xmrh.weight_capacity_class,
                    gv_weight_class,xmrl.weight,
                    gv_capacity_class,xmrl.capacity,
                    NULL) as weight_capacity                    -- 重量容積
            ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                    xmldv.frequent_qty,
                    NULL) as frequent_qty                       -- 入数
            ,NULL as frequent_factory                           -- 工場コード
            ,NULL as div_i                                      -- 区分Ｉ
            ,NULL as div_j                                      -- 区分Ｊ
-- 2008/08/20 Mod ↓
/*
            ,NULL as div_k                                      -- 区分Ｋ
*/
-- 2008/08/20 Mod ↑
            ,xmrl.delete_flg as div_k                           -- 区分Ｋ
            ,xmrl.designated_production_date as designate_date  -- 日付指定
            ,NULL as info_f                                     -- 情報Ｆ(年度)
            ,NULL as info_g                                     -- 情報Ｇ(産地コード)
            ,NULL as info_h                                     -- 情報Ｈ(Ｒ１)
            ,NULL as info_i                                     -- 情報Ｉ(Ｒ２)
            ,NULL as info_j                                     -- 情報Ｊ(Ｒ３)
            ,NULL as info_k                                     -- 情報Ｋ(製造工場)
            ,NULL as info_l                                     -- 情報Ｌ(製造ロット)
            ,NULL as info_m                                     -- 情報Ｍ(元品目コード)
            ,NULL as info_n                                     -- 情報Ｎ(元ロット)
            ,NULL as info_o                                     -- 情報Ｏ(仕入形態)
            ,NULL as info_p                                     -- 情報Ｐ(茶期区分)
            ,NULL as info_q                                     -- 情報Ｑ(タイプ)
            ,NULL as amt_a                                      -- お金Ａ(単価)
            ,NULL as amt_b                                      -- お金Ｂ(粉引率)
            ,NULL as amt_c                                      -- お金Ｃ(粉引後単価)
            ,NULL as amt_d                                      -- お金Ｄ(口銭区分)
            ,NULL as amt_e                                      -- お金Ｅ(口銭)
            ,NULL as amt_f                                      -- お金Ｆ(預り口銭額)
            ,NULL as amt_g                                      -- お金Ｇ(賦課金区分)
            ,NULL as amt_h                                      -- お金Ｈ(賦課金)
            ,NULL as amt_i                                      -- お金Ｉ(賦課金額)
            ,NULL as amt_j                                      -- お金Ｊ(粉引後金額)
            ,xmrh.last_update_date as update_date_h             -- 更新日時(ヘッダ)
            ,xmrl.last_update_date as update_date_l             -- 更新日時(明細)
      FROM   xxinv_mov_req_instr_headers xmrh       -- 移動依頼/指示ヘッダ(アドオン)
            ,xxinv_mov_req_instr_lines   xmrl       -- 移動依頼/指示明細(アドオン)
            ,xxcmn_item_locations2_v     xilv1      -- OPM保管場所情報VIEW2
            ,xxcmn_item_locations2_v     xilv2      -- OPM保管場所情報VIEW2
            ,xxcmn_item_mst2_v           ximv       -- OPM品目情報VIEW2
            ,xxcmn_item_categories4_v    xicv       -- OPM品目カテゴリ割当情報VIEW4
            ,xxcmn_locations2_v          xlv        -- 事業所情報VIEW2
            ,xxcmn_carriers2_v           xcv        -- 運送業者情報VIEW2
            ,xxcmn_lookup_values2_v      xlvv       -- クイックコード情報VIEW2
            ,(
              SELECT xmld.mov_line_id
                    ,ilm.lot_id
                    ,ilm.item_id
                    ,ilm.attribute1 as lot_date                         -- 製造日
                    ,ilm.attribute3 as best_bfr_date                    -- 賞味期限
                    ,ilm.attribute2 as lot_sign                         -- 固有記号
                    ,ilm.attribute6 as frequent_qty                     -- 入数
                    ,DECODE(ximv2.lot_ctl,gv_lot_ctl_on,
                            ilm.lot_no,
                            NULL) as lot_no                             -- ロットNo
-- 2008/08/20 Mod ↓
/*
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_10,
                                xmld.actual_quantity,0)
                        ,0)) as instruct_qty                             -- 指示数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity,0)
                        ,0)) as num_of_deliver                           -- 出庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_30,
                                xmld.actual_quantity,0)
                        ,0)) as ship_to_qty                              -- 入庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity,0)
                        ,0)) as fix_qty                                  -- 確定数
*/
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_10,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as instruct_qty                          -- 指示数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as num_of_deliver                        -- 出庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_30,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as ship_to_qty                           -- 入庫数
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as fix_qty                               -- 確定数
-- 2008/08/20 Mod ↑
              FROM   xxinv_mov_lot_details xmld     -- 移動ロット詳細(アドオン)
                    ,ic_lots_mst           ilm      -- OPMロットマスタ
                    ,xxcmn_item_mst2_v     ximv2    -- OPM品目情報VIEW2
              WHERE  xmld.lot_id     = ilm.lot_id(+)
              AND    xmld.item_id    = ilm.item_id(+)
              AND    xmld.item_id    = ximv2.item_id
              AND    ((gd_update_time_from IS NULL)
                 OR   (xmld.last_update_date >= gd_update_time_from))
              AND    ((gd_update_time_to IS NULL)
                 OR   (xmld.last_update_date <= gd_update_time_to))
              GROUP BY xmld.mov_line_id
                      ,ilm.lot_id
                      ,ilm.item_id
                      ,ilm.attribute1
                      ,ilm.attribute3
                      ,ilm.attribute2
                      ,ilm.attribute6
                      ,DECODE(ximv2.lot_ctl,gv_lot_ctl_on,
                              ilm.lot_no,
                              NULL)
             ) xmldv
      WHERE  xmrh.mov_hdr_id           = xmrl.mov_hdr_id
      AND    xmrl.item_id              = ximv.item_id
      AND    ximv.item_id              = xicv.item_id
      AND    xcv.party_number(+)       = NVL(xmrh.actual_freight_carrier_code,
                                             xmrh.freight_carrier_code)
      AND    xmrh.shipped_locat_code   = xilv1.segment1
      AND    xmrh.ship_to_locat_code   = xilv2.segment1
      AND    xilv2.location_id         = xlv.location_id
      AND    xmrl.mov_line_id          = xmldv.mov_line_id(+)
      AND    xlvv.lookup_code(+)       = NVL(xmrh.actual_shipping_method_code,
                                             xmrh.shipping_method_code)
      AND    xlvv.lookup_type(+)       = gv_ship_method
-- ステータス
      -- 2008/07/30 Mod ↓
/*
      AND    NVL(xmrh.status,gv_status_null) IN (
              gv_xxinv_status_02                       -- 依頼済:02
             ,gv_xxinv_status_03                       -- 調整中:03
             ,gv_xxinv_status_04                       -- 出庫報告有:04
             ,gv_xxinv_status_05                       -- 入庫報告有:05
             ,gv_xxinv_status_06                       -- 入出庫報告有:06
             ,gv_xxinv_status_07                       -- 取消:99
      )
*/
      AND    NVL(xmrh.status,gv_status_null) >= gv_xxinv_status_02         -- 依頼済:02以降
      -- 2008/07/30 Mod ↑
-- 配送No
      AND   ((gv_ship_no_from IS NULL) OR (xmrh.delivery_no >= gv_ship_no_from))
      AND   ((gv_ship_no_to IS NULL)   OR (xmrh.delivery_no <= gv_ship_no_to))
-- 依頼No
      AND   ((gv_req_no_from IS NULL) OR (xmrh.mov_num >= gv_req_no_from))
      AND   ((gv_req_no_to IS NULL)   OR (xmrh.mov_num <= gv_req_no_to))
-- 出庫倉庫
      AND   ((gv_location_code IS NULL) OR (xmrh.shipped_locat_code = gv_location_code))
-- 入庫倉庫
      AND   ((gv_arvl_code IS NULL) OR (xmrh.ship_to_locat_code = gv_arvl_code))
-- 運送業者
      AND   ((gv_carrier_code IS NULL)
       OR    (NVL(xmrh.freight_carrier_code,xmrh.actual_freight_carrier_code) = gv_carrier_code))
-- 納入日/出庫日(必須)
      AND    NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date) >= gd_ship_date_from
      AND    NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date) <= gd_ship_date_to
-- 入庫日
      AND   ((gd_arrival_date_from IS NULL)
       OR    (NVL(xmrh.actual_arrival_date,xmrh.schedule_arrival_date) >= gd_arrival_date_from))
      AND   ((gd_arrival_date_to IS NULL)
       OR    (NVL(xmrh.actual_arrival_date,xmrh.schedule_arrival_date) <= gd_arrival_date_to))
-- 指示部署
      AND   ((gv_instruction_dept IS NULL) OR (xmrh.instruction_post_code = gv_instruction_dept))
-- 品目
      AND   ((gv_item_no IS NULL) OR (ximv.item_no = gv_item_no))
-- 更新日時
      AND   ((gd_update_time_from IS NULL) OR (xmrh.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xmrh.last_update_date <= gd_update_time_to))
      AND   ((gd_update_time_from IS NULL) OR (xmrl.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xmrl.last_update_date <= gd_update_time_to))
-- 商品区分
      AND   ((gv_prod_class IS NULL) OR (xicv.prod_class_code         = gv_prod_class))
-- 品目区分
      AND   ((gv_item_class IS NULL) OR (xicv.item_class_code         = gv_item_class))
-- クイックコード情報VIEW2
      AND   (xlvv.lookup_code IS NULL
       OR    ((xlvv.start_date_active <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR    xlvv.start_date_active IS NULL)
      AND    (xlvv.end_date_active   >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR     xlvv.end_date_active IS NULL)
      AND    xlvv.enabled_flag = gv_enabled_flag_on))
-- OPM品目情報VIEW2
      AND    TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date)) 
      BETWEEN ximv.start_date_active AND ximv.end_date_active
-- 運送業者情報VIEW2
      AND    (xcv.party_number IS NULL
       OR    (TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      BETWEEN xcv.start_date_active AND xcv.end_date_active))
-- OPM保管場所情報VIEW2
      AND    xilv1.date_from <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      AND    (xilv1.date_to  >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR     xilv1.date_to IS NULL)
      AND    xilv1.disable_date IS NULL
-- OPM保管場所情報VIEW2
      AND    xilv2.date_from <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      AND    (xilv2.date_to  >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR     xilv2.date_to IS NULL)
      AND    xilv2.disable_date IS NULL
-- 事業所情報VIEW2
      AND    xlv.inactive_date IS NULL
      AND    xlv.start_date_active <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      AND    xlv.end_date_active   >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
-- セキュリティ区分
      AND    (
-- 伊藤園ユーザータイプ
              (gv_sec_class = gv_sec_class_home)
-- 取引先ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_vend
               AND    xilv1.purchase_code IN
                 (SELECT papf.attribute4           -- 取引先コード(仕入先コード)
                  FROM   fnd_user           fu              -- ユーザーマスタ
                        ,per_all_people_f   papf            -- 従業員マスタ
                  WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ユーザーID
              )
-- 外部倉庫ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_extn
               AND    ((xmrh.shipped_locat_code IN  -- 出庫元保管場所
                 (SELECT xilv.segment1                -- 保管倉庫コード
                  FROM   fnd_user               fu          -- ユーザーマスタ
                        ,per_all_people_f       papf        -- 従業員マスタ
                        ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- 仕入先コード
                  AND    fu.user_id                 = gn_user_id))           -- ユーザーID
                OR    (xmrh.ship_to_locat_code IN  -- 入庫先保管場所
                 (SELECT xilv.segment1                -- 保管倉庫コード
                  FROM   fnd_user               fu          -- ユーザーマスタ
                        ,per_all_people_f       papf        -- 従業員マスタ
                        ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                  AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- 仕入先コード
                  AND    fu.user_id                 = gn_user_id)))          -- ユーザーID
              )
-- 東洋埠頭ユーザータイプ
       OR     (gv_sec_class = gv_sec_class_quay
               AND    ((
                       xmrh.shipped_locat_code IN (
                          SELECT xilv.segment1                -- 保管倉庫コード
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
               OR      xmrh.shipped_locat_code IN (
-- 2008/11/26 Mod ↓
-- 2008/07/30 Mod ↓
--                          SELECT xilv.frequent_whse           -- 代表倉庫
--                          SELECT xilv.frequent_whse_code      -- 主管倉庫
                          SELECT xilv2.segment1      -- 東洋埠頭子倉庫
-- 2008/07/30 Mod ↑
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    xilv.segment1              = xilv2.frequent_whse_code   -- 子倉庫絞込み
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
                      )
                OR    (
                       xmrh.ship_to_locat_code IN (
                          SELECT xilv.segment1                -- 保管倉庫コード
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
               OR      xmrh.ship_to_locat_code IN (
-- 2008/07/30 Mod ↓
--                          SELECT xilv.frequent_whse           -- 代表倉庫
--                          SELECT xilv.frequent_whse_code      -- 主管倉庫
                          SELECT xilv2.segment1      -- 東洋埠頭子倉庫
-- 2008/07/30 Mod ↑
                          FROM   fnd_user               fu          -- ユーザーマスタ
                                ,per_all_people_f       papf        -- 従業員マスタ
                                ,xxcmn_item_locations_v xilv        -- OPM保管場所情報VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM保管場所情報VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- 従業員ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- 適用終了日
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- 適用開始日
                          AND  ((fu.end_date               IS NULL)                 -- 適用終了日
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- 仕入先コード
                          AND    xilv.segment1              = xilv2.frequent_whse_code       -- 仕入先コード
                          AND    fu.user_id                 = gn_user_id            -- ユーザーID
                          )
-- 2008/11/26 Mod ↑
                      ))
              )
             )
-- ソート順
      ORDER BY NVL(xmrh.schedule_ship_date,
                   xmrh.actual_ship_date)                 -- 出庫日
              ,NVL(xmrh.schedule_arrival_date,
                   xmrh.actual_arrival_date)              -- 入庫日
              ,xmrh.shipped_locat_code                    -- 倉庫コード
              ,xmrh.ship_to_locat_code                    -- 配送先コード
              ,xmrh.delivery_no                           -- 配送No.
              ,xmrh.mov_num                               -- 依頼No.
              ,xmrl.line_number                           -- 明細No.
              ,xmrl.item_code                             -- 品目コード
              ,xmldv.lot_no                               -- ロットNo
              ,xmldv.lot_date                             -- 製造日
              ,xmldv.best_bfr_date                        -- 賞味期限
              ,xmldv.lot_sign                             -- 固有記号
      ;
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
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
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.sel_tbl_id         := lr_mst_data_rec.sel_tbl_id;         -- テーブルID
      mst_rec.company_name       := lr_mst_data_rec.company_name;       -- 会社名
      mst_rec.data_class         := lr_mst_data_rec.data_class;         -- データ種別
      mst_rec.ship_no            := lr_mst_data_rec.ship_no;            -- 配送No.
      mst_rec.request_no         := lr_mst_data_rec.request_no;         -- 依頼No.
      mst_rec.relation_no        := lr_mst_data_rec.relation_no;        -- 関連No.
      mst_rec.base_request_no    := lr_mst_data_rec.base_request_no;    -- コピー元No.   2008/09/02 Add
      mst_rec.base_ship_no       := lr_mst_data_rec.base_ship_no;       -- 元配送No.
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;        -- 取引先コード
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;        -- 取引先名
      mst_rec.vendor_s_name      := lr_mst_data_rec.vendor_s_name;      -- 取引先略名
      mst_rec.mediation_code     := lr_mst_data_rec.mediation_code;     -- 斡旋者コード
      mst_rec.mediation_name     := lr_mst_data_rec.mediation_name;     -- 斡旋者名
      mst_rec.mediation_s_name   := lr_mst_data_rec.mediation_s_name;   -- 斡旋者略名
      mst_rec.whse_code          := lr_mst_data_rec.whse_code;          -- 倉庫コード
      mst_rec.whse_name          := lr_mst_data_rec.whse_name;          -- 倉庫名
      mst_rec.whse_s_name        := lr_mst_data_rec.whse_s_name;        -- 倉庫略名
      mst_rec.vendor_site_code   := lr_mst_data_rec.vendor_site_code;   -- 配送先コード
      mst_rec.vendor_site_name   := lr_mst_data_rec.vendor_site_name;   -- 配送先名
      mst_rec.vendor_site_s_name := lr_mst_data_rec.vendor_site_s_name; -- 配送先略名
      mst_rec.zip                := lr_mst_data_rec.zip;                -- 郵便番号
      mst_rec.address            := lr_mst_data_rec.address;            -- 住所
      mst_rec.phone              := lr_mst_data_rec.phone;              -- 電話番号
      mst_rec.carrier_code       := lr_mst_data_rec.carrier_code;       -- 運送業者コード
      mst_rec.carrier_name       := lr_mst_data_rec.carrier_name;       -- 運送業者名
      mst_rec.carrier_s_name     := lr_mst_data_rec.carrier_s_name;     -- 運送業者略名
      mst_rec.ship_date          := lr_mst_data_rec.ship_date;          -- 出庫日
      mst_rec.arrival_date       := lr_mst_data_rec.arrival_date;       -- 入庫日
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;  -- 着荷時間FROM
      mst_rec.arrival_time_to    := lr_mst_data_rec.arrival_time_to;    -- 着荷時間TO
      mst_rec.method_code        := lr_mst_data_rec.method_code;        -- 配送区分
      mst_rec.div_a              := lr_mst_data_rec.div_a;              -- 区分Ａ
      mst_rec.div_b              := lr_mst_data_rec.div_b;              -- 区分Ｂ
      mst_rec.div_c              := lr_mst_data_rec.div_c;              -- 区分Ｃ
      mst_rec.instruction_dept   := lr_mst_data_rec.instruction_dept;   -- 指示部署コード
      mst_rec.request_dept       := lr_mst_data_rec.request_dept;       -- 依頼部署コード
      mst_rec.status             := lr_mst_data_rec.status;             -- ステータス
      mst_rec.notif_status       := lr_mst_data_rec.notif_status;       -- 通知ステータス
      mst_rec.div_d              := lr_mst_data_rec.div_d;              -- 区分Ｄ
      mst_rec.div_e              := lr_mst_data_rec.div_e;              -- 区分Ｅ
      mst_rec.div_f              := lr_mst_data_rec.div_f;              -- 区分Ｆ
      mst_rec.div_g              := lr_mst_data_rec.div_g;              -- 区分Ｇ
      mst_rec.div_h              := lr_mst_data_rec.div_h;              -- 区分Ｈ
      mst_rec.info_a             := lr_mst_data_rec.info_a;             -- 情報Ａ
      mst_rec.info_b             := lr_mst_data_rec.info_b;             -- 情報Ｂ
      mst_rec.info_c             := lr_mst_data_rec.info_c;             -- 情報Ｃ
      mst_rec.info_d             := lr_mst_data_rec.info_d;             -- 情報Ｄ
      mst_rec.info_e             := lr_mst_data_rec.info_e;             -- 情報Ｅ
      mst_rec.head_description   := lr_mst_data_rec.head_description;   -- 摘要(ヘッダ)
      mst_rec.line_description   := lr_mst_data_rec.line_description;   -- 摘要(明細)
      mst_rec.line_num           := lr_mst_data_rec.line_num;           -- 明細No.
      mst_rec.item_no            := lr_mst_data_rec.item_no;            -- 品目コード
      mst_rec.item_name          := lr_mst_data_rec.item_name;          -- 品目名
      mst_rec.item_s_name        := lr_mst_data_rec.item_s_name;        -- 品目略名
      mst_rec.futai_code         := lr_mst_data_rec.futai_code;         -- 付帯
      mst_rec.lot_no             := lr_mst_data_rec.lot_no;             -- ロットNo
      mst_rec.v_lot_date         := lr_mst_data_rec.lot_date;           -- 製造日
      mst_rec.v_best_bfr_date    := lr_mst_data_rec.best_bfr_date;      -- 賞味期限
      mst_rec.lot_sign           := lr_mst_data_rec.lot_sign;           -- 固有記号
      mst_rec.request_qty        := lr_mst_data_rec.request_qty;        -- 依頼数
      mst_rec.instruct_qty       := lr_mst_data_rec.instruct_qty;       -- 指示数
      mst_rec.num_of_deliver     := lr_mst_data_rec.num_of_deliver;     -- 出庫数
      mst_rec.ship_to_qty        := lr_mst_data_rec.ship_to_qty;        -- 入庫数
      mst_rec.fix_qty            := lr_mst_data_rec.fix_qty;            -- 確定数
      mst_rec.item_um            := lr_mst_data_rec.item_um;            -- 単位
      mst_rec.weight_capacity    := lr_mst_data_rec.weight_capacity;    -- 重量容積
      mst_rec.frequent_qty       := TO_NUMBER(lr_mst_data_rec.frequent_qty);       -- 入数
      mst_rec.frequent_factory   := lr_mst_data_rec.frequent_factory;   -- 工場コード
      mst_rec.div_i              := lr_mst_data_rec.div_i;              -- 区分Ｉ
      mst_rec.div_j              := lr_mst_data_rec.div_j;              -- 区分Ｊ
      mst_rec.div_k              := lr_mst_data_rec.div_k;              -- 区分Ｋ
-- 2008/08/20 Mod ↓
/*
      mst_rec.v_designate_date   := lr_mst_data_rec.designate_date;     -- 日付指定
*/
      mst_rec.designate_date     := lr_mst_data_rec.designate_date;     -- 日付指定
-- 2008/08/20 Mod ↑
      mst_rec.amt_a              := lr_mst_data_rec.amt_a;              -- お金Ａ
      mst_rec.update_date_h      := lr_mst_data_rec.update_date_h;      -- 最終更新日(ヘッダ)
      mst_rec.update_date_l      := lr_mst_data_rec.update_date_l;      -- 最終更新日(明細)
--
      -- 数値、日付を文字列に変換する
      mst_rec.v_ship_date       := TO_CHAR(mst_rec.ship_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.v_update_date_h   := TO_CHAR(mst_rec.update_date_h,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_update_date_l   := TO_CHAR(mst_rec.update_date_l,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_designate_date  := TO_CHAR(mst_rec.designate_date,'YYYY/MM/DD'); -- 2008/08/20 Add
--
      gt_master_tbl(ln_cnt) := mst_rec;
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END mov_sel_proc;
--
  /**********************************************************************************
   * Procedure Name   : put_csv_data
   * Description      : CSVファイルへのデータ出力
   ***********************************************************************************/
  PROCEDURE put_csv_data(
    if_file_hand IN            UTL_FILE.FILE_TYPE,
    ir_mst_rec   IN            masters_rec,
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_csv_data'; -- プログラム名
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
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
-- add start ver1.3
    cv_crlf         CONSTANT VARCHAR2(1)  := CHR(13); -- 改行コード
-- add end ver1.3
--
    -- *** ローカル変数 ***
    lv_data         VARCHAR2(5000);
    ln_num          NUMBER;
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
    -- データ作成
    lv_data := ir_mst_rec.company_name      || cv_sep_com ||                    -- 会社名
               ir_mst_rec.data_class        || cv_sep_com ||                    -- データ種別
               ir_mst_rec.v_seq_no          || cv_sep_com ||                    -- 伝送用枝番
               ir_mst_rec.ship_no           || cv_sep_com ||                    -- 配送No.
               ir_mst_rec.request_no        || cv_sep_com ||                    -- 依頼No.
               ir_mst_rec.relation_no       || cv_sep_com ||                    -- 関連No.
               ir_mst_rec.base_request_no   || cv_sep_com ||                    -- コピー元No.   2008/09/02 Add
               ir_mst_rec.base_ship_no      || cv_sep_com ||                    -- 元配送No.
               ir_mst_rec.vendor_code       || cv_sep_com ||                    -- 取引先コード
               replace_sep(ir_mst_rec.vendor_name       ) || cv_sep_com ||      -- 取引先名
               replace_sep(ir_mst_rec.vendor_s_name     ) || cv_sep_com ||      -- 取引先略名
               ir_mst_rec.mediation_code    || cv_sep_com ||                    -- 斡旋者コード
               replace_sep(ir_mst_rec.mediation_name    ) || cv_sep_com ||      -- 斡旋者名
               replace_sep(ir_mst_rec.mediation_s_name  ) || cv_sep_com ||      -- 斡旋者略名
               ir_mst_rec.whse_code         || cv_sep_com ||                    -- 倉庫コード
               replace_sep(ir_mst_rec.whse_name         ) || cv_sep_com ||      -- 倉庫名
               replace_sep(ir_mst_rec.whse_s_name       ) || cv_sep_com ||      -- 倉庫略名
               ir_mst_rec.vendor_site_code  || cv_sep_com ||                    -- 配送先コード
               replace_sep(ir_mst_rec.vendor_site_name  ) || cv_sep_com ||      -- 配送先名
               replace_sep(ir_mst_rec.vendor_site_s_name) || cv_sep_com ||      -- 配送先略名
               replace_sep(ir_mst_rec.zip               ) || cv_sep_com ||      -- 郵便番号
               replace_sep(ir_mst_rec.address           ) || cv_sep_com ||      -- 住所
               replace_sep(ir_mst_rec.phone             ) || cv_sep_com ||      -- 電話番号
               ir_mst_rec.carrier_code      || cv_sep_com ||                    -- 運送業者コード
               replace_sep(ir_mst_rec.carrier_name      ) || cv_sep_com ||      -- 運送業者名
               replace_sep(ir_mst_rec.carrier_s_name    ) || cv_sep_com ||      -- 運送業者略名
               ir_mst_rec.v_ship_date       || cv_sep_com ||                    -- 出庫日
               ir_mst_rec.v_arrival_date    || cv_sep_com ||                    -- 入庫日
               ir_mst_rec.arrival_time_from || cv_sep_com ||                    -- 着荷時間FROM
               ir_mst_rec.arrival_time_to   || cv_sep_com ||                    -- 着荷時間TO
               ir_mst_rec.method_code       || cv_sep_com ||                    -- 配送区分
               ir_mst_rec.div_a             || cv_sep_com ||                    -- 区分Ａ
               ir_mst_rec.div_b             || cv_sep_com ||                    -- 区分Ｂ
               ir_mst_rec.div_c             || cv_sep_com ||                    -- 区分Ｃ
               ir_mst_rec.instruction_dept  || cv_sep_com ||                    -- 指示部署コード
               ir_mst_rec.request_dept      || cv_sep_com ||                    -- 依頼部署コード
               ir_mst_rec.status            || cv_sep_com ||                    -- ステータス
               ir_mst_rec.notif_status      || cv_sep_com ||                    -- 通知ステータス
               replace_sep(ir_mst_rec.div_d             ) || cv_sep_com ||      -- 区分Ｄ
               ir_mst_rec.div_e             || cv_sep_com ||                    -- 区分Ｅ
               ir_mst_rec.div_f             || cv_sep_com ||                    -- 区分Ｆ
               ir_mst_rec.div_g             || cv_sep_com ||                    -- 区分Ｇ
               ir_mst_rec.div_h             || cv_sep_com ||                    -- 区分Ｈ
               ir_mst_rec.info_a            || cv_sep_com ||                    -- 情報Ａ
               ir_mst_rec.info_b            || cv_sep_com ||                    -- 情報Ｂ
               replace_sep(ir_mst_rec.info_c            ) || cv_sep_com ||      -- 情報Ｃ
               replace_sep(ir_mst_rec.info_d            ) || cv_sep_com ||      -- 情報Ｄ
               ir_mst_rec.info_e            || cv_sep_com ||                    -- 情報Ｅ
               replace_sep(ir_mst_rec.description       ) || cv_sep_com ||      -- 摘要
               ir_mst_rec.line_num          || cv_sep_com ||                    -- 明細No.
               ir_mst_rec.item_no           || cv_sep_com ||                    -- 品目コード
               replace_sep(ir_mst_rec.item_name         ) || cv_sep_com ||      -- 品目名
               replace_sep(ir_mst_rec.item_s_name       ) || cv_sep_com ||      -- 品目略名
               ir_mst_rec.futai_code        || cv_sep_com ||                    -- 付帯
               ir_mst_rec.lot_no            || cv_sep_com ||                    -- ロット
               ir_mst_rec.v_lot_date        || cv_sep_com ||                    -- 製造日
               ir_mst_rec.v_best_bfr_date   || cv_sep_com ||                    -- 賞味期限
               ir_mst_rec.lot_sign          || cv_sep_com ||                    -- 固有記号
               decimal_round_up(ir_mst_rec.request_qty,3)     || cv_sep_com ||  -- 依頼数
               decimal_round_up(ir_mst_rec.instruct_qty,3)    || cv_sep_com ||  -- 指示数
               decimal_round_up(ir_mst_rec.num_of_deliver,3)  || cv_sep_com ||  -- 出庫数
               decimal_round_up(ir_mst_rec.ship_to_qty,3)     || cv_sep_com ||  -- 入庫数
               decimal_round_up(ir_mst_rec.fix_qty,3)         || cv_sep_com ||  -- 確定数
               ir_mst_rec.item_um           || cv_sep_com ||                    -- 単位
               decimal_round_up(ir_mst_rec.weight_capacity,0) || cv_sep_com ||  -- 重量容積
               decimal_round_up(ir_mst_rec.frequent_qty,3)    || cv_sep_com ||  -- 入数
               ir_mst_rec.frequent_factory  || cv_sep_com ||                    -- 工場コード
               ir_mst_rec.div_i             || cv_sep_com ||                    -- 区分Ｉ
               ir_mst_rec.div_j             || cv_sep_com ||                    -- 区分Ｊ
               ir_mst_rec.div_k             || cv_sep_com ||                    -- 区分Ｋ
               ir_mst_rec.v_designate_date  || cv_sep_com ||                    -- 日付指定
               ir_mst_rec.info_f            || cv_sep_com ||                    -- 情報Ｆ
               ir_mst_rec.info_g            || cv_sep_com ||                    -- 情報Ｇ
               ir_mst_rec.info_h            || cv_sep_com ||                    -- 情報Ｈ
               ir_mst_rec.info_i            || cv_sep_com ||                    -- 情報Ｉ
               ir_mst_rec.info_j            || cv_sep_com ||                    -- 情報Ｊ
               ir_mst_rec.info_k            || cv_sep_com ||                    -- 情報Ｋ
               ir_mst_rec.info_l            || cv_sep_com ||                    -- 情報Ｌ
               ir_mst_rec.info_m            || cv_sep_com ||                    -- 情報Ｍ
               ir_mst_rec.info_n            || cv_sep_com ||                    -- 情報Ｎ
               ir_mst_rec.info_o            || cv_sep_com ||                    -- 情報Ｏ
               ir_mst_rec.info_p            || cv_sep_com ||                    -- 情報Ｐ
               ir_mst_rec.info_q            || cv_sep_com ||                    -- 情報Ｑ
               ir_mst_rec.amt_a             || cv_sep_com ||                    -- お金Ａ
               ir_mst_rec.amt_b             || cv_sep_com ||                    -- お金Ｂ
               ir_mst_rec.amt_c             || cv_sep_com ||                    -- お金Ｃ
               ir_mst_rec.amt_d             || cv_sep_com ||                    -- お金Ｄ
               ir_mst_rec.amt_e             || cv_sep_com ||                    -- お金Ｅ
               ir_mst_rec.amt_f             || cv_sep_com ||                    -- お金Ｆ
               ir_mst_rec.amt_g             || cv_sep_com ||                    -- お金Ｇ
               ir_mst_rec.amt_h             || cv_sep_com ||                    -- お金Ｈ
               ir_mst_rec.amt_i             || cv_sep_com ||                    -- お金Ｉ
               ir_mst_rec.amt_j             || cv_sep_com ||                    -- お金Ｊ
-- mod start ver1.3
--               ir_mst_rec.v_update_date                                         -- 更新日時
               ir_mst_rec.v_update_date     || cv_crlf                          -- 更新日時
-- mod end ver1.3
               ;
--
    -- データ出力
    UTL_FILE.PUT_LINE(if_file_hand,lv_data);
--
--    gn_normal_cnt := gn_normal_cnt + 1;            -- 2008/08/20 Del
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END put_csv_data;
--
  /***********************************************************************************
   * Procedure Name   : csv_file_proc
   * Description      : CSVファイル出力(D-6)
   ***********************************************************************************/
  PROCEDURE csv_file_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'csv_file_proc';           -- プログラム名
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
    lv_head_seq       CONSTANT VARCHAR2(2)  := '10';
    lv_line_seq       CONSTANT VARCHAR2(2)  := '20';
--
    lv_joint_word     CONSTANT VARCHAR2(4)   := '_';
    lv_extend_word    CONSTANT VARCHAR2(4)   := '.csv';
--
    -- *** ローカル変数 ***
    mst_rec         masters_rec;
    k_mst_rec       masters_rec;
    lv_data         VARCHAR2(5000);
    lf_file_hand    UTL_FILE.FILE_TYPE;         -- ファイル・ハンドルの宣言
--
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    ln_tbl_id       NUMBER;
    ln_len          NUMBER;
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
    -- ファイルパスNULL
    IF (gr_outbound_rec.directory IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_94d_53);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ファイル名NULL
    IF (gr_outbound_rec.file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_94d_54);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ln_len := LENGTH(gr_outbound_rec.file_name);
    -- ファイル名称加工(ファイル名-'.CSV'+'_'+''データ種別'+'_'YYYYMMDDHH24MISS'+'.CSV')
    gv_sch_file_name := substr(gr_outbound_rec.file_name,1,ln_len-4)
                        || lv_joint_word
                        || gv_data_class
                        || lv_joint_word
                        || TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
                        || lv_extend_word;
--
    -- ファイル存在チェック
    UTL_FILE.FGETATTR(gr_outbound_rec.directory,
                      gv_sch_file_name,
                      lb_retcd,
                      ln_file_size,
                      ln_block_size);
--
    -- ファイル存在
    IF (lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_94d_51);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    BEGIN
--
      -- ファイルオープン
      lf_file_hand := UTL_FILE.FOPEN(gr_outbound_rec.directory,
                                     gv_sch_file_name,
                                     'w');
--
      ln_tbl_id := NULL;
--
      <<file_put_loop>>
      FOR i IN gt_master_tbl.FIRST .. gt_master_tbl.LAST LOOP
        mst_rec := gt_master_tbl(i);
--
        IF ((ln_tbl_id IS NULL) OR (ln_tbl_id <> mst_rec.sel_tbl_id)) THEN
          mst_rec.v_seq_no := lv_head_seq;
          ln_tbl_id := mst_rec.sel_tbl_id;
        ELSE
          mst_rec.v_seq_no := lv_line_seq;
          ln_tbl_id := mst_rec.sel_tbl_id;
        END IF;
--
        -- ヘッダ部出力
        IF (mst_rec.v_seq_no = lv_head_seq) THEN
          k_mst_rec := mst_rec;
--
          mst_rec.line_num          := NULL; -- 明細No.
          mst_rec.item_no           := NULL; -- 品目コード
          mst_rec.item_name         := NULL; -- 品目名
          mst_rec.item_s_name       := NULL; -- 品目略名
          mst_rec.futai_code        := NULL; -- 付帯
          mst_rec.lot_no            := NULL; -- ロット
          mst_rec.lot_date          := NULL; -- 製造日
          mst_rec.best_bfr_date     := NULL; -- 賞味期限
          mst_rec.lot_sign          := NULL; -- 固有記号
          mst_rec.request_qty       := NULL; -- 依頼数
          mst_rec.instruct_qty      := NULL; -- 指示数
          mst_rec.num_of_deliver    := NULL; -- 出庫数
          mst_rec.ship_to_qty       := NULL; -- 入庫数
          mst_rec.fix_qty           := NULL; -- 確定数
          mst_rec.item_um           := NULL; -- 単位
          mst_rec.weight_capacity   := NULL; -- 重量容積
          mst_rec.frequent_qty      := NULL; -- 入数
          mst_rec.frequent_factory  := NULL; -- 工場コード
          mst_rec.div_i             := NULL; -- 区分Ｉ
          mst_rec.div_j             := NULL; -- 区分Ｊ
          mst_rec.div_k             := NULL; -- 区分Ｋ
          mst_rec.designate_date    := NULL; -- 日付指定
          mst_rec.info_f            := NULL; -- 情報Ｆ
          mst_rec.info_g            := NULL; -- 情報Ｇ
          mst_rec.info_h            := NULL; -- 情報Ｈ
          mst_rec.info_i            := NULL; -- 情報Ｉ
          mst_rec.info_j            := NULL; -- 情報Ｊ
          mst_rec.info_k            := NULL; -- 情報Ｋ
          mst_rec.info_l            := NULL; -- 情報Ｌ
          mst_rec.info_m            := NULL; -- 情報Ｍ
          mst_rec.info_n            := NULL; -- 情報Ｎ
          mst_rec.info_o            := NULL; -- 情報Ｏ
          mst_rec.info_p            := NULL; -- 情報Ｐ
          mst_rec.info_q            := NULL; -- 情報Ｑ
          mst_rec.amt_a             := NULL; -- お金Ａ
          mst_rec.amt_b             := NULL; -- お金Ｂ
          mst_rec.amt_c             := NULL; -- お金Ｃ
          mst_rec.amt_d             := NULL; -- お金Ｄ
          mst_rec.amt_e             := NULL; -- お金Ｅ
          mst_rec.amt_f             := NULL; -- お金Ｆ
          mst_rec.amt_g             := NULL; -- お金Ｇ
          mst_rec.amt_h             := NULL; -- お金Ｈ
          mst_rec.amt_i             := NULL; -- お金Ｉ
          mst_rec.amt_j             := NULL; -- お金Ｊ
--
          mst_rec.v_lot_date        := NULL; -- 製造日
          mst_rec.v_best_bfr_date   := NULL; -- 賞味期限
          mst_rec.v_designate_date  := NULL; -- 日付指定
--
          mst_rec.description   := mst_rec.head_description;
          mst_rec.v_update_date := mst_rec.v_update_date_h;
--
          -- データ出力
          put_csv_data(lf_file_hand,
                       mst_rec,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
          mst_rec := k_mst_rec;
          mst_rec.v_seq_no := lv_line_seq;
        END IF;
--
        -- 明細部出力
        IF (mst_rec.v_seq_no = lv_line_seq) THEN
          mst_rec.relation_no          := NULL; -- 関連No.
          mst_rec.base_request_no      := NULL; -- コピー元No.   2008/09/02 Add
          mst_rec.base_ship_no         := NULL; -- 元配送No.
          mst_rec.vendor_code          := NULL; -- 取引先コード
          mst_rec.vendor_name          := NULL; -- 取引先名
          mst_rec.vendor_s_name        := NULL; -- 取引先略名
          mst_rec.mediation_code       := NULL; -- 斡旋者コード
          mst_rec.mediation_name       := NULL; -- 斡旋者名
          mst_rec.mediation_s_name     := NULL; -- 斡旋者略名
          mst_rec.whse_code            := NULL; -- 倉庫コード
          mst_rec.whse_name            := NULL; -- 倉庫名
          mst_rec.whse_s_name          := NULL; -- 倉庫略名
          mst_rec.vendor_site_code     := NULL; -- 配送先コード
          mst_rec.vendor_site_name     := NULL; -- 配送先名
          mst_rec.vendor_site_s_name   := NULL; -- 配送先略名
          mst_rec.zip                  := NULL; -- 郵便番号
          mst_rec.address              := NULL; -- 住所
          mst_rec.phone                := NULL; -- 電話番号
          mst_rec.carrier_code         := NULL; -- 運送業者コード
          mst_rec.carrier_name         := NULL; -- 運送業者名
          mst_rec.carrier_s_name       := NULL; -- 運送業者略名
          mst_rec.ship_date            := NULL; -- 出庫日
          mst_rec.arrival_date         := NULL; -- 入庫日
          mst_rec.arrival_time_from    := NULL; -- 着荷時間FROM
          mst_rec.arrival_time_to      := NULL; -- 着荷時間TO
          mst_rec.method_code          := NULL; -- 配送区分
          mst_rec.div_a                := NULL; -- 区分Ａ
          mst_rec.div_b                := NULL; -- 区分Ｂ
          mst_rec.div_c                := NULL; -- 区分Ｃ
          mst_rec.instruction_dept     := NULL; -- 指示部署コード
          mst_rec.request_dept         := NULL; -- 依頼部署コード
          mst_rec.status               := NULL; -- ステータス
          mst_rec.notif_status         := NULL; -- 通知ステータス
          mst_rec.div_d                := NULL; -- 区分Ｄ
          mst_rec.div_e                := NULL; -- 区分Ｅ
          mst_rec.div_f                := NULL; -- 区分Ｆ
          mst_rec.div_g                := NULL; -- 区分Ｇ
          mst_rec.div_h                := NULL; -- 区分Ｈ
          mst_rec.info_a               := NULL; -- 情報Ａ
          mst_rec.info_b               := NULL; -- 情報Ｂ
          mst_rec.info_c               := NULL; -- 情報Ｃ
          mst_rec.info_d               := NULL; -- 情報Ｄ
          mst_rec.info_e               := NULL; -- 情報Ｅ
--
          mst_rec.v_ship_date          := NULL; -- 出庫日
          mst_rec.v_arrival_date       := NULL; -- 入庫日
--
          mst_rec.description   := mst_rec.line_description;
          mst_rec.v_update_date := mst_rec.v_update_date_l;
--
          -- データ出力
          put_csv_data(lf_file_hand,
                       mst_rec,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END LOOP file_put_loop;
--
      -- ファイルクローズ
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN       -- ファイルパス不正エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_50);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.INVALID_FILENAME THEN   -- ファイル名不正エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_51);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.ACCESS_DENIED OR        -- ファイルアクセス権限エラー
           UTL_FILE.WRITE_ERROR THEN        -- 書き込みエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_52);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END csv_file_proc;
--
  /**********************************************************************************
   * Procedure Name   : workflow_start
   * Description      : ワークフロー通知処理(D-7)
   ***********************************************************************************/
  PROCEDURE workflow_start(
    ov_errbuf             OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'workflow_start'; -- プログラム名
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
    lv_itemkey                VARCHAR2(30);
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
    gr_outbound_rec.file_name := gv_sch_file_name;
--
    --WFタイプで一意となるWFキーを取得
    SELECT TO_CHAR(xxcmn_wf_key_s1.NEXTVAL)
    INTO   lv_itemkey
    FROM   DUAL;
--
    BEGIN
--
      --WFプロセスを作成
      WF_ENGINE.CREATEPROCESS(gr_outbound_rec.wf_name, lv_itemkey, gr_outbound_rec.wf_name);
--
      --WFオーナーを設定
      WF_ENGINE.SETITEMOWNER(gr_outbound_rec.wf_name, lv_itemkey, gr_outbound_rec.wf_owner);
--
      --WF属性を設定
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_NAME',
                                  gr_outbound_rec.directory|| ',' ||gr_outbound_rec.file_name );
      -- 通知先ユーザー01
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD01',
                                  gr_outbound_rec.user_cd01);
      -- 通知先ユーザー02
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD02',
                                  gr_outbound_rec.user_cd02);
      -- 通知先ユーザー03
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD03',
                                  gr_outbound_rec.user_cd03);
      -- 通知先ユーザー04
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD04',
                                  gr_outbound_rec.user_cd04);
      -- 通知先ユーザー05
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD05',
                                  gr_outbound_rec.user_cd05);
      -- 通知先ユーザー06
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD06',
                                  gr_outbound_rec.user_cd06);
      -- 通知先ユーザー07
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD07',
                                  gr_outbound_rec.user_cd07);
      -- 通知先ユーザー08
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD08',
                                  gr_outbound_rec.user_cd08);
      -- 通知先ユーザー09
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD09',
                                  gr_outbound_rec.user_cd09);
      -- 通知先ユーザー10
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD10',
                                  gr_outbound_rec.user_cd10);
--
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_DISP_NAME',
                                  gr_outbound_rec.file_display_name);
--
      --WFプロセスを起動
      WF_ENGINE.STARTPROCESS(gr_outbound_rec.wf_name, lv_itemkey);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_55);
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END workflow_start;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_wf_ope_div        IN            VARCHAR2,  --  1.処理区分          (必須)
    iv_wf_class          IN            VARCHAR2,  --  2.対象              (必須)
    iv_wf_notification   IN            VARCHAR2,  --  3.宛先              (必須)
    iv_data_class        IN            VARCHAR2,  --  4.データ種別        (必須)
    iv_ship_no_from      IN            VARCHAR2,  --  5.配送No.FROM       (任意)
    iv_ship_no_to        IN            VARCHAR2,  --  6.配送No.TO         (任意)
    iv_req_no_from       IN            VARCHAR2,  --  7.依頼No.FROM       (任意)
    iv_req_no_to         IN            VARCHAR2,  --  8.依頼No.TO         (任意)
    iv_vendor_code       IN            VARCHAR2,  --  9.取引先            (任意)
    iv_mediation         IN            VARCHAR2,  -- 10.斡旋者            (任意)
    iv_location_code     IN            VARCHAR2,  -- 11.出庫倉庫          (任意)
    iv_arvl_code         IN            VARCHAR2,  -- 12.入庫倉庫          (任意)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.配送先            (任意)
    iv_carrier_code      IN            VARCHAR2,  -- 14.運送業者          (任意)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.納入日/出庫日FROM (必須)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.納入日/出庫日TO   (必須)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.入庫日FROM        (任意)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.入庫日TO          (任意)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.指示部署          (任意)
    iv_item_no           IN            VARCHAR2,  -- 20.品目              (任意)
    iv_update_time_from  IN            VARCHAR2,  -- 21.更新日時FROM      (任意)
    iv_update_time_to    IN            VARCHAR2,  -- 22.更新日時TO        (任意)
    iv_prod_class        IN            VARCHAR2,  -- 23.商品区分          (任意)
    iv_item_class        IN            VARCHAR2,  -- 24.品目区分          (任意)
    iv_sec_class         IN            VARCHAR2,  -- 25.セキュリティ区分  (必須)
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_tbl_name_pha   CONSTANT VARCHAR2(200) := '発注ヘッダ';
    lv_tbl_name_oha   CONSTANT VARCHAR2(200) := '受注ヘッダアドオン';
    lv_tbl_name_mov   CONSTANT VARCHAR2(200) := '移動依頼/指示ヘッダアドオン';
--
    -- *** ローカル変数 ***
    lv_tbl_name     VARCHAR2(200);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    --*********************************************
    --***   入力パラメータチェック処理(D-1)     ***
    --*********************************************
    parameter_check(
      iv_wf_ope_div,        --  1.処理区分
      iv_wf_class,          --  2.対象
      iv_wf_notification,   --  3.宛先
      iv_data_class,        --  4.データ種別
      iv_ship_no_from,      --  5.配送No.FROM
      iv_ship_no_to,        --  6.配送No.TO
      iv_req_no_from,       --  7.依頼No.FROM
      iv_req_no_to,         --  8.依頼No.TO
      iv_vendor_code,       --  9.取引先
      iv_mediation,         -- 10.斡旋者
      iv_location_code,     -- 11.出庫倉庫
      iv_arvl_code,         -- 12.入庫倉庫
      iv_vendor_site_code,  -- 13.配送先
      iv_carrier_code,      -- 14.運送業者
      iv_ship_date_from,    -- 15.納入日/出庫日FROM
      iv_ship_date_to,      -- 16.納入日/出庫日TO
      iv_arrival_date_from, -- 17.入庫日FROM
      iv_arrival_date_to,   -- 18.入庫日TO
      iv_instruction_dept,  -- 19.指示部署
      iv_item_no,           -- 20.品目
      iv_update_time_from,  -- 21.更新日時FROM
      iv_update_time_to,    -- 22.更新日時TO
      iv_prod_class,        -- 23.商品区分
      iv_item_class,        -- 24.品目区分
      iv_sec_class,         -- 25.セキュリティ区分
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- データ種別：発注
    IF (iv_data_class = gv_data_class_pha) THEN
--
      --*********************************************
      --***       発注情報取得処理(D-4)           ***
      --*********************************************
      pha_sel_proc(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- データ種別：支給
    ELSIF (iv_data_class = gv_data_class_oha) THEN
--
      --*********************************************
      --***       支給情報取得処理(D-4)           ***
      --*********************************************
      oha_sel_proc(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- データ種別：移動
    ELSIF (iv_data_class = gv_data_class_mov) THEN
--
      --*********************************************
      --***       移動情報取得処理(D-5)           ***
      --*********************************************
      mov_sel_proc(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- データあり
    IF (gt_master_tbl.COUNT > 0) THEN
      --*********************************************
      --***        CSVファイル出力(D-6)           ***
      --*********************************************
      csv_file_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- データなし
    ELSE
--
      -- 発注情報
      IF (gv_data_class = gv_data_class_pha) THEN
        lv_tbl_name := lv_tbl_name_pha;
--
      -- 支給情報
      ELSIF (gv_data_class = gv_data_class_oha) THEN
        lv_tbl_name := lv_tbl_name_oha;
--
      -- 移動情報
      ELSE
        lv_tbl_name := lv_tbl_name_mov;
      END IF;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_05,
                                            gv_tkn_table,
                                            lv_tbl_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      lv_retcode := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_normal) THEN
      --*********************************************
      --***       Workflow通知処理(D-7)           ***
      --*********************************************
      workflow_start(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      ov_retcode := lv_retcode;
    END IF;
--
    gn_target_cnt := gt_master_tbl.COUNT;
--
    gn_normal_cnt := gn_target_cnt;           -- 2008/08/20 Add
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf                  OUT NOCOPY VARCHAR2,  --   エラー・メッセージ  --# 固定 #
    retcode                 OUT NOCOPY VARCHAR2,  --   リターン・コード    --# 固定 #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.処理区分          (必須)
    iv_wf_class          IN            VARCHAR2,  --  2.対象              (必須)
    iv_wf_notification   IN            VARCHAR2,  --  3.宛先              (必須)
    iv_data_class        IN            VARCHAR2,  --  4.データ種別        (必須)
    iv_ship_no_from      IN            VARCHAR2,  --  5.配送No.FROM       (任意)
    iv_ship_no_to        IN            VARCHAR2,  --  6.配送No.TO         (任意)
    iv_req_no_from       IN            VARCHAR2,  --  7.依頼No.FROM       (任意)
    iv_req_no_to         IN            VARCHAR2,  --  8.依頼No.TO         (任意)
    iv_vendor_code       IN            VARCHAR2,  --  9.取引先            (任意)
    iv_mediation         IN            VARCHAR2,  -- 10.斡旋者            (任意)
    iv_location_code     IN            VARCHAR2,  -- 11.出庫倉庫          (任意)
    iv_arvl_code         IN            VARCHAR2,  -- 12.入庫倉庫          (任意)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.配送先            (任意)
    iv_carrier_code      IN            VARCHAR2,  -- 14.運送業者          (任意)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.納入日/出庫日FROM (必須)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.納入日/出庫日TO   (必須)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.入庫日FROM        (任意)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.入庫日TO          (任意)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.指示部署          (任意)
    iv_item_no           IN            VARCHAR2,  -- 20.品目              (任意)
    iv_update_time_from  IN            VARCHAR2,  -- 21.更新日時FROM      (任意)
    iv_update_time_to    IN            VARCHAR2,  -- 22.更新日時TO        (任意)
    iv_prod_class        IN            VARCHAR2,  -- 23.商品区分          (任意)
    iv_item_class        IN            VARCHAR2,  -- 24.品目区分          (任意)
    iv_sec_class         IN            VARCHAR2   -- 25.セキュリティ区分  (必須)
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
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      iv_wf_ope_div,        --  1.処理区分
      iv_wf_class,          --  2.対象
      iv_wf_notification,   --  3.宛先
      iv_data_class,        --  4.データ種別
      iv_ship_no_from,      --  5.配送No.FROM
      iv_ship_no_to,        --  6.配送No.TO
      iv_req_no_from,       --  7.依頼No.FROM
      iv_req_no_to,         --  8.依頼No.TO
      iv_vendor_code,       --  9.取引先
      iv_mediation,         -- 10.斡旋者
      iv_location_code,     -- 11.出庫倉庫
      iv_arvl_code,         -- 12.入庫倉庫
      iv_vendor_site_code,  -- 13.配送先
      iv_carrier_code,      -- 14.運送業者
      iv_ship_date_from,    -- 15.納入日/出庫日FROM
      iv_ship_date_to,      -- 16.納入日/出庫日TO
      iv_arrival_date_from, -- 17.入庫日FROM
      iv_arrival_date_to,   -- 18.入庫日TO
      iv_instruction_dept,  -- 19.指示部署
      iv_item_no,           -- 20.品目
      iv_update_time_from,  -- 21.更新日時FROM
      iv_update_time_to,    -- 22.更新日時TO
      iv_prod_class,        -- 23.商品区分
      iv_item_class,        -- 24.品目区分
      iv_sec_class,         -- 25.セキュリティ区分
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxpo940004c;
/
