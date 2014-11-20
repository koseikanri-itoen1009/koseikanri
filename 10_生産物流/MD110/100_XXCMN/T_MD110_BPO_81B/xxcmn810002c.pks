CREATE OR REPLACE PACKAGE xxcmn810002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn810002c(spec)
 * Description      : �i�ڃ}�X�^�X�V(����)
 * MD.050           : �i�ڃ}�X�^ T_MD050_BPO_810
 * MD.070           : �i�ڃ}�X�^�X�V(����)(81B) T_MD070_BPO_81B
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
 *  2007/12/12    1.0   T.Iwasa          main�V�K�쐬
 *  2008/05/02    1.1   H.Marushita      �����ύX�v��No.81�Ή�
 *  2008/05/20    1.2   H.Marushita      �����ύX�v��No.105�Ή�
 *  2008/09/11    1.3   Oracle �R����_  �w�E115�Ή�
 *  2008/09/24    1.4   Oracle �R����_  T_S_421�Ή�
 *  2008/09/29    1.5   Oracle �R����_  T_S_546,T_S_547�Ή�
 *  2008/11/24    1.6   Oracle �勴�F�Y  �{�Ԋ��⍇��_��Q�Ǘ��\220�Ή�
 *  2009/01/28    1.7   Oracle �Ŗ����\  �{��#1022�Ή�
 *  2009/02/27    1.8   Oracle �Ŗ����\  �{��#1212�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
-- 2009/02/27 v1.8 UPDATE START
--    iv_applied_date IN     VARCHAR2          -- 1.�K�p���t
    iv_applied_date IN     VARCHAR2,         -- 1.�K�p���t
    iv_start_class  IN     VARCHAR2          -- 2.�N���敪
-- 2009/02/27 v1.8 UPDATE END
  );
END xxcmn810002c;
/
