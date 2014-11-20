CREATE OR REPLACE PACKAGE BODY APPS.xxcso_task_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_TASK_COMMON_PKG(BODY)
 * Description      : 共通関数(XXCSOタスク）
 * MD.050/070       :
 * Version          : 1.4
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  create_task               P    -     訪問タスク登録関数
 *  update_task               P    -     訪問タスク更新関数
 *  delete_task               P    -     訪問タスク削除関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   K.Cho            新規作成
 *  2008/12/16    1.0   T.maruyama       訪問タスク削除関数
 *  2008/12/25    1.0   M.maruyama       API起動処理のOUTパラメータ'gx_return_status'の正常終了
 *                                       判定値を'S'から'fnd_api.g_ret_sts_success'へ変更
 *  2009/05/01    1.1   Tomoko.Mori      T1_0897対応
 *  2009/05/22    1.2   K.Satomura       T1_1080対応
 *  2009/07/16    1.3   K.Satomura       0000070対応
 *  2009/10/23    1.4   Daisuke.Abe      障害対応(E_T4_00056)
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_task_common_pkg';   -- パッケージ名
  cv_app_name         CONSTANT VARCHAR2(5)   := 'XXCSO';                   -- アプリケーション短縮名
  cv_msg_part         CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)   := '.';

  --*** 処理部共通例外 ***
  g_process_expt      EXCEPTION;
  --*** 共通関数例外 ***
  g_api_expt          EXCEPTION;
--
   /**********************************************************************************
   * Function Name    : create_task
   * Description      : 訪問タスク登録処理
   ***********************************************************************************/
  PROCEDURE create_task(
    in_resource_id           IN  NUMBER,                 -- 営業員コードのリソースID
    in_party_id              IN  NUMBER,                 -- 顧客のパーティID
    iv_party_name            IN  VARCHAR2,               -- 顧客のパーティ名称
    id_visit_date            IN  DATE,                   -- 実績終了日（訪問日時）
    iv_description           IN  VARCHAR2 DEFAULT NULL,  -- 詳細内容
    /* 2009.07.16 K.Satomura 0000070対応 START */
    it_task_status_id        IN  jtf_task_statuses_b.task_status_id%TYPE DEFAULT NULL,-- タスクステータスＩＤ
    /* 2009.07.16 K.Satomura 0000070対応 END */
    iv_attribute1            IN  VARCHAR2 DEFAULT NULL,  -- DFF1
    iv_attribute2            IN  VARCHAR2 DEFAULT NULL,  -- DFF2
    iv_attribute3            IN  VARCHAR2 DEFAULT NULL,  -- DFF3
    iv_attribute4            IN  VARCHAR2 DEFAULT NULL,  -- DFF4
    iv_attribute5            IN  VARCHAR2 DEFAULT NULL,  -- DFF5
    iv_attribute6            IN  VARCHAR2 DEFAULT NULL,  -- DFF6
    iv_attribute7            IN  VARCHAR2 DEFAULT NULL,  -- DFF7
    iv_attribute8            IN  VARCHAR2 DEFAULT NULL,  -- DFF8
    iv_attribute9            IN  VARCHAR2 DEFAULT NULL,  -- DFF9
    iv_attribute10           IN  VARCHAR2 DEFAULT NULL,  -- DFF10
    iv_attribute11           IN  VARCHAR2 DEFAULT NULL,  -- DFF11
    iv_attribute12           IN  VARCHAR2 DEFAULT NULL,  -- DFF12
    iv_attribute13           IN  VARCHAR2 DEFAULT NULL,  -- DFF13
    iv_attribute14           IN  VARCHAR2 DEFAULT NULL,  -- DFF14
    on_task_id               OUT NUMBER,                 -- タスクID
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'create_task';
--
    -- プロファイル・オプション
    cv_prfnm_visit_task_name         CONSTANT VARCHAR2(100) := 'XXCSO1_VISIT_TASK_NAME'; -- タスク名称
    cv_prfnm_task_type_name          CONSTANT VARCHAR2(100) := 'XXCSO1_HHT_TASK_TYPE'; -- タスクタイプ名称
    cv_prfnm_task_status_closed_id   CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_CLOSED_ID'; -- タスクステータス
--
    -- メッセージコード
    cv_tkn_number_01           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- プロファイル取得エラー
    cv_tkn_number_02           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00155';  -- 抽出エラー
--
    -- トークンコード
    cv_tkn_err_msg             CONSTANT VARCHAR2(20) := 'ERR_MSG';
    cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
    cv_tkn_task_nm             CONSTANT VARCHAR2(20) := 'TASK_NAME';
--
    cv_task_type_id_nm         CONSTANT VARCHAR2(100) := 'タスクタイプID';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    lv_task_name               VARCHAR2(100); -- タスク名称
    lv_task_type_name          VARCHAR2(100); -- タスクタイプ名称
    ln_task_type_id            NUMBER;        -- タスクタイプID
    lv_task_status_id          VARCHAR2(100); -- タスクステータスID
    ln_task_status_id          NUMBER;        -- タスクステータスID
--
    -- API戻り値
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- *** タスク名称取得 ***
    FND_PROFILE.GET(
                  cv_prfnm_visit_task_name
                 ,lv_task_name
    ); 
    -- 取得した値がない場合
    IF (lv_task_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_nm               -- トークンコード1
                     ,iv_token_value1 => cv_prfnm_visit_task_name     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
--
    -- *** タスクタイプID取得 ***
    -- タスクタイプ名称取得
    FND_PROFILE.GET(
                  cv_prfnm_task_type_name
                 ,lv_task_type_name
    ); 
    -- 取得した値がない場合
    IF (lv_task_type_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_nm               -- トークンコード1
                     ,iv_token_value1 => cv_prfnm_task_type_name      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
    -- タスクタイプID取得
    BEGIN
--
      SELECT jttv.task_type_id
      INTO ln_task_type_id
      FROM jtf_task_types_vl jttv
      WHERE jttv.name = lv_task_type_name
        AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(jttv.start_date_active, SYSDATE))
        AND TRUNC(NVL(jttv.end_date_active, SYSDATE));
    EXCEPTION
      WHEN OTHERS THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_02             -- メッセージコード
                      ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                      ,iv_token_value1 => cv_task_type_id_nm      -- トークン値1
                      ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード1
                      ,iv_token_value2 => SQLERRM      -- トークン値1
                    );
       lv_errbuf := lv_errmsg;
       RAISE g_process_expt;
    END;
--
    -- *** タスクステータスID ***
    /* 2009.07.16 K.Satomura 0000070対応 START */
    IF (it_task_status_id IS NULL) THEN
    /* 2009.07.16 K.Satomura 0000070対応 END */
      FND_PROFILE.GET(
                    cv_prfnm_task_status_closed_id
                   ,lv_task_status_id
      ); 
      -- 取得失敗した場合
      IF (lv_task_status_id IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_prof_nm                 -- トークンコード1
                       ,iv_token_value1 => cv_prfnm_task_status_closed_id -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE g_process_expt;
      ELSE
        ln_task_status_id := TO_NUMBER(lv_task_status_id);
      END IF;
    /* 2009.07.16 K.Satomura 0000070対応 START */
    ELSE
      ln_task_status_id := it_task_status_id;
      --
    END IF;
    /* 2009.07.16 K.Satomura 0000070対応 END */
--
    ------------------
    ---- API 起動 ----
    ------------------
    JTF_TASKS_PUB.CREATE_TASK(
       p_api_version             => 1.0                      -- バージョンナンバー
      ,p_task_name               => lv_task_name             -- タスク名称
      ,p_task_type_id            => ln_task_type_id          -- タスクタイプID
      ,p_description             => iv_description           -- 摘要
      ,p_task_status_id          => ln_task_status_id        -- タスクステータス
      ,p_owner_type_code         => 'RS_EMPLOYEE'            -- タスク所有者タイプコード
      ,p_owner_id                => in_resource_id           -- タスク所有者ID
      /* 2009.05.22 K.Satomura T1_1080対応 START */
      ,p_customer_id             => in_party_id              -- パーティーID
      /* 2009.05.22 K.Satomura T1_1080対応 END */
      ,p_scheduled_end_date      => TRUNC(id_visit_date)     -- 予定終了日時
      ,p_actual_end_date         => id_visit_date            -- 実績終了日時
      ,p_source_object_type_code => 'PARTY'                  -- ソースオブジェクトコード
      ,p_source_object_id        => in_party_id              -- ソースオブジェクトID
      ,p_source_object_name      => iv_party_name            -- ソースオブジェクト名称
      ,p_attribute1              => iv_attribute1
      ,p_attribute2              => iv_attribute2
      ,p_attribute3              => iv_attribute3
      ,p_attribute4              => iv_attribute4
      ,p_attribute5              => iv_attribute5
      ,p_attribute6              => iv_attribute6
      ,p_attribute7              => iv_attribute7
      ,p_attribute8              => iv_attribute8
      ,p_attribute9              => iv_attribute9
      ,p_attribute10             => iv_attribute10
      ,p_attribute11             => iv_attribute11
      ,p_attribute12             => iv_attribute12
      ,p_attribute13             => iv_attribute13
      ,p_attribute14             => iv_attribute14
      ,p_attribute_category      => NULL
      ,x_task_id                 => on_task_id
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** 処理部例外 ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API例外 ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END create_task;
--
   /**********************************************************************************
   * Function Name    : update_task
   * Description      : 訪問タスク更新処理
   ***********************************************************************************/
  PROCEDURE update_task(
    in_task_id               IN  NUMBER,                 -- タスクID
    in_resource_id           IN  NUMBER,                 -- 営業員コードのリソースID
    in_party_id              IN  NUMBER,                 -- 顧客のパーティID
    iv_party_name            IN  VARCHAR2,               -- 顧客のパーティ名称
    id_visit_date            IN  DATE,                   -- 実績終了日（訪問日時）
    iv_description           IN  VARCHAR2 DEFAULT NULL,  -- 詳細内容
    in_obj_ver_num           IN  NUMBER,                 -- オブジェクトバージョン番号
    /* 2009.07.16 K.Satomura 0000070対応 START */
    it_task_status_id        IN  jtf_task_statuses_b.task_status_id%TYPE DEFAULT NULL,-- タスクステータスＩＤ
    /* 2009.07.16 K.Satomura 0000070対応 END */
    iv_attribute1            IN  VARCHAR2 DEFAULT NULL,  -- DFF1
    iv_attribute2            IN  VARCHAR2 DEFAULT NULL,  -- DFF2
    iv_attribute3            IN  VARCHAR2 DEFAULT NULL,  -- DFF3
    iv_attribute4            IN  VARCHAR2 DEFAULT NULL,  -- DFF4
    iv_attribute5            IN  VARCHAR2 DEFAULT NULL,  -- DFF5
    iv_attribute6            IN  VARCHAR2 DEFAULT NULL,  -- DFF6
    iv_attribute7            IN  VARCHAR2 DEFAULT NULL,  -- DFF7
    iv_attribute8            IN  VARCHAR2 DEFAULT NULL,  -- DFF8
    iv_attribute9            IN  VARCHAR2 DEFAULT NULL,  -- DFF9
    iv_attribute10           IN  VARCHAR2 DEFAULT NULL,  -- DFF10
    iv_attribute11           IN  VARCHAR2 DEFAULT NULL,  -- DFF11
    iv_attribute12           IN  VARCHAR2 DEFAULT NULL,  -- DFF12
    iv_attribute13           IN  VARCHAR2 DEFAULT NULL,  -- DFF13
    iv_attribute14           IN  VARCHAR2 DEFAULT NULL,  -- DFF14
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'update_task';
--
    -- プロファイル・オプション
    cv_prfnm_visit_task_name         CONSTANT VARCHAR2(100) := 'XXCSO1_VISIT_TASK_NAME'; -- タスク名称
    cv_prfnm_task_type_name          CONSTANT VARCHAR2(100) := 'XXCSO1_HHT_TASK_TYPE'; -- タスクタイプ名称
    cv_prfnm_task_status_closed_id   CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_CLOSED_ID'; -- タスクステータス
--
    -- メッセージコード
    cv_tkn_number_01           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- プロファイル取得エラー
    cv_tkn_number_02           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00155';  -- 抽出エラー
--
    -- トークンコード
    cv_tkn_err_msg             CONSTANT VARCHAR2(20) := 'ERR_MSG';
    cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
    cv_tkn_task_nm             CONSTANT VARCHAR2(20) := 'TASK_NAME';
--
    cv_task_type_id_nm         CONSTANT VARCHAR2(100) := 'タスクタイプID';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    lv_task_name               jtf_tasks_tl.task_name%TYPE;             -- タスク名称
    lv_task_type_name          jtf_task_types_tl.name%TYPE;                           -- タスクタイプ名称
    ln_task_type_id            jtf_tasks_b.task_type_id%TYPE;           -- タスクタイプID
    lv_task_status_id          VARCHAR2(100);                           -- タスクステータスID
    ln_task_status_id          jtf_tasks_b.task_status_id%TYPE;         -- タスクステータスID
    ln_obj_ver_num             NUMBER;                 -- オブジェクトバージョン番号
--
    -- API戻り値
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- *** タスク名称取得 ***
    FND_PROFILE.GET(
                  cv_prfnm_visit_task_name
                 ,lv_task_name
    ); 
    -- 取得した値がない場合
    IF (lv_task_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_nm               -- トークンコード1
                     ,iv_token_value1 => cv_prfnm_visit_task_name     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
--
    -- *** タスクタイプID取得 ***
    -- タスクタイプ名称取得
    FND_PROFILE.GET(
                  cv_prfnm_task_type_name
                 ,lv_task_type_name
    ); 
    -- 取得した値がない場合
    IF (lv_task_type_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_nm               -- トークンコード1
                     ,iv_token_value1 => cv_prfnm_task_type_name      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
    -- タスクタイプID取得
    BEGIN
--
      SELECT jttv.task_type_id
      INTO ln_task_type_id
      FROM jtf_task_types_vl jttv
      WHERE jttv.name = lv_task_type_name
        AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(jttv.start_date_active, SYSDATE))
        AND TRUNC(NVL(jttv.end_date_active, SYSDATE));
    EXCEPTION
      WHEN OTHERS THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_02             -- メッセージコード
                      ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                      ,iv_token_value1 => cv_task_type_id_nm      -- トークン値1
                      ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード1
                      ,iv_token_value2 => SQLERRM      -- トークン値1
                    );
       lv_errbuf := lv_errmsg;
       RAISE g_process_expt;
    END;
--
    -- *** タスクステータスID ***
    /* 2009.07.16 K.Satomura 0000070対応 START */
    IF (it_task_status_id IS NULL) THEN
    /* 2009.07.16 K.Satomura 0000070対応 END */
      FND_PROFILE.GET(
                    cv_prfnm_task_status_closed_id
                   ,lv_task_status_id
      ); 
      -- 取得失敗した場合
      IF (lv_task_status_id IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_prof_nm                 -- トークンコード1
                       ,iv_token_value1 => cv_prfnm_task_status_closed_id -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE g_process_expt;
      ELSE
        ln_task_status_id := TO_NUMBER(lv_task_status_id);
      END IF;
    /* 2009.07.16 K.Satomura 0000070対応 START */
    ELSE
      ln_task_status_id := it_task_status_id;
      --
    END IF;
    /* 2009.07.16 K.Satomura 0000070対応 END */
--
    ln_obj_ver_num := in_obj_ver_num;
--
    ------------------
    ---- API 起動 ----
    ------------------
    JTF_TASKS_PUB.UPDATE_TASK(
       p_api_version             => 1.0                      -- バージョンナンバー
      ,p_task_id                 => in_task_id               -- タスクID
      ,p_task_name               => lv_task_name             -- タスク名称
      ,p_task_type_id            => ln_task_type_id          -- タスクタイプID
      ,p_description             => iv_description           -- 摘要
      ,p_task_status_id          => ln_task_status_id        -- タスクステータス
      ,p_owner_type_code         => 'RS_EMPLOYEE'            -- タスク所有者タイプコード
      ,p_owner_id                => in_resource_id           -- タスク所有者ID
      /* 2009.05.22 K.Satomura T1_1080対応 START */
      ,p_customer_id             => in_party_id              -- パーティーID
      /* 2009.05.22 K.Satomura T1_1080対応 END */
      ,p_scheduled_end_date      => TRUNC(id_visit_date)     -- 予定終了日時
      ,p_actual_end_date         => id_visit_date            -- 実績終了日時
      ,p_source_object_type_code => 'PARTY'                  -- ソースオブジェクトコード
      ,p_source_object_id        => in_party_id              -- ソースオブジェクトID
      ,p_source_object_name      => iv_party_name            -- ソースオブジェクト名称
      ,p_object_version_number   => ln_obj_ver_num
      ,p_attribute1              => iv_attribute1
      ,p_attribute2              => iv_attribute2
      ,p_attribute3              => iv_attribute3
      ,p_attribute4              => iv_attribute4
      ,p_attribute5              => iv_attribute5
      ,p_attribute6              => iv_attribute6
      ,p_attribute7              => iv_attribute7
      ,p_attribute8              => iv_attribute8
      ,p_attribute9              => iv_attribute9
      ,p_attribute10             => iv_attribute10
      ,p_attribute11             => iv_attribute11
      ,p_attribute12             => iv_attribute12
      ,p_attribute13             => iv_attribute13
      ,p_attribute14             => iv_attribute14
      ,p_attribute_category      => NULL
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** 処理部例外 ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API例外 ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END update_task;
--
   /**********************************************************************************
   * Function Name    : delete_task
   * Description      : 訪問タスク削除処理
   ***********************************************************************************/
  PROCEDURE delete_task(
    in_task_id               IN  NUMBER,                 -- タスクID
    in_obj_ver_num           IN  NUMBER,                 -- オブジェクトバージョン番号
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'delete_task';
--
    -- トークンコード
    cv_tkn_err_msg             CONSTANT VARCHAR2(20) := 'ERR_MSG';
    cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
    cv_tkn_task_nm             CONSTANT VARCHAR2(20) := 'TASK_NAME';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    -- API戻り値
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ------------------
    ---- API 起動 ----
    ------------------
    JTF_TASKS_PUB.DELETE_TASK(
       p_api_version             => 1.0                      -- バージョンナンバー            
      ,p_object_version_number   => in_obj_ver_num           -- オブジェクトバージョン番号
      ,p_task_id                 => in_task_id               -- タスクID
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** 処理部例外 ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API例外 ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END delete_task;
/* 2009.10.23 D.Abe E_T4_00056対応 START */
--
   /**********************************************************************************
   * Function Name    : update_task2
   * Description      : 訪問タスク更新処理２（ATTRIBUTE15のみ更新）
   ***********************************************************************************/
  PROCEDURE update_task2(
    in_task_id               IN  NUMBER,                 -- タスクID
    in_obj_ver_num           IN  NUMBER,                 -- オブジェクトバージョン番号
    iv_attribute15           IN  VARCHAR2 DEFAULT jtf_task_utl.g_miss_char,  -- DFF15
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'update_task2';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_obj_ver_num             NUMBER;          -- オブジェクトバージョン番号

    -- API戻り値
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ln_obj_ver_num := in_obj_ver_num;
    ------------------
    ---- API 起動 ----
    ------------------
    JTF_TASKS_PUB.UPDATE_TASK(
       p_api_version             => 1.0                 -- バージョンナンバー
      ,p_task_id                 => in_task_id          -- タスクID
      ,p_object_version_number   => ln_obj_ver_num      -- オブジェクトバージョン番号
      ,p_attribute15             => iv_attribute15
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** 処理部例外 ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API例外 ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END update_task2;
/* 2009.10.23 D.Abe E_T4_00056対応 END */
--
END XXCSO_TASK_COMMON_PKG;
/
