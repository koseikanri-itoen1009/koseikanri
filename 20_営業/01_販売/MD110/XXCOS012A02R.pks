CREATE OR REPLACE PACKAGE APPS.XXCOS012A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS012A02R (spec)
 * Description      : �s�b�N���X�g�i�o�א�E�̔���E���i�ʁj
 * MD.050           : �s�b�N���X�g�i�o�א�E�̔���E���i�ʁj MD050_COS_012_A02
 * Version          : 1.13
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
 *  2008/12/22    1.0   K.Kakishita      �V�K�쐬
 *  2009/02/23    1.1   K.Kakishita      ����敪�̃N�C�b�N�R�[�h�^�C�v����уR�[�h�̕ύX
 *  2009/02/26    1.2   K.Kakishita      ���[�R���J�����g�N����̃��[�N�e�[�u���폜������
 *                                       �R�����g�����O���B
 *  2009/04/03    1.3   N.Maeda          �yST��QNo.T1_0086�Ή��z
 *                                       ��݌ɕi�ڂ𒊏o�Ώۂ�菜�O����悤�ύX�B
 *  2009/06/05    1.4   T.Kitajima       [T1_1334]�󒍖��ׁAEDI���׌��������ύX
 *  2009/06/09    1.5   T.Kitajima       [T1_1374]���_��(40byte)
 *                                                �`�F�[���X��(40byte)
 *                                                �q�ɖ�(50byte)
 *                                                �X�܃R�[�h(10byte)
 *                                                �i�ڃR�[�h(16byte)
 *                                                �i��(40byte)
 *                                                �ɏC��
 *  2009/06/09    1.5   T.Kitajima       [T1_1375]������0�̏ꍇ�A�P�[�X����0�ݒ�A
 *                                                �o�����ɐ��ʂ�ݒ肷��B
 *  2009/06/15    1.6   K.Kiriu          [T1_1358]��ԓ����敪�N�C�b�N�R�[�h�l�ύX�Ή�
 *  2009/07/10    1.7   M.Sano           [0000063]���敪�ɂ��f�[�^�쐬�Ώۂ̐���
 *  2009/07/22    1.8   M.Sano           [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/08/11    1.9   M.Sano           [0000008]�s�b�L���O���X�g���\���O
 *  2009/08/20    1.10  N.Sano           [0000889]�����敪�Ή�
 *  2010/02/04    1.11  Y.Kikuchi        [E_�{�ғ�_01161]�ȉ��̒��o���������O����B
 *                                                       �E�o�׌��ۊǏꏊ�̏���
 *                                                       �E�ʉߍ݌Ɍ^�敪
 *  2010/02/22    1.12  K.Kiriu          [E_�{�ғ�_01551]
 *                                        �E�󒍃e�[�u���ɂȂ��󒍏��̃s�b�L���O���X�g��
 *                                          �d�c�h���e�[�u������o�͉\�ɂ���
 *                                        �E�N�C�b�N�󒍂̏��敪��NULL�݂̂ɂ���
 *                                        �E�d�c�h�i�󒍗L�j�̏��敪��NULL,'2'�ɂ���
 *                                        �E�G���[�i�ڂ̖��׃��x���W����������i�R�[�h�Q�݂̂ɂ���
 *                                        �E�P�ʊ��Z�}�X�^�̌��������F���������O���������ڂɒǉ�����
 *                                        �E��݌ɕi�A�G���[�i�ڂ̎擾�����̓��t���Ɩ����t����󒍓��ɕύX
 *  2010/06/14    1.13  T.Maruyama       [E_�{�ғ�_02638]
 *                                       �E�p�����[�^��EDI��M����ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_login_base_code        IN      VARCHAR2,         -- 1.���_
    iv_login_chain_store_code IN      VARCHAR2,         -- 2.�`�F�[���X
    iv_request_date_from      IN      VARCHAR2,         -- 3.�����iFrom�j
    iv_request_date_to        IN      VARCHAR2,         -- 4.�����iTo�j
/* 2010/02/22 Ver1.12 Mod Start */
--    iv_bargain_class          IN      VARCHAR2)         -- 5.��ԓ����敪
    iv_bargain_class          IN      VARCHAR2,         -- 5.��ԓ����敪
/* 2010/06/14 1.13 T.Maruyama Mod START */
--    iv_sales_output_type      IN      VARCHAR2)         -- 6.����Ώۏo�͋敪
    iv_sales_output_type      IN      VARCHAR2,         -- 6.����Ώۏo�͋敪
    iv_edi_received_date      IN      VARCHAR2)         -- 7.EDI��M��
/* 2010/06/14 1.13 T.Maruyama Mod END */
/* 2010/02/22 Ver1.12 Mod End   */
  ;
END XXCOS012A02R;
/
