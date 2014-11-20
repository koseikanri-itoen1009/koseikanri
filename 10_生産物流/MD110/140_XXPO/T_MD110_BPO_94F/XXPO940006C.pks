CREATE OR REPLACE PACKAGE xxpo940006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940006C(spec)
 * Description      : �x���˗��捞����
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : �x���˗��捞���� T_MD070_BPO_94F
 * Version          : 1.11
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/06/13    1.0   Oracle �Ŗ�        ����쐬
 *  2008/06/30    1.1   Oracle �Ŗ�        �^���敪��w��������t�уR�[�h�A�����l�ݒ�
 *                                         �o�^�X�e�[�^�X�ύX
 *  2008/07/08    1.2   Oracle �R����_    I_S_192�Ή�
 *  2008/07/17    1.3   Oracle �Ŗ�        MD050�w�E����#13�Ή�
 *  2008/07/24    1.4   Oracle �Ŗ�        �����ۑ�#32,�����ύX#166�#173�Ή�
 *  2008/07/29    1.5   Oracle �Ŗ�        ST�s��Ή�
 *  2008/07/30    1.6   Oracle �Ŗ�        ST�s��Ή�
 *  2008/08/28    1.7   Oracle �R����_    T_TE080_BPO_940 �w�E16�Ή�
 *  2008/10/08    1.8   Oracle �ɓ��ЂƂ�  �����e�X�g�w�E240�Ή�
 *  2008/10/31    1.9   Oracle �ɓ��ЂƂ�  �����e�X�g�w�E528�Ή�
 *  2009/02/09    1.10  Oracle �g�c �Ď�   �{��#15�Ή�
 *  2009/06/08    1.11  SCS    �ɓ��ЂƂ�  �{��#1526�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode           OUT NOCOPY VARCHAR2,      --   �G���[�R�[�h     #�Œ�#
    iv_data_class     IN         VARCHAR2,      -- 1.�f�[�^���
    iv_trans_type     IN         VARCHAR2,      -- 2.�����敪
    iv_req_dept       IN         VARCHAR2,      -- 3.�˗�����
    iv_vendor         IN         VARCHAR2,      -- 4.�����
    iv_ship_to        IN         VARCHAR2,      -- 5.�z����
    iv_arvl_time_from IN         VARCHAR2,      -- 6.���ɓ�FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.���ɓ�TO
    iv_security_class IN         VARCHAR2       -- 8.�Z�L�����e�B�敪
  );
END xxpo940006c;
/
