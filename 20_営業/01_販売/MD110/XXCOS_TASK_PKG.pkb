CREATE OR REPLACE PACKAGE BODY XXCOS_TASK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_TASK_PKG(spec)
 * Description      : 共通関数パッケージ(販売)
 * MD.070           : 共通関数    MD070_IPO_COS
 * Version          : 1.5
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  task_entry                  P                 訪問・有効実績登録
 *  
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2008/12/12    1.0   T.kitajima       新規作成
 *  2009/02/18    1.1   T.kitajima       [COS_091]消化VD対応
 *  2009/05/18    1.2   T.kitajima       [T1_0652]入金情報時の登録元ソース番号必須解除
 *  2009/11/24    1.3   S.Miyakoshi      TASKデータ取得時の日付の条件変更
 *  2010/11/15    1.4   K.Kiriu          [E_本稼動_05129]タスク作成PT対応
 *  2011/03/28    1.5   Oukou            [E_本稼動_00153]HHT入金データ取込異常終了対応
 *
 ****************************************************************************************/
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
/* 2011/03/28 Ver1.5 ADD Start */
  -- レコードロックエラー
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
/* 2011/03/28 Ver1.5 ADD End   */
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  global_indispensability_expt    EXCEPTION; -- 必須エラー
  global_registration_expt        EXCEPTION; -- 登録区分指定エラー
  global_effective_visi_expt      EXCEPTION; -- 有効訪問状態エラー
  global_get_effective_visi_expt  EXCEPTION; -- 有効訪問取得エラー
  
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS_TASK_PKG';       -- パッケージ名
  --アプリケーション短縮名
  ct_xxcos_appl_short_name        CONSTANT  fnd_application.application_short_name%TYPE
                                            := 'XXCOS';                         -- 販物短縮アプリ名
  --販物メッセージ
  ct_msg_app_xxcos1_13568         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13568';              -- リソースID必須エラーメッセージ
  ct_msg_app_xxcos1_13569         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13569';              -- パーティID必須エラーメッセージ
  ct_msg_app_xxcos1_13570         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13570';              -- パーティ名称必須エラーメッセージ
  ct_msg_app_xxcos1_13571         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13571';              -- 訪問日時必須エラーメッセージ
  ct_msg_app_xxcos1_13572         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13572';              -- 売上金額必須エラーメッセージ
  ct_msg_app_xxcos1_13573         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13573';              -- 登録区分必須エラーメッセージ
  ct_msg_app_xxcos1_13574         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13574';              -- 登録元ソース番号必須エラーメッセージ
  ct_msg_app_xxcos1_13575         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13575';              -- 顧客ステータス必須エラーメッセージ
  ct_msg_app_xxcos1_13576         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13576';              -- 登録区分指定エラー
  ct_msg_app_xxcos1_13577         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13577';              -- 有効訪問区分チェックエラー
  ct_msg_app_xxcos1_13578         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13578';              -- 有効訪問区分取得エラー
  ct_msg_app_xxcos1_13579         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13579';              -- 入力区分必須エラー
  ct_msg_app_xxcos1_13580         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13580';              -- 納品
  ct_msg_app_xxcos1_13581         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13581';              -- 入金
  ct_msg_app_xxcos1_13582         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13582';              -- 売上金額マイナスエラー
  ct_msg_app_xxcos1_13589         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13589';              -- 消化
/* 2011/03/28 Ver1.5 ADD Start */
  ct_msg_app_xxcos1_00001         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00001';              -- ロックエラー
/* 2011/03/28 Ver1.5 ADD End   */

  --トークン
  cv_tkn_in_param                 CONSTANT  VARCHAR2(100) := 'PARAM';           -- 入力パラメータ
  cv_tkn_in_param1                CONSTANT  VARCHAR2(100) := 'PARAM1';          -- 入力パラメータ
  cv_tkn_in_param2                CONSTANT  VARCHAR2(100) := 'PARAM2';          -- 入力パラメータ
  cv_tkn_in_param3                CONSTANT  VARCHAR2(100) := 'PARAM3';          -- 入力パラメータ
/* 2011/03/28 Ver1.5 ADD Start */
  cv_tkn_table                    CONSTANT  VARCHAR2(20)  := 'TABLE';           -- テーブル
/* 2011/03/28 Ver1.5 ADD End   */
  --登録区分
  cv_registration_division_3      CONSTANT  VARCHAR2(1)   := '3';                  -- 納品情報
  cv_registration_division_4      CONSTANT  VARCHAR2(1)   := '4';                  -- 集金情報
  cv_registration_division_5      CONSTANT  VARCHAR2(1)   := '5';                  -- 消化VD情報
  --有効訪問区分
  cv_effective_visit_1            CONSTANT  VARCHAR2(1)   := '1';                  -- 有効
  cv_effective_visit_0            CONSTANT  VARCHAR2(1)   := '0';                  -- 訪問
  --ソース文書
  cv_source_party                 CONSTANT  VARCHAR2(5)   := 'PARTY';              -- PARTY
  cv_own_typ                      CONSTANT  VARCHAR2(15)  := 'RS_EMPLOYEE';        -- RS_EMPLOYEE
/* 2010/11/15 Ver1.4 Del Start */
--  --フォーマット
--  cv_trunc_format_dd              CONSTANT  VARCHAR2(2)   := 'DD';                 -- 日
/* 2010/11/15 Ver1.4 Del End   */
  --入力区分
  cv_input_division_0             CONSTANT  VARCHAR2(1)   := '0';                  -- ダミー
  cv_input_division_1             CONSTANT  VARCHAR2(1)   := '1';                  -- 納品入力・EOS伝票入力
  cv_input_division_2             CONSTANT  VARCHAR2(1)   := '2';                  -- 返品入力
  cv_input_division_3             CONSTANT  VARCHAR2(1)   := '3';                  -- 自販機売上
  cv_input_division_4             CONSTANT  VARCHAR2(1)   := '4';                  -- 自販機返品
  cv_input_division_5             CONSTANT  VARCHAR2(1)   := '5';                  -- フルVD納品・自動吸上
  --削除フラグ
  cd_del_flg_y                    CONSTANT  VARCHAR2(1)   := 'Y';                  -- 削除
  cd_del_flg_n                    CONSTANT  VARCHAR2(1)   := 'N';                  -- 有効
  --詳細内容
  cv_details_delivery             CONSTANT VARCHAR2(50)   := xxccp_common_pkg.get_msg(
                                                                iv_application        =>  ct_xxcos_appl_short_name
                                                               ,iv_name               =>  ct_msg_app_xxcos1_13580
                                                             );                    -- 納品
  cv_details_payment              CONSTANT VARCHAR2(50)   := xxccp_common_pkg.get_msg(
                                                                iv_application        =>  ct_xxcos_appl_short_name
                                                               ,iv_name               =>  ct_msg_app_xxcos1_13581
                                                             );                    -- 入金
  cv_details_digestion            CONSTANT VARCHAR2(50)   := xxccp_common_pkg.get_msg(
                                                                iv_application        =>  ct_xxcos_appl_short_name
                                                               ,iv_name               =>  ct_msg_app_xxcos1_13589
                                                             );                    -- 消化
  --
/* 2011/03/28 Ver1.5 ADD Start */
  cv_table_task                   CONSTANT  VARCHAR2(20)  := 'タスク情報';         -- テーブル
/* 2011/03/28 Ver1.5 ADD End   */
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  --==================================
  -- プライベート･ファンクション
  --==================================
--
  /**********************************************************************************
   * Procedure Name   : task_entry
   * Description      : 訪問・有効実績登録
   ***********************************************************************************/
  PROCEDURE task_entry(
               ov_errbuf          OUT NOCOPY  VARCHAR2                --エラーメッセージ
              ,ov_retcode         OUT NOCOPY  VARCHAR2                --リターンコード
              ,ov_errmsg          OUT NOCOPY  VARCHAR2                --ユーザー・エラー・メッセージ
              ,in_resource_id     IN          NUMBER    DEFAULT NULL  --リソースID
              ,in_party_id        IN          NUMBER    DEFAULT NULL  --パーティID
              ,iv_party_name      IN          VARCHAR2  DEFAULT NULL  --パーティ名称
              ,id_visit_date      IN          DATE      DEFAULT NULL  --訪問日時
              ,iv_description     IN          VARCHAR2  DEFAULT NULL  --詳細内容
              ,in_sales_amount    IN          NUMBER    DEFAULT NULL  --売上金額(2008/12/12 追加)
              ,iv_input_division  IN          VARCHAR2  DEFAULT NULL  --入力区分(2008/12/17 追加)
              ,iv_entry_class     IN          VARCHAR2  DEFAULT NULL  --ＤＦＦ１２（登録区分）
              ,iv_source_no       IN          VARCHAR2  DEFAULT NULL  --ＤＦＦ１３（登録元ソース番号）
              ,iv_customer_status IN          VARCHAR2  DEFAULT NULL  --ＤＦＦ１４（顧客ステータス）
            )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'task_entry'; -- プログラム名
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
    lv_key_info            VARCHAR2(5000);                         --キー情報
    lv_description         VARCHAR2(5000);                         --詳細
    lv_effective_visi      VARCHAR2(1);                            --有効訪問区分
/* 2011/03/28 Ver1.5 ADD Start */
    ln_task_cnt            NUMBER;                                 --タスクデータ件数
    lv_target_task_id      jtf_tasks_b.task_id%TYPE;               --タスクID
/* 2011/03/28 Ver1.5 ADD End   */
    lt_msg_num             fnd_new_messages.message_name%TYPE;     --メッセージコード
    lt_task_effective_visi jtf_tasks_b.attribute11%TYPE;           --TASK有効訪問区分
    lt_task_id             jtf_tasks_b.task_id%TYPE;               --タスクID
    lt_ovn                 jtf_tasks_b.object_version_number%TYPE; --オブジェクトヴァージョンNo
/* 2010/11/15 Ver1.4 Add Start */
    ld_visit_date          DATE;                                   --訪問日(有効訪問区分チェック条件用)
/* 2010/11/15 Ver1.4 Add End   */
/* 2011/03/28 Ver1.5 ADD Start */
--
    -- *** ローカル・カーソル ***
    --タスク情報
    CURSOR task_data_cur(it_task_id  jtf_tasks_b.task_id%TYPE)
    IS
      SELECT
             /*+
               INDEX( jtb xxcso_jtf_tasks_b_n18 )
             */
             jtb.attribute11            attribute11,            -- 有効訪問区分
             jtb.task_id                task_id,                -- TASK ID
             jtb.object_version_number  object_version_number   -- オブジェクトヴァージョンNo
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                      = in_resource_id
      AND    jtb.source_object_id              = in_party_id
      AND    jtb.source_object_type_code       = cv_source_party
      AND    TRUNC(jtb.actual_end_date)        = ld_visit_date
      AND    jtb.attribute12     IN (cv_registration_division_3,
                                     cv_registration_division_4,
                                     cv_registration_division_5)
      AND    jtb.deleted_flag                  = cd_del_flg_n
      AND    jtb.owner_type_code               = cv_own_typ
      AND    (
             jtb.attribute11                  != cv_effective_visit_1
             OR     (jtb.attribute11           = cv_effective_visit_1
                     AND
                     jtb.task_id              != it_task_id
                    )
             )
      FOR UPDATE NOWAIT;
/* 2011/03/28 Ver1.5 ADD End   */
--
    -- ================
    -- ユーザー定義例外
    -- ================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode :=xxccp_common_pkg.set_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --1.引数チェック
    --==============================================================
    --==================================
    --1-1.リソースIDの必須チェック
    --==================================
    IF ( in_resource_id IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13568;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-2.パーティIDの必須チェック
    --==================================
    IF ( in_party_id IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13569;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-3.パーティ名称の必須チェック
    --==================================
    IF ( iv_party_name IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13570;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-4.訪問日時の必須チェック
    --==================================
    IF ( id_visit_date IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13571;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-5.売上金額の必須チェック
    --==================================
    IF ( in_sales_amount IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13572;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-6.登録区分の必須チェック
    --==================================
    IF ( iv_entry_class IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13573;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-7.登録元ソース番号の必須チェック
    --==================================
--****************************** 2009/05/18 1.3 T.Kitajima MOD START ******************************--
--    IF ( iv_source_no IS NULL ) THEN
    IF ( iv_source_no IS NULL ) AND
       ( iv_entry_class != cv_registration_division_4 )
    THEN
--****************************** 2009/05/18 1.3 T.Kitajima MOD START ******************************--
      lt_msg_num := ct_msg_app_xxcos1_13574;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-8.顧客ステータスの必須チェック
    --==================================
    IF ( iv_customer_status IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13575;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-9.入力区分の必須チェック
    --==================================
    IF ( iv_input_division IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13579;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-10.売上金額マイナスチェック
    --==================================
    IF ( in_sales_amount < 0 ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13582;
      RAISE global_indispensability_expt;
    END IF;
--
    --==================================
    --2.登録区分確認
    --==================================
    IF ( iv_entry_class = cv_registration_division_3 ) THEN
      lv_description := cv_details_delivery;                   -- 納品情報
    ELSIF ( iv_entry_class = cv_registration_division_4 ) THEN
      lv_description := cv_details_payment;                    -- 入金情報
    ELSIF ( iv_entry_class = cv_registration_division_5 ) THEN
      lv_description := cv_details_digestion;                  -- 消化情報
    ELSE
      lv_key_info := iv_entry_class;
      RAISE global_registration_expt;
    END IF;
--
    --==================================
    --3.有効訪問区分チェック
    --==================================
    lv_effective_visi := NULL;
    --納品情報
    IF ( iv_entry_class = cv_registration_division_3 ) THEN
      --入力区分が1,3,5のとき
      IF ( iv_input_division = cv_input_division_1 OR
           iv_input_division = cv_input_division_3 OR
           iv_input_division = cv_input_division_5 ) THEN
        --金額があるとき
        IF ( in_sales_amount > 0 ) THEN
          lv_effective_visi := cv_effective_visit_1;               -- 有効
        --金額が0のとき
        ELSIF ( in_sales_amount = 0 ) THEN
          lv_effective_visi := cv_effective_visit_0;               -- 訪問
        END IF;
      --入力区分が2,4のとき
      ELSIF ( iv_input_division = cv_input_division_2 OR
              iv_input_division = cv_input_division_4 ) THEN
        --何もしない
        NULL;
      --入力区分がそれ以外
      ELSE
          --エラー
          RAISE global_effective_visi_expt;
      END IF;
    END IF;
    --集金情報
    IF ( iv_entry_class = cv_registration_division_4 ) THEN
      --入力区分が0のとき
      IF ( iv_input_division = cv_input_division_0 ) THEN
        lv_effective_visi := cv_effective_visit_0;               -- 訪問
      ELSE
        --エラー
        RAISE global_effective_visi_expt;
      END IF;
    END IF;
    --消化情報
    IF ( iv_entry_class = cv_registration_division_5 ) THEN
      --入力区分が0のとき
      IF ( iv_input_division = cv_input_division_0 ) THEN
        --金額があるとき
        IF ( in_sales_amount > 0 ) THEN
          lv_effective_visi := cv_effective_visit_1;               -- 有効
        END IF;
      ELSE
        --エラー
        RAISE global_effective_visi_expt;
      END IF;
    END IF;
--
    --有効訪問区分がNULLのときは何もしない
    IF ( lv_effective_visi IS NULL ) THEN
      NULL;
    ELSE
/* 2010/11/15 Ver1.4 Add Start */
      --条件用訪問日の設定
      ld_visit_date := TRUNC(id_visit_date);
/* 2010/11/15 Ver1.4 Add End   */
/* 2011/03/28 Ver1.5 ADD Start */
      --タスクデータ件数取得
      SELECT
             /*+
               INDEX( jtb xxcso_jtf_tasks_b_n18 )
             */
             COUNT(1)
      INTO   ln_task_cnt
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                      = in_resource_id
      AND    jtb.source_object_id              = in_party_id
      AND    jtb.source_object_type_code       = cv_source_party
      AND    TRUNC(jtb.actual_end_date)        = ld_visit_date
      AND    jtb.attribute12     IN (cv_registration_division_3,cv_registration_division_4,cv_registration_division_5)
      AND    jtb.deleted_flag                  = cd_del_flg_n
      AND    jtb.owner_type_code               = cv_own_typ
      ;
      --
      IF ( ln_task_cnt > 1 ) THEN
        -- 最古最終更新日タスク情報取得
        SELECT jtb_t.task_id
        INTO   lv_target_task_id
        FROM   (SELECT 
                      /*+
                      INDEX( jtb1 xxcso_jtf_tasks_b_n18 )
                      */
                      jtb1.task_id                       task_id
               FROM   jtf_tasks_b jtb1
               WHERE  jtb1.owner_id                      = in_resource_id
               AND    jtb1.source_object_id              = in_party_id
               AND    jtb1.source_object_type_code       = cv_source_party
               AND    TRUNC(jtb1.actual_end_date)        = ld_visit_date
               AND    jtb1.attribute12     IN (cv_registration_division_3,
                                               cv_registration_division_4,
                                               cv_registration_division_5)
               AND    jtb1.deleted_flag                  = cd_del_flg_n
               AND    jtb1.owner_type_code               = cv_own_typ
               AND    jtb1.attribute11                   = cv_effective_visit_1
               ORDER BY jtb1.last_update_date, jtb1.task_id ASC)  jtb_t
        WHERE  ROWNUM                             = 1
        ;
        -- タスクデータ削除
        FOR task_rec IN task_data_cur(lv_target_task_id) LOOP
          xxcso_task_common_pkg.delete_task(
             in_task_id     => task_rec.task_id                --タスクID
            ,in_obj_ver_num => task_rec.object_version_number  --オブジェクトヴァージョンNo
            ,ov_errbuf      => lv_errbuf                       --エラーバッファー
            ,ov_retcode     => lv_retcode                      --エラーコード
            ,ov_errmsg      => lv_errmsg                       --エラーメッセージ
          );
          -- 削除チェック
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        END LOOP;
        --
      END IF;
/* 2011/03/28 Ver1.5 ADD End   */
      --TASKデータ取得(有効訪問区分)
      BEGIN
/* 2010/11/15 Ver1.4 Mod Start */
--        SELECT jtb.attribute11,           -- 有効訪問区分
        SELECT
               /*+
                 INDEX( jtb xxcso_jtf_tasks_b_n18 )
               */
               jtb.attribute11,           -- 有効訪問区分
/* 2010/11/15 Ver1.4 Mod End   */
               jtb.task_id,               -- TASK ID
               jtb.object_version_number  -- オブジェクトヴァージョンNo
        INTO   lt_task_effective_visi,
               lt_task_id,
               lt_ovn
        FROM   jtf_tasks_b jtb
        WHERE  jtb.owner_id                                  = in_resource_id
        AND    jtb.source_object_id                          = in_party_id
        AND    jtb.source_object_type_code                   = cv_source_party
--****************************** 2009/11/24 1.3 S.Miyakoshi MOD START ******************************--
--        AND    jtb.actual_end_date BETWEEN TRUNC(id_visit_date,cv_trunc_format_dd) AND TRUNC(id_visit_date + 1 ,cv_trunc_format_dd)
/* 2010/11/15 Ver1.4 Mod Start */
--        AND    TRUNC(jtb.actual_end_date,cv_trunc_format_dd) = TRUNC(id_visit_date,cv_trunc_format_dd)
        AND    TRUNC(jtb.actual_end_date) = ld_visit_date
/* 2010/11/15 Ver1.4 Mod End   */
--****************************** 2009/11/24 1.3 S.Miyakoshi MOD END ********************************--
        AND    jtb.attribute12     IN (cv_registration_division_3,cv_registration_division_4,cv_registration_division_5)
        AND    jtb.deleted_flag    = cd_del_flg_n
        AND    jtb.owner_type_code = cv_own_typ
        ;
        --
        --有効訪問区分がNULLの場合
        IF ( lt_task_effective_visi IS NULL ) THEN
          RAISE global_get_effective_visi_expt;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
         --==================================
      --4.有効訪問区分が有効の場合
      --==================================
      IF ( lv_effective_visi = cv_effective_visit_1 ) THEN        -- INパラが有効
        IF ( lt_task_effective_visi = cv_effective_visit_1 ) THEN -- TASKが有効
          NULL;
        ELSIF ( lt_task_effective_visi = cv_effective_visit_0 ) THEN -- TASKが訪問
          --TASK情報を一旦削除
          xxcso_task_common_pkg.delete_task(
             in_task_id     => lt_task_id               --タスクID
            ,in_obj_ver_num => lt_task_effective_visi   --オブジェクトヴァージョンNo
            ,ov_errbuf      => lv_errbuf                --エラーバッファー
            ,ov_retcode     => lv_retcode               --エラーコード
            ,ov_errmsg      => lv_errmsg                --エラーメッセージ
          );
          --削除チェック
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --TASK情報を登録
          xxcso_task_common_pkg.create_task(
             in_resource_id => in_resource_id           --リソースID
            ,in_party_id    => in_party_id              --顧客パーティID
            ,iv_party_name  => iv_party_name            --顧客パーティ名称
            ,id_visit_date  => id_visit_date            --訪問日時
            ,iv_description => lv_description           --詳細内容
            ,iv_attribute1  => NULL
            ,iv_attribute2  => NULL
            ,iv_attribute3  => NULL
            ,iv_attribute4  => NULL
            ,iv_attribute5  => NULL
            ,iv_attribute6  => NULL
            ,iv_attribute7  => NULL
            ,iv_attribute8  => NULL
            ,iv_attribute9  => NULL
            ,iv_attribute10 => NULL
            ,iv_attribute11 => lv_effective_visi        --有効訪問区分
            ,iv_attribute12 => iv_entry_class           --登録区分
            ,iv_attribute13 => iv_source_no             --登録元ソース番号
            ,iv_attribute14 => iv_customer_status       --顧客ステータス
            ,on_task_id     => lt_task_id               --タスクID
            ,ov_errbuf      => lv_errbuf                --エラーバッファー
            ,ov_retcode     => lv_retcode               --エラーコード
            ,ov_errmsg      => lv_errmsg                --エラーメッセージ
          );
          --登録チェック
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        ELSE
          --TASK情報を登録
          xxcso_task_common_pkg.create_task(
             in_resource_id => in_resource_id           --リソースID
            ,in_party_id    => in_party_id              --顧客パーティID
            ,iv_party_name  => iv_party_name            --顧客パーティ名称
            ,id_visit_date  => id_visit_date            --訪問日時
            ,iv_description => lv_description           --詳細内容
            ,iv_attribute1  => NULL
            ,iv_attribute2  => NULL
            ,iv_attribute3  => NULL
            ,iv_attribute4  => NULL
            ,iv_attribute5  => NULL
            ,iv_attribute6  => NULL
            ,iv_attribute7  => NULL
            ,iv_attribute8  => NULL
            ,iv_attribute9  => NULL
            ,iv_attribute10 => NULL
            ,iv_attribute11 => lv_effective_visi        --有効訪問区分
            ,iv_attribute12 => iv_entry_class           --登録区分
            ,iv_attribute13 => iv_source_no             --登録元ソース番号
            ,iv_attribute14 => iv_customer_status       --顧客ステータス
            ,on_task_id     => lt_task_id               --タスクID
            ,ov_errbuf      => lv_errbuf                --エラーバッファー
            ,ov_retcode     => lv_retcode               --エラーコード
            ,ov_errmsg      => lv_errmsg                --エラーメッセージ
          );
          --登録チェック
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
  --
      --==================================
      --5.有効訪問区分が訪問の場合
      --==================================
      IF ( lv_effective_visi = cv_effective_visit_0 ) THEN        -- INパラが訪問
        IF ( lt_task_effective_visi = cv_effective_visit_1 ) THEN -- TASKが有効
          NULL;
        ELSIF ( lt_task_effective_visi = cv_effective_visit_0 ) THEN -- TASKが訪問
          NULL;
        ELSE
          --TASK情報を登録
          xxcso_task_common_pkg.create_task(
             in_resource_id => in_resource_id           --リソースID
            ,in_party_id    => in_party_id              --顧客パーティID
            ,iv_party_name  => iv_party_name            --顧客パーティ名称
            ,id_visit_date  => id_visit_date            --訪問日時
            ,iv_description => lv_description           --詳細内容
            ,iv_attribute1  => NULL
            ,iv_attribute2  => NULL
            ,iv_attribute3  => NULL
            ,iv_attribute4  => NULL
            ,iv_attribute5  => NULL
            ,iv_attribute6  => NULL
            ,iv_attribute7  => NULL
            ,iv_attribute8  => NULL
            ,iv_attribute9  => NULL
            ,iv_attribute10 => NULL
            ,iv_attribute11 => lv_effective_visi        --有効訪問区分
            ,iv_attribute12 => iv_entry_class           --登録区分
            ,iv_attribute13 => iv_source_no             --登録元ソース番号
            ,iv_attribute14 => iv_customer_status       --顧客ステータス
            ,on_task_id     => lt_task_id               --タスクID
            ,ov_errbuf      => lv_errbuf                --エラーバッファー
            ,ov_retcode     => lv_retcode               --エラーコード
            ,ov_errmsg      => lv_errmsg                --エラーメッセージ
          );
          --登録チェック
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --必須エラー
    WHEN global_indispensability_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  lt_msg_num
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --登録区分指定エラー
    WHEN global_registration_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_app_xxcos1_13576,
        iv_token_name1        =>  cv_tkn_in_param,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --有効訪問状態エラー
    WHEN global_effective_visi_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_app_xxcos1_13577,
        iv_token_name1        =>  cv_tkn_in_param1,
        iv_token_value1       =>  iv_entry_class,
        iv_token_name2        =>  cv_tkn_in_param2,
        iv_token_value2       =>  iv_input_division,
        iv_token_name3        =>  cv_tkn_in_param3,
        iv_token_value3       =>  in_sales_amount
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --有効訪問取得エラー
    WHEN global_get_effective_visi_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_app_xxcos1_13578,
        iv_token_name1        =>  cv_tkn_in_param1,
        iv_token_value1       =>  in_resource_id,
        iv_token_name2        =>  cv_tkn_in_param2,
        iv_token_value2       =>  id_visit_date
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2011/03/28 Ver1.5 ADD Start */
    --ロックエラー
    WHEN record_lock_expt THEN
      IF ( task_data_cur%ISOPEN ) THEN
        CLOSE task_data_cur;
      END IF;
      -- メッセージ作成
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name
       ,iv_name               =>  ct_msg_app_xxcos1_00001
       ,iv_token_name1        =>  cv_tkn_table
       ,iv_token_value1       =>  cv_table_task
      );
      --
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2011/03/28 Ver1.5 ADD End   */
---
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
--#####################################  固定部 END   ##########################################
--
  END task_entry;
--
END XXCOS_TASK_PKG;
/
