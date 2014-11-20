CREATE OR REPLACE PACKAGE APPS.XXCOS002A032C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A032C (spec)
 * Description      : �c�Ɛ��ѕ\�W�v
 * MD.050           : �c�Ɛ��ѕ\�W�v MD050_COS_002_A03
 * Version          : 1.9
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
 *  2009/01/14    1.0   T.Nakabayashi    �V�K�쐬
 *  2009/01/27    1.0   T.Nakabayashi    �p�b�P�[�W���C�� XXCOS002A03C -> XXCOS002A032C
 *  2009/02/10    1.1   T.Nakabayashi    [COS_42]B-5 ����Q�W�v�����ɂĔ[�i�`�Ԃ��O���[�s���O�����ɓ����Ă����s����C��
 *  2009/02/20    1.2   T.Nakabayashi    get_msg�̃p�b�P�[�W���C��
 *                                       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/26    1.3   T.Nakabayashi    MD050�ۑ�No153�Ή� �]�ƈ��A�A�T�C�������g�K�p�����f�ǉ�
 *                                       ���ʃ��O�w�b�_�o�͏��� �g�ݍ��ݘR��Ή�
 *  2009/04/28    1.4   K.Kiriu          [T1_0482]�K��f�[�^���o��������Ή�
 *                                       [T1_0718]�V�K�l���|�C���g�����ǉ��Ή�
 *                                       [T1_1146]�Q�R�[�h�擾�����s���Ή�
 *  2009/05/26    1.5   K.Kiriu          [T1_1213]�ڋq�����J�E���g�����}�X�^���������C��
 *  2009/08/31    1.6   K.Kiriu          [0000929]�K�⌬��/�L���K�⌏���̃J�E���g���@�ύX
 *  2009/09/04    1.7   K.Kiriu          [0000900]PT�Ή�
 *  2009/10/30    1.8   M.Sano           [0001373]XXCOS_RS_INFO_V�ύX�ɔ���PT�Ή�
 *  2009/11/12    1.9   N.Maeda          [E_T4_00188]�V�K�l���|�C���g�W�v�����C��
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode             OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_process_date     IN      VARCHAR2,         --  1.�������t
    iv_processing_class IN      VARCHAR2          --  2.�����敪
  );
END XXCOS002A032C;
/
