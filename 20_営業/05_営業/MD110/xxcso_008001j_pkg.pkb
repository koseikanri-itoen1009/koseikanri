CREATE OR REPLACE PACKAGE BODY APPS.xxcso_008001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_008001j_pkg(BODY)
 * Description      : 週次活動状況照会画面共通関数
 * MD.050/070       : 
 * Version          : 1.3
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_baseline_base_code    F    V      検索基準拠点コード取得関数
 *  get_plan_or_result        F    V      予定実績出力文言取得関数
 *  get_init_base_code        F    V      初期表示拠点コード取得関数
 *  get_init_base_name        F    V      初期表示拠点名称取得関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   N.Yanagitaira    新規作成
 *  2009/04/10    1.1   N.Yanagitaira    [ST障害T1_0422,T1_0477]get_plan_or_result追加
 *  2009/05/21    1.2   N.Yanagitaira    [ST障害T1_1104]get_baseline_base_code修正
 *                                                      get_init_base_code追加
 *                                                      get_init_base_name追加
 *  2012/09/11    1.3   M.Nagai          E_本稼動_09619対応
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_y                CONSTANT VARCHAR2(1)   := 'Y';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso008001j_pkg';   -- パッケージ名
--
   /**********************************************************************************
   * Function Name    : get_baseline_base_code
   * Description      : 検索基準拠点コード取得関数
   ***********************************************************************************/
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_baseline_base_code';
-- 20090521_N.Yanagitaira T1_1104 Add START
    cv_manage_base_code          CONSTANT VARCHAR2(30)    := 'XXCSO1_MANAGE_BASE_CODE';
-- 20090521_N.Yanagitaira T1_1104 Add END
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD START */
    cv_week_aff                  CONSTANT VARCHAR2(30)    := 'XXCSO1_WEEKRY_TASK_AFF';
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD END */
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_baseline_base_code        fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
-- 20090521_N.Yanagitaira T1_1104 Add START
    lv_manage_base_code          fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
-- 20090521_N.Yanagitaira T1_1104 Add END
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD START */
    ln_week_aff                  NUMBER;
    ln_cnt                       NUMBER := 1;
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD END */
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR root_base_data_cur IS
    SELECT  LEVEL
           ,xablv.base_code       AS base_code
           ,xablv.child_base_code AS child_base_code
    FROM    xxcso_aff_base_level_v2 xablv
    START WITH
            xablv.child_base_code = 
              (
                SELECT xxcso_util_common_pkg.get_emp_parameter(
                        xev.work_base_code_new
                       ,xev.work_base_code_old
                       ,xev.issue_date
                       ,xxcso_util_common_pkg.get_online_sysdate
                      ) base_code
                FROM   xxcso_employees_v2 xev
                WHERE  xev.user_id = fnd_global.user_id
              )
    CONNECT BY NOCYCLE PRIOR
            xablv.base_code = xablv.child_base_code
    ORDER BY LEVEL DESC
    ;
--
  -- 検索基準拠点コード取得
  BEGIN
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD START */
    --プロファイル取得
    ln_week_aff := TO_NUMBER(fnd_profile.value(cv_week_aff));
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD END */
--
    lv_baseline_base_code := NULL;
-- 20090521_N.Yanagitaira T1_1104 Add START
    lv_manage_base_code   := FND_PROFILE.VALUE(cv_manage_base_code);
-- 20090521_N.Yanagitaira T1_1104 Add END
--
-- 20090521_N.Yanagitaira T1_1104 Mod START
--    <<root_base_data_rec>>
--    FOR root_base_data_rec IN root_base_data_cur
--    LOOP
--      -- child_base_codeの2番目が常にL3の第3階層
--      IF (root_base_data_cur%ROWCOUNT = 2) THEN
--        lv_baseline_base_code := root_base_data_rec.child_base_code;
--        EXIT;
--      END IF;
--    END LOOP root_base_data_rec;
    IF ( lv_manage_base_code IS NOT NULL ) THEN
--
      lv_baseline_base_code := lv_manage_base_code;
--
    ELSE
--
      <<root_base_data_rec>>
      FOR root_base_data_rec IN root_base_data_cur
      LOOP
--
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD START */
         --プロファイルで指定された階層が存在しない階層である場合の為、L1階層を保持する。
        IF ( ln_cnt = 1 ) THEN
          lv_baseline_base_code := root_base_data_rec.base_code;
        END IF;
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD END */
--
        -- child_base_codeの2番目が常にL3の第3階層
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 MOD START */
--        IF (root_base_data_cur%ROWCOUNT = 2) THEN
        IF ( root_base_data_cur%ROWCOUNT = ln_week_aff ) THEN
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 MOD END */
          lv_baseline_base_code := root_base_data_rec.child_base_code;
          EXIT;
        END IF;
--
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD START */
        ln_cnt := ln_cnt + 1;
/* 2012/09/11 Ver1.3 M.Nagai E_本稼動_09619対応 ADD END */
--
      END LOOP root_base_data_rec;
--
    END IF;
-- 20090521_N.Yanagitaira T1_1104 Mod START
--
    RETURN lv_baseline_base_code;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_baseline_base_code;
--
-- 20090410_N.Yanagitaira T1_0422,T1_0477 Add START
   /**********************************************************************************
   * Function Name    : get_plan_or_result
   * Description      : 予定実績出力文言取得関数
   ***********************************************************************************/
  FUNCTION get_plan_or_result(
    in_task_status_id           NUMBER
   ,in_task_type_id             NUMBER
   ,id_actual_end_date          DATE
   ,id_scheduled_end_date       DATE
   ,iv_source_object_type_code  VARCHAR2
   ,iv_task_party_name          VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                       CONSTANT VARCHAR2(100) := 'get_plan_or_result';
    cv_task_status_open               CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_STATUS_OPEN_ID';
    cv_task_status_closed             CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_STATUS_CLOSED_ID';
    cv_task_type_visit                CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_TYPE_VISIT';
    cv_source_object_type_party       CONSTANT VARCHAR2(30)  := 'PARTY';
    cv_source_object_type_oppor       CONSTANT VARCHAR2(30)  := 'OPPORTUNITY';
    cv_zero_time                      CONSTANT VARCHAR2(30)  := '00:00';
    cv_space                          CONSTANT VARCHAR2(2)   := '　';
    cv_pran_string                    CONSTANT VARCHAR2(2)   := '予';
    cv_result_string                  CONSTANT VARCHAR2(2)   := '実';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_task_status_id             VARCHAR2(100);
    lv_task_type_id               VARCHAR2(100);
    lv_return_value1              VARCHAR2(100);
    lv_return_value2              VARCHAR2(100);
    lv_return_value3              VARCHAR2(4000);
--
  BEGIN
--
    -- 初期化
    lv_task_status_id  := TO_CHAR(in_task_status_id);
    lv_task_type_id    := TO_CHAR(in_task_type_id);
    lv_return_value1   := NULL;
    lv_return_value2   := NULL;
    lv_return_value3   := NULL;
--
    -- ///////////////////
    -- 予／実 文言の設定
    -- ///////////////////
    -- ステータス:OPEN
    IF ( lv_task_status_id = FND_PROFILE.VALUE(cv_task_status_open) ) THEN
--
      lv_return_value1 := cv_pran_string;
--
    -- ステータス:CLOSE
    ELSIF ( lv_task_status_id = FND_PROFILE.VALUE(cv_task_status_closed) ) THEN
--
      -- 訪問の場合
      IF ( lv_task_type_id = FND_PROFILE.VALUE(cv_task_type_visit) ) THEN
--
        -- 訪問日時がNULL
        IF ( id_actual_end_date IS NULL ) THEN
--
            lv_return_value1 := cv_pran_string;
--
        ELSE
--
          -- 訪問日時が未来日付
          IF ( TRUNC(id_actual_end_date) > TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) THEN
--
            lv_return_value1 := cv_pran_string;
--
          -- 訪問日時が過去日付(現在日含む)
          ELSE
--
            lv_return_value1 := cv_result_string;
--
          END IF;
--
        END IF;
--
      -- 訪問以外の場合
      ELSE
--
        -- 訪問日時がNULL
        IF ( id_actual_end_date IS NULL ) THEN
--
            lv_return_value1 := cv_pran_string;
--
        ELSE
--
            lv_return_value1 := cv_result_string;
--
        END IF;
--
      END IF;
--
    -- 上記以外のステータスの場合
    ELSE
--
      lv_return_value1 := NULL;
--
    END IF;
--
    -- 文言へスペースの設定
    IF ( lv_return_value1 IS NOT NULL ) THEN
--
      lv_return_value1 := lv_return_value1 || cv_space;
--
    END IF;
--
    -- ///////////////////
    -- 時刻 文言の設定
    -- ///////////////////
    IF ( id_actual_end_date IS NOT NULL ) THEN
--
      lv_return_value2 := TO_CHAR(id_actual_end_date, 'hh24:mi');
--
    ELSIF ( id_actual_end_date IS NULL AND id_scheduled_end_date IS NOT NULL ) THEN
--
      lv_return_value2 := cv_zero_time;
--
    ELSE
--
      lv_return_value2 := NULL;
--
    END IF;
--
    -- ///////////////////
    -- 顧客名 文言の設定
    -- ///////////////////
    IF ( iv_source_object_type_code IN (cv_source_object_type_party, cv_source_object_type_oppor)  ) THEN
--
      lv_return_value3 := cv_space || iv_task_party_name;
--
    ELSE
--
      lv_return_value3 := NULL;
--
    END IF;
--
    RETURN lv_return_value1 || lv_return_value2 || lv_return_value3;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
--
  END get_plan_or_result;
-- 20090410_N.Yanagitaira T1_0422,T1_0477 Add END
--
-- 20090521_N.Yanagitaira T1_1104 Add START
   /**********************************************************************************
   * Function Name    : get_init_base_code
   * Description      : 初期表示拠点コード取得関数
   ***********************************************************************************/
  FUNCTION get_init_base_code
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_init_base_code';
    cv_manage_base_code          CONSTANT VARCHAR2(30)    := 'XXCSO1_MANAGE_BASE_CODE';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_init_base_code            fnd_flex_values.flex_value%TYPE;
    lv_manage_base_code          fnd_flex_values.flex_value%TYPE;
    lv_login_base_code           fnd_flex_values.flex_value%TYPE;

--
  BEGIN
--
    lv_init_base_code   := NULL;
    lv_manage_base_code := FND_PROFILE.VALUE(cv_manage_base_code);
    lv_login_base_code  := NULL;
--
    IF ( lv_manage_base_code IS NOT NULL ) THEN
--
      lv_init_base_code := lv_manage_base_code;
--
    ELSE
--
      BEGIN
        SELECT  XXCSO_UTIL_COMMON_PKG.get_emp_parameter(
                  xev.work_base_code_new
                 ,xev.work_base_code_old
                 ,xev.issue_date
                 ,TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
                )
        INTO    lv_login_base_code
        FROM    xxcso_employees_v2 xev
        WHERE   xev.user_id = FND_GLOBAL.user_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_login_base_code := NULL;
      END;
--
      lv_init_base_code := lv_login_base_code;
--
    END IF;

    RETURN lv_init_base_code;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
--
  END get_init_base_code;
--
   /**********************************************************************************
   * Function Name    : get_init_base_name
   * Description      : 初期表示拠点名称取得関数
   ***********************************************************************************/
  FUNCTION get_init_base_name
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_init_base_name';
    cv_manage_base_code          CONSTANT VARCHAR2(30)    := 'XXCSO1_MANAGE_BASE_CODE';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_init_base_name            fnd_flex_values.attribute4%TYPE;
    lv_manage_base_code          fnd_flex_values.flex_value%TYPE;
    lv_manage_base_name          fnd_flex_values.attribute4%TYPE;
    lv_login_base_name           fnd_flex_values.attribute4%TYPE;
--
  BEGIN
--
    lv_init_base_name   := NULL;
    lv_manage_base_code := FND_PROFILE.VALUE(cv_manage_base_code);
    lv_manage_base_name := NULL;
    lv_login_base_name  := NULL;
--
    IF ( lv_manage_base_code IS NOT NULL ) THEN
--
      BEGIN
        SELECT  xabv.base_name
        INTO    lv_manage_base_name
        FROM    xxcso_aff_base_v2 xabv
        WHERE   xabv.base_code = lv_manage_base_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_manage_base_name := NULL;
        WHEN TOO_MANY_ROWS THEN
          lv_manage_base_name := NULL;
      END;
--
      lv_init_base_name := lv_manage_base_name;
--
    ELSE
--
      BEGIN
        SELECT  XXCSO_UTIL_COMMON_PKG.get_emp_parameter(
                  xev.work_base_name_new
                 ,xev.work_base_name_old
                 ,xev.issue_date
                 ,TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
                )
        INTO    lv_login_base_name
        FROM    xxcso_employees_v2 xev
        WHERE   xev.user_id = FND_GLOBAL.user_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_login_base_name := NULL;
      END;
--
      lv_init_base_name := lv_login_base_name;
--
    END IF;

    RETURN lv_init_base_name;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
--
  END get_init_base_name;
-- 20090521_N.Yanagitaira T1_1104 Add END
--
END xxcso_008001j_pkg;
/
