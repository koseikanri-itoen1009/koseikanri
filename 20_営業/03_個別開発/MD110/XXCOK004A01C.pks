CREATE OR REPLACE PACKAGE XXCOK004A01C
AS
 /*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK004A01C(spec)
 * Description      : �ڋq�ڍs���Ɍڋq�}�X�^�̒ޑK���z�Ɋ�Â��d������쐬���܂��B
 * MD.050           : VD�ޑK�̐U�֎d��쐬 (MD050_COK_004_A01)
 * Version          : 1.1
 *
 * Program List
 * ----------------------- ----------------------------------------------------------
 *  Name                    Description
 * ----------------------- ----------------------------------------------------------
 *  init                    ��������                        (A-1)
 *  get_cust_shift_info     �ڋq�ڍs���擾                (A-2)
 *  lock_cust_shift_info    �ڋq�ڍs��񃍃b�N�擾          (A-3)
 *  distinct_target_cust_f  �U�֎d��쐬�Ώیڋq����        (A-4)
 *  chk_acctg_target        ��v���ԃ`�F�b�N                (A-5)
 *  get_gl_data_info        GL�A�g�f�[�^�t�����̎擾      (A-6)
 *  ins_gl_oif              ��ʉ�vOIF�o�^                 (A-7)
 *  upd_cust_shift_info     �ڋq�ڍs���X�V                (A-8)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   K.Motohashi      �V�K�쐬
 *  2009/02/02    1.1   K.Suenaga        [��QCOK_002]��o�b�`�Ή�(�p�����[�^�ǉ�)
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf   OUT VARCHAR2  -- �G���[���b�Z�[�W
  , retcode  OUT VARCHAR2  -- �G���[�R�[�h
  , iv_process_flag IN VARCHAR2 -- ���͍��ڂ̋N���敪�p�����[�^
  );
END XXCOK004A01C;
/