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
END xxcso_008001j_pkg;
/
