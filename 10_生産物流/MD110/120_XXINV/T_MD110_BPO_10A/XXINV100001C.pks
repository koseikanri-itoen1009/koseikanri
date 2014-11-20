CREATE OR REPLACE PACKAGE XXINV100001C AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100001C(spec)
 * Description      : ���Y����(�v��)
 * MD.050           : �v��E�ړ��E�݌ɁE�̔��v��/����v�� T_MD050_BPO100
 * MD.070           : �v��E�ړ��E�݌ɁE�̔��v��/����v�� T_MD070_BPO10A
 * Version          : 1.21
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
 *  2008/01/11   1.0  Oracle �y�c ��     ����쐬
 *  2008/04/21   1.1  Oracle �y�c ��     �����ύX�v�� No27 �Ή�
 *  2008/04/24   1.2  Oracle �y�c ��     �����ύX�v�� No27�C��, No72 �Ή�
 *  2008/05/01   1.3  Oracle �y�c ��     �����e�X�g���̕s��Ή�
 *  2008/05/26   1.4  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(I/F�폜��̃R�~�b�g�ǉ�)
 *  2008/05/26   1.5  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(�G���[�����A�X�L�b�v�����̎Z�o���@�ύX)
 *  2008/05/26   1.6  Oracle �F�{ �a�Y   �K��ᔽ(varchar�g�p)�Ή�
 *  2008/05/29   1.7  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(�̔��v���MD050.�@�\�t���[�ƃ��W�b�N�̕s��v�C��)
 *  2008/06/04   1.8  Oracle �F�{ �a�Y   �V�X�e���e�X�g��Q�Ή�(�̔��v��̍폜�Ώے��o��������ROWNUM=1�폜)
 *  2008/06/12   1.9  Oracle �勴 �F�Y   �����e�X�g��Q�Ή�(400_�s����O#115)
 *  2008/08/01   1.10 Oracle �R�� ��_   ST��QNo10,�ύX�v��No184�Ή�
 *  2008/09/01   1.11 Oracle �勴 �F�Y   PT 2-2_13 �w�E56,PT 2-2_14 �w�E58,���b�Z�[�W�o�͕s��Ή�
 *  2008/09/16   1.12 Oracle �勴 �F�Y   PT 2-2_14�w�E75,76,77�Ή�
 *  2008/11/07   1.13 Oracle Yuko Kawano �����w�E#585
 *  2008/11/11   1.14 Oracle ���c ����   �����w�E#589�Ή�
 *  2008/11/13   1.15 Oracle �勴 �F�Y   �w�E586,596�Ή�
 *  2008/12/01   1.16 Oracle �勴 �F�Y   �{��#155�Ή�
 *  2009/02/17   1.17 Oracle ���g�R����  �{�ԏ�Q#38�Ή�
 *  2009/02/27   1.18 Oracle �勴 �F�Y   �{��#1240�Ή�
 *  2009/04/08   1.19 Oracle �g�� ����   �{��#1352,1374�Ή�
 *  2009/04/09   1.20 Oracle �g�� ����   �{��#1350�Ή�
 *  2009/04/13   1.21 Oracle �g�� ����   �{��#1350�Ή�,���b�Z�[�W�o�͕s��Ή�(�G���[�d���\��)
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT NOCOPY VARCHAR2,   -- �G���[���b�Z�[�W #�Œ�#
    retcode                OUT NOCOPY VARCHAR2,   -- �G���[�R�[�h     #�Œ�#
    iv_forecast_designator IN         VARCHAR2,   -- Forecast�敪
    iv_forecast_yyyymm     IN         VARCHAR2,   -- �N��
    iv_forecast_year       IN         VARCHAR2,   -- �N�x
    iv_forecast_version    IN         VARCHAR2,   -- ����
    iv_forecast_date       IN         VARCHAR2,   -- �J�n���t
    iv_forecast_end_date   IN         VARCHAR2,   -- �I�����t
    iv_item_no             IN         VARCHAR2,   -- �i��
    iv_location_code       IN         VARCHAR2,   -- �o�ɑq��
    iv_account_number      IN         VARCHAR2,   -- ���_
    iv_dept_code           IN         VARCHAR2    -- �捞����
  );
END XXINV100001C;
/
