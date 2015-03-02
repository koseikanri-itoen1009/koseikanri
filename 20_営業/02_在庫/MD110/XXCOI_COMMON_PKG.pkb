CREATE OR REPLACE PACKAGE BODY XXCOI_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI_COMMON_PKG(body)
 * Description      : 共通関数パッケージ(在庫)
 * MD.070           : 共通関数    MD070_IPO_COI
 * Version          : 1.12
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  ORG_ACCT_PERIOD_CHK        在庫会計期間チェック
 *  GET_ORGANIZATION_ID        在庫組織ID取得
 *  GET_BELONGING_BASE         所属拠点コード取得1
 *  GET_BASE_CODE              所属拠点コード取得2
 *  GET_BELONGING_BASE2        所属拠点コード取得3
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
 *  CRE_LOT_TRX_TEMP           ロット別取引TEMP作成
 *  DEL_LOT_TRX_TEMP           ロット別取引TEMP削除
 *  CRE_LOT_TRX                ロット別取引明細作成
 *  GET_CUSTOMER_ID            顧客導出（受注アドオン）
 *  GET_PARENT_CHILD_ITEM_INFO 品目コード導出（親／子）
 *  INS_UPD_LOT_HOLD_INFO      ロット情報保持マスタ反映
 *  INS_UPD_DEL_LOT_ONHAND     ロット別手持数量反映
 *  GET_FRESH_CONDITION_DATE   鮮度条件基準日算出
 *  GET_RESERVED_QUANTITY      引当可能数算出
 *  GET_FRESH_CONDITION_DATE_F 鮮度条件基準日算出(ファンクション型)
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
 *  2011/11/01    1.11  T.Yoshimoto      [E_本稼動_07570]所属拠点コード取得3を追加
 *  2014/11/07    1.12  Y.Nagasue        [E_本稼動_12237]倉庫管理システム対応 以下の関数を新規作成
 *                                        ロット別取引TEMP作成、ロット別取引TEMP削除、ロット別取引明細、
 *                                        顧客導出（受注アドオン）、品目コード導出（親／子）、
 *                                        ロット情報保持マスタ反映、ロット別手持数量反映、
 *                                        鮮度条件基準日算出、引当可能数算出、鮮度条件基準日算出(ファンクション型)
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
-- 2011/11/01 T.Yoshimoto v1.11 Add Start E_本稼動_07570
/************************************************************************
 * Procedure Name  : GET_BELONGING_BASE2
 * Description     : 営業員に紐付く所属拠点コードを取得する。
 ************************************************************************/
  PROCEDURE get_belonging_base2(
    in_employee_code  IN  VARCHAR2        -- 営業員コード
   ,id_target_date    IN  DATE            -- 対象日
   ,ov_base_code      OUT VARCHAR2        -- 拠点コード
   ,ov_errbuf         OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2        -- ユーザー・エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(99) := 'get_belonging_base2';
    -- *** ローカル定数 ***
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    cv_date_format CONSTANT VARCHAR2(8) := 'YYYYMMDD';
    cv_employee    CONSTANT VARCHAR2(8) := 'EMPLOYEE';              -- カテゴリ：従業員
    cv_emp         CONSTANT VARCHAR2(3) := 'EMP';
    cv_y           CONSTANT VARCHAR2(1) := 'Y';
--
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- 拠点コード初期化
    ov_base_code := NULL;
--
    -- 営業員コードがNULLまたは、対象日がNULLの場合
    IF ( ( in_employee_code IS NULL ) OR ( id_target_date IS NULL ) ) THEN
      ov_retcode := cv_status_error;    -- 異常:2
--
    ELSE
--
      SELECT CASE
               WHEN aaf.ass_attribute2 IS NULL              -- 発令日
                 THEN aaf.ass_attribute5
               WHEN TO_DATE(aaf.ass_attribute2,cv_date_format) > id_target_date
                 THEN aaf.ass_attribute6                    -- 拠点コード（旧）
               ELSE aaf.ass_attribute5                      -- 拠点コード（新）
             END  AS base_code
      INTO   ov_base_code                                   -- 自拠点コード
      FROM   per_all_people_f         apf                   -- 従業員マスタ
            ,per_all_assignments_f    aaf                   -- 従業員割当マスタ(アサイメント)
            ,per_person_types         ppt                   -- 従業員区分マスタ
            ,jtf_rs_salesreps         jrs
            ,jtf_rs_resource_extns    jrre
      WHERE  TRUNC(id_target_date) BETWEEN TRUNC(apf.effective_start_date)
          AND  TRUNC(NVL(apf.effective_end_date,id_target_date))
        AND  TRUNC(id_target_date) BETWEEN TRUNC(aaf.effective_start_date)
          AND  TRUNC(NVL(aaf.effective_end_date,id_target_date))
        AND  ppt.business_group_id  = cn_business_group_id
        AND  ppt.system_person_type = cv_emp
        AND  ppt.active_flag        = cv_y
        AND  apf.person_type_id     = ppt.person_type_id
        AND  aaf.person_id          = apf.person_id
        AND  apf.person_id          = jrre.source_id
        AND  jrre.category          = cv_employee
        AND  jrre.resource_id       = jrs.resource_id
        AND  jrs.salesrep_number    = in_employee_code
      ;
      --
      IF (ov_base_code IS NULL) THEN
        ov_retcode := cv_status_error;    -- 異常:2
      END IF;
--
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_belonging_base2;
-- 2011/11/01 T.Yoshimoto v1.11 Add End
-- == 2014/11/07 Ver1.5 Y.Nagasue ADD START ======================================================
/************************************************************************
 * Procedure Name  : CRE_LOT_TRX_TEMP
 * Description     : ロット別取引TEMP作成
 ************************************************************************/
  PROCEDURE cre_lot_trx_temp(
    in_trx_set_id       IN  NUMBER   -- 取引セットID
   ,iv_parent_item_code IN  VARCHAR2 -- 親品目コード
   ,iv_child_item_code  IN  VARCHAR2 -- 子品目コード
   ,iv_lot              IN  VARCHAR2 -- ロット(賞味期限)
   ,iv_diff_sum_code    IN  VARCHAR2 -- 固有記号
   ,iv_trx_type_code    IN  VARCHAR2 -- 取引タイプコード
   ,id_trx_date         IN  DATE     -- 取引日
   ,iv_slip_num         IN  VARCHAR2 -- 伝票No
   ,in_case_in_qty      IN  NUMBER   -- 入数
   ,in_case_qty         IN  NUMBER   -- ケース数
   ,in_singly_qty       IN  NUMBER   -- バラ数
   ,in_summary_qty      IN  NUMBER   -- 取引数量
   ,iv_base_code        IN  VARCHAR2 -- 拠点コード
   ,iv_subinv_code      IN  VARCHAR2 -- 保管場所コード
   ,iv_tran_subinv_code IN  VARCHAR2 -- 転送先保管場所コード
   ,iv_tran_loc_code    IN  VARCHAR2 -- 転送先ロケーションコード
   ,iv_inout_code       IN  VARCHAR2 -- 入出庫コード
   ,iv_source_code      IN  VARCHAR2 -- ソースコード
   ,iv_relation_key     IN  VARCHAR2 -- 紐付けキー
   ,on_trx_id           OUT NUMBER   -- ロット別TEMP取引ID
   ,ov_errbuf           OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode          OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg           OUT VARCHAR2 -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'cre_lot_trx_temp'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_10477 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10477'; -- 共通関数パラメータ必須エラー
    cv_err_msg_xxcoi1_10478 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10478'; -- ケース数・バラ数符号チェックエラー
    cv_err_msg_xxcoi1_10479 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10479'; -- 取引数量チェックエラー
    cv_err_msg_xxcoi1_00005 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
    cv_err_msg_xxcoi1_10470 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10470'; -- マスタ組織取得エラー
    cv_err_msg_xxcoi1_00006 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
    cv_err_msg_xxcoi1_10480 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10480'; -- 品目ID取得エラー
    cv_err_msg_xxcoi1_10481 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10481'; -- ロケーション取得エラー
    cv_err_msg_xxcoi1_10507 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10507'; -- 入数0以下エラー
--
    cv_msg_xxcoi1_10493     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10493'; -- ロット別取引TEMP作成
    cv_msg_xxcoi1_10496     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10496'; -- 親品目コード
    cv_msg_xxcoi1_10497     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10497'; -- 取引タイプコード
    cv_msg_xxcoi1_10498     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10498'; -- 取引日
    cv_msg_xxcoi1_10499     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10499'; -- 伝票No
    cv_msg_xxcoi1_10500     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10500'; -- 入数
    cv_msg_xxcoi1_10501     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10501'; -- 取引数量
    cv_msg_xxcoi1_10502     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10502'; -- 拠点コード
    cv_msg_xxcoi1_10503     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10503'; -- 保管場所コード
    cv_msg_xxcoi1_10504     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10504'; -- ソースコード
    cv_msg_xxcoi1_10505     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10505'; -- 紐付けキー
--
    cv_msg_tkn_param1       CONSTANT VARCHAR2(20)  := 'PARAM1';           -- トークン：パラメータ１
    cv_msg_tkn_param2       CONSTANT VARCHAR2(20)  := 'PARAM2';           -- トークン：パラメータ２
    cv_msg_tkn_pro_tok      CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- トークン：プロファイル名
    cv_msg_tkn_org_code_tok CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- トークン：在庫組織コード
    cv_msg_tkn_item_code    CONSTANT VARCHAR2(20)  := 'ITEM_CODE';        -- トークン：品目コード
    cv_msg_tkn_subinv_code  CONSTANT VARCHAR2(20)  := 'SUBINV_CODE';      -- トークン：保管場所コード
--
    -- プロファイル
    cv_xxcoi1_organization_code
                            CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- 在庫組織コード
--
    -- 参照タイプ
    cv_xxcoi1_tran_type     CONSTANT VARCHAR2(30)  := 'XXCOI1_TRANSACTION_TYPE_NAME';   -- ユーザー定義取引タイプ名称
    cv_xxcoi1_lot_tran_type CONSTANT VARCHAR2(30)  := 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'; -- ロット別取引表示取引タイプ名
--
    -- 取引タイプコード
    cv_trx_type_code_10     CONSTANT VARCHAR2(2)   := '10'; -- 入出庫
    cv_trx_type_code_20     CONSTANT VARCHAR2(2)   := '20'; -- 倉替
    cv_trx_type_code_70     CONSTANT VARCHAR2(2)   := '70'; -- 消化VD補充
--
    -- ソースコード値
    cv_invttmtx             CONSTANT VARCHAR2(15)  := 'INVTTMTX';     -- その他取引入力画面
    cv_xxcoi016a06c         CONSTANT VARCHAR2(15)  := 'XXCOI016A06C'; -- ロット別出荷情報作成
--
    -- SQL使用定数
    cv_flag_y               CONSTANT VARCHAR2(1)   := 'Y'; -- フラグ:Y
    ct_lang                 CONSTANT fnd_lookup_values.language%TYPE                 := USERENV('LANG'); -- 言語
    ct_priority_1           CONSTANT xxcoi_mst_warehouse_location.priority%TYPE      := 1;               -- 優先順位：メインロケーション
    ct_location_type_3      CONSTANT xxcoi_mst_warehouse_location.location_type%TYPE := '3';             -- ロケーションタイプ：ダミーロケーション
--
--
    -- *** ローカル変数 ***
    -- 入力パラメータ格納用変数
    lt_trx_set_id        xxcoi_lot_transactions_temp.transaction_set_id%TYPE;      -- 取引セットID
    lt_parent_item_code  mtl_system_items_b.segment1%TYPE;                         -- 親品目コード
    lt_child_item_code   mtl_system_items_b.segment1%TYPE;                         -- 子品目コード
    lt_lot               xxcoi_lot_transactions_temp.lot%TYPE;                     -- ロット(賞味期限)
    lt_diff_sum_code     xxcoi_lot_transactions_temp.difference_summary_code%TYPE; -- 固有記号
    lt_trx_type_code     xxcoi_lot_transactions_temp.transaction_type_code%TYPE;   -- 取引タイプコード
    lt_trx_date          xxcoi_lot_transactions_temp.transaction_date%TYPE;        -- 取引日
    lt_slip_num          xxcoi_lot_transactions_temp.slip_num%TYPE;                -- 伝票No
    lt_case_in_qty       xxcoi_lot_transactions_temp.case_in_qty%TYPE;             -- 入数
    lt_case_qty          xxcoi_lot_transactions_temp.case_qty%TYPE;                -- ケース数
    lt_singly_qty        xxcoi_lot_transactions_temp.singly_qty%TYPE;              -- バラ数
    lt_summary_qty       xxcoi_lot_transactions_temp.summary_qty%TYPE;             -- 取引数量
    lt_base_code         xxcoi_lot_transactions_temp.base_code%TYPE;               -- 拠点コード
    lt_subinv_code       xxcoi_lot_transactions_temp.subinventory_code%TYPE;       -- 保管場所コード
    lt_tran_subinv_code  xxcoi_lot_transactions_temp.transfer_subinventory%TYPE;   -- 転送先保管場所コード
    lt_tran_loc_code     xxcoi_lot_transactions_temp.transfer_location_code%TYPE;  -- 転送先ロケーションコード
    lt_sign_div          xxcoi_lot_transactions_temp.sign_div%TYPE;                -- 符号区分
    lt_source_code       xxcoi_lot_transactions_temp.source_code%TYPE;             -- ソースコード
    lt_relation_key      xxcoi_lot_transactions_temp.relation_key%TYPE;            -- 紐付けキー
--
    -- ID変換、導出項目
    lt_org_code          mtl_parameters.organization_code%TYPE;           -- 在庫組織コード
    lt_org_id            mtl_parameters.organization_id%TYPE;             -- 在庫組織ID
    lt_parent_item_id    xxcoi_lot_transactions_temp.parent_item_id%TYPE; -- 親品目ID
    lt_child_item_id     xxcoi_lot_transactions_temp.child_item_id%TYPE;  -- 子品目ID
    lt_loc_code          xxcoi_lot_transactions_temp.location_code%TYPE;  -- ロケーションコード
    lt_trx_id            xxcoi_lot_transactions_temp.transaction_id%TYPE; -- 取引ID
--
    -- メッセージ格納用変数
    lv_msg_proc_name     VARCHAR2(100); -- プロシージャ名
    lv_msg_chk_tkn       VARCHAR2(100); -- 入力パラメータエラートークン格納用変数
--
    -- その他
    lv_inout_code        VARCHAR2(3); -- 入出庫コード
    ln_trx_num_chk       NUMBER;      -- 取引数量チェック用変数
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    -- 入力パラメータ格納用変数
    lt_trx_set_id           := NULL; -- 取引セットID
    lt_parent_item_code     := NULL; -- 親品目コード
    lt_child_item_code      := NULL; -- 子品目コード
    lt_lot                  := NULL; -- ロット(賞味期限)
    lt_diff_sum_code        := NULL; -- 固有記号
    lt_trx_type_code        := NULL; -- 取引タイプコード
    lt_trx_date             := NULL; -- 取引日
    lt_slip_num             := NULL; -- 伝票No
    lt_case_in_qty          := NULL; -- 入数
    lt_case_qty             := NULL; -- ケース数
    lt_singly_qty           := NULL; -- バラ数
    lt_summary_qty          := NULL; -- 取引数量
    lt_base_code            := NULL; -- 拠点コード
    lt_subinv_code          := NULL; -- 保管場所コード
    lt_tran_subinv_code     := NULL; -- 転送先保管場所コード
    lt_tran_loc_code        := NULL; -- 転送先ロケーションコード
    lt_sign_div             := NULL; -- 符号区分
    lt_source_code          := NULL; -- ソースコード
    lt_relation_key         := NULL; -- 紐付けキー
--
    -- SQL導出項目
    lt_org_code             := NULL; -- 在庫組織コード
    lt_org_id               := NULL; -- 在庫組織ID
    lt_parent_item_id       := NULL; -- 親品目ID
    lt_child_item_id        := NULL; -- 子品目ID
    lt_loc_code             := NULL; -- ロケーションコード
    lt_trx_id               := NULL; -- 取引ID
--
    -- メッセージ格納用変数
    lv_msg_proc_name        := NULL; -- プロシージャ名
    lv_msg_chk_tkn          := NULL; -- 入力パラメータエラートークン格納用変数
--
    -- その他
    lv_inout_code           := NULL; -- 入出庫コード
    ln_trx_num_chk          := NULL; -- 取引数量チェック用変数
--
    -- プロシージャ名取得
    lv_msg_proc_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10493
                        );
--
    -- ======================================
    -- １：入力パラメータのチェック
    -- ======================================
    -- 親品目コード
    IF ( iv_parent_item_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10496
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取引タイプコード
    IF ( iv_trx_type_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10497
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取引日
    IF ( id_trx_date IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10498
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 伝票No
    IF ( iv_slip_num IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10499
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入数
    IF ( in_case_in_qty IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10500
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取引数量
    IF ( in_summary_qty IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10501
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 拠点コード
    IF ( iv_base_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10502
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 保管場所コード
    IF ( iv_subinv_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10503
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ソースコード
    IF ( iv_source_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10504
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 紐付けキー
    IF ( iv_relation_key IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10505
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- INパラメータを変数に退避
    lt_trx_set_id       := in_trx_set_id;       -- 取引セットID
    lt_parent_item_code := iv_parent_item_code; -- 親品目コード
    lt_child_item_code  := iv_child_item_code;  -- 子品目コード
    lt_lot              := iv_lot;              -- ロット(賞味期限)
    lt_diff_sum_code    := iv_diff_sum_code;    -- 固有記号
    lt_trx_type_code    := iv_trx_type_code;    -- 取引タイプコード
    lt_trx_date         := id_trx_date;         -- 取引日
    lt_slip_num         := iv_slip_num;         -- 伝票No
    lt_case_in_qty      := in_case_in_qty;      -- 入数
    lt_case_qty         := in_case_qty;         -- ケース数
    lt_singly_qty       := in_singly_qty;       -- バラ数
    lt_summary_qty      := in_summary_qty;      -- 取引数量
    lt_base_code        := iv_base_code;        -- 拠点コード
    lt_subinv_code      := iv_subinv_code;      -- 保管場所コード
    lt_tran_subinv_code := iv_tran_subinv_code; -- 転送先保管場所コード
    lt_tran_loc_code    := iv_tran_loc_code;    -- 転送先ロケーションコード
    lv_inout_code       := iv_inout_code;       -- 入出庫コード
    lt_source_code      := iv_source_code;      -- ソースコード
    lt_relation_key     := iv_relation_key;     -- 紐付けキー
--
    -- 入数、ケース数、バラ数、取引数量の検証
    -- ケース数がNULLの場合は0を設定
    IF ( lt_case_qty IS NULL ) THEN
      lt_case_qty := 0;
    END IF;
--
    -- バラ数がNULLの場合は0を設定
    IF ( lt_singly_qty IS NULL ) THEN
      lt_singly_qty := 0;
    END IF;
--
    -- 入数が0以下の場合は、エラー
    IF ( lt_case_in_qty <= 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10507
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/*
    -- ケース数、バラ数の符号チェック
    -- 符号が異なる場合はエラー
    IF ( (lt_case_qty >= 0 AND lt_singly_qty >= 0) OR (lt_case_qty <= 0 AND lt_singly_qty <= 0) ) THEN
      NULL;
    ELSE
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10478
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
*/
--
    -- (入数＊ケース数)＋バラ数が取引数量と異なる場合はエラー
    ln_trx_num_chk := ( lt_case_in_qty * lt_case_qty ) + lt_singly_qty;
    IF ( lt_summary_qty <> ln_trx_num_chk ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10479
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- WHOカラム取得
    -- 固定グローバル変数を使用するため割愛
--
    -- プロファイル「XXCOI:在庫組織コード」を取得
    -- 取得できない場合はエラー
    lt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00005
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_xxcoi1_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- ２：ID変換、取得
    -- ======================================
    -- 共通関数を使用し、在庫組織IDを取得
    -- 取得できない場合はエラー
    lt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => lt_org_code
                 );
    IF ( lt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00006
                     ,iv_token_name1  => cv_msg_tkn_org_code_tok
                     ,iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 親品目ID取得
    -- 取得できない場合はエラー
    BEGIN
      SELECT msib.inventory_item_id inventory_item_id
      INTO   lt_parent_item_id
      FROM   mtl_system_items_b msib                    -- Disc品目マスタ
      WHERE  msib.segment1        = lt_parent_item_code -- 親品目コード
      AND    msib.organization_id = lt_org_id           -- 在庫組織ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10480
                       ,iv_token_name1  => cv_msg_tkn_org_code_tok
                       ,iv_token_value1 => lt_org_code
                       ,iv_token_name2  => cv_msg_tkn_item_code
                       ,iv_token_value2 => lt_parent_item_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 子品目ID取得
    -- NULLの場合は処理を行わない
    IF ( lt_child_item_code IS NULL ) THEN
      NULL;
    ELSE
      -- 子品目IDを取得
      -- 取得できない場合はエラー
      BEGIN
        SELECT msib.inventory_item_id inventory_item_id
        INTO   lt_child_item_id
        FROM   mtl_system_items_b msib                   -- Disc品目マスタ
        WHERE  msib.segment1        = lt_child_item_code -- 子品目コード
        AND    msib.organization_id = lt_org_id          -- 在庫組織ID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10480
                         ,iv_token_name1  => cv_msg_tkn_org_code_tok
                         ,iv_token_value1 => lt_org_code
                         ,iv_token_name2  => cv_msg_tkn_item_code
                         ,iv_token_value2 => lt_child_item_code
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    -- ロケーションコード取得
    -- 子品目コードがNULL、または、ロット別出荷情報作成から起動の場合は処理を行わない
    IF ( ( lt_child_item_code IS NULL ) OR ( lt_source_code = cv_xxcoi016a06c ) ) THEN
      NULL;
    ELSE
      -- メインロケーションを取得
      -- 取得できなかった場合は、ダミーロケーションを取得
      BEGIN
        SELECT xmwl.location_code location_code
        INTO   lt_loc_code
        FROM   xxcoi_mst_warehouse_location xmwl         -- 倉庫ロケーションマスタ
        WHERE  xmwl.organization_id   = lt_org_id        -- 在庫組織ID
        AND    xmwl.base_code         = lt_base_code     -- 拠点コード
        AND    xmwl.subinventory_code = lt_subinv_code   -- 保管場所コード
        AND    xmwl.child_item_id     = lt_child_item_id -- 子品目ID
        AND    xmwl.priority          = ct_priority_1    -- 優先順位：１（メインロケーション）
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ダミーロケーションを取得
          -- 取得できなかった場合はエラー
          BEGIN
            SELECT xmwl.location_code location_code
            INTO   lt_loc_code
            FROM   xxcoi_mst_warehouse_location xmwl            -- 倉庫ロケーションマスタ
            WHERE  xmwl.organization_id   = lt_org_id           -- 在庫組織ID
            AND    xmwl.base_code         = lt_base_code        -- 拠点コード
            AND    xmwl.subinventory_code = lt_subinv_code      -- 保管場所コード
            AND    xmwl.location_type     = ct_location_type_3  -- ロケーションタイプ：ダミーロケーション
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_coi
                             ,iv_name         => cv_err_msg_xxcoi1_10481
                             ,iv_token_name1  => cv_msg_tkn_org_code_tok
                             ,iv_token_value1 => lt_org_code
                             ,iv_token_name2  => cv_msg_tkn_subinv_code
                             ,iv_token_value2 => lt_subinv_code
                             ,iv_token_name3  => cv_msg_tkn_item_code
                             ,iv_token_value3 => lt_child_item_code
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
      END;
    END IF;
--
    -- 符号取得
    -- 入出庫、倉替、消化VD補充の場合
    IF ( lt_trx_type_code IN ( cv_trx_type_code_10, cv_trx_type_code_20, cv_trx_type_code_70 ) ) THEN
      SELECT flv.attribute2    AS attribute2 -- 符号区分
      INTO   lt_sign_div
      FROM   fnd_lookup_values flv --参照タイプ
      WHERE  flv.lookup_type  = cv_xxcoi1_lot_tran_type
      AND    flv.lookup_code  = lv_inout_code
      AND    flv.language     = ct_lang
      AND    flv.enabled_flag = cv_flag_y
      AND    lt_trx_date      BETWEEN NVL(flv.start_date_active, lt_trx_date)
                              AND     NVL(flv.end_date_active  , lt_trx_date)
      ;
    -- 上記以外の場合
    ELSE
      SELECT flv.attribute2    AS attribute2 -- 符号区分
      INTO   lt_sign_div
      FROM   fnd_lookup_values flv --参照タイプ
      WHERE  flv.lookup_type  = cv_xxcoi1_tran_type
      AND    flv.lookup_code  = lt_trx_type_code
      AND    flv.language     = ct_lang
      AND    flv.enabled_flag = cv_flag_y
      AND    lt_trx_date      BETWEEN NVL(flv.start_date_active, lt_trx_date)
                              AND     NVL(flv.end_date_active  , lt_trx_date)
      ;
    END IF;
--
    -- ======================================
    -- ３：ロット別取引TEMP登録、更新
    -- ======================================
    -- 存在チェック
    BEGIN
      SELECT xltt.transaction_id transaction_id
      INTO   lt_trx_id
      FROM   xxcoi_lot_transactions_temp xltt              -- ロット別取引TEMP
      WHERE  xltt.transaction_type_code = lt_trx_type_code -- 取引タイプコード
      AND    xltt.source_code           = lt_source_code   -- ソースコード
      AND    xltt.relation_key          = lt_relation_key  -- 紐付けキー
      AND    xltt.base_code             = lt_base_code     -- 拠点コード
      AND    xltt.subinventory_code     = lt_subinv_code   -- 保管場所コード
      AND    xltt.organization_id       = lt_org_id        -- 在庫組織ID
      AND    xltt.source_code           = cv_invttmtx      -- その他取引画面
      ;
--
      -- 存在する場合は、更新
      UPDATE xxcoi_lot_transactions_temp
      SET    transaction_set_id        = lt_trx_set_id                    -- 取引セットID
            ,organization_id           = lt_org_id                        -- 在庫組織ID
            ,parent_item_id            = lt_parent_item_id                -- 親品目ID
            ,child_item_id             = lt_child_item_id                 -- 子品目ID
            ,lot                       = lt_lot                           -- ロット
            ,difference_summary_code   = lt_diff_sum_code                 -- 固有記号
            ,transaction_month         = TO_CHAR( lt_trx_date, 'YYYYMM' ) -- 取引年月
            ,transaction_date          = lt_trx_date                      -- 取引日
            ,slip_num                  = lt_slip_num                      -- 伝票No
            ,case_in_qty               = lt_case_in_qty                   -- 入数
            ,case_qty                  = lt_case_qty                      -- ケース数
            ,singly_qty                = lt_singly_qty                    -- バラ数
            ,summary_qty               = lt_summary_qty                   -- 取引数量
            ,base_code                 = lt_base_code                     -- 拠点コード
            ,subinventory_code         = lt_subinv_code                   -- 保管場所コード
            ,location_code             = lt_loc_code                      -- ロケーションコード
            ,transfer_organization_id  = DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id )
                                                                          -- 転送先在庫組織ID
            ,transfer_subinventory     = lt_tran_subinv_code              -- 転送先保管場所コード
            ,transfer_location_code    = lt_tran_loc_code                 -- 転送先ロケーションコード
            ,last_updated_by           = cn_last_updated_by               -- 最終更新者
            ,last_update_date          = cd_last_update_date              -- 最終更新日
            ,last_update_login         = cn_last_update_login             -- 最終更新ログイン
            ,request_id                = cn_request_id                    -- 要求ID
            ,program_application_id    = cn_program_application_id        -- コンカレント・プログラム・アプリケーションID
            ,program_id                = cn_program_id                    -- コンカレント・プログラムID
            ,program_update_date       = cd_program_update_date           -- プログラム更新日
      WHERE  transaction_id            = lt_trx_id                        -- 取引ID
      ;
--
    EXCEPTION
      -- 存在しない場合は、新規作成
      WHEN NO_DATA_FOUND THEN
--
        -- シーケンス値取得
        SELECT xxcoi_lot_trx_temp_s01.NEXTVAL
        INTO   lt_trx_id
        FROM   DUAL
        ;
--
        IF ( lt_case_qty * lt_singly_qty >= 0 ) THEN
          -- ケース数とバラ数の符号が一致する場合、ロット別取引TEMPを1行で登録する。
          -- ロット別取引TEMP作成
          INSERT INTO xxcoi_lot_transactions_temp(
             transaction_id                                       -- 取引ID
            ,transaction_set_id                                   -- 取引セットID
            ,organization_id                                      -- 在庫組織ID
            ,parent_item_id                                       -- 親品目ID
            ,child_item_id                                        -- 子品目ID
            ,lot                                                  -- ロット
            ,difference_summary_code                              -- 固有記号
            ,transaction_type_code                                -- 取引タイプコード
            ,transaction_month                                    -- 取引年月
            ,transaction_date                                     -- 取引日
            ,slip_num                                             -- 伝票No
            ,case_in_qty                                          -- 入数
            ,case_qty                                             -- ケース数
            ,singly_qty                                           -- バラ数
            ,summary_qty                                          -- 取引数量
            ,transaction_uom                                      -- 基準単位
            ,primary_quantity                                     -- 基準単位数量
            ,base_code                                            -- 拠点コード
            ,subinventory_code                                    -- 保管場所コード
            ,location_code                                        -- ロケーションコード
            ,transfer_organization_id                             -- 転送先在庫組織ID
            ,transfer_subinventory                                -- 転送先保管場所コード
            ,transfer_location_code                               -- 転送先ロケーションコード
            ,sign_div                                             -- 符号区分
            ,source_code                                          -- ソースコード
            ,relation_key                                         -- 紐付けキー
            ,created_by                                           -- 作成者
            ,creation_date                                        -- 作成日
            ,last_updated_by                                      -- 最終更新者
            ,last_update_date                                     -- 最終更新日
            ,last_update_login                                    -- 最終更新ログイン
            ,request_id                                           -- 要求ID
            ,program_application_id                               -- コンカレント・プログラム・アプリケーションID
            ,program_id                                           -- コンカレント・プログラムID
            ,program_update_date                                  -- プログラム更新日
          )VALUES(
             lt_trx_id                                            -- 取引ID
            ,lt_trx_set_id                                        -- 取引セットID
            ,lt_org_id                                            -- 在庫組織ID
            ,lt_parent_item_id                                    -- 親品目ID
            ,lt_child_item_id                                     -- 子品目ID
            ,lt_lot                                               -- ロット
            ,lt_diff_sum_code                                     -- 固有記号
            ,lt_trx_type_code                                     -- 取引タイプコード
            ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- 取引年月
            ,lt_trx_date                                          -- 取引日
            ,lt_slip_num                                          -- 伝票No
            ,lt_case_in_qty                                       -- 入数
            ,lt_case_qty                                          -- ケース数
            ,lt_singly_qty                                        -- バラ数
            ,lt_summary_qty                                       -- 取引数量
            ,NULL                                                 -- 基準単位
            ,NULL                                                 -- 基準単位数量
            ,lt_base_code                                         -- 拠点コード
            ,lt_subinv_code                                       -- 保管場所コード
            ,lt_loc_code                                          -- ロケーションコード
            ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- 転送先在庫組織ID
            ,lt_tran_subinv_code                                  -- 転送先保管場所コード
            ,lt_tran_loc_code                                     -- 転送先ロケーションコード
            ,lt_sign_div                                          -- 符号区分
            ,lt_source_code                                       -- ソースコード
            ,lt_relation_key                                      -- 紐付けキー
            ,cn_created_by                                        -- 作成者
            ,cd_creation_date                                     -- 作成日
            ,cn_last_updated_by                                   -- 最終更新者
            ,cd_last_update_date                                  -- 最終更新日
            ,cn_last_update_login                                 -- 最終更新ログイン
            ,cn_request_id                                        -- 要求ID
            ,cn_program_application_id                            -- コンカレント・プログラム・アプリケーションID
            ,cn_program_id                                        -- コンカレント・プログラムID
            ,cd_program_update_date                               -- プログラム更新日
          );
        ELSE
          -- ケース数とバラ数の符号が異なる場合、ロット別取引TEMPを2行に分けて登録する。
          -- ロット別取引TEMP作成
          INSERT INTO xxcoi_lot_transactions_temp(
             transaction_id                                       -- 取引ID
            ,transaction_set_id                                   -- 取引セットID
            ,organization_id                                      -- 在庫組織ID
            ,parent_item_id                                       -- 親品目ID
            ,child_item_id                                        -- 子品目ID
            ,lot                                                  -- ロット
            ,difference_summary_code                              -- 固有記号
            ,transaction_type_code                                -- 取引タイプコード
            ,transaction_month                                    -- 取引年月
            ,transaction_date                                     -- 取引日
            ,slip_num                                             -- 伝票No
            ,case_in_qty                                          -- 入数
            ,case_qty                                             -- ケース数
            ,singly_qty                                           -- バラ数
            ,summary_qty                                          -- 取引数量
            ,transaction_uom                                      -- 基準単位
            ,primary_quantity                                     -- 基準単位数量
            ,base_code                                            -- 拠点コード
            ,subinventory_code                                    -- 保管場所コード
            ,location_code                                        -- ロケーションコード
            ,transfer_organization_id                             -- 転送先在庫組織ID
            ,transfer_subinventory                                -- 転送先保管場所コード
            ,transfer_location_code                               -- 転送先ロケーションコード
            ,sign_div                                             -- 符号区分
            ,source_code                                          -- ソースコード
            ,relation_key                                         -- 紐付けキー
            ,created_by                                           -- 作成者
            ,creation_date                                        -- 作成日
            ,last_updated_by                                      -- 最終更新者
            ,last_update_date                                     -- 最終更新日
            ,last_update_login                                    -- 最終更新ログイン
            ,request_id                                           -- 要求ID
            ,program_application_id                               -- コンカレント・プログラム・アプリケーションID
            ,program_id                                           -- コンカレント・プログラムID
            ,program_update_date                                  -- プログラム更新日
          )VALUES(
             lt_trx_id                                            -- 取引ID
            ,lt_trx_set_id                                        -- 取引セットID
            ,lt_org_id                                            -- 在庫組織ID
            ,lt_parent_item_id                                    -- 親品目ID
            ,lt_child_item_id                                     -- 子品目ID
            ,lt_lot                                               -- ロット
            ,lt_diff_sum_code                                     -- 固有記号
            ,lt_trx_type_code                                     -- 取引タイプコード
            ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- 取引年月
            ,lt_trx_date                                          -- 取引日
            ,lt_slip_num                                          -- 伝票No
            ,lt_case_in_qty                                       -- 入数
            ,lt_case_qty                                          -- ケース数
            ,0                                                    -- バラ数
            ,lt_case_in_qty * lt_case_qty                         -- 取引数量
            ,NULL                                                 -- 基準単位
            ,NULL                                                 -- 基準単位数量
            ,lt_base_code                                         -- 拠点コード
            ,lt_subinv_code                                       -- 保管場所コード
            ,lt_loc_code                                          -- ロケーションコード
            ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- 転送先在庫組織ID
            ,lt_tran_subinv_code                                  -- 転送先保管場所コード
            ,lt_tran_loc_code                                     -- 転送先ロケーションコード
            ,lt_sign_div                                          -- 符号区分
            ,lt_source_code                                       -- ソースコード
            ,lt_relation_key                                      -- 紐付けキー
            ,cn_created_by                                        -- 作成者
            ,cd_creation_date                                     -- 作成日
            ,cn_last_updated_by                                   -- 最終更新者
            ,cd_last_update_date                                  -- 最終更新日
            ,cn_last_update_login                                 -- 最終更新ログイン
            ,cn_request_id                                        -- 要求ID
            ,cn_program_application_id                            -- コンカレント・プログラム・アプリケーションID
            ,cn_program_id                                        -- コンカレント・プログラムID
            ,cd_program_update_date                               -- プログラム更新日
          );
--
          -- シーケンス値取得
          SELECT xxcoi_lot_trx_temp_s01.NEXTVAL
          INTO   lt_trx_id
          FROM   DUAL
          ;
--
          -- ロット別取引TEMP作成
          INSERT INTO xxcoi_lot_transactions_temp(
             transaction_id                                       -- 取引ID
            ,transaction_set_id                                   -- 取引セットID
            ,organization_id                                      -- 在庫組織ID
            ,parent_item_id                                       -- 親品目ID
            ,child_item_id                                        -- 子品目ID
            ,lot                                                  -- ロット
            ,difference_summary_code                              -- 固有記号
            ,transaction_type_code                                -- 取引タイプコード
            ,transaction_month                                    -- 取引年月
            ,transaction_date                                     -- 取引日
            ,slip_num                                             -- 伝票No
            ,case_in_qty                                          -- 入数
            ,case_qty                                             -- ケース数
            ,singly_qty                                           -- バラ数
            ,summary_qty                                          -- 取引数量
            ,transaction_uom                                      -- 基準単位
            ,primary_quantity                                     -- 基準単位数量
            ,base_code                                            -- 拠点コード
            ,subinventory_code                                    -- 保管場所コード
            ,location_code                                        -- ロケーションコード
            ,transfer_organization_id                             -- 転送先在庫組織ID
            ,transfer_subinventory                                -- 転送先保管場所コード
            ,transfer_location_code                               -- 転送先ロケーションコード
            ,sign_div                                             -- 符号区分
            ,source_code                                          -- ソースコード
            ,relation_key                                         -- 紐付けキー
            ,created_by                                           -- 作成者
            ,creation_date                                        -- 作成日
            ,last_updated_by                                      -- 最終更新者
            ,last_update_date                                     -- 最終更新日
            ,last_update_login                                    -- 最終更新ログイン
            ,request_id                                           -- 要求ID
            ,program_application_id                               -- コンカレント・プログラム・アプリケーションID
            ,program_id                                           -- コンカレント・プログラムID
            ,program_update_date                                  -- プログラム更新日
          )VALUES(
             lt_trx_id                                            -- 取引ID
            ,lt_trx_set_id                                        -- 取引セットID
            ,lt_org_id                                            -- 在庫組織ID
            ,lt_parent_item_id                                    -- 親品目ID
            ,lt_child_item_id                                     -- 子品目ID
            ,lt_lot                                               -- ロット
            ,lt_diff_sum_code                                     -- 固有記号
            ,lt_trx_type_code                                     -- 取引タイプコード
            ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- 取引年月
            ,lt_trx_date                                          -- 取引日
            ,lt_slip_num                                          -- 伝票No
            ,lt_case_in_qty                                       -- 入数
            ,0                                                    -- ケース数
            ,lt_singly_qty                                        -- バラ数
            ,lt_singly_qty                                        -- 取引数量
            ,NULL                                                 -- 基準単位
            ,NULL                                                 -- 基準単位数量
            ,lt_base_code                                         -- 拠点コード
            ,lt_subinv_code                                       -- 保管場所コード
            ,lt_loc_code                                          -- ロケーションコード
            ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- 転送先在庫組織ID
            ,lt_tran_subinv_code                                  -- 転送先保管場所コード
            ,lt_tran_loc_code                                     -- 転送先ロケーションコード
            ,lt_sign_div                                          -- 符号区分
            ,lt_source_code                                       -- ソースコード
            ,lt_relation_key                                      -- 紐付けキー
            ,cn_created_by                                        -- 作成者
            ,cd_creation_date                                     -- 作成日
            ,cn_last_updated_by                                   -- 最終更新者
            ,cd_last_update_date                                  -- 最終更新日
            ,cn_last_update_login                                 -- 最終更新ログイン
            ,cn_request_id                                        -- 要求ID
            ,cn_program_application_id                            -- コンカレント・プログラム・アプリケーションID
            ,cn_program_id                                        -- コンカレント・プログラムID
            ,cd_program_update_date                               -- プログラム更新日
          );
      END IF;
--
    END;
--
    -- OUTパラメータに取得した取引IDを設定
    on_trx_id := lt_trx_id;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END cre_lot_trx_temp;
--
/************************************************************************
 * Procedure Name  : DEL_LOT_TRX_TEMP
 * Description     : ロット別取引TEMP削除
 ************************************************************************/
  PROCEDURE del_lot_trx_temp(
    in_trx_id  IN  NUMBER          -- ロット別TEMP取引ID
   ,ov_errbuf  OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg  OUT VARCHAR2        -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'del_lot_trx_temp'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_10477 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10477'; -- 共通関数パラメータ必須エラー
    cv_msg_xxcoi1_10494     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10494'; -- プロシージャ名：ロット別取引TEMP削除
    cv_msg_xxcoi1_10506     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10506'; -- 取引ID
--
    cv_msg_tkn_param1       CONSTANT VARCHAR2(20)  := 'PARAM1';           -- トークン：パラメータ１
    cv_msg_tkn_param2       CONSTANT VARCHAR2(20)  := 'PARAM2';           -- トークン：パラメータ２
-- 
    -- *** ローカル変数 ***
    -- 入力パラメータ格納用変数
    lt_trx_id          xxcoi_lot_transactions_temp.transaction_id%TYPE; -- 取引ID
--
    -- メッセージ格納用変数
    lv_msg_proc_name VARCHAR2(100); -- プロシージャ名
    lv_msg_chk_tkn   VARCHAR2(100); -- 入力パラメータエラートークン格納用変数
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ローカル変数初期化
--
    -- 入力パラメータ格納用変数
    lt_trx_id        := NULL; -- 取引ID
--
    -- メッセージ格納用変数
    lv_msg_proc_name := NULL; -- プロシージャ名
    lv_msg_chk_tkn   := NULL; -- 入力パラメータエラートークン格納用変数
--
    -- プロシージャ名取得
    lv_msg_proc_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10494
                        );
--
--
    -- ======================================
    -- １：入力パラメータのチェック
    -- ======================================
    -- 取引ID
    IF ( in_trx_id IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10506
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータを変数に退避
    lt_trx_id := in_trx_id; -- 取引ID
--
    -- ======================================
    -- ２：ロット別取引TEMP削除
    -- ======================================
    DELETE 
    FROM   xxcoi_lot_transactions_temp xltt
    WHERE  transaction_id = lt_trx_id      -- 取引ID
    ;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END del_lot_trx_temp;
--
/************************************************************************
 * Procedure Name  : CRE_LOT_TRX
 * Description     : ロット別取引明細作成
 ************************************************************************/
  PROCEDURE cre_lot_trx(
    in_trx_set_id            IN  NUMBER   -- 取引セットID
   ,iv_parent_item_code      IN  VARCHAR2 -- 親品目コード
   ,iv_child_item_code       IN  VARCHAR2 -- 子品目コード
   ,iv_lot                   IN  VARCHAR2 -- ロット(賞味期限)
   ,iv_diff_sum_code         IN  VARCHAR2 -- 固有記号
   ,iv_trx_type_code         IN  VARCHAR2 -- 取引タイプコード
   ,id_trx_date              IN  DATE     -- 取引日
   ,iv_slip_num              IN  VARCHAR2 -- 伝票No
   ,in_case_in_qty           IN  NUMBER   -- 入数
   ,in_case_qty              IN  NUMBER   -- ケース数
   ,in_singly_qty            IN  NUMBER   -- バラ数
   ,in_summary_qty           IN  NUMBER   -- 取引数量
   ,iv_base_code             IN  VARCHAR2 -- 拠点コード
   ,iv_subinv_code           IN  VARCHAR2 -- 保管場所コード
   ,iv_loc_code              IN  VARCHAR2 -- ロケーションコード
   ,iv_tran_subinv_code      IN  VARCHAR2 -- 転送先保管場所コード
   ,iv_tran_loc_code         IN  VARCHAR2 -- 転送先ロケーションコード
   ,iv_source_code           IN  VARCHAR2 -- ソースコード
   ,iv_relation_key          IN  VARCHAR2 -- 紐付けキー
   ,iv_reason                IN  VARCHAR2 -- 事由
   ,iv_reserve_trx_type_code IN  VARCHAR2 -- 引当時取引タイプコード
   ,on_trx_id                OUT NUMBER   -- ロット別取引明細
   ,ov_errbuf                OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2 -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'cre_lot_trx'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_10477 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10477'; -- 共通関数パラメータ必須エラー
    cv_err_msg_xxcoi1_10478 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10478'; -- ケース数・バラ数符号チェックエラー
    cv_err_msg_xxcoi1_10479 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10479'; -- 取引数量チェックエラー
    cv_err_msg_xxcoi1_00005 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
    cv_err_msg_xxcoi1_00006 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
    cv_err_msg_xxcoi1_10480 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10480'; -- 品目ID取得エラー
    cv_err_msg_xxcoi1_10482 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10482'; -- 品目情報取得エラー
    cv_err_msg_xxcoi1_10483 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10483'; -- 換算後数量取得エラー
    cv_err_msg_xxcoi1_10484 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10484'; -- 従業員情報取得エラー
    cv_err_msg_xxcoi1_10507 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10507'; -- 入数0以下エラー
    cv_err_msg_xxcoi1_00011 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付未取得エラー
--
    cv_msg_xxcoi1_10495     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10495'; -- プロシージャ：ロット別取引明細作成
    cv_msg_xxcoi1_10496     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10496'; -- 親品目コード
    cv_msg_xxcoi1_10497     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10497'; -- 取引タイプコード
    cv_msg_xxcoi1_10498     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10498'; -- 取引日
    cv_msg_xxcoi1_10500     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10500'; -- 入数
    cv_msg_xxcoi1_10501     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10501'; -- 取引数量
    cv_msg_xxcoi1_10502     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10502'; -- 拠点コード
    cv_msg_xxcoi1_10503     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10503'; -- 保管場所コード
    cv_msg_xxcoi1_10504     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10504'; -- ソースコード
--
    cv_msg_tkn_param1       CONSTANT VARCHAR2(20)  := 'PARAM1';           -- トークン：パラメータ１
    cv_msg_tkn_param2       CONSTANT VARCHAR2(20)  := 'PARAM2';           -- トークン：パラメータ２
    cv_msg_tkn_pro_tok      CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- トークン：プロファイル名
    cv_msg_tkn_org_code_tok CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- トークン：在庫組織コード
    cv_msg_tkn_item_code    CONSTANT VARCHAR2(20)  := 'ITEM_CODE';        -- トークン：品目コード
    cv_msg_tkn_err_msg      CONSTANT VARCHAR2(20)  := 'ERR_MSG';          -- トークン：エラーメッセージ
    cv_msg_tkn_uom_code     CONSTANT VARCHAR2(20)  := 'UOM_CODE';         -- トークン：換算前単位
--
    -- プロファイル名
    cv_xxcoi1_organization_code CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- プロファイル：在庫組織コード
--
    -- *** ローカル変数 ***
    -- 入力パラメータ格納用変数
    lt_trx_set_id            xxcoi_lot_transactions.transaction_set_id%TYPE;            -- 取引セットID
    lt_parent_item_code      mtl_system_items_b.segment1%TYPE;                          -- 親品目コード
    lt_child_item_code       mtl_system_items_b.segment1%TYPE;                          -- 子品目コード
    lt_lot                   xxcoi_lot_transactions.lot%TYPE;                           -- ロット(賞味期限)
    lt_diff_sum_code         xxcoi_lot_transactions.difference_summary_code%TYPE;       -- 固有記号
    lt_trx_type_code         xxcoi_lot_transactions.transaction_type_code%TYPE;         -- 取引タイプコード
    lt_trx_date              xxcoi_lot_transactions.transaction_date%TYPE;              -- 取引日
    lt_slip_num              xxcoi_lot_transactions.slip_num%TYPE;                      -- 伝票No
    lt_case_in_qty           xxcoi_lot_transactions.case_in_qty%TYPE;                   -- 入数
    lt_case_qty              xxcoi_lot_transactions.case_qty%TYPE;                      -- ケース数
    lt_singly_qty            xxcoi_lot_transactions.singly_qty%TYPE;                    -- バラ数
    lt_summary_qty           xxcoi_lot_transactions.summary_qty%TYPE;                   -- 取引数量
    lt_base_code             xxcoi_lot_transactions.base_code%TYPE;                     -- 拠点コード
    lt_subinv_code           xxcoi_lot_transactions.subinventory_code%TYPE;             -- 保管場所コード
    lt_loc_code              xxcoi_lot_transactions.location_code%TYPE;                 -- ロケーションコード
    lt_tran_subinv_code      xxcoi_lot_transactions.transfer_subinventory%TYPE;         -- 転送先保管場所コード
    lt_tran_loc_code         xxcoi_lot_transactions.transfer_location_code%TYPE;        -- 転送先ロケーションコード
    lt_source_code           xxcoi_lot_transactions.source_code%TYPE;                   -- ソースコード
    lt_relation_key          xxcoi_lot_transactions.relation_key%TYPE;                  -- 紐付けキー
    lt_reason                xxcoi_lot_transactions.reason%TYPE;                        -- 事由
    lt_reserve_trx_type_code xxcoi_lot_transactions.reserve_transaction_type_code%TYPE; -- 引当時取引タイプコード
--
    -- ID変換、導出項目
    ld_proc_date       DATE;                                       -- 業務日付
    lt_org_code        mtl_parameters.organization_code%TYPE;      -- 在庫組織コード
    lt_org_id          mtl_parameters.organization_id%TYPE;        -- 在庫組織ID
    lt_parent_item_id  xxcoi_lot_transactions.parent_item_id%TYPE; -- 親品目ID
    lt_trx_id          xxcoi_lot_transactions.transaction_id%TYPE; -- 取引ID
    lt_fix_user_code   xxcoi_lot_transactions.fix_user_code%TYPE;  -- 確定者コード
    lt_fix_user_name   xxcoi_lot_transactions.fix_user_name%TYPE;  -- 確定者名
--
    -- 共通関数取得項目
    -- 在庫共通関数「品目情報取得2」
    lt_item_status        mtl_system_items_b.inventory_item_status_code%TYPE;    -- 品目ステータス
    lt_cust_order_flg     mtl_system_items_b.customer_order_enabled_flag%TYPE;   -- 顧客受注可能フラグ
    lt_transaction_enable mtl_system_items_b.mtl_transactions_enabled_flag%TYPE; -- 取引可能
    lt_stock_enabled_flg  mtl_system_items_b.stock_enabled_flag%TYPE;            -- 在庫保有可能フラグ
    lt_return_enable      mtl_system_items_b.returnable_flag%TYPE;               -- 返品可能
    lt_sales_class        ic_item_mst_b.attribute26%TYPE;                        -- 売上対象区分
    lt_primary_unit       mtl_system_items_b.primary_unit_of_measure%TYPE;       -- 基準単位
    lt_child_item_id      xxcoi_lot_transactions.child_item_id%TYPE;             -- 子品目ID
    lt_primary_uom_code   mtl_system_items_b.primary_uom_code%TYPE;              -- 基準単位コード
--
    -- 販売共通関数「単位換算取得」
    lt_after_quantity xxcoi_lot_transactions.primary_quantity%TYPE; -- 換算後数量
    ln_content        NUMBER;                                       -- 入数
--
    -- メッセージ格納用変数
    lv_msg_proc_name VARCHAR2(100); -- プロシージャ名
    lv_msg_chk_tkn   VARCHAR2(100); -- 入力パラメータエラートークン格納用変数
--
    -- その他
    ln_trx_num_chk NUMBER; -- 取引数量チェック用変数
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    -- 入力パラメータ格納用変数
    lt_trx_set_id            := NULL; -- 取引セットID
    lt_parent_item_code      := NULL; -- 親品目コード
    lt_child_item_code       := NULL; -- 子品目コード
    lt_lot                   := NULL; -- ロット(賞味期限)
    lt_diff_sum_code         := NULL; -- 固有記号
    lt_trx_type_code         := NULL; -- 取引タイプコード
    lt_trx_date              := NULL; -- 取引日
    lt_slip_num              := NULL; -- 伝票No
    lt_case_in_qty           := NULL; -- 入数
    lt_case_qty              := NULL; -- ケース数
    lt_singly_qty            := NULL; -- バラ数
    lt_summary_qty           := NULL; -- 取引数量
    lt_base_code             := NULL; -- 拠点コード
    lt_subinv_code           := NULL; -- 保管場所コード
    lt_loc_code              := NULL; -- ロケーションコード
    lt_tran_subinv_code      := NULL; -- 転送先保管場所コード
    lt_tran_loc_code         := NULL; -- 転送先ロケーションコード
    lt_source_code           := NULL; -- ソースコード
    lt_relation_key          := NULL; -- 紐付けキー
    lt_reason                := NULL; -- 事由
    lt_reserve_trx_type_code := NULL; -- 引当時取引タイプコード
--
    -- ID変換、導出項目
    ld_proc_date             := NULL; -- 業務日付
    lt_org_code              := NULL; -- 在庫組織コード
    lt_org_id                := NULL; -- 在庫組織ID
    lt_parent_item_id        := NULL; -- 親品目ID
    lt_trx_id                := NULL; -- 取引ID
    lt_fix_user_code         := NULL; -- 確定者コード
    lt_fix_user_name         := NULL; -- 確定者名
--
    -- 共通関数取得項目
    -- 在庫共通関数「品目情報取得2」
    lt_item_status           := NULL; -- 品目ステータス
    lt_cust_order_flg        := NULL; -- 顧客受注可能フラグ
    lt_transaction_enable    := NULL; -- 取引可能
    lt_stock_enabled_flg     := NULL; -- 在庫保有可能フラグ
    lt_return_enable         := NULL; -- 返品可能
    lt_sales_class           := NULL; -- 売上対象区分
    lt_primary_unit          := NULL; -- 基準単位
    lt_child_item_id         := NULL; -- 子品目ID
    lt_primary_uom_code      := NULL; -- 基準単位コード
--
    -- 販売共通関数「単位換算取得」
    lt_after_quantity        := NULL; -- 換算後数量
    ln_content               := NULL; -- 入数
--
    -- その他
    ln_trx_num_chk           := NULL; -- 取引数量チェック用変数
--
    -- プロシージャ名取得
    lv_msg_proc_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10495
                        );
--
    -- ======================================
    -- １：入力パラメータのチェック
    -- ======================================
    -- 親品目コード
    IF ( iv_parent_item_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10496
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取引タイプコード
    IF ( iv_trx_type_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10497
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取引日
    IF ( id_trx_date IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10498
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入数
    IF ( in_case_in_qty IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10500
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取引数量
    IF ( in_summary_qty IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10501
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 拠点コード
    IF ( iv_base_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10502
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 保管場所コード
    IF ( iv_subinv_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10503
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ソースコード
    IF ( iv_source_code IS NULL ) THEN
      -- トークン設定値取得
      lv_msg_chk_tkn := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_msg_xxcoi1_10504
                        );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10477
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => lv_msg_proc_name
                     ,iv_token_name2  => cv_msg_tkn_param2
                     ,iv_token_value2 => lv_msg_chk_tkn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- INパラメータを変数に退避
    lt_trx_set_id            := in_trx_set_id;             -- 取引セットID
    lt_parent_item_code      := iv_parent_item_code;       -- 親品目コード
    lt_child_item_code       := iv_child_item_code;        -- 子品目コード
    lt_lot                   := iv_lot;                    -- ロット(賞味期限)
    lt_diff_sum_code         := iv_diff_sum_code;          -- 固有記号
    lt_trx_type_code         := iv_trx_type_code;          -- 取引タイプコード
    lt_trx_date              := id_trx_date;               -- 取引日
    lt_slip_num              := iv_slip_num;               -- 伝票No
    lt_case_in_qty           := in_case_in_qty;            -- 入数
    lt_case_qty              := in_case_qty;               -- ケース数
    lt_singly_qty            := in_singly_qty;             -- バラ数
    lt_summary_qty           := in_summary_qty;            -- 取引数量
    lt_base_code             := iv_base_code;              -- 拠点コード
    lt_subinv_code           := iv_subinv_code;            -- 保管場所コード
    lt_loc_code              := iv_loc_code;               -- ロケーションコード
    lt_tran_subinv_code      := iv_tran_subinv_code;       -- 転送先保管場所コード
    lt_tran_loc_code         := iv_tran_loc_code;          -- 転送先ロケーションコード
    lt_source_code           := iv_source_code;            -- ソースコード
    lt_relation_key          := iv_relation_key;           -- 紐付けキー
    lt_reason                := iv_reason;                 -- 事由
    lt_reserve_trx_type_code := iv_reserve_trx_type_code ; -- 引当時取引タイプコード
--
    -- 入数、ケース数、バラ数、取引数量の検証
    -- ケース数がNULLの場合は0を設定
    IF ( lt_case_qty IS NULL ) THEN
      lt_case_qty := 0;
    END IF;
--
    -- バラ数がNULLの場合は0を設定
    IF ( lt_singly_qty IS NULL ) THEN
      lt_singly_qty := 0;
    END IF;
--
    -- 入数が0以下の場合は、エラー
    IF ( lt_case_in_qty <= 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10507
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ケース数、バラ数の符号チェック
    -- 符号が異なる場合はエラー
    IF ( ( lt_case_qty >= 0 AND lt_singly_qty >= 0 ) OR ( lt_case_qty <= 0 AND lt_singly_qty <= 0 ) ) THEN
      NULL;
    ELSE
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10478
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (入数＊ケース数)＋バラ数が取引数量と異なる場合はエラー
    ln_trx_num_chk := (lt_case_in_qty * lt_case_qty) + lt_singly_qty;
    IF ( lt_summary_qty <> ln_trx_num_chk ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10479
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- WHOカラム取得
    -- 固定グローバル変数を使用するため割愛
--
    -- プロファイル「XXCOI:在庫組織コード」を取得
    -- 取得できない場合はエラー
    lt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00005
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_xxcoi1_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 業務日付取得
    -- 取得できない場合は、エラー
    ld_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( ld_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00011
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- ２：ID変換、取得
    -- ======================================
    -- 共通関数を使用し、在庫組織IDを取得
    -- 取得できない場合はエラー
    lt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => lt_org_code
                 );
    IF ( lt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00006
                     ,iv_token_name1  => cv_msg_tkn_org_code_tok
                     ,iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 親品目ID取得
    -- 取得できない場合はエラー
    BEGIN
      SELECT msib.inventory_item_id inventory_item_id
      INTO   lt_parent_item_id
      FROM   mtl_system_items_b msib                    -- Disc品目マスタ
      WHERE  msib.segment1        = lt_parent_item_code -- 親品目コード
      AND    msib.organization_id = lt_org_id           -- 在庫組織ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10480
                       ,iv_token_name1  => cv_msg_tkn_org_code_tok
                       ,iv_token_value1 => lt_org_code
                       ,iv_token_name2  => cv_msg_tkn_item_code
                       ,iv_token_value2 => lt_parent_item_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 子品目ID取得
    -- NULLの場合は処理を行わない
    IF ( lt_child_item_code IS NULL ) THEN
      NULL;
    ELSE
      -- 子品目の品目情報を取得
      -- 在庫共通関数「品目情報取得2」
      xxcoi_common_pkg.get_item_info2(
        ov_errbuf               => lv_errbuf             -- エラーメッセージ
       ,ov_retcode              => lv_retcode            -- リターン・コード
       ,ov_errmsg               => lv_errmsg             -- ユーザー・エラーメッセージ
       ,iv_item_code            => lt_child_item_code    -- INパラメータ.子品目コード
       ,in_org_id               => lt_org_id             -- 在庫組織ID
       ,ov_item_status          => lt_item_status        -- ※使用しない_品目ステータス
       ,ov_cust_order_flg       => lt_cust_order_flg     -- ※使用しない_顧客受注可能フラグ
       ,ov_transaction_enable   => lt_transaction_enable -- ※使用しない_取引可能
       ,ov_stock_enabled_flg    => lt_stock_enabled_flg  -- ※使用しない_在庫保有可能フラグ
       ,ov_return_enable        => lt_return_enable      -- ※使用しない_返品可能
       ,ov_sales_class          => lt_sales_class        -- ※使用しない_売上対象区分
       ,ov_primary_unit         => lt_primary_unit       -- ※使用しない_基準単位
       ,on_inventory_item_id    => lt_child_item_id      -- 子品目ID
       ,ov_primary_uom_code     => lt_primary_uom_code   -- 基準単位コード
      );
      -- リターンコードが正常以外の場合、エラー
      IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10482
                         ,iv_token_name1  => cv_msg_tkn_org_code_tok
                         ,iv_token_value1 => lt_org_code
                         ,iv_token_name2  => cv_msg_tkn_item_code
                         ,iv_token_value2 => lt_child_item_code
                         ,iv_token_name3  => cv_msg_tkn_err_msg
                         ,iv_token_value3 => lv_errmsg
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END IF;
--
      -- 基準単位数量を取得
      -- 販売共通関数「単位換算取得」
      xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => lt_primary_uom_code -- 換算前単位コード
       ,in_before_quantity    => lt_summary_qty      -- 換算前数量
       ,iov_item_code         => lt_child_item_code  -- 品目コード
       ,iov_organization_code => lt_org_code         -- 在庫組織コード
       ,ion_inventory_item_id => lt_child_item_id    -- 品目ＩＤ
       ,ion_organization_id   => lt_org_id           -- 在庫組織ＩＤ
       ,iov_after_uom_code    => lt_primary_uom_code -- 換算後単位コード
       ,on_after_quantity     => lt_after_quantity   -- 換算後数量
       ,on_content            => ln_content          -- 入数
       ,ov_errbuf             => lv_errbuf           -- エラー・メッセージエラー
       ,ov_retcode            => lv_retcode          -- リターン・コード
       ,ov_errmsg             => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- リターンコードが正常以外の場合、エラー
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10483
                         ,iv_token_name1  => cv_msg_tkn_org_code_tok
                         ,iv_token_value1 => lt_org_code
                         ,iv_token_name2  => cv_msg_tkn_item_code
                         ,iv_token_value2 => lt_child_item_code
                         ,iv_token_name3  => cv_msg_tkn_uom_code
                         ,iv_token_value3 => lt_primary_uom_code
                         ,iv_token_name4  => cv_msg_tkn_err_msg
                         ,iv_token_value4 => lv_errmsg
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- 従業員情報の取得
    BEGIN
      SELECT papf.employee_number                                     emp_code -- 従業員コード
            ,papf.per_information18 || ' ' || papf.per_information19  emp_name -- 従業員名
      INTO   lt_fix_user_code                                                  -- 確定者コード
            ,lt_fix_user_name                                                  -- 確定者名
      FROM   fnd_user fu                                                       -- ユーザマスタ
            ,per_all_people_f papf                                             -- 従業員マスタ
      WHERE  fu.user_id     = cn_created_by                                    -- ユーザID
      AND    fu.employee_id = papf.person_id
      AND    ld_proc_date BETWEEN papf.effective_start_date
                          AND     papf.effective_end_date                      -- 有効日付チェック
      ;
--
    EXCEPTION
      -- 取得できなかった場合は、エラー
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_err_msg_xxcoi1_10484
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- シーケンス値取得
    SELECT xxcoi_lot_transactions_s01.NEXTVAL
    INTO   lt_trx_id
    FROM   DUAL
    ;
--
    -- ロット別取引明細作成
    INSERT INTO xxcoi_lot_transactions(
      transaction_id                                       -- 取引ID
     ,transaction_set_id                                   -- 取引セットID
     ,organization_id                                      -- 在庫組織ID
     ,parent_item_id                                       -- 親品目ID
     ,child_item_id                                        -- 子品目ID
     ,lot                                                  -- ロット
     ,difference_summary_code                              -- 固有記号
     ,transaction_type_code                                -- 取引タイプコード
     ,transaction_month                                    -- 取引年月
     ,transaction_date                                     -- 取引日
     ,slip_num                                             -- 伝票No
     ,case_in_qty                                          -- 入数
     ,case_qty                                             -- ケース数
     ,singly_qty                                           -- バラ数
     ,summary_qty                                          -- 取引数量
     ,transaction_uom                                      -- 基準単位
     ,primary_quantity                                     -- 基準単位数量
     ,base_code                                            -- 拠点コード
     ,subinventory_code                                    -- 保管場所コード
     ,location_code                                        -- ロケーションコード
     ,transfer_organization_id                             -- 転送先在庫組織ID
     ,transfer_subinventory                                -- 転送先保管場所コード
     ,transfer_location_code                               -- 転送先ロケーションコード
     ,source_code                                          -- ソースコード
     ,relation_key                                         -- 紐付けキー
     ,reserve_transaction_type_code                        -- 引当時取引タイプコード
     ,reason                                               -- 事由
     ,fix_user_code                                        -- 確定者コード
     ,fix_user_name                                        -- 確定者名
     ,created_by                                           -- 作成者
     ,creation_date                                        -- 作成日
     ,last_updated_by                                      -- 最終更新者
     ,last_update_date                                     -- 最終更新日
     ,last_update_login                                    -- 最終更新ログイン
     ,request_id                                           -- 要求ID
     ,program_application_id                               -- コンカレント・プログラム・アプリケーションID
     ,program_id                                           -- コンカレント・プログラムID
     ,program_update_date                                  -- プログラム更新日
    )VALUES(
      lt_trx_id                                            -- 取引ID
     ,lt_trx_set_id                                        -- 取引セットID
     ,lt_org_id                                            -- 在庫組織ID
     ,lt_parent_item_id                                    -- 親品目ID
     ,lt_child_item_id                                     -- 子品目ID
     ,lt_lot                                               -- ロット
     ,lt_diff_sum_code                                     -- 固有記号
     ,lt_trx_type_code                                     -- 取引タイプコード
     ,TO_CHAR( lt_trx_date, 'YYYYMM' )                     -- 取引年月
     ,lt_trx_date                                          -- 取引日
     ,lt_slip_num                                          -- 伝票No
     ,lt_case_in_qty                                       -- 入数
     ,lt_case_qty                                          -- ケース数
     ,lt_singly_qty                                        -- バラ数
     ,lt_summary_qty                                       -- 取引数量
     ,lt_primary_uom_code                                  -- 基準単位
     ,lt_after_quantity                                    -- 基準単位数量
     ,lt_base_code                                         -- 拠点コード
     ,lt_subinv_code                                       -- 保管場所コード
     ,lt_loc_code                                          -- ロケーションコード
     ,DECODE( lt_tran_subinv_code, NULL, NULL, lt_org_id ) -- 転送先在庫組織ID
     ,lt_tran_subinv_code                                  -- 転送先保管場所コード
     ,lt_tran_loc_code                                     -- 転送先ロケーションコード
     ,lt_source_code                                       -- ソースコード
     ,lt_relation_key                                      -- 紐付けキー
     ,lt_reserve_trx_type_code                             -- 引当時取引タイプコード
     ,lt_reason                                            -- 事由
     ,lt_fix_user_code                                     -- 確定者コード
     ,lt_fix_user_name                                     -- 確定者名
     ,cn_created_by                                        -- 作成者
     ,cd_creation_date                                     -- 作成日
     ,cn_last_updated_by                                   -- 最終更新者
     ,cd_last_update_date                                  -- 最終更新日
     ,cn_last_update_login                                 -- 最終更新ログイン
     ,cn_request_id                                        -- 要求ID
     ,cn_program_application_id                            -- コンカレント・プログラム・アプリケーションID
     ,cn_program_id                                        -- コンカレント・プログラムID
     ,cd_program_update_date                               -- プログラム更新日
    );
--
    -- OUTパラメータ設定
    on_trx_id := lt_trx_id;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END cre_lot_trx;
--
/************************************************************************
 * Function Name   : GET_CUSTOMER_ID
 * Description     : 顧客導出（受注アドオン）
 ************************************************************************/
--
  FUNCTION get_customer_id(
    in_deliver_to_id IN NUMBER -- 出荷先ID
  ) RETURN NUMBER 
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_status_a           CONSTANT hz_cust_accounts.status%TYPE              := 'A';  -- 顧客ステータス_有効
    ct_cust_class_code_10 CONSTANT hz_cust_accounts.customer_class_code%TYPE := '10'; -- 顧客区分_顧客
--
    -- *** ローカル変数 ***
    lt_cust_acct_id  hz_cust_accounts.cust_account_id%TYPE; -- 顧客ID(出力値)
    lt_party_site_id hz_party_sites.party_site_id%TYPE;     -- パーティサイトID（入力値）
--
  BEGIN
--
    -- ===============================
    -- 1.初期処理
    -- ===============================
    -- 変数初期化
    lt_cust_acct_id  := NULL;
    lt_party_site_id := NULL;
--
    -- NULLの場合は、後続処理を実施しない
    IF ( in_deliver_to_id IS NULL ) THEN 
      NULL;
    ELSE
      -- INパラメータ退避
      lt_party_site_id := in_deliver_to_id; -- パーティサイトID
--
      -- ===============================
      -- 2.顧客ID取得
      -- ===============================
      BEGIN
        SELECT hca.cust_account_id cust_account_id             -- 顧客ID
        INTO   lt_cust_acct_id
        FROM   hz_cust_accounts hca                            -- 顧客マスタ
              ,hz_parties       hp                             -- パーティマスタ
              ,hz_party_sites   hps                            -- パーティサイトマスタ
        WHERE  hps.party_site_id       = lt_party_site_id      -- パーティサイトID
        AND    hps.party_id            = hp.party_id
        AND    hp.party_id             = hca.party_id
        AND    hca.status              = ct_status_a           -- ステータス
        AND    hca.customer_class_code = ct_cust_class_code_10 -- 顧客区分
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
--
    -- ===============================
    -- 3.戻り値設定
    -- ===============================
    RETURN lt_cust_acct_id;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_customer_id;
--
/************************************************************************
 * Procedure Name  : GET_PARENT_CHILD_ITEM_INFO
 * Description     : 品目コード導出（親／子）
 ************************************************************************/
  PROCEDURE get_parent_child_item_info(
    id_date           IN  DATE            -- 日付
   ,in_inv_org_id     IN  NUMBER          -- 在庫組織ID
   ,in_parent_item_id IN  NUMBER          -- 親品目ID
   ,in_child_item_id  IN  NUMBER          -- 子品目ID
   ,ot_item_info_tab  OUT item_info_ttype -- 品目情報（テーブル型）
   ,ov_errbuf         OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2        -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_parent_child_item_info'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_10492   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10492'; -- 品目（親／子）入力パラメータエラー
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00024'; -- 入力パラメータ未設定エラー
    cv_err_msg_xxcoi1_00032   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00032'; -- プロファイル取得エラー
    cv_err_msg_xxcoi1_10513   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10513'; -- 日付
    cv_err_msg_xxcoi1_10514   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10514'; -- 在庫組織ID
    cv_err_msg_xxcoi1_10520   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10520'; -- 品目（親／子）取得エラー
    cv_msg_tkn_param1         CONSTANT VARCHAR2(20)  := 'PARAM1';           -- トークン：パラメータ１
    cv_msg_tkn_param2         CONSTANT VARCHAR2(20)  := 'PARAM2';           -- トークン：パラメータ２
    cv_msg_tkn_item_id        CONSTANT VARCHAR2(20)  := 'ITEM_ID';          -- トークン：品目ID
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(20)  := 'IN_PARAM_NAME';    -- トークン：入力パラメータ
    cv_msg_tkn_pro_tok        CONSTANT VARCHAR2(30)  := 'PRO_TOK';          -- トークン：プロファイル
    cv_item_div_h             CONSTANT VARCHAR2(30)  := 'XXCOS1_ITEM_DIV_H';-- プロファイル名：XXCOS:本社商品区分
--
    -- *** ローカル変数 ***
    lv_cstegory_set_name      VARCHAR2(100);   -- カテゴリセット名
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ======================================
    -- １：初期処理
    -- ======================================
    -- 在庫組織IDがNULLの場合
    IF ( in_inv_org_id IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10514 -- 在庫組織ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 日付がNULLの場合
    IF ( id_date IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10513 -- 日付
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 親品目ID、子品目IDがどちらもNULL、またはどちらもNOT NULLの場合はエラー
    IF ((in_parent_item_id IS NULL 
      AND  in_child_item_id IS NULL)
    OR (in_parent_item_id IS NOT NULL
       AND  in_child_item_id IS NOT NULL))
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10492
                    ,iv_token_name1  => cv_msg_tkn_param1
                    ,iv_token_value1 => in_parent_item_id -- 親品目ID
                    ,iv_token_name2  => cv_msg_tkn_param2
                    ,iv_token_value2 => in_child_item_id  -- 子品目ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- プロファイル「本社商品区分」取得
    lv_cstegory_set_name := FND_PROFILE.VALUE( cv_item_div_h );
    IF ( lv_cstegory_set_name IS NULL ) THEN
      -- エラーメッセージ
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00032
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_item_div_h
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- ２：子品目情報取得
    -- ======================================
    -- INパラメータ.親品目IDがNOT NULLの場合、子品目情報を取得
    IF ( in_parent_item_id IS NOT NULL ) THEN
      SELECT msib2.inventory_item_id item_id         -- 品目ID
            ,iimb2.item_no           item_no         -- 品目コード
            ,ximb2.item_short_name   item_short_name -- 略称
            ,item_kbn.item_kbn       item_kbn        -- 商品区分
            ,item_kbn.item_kbn_name  item_kbn_name   -- 商品区分名
      BULK COLLECT INTO  ot_item_info_tab           -- 品目情報（テーブル型）
      FROM   mtl_system_items_b msib1  -- Disc品目マスタ（親）
            ,mtl_system_items_b msib2  -- Disc品目マスタ（子）
            ,ic_item_mst_b      iimb1 -- OPM品目マスタ（親）
            ,ic_item_mst_b      iimb2 -- OPM品目マスタ（子）
            ,xxcmn_item_mst_b   ximb1 -- OPM品目アドオンマスタ（親）
            ,xxcmn_item_mst_b   ximb2 -- OPM品目アドオンマスタ（子）
            ,(SELECT gic.item_id        item_id       -- 品目ID
                    ,mcv.segment1       item_kbn      -- 商品区分
                    ,mcv.description    item_kbn_name -- 商品区分名
              FROM   gmi_item_categories  gic  -- 品目カテゴリ
                    ,mtl_category_sets_vl mcsv -- 品目カテゴリセットビュー
                    ,mtl_categories_vl    mcv  -- 品目カテゴリビュー
              WHERE  gic.category_set_id     = mcsv.category_set_id -- カテゴリセットID
                AND  mcsv.category_set_name  = lv_cstegory_set_name -- カテゴリセット名
                AND  gic.category_id         = mcv.category_id      -- カテゴリID
              ) item_kbn
      WHERE msib1.organization_id   = in_inv_org_id
        AND msib1.inventory_item_id = in_parent_item_id
        AND msib1.segment1          = iimb1.item_no
        AND iimb1.item_id           = ximb1.item_id
        AND id_date BETWEEN ximb1.start_date_active AND ximb1.end_date_active
        AND iimb1.item_id           = ximb2.parent_item_id
        AND ximb2.item_id           = iimb2.item_id
        AND id_date BETWEEN ximb2.start_date_active AND ximb2.end_date_active
        AND iimb2.item_no           = msib2.segment1
        AND iimb2.item_id           = item_kbn.item_id
        AND msib2.organization_id   = in_inv_org_id
      ;
--
    ELSIF ( in_child_item_id IS NOT NULL ) THEN
      -- ======================================
      -- ３：親品目情報取得
      -- ======================================
      SELECT msib1.inventory_item_id item_id         -- 品目ID
            ,iimb1.item_no           item_no         -- 品目コード
            ,ximb1.item_short_name   item_short_name -- 略称
            ,item_kbn.item_kbn             item_kbn        -- 商品区分
            ,item_kbn.item_kbn_name        item_kbn_name   -- 商品区分名
      BULK COLLECT INTO  ot_item_info_tab           -- 品目情報（テーブル型）
      FROM   mtl_system_items_b msib1  -- Disc品目マスタ（親）
            ,mtl_system_items_b msib2  -- Disc品目マスタ（子）
            ,ic_item_mst_b      iimb1  -- OPM品目マスタ（親）
            ,ic_item_mst_b      iimb2  -- OPM品目マスタ（子）
            ,xxcmn_item_mst_b   ximb1  -- OPM品目アドオンマスタ（親）
            ,xxcmn_item_mst_b   ximb2  -- OPM品目アドオンマスタ（子）
            ,(SELECT gic.item_id        item_id       -- 品目ID
                    ,mcv.segment1       item_kbn      -- 商品区分
                    ,mcv.description    item_kbn_name -- 商品区分名
              FROM   gmi_item_categories  gic  -- 品目カテゴリ
                    ,mtl_category_sets_vl mcsv -- 品目カテゴリセットビュー
                    ,mtl_categories_vl    mcv  -- 品目カテゴリビュー
              WHERE  gic.category_set_id     = mcsv.category_set_id -- カテゴリセットID
                AND  mcsv.category_set_name  = lv_cstegory_set_name -- カテゴリセット名
                AND  gic.category_id         = mcv.category_id      -- カテゴリID
              ) item_kbn
      WHERE msib2.organization_id   = in_inv_org_id
        AND msib2.inventory_item_id = in_child_item_id
        AND msib2.segment1          = iimb2.item_no
        AND iimb2.item_id           = ximb2.item_id
        AND id_date BETWEEN ximb2.start_date_active AND ximb2.end_date_active
        AND ximb2.parent_item_id    = ximb1.item_id
        AND ximb1.item_id           = iimb1.item_id
        AND id_date BETWEEN ximb1.start_date_active AND ximb1.end_date_active
        AND iimb1.item_no           = msib1.segment1
        AND iimb1.item_id           = item_kbn.item_id
        AND msib1.organization_id   = in_inv_org_id
      ;
    END IF;
--
    -- データが取得できなかった場合
    IF ( ot_item_info_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10520
                    ,iv_token_name1  => cv_msg_tkn_item_id
                    ,iv_token_value1 => NVL(in_parent_item_id,in_child_item_id) -- 品目ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ot_item_info_tab(1).item_id := -1; -- OAFからの起動でエラーとなってしまうため
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ot_item_info_tab(1).item_id := -1; -- OAFからの起動でエラーとなってしまうため
--
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_parent_child_item_info;
--
/************************************************************************
 * Procedure Name  : INS_UPD_LOT_HOLD_INFO
 * Description     : ロット情報保持マスタ反映
 ************************************************************************/
  PROCEDURE ins_upd_lot_hold_info(
    in_customer_id    IN  NUMBER   -- 顧客ID
   ,in_deliver_to_id  IN  NUMBER   -- 出荷先ID
   ,in_parent_item_id IN  NUMBER   -- 親品目ID
   ,iv_deliver_lot    IN  VARCHAR2 -- 納品ロット
   ,id_delivery_date  IN  DATE     -- 納品日
   ,iv_e_s_kbn        IN  VARCHAR2 -- 営業生産区分
   ,iv_cancel_kbn     IN  VARCHAR2 -- 取消区分
   ,ov_errbuf         OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2 -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'ins_upd_lot_hold_info'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00024'; -- 入力パラメータ未設定エラー
    cv_err_msg_xxcoi1_10512   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10512'; -- 営業生産区分エラー
    cv_err_msg_xxcoi1_10515   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10515'; -- 顧客ID
    cv_err_msg_xxcoi1_10516   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10516'; -- 親品目ID
    cv_err_msg_xxcoi1_10517   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10517'; -- 納品ロット
    cv_err_msg_xxcoi1_10518   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10518'; -- 納品日
    cv_err_msg_xxcoi1_10519   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10519'; -- 営業生産区分
    cv_err_msg_xxcoi1_10639   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10639'; -- 取消区分エラー
    cv_err_msg_xxcoi1_10640   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10640'; -- 取消区分
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(20)  := 'IN_PARAM_NAME';    -- トークン：入力パラメータ
    cv_e_s_kbn_1              CONSTANT VARCHAR2(20)  := '1';                -- 営業生産区分：'1'（営業）
    cv_e_s_kbn_2              CONSTANT VARCHAR2(20)  := '2';                -- 営業生産区分：'2'（生産）
    cv_insert_flag_y          CONSTANT VARCHAR2(20)  := 'Y';                -- insertフラグ：'Y'
    cv_insert_flag_n          CONSTANT VARCHAR2(20)  := 'N';                -- insertフラグ：'N'
    cv_cancel_kbn_0           CONSTANT VARCHAR2(1)   := '0';                -- 取消区分：'0'
    cv_cancel_kbn_1           CONSTANT VARCHAR2(1)   := '1';                -- 取消区分：'1'
    cv_yyyymmdd               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';       -- 日付形式：YYYY/MM/DD
    ct_req_status_03          CONSTANT xxwsh_order_headers_all.req_status%TYPE := '03'; 
                                                                            -- ステータス：03(締め済み)
    ct_req_status_04          CONSTANT xxwsh_order_headers_all.req_status%TYPE := '04';
                                                                            -- ステータス：04(出荷実績計上済)
    ct_lastest_ext_flag_y     CONSTANT xxwsh_order_headers_all.latest_external_flag%TYPE := 'Y'; 
                                                                            -- 最新フラグ：Y
    ct_lastest_ext_flag_n     CONSTANT xxwsh_order_headers_all.latest_external_flag%TYPE := 'N';
                                                                            -- 最新フラグ：N
    ct_ship_shikyu_class_1    CONSTANT xxwsh_oe_transaction_types2_v.shipping_shikyu_class%TYPE := '1';
                                                                            -- 出荷支給区分：1(出荷依頼)
    ct_del_flag_y             CONSTANT xxwsh_order_lines_all.delete_flag%TYPE := 'Y'; 
                                                                            -- 削除フラグ：Y
    ct_del_flag_n             CONSTANT xxwsh_order_lines_all.delete_flag%TYPE := 'N'; 
                                                                            -- 削除フラグ：N
    ct_document_type_10       CONSTANT xxinv_mov_lot_details.document_type_code%TYPE := '10'; 
                                                                            -- 文書タイプ：10(出荷依頼)
    ct_record_type_01         CONSTANT xxinv_mov_lot_details.record_type_code%TYPE := '10'; 
                                                                            -- レコードタイプ：10(指示)
    ct_record_type_02         CONSTANT xxinv_mov_lot_details.record_type_code%TYPE := '20'; 
                                                                            -- レコードタイプ：20(実績)
--
--
    -- *** ローカル変数 ***
    lt_last_deliver_lot_e   xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE; -- 納品ロット（営業）
    lt_last_deliver_lot_s   xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE; -- 納品ロット（生産）
    lt_delivery_date_e      xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;    -- 納品日（営業）
    lt_delivery_date_s      xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;    -- 納品日（生産）
    lt_request_id           xxcoi_mst_lot_hold_info.request_id%TYPE;         -- 要求ID
    lt_lot_hold_info_id     xxcoi_mst_lot_hold_info.lot_hold_info_id%TYPE;   -- ロット情報保持マスタID
    lv_insert_flag          VARCHAR2(1);                                     -- INSERTフラグ
    lt_last_date_03         xxwsh_order_headers_all.arrival_date%TYPE;       -- 直近過去の出荷指示情報着日
    lt_last_date_04         xxwsh_order_headers_all.arrival_date%TYPE;       -- 直近過去の出荷実績情報着日
    ld_last_lot_date        DATE;                                            -- 納品ロット日付型
    lt_upd_lot_s            xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE; -- 納品ロット(生産)更新用
    lt_upd_date_s           xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;    -- 納品日(生産)更新用
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    lt_last_deliver_lot_e := NULL;
    lt_last_deliver_lot_s := NULL;
    lt_delivery_date_e    := NULL;
    lt_delivery_date_s    := NULL;
    lt_request_id         := NULL;
    lt_lot_hold_info_id   := NULL;
    lv_insert_flag        := cv_insert_flag_n;
    lt_last_date_03       := NULL;
    lt_last_date_04       := NULL;
    ld_last_lot_date      := NULL;
    lt_upd_lot_s          := NULL;
    lt_upd_date_s         := NULL;
--
    -- ======================================
    -- １：初期処理
    -- ======================================
    -- 入力パラメータ「顧客ID」がNULLの場合
    IF ( in_customer_id IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_00024
                    ,iv_token_name1  => cv_msg_tkn_in_param_name
                    ,iv_token_value1 => cv_err_msg_xxcoi1_10515 -- 顧客ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「親品目ID」がNULLの場合
    IF ( in_parent_item_id IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10516 -- 親品目ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「営業生産区分」がNULLの場合
    IF ( iv_e_s_kbn IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10519 -- 営業生産区分
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF ( iv_cancel_kbn IS NULL ) THEN
    -- 入力パラメータ「取消区分」がNULLの場合
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10640 -- 取消区分
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- INパラメータ.営業生産区分が'1'（営業）または'2'（生産）以外の場合はエラー
    IF ( iv_e_s_kbn <> cv_e_s_kbn_1
      AND iv_e_s_kbn <> cv_e_s_kbn_2
    ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10512
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- INパラメータ.取消区分が0または1以外の場合、エラー
    IF ( iv_cancel_kbn <> cv_cancel_kbn_0
      AND iv_cancel_kbn <> cv_cancel_kbn_1
    ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_err_msg_xxcoi1_10639
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 生産の取消以外の場合、必須
    IF ( iv_e_s_kbn = cv_e_s_kbn_2 AND iv_cancel_kbn = cv_cancel_kbn_1 ) THEN
      NULL;
--
    ELSE
--
      -- 入力パラメータ「納品ロット」がNULLの場合
      IF ( iv_deliver_lot IS NULL ) THEN
        -- 入力パラメータ未設定エラーメッセージを設定
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_00024
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10517 -- 納品ロット
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
  --
      -- 入力パラメータ「納品日」がNULLの場合
      IF ( id_delivery_date IS NULL ) THEN
        -- 入力パラメータ未設定エラーメッセージを設定
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_00024
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10518 -- 納品日
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ======================================
    -- ２：ロット情報保持マスタ取得
    -- ======================================
    -- 取消以外の場合
    IF ( iv_cancel_kbn = cv_cancel_kbn_0 ) THEN
--
      BEGIN
        -- INパラメータより、ロット情報保持マスタのデータを取得します
        SELECT xmlhi.last_deliver_lot_e  last_deliver_lot_e -- 納品ロット（営業）
              ,xmlhi.delivery_date_e     delivery_date_e    -- 納品日（営業）
              ,xmlhi.last_deliver_lot_s  last_deliver_lot_s -- 納品ロット（生産）
              ,xmlhi.delivery_date_s     delivery_date_s    -- 納品日（生産）
        INTO   lt_last_deliver_lot_e
              ,lt_delivery_date_e   
              ,lt_last_deliver_lot_s
              ,lt_delivery_date_s   
        FROM   xxcoi_mst_lot_hold_info  xmlhi               -- ロット情報保持マスタ
        WHERE  xmlhi.customer_id     = in_customer_id       -- 顧客ID
          AND  xmlhi.parent_item_id  = in_parent_item_id    -- 親品目ID
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- データが取得できなかった場合、INSERTフラグをYに更新します
        lv_insert_flag := cv_insert_flag_y;
      END;
--
    END IF;
--
    -- ======================================
    -- ３：ロット情報保持マスタ登録
    -- ======================================
    -- INSERTフラグがYの場合のみ登録します
    IF ( lv_insert_flag = cv_insert_flag_y ) THEN
--
      -- シーケンス値取得
      SELECT xxcoi_mst_lot_hold_info_s01.NEXTVAL
      INTO   lt_lot_hold_info_id
      FROM   DUAL
      ;
--
      -- 営業生産区分を判定し、変数に値をセットします
      -- 営業生産区分が'1'（営業）の場合
      IF ( iv_e_s_kbn = cv_e_s_kbn_1 ) THEN
        -- 納品ロット（営業）
        lt_last_deliver_lot_e := iv_deliver_lot;
        -- 納品日（営業）
        lt_delivery_date_e    := id_delivery_date;
        -- 納品ロット（生産）
        lt_last_deliver_lot_s := NULL;
        -- 納品日（生産）
        lt_delivery_date_s    := NULL;
--
      -- 営業生産区分が'2'（生産）の場合
      ELSE
        -- 納品ロット（営業）
        lt_last_deliver_lot_e := NULL;
        -- 納品日（営業）
        lt_delivery_date_e    := NULL;
        -- 納品ロット（生産）
        lt_last_deliver_lot_s := iv_deliver_lot;
        -- 納品日（生産）
        lt_delivery_date_s    := id_delivery_date;
      END IF;
--
      -- ロット情報保持マスタ登録
      INSERT INTO xxcoi_mst_lot_hold_info(
        lot_hold_info_id        -- ロット情報保持マスタID
       ,customer_id             -- 顧客ID
       ,parent_item_id          -- 親品目ID
       ,last_deliver_lot_e      -- 納品ロット_営業
       ,delivery_date_e         -- 納品日_営業
       ,last_deliver_lot_s      -- 納品ロット_生産
       ,delivery_date_s         -- 納品日_生産
       ,created_by              -- 作成者
       ,creation_date           -- 作成日
       ,last_updated_by         -- 最終更新者
       ,last_update_date        -- 最終更新日
       ,last_update_login       -- 最終更新ログイン
       ,request_id              -- 要求ID
       ,program_application_id  -- コンカレント・プログラム・アプリケーションID
       ,program_id              -- コンカレント・プログラムID
       ,program_update_date     -- プログラム更新日
      )VALUES(
        lt_lot_hold_info_id        -- ロット情報保持マスタID
       ,in_customer_id             -- 顧客ID
       ,in_parent_item_id          -- 親品目ID
       ,lt_last_deliver_lot_e      -- 納品ロット_営業
       ,lt_delivery_date_e         -- 納品日_営業
       ,lt_last_deliver_lot_s      -- 納品ロット_生産
       ,lt_delivery_date_s         -- 納品日_生産
       ,cn_created_by              -- 作成者
       ,cd_creation_date           -- 作成日
       ,cn_last_updated_by         -- 最終更新者
       ,cd_last_update_date        -- 最終更新日
       ,cn_last_update_login       -- 最終更新ログイン
       ,cn_request_id              -- 要求ID
       ,cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
       ,cn_program_id              -- コンカレント・プログラムID
       ,cd_program_update_date     -- プログラム更新日
      );
--
    -- ======================================
    -- ４：ロット情報保持マスタ更新
    -- ======================================
    -- INSERTフラグがNの場合は更新
    ELSE
--
      -- 営業生産区分が'1'(営業)の場合
      IF ( iv_e_s_kbn = cv_e_s_kbn_1 ) THEN
        -- 更新判定
        -- 納品日_営業がNULL
        IF ( lt_delivery_date_e IS NULL 
        -- 納品日_営業 < INパラメータ.納品日
          OR lt_delivery_date_e < id_delivery_date
        -- 納品日_営業 = INパラメータ.納品日かつ納品ロット_営業＜INパラメータ.納品ロット
          OR ( ( lt_delivery_date_e = id_delivery_date )
            AND ( TO_DATE( lt_last_deliver_lot_e, cv_yyyymmdd ) < TO_DATE( iv_deliver_lot, cv_yyyymmdd ) )
          )
        ) THEN
--
          -- 更新対象の場合、INパラメータの値でロット情報保持マスタ更新
          UPDATE xxcoi_mst_lot_hold_info xmlhi
          SET    xmlhi.last_deliver_lot_e      = iv_deliver_lot            -- 納品ロット_営業
                ,xmlhi.delivery_date_e         = id_delivery_date          -- 納品日_営業
                ,xmlhi.last_updated_by         = cn_last_updated_by        -- 最終更新者
                ,xmlhi.last_update_date        = cd_last_update_date       -- 最終更新日
                ,xmlhi.last_update_login       = cn_last_update_login      -- 最終更新ログイン
                ,xmlhi.request_id              = cn_request_id             -- 要求ID
                ,xmlhi.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                ,xmlhi.program_id              = cn_program_id             -- コンカレント・プログラムID
                ,xmlhi.program_update_date     = cd_program_update_date    -- プログラム更新日
          WHERE  xmlhi.customer_id             = in_customer_id            -- 顧客ID
            AND  xmlhi.parent_item_id          = in_parent_item_id         -- 親品目ID
          ;
        END IF;
--
      -- 営業生産区分が'2'(生産)の場合
      ELSE
        -- 取消以外の場合
        IF ( iv_cancel_kbn = cv_cancel_kbn_0 ) THEN
          -- 更新判定
          -- 納品日_生産がNULL
          IF ( lt_delivery_date_s IS NULL
          -- 納品日_生産 < INパラメータ.納品日
            OR lt_delivery_date_s < id_delivery_date
          -- 納品日_生産=INパラメータ.納品日かつ納品ロット_生産＜INパラメータ.納品ロット
            OR ( ( lt_delivery_date_s = id_delivery_date )
              AND ( TO_DATE( lt_last_deliver_lot_s, cv_yyyymmdd ) < TO_DATE( iv_deliver_lot, cv_yyyymmdd ) )
            )
          ) THEN
            -- 取消以外の場合で更新対象の場合、INパラメータの値でロット情報保持マスタ更新
            UPDATE xxcoi_mst_lot_hold_info xmlhi
            SET    xmlhi.last_deliver_lot_s      = iv_deliver_lot            -- 納品ロット_生産
                  ,xmlhi.delivery_date_s         = id_delivery_date          -- 納品日_生産
                  ,xmlhi.last_updated_by         = cn_last_updated_by        -- 最終更新者
                  ,xmlhi.last_update_date        = cd_last_update_date       -- 最終更新日
                  ,xmlhi.last_update_login       = cn_last_update_login      -- 最終更新ログイン
                  ,xmlhi.request_id              = cn_request_id             -- 要求ID
                  ,xmlhi.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                  ,xmlhi.program_id              = cn_program_id             -- コンカレント・プログラムID
                  ,xmlhi.program_update_date     = cd_program_update_date    -- プログラム更新日
            WHERE  xmlhi.customer_id             = in_customer_id            -- 顧客ID
              AND  xmlhi.parent_item_id          = in_parent_item_id         -- 親品目ID
            ;
--
          END IF;
--
        -- 取消の場合
        ELSE
--
          BEGIN
            -- 直近過去の出荷指示情報取得
            SELECT MAX( xoha.schedule_ship_date ) schedule_ship_date        -- MAX(出荷予定日)
            INTO   lt_last_date_03
            FROM   xxwsh_order_headers_all       xoha                       -- 受注ヘッダ
                  ,xxwsh_order_lines_all         xola                       -- 受注明細
                  ,xxwsh_oe_transaction_types2_v xottv                      -- 受注タイプ
            WHERE  xoha.deliver_to_id              = in_deliver_to_id       -- 出荷先ID
              AND  NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                   = ct_lastest_ext_flag_y  -- 最新フラグ
              AND  xoha.schedule_ship_date        <= id_delivery_date       -- 出荷予定日：INパラメータ.納品日
              AND  xoha.req_status                 = ct_req_status_03       -- ステータス：締め済み
              AND  xottv.transaction_type_id       = xoha.order_type_id     -- 受注タイプID
              AND  xottv.shipping_shikyu_class     = ct_ship_shikyu_class_1 -- 出荷依頼
              AND  xottv.start_date_active        <= TRUNC( SYSDATE )       -- 開始日
              AND  ( ( xottv.end_date_active      >= TRUNC( SYSDATE ) )
                    OR ( xottv.end_date_active     IS NULL ) 
                   )                                                        -- 終了日
              AND  xola.order_header_id            = xoha.order_header_id   -- 受注ヘッダID
              AND  xola.shipping_item_code        IN                        -- 出荷品目
                  ( SELECT ximv.item_no item_no                             -- 品目コード
                    FROM   xxcmn_item_mst2_v  ximv                          -- 品目情報ビュー2_子
                          ,xxcmn_item_mst2_v  ximv2                         -- 品目情報ビュー2_親
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- 適用開始日
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- 適用終了日
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- 適用開始日
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- 適用終了日
                    AND    ximv2.inventory_item_id  = in_parent_item_id     -- INパラメータ.親品目ID
                  )
              AND  NVL( xola.delete_flag,  ct_del_flag_n ) 
                                                  <> ct_del_flag_y          -- 削除フラグ'Y'以外
            ;
          EXCEPTION
            -- 未取得時はNULLを設定し継続
            WHEN NO_DATA_FOUND THEN
              lt_last_date_03 := NULL;
          END;
--
          BEGIN
            -- 直近過去の出荷実績情報
            SELECT  MAX( info.arrival_date ) arrival_date                      -- 最大着荷日
            INTO    lt_last_date_04
            FROM(
              SELECT xoha.arrival_date arrival_date                            -- 着荷日
              FROM   xxwsh_order_headers_all       xoha                        -- 受注ヘッダアドオン
                    ,xxwsh_order_lines_all         xola                        -- 受注明細アドオン
                    ,xxwsh_oe_transaction_types2_v xottv                       -- 受注タイプ
              WHERE  xoha.result_deliver_to_id        = in_deliver_to_id       -- 出荷先ID(実績)
                AND  NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                      = ct_lastest_ext_flag_y  -- 最新フラグ
                AND  xoha.req_status                  = ct_req_status_04       -- ステータス：出荷実績計上済
                AND  xottv.transaction_type_id        = xoha.order_type_id     -- 受注タイプID
                AND  xottv.shipping_shikyu_class      = ct_ship_shikyu_class_1 -- 出荷支給区分
                AND  xottv.start_date_active         <= TRUNC( SYSDATE )       -- 開始日
                AND  ( ( xottv.end_date_active       >= TRUNC( SYSDATE ) )
                       OR ( xottv.end_date_active    IS NULL )
                     )                                                         -- 終了日
                AND  xola.order_header_id             = xoha.order_header_id   -- 受注ヘッダID
                AND  xola.shipping_item_code       IN                          -- 出荷品目
                  ( SELECT ximv.item_no item_no                                -- 品目コード
                    FROM   xxcmn_item_mst2_v  ximv                             -- 品目情報ビュー2_子
                          ,xxcmn_item_mst2_v  ximv2                            -- 品目情報ビュー2_親
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )         -- 適用開始日
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )         -- 適用終了日
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )         -- 適用開始日
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )         -- 適用終了日
                    AND    ximv2.inventory_item_id  = in_parent_item_id        -- INパラメータ.親品目ID
                  )
                AND  NVL( xola.delete_flag, ct_del_flag_n )
                                                    <> ct_del_flag_y           -- 削除フラグ'Y'以外
                AND  xola.shipped_quantity           > 0                       -- 出荷実績数量0以上
              UNION ALL
              SELECT /*+ leading(xoha) index(xoha xxwsh_oh_n13) */
                     xoha.arrival_date arrival_date                            -- 着荷日
              FROM   xxwsh_order_headers_all       xoha                        -- 受注ヘッダアドオン
                    ,xxwsh_order_lines_all         xola                        -- 受注明細アドオン
                    ,xxwsh_oe_transaction_types2_v xottv                       -- 受注タイプ
              WHERE  xoha.result_deliver_to_id       IS NULL                   -- 出荷先ID(実績)
                AND  xoha.deliver_to_id               = in_deliver_to_id       -- 出荷先ID
                AND  NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                      = ct_lastest_ext_flag_y  -- 最新フラグ
                AND  xoha.req_status                  = ct_req_status_04       -- ステータス：出荷実績計上済
                AND  xottv.transaction_type_id        = xoha.order_type_id     -- 受注タイプID
                AND  xottv.shipping_shikyu_class      = ct_ship_shikyu_class_1 -- 出荷支給区分
                AND  xottv.start_date_active         <= TRUNC( SYSDATE )       -- 開始日
                AND  ( ( xottv.end_date_active       >= TRUNC( SYSDATE ) )
                       OR( xottv.end_date_active     IS NULL )
                     )                                                         -- 終了日
                AND  xola.order_header_id             = xoha.order_header_id   -- 受注ヘッダID
                AND  xola.shipping_item_code         IN                        -- 出荷品目
                  ( SELECT ximv.item_no item_no                             -- 品目コード
                    FROM   xxcmn_item_mst2_v  ximv                          -- 品目情報ビュー2_子
                          ,xxcmn_item_mst2_v  ximv2                         -- 品目情報ビュー2_親
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- 適用開始日
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- 適用終了日
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- 適用開始日
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- 適用終了日
                    AND    ximv2.inventory_item_id  = in_parent_item_id     -- INパラメータ.親品目ID
                  )
                AND  NVL( xola.delete_flag, ct_del_flag_n )  
                                                     <> ct_del_flag_y           -- 削除フラグ'Y'以外
                AND  xola.shipped_quantity            > 0                       -- 出荷実績数量0以上
              ) info
            ;
          EXCEPTION
            -- 未取得時はNULLをセットし処理を継続
            WHEN NO_DATA_FOUND THEN
              lt_last_date_04 := NULL;
          END;
--
          -- 賞味期限取得
          -- 指示実績ともに存在しない場合
          IF ( ( lt_last_date_03 IS NULL ) AND ( lt_last_date_04 IS NULL ) ) THEN
            NULL;
          -- 実績 < 指示 の場合
          ELSIF ( ( lt_last_date_04 < lt_last_date_03 ) OR ( lt_last_date_04 IS NULL ) ) THEN
          --
            -- 賞味期限取得
            SELECT MAX( TO_DATE( ilm.attribute3, cv_yyyymmdd ) ) taste_term   -- 賞味期限
              INTO ld_last_lot_date
              FROM xxwsh_order_headers_all        xoha                        -- 受注ヘッダアドオン
                  ,xxwsh_order_lines_all          xola                        -- 受注明細アドオン
                  ,xxinv_mov_lot_details          xmld                        -- 移動ロット詳細
                  ,xxwsh_oe_transaction_types2_v  xottv                       -- 受注タイプ
                  ,ic_lots_mst                    ilm                         -- OPMロットマスタ
             WHERE xoha.deliver_to_id              = in_deliver_to_id         -- 出荷先ID
               AND NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                   = ct_lastest_ext_flag_y    -- 最新フラグ
               AND xoha.schedule_ship_date         = TRUNC( lt_last_date_03 ) -- 出荷予定日：出荷指示情報の最大着日
               AND xoha.req_status                 = ct_req_status_03         -- ステータス：締め済み
               AND xottv.transaction_type_id       = xoha.order_type_id       -- 受注タイプID
               AND xottv.shipping_shikyu_class     = ct_ship_shikyu_class_1   -- 出荷依頼
               AND xottv.start_date_active        <= TRUNC( SYSDATE )         -- 開始日
               AND ( ( xottv.end_date_active      >= TRUNC( SYSDATE ) )
                    OR ( xottv.end_date_active    IS NULL ) 
                   )                                                          -- 終了日
               AND xola.order_header_id            = xoha.order_header_id     -- 受注ヘッダID
               AND xola.shipping_item_code        IN                          -- 出荷品目
                  ( SELECT ximv.item_no item_no                             -- 品目コード
                    FROM   xxcmn_item_mst2_v  ximv                          -- 品目情報ビュー2_子
                          ,xxcmn_item_mst2_v  ximv2                         -- 品目情報ビュー2_親
                    WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- 適用開始日
                    AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- 適用終了日
                    AND    ximv.parent_item_id     = ximv2.item_id
                    AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- 適用開始日
                    AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- 適用終了日
                    AND    ximv2.inventory_item_id  = in_parent_item_id     -- INパラメータ.親品目ID
                  )
               AND NVL( xola.delete_flag,  ct_del_flag_n ) 
                                                  <> ct_del_flag_y            -- 削除フラグ'Y'以外
               AND xmld.mov_line_id                = xola.order_line_id       -- 明細ID
               AND xmld.document_type_code         = ct_document_type_10      -- 文書タイプ：出荷依頼
               AND xmld.record_type_code           = ct_record_type_01        -- レコードタイプ：指示
               AND ilm.lot_id                      = xmld.lot_id              -- OPMロットID
               AND ilm.item_id                     = xmld.item_id             -- OPM品目ID
            ;
--
            -- 出荷日、出荷ロット設定
            lt_upd_lot_s  := TO_CHAR( ld_last_lot_date, cv_yyyymmdd ); -- 出荷ロット
            lt_upd_date_s := lt_last_date_03;                          -- 出荷日
--
          -- 指示 < 実績 の場合
          ELSE
            SELECT MAX( TO_DATE( info.taste_term, cv_yyyymmdd ) ) taste_term
              INTO ld_last_lot_date
              FROM(
                SELECT ilm.attribute3 taste_term                                 -- 賞味期限
                  FROM xxwsh_order_headers_all        xoha                       -- 受注ヘッダアドオン
                      ,xxwsh_order_lines_all          xola                       -- 受注明細アドオン
                      ,xxinv_mov_lot_details          xmld                       -- 移動ロット詳細
                      ,xxwsh_oe_transaction_types2_v  xottv                      -- 受注タイプ
                      ,ic_lots_mst                    ilm                        -- OPMロットマスタ
                 WHERE xoha.result_deliver_to_id      = in_deliver_to_id         -- 出荷先ID(実績)
                   AND xoha.arrival_date             >= TRUNC( lt_last_date_04 ) -- 着荷日:出荷実績情報の最大着日
                   AND xoha.arrival_date              < TRUNC( lt_last_date_04 + 1 ) -- 着荷日:出荷実績情報の最大着日
                   AND NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n ) 
                                                      = ct_lastest_ext_flag_y    -- 最新フラグ=Y
                   AND xoha.req_status                = ct_req_status_04         -- ステータス：出荷実績計上済
                   AND xottv.transaction_type_id      = xoha.order_type_id       -- 受注タイプID
                   AND xottv.shipping_shikyu_class    = ct_ship_shikyu_class_1   -- 出荷依頼
                   AND xottv.start_date_active       <= TRUNC( SYSDATE )
                   AND ( ( xottv.end_date_active     >= TRUNC( SYSDATE ) )
                         OR ( xottv.end_date_active  IS NULL ) 
                       )
                   AND xola.order_header_id           = xoha.order_header_id     -- 受注ヘッダID
                   AND xola.shipping_item_code       IN                          -- 出荷品目
                       ( SELECT ximv.item_no item_no                             -- 品目コード
                         FROM   xxcmn_item_mst2_v  ximv                          -- 品目情報ビュー2_子
                               ,xxcmn_item_mst2_v  ximv2                         -- 品目情報ビュー2_親
                         WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- 適用開始日
                         AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- 適用終了日
                         AND    ximv.parent_item_id     = ximv2.item_id
                         AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- 適用開始日
                         AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- 適用終了日
                         AND    ximv2.inventory_item_id  = in_parent_item_id     -- INパラメータ.親品目ID
                       )
                   AND NVL( xola.delete_flag, ct_del_flag_n ) 
                                                     <> ct_del_flag_y            -- 削除フラグ'Y'以外
                   AND xmld.mov_line_id               = xola.order_line_id       -- 明細ID
                   AND xmld.document_type_code        = ct_document_type_10      -- 文書タイプ：出荷依頼
                   AND xmld.record_type_code          = ct_record_type_02        -- レコードタイプ：出荷実績
                   AND ilm.lot_id                     = xmld.lot_id              -- OPMロットID
                   AND ilm.item_id                    = xmld.item_id             -- OPM品目ID
                   AND xmld.actual_quantity           > 0                        -- 実績数量
                UNION ALL
                SELECT /*+ leading(xoha xola) index(xoha xxwsh_oh_n13) */
                       ilm.attribute3 taste_term                                 -- 賞味期限
                  FROM xxwsh_order_headers_all        xoha                       -- 受注ヘッダアドオン
                      ,xxwsh_order_lines_all          xola                       -- 受注明細アドオン
                      ,xxinv_mov_lot_details          xmld                       -- 移動ロット詳細
                      ,xxwsh_oe_transaction_types2_v  xottv                      -- 受注タイプ
                      ,ic_lots_mst                    ilm                        -- OPMロットマスタ
                 WHERE xoha.result_deliver_to_id     IS NULL                     -- 出荷先ID(実績)
                   AND xoha.deliver_to_id             = in_deliver_to_id         -- 出荷先ID
                   AND xoha.schedule_arrival_date    >= TRUNC( lt_last_date_04 ) -- 着荷予定日:出荷実績情報の最大着日
                   AND xoha.schedule_arrival_date     < TRUNC( lt_last_date_04 + 1 ) -- 着荷予定日:出荷実績情報の最大着日
                   AND NVL( xoha.latest_external_flag, ct_lastest_ext_flag_n )
                                                      = ct_lastest_ext_flag_y    -- 最新フラグ=Y
                   AND xoha.req_status                = ct_req_status_04         -- 出荷実績計上済
                   AND xottv.transaction_type_id      = xoha.order_type_id       -- 受注タイプID
                   AND xottv.shipping_shikyu_class    = ct_ship_shikyu_class_1   -- 出荷依頼
                   AND xottv.start_date_active       <= TRUNC( SYSDATE )         -- 開始日
                   AND ( ( xottv.end_date_active     >= TRUNC( SYSDATE ) )
                         OR( xottv.end_date_active   IS NULL )
                       )                                                         -- 終了日
                   AND xola.order_header_id           = xoha.order_header_id     -- 受注ヘッダID
                   AND xola.shipping_item_code       IN                          -- 出荷品目
                       ( SELECT ximv.item_no item_no                             -- 品目コード
                         FROM   xxcmn_item_mst2_v  ximv                          -- 品目情報ビュー2_子
                               ,xxcmn_item_mst2_v  ximv2                         -- 品目情報ビュー2_親
                         WHERE  ximv.start_date_active  <= TRUNC( SYSDATE )      -- 適用開始日
                         AND    ximv.end_date_active    >= TRUNC( SYSDATE )      -- 適用終了日
                         AND    ximv.parent_item_id     = ximv2.item_id
                         AND    ximv2.start_date_active <= TRUNC( SYSDATE )      -- 適用開始日
                         AND    ximv2.end_date_active   >= TRUNC( SYSDATE )      -- 適用終了日
                         AND    ximv2.inventory_item_id  = in_parent_item_id     -- INパラメータ.親品目ID
                       )
                   AND NVL( xola.delete_flag, ct_del_flag_n ) 
                                                     <> ct_del_flag_y            -- 削除フラグ'Y'以外
                   AND xmld.mov_line_id               = xola.order_line_id       -- 明細ID
                   AND xmld.document_type_code        = ct_document_type_10      -- 文書タイプ
                   AND xmld.record_type_code          = ct_record_type_02        -- レコードタイプ
                   AND ilm.lot_id                     = xmld.lot_id              -- OPMロットID
                   AND ilm.item_id                    = xmld.item_id             -- OPM品目ID
                   AND xmld.actual_quantity           > 0                        -- 実績数量
              ) info
            ;
            -- 出荷日、出荷ロット設定
            lt_upd_lot_s  := TO_CHAR( ld_last_lot_date, cv_yyyymmdd ); -- 出荷ロット
            lt_upd_date_s := lt_last_date_04;                          -- 出荷日
--
          END IF;
--
          IF ( lt_upd_lot_s IS NOT NULL ) THEN
            -- ロット情報保持マスタ更新
            UPDATE xxcoi_mst_lot_hold_info xmlhi
            SET    xmlhi.last_deliver_lot_s      = lt_upd_lot_s              -- 納品ロット_生産
                  ,xmlhi.delivery_date_s         = TRUNC( lt_upd_date_s )    -- 納品日_生産
                  ,xmlhi.last_updated_by         = cn_last_updated_by        -- 最終更新者
                  ,xmlhi.last_update_date        = cd_last_update_date       -- 最終更新日
                  ,xmlhi.last_update_login       = cn_last_update_login      -- 最終更新ログイン
                  ,xmlhi.request_id              = cn_request_id             -- 要求ID
                  ,xmlhi.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                  ,xmlhi.program_id              = cn_program_id             -- コンカレント・プログラムID
                  ,xmlhi.program_update_date     = cd_program_update_date    -- プログラム更新日
            WHERE  xmlhi.customer_id             = in_customer_id            -- 顧客ID
              AND  xmlhi.parent_item_id          = in_parent_item_id         -- 親品目ID
            ;
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ======================================
    -- ５：エラー処理
    -- ======================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END ins_upd_lot_hold_info;
--
/************************************************************************
 * Procedure Name  : INS_UPD_DEL_LOT_ONHAND
 * Description     : ロット別手持数量反映
 ************************************************************************/
  PROCEDURE ins_upd_del_lot_onhand(
    in_inv_org_id       IN  NUMBER           -- 在庫組織ID
   ,iv_base_code        IN  VARCHAR2         -- 拠点コード
   ,iv_subinv_code      IN  VARCHAR2         -- 保管場所コード
   ,iv_loc_code         IN  VARCHAR2         -- ロケーションコード
   ,in_child_item_id    IN  NUMBER           -- 子品目ID
   ,iv_lot              IN  VARCHAR2         -- ロット(賞味期限)
   ,iv_diff_sum_code    IN  VARCHAR2         -- 固有記号
   ,in_case_in_qty      IN  NUMBER           -- 入数
   ,in_case_qty         IN  NUMBER           -- ケース数
   ,in_singly_qty       IN  NUMBER           -- バラ数
   ,in_summary_qty      IN  NUMBER           -- 取引数量
   ,ov_errbuf           OUT VARCHAR2         -- エラーメッセージ
   ,ov_retcode          OUT VARCHAR2         -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg           OUT VARCHAR2         -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'ins_upd_del_lot_onhand'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00024'; -- 入力パラメータ未設定エラー
    cv_err_msg_xxcoi1_10500   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10500'; -- 入数
    cv_err_msg_xxcoi1_10501   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10501'; -- 取引数量
    cv_err_msg_xxcoi1_10502   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10502'; -- 拠点コード
    cv_err_msg_xxcoi1_10503   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10503'; -- 保管場所コード
    cv_err_msg_xxcoi1_10514   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10514'; -- 在庫組織ID
    cv_err_msg_xxcoi1_10581   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10581'; -- ロケーションコード
    cv_err_msg_xxcoi1_10582   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10582'; -- 子品目ID
    cv_err_msg_xxcoi1_10583   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10583'; -- 入力パラメータマイナスエラー
    cv_err_msg_xxcoi1_10584   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10584'; -- 入力パラメータ（入数）妥当性エラー
    cv_err_msg_xxcoi1_10585   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10585'; -- 手持数量算出結果マイナスエラー
    cv_err_msg_xxcoi1_10586   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10586'; -- ケース数
    cv_err_msg_xxcoi1_10587   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10587'; -- バラ数
    cv_err_msg_xxcoi1_10607   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10607'; -- 製造日取得エラー
--
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(13)  := 'IN_PARAM_NAME';    -- トークン：入力パラメータ
    cv_msg_tkn_item_id        CONSTANT VARCHAR2(13)  := 'ITEM_ID';          -- トークン：品目ID
    cv_msg_tkn_diff_sum_code  CONSTANT VARCHAR2(13)  := 'DIFF_SUM_CODE';    -- トークン：固有記号
    cv_msg_tkn_lot            CONSTANT VARCHAR2(13)  := 'LOT';              -- トークン：ロット
--
    cv_insert_flag_y          CONSTANT VARCHAR2(1)   := 'Y';                -- insertフラグ：'Y'
    cv_insert_flag_n          CONSTANT VARCHAR2(1)   := 'N';                -- insertフラグ：'N'
    cv_lot_no_dafault         CONSTANT VARCHAR2(10)  := 'DEFAULTLOT';       -- ロット番号：'DEFAULTLOT'
--
    cv_date_fmt               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';       -- 日付型YYYY/MM/DD
--
    -- *** ローカル変数 ***
    lt_case_qty        xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- ケース数
    lt_singly_qty      xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- バラ数
    lt_summary_qty     xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- 取引数量
    lt_case_qty_sum    xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- ケース数（算出用）
    lt_singly_qty_sum  xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- バラ数（算出用）
    lt_summary_qty_sum xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- 取引数量（算出用）
    lt_product_date    ic_lots_mst.attribute1%TYPE;                 -- 製造年月日
    lv_insert_flag     VARCHAR2(1);                                 -- INSERTフラグ
    ln_case_qty_minus  NUMBER;                                      -- ケース数（取り崩し計算用）
    lt_expiration_day  xxcmn_item_mst_b.expiration_day%TYPE;        -- 賞味期間
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    lt_case_qty         := NULL;  -- ケース数
    lt_singly_qty       := NULL;  -- バラ数
    lt_summary_qty      := NULL;  -- 取引数量
    lt_case_qty_sum     := NULL;  -- ケース数（算出用）
    lt_singly_qty_sum   := NULL;  -- バラ数（算出用）
    lt_summary_qty_sum  := NULL;  -- 取引数量（算出用）
    lt_product_date     := NULL;  -- 製造年月日
    ln_case_qty_minus   := NULL;  -- ケース数（取り崩し計算用）
    lv_insert_flag      := cv_insert_flag_n; -- INSERTフラグ
--
    -- ======================================
    -- １：初期処理
    -- ======================================
    -- 入力パラメータ「在庫組織ID」がNULLの場合
    IF ( in_inv_org_id IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10514 -- 在庫組織ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「拠点コード」がNULLの場合
    IF ( iv_base_code IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10502 -- 拠点コード
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「保管場所コード」がNULLの場合
    IF ( iv_subinv_code IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10503 -- 保管場所コード
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「ロケーションコード」がNULLの場合
    IF ( iv_loc_code IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10581 -- ロケーションコード
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「子品目ID」がNULLの場合
    IF ( in_child_item_id IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10582 -- 子品目ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「取引数量」がNULLの場合
    IF ( in_summary_qty IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10501 -- 取引数量
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「入数」がNULLの場合
    IF ( in_case_in_qty IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10500 -- 入数
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- -- 入力パラメータ「入数」が0以下の場合
    IF ( in_case_in_qty <= 0) THEN
      -- 入力パラメータ（入数）妥当性エラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10584
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- WHOカラムの取得
    -- 固定グローバル変数を使用するため割愛
--
    -- ======================================
    -- ２：ロット別手持数量抽出
    -- ======================================
    BEGIN
      -- INパラメータより、ロット別手持数量のデータを取得します
      SELECT xloq.case_qty    case_qty    -- ケース数
            ,xloq.singly_qty  singly_qty  -- バラ数
            ,xloq.summary_qty summary_qty -- 取引数量
      INTO   lt_case_qty    -- ケース数
            ,lt_singly_qty  -- バラ数
            ,lt_summary_qty -- 取引数量
      FROM   xxcoi_lot_onhand_quantites  xloq  -- ロット別手持数量
      WHERE  xloq.organization_id    = in_inv_org_id     -- 在庫組織ID
        AND  xloq.base_code          = iv_base_code      -- 拠点コード
        AND  xloq.subinventory_code  = iv_subinv_code    -- 保管場所コード
        AND  xloq.location_code      = iv_loc_code       -- ロケーションコード
        AND  xloq.child_item_id      = in_child_item_id  -- 子品目ID
        AND  (xloq.lot               = iv_lot
           OR (xloq.lot IS NULL AND iv_lot IS NULL))     -- ロット（賞味期限）
        AND  (xloq.difference_summary_code  = iv_diff_sum_code
           OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL)) -- 固有記号
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- データが取得できなかった場合、INSERTフラグをYに更新します
      lv_insert_flag := cv_insert_flag_y;
    END;
    -- ======================================
    -- ３：ロット別手持数量登録
    -- ======================================
    -- INSERTフラグがYの場合のみ登録します
    IF ( lv_insert_flag = cv_insert_flag_y ) THEN
      -- 入力パラメータチェック
      -- 入力パラメータ「ケース数」がマイナスの場合
      IF ( in_case_qty < 0 ) THEN
        -- 入力パラメータマイナスエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10583
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10586 -- ケース数
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- 入力パラメータ「バラ数」がマイナスの場合
      IF ( in_singly_qty < 0 ) THEN
        -- 入力パラメータマイナスエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10583
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10587 -- バラ数
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- 入力パラメータ「取引数量」がマイナスの場合
      IF ( in_summary_qty < 0 ) THEN
        -- 入力パラメータマイナスエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10583
                       ,iv_token_name1  => cv_msg_tkn_in_param_name
                       ,iv_token_value1 => cv_err_msg_xxcoi1_10501 -- 取引数量
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      BEGIN
        -- 製造日を取得
        -- ロット（賞味期限）がNULLの場合は製造日にNULLを設定
        IF ( iv_lot IS NULL ) THEN
          lt_product_date := NULL;
--
        -- ロット（賞味期限）がNULL以外の場合は賞味期限-賞味期間で製造日を導出
        ELSE
          -- 賞味期間導出
          SELECT ximb.expiration_day expiration_day        -- 賞味期間
          INTO   lt_expiration_day
          FROM   xxcmn_item_mst_b   ximb                   -- OPM品目アドオンマスタ
                ,ic_item_mst_b      iimb                   -- OPM品目マスタ
                ,mtl_system_items_b msib                   -- Disc品目マスタ
          WHERE msib.organization_id    = in_inv_org_id    -- INパラメータ.在庫組織ID
          AND   msib.inventory_item_id  = in_child_item_id -- INパラメータ.Disc品目ID
          AND   iimb.item_no            = msib.segment1
          AND   iimb.item_id            = ximb.item_id
          AND   ximb.start_date_active <= TRUNC( SYSDATE ) -- 適用開始日
          AND   ximb.end_date_active   >= TRUNC( SYSDATE ) -- 適用終了日
          ;
--
          -- INパラメータ.賞味期限 - 算出した賞味期間の計算結果を製造日に設定する
          lt_product_date := TO_CHAR( TO_DATE( iv_lot , cv_date_fmt ) - lt_expiration_day , cv_date_fmt );
--
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 製造日取得エラー
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_coi
                         ,iv_name         => cv_err_msg_xxcoi1_10607
                         ,iv_token_name1  => cv_msg_tkn_item_id
                         ,iv_token_value1 => in_child_item_id   -- 子品目ID
                         ,iv_token_name2  => cv_msg_tkn_diff_sum_code
                         ,iv_token_value2 => iv_diff_sum_code   -- 固有記号
                         ,iv_token_name3  => cv_msg_tkn_lot
                         ,iv_token_value3 => iv_lot             -- ロット
                        );
           lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 取引数量が0より大きい場合、手持数量を反映
      IF( NVL( in_summary_qty, 0 ) > 0 )THEN
        -- ロット別手持数量登録
        INSERT INTO xxcoi_lot_onhand_quantites(
          organization_id         -- 在庫組織ID
         ,base_code               -- 拠点コード
         ,subinventory_code       -- 保管場所コード
         ,location_code           -- ロケーションコード
         ,child_item_id           -- 子品目ID
         ,lot                     -- ロット
         ,difference_summary_code -- 固有記号
         ,case_in_qty             -- 入数
         ,case_qty                -- ケース数
         ,singly_qty              -- バラ数
         ,summary_qty             -- 取引数量
         ,production_date         -- 製造日
         ,created_by              -- 作成者
         ,creation_date           -- 作成日
         ,last_updated_by         -- 最終更新者
         ,last_update_date        -- 最終更新日
         ,last_update_login       -- 最終更新ログイン
         ,request_id              -- 要求ID
         ,program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,program_id              -- コンカレント・プログラムID
         ,program_update_date     -- プログラム更新日
        )VALUES(
          in_inv_org_id             -- 在庫組織ID
         ,iv_base_code              -- 拠点コード
         ,iv_subinv_code            -- 保管場所コード
         ,iv_loc_code               -- ロケーションコード
         ,in_child_item_id          -- 子品目ID
         ,iv_lot                    -- ロット
         ,iv_diff_sum_code          -- 固有記号
         ,in_case_in_qty            -- 入数
         ,NVL( in_case_qty, 0 )     -- ケース数
         ,NVL( in_singly_qty, 0 )   -- バラ数
         ,NVL( in_summary_qty, 0 )  -- 取引数量
         ,lt_product_date           -- 製造日
         ,cn_created_by             -- 作成者
         ,cd_creation_date          -- 作成日
         ,cn_last_updated_by        -- 最終更新者
         ,cd_last_update_date       -- 最終更新日
         ,cn_last_update_login      -- 最終更新ログイン
         ,cn_request_id             -- 要求ID
         ,cn_program_application_id -- コンカレント・プログラム・アプリケーションID
         ,cn_program_id             -- コンカレント・プログラムID
         ,cd_program_update_date    -- プログラム更新日
        );
      END IF;
--
    -- ======================================
    -- ４：ロット情報保持マスタ更新
    -- ======================================
    ELSE
      -- ケース数、バラ数、取引数量の算出
      -- ケース数
      lt_case_qty_sum     := NVL(lt_case_qty,0) + NVL(in_case_qty,0);
      -- バラ数
      lt_singly_qty_sum   := NVL(lt_singly_qty,0) + NVL(in_singly_qty,0);
      -- 取引数量
      lt_summary_qty_sum  := NVL(lt_summary_qty,0) + NVL(in_summary_qty,0);
--
      -- ケース数がマイナスの場合はエラー
      IF ( lt_case_qty_sum  < 0 ) THEN
        -- 手持数量算出結果マイナスエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10585
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- バラ数がマイナスの場合、ケースを取り崩す
      IF ( lt_singly_qty_sum < 0 ) THEN
        -- 取り崩すケース数を算出
        IF ( MOD(lt_singly_qty_sum,in_case_in_qty) = 0 ) THEN
          -- バラ数が入数の倍数の場合：（バラ数 / 入数) * -1
          ln_case_qty_minus := TRUNC((lt_singly_qty_sum / in_case_in_qty)) * -1;
        ELSE
          -- 上記以外の場合：（(バラ数 / 入数) * -1) +1
          ln_case_qty_minus := (TRUNC((lt_singly_qty_sum / in_case_in_qty)) * -1) +1;
        END IF;
--
        -- ケースを取り崩した後のケース数、バラ数を計算
        lt_case_qty_sum   := lt_case_qty_sum   - ln_case_qty_minus;
        lt_singly_qty_sum := lt_singly_qty_sum + (in_case_in_qty * ln_case_qty_minus);
--
      END IF;
--
      -- 算出後のケース数、バラ数、取引数量のいずれかがマイナスの場合はエラー
      IF ( lt_case_qty_sum    < 0
        OR lt_singly_qty_sum  < 0
        OR lt_summary_qty_sum < 0)
      THEN
         -- 手持数量算出結果マイナスエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10585
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- 算出後のケース数、バラ数、取引数量が全て0の場合は、テーブルから削除
      IF ( lt_case_qty_sum    = 0
       AND lt_singly_qty_sum  = 0
       AND lt_summary_qty_sum = 0 )
      THEN
        DELETE FROM xxcoi_lot_onhand_quantites xloq -- ロット別手持数量
        WHERE  xloq.organization_id    = in_inv_org_id     -- 在庫組織ID
          AND  xloq.base_code          = iv_base_code      -- 拠点コード
          AND  xloq.subinventory_code  = iv_subinv_code    -- 保管場所コード
          AND  xloq.location_code      = iv_loc_code       -- ロケーションコード
          AND  xloq.child_item_id      = in_child_item_id  -- 子品目ID
          AND  (xloq.lot               = iv_lot
             OR (xloq.lot IS NULL AND iv_lot IS NULL)) -- ロット（賞味期限）
          AND  (xloq.difference_summary_code  = iv_diff_sum_code
             OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL)) -- 固有記号
        ;
      -- 上記以外の場合は、更新
      ELSE
        UPDATE xxcoi_lot_onhand_quantites xloq -- ロット別手持数量
        SET    xloq.case_qty      = lt_case_qty_sum       -- ケース数
              ,xloq.singly_qty    = lt_singly_qty_sum     -- バラ数
              ,xloq.summary_qty   = lt_summary_qty_sum    -- 取引数量
              ,xloq.last_updated_by         = cn_last_updated_by        -- 最終更新者
              ,xloq.last_update_date        = cd_last_update_date       -- 最終更新日
              ,xloq.last_update_login       = cn_last_update_login      -- 最終更新ログイン
              ,xloq.request_id              = cn_request_id             -- 要求ID
              ,xloq.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xloq.program_id              = cn_program_id             -- コンカレント・プログラムID
              ,xloq.program_update_date     = cd_program_update_date    -- プログラム更新日
        WHERE  xloq.organization_id    = in_inv_org_id     -- 在庫組織ID
          AND  xloq.base_code          = iv_base_code      -- 拠点コード
          AND  xloq.subinventory_code  = iv_subinv_code    -- 保管場所コード
          AND  xloq.location_code      = iv_loc_code       -- ロケーションコード
          AND  xloq.child_item_id      = in_child_item_id  -- 子品目ID
          AND  (xloq.lot               = iv_lot
             OR (xloq.lot IS NULL AND iv_lot IS NULL))     -- ロット（賞味期限）
          AND  (xloq.difference_summary_code  = iv_diff_sum_code
             OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL))     -- 固有記号
        ;
      END IF;
    END IF;
--
    -- ======================================
    -- ５：エラー処理
    -- ======================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END ins_upd_del_lot_onhand;
--
/************************************************************************
 * Procedure Name  : GET_FRESH_CONDITION_DATE
 * Description     : 鮮度条件基準日算出
 ************************************************************************/
  PROCEDURE get_fresh_condition_date(
    id_use_by_date           IN  DATE             -- 賞味期限
   ,id_product_date          IN  DATE             -- 製造年月日
   ,iv_fresh_condition       IN  VARCHAR2         -- 鮮度条件
   ,od_fresh_condition_date  OUT DATE             -- 鮮度条件基準日
   ,ov_errbuf                OUT VARCHAR2         -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2         -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2         -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_fresh_condition_date'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_00011   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00011'; -- 業務日付未取得エラー
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00024'; -- 入力パラメータ未設定エラー
    cv_err_msg_xxcoi1_10588   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10588'; -- 賞味期限
    cv_err_msg_xxcoi1_10589   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10589'; -- 製造年月日
    cv_err_msg_xxcoi1_10590   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10590'; -- 鮮度条件
    cv_err_msg_xxcoi1_10591   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10591'; -- 鮮度条件情報取得エラー
--
    cv_msg_tkn_param1         CONSTANT VARCHAR2(13)  := 'PARAM1';           -- トークン：パラメータ１
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(13)  := 'IN_PARAM_NAME';    -- トークン：入力パラメータ
--
    cv_freshness_condition    CONSTANT VARCHAR2(30)  := 'XXCOI1_FRESHNESS_CONDITION'; -- 参照タイプ：鮮度条件
--
    cv_fresh_con_type_0       CONSTANT VARCHAR2(1)   := '0'; -- 鮮度条件タイプ：'0'（一般）
    cv_fresh_con_type_1       CONSTANT VARCHAR2(1)   := '1'; -- 鮮度条件タイプ：'1'（賞味期限基準）
    cv_fresh_con_type_2       CONSTANT VARCHAR2(1)   := '2'; -- 鮮度条件タイプ：'2'（製造日基準）
    cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y'; -- フラグ:Y
--
    -- *** ローカル変数 ***
    lt_fresh_condition_type   fnd_lookup_values.attribute1%TYPE;  -- 鮮度条件タイプ
    lt_standard_value         fnd_lookup_values.attribute2%TYPE;  -- 基準値
    lt_adjusted_value         fnd_lookup_values.attribute3%TYPE;  -- 調整値
    ld_proc_date              DATE; -- 業務日付
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    lt_fresh_condition_type  := NULL;  -- 鮮度条件タイプ
    lt_standard_value        := NULL;  -- 基準値
    lt_adjusted_value        := NULL;  -- 調整値
    ld_proc_date             := NULL;  -- 業務日付
--
    -- ======================================
    -- １：初期処理
    -- ======================================
    -- 賞味期限がNULLの場合
    IF ( id_use_by_date IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10588 -- 賞味期限
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 製造年月日がNULLの場合
    IF ( id_product_date IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10589 -- 製造年月日
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    
--
    -- 鮮度条件がNULLの場合
    IF ( iv_fresh_condition IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10590 -- 鮮度条件
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 業務日付を取得
    ld_proc_date := xxccp_common_pkg2.get_process_date;
    -- 取得できない場合は、エラー
    IF ( ld_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00011
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- ２：鮮度条件情報取得
    -- ======================================
    BEGIN
      SELECT flv.attribute1    fresh_condition_type -- 鮮度条件タイプ
            ,flv.attribute2    standard_value       -- 基準値
            ,flv.attribute3    adjusted_value       -- 調整値
      INTO   lt_fresh_condition_type -- 鮮度条件タイプ
            ,lt_standard_value       -- 基準値
            ,lt_adjusted_value       -- 調整値
      FROM   fnd_lookup_values  flv    -- 参照タイプ
      WHERE  flv.lookup_type         = cv_freshness_condition -- タイプ
        AND  flv.language            = USERENV('LANG')        -- 言語
        AND  flv.lookup_code         = iv_fresh_condition     -- コード
        AND  flv.enabled_flag        = cv_flag_y              -- 有効フラグ
        AND  ld_proc_date BETWEEN NVL(flv.start_date_active,ld_proc_date) -- 有効開始日
                          AND     NVL(flv.end_date_active,ld_proc_date)   -- 有効終了日
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- 鮮度条件情報取得エラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10591
                     ,iv_token_name1  => cv_msg_tkn_param1
                     ,iv_token_value1 => iv_fresh_condition -- INパラメータ.鮮度条件
                    );
      lv_errbuf := SQLERRM;
      RAISE global_process_expt;
    END;
--
    -- ======================================
    -- ３：鮮度条件基準日算出
    -- ======================================
    -- 鮮度条件タイプ = '0' (一般) の場合
    IF ( lt_fresh_condition_type = cv_fresh_con_type_0 ) THEN
      od_fresh_condition_date
        := id_use_by_date               -- 賞味期限
         + NVL( lt_standard_value, 0 )  -- 基準値
         + NVL( lt_adjusted_value, 0 ); -- 調整値
--
    -- 鮮度条件タイプ = '1' (賞味期限基準) の場合
    ELSIF ( lt_fresh_condition_type = cv_fresh_con_type_1 ) THEN
      od_fresh_condition_date
        := id_product_date              -- 製造年月日
         + TRUNC((id_use_by_date - id_product_date) / lt_standard_value) -- (賞味期限 - 製造年月日) / 基準値
         + NVL( lt_adjusted_value, 0 ); -- 調整値
    -- 鮮度条件タイプ = '2' (製造日基準) の場合
    ELSIF ( lt_fresh_condition_type = cv_fresh_con_type_2 ) THEN
      od_fresh_condition_date
        := id_product_date              -- 製造年月日
         + NVL( lt_standard_value, 0 )  -- 基準値
         + NVL( lt_adjusted_value, 0 ); -- 調整値
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_fresh_condition_date;
--
/************************************************************************
 * Procedure Name  : GET_RESERVED_QUANTITY
 * Description     : 引当可能数算出
 ************************************************************************/
  PROCEDURE get_reserved_quantity(
    in_inv_org_id       IN  NUMBER           -- 在庫組織ID
   ,iv_base_code        IN  VARCHAR2         -- 拠点コード
   ,iv_subinv_code      IN  VARCHAR2         -- 保管場所コード
   ,iv_loc_code         IN  VARCHAR2         -- ロケーションコード
   ,in_child_item_id    IN  NUMBER           -- 子品目ID
   ,iv_lot              IN  VARCHAR2         -- ロット(賞味期限)
   ,iv_diff_sum_code    IN  VARCHAR2         -- 固有記号
   ,on_case_in_qty      OUT NUMBER           -- 入数
   ,on_case_qty         OUT NUMBER           -- ケース数
   ,on_singly_qty       OUT NUMBER           -- バラ数
   ,on_summary_qty      OUT NUMBER           -- 取引数量
   ,ov_errbuf           OUT VARCHAR2         -- エラーメッセージ
   ,ov_retcode          OUT VARCHAR2         -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg           OUT VARCHAR2         -- ユーザー・エラーメッセージ
  )IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_reserved_quantity'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージ用定数
    cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';            -- アプリケーション短縮名
    cv_err_msg_xxcoi1_00024   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00024'; -- 入力パラメータ未設定エラー
    cv_err_msg_xxcoi1_00032   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00032'; -- プロファイル取得エラー
    cv_err_msg_xxcoi1_10502   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10502'; -- 拠点コード
    cv_err_msg_xxcoi1_10503   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10503'; -- 保管場所コード
    cv_err_msg_xxcoi1_10514   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10514'; -- 在庫組織ID
    cv_err_msg_xxcoi1_10581   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10581'; -- ロケーションコード
    cv_err_msg_xxcoi1_10582   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10582'; -- 子品目ID
    cv_err_msg_xxcoi1_10585   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10585'; -- 手持数量算出結果マイナスエラー
    cv_err_msg_xxcoi1_10592   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10592'; -- ロット別手持数量取得エラー
--
    cv_msg_tkn_in_param_name  CONSTANT VARCHAR2(13)  := 'IN_PARAM_NAME';    -- トークン：入力パラメータ
    cv_msg_tkn_pro_tok        CONSTANT VARCHAR2(13)  := 'PRO_TOK';          -- トークン：プロファイル
--
    cv_org_id                 CONSTANT VARCHAR2(13)  := 'ORG_ID';           -- MO:営業単位
--
    cv_shipping_status_10     CONSTANT VARCHAR2(2)   := '10';               -- 出荷情報ステータス：10（引当未）
    cv_shipping_status_20     CONSTANT VARCHAR2(2)   := '20';               -- 出荷情報ステータス：20（引当済）
    cv_shipping_status_25     CONSTANT VARCHAR2(2)   := '25';               -- 出荷情報ステータス：25（出荷仮確定）
--
    cv_lot_tran_kbn_9         CONSTANT VARCHAR2(1)   := '9';                -- ロット別取引作成区分：9(対象外)
--
    cv_xxcoi016a06c           CONSTANT VARCHAR2(15)  := 'XXCOI016A06C';     -- ロット別出荷情報作成
--
    -- *** ローカル変数 ***
    lt_case_in_qty     xxcoi_lot_onhand_quantites.case_in_qty%TYPE; -- 入数
    lt_case_qty        xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- ケース数
    lt_singly_qty      xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- バラ数
    lt_summary_qty     xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- 取引数量
    lt_case_qty_sum    xxcoi_lot_onhand_quantites.case_qty%TYPE;    -- ケース数（合計）
    lt_singly_qty_sum  xxcoi_lot_onhand_quantites.singly_qty%TYPE;  -- バラ数（合計）
    lt_summary_qty_sum xxcoi_lot_onhand_quantites.summary_qty%TYPE; -- 取引数量（合計）
    lt_org_id          fnd_profile_option_values.profile_option_value%TYPE; -- 営業単位
    ln_case_qty_minus  NUMBER;      -- ケース数（取り崩し計算用）
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
  BEGIN
--
  --##################  固定ステータス初期化部 START   ###################
  --
    ov_retcode := cv_status_normal;
  --
  --###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    lt_case_in_qty     := NULL; -- 入数
    lt_case_qty        := NULL; -- ケース数
    lt_singly_qty      := NULL; -- バラ数
    lt_summary_qty     := NULL; -- 取引数量
    lt_case_qty_sum    := NULL; -- ケース数（合計）
    lt_singly_qty_sum  := NULL; -- バラ数（合計）
    lt_summary_qty_sum := NULL; -- 取引数量（合計）
    ln_case_qty_minus  := NULL; -- 取り崩すケース数
    lt_org_id          := NULL; -- 営業単位
--
    -- ======================================
    -- １：初期処理
    -- ======================================
    -- 入力パラメータ「在庫組織ID」がNULLの場合
    IF ( in_inv_org_id IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10514 -- 在庫組織ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「拠点コード」がNULLの場合
    IF ( iv_base_code IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10502 -- 拠点コード
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「保管場所コード」がNULLの場合
    IF ( iv_subinv_code IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10503 -- 保管場所コード
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「ロケーションコード」がNULLの場合
    IF ( iv_loc_code IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10581 -- ロケーションコード
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「子品目ID」がNULLの場合
    IF ( in_child_item_id IS NULL ) THEN
      -- 入力パラメータ未設定エラーメッセージを設定
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00024
                     ,iv_token_name1  => cv_msg_tkn_in_param_name
                     ,iv_token_value1 => cv_err_msg_xxcoi1_10582 -- 子品目ID
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- プロファイル「MO:営業単位」を取得
    lt_org_id := FND_PROFILE.VALUE(cv_org_id);
    IF ( lt_org_id IS NULL ) THEN
      -- プロファイル値取得エラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_00032
                     ,iv_token_name1  => cv_msg_tkn_pro_tok
                     ,iv_token_value1 => cv_org_id
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- ２：手持数量情報取得
    -- ======================================
    BEGIN
      -- ロット手持数量情報を取得します
      SELECT xloq.case_in_qty case_in_qty -- 入数
            ,xloq.case_qty    case_qty    -- ケース数
            ,xloq.singly_qty  singly_qty  -- バラ数
            ,xloq.summary_qty summary_qty -- 取引数量
      INTO   lt_case_in_qty -- 入数
            ,lt_case_qty    -- ケース数
            ,lt_singly_qty  -- バラ数
            ,lt_summary_qty -- 取引数量
      FROM   xxcoi_lot_onhand_quantites  xloq  -- ロット別手持数量
      WHERE  xloq.organization_id    = in_inv_org_id     -- 在庫組織ID
        AND  xloq.base_code          = iv_base_code      -- 拠点コード
        AND  xloq.subinventory_code  = iv_subinv_code    -- 保管場所コード
        AND  xloq.location_code      = iv_loc_code       -- ロケーションコード
        AND  xloq.child_item_id      = in_child_item_id  -- 子品目ID
        AND  (xloq.lot               = iv_lot
           OR (xloq.lot IS NULL AND iv_lot IS NULL))     -- ロット（賞味期限）
        AND  (xloq.difference_summary_code  = iv_diff_sum_code
           OR (xloq.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL))     -- 固有記号
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ロット別手持数量取得エラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_err_msg_xxcoi1_10592
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ======================================
    -- ３：引当情報取得
    -- ======================================
    -- 引当情報を取得
    SELECT NVL(SUM(xlri.case_qty), 0)    case_qty_sum    -- ケース数（合計）
          ,NVL(SUM(xlri.singly_qty), 0)  singly_qty_sum  -- バラ数（合計）
          ,NVL(SUM(xlri.summary_qty), 0) summary_qty_sum -- 取引数量（合計）
    INTO   lt_case_qty_sum                               -- ケース数（合計）
          ,lt_singly_qty_sum                             -- バラ数（合計）
          ,lt_summary_qty_sum                            -- 取引数量（合計）
    FROM   xxcoi_lot_reserve_info  xlri                  -- ロット別引当情報
    WHERE  xlri.shipping_status    IN ( cv_shipping_status_10, cv_shipping_status_20, cv_shipping_status_25 ) -- 出荷情報ステータス
--
      AND  xlri.org_id             = lt_org_id             -- 営業単位
      AND  xlri.base_code          = iv_base_code          -- 拠点コード
      AND  xlri.whse_code          = iv_subinv_code        -- 保管場所コード
      AND  xlri.location_code      = iv_loc_code           -- ロケーションコード
      AND  xlri.item_id            = in_child_item_id      -- 子品目ID
      AND  (xlri.lot               = iv_lot
         OR (xlri.lot IS NULL AND iv_lot IS NULL))         -- ロット（賞味期限）
      AND  (xlri.difference_summary_code  = iv_diff_sum_code
         OR (xlri.difference_summary_code IS NULL AND iv_diff_sum_code IS NULL))  -- 固有記号
    ;
--
    -- ======================================
    -- 3-1.ロット別取引TEMP存在数取得
    -- ======================================
--
    -- ======================================
    -- ４：引当可能数算出
    -- ======================================
    -- ケース数、バラ数、取引数量の算出
    lt_case_qty_sum    := lt_case_qty    - lt_case_qty_sum;    -- ケース数
    lt_singly_qty_sum  := lt_singly_qty  - lt_singly_qty_sum;  -- バラ数
    lt_summary_qty_sum := lt_summary_qty - lt_summary_qty_sum; -- 取引数量
--
    -- ケース数がマイナスの場合はエラー
    IF ( lt_case_qty_sum  < 0 ) THEN
      -- 手持数量算出結果マイナスエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10585
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- バラ数がマイナスの場合、ケースを取り崩す
    IF ( lt_singly_qty_sum < 0 ) THEN
      -- 取り崩すケース数を算出
      IF ( MOD(lt_singly_qty_sum,lt_case_in_qty) = 0 ) THEN
        -- バラ数が入数の倍数の場合：（バラ数 / 入数) * -1
        ln_case_qty_minus := TRUNC((lt_singly_qty_sum / lt_case_in_qty)) * -1;
      ELSE
        -- 上記以外の場合：（(バラ数 / 入数) * -1) +1
        ln_case_qty_minus := (TRUNC((lt_singly_qty_sum / lt_case_in_qty)) * -1) +1;
      END IF;
--
      -- ケースを取り崩した後のケース数、バラ数を計算
      lt_case_qty_sum   := lt_case_qty_sum   - ln_case_qty_minus;
      lt_singly_qty_sum := lt_singly_qty_sum + (lt_case_in_qty * ln_case_qty_minus);
--
    END IF;
--
    -- 算出後のケース数、バラ数、取引数量のいずれかがマイナスの場合はエラー
    IF ( lt_case_qty_sum    < 0
      OR lt_singly_qty_sum  < 0
      OR lt_summary_qty_sum < 0)
    THEN
       -- 手持数量算出結果マイナスエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_err_msg_xxcoi1_10585
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- ５：戻り値設定
    -- ======================================
    on_case_in_qty := lt_case_in_qty;     -- 入数
    on_case_qty    := lt_case_qty_sum;    -- ケース数
    on_singly_qty  := lt_singly_qty_sum;  -- バラ数
    on_summary_qty := lt_summary_qty_sum; -- 取引数量
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_reserved_quantity;
--
/************************************************************************
 * Function Name   : GET_FRESH_CONDITION_DATE_F
 * Description     : 鮮度条件基準日算出(ファンクション型)
 ************************************************************************/
--
  FUNCTION get_fresh_condition_date_f(
    id_use_by_date     IN  DATE     -- 賞味期限
   ,id_product_date    IN  DATE     -- 製造年月日
   ,iv_fresh_condition IN  VARCHAR2 -- 鮮度条件
  ) RETURN DATE
  IS
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
    global_process_expt EXCEPTION; -- 処理部共通例外
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_return DATE; -- 戻り値
--
  BEGIN
    -- 変数初期化
    ld_return := NULL;
--
    -- 共通関数：「鮮度条件基準日算出」を使用し鮮度条件を導出
    xxcoi_common_pkg.get_fresh_condition_date(
      id_use_by_date          => id_use_by_date     -- 賞味期限
     ,id_product_date         => id_product_date    -- 製造年月日
     ,iv_fresh_condition      => iv_fresh_condition -- 鮮度条件
     ,od_fresh_condition_date => ld_return          -- 鮮度条件基準日
     ,ov_errbuf               => lv_errbuf          -- エラーメッセージ
     ,ov_retcode              => lv_retcode         -- リターン・コード(0:正常、2:エラー)
     ,ov_errmsg               => lv_errmsg          -- ユーザー・エラーメッセージ
    );
--
    -- 戻り値セット
    IF ( lv_retcode <> cv_status_normal ) THEN
      RETURN NULL;
    ELSE
      RETURN ld_return;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_fresh_condition_date_f;
--
-- == 2014/11/07 Ver1.12 Y.Nagasue ADD END ======================================================
END XXCOI_COMMON_PKG;
/
