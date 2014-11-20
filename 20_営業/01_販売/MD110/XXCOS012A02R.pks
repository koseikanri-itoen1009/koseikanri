CREATE OR REPLACE PACKAGE XXCOS012A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS012A02R (spec)
 * Description      : �s�b�N���X�g�i�o�א�E�̔���E���i�ʁj
 * MD.050           : �s�b�N���X�g�i�o�א�E�̔���E���i�ʁj MD050_COS_012_A02
 * Version          : 1.5
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
    iv_bargain_class          IN      VARCHAR2)         -- 5.��ԓ����敪
  ;
END XXCOS012A02R;
/
