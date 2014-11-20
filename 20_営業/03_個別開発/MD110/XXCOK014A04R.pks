CREATE OR REPLACE PACKAGE XXCOK014A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A04R(spec)
 * Description      : �u�x����v�u����v�㋒�_�v�u�ڋq�v�P�ʂɔ̎�c�������o��
 * MD.050           : ���̋@�̎�c���ꗗ MD050_COK_014_A04
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
 *  2008/12/17    1.0   T.Taniguchi      main�V�K�쐬
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         -- �G���[���b�Z�[�W
    retcode                  OUT    VARCHAR2,         -- �G���[�R�[�h
    iv_payment_date          IN     VARCHAR2,         -- �x����
    iv_ref_base_code         IN     VARCHAR2,         -- �⍇���S�����_
    iv_selling_base_code     IN     VARCHAR2,         -- ����v�㋒�_
    iv_target_disp           IN     VARCHAR2          -- �\���Ώ�
  );
END XXCOK014A04R;
/
