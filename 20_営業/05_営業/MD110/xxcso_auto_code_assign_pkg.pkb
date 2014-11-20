CREATE OR REPLACE PACKAGE BODY xxcso_auto_code_assign_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_AUTO_CODE_ASSIGN_PKG(BODY)
 * Description      : 共通関数(XXCSO採番）
 * MD.050/070       :
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  auto_code_assign          F    -     自動採番関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/21    1.0   T.maruyama       新規作成
 *  2008/12/25    1.0   M.maruyama       採番種別'2'（契約書番号)の戻り値編集を修正
 *                                       日付値を'YYYYMMDD'から'YYMMDD'へ
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_auto_code_assign_pkg';   -- パッケージ名
  cv_app_name         CONSTANT VARCHAR2(5)   := 'XXCSO';                        -- アプリケーション短縮名
  cv_msg_part         CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)   := '.';
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

  --*** 処理部共通例外 ***
  g_process_expt      EXCEPTION;
  --*** 共通関数例外 ***
  g_api_expt          EXCEPTION;
--
   /**********************************************************************************
   * Function Name    : auto_code_assign
   * Description      : 自動採番関数
   ***********************************************************************************/
  FUNCTION auto_code_assign(
    iv_cl_assign             IN  VARCHAR2,               -- 採番種別（'1':見積、'2':契約）
    iv_base_code             IN  VARCHAR2,               -- 拠点コード
    id_base_date             IN  DATE                    -- 処理日付（YYYMMDD）
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'auto_code_assign';
    cn_max_seq_number_1        CONSTANT NUMBER          := 9999;   --見積最大番号
    cn_max_seq_number_2        CONSTANT NUMBER          := 9999;   --契約最大番号
    cn_cntrct_seq_prefix       CONSTANT VARCHAR2(2)     := '03';   --契約書番号用
    --logメッセージ
    cv_log_msg_1               CONSTANT VARCHAR2(100)   := '採番種別不正';
    cv_log_msg_2               CONSTANT VARCHAR2(100)   := '拠点ＣＤ不正';
    cv_log_msg_3               CONSTANT VARCHAR2(100)   := '年度取得失敗';
    cv_log_msg_4               CONSTANT VARCHAR2(100)   := '採番テーブル最大値エラー';
    cv_log_msg_5               CONSTANT VARCHAR2(100)   := '処理日付NULL';
    cv_log_msg_6               CONSTANT VARCHAR2(100)   := '拠点ＣＤNULL';    
--
    -- トークンコード
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lt_base_code               xxcso_aff_base_v2.base_code%TYPE;
    ln_business_year           NUMBER;
    lt_seq_number              xxcso_code_assignments.seq_number%TYPE;
    lt_process_date            xxcso_code_assignments.process_date%TYPE;
    lv_ret_seq_number          VARCHAR2(100);
    lv_log_msg                 VARCHAR2(1000);
--
--  --自律型トランザクション
    PRAGMA AUTONOMOUS_TRANSACTION;
--
--
  BEGIN
--
    --------------------------------------------------
    -- パラメータ採番種別（'1':見積、'2':契約）チェック
    --------------------------------------------------
    IF ( iv_cl_assign NOT IN ('1', '2') ) 
    OR ( iv_cl_assign IS NULL ) THEN
      --'1','2'以外またはNULLの場合はエラー
      lv_log_msg := cv_log_msg_1;
      RAISE g_process_expt;
    END IF;
--
    --------------------------------------------------
    -- パラメータ処理日必須
    --------------------------------------------------
    IF ( id_base_date IS NULL ) THEN
      lv_log_msg := cv_log_msg_5;
      RAISE g_process_expt;
    END IF;
--
    --------------------------------------------------
    -- パラメータ拠点コードチェック
    --------------------------------------------------
    --見積の場合
    IF ( iv_cl_assign = '1' ) THEN
      --必須チェック
      IF ( iv_base_code IS NULL ) THEN
        lv_log_msg := cv_log_msg_6;
        RAISE g_process_expt;
      END IF;
--
      --存在チェック
      BEGIN
        SELECT abv.base_code
        INTO   lt_base_code
        FROM   xxcso_aff_base_v2 abv
        WHERE  abv.base_code = iv_base_code;
      EXCEPTION
        WHEN OTHERS THEN
          lv_log_msg := cv_log_msg_2;
          RAISE g_process_expt;
      END;
--
    END IF;
--
    --------------------------------------------------
    -- 年度取得
    --------------------------------------------------
    --見積の場合
    IF ( iv_cl_assign = '1' ) THEN
      --年度取得
      ln_business_year := xxcso_util_common_pkg.get_business_year(
                            iv_year_month => TO_CHAR(id_base_date, 'YYYYMM')
                          );
      IF ( ln_business_year IS NULL ) THEN
        lv_log_msg := cv_log_msg_3;
        RAISE g_process_expt;
      END IF;
    END IF;
--
    --------------------------------------------------
    -- 自動採番処理：'1'（見積）の場合
    --------------------------------------------------
    IF ( iv_cl_assign = '1' ) THEN
      ----------------------------------------------
      --採番テーブル検索
      ----------------------------------------------
      BEGIN
        SELECT ca.seq_number
        INTO   lt_seq_number
        FROM   xxcso_code_assignments ca
        WHERE  ca.code_assignment_type = iv_cl_assign
        AND    ca.base_code            = iv_base_code
        AND    ca.fiscal_year          = TO_CHAR(ln_business_year)
        FOR UPDATE;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --存在しない場合
          lt_seq_number := NULL;
      END;
--
      ----------------------------------------------
      --採番処理
      ----------------------------------------------   
      IF ( lt_seq_number IS NOT NULL ) THEN
        ----------------------------------------------
        --採番テーブルに採番用レコードが存在する場合
        ----------------------------------------------
        --最大値を超えていないかチェック
        IF ( lt_seq_number = cn_max_seq_number_1 ) THEN
          lv_log_msg := cv_log_msg_4;
          RAISE g_process_expt;
        END IF;
--
      ELSE
        ----------------------------------------------
        --採番テーブルに採番用レコードが存在しない場合
        ----------------------------------------------     
        --採番テーブルレコード作成
        BEGIN
          INSERT INTO xxcso_code_assignments(
            code_assignment_type,            --採番種別
            base_code,                       --拠点コード
            fiscal_year,                     --年度
            process_date,                    --業務処理日付
            seq_number,                      --連番
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          ) VALUES (
            '1',                             --採番種別
            iv_base_code,                    --拠点コード
            TO_CHAR(ln_business_year),       --年度
            NULL,                            --業務処理日付
            0,                               --連番（初期値ゼロ）
            cn_created_by,
            cd_creation_date,
            cn_last_updated_by,
            cd_last_update_date,
            cn_last_update_login,
            cn_request_id,
            cn_program_application_id,
            cn_program_id,
            cd_program_update_date
          );
--
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            --一意制約エラー（他トランから登録）
            NULL;
        END;
--        
        --採番テーブルをロック
        SELECT ca.seq_number
        INTO   lt_seq_number
        FROM   xxcso_code_assignments ca
        WHERE  ca.code_assignment_type = iv_cl_assign
        AND    ca.base_code            = iv_base_code
        AND    ca.fiscal_year          = TO_CHAR(ln_business_year)
        FOR UPDATE;
--      
      END IF;
--
      ----------------------------------------------
      --リターン用に編集
      ----------------------------------------------
      SELECT TO_CHAR(ln_business_year) 
            || iv_base_code 
            || LPAD(TO_CHAR(lt_seq_number + 1), 4, '0')
      INTO   lv_ret_seq_number
      FROM   DUAL;
--
      ----------------------------------------------
      --採番テーブルの更新
      ----------------------------------------------
      UPDATE xxcso_code_assignments ca
      SET    ca.seq_number        = lt_seq_number + 1
            ,ca.last_updated_by   = cn_last_updated_by
            ,ca.last_update_date  = cd_last_update_date
            ,ca.last_update_login = cn_last_update_login
      WHERE  ca.code_assignment_type = iv_cl_assign
      AND    ca.base_code            = iv_base_code
      AND    ca.fiscal_year          = TO_CHAR(ln_business_year);
--
    END IF;    
--
--
    --------------------------------------------------
    -- 自動採番処理：'2'（契約）の場合
    --------------------------------------------------
    IF ( iv_cl_assign = '2' ) THEN
      ----------------------------------------------
      --採番テーブル検索
      ----------------------------------------------
      BEGIN
        SELECT ca.seq_number,
               ca.process_date
        INTO   lt_seq_number,
               lt_process_date
        FROM   xxcso_code_assignments ca
        WHERE  ca.code_assignment_type = iv_cl_assign
        FOR UPDATE;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --存在しない場合
          lt_seq_number := NULL;
          lt_process_date := NULL;
      END;
--
      ----------------------------------------------
      --採番処理
      ----------------------------------------------         
      IF ( lt_seq_number IS NOT NULL ) THEN
        ----------------------------------------------
        --採番テーブルに採番用レコードが存在する場合
        ----------------------------------------------
        IF ( lt_process_date <> TRUNC(id_base_date) ) THEN
          --採番テーブルの処理日とパラメータの処理日が異なる場合
          --初期化
          lt_process_date := TRUNC(id_base_date);
          lt_seq_number   := 0;
        ELSIF ( lt_seq_number = cn_max_seq_number_2 ) THEN
          --採番テーブルの処理日とパラメータの処理日が同じ場合
          --最大値を超えていないかチェック
          lv_log_msg := cv_log_msg_4;
          RAISE g_process_expt;
        END IF;      
--
      ELSE
        ----------------------------------------------
        --採番テーブルに採番用レコードが存在しない場合
        ----------------------------------------------      
        --採番テーブルレコード作成
        BEGIN
          INSERT INTO xxcso_code_assignments(
            code_assignment_type,            --採番種別
            base_code,                       --拠点コード
            fiscal_year,                     --年度
            process_date,                    --業務処理日付
            seq_number,                      --連番
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          ) VALUES (
            '2',                             --採番種別
            NULL,                            --拠点コード
            NULL,                            --年度
            TRUNC(id_base_date),             --業務処理日付
            0,                               --連番（初期値ゼロ）
            cn_created_by,
            cd_creation_date,
            cn_last_updated_by,
            cd_last_update_date,
            cn_last_update_login,
            cn_request_id,
            cn_program_application_id,
            cn_program_id,
            cd_program_update_date
          );
--
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            --一意制約エラー（他トランから登録）
            NULL;
        END;
--
        --採番テーブルをロック
        SELECT ca.seq_number,
               ca.process_date
        INTO   lt_seq_number,
               lt_process_date
        FROM   xxcso_code_assignments ca
        WHERE  ca.code_assignment_type = iv_cl_assign
        FOR UPDATE;
-- 
      END IF;
--
      ----------------------------------------------
      --リターン用に編集
      ----------------------------------------------
      SELECT cn_cntrct_seq_prefix
            || TO_CHAR(lt_process_date, 'YYMMDD') 
            || LPAD(TO_CHAR(lt_seq_number + 1), 4, '0')
      INTO   lv_ret_seq_number
      FROM   DUAL;
--
      ----------------------------------------------
      --採番テーブルの更新
      ----------------------------------------------
      UPDATE xxcso_code_assignments ca
      SET    ca.process_date      = lt_process_date
            ,ca.seq_number        = lt_seq_number + 1
            ,ca.last_updated_by   = cn_last_updated_by
            ,ca.last_update_date  = cd_last_update_date
            ,ca.last_update_login = cn_last_update_login
      WHERE  ca.code_assignment_type = iv_cl_assign;
--
    END IF;
--
--
    --------------------------------------------------
    -- 終了処理
    --------------------------------------------------
    --コミット       
    COMMIT;
    RETURN lv_ret_seq_number;
--      
  EXCEPTION
--    
-- *** OTHERS例外ハンドラ ***
    WHEN g_process_expt THEN
      --ロールバック
      ROLLBACK;
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name || ' : ' || lv_log_msg);
      RETURN NULL;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --ロールバック
      ROLLBACK;
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
      RETURN NULL;
--
--#####################################  固定部 END   ##########################################
  END auto_code_assign;
--
END XXCSO_AUTO_CODE_ASSIGN_PKG;
/
