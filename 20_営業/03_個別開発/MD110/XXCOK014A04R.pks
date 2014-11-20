CREATE OR REPLACE PACKAGE XXCOK014A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A04R(spec)
 * Description      : �u�x����v�u����v�㋒�_�v�u�ڋq�v�P�ʂɔ̎�c�������o��
 * MD.050           : ���̋@�̎�c���ꗗ MD050_COK_014_A04
 * Version          : 1.1
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
 *  2008/12/17    1.0   T.Taniguchi      main�V�K�쐬
 *  2013/04/25    1.1   S.Niki           [��QE_�{�ғ�_10411] �p�����[�^�u�x����R�[�h�v�u�X�e�[�^�X�v�ǉ�
 *                                                            �ϓ��d�C�㖢���̓}�[�N�o�́A�\�[�g���ύX
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         -- �G���[���b�Z�[�W
    retcode                  OUT    VARCHAR2,         -- �G���[�R�[�h
    iv_payment_date          IN     VARCHAR2,         -- �x����
    iv_ref_base_code         IN     VARCHAR2,         -- �⍇���S�����_
    iv_selling_base_code     IN     VARCHAR2,         -- ����v�㋒�_
-- Ver.1.1 [��QE_�{�ғ�_10411] SCSK S.Niki UPD START
--    iv_target_disp           IN     VARCHAR2          -- �\���Ώ�
    iv_target_disp           IN     VARCHAR2,         -- �\���Ώ�
    iv_payment_code          IN     VARCHAR2,         -- �x����R�[�h
    iv_resv_payment          IN     VARCHAR2          -- �x���X�e�[�^�X
-- Ver.1.1 [��QE_�{�ғ�_10411] SCSK S.Niki UPD END
  );
END XXCOK014A04R;
/
