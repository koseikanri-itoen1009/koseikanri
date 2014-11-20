CREATE OR REPLACE PACKAGE BODY APPS.xxcso_020001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_020001j_pkg(BODY)
 * Description      : フルベンダーSP専決
 * MD.050/070       : 
 * Version          : 1.13
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  initialize_transaction    P    -     トランザクション初期化処理
 *  process_request           P    -     通知ワークフロー起動処理
 *  process_lock              P    -     トランザクションロック処理
 *  get_inst_info_parameter   F    V     設置先情報判定
 *  get_cntr_info_parameter   F    V     契約先情報判定
 *  get_bm1_info_parameter    F    V     BM1情報判定
 *  get_bm2_info_parameter    F    V     BM2情報判定
 *  get_bm3_info_parameter    F    V     BM3情報判定
 *  calculate_sc_line         P    -     売価別条件計算（明細行ごと）
 *  calculate_cc_line         P    -     一律条件・容器別条件計算（明細行ごと）
 *  get_gross_profit_rate     F    V     粗利率取得
 *  calculate_est_year_profit P    -     概算年間損益計算
 *  get_appr_auth_level_num_1 F    N     承認権限レベル番号１取得
 *  get_appr_auth_level_num_2 F    N     承認権限レベル番号２取得
 *  get_appr_auth_level_num_3 F    N     承認権限レベル番号３取得
 *  get_appr_auth_level_num_4 F    N     承認権限レベル番号４取得
 *  get_appr_auth_level_num_0 F    N     承認権限レベル番号（デフォルト）取得
 *  conv_number_separate      P    -     数値セパレート変換
 *  conv_line_number_separate P    -     数値セパレート変換（明細）
 *  chk_double_byte           F    V     全角文字チェック（共通関数ラッピング）
 *  chk_single_byte_kana      F    V     半角カナチェック（共通関数ラッピング）
 *  chk_account_many          P    -     アカウント複数チェック
 *  chk_cust_site_uses        P    -     顧客使用目的チェック
 *  chk_validate_db           P    -     ＤＢ更新判定チェック
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/23    1.0   H.Ogawa          新規作成
 *  2009/03/23    1.1   N.Yanagitaira    [障害T1_0163]承認時契約先update処理修正
 *  2009/04/06    1.2   N.Yanagitaira    [障害T1_0316]回送先レコード更新処理修正
 *  2009/04/09    1.3   K.Satomura       [障害T1_0424]承認完了日・決裁日設定値修正
 *  2009/04/17    1.4   N.Yanagitaira    [障害T1_0536]通知ワークフロー送信元設定値修正
 *  2009/04/27    1.5   N.Yanagitaira    [障害T1_0708]入力項目チェック処理統一修正
 *                                                    chk_double_byte
 *                                                    chk_single_byte_kana
 *  2009/05/01    1.6   T.Mori           [障害T1_0897]スキーマ名設定
 *  2009/05/07    1.7   N.Yanagitaira    [障害T1_0200]VDリース料、費用合計算出方法修正
 *  2009/06/05    1.8   N.Yanagitaira    [障害T1_1307]chk_single_byte_kana修正
 *  2009/07/16    1.9   D.Abe            [SCS障害0000385]SP専決書否認時のフロー変更
 *  2009/10/26    1.10  K.Satomura       [E_T4_00075]損益分岐点の計算方法修正
 *  2009/11/29    1.11  D.Abe            [E_本稼動_00106]アカウント複数判定
 *  2010/01/12    1.12  D.Abe            [E_本稼動_00823]顧客マスタの整合性チェック対応
 *  2010/01/15    1.13  D.Abe            [E_本稼動_00950]ＤＢ更新判定チェック対応
*****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_020001j_pkg';   -- パッケージ名
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  nowait_except       EXCEPTION;
  PRAGMA EXCEPTION_INIT(nowait_except, -54);
--
  /**********************************************************************************
   * Function Name    : initialize_transaction
   * Description      : トランザクション初期化処理
   ***********************************************************************************/
  PROCEDURE initialize_transaction(
    iv_sp_decision_header_id    IN  VARCHAR2
   ,iv_app_base_code            IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'initialize_transaction';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_count                     NUMBER;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    SELECT  COUNT('x')
    INTO    ln_count
    FROM    xxcso_tmp_sp_dec_request  xtsdr
    ;
--
    IF ( ln_count = 0 ) THEN
--
      INSERT INTO    xxcso_tmp_sp_dec_request(
                       sp_decision_header_id
                      ,app_base_code
                      ,created_by
                      ,creation_date
                      ,last_updated_by
                      ,last_update_date
                      ,last_update_login
                     )
             VALUES  (
                       TO_NUMBER(iv_sp_decision_header_id)
                      ,iv_app_base_code
                      ,fnd_global.user_id
                      ,SYSDATE
                      ,fnd_global.user_id
                      ,SYSDATE
                      ,fnd_global.login_id
                     )
      ;
--
    ELSE
--
      UPDATE  xxcso_tmp_sp_dec_request
      SET     sp_decision_header_id = TO_NUMBER(iv_sp_decision_header_id)
             ,app_base_code         = iv_app_base_code
             ,created_by            = fnd_global.user_id
             ,creation_date         = SYSDATE
             ,last_updated_by       = fnd_global.user_id
             ,last_update_date      = SYSDATE
             ,last_update_login     = fnd_global.login_id
      ;
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
  END initialize_transaction;
--
  /**********************************************************************************
   * Function Name    : process_request
   * Description      : 通知ワークフロー起動処理
   ***********************************************************************************/
  PROCEDURE process_request(
    ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'process_request';
    cv_operation_submit          CONSTANT VARCHAR2(30)    := 'SUBMIT';
    cv_operation_confirm         CONSTANT VARCHAR2(30)    := 'CONFIRM';
    cv_operation_return          CONSTANT VARCHAR2(30)    := 'RETURN';
    cv_operation_approve         CONSTANT VARCHAR2(30)    := 'APPROVE';
    cv_operation_reject          CONSTANT VARCHAR2(30)    := 'REJECT';
    cv_approve_init              CONSTANT VARCHAR2(1)     := '*';
    cv_approval_state_none       CONSTANT VARCHAR2(1)     := '0';
    cv_approval_state_during     CONSTANT VARCHAR2(1)     := '1';
    cv_approval_state_end        CONSTANT VARCHAR2(1)     := '2';
    cv_content_approve           CONSTANT VARCHAR2(1)     := '1';
    cv_content_reject            CONSTANT VARCHAR2(1)     := '2';
    cv_content_confirm           CONSTANT VARCHAR2(1)     := '3';
    cv_content_return            CONSTANT VARCHAR2(1)     := '4';
    cv_status_request            CONSTANT VARCHAR2(1)     := '2';
    cv_status_enabled            CONSTANT VARCHAR2(1)     := '3';
    cv_status_reject             CONSTANT VARCHAR2(1)     := '4';
    cv_request_approve           CONSTANT VARCHAR2(1)     := '1';
    cv_notify_reject             CONSTANT VARCHAR2(1)     := '3';
    cv_notify_return             CONSTANT VARCHAR2(1)     := '4';
    cv_notify_approve_end        CONSTANT VARCHAR2(1)     := '5';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_operation_mode            xxcso_tmp_sp_dec_request.operation_mode%TYPE;
    ln_sp_decision_header_id     xxcso_tmp_sp_dec_request.sp_decision_header_id%TYPE;
    lv_application_code          xxcso_sp_decision_headers.application_code%TYPE;
    lv_status                    xxcso_sp_decision_headers.status%TYPE;
    lv_approve_code              xxcso_sp_decision_sends.approve_code%TYPE;
-- 20090406_N.Yanagitaira T1_0536 Mod START
    lv_employee_number           per_people_f.employee_number%TYPE;
-- 20090406_N.Yanagitaira T1_0536 Mod END
    TYPE sp_decision_send_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.sp_decision_send_id%TYPE INDEX BY BINARY_INTEGER;
    TYPE approve_code_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.approve_code%TYPE INDEX BY BINARY_INTEGER;
    TYPE work_request_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.work_request_type%TYPE INDEX BY BINARY_INTEGER;
    TYPE approval_state_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.approval_state_type%TYPE INDEX BY BINARY_INTEGER;
    lt_sp_decision_send_tbl    sp_decision_send_tbl_type;
    lt_approve_code_tbl        approve_code_tbl_type;
    lt_work_request_tbl        work_request_tbl_type;
    lt_approval_state_tbl      approval_state_tbl_type;
    ln_approve_code_count      NUMBER;
    ln_cust_account_id         NUMBER;
    ln_contract_customer_id    NUMBER;
    lb_notify_flag             BOOLEAN;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    lb_notify_flag := FALSE;
--
    SELECT  xtsdr.operation_mode
           ,xtsdr.sp_decision_header_id
           ,xsdh.application_code
           ,xsdh.status
    INTO    lv_operation_mode
           ,ln_sp_decision_header_id
           ,lv_application_code
           ,lv_status
    FROM    xxcso_tmp_sp_dec_request    xtsdr
           ,xxcso_sp_decision_headers   xsdh
    WHERE   xsdh.sp_decision_header_id = xtsdr.sp_decision_header_id
    ;
--
-- 20090417_N.Yanagitaira T1_0536 Add START
    SELECT   xev.employee_number
    INTO     lv_employee_number 
    FROM     xxcso_employees_v2 xev
    WHERE    xev.user_id = fnd_global.user_id
    ;
-- 20090417_N.Yanagitaira T1_0536 Add END
--
    SELECT  xsds.sp_decision_send_id
           ,xsds.approve_code
           ,xsds.work_request_type
           ,xsds.approval_state_type
    BULK COLLECT INTO
            lt_sp_decision_send_tbl
           ,lt_approve_code_tbl
           ,lt_work_request_tbl
           ,lt_approval_state_tbl
    FROM    xxcso_sp_decision_sends    xsds
    WHERE   xsds.sp_decision_header_id = ln_sp_decision_header_id
    AND     xsds.approve_code         <> cv_approve_init
    ORDER BY xsds.approval_authority_number
    ;
--
    << send_loop >>
    FOR idx IN 1..lt_sp_decision_send_tbl.COUNT
    LOOP
--
      IF ( lv_operation_mode = cv_operation_submit ) THEN
        ---------------------------------
        -- 提出の場合
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_none ) THEN
--
          -- ステータスを承認依頼中に変更し、申請回数をカウントアップする
          UPDATE  xxcso_sp_decision_headers
          SET     status              = cv_status_request
                 ,application_number  = (application_number + 1)
                 ,application_date    = TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                 ,last_updated_by     = DECODE(last_update_date
                                         ,creation_date, created_by
                                         ,fnd_global.user_id
                                        )
                 ,last_update_date    = DECODE(last_update_date
                                         ,creation_date, creation_date
                                         ,SYSDATE
                                        )
                 ,last_update_login   = DECODE(last_update_date
                                         ,creation_date, last_update_login
                                         ,fnd_global.login_id
                                        )
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          ;
--
          -- 次の回送先を見つけ、決裁状態区分を処理中に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_during
                 ,last_updated_by     = DECODE(last_update_date
                                         ,creation_date, created_by
                                         ,fnd_global.user_id
                                        )
                 ,last_update_date    = DECODE(last_update_date
                                         ,creation_date, creation_date
                                         ,SYSDATE
                                        )
                 ,last_update_login   = DECODE(last_update_date
                                         ,creation_date, last_update_login
                                         ,fnd_global.login_id
                                        )
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- 通知ワークフロー起動
          xxcso020A02C.main(
             iv_notify_type            => lt_work_request_tbl(idx)
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
-- 20090417_N.Yanagitaira T1_0536 Mod START
--            ,iv_send_employee_number   => lv_application_code
            ,iv_send_employee_number   => lv_employee_number
-- 20090417_N.Yanagitaira T1_0536 Mod END
            ,iv_dest_employee_number   => lt_approve_code_tbl(idx)
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- 正常終了しなかった場合は終了
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_confirm ) THEN
        ---------------------------------
        -- 確認の場合
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- ステータスを承認依頼中に変更する
          IF ( lv_status <> cv_status_enabled ) THEN
--
            UPDATE  xxcso_sp_decision_headers
            SET     status              = cv_status_request
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_header_id = ln_sp_decision_header_id
            ;
--
          END IF;
--
          -- 処理中の回送先を見つけ、決裁状態区分を処理済に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_end
                 /* 2009.04.09 K.Satomura T1_0424対応 START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424対応 END */
                 ,approval_content    = cv_content_confirm
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          lv_approve_code := lt_approve_code_tbl(idx);
--
        END IF;
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_none ) THEN
--
          -- 次の回送先を見つけ、決裁状態区分を処理中に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_during
-- 20090406_N.Yanagitaira T1_0316 Del START
--                 ,approval_date       = NULL
--                 ,approval_content    = NULL
-- 20090406_N.Yanagitaira T1_0316 Del END
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- 通知ワークフロー起動
          xxcso020A02C.main(
             iv_notify_type            => lt_work_request_tbl(idx)
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
-- 20090417_N.Yanagitaira T1_0536 Mod START
--            ,iv_send_employee_number   => lv_application_code
            ,iv_send_employee_number   => lv_employee_number
-- 20090417_N.Yanagitaira T1_0536 Mod END
            ,iv_dest_employee_number   => lt_approve_code_tbl(idx)
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- 正常終了しなかった場合は終了
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_approve ) THEN
        ---------------------------------
        -- 承認の場合
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- ステータスを承認依頼中に変更する
          IF ( lv_status <> cv_status_enabled ) THEN
--
            UPDATE  xxcso_sp_decision_headers
            SET     status              = cv_status_request
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_header_id = ln_sp_decision_header_id
            ;
--
          END IF;
--
          -- 処理中の回送先を見つけ、決裁状態区分を処理済に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_end
                 /* 2009.04.09 K.Satomura T1_0424対応 START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424対応 END */
                 ,approval_content    = cv_content_approve
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          lv_approve_code := lt_approve_code_tbl(idx);
--
        END IF;
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_none ) THEN
--
          -- 次の回送先を見つけ、決裁状態区分を処理中に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_during
-- 20090406_N.Yanagitaira T1_0316 Del START
--                 ,approval_date       = NULL
--                 ,approval_content    = NULL
-- 20090406_N.Yanagitaira T1_0316 Del END
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- 通知ワークフロー起動
          xxcso020A02C.main(
             iv_notify_type            => lt_work_request_tbl(idx)
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
-- 20090417_N.Yanagitaira T1_0536 Mod START
--            ,iv_send_employee_number   => lv_application_code
            ,iv_send_employee_number   => lv_employee_number
-- 20090417_N.Yanagitaira T1_0536 Mod END
            ,iv_dest_employee_number   => lt_approve_code_tbl(idx)
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- 正常終了しなかった場合は終了
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_return ) THEN
        ---------------------------------
        -- 返却の場合
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- ステータスを否決に変更する
          UPDATE  xxcso_sp_decision_headers
          SET     status              = cv_status_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          ;
--
          -- 処理中の回送先を見つけ、決裁状態区分を未処理に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 /* 2009.04.09 K.Satomura T1_0424対応 START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424対応 END */
                 ,approval_content    = cv_content_return
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- 直近の処理済の回送先を見つけ、決裁状態区分を処理中に設定する
          IF ( idx <> 1 ) THEN
--
            UPDATE  xxcso_sp_decision_sends
            SET     approval_state_type = cv_approval_state_during
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx-1)
            ;
--
          END IF;
--
          -- 通知ワークフロー起動
          xxcso020A02C.main(
             iv_notify_type            => cv_notify_return
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
            ,iv_send_employee_number   => lt_approve_code_tbl(idx)
            ,iv_dest_employee_number   => lv_application_code
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- 正常終了しなかった場合は終了
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          /* 20090716_abe_0000385 START*/
          -- 処理中の回送先を見つけ、決裁状態区分を未処理に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 ,approval_content    = cv_content_return
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          AND     approval_state_type <> cv_approval_state_none
          ;
          /* 20090716_abe_0000385 END*/
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_reject ) THEN
        ---------------------------------
        -- 否決の場合
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- ステータスを否決に変更する
          UPDATE  xxcso_sp_decision_headers
          SET     status              = cv_status_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          ;
--
          -- 処理中の回送先を見つけ、決裁状態区分を未処理に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 /* 2009.04.09 K.Satomura T1_0424対応 START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424対応 END */
                 ,approval_content    = cv_content_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- 直近の処理済の回送先を見つけ、決裁状態区分を処理中に設定する
          IF ( idx <> 1 ) THEN
--
            UPDATE  xxcso_sp_decision_sends
            SET     approval_state_type = cv_approval_state_during
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx-1)
            ;
--
          END IF;
--
          -- 通知ワークフロー起動
          xxcso020A02C.main(
             iv_notify_type            => cv_notify_reject
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
            ,iv_send_employee_number   => lt_approve_code_tbl(idx)
            ,iv_dest_employee_number   => lv_application_code
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- 正常終了しなかった場合は終了
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          /* 20090716_abe_0000385 START*/
          -- 処理中の回送先を見つけ、決裁状態区分を未処理に設定する
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 ,approval_content    = cv_content_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          AND     approval_state_type <> cv_approval_state_none
          ;
          /* 20090716_abe_0000385 END*/
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
    END LOOP send_loop;
--
-- 20090406_N.Yanagitaira T1_0316 Add START
    -- 回送先の社員番号に*を入力した場合、決裁日／決済内容／決済コメントを初期化する
    UPDATE  xxcso_sp_decision_sends
    SET     approval_date       = NULL
           ,approval_content    = NULL
           ,approval_comment    = NULL
    WHERE   sp_decision_send_id IN
            (
              SELECT xsds.sp_decision_send_id
              FROM   xxcso_sp_decision_headers xsdh
                    ,xxcso_sp_decision_sends   xsds
              WHERE  xsdh.sp_decision_header_id  = ln_sp_decision_header_id
              AND    xsdh.status                <> cv_status_enabled
              AND    xsds.sp_decision_header_id  = xsdh.sp_decision_header_id
              AND    xsds.approve_code           = cv_approve_init
              AND    xsds.approval_state_type    IN (cv_approval_state_none, cv_approval_state_during)
            )
    ;
-- 20090406_N.Yanagitaira T1_0316 Add END
--
    -- まだ後ろに承認者がいるかどうかを確認する
    IF ( lv_operation_mode = cv_operation_approve ) THEN
--
      SELECT  COUNT('x')
      INTO    ln_approve_code_count
      FROM    xxcso_sp_decision_headers  xsdh
             ,xxcso_sp_decision_sends    xsds
      WHERE   xsdh.sp_decision_header_id  = ln_sp_decision_header_id
      AND     xsdh.status                <> cv_status_enabled
      AND     xsds.sp_decision_header_id  = xsdh.sp_decision_header_id
      AND     xsds.approve_code          <> cv_approve_init
      AND     xsds.approval_state_type    IN (cv_approval_state_none, cv_approval_state_during)
      AND     xsds.work_request_type      = cv_request_approve
      AND     ROWNUM                      = 1
      ;
--
      IF ( ln_approve_code_count = 0 ) THEN
--
        -- 最終承認者の場合は、ステータスを有効、
        -- 承認完了日にシステム日付を設定する
        UPDATE  xxcso_sp_decision_headers
        SET     status                 = cv_status_enabled
               /* 2009.04.09 K.Satomura T1_0424対応 START */
               --,approval_complete_date = SYSDATE
               ,approval_complete_date = xxcso_util_common_pkg.get_online_sysdate
               /* 2009.04.09 K.Satomura T1_0424対応 END */
               ,last_updated_by        = fnd_global.user_id
               ,last_update_date       = SYSDATE
               ,last_update_login      = fnd_global.login_id
        WHERE   sp_decision_header_id = ln_sp_decision_header_id
        ;
--
        IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
          -- 正常終了しなかった場合は終了
          RETURN;
--
        END IF;
--
        -- マスタ連携APIコール
        xxcso020A03C.main(
          errbuf                      => ov_errbuf
         ,retcode                     => ov_retcode
         ,it_sp_decision_header_id    => ln_sp_decision_header_id
         ,ot_cust_account_id          => ln_cust_account_id
         ,ot_contract_customer_id     => ln_contract_customer_id
        );
--
        IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
          -- 正常終了しなかった場合は終了
          RETURN;
--
        END IF;
--
        -- マスタ連携APIからのIDをセットする（設置先）
        UPDATE  xxcso_sp_decision_custs
        SET     customer_id                = ln_cust_account_id
        WHERE   sp_decision_header_id      = ln_sp_decision_header_id
        AND     sp_decision_customer_class = '1'
        ;
--
        -- マスタ連携APIからのIDをセットする（契約先）
        UPDATE  xxcso_sp_decision_custs
        SET     customer_id                = ln_contract_customer_id
-- 20090323_N.Yanagitaira T1_0163 Add START
               ,same_install_account_flag  = 'N'
-- 20090323_N.Yanagitaira T1_0163 Add END
        WHERE   sp_decision_header_id      = ln_sp_decision_header_id
        AND     sp_decision_customer_class = '2'
        ;
--
      END IF;
--
    END IF;
--
    IF NOT ( lb_notify_flag ) THEN
--
      IF ( lv_operation_mode IN ( cv_operation_confirm, cv_operation_approve ) ) THEN
--
        -- 通知ワークフロー起動
        xxcso020A02C.main(
           iv_notify_type            => cv_notify_approve_end
          ,it_sp_decision_header_id  => ln_sp_decision_header_id
          ,iv_send_employee_number   => lv_approve_code
          ,iv_dest_employee_number   => lv_application_code
          ,errbuf                    => ov_errbuf
          ,retcode                   => ov_retcode
        );
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
  END process_request;
--
  /**********************************************************************************
   * Function Name    : process_lock
   * Description      : トランザクションロック処理
   ***********************************************************************************/
  PROCEDURE process_lock(
    in_sp_decision_header_id       IN  NUMBER
   ,iv_sp_decision_number          IN  VARCHAR2
   ,id_last_update_date            IN  DATE
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'process_lock';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_last_update_date          DATE;
    lb_exception_flag            BOOLEAN;
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    lb_exception_flag := FALSE;
--
    BEGIN
--
      SELECT  xsdh.last_update_date
      INTO    ld_last_update_date
      FROM    xxcso_sp_decision_headers  xsdh
      WHERE   xsdh.sp_decision_header_id = in_sp_decision_header_id
      FOR UPDATE NOWAIT
      ;
--
    EXCEPTION
      WHEN nowait_except THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00002';
--
        lb_exception_flag := TRUE;
    END;
--
    IF ( lb_exception_flag = FALSE ) THEN
--
      if ( id_last_update_date < ld_last_update_date ) THEN
--
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00003';
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
  END process_lock;
--
  /**********************************************************************************
   * Function Name    : get_inst_info_parameter
   * Description      : 設置先情報判定
   ***********************************************************************************/
  FUNCTION get_inst_info_parameter(
    in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_inst_info_parameter';
    cv_mc_candidate              CONSTANT VARCHAR2(2)     := '10';
    cv_mc                        CONSTANT VARCHAR2(2)     := '20';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_cust_account_id IS NULL ) THEN
--
      lv_return_value := iv_sp_inst_cust_param;
--
    ELSE
--
      IF ( iv_customer_status IN (cv_mc_candidate, cv_mc) ) THEN
--
        lv_return_value := iv_sp_inst_cust_param;
--
      ELSE
--
        lv_return_value := iv_cust_acct_param;
--
      END IF;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_inst_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_cntr_info_parameter
   * Description      : 契約先情報判定
   ***********************************************************************************/
  FUNCTION get_cntr_info_parameter(
    in_contract_customer_id        IN  NUMBER
   ,iv_same_install_account_flag   IN  VARCHAR2
   ,in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,iv_sp_cntr_cust_param          IN  VARCHAR2
   ,iv_cntrct_cust_param           IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_cntr_info_parameter';
    cv_same                      CONSTANT VARCHAR2(1)     := 'Y';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_contract_customer_id IS NULL ) THEN
--
      IF ( iv_same_install_account_flag = cv_same ) THEN
--
        lv_return_value
          := get_inst_info_parameter(
               in_cust_account_id
              ,iv_customer_status
              ,iv_sp_inst_cust_param
              ,iv_cust_acct_param
             );
--
      ELSE
--
        lv_return_value := iv_sp_cntr_cust_param;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_cntrct_cust_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_cntr_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_bm1_info_parameter
   * Description      : BM1情報判定
   ***********************************************************************************/
  FUNCTION get_bm1_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_bm1_send_type               IN  VARCHAR2
   ,in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,in_contract_customer_id        IN  NUMBER
   ,iv_same_install_account_flag   IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
   ,iv_sp_cntr_cust_param          IN  VARCHAR2
   ,iv_cntrct_cust_param           IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_bm1_info_parameter';
    cv_bm_payment_non            CONSTANT VARCHAR2(1)     := '5';
    cv_same_inst                 CONSTANT VARCHAR2(1)     := '1';
    cv_same_cntr                 CONSTANT VARCHAR2(1)     := '2';
    cv_other                     CONSTANT VARCHAR2(1)     := '3';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_vendor_id IS NULL ) THEN
--
      IF ( iv_bm_payment_type = cv_bm_payment_non ) THEN
--
        lv_return_value := NULL;
--
      ELSE
--
        IF ( iv_bm1_send_type = cv_same_inst ) THEN
--
          lv_return_value
            := get_inst_info_parameter(
                 in_cust_account_id
                ,iv_customer_status
                ,iv_sp_inst_cust_param
                ,iv_cust_acct_param
               );
--
        ELSIF ( iv_bm1_send_type = cv_same_cntr ) THEN
--
          lv_return_value
            := get_cntr_info_parameter(
                 in_contract_customer_id
                ,iv_same_install_account_flag
                ,in_cust_account_id
                ,iv_customer_status
                ,iv_sp_cntr_cust_param
                ,iv_cntrct_cust_param
                ,iv_sp_inst_cust_param
                ,iv_cust_acct_param
               );
--
        ELSE
--
          lv_return_value := iv_sp_vend_cust_param;
--
        END IF;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_vendor_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_bm1_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_bm2_info_parameter
   * Description      : BM2情報判定
   ***********************************************************************************/
  FUNCTION get_bm2_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_bm2_info_parameter';
    cv_bm_payment_non            CONSTANT VARCHAR2(1)     := '5';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_vendor_id IS NULL ) THEN
--
      IF ( iv_bm_payment_type = cv_bm_payment_non ) THEN
--
        lv_return_value := NULL;
--
      ELSE
--
        lv_return_value := iv_sp_vend_cust_param;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_vendor_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_bm2_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_bm3_info_parameter
   * Description      : BM3情報判定
   ***********************************************************************************/
  FUNCTION get_bm3_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_bm3_info_parameter';
    cv_bm_payment_non            CONSTANT VARCHAR2(1)     := '5';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_vendor_id IS NULL ) THEN
--
      IF ( iv_bm_payment_type = cv_bm_payment_non ) THEN
--
        lv_return_value := NULL;
--
      ELSE
--
        lv_return_value := iv_sp_vend_cust_param;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_vendor_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_bm3_info_parameter;
--
  /**********************************************************************************
   * Function Name    : calculate_sc_line
   * Description      : 売価別条件計算（明細行ごと）
   ***********************************************************************************/
  PROCEDURE calculate_sc_line(
    iv_fixed_price                 IN  VARCHAR2
   ,iv_sales_price                 IN  VARCHAR2
   ,iv_bm1_bm_rate                 IN  VARCHAR2
   ,iv_bm1_bm_amt                  IN  VARCHAR2
   ,iv_bm2_bm_rate                 IN  VARCHAR2
   ,iv_bm2_bm_amt                  IN  VARCHAR2
   ,iv_bm3_bm_rate                 IN  VARCHAR2
   ,iv_bm3_bm_amt                  IN  VARCHAR2
   ,on_gross_profit                OUT NUMBER
   ,on_sales_price                 OUT NUMBER
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_bm_amount                   OUT VARCHAR2
   ,ov_bm_conv_rate                OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'calculate_sc_line';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_fixed_price                    NUMBER;
    ln_defined_cost_rate              NUMBER;
    ln_cost_price                     NUMBER;
    ln_bm_rate                        NUMBER;
    ln_bm_amount                      NUMBER;
    ln_bm_conv_rate                   NUMBER;
  BEGIN
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- 設定原価率取得
    SELECT  TO_NUMBER(flvv.attribute1)
    INTO    ln_defined_cost_rate
    FROM    fnd_lookup_values_vl  flvv
    WHERE   flvv.lookup_type               = 'XXCSO1_SP_RULE_SELL_PRICE'
    AND     flvv.lookup_code               = iv_fixed_price
    AND     flvv.enabled_flag              = 'Y'
    AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    ;
--
    ln_fixed_price := TO_NUMBER(REPLACE(iv_fixed_price, ',', ''));
    on_sales_price := TO_NUMBER(REPLACE(iv_sales_price, ',', ''));
    -- 原価計算
    ln_cost_price := ln_fixed_price * ln_defined_cost_rate;
--
    -- 粗利率計算
    on_gross_profit := on_sales_price - ln_cost_price;
--
    -- BM率の合計値を計算
    ln_bm_rate := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm2_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm3_bm_rate, ',', ''), '0'));
--
    -- BM金額の合計値を計算
    ln_bm_amount := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm2_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm3_bm_amt, ',', ''), '0'));
--
    -- 定価換算率を計算
    ln_bm_conv_rate
      := (
          ((on_sales_price * ln_bm_rate / 100) +
           (ln_fixed_price - on_sales_price + ln_bm_amount)
          ) / ln_fixed_price
         ) * 100;
--
    -- 返却値を設定
    ov_bm_rate      := TO_CHAR(ln_bm_rate, 'FM999G999G999G999G990D90');
    ov_bm_amount    := TO_CHAR(ln_bm_amount, 'FM999G999G999G999G990D90');
    ov_bm_conv_rate := TO_CHAR(ROUND(ln_bm_conv_rate, 2), 'FM999G999G999G999G990D90');
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END calculate_sc_line;
--
  /**********************************************************************************
   * Function Name    : calculate_cc_line
   * Description      : 売価別条件計算（明細行ごと）
   ***********************************************************************************/
  PROCEDURE calculate_cc_line(
    iv_container_type              IN  VARCHAR2
   ,iv_discount_amt                IN  VARCHAR2
   ,iv_bm1_bm_rate                 IN  VARCHAR2
   ,iv_bm1_bm_amt                  IN  VARCHAR2
   ,iv_bm2_bm_rate                 IN  VARCHAR2
   ,iv_bm2_bm_amt                  IN  VARCHAR2
   ,iv_bm3_bm_rate                 IN  VARCHAR2
   ,iv_bm3_bm_amt                  IN  VARCHAR2
   ,on_gross_profit                OUT NUMBER
   ,on_sales_price                 OUT NUMBER
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_bm_amount                   OUT VARCHAR2
   ,ov_bm_conv_rate                OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'calculate_cc_line';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_fixed_price                    NUMBER;
    ln_discount_amt                   NUMBER;
    ln_defined_cost_rate              NUMBER;
    ln_cost_price                     NUMBER;
    ln_bm_rate                        NUMBER;
    ln_bm_amount                      NUMBER;
    ln_bm_conv_rate                   NUMBER;
  BEGIN
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- 設定定価、設定原価率取得
    SELECT  TO_NUMBER(flvv.attribute2)
           ,TO_NUMBER(flvv.attribute3)
    INTO    ln_fixed_price
           ,ln_defined_cost_rate
    FROM    fnd_lookup_values_vl  flvv
    WHERE   flvv.lookup_type               = 'XXCSO1_SP_RULE_BOTTLE'
    AND     flvv.lookup_code               = iv_container_type
    AND     flvv.enabled_flag              = 'Y'
    AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    ;
--
    -- 定価からの値引額取得
    ln_discount_amt := TO_NUMBER(NVL(REPLACE(iv_discount_amt, ',' , ''), 0));
--
    -- 原価計算
    ln_cost_price  := ln_fixed_price * ln_defined_cost_rate;
--
    -- 売価計算
    on_sales_price := ln_fixed_price + ln_discount_amt;
--
    -- 粗利率計算
    on_gross_profit := on_sales_price - ln_cost_price;
--
    -- BM率の合計値を計算
    ln_bm_rate := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm2_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm3_bm_rate, ',', ''), '0'));
--
    -- BM金額の合計値を計算
    ln_bm_amount := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm2_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm3_bm_amt, ',', ''), '0'));
--
    -- 定価換算率を計算
    ln_bm_conv_rate
      := (
          ((on_sales_price * ln_bm_rate / 100) +
           (0 - ln_discount_amt + ln_bm_amount)
          ) / ln_fixed_price
         ) * 100;
--
    -- 返却値を設定
    ov_bm_rate      := TO_CHAR(ln_bm_rate, 'FM999G999G999G999G990D90');
    ov_bm_amount    := TO_CHAR(ln_bm_amount, 'FM999G999G999G999G990D90');
    ov_bm_conv_rate := TO_CHAR(ROUND(ln_bm_conv_rate, 2), 'FM999G999G999G999G990D90');
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END calculate_cc_line;
--
  /**********************************************************************************
   * Function Name    : calculate_est_year_profit
   * Description      : 概算年間損益計算
   ***********************************************************************************/
  PROCEDURE calculate_est_year_profit(
    iv_sales_month                 IN  VARCHAR2
   ,iv_sales_gross_margin_rate     IN  VARCHAR2
   ,iv_bm_rate                     IN  VARCHAR2
   ,iv_lease_charge_month          IN  VARCHAR2
   ,iv_construction_charge         IN  VARCHAR2
   ,iv_contract_year_date          IN  VARCHAR2
   ,iv_install_support_amt         IN  VARCHAR2
   ,iv_electricity_amount          IN  VARCHAR2
   ,iv_electricity_amt_month       IN  VARCHAR2
   ,ov_sales_year                  OUT VARCHAR2
   ,ov_year_gross_margin_amt       OUT VARCHAR2
   ,ov_vd_sales_charge             OUT VARCHAR2
   ,ov_install_support_amt_year    OUT VARCHAR2
   ,ov_vd_lease_charge             OUT VARCHAR2
   ,ov_electricity_amt_month       OUT VARCHAR2
   ,ov_electricity_amt_year        OUT VARCHAR2
   ,ov_transportation_charge       OUT VARCHAR2
   ,ov_labor_cost_other            OUT VARCHAR2
   ,ov_total_cost                  OUT VARCHAR2
   ,ov_operating_profit            OUT VARCHAR2
   ,ov_operating_profit_rate       OUT VARCHAR2
   ,ov_break_even_point            OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'calculate_est_year_profit';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_sales_month                    NUMBER;
    ln_sales_gross_margin_rate        NUMBER;
    ln_bm_rate                        NUMBER;
    ln_lease_charge_month             NUMBER;
    ln_construction_charge            NUMBER;
    ln_contract_year_date             NUMBER;
    ln_install_support_amt            NUMBER;
    ln_electricity_amt_month          NUMBER;
    ln_sales_year                     NUMBER;
    ln_year_gross_margin_amt          NUMBER;
    ln_vd_sales_charge                NUMBER;
    ln_install_support_amt_year       NUMBER;
    ln_vd_lease_charge                NUMBER;
    ln_electricity_amt_year           NUMBER;
    ln_transportation_charge          NUMBER;
    ln_labor_cost_other               NUMBER;
    ln_total_cost                     NUMBER;
    ln_operating_profit               NUMBER;
    ln_operating_profit_rate          NUMBER;
    ln_break_even_point               NUMBER;
    ln_constraction_chg_rate          NUMBER;
    ln_transportation_chg_rate        NUMBER;
    ln_labor_cost_other_rate          NUMBER;
  BEGIN
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- 工事費率、運送費率、人件費率取得
    SELECT  TO_NUMBER(flvv1.attribute1)
           ,TO_NUMBER(flvv2.attribute1)
           ,TO_NUMBER(flvv3.attribute1)
    INTO    ln_constraction_chg_rate
           ,ln_transportation_chg_rate
           ,ln_labor_cost_other_rate
    FROM    fnd_lookup_values_vl  flvv1
           ,fnd_lookup_values_vl  flvv2
           ,fnd_lookup_values_vl  flvv3
    WHERE   flvv1.lookup_type               = 'XXCSO1_SP_ROUGH_YEAR_PL'
    AND     flvv2.lookup_type               = 'XXCSO1_SP_ROUGH_YEAR_PL'
    AND     flvv3.lookup_type               = 'XXCSO1_SP_ROUGH_YEAR_PL'
    AND     flvv1.lookup_code               = 'SP_INSTALLATION_COST_RATE'
    AND     flvv2.lookup_code               = 'SP_SHIPPING_COST_RATE'
    AND     flvv3.lookup_code               = 'SP_STAFF_COST_RATE'
    AND     flvv1.enabled_flag              = 'Y'
    AND     NVL(flvv1.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv1.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     flvv2.enabled_flag              = 'Y'
    AND     NVL(flvv2.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv2.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     flvv3.enabled_flag              = 'Y'
    AND     NVL(flvv3.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv3.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    ;
--
    -- 月間売上
    ln_sales_month := TO_NUMBER(NVL(REPLACE(iv_sales_month, ',' , ''), 0));
--
    -- 売上粗利率
    ln_sales_gross_margin_rate := TO_NUMBER(NVL(REPLACE(iv_sales_gross_margin_rate, ',' , ''), 0));
--
    -- BM率
    ln_bm_rate := TO_NUMBER(NVL(REPLACE(iv_bm_rate, ',' , ''), 0));
--
    -- リース料（月額）
    ln_lease_charge_month := TO_NUMBER(NVL(REPLACE(iv_lease_charge_month, ',' , ''), 0));
--
    -- 工事費
    ln_construction_charge := TO_NUMBER(NVL(REPLACE(iv_construction_charge, ',' , ''), 0));
--
    -- 契約年数
    ln_contract_year_date := TO_NUMBER(NVL(REPLACE(iv_contract_year_date, ',' , ''), 0));
--
    -- 初回設置協賛金
    ln_install_support_amt := TO_NUMBER(NVL(REPLACE(iv_install_support_amt, ',' , ''), 0));
--
    -- 電気代（月）
    ln_electricity_amt_month := TO_NUMBER(NVL(REPLACE(iv_electricity_amt_month, ',' , ''), 0));
    IF ( ln_electricity_amt_month = 0 ) THEN
--
      ln_electricity_amt_month
        := ROUND((TO_NUMBER(NVL(REPLACE(iv_electricity_amount, ',', ''), 0)) / 1000), 2);
--
    END IF;
--
    ov_electricity_amt_month := TO_CHAR(ln_electricity_amt_month, 'FM999G999G999G999G990D90');
--
    -- 年間売上
    ln_sales_year := ln_sales_month * 12;
    ov_sales_year := TO_CHAR(ln_sales_year, 'FM999G999G999G999G990');
--
    -- 年間粗利金額
    ln_year_gross_margin_amt := (ln_sales_year * ln_sales_gross_margin_rate) / 100;
    ov_year_gross_margin_amt := TO_CHAR(ln_year_gross_margin_amt, 'FM999G999G999G999G990D90');
--
    -- VD販売手数料
    ln_vd_sales_charge := (ln_sales_year * ln_bm_rate) / 100;
    ov_vd_sales_charge := TO_CHAR(ln_vd_sales_charge, 'FM999G999G999G999G990D90');
--
    -- 設置協賛金／年
    ln_install_support_amt_year := ln_install_support_amt / ln_contract_year_date / 1000;
    ov_install_support_amt_year := TO_CHAR(
                                     ROUND(ln_install_support_amt_year, 2)
                                    ,'FM999G999G999G999G990D90'
                                   );
--
    -- VDリース料
-- 200900507_N.Yanagitaira T1_0200 Mod START
--    ln_vd_lease_charge := ln_lease_charge_month * 12 + 
--                          ln_construction_charge * ln_constraction_chg_rate * 12;
    ln_vd_lease_charge := ln_lease_charge_month * 12 + 
                          ln_construction_charge / ln_contract_year_date;
-- 200900507_N.Yanagitaira T1_0200 Mod END
    ov_vd_lease_charge := TO_CHAR(ln_vd_lease_charge, 'FM999G999G999G999G990D90');
--
    -- 電気代（年）
    ln_electricity_amt_year := ln_electricity_amt_month * 12;
    ov_electricity_amt_year := TO_CHAR(ln_electricity_amt_year, 'FM999G999G999G999G990D90');
--
    -- 運送費A
    ln_transportation_charge := ln_sales_year * ln_transportation_chg_rate;
    ov_transportation_charge := TO_CHAR(ln_transportation_charge, 'FM999G999G999G999G990D90');
--
    -- 人件費
    ln_labor_cost_other := ln_sales_year * ln_labor_cost_other_rate;
    ov_labor_cost_other := TO_CHAR(ln_labor_cost_other, 'FM999G999G999G999G990D90');
--
    -- 費用合計
    ln_total_cost := ln_vd_sales_charge +
                     ln_vd_lease_charge +
                     ln_electricity_amt_year +
-- 200900507_N.Yanagitaira T1_0200 Add START
                     ln_install_support_amt_year +
-- 200900507_N.Yanagitaira T1_0200 Add END
                     ln_transportation_charge +
                     ln_labor_cost_other;
    ov_total_cost := TO_CHAR(ln_total_cost, 'FM999G999G999G999G990D90');
--
    -- 営業利益
    ln_operating_profit := ln_year_gross_margin_amt - ln_total_cost;
    ov_operating_profit := TO_CHAR(ln_operating_profit, 'FM999G999G999G999G990D90');
--
    -- 営業利益率
    ln_operating_profit_rate := (ln_operating_profit / ln_sales_year) * 100;
    ov_operating_profit_rate := TO_CHAR(
                                  ROUND(ln_operating_profit_rate, 2)
                                 ,'FM999G999G999G999G990D90'
                                );
--
    -- 損益分岐点
-- 2009/10/26 K.Satomura E_T4_00075 Mod START
    --ln_break_even_point := (ln_vd_lease_charge +
    --                        ln_electricity_amt_year +
    --                        ln_labor_cost_other
    --                       ) / 
    --                       (
    --                        (ln_year_gross_margin_amt -
    --                         ln_vd_sales_charge -
    --                         ln_transportation_charge
    --                        ) / ln_sales_year
    --                       );
    -- 損益分岐点 = (A / (1 - (B  / 年間粗利金額))) / (売上粗利率 / 100)
    --          A = ＶＤリース料 + 設置協賛金／年 + 電気代（年）
    --          B = ＶＤ販売手数料 + 運送費Ａ + 人件費他
    ln_break_even_point := (
                             (ln_vd_lease_charge + ln_install_support_amt_year + ln_electricity_amt_year) /
                             (1 - 
                               (
                                 (ln_vd_sales_charge + ln_transportation_charge + ln_labor_cost_other) / ln_year_gross_margin_amt
                               )
                             )
                           ) / (ln_sales_gross_margin_rate / 100)
                           ;
    --
-- 2009/10/26 K.Satomura E_T4_00075 Mod End
    ov_break_even_point := TO_CHAR(ROUND(ln_break_even_point, 2), 'FM999G999G999G999G990D90');
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END calculate_est_year_profit;
--
  /**********************************************************************************
   * Function Name    : get_gross_profit_rate
   * Description      : 粗利率取得
   ***********************************************************************************/
  FUNCTION get_gross_profit_rate(
    in_total_gross_profit          IN  NUMBER
   ,in_total_sales_price           IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_gross_profit_rate';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_gross_profit_rate         NUMBER;
  BEGIN
    ln_gross_profit_rate := (in_total_gross_profit / in_total_sales_price) * 100 - 1;
    RETURN TO_CHAR(ROUND(ln_gross_profit_rate, 2), 'FM999G999G999G999G990D90');
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_gross_profit_rate;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_1
   * Description      : 承認権限レベル番号１取得
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_1(
    iv_fixed_price                 IN  VARCHAR2
   ,iv_sales_price                 IN  VARCHAR2
   ,iv_discount_amt                IN  VARCHAR2
   ,iv_bm_conv_rate                IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_1';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_discount_amt         NUMBER;
    ln_bm_conv_rate         NUMBER;
    ln_appr_auth_level_num  NUMBER;
--
  BEGIN
--
    IF ( iv_fixed_price IS NOT NULL ) THEN
--
      ln_discount_amt := TO_NUMBER(REPLACE(iv_fixed_price, ',', '')) -
                         TO_NUMBER(REPLACE(iv_sales_price, ',', ''));
--
    ELSE
--
      ln_discount_amt := 0 - TO_NUMBER(REPLACE(iv_discount_amt, ',', ''));
--
    END IF;
    ln_bm_conv_rate := TO_NUMBER(REPLACE(iv_bm_conv_rate, ',', ''));
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                         = 'XXCSO1_SP_WF_RULE_DETAIL_1'
      AND     flvv.enabled_flag                                        = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_discount_amt)        <= ln_discount_amt
      AND     NVL(TO_NUMBER(flvv.attribute3), ln_discount_amt)        >= ln_discount_amt
      AND     NVL(TO_NUMBER(flvv.attribute4), (ln_bm_conv_rate - 1))   < ln_bm_conv_rate
      AND     NVL(TO_NUMBER(flvv.attribute5), ln_bm_conv_rate)        >= ln_bm_conv_rate
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_appr_auth_level_num_1;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_2
   * Description      : 承認権限レベル番号２取得
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_2(
    iv_install_support_amt         IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_2';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_install_support_amt  NUMBER;
    ln_appr_auth_level_num  NUMBER;
--
  BEGIN
--
    ln_install_support_amt := NVL(TO_NUMBER(REPLACE(iv_install_support_amt, ',', '')), 0);
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_WF_RULE_DETAIL_2'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_install_support_amt) 
                                                               <= ln_install_support_amt
      AND     NVL(TO_NUMBER(flvv.attribute3), (ln_install_support_amt + 1))
                                                                > ln_install_support_amt
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_appr_auth_level_num_2;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_3
   * Description      : 承認権限レベル番号３取得
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_3(
    iv_electricity_amt             IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_3';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_electricity_amt      NUMBER;
    ln_appr_auth_level_num  NUMBER;
--
  BEGIN
--
    ln_electricity_amt := NVL(TO_NUMBER(REPLACE(iv_electricity_amt, ',', '')), 0);
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_WF_RULE_DETAIL_3'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_electricity_amt) 
                                                               <= ln_electricity_amt
      AND     NVL(TO_NUMBER(flvv.attribute3), (ln_electricity_amt + 1))
                                                                > ln_electricity_amt
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_appr_auth_level_num_3;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_4
   * Description      : 承認権限レベル番号４取得
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_4(
    iv_construction_charge         IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_4';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_construction_charge      NUMBER;
    ln_appr_auth_level_num      NUMBER;
--
  BEGIN
--
    ln_construction_charge := NVL(TO_NUMBER(REPLACE(iv_construction_charge, ',', '')), 0) * 1000;
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_WF_RULE_DETAIL_4'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_construction_charge) 
                                                               <= ln_construction_charge
      AND     NVL(TO_NUMBER(flvv.attribute3), (ln_construction_charge + 1))
                                                                > ln_construction_charge
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_appr_auth_level_num_4;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_0
   * Description      : 承認権限レベル番号（デフォルト）取得
   ***********************************************************************************/
  PROCEDURE get_appr_auth_level_num_0(
    on_appr_auth_level_num         OUT NUMBER
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_0';
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
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.lookup_code)), 0)
      INTO    on_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_DECISION_LEVEL'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     flvv.attribute3                                   = '1'
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00307';
      WHEN TOO_MANY_ROWS THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00308';
    END;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_appr_auth_level_num_0;
--
  /**********************************************************************************
   * Function Name    : chk_double_byte_kana
   * Description      : 全角カナチェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_double_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte_kana';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
    ln_length                    NUMBER;
--
  BEGIN
--
    lv_return_value := '1';
    ln_length := LENGTH(iv_value);
--
    << dobule_byte_check_loop >>
    FOR idx IN 1..ln_length
    LOOP
--
      lb_return_value := xxccp_common_pkg.chk_double_byte_kana(SUBSTR(iv_value, idx, 1));
--
      IF NOT ( lb_return_value ) THEN
--
        lv_return_value := '0';
        EXIT dobule_byte_check_loop;
--
      END IF;
--
    END LOOP dobule_byte_check_loop;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_double_byte_kana;
--
  /**********************************************************************************
   * Function Name    : chk_tel_format
   * Description      : 電話番号チェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_tel_format(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_tel_format';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lb_return_value := xxccp_common_pkg.chk_tel_format(iv_value);
--
    IF ( lb_return_value ) THEN
--
      lv_return_value := '1';
--
    ELSE
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_tel_format;
--
  /**********************************************************************************
   * Function Name    : conv_number_separate
   * Description      : 数値セパレート変換
   ***********************************************************************************/
  PROCEDURE conv_number_separate(
    iv_sele_number                 IN  VARCHAR2
   ,iv_contract_year_date          IN  VARCHAR2
   ,iv_install_support_amt         IN  VARCHAR2
   ,iv_install_support_amt2        IN  VARCHAR2
   ,iv_payment_cycle               IN  VARCHAR2
   ,iv_electricity_amount          IN  VARCHAR2
   ,iv_sales_month                 IN  VARCHAR2
   ,iv_bm_rate                     IN  VARCHAR2
   ,iv_vd_sales_charge             IN  VARCHAR2
   ,iv_lease_charge_month          IN  VARCHAR2
   ,iv_contruction_charge          IN  VARCHAR2
   ,iv_electricity_amt_month       IN  VARCHAR2
   ,ov_sele_number                 OUT VARCHAR2
   ,ov_contract_year_date          OUT VARCHAR2
   ,ov_install_support_amt         OUT VARCHAR2
   ,ov_install_support_amt2        OUT VARCHAR2
   ,ov_payment_cycle               OUT VARCHAR2
   ,ov_electricity_amount          OUT VARCHAR2
   ,ov_sales_month                 OUT VARCHAR2
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_vd_sales_charge             OUT VARCHAR2
   ,ov_lease_charge_month          OUT VARCHAR2
   ,ov_contruction_charge          OUT VARCHAR2
   ,ov_electricity_amt_month       OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'conv_number_separate';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_sele_number                 NUMBER;
    ln_contract_year_date          NUMBER;
    ln_install_support_amt         NUMBER;
    ln_install_support_amt2        NUMBER;
    ln_payment_cycle               NUMBER;
    ln_electricity_amount          NUMBER;
    ln_sales_month                 NUMBER;
    ln_bm_rate                     NUMBER;
    ln_vd_sales_charge             NUMBER;
    ln_lease_charge_month          NUMBER;
    ln_contruction_charge          NUMBER;
    ln_electricity_amt_month       NUMBER;
--
  BEGIN
--
    BEGIN
      ln_sele_number := TO_NUMBER(REPLACE(iv_sele_number, ',',''));
      IF ( (ln_sele_number - TRUNC(ln_sele_number)) = 0 ) THEN
        ov_sele_number := TO_CHAR(ln_sele_number, 'FM999G999G999G999G990');
      ELSE
        ov_sele_number := iv_sele_number;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_sele_number := iv_sele_number;
    END;
--
    BEGIN
      ln_contract_year_date := TO_NUMBER(REPLACE(iv_contract_year_date, ',',''));
      IF ( (ln_contract_year_date - TRUNC(ln_contract_year_date)) = 0 ) THEN
        ov_contract_year_date := TO_CHAR(ln_contract_year_date, 'FM999G999G999G999G990');
      ELSE
        ov_contract_year_date := iv_contract_year_date;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_contract_year_date := iv_contract_year_date;
    END;
--
    BEGIN
      ln_install_support_amt := TO_NUMBER(REPLACE(iv_install_support_amt, ',',''));
      IF ( (ln_install_support_amt - TRUNC(ln_install_support_amt)) = 0 ) THEN
        ov_install_support_amt := TO_CHAR(ln_install_support_amt, 'FM999G999G999G999G990');
      ELSE
        ov_install_support_amt := iv_install_support_amt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_install_support_amt := iv_install_support_amt;
    END;
--
    BEGIN
      ln_install_support_amt2 := TO_NUMBER(REPLACE(iv_install_support_amt2, ',',''));
      IF ( (ln_install_support_amt2 - TRUNC(ln_install_support_amt2)) = 0 ) THEN
        ov_install_support_amt2 := TO_CHAR(ln_install_support_amt2, 'FM999G999G999G999G990');
      ELSE
        ov_install_support_amt2 := iv_install_support_amt2;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_install_support_amt2 := iv_install_support_amt2;
    END;
--
    BEGIN
      ln_payment_cycle := TO_NUMBER(REPLACE(iv_payment_cycle, ',',''));
      IF ( (ln_payment_cycle - TRUNC(ln_payment_cycle)) = 0 ) THEN
        ov_payment_cycle := TO_CHAR(ln_payment_cycle, 'FM999G999G999G999G990');
      ELSE
        ov_payment_cycle := iv_payment_cycle;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_payment_cycle := iv_payment_cycle;
    END;
--
    BEGIN
      ln_electricity_amount := TO_NUMBER(REPLACE(iv_electricity_amount, ',',''));
      IF ( (ln_electricity_amount - TRUNC(ln_electricity_amount)) = 0 ) THEN
        ov_electricity_amount := TO_CHAR(ln_electricity_amount, 'FM999G999G999G999G990');
      ELSE
        ov_electricity_amount := iv_electricity_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_electricity_amount := iv_electricity_amount;
    END;
--
    BEGIN
      ln_sales_month := TO_NUMBER(REPLACE(iv_sales_month, ',',''));
      IF ( (ln_sales_month - TRUNC(ln_sales_month)) = 0 ) THEN
        ov_sales_month := TO_CHAR(ln_sales_month, 'FM999G999G999G999G990');
      ELSE
        ov_sales_month := iv_sales_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_sales_month := iv_sales_month;
    END;
--
    BEGIN
      ln_bm_rate := TO_NUMBER(REPLACE(iv_bm_rate, ',',''));
      IF ( (ln_bm_rate - TRUNC(ln_bm_rate, 2)) = 0 ) THEN
        ov_bm_rate := TO_CHAR(ln_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm_rate := iv_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm_rate := iv_bm_rate;
    END;
--
    BEGIN
      ln_vd_sales_charge := TO_NUMBER(REPLACE(iv_vd_sales_charge, ',',''));
      IF ( (ln_vd_sales_charge - TRUNC(ln_vd_sales_charge, 2)) = 0 ) THEN
        ov_vd_sales_charge := TO_CHAR(ln_vd_sales_charge, 'FM999G999G999G999G990D90');
      ELSE
        ov_vd_sales_charge := iv_vd_sales_charge;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_vd_sales_charge := iv_vd_sales_charge;
    END;
--
    BEGIN
      ln_lease_charge_month := TO_NUMBER(REPLACE(iv_lease_charge_month, ',',''));
      IF ( (ln_lease_charge_month - TRUNC(ln_lease_charge_month)) = 0 ) THEN
        ov_lease_charge_month := TO_CHAR(ln_lease_charge_month, 'FM999G999G999G999G990');
      ELSE
        ov_lease_charge_month := iv_lease_charge_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_lease_charge_month := iv_lease_charge_month;
    END;
--
    BEGIN
      ln_contruction_charge := TO_NUMBER(REPLACE(iv_contruction_charge, ',',''));
      IF ( (ln_contruction_charge - TRUNC(ln_contruction_charge)) = 0 ) THEN
        ov_contruction_charge := TO_CHAR(ln_contruction_charge, 'FM999G999G999G999G990');
      ELSE
        ov_contruction_charge := iv_contruction_charge;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_contruction_charge := iv_contruction_charge;
    END;
--
    BEGIN
      ln_electricity_amt_month := TO_NUMBER(REPLACE(iv_electricity_amt_month, ',',''));
      IF ( (ln_electricity_amt_month - TRUNC(ln_electricity_amt_month, 2)) = 0 ) THEN
        ov_electricity_amt_month := TO_CHAR(ln_electricity_amt_month, 'FM999G999G999G999G990D90');
      ELSE
        ov_electricity_amt_month := iv_electricity_amt_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_electricity_amt_month := iv_electricity_amt_month;
    END;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END conv_number_separate;
--
  /**********************************************************************************
   * Function Name    : conv_line_number_separate
   * Description      : 数値セパレート変換（明細）
   ***********************************************************************************/
  PROCEDURE conv_line_number_separate(
    iv_sales_price                  IN  VARCHAR2
   ,iv_discount_amt                 IN  VARCHAR2
   ,iv_total_bm_rate                IN  VARCHAR2
   ,iv_total_bm_amount              IN  VARCHAR2
   ,iv_total_bm_conv_rate           IN  VARCHAR2
   ,iv_bm1_bm_rate                  IN  VARCHAR2
   ,iv_bm1_bm_amount                IN  VARCHAR2
   ,iv_bm2_bm_rate                  IN  VARCHAR2
   ,iv_bm2_bm_amount                IN  VARCHAR2
   ,iv_bm3_bm_rate                  IN  VARCHAR2
   ,iv_bm3_bm_amount                IN  VARCHAR2
   ,ov_sales_price                  OUT VARCHAR2
   ,ov_discount_amt                 OUT VARCHAR2
   ,ov_total_bm_rate                OUT VARCHAR2
   ,ov_total_bm_amount              OUT VARCHAR2
   ,ov_total_bm_conv_rate           OUT VARCHAR2
   ,ov_bm1_bm_rate                  OUT VARCHAR2
   ,ov_bm1_bm_amount                OUT VARCHAR2
   ,ov_bm2_bm_rate                  OUT VARCHAR2
   ,ov_bm2_bm_amount                OUT VARCHAR2
   ,ov_bm3_bm_rate                  OUT VARCHAR2
   ,ov_bm3_bm_amount                OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'conv_line_number_separate';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_sales_price                  NUMBER;
    ln_discount_amt                 NUMBER;
    ln_total_bm_rate                NUMBER;
    ln_total_bm_amount              NUMBER;
    ln_total_bm_conv_rate           NUMBER;
    ln_bm1_bm_rate                  NUMBER;
    ln_bm1_bm_amount                NUMBER;
    ln_bm2_bm_rate                  NUMBER;
    ln_bm2_bm_amount                NUMBER;
    ln_bm3_bm_rate                  NUMBER;
    ln_bm3_bm_amount                NUMBER;
--
  BEGIN
--
    BEGIN
      ln_sales_price := TO_NUMBER(REPLACE(iv_sales_price, ',',''));
      IF ( (ln_sales_price - TRUNC(ln_sales_price)) = 0 ) THEN
        ov_sales_price := TO_CHAR(ln_sales_price, 'FM999G999G999G999G990');
      ELSE
        ov_sales_price := iv_sales_price;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_sales_price := iv_sales_price;
    END;
--
    BEGIN
      ln_discount_amt := TO_NUMBER(REPLACE(iv_discount_amt, ',',''));
      IF ( (ln_discount_amt - TRUNC(ln_discount_amt)) = 0 ) THEN
        ov_discount_amt := TO_CHAR(ln_discount_amt, 'FM999G999G999G999G990');
      ELSE
        ov_discount_amt := iv_discount_amt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_discount_amt := iv_discount_amt;
    END;
--
    BEGIN
      ln_total_bm_rate := TO_NUMBER(REPLACE(iv_total_bm_rate, ',',''));
      IF ( (ln_total_bm_rate - TRUNC(ln_total_bm_rate, 2)) = 0 ) THEN
        ov_total_bm_rate := TO_CHAR(ln_total_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_total_bm_rate := iv_total_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_total_bm_rate := iv_total_bm_rate;
    END;
--
    BEGIN
      ln_total_bm_amount := TO_NUMBER(REPLACE(iv_total_bm_amount, ',',''));
      IF ( (ln_total_bm_amount - TRUNC(ln_total_bm_amount, 2)) = 0 ) THEN
        ov_total_bm_amount := TO_CHAR(ln_total_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_total_bm_amount := iv_total_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_total_bm_amount := iv_total_bm_amount;
    END;
--
    BEGIN
      ln_total_bm_conv_rate := TO_NUMBER(REPLACE(iv_total_bm_conv_rate, ',',''));
      IF ( (ln_total_bm_conv_rate - TRUNC(ln_total_bm_conv_rate, 2)) = 0 ) THEN
        ov_total_bm_conv_rate := TO_CHAR(ln_total_bm_conv_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_total_bm_conv_rate := iv_total_bm_conv_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_total_bm_conv_rate := iv_total_bm_conv_rate;
    END;
--
    BEGIN
      ln_bm1_bm_rate := TO_NUMBER(REPLACE(iv_bm1_bm_rate, ',',''));
      IF ( (ln_bm1_bm_rate - TRUNC(ln_bm1_bm_rate, 2)) = 0 ) THEN
        ov_bm1_bm_rate := TO_CHAR(ln_bm1_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm1_bm_rate := iv_bm1_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm1_bm_rate := iv_bm1_bm_rate;
    END;
--
    BEGIN
      ln_bm1_bm_amount := TO_NUMBER(REPLACE(iv_bm1_bm_amount, ',',''));
      IF ( (ln_bm1_bm_amount - TRUNC(ln_bm1_bm_amount, 2)) = 0 ) THEN
        ov_bm1_bm_amount := TO_CHAR(ln_bm1_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm1_bm_amount := iv_bm1_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm1_bm_amount := iv_bm1_bm_amount;
    END;
--
    BEGIN
      ln_bm2_bm_rate := TO_NUMBER(REPLACE(iv_bm2_bm_rate, ',',''));
      IF ( (ln_bm2_bm_rate - TRUNC(ln_bm2_bm_rate, 2)) = 0 ) THEN
        ov_bm2_bm_rate := TO_CHAR(ln_bm2_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm2_bm_rate := iv_bm2_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm2_bm_rate := iv_bm2_bm_rate;
    END;
--
    BEGIN
      ln_bm2_bm_amount := TO_NUMBER(REPLACE(iv_bm2_bm_amount, ',',''));
      IF ( (ln_bm2_bm_amount - TRUNC(ln_bm2_bm_amount, 2)) = 0 ) THEN
        ov_bm2_bm_amount := TO_CHAR(ln_bm2_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm2_bm_amount := iv_bm2_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm2_bm_amount := iv_bm2_bm_amount;
    END;
--
    BEGIN
      ln_bm3_bm_rate := TO_NUMBER(REPLACE(iv_bm3_bm_rate, ',',''));
      IF ( (ln_bm3_bm_rate - TRUNC(ln_bm3_bm_rate, 2)) = 0 ) THEN
        ov_bm3_bm_rate := TO_CHAR(ln_bm3_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm3_bm_rate := iv_bm3_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm3_bm_rate := iv_bm3_bm_rate;
    END;
--
    BEGIN
      ln_bm3_bm_amount := TO_NUMBER(REPLACE(iv_bm3_bm_amount, ',',''));
      IF ( (ln_bm3_bm_amount - TRUNC(ln_bm3_bm_amount, 2)) = 0 ) THEN
        ov_bm3_bm_amount := TO_CHAR(ln_bm3_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm3_bm_amount := iv_bm3_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm3_bm_amount := iv_bm3_bm_amount;
    END;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END conv_line_number_separate;
--
-- 20090427_N.Yanagitaira T1_0708 Add START
  /**********************************************************************************
   * Function Name    : chk_double_byte
   * Description      : 全角文字チェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_double_byte(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
    lb_return_value := xxccp_common_pkg.chk_double_byte(iv_value);
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_double_byte;
--
  /**********************************************************************************
   * Function Name    : chk_single_byte_kana
   * Description      : 半角カナチェック（共通関数ラッピング）
   ***********************************************************************************/
  FUNCTION chk_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_single_byte_kana';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
-- 20090605_N.Yanagitaira T1_1307 Mod START
--    lb_return_value := xxccp_common_pkg.chk_single_byte_kana(iv_value);
    -- 共通関数の半角文字チェックを行う
    lb_return_value := xxccp_common_pkg.chk_single_byte(iv_value);
-- 20090605_N.Yanagitaira T1_1307 Mod END
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_single_byte_kana;
--
-- 20090427_N.Yanagitaira T1_0708 Add END
--
-- 20091129_D.Abe E_本稼動_00106 Mod START
--
  /**********************************************************************************
   * Function Name    : chk_account_many
   * Description      : アカウント複数判定
   ***********************************************************************************/
  PROCEDURE chk_account_many(
    iv_account_number           IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_account_many';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_count                     NUMBER;
    lv_errmsg                    VARCHAR2(2000);
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR l_account_cur
    IS
      SELECT account_number
      FROM   xxcso_cust_accounts_v xcav1,
             (SELECT party_id
              FROM   xxcso_cust_accounts_v  xtsdr
              WHERE  account_number = iv_account_number
             )xcav2
      WHERE xcav1.party_id = xcav2.party_id 
      ORDER BY account_number
    ;
    -- *** ローカル・レコード *** 
    l_account_cur_rec  l_account_cur%ROWTYPE;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ln_count := 0;
    lv_errmsg:=NULL;
    -- カーソルオープン
    OPEN l_account_cur;
--
    <<account_loop>>
    LOOP
      FETCH l_account_cur INTO l_account_cur_rec;
--
      EXIT WHEN l_account_cur%NOTFOUND
        OR l_account_cur%ROWCOUNT = 0;
      IF (ln_count = 0 ) THEN
        lv_errmsg :=  l_account_cur_rec.account_number;
      ELSE
        lv_errmsg := lv_errmsg || ',' || l_account_cur_rec.account_number;
      END IF;
      ln_count := ln_count + 1;
--
    END LOOP account_loop;
--
    -- カーソル・クローズ
    CLOSE l_account_cur;

    IF (ln_count > 1) THEN
      ov_errmsg := lv_errmsg;
      ov_retcode := xxcso_common_pkg.gv_status_warn;
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
  END chk_account_many;
--
-- 20091129_D.Abe E_本稼動_00106 Mod END
-- 20100112_D.Abe E_本稼動_00823 Mod START
  /**********************************************************************************
   * Function Name    : chk_cust_site_uses
   * Description      : 顧客使用目的チェック
   ***********************************************************************************/
  PROCEDURE chk_cust_site_uses(
    iv_account_number           IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_cust_site_uses';
    -- ===============================
    -- *** ローカル定数 ***
    -- ===============================
    cv_ship_to_site_code    CONSTANT VARCHAR2(30) := 'SHIP_TO';
    cv_bill_to_site_code    CONSTANT VARCHAR2(30) := 'BILL_TO';
    cv_site_use_status      CONSTANT VARCHAR2(30) := 'A';
    cv_site_use_lookup_type CONSTANT VARCHAR2(30) := 'SITE_USE_CODE';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_count                     NUMBER;
    lv_errmsg                    VARCHAR2(2000);
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR l_site_uses_cur
    IS
      -- 顧客使用目的の取得(出荷先・請求先以外)
      SELECT flvv.meaning         meaning
      FROM   hz_cust_accounts     hca
            ,hz_cust_acct_sites   hcas
            ,hz_cust_site_uses    hcsu
            ,fnd_lookup_values_vl flvv
      WHERE  hca.account_number  = iv_account_number
      AND    hca.cust_account_id = hcas.cust_account_id
      AND    hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
      AND    (
               (hcsu.site_use_code  <> cv_ship_to_site_code)
               AND
               (hcsu.site_use_code  <> cv_bill_to_site_code)
             )
      AND    hcsu.status        = cv_site_use_status
      AND    flvv.lookup_type   = cv_site_use_lookup_type
      AND    flvv.lookup_code   = hcsu.site_use_code
      ;

    -- *** ローカル・レコード *** 
    l_site_uses_cur_rec  l_site_uses_cur%ROWTYPE;

--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ln_count := 0;
    lv_errmsg:=NULL;
    -- カーソルオープン
    OPEN l_site_uses_cur;
--
    <<site_uses_loop>>
    LOOP
      FETCH l_site_uses_cur INTO l_site_uses_cur_rec;
--
      EXIT WHEN l_site_uses_cur%NOTFOUND
        OR l_site_uses_cur%ROWCOUNT = 0;
      IF (ln_count = 0 ) THEN
        lv_errmsg :=  l_site_uses_cur_rec.meaning;
      ELSE
        lv_errmsg := lv_errmsg || '、' || l_site_uses_cur_rec.meaning;
      END IF;
      ln_count := ln_count + 1;
--
    END LOOP site_uses_loop;
--
    -- カーソル・クローズ
    CLOSE l_site_uses_cur;

    IF (ln_count > 0) THEN
      ov_errmsg := lv_errmsg;
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
    --
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_cust_site_uses;
--
-- 20100112_D.Abe E_本稼動_00823 Mod END
-- 20100115_D.Abe E_本稼動_00950 Mod START
  /**********************************************************************************
   * Function Name    : chk_validate_db
   * Description      : ＤＢ更新判定チェック
   ***********************************************************************************/
  PROCEDURE chk_validate_db(
    in_sp_decision_header_id      IN  NUMBER
   ,id_last_update_date           IN  DATE
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_validate_db';

    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_last_update_date          DATE;
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    lb_return_value := FALSE;

    SELECT  xsdh.last_update_date
    INTO    ld_last_update_date
    FROM    xxcso_sp_decision_headers  xsdh
    WHERE   xsdh.sp_decision_header_id = in_sp_decision_header_id;

    IF ( id_last_update_date < ld_last_update_date ) THEN
      lb_return_value := TRUE;
    END IF;

    IF (lb_return_value) THEN
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
    --
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_validate_db;
--
-- 20100115_D.Abe E_本稼動_00950 Mod END
END xxcso_020001j_pkg;
/
