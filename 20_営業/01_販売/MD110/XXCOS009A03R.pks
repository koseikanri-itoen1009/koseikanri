CREATE OR REPLACE PACKAGE APPS.XXCOS009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A03R (spec)
 * Description      : ��������`�F�b�N���X�g
 * MD.050           : ��������`�F�b�N���X�g MD050_COS_009_A03
 * Version          : 1.6
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
 *  2008/12/10    1.0   H.Ri             �V�K�쐬
 *  2009/02/17    1.1   H.Ri             get_msg�̃p�b�P�[�W���C��
 *  2009/04/21    1.2   K.Kiriu          [T1_0444]���ьv��҃R�[�h�̌����s���Ή�
 *  2009/06/17    1.3   N.Nishimura      [T1_1439]�Ώی���0�����A����I���Ƃ���
 *  2009/06/25    1.4   N.Nishimura      [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/08/11    1.5   N.Maeda          [0000865]PT�Ή�
 *  2009/08/13    1.5   N.Maeda          [0000865]���r���[�w�E�Ή�
 *  2009/09/02    1.6   M.Sano           [0001227]PT�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode           OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_sale_base_code IN     VARCHAR2,         --   ���㋒�_�R�[�h
    iv_dlv_date_from  IN     VARCHAR2,         --   �[�i��(FROM)
    iv_dlv_date_to    IN     VARCHAR2,         --   �[�i��(TO)
    iv_sale_emp_code  IN     VARCHAR2,         --   �c�ƒS���҃R�[�h
    iv_ship_to_code   IN     VARCHAR2          --   �o�א�R�[�h
  );
END XXCOS009A03R;
/
