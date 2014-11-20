CREATE OR REPLACE PACKAGE XXCSM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A01(spec)
 * Description      : ���i�v��p�ߔN�x�̔����яW�v
 * MD.050           : ���i�v��p�ߔN�x�̔����яW�v MD050_CSM_002_A01
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
 *  2009/01/07    1.0   S.Son        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT  NOCOPY  VARCHAR2,         -- �G���[���b�Z�[�W
    retcode               OUT  NOCOPY  VARCHAR2,         -- �G���[�R�[�h
    iv_parallel_value_no  IN   VARCHAR2,                 -- 1.�p�������ԍ�
    iv_parallel_cnt       IN   VARCHAR2,                 -- 2.�p��������
    iv_location_cd        IN   VARCHAR2,                 -- 3.���_�R�[�h
    iv_item_no            IN   VARCHAR2                  -- 4.�i�ڃR�[�h
  );
END XXCSM002A01C;
/
