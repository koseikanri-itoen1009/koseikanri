CREATE OR REPLACE PACKAGE BODY APPS.xxcso_008001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_008001j_pkg(BODY)
 * Description      : �T�������󋵏Ɖ��ʋ��ʊ֐�
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_baseline_base_code    F    V      ��������_�R�[�h�擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   N.Yanagitaira    �V�K�쐬
 *  2009/04/10    1.1   N.Yanagitaira    [ST��QT1_0422,T1_0477]get_plan_or_result�ǉ�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_y                CONSTANT VARCHAR2(1)   := 'Y';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso008001j_pkg';   -- �p�b�P�[�W��
--
   /**********************************************************************************
   * Function Name    : get_baseline_base_code
   * Description      : ��������_�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_baseline_base_code';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_baseline_base_code        fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
    -- ===============================
    -- ���[�J���E�J�[�\��
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
  -- ��������_�R�[�h�擾
  BEGIN
--
    lv_baseline_base_code := NULL;
--
    <<root_base_data_rec>>
    FOR root_base_data_rec IN root_base_data_cur
    LOOP
      -- child_base_code��2�Ԗڂ����L3�̑�3�K�w
      IF (root_base_data_cur%ROWCOUNT = 2) THEN
        lv_baseline_base_code := root_base_data_rec.child_base_code;
        EXIT;
      END IF;
    END LOOP root_base_data_rec;
--
    RETURN lv_baseline_base_code;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_baseline_base_code;
--
-- 20090410_N.Yanagitaira T1_0422,T1_0477 Add START
   /**********************************************************************************
   * Function Name    : get_baseline_base_code
   * Description      : ��������_�R�[�h�擾�֐�
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
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                       CONSTANT VARCHAR2(100) := 'get_plan_or_result';
    cv_task_status_open               CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_STATUS_OPEN_ID';
    cv_task_status_closed             CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_STATUS_CLOSED_ID';
    cv_task_type_visit                CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_TYPE_VISIT';
    cv_source_object_type_party       CONSTANT VARCHAR2(30)  := 'PARTY';
    cv_source_object_type_oppor       CONSTANT VARCHAR2(30)  := 'OPPORTUNITY';
    cv_zero_time                      CONSTANT VARCHAR2(30)  := '00:00';
    cv_space                          CONSTANT VARCHAR2(2)   := '�@';
    cv_pran_string                    CONSTANT VARCHAR2(2)   := '�\';
    cv_result_string                  CONSTANT VARCHAR2(2)   := '��';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_task_status_id             VARCHAR2(100);
    lv_task_type_id               VARCHAR2(100);
    lv_return_value1              VARCHAR2(100);
    lv_return_value2              VARCHAR2(100);
    lv_return_value3              VARCHAR2(4000);
--
  BEGIN
--
    -- ������
    lv_task_status_id  := TO_CHAR(in_task_status_id);
    lv_task_type_id    := TO_CHAR(in_task_type_id);
    lv_return_value1   := NULL;
    lv_return_value2   := NULL;
    lv_return_value3   := NULL;
--
    -- ///////////////////
    -- �\�^�� �����̐ݒ�
    -- ///////////////////
    -- �X�e�[�^�X:OPEN
    IF ( lv_task_status_id = FND_PROFILE.VALUE(cv_task_status_open) ) THEN
--
      lv_return_value1 := cv_pran_string;
--
    -- �X�e�[�^�X:CLOSE
    ELSIF ( lv_task_status_id = FND_PROFILE.VALUE(cv_task_status_closed) ) THEN
--
      -- �K��̏ꍇ
      IF ( lv_task_type_id = FND_PROFILE.VALUE(cv_task_type_visit) ) THEN
--
        -- �K�������NULL
        IF ( id_actual_end_date IS NULL ) THEN
--
            lv_return_value1 := cv_pran_string;
--
        ELSE
--
          -- �K��������������t
          IF ( TRUNC(id_actual_end_date) > TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) THEN
--
            lv_return_value1 := cv_pran_string;
--
          -- �K��������ߋ����t(���ݓ��܂�)
          ELSE
--
            lv_return_value1 := cv_result_string;
--
          END IF;
--
        END IF;
--
      -- �K��ȊO�̏ꍇ
      ELSE
--
        -- �K�������NULL
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
    -- ��L�ȊO�̃X�e�[�^�X�̏ꍇ
    ELSE
--
      lv_return_value1 := NULL;
--
    END IF;
--
    -- �����փX�y�[�X�̐ݒ�
    IF ( lv_return_value1 IS NOT NULL ) THEN
--
      lv_return_value1 := lv_return_value1 || cv_space;
--
    END IF;
--
    -- ///////////////////
    -- ���� �����̐ݒ�
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
    -- �ڋq�� �����̐ݒ�
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_plan_or_result;

-- 20090410_N.Yanagitaira T1_0422,T1_0477 Add END
--
END xxcso_008001j_pkg;
/
