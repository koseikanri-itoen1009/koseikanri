CREATE OR REPLACE PACKAGE XXCOK015A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A02R(spec)
 * Description      : �萔���������x������ۂ̎x���ē����i�̎����t���j��
 *                    �e����v�㋒�_�ň�����܂��B
 * MD.050           : �x���ē�������i�̎����t���j MD050_COK_015_A02
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
 *  2009/01/20    1.0   K.Yamaguchi      �V�K�쐬
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_base_code                   IN  VARCHAR2        -- ����v�㋒�_
  , iv_fix_flag                    IN  VARCHAR2        -- �x���m��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
  );
END XXCOK015A02R;
/
