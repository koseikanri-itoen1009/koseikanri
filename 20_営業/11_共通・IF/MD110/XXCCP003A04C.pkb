CREATE OR REPLACE PACKAGE BODY APPS.XXCCP003A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCCP003A04C(body)
 * Description      : 問屋未確定データ出力（収益認識）
 * MD.070           : 問屋未確定データ出力（収益認識）(MD070_IPO_CCP_003_A04)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/01/15    1.0   SCSK N.Abe       [E_本稼動_16026]新規作成
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
  cv_xxcok_appl_name        CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_all_base_allowed       CONSTANT VARCHAR2(100) := 'XXCOK1_WHOLESALE_INVOICE_UPLOAD_ALL_BASE_ALLOWED';
  cv_err_msg_00003          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00003';   --プロファイル取得エラー
  cv_err_msg_00030          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00030';   --所属部門取得エラー
  cv_token_profile          CONSTANT VARCHAR2(10)  := 'PROFILE';         --トークン名(PROFILE)
  cv_token_user_id          CONSTANT VARCHAR2(10)  := 'USER_ID';         --トークン名(USER_ID)
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
  gv_all_base_allowed VARCHAR2(1);            --カスタム･プロファイル取得変数
  gv_user_dept_code VARCHAR2(100);            --ユーザ担当拠点
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP003A04C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code          IN  VARCHAR2      --   1.拠点
   ,iv_payment_date_from  IN  VARCHAR2      --   2.支払予定日FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   3.支払予定日TO
   ,iv_selling_date_from  IN  VARCHAR2      --   4.売上対象年月日FROM
   ,iv_selling_date_to    IN  VARCHAR2      --   5.売上対象年月日TO
   ,iv_cust_code          IN  VARCHAR2      --   6.顧客
   ,iv_bill_no            IN  VARCHAR2      --   7.請求書No
   ,iv_supplier_code      IN  VARCHAR2      --   8.仕入先CD
   ,iv_status             IN  VARCHAR2      --   9.ステータス
   ,ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
    cv_flag_n               CONSTANT VARCHAR2(1)   := 'N';                 --N:対象外
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_msg            VARCHAR2(5000) DEFAULT NULL;                --メッセージ取得変数
    lb_retcode        BOOLEAN        DEFAULT TRUE;                --メッセージ出力の戻り値
    lv_profile_code   VARCHAR2(100)  DEFAULT NULL; --プロファイル値
    lv_user_dept_code VARCHAR2(100)  DEFAULT NULL; --ユーザ担当拠点
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_process_date  DATE := xxccp_common_pkg2.get_process_date; -- 業務日付
    lt_sales_ou_id   hr_operating_units.organization_id%TYPE;    -- 営業組織ID
--
    -- =======================
    -- ローカル例外
    -- =======================
    get_profile_expt        EXCEPTION;   -- カスタム･プロファイル取得エラー
    get_user_dept_code_expt EXCEPTION;   -- 所属部門取得エラー
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 問屋未確定レコード取得
    CURSOR main_cur( iv_payment_date_from IN VARCHAR2
                   , iv_payment_date_to   IN VARCHAR2
                   )
    IS
      WITH
        base_v AS
          (SELECT hca.account_number AS base_code -- 拠点コード
                 ,hp.party_name      AS base_name -- 拠点名
           FROM   hz_cust_accounts hca -- 顧客マスタ
                 ,hz_parties       hp  -- パーティ
           WHERE  hp.party_id =  hca.party_id
          )
       ,cust_v AS
          (SELECT hca.account_number AS cust_code -- 顧客コード
                 ,hp.party_name      AS cust_name -- 顧客名
           FROM   hz_cust_accounts hca -- 顧客マスタ
                 ,hz_parties       hp  -- パーティ
           WHERE  hp.party_id =  hca.party_id
          )
       ,status_v AS
          (SELECT flvv.lookup_code   AS status      -- ステータス
                 ,flvv.meaning       AS status_name -- ステータス名
           FROM   fnd_lookup_values_vl flvv  -- クイックコード
           WHERE  flvv.lookup_type   = 'XXCOK1_SALES_OUTLET_INV_STATUS'
             AND  flvv.enabled_flag  = 'Y'
             AND  ld_process_date   BETWEEN TRUNC( NVL( flvv.start_date_active ,ld_process_date ) )
                                        AND TRUNC( NVL( flvv.end_date_active   ,ld_process_date ) )
          )
       ,wholesale_v AS
          (SELECT /*+ INDEX(xwbh XXCOK_WHOLESALE_BILL_HEAD_N03) */
                  xwbh.base_code                                    AS base_code
                 ,xwbh.supplier_code                                AS supplier_code
                 ,pvs.attribute1                                    AS supplier_name
                 ,TO_CHAR( xwbh.expect_payment_date, 'RRRR/MM/DD' ) AS expect_payment_date
                 ,NVL( TO_CHAR( xwbl.selling_date, 'YYYY/MM/DD' ), TO_CHAR( TO_DATE(xwbl.selling_month,'YYYYMM'), 'YYYY/MM' ) )
                                                                    AS selling_date
                 ,xwbh.cust_code                                    AS cust_code
                 ,xwbl.bill_no                                      AS bill_no
                 ,xwbl.recon_slip_num                               AS recon_slip_num
                 ,SUM( xwbl.demand_amt )                            AS demand_amt
                 ,SUM( xwbl.payment_amt )                           AS payment_amt
                 ,xwbl.status                                       AS status
           FROM   xxcok_wholesale_bill_head  xwbh  -- 問屋請求書ヘッダ
                 ,xxcok_wholesale_bill_line  xwbl  -- 問屋請求書明細
                 ,po_vendors                 pv    -- 仕入先マスタ
                 ,po_vendor_sites_all        pvs   -- 仕入先サイト
           WHERE  xwbl.wholesale_bill_header_id   =  xwbh.wholesale_bill_header_id
             AND  xwbl.selling_date               IS NOT NULL
             AND  pv.segment1                     =  xwbh.supplier_code
             AND  pvs.vendor_id                   =  pv.vendor_id
             AND  pvs.org_id                      =  lt_sales_ou_id                                               -- 営業組織ID
             AND  xwbh.expect_payment_date        >= TO_DATE( iv_payment_date_from ,'YYYY/MM/DD HH24:MI:SS' )     -- パラメータ.支払予定日FROM
             AND  xwbh.expect_payment_date        <= TO_DATE( iv_payment_date_to   ,'YYYY/MM/DD HH24:MI:SS' )     -- パラメータ.支払予定日TO
             AND  xwbh.base_code                  =  NVL( iv_base_code, xwbh.base_code )                          -- パラメータ.拠点
             AND  xwbl.selling_date               >= NVL( TO_DATE( iv_selling_date_from, 'YYYY/MM/DD HH24:MI:SS' ), xwbl.selling_date ) -- パラメータ.売上対象年月日FROM
             AND  xwbl.selling_date               <= NVL( TO_DATE( iv_selling_date_to,   'YYYY/MM/DD HH24:MI:SS' ), xwbl.selling_date ) -- パラメータ.売上対象年月日TO
             AND  xwbh.cust_code                  =  NVL( iv_cust_code, xwbh.cust_code )                          -- パラメータ.顧客
             AND  xwbl.bill_no                    =  NVL( iv_bill_no, xwbl.bill_no )                              -- パラメータ.請求書NO
             AND  xwbh.supplier_code              =  NVL( iv_supplier_code, xwbh.supplier_code )                  -- パラメータ.仕入先コード
             AND  ( ( iv_status                   = '0' )           -- パラメータ.ステータス（0:全て）
               OR   ( ( iv_status                 = '1' )           -- パラメータ.ステータス（1:未払）
                 AND  ( xwbl.recon_slip_num       IS NULL )
                 AND  ( NVL( xwbl.status, 'DD' )  <> 'D' ) )
               OR   ( ( iv_status                 = '2' )           -- パラメータ.ステータス（2:支払済）
                 AND  ( xwbl.recon_slip_num       IS NOT NULL ) )
               OR   ( ( iv_status                 = '3' )           -- パラメータ.ステータス（3:削除済）
                 AND  ( NVL( xwbl.status, 'DD' )  = 'D' ) ) )
           GROUP BY xwbh.base_code            -- 拠点CD
                   ,xwbh.supplier_code        -- 仕入先CD
                   ,pvs.attribute1            -- 仕入先名
                   ,xwbh.expect_payment_date  -- 支払予定日
                   ,xwbl.selling_month        -- 売上年月
                   ,xwbl.selling_date         -- 売上対象年月日
                   ,xwbh.cust_code            -- 顧客CD
                   ,xwbl.bill_no              -- 請求書No
                   ,xwbl.recon_slip_num       -- 支払伝票番号
                   ,xwbl.status               -- ステータス
          )
      SELECT wv.base_code            AS base_code
            ,bv.base_name            AS base_name
            ,wv.supplier_code        AS supplier_code
            ,wv.supplier_name        AS supplier_name
            ,wv.expect_payment_date  AS expect_payment_date
            ,wv.selling_date         AS selling_date
            ,wv.cust_code            AS cust_code
            ,cv.cust_name            AS cust_name
            ,wv.bill_no              AS bill_no
            ,wv.recon_slip_num       AS recon_slip_num
            ,wv.demand_amt           AS demand_amt
            ,wv.payment_amt          AS payment_amt
            ,RPAD(wv.status,2,' ')   AS status
            ,sv.status_name          AS status_name
      FROM   wholesale_v    wv   -- 問屋請求VIEW
            ,base_v         bv   -- 拠点VIEW
            ,cust_v         cv   -- 顧客VIEW
            ,status_v       sv   -- ステータスVIEW
      WHERE  wv.base_code      = bv.base_code
        AND  wv.cust_code      = cv.cust_code
        AND  wv.status         = sv.status(+)
      ORDER BY wv.base_code            -- 拠点CD
              ,wv.supplier_code        -- 仕入先CD
              ,wv.expect_payment_date  -- 支払予定日
              ,wv.selling_date         -- 売上対象年月日
              ,wv.cust_code            -- 顧客CD
              ,wv.bill_no              -- 請求書No
              ,wv.recon_slip_num       -- 支払伝票番号
      ;
    -- メインカーソルレコード型
    main_rec  main_cur%ROWTYPE;
--
    -- 支払金額取得
    CURSOR deduction_recon_cur( iv_recon_slip_num IN VARCHAR2 )
    IS
      SELECT  ( SELECT NVL(SUM(xdrla.payment_amt),0) from XXCOK_DEDUCTION_RECON_LINE_AP xdrla where xdrla.recon_slip_num = iv_recon_slip_num )  +
              ( SELECT NVL(SUM(xdrlw.payment_amt),0) from XXCOK_DEDUCTION_RECON_LINE_WP xdrlw where xdrlw.recon_slip_num = iv_recon_slip_num )  +
              ( SELECT NVL(SUM(xapi.payment_amt ),0) from XXCOK_ACCOUNT_PAYMENT_INFO    xapi  where xapi .recon_slip_num = iv_recon_slip_num )
                                        AS  payment_amt ,   -- 支払金額
              xdrh.recon_status         AS  status      ,   -- ステータス
              flv.MEANING               AS  status_name     -- ステータス名
      FROM    fnd_lookup_values           flv , -- クイックコード
              xxcok_deduction_recon_head  xdrh  -- 控除消込ヘッダー情報
      WHERE   xdrh.recon_slip_num       = iv_recon_slip_num           AND
              flv.LOOKUP_TYPE           = 'XXCOK1_HEAD_ERASE_STATUS'  AND
              flv.LANGUAGE              = 'JA'                        AND
              flv.LOOKUP_CODE           = xdrh.recon_status;
--
    deduction_recon_rec deduction_recon_cur%ROWTYPE;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init部
    -- ===============================
    BEGIN
      SELECT hou.organization_id AS sales_ou_id
      INTO   lt_sales_ou_id
      FROM   hr_operating_units hou
      WHERE  hou.name = 'SALES-OU'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := '営業組織IDの取得に失敗しました。';
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --==============================================================
    -- カスタム・プロファイル・オプション取得
    --==============================================================
    BEGIN
      gv_all_base_allowed := FND_PROFILE.VALUE( cv_all_base_allowed );
      IF ( gv_all_base_allowed IS NULL ) THEN
        lv_profile_code := cv_all_base_allowed;
        RAISE get_profile_expt;
      END IF;
    END;
--
    -- =============================================================================
    -- 3.ユーザの所属部門を取得
    -- =============================================================================
    BEGIN
      lv_user_dept_code := xxcok_common_pkg.get_department_code_f(
                             in_user_id => cn_created_by
                           );
--
      IF ( lv_user_dept_code IS NULL ) THEN
        RAISE get_user_dept_code_expt;
      END IF;
      gv_user_dept_code := lv_user_dept_code ;
    END;
--
    --==============================================================
    -- 入力パラメータ出力
    --==============================================================
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '拠点 : ' || iv_base_code
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '支払予定日FROM : ' ||
                                TO_CHAR( TO_DATE( iv_payment_date_from ,'YYYY/MM/DD HH24:MI:SS' ) ,'YYYY/MM/DD' )
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '支払予定日TO   : ' ||
                                TO_CHAR( TO_DATE( iv_payment_date_to   ,'YYYY/MM/DD HH24:MI:SS' ) ,'YYYY/MM/DD' )
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '売上対象年月日FROM : ' ||
                                TO_CHAR( TO_DATE( iv_selling_date_from ,'YYYY/MM/DD HH24:MI:SS' ) ,'YYYY/MM/DD' )
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '売上対象年月日TO   : ' ||
                                TO_CHAR( TO_DATE( iv_selling_date_to   ,'YYYY/MM/DD HH24:MI:SS' ) ,'YYYY/MM/DD' )
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '顧客 : ' || iv_cust_code
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '請求書No : ' || iv_bill_no
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '仕入先コード : ' || iv_supplier_code
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => 'ステータス : ' || CASE
                                                     WHEN iv_status = '0' THEN
                                                        '全て'
                                                     WHEN iv_status = '1' THEN
                                                        '未払'
                                                     WHEN iv_status = '2' THEN
                                                        '支払済'
                                                     WHEN iv_status = '3' THEN
                                                        '削除済'
                                                   END
                     );
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 支払予定日FROM > 支払予定日TO の場合
    IF ( TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' ) > TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' ) ) THEN
      ov_errbuf  := '支払予定日FROM は 支払予定日TO 以前の日付を指定して下さい。';
      ov_retcode := cv_status_error;
    -- 支払予定日FROM > 支払予定日TO の場合
    ELSIF ( ( iv_selling_date_from IS NOT NULL AND iv_selling_date_to IS NOT NULL )
      AND   ( TO_DATE( iv_selling_date_from, 'YYYY/MM/DD HH24:MI:SS' ) > TO_DATE( iv_selling_date_to, 'YYYY/MM/DD HH24:MI:SS' ) ) ) THEN
      ov_errbuf  := '売上対象年月日FROM は 売上対象年月日TO 以前の日付を指定して下さい。';
      ov_retcode := cv_status_error;
    ELSE
      -- ===============================
      -- 処理部
      -- ===============================
--
      -- 項目名出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>           '"' || '削除区分'                   || '"' -- 削除区分
                   || ',' || '"' || '拠点CD'                     || '"' -- 拠点CD
                   || ',' || '"' || '拠点名'                     || '"' -- 拠点名
                   || ',' || '"' || '仕入先CD'                   || '"' -- 仕入先CD
                   || ',' || '"' || '仕入先名'                   || '"' -- 仕入先名
                   || ',' || '"' || '支払予定日'                 || '"' -- 支払予定日
                   || ',' || '"' || '売上対象年月日'             || '"' -- 売上対象年月日
                   || ',' || '"' || '顧客CD'                     || '"' -- 顧客CD
                   || ',' || '"' || '顧客名'                     || '"' -- 顧客名
                   || ',' || '"' || '請求書No'                   || '"' -- 請求書No
                   || ',' || '"' || '支払伝票番号'               || '"' -- 支払伝票番号
                   || ',' || '"' || '請求金額'                   || '"' -- 請求金額
                   || ',' || '"' || '支払金額'                   || '"' -- 支払金額
                   || ',' || '"' || 'ステータス'                 || '"' -- ステータス
                   || ',' || '"' || 'ステータス名'               || '"' -- ステータス名
      );
      -- データ部出力(CSV)
      FOR main_rec IN main_cur( iv_payment_date_from, iv_payment_date_to ) LOOP
        IF ( gv_all_base_allowed  <> cv_flag_n )
          OR ( gv_all_base_allowed = cv_flag_n AND lv_user_dept_code = main_rec.base_code )
          THEN
        --件数セット
          gn_target_cnt := gn_target_cnt + 1;
          IF  main_rec.recon_slip_num IS  NOT NULL  THEN
            OPEN  deduction_recon_cur(main_rec.recon_slip_num);
            FETCH deduction_recon_cur INTO  deduction_recon_rec;
            CLOSE deduction_recon_cur;
            main_rec.payment_amt  :=  deduction_recon_rec.payment_amt ;
            main_rec.status       :=  deduction_recon_rec.status      ;
            main_rec.status_name  :=  deduction_recon_rec.status_name ;
          END IF;
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   =>         '"' || NULL                         || '"' -- 削除区分
                     || ',' || '"' || main_rec.base_code           || '"' -- 拠点CD
                     || ',' || '"' || main_rec.base_name           || '"' -- 拠点名
                     || ',' || '"' || main_rec.supplier_code       || '"' -- 仕入先CD
                     || ',' || '"' || main_rec.supplier_name       || '"' -- 仕入先名
                     || ',' || '"' || main_rec.expect_payment_date || '"' -- 支払予定日
                     || ',' || '"' || main_rec.selling_date        || '"' -- 売上対象年月日
                     || ',' || '"' || main_rec.cust_code           || '"' -- 顧客CD
                     || ',' || '"' || main_rec.cust_name           || '"' -- 顧客名
                     || ',' || '"' || main_rec.bill_no             || '"' -- 請求書No
                     || ',' || '"' || main_rec.recon_slip_num      || '"' -- 支払伝票番号
                     || ',' || '"' || main_rec.demand_amt          || '"' -- 請求金額
                     || ',' || '"' || main_rec.payment_amt         || '"' -- 支払金額
                     || ',' || '"' || main_rec.status              || '"' -- ステータス
                     || ',' || '"' || main_rec.status_name         || '"' -- ステータス名
          );
        END IF ;
      END LOOP;
--
      -- 成功件数=対象件数
      gn_normal_cnt  := gn_target_cnt;
      -- 対象件数=0であればメッセージ出力
      IF ( gn_target_cnt = 0 ) THEN
       FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => CHR(10) || '対象データはありません。'
       );
      END IF;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** プロファイル取得エラー ***
    WHEN get_profile_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00003
                , iv_token_name1  => cv_token_profile
                , iv_token_value1 => lv_profile_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    WHEN get_user_dept_code_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00030
                , iv_token_name1  => cv_token_user_id
                , iv_token_value1 => cn_created_by
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
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
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_base_code          IN  VARCHAR2      --   1.拠点
   ,iv_payment_date_from  IN  VARCHAR2      --   2.支払予定日FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   3.支払予定日TO
   ,iv_selling_date_from  IN  VARCHAR2      --   4.売上対象年月日FROM
   ,iv_selling_date_to    IN  VARCHAR2      --   5.売上対象年月日TO
   ,iv_cust_code          IN  VARCHAR2      --   6.顧客
   ,iv_bill_no            IN  VARCHAR2      --   7.請求書No
   ,iv_supplier_code      IN  VARCHAR2      --   8.仕入先CD
   ,iv_status             IN  VARCHAR2      --   9.ステータス(0:全て,1:未払,2:支払済,3:削除済)
  )
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
       iv_base_code          --   1.拠点
      ,iv_payment_date_from  --   2.支払予定日FROM
      ,iv_payment_date_to    --   3.支払予定日TO
      ,iv_selling_date_from  --   4.売上対象年月日FROM
      ,iv_selling_date_to    --   5.売上対象年月日TO
      ,iv_cust_code          --   6.顧客
      ,iv_bill_no            --   7.請求書No
      ,iv_supplier_code      --   8.仕入先CD
      ,iv_status             --   9.ステータス
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP003A04C;
/
