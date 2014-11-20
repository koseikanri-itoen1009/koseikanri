CREATE OR REPLACE PACKAGE XXCFF016A35C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A35C(spec)
 * Description      : ���[�X�_�񃁃��e�i���X
 * MD.050           : MD050_CFF_016_A35_���[�X�_�񃁃��e�i���X
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
 *  2012/10/12    1.0   SCSK�J��         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT VARCHAR2,   --    �G���[���b�Z�[�W #�Œ�#
    retcode                 OUT VARCHAR2,   --    �G���[�R�[�h     #�Œ�#
    iv_contract_number      IN  VARCHAR2,   -- 1. �_��ԍ�
    iv_lease_company        IN  VARCHAR2,   -- 2. ���[�X���
    iv_update_reason        IN  VARCHAR2,   -- 3. �X�V���R
    iv_lease_start_date     IN  VARCHAR2,   -- 4. ���[�X�J�n��
    iv_lease_end_date       IN  VARCHAR2,   -- 5. ���[�X�I����
    iv_payment_frequency    IN  VARCHAR2,   -- 6. �x����
    iv_contract_date        IN  VARCHAR2,   -- 7. �_���
    iv_first_payment_date   IN  VARCHAR2,   -- 8. ����x����
    iv_second_payment_date  IN  VARCHAR2,   -- 9. �Q��ڎx����
    iv_third_payment_date   IN  VARCHAR2,   -- 10.�R��ڈȍ~�x����
    iv_comments             IN  VARCHAR2    -- 11.����
  );
END XXCFF016A35C;
/
