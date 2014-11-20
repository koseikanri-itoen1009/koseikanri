create or replace
PACKAGE BODY xxpo940003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940003c(body)
 * Description      : ロット在庫情報抽出処理
 * MD.050           : 生産物流共通                  T_MD050_BPO_940
 * MD.070           : ロット在庫情報抽出処理        T_MD070_BPO_94C
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  parameter_disp         パラメータの出力
 *  get_inv_stock_vol      手持在庫数取得
 *  get_supply_stock_plan  入庫予定数取得
 *  get_lot_inf_proc       ロット在庫情報取得処理           (C-1)
 *  csv_file_proc          CSVファイル出力                  (C-2)
 *  workflow_start         ワークフロー通知処理             (C-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/18    1.0   Oracle 大橋 孝郎 初回作成
 *  2008/08/01    1.1   Oracle 吉田 夏樹 ST不具合対応
 *  2008/08/04    1.2   Oracle 吉田 夏樹 PT対応
 *  2008/08/19    1.3   Oracle 山根 一浩 仕様不備・指摘15
 *  2008/09/17    1.4   Oracle 大橋 孝郎 T_S_460対応
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
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo940003c'; -- パッケージ名
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';        -- アプリケーション短縮名
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';       -- アプリケーション短縮名
--
  -- データ種別
  gv_data_class    CONSTANT VARCHAR2(3) := '510';
--
  -- 伝送用枝番
  gv_transmission_no CONSTANT VARCHAR2(2) := '00';
--
  gv_sec_class_home CONSTANT VARCHAR2(1) := '1';   -- 伊藤園ユーザータイプ
  gv_sec_class_vend CONSTANT VARCHAR2(1) := '2';   -- 取引先ユーザータイプ
  gv_sec_class_extn CONSTANT VARCHAR2(1) := '3';   -- 外部倉庫ユーザータイプ
  gv_sec_class_quay CONSTANT VARCHAR2(1) := '4';   -- 東洋埠頭ユーザータイプ
--
  gv_company_name   CONSTANT VARCHAR2(10) := 'ITOEN';
--
  -- トークン
  gv_tkn_xxpo_10026       CONSTANT VARCHAR2(15) := 'APP-XXPO-10026';  -- データ未取得メッセージ
  gv_tkn_xxpo_30022       CONSTANT VARCHAR2(15) := 'APP-XXPO-30022';  -- パラメータ受取
  gv_tkn_xxcmn_10113      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10113'; -- ファイルパス不正ｴﾗｰ
  gv_tkn_xxcmn_10114      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10114'; -- ファイル名不正ｴﾗｰ
  gv_tkn_xxcmn_10115      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10115'; -- ファイルアクセス権限ｴﾗｰ
  gv_tkn_xxcmn_10119      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10119'; -- ファイルパスNULLｴﾗｰ
  gv_tkn_xxcmn_10120      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10120'; -- ファイル名NULLｴﾗｰ
  gv_tkn_xxcmn_10117      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10117'; -- Workflow起動ｴﾗｰ
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
  gv_sep_com         CONSTANT VARCHAR2(1)  := ',';
  gv_lot_code0       CONSTANT VARCHAR2(1)  := '0';                 -- 非ロット管理区分コード
  gv_lot_code1       CONSTANT VARCHAR2(1)  := '1';                 -- ロット管理区分コード
  gv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
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
    segment1              VARCHAR2(40),  -- 保管倉庫コード
    inventory_location_id NUMBER,        -- 保管倉庫ID
    loct_onhand           NUMBER,        -- 手持数量
    vendor_code           VARCHAR2(240), -- 取引先(DFF8)
    vendor_full_name      VARCHAR2(60),  -- 正式名(仕入先)
    vendor_short_name     VARCHAR2(20),  -- 略称(仕入先)
    item_id               VARCHAR2(7),   -- 品目ID
    item_no               VARCHAR2(10),  -- 品目コード
    item_name             VARCHAR2(40),  -- 品名・正式名
    item_short_name       VARCHAR2(20),  -- 品名・略称
    lot_id                VARCHAR2(10),  -- ロットID
    lot_no                VARCHAR2(10),  -- ロットNo
    product_date          VARCHAR2(10),  -- 製造年月日(DFF1)
    use_by_date           VARCHAR2(240), -- 賞味期限(DFF3)
    original_char         VARCHAR2(240), -- 固有記号(DFF2)
    manu_factory          VARCHAR2(240), -- 製造工場(DFF20)
    manu_lot              VARCHAR2(240), -- 製造ロット(DFF21)
    home                  VARCHAR2(240), -- 産地(DFF12)
    rank1                 VARCHAR2(240), -- ランク1(DFF14)
    rank2                 VARCHAR2(240), -- ランク2(DFF15)
    description           VARCHAR2(240), -- 摘要(DFF18)
    qt_inspect_req_no     VARCHAR2(240), -- 検査依頼番号(DFF22)
    inspect_due_date1     VARCHAR2(10),  -- 検査予定日1
    test_date1            VARCHAR2(10),  -- 検査日1
    qt_effect1            VARCHAR2(10),  -- 結果1
    inspect_due_date2     VARCHAR2(10),  -- 検査予定日2
    test_date2            VARCHAR2(10),  -- 検査日2
    qt_effect2            VARCHAR2(10),  -- 結果2
    inspect_due_date3     VARCHAR2(10),  -- 検査予定日3
    test_date3            VARCHAR2(10),  -- 検査日3
    qt_effect3            VARCHAR2(10)   -- 結果3
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
  gv_prod_class               VARCHAR2(20);  --  4.商品区分          (必須)
  gv_item_class               VARCHAR2(20);  --  5.品目区分          (必須)
  gv_frequent_whse_div        VARCHAR2(20);  --  6.代表倉庫区分      (任意)
  gv_whse                     VARCHAR2(20);  --  7.倉庫              (任意)
  gv_vendor_id                VARCHAR2(20);  --  8.取引先            (任意)
  gv_item_no                  VARCHAR2(20);  --  9.品目              (任意)
  gv_lot_no                   VARCHAR2(20);  --  10.ロット           (任意)
  gv_manufacture_date         VARCHAR2(10);  --  11.製造日           (任意)
  gv_expiration_date          VARCHAR2(10);  --  12.賞味期限         (任意)
  gv_uniqe_sign               VARCHAR2(20);  --  13.固有記号         (任意)
  gv_mf_factory               VARCHAR2(20);  --  14.製造工場         (任意)
  gv_mf_lot                   VARCHAR2(20);  --  15.製造ロット       (任意)
  gv_home                     VARCHAR2(20);  --  16.産地             (任意)
  gv_r1                       VARCHAR2(20);  --  17.R1               (任意)
  gv_r2                       VARCHAR2(20);  --  18.R2               (任意)
  gv_sec_class                VARCHAR2(20);  --  19.セキュリティ区分  (必須)
--
  gd_manufacture_date         DATE;          -- 製造日
  gd_expiration_date          DATE;          -- 賞味期限
--
  gv_sch_file_name            VARCHAR2(2000);          -- 対象ファイル名
--
  gn_user_id                  NUMBER;                  -- ユーザID
  gd_sys_date                 DATE;                    -- 当日日付
--
--
  gr_outbound_rec             xxcmn_common_pkg.outbound_rec; -- outbound関連データ
--
  /**********************************************************************************
   * Procedure Name   : parameter_disp
   * Description      : パラメータの出力
   ***********************************************************************************/
  PROCEDURE parameter_disp(
    iv_wf_ope_div        IN            VARCHAR2,  --  1.処理区分          (必須)
    iv_wf_class          IN            VARCHAR2,  --  2.対象              (必須)
    iv_wf_notification   IN            VARCHAR2,  --  3.宛先              (必須)
    iv_prod_class        IN            VARCHAR2,  --  4.商品区分          (必須)
    iv_item_class        IN            VARCHAR2,  --  5.品目区分          (必須)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.代表倉庫区分      (任意)
    iv_whse              IN            VARCHAR2,  --  7.倉庫              (任意)
    iv_vendor_id         IN            VARCHAR2,  --  8.取引先            (任意)
    iv_item_no           IN            VARCHAR2,  --  9.品目              (任意)
    iv_lot_no            IN            VARCHAR2,  -- 10.ロット            (任意)
    iv_manufacture_date  IN            VARCHAR2,  -- 11.製造日            (任意)
    iv_expiration_date   IN            VARCHAR2,  -- 12.賞味期限          (任意)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.固有記号          (任意)
    iv_mf_factory        IN            VARCHAR2,  -- 14.製造工場          (任意)
    iv_mf_lot            IN            VARCHAR2,  -- 15.製造ロット        (任意)
    iv_home              IN            VARCHAR2,  -- 16.産地              (任意)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (任意)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (任意)
    iv_sec_class         IN            VARCHAR2,  -- 19.セキュリティ区分  (必須)
    ov_errbuf            OUT NOCOPY    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY    VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_wf_ope_div_n           CONSTANT VARCHAR2(100) := '処理区分';
    lv_wf_class_n             CONSTANT VARCHAR2(100) := '対象';
    lv_wf_notification_n      CONSTANT VARCHAR2(100) := '宛先';
    lv_prod_class_n           CONSTANT VARCHAR2(100) := '商品区分';
    lv_item_class_n           CONSTANT VARCHAR2(100) := '品目区分';
    lv_frequent_whse_div_n    CONSTANT VARCHAR2(100) := '代表倉庫区分';
    lv_whse_n                 CONSTANT VARCHAR2(100) := '倉庫';
    lv_vendor_id_n            CONSTANT VARCHAR2(100) := '取引先';
    lv_item_no_n              CONSTANT VARCHAR2(100) := '品目';
    lv_lot_no_n               CONSTANT VARCHAR2(100) := 'ロット';
    lv_manufacture_date_n     CONSTANT VARCHAR2(100) := '製造日';
    lv_expiration_date_n      CONSTANT VARCHAR2(100) := '賞味期限';
    lv_uniqe_sign_n           CONSTANT VARCHAR2(100) := '固有記号';
    lv_mf_factory_n           CONSTANT VARCHAR2(100) := '製造工場';
    lv_mf_lot_n               CONSTANT VARCHAR2(100) := '製造ロット';
    lv_home_n                 CONSTANT VARCHAR2(100) := '産地';
    lv_r1_n                   CONSTANT VARCHAR2(100) := 'R1';
    lv_r2_n                   CONSTANT VARCHAR2(100) := 'R2';
    lv_sec_class_n            CONSTANT VARCHAR2(100) := 'セキュリティ区分';
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
    -- パラメータをグローバル変数へ格納
    gv_wf_ope_div        := iv_wf_ope_div;        --  1.処理区分
    gv_wf_class          := iv_wf_class;          --  2.対象
    gv_wf_notification   := iv_wf_notification;   --  3.宛先
    gv_prod_class        := iv_prod_class;        --  4.商品区分
    gv_item_class        := iv_item_class;        --  5.品目区分
    gv_frequent_whse_div := iv_frequent_whse_div; --  6.代表倉庫区分
    gv_whse              := iv_whse;              --  7.倉庫
    gv_vendor_id         := iv_vendor_id;         --  8.取引先
    gv_item_no           := iv_item_no;           --  9.品目
    gv_lot_no            := iv_lot_no;            -- 10.ロット
    gv_manufacture_date  := iv_manufacture_date;  -- 11.製造日
    gv_expiration_date   := iv_expiration_date;   -- 12.賞味期限
    gv_uniqe_sign        := iv_uniqe_sign;        -- 13.固有記号
    gv_mf_factory        := iv_mf_factory;        -- 14.製造工場
    gv_mf_lot            := iv_mf_lot;            -- 15.製造ロット
    gv_home              := iv_home;              -- 16.産地
    gv_r1                := iv_r1;                -- 17.R1
    gv_r2                := iv_r2;                -- 18.R2
    gv_sec_class         := iv_sec_class;         -- 19.セキュリティ区分
--
    -- 製造日を日付型へ変更
    gd_manufacture_date := FND_DATE.STRING_TO_DATE(gv_manufacture_date,'YYYY/MM/DD');
--
    -- 賞味期限を日付型へ変更
    gd_expiration_date  := FND_DATE.STRING_TO_DATE(gv_expiration_date,'YYYY/MM/DD');
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
    -- 処理区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_wf_ope_div_n,
                                          gv_tkn_data,
                                          gv_wf_ope_div);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 対象
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_wf_class_n,
                                          gv_tkn_data,
                                          gv_wf_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 宛先
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_wf_notification_n,
                                          gv_tkn_data,
                                          gv_wf_notification);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 商品区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_prod_class_n,
                                          gv_tkn_data,
                                          gv_prod_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 品目区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_item_class_n,
                                          gv_tkn_data,
                                          gv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 代表倉庫区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_frequent_whse_div_n,
                                          gv_tkn_data,
                                          gv_frequent_whse_div);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 倉庫
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_whse_n,
                                          gv_tkn_data,
                                          gv_whse);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 取引先
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_vendor_id_n,
                                          gv_tkn_data,
                                          gv_vendor_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 品目
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_item_no_n,
                                          gv_tkn_data,
                                          gv_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ロット
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_lot_no_n,
                                          gv_tkn_data,
                                          gv_lot_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 製造日
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_manufacture_date_n,
                                          gv_tkn_data,
                                          gv_manufacture_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 賞味期限
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_expiration_date_n,
                                          gv_tkn_data,
                                          gv_expiration_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 固有記号
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_uniqe_sign_n,
                                          gv_tkn_data,
                                          gv_uniqe_sign);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 製造工場
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_mf_factory_n,
                                          gv_tkn_data,
                                          gv_mf_factory);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 製造ロット
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_mf_lot_n,
                                          gv_tkn_data,
                                          gv_mf_lot);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- 産地
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_home_n,
                                          gv_tkn_data,
                                          gv_home);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- R1
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_r1_n,
                                          gv_tkn_data,
                                          gv_r1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- R2
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_r2_n,
                                          gv_tkn_data,
                                          gv_r2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- セキュリティ区分
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
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
  /***********************************************************************************
   * Function Name    : get_inv_stock_vol
   * Description      : 手持在庫数取得
   ***********************************************************************************/
  FUNCTION  get_inv_stock_vol(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- 変数宣言
    ln_temp_inv_stock_vol           NUMBER;
    ln_lot_id                       ic_lots_mst.lot_id%TYPE;
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- ロット管理区分取得
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- 手持在庫数量算出API引数.ロットIDの設定
    IF (lv_lot_ctl = gv_lot_code1) THEN
      -- ロット管理品の場合、抽出したロットIDを設定
      ln_lot_id := in_lot_id;
    ELSE
      -- 非ロット管理品の場合、NULLを設定
      ln_lot_id := NULL;
    END IF;
--
    -- 共通関数｢手持在庫数量算出API｣コール
    ln_temp_inv_stock_vol := xxcmn_common2_pkg.get_stock_qty(
                               in_whse_id => in_inventory_location_id,  -- OPM保管倉庫ID
                               in_item_id => in_item_id,                -- OPM品目ID
                               in_lot_id  => ln_lot_id);                -- ロットID
--
    RETURN ln_temp_inv_stock_vol;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_inv_stock_vol;
--
  /***********************************************************************************
   * Function Name    : get_supply_stock_plan
   * Description      : 入庫予定数取得
   ***********************************************************************************/
  FUNCTION  get_supply_stock_plan(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- 変数宣言
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_hacchu_ukeire_yotei          NUMBER;    -- 入庫予定数(7-2:発注受入予定)
    ln_idou_nyuuko_yotei_shiji      NUMBER;    -- 入庫予定数(7-3:移動入庫予定 指示)
    ln_idou_nyuuko_yotei_shukko     NUMBER;    -- 入庫予定数(7-4:移動入庫予定 出庫報告有)
    ln_seisan_yotei                 NUMBER;    -- 入庫予定数(7-5:生産予定)
    ln_temp_supply_stock_plan       NUMBER;    -- 入庫予定数退避
    ld_max_date                     DATE;      -- 最大日付格納変数
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- 変数初期化
    ln_hacchu_ukeire_yotei      := 0;
    ln_idou_nyuuko_yotei_shiji  := 0;
    ln_idou_nyuuko_yotei_shukko := 0;
    ln_seisan_yotei             := 0;
--
    -- 日付範囲なしに数量を取得する
    ld_max_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), gv_date_format);
--
    -- ロット管理区分取得
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF (lv_lot_ctl = gv_lot_code1) THEN
      -- ※ロット品※
      -- 入庫予定数(7-2:発注受入予定)
      xxcmn_common2_pkg.get_sup_lot_order_qty(
        iv_whse_code => iv_segment1,             -- 保管倉庫コード
        iv_item_code => iv_item_no,              -- 品目コード
        iv_lot_no    => iv_lot_no,               -- ロットNO
        id_eff_date  => ld_max_date,             -- 有効日付
        on_qty       => ln_hacchu_ukeire_yotei,  -- 数量
        ov_errbuf    => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-3:移動入庫予定 指示)
      xxcmn_common2_pkg.get_sup_lot_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-4:移動入庫予定 出庫報告有)
      xxcmn_common2_pkg.get_sup_lot_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-5:生産予定)
      xxcmn_common2_pkg.get_sup_lot_produce_qty(
        iv_whse_code => iv_segment1,             -- 保管倉庫コード
        in_item_id   => in_item_id,              -- 品目ID
        in_lot_id    => in_lot_id,               -- ロットID
        id_eff_date  => ld_max_date,             -- 有効日付
        on_qty       => ln_seisan_yotei,         -- 数量
        ov_errbuf    => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ※ロット品END※
    ELSIF (lv_lot_ctl = gv_lot_code0) THEN
--
      -- ※非ロット品※
      -- 入庫予定数(7-2:発注受入予定)
      xxcmn_common2_pkg.get_sup_order_qty(
        iv_whse_code => iv_segment1,             -- 保管倉庫コード
        iv_item_code => iv_item_no,              -- 品目コード
        id_eff_date  => ld_max_date,             -- 有効日付
        on_qty       => ln_hacchu_ukeire_yotei,  -- 数量
        ov_errbuf    => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      --入庫予定数(7-3:移動入庫予定 指示)
      xxcmn_common2_pkg.get_sup_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-4:移動入庫予定 出庫報告有)
      xxcmn_common2_pkg.get_sup_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ※非ロット品END※
    END IF;
--
    -- 各共通関数にて取得した値をサマリ = 入庫予定数
    ln_temp_supply_stock_plan := ln_hacchu_ukeire_yotei
                               + ln_idou_nyuuko_yotei_shiji
                               + ln_idou_nyuuko_yotei_shukko
                               + ln_seisan_yotei;
--
    RETURN ln_temp_supply_stock_plan;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_supply_stock_plan;
--
--
  /**********************************************************************************
   * Procedure Name   : get_lot_inf_proc
   * Description      : ロット在庫情報取得処理(C-1)
   ***********************************************************************************/
  PROCEDURE get_lot_inf_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_inf_proc'; -- プログラム名
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
		cn_zero            CONSTANT NUMBER       := 0;
--
    -- *** ローカル変数 ***
    mst_rec              masters_rec;
    ln_cnt               NUMBER;
    lv_prof_xdfw         VARCHAR2(4);         -- ダミー代表倉庫
    ld_target_date       DATE;                -- 対象日付
    ln_prof_xtt          NUMBER;              -- 在庫照会対象
    lv_target_flg        VARCHAR2(1);         -- 対象データフラグ
    ln_stock_vol         NUMBER;              -- 手持在庫数
    ln_supply_stock_plan NUMBER;              -- 入庫予定数
-- 2008/08/01 PT対応 1.1 modify start
    ln_vendor_code       VARCHAR2(4);         -- 取引先コード(ブレイク用)
    ln_item_no           VARCHAR2(7);         -- 品目コード(ブレイク用)
    ln_lot_no            VARCHAR2(10);        -- ロットNo.(ブレイク用)
-- 2008/08/01 PT対応 1.1 modify end
--
    -- *** ローカル・カーソル ***
    
-- 2008/08/03 PT対応 1.2 modify start
/*
    CURSOR mst_data_cur
    IS
      SELECT  iiim.segment1                                            AS segment1          -- 保管倉庫コード
             ,iiim.inventory_location_id                               AS inventory_location_id -- 保管倉庫ID
             ,NVL(ili.loct_onhand, cn_zero)                            AS loct_onhand       -- 手持数量
             ,iiim.attribute8                                          AS vendor_code       -- 取引先(DFF8)
             ,REPLACE(xvv.vendor_full_name,gv_sep_com)                 AS vendor_full_name  -- 正式名(仕入先)
             ,REPLACE(xvv.vendor_short_name,gv_sep_com)                AS vendor_short_name -- 略称(仕入先)
             ,iiim.item_id                                             AS item_id           -- 品目ID
             ,iiim.item_no                                             AS item_no           -- 品目コード
             ,REPLACE(iiim.item_name,gv_sep_com)                       AS item_name         -- 品名・正式名
             ,REPLACE(iiim.item_short_name,gv_sep_com)                 AS item_short_name   -- 品名・略称
             ,iiim.lot_id                                              AS lot_id            -- ロットID
             ,DECODE(iiim.lot_ctl, gv_lot_code0, NULL, iiim.lot_no)    AS lot_no            -- ロットNo
             ,FND_DATE.STRING_TO_DATE(iiim.attribute1, gv_date_format) AS product_date      -- 製造年月日(DFF1)
             ,FND_DATE.STRING_TO_DATE(iiim.attribute3, gv_date_format) AS use_by_date       -- 賞味期限(DFF3)
             ,iiim.attribute2                                          AS original_char     -- 固有記号(DFF2)
             ,iiim.attribute20                                         AS manu_factory      -- 製造工場(DFF20)
             ,iiim.attribute21                                         AS manu_lot          -- 製造ロット(DFF21)
             ,iiim.attribute12                                         AS home              -- 産地(DFF12)
             ,iiim.attribute14                                         AS rank1             -- ランク1(DFF14)
             ,iiim.attribute15                                         AS rank2             -- ランク2(DFF15)
             ,REPLACE(iiim.attribute18,gv_sep_com)                     AS description       -- 摘要(DFF18)
             ,iiim.attribute22                                         AS qt_inspect_req_no -- 検査依頼番号(DFF22)
             ,FND_DATE.STRING_TO_DATE(xqi.inspect_due_date1, gv_date_format) AS inspect_due_date1 -- 検査予定日1
             ,FND_DATE.STRING_TO_DATE(xqi.test_date1, gv_date_format)        AS test_date1        -- 検査日1
             ,xqi.qt_effect1                                           AS qt_effect1        -- 結果1
             ,FND_DATE.STRING_TO_DATE(xqi.inspect_due_date2, gv_date_format) AS inspect_due_date2 -- 検査予定日2
             ,FND_DATE.STRING_TO_DATE(xqi.test_date2, gv_date_format)  AS test_date2        -- 検査日2
             ,xqi.qt_effect2                                           AS qt_effect2        -- 結果2
             ,FND_DATE.STRING_TO_DATE(xqi.inspect_due_date3, gv_date_format) AS inspect_due_date3 -- 検査予定日3
             ,FND_DATE.STRING_TO_DATE(xqi.test_date3, gv_date_format)        AS test_date3        -- 検査日3
             ,xqi.qt_effect3                                           AS qt_effect3        -- 結果3
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_name,             -- 品名・正式名
                     ximv.item_short_name,       -- 品名・略称
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute8,
                     ilm.attribute12,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute18,
                     ilm.attribute20,
                     ilm.attribute21,
                     ilm.attribute22
              FROM   xxcmn_item_mst_v ximv,          -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,                -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,   -- OPM保管場所情報VIEW
                     xxcmn_item_categories5_v xicv   -- OPM品目カテゴリ割当情報VIEW5
-- 2008/08/01 PT対応 1.1 modify(カテゴリVIEW削除)
              WHERE  ximv.item_id            = ilm.item_id
              -- 品目区分(必須)
              AND    xicv.item_class_code    = gv_item_class
              -- 商品区分(必須)
              AND    xicv.prod_class_code    = gv_prod_class
              AND    xicv.item_id            = ximv.item_id
              AND  ((ximv.lot_ctl            = gv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = gv_lot_code0)) iiim,
             xxcmn_item_locations_v  xilv_fr,       -- OPM保管場所情報VIEW(代表倉庫)
             xxwip_qt_inspection    xqi,            -- 品質検査依頼情報
             xxcmn_vendors_v            xvv         -- 仕入先情報
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- セキュリティ区分
      AND    (
      -- 伊藤園ユーザータイプ
                   (gv_sec_class = gv_sec_class_home
                    AND (
                          -- 検索条件：倉庫が入力済
                          (gv_whse IS NOT NULL
                        AND (
                             -- 検索条件：代表倉庫区分が'Y'
                             (gv_frequent_whse_div = 'Y'
                                AND ( (iiim.frequent_whse      = xilv_fr.segment1)
                                    OR(   (iiim.frequent_whse     = lv_prof_xdfw)  -- ダミー代表倉庫
                                      AND ( xilv_fr.segment1 = (SELECT xfil.frq_item_location_code
                                                                FROM  xxwsh_frq_item_locations xfil -- 品目別保管倉庫
                                                                WHERE xfil.item_location_code = iiim.segment1
                                                                AND   xfil.item_id = iiim.item_id))))
                                AND xilv_fr.frequent_whse   = gv_whse)
                             -- 検索条件：代表倉庫区分が'N'
                             OR (gv_frequent_whse_div = 'N'
                                AND (iiim.segment1 = gv_whse)
                                AND (xilv_fr.segment1 = iiim.segment1))
                            )
                          )
                        -- 検索条件：倉庫が未入力
                        OR (gv_whse IS NULL
-- 2008/08/01 PT対応 1.1 modify start
                        AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT対応 1.1 modify end)
                        )
                   )
      -- 仕入先ユーザータイプ
               OR  (gv_sec_class = gv_sec_class_vend
                    AND iiim.attribute8 IN
                      (SELECT papf.attribute4            -- 取引先コード(仕入先コード)
                       FROM   fnd_user           fu      -- ユーザーマスタ
                             ,per_all_people_f   papf    -- 従業員マスタ
                       WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                       AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                       AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                       AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                       AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                         OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                       AND    fu.user_id                 = gn_user_id)            -- ユーザーID
                    AND (
                          -- 検索条件：倉庫が入力済
                          (gv_whse IS NOT NULL
                      AND xilv_fr.segment1 = gv_whse
-- 2008/08/01 PT対応 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT対応 1.1 modify end
                      -- 検索条件：倉庫が未入力
                      OR (gv_whse IS NULL
-- 2008/08/01 PT対応 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT対応 1.1 modify end
                        )
                   )
      -- 外部倉庫ユーザータイプ
               OR     (gv_sec_class = gv_sec_class_extn
                    AND (
                          iiim.segment1 IN
                            (SELECT xilv.segment1                      -- 保管倉庫コード
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
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                        OR iiim.segment1 IN
                            (SELECT xvs.vendor_stock_whse              -- 相手先在庫入庫先
                             FROM   fnd_user               fu          -- ユーザーマスタ
                                   ,per_all_people_f       papf        -- 従業員マスタ
                                   ,xxcmn_vendor_sites_v   xvs         -- 仕入先サイト情報VIEW
                             WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xvs.vendor_id              = papf.attribute4        -- 仕入先コード
                             AND    xvs.vendor_site_code       = papf.attribute6        -- 仕入先サイト名
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                        )
                    AND ( 
                            -- 検索条件：倉庫が入力済
                            (gv_whse IS NOT NULL 
                          AND (
                               -- 検索条件：代表倉庫区分が'Y'
                               (gv_frequent_whse_div = 'Y'
                                AND ( (iiim.frequent_whse      = xilv_fr.segment1)
                                    OR(   (iiim.frequent_whse     = lv_prof_xdfw)  -- ダミー代表倉庫
                                      AND ( xilv_fr.segment1 = (SELECT xfil.frq_item_location_code
                                                                FROM  xxwsh_frq_item_locations xfil -- 品目別保管倉庫
                                                                WHERE xfil.item_location_code = iiim.segment1
                                                                AND   xfil.item_id = iiim.item_id))))
                                AND xilv_fr.frequent_whse   = gv_whse)
                               -- 検索条件：代表倉庫区分が'N'
                               OR (gv_frequent_whse_div = 'N'
                                  AND (iiim.segment1 = gv_whse)
                                  AND (xilv_fr.segment1 = iiim.segment1))
                              )
                            )
                         -- 検索条件：倉庫が未入力
                          OR( gv_whse IS NULL
-- 2008/08/01 PT対応 1.1 modify start
                          AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT対応 1.1 modify end
                        )
                   )
      -- 東洋埠頭ユーザータイプ
               OR     (gv_sec_class = gv_sec_class_quay
                    AND (
                          iiim.attribute8 IN
                            (SELECT papf.attribute4            -- 取引先コード(仕入先コード)
                             FROM   fnd_user           fu      -- ユーザーマスタ
                                   ,per_all_people_f   papf    -- 従業員マスタ
                             WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                        OR iiim.attribute8 IN
                            (SELECT xv.segment1                -- 取引先コード(仕入先コード)
                             FROM   fnd_user           fu      -- ユーザーマスタ
                                   ,per_all_people_f   papf    -- 従業員マスタ
                                   ,xxcmn_vendors_v    xv      -- 仕入先情報VIEW
                             WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xv.spare3                  = papf.attribute4        -- 取引先コード(関連取引)
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                        )
                    AND (
                          -- 検索条件：倉庫が入力済
                          (gv_whse IS NOT NULL
                      AND xilv_fr.segment1 = gv_whse
-- 2008/08/01 PT対応 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1
-- 2008/08/01 PT対応 1.1 modify end
                          )
                      -- 検索条件：倉庫が未入力
                      OR (gv_whse IS NULL
-- 2008/08/01 PT対応 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT対応 1.1 modify end
                        )
                   )
             )
      -- 抽出条件(検索値)
      -- 取引先
      AND   ((gv_vendor_id IS NULL) OR (iiim.attribute8 = gv_vendor_id))
      -- 品目
      AND   ((gv_item_no IS NULL) OR (iiim.item_no = gv_item_no))
      -- ロット
      AND   ((gv_lot_no IS NULL) OR (iiim.lot_no = gv_lot_no))
      -- 製造日
      AND   ((gv_manufacture_date IS NULL) OR (iiim.attribute1 = gv_manufacture_date))
      -- 賞味期限
      AND   ((gv_expiration_date IS NULL) OR (iiim.attribute3 = gv_expiration_date))
      -- 固有記号
      AND   ((gv_uniqe_sign IS NULL) OR (iiim.attribute2 = gv_uniqe_sign))
      -- 製造工場
      AND   ((gv_mf_factory IS NULL) OR (iiim.attribute20 = gv_mf_factory))
      -- 製造ロット番号
      AND   ((gv_mf_lot IS NULL) OR (iiim.attribute21 = gv_mf_lot))
      -- 産地
      AND   ((gv_home IS NULL) OR (iiim.attribute12 = gv_home))
      -- R1
      AND   ((gv_r1 IS NULL) OR (iiim.attribute14 = gv_r1))
      -- R2
      AND   ((gv_r2 IS NULL) OR (iiim.attribute15 = gv_r2))
      ORDER BY TO_NUMBER(iiim.attribute8),
               iiim.item_no,
-- 2008/08/01 PT対応 1.1 modify start
               --TO_NUMBER(iiim.lot_id);
               TO_NUMBER(DECODE(iiim.lot_ctl, gv_lot_code0, '0', iiim.lot_no));
-- 2008/08/01 PT対応 1.1 modify end
*/
    CURSOR mst_data_cur
    IS
      SELECT  iiim.segment1                                            AS segment1          -- 保管倉庫コード
             ,iiim.inventory_location_id                               AS inventory_location_id -- 保管倉庫ID
             ,NVL(ili.loct_onhand, cn_zero)                            AS loct_onhand       -- 手持数量
             ,iiim.attribute8                                          AS vendor_code       -- 取引先(DFF8)
             ,REPLACE(iiim.vendor_full_name,gv_sep_com)                AS vendor_full_name  -- 正式名(仕入先)
             ,REPLACE(iiim.vendor_short_name,gv_sep_com)               AS vendor_short_name -- 略称(仕入先)
             ,iiim.item_id                                             AS item_id           -- 品目ID
             ,iiim.item_no                                             AS item_no           -- 品目コード
             ,REPLACE(iiim.item_name,gv_sep_com)                       AS item_name         -- 品名・正式名
             ,REPLACE(iiim.item_short_name,gv_sep_com)                 AS item_short_name   -- 品名・略称
             ,iiim.lot_id                                              AS lot_id            -- ロットID
             ,DECODE(iiim.lot_ctl, gv_lot_code0, NULL, iiim.lot_no)    AS lot_no            -- ロットNo
/* 2008/08/19 Mod ↓
             ,FND_DATE.STRING_TO_DATE(iiim.attribute1, gv_date_format) AS product_date      -- 製造年月日(DFF1)
             ,FND_DATE.STRING_TO_DATE(iiim.attribute3, gv_date_format) AS use_by_date       -- 賞味期限(DFF3)
2008/08/19 Mod ↑ */
             ,iiim.attribute1                                          AS product_date      -- 製造年月日(DFF1)
             ,iiim.attribute3                                          AS use_by_date       -- 賞味期限(DFF3)
             ,iiim.attribute2                                          AS original_char     -- 固有記号(DFF2)
             ,iiim.attribute20                                         AS manu_factory      -- 製造工場(DFF20)
             ,iiim.attribute21                                         AS manu_lot          -- 製造ロット(DFF21)
             ,iiim.attribute12                                         AS home              -- 産地(DFF12)
             ,iiim.attribute14                                         AS rank1             -- ランク1(DFF14)
             ,iiim.attribute15                                         AS rank2             -- ランク2(DFF15)
             ,REPLACE(iiim.attribute18,gv_sep_com)                     AS description       -- 摘要(DFF18)
             ,iiim.attribute22                                         AS qt_inspect_req_no -- 検査依頼番号(DFF22)
/* 2008/08/19 Mod ↓
             ,FND_DATE.STRING_TO_DATE(iiim.inspect_due_date1, gv_date_format) AS inspect_due_date1 -- 検査予定日1
             ,FND_DATE.STRING_TO_DATE(iiim.test_date1, gv_date_format)        AS test_date1        -- 検査日1
2008/08/19 Mod ↑ */
             ,TO_CHAR(iiim.inspect_due_date1, gv_date_format)          AS inspect_due_date1 -- 検査予定日1
             ,TO_CHAR(iiim.test_date1, gv_date_format)                 AS test_date1        -- 検査日1
             ,iiim.qt_effect1                                          AS qt_effect1        -- 結果1
/* 2008/08/19 Mod ↓
             ,FND_DATE.STRING_TO_DATE(iiim.inspect_due_date2, gv_date_format) AS inspect_due_date2 -- 検査予定日2
             ,FND_DATE.STRING_TO_DATE(iiim.test_date2, gv_date_format)  AS test_date2        -- 検査日2
2008/08/19 Mod ↑ */
             ,TO_CHAR(iiim.inspect_due_date2, gv_date_format)          AS inspect_due_date2 -- 検査予定日2
             ,TO_CHAR(iiim.test_date2, gv_date_format)                 AS test_date2        -- 検査日2
             ,iiim.qt_effect2                                          AS qt_effect2        -- 結果2
/* 2008/08/19 Mod ↓
             ,FND_DATE.STRING_TO_DATE(iiim.inspect_due_date3, gv_date_format) AS inspect_due_date3 -- 検査予定日3
             ,FND_DATE.STRING_TO_DATE(iiim.test_date3, gv_date_format)        AS test_date3        -- 検査日3
2008/08/19 Mod ↑ */
             ,TO_CHAR(iiim.inspect_due_date3, gv_date_format)          AS inspect_due_date3 -- 検査予定日3
             ,TO_CHAR(iiim.test_date3, gv_date_format)                 AS test_date3        -- 検査日3
             ,iiim.qt_effect3                                          AS qt_effect3        -- 結果3
      FROM   (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_name,             -- 品名・正式名
                     ximv.item_short_name,       -- 品名・略称
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute8,
                     ilm.attribute12,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute18,
                     ilm.attribute20,
                     ilm.attribute21,
                     ilm.attribute22,
                     xvv.vendor_full_name,       -- 正式名(仕入先)
                     xvv.vendor_short_name,      -- 略称(仕入先)
                     xqi.inspect_due_date1,      -- 検査予定日1
                     xqi.test_date1,             -- 検査日1
                     xqi.qt_effect1,             -- 結果1
                     xqi.inspect_due_date2,      -- 検査予定日2
                     xqi.test_date2,             -- 検査日2
                     xqi.qt_effect2,             -- 結果2
                     xqi.inspect_due_date3,      -- 検査予定日3
                     xqi.test_date3,             -- 検査日3
                     xqi.qt_effect3              -- 結果3
              FROM   xxcmn_item_mst_v         ximv,    -- OPM品目マスタ情報VIEW
                     ic_lots_mst              ilm,     -- OPMロットマスタ
                     xxcmn_item_locations_v   xilv,    -- OPM保管場所情報VIEW
                     xxcmn_item_categories5_v xicv,    -- OPM品目カテゴリ割当情報VIEW5
                     xxwip_qt_inspection      xqi,     -- 品質検査依頼情報
                     xxcmn_vendors_v          xvv      -- 仕入先情報
              WHERE  ximv.item_id            = ilm.item_id
              -- 品目区分(必須)
              AND    xicv.item_class_code    = gv_item_class
              -- 商品区分(必須)
              AND    xicv.prod_class_code    = gv_prod_class
              AND    xicv.item_id            = ximv.item_id
              AND  ((ximv.lot_ctl            = gv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = gv_lot_code0)
              AND    ilm.attribute8          = xvv.segment1(+)
              AND    TO_NUMBER(ilm.attribute22) = xqi.qt_inspect_req_no(+)
              -- セキュリティ区分
              AND    (
                -- 伊藤園ユーザータイプ
                   (gv_sec_class = gv_sec_class_home
                     AND (
                          (gv_whse IS NULL)
                        OR (
                             -- 検索条件：代表倉庫区分が'Y'
                             (gv_frequent_whse_div = 'Y'
                                AND ( EXISTS (SELECT '1'
                                             FROM   xxcmn_item_locations_v xilv_fr1
                                             WHERE  xilv.frequent_whse     = xilv_fr1.segment1
                                             AND    xilv_fr1.frequent_whse = gv_whse)
                                    OR( (xilv.frequent_whse     = lv_prof_xdfw)      -- ダミー代表倉庫
                                      AND ( EXISTS (SELECT '1'
                                                   FROM  xxwsh_frq_item_locations xfil -- 品目別保管倉庫
                                                        ,xxcmn_item_locations_v xilv_fr2
                                                   WHERE xfil.item_location_code     = xilv.segment1
                                                   AND   xfil.item_id                = ximv.item_id
                                                   AND   xfil.frq_item_location_code = xilv_fr2.segment1
                                                   AND   xilv_fr2.frequent_whse      = gv_whse)))))
                                -- 検索条件：代表倉庫区分が'N'
                                OR (gv_frequent_whse_div = 'N'
                                   AND xilv.segment1 = gv_whse)
                           )
                         )
                   )
                -- 仕入先ユーザータイプ
               OR  (gv_sec_class = gv_sec_class_vend
                      AND ilm.attribute8 IN
                        (SELECT papf.attribute4            -- 取引先コード(仕入先コード)
                         FROM   fnd_user           fu      -- ユーザーマスタ
                               ,per_all_people_f   papf    -- 従業員マスタ
                         WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                         AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                         AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                         AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                         AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                           OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                         AND    fu.user_id                 = gn_user_id)            -- ユーザーID
                      AND (
                         -- 検索条件：倉庫が入力済
                            (gv_whse IS NULL)
                         OR (xilv.segment1 = gv_whse)
                          )
                   )
                -- 外部倉庫ユーザータイプ
               OR  (gv_sec_class = gv_sec_class_extn
                      AND (
                          xilv.segment1 IN
                            (SELECT xilv2.segment1                     -- 保管倉庫コード
                             FROM   fnd_user               fu          -- ユーザーマスタ
                                   ,per_all_people_f       papf        -- 従業員マスタ
                                   ,xxcmn_item_locations_v xilv2       -- OPM保管場所情報VIEW
                             WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xilv.purchase_code         = papf.attribute4        -- 仕入先コード
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                        OR xilv.segment1 IN
                            (SELECT xvs.vendor_stock_whse              -- 相手先在庫入庫先
                             FROM   fnd_user               fu          -- ユーザーマスタ
                                   ,per_all_people_f       papf        -- 従業員マスタ
                                   ,xxcmn_vendor_sites_v   xvs         -- 仕入先サイト情報VIEW
                             WHERE  fu.employee_id             = papf.person_id         -- 従業員ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xvs.vendor_id              = papf.attribute4        -- 仕入先コード
                             AND    xvs.vendor_site_code       = papf.attribute6        -- 仕入先サイト名
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                         )
                      AND (
                            -- 検索条件：倉庫が入力済
                            (gv_whse IS NULL)
                          OR (
                               -- 検索条件：代表倉庫区分が'Y'
                             (gv_frequent_whse_div = 'Y'
                                AND ((EXISTS (SELECT '1'
                                             FROM   xxcmn_item_locations_v xilv_fr3
                                             WHERE  xilv.frequent_whse     = xilv_fr3.segment1
                                             AND    xilv_fr3.frequent_whse = gv_whse))
                                    OR(   (xilv.frequent_whse     = lv_prof_xdfw)      -- ダミー代表倉庫
                                      AND ( EXISTS (SELECT '1'
                                                   FROM  xxwsh_frq_item_locations xfil -- 品目別保管倉庫
                                                        ,xxcmn_item_locations_v xilv_fr4
                                                   WHERE xfil.item_location_code     = xilv.segment1
                                                   AND   xfil.item_id                = ximv.item_id
                                                   AND   xfil.frq_item_location_code = xilv_fr4.segment1
                                                   AND   xilv_fr4.frequent_whse      = gv_whse)))))
                             -- 検索条件：代表倉庫区分が'N'
                             OR (gv_frequent_whse_div = 'N'
                                AND xilv.segment1 = gv_whse)
                            )
                          )
                   )
                -- 東洋埠頭ユーザータイプ
                   OR     (gv_sec_class = gv_sec_class_quay
                     AND (
                          ilm.attribute8 IN
                            (SELECT papf.attribute4            -- 取引先コード(仕入先コード)
                             FROM   fnd_user           fu      -- ユーザーマスタ
                                   ,per_all_people_f   papf    -- 従業員マスタ
                             WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                        OR ilm.attribute8 IN
                            (SELECT xv.segment1                -- 取引先コード(仕入先コード)
                             FROM   fnd_user           fu      -- ユーザーマスタ
                                   ,per_all_people_f   papf    -- 従業員マスタ
                                   ,xxcmn_vendors_v    xv      -- 仕入先情報VIEW
                             WHERE  fu.employee_id   = papf.person_id                   -- 従業員ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- 適用終了日
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- 適用開始日
                             AND  ((fu.end_date               IS NULL)                  -- 適用終了日
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xv.spare3                  = papf.attribute4        -- 取引先コード(関連取引)
                             AND    fu.user_id                 = gn_user_id             -- ユーザーID
                            )
                        )
                    AND (
                          -- 検索条件：倉庫が入力済
                         ((gv_whse IS NULL)
                      OR  (xilv.segment1 = gv_whse))
                        )
                   )
             )) iiim,
            ic_loct_inv              ili     -- OPM手持数量
      -- 抽出条件(検索値)
      WHERE  
             iiim.item_id            = ili.item_id(+)
      AND    iiim.segment1           = ili.location(+)
      AND    iiim.lot_id             = ili.lot_id(+)
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 取引先
      AND   ((gv_vendor_id IS NULL) OR (iiim.attribute8 = gv_vendor_id))
      -- 品目
      AND   ((gv_item_no IS NULL) OR (iiim.item_no = gv_item_no))
      -- ロット
      AND   ((gv_lot_no IS NULL) OR (iiim.lot_no = gv_lot_no))
      -- 製造日
      AND   ((gv_manufacture_date IS NULL) OR (iiim.attribute1 = gv_manufacture_date))
      -- 賞味期限
      AND   ((gv_expiration_date IS NULL) OR (iiim.attribute3 = gv_expiration_date))
      -- 固有記号
      AND   ((gv_uniqe_sign IS NULL) OR (iiim.attribute2 = gv_uniqe_sign))
      -- 製造工場
      AND   ((gv_mf_factory IS NULL) OR (iiim.attribute20 = gv_mf_factory))
      -- 製造ロット番号
      AND   ((gv_mf_lot IS NULL) OR (iiim.attribute21 = gv_mf_lot))
      -- 産地
      AND   ((gv_home IS NULL) OR (iiim.attribute12 = gv_home))
      -- R1
      AND   ((gv_r1 IS NULL) OR (iiim.attribute14 = gv_r1))
      -- R2
      AND   ((gv_r2 IS NULL) OR (iiim.attribute15 = gv_r2))
      ORDER BY TO_NUMBER(iiim.attribute8),
               iiim.item_no,
               TO_NUMBER(DECODE(iiim.lot_ctl, gv_lot_code0, '0', iiim.lot_no));
-- 2008/08/03 PT対応 1.2 modify end
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
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
    ln_cnt := 1;
-- 2008/08/01 PT対応 1.1 modify start
    ln_vendor_code := NULL;
    ln_item_no := NULL;
    ln_lot_no := NULL;
-- 2008/08/01 PT対応 1.1 modify end
    -- プロファイル値取得
--
    gn_user_id             := FND_GLOBAL.USER_ID;
    gd_sys_date            := SYSDATE;
--
    lv_prof_xdfw := FND_PROFILE.VALUE('XXCMN_DUMMY_FREQUENT_WHSE');
    ln_prof_xtt  := FND_PROFILE.VALUE('XXINV_TARGET_TERM');
    -- プロファイルより取得した日数から、在庫照会対象日付を算出
    ld_target_date := TRUNC(SYSDATE) - ln_prof_xtt;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
-- 2008/08/01 PT対応 1.1 modify start
      IF ( (ln_vendor_code IS NULL AND ln_item_no IS NULL AND ln_lot_no IS NULL)
        OR (NOT (ln_vendor_code = lr_mst_data_rec.vendor_code
        AND ln_item_no     = lr_mst_data_rec.item_no
        AND ln_lot_no      = lr_mst_data_rec.lot_no))) THEN
--
        ln_stock_vol := 0;
        ln_supply_stock_plan := 0;
        lv_target_flg := '0';
--
        -- 手持在庫数、入庫予定数チェック処理
        IF ((gv_sec_class IN(gv_sec_class_home,gv_sec_class_vend,gv_sec_class_quay)
               AND (gv_whse IS NOT NULL))
             OR (gv_sec_class = gv_sec_class_extn)) THEN
          -- 手持在庫数チェック
          ln_stock_vol := get_inv_stock_vol(
                            lr_mst_data_rec.inventory_location_id,
                            lr_mst_data_rec.item_no,
                            lr_mst_data_rec.item_id,
                            lr_mst_data_rec.lot_id,
                            lr_mst_data_rec.loct_onhand);
--
          -- 手持在庫数が0以外の場合
          IF (ln_stock_vol = 0) THEN
--
            -- 入庫予定数チェック
            ln_supply_stock_plan := get_supply_stock_plan(
                                      lr_mst_data_rec.segment1,
                                      lr_mst_data_rec.inventory_location_id,
                                      lr_mst_data_rec.item_no,
                                      lr_mst_data_rec.item_id,
                                      lr_mst_data_rec.lot_no,
                                      lr_mst_data_rec.lot_id,
                                      lr_mst_data_rec.loct_onhand);
--
            -- 入庫予定数が0以外の場合
            IF (ln_supply_stock_plan != 0) THEN
              -- 対象データ区分に'1'(対象)を設定
              lv_target_flg := '1';
            END IF;
          ELSE
            -- 対象データ区分に'1'(対象)を設定
            lv_target_flg := '1';
          END IF;
        ELSE
          -- 対象データ区分に'1'(対象)を設定
          lv_target_flg := '1';
        END IF;
--
        -- 対象データ区分が'1'(対象)の場合
        IF (lv_target_flg = '1') THEN
          mst_rec.segment1          := lr_mst_data_rec.segment1;           -- 保管倉庫コード
          mst_rec.vendor_code       := lr_mst_data_rec.vendor_code;        -- 取引先
          mst_rec.vendor_full_name  := lr_mst_data_rec.vendor_full_name;   -- 正式名(仕入先)
          mst_rec.vendor_short_name := lr_mst_data_rec.vendor_short_name;  -- 略称(仕入先)
          mst_rec.item_id           := lr_mst_data_rec.item_id;            -- 品目ID
          mst_rec.item_no           := lr_mst_data_rec.item_no;            -- 品目コード
          mst_rec.item_name         := lr_mst_data_rec.item_name;          -- 品名・正式名
          mst_rec.item_short_name   := lr_mst_data_rec.item_short_name;    -- 品名・略称
          mst_rec.lot_id            := lr_mst_data_rec.lot_id;             -- ロットID
          mst_rec.lot_no            := lr_mst_data_rec.lot_no;             -- ロットNo
          mst_rec.product_date      := lr_mst_data_rec.product_date;       -- 製造年月日
          mst_rec.use_by_date       := lr_mst_data_rec.use_by_date;        -- 賞味期限
          mst_rec.original_char     := lr_mst_data_rec.original_char;      -- 固有記号
          mst_rec.manu_factory      := lr_mst_data_rec.manu_factory;       -- 製造工場
          mst_rec.manu_lot          := lr_mst_data_rec.manu_lot;           -- 製造ロット
          mst_rec.home              := lr_mst_data_rec.home;               -- 産地
          mst_rec.rank1             := lr_mst_data_rec.rank1;              -- ランク1
          mst_rec.rank2             := lr_mst_data_rec.rank2;              -- ランク2
          mst_rec.description       := lr_mst_data_rec.description;        -- 摘要
          mst_rec.qt_inspect_req_no := lr_mst_data_rec.qt_inspect_req_no;  -- 検査依頼番号
          mst_rec.inspect_due_date1 := lr_mst_data_rec.inspect_due_date1;  -- 検査予定日1
          mst_rec.test_date1        := lr_mst_data_rec.test_date1;         -- 検査日1
          mst_rec.qt_effect1        := lr_mst_data_rec.qt_effect1;         -- 結果1
          mst_rec.inspect_due_date2 := lr_mst_data_rec.inspect_due_date2;  -- 検査予定日2
          mst_rec.test_date2        := lr_mst_data_rec.test_date2;         -- 検査日2
          mst_rec.qt_effect2        := lr_mst_data_rec.qt_effect2;         -- 結果2
          mst_rec.inspect_due_date3 := lr_mst_data_rec.inspect_due_date3;  -- 検査予定日3
          mst_rec.test_date3        := lr_mst_data_rec.test_date3;         -- 検査日3
          mst_rec.qt_effect3        := lr_mst_data_rec.qt_effect3;         -- 結果3
--
          gt_master_tbl(ln_cnt) := mst_rec;
          ln_cnt := ln_cnt + 1;
        END IF;
--
      END IF;
--
      ln_vendor_code := lr_mst_data_rec.vendor_code;
      ln_item_no     := lr_mst_data_rec.item_no;
      ln_lot_no      := lr_mst_data_rec.lot_no;
-- 2008/08/01 PT対応 1.1 modify end
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
  END get_lot_inf_proc;
--
  /***********************************************************************************
   * Procedure Name   : csv_file_proc
   * Description      : CSVファイル出力(C-2)
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
    gv_sep_com        CONSTANT VARCHAR2(1)  := ',';
-- add start ver1.4
    lv_crlf           CONSTANT VARCHAR2(1)  := CHR(13); -- 改行コード
-- add end ver1.4
--
    -- *** ローカル変数 ***
    mst_rec         masters_rec;
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
                                            gv_tkn_xxcmn_10119);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ファイル名NULL
    IF (gr_outbound_rec.file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_xxcmn_10120);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ln_len := length(gr_outbound_rec.file_name);
    -- ファイル名称加工(ファイル名-'.CSV'+'_'+'YYYYMMDDHH24MISS'+'.CSV')
    gv_sch_file_name := substr(gr_outbound_rec.file_name,1,ln_len-4)
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
                                            gv_tkn_xxcmn_10114);
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
        -- データ作成
        lv_data := gv_company_name           || gv_sep_com ||  -- 会社名
                   gv_data_class             || gv_sep_com ||  -- データ種別
                   gv_transmission_no        || gv_sep_com ||  -- 伝送用枝番
                   mst_rec.vendor_code       || gv_sep_com ||  -- 取引先
                   mst_rec.vendor_full_name  || gv_sep_com ||  -- 正式名(仕入先)
                   mst_rec.vendor_short_name || gv_sep_com ||  -- 略称(仕入先)
                   mst_rec.item_no           || gv_sep_com ||  -- 品目コード
                   mst_rec.item_name         || gv_sep_com ||  -- 品名・正式名
                   mst_rec.item_short_name   || gv_sep_com ||  -- 品名・略称
                   mst_rec.lot_no            || gv_sep_com ||  -- ロットNo
                   mst_rec.product_date      || gv_sep_com ||  -- 製造年月日
                   mst_rec.use_by_date       || gv_sep_com ||  -- 賞味期限
                   mst_rec.original_char     || gv_sep_com ||  -- 固有記号
                   mst_rec.manu_factory      || gv_sep_com ||  -- 製造工場
                   mst_rec.manu_lot          || gv_sep_com ||  -- 製造ロット
                   mst_rec.home              || gv_sep_com ||  -- 産地
                   mst_rec.rank1             || gv_sep_com ||  -- ランク1
                   mst_rec.rank2             || gv_sep_com ||  -- ランク2
                   mst_rec.description       || gv_sep_com ||  -- 摘要
                   mst_rec.qt_inspect_req_no || gv_sep_com ||  -- 検査依頼番号
                   mst_rec.inspect_due_date1 || gv_sep_com ||  -- 検査予定日1
                   mst_rec.test_date1        || gv_sep_com ||  -- 検査日1
                   mst_rec.qt_effect1        || gv_sep_com ||  -- 結果1
                   mst_rec.inspect_due_date2 || gv_sep_com ||  -- 検査予定日2
                   mst_rec.test_date2        || gv_sep_com ||  -- 検査日2
                   mst_rec.qt_effect2        || gv_sep_com ||  -- 結果2
                   mst_rec.inspect_due_date3 || gv_sep_com ||  -- 検査予定日3
                   mst_rec.test_date3        || gv_sep_com ||  -- 検査日3
-- mod start ver1.4
--                   mst_rec.qt_effect3;                         -- 結果3
                   mst_rec.qt_effect3        || lv_crlf;       -- 結果3
-- mod end ver1.4
--
        -- データ出力
        UTL_FILE.PUT_LINE(lf_file_hand,lv_data);
--
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP file_put_loop;
--
      -- ファイルクローズ
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN       -- ファイルパス不正エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_xxcmn_10113);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.INVALID_FILENAME THEN   -- ファイル名不正エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_xxcmn_10114);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.ACCESS_DENIED OR        -- ファイルアクセス権限エラー
           UTL_FILE.WRITE_ERROR THEN        -- 書き込みエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_xxcmn_10115);
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
   * Description      : ワークフロー通知処理(C-3)
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
                                              gv_tkn_xxcmn_10117);
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
    iv_prod_class        IN            VARCHAR2,  --  4.商品区分          (必須)
    iv_item_class        IN            VARCHAR2,  --  5.品目区分          (必須)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.代表倉庫区分      (任意)
    iv_whse              IN            VARCHAR2,  --  7.倉庫              (任意)
    iv_vendor_id         IN            VARCHAR2,  --  8.取引先            (任意)
    iv_item_no           IN            VARCHAR2,  --  9.品目              (任意)
    iv_lot_no            IN            VARCHAR2,  -- 10.ロット            (任意)
    iv_manufacture_date  IN            VARCHAR2,  -- 11.製造日            (任意)
    iv_expiration_date   IN            VARCHAR2,  -- 12.賞味期限          (任意)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.固有記号          (任意)
    iv_mf_factory        IN            VARCHAR2,  -- 14.製造工場          (任意)
    iv_mf_lot            IN            VARCHAR2,  -- 15.製造ロット        (任意)
    iv_home              IN            VARCHAR2,  -- 16.産地              (任意)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (任意)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (任意)
    iv_sec_class         IN            VARCHAR2,  -- 19.セキュリティ区分  (必須)
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
    lv_tbl_name    CONSTANT VARCHAR2(200) := 'ロット在庫情報';
--
    -- *** ローカル変数 ***
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
    -- パラメータ出力
    parameter_disp(
      iv_wf_ope_div,        --  1.処理区分
      iv_wf_class,          --  2.対象
      iv_wf_notification,   --  3.宛先
      iv_prod_class,        --  4.商品区分
      iv_item_class,        --  5.品目区分
      iv_frequent_whse_div, --  6.代表倉庫区分
      iv_whse,              --  7.倉庫
      iv_vendor_id,         --  8.取引先
      iv_item_no,           --  9.品目
      iv_lot_no,            -- 10.ロット
      iv_manufacture_date,  -- 11.製造日
      iv_expiration_date,   -- 12.賞味期限
      iv_uniqe_sign,        -- 13.固有記号
      iv_mf_factory,        -- 14.製造工場
      iv_mf_lot,            -- 15.製造ロット
      iv_home,              -- 16.産地
      iv_r1,                -- 17.R1
      iv_r2,                -- 18.R2
      iv_sec_class,         -- 19.セキュリティ区分
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      ロット在庫情報取得処理(C-1)      ***
    --*********************************************
    get_lot_inf_proc(
      lv_errbuf,       -- エラー・メッセージ           --# 固定 #
      lv_retcode,      -- リターン・コード             --# 固定 #
      lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- データ取得された場合
    IF (gt_master_tbl.COUNT > 0) THEN
      --*********************************************
      --***        CSVファイル出力(C-2)           ***
      --*********************************************
      csv_file_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    -- データ取得されなかった場合
    ELSE
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_xxpo_10026,
                                            gv_tkn_table,
                                            lv_tbl_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      lv_retcode := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_normal) THEN
      --*********************************************
      --***       Workflow通知処理(C-3)           ***
      --*********************************************
      workflow_start(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
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
    iv_prod_class        IN            VARCHAR2,  --  4.商品区分          (必須)
    iv_item_class        IN            VARCHAR2,  --  5.品目区分          (必須)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.代表倉庫区分      (任意)
    iv_whse              IN            VARCHAR2,  --  7.倉庫              (任意)
    iv_vendor_id         IN            VARCHAR2,  --  8.取引先            (任意)
    iv_item_no           IN            VARCHAR2,  --  9.品目              (任意)
    iv_lot_no            IN            VARCHAR2,  -- 10.ロット            (任意)
    iv_manufacture_date  IN            VARCHAR2,  -- 11.製造日            (任意)
    iv_expiration_date   IN            VARCHAR2,  -- 12.賞味期限          (任意)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.固有記号          (任意)
    iv_mf_factory        IN            VARCHAR2,  -- 14.製造工場          (任意)
    iv_mf_lot            IN            VARCHAR2,  -- 15.製造ロット        (任意)
    iv_home              IN            VARCHAR2,  -- 16.産地              (任意)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (任意)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (任意)
    iv_sec_class         IN            VARCHAR2   -- 19.セキュリティ区分  (必須)
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
      iv_prod_class,        --  4.商品区分
      iv_item_class,        --  5.品目区分
      iv_frequent_whse_div, --  6.代表倉庫区分
      iv_whse,              --  7.倉庫
      iv_vendor_id,         --  8.取引先
      iv_item_no,           --  9.品目
      iv_lot_no,            -- 10.ロット
      iv_manufacture_date,  -- 11.製造日
      iv_expiration_date,   -- 12.賞味期限
      iv_uniqe_sign,        -- 13.固有記号
      iv_mf_factory,        -- 14.製造工場
      iv_mf_lot,            -- 15.製造ロット
      iv_home,              -- 16.産地
      iv_r1,                -- 17.R1
      iv_r2,                -- 18.R2
      iv_sec_class,         -- 19.セキュリティ区分
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
END xxpo940003c;
/
