CREATE OR REPLACE PACKAGE XXCOS002A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A05R(spec)
 * Description      : �[�i���`�F�b�N���X�g
 * MD.050           : �[�i���`�F�b�N���X�g MD050_COS_002_A05
 * Version          : 1.6
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
 *  2009/01/05    1.0   S.Miyakoshi      �V�K�쐬
 *  2009/02/17    1.1   S.Miyakoshi      get_msg�̃p�b�P�[�W���C��
 *  2009/02/26    1.2   S.Miyakoshi      �]�ƈ��̗����Ǘ��Ή�(xxcos_rs_info_v)
 *  2009/02/26    1.3   S.Miyakoshi      ���[�R���J�����g�N����̃��[�N�e�[�u���폜�����̃R�����g��������
 *  2009/02/27    1.4   S.Miyakoshi      [COS_150]�̔����уf�[�^���o�����C��
 *  2009/03/04    1.5   N.Maeda          ���[�o�͎��̔[�i���}�b�s���O���ڂ̕ύX
 *                                       �E�C���O
 *                                          �˔̔�����.�[�i�����g�p
 *                                       �E�C����
 *                                          �˔̔�����.���������g�p
 *                                       ���P���A�����̃}�b�s���O���ڂ̕ύX
 *                                       �E�C���O
 *                                          �ˉ��P��:�艿�P��
 *                                          �˔���:�[�i�P���~����
 *                                       �E�C����
 *                                          �ˉ��P��:�[�i�P���i����P)
 *                                          �˔���:�艿�P��
 *  2009/05/01    1.6   N.Maeda          [T1_0885]���o�Ώۂɢ��l�ڋq���ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode               OUT VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_delivery_date      IN  VARCHAR2,         --  �[�i��
    iv_delivery_base_code IN  VARCHAR2,         --  ���_
    iv_dlv_by_code        IN  VARCHAR2,         --  �c�ƈ�
    iv_hht_invoice_no     IN  VARCHAR2          --  HHT�`�[No
  );
END XXCOS002A05R;
/
