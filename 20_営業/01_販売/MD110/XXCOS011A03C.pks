CREATE OR REPLACE PACKAGE APPS.XXCOS011A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS011A03C (spec)
 * Description      : �[�i�\��f�[�^�̍쐬���s��
 * MD.050           : �[�i�\��f�[�^�쐬 (MD050_COS_011_A03)
 * Version          : 1.12
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
 *  2009/01/08    1.0   H.Fujimoto       �V�K�쐬
 *  2009/02/20    1.1   H.Fujimoto       �����s�No.106
 *  2009/02/24    1.2   H.Fujimoto       �����s�No.126,134
 *  2009/02/25    1.3   H.Fujimoto       �����s�No.135
 *  2009/02/25    1.4   H.Fujimoto       �����s�No.141
 *  2009/02/27    1.5   H.Fujimoto       �����s�No.146,149
 *  2009/03/04    1.6   H.Fujimoto       �����s�No.154
 *  2009/04/28    1.7   K.Kiriu          [T1_0756]���R�[�h���ύX�Ή�
 *  2009/05/12    1.8   K.Kiriu          [T1_0677]���x���쐬�Ή�
 *                                       [T1_0937]�폜���̌����J�E���g�Ή�
 *  2009/05/22    1.9   M.Sano           [T1_1073]�_�~�[�i�ڎ��̐��ʍ��ڕύX�Ή�
 *  2009/06/11    1.10  T.Kitajima       [T1_1348]�sNo�̌��������ύX
 *  2009/06/12    1.10  T.Kitajima       [T1_1350]���C���J�[�\���\�[�g�����ύX
 *  2009/06/12    1.10  T.Kitajima       [T1_1356]�t�@�C��No���ڋq�A�h�I��.EDI�`���ǔ�
 *  2009/06/12    1.10  T.Kitajima       [T1_1357]�`�[�ԍ����l�`�F�b�N
 *  2009/06/12    1.10  T.Kitajima       [T1_1358]��ԓ����敪0��00,1��01,2��02
 *  2009/06/19    1.10  T.Kitajima       [T1_1436]�󒍃f�[�^�A�c�ƒP�ʍi���ݒǉ�
 *  2009/06/24    1.10  T.Kitajima       [T1_1359]���ʊ��Z�Ή�
 *  2009/07/08    1.10  M.Sano           [T1_1357]���r���[�w�E�����Ή�
 *  2009/07/10    1.10  N.Maeda          [000063]���敪�ɂ��f�[�^�쐬�Ώۂ̐���ǉ�
 *                                       [000064]��DFF���ڒǉ��ɔ����A�A�g���ڒǉ�
 *  2009/07/21    1.11  K.Kiriu          [0000644]�������z�̒[�������Ή�
 *  2009/07/24    1.11  K.Kiriu          [T1_1359]���r���[�w�E�����Ή�
 *  2009/08/10    1.11  K.Kiriu          [0000438]�w�E�����Ή�
 *  2009/09/03    1.12  N.Maeda          [0001065]�wXXCOS_HEAD_PROD_CLASS_V�x��MainSQL�捞
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_name        IN     VARCHAR2,         --   1.�t�@�C����
    iv_make_class       IN     VARCHAR2,         --   2.�쐬�敪
    iv_edi_c_code       IN     VARCHAR2,         --   3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN     VARCHAR2,         --   4.EDI�`���ǔ�
    iv_edi_f_number_f   IN     VARCHAR2,         --   4.EDI�`���ǔ�(�t�@�C�����p)
    iv_edi_f_number_s   IN     VARCHAR2,         --   5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN     VARCHAR2,         --   6.�X�ܔ[�i��From
    iv_shop_date_to     IN     VARCHAR2,         --   7.�X�ܔ[�i��To
    iv_sale_class       IN     VARCHAR2,         --   8.��ԓ����敪
    iv_area_code        IN     VARCHAR2,         --   9.�n��R�[�h
    iv_center_date      IN     VARCHAR2,         --  10.�Z���^�[�[�i��
    iv_delivery_time    IN     VARCHAR2,         --  11.�[�i����
    iv_delivery_charge  IN     VARCHAR2,         --  12.�[�i�S����
    iv_carrier_means    IN     VARCHAR2,         --  13.�A����i
    iv_proc_date        IN     VARCHAR2,         --  14.������
    iv_proc_time        IN     VARCHAR2          --  15.��������
  );
END XXCOS011A03C;
/
