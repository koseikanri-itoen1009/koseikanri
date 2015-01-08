CREATE OR REPLACE PACKAGE XXCOS006A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS006A04R (spec)
 * Description      : �o�׈˗���
 * MD.050           : �o�׈˗��� MD050_COS_006_A04
 * Version          : 1.8
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
 *  2009/07/09    1.5   M.Sano           �ySCS��QNo.0000063�Ή��z
 *                                       ���敪�ɂ��f�[�^�쐬�Ώۂ̐���
 *  2009/10/01    1.6   S.Miyakoshi      �ySCS��QNo.0001378�Ή��z
 *                                       ���[���[�N�e�[�u���̌����ӂ�Ή�
 *                                       �N�C�b�N�R�[�h�擾���̃p�t�H�[�}���X�Ή�
 *  2013/03/26    1.7   T.Ishiwata       �yE_�{�ғ�_10343�Ή��z
 *                                        �p�����[�^�u�o�͋敪�v�ǉ��A�����A�^�C�g���ύX
 *  2014/11/14    1.8   K.Oomata         �yE_�{�ғ�_12575�Ή��z
 *                                        �p�����[�^�u�o�͏��D�捀�ځv�u����CSV�o�́v�ǉ��B
 *                                        �����Ώێ󒍃\�[�X�C���B
 *                                       �u�E�v�v���Ɍڋq�����ԍ��ݒ肷��悤�C���B
 *                                        SVF���ʊ֐��ɓn��VRQ�t�@�C���̐ݒ�l�C���B
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_ship_from_subinv_code  IN      VARCHAR2,         -- 1.�o�׌��q��
    iv_ordered_date_from      IN      VARCHAR2,         -- 2.�󒍓��iFrom�j
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata Start
--    iv_ordered_date_to        IN      VARCHAR2          -- 3.�󒍓��iTo�j
    iv_ordered_date_to        IN      VARCHAR2,         -- 3.�󒍓��iTo�j
-- 2014/11/14 Ver.1.8 Mod K.Oomata Start
--    iv_output_code            IN      VARCHAR2          -- 4.�o�͋敪
---- 2013/03/26 Ver.1.7 Mod T.Ishiwata End
    iv_output_code            IN      VARCHAR2,          -- 4.�o�͋敪
    iv_sort_key               IN      VARCHAR2,          -- 5.�o�͏��D�捀��(0�F�o�׌��ۊǏꏊ�D��A1�F�`�[No.�D��)
    iv_international_csv      IN      VARCHAR2           -- 6.����CSV�o��(Y�F����CSV��ΏۂƂ���AN�F����CSV��ΏۂƂ��Ȃ�)
-- 2014/11/14 Ver.1.8 Mod K.Oomata End
  );
END XXCOS006A04R;
/
