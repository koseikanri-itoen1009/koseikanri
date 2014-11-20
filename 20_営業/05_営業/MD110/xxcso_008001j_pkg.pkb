CREATE OR REPLACE PACKAGE BODY APPS.xxcso_008001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_008001j_pkg(BODY)
 * Description      : 週次活動状況照会画面共通関数
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_baseline_base_code    F    V      検索基準拠点コード取得関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   N.Yanagitaira    新規作成
 *  2009/04/10    1.1   N.Yanagitaira    [ST障害T1_0422,T1_0477]get_plan_or_result追加
 *
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_baseline_base_code        fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
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
              (SELECT xxcso_util_common_pkg.get_emp_parameter(
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
--
    lv_baseline_base_code := NULL;
--
    <<root_base_data_rec>>
    FOR root_base_data_rec IN root_base_data_cur
    LOOP
      -- child_base_codeの2番目が常にL3の第3階層
      IF (root_base_data_cur%ROWCOUNT = 2) THEN
        lv_baseline_base_code := root_base_data_rec.child_base_code;
        EXIT;
      END IF;
    END LOOP root_base_data_rec;
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
   * Function Name    : get_baseline_base_code
   * Description      : 検索基準拠点コード取得関数
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
END xxcso_008001j_pkg;
/
