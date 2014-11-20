CREATE OR REPLACE PACKAGE XXCOS004A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A03R (spec)
 * Description      : �����v�Z�`�F�b�N���X�g
 * MD.050           : �����v�Z�`�F�b�N���X�g MD050_COS_004_A03
 * Version          : 1.2
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
 *  2008/11/04    1.0   K.Kin            �V�K�쐬
 *  2009/02/04    1.1   K.Kin            [COS_011]������o�b�t�@�����������܂��s��Ή�
 *  2009/02/26    1.2   K.Kin            �폜�����̃R�����g�폜
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_sales_base_code        IN      VARCHAR2,         -- 1.���_�R�[�h
    iv_customer_number        IN      VARCHAR2          -- 2.�ڋq�R�[�h
  );
END XXCOS004A03R;
/
