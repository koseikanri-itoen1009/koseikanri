CREATE OR REPLACE PACKAGE XXCOS006A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS006A04R (spec)
 * Description      : �o�׈˗���
 * MD.050           : �o�׈˗��� MD050_COS_006_A04
 * Version          : 1.4
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
 *  2008/11/07    1.0   K.Kakishita      �V�K�쐬
 *  2009/02/26    1.1   K.Kakishita      ���[�R���J�����g�N����̃��[�N�e�[�u���폜������
 *                                       �R�����g�����O���B
 *  2009/03/03    1.2   N.Maeda          �s�v�Ȓ萔�̍폜
 *                                       ( ct_qct_cus_class_mst , ct_qcc_cus_class_mst1 )
 *  2009/04/01    1.3   N.Maeda          �yST��QNo.T1-0085�Ή��z
 *                                       ��݌ɕi�ڂ�񒊏o�f�[�^�֕ύX
 *                                       �yST��QNo.T1-0049�Ή��z
 *                                       ���l�f�[�^�擾�J�������̏C��
 *                                       description�ւ̃Z�b�g���e���C��
 *  2009/06/19    1.4   K.Kiriu          �yST��QNo.T1-1437�Ή��z
 *                                       �f�[�^�p�[�W�s��Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_ship_from_subinv_code  IN      VARCHAR2,         -- 1.�o�׌��q��
    iv_ordered_date_from      IN      VARCHAR2,         -- 2.�󒍓��iFrom�j
    iv_ordered_date_to        IN      VARCHAR2          -- 3.�󒍓��iTo�j
  );
END XXCOS006A04R;
/
