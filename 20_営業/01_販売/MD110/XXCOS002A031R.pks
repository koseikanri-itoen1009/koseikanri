CREATE OR REPLACE PACKAGE XXCOS002A031R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A031R(spec)
 * Description      : �c�Ɛ��ѕ\
 * MD.050           : �c�Ɛ��ѕ\ MD050_COS_002_A03
 * Version          : 1.7
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
 *  2009/02/06    1.0   T.Nakabayashi    main�V�K�쐬
 *  2009/02/23    1.1   T.Nakabayashi    [COS_123]A-2 �O���[�v�R�[�h���ݒ�ł��ʂ̐��ѕ\�͏o�͉\�Ƃ���
 *  2009/02/26    1.2   T.Nakabayashi    MD050�ۑ�No153�Ή� �]�ƈ��A�A�T�C�������g�K�p�����f�ǉ�
 *  2009/02/27    1.3   T.Nakabayashi    ���[���[�N�e�[�u���폜���� �R�����g�A�E�g����
 *  2009/06/09    1.4   T.Tominaga       ���[���[�N�e�[�u���폜����"delete_rpt_wrk_data" �R�����g�A�E�g����
 *  2009/06/18    1.5   K.Kiriu          [T1_1446]PT�Ή�
 *  2009/06/22    1.6   K.Kiriu          [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/07    1.7   K.Kiriu          [0000418]�폜�����擾�s��Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_date          IN      VARCHAR2,         --  2.�[�i��
    iv_delivery_base_code     IN      VARCHAR2,         --  3.���_
    iv_section_code           IN      VARCHAR2,         --  4.��
    iv_results_employee_code  IN      VARCHAR2          --  5.�c�ƈ�
  );
END XXCOS002A031R;
/
