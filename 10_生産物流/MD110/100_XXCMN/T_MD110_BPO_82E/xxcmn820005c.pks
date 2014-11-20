CREATE OR REPLACE PACKAGE xxcmn820005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820005c(spec)
 * Description      : �����R�s�[����
 * MD.050           : �W�������}�X�^T_MD050_BPO_821
 * MD.070           : �����R�s�[����(82E) T_MD070_BPO_82E
 * Version          : 1.1
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
 *  2008/07/01    1.0   H.Itou           �V�K�쐬
 *  2009/01/08    1.1   N.Yoshida        �{��#968�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,retcode              OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,iv_calendar_code     IN  VARCHAR2    --   �J�����_�R�[�h
   ,iv_prod_class_code   IN  VARCHAR2    --   ���i�敪
   ,iv_item_class_code   IN  VARCHAR2    --   �i�ڋ敪
   ,iv_item_code         IN  VARCHAR2    --   �i��
   ,iv_update_date_from  IN  VARCHAR2    --   �X�V����FROM
   ,iv_update_date_to    IN  VARCHAR2    --   �X�V����TO
  );
END xxcmn820005c;
/
