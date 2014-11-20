CREATE OR REPLACE PACKAGE XXCFF_FORMS_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_FORMS_PKG(spec)
 * Description      : ���[�X�EFA�̈�FORMS�p���ʊ֐�
 * MD.050           : �Ȃ�
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ---- ----- ----------------------------------------------
 *  Name                        Type  Ret   Description
 * ---------------------------- ---- ----- ----------------------------------------------
 *  exe_sql                      P    -     ���ISQL���s����
 *  �쐬���ɋL�q���Ă�������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   SCS�����r��      �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`���ʊ֐�
  -- ===============================
  -- ���ISQL���s����
  PROCEDURE exe_sql(
    iv_sql        IN  VARCHAR2,   --   ���sSQL
    ov_value1     OUT VARCHAR2,   --   SQL���s����
    ov_value2     OUT VARCHAR2,   --   SQL���s����
    ov_value3     OUT VARCHAR2,   --   SQL���s����
    ov_value4     OUT VARCHAR2,   --   SQL���s����
    ov_value5     OUT VARCHAR2,   --   SQL���s����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
END XXCFF_FORMS_PKG;
/
