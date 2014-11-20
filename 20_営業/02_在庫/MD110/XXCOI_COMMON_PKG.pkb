CREATE OR REPLACE PACKAGE BODY XXCOI_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI_COMMON_PKG(body)
 * Description      : 共通関数パッケージ(在庫)
 * MD.070           : 共通関数    MD070_IPO_COI
 * Version          : 1.10
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  ORG_ACCT_PERIOD_CHK        在庫会計期間チェック
 *  GET_ORGANIZATION_ID        在庫組織ID取得
 *  GET_BELONGING_BASE         所属拠点コード取得1
 *  GET_BASE_CODE              所属拠点コード取得2
 *  GET_MEANING                LOOKUP情報取得
 *  GET_CMPNT_COST             標準原価取得
 *  GET_DISCRETE_COST          営業原価取得
 *  GET_TRANSACTION_TYPE_ID    取引タイプID取得
 *  GET_ITEM_INFO              品目情報取得1
 *  GET_ITEM_CODE              品目情報取得2
 *  GET_UOM_DISABLE_INFO       単位無効日情報取得
 *  GET_SUBINVENTORY_INFO1     保管場所情報取得1
 *  GET_SUBINVENTORY_INFO2     保管場所情報取得2
 *  GET_MANAGE_DEPT_F          管理課判別フラグ取得
 *  GET_LOOKUP_VALUES          クイックコードマスタ情報取得
 *  CONVERT_WHOUSE_SUBINV_CODE HHT保管場所コード変換 倉庫保管場所コード変換
 *  CONVERT_EMP_SUBINV_CODE    HHT保管場所コード変換 営業車保管場所コード変換
 *  CONVERT_CUST_SUBINV_CODE   HHT保管場所コード変換 預け先保管場所コード変換
 *  CONVERT_BASE_SUBINV_CODE   HHT保管場所コード変換 メイン倉庫保管場所コード変換
 *  CHECK_CUST_STATUS          HHT保管場所コード変換 顧客ステータスチェック
 *  CONVERT_SUBINV_CODE        HHT保管場所コード変換
 *  GET_DISPOSITION_ID         勘定科目別名ID取得
 *  ADD_HHT_ERR_LIST_DATA      HHT情報取込エラー出力
 *  GET_DISPOSITION_ID_2       勘定科目別名ID取得2
 *  GET_ITEM_INFO2             品目情報取得(品目ID、単位コード)
 *  GET_BASE_AFF_ACTIVE_DATE   拠点AFF部門適用開始日取得
 *  GET_SUBINV_AFF_ACTIVE_DATE 保管場所AFF部門適用開始日取得
 *  CHK_AFF_ACTIVE             AFF部門チェック
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/23    1.0   T.Nishikawa      新規作成
 *  2009/03/13    1.1   H.Wada           get_subinventory_info1 取得条件修正(障害番号T1_0040)
 *  2009/03/30    1.2   N.Abe            convert_cust_subinv_code 顧客ステータス不備対応(障害番号T1_0165)
 *  2009/04/09    1.3   H.Sasaki         [T1_0380]入庫側顧客コードの戻り値設定
 *  2009/04/24    1.4   T.Nakamura       [T1_0630]倉庫保管場所変換で、専門店直営の保管場所コード体系に対応
 *  2009/04/30    1.5   T.Nakamura       最終行にバックスラッシュを追加
 *  2009/04/30    1.5   T.Nakamura       最終行にバックスラッシュを追加
 *  2009/05/18    1.6   T.Nakamura       [T1_1044]HHT倉庫保管場所コードの取得条件変更
 *  2009/06/03    1.7   H.Sasaki         [T1_1287][T1_1288]アサイメントの有効日を条件に追加
 *  2009/09/30    1.8   N.Abe            [E_T3_00616]アサインメントの有効日を条件に追加
 *  2010/03/23    1.9   Y.Goto           [E_本稼動_01943]AFF部門適用開始日取得を追加
 *  2010/03/29    1.10  Y.Goto           [E_本稼動_01943]AFF部門チェックを追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;   -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;     -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;    -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATIO
--N_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DAT
--BUSINESS
  cd_business_date          CONSTANT DATE        := xxccp_common_pkg2.get_process_date;   -- 業務日付
  cn_business_group_id      CONSTANT NUMBER      := fnd_global.per_business_group_id;     -- BUSINESS_GROUP_ID
--E
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI_COMMON_PKG';       -- パッケージ名
--
--################################  固定部 END   ##################################
--
--
/************************************************************************
 * Function Name   : ORG_ACCT_PERIOD_CHK
 * Description     : 対象日に対応する在庫会計期間がオープンしているかを
 *                   チェックする。
 ************************************************************************/
  PROCEDURE org_acct_period_chk(
    in_organization_id IN  NUMBER       -- 在庫組織ID
   ,id_target_date     IN  DATE         -- 対象日
   ,ob_chk_result      OUT BOOLEAN      -- ステータス
   ,ov_errbuf          OUT VARCHAR2     -- エラーメッセージ
   ,ov_retcode         OUT VARCHAR2     -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg          OUT VARCHAR2     -- ユーザー・エラーメッセージ
  )
  IS
    cv_prg_name        CONSTANT VARCHAR2(30) := 'org_acct_period_chk';
    lv_open_flg        VARCHAR2(10);
  BEGIN
    ob_chk_result := FALSE;
    IF (in_organization_id IS NULL OR id_target_date IS NULL) THEN
      ov_retcode := cv_status_error;    -- 異常:2
    ELSE
      ov_retcode := cv_status_normal;   -- 正常:0
      SELECT oap.open_flag AS open_flag
      INTO   lv_open_flg
      FROM   org_acct_periods oap
      WHERE  oap.organization_id = in_organization_id
      AND    id_target_date BETWEEN oap.period_start_date AND oap.schedule_close_date;
      --
      IF (lv_open_flg = 'Y') THEN
        ob_chk_result := TRUE;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END org_acct_period_chk;
/************************************************************************
 * Function Name   : GET_ORGANIZATION_ID
 * Description     : 販売物流領域の在庫組織IDを取得する。
 ************************************************************************/
  FUNCTION get_organization_id(
    iv_organization_code IN VARCHAR2    -- 在庫組織コード
  ) RETURN NUMBER
  IS
    ln_organization_id NUMBER;
  BEGIN
    BEGIN
      SELECT mp.organization_id AS organization_id -- 組織ID
      INTO   ln_organization_id
      FROM   mtl_parameters mp                     -- 組織パラメータ
      WHERE  mp.organization_code = iv_organization_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_organization_id;
  END get_organization_id;
/************************************************************************
 * Procedure Name  : GET_BELONGING_BASE
 * Description     : ログインユーザーに紐付く所属拠点コードを取得する。
 ************************************************************************/
  PROCEDURE get_belonging_base(
    in_user_id      IN  NUMBER          -- ユーザーID
   ,id_target_date  IN  DATE            -- 対象日
   ,ov_base_code    OUT VARCHAR2        -- 拠点コード
   ,ov_errbuf       OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode      OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg       OUT VARCHAR2        -- ユーザー・エラーメッセージ
  )
  IS
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_belonging_base';
  BEGIN
    IF (in_user_id IS NULL OR id_target_date IS NULL) THEN
      ov_retcode := cv_status_error;    -- 異常:2
    ELSE
      ov_retcode := cv_status_normal;   -- 正常:0
      SELECT CASE
             WHEN aaf.ass_attribute2 IS NULL                -- 発令日
             THEN aaf.ass_attribute5
             WHEN TO_DATE(aaf.ass_attribute2,'YYYYMMDD') > id_target_date
             THEN aaf.ass_attribute6                        -- 拠点コード（旧）
             ELSE aaf.ass_attribute5                        -- 拠点コード（新）
             END  AS base_code
      INTO   ov_base_code                                   -- 自拠点コード
      FROM   fnd_user                 fnu                   -- ユーザーマスタ
            ,per_all_people_f         apf                   -- 従業員マスタ
            ,per_all_assignments_f    aaf                   -- 従業員割当マスタ(アサイメント)
            ,per_person_types         ppt                   -- 従業員区分マスタ
      WHERE  fnu.user_id            = in_user_id            -- FND_GLOBAL.USER_ID
      AND    apf.person_id          = fnu.employee_id
      AND    TRUNC(id_target_date) BETWEEN TRUNC(apf.effective_start_date)
      AND    TRUNC(NVL(apf.effective_end_date,id_target_date))
-- == 2009/09/30 V1.8 Added START ===============================================================
      AND    TRUNC(id_target_date) BETWEEN TRUNC(aaf.effective_start_date)
      AND    TRUNC(NVL(aaf.effective_end_date,id_target_date))
-- == 2009/09/30 V1.8 Added END   ===============================================================
      AND    ppt.business_group_id  = cn_business_group_id
      AND    ppt.system_person_type = 'EMP'
      AND    ppt.active_flag        = 'Y'
      AND    apf.person_type_id     = ppt.person_type_id
      AND    aaf.person_id          = apf.person_id;
      --
      IF (ov_base_code IS NULL) THEN
        ov_retcode := cv_status_error;    -- 異常:2
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_belonging_base;
/************************************************************************
 * Function Name   : GET_BASE_CODE
 * Description     : 所属拠点コード取得のファンクション機能。
 ************************************************************************/
  FUNCTION get_base_code(
    in_user_id      IN NUMBER             -- ユーザーID
   ,id_target_date  IN DATE               -- 対象日
  ) RETURN VARCHAR2
  IS
    lv_base_code    VARCHAR2(4) := NULL;  -- 拠点コード
    ln_user_id      NUMBER;
    ld_target_date  DATE;
  BEGIN
    IF (in_user_id IS NULL) THEN
      ln_user_id := fnd_global.user_id;
    ELSE
      ln_user_id := in_user_id;
    END IF;
    IF (id_target_date IS NULL) THEN
      ld_target_date := SYSDATE;
    ELSE
      ld_target_date := id_target_date;
    END IF;
    BEGIN
      SELECT  CASE
                WHEN aaf.ass_attribute2 IS NULL                   -- 発令日
                  THEN aaf.ass_attribute5
                WHEN TO_DATE(aaf.ass_attribute2,'YYYYMMDD') > ld_target_date
                  THEN aaf.ass_attribute6                         -- 拠点コード（旧）
                  ELSE aaf.ass_attribute5                         -- 拠点コード（新）
              END  AS base_code
      INTO    lv_base_code                                        -- 自拠点コード
      FROM    fnd_user                 fnu                        -- ユーザーマスタ
             ,per_all_people_f         apf                        -- 従業員マスタ
             ,per_all_assignments_f    aaf                        -- 従業員割当マスタ(アサイメント)
             ,per_person_types         ppt                        -- 従業員区分マスタ
      WHERE   fnu.user_id            = ln_user_id                 -- FND_GLOBAL.USER_ID
      AND     apf.person_id          = fnu.employee_id
      AND     TRUNC(ld_target_date) BETWEEN TRUNC(apf.effective_start_date)
      AND     TRUNC(NVL(apf.effective_end_date,ld_target_date))
-- == 2009/06/03 V1.7 Added START ===============================================================
      AND     TRUNC(ld_target_date) BETWEEN TRUNC(aaf.effective_start_date)
      AND     TRUNC(NVL(aaf.effective_end_date,ld_target_date))
-- == 2009/06/03 V1.7 Added END   ===============================================================
      AND    ppt.business_group_id  = cn_business_group_id
      AND    ppt.system_person_type = 'EMP'
      AND    ppt.active_flag        = 'Y'
      AND    apf.person_type_id     = ppt.person_type_id
      AND    aaf.person_id          = apf.person_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN lv_base_code;
  END get_base_code;
/************************************************************************
 * Function Name   : GET_MEANING
 * Description     : クイックコードの参照タイプ・参照コードの内容を取得する。
 ************************************************************************/
  FUNCTION get_meaning(
    iv_lookup_type IN VARCHAR2          -- 参照タイプ
   ,iv_lookup_code IN VARCHAR2          -- 参照コード
  ) RETURN VARCHAR2
  IS
    lv_translated_string VARCHAR2(500) := NULL;
  BEGIN
    BEGIN
      SELECT flv.meaning AS meaning
      INTO   lv_translated_string
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_code   = iv_lookup_code
      AND    flv.lookup_type   = iv_lookup_type
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = 'Y'
      AND    SYSDATE BETWEEN NVL(flv.start_date_active,SYSDATE)
                     AND     NVL(flv.end_date_active,  SYSDATE);
      --
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN lv_translated_string;
  END get_meaning;
/************************************************************************
 * Procedure Name  : GET_CMPNT_COST
 * Description     : 品目IDを元に標準原価を取得します。
 ************************************************************************/
  PROCEDURE get_cmpnt_cost(
    in_item_id      IN  NUMBER          -- 品目ID
   ,in_org_id       IN  NUMBER          -- 組織ID
   ,id_period_date  IN  DATE            -- 対象日
   ,ov_cmpnt_cost   OUT VARCHAR2        -- 標準原価
   ,ov_errbuf       OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode      OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg       OUT VARCHAR2        -- ユーザー・エラーメッセージ
  )
  IS
    cv_prg_name     CONSTANT VARCHAR2(99) := 'get_cmpnt_cost';
    lv_calendar_code         VARCHAR2(4);       -- 期間
  BEGIN
    IF (in_item_id      IS NULL
      OR in_org_id      IS NULL
      OR id_period_date IS NULL) THEN
      ov_retcode := cv_status_error;    -- 異常:2
    ELSE
      ov_retcode := cv_status_normal;   -- 正常:0
      --
      -- ===================================
      --  年度設定
      -- ===================================
      lv_calendar_code := TO_CHAR(id_period_date,'YYYY');
      IF (id_period_date < TO_DATE(lv_calendar_code||'0501','YYYYMMDD')) THEN
        -- 対象日が5/1以前の場合、対象日の前年を年度とする
        lv_calendar_code := TO_CHAR(TO_NUMBER(lv_calendar_code) - 1);
      END IF;
      --
      SELECT SUM(TO_NUMBER(ccd.cmpnt_cost)) AS cmpnt_cost
      INTO   ov_cmpnt_cost
      FROM   cm_cmpt_dtl              ccd
            ,ic_item_mst_b            cimb
            ,mtl_system_items_b       msib
      WHERE  ccd.item_id            = cimb.item_id
      AND    ccd.calendar_code      = lv_calendar_code
      AND    cimb.item_no           = msib.segment1
      AND    msib.inventory_item_id = in_item_id
      AND    msib.organization_id   = in_org_id;
    END IF;
    --
    IF (ov_cmpnt_cost IS NULL) THEN
      ov_retcode    := cv_status_error; -- 異常:2
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_cmpnt_cost := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_cmpnt_cost;
/************************************************************************
 * Procedure Name  : GET_DISCRETE_COST
 * Description     : 品目IDを元に確定済みの営業原価を取得します。
 ************************************************************************/
  PROCEDURE get_discrete_cost(
    in_item_id        IN  NUMBER             -- 品目ID
   ,in_org_id         IN  NUMBER             -- 組織ID
   ,id_target_date    IN  DATE               -- 対象日
   ,ov_discrete_cost  OUT VARCHAR2           -- 営業原価
   ,ov_errbuf         OUT VARCHAR2           -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2           -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2           -- ユーザー・エラーメッセージ
  )
  IS
    cv_prg_name  CONSTANT VARCHAR2(99) := 'get_discrete_cost';
  BEGIN
    IF (in_item_id      IS NULL
      OR in_org_id      IS NULL
      OR id_target_date IS NULL) THEN
      ov_retcode := cv_status_error;         -- 異常:2
    ELSE
      ov_retcode := cv_status_normal;        -- 正常:0
      BEGIN
        SELECT CASE
               WHEN imb.attribute9 <= TO_CHAR(id_target_date,'YYYY/MM/DD') -- 営業原価適用開始日
               THEN imb.attribute8                                  -- 営業原価(新)
               ELSE imb.attribute7                                  -- 旧営業原価
               END  AS discrete_cost
        INTO   ov_discrete_cost
        FROM   mtl_system_items_b     sib                           -- Disc品目マスタ
              ,ic_item_mst_b          imb                           -- OPM品目マスタ
        WHERE  sib.organization_id               = in_org_id        -- 営業システムの在庫組織ID
          AND  sib.inventory_item_id             = in_item_id       -- 対象品目ID
          AND  sib.inventory_item_status_code   <> 'Inactive'       -- 品目ステータス：全機能使用可能
          AND  sib.customer_order_enabled_flag   = 'Y'              -- 顧客受注可能フラグ
          AND  sib.mtl_transactions_enabled_flag = 'Y'              -- 取引可能
          AND  sib.stock_enabled_flag            = 'Y'              -- 在庫保有可能フラグ
          AND  sib.returnable_flag               = 'Y'              -- 返品可能
          AND  imb.item_no                       = sib.segment1     -- 品名コード
          AND  imb.attribute26                   = '1';             -- 売上対象区分
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT cic.item_cost AS item_cost
          INTO   ov_discrete_cost
          FROM   cst_item_costs          cic -- Disc品目原価
          WHERE  cic.inventory_item_id = in_item_id
          AND    cic.organization_id   = in_org_id
          AND    cic.cost_type_id      = 1;  -- 確定済
      END;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_discrete_cost := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_discrete_cost;
/************************************************************************
 * Function Name   : GET_TRANSACTION_TYPE_ID
 * Description     : 取引タイプ名をもとに、取引タイプIDを取得
 ************************************************************************/
  FUNCTION  get_transaction_type_id(
    iv_transaction_type_name IN VARCHAR2     -- 取引タイプ名
  ) RETURN NUMBER
  IS
    ln_transaction_type_id NUMBER;
  BEGIN
    BEGIN
      SELECT mtt.transaction_type_id AS transaction_type_id
      INTO   ln_transaction_type_id
      FROM   mtl_transaction_types mtt
      WHERE  NVL(mtt.disable_date,SYSDATE) >= SYSDATE
      AND    mtt.transaction_type_name      = iv_transaction_type_name;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_transaction_type_id;
  END get_transaction_type_id;
/************************************************************************
 * Function Name   : GET_ITEM_CODE
 * Description     : 品目IDをもとに品目コードを取得する。
 ************************************************************************/
  FUNCTION get_item_code(
    in_item_id    IN NUMBER             -- 品目ID
   ,in_org_id     IN NUMBER             -- 組織ID
  ) RETURN VARCHAR2
  IS
    lv_item_code VARCHAR2(40) := NULL;  -- 品目コード
  BEGIN
    BEGIN
      SELECT msib.segment1 AS item_code
      INTO   lv_item_code
      FROM   mtl_system_items_b msib
      WHERE  msib.inventory_item_id = in_item_id
      AND    msib.organization_id   = in_org_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN lv_item_code;
  END get_item_code;
--
/************************************************************************
 * Procedure Name  : get_item_info
 * Description     : 品目チェックに使用する品目付加情報を取得します。
 ************************************************************************/
  PROCEDURE get_item_info(
    ov_errbuf               OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode              OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg               OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_item_code            IN  VARCHAR2   -- 4.品目コード
   ,in_org_id               IN  NUMBER     -- 5.在庫組織ID
   ,ov_item_status          OUT VARCHAR2   -- 6.品目ステータス
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.顧客受注可能フラグ
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.取引可能
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.在庫保有可能フラグ
   ,ov_return_enable        OUT VARCHAR2   -- 10.返品可能
   ,ov_sales_class          OUT VARCHAR2   -- 11.売上対象区分
   ,ov_primary_unit         OUT VARCHAR2   -- 12.基準単位
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'get_item_info';   -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';              -- アプリケーション短縮名
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 対象データ無しメッセージ
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- 複数件取得エラー
    cv_msg_coi_10258       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10258';   -- 入力パラメータ未設定エラー（品目コード）
    cv_msg_coi_10259       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10259';   -- 入力パラメータ未設定エラー（在庫組織ID）
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル例外 ***
    no_parameter_expt   EXCEPTION;   -- パラメータ未設定エラー
--
  BEGIN
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ====================================================
    -- INパラメータチェック
    -- ====================================================
    -- 品目コードが未設定の場合
    IF (iv_item_code IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10258);
      RAISE no_parameter_expt;
    END IF;
--
    -- 在庫組織IDが未設定の場合
    IF (in_org_id IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10259);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- 品目情報 取得
    -- ====================================================
    SELECT msib.inventory_item_status_code    AS inventory_item_status_code      -- 1.品目ステータス
          ,msib.customer_order_enabled_flag   AS customer_order_enabled_flag     -- 2.顧客受注可能フラグ
          ,msib.mtl_transactions_enabled_flag AS mtl_transactions_enabled_flag   -- 3.取引可能
          ,msib.stock_enabled_flag            AS stock_enabled_flag              -- 4.在庫保有可能フラグ
          ,msib.returnable_flag               AS returnable_flag                 -- 5.返品可能
          ,iimb.attribute26                   AS attribute26                     -- 6.売上対象区分
          ,msib.primary_unit_of_measure       AS primary_unit_of_measure         -- 7.基準単位
    INTO   ov_item_status            -- 1.品目ステータス
          ,ov_cust_order_flg         -- 2.顧客受注可能フラグ
          ,ov_transaction_enable     -- 3.取引可能
          ,ov_stock_enabled_flg      -- 4.在庫保有可能フラグ
          ,ov_return_enable          -- 5.返品可能
          ,ov_sales_class            -- 6.売上対象区分
          ,ov_primary_unit           -- 7.基準単位
    FROM   mtl_system_items_b msib   -- 1.Disc品目マスタ
          ,ic_item_mst_b      iimb   -- 2.OPM品目マスタ
    WHERE  msib.segment1        = iv_item_code
    AND    msib.organization_id = in_org_id
    AND    iimb.item_no         = msib.segment1;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** 取得件数なしエラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** 複数件取得エラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** パラメータ未設定エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_item_info;
--
--
/************************************************************************
 * Procedure Name  : get_item_info2
 * Description     : 品目チェックに使用する品目付加情報を取得します。
 ************************************************************************/
  PROCEDURE get_item_info2(
    ov_errbuf               OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode              OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg               OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_item_code            IN  VARCHAR2   -- 4.品目コード
   ,in_org_id               IN  NUMBER     -- 5.在庫組織ID
   ,ov_item_status          OUT VARCHAR2   -- 6.品目ステータス
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.顧客受注可能フラグ
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.取引可能
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.在庫保有可能フラグ
   ,ov_return_enable        OUT VARCHAR2   -- 10.返品可能
   ,ov_sales_class          OUT VARCHAR2   -- 11.売上対象区分
   ,ov_primary_unit         OUT VARCHAR2   -- 12.基準単位
   ,on_inventory_item_id    OUT NUMBER     -- 13.品目ID
   ,ov_primary_uom_code     OUT VARCHAR2   -- 14.基準単位コード
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'get_item_info';   -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';              -- アプリケーション短縮名
--
    cv_msg_coi_10368       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10368';   -- 品目取得例外メッセージ
    cv_msg_coi_10369       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10369';   -- 品目複数件取得エラー
    cv_msg_coi_10258       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10258';   -- 入力パラメータ未設定エラー（品目コード）
    cv_msg_coi_10259       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10259';   -- 入力パラメータ未設定エラー（在庫組織ID）
    --
    cv_tkn_item_code       CONSTANT VARCHAR2(9)  := 'ITEM_CODE';          -- TKN:IETM_CODE
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル例外 ***
    no_parameter_expt   EXCEPTION;   -- パラメータ未設定エラー
--
  BEGIN
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ====================================================
    -- INパラメータチェック
    -- ====================================================
    -- 品目コードが未設定の場合
    IF (iv_item_code IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10258);
      RAISE no_parameter_expt;
    END IF;
--
    -- 在庫組織IDが未設定の場合
    IF (in_org_id IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10259);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- 品目情報 取得
    -- ====================================================
    SELECT msib.inventory_item_status_code    AS inventory_item_status_code      -- 1.品目ステータス
          ,msib.customer_order_enabled_flag   AS customer_order_enabled_flag     -- 2.顧客受注可能フラグ
          ,msib.mtl_transactions_enabled_flag AS mtl_transactions_enabled_flag   -- 3.取引可能
          ,msib.stock_enabled_flag            AS stock_enabled_flag              -- 4.在庫保有可能フラグ
          ,msib.returnable_flag               AS returnable_flag                 -- 5.返品可能
          ,iimb.attribute26                   AS attribute26                     -- 6.売上対象区分
          ,msib.primary_unit_of_measure       AS primary_unit_of_measure         -- 7.基準単位
          ,msib.inventory_item_id             AS inventory_item_id               -- 8.品目ID
          ,msib.primary_uom_code              AS primary_uom_code                -- 9.基準単位コード
    INTO   ov_item_status            -- 1.品目ステータス
          ,ov_cust_order_flg         -- 2.顧客受注可能フラグ
          ,ov_transaction_enable     -- 3.取引可能
          ,ov_stock_enabled_flg      -- 4.在庫保有可能フラグ
          ,ov_return_enable          -- 5.返品可能
          ,ov_sales_class            -- 6.売上対象区分
          ,ov_primary_unit           -- 7.基準単位
          ,on_inventory_item_id      -- 8.品目ID
          ,ov_primary_uom_code       -- 9.基準単位コード
    FROM   mtl_system_items_b msib   -- 1.Disc品目マスタ
          ,ic_item_mst_b      iimb   -- 2.OPM品目マスタ
    WHERE  msib.segment1        = iv_item_code
    AND    msib.organization_id = in_org_id
    AND    iimb.item_no         = msib.segment1;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** 取得件数なしエラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10368
                     ,iv_token_name1  => cv_tkn_item_code
                     ,iv_token_value1 => iv_item_code
                      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** 複数件取得エラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10369
                     ,iv_token_name1  => cv_tkn_item_code
                     ,iv_token_value1 => iv_item_code
                      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** パラメータ未設定エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_item_info2;
--
/************************************************************************
 * Procedure Name  : get_uom_disable_info
 * Description     : 単位マスタより単位の無効日を取得します。
 ************************************************************************/
  PROCEDURE get_uom_disable_info(
    ov_errbuf         OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode        OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg         OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_unit_code      IN  VARCHAR2   -- 4.単位コード
   ,od_disable_date   OUT DATE       -- 5.無効日
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uom_disable_info'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';   -- アプリケーション短縮名
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 対象データ無しメッセージ
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- 複数件取得エラー
    cv_msg_coi_10260       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10260';   -- 入力パラメータ未設定エラー（単位コード）
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル例外 ***
    no_parameter_expt   EXCEPTION;   -- パラメータ未設定エラー
--
  BEGIN
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ====================================================
    -- INパラメータチェック
    -- ====================================================
    -- 単位コードが未設定の場合
    IF (iv_unit_code IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10260);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- 無効日 取得
    -- ====================================================
    SELECT muomt.disable_date AS disable_date   -- 1.無効日
    INTO   od_disable_date                      -- 1.無効日
    FROM   mtl_units_of_measure_tl muomt        -- 1.単位マスタ
    WHERE  muomt.uom_code = iv_unit_code
    AND    muomt.language = USERENV('LANG');
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** 取得件数なしエラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** 複数件取得エラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** パラメータ未設定エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_uom_disable_info;
--
/************************************************************************
 * Procedure Name  : get_subinventory_info1
 * Description     : 保管場所マスタより、拠点コード・倉庫コードを基に
 *                   保管場所コードと無効日を取得します。
 ************************************************************************/
  PROCEDURE get_subinventory_info1(
    ov_errbuf         OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode        OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg         OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code      IN  VARCHAR2   -- 4.拠点コード
   ,iv_whse_code      IN  VARCHAR2   -- 5.倉庫コード
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.保管場所コード
   ,od_disable_date   OUT DATE       -- 7.無効日
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_subinventory_info1'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';   -- アプリケーション短縮名
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 対象データ無しメッセージ
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- 複数件取得エラー
    cv_msg_coi_10261       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10261';   -- 入力パラメータ未設定エラー（拠点コード）
    cv_msg_coi_10262       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10262';   -- 入力パラメータ未設定エラー（倉庫コード）
--
    cv_whse_code_whse      CONSTANT VARCHAR2(1) := '1';   -- 倉庫
-- add 2009/03/13 1.1 H.Wada #T1_0040 ↓
    cv_whse_code_store     CONSTANT VARCHAR2(1) := '4';   -- 専門店
-- add 2009/03/13 1.1 H.Wada #T1_0040 ↑
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル例外 ***
    no_parameter_expt      EXCEPTION;   -- パラメータ未設定エラー
--
  BEGIN
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ====================================================
    -- INパラメータチェック
    -- ====================================================
    -- 拠点コードが未設定の場合
    IF (iv_base_code IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10261);
      RAISE no_parameter_expt;
    END IF;
    -- 倉庫コードが未設定の場合
    IF (iv_whse_code IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10262);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- 保管場所情報 取得
    -- ====================================================
    SELECT msi.secondary_inventory_name AS secondary_inventory_name   -- 1.保管場所コード
          ,msi.disable_date             AS disable_date               -- 2.無効日
    INTO   ov_sec_inv_nm     -- 1.保管場所コード
          ,od_disable_date   -- 2.無効日
    FROM   mtl_secondary_inventories msi   -- 1.保管場所マスタ
    WHERE  msi.attribute7 = iv_base_code
    AND    SUBSTRB(msi.secondary_inventory_name,6 ,2) = iv_whse_code
    AND    msi.attribute1 IN (cv_whse_code_whse, cv_whse_code_store);
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                  -- *** 取得件数なしエラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** 複数件取得エラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** パラメータ未設定エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_subinventory_info1;
--
--
/************************************************************************
 * Procedure Name  : get_subinventory_info2
 * Description     : 保管場所マスタより、拠点コード・店舗コードを基に
 *                   保管場所コードと無効日を取得します。
 ************************************************************************/
  PROCEDURE get_subinventory_info2(
    ov_errbuf         OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode        OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg         OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code      IN  VARCHAR2   -- 4.拠点コード
   ,iv_shop_code      IN  VARCHAR2   -- 5.店舗コード
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.保管場所コード
   ,od_disable_date   OUT DATE       -- 7.無効日
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_subinventory_info2'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';   -- アプリケーション短縮名
--
    cv_msg_coi_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 対象データ無しメッセージ
    cv_msg_coi_00025       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00025';   -- 複数件取得エラー
    cv_msg_coi_10261       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10261';   -- 入力パラメータ未設定エラー（拠点コード）
    cv_msg_coi_10263       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10263';   -- 入力パラメータ未設定エラー（店舗コード）
--
    cv_deposit_point       CONSTANT VARCHAR2(1) := '3';   -- 預け先
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル例外 ***
    no_parameter_expt      EXCEPTION;   -- パラメータ未設定エラー
--
  BEGIN
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ====================================================
    -- INパラメータチェック
    -- ====================================================
    -- 拠点コードが未設定の場合
    IF (iv_base_code IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10261);
      RAISE no_parameter_expt;
    END IF;
    -- 店舗コードが未設定の場合
    IF (iv_shop_code IS NULL) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10263);
      RAISE no_parameter_expt;
    END IF;
--
    -- ====================================================
    -- 保管場所情報 取得
    -- ====================================================
    SELECT msi.secondary_inventory_name AS secondary_inventory_name   -- 1.保管場所コード
          ,msi.disable_date             AS disable_date               -- 2.無効日
    INTO   ov_sec_inv_nm     -- 1.保管場所コード
          ,od_disable_date   -- 2.無効日
    FROM   mtl_secondary_inventories msi   -- 1.保管場所マスタ
    WHERE  msi.attribute7 = iv_base_code
    AND    SUBSTRB(msi.secondary_inventory_name,6 ,5) = iv_shop_code
    AND    msi.attribute1 = cv_deposit_point;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN  -- *** 取得件数なしエラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00008);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN                  -- *** 複数件取得エラー ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN no_parameter_expt THEN              -- *** パラメータ必須エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_subinventory_info2;
--
--
/************************************************************************
 * Function Name   : GET_MANAGE_DEPT_F
 * Description     : 自拠点が管理課か単独拠点なのかを判別するフラグを取得する。
 *                   戻り値：0（単独拠点）、1（管理課）
 ************************************************************************/
  FUNCTION get_manage_dept_f(
    iv_base_code   IN   VARCHAR2   -- 1.拠点コード
  ) RETURN NUMBER   -- 管理課判別フラグ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_manage_dept_f'; -- プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_class_code_base   CONSTANT VARCHAR2(10) := '1';   -- 拠点
    cv_status            CONSTANT VARCHAR2(1)  := 'A';   -- ステータス
    cn_sole_base         CONSTANT NUMBER       := 0;     -- 単独拠点
    cn_manage_section    CONSTANT NUMBER       := 1;     -- 管理課
    --
    -- *** ローカル変数 ***
    lt_account_number         hz_cust_accounts.account_number%TYPE;            -- 1.顧客コード
    lt_management_base_code   xxcmm_cust_accounts.management_base_code%TYPE;   -- 2.管理元拠点コード
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
    -- ====================================================
    -- INパラメータチェック
    -- ====================================================
    -- 拠点コードが未設定の場合
    IF (iv_base_code IS NULL) THEN
      RETURN NULL;
    END IF;
    --
    -- ====================================================
    -- 顧客情報 取得
    -- ====================================================
    SELECT hca.account_number         -- 1.顧客コード
          ,xca.management_base_code   -- 2.管理元拠点コード
    INTO   lt_account_number          -- 1.顧客コード
          ,lt_management_base_code    -- 2.管理元拠点コード
    FROM   hz_cust_accounts    hca    -- 1.顧客アカウント
          ,xxcmm_cust_accounts xca    -- 2.顧客追加情報アドオン
    WHERE  hca.account_number = iv_base_code
    AND    xca.customer_id = hca.cust_account_id
    AND    hca.customer_class_code = cv_class_code_base
    AND    hca.STATUS = cv_status;
    --
    -- ====================================================
    -- 顧客情報チェック
    -- ====================================================
    -- 管理元拠点コードが未設定の場合
    IF (lt_management_base_code IS NULL) THEN
      RETURN cn_sole_base;
    -- 顧客コード≠管理元拠点コードの場合
    ELSIF (lt_account_number <> lt_management_base_code) THEN
      RETURN cn_sole_base;
    -- 顧客コード＝管理元拠点コードの場合
    ELSIF (lt_account_number = lt_management_base_code) THEN
      RETURN cn_manage_section;
    ELSE
      RETURN NULL;
    END IF;
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                      -- *** 取得件数なしエラー ***
      RETURN NULL;
    --
  END get_manage_dept_f;
--
/************************************************************************
 * Function Name   : get_lookup_values
 * Description     : クイックコードマスタの各項目値をレコード型で取得する。
 ************************************************************************/
  FUNCTION get_lookup_values(
    iv_lookup_type    IN  VARCHAR2
   ,iv_lookup_code    IN  VARCHAR2
   ,id_enabled_date   IN  DATE      DEFAULT SYSDATE
  ) RETURN lookup_rec
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lookup_values'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lr_lookup_values        lookup_rec;     -- クイックコードマスタ情報格納レコード
    ld_sysdate              DATE;           -- システム日付
    ld_param_enabled_date   DATE;           -- 【入力パラメータ】有効日
    --
  BEGIN
    -- 初期化処理
    lr_lookup_values      :=  NULL;
    ld_sysdate            :=  TRUNC(SYSDATE);
    ld_param_enabled_date :=  TRUNC(id_enabled_date);
    --
    IF (ld_sysdate = ld_param_enabled_date) THEN
      -- 【入力パラメータ】有効日が、システム日付と一致する場合
      SELECT  flv.meaning     AS meaning          -- 内容
             ,flv.description AS description      -- 摘要
             ,flv.attribute1  AS attribute1       -- DFF1
             ,flv.attribute2  AS attribute2       -- DFF2
             ,flv.attribute3  AS attribute3       -- DFF3
             ,flv.attribute4  AS attribute4       -- DFF4
             ,flv.attribute5  AS attribute5       -- DFF5
             ,flv.attribute6  AS attribute6       -- DFF6
             ,flv.attribute7  AS attribute7       -- DFF7
             ,flv.attribute8  AS attribute8       -- DFF8
             ,flv.attribute9  AS attribute9       -- DFF9
             ,flv.attribute10 AS attribute10      -- DFF10
             ,flv.attribute11 AS attribute11      -- DFF11
             ,flv.attribute12 AS attribute12      -- DFF12
             ,flv.attribute13 AS attribute13      -- DFF13
             ,flv.attribute14 AS attribute14      -- DFF14
             ,flv.attribute15 AS attribute15      -- DFF15
      INTO    lr_lookup_values.meaning
             ,lr_lookup_values.description
             ,lr_lookup_values.attribute1
             ,lr_lookup_values.attribute2
             ,lr_lookup_values.attribute3
             ,lr_lookup_values.attribute4
             ,lr_lookup_values.attribute5
             ,lr_lookup_values.attribute6
             ,lr_lookup_values.attribute7
             ,lr_lookup_values.attribute8
             ,lr_lookup_values.attribute9
             ,lr_lookup_values.attribute10
             ,lr_lookup_values.attribute11
             ,lr_lookup_values.attribute12
             ,lr_lookup_values.attribute13
             ,lr_lookup_values.attribute14
             ,lr_lookup_values.attribute15
      FROM    fnd_lookup_values     flv           -- LOOKUP表
      WHERE   flv.lookup_type   =   iv_lookup_type
      AND     flv.lookup_code   =   iv_lookup_code
      AND     flv.language      =   USERENV('LANG')
      AND     flv.enabled_flag  =   'Y'
      AND     ld_sysdate BETWEEN NVL(flv.start_date_active, ld_sysdate)
                         AND     NVL(flv.end_date_active,   ld_sysdate);
      --
    ELSE
      -- 【入力パラメータ】有効日が、システム日付と一致しない場合
      SELECT  flv.meaning     AS meaning          -- 内容
             ,flv.description AS description      -- 摘要
             ,flv.attribute1  AS attribute1       -- DFF1
             ,flv.attribute2  AS attribute2       -- DFF2
             ,flv.attribute3  AS attribute3       -- DFF3
             ,flv.attribute4  AS attribute4       -- DFF4
             ,flv.attribute5  AS attribute5       -- DFF5
             ,flv.attribute6  AS attribute6       -- DFF6
             ,flv.attribute7  AS attribute7       -- DFF7
             ,flv.attribute8  AS attribute8       -- DFF8
             ,flv.attribute9  AS attribute9       -- DFF9
             ,flv.attribute10 AS attribute10      -- DFF10
             ,flv.attribute11 AS attribute11      -- DFF11
             ,flv.attribute12 AS attribute12      -- DFF12
             ,flv.attribute13 AS attribute13      -- DFF13
             ,flv.attribute14 AS attribute14      -- DFF14
             ,flv.attribute15 AS attribute15      -- DFF15
      INTO    lr_lookup_values.meaning
             ,lr_lookup_values.description
             ,lr_lookup_values.attribute1
             ,lr_lookup_values.attribute2
             ,lr_lookup_values.attribute3
             ,lr_lookup_values.attribute4
             ,lr_lookup_values.attribute5
             ,lr_lookup_values.attribute6
             ,lr_lookup_values.attribute7
             ,lr_lookup_values.attribute8
             ,lr_lookup_values.attribute9
             ,lr_lookup_values.attribute10
             ,lr_lookup_values.attribute11
             ,lr_lookup_values.attribute12
             ,lr_lookup_values.attribute13
             ,lr_lookup_values.attribute14
             ,lr_lookup_values.attribute15
      FROM    fnd_lookup_values     flv           -- LOOKUP表
      WHERE   flv.lookup_type   =   iv_lookup_type
      AND     flv.lookup_code   =   iv_lookup_code
      AND     flv.language      =   USERENV('LANG')
      AND     ld_param_enabled_date BETWEEN NVL(flv.start_date_active, ld_param_enabled_date)
                                    AND     NVL(flv.end_date_active,   ld_param_enabled_date);
      --
    END IF;
    --
    RETURN  lr_lookup_values;
--
  EXCEPTION
    WHEN OTHERS THEN
      -- 全項目NULLで返却
      RETURN  lr_lookup_values;
--
  END get_lookup_values;
--
/************************************************************************
 * Procedure Name  : CONVERT_WHOUSE_SUBINV_CODE
 * Description     : HHT倉庫保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_whouse_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code                    IN         VARCHAR2   -- 4.拠点コード
   ,iv_warehouse_code               IN         VARCHAR2   -- 5.倉庫コード
   ,in_organization_id              IN         NUMBER     -- 6.在庫組織ID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 7.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 8.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 9.棚卸対象
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_whouse_subinv_code';     -- プログラム名
    -- *** ローカル定数 ***
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';                        -- アプリケーション短縮名
    cv_msg_coi_10206       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10206';             -- MSG：保管場所取得エラー
-- == 2009/04/24 Ver1.4 Modified START ============================================
--    cv_msg_coi_10207       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10207';             -- MSG：保管場所失効エラー
--    cv_tkn_subinv_code     CONSTANT VARCHAR2(13) := 'SUB_INV_CODE';                 -- TKN：保管場所ｺｰﾄﾞ
--    cv_warehouse_div       CONSTANT VARCHAR2(1)  := 'A';                            -- 倉庫識別子
    cv_whse_code_whse      CONSTANT VARCHAR2(1)  := '1';                            -- 倉庫
    cv_whse_code_store     CONSTANT VARCHAR2(1)  := '4';                            -- 専門店
    cv_msg_coi_10380       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10380';             -- MSG：保管場所失効エラー
    cv_tkn_dept_code       CONSTANT VARCHAR2(10) := 'DEPT_CODE';                    -- TKN：拠点ｺｰﾄﾞ
    cv_tkn_whouse_code     CONSTANT VARCHAR2(11) := 'WHOUSE_CODE';                  -- TKN：倉庫ｺｰﾄﾞ
-- == 2009/04/24 Ver1.4 Modified END ============================================
    -- *** ローカル変数 ***
-- == 2009/04/24 Ver1.4 Deleted START =========================================
--    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;            -- 保管場所失効日
-- == 2009/04/24 Ver1.4 Deleted END =========================================
    -- *** ローカル例外 ***
    disable_date_expt       EXCEPTION;                                              -- 保管場所失効日エラー
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
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
-- == 2009/05/18 V1.6 Modified START ===============================================================
--    SELECT 
--             msi.secondary_inventory_name   AS secondary_inventory_name -- 1.保管場所コード
--            ,msi.attribute7                 AS base_code                -- 2.拠点コード
---- == 2009/04/24 Ver1.4 Deleted START =========================================
----            ,msi.disable_date               AS disable_date             -- 3.失効日
---- == 2009/04/24 Ver1.4 Deleted END =========================================
--            ,msi.attribute5                 AS subinv_div               -- 4.棚卸対象
--    INTO
--             ov_subinv_code                                             -- 1.保管場所コード
--            ,ov_base_code                                               -- 2.拠点コード
---- == 2009/04/24 Ver1.4 Deleted START =========================================
----            ,lt_disable_date                                            -- 3.失効日
---- == 2009/04/24 Ver1.4 Deleted END =========================================
--            ,ov_subinv_div                                              -- 4.棚卸対象
--    FROM    mtl_secondary_inventories msi 
---- == 2009/04/24 Ver1.4 Modified START =========================================
----    WHERE   msi.secondary_inventory_name    = cv_warehouse_div||iv_base_code||iv_warehouse_code
--    WHERE   msi.attribute7                             =  iv_base_code
--    AND     SUBSTRB(msi.secondary_inventory_name, -2)  =  iv_warehouse_code
--    AND     msi.attribute1                             IN ( cv_whse_code_whse, cv_whse_code_store )
--    AND     TRUNC( NVL(msi.disable_date, SYSDATE+1 ) ) >  TRUNC( SYSDATE )
---- == 2009/04/24 Ver1.4 Modified END =========================================
--    AND     msi.organization_id             = in_organization_id;
--
    SELECT 
             msi.secondary_inventory_name   AS secondary_inventory_name -- 1.保管場所コード
            ,msi.attribute7                 AS base_code                -- 2.拠点コード
            ,msi.attribute5                 AS subinv_div               -- 4.棚卸対象
    INTO
             ov_subinv_code                                             -- 1.保管場所コード
            ,ov_base_code                                               -- 2.拠点コード
            ,ov_subinv_div                                              -- 4.棚卸対象
    FROM    mtl_secondary_inventories msi
    WHERE   SUBSTRB(msi.secondary_inventory_name, 2, 4) =  iv_base_code
    AND     SUBSTRB(msi.secondary_inventory_name, -2)   =  iv_warehouse_code
    AND     msi.attribute1                              IN ( cv_whse_code_whse, cv_whse_code_store )
    AND     TRUNC( NVL(msi.disable_date, SYSDATE+1 ) )  >  TRUNC( SYSDATE )
    AND     msi.organization_id                         =  in_organization_id;
-- == 2009/05/18 V1.6 Modified END   ===============================================================
    --
-- == 2009/04/24 Ver1.4 Deleted START =========================================
--    IF lt_disable_date IS NOT NULL 
--        AND TRUNC(lt_disable_date) <= TRUNC(SYSDATE) 
--    THEN
--    --
--        RAISE disable_date_expt;
--    --
--    END IF;
-- == 2009/04/24 Ver1.4 Deleted END =========================================
  --
  EXCEPTION
  --
-- == 2009/04/24 Ver1.4 Deleted START =========================================
--    WHEN disable_date_expt THEN
--        ov_errmsg  := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_msg_kbn_coi
--                  ,iv_name         => cv_msg_coi_10207
--                  ,iv_token_name1  => cv_tkn_subinv_code
--                  ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
--                      );
--        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
--        ov_retcode := cv_status_warn;
--    --
-- == 2009/04/24 Ver1.4 Deleted END =========================================
    WHEN NO_DATA_FOUND THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10206
-- == 2009/04/24 Ver1.4 Modified START =========================================
--                        ,iv_token_name1  => cv_tkn_subinv_code
--                        ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_whouse_code
                        ,iv_token_value2 => iv_warehouse_code
-- == 2009/04/24 Ver1.4 Modified END =========================================
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
-- == 2009/04/24 Ver1.4 Added START ============================================
    WHEN TOO_MANY_ROWS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10380
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_whouse_code
                        ,iv_token_value2 => iv_warehouse_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
-- == 2009/04/24 Ver1.4 Added END ============================================
    WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10206
-- == 2009/04/24 Ver1.4 Modified START =========================================
--                        ,iv_token_name1  => cv_tkn_subinv_code
--                        ,iv_token_value1 => cv_warehouse_div||iv_base_code||iv_warehouse_code
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_whouse_code
                        ,iv_token_value2 => iv_warehouse_code
-- == 2009/04/24 Ver1.4 Modified END =========================================
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_whouse_subinv_code;
/************************************************************************
 * Procedure Name  : CONVERT_EMP_SUBINV_CODE
 * Description     : HHT営業車保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_emp_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code                    IN         VARCHAR2   -- 4.拠点コード
   ,iv_employee_number              IN         VARCHAR2   -- 5.従業員コード
   ,id_transaction_date             IN         DATE       -- 6.伝票日付
   ,in_organization_id              IN         NUMBER     -- 7.在庫組織ID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 8.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 9.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   --10.棚卸対象
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_emp_subinv_code';     -- プログラム名
    -- *** ローカル定数 ***
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)  := 'XXCOI';               -- アプリケーション短縮名
    cv_dummy_code          CONSTANT VARCHAR2(2) := '99';                    -- ダミーコード
    cv_cust_class_base     CONSTANT VARCHAR2(1) := '1';                     -- 顧客区分：拠点
    cv_dept_hht_single_div CONSTANT VARCHAR2(1) := '2';                     -- 百貨店HHT区分：拠点単
    cv_dept_hht_double_div CONSTANT VARCHAR2(1) := '1';                     -- 百貨店HHT区分：拠点複
    cv_employee            CONSTANT VARCHAR2(8) := 'EMPLOYEE';              -- カテゴリ：従業員
    cv_sub_inv_type_car           CONSTANT VARCHAR2(1) := '5';                     -- 保管場所分類：営業車
    --
    cv_msg_coi_10204       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10204';     -- MSG：百貨店HHT区分取得エラー
    cv_msg_coi_10208       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10208';     -- MSG：所属拠点取得エラー
    cv_msg_coi_10209       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10209';     -- MSG：所属拠点未設定エラー
    cv_msg_coi_10217       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10217';     -- MSG：管理元拠点不一致エラー
    cv_msg_coi_10212       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10212';     -- MSG：営業車保管場所取得エラー
    cv_msg_coi_10213       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10213';     -- MSG：営業車保管場所失効エラー
    cv_msg_coi_10253       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10253';     -- MSG：営業車保管場所重複エラー
    cv_tkn_employee_code   CONSTANT VARCHAR2(13) := 'EMPLOYEE_CODE';        -- TKN：営業員ｺｰﾄﾞ
    cv_tkn_dept_code       CONSTANT VARCHAR2(13) := 'DEPT_CODE';            -- TKN：拠点ｺｰﾄﾞ
    --
    -- *** ローカル変数 ***
    lt_dept_hht_div         xxcmm_cust_accounts.dept_hht_div%TYPE;          -- 百貨店用HHT区分
    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;    -- 保管場所失効日
    lt_salesrep_number      jtf_rs_salesreps.salesrep_number%TYPE;          -- 営業員コード
    lt_belong_base_code     hz_cust_accounts.account_number%TYPE;           -- 所属拠点コード
    ln_base_count           NUMBER := 0;                                    -- 管理元拠点一致件数
    -- *** ローカル例外 ***
    sub_error_expt          EXCEPTION;                                         -- サブ定義例外エラー
    sub_others_error_expt   EXCEPTION;                                         -- サブ定義Oters例外エラー
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
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
    -- ====================================================
    -- 1.百貨店用HHT区分 取得
    -- ====================================================
    --
    BEGIN
    --
        SELECT 
                NVL(xca.dept_hht_div,cv_dept_hht_single_div) AS dept_hht_div    -- 1.百貨店用HHT区分
        INTO   
                lt_dept_hht_div                                                 -- 1.百貨店用HHT区分
        FROM   
                hz_cust_accounts hca
               ,xxcmm_cust_accounts xca
        WHERE  
                hca.cust_account_id     = xca.customer_id
        AND     hca.account_number      = iv_base_code
        AND     hca.customer_class_code = cv_cust_class_base;
    --
    EXCEPTION
    --
        WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_others_error_expt;
    --
    END;
    -- ================================================
    -- 2.百貨店HHT区分：拠点複
    -- ================================================
    IF lt_dept_hht_div = cv_dept_hht_double_div THEN
        -- ========================================
        -- 2-1.営業員コード、従業員の所属拠点を取得
        -- ========================================
        BEGIN
        --
            SELECT  
                    jrs.salesrep_number                 AS salesrep_number  -- 1.営業員コード
                    ,CASE WHEN TRUNC(id_transaction_date) < TRUNC(to_date(paf.ass_attribute2,'yyyymmdd')) 
                            THEN NVL(paf.ass_attribute6,cv_dummy_code)
                          WHEN TRUNC(id_transaction_date) >= TRUNC(to_date(paf.ass_attribute2,'yyyymmdd')) 
                            THEN NVL(paf.ass_attribute5,cv_dummy_code)
                          ELSE cv_dummy_code END        AS dept_code        -- 2.所属拠点コード
            INTO
                    lt_salesrep_number                                      -- 1.営業員コード
                    ,lt_belong_base_code                                    -- 2.所属拠点コード
            FROM    per_all_people_f ppf
                    ,per_all_assignments_f paf
                    ,jtf_rs_salesreps jrs
                    ,jtf_rs_resource_extns jrre
            WHERE   ppf.person_id       = paf.person_id
            AND     TRUNC(cd_business_date) 
                      BETWEEN TRUNC(ppf.effective_start_date )
                          AND TRUNC( NVL( ppf.effective_end_date , cd_business_date) )
            AND     TRUNC(cd_business_date) 
                      BETWEEN TRUNC(paf.effective_start_date )
                          AND TRUNC( NVL( paf.effective_end_date , cd_business_date ) )
            AND     ppf.person_id       = jrre.source_id
            AND     jrre.category       = cv_employee
            AND     jrre.resource_id    = jrs.resource_id
            AND     ppf.employee_number = iv_employee_number;
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10208
                                ,iv_token_name1  => cv_tkn_employee_code
                                ,iv_token_value1 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10208
                                ,iv_token_name1  => cv_tkn_employee_code
                                ,iv_token_value1 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_others_error_expt;
        --
        END;
        -- ========================================
        -- 2-2.新/旧拠点コードの未設定、発令日の未設定例外
        -- ========================================
        IF lt_belong_base_code = cv_dummy_code THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10209
                      ,iv_token_name1  => cv_tkn_employee_code
                      ,iv_token_value1 => iv_employee_number
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
        -- ========================================
        -- 2-3.管理元拠点の一致チェック
        -- ========================================
        --
        SELECT
              COUNT(1) AS COUNT             -- 1.管理元拠点の一致件数
        INTO
              ln_base_count                 -- 1.管理元拠点の一致件数
        FROM
              hz_cust_accounts hca
             ,xxcmm_cust_accounts xca
        WHERE
              hca.cust_account_id       = xca.customer_id
        AND   hca.customer_class_code   = cv_cust_class_base
        AND   hca.account_number        = lt_belong_base_code
        AND   xca.management_base_code  = iv_base_code
        AND   ROWNUM                    = 1;
        --
        IF ln_base_count = 0 THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10217
                            ,iv_token_name1  => cv_tkn_dept_code
                            ,iv_token_value1 => iv_base_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
        -- ========================================
        -- 2-4.営業車 保管場所の取得
        -- ========================================
        BEGIN
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.保管場所コード
                    ,msi.attribute7                 AS base_code                    -- 2.拠点コード
                    ,msi.disable_date               AS disable_date                 -- 3.失効日
                    ,msi.attribute5                 AS subinv_div                   -- 4.棚卸対象
            INTO
                     ov_subinv_code                                                 -- 1.保管場所コード
                    ,ov_base_code                                                   -- 2.拠点コード
                    ,lt_disable_date                                                -- 3.失効日
                    ,ov_subinv_div                                                  -- 4.棚卸対象
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.attribute7                              = lt_belong_base_code
            AND     msi.attribute3                              = lt_salesrep_number
            AND     msi.organization_id                         = in_organization_id
            AND     TRUNC( NVL(msi.disable_date,SYSDATE+1 ) )   > TRUNC( SYSDATE );
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_belong_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN TOO_MANY_ROWS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10253
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_belong_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_belong_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_others_error_expt;
        --
        END;
    --
    END IF;
    -- ================================================
    -- 3.百貨店HHT区分：拠点単
    -- ================================================
    IF lt_dept_hht_div = cv_dept_hht_single_div THEN
        -- ========================================
        -- 3-1.営業車 保管場所の取得
        -- ========================================
        BEGIN
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.保管場所コード
                    ,msi.attribute7                 AS base_code                    -- 2.拠点コード
                    ,msi.disable_date               AS disable_date                 -- 3.失効日
                    ,msi.attribute5                 AS subinv_div                   -- 4.棚卸対象
            INTO
                     ov_subinv_code                                                 -- 1.保管場所コード
                    ,ov_base_code                                                   -- 2.拠点コード
                    ,lt_disable_date                                                -- 3.失効日
                    ,ov_subinv_div                                                  -- 4.棚卸対象
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.attribute7                              = iv_base_code
            AND     msi.attribute3                              = iv_employee_number
            AND     msi.organization_id                         = in_organization_id
            AND     TRUNC(NVL( msi.disable_date,SYSDATE+1 ) )   > TRUNC(SYSDATE);
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN TOO_MANY_ROWS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10253
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10212
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                                ,iv_token_name2  => cv_tkn_employee_code
                                ,iv_token_value2 => iv_employee_number
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_others_error_expt;
        --
        END;
    --
    END IF;
  --
  EXCEPTION
  --
    WHEN sub_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN sub_others_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    --
    WHEN OTHERS THEN
        ov_errmsg  := SQLERRM;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_emp_subinv_code;
/************************************************************************
 * Procedure Name  : CONVERT_CUST_SUBINV_CODE
 * Description     : HHT預け先保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_cust_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code                    IN         VARCHAR2   -- 4.拠点コード
   ,iv_cust_code                    IN         VARCHAR2   -- 5.顧客コード
   ,id_transaction_date             IN         DATE       -- 6.伝票日付
   ,in_organization_id              IN         NUMBER     -- 7.在庫組織ID
   ,iv_record_type                  IN         VARCHAR2   -- 8.レコード種別
   ,iv_hht_form_flag                IN         VARCHAR2   -- 9.HHT取引入力画面フラグ
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   --10.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   --11.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   --12.保管場所区区分
   ,ov_business_low_type            OUT NOCOPY VARCHAR2   --13.業態小分類
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_cust_subinv_code';     -- プログラム名
    -- *** ローカル定数 ***
    cv_flag_y               CONSTANT VARCHAR2(1) := 'Y';     -- フラグY
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5) := 'XXCOI';                 -- アプリケーション短縮名
    cv_dummy_code          CONSTANT VARCHAR2(2) := '99';                    -- ダミーコード
    cv_dept_hht_single_div CONSTANT VARCHAR2(1) := '2';                     -- 百貨店HHT区分：拠点単(2)
    cv_dept_hht_double_div CONSTANT VARCHAR2(1) := '1';                     -- 百貨店HHT区分：拠点複(1)
    cv_vd_div              CONSTANT VARCHAR2(1) := 'V';                     -- 保管場所コード体系：接頭語：自販機
    cv_vd_s_div            CONSTANT VARCHAR2(1) := 'S';                     -- 保管場所コード体系：接尾語：消化VD
    cv_vd_f_div            CONSTANT VARCHAR2(1) := 'F';                     -- 保管場所コード体系：接尾語：フルVD
    cv_biz_low_type_24     CONSTANT VARCHAR2(2) := '24';                    -- 業態小分類：フル(消化)VD
    cv_biz_low_type_25     CONSTANT VARCHAR2(2) := '25';                    -- 業態小分類：フルVD
    cv_biz_low_type_27     CONSTANT VARCHAR2(2) := '27';                    -- 業態小分類：消化VD
    cv_cust_status_mc      CONSTANT VARCHAR2(2) := '20';                    -- 顧客ステータス：MC
    cv_cust_status_sp      CONSTANT VARCHAR2(2) := '25';                    -- 顧客ステータス：SP決済
    cv_cust_status_appl    CONSTANT VARCHAR2(2) := '30';                    -- 顧客ステータス：承認済
    cv_cust_status_cust    CONSTANT VARCHAR2(2) := '40';                    -- 顧客ステータス：顧客
    cv_cust_status_rest    CONSTANT VARCHAR2(2) := '50';                    -- 顧客ステータス：休止
    cv_cust_status_credit  CONSTANT VARCHAR2(2) := '80';                    -- 顧客ステータス：更正債権
    cv_record_type_sample  CONSTANT VARCHAR2(2) := '40';                    -- レコード種別：見本
    cv_record_type_inv     CONSTANT VARCHAR2(2) := '90';                    -- レコード種別：棚卸
    cv_cust_class_base     CONSTANT VARCHAR2(1) := '1';                     -- 顧客区分：拠点
    cv_cust_class_cust     CONSTANT VARCHAR2(2) := '10';                    -- 顧客区分：顧客
    cv_cust_class_uesama   CONSTANT VARCHAR2(2) := '12';                    -- 顧客区分：上様
    --
    cv_msg_coi_10204       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10204';     -- 百貨店HHT区分取得エラー
    cv_msg_coi_10214       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10214';     -- 管轄拠点取得エラー
    cv_msg_coi_10215       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10215';     -- 管轄拠点未設定エラー
    cv_msg_coi_10216       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10216';     -- 顧客ステータスエラー
    cv_msg_coi_10210       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10210';     -- 管理元拠点不一致エラー
    cv_msg_coi_10219       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10219';     -- 預け先保管場所取得エラー
    cv_msg_coi_10252       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10252';     -- 預け先保管場所重複エラー
    cv_msg_coi_10220       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10220';     -- 預け先保管場所失効エラー
    cv_msg_coi_10206       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10206';     -- 保管場所の取得エラー
    cv_msg_coi_10207       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10207';     -- 保管場所の失効エラー
    cv_msg_coi_10218       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10218';     -- 管轄拠点不一致エラー
    --
    cv_msg_coi_10344       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10344';     -- フルVD拠点保管場所取得エラー
    cv_msg_coi_10345       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10345';     -- フルVD拠点保管場所失効エラー
    cv_msg_coi_10346       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10346';     -- 消化VD拠点保管場所取得エラー
    cv_msg_coi_10347       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10347';     -- 消化VD拠点保管場所失効エラー
    --
    cv_tkn_dept_code       CONSTANT VARCHAR2(13) := 'DEPT_CODE';
    cv_tkn_cust_code       CONSTANT VARCHAR2(13) := 'CUST_CODE';
    cv_tkn_sub_inv_code    CONSTANT VARCHAR2(13) := 'SUB_INV_CODE';
    -- *** ローカル変数 ***
    lt_dept_hht_div         xxcmm_cust_accounts.dept_hht_div%TYPE;                      -- 百貨店用HHT区分
    lt_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;                    -- 管轄拠点
    lt_cust_status          hz_parties.duns_number_c%TYPE;                              -- 顧客ステータス
    lt_customer_class_code  hz_cust_accounts.customer_class_code%TYPE;                  -- 顧客区分
    lt_sub_inv_name         mtl_secondary_inventories.secondary_inventory_name%TYPE;    -- 保管場所コード
    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;                -- 保管場所失効日
    ln_base_count           NUMBER := 0;                                                -- 管理元拠点一致件数
    --
    -- *** ローカル例外 ***
    sub_error_expt          EXCEPTION;                                         -- サブ定義例外エラー
    sub_others_error_expt   EXCEPTION;                                         -- サブ定義Oters例外エラー
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
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
    -- ====================================================
    -- 1.百貨店用HHT区分 取得
    -- ====================================================
    --
    BEGIN
    --
        SELECT NVL(xca.dept_hht_div,cv_dept_hht_single_div)     -- 1.百貨店用HHT区分
        INTO   lt_dept_hht_div                                  -- 1.百貨店用HHT区分
        FROM   hz_cust_accounts hca
               ,xxcmm_cust_accounts xca
        WHERE  hca.cust_account_id      = xca.customer_id
        AND    hca.account_number       = iv_base_code
        AND    hca.customer_class_code  = cv_cust_class_base;
    --
    EXCEPTION
     --
        WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10204
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_others_error_expt;
    --
    END;
    -- ================================================
    -- 2.顧客の管轄拠点を取得
    -- ================================================
    BEGIN
    --
        SELECT
                CASE TO_CHAR(id_transaction_date,'YYYYMM') 
                    WHEN TO_CHAR(cd_business_date,'YYYYMM' )
                      THEN NVL(xca.sale_base_code,cv_dummy_code)
                    ELSE NVL(xca.past_sale_base_code,cv_dummy_code)
                    END                    AS base_code                 -- 1.管轄拠点コード
                 ,hp.duns_number_c         AS cust_status               -- 2.顧客ステータス
                 ,xca.business_low_type    AS business_low_type         -- 3.業態小分類
                 ,hca.customer_class_code  AS customer_class_code       -- 4.顧客区分
        INTO
                 lt_base_code                                           -- 1.管轄拠点コード
                ,lt_cust_status                                         -- 2.顧客ステータス
                ,ov_business_low_type                                   -- 3.業態小分類
                ,lt_customer_class_code                                 -- 4.顧客区分
        FROM
                 hz_parties hp
                ,hz_cust_accounts hca
                ,xxcmm_cust_accounts xca
        WHERE
                hp.party_id         = hca.party_id
        AND     hca.cust_account_id = xca.customer_id
        AND     hca.account_number  = iv_cust_code
        AND     hca.customer_class_code IN( cv_cust_class_cust , cv_cust_class_uesama );
    --
    EXCEPTION
    --
        WHEN NO_DATA_FOUND THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10214
                            ,iv_token_name1  => cv_tkn_cust_code
                            ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10214
                            ,iv_token_name1  => cv_tkn_cust_code
                            ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_others_error_expt;
    --
    END;
    -- ========================================
    -- 3.拠点コードの未設定例外
    -- ========================================
    IF lt_base_code = cv_dummy_code THEN
    --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_coi
                  ,iv_name         => cv_msg_coi_10215
                  ,iv_token_name1  => cv_tkn_cust_code
                  ,iv_token_value1 => iv_cust_code
                      );
        lv_errbuf := SQLERRM;
        RAISE sub_error_expt;
    --
    END IF;
    -- ========================================
    -- 4.顧客ステータスチェック
    -- ========================================
    -- 12:上様顧客
    IF lt_customer_class_code = cv_cust_class_uesama THEN
    --
        IF lt_cust_status NOT IN( cv_cust_status_appl   -- 30:承認
                                 ,cv_cust_status_cust ) -- 40:顧客
        THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10216
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    --
    ELSE
    --
-- == 2009/03/30 Ver1.2 Modified START =========================================
--        IF iv_record_type = cv_record_type_inv THEN         -- 90:棚卸
--        --
--            IF lt_cust_status NOT IN( cv_cust_status_appl      -- 30:承認
--                                     ,cv_cust_status_cust      -- 40:顧客
--                                     ,cv_cust_status_rest      -- 50:休止
--                                     ,cv_cust_status_credit )  -- 80:更正債権
--            THEN
--            --
--                lv_errmsg  := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_msg_kbn_coi
--                          ,iv_name         => cv_msg_coi_10216
--                          ,iv_token_name1  => cv_tkn_cust_code
--                          ,iv_token_value1 => iv_cust_code
--                              );
--                lv_errbuf := SQLERRM;
--                RAISE sub_error_expt;
--            --
--            END IF;
--        --
--        ELSE
--        --
--            IF ( ( iv_hht_form_flag IS NOT NULL ) AND ( iv_hht_form_flag = cv_flag_y ) ) THEN
--                -- HHT取引入力画面の場合
--                IF lt_cust_status NOT IN( cv_cust_status_appl      -- 30:承認
--                                         ,cv_cust_status_cust      -- 40:顧客
--                                         ,cv_cust_status_rest      -- 50:休止
--                                         ,cv_cust_status_credit )  -- 80:更正債権
--                THEN
--                --
--                    lv_errmsg  := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_coi
--                              ,iv_name         => cv_msg_coi_10216
--                              ,iv_token_name1  => cv_tkn_cust_code
--                              ,iv_token_value1 => iv_cust_code
--                                  );
--                    lv_errbuf := SQLERRM;
--                    RAISE sub_error_expt;
--                --
--                END IF;
--            --
--            ELSE
--                -- HHT_IFの場合
                -- 上様以外の場合
                IF lt_cust_status NOT IN( cv_cust_status_appl   -- 30:承認
                                         ,cv_cust_status_cust   -- 40:顧客
                                         ,cv_cust_status_rest)  -- 50:休止
                                         
                THEN
                --
                    lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_coi
                              ,iv_name         => cv_msg_coi_10216
                              ,iv_token_name1  => cv_tkn_cust_code
                              ,iv_token_value1 => iv_cust_code
                                  );
                    lv_errbuf := SQLERRM;
                    RAISE sub_error_expt;
                --
                END IF;
--            END IF;
--        --
--        END IF;
--    --
-- == 2009/03/30 Ver1.2 Modified END =========================================
    END IF;
    -- ========================================
    -- 5.拠点複の場合は、管理元拠点の一致チェック
    -- ========================================
    IF lt_dept_hht_div = cv_dept_hht_double_div THEN
    --
        SELECT
              COUNT(1) AS COUNT            -- 1.管理元拠点の一致件数
        INTO
              ln_base_count                -- 1.管理元拠点の一致件数
        FROM
              hz_cust_accounts hca
             ,xxcmm_cust_accounts xca
        WHERE
              hca.cust_account_id       = xca.customer_id
        AND   hca.customer_class_code   = cv_cust_class_base
        AND   hca.account_number        = lt_base_code
        AND   xca.management_base_code  = iv_base_code
        AND   ROWNUM = 1;
        --
        IF ln_base_count = 0 THEN
            --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10210
                            ,iv_token_name1  => cv_tkn_dept_code
                            ,iv_token_value1 => iv_base_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    -- ========================================
    -- 6.拠点単の場合は、管轄拠点の一致チェック
    -- ========================================
    ELSE
    --
        IF iv_base_code <> lt_base_code THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10218
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => iv_base_code
                              );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    --
    END IF;
    -- ========================================
    -- 2-5.預け先 保管場所の取得
    -- ========================================
    -- -------------------------
    -- 2-5-1.消化VD(27)
    -- -------------------------
    IF ov_business_low_type = cv_biz_low_type_27 THEN
    --
        BEGIN
        -- 
            lt_sub_inv_name := cv_vd_div||lt_base_code||cv_vd_s_div;
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.保管場所コード
                    ,msi.attribute7                 AS base_code                    -- 2.拠点コード
                    ,msi.disable_date               AS disable_date                 -- 3.失効日
                    ,msi.attribute5                 AS subinv_div                   -- 4.棚卸対象
            INTO
                     ov_subinv_code                                                 -- 1.保管場所コード
                    ,ov_base_code                                                   -- 2.拠点コード
                    ,lt_disable_date                                                -- 3.失効日
                    ,ov_subinv_div                                                  -- 4.棚卸対象
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.secondary_inventory_name    = lt_sub_inv_name
            AND     msi.organization_id             = in_organization_id;
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10346
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_s_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10346
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_s_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
        END;
        --
        IF lt_disable_date IS NOT NULL AND TRUNC(lt_disable_date) <= TRUNC(SYSDATE) THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10347
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_s_div
                            );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    -- -------------------------
    -- 2-5-2.フルVD(24,25)
    -- -------------------------
    ELSIF ov_business_low_type IN(cv_biz_low_type_24,cv_biz_low_type_25) THEN
    --
        BEGIN
        --
            lt_sub_inv_name := cv_vd_div||lt_base_code||cv_vd_f_div;
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.保管場所コード
                    ,msi.attribute7                 AS base_code                    -- 2.拠点コード
                    ,msi.disable_date               AS disable_date                 -- 3.失効日
                    ,msi.attribute5                 AS subinv_div                   -- 4.棚卸対象
            INTO
                     ov_subinv_code                                                 -- 1.保管場所コード
                    ,ov_base_code                                                   -- 2.拠点コード
                    ,lt_disable_date                                                -- 3.失効日
                    ,ov_subinv_div                                                  -- 4.棚卸対象
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.secondary_inventory_name    = lt_sub_inv_name
            AND     msi.organization_id             = in_organization_id;
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10344
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_f_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10344
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_f_div
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
        END;
        --
        IF lt_disable_date IS NOT NULL AND TRUNC(lt_disable_date) <= TRUNC(SYSDATE) THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10345
                                ,iv_token_name1  => cv_tkn_sub_inv_code
                                ,iv_token_value1 => cv_vd_div||lt_base_code||cv_vd_f_div
                            );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    -- -------------------------
    -- 2-5-1.以外
    -- -------------------------
    ELSE
    --
        BEGIN
        --
            SELECT
                     msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.保管場所コード
                    ,msi.attribute7                 AS base_code                    -- 2.拠点コード
                    ,msi.disable_date               AS disable_date                 -- 3.失効日
                    ,msi.attribute5                 AS subinv_div                   -- 4.棚卸対象
            INTO
                     ov_subinv_code                                                 -- 1.保管場所コード
                    ,ov_base_code                                                   -- 2.拠点コード
                    ,lt_disable_date                                                -- 3.失効日
                    ,ov_subinv_div                                                  -- 4.棚卸対象
            FROM
                    mtl_secondary_inventories msi
            WHERE
                    msi.attribute7                              = lt_base_code
            AND     msi.attribute4                              = iv_cust_code
            AND     msi.organization_id                         = in_organization_id
            AND     TRUNC( NVL(msi.disable_date,SYSDATE+1) )    > TRUNC(SYSDATE);
        --
        EXCEPTION
        --
            WHEN NO_DATA_FOUND THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10219
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_base_code
                                ,iv_token_name2  => cv_tkn_cust_code
                                ,iv_token_value2 => iv_cust_code
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN TOO_MANY_ROWS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10252
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_base_code
                                ,iv_token_name2  => cv_tkn_cust_code
                                ,iv_token_value2 => iv_cust_code
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
            --
            WHEN OTHERS THEN
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_coi
                                ,iv_name         => cv_msg_coi_10219
                                ,iv_token_name1  => cv_tkn_dept_code
                                ,iv_token_value1 => lt_base_code
                                ,iv_token_name2  => cv_tkn_cust_code
                                ,iv_token_value2 => iv_cust_code
                              );
                lv_errbuf := SQLERRM;
                RAISE sub_error_expt;
        --
        END;
        --
    END IF;
  --
  EXCEPTION
  --
    WHEN sub_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN sub_others_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    --
    WHEN OTHERS THEN
        ov_errmsg  := SQLERRM;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_cust_subinv_code;
/************************************************************************
 * Procedure Name  : CONVERT_BASE_SUBINV_CODE
 * Description     : HHTメイン倉庫保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_base_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_dept_code                    IN         VARCHAR2   -- 4.拠点コード
   ,in_organization_id              IN         NUMBER     -- 5.在庫組織ID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 6.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 7.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 8.保管場所変換区分
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'convert_base_subinv_code';     -- プログラム名
    -- *** ローカル定数 ***
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';                        -- アプリケーション短縮名
    cv_msg_coi_10221       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10221';             -- 保管場所取得エラー
    cv_msg_coi_10251       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10251';             -- 保管場所重複エラー
    --
    cv_tkn_dept_code       CONSTANT VARCHAR2(13) := 'DEPT_CODE';
    --
    cv_main_warehouse_flag CONSTANT VARCHAR2(1) := 'Y';                             -- メイン倉庫フラグ
    -- *** ローカル変数 ***
    lt_disable_date         mtl_secondary_inventories.disable_date%TYPE;            -- 保管場所失効日
    -- *** ローカル例外 ***
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
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    SELECT 
             msi.secondary_inventory_name   AS secondary_inventory_name     -- 1.保管場所コード
            ,msi.attribute7                 AS base_code                    -- 2.拠点コード
            ,msi.disable_date               AS disable_date                 -- 3.失効日
            ,msi.attribute5                 AS subinv_div                   -- 4.棚卸対象
    INTO
             ov_subinv_code                                                 -- 1.保管場所コード
            ,ov_base_code                                                   -- 2.拠点コード
            ,lt_disable_date                                                -- 3.失効日
            ,ov_subinv_div                                                  -- 4.棚卸対象    
    FROM    mtl_secondary_inventories msi 
    WHERE   msi.attribute7                              = iv_dept_code
    AND     msi.attribute6                              = cv_main_warehouse_flag
    AND     msi.organization_id                         = in_organization_id
    AND     TRUNC( NVL(msi.disable_date , SYSDATE+1 ) ) > TRUNC(SYSDATE);
    --
  EXCEPTION
    --
    WHEN NO_DATA_FOUND THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10221
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_dept_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN TOO_MANY_ROWS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10251
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_dept_code
                      );
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                        ,iv_name         => cv_msg_coi_10221
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_dept_code
                      );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END convert_base_subinv_code;
/************************************************************************
 * Procedure Name  : CHECK_CUST_STATUS
 * Description     : HHT顧客ステータスチェック
 ************************************************************************/
  PROCEDURE check_cust_status(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_cust_code                    IN         VARCHAR2   -- 4.顧客コード
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'check_cust_status';   -- プログラム名
    -- *** ローカル定数 ***
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';                -- アプリケーション短縮名
    cv_msg_coi_10214       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10223';     -- MSG：顧客ｽﾃｰﾀｽ取得エラー
    cv_msg_coi_10303       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10303';     -- MSG：顧客ステータスエラー
    cv_tkn_cust_code       CONSTANT VARCHAR2(13) := 'CUST_CODE';            -- TKN：顧客コード
    cv_cust_status_mc      CONSTANT VARCHAR2(2)  := '20';                   -- 顧客ステータス：MC
    cv_cust_status_sp      CONSTANT VARCHAR2(2)  := '25';                   -- 顧客ステータス：SP決済
    cv_cust_status_appl    CONSTANT VARCHAR2(2)  := '30';                   -- 顧客ステータス：承認済
    cv_cust_status_cust    CONSTANT VARCHAR2(2)  := '40';                   -- 顧客ステータス：顧客
    cv_cust_status_rest    CONSTANT VARCHAR2(2)  := '50';                   -- 顧客ステータス：休止
    cv_cust_class_uesama   CONSTANT VARCHAR2(2)  := '12';                   -- 顧客区分：上様
    -- *** ローカル変数 ***
    lt_cust_status         hz_parties.duns_number_c%TYPE;                   -- 顧客ステータス
    lt_customer_class_code hz_cust_accounts.customer_class_code%TYPE;       -- 顧客区分
    -- *** ローカル例外 ***
    sub_error_expt         EXCEPTION;                                       -- サブ定義例外エラー
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
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ================================================
    -- 1.顧客ステータスを取得
    -- ================================================
    BEGIN
    --
        SELECT
                 hp.duns_number_c         AS duns_number_c             -- 1.顧客ステータス
                ,hca.customer_class_code  AS customer_class_code       -- 2.顧客区分
        INTO
                 lt_cust_status                                        -- 1.顧客ステータス
                ,lt_customer_class_code                                -- 2.顧客区分
        FROM
                 hz_parties hp
                ,hz_cust_accounts hca
        WHERE
                hp.party_id         = hca.party_id
        AND     hca.account_number  = iv_cust_code;
    --
    EXCEPTION
    --
        WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10214
                            ,iv_token_name1  => cv_tkn_cust_code
                            ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
    --
    END;
    -- ========================================
    -- 2.顧客ステータスチェック
    -- ========================================
    -- 12:上様顧客
    IF lt_customer_class_code = cv_cust_class_uesama THEN
    --
        IF lt_cust_status NOT IN( cv_cust_status_appl   -- 30:承認
                                 ,cv_cust_status_cust ) -- 40:顧客
        THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10303
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
    --
    ELSE
    --
        IF lt_cust_status NOT IN( cv_cust_status_mc     -- 20:MC
                                 ,cv_cust_status_sp     -- 25:SP
                                 ,cv_cust_status_appl   -- 30:承認
                                 ,cv_cust_status_cust   -- 40:顧客
                                 ,cv_cust_status_rest ) -- 50:休止
        THEN
        --
            lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10303
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_cust_code
                          );
            lv_errbuf := SQLERRM;
            RAISE sub_error_expt;
        --
        END IF;
  --
  END IF;
  --
  EXCEPTION
  --
    WHEN sub_error_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    WHEN OTHERS THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
        ov_retcode := cv_status_error;
  --
  END check_cust_status;
/************************************************************************
 * Procedure Name  : CONVERT_SUBINV_CODE
 * Description     : HHT保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_record_type                  IN         VARCHAR2   -- 4.レコード種別
   ,iv_invoice_type                 IN         VARCHAR2   -- 5.伝票区分
   ,iv_department_flag              IN         VARCHAR2   -- 6.百貨店フラグ
   ,iv_base_code                    IN         VARCHAR2   -- 7.拠点コード
   ,iv_outside_code                 IN         VARCHAR2   -- 8.出庫側コード
   ,iv_inside_code                  IN         VARCHAR2   -- 9.入庫側コード
   ,id_transaction_date             IN         DATE       -- 10.取引日
   ,in_organization_id              IN         NUMBER     -- 11.在庫組織ID
   ,iv_hht_form_flag                IN         VARCHAR2   -- 12.HHT取引入力画面フラグ
   ,ov_outside_subinv_code          OUT NOCOPY VARCHAR2   -- 13.出庫側保管場所コード
   ,ov_inside_subinv_code           OUT NOCOPY VARCHAR2   -- 14.入庫側保管場所コード
   ,ov_outside_base_code            OUT NOCOPY VARCHAR2   -- 15.出庫側拠点コード
   ,ov_inside_base_code             OUT NOCOPY VARCHAR2   -- 16.入庫側拠点コード
   ,ov_outside_subinv_code_conv     OUT NOCOPY VARCHAR2   -- 17.出庫側保管場所変換区分
   ,ov_inside_subinv_code_conv      OUT NOCOPY VARCHAR2   -- 18.入庫側保管場所変換区分
   ,ov_outside_business_low_type    OUT NOCOPY VARCHAR2   -- 19.出庫側業態小分類
   ,ov_inside_business_low_type     OUT NOCOPY VARCHAR2   -- 20.入庫側業態小分類
   ,ov_outside_cust_code            OUT NOCOPY VARCHAR2   -- 21.出庫側顧客コード
   ,ov_inside_cust_code             OUT NOCOPY VARCHAR2   -- 22.入庫側顧客コード
   ,ov_hht_program_div              OUT NOCOPY VARCHAR2   -- 23.入出庫ジャーナル処理区分
   ,ov_item_convert_div             OUT NOCOPY VARCHAR2   -- 24.商品振替区分
   ,ov_stock_uncheck_list_div       OUT NOCOPY VARCHAR2   -- 25.入庫未確認リスト対象区分
   ,ov_stock_balance_list_div       OUT NOCOPY VARCHAR2   -- 26.入庫差異確認リスト対象区分
   ,ov_consume_vd_flag              OUT NOCOPY VARCHAR2   -- 27.消化VD補充対象フラグ
   ,ov_outside_subinv_div           OUT NOCOPY VARCHAR2   -- 28.出庫側棚卸対象
   ,ov_inside_subinv_div            OUT NOCOPY VARCHAR2   -- 29.入庫側棚卸対象
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'convert_subinv_code';   -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_kbn_coi         CONSTANT VARCHAR2(5)  := 'XXCOI';              -- アプリケーション短縮名
    cv_msg_coi_10225       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10225';   -- 組み合わせエラーメッセージ
    --
    cv_tkn_record_type     CONSTANT VARCHAR2(13) := 'RECORD_TYPE';
    cv_tkn_invoice_type    CONSTANT VARCHAR2(13) := 'INVOICE_TYPE';
    cv_tkn_department_flag CONSTANT VARCHAR2(13) := 'DEPT_FLAG';
    --
    cv_dummy_code          CONSTANT VARCHAR2(2)  := '99';
    cv_cust_class_base     CONSTANT VARCHAR2(1)  := '1';                     -- 顧客区分：拠点
    cv_warehouse_div       CONSTANT VARCHAR2(1)  := 'A';                     -- 倉庫
    cv_sales_div           CONSTANT VARCHAR2(1)  := 'B';                     -- 営業車
    cv_cust_div            CONSTANT VARCHAR2(1)  := 'C';                     -- 預け先
    cv_inside_main_div     CONSTANT VARCHAR2(1)  := 'D';                     -- メイン倉庫
    cv_outside_main_div    CONSTANT VARCHAR2(1)  := 'E';                     -- 預け先メイン倉庫
    cv_customer_div        CONSTANT VARCHAR2(1)  := 'F';                     -- 顧客
    -- *** ローカル変数 ***
    lt_cust_base_code      xxcmm_cust_accounts.sale_base_code%TYPE;          -- 預け先拠点コード
    -- *** ローカル例外 ***
    sub_error_expt          EXCEPTION;                                       -- 値取得エラー
    sub_prog_error_expt     EXCEPTION;                                       -- サブ・プログラムエラー
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
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ========================
    -- 1.コード変換定義情報 取得
    -- ========================
    BEGIN
    --
        SELECT   
                 xhecv.outside_subinv_code_conv_div AS  outside_subinv_code_conv_div      -- 1.出庫側保管場所変換区分
                ,xhecv.inside_subinv_code_conv_div  AS  inside_subinv_code_conv_div       -- 2.入庫側保管場所変換区分
                ,xhecv.program_div                  AS  program_div                       -- 3.入出庫ジャーナル処理区分
                ,xhecv.consume_vd_flag              AS  consume_vd_flag                   -- 4.消化VD補充対象フラグ
                ,xhecv.stock_uncheck_list_div       AS  stock_uncheck_list_div            -- 5.入庫未確認リスト対象区分
                ,xhecv.stock_balance_list_div       AS  stock_balance_list_div            -- 6.入庫差異確認リスト対象区
                ,xhecv.item_convert_div             AS  item_convert_div                  -- 7.商品振替区分
        INTO     
                 ov_outside_subinv_code_conv                                              -- 1.出庫側保管場所変換区分
                ,ov_inside_subinv_code_conv                                               -- 2.入庫側保管場所変換区分
                ,ov_hht_program_div                                                       -- 3.入出庫ジャーナル処理区分
                ,ov_consume_vd_flag                                                       -- 4.消化VD補充対象フラグ
                ,ov_stock_uncheck_list_div                                                -- 5.入庫未確認リスト対象区分
                ,ov_stock_balance_list_div                                                -- 6.入庫差異確認リスト対象区分
                ,ov_item_convert_div                                                      -- 7.商品振替区分
        FROM    xxcoi_hht_ebs_convert_v xhecv
        WHERE   xhecv.record_type       = iv_record_type
        AND     xhecv.invoice_type      = NVL(iv_invoice_type,cv_dummy_code)
        AND     xhecv.department_flag   = NVL(iv_department_flag,cv_dummy_code)
        AND     TRUNC(cd_business_date) 
                    BETWEEN TRUNC( xhecv.start_date_active ) 
                        AND TRUNC( NVL( xhecv.end_date_active,cd_business_date ) );
    --
    EXCEPTION
    --
        WHEN NO_DATA_FOUND THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10225
                            ,iv_token_name1  => cv_tkn_record_type
                            ,iv_token_value1 => iv_record_type
                            ,iv_token_name2  => cv_tkn_invoice_type
                            ,iv_token_value2 => iv_invoice_type
                            ,iv_token_name3  => cv_tkn_department_flag
                            ,iv_token_value3 => iv_department_flag
                          );
            lv_retcode := cv_status_warn;
            lv_errbuf  := SQLERRM;
            RAISE sub_error_expt;
        --
        WHEN TOO_MANY_ROWS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10225
                            ,iv_token_name1  => cv_tkn_record_type
                            ,iv_token_value1 => iv_record_type
                            ,iv_token_name2  => cv_tkn_invoice_type
                            ,iv_token_value2 => iv_invoice_type
                            ,iv_token_name3  => cv_tkn_department_flag
                            ,iv_token_value3 => iv_department_flag
                          );
            lv_retcode := cv_status_warn;
            lv_errbuf  := SQLERRM;
            RAISE sub_error_expt;
        --
        WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                            ,iv_name         => cv_msg_coi_10225
                            ,iv_token_name1  => cv_tkn_record_type
                            ,iv_token_value1 => iv_record_type
                            ,iv_token_name2  => cv_tkn_invoice_type
                            ,iv_token_value2 => iv_invoice_type
                            ,iv_token_name3  => cv_tkn_department_flag
                            ,iv_token_value3 => iv_department_flag
                          );
            lv_retcode := cv_status_error;
            lv_errbuf  := SQLERRM;
            RAISE sub_error_expt;
    --
    END;
    -- ========================
    -- 2.倉庫保管場場所 取得(A)
    -- ========================
    -- ----------------------------------------------------
    -- 2-1.出庫側 倉庫保管場場所 取得
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_warehouse_div THEN
    --
        convert_whouse_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.エラーメッセージ
           ,ov_retcode          => lv_retcode               -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           => lv_errmsg                -- 3.ユーザー・エラーメッセージ
           ,iv_base_code        => iv_base_code             -- 4.拠点コード
           ,iv_warehouse_code   => iv_outside_code          -- 5.倉庫コード
           ,in_organization_id  => in_organization_id       -- 6.在庫組織ID
           ,ov_subinv_code      => ov_outside_subinv_code   -- 7.保管場所コード
           ,ov_base_code        => ov_outside_base_code     -- 8.拠点コード
           ,ov_subinv_div       => ov_outside_subinv_div    -- 9.棚卸対象
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ----------------------------------------------------
    -- 2-2.入庫側 倉庫保管場場所 取得
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_warehouse_div THEN
    --
        convert_whouse_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.エラーメッセージ
           ,ov_retcode          => lv_retcode               -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           => lv_errmsg                -- 3.ユーザー・エラーメッセージ
           ,iv_base_code        => iv_base_code             -- 4.拠点コード
           ,iv_warehouse_code   => iv_inside_code           -- 5.倉庫コード
           ,in_organization_id  => in_organization_id       -- 6.在庫組織ID
           ,ov_subinv_code      => ov_inside_subinv_code    -- 7.保管場所コード
           ,ov_base_code        => ov_inside_base_code      -- 8.拠点コード
           ,ov_subinv_div       => ov_inside_subinv_div     -- 9.棚卸対象
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==========================
    -- 3.営業者保管場場所 取得(B)
    -- ==========================
    -- ----------------------------------------------------
    -- 3-1.出庫側 営業車保管場場所 取得
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_sales_div THEN
        --
        convert_emp_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.エラーメッセージ
           ,ov_retcode          => lv_retcode               -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           => lv_errmsg                -- 3.ユーザー・エラーメッセージ
           ,iv_base_code        => iv_base_code             -- 4.拠点コード
           ,iv_employee_number  => iv_outside_code          -- 5.従業員コード
           ,in_organization_id  => in_organization_id       -- 6.在庫組織ID
           ,id_transaction_date => id_transaction_date      -- 7.伝票日付
           ,ov_subinv_code      => ov_outside_subinv_code   -- 8.保管場所コード
           ,ov_base_code        => ov_outside_base_code     -- 9.拠点コード
           ,ov_subinv_div       => ov_outside_subinv_div    --10.棚卸対象
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    --
    -- ----------------------------------------------------
    -- 3-2.入庫側 営業車保管場場所 取得
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_sales_div THEN
        --
        convert_emp_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.エラーメッセージ
           ,ov_retcode          => lv_retcode               -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           => lv_errmsg                -- 3.ユーザー・エラーメッセージ
           ,iv_base_code        => iv_base_code             -- 4.拠点コード
           ,iv_employee_number  => iv_inside_code           -- 5.従業員コード
           ,in_organization_id  => in_organization_id       -- 6.在庫組織ID
           ,id_transaction_date => id_transaction_date      -- 7.伝票日付
           ,ov_subinv_code      => ov_inside_subinv_code    -- 8.保管場所コード
           ,ov_base_code        => ov_inside_base_code      -- 9.拠点コード
           ,ov_subinv_div       => ov_inside_subinv_div     --10.棚卸対象
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==========================
    -- 4.預け先保管場場所 取得(C)
    -- ==========================
    -- ----------------------------------------------------
    -- 4-1.出庫側 預け先保管場場所 取得
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_cust_div THEN
        --
        convert_cust_subinv_code(
            ov_errbuf            => lv_errbuf                       -- 1.エラーメッセージ
           ,ov_retcode           => lv_retcode                      -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg            => lv_errmsg                       -- 3.ユーザー・エラーメッセージ
           ,iv_base_code         => iv_base_code                    -- 4.拠点コード
           ,iv_cust_code         => iv_outside_code                 -- 5.顧客コード
           ,id_transaction_date  => id_transaction_date             -- 6.伝票日付
           ,in_organization_id   => in_organization_id              -- 7.在庫組織ID
           ,iv_record_type       => iv_record_type                  -- 8.レコード種別
           ,iv_hht_form_flag     => iv_hht_form_flag                -- 9.HHT取引入力画面フラグ
           ,ov_subinv_code       => ov_outside_subinv_code          --10.保管場所コード
           ,ov_base_code         => ov_outside_base_code            --11.拠点コード
           ,ov_subinv_div        => ov_outside_subinv_div           --12.棚卸対象
           ,ov_business_low_type => ov_outside_business_low_type    --13.業態小分類
          );
        --
        -- 入庫側顧客コードをセット
        ov_outside_cust_code := iv_outside_code;
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    --
    -- ----------------------------------------------------
    -- 4-2.入庫側 預け先保管場場所 取得
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_cust_div THEN
        --
        convert_cust_subinv_code(
            ov_errbuf            => lv_errbuf                       -- 1.エラーメッセージ
           ,ov_retcode           => lv_retcode                      -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg            => lv_errmsg                       -- 3.ユーザー・エラーメッセージ
           ,iv_base_code         => iv_base_code                    -- 4.拠点コード
           ,iv_cust_code         => iv_inside_code                  -- 5.顧客コード
           ,id_transaction_date  => id_transaction_date             -- 6.伝票日付
           ,in_organization_id   => in_organization_id              -- 7.在庫組織ID
           ,iv_record_type       => iv_record_type                  -- 8.レコード種別
           ,iv_hht_form_flag     => iv_hht_form_flag                -- 9.HHT取引入力画面フラグ
           ,ov_subinv_code       => ov_inside_subinv_code           --10.保管場所コード
           ,ov_base_code         => ov_inside_base_code             --11.拠点コード
           ,ov_subinv_div        => ov_inside_subinv_div            --12.棚卸対象
           ,ov_business_low_type => ov_inside_business_low_type     --13.業態小分類
          );
        -- 預け先管轄拠点をセット
        lt_cust_base_code := ov_inside_base_code;
        -- 入庫側顧客コードをセット
        ov_inside_cust_code := iv_inside_code;
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==================================
    -- 5.拠点メイン倉庫保管場場所 取得(D)
    -- ==================================
    -- ----------------------------------------------------
    -- 5-1.入庫側 メイン倉庫保管場場所 取得
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_inside_main_div THEN
        --
        convert_base_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.エラーメッセージ
           ,ov_retcode          => lv_retcode               -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           => lv_errmsg                -- 3.ユーザー・エラーメッセージ
           ,iv_dept_code        => iv_inside_code           -- 4.拠点コード
           ,in_organization_id  => in_organization_id       -- 5.在庫組織ID
           ,ov_subinv_code      => ov_inside_subinv_code    -- 6.保管場所コード
           ,ov_base_code        => ov_inside_base_code      -- 7.拠点コード
           ,ov_subinv_div       => ov_inside_subinv_div     -- 8.棚卸対象
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    -- ==================================
    -- 6.預け先メイン倉庫保管場場所 取得(E)
    -- ==================================
    -- ----------------------------------------------------
    -- 6-1.出庫側 メイン倉庫保管場場所 取得
    -- ----------------------------------------------------
    IF ov_outside_subinv_code_conv = cv_outside_main_div THEN
        --
        convert_base_subinv_code(
            ov_errbuf           => lv_errbuf                -- 1.エラーメッセージ
           ,ov_retcode          => lv_retcode               -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           => lv_errmsg                -- 3.ユーザー・エラーメッセージ
           ,iv_dept_code        => lt_cust_base_code        -- 4.管轄拠点コード
           ,in_organization_id  => in_organization_id       -- 5.在庫組織ID
           ,ov_subinv_code      => ov_outside_subinv_code   -- 6.保管場所コード
           ,ov_base_code        => ov_outside_base_code     -- 7.拠点コード
           ,ov_subinv_div       => ov_outside_subinv_div    -- 8.棚卸対象
          );
        --
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;
    --
    END IF;
    --
    -- ==================================
    -- 7.顧客ステータスチェック(F)
    -- ==================================
    -- ----------------------------------------------------
    -- 7-1.入庫側 顧客ステータスチェック
    -- ----------------------------------------------------
    IF ov_inside_subinv_code_conv = cv_customer_div THEN
        --
        check_cust_status(
            ov_errbuf           => lv_errbuf                -- 1.エラーメッセージ
           ,ov_retcode          => lv_retcode               -- 2.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           => lv_errmsg                -- 3.ユーザー・エラーメッセージ
           ,iv_cust_code        => iv_inside_code           -- 4.顧客コード
          );
        --
-- == 2009/04/09 V1.3 Added START ===============================================================
        -- 入庫側顧客コードをセット
        ov_inside_cust_code := iv_inside_code;
-- == 2009/04/09 V1.3 Added END   ===============================================================
        IF lv_retcode <> cv_status_normal THEN
            RAISE sub_prog_error_expt;
        END IF;    
    --
    END IF;
    --
--
  EXCEPTION
    WHEN sub_error_expt THEN              -- *** 値取得エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
--
    WHEN sub_prog_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
--
  END convert_subinv_code;
--
--###########################   END   ##############################
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID
 * Description     : 勘定科目別名取引を作成する際に必要となる
 *                   勘定科目別名IDを取得する。有効日判定あり。
 ************************************************************************/
  FUNCTION get_disposition_id(
    iv_inv_account_kbn IN VARCHAR2   -- 1.入出庫勘定区分
   ,iv_dept_code       IN VARCHAR2   -- 2.部門コード
   ,in_organization_id IN NUMBER     -- 3.在庫組織ID
  ) RETURN NUMBER                    -- 勘定科目別名ID
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_disposition_id'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_date            DATE;                                         -- 業務日付
    lt_disposition_id  mtl_generic_dispositions.disposition_id%TYPE; -- 勘定科目別名ID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務日付取得
    ld_date := xxccp_common_pkg2.get_process_date;
--
    -- ====================================================
    -- 勘定科目別名ID取得
    -- ====================================================
    SELECT mgd.disposition_id AS disposition_id                                    -- 勘定科目別名ID
    INTO   lt_disposition_id
    FROM   mtl_generic_dispositions mgd                                            -- 勘定科目別名テーブル
    WHERE  mgd.segment1        = iv_dept_code                                      -- 部門コード
    AND    mgd.segment2        = iv_inv_account_kbn                                -- 入出庫勘定区分
    AND    mgd.organization_id = in_organization_id                                -- 在庫組織ID
    AND    ld_date BETWEEN mgd.effective_date AND NVL( mgd.disable_date, ld_date ) -- 有効日無効日判定
    ;
--
    -- 戻り値に勘定科目別名IDを設定します
    RETURN lt_disposition_id;
--
  EXCEPTION
    -- 取得に失敗した場合、NULLを戻します
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_disposition_id;
--
/************************************************************************
 * Procedure Name  : ADD_HHT_ERR_LIST_DATA
 * Description     : HHTデータ(入出庫・棚卸)取込の際にエラーとなった
 *                   レコードをもとに、HHTエラーリスト帳票に必要な
 *                   データをHHTエラーリスト帳票ワークテーブルに追加する。
 ************************************************************************/
  PROCEDURE add_hht_err_list_data(
    ov_errbuf                 OUT VARCHAR2   -- 1.エラー・メッセージ
   ,ov_retcode                OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg                 OUT VARCHAR2   -- 3.ユーザー・エラー・メッセージ
   ,iv_base_code              IN  VARCHAR2   -- 4.拠点コード
   ,iv_origin_shipment        IN  VARCHAR2   -- 5.出庫側コード
   ,iv_data_name              IN  VARCHAR2   -- 6.データ名称
   ,id_transaction_date       IN  DATE       -- 7.取引日
   ,iv_entry_number           IN  VARCHAR2   -- 8.伝票NO
   ,iv_party_num              IN  VARCHAR2   -- 9.入庫側コード
   ,iv_performance_by_code    IN  VARCHAR2   -- 10.営業員コード
   ,iv_item_code              IN  VARCHAR2   -- 11.品目コード
   ,iv_error_message          IN  VARCHAR2   -- 12.エラー内容
  ) 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'add_hht_err_list_data'; -- プログラム名
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
    cv_customer_class_code1 CONSTANT VARCHAR2(1)   := '1';  -- 顧客区分 1:拠点
    cv_customer_class_code2 CONSTANT VARCHAR2(2)   := '10'; -- 顧客区分 10:顧客
--
    -- *** ローカル変数 ***
    lt_party_name1          hz_parties.party_name%TYPE;     -- 正式名称 拠点名称
    lt_party_name2          hz_parties.party_name%TYPE;     -- 正式名称 顧客名
    lt_account_number       VARCHAR2(9);                    -- 顧客コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- パラメータ.拠点コードが設定されている場合
    IF ( iv_base_code IS NOT NULL ) THEN
--
      BEGIN
        SELECT hp.party_name AS party_name                       -- 正式名称
        INTO   lt_party_name1                                    -- 拠点名称
        FROM   hz_parties hp                                     -- パーティーマスタ
              ,hz_cust_accounts hca                              -- 顧客アカウント
        WHERE  hp.party_id             = hca.party_id            -- パーティーID
        AND    hca.customer_class_code = cv_customer_class_code1 -- 顧客区分
        AND    hca.account_number      = iv_base_code            -- 顧客コード
        ;
      -- 例外発生時は拠点名称にNULLを設定
      EXCEPTION
        WHEN OTHERS THEN
          lt_party_name1 := NULL;
      END;
--
    END IF;
--
    -- パラメータ.入庫側コードの桁数が9桁の場合、顧客コードに設定
    IF ( LENGTHB( iv_party_num ) = 9 ) THEN
       lt_account_number := iv_party_num;
    -- パラメータ.出庫側コードの桁数が9桁の場合、顧客コードに設定
    ELSIF ( LENGTHB( iv_origin_shipment ) = 9 ) THEN
       lt_account_number := iv_origin_shipment;
    -- 上記以外の場合、顧客コードにNULLを設定
    ELSE 
       lt_account_number := NULL;
    END IF;
--
    -- 顧客コードが設定されている場合
    IF ( lt_account_number IS NOT NULL ) THEN
--
      BEGIN
        SELECT hp.party_name AS party_name                       -- 正式名称
        INTO   lt_party_name2                                    -- 顧客名
        FROM   hz_parties hp                                     -- パーティーマスタ
              ,hz_cust_accounts hca                              -- 顧客アカウント
        WHERE  hp.party_id             = hca.party_id            -- パーティーID
        AND    hca.customer_class_code = cv_customer_class_code2 -- 顧客区分
        AND    hca.account_number      = lt_account_number       -- 顧客コード
        ;
      -- 例外発生時は顧客名にNULLを設定
      EXCEPTION
        WHEN OTHERS THEN
          lt_party_name2 := NULL;
      END;
--
    END IF;
--
    -- HHTエラーリスト帳票ワークテーブルに登録
    INSERT INTO xxcos_rep_hht_err_list(
       record_id                                  -- RECORD_ID
      ,base_code                                  -- 拠点コード
      ,base_name                                  -- 拠点名称
      ,origin_shipment                            -- 出庫側コード
      ,data_name                                  -- データ名称
      ,order_no_hht                               -- 受注NO（HHT）
      ,invoice_invent_date                        -- 伝票/棚卸日
      ,entry_number                               -- 伝票NO
      ,line_no                                    -- 行NO
      ,order_no_ebs                               -- 受注NO（EBS）
      ,party_num                                  -- 顧客コード
      ,customer_name                              -- 顧客名
      ,payment_dlv_date                           -- 入金/納品日
      ,payment_class_name                         -- 入金区分名称
      ,performance_by_code                        -- 成績者コード
      ,item_code                                  -- 品目コード
      ,error_message                              -- エラー内容
      ,report_group_id                            -- 帳票用グループID
      ,created_by                                 -- 作成者
      ,creation_date                              -- 作成日
      ,last_updated_by                            -- 最終更新者
      ,last_update_date                           -- 最終更新日
      ,last_update_login                          -- 最終更新ﾛｸﾞｲﾝ
      ,request_id                                 -- 要求ID
      ,program_application_id                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      ,program_id                                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      ,program_update_date                        -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    VALUES(
       xxcos_rep_hht_err_list_s01.nextval         -- RECORD_ID
      ,SUBSTRB( iv_base_code, 1, 4 )              -- 拠点コード
      ,SUBSTRB( lt_party_name1, 1, 30 )           -- 拠点名称
      ,SUBSTRB( iv_origin_shipment, 1, 9 )        -- 出庫側コード
      ,SUBSTRB( iv_data_name, 1, 20 )             -- データ名称
      ,NULL                                       -- 受注No（HHT）
      ,id_transaction_date                        -- 伝票/棚卸日
      ,SUBSTRB( iv_entry_number, 1, 9 )           -- 伝票NO
      ,NULL                                       -- 行NO
      ,NULL                                       -- 受注NO（EBS）
      ,SUBSTRB( iv_party_num, 1, 9 )              -- 顧客コード
      ,SUBSTRB( lt_party_name2, 1, 40 )           -- 顧客名
      ,NULL                                       -- 入金/納品日
      ,NULL                                       -- 入金区分名称
      ,SUBSTRB( iv_performance_by_code, 1, 5 )    -- 成績者コード
      ,SUBSTRB( iv_item_code, 1, 7 )              -- 品目コード
      ,SUBSTRB( iv_error_message, 1, 60 )         -- エラー内容
      ,NULL                                       -- 帳票用グループID
      ,cn_created_by                              -- 作成者
      ,cd_creation_date                           -- 作成日
      ,cn_last_updated_by                         -- 最終更新者
      ,cd_last_update_date                        -- 最終更新日
      ,cn_last_update_login                       -- 最終更新ﾛｸﾞｲﾝ
      ,cn_request_id                              -- 要求ID
      ,cn_program_application_id                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      ,cn_program_id                              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      ,cd_program_update_date                     -- ﾌﾟﾛｸﾞﾗﾑ更新日
     ) ;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END add_hht_err_list_data;
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID_2
 * Description     : 勘定科目別名取引を作成する際に必要となる
 *                   勘定科目別名IDを取得します。有効日判定なし。
 ************************************************************************/
  FUNCTION get_disposition_id_2(
    iv_inv_account_kbn IN VARCHAR2   -- 1.入出庫勘定区分
   ,iv_dept_code       IN VARCHAR2   -- 2.部門コード
   ,in_organization_id IN NUMBER     -- 3.在庫組織ID
  ) RETURN NUMBER                    -- 勘定科目別名ID
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_disposition_id_2'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_disposition_id2  mtl_generic_dispositions.disposition_id%TYPE; -- 勘定科目別名ID
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
--    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 勘定科目別名ID取得
    -- ====================================================
    SELECT mgd.disposition_id AS disposition_id     -- 勘定科目別名ID
    INTO   lt_disposition_id2
    FROM   mtl_generic_dispositions mgd             -- 勘定科目別名テーブル
    WHERE  mgd.segment1        = iv_dept_code       -- 部門コード
    AND    mgd.segment2        = iv_inv_account_kbn -- 入出庫区分
    AND    mgd.organization_id = in_organization_id -- 在庫組織ID
    ;
--
    -- 戻り値に勘定科目別名IDを設定します
    RETURN lt_disposition_id2;
--
  EXCEPTION
    -- 取得に失敗した場合、NULLを戻します
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_disposition_id_2;
--
--###########################   END   ##############################
--
-- == 2010/03/23 V1.9 Added START ===============================================================
/************************************************************************
 * Procedure Name  : GET_BASE_AFF_ACTIVE_DATE
 * Description     : 拠点コードからAFF部門の適用開始日を取得する。
 ************************************************************************/
  PROCEDURE get_base_aff_active_date(
    iv_base_code             IN  VARCHAR2   -- 拠点コード
   ,od_start_date_active     OUT DATE       -- 適用開始日
   ,ov_errbuf                OUT VARCHAR2   -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2   -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2   -- ユーザー・エラーメッセージ
  )
  IS
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_base_aff_active_date';
  BEGIN
    IF (iv_base_code IS NULL) THEN
      ov_retcode := cv_status_error;    -- 異常:2
    ELSE
      ov_retcode := cv_status_normal;   -- 正常:0
      -- ====================================================
      -- 適用開始日取得
      -- ====================================================
      SELECT ffv.start_date_active AS start_date_active      -- 適用開始日
      INTO   od_start_date_active
      FROM   fnd_flex_value_sets           ffvs              -- キーフレックス（セット）
            ,fnd_flex_values               ffv               -- キーフレックス（値）
      WHERE  ffvs.flex_value_set_id    = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name  = 'XX03_DEPARTMENT'
      AND    ffv.enabled_flag          = 'Y'
      AND    ffv.flex_value            = iv_base_code
      ;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_base_aff_active_date;
--
/************************************************************************
 * Procedure Name  : GET_SUBINV_AFF_ACTIVE_DATE
 * Description     : 保管場所コードからAFF部門の適用開始日を取得する。
 ************************************************************************/
  PROCEDURE get_subinv_aff_active_date(
    in_organization_id       IN  NUMBER     -- 在庫組織ID
   ,iv_subinv_code           IN  VARCHAR2   -- 保管場所コード
   ,od_start_date_active     OUT DATE       -- 適用開始日
   ,ov_errbuf                OUT VARCHAR2   -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2   -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2   -- ユーザー・エラーメッセージ
  )
  IS
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_subinv_aff_active_date';
  BEGIN
    IF (in_organization_id IS NULL) OR (iv_subinv_code IS NULL) THEN
      ov_retcode := cv_status_error;    -- 異常:2
    ELSE
      ov_retcode := cv_status_normal;   -- 正常:0
      -- ====================================================
      -- 適用開始日取得
      -- ====================================================
      SELECT ffv.start_date_active AS start_date_active      -- 適用開始日
      INTO   od_start_date_active
      FROM   mtl_secondary_inventories     msi               -- 保管場所マスタ
            ,fnd_flex_value_sets           ffvs              -- キーフレックス（セット）
            ,fnd_flex_values               ffv               -- キーフレックス（値）
      WHERE  ffvs.flex_value_set_id       = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name     = 'XX03_DEPARTMENT'
      AND    ffv.enabled_flag             = 'Y'
      AND    ffv.flex_value               = msi.attribute7
      AND    msi.organization_id          = in_organization_id
      AND    msi.secondary_inventory_name = iv_subinv_code
      ;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_subinv_aff_active_date;
--
-- == 2010/03/23 V1.9 Added END   ===============================================================
-- == 2010/03/29 V1.10 Added START ===============================================================
/************************************************************************
 * Function Name   : CHK_AFF_ACTIVE
 * Description     : AFF部門の使用可能チェックを行います。
 ************************************************************************/
  FUNCTION chk_aff_active(
      in_organization_id      IN  NUMBER      -- 在庫組織ID
    , iv_base_code            IN  VARCHAR2    -- 拠点コード
    , iv_subinv_code          IN  VARCHAR2    -- 保管場所コード
    , id_target_date          IN  DATE        -- 対象日
  ) RETURN VARCHAR2                           -- チェック結果
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'chk_aff_active'; -- プログラム名
    cv_y         CONSTANT VARCHAR2(1)  := 'Y';               -- 使用可能
    cv_n         CONSTANT VARCHAR2(1)  := 'N';               -- 使用不可
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_start_date_active      fnd_flex_values.start_date_active%TYPE; -- 適用開始日
--
  BEGIN
--
    -- ====================================================
    -- AFF部門取得
    -- ====================================================
    IF (iv_base_code IS NOT NULL) THEN
      -- 拠点コードより使用可不可を確認
      SELECT  ffv.start_date_active         start_date_active --  適応開始日
      INTO    ld_start_date_active
      FROM    fnd_flex_value_sets           ffvs              --  キーフレックス（セット）
            , fnd_flex_values               ffv               --  キーフレックス（値）
      WHERE   ffvs.flex_value_set_id      =   ffv.flex_value_set_id
      AND     ffvs.flex_value_set_name    =   'XX03_DEPARTMENT'
      AND     ffv.enabled_flag            =   'Y'
      AND     ffv.flex_value              =   iv_base_code
      ;
      --
      IF  (ld_start_date_active IS NULL) THEN
        -- 適応開始日NULLの場合、使用可能
        RETURN  cv_y;
      ELSIF (ld_start_date_active   <=  id_target_date) THEN
        -- 対象日が適応開始日以降の場合、使用可能
        RETURN  cv_y;
      ELSE
        -- 対象日が適応開始日より前の場合、使用不可
        RETURN  cv_n;
      END IF;
      --
    ELSIF (iv_subinv_code IS NOT NULL) THEN
      -- 保管場所コードより使用可不可を確認
      SELECT  ffv.start_date_active AS start_date_active      -- 適用開始日
      INTO    ld_start_date_active
      FROM    mtl_secondary_inventories     msi               -- 保管場所マスタ
            , fnd_flex_value_sets           ffvs              -- キーフレックス（セット）
            , fnd_flex_values               ffv               -- キーフレックス（値）
      WHERE   ffvs.flex_value_set_id        =   ffv.flex_value_set_id
      AND     ffvs.flex_value_set_name      =   'XX03_DEPARTMENT'
      AND     ffv.enabled_flag              =   'Y'
      AND     ffv.flex_value                =   msi.attribute7
      AND     msi.organization_id           =   in_organization_id
      AND     msi.secondary_inventory_name  =   iv_subinv_code
      ;
      --
      IF  (ld_start_date_active IS NULL) THEN
        -- 適応開始日NULLの場合、使用可能
        RETURN  cv_y;
      ELSIF (ld_start_date_active   <=  id_target_date) THEN
        -- 対象日が適応開始日以降の場合、使用可能
        RETURN  cv_y;
      ELSE
        -- 対象日が適応開始日より前の場合、使用不可
        RETURN  cv_n;
      END IF;
      --
    ELSE
      -- 拠点、保管場所がともにNULLの場合、使用不可
      RETURN cv_n;
      --
    END IF;

--
  EXCEPTION
    -- NOTFOUND, TOO_MANY_ROWS等は使用不可
    WHEN OTHERS THEN
      RETURN cv_n;
--
  END chk_aff_active;
--
-- == 2010/03/29 V1.10 Added END   ===============================================================
END XXCOI_COMMON_PKG;
/
