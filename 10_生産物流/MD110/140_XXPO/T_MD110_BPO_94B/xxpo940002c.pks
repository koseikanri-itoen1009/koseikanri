CREATE OR REPLACE PACKAGE xxpo940002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940002c(spec)
 * Description      : �o�������ю捞����
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : �o�������ю捞���� T_MD070_BPO_94B
 * Version          : 1.9
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/06/06    1.0   Oracle �ɓ��ЂƂ�   ����쐬
 *  2008/07/08    1.1   Oracle �R����_     I_S_192�Ή�
 *  2008/07/22    1.2   Oracle �ɓ��ЂƂ�   �����ۑ�#32�Ή�
 *  2008/08/18    1.3   Oracle �ɓ��ЂƂ�   T_S_595 �i�ڏ��VIEW2�𐻑�����Œ��o����
 *  2008/12/02    1.4   SCS    �ɓ��ЂƂ�   �{�ԏ�Q#171
 *  2008/12/24    1.5   SCS    �R�{ ���v    �{�ԏ�Q#743
 *  2008/12/26    1.6   SCS    �ɓ� �ЂƂ�  �{�ԏ�Q#809
 *  2009/02/09    1.7   SCS    �g�c �Ď�    �{��#15�A#1178�Ή�
 *  2009/03/13    1.8   SCS    �ɓ� �ЂƂ�  �{��#32�Ή�
 *  2009/03/24    1.9   SCS    �ѓc ��      �{�ԏ�Q#1317�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_data_class             IN  VARCHAR2,   --   �f�[�^���
    iv_vendor_code            IN  VARCHAR2,   --   �����
    iv_factory_code           IN  VARCHAR2,   --   �H��
    iv_manufactured_date_from IN  VARCHAR2,   --   ���Y��FROM
    iv_manufactured_date_to   IN  VARCHAR2,   --   ���Y��TO
    iv_security_kbn           IN  VARCHAR2    --   �Z�L�����e�B�敪
  );
END xxpo940002c;
/
