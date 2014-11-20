CREATE OR REPLACE PACKAGE BODY APPS.xxcso_005001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_005001j_pkg(body)
 * Description      : ���\�[�X�Z�L�����e�B�p�b�P�[�W
 * MD.050           :  MD050_CSO_005_A01_�c�ƈ����\�[�X�֘A���̃Z�L�����e�B
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 * get_predicate          �Z�L�����e�B�|���V�[�擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-05-08    1.0   Hiroshi.Ogawa    �V�K�쐬(T1_0593�Ή�)
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_util_common_pkg';   -- �p�b�P�[�W��
   /**********************************************************************************
   * Function Name    : get_predicate
   * Description      : �Z�L�����e�B�|���V�[�擾
   ***********************************************************************************/
  FUNCTION  get_predicate(
    iv_schema            IN   VARCHAR2
   ,iv_object            IN   VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_predicate';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_base_code                 jtf_rs_groups_b.attribute1%TYPE;
    lv_predicate                 VARCHAR2(4000);
--
  BEGIN
--
    IF ( fnd_profile.value('XXCSO1_RS_SECURITY_LEVEL') = '1' ) THEN
--
      lv_base_code := xxcso_util_common_pkg.get_current_rs_base_code;
--
      lv_predicate :=
        'CATEGORY = ''EMPLOYEE'' '                                ||
        'AND ('                                                   ||
          ' xxcso_util_common_pkg.get_rs_base_code('              ||
              'RESOURCE_ID,'                                      ||
              'TRUNC(xxcso_util_common_pkg.get_online_sysdate)'   ||
          ') = xxcso_util_common_pkg.get_current_rs_base_code '   ||
          'OR xxcso_util_common_pkg.get_rs_base_code('            ||
                'RESOURCE_ID,'                                    ||
                'TRUNC(xxcso_util_common_pkg.get_online_sysdate)' ||
          ') IS NULL '                                            ||
          'OR USER_ID = fnd_global.user_id'                       ||
        ')'
      ;
--
    ELSE
--
      lv_predicate := '1=1';
--
    END IF;
--
    RETURN lv_predicate;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_predicate;
--
END xxcso_005001j_pkg;
/
