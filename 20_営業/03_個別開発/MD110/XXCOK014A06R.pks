CREATE OR REPLACE PACKAGE XXCOK014A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A06(spec)
 * Description      : �����ʔ̎�̋��v�Z�������s���ɔ̎�����}�X�^���o�^�̔̔����т��G���[���X�g�ɏo��
 * MD.050           : ���̋@�̎�����G���[���X�g MD050_COK_014_A06
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
 *  2008/12/24    1.0   S.Tozawa         �V�K�쐬
 *  2009/03/25    1.1   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2011/12/20    1.2   T.Yoshimoto      [���PE_�{�ғ�_08361] �p�����[�^�ǉ��Ή�
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , retcode          OUT VARCHAR2     -- ���^�[���E�R�[�h
  , iv_base_code     IN  VARCHAR2     -- ����v�㋒�_�R�[�h(���̓p�����[�^)
-- 2011/12/20 v1.2 T.Yoshimoto Add Start E_�{�ғ�_08631
  , iv_cust_code     IN  VARCHAR2     -- �ڋq�R�[�h(���̓p�����[�^)
-- 2011/12/20 v1.2 T.Yoshimoto Add End
  );
--
END XXCOK014A06R;
/
