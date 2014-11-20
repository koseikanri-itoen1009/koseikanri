CREATE OR REPLACE PACKAGE BODY xxcso_auto_code_assign_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_AUTO_CODE_ASSIGN_PKG(BODY)
 * Description      : ���ʊ֐�(XXCSO�̔ԁj
 * MD.050/070       :
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  auto_code_assign          F    -     �����̔Ԋ֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/21    1.0   T.maruyama       �V�K�쐬
 *  2008/12/25    1.0   M.maruyama       �̔Ԏ��'2'�i�_�񏑔ԍ�)�̖߂�l�ҏW���C��
 *                                       ���t�l��'YYYYMMDD'����'YYMMDD'��
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_auto_code_assign_pkg';   -- �p�b�P�[�W��
  cv_app_name         CONSTANT VARCHAR2(5)   := 'XXCSO';                        -- �A�v���P�[�V�����Z�k��
  cv_msg_part         CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)   := '.';
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE

  --*** ���������ʗ�O ***
  g_process_expt      EXCEPTION;
  --*** ���ʊ֐���O ***
  g_api_expt          EXCEPTION;
--
   /**********************************************************************************
   * Function Name    : auto_code_assign
   * Description      : �����̔Ԋ֐�
   ***********************************************************************************/
  FUNCTION auto_code_assign(
    iv_cl_assign             IN  VARCHAR2,               -- �̔Ԏ�ʁi'1':���ρA'2':�_��j
    iv_base_code             IN  VARCHAR2,               -- ���_�R�[�h
    id_base_date             IN  DATE                    -- �������t�iYYYMMDD�j
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'auto_code_assign';
    cn_max_seq_number_1        CONSTANT NUMBER          := 9999;   --���ύő�ԍ�
    cn_max_seq_number_2        CONSTANT NUMBER          := 9999;   --�_��ő�ԍ�
    cn_cntrct_seq_prefix       CONSTANT VARCHAR2(2)     := '03';   --�_�񏑔ԍ��p
    --log���b�Z�[�W
    cv_log_msg_1               CONSTANT VARCHAR2(100)   := '�̔Ԏ�ʕs��';
    cv_log_msg_2               CONSTANT VARCHAR2(100)   := '���_�b�c�s��';
    cv_log_msg_3               CONSTANT VARCHAR2(100)   := '�N�x�擾���s';
    cv_log_msg_4               CONSTANT VARCHAR2(100)   := '�̔ԃe�[�u���ő�l�G���[';
    cv_log_msg_5               CONSTANT VARCHAR2(100)   := '�������tNULL';
    cv_log_msg_6               CONSTANT VARCHAR2(100)   := '���_�b�cNULL';    
--
    -- �g�[�N���R�[�h
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lt_base_code               xxcso_aff_base_v2.base_code%TYPE;
    ln_business_year           NUMBER;
    lt_seq_number              xxcso_code_assignments.seq_number%TYPE;
    lt_process_date            xxcso_code_assignments.process_date%TYPE;
    lv_ret_seq_number          VARCHAR2(100);
    lv_log_msg                 VARCHAR2(1000);
--
--  --�����^�g�����U�N�V����
    PRAGMA AUTONOMOUS_TRANSACTION;
--
--
  BEGIN
--
    --------------------------------------------------
    -- �p�����[�^�̔Ԏ�ʁi'1':���ρA'2':�_��j�`�F�b�N
    --------------------------------------------------
    IF ( iv_cl_assign NOT IN ('1', '2') ) 
    OR ( iv_cl_assign IS NULL ) THEN
      --'1','2'�ȊO�܂���NULL�̏ꍇ�̓G���[
      lv_log_msg := cv_log_msg_1;
      RAISE g_process_expt;
    END IF;
--
    --------------------------------------------------
    -- �p�����[�^�������K�{
    --------------------------------------------------
    IF ( id_base_date IS NULL ) THEN
      lv_log_msg := cv_log_msg_5;
      RAISE g_process_expt;
    END IF;
--
    --------------------------------------------------
    -- �p�����[�^���_�R�[�h�`�F�b�N
    --------------------------------------------------
    --���ς̏ꍇ
    IF ( iv_cl_assign = '1' ) THEN
      --�K�{�`�F�b�N
      IF ( iv_base_code IS NULL ) THEN
        lv_log_msg := cv_log_msg_6;
        RAISE g_process_expt;
      END IF;
--
      --���݃`�F�b�N
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
    -- �N�x�擾
    --------------------------------------------------
    --���ς̏ꍇ
    IF ( iv_cl_assign = '1' ) THEN
      --�N�x�擾
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
    -- �����̔ԏ����F'1'�i���ρj�̏ꍇ
    --------------------------------------------------
    IF ( iv_cl_assign = '1' ) THEN
      ----------------------------------------------
      --�̔ԃe�[�u������
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
          --���݂��Ȃ��ꍇ
          lt_seq_number := NULL;
      END;
--
      ----------------------------------------------
      --�̔ԏ���
      ----------------------------------------------   
      IF ( lt_seq_number IS NOT NULL ) THEN
        ----------------------------------------------
        --�̔ԃe�[�u���ɍ̔ԗp���R�[�h�����݂���ꍇ
        ----------------------------------------------
        --�ő�l�𒴂��Ă��Ȃ����`�F�b�N
        IF ( lt_seq_number = cn_max_seq_number_1 ) THEN
          lv_log_msg := cv_log_msg_4;
          RAISE g_process_expt;
        END IF;
--
      ELSE
        ----------------------------------------------
        --�̔ԃe�[�u���ɍ̔ԗp���R�[�h�����݂��Ȃ��ꍇ
        ----------------------------------------------     
        --�̔ԃe�[�u�����R�[�h�쐬
        BEGIN
          INSERT INTO xxcso_code_assignments(
            code_assignment_type,            --�̔Ԏ��
            base_code,                       --���_�R�[�h
            fiscal_year,                     --�N�x
            process_date,                    --�Ɩ��������t
            seq_number,                      --�A��
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
            '1',                             --�̔Ԏ��
            iv_base_code,                    --���_�R�[�h
            TO_CHAR(ln_business_year),       --�N�x
            NULL,                            --�Ɩ��������t
            0,                               --�A�ԁi�����l�[���j
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
            --��Ӑ���G���[�i���g��������o�^�j
            NULL;
        END;
--        
        --�̔ԃe�[�u�������b�N
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
      --���^�[���p�ɕҏW
      ----------------------------------------------
      SELECT TO_CHAR(ln_business_year) 
            || iv_base_code 
            || LPAD(TO_CHAR(lt_seq_number + 1), 4, '0')
      INTO   lv_ret_seq_number
      FROM   DUAL;
--
      ----------------------------------------------
      --�̔ԃe�[�u���̍X�V
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
    -- �����̔ԏ����F'2'�i�_��j�̏ꍇ
    --------------------------------------------------
    IF ( iv_cl_assign = '2' ) THEN
      ----------------------------------------------
      --�̔ԃe�[�u������
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
          --���݂��Ȃ��ꍇ
          lt_seq_number := NULL;
          lt_process_date := NULL;
      END;
--
      ----------------------------------------------
      --�̔ԏ���
      ----------------------------------------------         
      IF ( lt_seq_number IS NOT NULL ) THEN
        ----------------------------------------------
        --�̔ԃe�[�u���ɍ̔ԗp���R�[�h�����݂���ꍇ
        ----------------------------------------------
        IF ( lt_process_date <> TRUNC(id_base_date) ) THEN
          --�̔ԃe�[�u���̏������ƃp�����[�^�̏��������قȂ�ꍇ
          --������
          lt_process_date := TRUNC(id_base_date);
          lt_seq_number   := 0;
        ELSIF ( lt_seq_number = cn_max_seq_number_2 ) THEN
          --�̔ԃe�[�u���̏������ƃp�����[�^�̏������������ꍇ
          --�ő�l�𒴂��Ă��Ȃ����`�F�b�N
          lv_log_msg := cv_log_msg_4;
          RAISE g_process_expt;
        END IF;      
--
      ELSE
        ----------------------------------------------
        --�̔ԃe�[�u���ɍ̔ԗp���R�[�h�����݂��Ȃ��ꍇ
        ----------------------------------------------      
        --�̔ԃe�[�u�����R�[�h�쐬
        BEGIN
          INSERT INTO xxcso_code_assignments(
            code_assignment_type,            --�̔Ԏ��
            base_code,                       --���_�R�[�h
            fiscal_year,                     --�N�x
            process_date,                    --�Ɩ��������t
            seq_number,                      --�A��
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
            '2',                             --�̔Ԏ��
            NULL,                            --���_�R�[�h
            NULL,                            --�N�x
            TRUNC(id_base_date),             --�Ɩ��������t
            0,                               --�A�ԁi�����l�[���j
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
            --��Ӑ���G���[�i���g��������o�^�j
            NULL;
        END;
--
        --�̔ԃe�[�u�������b�N
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
      --���^�[���p�ɕҏW
      ----------------------------------------------
      SELECT cn_cntrct_seq_prefix
            || TO_CHAR(lt_process_date, 'YYMMDD') 
            || LPAD(TO_CHAR(lt_seq_number + 1), 4, '0')
      INTO   lv_ret_seq_number
      FROM   DUAL;
--
      ----------------------------------------------
      --�̔ԃe�[�u���̍X�V
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
    -- �I������
    --------------------------------------------------
    --�R�~�b�g       
    COMMIT;
    RETURN lv_ret_seq_number;
--      
  EXCEPTION
--    
-- *** OTHERS��O�n���h�� ***
    WHEN g_process_expt THEN
      --���[���o�b�N
      ROLLBACK;
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name || ' : ' || lv_log_msg);
      RETURN NULL;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --���[���o�b�N
      ROLLBACK;
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
      RETURN NULL;
--
--#####################################  �Œ蕔 END   ##########################################
  END auto_code_assign;
--
END XXCSO_AUTO_CODE_ASSIGN_PKG;
/
