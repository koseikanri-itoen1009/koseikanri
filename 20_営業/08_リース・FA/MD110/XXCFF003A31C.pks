CREATE OR REPLACE PACKAGE XXCFF003A31C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A31C(spec)
 * Description      : ���[�X�_��o�^�ꗗ
 * MD.050           : ���[�X�_��o�^�ꗗ MD050_CFF_003_A31
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
 *  2009/01/05    1.0   SCS�R��          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode              OUT VARCHAR2,      --   �G���[�R�[�h     #�Œ�#
    iv_lease_st_date_fr  IN  VARCHAR2,      -- 1.���[�X�J�n��FROM
    iv_lease_st_date_to  IN  VARCHAR2,      -- 2.���[�X�J�n��TO
    iv_lease_company     IN  VARCHAR2,      -- 3.���[�X��ЃR�[�h
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.���[�X���FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.���[�X���TO
    iv_lease_type        IN  VARCHAR2       -- 6.���[�X�敪
  );
END XXCFF003A31C;
/
