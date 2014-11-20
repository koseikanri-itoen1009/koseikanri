CREATE OR REPLACE PACKAGE BODY XXCMM_CUST_STS_CHG_CHK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM_CUST_STS_CHK_PKG(body)
 * Description      : 顧客ステータスを「中止」に変更する際、ステータス変更が可能か判定を行います。
 * MD.050           : MD050_CMM_003_A11_顧客ステータス変更チェック
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  item_ins               物件情報存在チェック(A-2)
 *  cust_base_chk          基準在庫数・釣銭基準額チェック処理(A-3)
 *  cust_balance_chk       売掛残高チェック処理(A-4)
-- 2011/03/07 Ver1.5 add start
 *  cust_tran_chk          月内取引存在チェック処理(A-5)
-- 2011/03/07 Ver1.5 add end
 *  submain                メイン処理プロシージャ
 *  main                   実行ファイル登録プロシージャ(A-5 終了処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   Takuya.Kaihara   新規作成
 *  2009/02/19    1.1   Takuya.Kaihara   物件マスタ.削除フラグの修正
 *  2009/09/11    1.2   Yutaka.Kuboshima 障害0001350 業態(小分類)の必須チェックの削除
 *  2010/02/15    1.3   Yutaka.Kuboshima 障害E_本稼動_01528 PT対応：残高情報チェックSQL
 *  2010/08/04    1.4   Shigeto.NIki     障害E_本稼動_04245 業態関係なく売掛残高チェック
 *  2011/03/07    1.5   Masato.Hirose    障害E_本稼動_02443 月内取引の存在チェック追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
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
  init_err_expt             EXCEPTION;     -- 初期処理エラー
  ins_err_expt              EXCEPTION;     -- 有効物件中止チェックエラー
  stop_err_expt             EXCEPTION;     -- 中止チェックエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCMM_CUST_STS_CHG_CHK_PKG';    -- パッケージ名
--
  cv_cnst_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXCMM';                         -- アドオン：共通・マスタ
--
  --エラーメッセージ
  cv_msg_xxcmm_10312   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10312';              -- 中止チェックエラー
  cv_msg_xxcmm_10313   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10313';              -- 有効物件中止チェックエラー
  cv_msg_xxcmm_10314   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10314';              -- 中止チェック起動エラー
  cv_msg_xxcmm_10315   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10315';              -- 残高中止チェック起動エラー
-- 2011/03/07 Ver1.5 add start
  cv_msg_xxcmm_00018   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';              -- 業務日付取得エラー
  cv_msg_xxcmm_00356   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00356';              -- 月内取引存在チェックエラー
-- 2011/03/07 Ver1.5 add end
  --トークン
  cv_cnst_tkn_citem    CONSTANT VARCHAR2(15)  := 'CHECK_ITEM';                    -- トークン(チェック項目名)
  cv_cnst_tkn_tnum     CONSTANT VARCHAR2(15)  := 'TOTAL_NUM';                     -- トークン(サマリー結果)
  cv_cnst_tkn_cid      CONSTANT VARCHAR2(15)  := 'CUST_ID';                       -- トークン(顧客ID)
  cv_cnst_tkn_gsyo     CONSTANT VARCHAR2(15)  := 'GTAI_SYO';                      -- トークン(業態分類（小分類）)
-- 2011/03/07 Ver1.5 add start
  cv_cnst_tkn_ccd      CONSTANT VARCHAR2(15)  := 'CUST_CODE';                     -- 顧客コードトークン
-- 2011/03/07 Ver1.5 add end
--
  cv_sts_check_ok      CONSTANT VARCHAR2(1)   := '1';                             -- チェックステータス(OK)
  cv_sts_check_ng      CONSTANT VARCHAR2(1)   := '0';                             -- チェックステータス(NG)
  cv_cust_cls_cd_cu    CONSTANT VARCHAR2(2)   := '10';                            --顧客区分(顧客)
  cv_cust_cls_cd_uc    CONSTANT VARCHAR2(2)   := '12';                            --顧客区分(上様顧客)
  cv_cust_cls_cd_uk    CONSTANT VARCHAR2(2)   := '14';                            --顧客区分(売掛金管理先顧客)
  cv_site_use_cd_bt    CONSTANT VARCHAR2(20)  := 'BILL_TO';                       --使用目的(請求先)
  cv_site_use_cd_st    CONSTANT VARCHAR2(20)  := 'SHIP_TO';                       --使用目的(出荷先)
  cv_gtal_syo_24       CONSTANT VARCHAR2(2)   := '24';                            --業態分類(小分類)(フルサービス(消化)VD)
  cv_gtal_syo_25       CONSTANT VARCHAR2(2)   := '25';                            --業態分類(小分類)(フルサービスVD)
  cv_gtal_syo_27       CONSTANT VARCHAR2(2)   := '27';                            --業態分類(小分類)(消化VD)
  cv_status_op         CONSTANT VARCHAR2(2)   := 'OP';                            --ステータス(オープン)
  cv_status_cl         CONSTANT VARCHAR2(2)   := 'CL';                            --ステータス(クローズ)
--  cn_ins_sts_cd        CONSTANT NUMBER        := 6;                               --インスタンスステータスID(物件削除済)
  cv_ins_sts_cd        CONSTANT VARCHAR2(20)  := '物件削除済';                    --インスタンスステータスID(物件削除済)
-- 2011/03/07 Ver1.5 add start
  cv_gtal_dai_vd       CONSTANT VARCHAR2(2)   := '05';                            --業態分類(大分類)(VD)
  cv_date_mm           CONSTANT VARCHAR2(2)   := 'MM';                            --フォーマット('MM')
-- 2011/03/07 Ver1.5 add end
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- 2011/03/07 Ver1.5 add start
  gd_process_date      DATE;                                                      -- 業務日付
-- 2011/03/07 Ver1.5 add end
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_cust_id      IN  NUMBER,       --   顧客ID
    iv_gtai_syo     IN  VARCHAR2,     --   業態分類（小分類）
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    --チェックステータス初期化部
    ov_check_status := cv_sts_check_ok;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --顧客ID・業態分類(小分類)NULLチェック
-- 2009/09/11 Ver1.2 modify start by Y.Kuboshima
--    IF ( in_cust_id IS NULL OR iv_gtai_syo IS NULL ) THEN
    IF ( in_cust_id IS NULL ) THEN
-- 2009/09/11 Ver1.2 modify end by Y.Kuboshima
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10314,
                                            cv_cnst_tkn_cid,
                                            in_cust_id,
                                            cv_cnst_tkn_gsyo,
                                            iv_gtai_syo);
      RAISE init_err_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 add start
    -- 業務日付取得
    gd_process_date  := xxccp_common_pkg2.get_process_date;
--
    -- 業務日付が取得できなかったらエラー
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cnst_msg_kbn
                    ,iv_name         => cv_msg_xxcmm_00018);
      RAISE init_err_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 add end
  EXCEPTION
    --*** 初期処理エラー ***
    WHEN init_err_expt THEN
      ov_check_status := cv_sts_check_ng;             --チェックステータス
      ov_err_message  := lv_errmsg;                   --エラーメッセージ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : item_ins
   * Description      : 物件情報存在チェック(A-2)
   ***********************************************************************************/
  PROCEDURE item_ins(
    in_cust_id      IN  NUMBER,       --   顧客ID
    iv_gtai_syo     IN  VARCHAR2,     --   業態分類（小分類）
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_ins'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_errmsg      VARCHAR2(5000);                      -- ユーザー・エラー・メッセージ
    ln_item_count  NUMBER;                              --対象件数
--
--
  BEGIN
--
    --チェックステータス初期化部
    ov_check_status := cv_sts_check_ok;
    --ローカル変数初期化部
    ln_item_count := 0;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 物件情報存在チェック
--    SELECT COUNT( cii.instance_id )
--    INTO   ln_item_count
--    FROM   csi_item_instances cii,
--           hz_cust_accounts hca
--    WHERE  hca.cust_account_id = in_cust_id
--    AND    cii.owner_party_account_id = hca.cust_account_id
--    AND    cii.instance_status_id <> cn_ins_sts_cd
--    AND    ROWNUM = 1;
--
    -- 物件情報存在チェック
    SELECT COUNT( cii.instance_id )
    INTO   ln_item_count
    FROM   csi_item_instances cii,
           hz_cust_accounts   hca
    WHERE  hca.cust_account_id = in_cust_id
    AND    cii.owner_party_account_id = hca.cust_account_id
    AND    (NOT EXISTS (SELECT 1 
                       FROM    csi_instance_statuses  cis
                       WHERE   cis.name = cv_ins_sts_cd
                       AND     cii.instance_status_id = cis.instance_status_id ))
    AND    ROWNUM = 1;
--
    --物件情報存在が存在するか
    IF ( ln_item_count > 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10313);
      RAISE ins_err_expt;
    END IF;
--
  EXCEPTION
    --*** 有効物件中止チェックエラー ***
    WHEN ins_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --チェックステータス
      ov_err_message  := lv_errmsg;                  --エラーメッセージ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END item_ins;
--
  /**********************************************************************************
   * Procedure Name   : cust_base_chk
   * Description      : 基準在庫数・釣銭基準額チェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE cust_base_chk(
    in_cust_id      IN  NUMBER,       --   顧客ID
    iv_gtai_syo     IN  VARCHAR2,     --   業態分類（小分類）
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_base_chk'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_tkn_inv    CONSTANT VARCHAR2(50) := '基準在庫数';             --基準在庫数
    cv_tkn_chg    CONSTANT VARCHAR2(50) := '釣銭基準額';             --釣銭基準額
--
    -- *** ローカル変数 ***
    lv_errmsg    VARCHAR2(5000);                          -- ユーザー・エラー・メッセージ
    ln_inv_total NUMBER;                                  --基準在庫数合計
    ln_chg_chk   NUMBER;                                  --釣銭基準額合計
--
  BEGIN
--
    --チェックステータス初期化部
    ov_check_status := cv_sts_check_ok;
    --ローカル変数初期化部
    ln_inv_total := 0;
    ln_chg_chk := 0;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --基準在庫数チェック
    SELECT NVL( SUM( NVL( xmvc.inventory_quantity,0 ) ), 0 )
    INTO   ln_inv_total
    FROM   xxcoi_mst_vd_column xmvc
    WHERE  xmvc.customer_id = in_cust_id;
--
    IF ( ln_inv_total <> 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10312,
                                            cv_cnst_tkn_citem,
                                            cv_tkn_inv,
                                            cv_cnst_tkn_tnum,
                                            ln_inv_total);
      RAISE stop_err_expt;
    END IF;
--
    BEGIN
      --釣銭基準額チェック
      SELECT NVL( xca.change_amount,0 )
      INTO   ln_chg_chk
      FROM   xxcmm_cust_accounts xca
      WHERE  xca.customer_id = in_cust_id;
    EXCEPTION
      --*** 対象レコードなしエラー ***
      WHEN NO_DATA_FOUND THEN
        ln_chg_chk := 0;
      WHEN OTHERS THEN
        RAISE;
    END;
--
    IF ( ln_chg_chk <> 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10312,
                                            cv_cnst_tkn_citem,
                                            cv_tkn_chg,
                                            cv_cnst_tkn_tnum,
                                            ln_chg_chk);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** 中止チェックエラー ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --チェックステータス
      ov_err_message  := lv_errmsg;                  --エラーメッセージ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END cust_base_chk;
--
  /**********************************************************************************
   * Procedure Name   : cust_balance_chk
   * Description      : 売掛残高チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE cust_balance_chk(
    in_cust_id      IN  NUMBER,       --   顧客ID
    iv_gtai_syo     IN  VARCHAR2,     --   業態分類（小分類）
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_balance_chk'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル変数 ***
    lv_errmsg    VARCHAR2(5000);                                -- ユーザー・エラー・メッセージ
    ln_bal_count NUMBER;                                        --対象件数
--
--
  BEGIN
--
    --チェックステータス初期化部
    ov_check_status := cv_sts_check_ok;
    --ローカル変数初期化部
    ln_bal_count := 0;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --残高情報チェック
-- 2010/02/15 Ver1.3 E_本稼動_XXXXX modify start by Yutaka.Kuboshima
--    SELECT COUNT( hca.cust_account_id )
--    INTO   ln_bal_count
--    FROM   hz_cust_accounts hca,
--           hz_cust_site_uses_all hcsu,
--           hz_cust_acct_sites_all hcas,
--           ra_customer_trx_all rct,
--           ar_payment_schedules_all aps
--    WHERE  (hca.customer_class_code IN ( cv_cust_cls_cd_cu, cv_cust_cls_cd_uc )
--    AND    hca.cust_account_id      = in_cust_id
--    AND    hcas.cust_account_id     = hca.cust_account_id
--    AND    hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
--    AND    hcsu.site_use_code       = cv_site_use_cd_st
--    AND    aps.status               = cv_status_op
--    AND    hcsu.bill_to_site_use_id = rct.bill_to_site_use_id
--    AND    rct.customer_trx_id      = aps.customer_trx_id)
--    OR
--           (hca.customer_class_code = cv_cust_cls_cd_uk
--    AND    hca.cust_account_id      = in_cust_id
--    AND    hcas.cust_account_id     = hca.cust_account_id
--    AND    hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
--    AND    hcsu.site_use_code       = cv_site_use_cd_bt
--    AND    aps.status               = cv_status_op
--    AND    hcsu.site_use_id         = rct.bill_to_site_use_id
--    AND    rct.customer_trx_id      = aps.customer_trx_id);
    SELECT COUNT( cust_bal.cust_account_id )
    INTO   ln_bal_count
    FROM  ( SELECT hca_bill.cust_account_id cust_account_id
            FROM   hz_cust_accounts         hca_ship
                  ,hz_cust_site_uses        hcsu_ship  -- 営業OUのみ
                  ,hz_cust_acct_sites       hcas_ship  -- 営業OUのみ
                  ,hz_cust_accounts         hca_bill
                  ,hz_cust_site_uses        hcsu_bill  -- 営業OUのみ
                  ,hz_cust_acct_sites       hcas_bill  -- 営業OUのみ
                  ,ra_customer_trx_all      rct
                  ,ar_payment_schedules_all aps
            WHERE  hca_ship.customer_class_code IN ( cv_cust_cls_cd_cu, cv_cust_cls_cd_uc )
            AND    hca_ship.cust_account_id      = in_cust_id
            AND    hcas_ship.cust_account_id     = hca_ship.cust_account_id
            AND    hcsu_ship.cust_acct_site_id   = hcas_ship.cust_acct_site_id
            AND    hcsu_ship.site_use_code       = cv_site_use_cd_st
            AND    hcas_bill.cust_account_id     = hca_bill.cust_account_id
            AND    hcsu_bill.cust_acct_site_id   = hcas_bill.cust_acct_site_id
            AND    hcsu_bill.site_use_code       = cv_site_use_cd_bt
            AND    aps.status                    = cv_status_op
            AND    hcsu_ship.bill_to_site_use_id = hcsu_bill.site_use_id
            AND    hca_bill.cust_account_id      = rct.bill_to_customer_id
            AND    rct.customer_trx_id           = aps.customer_trx_id
            AND    ROWNUM                        = 1
            UNION ALL
            SELECT hca.cust_account_id cust_account_id
            FROM   hz_cust_accounts         hca
                  ,hz_cust_site_uses        hcsu  -- 営業OUのみ
                  ,hz_cust_acct_sites       hcas  -- 営業OUのみ
                  ,ra_customer_trx_all      rct
                  ,ar_payment_schedules_all aps
            WHERE  hca.customer_class_code  = cv_cust_cls_cd_uk
            AND    hca.cust_account_id      = in_cust_id
            AND    hcas.cust_account_id     = hca.cust_account_id
            AND    hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
            AND    hcsu.site_use_code       = cv_site_use_cd_bt
            AND    aps.status               = cv_status_op
            AND    hca.cust_account_id      = rct.bill_to_customer_id
            AND    rct.customer_trx_id      = aps.customer_trx_id
            AND    ROWNUM                   = 1
          ) cust_bal
    WHERE  ROWNUM = 1
    ;
-- 2010/02/15 Ver1.3 E_本稼動_XXXXX modify end by Yutaka.Kuboshima
--
    IF ( ln_bal_count > 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10315);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** 残高中止チェックエラー ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --チェックステータス
      ov_err_message  := lv_errmsg;                  --エラーメッセージ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END cust_balance_chk;
--
-- 2011/03/07 Ver1.5 add start
  /**********************************************************************************
   * Procedure Name   : cust_tran_chk
   * Description      : 月内取引存在チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE cust_tran_chk(
    in_cust_id      IN  NUMBER,       --   顧客ID
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_tran_chk'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_add_date_vd     CONSTANT NUMBER := -1;  -- 対象とする取引月（VD）
    cn_add_date_not_vd CONSTANT NUMBER := -2;  -- 対象とする取引月（VD以外）
--
    -- *** ローカル変数 ***
    lv_errmsg     VARCHAR2(5000);                            -- ユーザー・エラー・メッセージ
    lv_cust_code  hz_cust_accounts.account_number%TYPE;      -- ローカル変数・顧客コード
--
  BEGIN
--
    --チェックステータス初期化部
    ov_check_status := cv_sts_check_ok;
    --ローカル変数初期化部
    lv_cust_code := NULL;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      -- 月内取引存在チェック
      --  業態分類(大分類)  = VD  → 最終取引日 >= 1ヶ月前の月初日
      --  業態分類(大分類) <> VD  → 最終取引日 >= 2ヶ月前の月初日
      SELECT xca.customer_code AS customer_code  -- 顧客コード
      INTO   lv_cust_code
      FROM   xxcmm_cust_accounts         xca   -- 顧客追加情報
            ,xxcos_business_conditions_v xbcv  -- 業態分類ビュー
      WHERE  xca.customer_id        = in_cust_id          -- 内部ID
      AND    xca.business_low_type  = xbcv.s_lookup_code  -- 業態分類(小分類)
      AND    xca.final_tran_date   >= TRUNC(
                                        ADD_MONTHS( gd_process_date  -- 業務日付
                                                  , DECODE( xbcv.d_lookup_code  -- 業態分類(大分類)
                                                          , cv_gtal_dai_vd      -- VD('05')
                                                          , cn_add_date_vd      -- VDは、1ヶ月前の月初以内(-1)
                                                          , cn_add_date_not_vd  -- VD以外は、2ヶ月前の月初以内(-2)
                                                    )
                                        )
                                      , cv_date_mm  -- 月初日を取得('MM')
                                      )
      ;
    EXCEPTION
      --*** 対象レコードなしエラー ***
      WHEN NO_DATA_FOUND THEN
        lv_cust_code := NULL;
    END;
--
    -- 月内取引が存在すれば中止NG
    IF ( lv_cust_code IS NOT NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_00356,
                                            cv_cnst_tkn_ccd,
                                            lv_cust_code);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** 中止チェックエラー ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --チェックステータス
      ov_err_message  := lv_errmsg;                  --エラーメッセージ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END cust_tran_chk;
--
-- 2011/03/07 Ver1.5 add end
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_cust_id      IN  NUMBER,       --   顧客ID
    iv_gtai_syo     IN  VARCHAR2,     --   業態分類（小分類）
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_err_message    VARCHAR2(5000);                     --エラーメッセージ
    lv_check_status   VARCHAR2(1);                        --チェックステータス
--
  BEGIN
--
    --チェックステータス初期化部
    lv_check_status := cv_sts_check_ok;
    ov_check_status := cv_sts_check_ok;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- <初期処理>
    -- ===============================
    init(
      in_cust_id      =>  in_cust_id,        -- 顧客ID
      iv_gtai_syo     =>  iv_gtai_syo,       -- 業態分類（小分類）
      ov_check_status =>  lv_check_status,   -- チェックステータス
      ov_err_message  =>  lv_err_message     -- エラーメッセージ
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <物件情報存在チェック>
    -- ===============================
    item_ins(
      in_cust_id      =>  in_cust_id,        -- 顧客ID
      iv_gtai_syo     =>  iv_gtai_syo,       -- 業態分類（小分類）
      ov_check_status =>  lv_check_status,   -- チェックステータス
      ov_err_message  =>  lv_err_message     -- エラーメッセージ
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --業態分類（小分類）チェック
    IF ( iv_gtai_syo IN ( cv_gtal_syo_24, cv_gtal_syo_25, cv_gtal_syo_27 ) ) THEN
      -- =====================================
      -- <基準在庫数・釣銭基準額チェック処理>
      -- =====================================
      cust_base_chk(
        in_cust_id      =>  in_cust_id,        -- 顧客ID
        iv_gtai_syo     =>  iv_gtai_syo,       -- 業態分類（小分類）
        ov_check_status =>  lv_check_status,   -- チェックステータス
        ov_err_message  =>  lv_err_message     -- エラーメッセージ
        );
-- 2010/08/04 Ver1.4 modify start by Shigeto.Niki
--    ELSE
--
      IF ( lv_check_status = cv_sts_check_ng ) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- 2010/08/04 Ver1.4 modify end by Shigeto.Niki
      -- ===============================
      -- <売掛残高チェック処理>
      -- ===============================
      cust_balance_chk(
        in_cust_id      =>  in_cust_id,        -- 顧客ID
        iv_gtai_syo     =>  iv_gtai_syo,       -- 業態分類（小分類）
        ov_check_status =>  lv_check_status,   -- チェックステータス
        ov_err_message  =>  lv_err_message     -- エラーメッセージ
        );
-- 2010/08/04 Ver1.4 delete start by Shigeto.Niki
--    END IF;
-- 2010/08/04 Ver1.4 delete end by Shigeto.Niki
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 insert start
    -- ===============================
    -- <月内取引存在チェック>
    -- ===============================
    cust_tran_chk(
      in_cust_id      =>  in_cust_id,        -- 顧客ID
      ov_check_status =>  lv_check_status,   -- チェックステータス
      ov_err_message  =>  lv_err_message     -- エラーメッセージ
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 insert end
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_err_message  := lv_err_message;
      ov_check_status := lv_check_status;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    in_cust_id      IN  NUMBER,       --   顧客ID
    iv_gtai_syo     IN  VARCHAR2,     --   業態分類（小分類）
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  )
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
--
--
  BEGIN
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      in_cust_id,      -- 顧客ID
      iv_gtai_syo,     -- 業態分類（小分類）
      ov_check_status, -- チェックステータス
      ov_err_message   -- エラーメッセージ
    );
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
      ROLLBACK;
  END main;
--
END XXCMM_CUST_STS_CHG_CHK_PKG;
/
