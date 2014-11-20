CREATE OR REPLACE PACKAGE APPS.XXCOS009A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A01R (spec)
 * Description      : �󒍈ꗗ���X�g
 * MD.050           : �󒍈ꗗ���X�g MD050_COS_009_A01
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
 *  2009/01/06    1.0   T.TYOU             �V�K�쐬
 *  2009/02/12    1.1   T.TYOU           [��Q�ԍ��F064]�ۊǏꏊ�̊O��������������Ȃ�
 *  2009/02/17    1.2   T.TYOU           get_msg�̃p�b�P�[�W���C��
 *  2009/04/14    1.3   T.Kiriu          [T1_0470]�ڋq�����ԍ��擾���C��
 *  2009/05/08    1.4   T.Kitajima       [T1_0925]�o�א�R�[�h�ύX
 *  2009/06/19    1.5   N.Nishimura      [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/13    1.6   K.Kiriu          [0000063]���敪�̉ۑ�Ή�
 *  2009/07/29    1.7   T.Tominaga       [0000271]�󒍃\�[�X��EDI�󒍂Ƃ���ȊO�ƂŃJ�[�\���𕪂���iEDI�󒍂̂݃��b�N�j
 *  2009/10/02    1.8   N.Maeda          [0001338]execute_svf�̓Ɨ��g�����U�N�V������
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_order_source                 IN     VARCHAR2,         --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,         --   �[�i���_�R�[�h
    iv_ordered_date_from            IN     VARCHAR2,         --   �[�i��(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   �[�i��(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   �o�ח\���(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   �o�ח\���(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   �[�i�\���(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   �[�i�\���(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   ���͎҃R�[�h
    iv_ship_to_code                 IN     VARCHAR2,         --   �o�א�R�[�h
    iv_subinventory                 IN     VARCHAR2,         --   �ۊǏꏊ
    iv_order_number                 IN     VARCHAR2          --   �󒍔ԍ�
  );
END XXCOS009A01R;
/
