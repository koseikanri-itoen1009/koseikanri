CREATE OR REPLACE PACKAGE APPS.XXCSO019A14R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A14R(spec)
 * Description      :  �ڋq�����Ǘ��\
 * MD.050           : MD050_CSO_019_A14_�ڋq�����Ǘ��\
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/05/31    1.0   K.Kiriu          �V�K�쐬(E_�{�ғ�_14971)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2  --   �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT NOCOPY VARCHAR2  --   �G���[�R�[�h     #�Œ�#
   ,iv_base_code       IN  VARCHAR2         --   ���_�R�[�h
   ,iv_target_yyyymm   IN  VARCHAR2         --   �Ώ۔N��
   ,iv_employee_number IN  VARCHAR2         --   �]�ƈ��R�[�h
  );
END XXCSO019A14R;
/
