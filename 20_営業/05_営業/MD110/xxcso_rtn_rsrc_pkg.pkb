CREATE OR REPLACE PACKAGE BODY apps.xxcso_rtn_rsrc_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_rtn_rsrc_pkg(BODY)
 * Description      : ルートNo/担当営業員更新処理関数
 * MD.050/070       :
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  regist_route_no           P    -     ルートNo登録関数
 *  unregist_route_no         P    -     ルートNo削除関数
 *  regist_resource_no        P    -     担当営業員登録関数
 *  unregist_resource_no      P    -     担当営業員削除関数
 *  get_org_profile_id        F    -     組織プロファイルID取得関数（private）
 *  get_attr_group_id         F    -     属性グループID取得関数（private）
 *  call_org_profile_ext_api  P    -     組織プロファイル拡張APIコール関数（private）
 *  regist_org_profile_ext    P    -     組織プロファイル拡張登録関数（private）
 *  unregist_org_profile_ext  P    -     組織プロファイル拡張削除関数（private）
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   H.Ogawa          新規作成
 *  2008/12/24    1.0   M.maruyama       ヘッダ修正(Oracle版からSCS版へ)
 *  2009/02/24    1.1   H.Ogawa          APIからの例外処理部を修正
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_util_common_pkg';   -- パッケージ名
  gv_flexfield_name   CONSTANT VARCHAR2(30)  := 'HZ_ORG_PROFILES_GROUP';   -- 組織プロファイル拡張
  gv_route_no_flex_code
                      CONSTANT VARCHAR2(10)  := 'ROUTE';            -- ルートNo
  gv_resource_no_flex_code
                      CONSTANT VARCHAR2(10)  := 'RESOURCE';         -- 担当営業員
  gv_appl_short_name_ar
                      CONSTANT VARCHAR2(10)  := 'AR';               -- AR
  gv_column_resource_no
                      CONSTANT VARCHAR2(30)  := 'RESOURCE_NO';      -- カラム名（担当営業員コード）
  gv_column_resource_s_date
                      CONSTANT VARCHAR2(30)  := 'RESOURCE_S_DATE';  -- カラム名（担当営業員開始日）
  gv_column_resource_e_date
                      CONSTANT VARCHAR2(30)  := 'RESOURCE_E_DATE';  -- カラム名（担当営業員終了日）
  gv_column_route_no
                      CONSTANT VARCHAR2(30)  := 'ROUTE_NO';         -- カラム名（ルートNoコード）
  gv_column_route_s_date
                      CONSTANT VARCHAR2(30)  := 'ROUTE_S_DATE';     -- カラム名（ルートNo開始日）
  gv_column_route_e_date
                      CONSTANT VARCHAR2(30)  := 'ROUTE_E_DATE';     -- カラム名（ルートNo終了日）
--
   /**********************************************************************************
   * Function Name    : get_org_profile_id
   * Description      : 組織プロファイルID取得関数（private）
   ***********************************************************************************/
  FUNCTION get_org_profile_id(
    iv_account_number            IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_org_profile_id';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_org_profile_id            NUMBER;
--
  BEGIN
    SELECT  hop.organization_profile_id
    INTO    ln_org_profile_id
    FROM    hz_cust_accounts          hca
           ,hz_parties                hp
           ,hz_organization_profiles  hop
    WHERE   hca.account_number        = iv_account_number
      AND   hp.party_id               = hca.party_id
      AND   hop.party_id              = hp.party_id
      AND   hop.effective_end_date    IS NULL
    ;
--
    RETURN ln_org_profile_id;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_org_profile_id;
--
   /**********************************************************************************
   * Function Name    : get_attr_group_id
   * Description      : 属性グループID取得関数（private）
   ***********************************************************************************/
  FUNCTION get_attr_group_id(
    iv_regist_class            IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_attr_group_id';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_attr_group_id            NUMBER;
--
  BEGIN
    SELECT  efdfce.attr_group_id
    INTO    ln_attr_group_id
    FROM    fnd_application            fa
           ,ego_fnd_dsc_flx_ctx_ext    efdfce
    WHERE   fa.application_short_name              = gv_appl_short_name_ar
      AND   efdfce.application_id                  = fa.application_id
      AND   efdfce.descriptive_flexfield_name      = gv_flexfield_name
      AND   efdfce.descriptive_flex_context_code   = iv_regist_class
    ;
--
    RETURN ln_attr_group_id;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_attr_group_id;
--
   /**********************************************************************************
   * Function Name    : call_org_profile_ext_api
   * Description      : 組織プロファイル拡張APIコール関数（private）
   ***********************************************************************************/
  PROCEDURE call_org_profile_ext_api(
    in_org_profile_id            IN  NUMBER           -- 組織プロファイルID
   ,in_attr_group_id             IN  NUMBER           -- 属性グループID
   ,iv_transaction_mode          IN  VARCHAR2         -- 登録モード
   ,iv_regist_class              IN  VARCHAR2         -- 登録区分（ルートNo、担当営業員）
   ,iv_regist_code               IN  VARCHAR2         -- 登録コード
   ,id_start_date                IN  DATE             -- 適用開始日
   ,id_end_date                  IN  DATE             -- 適用終了日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'regist_org_profile_ext';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_regist_code_column      VARCHAR2(30);
    lv_start_date_column       VARCHAR2(30);
    lv_end_date_column         VARCHAR2(30);
    lt_attributes_row_table    EGO_USER_ATTR_ROW_TABLE;
    lt_attributes_data_table   EGO_USER_ATTR_DATA_TABLE;
    lt_change_info_table       EGO_USER_ATTR_CHANGE_TABLE;
    lv_failed_row_id_list      VARCHAR2(1);
    lv_return_status           VARCHAR2(1);
    ln_errorcode               NUMBER;
    ln_msg_count               NUMBER;
    lv_msg_data                VARCHAR2(4000);
    lt_errors                  error_handler.error_tbl_type;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    IF ( iv_regist_class = gv_resource_no_flex_code ) THEN
--
      lv_regist_code_column := gv_column_resource_no;
      lv_start_date_column  := gv_column_resource_s_date;
      lv_end_date_column    := gv_column_resource_e_date;
--
    ELSE
--
      lv_regist_code_column := gv_column_route_no;
      lv_start_date_column  := gv_column_route_s_date;
      lv_end_date_column    := gv_column_route_e_date;
--
    END IF;
--
    lt_attributes_row_table
      := EGO_USER_ATTR_ROW_TABLE(
           EGO_USER_ATTR_ROW_OBJ(
             1                                   -- ROW_IDENTIFIER
            ,in_attr_group_id                    -- ATTR_GROUP_ID
            ,NULL                                -- ATTR_GROUP_APP_ID
            ,NULL                                -- ATTR_GROUP_TYPE
            ,NULL                                -- ATTR_GROUP_NAME
            ,NULL                                -- DATA_LEVEL_1
            ,NULL                                -- DATA_LEVEL_2
            ,NULL                                -- DATA_LEVEL_3
            ,iv_transaction_mode                 -- TRANSACTION_TYPE
           )
         );
--
    lt_attributes_data_table
      := EGO_USER_ATTR_DATA_TABLE(
           EGO_USER_ATTR_DATA_OBJ(
             1                     -- ROW_IDENTIFIER
            ,lv_regist_code_column -- ATTR_NAME
            ,iv_regist_code        -- ATTR_VALUE_STR
            ,NULL                  -- ATTR_VALUE_NUM
            ,NULL                  -- ATTR_VALUE_DATE
            ,NULL                  -- ATTR_DISP_VALUE
            ,NULL                  -- ATTR_UNIT_OF_MEASURE
            ,NULL                  -- USER_ROW_IDENTIFIER
           )
          ,EGO_USER_ATTR_DATA_OBJ(
             1                     -- ROW_IDENTIFIER
            ,lv_start_date_column  -- ATTR_NAME
            ,NULL                  -- ATTR_VALUE_STR
            ,NULL                  -- ATTR_VALUE_NUM
            ,id_start_date         -- ATTR_VALUE_DATE
            ,NULL                  -- ATTR_DISP_VALUE
            ,NULL                  -- ATTR_UNIT_OF_MEASURE
            ,NULL                  -- USER_ROW_IDENTIFIER
           )
          ,EGO_USER_ATTR_DATA_OBJ(
             1                     -- ROW_IDENTIFIER
            ,lv_end_date_column    -- ATTR_NAME
            ,NULL                  -- ATTR_VALUE_STR
            ,NULL                  -- ATTR_VALUE_NUM
            ,id_end_date           -- ATTR_VALUE_DATE
            ,NULL                  -- ATTR_DISP_VALUE
            ,NULL                  -- ATTR_UNIT_OF_MEASURE
            ,NULL                  -- USER_ROW_IDENTIFIER
           )
         );
--
    HZ_EXTENSIBILITY_PUB.Process_Organization_Record(
       p_api_version             => 1.0
      ,p_org_profile_id          => in_org_profile_id
      ,p_attributes_row_table    => lt_attributes_row_table
      ,p_attributes_data_table   => lt_attributes_data_table
      ,p_commit                  => FND_API.G_FALSE
      ,x_failed_row_id_list      => lv_failed_row_id_list
      ,x_return_status           => lv_return_status
      ,x_errorcode               => ln_errorcode
      ,x_msg_count               => ln_msg_count
      ,x_msg_data                => lv_msg_data
    );
--
    IF (LENGTH(ln_msg_count) > 0) THEN
--
      DECLARE
--
        
--
      BEGIN
--
        ERROR_HANDLER.Get_Message_List(lt_errors);
--
        FOR i IN 1..lt_errors.COUNT
        LOOP
--
          ov_retcode := xxcso_common_pkg.gv_status_error;
          ov_errbuf  := SUBSTRB(ov_errbuf || lt_errors(i).message_text, 1, 4000);
--
        END LOOP;
--
      END;
--
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END call_org_profile_ext_api;
--
   /**********************************************************************************
   * Function Name    : regist_org_profile_ext
   * Description      : 組織プロファイル拡張登録関数（private）
   ***********************************************************************************/
  PROCEDURE regist_org_profile_ext(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_regist_class              IN  VARCHAR2         -- 登録区分（ルートNo、担当営業員）
   ,iv_regist_code               IN  VARCHAR2         -- 登録コード
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'regist_org_profile_ext';
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- 後データ（担当営業員）
    CURSOR get_after_resource_no_cur(
      in_org_profile_id  IN  NUMBER
     ,in_attr_group_id   IN  NUMBER
     ,id_start_date      IN  DATE
    )
    IS
      SELECT  hopeb.c_ext_attr1
             ,hopeb.d_ext_attr1
             ,hopeb.d_ext_attr2
      FROM    hz_org_profiles_ext_b      hopeb
      WHERE   hopeb.attr_group_id                    = in_attr_group_id
        AND   hopeb.organization_profile_id          = in_org_profile_id
        AND   hopeb.d_ext_attr1                      > id_start_date
      ORDER BY hopeb.d_ext_attr1
      ;
--
    -- 後データ（ルートNo）
    CURSOR get_after_route_no_cur(
      in_org_profile_id  IN  NUMBER
     ,in_attr_group_id   IN  NUMBER
     ,id_start_date      IN  DATE
    )
    IS
      SELECT  hopeb.c_ext_attr2
             ,hopeb.d_ext_attr3
             ,hopeb.d_ext_attr4
      FROM    hz_org_profiles_ext_b      hopeb
      WHERE   hopeb.attr_group_id                    = in_attr_group_id
        AND   hopeb.organization_profile_id          = in_org_profile_id
        AND   hopeb.d_ext_attr3                      > id_start_date
      ORDER BY hopeb.d_ext_attr3
      ;
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_org_profile_id            NUMBER;
    ln_attr_group_id             NUMBER;
    lv_before_regist_code        VARCHAR2(150);
    ld_before_start_date         DATE;
    ld_before_end_date           DATE;
    lb_before_data_exist         BOOLEAN;
    lv_after_regist_code         VARCHAR2(150);
    ld_after_start_date          DATE;
    ld_after_end_date            DATE;
    ld_target_end_date           DATE;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    lb_before_data_exist := TRUE;
--
    -- 組織プロファイルID取得
    ln_org_profile_id := get_org_profile_id(
                           iv_account_number => iv_account_number
                         );
--
    -- 属性グループID取得
    ln_attr_group_id := get_attr_group_id(iv_regist_class);
--
    -----------------------------------------------
    -- 前データ取得
    -----------------------------------------------
    IF ( iv_regist_class = gv_resource_no_flex_code ) THEN
--
      -- 適用開始日をまたぐ前データ（担当営業員）を取得する
      BEGIN
--
        SELECT  hopeb.c_ext_attr1
               ,hopeb.d_ext_attr1
               ,hopeb.d_ext_attr2
        INTO    lv_before_regist_code
               ,ld_before_start_date
               ,ld_before_end_date
        FROM    hz_org_profiles_ext_b      hopeb
        WHERE   hopeb.attr_group_id                    = ln_attr_group_id
          AND   hopeb.organization_profile_id          = ln_org_profile_id
          AND   hopeb.d_ext_attr1                      < id_start_date
          AND   NVL(hopeb.d_ext_attr2, id_start_date) >= id_start_date
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 取得できなかった場合は前データの更新を行わない
          -- 同じ日付のレコードは更新
          lb_before_data_exist := FALSE;
      END;
--
    ELSE
--
      -- 適用開始日をまたぐ前データ（ルートNo）を取得する
      BEGIN
--
        SELECT  hopeb.c_ext_attr2
               ,hopeb.d_ext_attr3
               ,hopeb.d_ext_attr4
        INTO    lv_before_regist_code
               ,ld_before_start_date
               ,ld_before_end_date
        FROM    hz_org_profiles_ext_b      hopeb
        WHERE   hopeb.attr_group_id                    = ln_attr_group_id
          AND   hopeb.organization_profile_id          = ln_org_profile_id
          AND   hopeb.d_ext_attr3                      < id_start_date
          AND   NVL(hopeb.d_ext_attr4, id_start_date) >= id_start_date
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 取得できなかった場合は前データの更新を行わない
          -- 同じ日付のレコードは更新
          lb_before_data_exist := FALSE;
      END;
--
    END IF;
--
    -----------------------------------------------
    -- 前データ更新
    -----------------------------------------------
    IF ( lb_before_data_exist ) THEN
--
      ld_before_end_date := id_start_date - 1;
--
      call_org_profile_ext_api(
        in_org_profile_id   => ln_org_profile_id
       ,in_attr_group_id    => ln_attr_group_id
       ,iv_transaction_mode => EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE
       ,iv_regist_class     => iv_regist_class
       ,iv_regist_code      => lv_before_regist_code
       ,id_start_date       => ld_before_start_date
       ,id_end_date         => ld_before_end_date
       ,ov_errbuf           => ov_errbuf
       ,ov_retcode          => ov_retcode
       ,ov_errmsg           => ov_errmsg
      );
--
      IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
        RETURN;
--
      END IF;
--
    END IF;
--
    -----------------------------------------------
    -- 後データ取得
    -----------------------------------------------
    IF ( iv_regist_class = gv_resource_no_flex_code ) THEN
--
      -- 適用開始日より未来のデータ（担当営業員）で直近のデータを取得する
      << after_resource_no_loop >>
      FOR resource_no_rec IN get_after_resource_no_cur(
                               ln_org_profile_id
                              ,ln_attr_group_id
                              ,id_start_date
                             )
      LOOP
--
        lv_after_regist_code := resource_no_rec.c_ext_attr1;
        ld_after_start_date  := resource_no_rec.d_ext_attr1;
        ld_after_end_date    := resource_no_rec.d_ext_attr2;
        EXIT;
--
      END LOOP after_resource_no_loop;
--
    ELSE
--
      -- 適用開始日より未来のデータ（ルート）で直近のデータを取得する
      << after_route_no_loop >>
      FOR route_no_rec IN get_after_route_no_cur(
                            ln_org_profile_id
                           ,ln_attr_group_id
                           ,id_start_date
                          )
      LOOP
--
        lv_after_regist_code := route_no_rec.c_ext_attr2;
        ld_after_start_date  := route_no_rec.d_ext_attr3;
        ld_after_end_date    := route_no_rec.d_ext_attr4;
        EXIT;
--
      END LOOP after_route_no_loop;
--
    END IF;
--
    -----------------------------------------------
    -- 対象データ更新
    -----------------------------------------------
    IF ( ld_after_start_date IS NOT NULL ) THEN
--
      ld_target_end_date := ld_after_start_date - 1;
--
    END IF;
--
    call_org_profile_ext_api(
      in_org_profile_id   => ln_org_profile_id
     ,in_attr_group_id    => ln_attr_group_id
     ,iv_transaction_mode => EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE
     ,iv_regist_class     => iv_regist_class
     ,iv_regist_code      => iv_regist_code
     ,id_start_date       => id_start_date
     ,id_end_date         => ld_target_end_date
     ,ov_errbuf           => ov_errbuf
     ,ov_retcode          => ov_retcode
     ,ov_errmsg           => ov_errmsg
    );
--
    IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
      RETURN;
--
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END regist_org_profile_ext;
--
   /**********************************************************************************
   * Function Name    : unregist_org_profile_ext
   * Description      : 組織プロファイル拡張削除関数（private）
   ***********************************************************************************/
  PROCEDURE unregist_org_profile_ext(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_regist_class              IN  VARCHAR2         -- 登録区分（ルートNo、担当営業員）
   ,iv_regist_code               IN  VARCHAR2         -- 登録コード
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'regist_org_profile_ext';
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- 前データ（担当営業員）
    CURSOR get_before_resource_no_cur(
      in_org_profile_id  IN  NUMBER
     ,in_attr_group_id   IN  NUMBER
     ,id_start_date      IN  DATE
    )
    IS
      SELECT  hopeb.c_ext_attr1
             ,hopeb.d_ext_attr1
             ,hopeb.d_ext_attr2
      FROM    hz_org_profiles_ext_b      hopeb
      WHERE   hopeb.attr_group_id                    = in_attr_group_id
        AND   hopeb.organization_profile_id          = in_org_profile_id
        AND   hopeb.d_ext_attr1                      < id_start_date
      ORDER BY hopeb.d_ext_attr1 DESC
      ;
--
    -- 前データ（ルートNo）
    CURSOR get_before_route_no_cur(
      in_org_profile_id  IN  NUMBER
     ,in_attr_group_id   IN  NUMBER
     ,id_start_date      IN  DATE
    )
    IS
      SELECT  hopeb.c_ext_attr2
             ,hopeb.d_ext_attr3
             ,hopeb.d_ext_attr4
      FROM    hz_org_profiles_ext_b      hopeb
      WHERE   hopeb.attr_group_id                    = in_attr_group_id
        AND   hopeb.organization_profile_id          = in_org_profile_id
        AND   hopeb.d_ext_attr3                      < id_start_date
      ORDER BY hopeb.d_ext_attr3 DESC
      ;
--
    -- 後データ（担当営業員）
    CURSOR get_after_resource_no_cur(
      in_org_profile_id  IN  NUMBER
     ,in_attr_group_id   IN  NUMBER
     ,id_start_date      IN  DATE
    )
    IS
      SELECT  hopeb.c_ext_attr1
             ,hopeb.d_ext_attr1
             ,hopeb.d_ext_attr2
      FROM    hz_org_profiles_ext_b      hopeb
      WHERE   hopeb.attr_group_id                    = in_attr_group_id
        AND   hopeb.organization_profile_id          = in_org_profile_id
        AND   hopeb.d_ext_attr1                      > id_start_date
      ORDER BY hopeb.d_ext_attr1
      ;
--
    -- 後データ（ルートNo）
    CURSOR get_after_route_no_cur(
      in_org_profile_id  IN  NUMBER
     ,in_attr_group_id   IN  NUMBER
     ,id_start_date      IN  DATE
    )
    IS
      SELECT  hopeb.c_ext_attr2
             ,hopeb.d_ext_attr3
             ,hopeb.d_ext_attr4
      FROM    hz_org_profiles_ext_b      hopeb
      WHERE   hopeb.attr_group_id                    = in_attr_group_id
        AND   hopeb.organization_profile_id          = in_org_profile_id
        AND   hopeb.d_ext_attr3                      > id_start_date
      ORDER BY hopeb.d_ext_attr3
      ;
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_org_profile_id            NUMBER;
    ln_attr_group_id             NUMBER;
    ln_target_count              NUMBER;
    lv_before_regist_code        VARCHAR2(150);
    ld_before_start_date         DATE;
    ld_before_end_date           DATE;
    lv_after_regist_code         VARCHAR2(150);
    ld_after_start_date          DATE;
    ld_after_end_date            DATE;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- 組織プロファイルID取得
    ln_org_profile_id := get_org_profile_id(
                           iv_account_number => iv_account_number
                         );
--
    -- 属性グループID取得
    ln_attr_group_id := get_attr_group_id(iv_regist_class);
--
    -----------------------------------------------
    -- 対象データ確認
    -----------------------------------------------
    IF ( iv_regist_class = gv_resource_no_flex_code ) THEN
--
      SELECT  COUNT('x')
      INTO    ln_target_count
      FROM    hz_org_profiles_ext_b   hopeb
      WHERE   hopeb.organization_profile_id = ln_org_profile_id
        AND   hopeb.attr_group_id           = ln_attr_group_id
        AND   hopeb.d_ext_attr1             = id_start_date
      ;
--
    ELSE
--
      SELECT  COUNT('x')
      INTO    ln_target_count
      FROM    hz_org_profiles_ext_b   hopeb
      WHERE   hopeb.organization_profile_id = ln_org_profile_id
        AND   hopeb.attr_group_id           = ln_attr_group_id
        AND   hopeb.d_ext_attr3             = id_start_date
      ;
--
    END IF;
--
    IF ( ln_target_count > 0 ) THEN
--
      call_org_profile_ext_api(
        in_org_profile_id   => ln_org_profile_id
       ,in_attr_group_id    => ln_attr_group_id
       ,iv_transaction_mode => EGO_USER_ATTRS_DATA_PVT.G_DELETE_MODE
       ,iv_regist_class     => iv_regist_class
       ,iv_regist_code      => iv_regist_code
       ,id_start_date       => id_start_date
       ,id_end_date         => NULL
       ,ov_errbuf           => ov_errbuf
       ,ov_retcode          => ov_retcode
       ,ov_errmsg           => ov_errmsg
      );
--
    END IF;
--
    IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
      RETURN;
--
    END IF;
--
    -----------------------------------------------
    -- 前データ取得
    -----------------------------------------------
    IF ( iv_regist_class = gv_resource_no_flex_code ) THEN
--
      -- 適用開始日より過去のデータ（担当営業員）で直近のデータを取得する
      << before_resource_no_loop >>
      FOR resource_no_rec IN get_before_resource_no_cur(
                               ln_org_profile_id
                              ,ln_attr_group_id
                              ,id_start_date
                             )
      LOOP
--
        lv_before_regist_code := resource_no_rec.c_ext_attr1;
        ld_before_start_date  := resource_no_rec.d_ext_attr1;
        ld_before_end_date    := resource_no_rec.d_ext_attr2;
        EXIT;
--
      END LOOP before_resource_no_loop;
--
    ELSE
--
      -- 適用開始日より過去のデータ（ルートNo）で直近のデータを取得する
      << before_route_no_loop >>
      FOR route_no_rec IN get_before_route_no_cur(
                            ln_org_profile_id
                           ,ln_attr_group_id
                           ,id_start_date
                          )
      LOOP
--
        lv_before_regist_code := route_no_rec.c_ext_attr2;
        ld_before_start_date  := route_no_rec.d_ext_attr3;
        ld_before_end_date    := route_no_rec.d_ext_attr4;
        EXIT;
--
      END LOOP before_route_no_loop;
--
    END IF;
--
    -----------------------------------------------
    -- 後データ取得
    -----------------------------------------------
    IF ( iv_regist_class = gv_resource_no_flex_code ) THEN
--
      -- 適用開始日より未来のデータ（担当営業員）で直近のデータを取得する
      << after_resource_no_loop >>
      FOR resource_no_rec IN get_after_resource_no_cur(
                               ln_org_profile_id
                              ,ln_attr_group_id
                              ,id_start_date
                             )
      LOOP
--
        lv_after_regist_code := resource_no_rec.c_ext_attr1;
        ld_after_start_date  := resource_no_rec.d_ext_attr1;
        ld_after_end_date    := resource_no_rec.d_ext_attr2;
        EXIT;
--
      END LOOP after_resource_no_loop;
--
    ELSE
--
      -- 適用開始日より未来のデータ（ルートNo）で直近のデータを取得する
      << after_route_no_loop >>
      FOR route_no_rec IN get_after_route_no_cur(
                            ln_org_profile_id
                           ,ln_attr_group_id
                           ,id_start_date
                          )
      LOOP
--
        lv_after_regist_code := route_no_rec.c_ext_attr2;
        ld_after_start_date  := route_no_rec.d_ext_attr3;
        ld_after_end_date    := route_no_rec.d_ext_attr4;
        EXIT;
--
      END LOOP after_route_no_loop;
--
    END IF;
--
    -----------------------------------------------
    -- 前データ更新
    -----------------------------------------------
    IF ( ld_before_start_date IS NOT NULL ) THEN
--
      IF ( ld_after_start_date IS NOT NULL ) THEN
--
        ld_before_end_date := ld_after_start_date - 1;
--
      ELSE
--
        ld_before_end_date := NULL;
--
      END IF;
--
      call_org_profile_ext_api(
        in_org_profile_id   => ln_org_profile_id
       ,in_attr_group_id    => ln_attr_group_id
       ,iv_transaction_mode => EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE
       ,iv_regist_class     => iv_regist_class
       ,iv_regist_code      => lv_before_regist_code
       ,id_start_date       => ld_before_start_date
       ,id_end_date         => ld_before_end_date
       ,ov_errbuf           => ov_errbuf
       ,ov_retcode          => ov_retcode
       ,ov_errmsg           => ov_errmsg
      );
--
      IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
        RETURN;
--
      END IF;
--
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END unregist_org_profile_ext;
--
   /**********************************************************************************
   * Function Name    : regist_route_no
   * Description      : ルートNo登録関数
   ***********************************************************************************/
  PROCEDURE regist_route_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_route_no                  IN  VARCHAR2         -- ルートNo
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'regist_route_no';
    -- ===============================
    -- ローカル変数
    -- ===============================
--
  BEGIN
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    regist_org_profile_ext(
      iv_account_number  => iv_account_number
     ,iv_regist_class    => gv_route_no_flex_code
     ,iv_regist_code     => iv_route_no
     ,id_start_date      => id_start_date
     ,ov_errbuf          => ov_errbuf
     ,ov_retcode         => ov_retcode
     ,ov_errmsg          => ov_errmsg
    );
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END regist_route_no;
--
   /**********************************************************************************
   * Function Name    : unregist_route_no
   * Description      : ルートNo削除関数
   ***********************************************************************************/
  PROCEDURE unregist_route_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_route_no                  IN  VARCHAR2         -- ルートNo
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'unregist_route_no';
    -- ===============================
    -- ローカル変数
    -- ===============================
--
  BEGIN
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    unregist_org_profile_ext(
      iv_account_number  => iv_account_number
     ,iv_regist_class    => gv_route_no_flex_code
     ,iv_regist_code     => iv_route_no
     ,id_start_date      => id_start_date
     ,ov_errbuf          => ov_errbuf
     ,ov_retcode         => ov_retcode
     ,ov_errmsg          => ov_errmsg
    );
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END unregist_route_no;
--
   /**********************************************************************************
   * Function Name    : regist_resource_no
   * Description      : 担当営業員登録関数
   ***********************************************************************************/
  PROCEDURE regist_resource_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_resource_no               IN  VARCHAR2         -- 担当営業員（従業員コード）
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'regist_resource_no';
    -- ===============================
    -- ローカル変数
    -- ===============================
--
  BEGIN
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    regist_org_profile_ext(
      iv_account_number  => iv_account_number
     ,iv_regist_class    => gv_resource_no_flex_code
     ,iv_regist_code     => iv_resource_no
     ,id_start_date      => id_start_date
     ,ov_errbuf          => ov_errbuf
     ,ov_retcode         => ov_retcode
     ,ov_errmsg          => ov_errmsg
    );
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END regist_resource_no;
--
   /**********************************************************************************
   * Function Name    : unregist_resource_no
   * Description      : 担当営業員削除関数
   ***********************************************************************************/
  PROCEDURE unregist_resource_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_resource_no               IN  VARCHAR2         -- 担当営業員（従業員コード）
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'unregist_resource_no';
    -- ===============================
    -- ローカル変数
    -- ===============================
--
  BEGIN
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    unregist_org_profile_ext(
      iv_account_number  => iv_account_number
     ,iv_regist_class    => gv_resource_no_flex_code
     ,iv_regist_code     => iv_resource_no
     ,id_start_date      => id_start_date
     ,ov_errbuf          => ov_errbuf
     ,ov_retcode         => ov_retcode
     ,ov_errmsg          => ov_errmsg
    );
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END unregist_resource_no;
--
END xxcso_rtn_rsrc_pkg;
/
