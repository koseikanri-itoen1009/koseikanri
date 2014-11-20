create or replace PACKAGE XXCOI009A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A04R(spec)
 * Description      : ���o�ɃW���[�i���`�F�b�N���X�g
 * MD.050           : ���o�ɃW���[�i���`�F�b�N���X�g MD050_COI_009_A04
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
 *  2008/12/22    1.0  SCS.Tsuboi         main�V�K�쐬
 *  2009/12/15    1.1  H.Sasaki           [E_�{�ғ�_00256]�N���p�����[�^�̔N����From-To��ݒ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode              OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_output_kbn        IN     VARCHAR2,         --   1.�o�͋敪
    iv_invoice_kbn       IN     VARCHAR2,         --   2.�`�[�敪
    iv_target_date       IN     VARCHAR2,         --   3.�N����
-- == 2009/12/15 V1.1 Added START ===============================================================
    iv_target_date_to    IN     VARCHAR2,         --   �N�����iTO�j
-- == 2009/12/15 V1.1 Added END   ===============================================================
    iv_out_base_code     IN     VARCHAR2,         --   4.���_
    iv_reverse_kbn       IN     VARCHAR2,         --   5.���o�ɋt�]�f�[�^�o�͋敪
    iv_output_dpt        IN     VARCHAR2          --   6.���[�o�͏ꏊ
  );
END XXCOI009A04R;
/
