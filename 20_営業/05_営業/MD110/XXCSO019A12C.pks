CREATE OR REPLACE PACKAGE APPS.XXCSO019A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A12C(spec)
 * Description      : ���[�gNo�^�c�ƈ�CSV�o��
 * MD.050           : ���[�gNo�^�c�ƈ�CSV�o�� (MD050_CSO_019A12)
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
 *  2018/02/15    1.0   K.Kiriu          main�V�K�쐬�iE_�{�ғ�_14722�j
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2    --   �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT    VARCHAR2    --   �G���[�R�[�h     #�Œ�#
   ,iv_base_code       IN     VARCHAR2    -- 1.���_�R�[�h
   ,iv_employee_number IN     VARCHAR2    -- 2.�c�ƈ�
   ,iv_route_no        IN     VARCHAR2    -- 3.���[�gNo
  );
END XXCSO019A12C;
/
