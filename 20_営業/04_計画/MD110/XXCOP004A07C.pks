CREATE OR REPLACE PACKAGE XXCOP004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A07C(spec)
 * Description      : �e�R�[�h�o�׎��э쐬
 * MD.050           : �e�R�[�h�o�׎��э쐬 MD050_COP_004_A07
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  init                     ��������(A-1)
 *  del_shipment_results     �e�R�[�h�o�׎��щߋ��f�[�^�폜(A-2)
 *  renew_shipment_results   �o�בq�ɃR�[�h�ŐV��(A-3)
 *  get_shipment_results     �o�׎��я�񒊏o(A-4)
 *  get_latest_code          �ŐV�o�בq�Ɏ擾(A-5)
 *  ins_shipment_results     �e�R�[�h�o�׎��уf�[�^�쐬(A-7)
 *  upd_shipment_results     �e�R�[�h�o�׎��уf�[�^�X�V(A-8)
 *  upd_appl_contorols       �O�񏈗��������X�V(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   SCS.Tsubomatsu   �V�K�쐬
 *  2009/02/09    1.1   SCS.Kikuchi      �����s�No.004�Ή�(A-5.�Y���f�[�^�����̏ꍇ�̏����ύX)
 *  2009/02/16    1.2   SCS.Tsubomatsu   �����s�No.010�Ή�(A-3.�X�V����������)
 *  2009/04/13    1.3   SCS.Kikuchi      T1_0507�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT VARCHAR2,           --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2            --   ���^�[���E�R�[�h    --# �Œ� #
  );

END XXCOP004A07C;
/
