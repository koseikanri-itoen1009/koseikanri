CREATE OR REPLACE PACKAGE APPS.XXCOI010A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A04C(spec)
 * Description      : ���_�ň����i�ڂ̑g�������𒊏o��CSV�t�@�C�����쐬���ĘA�g����B
 * MD.050           : ���_�i�ڏ��HHT�A�g MD050_COI_010_A04
 * Version          : 1.0
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
 *  2011/04/05    1.0   H.Sekine         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf          OUT    VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
    ,retcode         OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
    ,iv_target_date  IN     VARCHAR2          --   �y�C�Ӂz�����Ώۓ�
  );
END XXCOI010A04C;
/
