CREATE OR REPLACE PACKAGE BODY xxwip740001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP740001C(body)
 * Description      : 請求更新処理
 * MD.050           : 運賃計算（月次）   T_MD050_BPO_740
 * MD.070           : 請求更新           T_MD070_BPO_74B
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_related_date       関連データ取得(B-1)
 *  get_deliverys          運賃ヘッダーアドオンデータ取得(B-2、B-8)
 *  get_adj_charges        運賃調整アドオンデータ取得(B-3、B-9)
 *  get_billing            請求先アドオンマスタデータ取得(B-4、B-10)
 *  get_before             前々月、前月データ取得(B-5、B-11)
 *  set_ins_date           登録データ設定(B-6、B-12)
 *  init_plsql             PL/SQL表初期化(B-7)
 *  ins_billing            請求先アドオンマスタ一括登録処理(B-13)
 *  upd_billing            請求先アドオンマスタ一括更新処理(B-14)
 *  sub_submain            サブメイン処理プロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0  Oracle 和田 大輝  初回作成
 *  2008/09/29    1.1  Oracle 吉田 夏樹  T_S_614対応
 *  2008/10/21    1.2  Oracle 野村 正幸  T_S_571対応
 *  2008/11/07    1.3  Oracle 野村 正幸  統合#552、553対応
 *  2008/12/18    1.4  野村 正幸         本番#42対応
 *  2009/01/08    1.5  野村 正幸         本番#960対応
 *  2009/01/13    1.6  野村 正幸         本番#XXX対応（繰越金額計算対応）
 *  2011/02/07    1.7  桐生 和幸         E_本稼動_06520 (同一金額のデータが1行となってしまう障害対応)
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
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100) := 'xxwip740001c'; -- パッケージ名
--
  -- アプリケーション短縮名
  gv_wip_msg_kbn        CONSTANT VARCHAR2(5) := 'XXWIP';
  gv_cmn_msg_kbn        CONSTANT VARCHAR2(5) := 'XXCMN';
--
  -- メッセージ番号(XXWIP)
  gv_wip_msg_74b_005    CONSTANT VARCHAR2(15) := 'APP-XXWIP-10067'; -- プロファイル取得エラー
  gv_wip_msg_74b_004    CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ロックエラー詳細メッセージ
  gv_cmn_msg_notfnd     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- 対象データなし
  gv_cmn_msg_toomny     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10137'; -- 対象データが複数
--
  -- トークン
  gv_tkn_ng_profile     CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  gv_tkn_table          CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key            CONSTANT VARCHAR2(10) := 'KEY';
--
  -- トークン値
  gv_billing_dummy_name CONSTANT VARCHAR2(30) := '請求年月ダミーキー';
  gv_billing_mst_name   CONSTANT VARCHAR2(30) := '請求先アドオンマスタ';
--
  -- プロファイル・オプション
  gv_charge_dmy         CONSTANT VARCHAR2(23) := 'XXWIP_CHARGE_YYYYMM_DMY';  -- 請求年月ダミーキー
--
  -- 消費税区分
  gv_cons_tax_cls_month    CONSTANT VARCHAR2(1) := '1'; -- 月
  gv_cons_tax_cls_detail   CONSTANT VARCHAR2(1) := '2'; -- 明細
--
  -- 消費税率タイプ
  gv_cons_tax_rate_type    CONSTANT VARCHAR2(26) := 'XXCMN_CONSUMPTION_TAX_RATE';
--
  -- 四捨五入区分
  gv_half_adjust_cls_up    CONSTANT VARCHAR2(1) := '1';   -- 切り上げ
  gv_half_adjust_cls_down  CONSTANT VARCHAR2(1) := '2';   -- 切り捨て
  gv_half_adjust_cls_rnd   CONSTANT VARCHAR2(1) := '3';   -- 四捨五入
--
  -- 支払請求区分
  gv_p_b_cls_bil           CONSTANT VARCHAR2(1) := '2';    -- 請求
--
  -- 請求非課税
  gv_tax_free_bil_off      CONSTANT VARCHAR2(1) := '0';    -- OFF
  gv_tax_free_bil_on       CONSTANT VARCHAR2(1) := '1';    -- ON
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 請求先アドオンマスタ設定用マスタレコード
  TYPE masters_rec IS RECORD(
    billing_code           xxwip_billing_mst.billing_code%TYPE,             -- 請求先コード
    billing_date           VARCHAR2(6),                                     -- 請求年月
    charged_amt_sum        NUMBER,                                          -- 今月売上額
    consumption_tax        NUMBER,                                          -- 消費税
    cong_charge_sum        NUMBER,                                          -- 通行料等
    amount_bil_sum         NUMBER,                                          -- 請求調整合計額
    tax_bil_sum            NUMBER,                                          -- 課税調整合計
    tax_free_bil_sum       NUMBER,                                          -- 非課税調整合計
    adj_tax_extra_sum      NUMBER,                                          -- 消費税調整合計
--
    billing_name           xxwip_billing_mst.billing_name%TYPE,             -- 請求先名
    post_no                xxwip_billing_mst.post_no%TYPE,                  -- 郵便番号
    address                xxwip_billing_mst.address%TYPE,                  -- 住所
    telephone_no           xxwip_billing_mst.telephone_no%TYPE,             -- 電話番号
    fax_no                 xxwip_billing_mst.fax_no%TYPE,                   -- FAX番号
    money_transfer_date    xxwip_billing_mst.money_transfer_date%TYPE,      -- 振込日
    amount_receipt_money   xxwip_billing_mst.amount_receipt_money%TYPE,     -- 今回入金額
    amount_adjustment      xxwip_billing_mst.amount_adjustment%TYPE,        -- 調整額
    condition_setting_date xxwip_billing_mst.condition_setting_date%TYPE,   -- 支払条件設定日
    charged_amount         xxwip_billing_mst.charged_amount%TYPE            -- 今回請求金額
  );
--
  -- 四捨五入区分別設定用レコード
  TYPE billing_rec IS RECORD(
    billing_code           xxwip_billing_mst.billing_code%TYPE,             -- 請求先コード
    judgement_yyyymm       VARCHAR2(6),                                     -- 請求年月
    consumption_tax_classe xxwip_delivery_company.consumption_tax_classe%TYPE, -- 消費税区分
    charged_amt_sum        NUMBER,                                          -- 今月売上額
    detail_tax             NUMBER,                                          -- 消費税（明細）
    month_tax              NUMBER,                                          -- 消費税（月）
    cong_charge_sum        NUMBER,                                          -- 通行料等
    amount_bil_sum         NUMBER,                                          -- 請求調整合計額
    tax_bil_sum            NUMBER,                                          -- 課税調整合計
    adj_tax_extra_sum      NUMBER                                           -- 消費税調整合計
  );
--
  -- 対象データ情報を格納するテーブル型の定義
  TYPE masters_tbl   IS TABLE OF masters_rec     INDEX BY PLS_INTEGER;
  TYPE billing_tbl   IS TABLE OF billing_rec     INDEX BY PLS_INTEGER;
--
  gt_masters_tbl     masters_tbl;
  gt_billing_tbl     billing_tbl;
--
  -- *********************************************************************
  -- * 請求先アドオンマスタ
  -- *********************************************************************
  -- 登録PL/SQL表型
  -- 請求先アドオンマスタID
  TYPE i_bil_bil_mst_id_type       IS TABLE OF xxwip_billing_mst.billing_mst_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求先コード
  TYPE i_bil_bil_code_type         IS TABLE OF xxwip_billing_mst.billing_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求先名
  TYPE i_bil_bil_name_type         IS TABLE OF xxwip_billing_mst.billing_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求年月
  TYPE i_bil_bil_date_type         IS TABLE OF xxwip_billing_mst.billing_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 郵便番号
  TYPE i_bil_post_no_type          IS TABLE OF xxwip_billing_mst.post_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 住所
  TYPE i_bil_address_type          IS TABLE OF xxwip_billing_mst.address%TYPE
  INDEX BY BINARY_INTEGER;
  -- 電話番号
  TYPE i_bil_tel_no_type           IS TABLE OF xxwip_billing_mst.telephone_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- FAX番号
  TYPE i_bil_fax_no_type           IS TABLE OF xxwip_billing_mst.fax_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振込日
  TYPE i_bil_my_tran_dt_type       IS TABLE OF xxwip_billing_mst.money_transfer_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払条件設定日
  TYPE i_bil_cn_set_dt_type        IS TABLE OF xxwip_billing_mst.condition_setting_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 前月請求額
  TYPE i_bil_lt_mt_chrg_amt_type   IS TABLE OF xxwip_billing_mst.last_month_charge_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 今回入金額
  TYPE i_bil_amt_rcp_my_type       IS TABLE OF xxwip_billing_mst.amount_receipt_money%TYPE
  INDEX BY BINARY_INTEGER;
  -- 調整額
  TYPE i_bil_amt_adjt_type         IS TABLE OF xxwip_billing_mst.amount_adjustment%TYPE
  INDEX BY BINARY_INTEGER;
  -- 繰越額
  TYPE i_bil_blc_crd_fw_type       IS TABLE OF xxwip_billing_mst.balance_carried_forward%TYPE
  INDEX BY BINARY_INTEGER;
  -- 今回請求金額
  TYPE i_bil_chrg_amt_type         IS TABLE OF xxwip_billing_mst.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求金額合計
  TYPE i_bil_chrg_amt_ttl_type     IS TABLE OF xxwip_billing_mst.charged_amount_total%TYPE
  INDEX BY BINARY_INTEGER;
  -- 今月売上額
  TYPE i_bil_month_sales_type      IS TABLE OF xxwip_billing_mst.month_sales%TYPE
  INDEX BY BINARY_INTEGER;
  -- 消費税
  TYPE i_bil_consumption_tax_type  IS TABLE OF xxwip_billing_mst.consumption_tax%TYPE
  INDEX BY BINARY_INTEGER;
  -- 通行料等
  TYPE i_bil_cn_chrg_type          IS TABLE OF xxwip_billing_mst.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_bil_bil_mst_id_tab             i_bil_bil_mst_id_type;           -- 請求先アドオンマスタID
  i_bil_bil_code_tab               i_bil_bil_code_type;             -- 請求先コード
  i_bil_bil_name_tab               i_bil_bil_name_type;             -- 請求先名
  i_bil_bil_date_tab               i_bil_bil_date_type;             -- 請求年月
  i_bil_post_no_tab                i_bil_post_no_type;              -- 郵便番号
  i_bil_address_tab                i_bil_address_type;              -- 住所
  i_bil_tel_no_tab                 i_bil_tel_no_type;               -- 電話番号
  i_bil_fax_no_tab                 i_bil_fax_no_type;               -- FAX番号
  i_bil_my_tran_dt_tab             i_bil_my_tran_dt_type;           -- 振込日
  i_bil_cn_set_dt_tab              i_bil_cn_set_dt_type;            -- 支払条件設定日
  i_bil_lt_mt_chrg_amt_tab         i_bil_lt_mt_chrg_amt_type;       -- 前月請求額
  i_bil_amt_adjt_tab               i_bil_amt_adjt_type;             -- 調整額
  i_bil_amt_rcp_my_tab             i_bil_amt_rcp_my_type;           -- 今回入金額
  i_bil_blc_crd_fw_tab             i_bil_blc_crd_fw_type;           -- 繰越額
  i_bil_chrg_amt_tab               i_bil_chrg_amt_type;             -- 今回請求金額
  i_bil_chrg_amt_ttl_tab           i_bil_chrg_amt_ttl_type;         -- 請求金額合計
  i_bil_month_sales_tab            i_bil_month_sales_type;          -- 今月売上額
  i_bil_consumption_tax_tab        i_bil_consumption_tax_type;      -- 消費税
  i_bil_cn_chrg_tab                i_bil_cn_chrg_type;              -- 通行料等
--
  -- 更新PL/SQL表型
  -- 請求先アドオンマスタID
  TYPE u_bil_bil_mst_id_type       IS TABLE OF xxwip_billing_mst.billing_mst_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求先コード
  TYPE u_bil_bil_code_type         IS TABLE OF xxwip_billing_mst.billing_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求先名
  TYPE u_bil_bil_name_type         IS TABLE OF xxwip_billing_mst.billing_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求年月
  TYPE u_bil_bil_date_type         IS TABLE OF xxwip_billing_mst.billing_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 郵便番号
  TYPE u_bil_post_no_type          IS TABLE OF xxwip_billing_mst.post_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 住所
  TYPE u_bil_address_type          IS TABLE OF xxwip_billing_mst.address%TYPE
  INDEX BY BINARY_INTEGER;
  -- 電話番号
  TYPE u_bil_tel_no_type           IS TABLE OF xxwip_billing_mst.telephone_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- FAX番号
  TYPE u_bil_fax_no_type           IS TABLE OF xxwip_billing_mst.fax_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振込日
  TYPE u_bil_my_tran_dt_type       IS TABLE OF xxwip_billing_mst.money_transfer_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払条件設定日
  TYPE u_bil_cn_set_dt_type        IS TABLE OF xxwip_billing_mst.condition_setting_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 前月請求額
  TYPE u_bil_lt_mt_chrg_amt_type   IS TABLE OF xxwip_billing_mst.last_month_charge_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 今回入金額
  TYPE u_bil_amt_rcp_my_type       IS TABLE OF xxwip_billing_mst.amount_receipt_money%TYPE
  INDEX BY BINARY_INTEGER;
  -- 調整額
  TYPE u_bil_amt_adjt_type         IS TABLE OF xxwip_billing_mst.amount_adjustment%TYPE
  INDEX BY BINARY_INTEGER;
  -- 繰越額
  TYPE u_bil_blc_crd_fw_type       IS TABLE OF xxwip_billing_mst.balance_carried_forward%TYPE
  INDEX BY BINARY_INTEGER;
  -- 今回請求金額
  TYPE u_bil_chrg_amt_type         IS TABLE OF xxwip_billing_mst.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求金額合計
  TYPE u_bil_chrg_amt_ttl_type     IS TABLE OF xxwip_billing_mst.charged_amount_total%TYPE
  INDEX BY BINARY_INTEGER;
  -- 今月売上額
  TYPE u_bil_month_sales_type      IS TABLE OF xxwip_billing_mst.month_sales%TYPE
  INDEX BY BINARY_INTEGER;
  -- 消費税
  TYPE u_bil_consumption_tax_type  IS TABLE OF xxwip_billing_mst.consumption_tax%TYPE
  INDEX BY BINARY_INTEGER;
  -- 通行料等
  TYPE u_bil_cn_chrg_type          IS TABLE OF xxwip_billing_mst.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_bil_bil_mst_id_tab             u_bil_bil_mst_id_type;           -- 請求先アドオンマスタID
  u_bil_bil_code_tab               u_bil_bil_code_type;             -- 請求先コード
  u_bil_bil_name_tab               u_bil_bil_name_type;             -- 請求先名
  u_bil_bil_date_tab               u_bil_bil_date_type;             -- 請求年月
  u_bil_post_no_tab                u_bil_post_no_type;              -- 郵便番号
  u_bil_address_tab                u_bil_address_type;              -- 住所
  u_bil_tel_no_tab                 u_bil_tel_no_type;               -- 電話番号
  u_bil_fax_no_tab                 u_bil_fax_no_type;               -- FAX番号
  u_bil_my_tran_dt_tab             u_bil_my_tran_dt_type;           -- 振込日
  u_bil_cn_set_dt_tab              u_bil_cn_set_dt_type;            -- 支払条件設定日
  u_bil_lt_mt_chrg_amt_tab         u_bil_lt_mt_chrg_amt_type;       -- 前月請求額
  u_bil_amt_rcp_my_tab             u_bil_amt_rcp_my_type;           -- 今回入金額
  u_bil_amt_adjt_tab               u_bil_amt_adjt_type;             -- 調整額
  u_bil_blc_crd_fw_tab             u_bil_blc_crd_fw_type;           -- 繰越額
  u_bil_chrg_amt_tab               u_bil_chrg_amt_type;             -- 今回請求金額
  u_bil_chrg_amt_ttl_tab           u_bil_chrg_amt_ttl_type;         -- 請求金額合計
  u_bil_month_sales_tab            u_bil_month_sales_type;          -- 今月売上額
  u_bil_consumption_tax_tab        u_bil_consumption_tax_type;      -- 消費税
  u_bil_cn_chrg_tab                u_bil_cn_chrg_type;              -- 通行料等
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_sysdate               DATE;            -- システム日付
  gn_user_id               NUMBER;          -- ユーザID
  gn_login_id              NUMBER;          -- ログインID
  gn_conc_request_id       NUMBER;          -- コンカレント要求ID
  gn_prog_appl_id          NUMBER;          -- コンカレント・プログラム・アプリケーションID
  gn_conc_program_id       NUMBER;          -- コンカレント・プログラムID
--
  gv_close_type            VARCHAR2(1);     -- 締め区分
  gv_charge_dmy_key        VARCHAR2(6);     -- 請求年月ダミーキー
  gv_consumption_tax       VARCHAR2(2);     -- 消費税率（単位 %）
--
  gn_i_bil_tab_cnt         NUMBER;          -- 請求先アドオンマスタ 登録PL/SQL表カウンター
  gn_u_bil_tab_cnt         NUMBER;          -- 請求先アドオンマスタ 更新PL/SQL表カウンター
--
  /**********************************************************************************
   * Procedure Name   : get_related_date
   * Description      : 関連データ取得(B-1)
   ***********************************************************************************/
  PROCEDURE get_related_date(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_related_date'; -- プログラム名
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
    lv_charge_dmy_key        VARCHAR2(6);      -- 請求年月ダミーキー
    lv_close_type            VARCHAR2(1);      -- 締め区分（Y：締め前、N：締め後）
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
    gd_sysdate          := SYSDATE;                    -- システム日時
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ログインID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- コンカレント要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    -- ***********************************************
    -- プロファイル：請求年月ダミーキー 取得
    -- ***********************************************
    lv_charge_dmy_key := FND_PROFILE.VALUE(gv_charge_dmy);
--
    IF (lv_charge_dmy_key IS NULL) THEN -- プロファイルが取得できない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                            gv_wip_msg_74b_005,
                                            gv_tkn_ng_profile,
                                            gv_billing_dummy_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gv_charge_dmy_key := lv_charge_dmy_key;   -- グローバル変数に設定
--
    -- ***********************************************
    -- 締日取得
    -- ***********************************************
    xxwip_common3_pkg.check_lastmonth_close(
      lv_close_type  -- 締め区分
     ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
     ,lv_retcode     -- リターン・コード             --# 固定 #
     ,lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> gv_status_normal) THEN -- 共通関数エラー
      RAISE global_api_expt;
    END IF;
--
    gv_close_type := lv_close_type;   -- グローバル変数に設定
--
    -- ***********************************************
    -- 消費税率を取得（単位は%）
    -- ***********************************************
    BEGIN 
      SELECT  xlvv.lookup_code
      INTO    gv_consumption_tax
      FROM    xxcmn_lookup_values_v  xlvv      -- ルックアップ（消費税率用）
      WHERE   xlvv.lookup_type  = gv_cons_tax_rate_type;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                              gv_cmn_msg_notfnd,
                                              gv_tkn_table,
                                              'xxcmn_lookup_values_v',
                                              gv_tkn_key,
                                              gv_cons_tax_rate_type);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN   --*** データ複数取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                              gv_cmn_msg_toomny,
                                              gv_tkn_table,
                                              'xxcmn_lookup_values_v',
                                              gv_tkn_key,
                                              gv_cons_tax_rate_type);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
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
  END get_related_date;
--
  /**********************************************************************************
   * Procedure Name   : get_deliverys
   * Description      : 運賃ヘッダーアドオンデータ取得(B-2、B-8)
   ***********************************************************************************/
  PROCEDURE get_deliverys(
    id_sysdate    IN  DATE,         --   日付
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliverys'; -- プログラム名
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
    -- ==============================================================
    -- 商品区分、運送業者、消費税区分、請求先コード、請求年月単位で
    -- 運賃ヘッダアドオンを集計
    --  ※この時点では明細毎の消費税のみ算出する
    -- ==============================================================
--
    SELECT
-- ##### 20081021 Ver.1.2 T_S_571対応 START #####
/*****  項目別名付与の為、コメントアウト
        dhc.billing_code              -- 請求先コード
      , dhc.judgement_yyyymm          -- 請求年月
*****/
        dhc.billing_code      AS billing_code     -- 請求先コード
      , dhc.judgement_yyyymm  AS billing_date     -- 請求年月
-- ##### 20081021 Ver.1.2 T_S_571対応 END   #####
      , dhc.consumption_tax_classe    -- 消費税区分
-- ##### 20081107 Ver.1.12 統合#552、553対応 START #####
--      , SUM(dhc.charged_amount)       -- 今月売上額
      , SUM(dhc.total_amount)         -- 今月売上額（請求データの合計のサマリ）
-- ##### 20081107 Ver.1.12 統合#552、553対応 END   #####
-- 2008/09/29 1.1 N.Yoshida start
      --, SUM(dhc.line_tax)             -- 消費税（明細）
      , NULL                          -- 消費税（明細）
      , NULL                          -- 消費税（月）   (ここでは NULL を設定)
      , SUM(dhc.congestion_charge)    -- 通行料等
      , NULL                          -- 請求調整合計額 (ここでは NULL を設定)
      , NULL                          -- 課税調整額     (ここでは NULL を設定)
      , NULL                          -- 消費税調整額   (ここでは NULL を設定)
-- 2008/09/29 1.1 N.Yoshida end
    BULK COLLECT INTO gt_billing_tbl
    FROM
        (
          SELECT   xd.goods_classe                        AS  goods_classe          -- 商品区分
                 , xd.delivery_company_code               AS  delivery_company_code -- 運送業者
                 , xdc.consumption_tax_classe             AS  consumption_tax_classe -- 消費税区分
                 , xdc.billing_code                       AS  billing_code        -- 請求先コード
                 , TO_CHAR(xd.judgement_date, 'YYYYMM')   AS  judgement_yyyymm    -- 請求年月
-- ##### 20081107 Ver.1.12 統合#552、553対応 START #####
--                 , NVL(xd.charged_amount, 0)              AS  charged_amount      -- 今月売上額
                 , NVL(xd.total_amount, 0)                AS  total_amount      -- 今月売上額（請求データの合計）
-- ##### 20081107 Ver.1.12 統合#552、553対応 END   #####
                 , NVL(xd.congestion_charge, 0)           AS  congestion_charge   -- 通行料等
                 , NVL(xd.picking_charge, 0)              AS  picking_charge      -- ピッキング料
                 , NVL(xd.many_rate, 0)                   AS  many_rate           -- 諸料金
                 , xdc.half_adjust_classe                 AS  half_adjust_classe  -- 四捨五入区分
-- 2008/09/29 1.1 N.Yoshida start
                 , NULL                                   AS  line_tax            -- 明細単位の消費税
                 /*, CASE                                                           -- 明細単位の消費税
                    -- 四捨五入区分が切り上げ
                    WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN
                      TRUNC(
                        (NVL(xd.charged_amount, 0) +
                         NVL(xd.picking_charge, 0) +
                         NVL(xd.many_rate, 0))
                       * (TO_NUMBER(gv_consumption_tax) * 0.01)
                      )
                    -- 四捨五入区分が切り捨て
                    WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN
                      TRUNC(
                        (NVL(xd.charged_amount, 0) +
                         NVL(xd.picking_charge, 0) +
                         NVL(xd.many_rate, 0))
                       * (TO_NUMBER(gv_consumption_tax) * 0.01)
                      )
                    -- 四捨五入区分が四捨五入
                    WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN
                      ROUND(
                        (NVL(xd.charged_amount, 0) +
                         NVL(xd.picking_charge, 0) +
                         NVL(xd.many_rate, 0))
                       * (TO_NUMBER(gv_consumption_tax) * 0.01)
                      )
                    END line_tax*/
-- 2008/09/29 1.1 N.Yoshida end
          FROM    xxwip_deliverys        xd        -- 運賃ヘッダーアドオン
                , xxwip_delivery_company xdc       -- 運賃用運送業者マスタ
          WHERE     TO_CHAR(xd.judgement_date, 'YYYYMM') = TO_CHAR(id_sysdate, 'YYYYMM')
          AND       xd.p_b_classe                        = gv_p_b_cls_bil
          AND       xdc.delivery_company_code            = xd.delivery_company_code
          AND       xd.goods_classe                      = xdc.goods_classe
          AND       xdc.start_date_active                <= xd.judgement_date
          AND       xd.judgement_date                    <= xdc.end_date_active
          AND       EXISTS(
                      SELECT 'X'
                      FROM   xxwip_billing_mst  xbm
                      WHERE  xbm.billing_code = xdc.billing_code
                    )
        )  dhc
        GROUP BY    dhc.goods_classe            -- 商品区分
                  , dhc.delivery_company_code   -- 運送業者
                  , dhc.consumption_tax_classe  -- 消費税区分
                  , dhc.billing_code            -- 請求先コード
                  , dhc.judgement_yyyymm        -- 請求年月
--
-- ##### 20081021 Ver.1.2 T_S_571対応 START #####
--
--  運賃調整のみ登録されている情報を取得する為
--  運賃調整のデータをUNIONして0円で抽出する
--
/*****
        ORDER BY    dhc.billing_code 
                  , dhc.judgement_yyyymm;
*****/
/* 2011/02/07 Ver1.7 Mod Start */
--    UNION
    UNION ALL
/* 2011/02/07 Ver1.7 Mod End   */
    -- ============================================================
    -- 運賃調整の請求先コードと請求年月を集約して取得
    --     今月売上額と通行料は0で設定（金額を計上しない）
    -- ここで運賃調整だけに存在する請求先コードを
    --     対象データとして抽出する。
    -- ============================================================
    SELECT  xac.billing_code  AS billing_code   -- 請求先コード
          , xac.billing_date  AS billing_date   -- 請求年月
          , NULL                                -- 消費税区分     (ここでは NULL を設定)
          , 0                                   -- 今月売上額     (調整だけは  0 を設定)
          , NULL                                -- 消費税（明細） (ここでは NULL を設定)
          , NULL                                -- 消費税（月）   (ここでは NULL を設定)
          , 0                                   -- 通行料等       (調整だけは  0 を設定)
          , NULL                                -- 請求調整合計額 (ここでは NULL を設定)
          , NULL                                -- 課税調整額     (ここでは NULL を設定)
          , NULL                                -- 消費税調整額   (ここでは NULL を設定)
    FROM    xxwip_adj_charges xac     -- 運賃調整アドオン
    WHERE   xac.billing_date  =  TO_CHAR(id_sysdate, 'YYYYMM')
    GROUP BY   xac.billing_code
             , xac.billing_date
    ORDER BY   billing_code   -- 請求先コード
             , billing_date   -- 請求年月
    ;
--
-- ##### 20081021 Ver.1.2 T_S_571対応 END   #####
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
  END get_deliverys;
--
  /**********************************************************************************
   * Procedure Name   : get_adj_charges
   * Description      : 運賃調整アドオンデータ取得(B-3、B-9)
   ***********************************************************************************/
  PROCEDURE get_adj_charges(
    id_sysdate    IN  DATE,         --   日付
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_adj_charges'; -- プログラム名
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
    ln_mas_cnt   NUMBER;               -- 請求先アドオンマスタ設定用カウンター
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
    -- カウンターの初期化
    ln_mas_cnt := 1;
--
    -- *********************************************
    -- 請求先コードと請求年月でグループ化
    -- *********************************************
    <<gt_billing_tbl_loop>>
    FOR ln_index IN gt_billing_tbl.FIRST .. gt_billing_tbl.LAST LOOP
--
      -- ==================================================
      -- 消費税（月）の算出 （今月売上額 × 消費税）
      -- ==================================================
-- 2008/09/29 1.1 N.Yoshida start
      --gt_billing_tbl(ln_index).month_tax :=
      --    (gt_billing_tbl(ln_index).charged_amt_sum * (TO_NUMBER(gv_consumption_tax) * 0.01));
-- 2008/09/29 1.1 N.Yoshida end
--
      -- ==============================
      -- 初回 設定
      -- ==============================
      IF (gt_masters_tbl.EXISTS(ln_mas_cnt) = FALSE) THEN
        -- *** 請求先コード ***
        gt_masters_tbl(ln_mas_cnt).billing_code     := gt_billing_tbl(ln_index).billing_code;
        -- *** 請求年月 ***
        gt_masters_tbl(ln_mas_cnt).billing_date     := gt_billing_tbl(ln_index).judgement_yyyymm;
        -- *** 今月売上額 ***
        gt_masters_tbl(ln_mas_cnt).charged_amt_sum  := gt_billing_tbl(ln_index).charged_amt_sum;
--
        -- *** 消費税 ***
-- 2008/09/29 1.1 N.Yoshida start
        /*-- 消費税区分＝「月」の場合
        IF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_month) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).month_tax;
--
        -- 消費税区分＝「明細」の場合
        ELSIF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_detail) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).detail_tax;
--
        -- 上記以外の場合
        ELSE 
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 0;
        END IF;*/
-- 2008/09/29 1.1 N.Yoshida end
--
        -- *** 通行料等 ***
        gt_masters_tbl(ln_mas_cnt).cong_charge_sum  := gt_billing_tbl(ln_index).cong_charge_sum;
--
      -- ==============================
      -- 請求先コードと請求年月が同じ場合
      -- ==============================
      ELSIF ((gt_masters_tbl(ln_mas_cnt).billing_code = gt_billing_tbl(ln_index).billing_code) AND
             (gt_masters_tbl(ln_mas_cnt).billing_date = gt_billing_tbl(ln_index).judgement_yyyymm))
      THEN
        -- *** 今月売上額 ***
        gt_masters_tbl(ln_mas_cnt).charged_amt_sum  :=
          gt_masters_tbl(ln_mas_cnt).charged_amt_sum + gt_billing_tbl(ln_index).charged_amt_sum;
--
        -- *** 消費税 ***
-- 2008/09/29 1.1 N.Yoshida start
        /*-- 消費税区分 ＝「月」 の場合
        IF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_month) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 
            gt_masters_tbl(ln_mas_cnt).consumption_tax + gt_billing_tbl(ln_index).month_tax;
--
        -- 消費税区分 ＝「明細」 の場合
        ELSIF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_detail) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 
            gt_masters_tbl(ln_mas_cnt).consumption_tax + gt_billing_tbl(ln_index).detail_tax;
--
        -- 上記以外の場合
        ELSE 
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 0;
        END IF;*/
-- 2008/09/29 1.1 N.Yoshida end
--
        -- *** 通行料等 ***
        gt_masters_tbl(ln_mas_cnt).cong_charge_sum  :=
          gt_masters_tbl(ln_mas_cnt).cong_charge_sum + gt_billing_tbl(ln_index).cong_charge_sum;
--
      -- ==============================
      -- 請求先コードか請求年月が違う場合
      -- ==============================
      ELSE
--
        -- カウントアップ
        ln_mas_cnt := ln_mas_cnt + 1;
        -- *** 請求先コード ***
        gt_masters_tbl(ln_mas_cnt).billing_code     := gt_billing_tbl(ln_index).billing_code;
        -- *** 請求年月 ***
        gt_masters_tbl(ln_mas_cnt).billing_date     := gt_billing_tbl(ln_index).judgement_yyyymm;
        -- *** 今月売上額 ***
        gt_masters_tbl(ln_mas_cnt).charged_amt_sum  := gt_billing_tbl(ln_index).charged_amt_sum;
--
        -- *** 消費税 ***
-- 2008/09/29 1.1 N.Yoshida start
        /*-- 消費税区分 ＝「月」の場合
        IF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_month) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).month_tax;
--
        -- 消費税区分 ＝「明細」の場合
        ELSIF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_detail) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).detail_tax;
--
        -- 上記以外の場合
        ELSE 
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 0;
        END IF;*/
-- 2008/09/29 1.1 N.Yoshida end
--
        -- *** 通行料等 ***
        gt_masters_tbl(ln_mas_cnt).cong_charge_sum  := gt_billing_tbl(ln_index).cong_charge_sum;
      END IF;
--
    END LOOP gt_billing_tbl_loop;
--
    -- *********************************************
    -- 運賃調整アドオンより抽出
    --     請求先コード、請求年月で集計
    -- *********************************************
    <<gt_billing_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP
--
      BEGIN
-- 2008/09/29 1.1 N.Yoshida start
        -- 運賃調整アドオンマスタより金額取得
        SELECT    SUM(adj_charges.billing_sum)
                , SUM(adj_charges.billing_tax_sum)
                , SUM(adj_charges.adj_tax_extra)
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
                , SUM(adj_charges.tax_free_bil_sum)             -- 非課税調整合計
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
        INTO      gt_masters_tbl(ln_index).amount_bil_sum       -- 請求調整合計額
                , gt_masters_tbl(ln_index).tax_bil_sum          -- 課税調整合計
                , gt_masters_tbl(ln_index).adj_tax_extra_sum    -- 消費税調整合計
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
                , gt_masters_tbl(ln_index).tax_free_bil_sum     -- 非課税調整合計
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
        FROM
          (
            SELECT    xac.billing_code AS billing_code
                    , xac.billing_date AS billing_date
                    ,(
                      NVL(amount_billing1, 0) + 
                      NVL(amount_billing2, 0) + 
                      NVL(amount_billing3, 0) + 
                      NVL(amount_billing4, 0) + 
                      NVL(amount_billing5, 0)
                    ) AS billing_sum             -- 請求金額計（請求金額１～５を加算）
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
                    -- 非課税請求調整金額（合計）
                    ,(
                      CASE    -- 請求金額1
                        WHEN (NVL(xac.tax_free_billing1, gv_tax_free_bil_off) <> gv_tax_free_bil_off) THEN
                          NVL(amount_billing1, 0)
                        ELSE 0
                      END +
                      CASE    -- 請求金額2
                        WHEN (NVL(xac.tax_free_billing2, gv_tax_free_bil_off) <> gv_tax_free_bil_off) THEN
                          NVL(amount_billing2, 0)
                        ELSE 0
                      END +
                      CASE    -- 請求金額3
                        WHEN (NVL(xac.tax_free_billing3, gv_tax_free_bil_off) <> gv_tax_free_bil_off) THEN
                          NVL(amount_billing3, 0)
                        ELSE 0
                      END +
                      CASE    -- 請求金額4
                        WHEN (NVL(xac.tax_free_billing4, gv_tax_free_bil_off) <> gv_tax_free_bil_off) THEN
                          NVL(amount_billing4, 0)
                        ELSE 0
                      END +
                      CASE    -- 請求金額5
                        WHEN (NVL(xac.tax_free_billing5, gv_tax_free_bil_off) <> gv_tax_free_bil_off) THEN
                          NVL(amount_billing5, 0)
                        ELSE 0
                      END 
                      ) AS tax_free_bil_sum
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
                    ,(
                      CASE    -- 請求金額1
                        WHEN (NVL(xac.tax_free_billing1, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing1, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- 切上
                              CEIL(NVL(amount_billing1, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- 切捨
                              TRUNC(NVL(amount_billing1, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- 四捨五入
                              ROUND(NVL(amount_billing1, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- 請求金額2
                        WHEN (NVL(xac.tax_free_billing2, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing2, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- 切上
                              CEIL(NVL(amount_billing2, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- 切捨
                              TRUNC(NVL(amount_billing2, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- 四捨五入
                              ROUND(NVL(amount_billing2, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- 請求金額3
                        WHEN (NVL(xac.tax_free_billing3, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing3, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- 切上
                              CEIL(NVL(amount_billing3, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- 切捨
                              TRUNC(NVL(amount_billing3, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- 四捨五入
                              ROUND(NVL(amount_billing3, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- 請求金額4
                        WHEN (NVL(xac.tax_free_billing4, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing4, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- 切上
                              CEIL(NVL(amount_billing4, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- 切捨
                              TRUNC(NVL(amount_billing4, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- 四捨五入
                              ROUND(NVL(amount_billing4, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- 請求金額5
                        WHEN (NVL(xac.tax_free_billing5, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing5, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- 切上
                              CEIL(NVL(amount_billing5, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- 切捨
                              TRUNC(NVL(amount_billing5, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- 四捨五入
                              ROUND(NVL(amount_billing5, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END
                    ) AS billing_tax_sum
                    , NVL(adj_tax_extra, 0) AS adj_tax_extra  -- 消費税調整
            FROM    xxwip_adj_charges       xac   -- 運賃調整アドオン
-- ##### 20081021 Ver.1.2 T_S_571対応 START #####
-- 運賃調整と運送業者の依存関係がなくなったため
-- 結合をしないよう、コメントアウト
--                  , xxwip_delivery_company  xdc   -- 運賃用運送業者マスタ
-- ##### 20081021 Ver.1.2 T_S_571対応 END   #####
-- ##### 20081021 Ver.1.2 T_S_571対応 START #####
--            WHERE   xac.goods_classe            =   xdc.goods_classe
--            AND     xac.delivery_company_code   =   xdc.delivery_company_code
--            AND     xdc.start_date_active       <=  TO_DATE(xac.billing_date || '01','YYYYMMDD')
--            AND     xdc.end_date_active         >=  TO_DATE(xac.billing_date || '01','YYYYMMDD')
--            AND     xac.billing_code            =   gt_masters_tbl(ln_index).billing_code
            WHERE   xac.billing_code            =   gt_masters_tbl(ln_index).billing_code
-- ##### 20081021 Ver.1.2 T_S_571対応 END   #####
            AND     xac.billing_date            =   gt_masters_tbl(ln_index).billing_date
          ) adj_charges
        GROUP BY   adj_charges.billing_code
                 , adj_charges.billing_date;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_masters_tbl(ln_index).amount_bil_sum   := 0;    -- 請求調整合計額
          gt_masters_tbl(ln_index).tax_bil_sum := 0;         -- 課税調整合計
          gt_masters_tbl(ln_index).adj_tax_extra_sum := 0;   -- 消費税調整合計
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
          gt_masters_tbl(ln_index).tax_free_bil_sum  := 0;   -- 非課税調整合計
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
      END;
-- 2008/09/29 1.1 N.Yoshida end
--
    END LOOP gt_billing_tbl_loop;
--
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
  END get_adj_charges;
--
  /**********************************************************************************
   * Procedure Name   : get_billing
   * Description      : 請求先アドオンマスタデータ取得(B-4、B-10)
   ***********************************************************************************/
  PROCEDURE get_billing(
    id_sysdate    IN  DATE,         --   日付
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_billing'; -- プログラム名
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
    ln_count            NUMBER;                                -- カウンター
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
    -- ローカル変数の初期化
    ln_count := 0;
--
    <<gt_masters_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP

      SELECT xbm1.billing_name,                   -- 請求先名
             xbm1.post_no,                        -- 郵便番号
             xbm1.address,                        -- 住所
             xbm1.telephone_no,                   -- 電話番号
             xbm1.fax_no,                         -- FAX番号
-- ##### 20090113 Ver.1.6 本番#977対応（繰越金額計算対応） START #####
             xbm1.money_transfer_date            -- 振込日
--             xbm1.money_transfer_date,            -- 振込日
--             NVL(xbm1.amount_receipt_money, 0),   -- 今回入金額
--             NVL(xbm1.amount_adjustment, 0)       -- 調整額
-- ##### 20090113 Ver.1.6 本番#977対応（繰越金額計算対応） END   #####
      INTO   gt_masters_tbl(ln_index).billing_name,
             gt_masters_tbl(ln_index).post_no,
             gt_masters_tbl(ln_index).address,
             gt_masters_tbl(ln_index).telephone_no,
             gt_masters_tbl(ln_index).fax_no,
-- ##### 20090113 Ver.1.6 本番#977対応（繰越金額計算対応） START #####
             gt_masters_tbl(ln_index).money_transfer_date
--             gt_masters_tbl(ln_index).money_transfer_date,
--             gt_masters_tbl(ln_index).amount_receipt_money,
--             gt_masters_tbl(ln_index).amount_adjustment
-- ##### 20090113 Ver.1.6 本番#977対応（繰越金額計算対応） END   #####
      FROM   xxwip_billing_mst   xbm1   -- 請求先アドオンマスタ
      WHERE  xbm1.billing_code = gt_masters_tbl(ln_index).billing_code
      AND    DECODE(xbm1.billing_date, gv_charge_dmy_key,
                    '000000',          xbm1.billing_date) =
             (SELECT MAX(DECODE(xbm2.billing_date, gv_charge_dmy_key,
                                '000000',          xbm2.billing_date))
              FROM   xxwip_billing_mst xbm2
              WHERE  xbm2.billing_code = gt_masters_tbl(ln_index).billing_code);
--
-- ##### 20090113 Ver.1.6 本番#977対応（繰越金額計算対応） START #####
      -- 今回入金額と調整額は指定日付の値を取得する
      SELECT NVL(xbm1.amount_receipt_money, 0),   -- 今回入金額
             NVL(xbm1.amount_adjustment, 0)       -- 調整額
      INTO   gt_masters_tbl(ln_index).amount_receipt_money,
             gt_masters_tbl(ln_index).amount_adjustment
      FROM   xxwip_billing_mst   xbm1   -- 請求先アドオンマスタ
      WHERE  xbm1.billing_code = gt_masters_tbl(ln_index).billing_code
      AND  xbm1.billing_date = (SELECT MIN(xbm2.billing_date)
                                FROM   xxwip_billing_mst xbm2
                                WHERE  xbm2.billing_code  = gt_masters_tbl(ln_index).billing_code
                                AND (  xbm2.billing_date = TO_CHAR(id_sysdate,'YYYYMM')
                                    OR xbm2.billing_date = gv_charge_dmy_key));
-- ##### 20090113 Ver.1.6 本番#977対応（繰越金額計算対応） END   #####
--
      -- *********************************************
      -- 支払条件設定日の取得
      -- （システム日付の翌月＋振込日の営業日）
      -- *********************************************
      xxwip_common_pkg.get_business_date(
        NVL(FND_DATE.STRING_TO_DATE(TO_CHAR(ADD_MONTHS(id_sysdate,1), 'YYYYMM') ||
                                    gt_masters_tbl(ln_index).money_transfer_date
                                   ,'YYYYMMDD'),TRUNC(LAST_DAY(id_sysdate))),      -- 日付
        0,                                                   -- 期間
        gt_masters_tbl(ln_index).condition_setting_date,   -- 支払条件設定日
        lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
        lv_retcode,                             -- リターン・コード             --# 固定 #
        lv_errmsg);                             -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> gv_status_normal) THEN -- 共通関数エラー
        RAISE global_api_expt;
      END IF;
--
    END LOOP gt_masters_tbl_loop;
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
  END get_billing;
--
  /**********************************************************************************
   * Procedure Name   : get_before
   * Description      : 前々月、前月データ取得(B-5、B-11)
   ***********************************************************************************/
  PROCEDURE get_before(
    id_sysdate    IN  DATE,         --   日付
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_before'; -- プログラム名
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
    <<gt_masters_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP
      BEGIN
        SELECT NVL(xbm.charged_amount, 0)        -- 今回請求金額
        INTO   gt_masters_tbl(ln_index).charged_amount
        FROM   xxwip_billing_mst   xbm   -- 請求先アドオンマスタ
        WHERE  xbm.billing_code = gt_masters_tbl(ln_index).billing_code
        AND    xbm.billing_date = TO_CHAR(ADD_MONTHS(id_sysdate, -1), 'YYYYMM');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_masters_tbl(ln_index).charged_amount := 0;
      END;
    END LOOP gt_masters_tbl_loop;
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
  END get_before;
--
  /**********************************************************************************
   * Procedure Name   : set_ins_date
   * Description      : 登録データ設定(B-6、B-12)
   ***********************************************************************************/
  PROCEDURE set_ins_date(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ins_date'; -- プログラム名
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
    lt_billing_id   xxwip_billing_mst.billing_mst_id%TYPE; -- 請求先アドオンマスタID(更新用)
-- 2008/09/29 1.1 N.Yoshida start
    ln_consumption_tax                             NUMBER; -- 消費税(計算用)
-- 2008/09/29 1.1 N.Yoshida end
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
    <<gt_masters_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP
     -- 存在チェックを行い、存在する場合はロック処理を行う
      BEGIN
        SELECT xbm.billing_mst_id   -- 請求先アドオンマスタID
        INTO   lt_billing_id
        FROM   xxwip_billing_mst   xbm   -- 請求先アドオンマスタ
        WHERE  xbm.billing_code = gt_masters_tbl(ln_index).billing_code
        AND    xbm.billing_date = gt_masters_tbl(ln_index).billing_date
        FOR UPDATE NOWAIT;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_billing_id := NULL;
        WHEN lock_expt THEN   -- *** ロック取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,   gv_wip_msg_74b_004,
                                                gv_tkn_table,     gv_billing_mst_name);
          RAISE global_api_expt;
      END;
--
-- 2008/09/29 1.1 N.Yoshida start
      -- 消費税の計算：((今月売上額(運賃ヘッダ分)＋課税調整合計)×消費税率×0.01)＋消費税調整合計
      ln_consumption_tax := TRUNC((NVL(gt_masters_tbl(ln_index).charged_amt_sum, 0) + 
                                     NVL(gt_masters_tbl(ln_index).tax_bil_sum, 0)) * 
                                       (TO_NUMBER(gv_consumption_tax) * 0.01))      +
                            NVL(gt_masters_tbl(ln_index).adj_tax_extra_sum, 0);
-- 2008/09/29 1.1 N.Yoshida end
--
      -- データが存在しない場合
      IF (lt_billing_id IS NULL) THEN
        -- カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
        gn_i_bil_tab_cnt := gn_i_bil_tab_cnt + 1;
--
        -- 登録用PL/SQL表にデータを設定
        -- 請求先アドオンマスタID
        SELECT xxwip_billing_mst_id_s1.NEXTVAL
        INTO   i_bil_bil_mst_id_tab(gn_i_bil_tab_cnt)
        FROM   dual;
        -- 請求先コード
        i_bil_bil_code_tab(gn_i_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_code;
        -- 請求先名
        i_bil_bil_name_tab(gn_i_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_name;
        -- 請求年月
        i_bil_bil_date_tab(gn_i_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_date;
        -- 郵便番号
        i_bil_post_no_tab(gn_i_bil_tab_cnt)   := gt_masters_tbl(ln_index).post_no;
        -- 住所
        i_bil_address_tab(gn_i_bil_tab_cnt)   := gt_masters_tbl(ln_index).address;
        -- 電話番号
        i_bil_tel_no_tab(gn_i_bil_tab_cnt)    := gt_masters_tbl(ln_index).telephone_no;
        -- FAX番号
        i_bil_fax_no_tab(gn_i_bil_tab_cnt)    := gt_masters_tbl(ln_index).fax_no;
        -- 振込日
        i_bil_my_tran_dt_tab(gn_i_bil_tab_cnt) :=
           gt_masters_tbl(ln_index).money_transfer_date;
        -- 支払条件設定日
        i_bil_cn_set_dt_tab(gn_i_bil_tab_cnt) :=
          gt_masters_tbl(ln_index).condition_setting_date;
        -- 前月請求額
        i_bil_lt_mt_chrg_amt_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount, 0);
        -- 繰越額
        i_bil_blc_crd_fw_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount,       0) -
          NVL(gt_masters_tbl(ln_index).amount_receipt_money, 0) -
          NVL(gt_masters_tbl(ln_index).amount_adjustment,    0);
        -- 今回請求金額
        -- 請求データの合計＋通行料＋請求調整合計金額＋消費税
-- 2008/09/29 1.1 N.Yoshida start
        i_bil_chrg_amt_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum,  0) +
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          NVL(gt_masters_tbl(ln_index).cong_charge_sum,  0) +
          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
        -- 請求金額合計（今回請求金額＋繰越額）
        i_bil_chrg_amt_ttl_tab(gn_i_bil_tab_cnt) :=
          NVL(i_bil_chrg_amt_tab(gn_i_bil_tab_cnt),   0) +
          NVL(i_bil_blc_crd_fw_tab(gn_i_bil_tab_cnt), 0);
        -- 今月売上額（請求データの合計＋課税調整額）
        i_bil_month_sales_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum, 0) +
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
--          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0);
          NVL(gt_masters_tbl(ln_index).tax_bil_sum,   0);
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
--
        -- 消費税
-- 2008/09/29 1.1 N.Yoshida start
        i_bil_consumption_tax_tab(gn_i_bil_tab_cnt) := 
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
--
        -- 通行料等（請求データの通行料＋非課税調整額）
        i_bil_cn_chrg_tab(gn_i_bil_tab_cnt) :=
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
--          NVL(gt_masters_tbl(ln_index).cong_charge_sum, 0);
          NVL(gt_masters_tbl(ln_index).cong_charge_sum, 0) +
          NVL(gt_masters_tbl(ln_index).tax_free_bil_sum, 0);     -- 非課税調整合計
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
--
      -- データが存在する場合
      ELSIF (lt_billing_id IS NOT NULL) THEN
        -- カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
        gn_u_bil_tab_cnt := gn_u_bil_tab_cnt + 1;
--
        -- 更新用PL/SQL表にデータを設定
        -- 請求先アドオンマスタIDの格納
        u_bil_bil_mst_id_tab(gn_u_bil_tab_cnt) := lt_billing_id;
        -- 請求先コード
        u_bil_bil_code_tab(gn_u_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_code;
        -- 請求先名
        u_bil_bil_name_tab(gn_u_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_name;
        -- 請求年月
        u_bil_bil_date_tab(gn_u_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_date;
        -- 郵便番号
        u_bil_post_no_tab(gn_u_bil_tab_cnt)   := gt_masters_tbl(ln_index).post_no;
        -- 住所
        u_bil_address_tab(gn_u_bil_tab_cnt)   := gt_masters_tbl(ln_index).address;
        -- 電話番号
        u_bil_tel_no_tab(gn_u_bil_tab_cnt)    := gt_masters_tbl(ln_index).telephone_no;
        -- FAX番号
        u_bil_fax_no_tab(gn_u_bil_tab_cnt)    := gt_masters_tbl(ln_index).fax_no;
        -- 振込日
        u_bil_my_tran_dt_tab(gn_u_bil_tab_cnt) :=
           gt_masters_tbl(ln_index).money_transfer_date;
        -- 支払条件設定日
        u_bil_cn_set_dt_tab(gn_u_bil_tab_cnt) :=
          gt_masters_tbl(ln_index).condition_setting_date;
        -- 前月請求額
        u_bil_lt_mt_chrg_amt_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount, 0);
        -- 繰越額
        u_bil_blc_crd_fw_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount,       0) -
          NVL(gt_masters_tbl(ln_index).amount_receipt_money, 0) -
          NVL(gt_masters_tbl(ln_index).amount_adjustment,    0);
        -- 今回請求金額
-- 2008/09/29 1.1 N.Yoshida start
        u_bil_chrg_amt_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum,  0) +
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          NVL(gt_masters_tbl(ln_index).cong_charge_sum,  0) +
          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
        -- 請求金額合計
        u_bil_chrg_amt_ttl_tab(gn_u_bil_tab_cnt) :=
          NVL(u_bil_chrg_amt_tab(gn_u_bil_tab_cnt),   0) +
          NVL(u_bil_blc_crd_fw_tab(gn_u_bil_tab_cnt), 0);
        -- 今月売上額（請求データの合計＋課税調整額）
        u_bil_month_sales_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum, 0) +
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
--          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0);
          NVL(gt_masters_tbl(ln_index).tax_bil_sum,   0);
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
        -- 消費税
-- 2008/09/29 1.1 N.Yoshida start
        u_bil_consumption_tax_tab(gn_u_bil_tab_cnt) :=
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
        -- 通行料等（請求データの通行料＋非課税調整額）
        u_bil_cn_chrg_tab(gn_u_bil_tab_cnt) :=
-- ##### 20081218 Ver.1.4 本番#42対応 START #####
--          NVL(gt_masters_tbl(ln_index).cong_charge_sum, 0);
          NVL(gt_masters_tbl(ln_index).cong_charge_sum, 0) +
          NVL(gt_masters_tbl(ln_index).tax_free_bil_sum, 0);     -- 非課税調整合計
-- ##### 20081218 Ver.1.4 本番#42対応 END   #####
--
      END IF;
--
    END LOOP gt_masters_tbl_loop;
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
  END set_ins_date;
--
  /**********************************************************************************
   * Procedure Name   : ins_billing
   * Description      : 請求先アドオンマスタ一括登録処理(B-13)
   ***********************************************************************************/
  PROCEDURE ins_billing(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_billing'; -- プログラム名
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
    -- ***************************
    -- * 請求先アドオンマスタ 登録
    -- ***************************
    FORALL ln_index IN i_bil_bil_mst_id_tab.FIRST .. i_bil_bil_mst_id_tab.LAST
      INSERT INTO xxwip_billing_mst                    -- 請求先アドオンマスタ
      (billing_mst_id,                                 -- 1.請求先アドオンマスタID
       billing_code,                                   -- 2.請求先コード
       billing_name,                                   -- 3.請求先名
       billing_date,                                   -- 4.請求年月
       post_no,                                        -- 5.郵便番号
       address,                                        -- 6.住所
       telephone_no,                                   -- 7.電話番号
       fax_no,                                         -- 8.FAX番号
       money_transfer_date,                            -- 9.振込日
       condition_setting_date,                         -- 10.支払条件設定日
       last_month_charge_amount,                       -- 11.前月請求額
       amount_receipt_money,                           -- 12.今回入金額
       amount_adjustment,                              -- 13.調整費
       balance_carried_forward,                        -- 14.繰越額
       charged_amount,                                 -- 15.今回請求金額
       charged_amount_total,                           -- 16.請求金額合計
       month_sales,                                    -- 17.今月売上額
       consumption_tax,                                -- 18.消費税
       congestion_charge,                              -- 19.通行料等
       created_by,                                     -- 20.作成者
       creation_date,                                  -- 21.作成日
       last_updated_by,                                -- 22.最終更新者
       last_update_date,                               -- 23.最終更新日
       last_update_login,                              -- 24.最終更新ログイン
       request_id,                                     -- 25.要求ID
       program_application_id,                         -- 26.ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
       program_id,                                     -- 27.コンカレント・プログラムID
       program_update_date)                            -- 28.プログラム更新日
      VALUES
      (i_bil_bil_mst_id_tab(ln_index),                 -- 1.請求先アドオンマスタID
       i_bil_bil_code_tab(ln_index),                   -- 2.請求先コード
       i_bil_bil_name_tab(ln_index),                   -- 3.請求先名
       i_bil_bil_date_tab(ln_index),                   -- 4.請求年月
       i_bil_post_no_tab(ln_index),                    -- 5.郵便番号
       i_bil_address_tab(ln_index),                    -- 6.住所
       i_bil_tel_no_tab(ln_index),                     -- 7.電話番号
       i_bil_fax_no_tab(ln_index),                     -- 8.FAX番号
       i_bil_my_tran_dt_tab(ln_index),                 -- 9.振込日
       i_bil_cn_set_dt_tab(ln_index),                  -- 10.支払条件設定日
       i_bil_lt_mt_chrg_amt_tab(ln_index),             -- 11.前月請求額
-- ##### 20081107 Ver.1.12 統合#552、553対応 START #####
--       NULL,                                           -- 12.今回入金額
--       NULL,                                           -- 13.調整費
       0,                                              -- 12.今回入金額（初期設定０）
       0,                                              -- 13.調整費    （初期設定０）
-- ##### 20081107 Ver.1.12 統合#552、553対応 END   #####
       i_bil_blc_crd_fw_tab(ln_index),                 -- 14.繰越額
       i_bil_chrg_amt_tab(ln_index),                   -- 15.今回請求金額
       i_bil_chrg_amt_ttl_tab(ln_index),               -- 16.請求金額合計
       i_bil_month_sales_tab(ln_index),                -- 17.今月売上額
       i_bil_consumption_tax_tab(ln_index),            -- 18.消費税
       i_bil_cn_chrg_tab(ln_index),                    -- 19.通行料等
       gn_user_id,                                     -- 20.作成者
       gd_sysdate,                                     -- 21.作成日
       gn_user_id,                                     -- 22.最終更新者
       gd_sysdate,                                     -- 23.最終更新日
       gn_login_id,                                    -- 24.最終更新ログイン
       gn_conc_request_id,                             -- 25.要求ID
       gn_prog_appl_id,                                -- 26.ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
       gn_conc_program_id,                             -- 27.コンカレント・プログラムID
       gd_sysdate);                                    -- 28.プログラム更新日
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
  END ins_billing;
--
  /**********************************************************************************
   * Procedure Name   : upd_billing
   * Description      : 請求先アドオンマスタ一括更新処理(B-14)
   ***********************************************************************************/
  PROCEDURE upd_billing(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_billing'; -- プログラム名
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
    -- ***************************
    -- * 請求先アドオンマスタ 登録
    -- ***************************
    FORALL ln_index IN u_bil_bil_mst_id_tab.FIRST .. u_bil_bil_mst_id_tab.LAST
      UPDATE xxwip_billing_mst xbm    -- 請求先アドオンマスタ
      SET    billing_name             = u_bil_bil_name_tab(ln_index),        -- 請求先名
             post_no                  = u_bil_post_no_tab(ln_index),         -- 郵便番号
             address                  = u_bil_address_tab(ln_index),         -- 住所
             telephone_no             = u_bil_tel_no_tab(ln_index),          -- 電話番号
             fax_no                   = u_bil_fax_no_tab(ln_index),          -- FAX番号
             money_transfer_date      = u_bil_my_tran_dt_tab(ln_index),      -- 振込日
             condition_setting_date   = u_bil_cn_set_dt_tab(ln_index),       -- 支払条件設定日
             last_month_charge_amount = u_bil_lt_mt_chrg_amt_tab(ln_index),  -- 前月請求額
             balance_carried_forward  = u_bil_blc_crd_fw_tab(ln_index),      -- 繰越額
             charged_amount           = u_bil_chrg_amt_tab(ln_index),        -- 今回請求金額
             charged_amount_total     = u_bil_chrg_amt_ttl_tab(ln_index),    -- 請求金額合計
             month_sales              = u_bil_month_sales_tab(ln_index),     -- 今月売上額
             consumption_tax          = u_bil_consumption_tax_tab(ln_index), -- 消費税
             congestion_charge        = u_bil_cn_chrg_tab(ln_index),         -- 通行料等
             last_updated_by          = gn_user_id,                 -- 最終更新者
             last_update_date         = gd_sysdate,                 -- 最終更新日
             last_update_login        = gn_login_id,                -- 最終更新ﾛｸﾞｲﾝ
             request_id               = gn_conc_request_id,         -- 要求ID
             program_application_id   = gn_prog_appl_id,            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
             program_id               = gn_conc_program_id,         -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑID
             program_update_date      = gd_sysdate                  -- ﾌﾟﾛｸﾞﾗﾑ更新日
      WHERE  xbm.billing_mst_id       = u_bil_bil_mst_id_tab(ln_index);
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
  END upd_billing;
--
  /**********************************************************************************
   * Procedure Name   : init_plsql
   * Description      : PL/SQL表初期化(B-7)
   ***********************************************************************************/
  PROCEDURE init_plsql(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_plsql'; -- プログラム名
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
    -- PL/SQL表の初期化
    gt_masters_tbl.DELETE;
    gt_billing_tbl.DELETE;
--
-- ##### 20090108 Ver.1.5 本番#960対応 START #####
  i_bil_bil_mst_id_tab.DELETE;        -- 請求先アドオンマスタID
  i_bil_bil_code_tab.DELETE;          -- 請求先コード
  i_bil_bil_name_tab.DELETE;          -- 請求先名
  i_bil_bil_date_tab.DELETE;          -- 請求年月
  i_bil_post_no_tab.DELETE;           -- 郵便番号
  i_bil_address_tab.DELETE;           -- 住所
  i_bil_tel_no_tab.DELETE;            -- 電話番号
  i_bil_fax_no_tab.DELETE;            -- FAX番号
  i_bil_my_tran_dt_tab.DELETE;        -- 振込日
  i_bil_cn_set_dt_tab.DELETE;         -- 支払条件設定日
  i_bil_lt_mt_chrg_amt_tab.DELETE;    -- 前月請求額
  i_bil_amt_adjt_tab.DELETE;          -- 調整額
  i_bil_amt_rcp_my_tab.DELETE;        -- 今回入金額
  i_bil_blc_crd_fw_tab.DELETE;        -- 繰越額
  i_bil_chrg_amt_tab.DELETE;          -- 今回請求金額
  i_bil_chrg_amt_ttl_tab.DELETE;      -- 請求金額合計
  i_bil_month_sales_tab.DELETE;       -- 今月売上額
  i_bil_consumption_tax_tab.DELETE;   -- 消費税
  i_bil_cn_chrg_tab.DELETE;           -- 通行料等
--
  u_bil_bil_mst_id_tab.DELETE;        -- 請求先アドオンマスタID
  u_bil_bil_code_tab.DELETE;          -- 請求先コード
  u_bil_bil_name_tab.DELETE;          -- 請求先名
  u_bil_bil_date_tab.DELETE;          -- 請求年月
  u_bil_post_no_tab.DELETE;           -- 郵便番号
  u_bil_address_tab.DELETE;           -- 住所
  u_bil_tel_no_tab.DELETE;            -- 電話番号
  u_bil_fax_no_tab.DELETE;            -- FAX番号
  u_bil_my_tran_dt_tab.DELETE;        -- 振込日
  u_bil_cn_set_dt_tab.DELETE;         -- 支払条件設定日
  u_bil_lt_mt_chrg_amt_tab.DELETE;    -- 前月請求額
  u_bil_amt_rcp_my_tab.DELETE;        -- 今回入金額
  u_bil_amt_adjt_tab.DELETE;          -- 調整額
  u_bil_blc_crd_fw_tab.DELETE;        -- 繰越額
  u_bil_chrg_amt_tab.DELETE;          -- 今回請求金額
  u_bil_chrg_amt_ttl_tab.DELETE;      -- 請求金額合計
  u_bil_month_sales_tab.DELETE;       -- 今月売上額
  u_bil_consumption_tax_tab.DELETE;   -- 消費税
  u_bil_cn_chrg_tab.DELETE;           -- 通行料等
-- ##### 20090108 Ver.1.5 本番#960対応 END   #####
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
  END init_plsql;
--
  /**********************************************************************************
   * Procedure Name   : sub_submain
   * Description      : サブメイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE sub_submain(
    id_param_date IN  DATE,         --   1.日付（当月、前月）
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sub_submain'; -- プログラム名
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
    -- ユーザ定義グローバル変数の初期化
    gn_i_bil_tab_cnt   := 0;
    gn_u_bil_tab_cnt   := 0;
--
    -- ===========================================
    -- 運賃ヘッダーアドオンデータ取得(B-2、B-8)
    -- ===========================================
    get_deliverys(
      id_param_date,     -- 日付
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 対象データなしの場合
    IF (gt_billing_tbl.COUNT = 0) THEN
      RETURN;
    END IF;
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 運賃調整アドオンデータ取得(B-3、B-9)
    -- ===========================================
    get_adj_charges(
      id_param_date,     -- 日付
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 請求先アドオンマスタデータ取得(B-4、B-10)
    -- ===========================================
    get_billing(
      id_param_date,     -- 日付
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 前々月、前月データ取得(B-5、B-11)
    -- ===========================================
    get_before(
      id_param_date,     -- 日付
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 登録データ設定(B-6、B-12)
    -- ===========================================
    set_ins_date(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 請求先アドオンマスタ一括登録処理(B-13)
    -- ===========================================
    ins_billing(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 請求先アドオンマスタ一括更新処理(B-14)
    -- ===========================================
    upd_billing(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
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
  END sub_submain;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    -- *** ローカル定数 ***
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
    -- ===========================================
    -- 関連データ取得(B-1)
    -- ===========================================
    get_related_date(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 締日前の場合
    IF (gv_close_type = 'Y') THEN
      -- ===========================================
      -- サブメイン処理プロシージャ
      -- ===========================================
      sub_submain(
        ADD_MONTHS(gd_sysdate, -1), -- 前月
        lv_errbuf,                  -- エラー・メッセージ           --# 固定 #
        lv_retcode,                 -- リターン・コード             --# 固定 #
        lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===========================================
      -- PL/SQL表初期化(B-7)
      -- ===========================================
      init_plsql(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_process_expt;
      -- 処理が成功の場合
      ELSIF (lv_retcode = gv_status_normal) THEN
        -- コミット
        COMMIT;
      END IF;
--
    END IF;
--
    -- 締日後の場合
    -- ===========================================
    -- サブメイン処理プロシージャ
    -- ===========================================
    sub_submain(
      gd_sysdate,        -- 当月
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    gn_normal_cnt := gn_target_cnt;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
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
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
END xxwip740001c;
/
