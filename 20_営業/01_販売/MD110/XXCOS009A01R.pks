CREATE OR REPLACE PACKAGE XXCOS009A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A01R (spec)
 * Description      : �󒍈ꗗ���X�g
 * MD.050           : �󒍈ꗗ���X�g MD050_COS_009_A01
 * Version          : 1.3
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
