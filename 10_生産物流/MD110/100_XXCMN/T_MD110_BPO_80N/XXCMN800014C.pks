CREATE OR REPLACE PACKAGE XXCMN800014C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800014C(spec)
 * Description      : ���Y�o�b�`����CSV�t�@�C���o�͂��A���[�N�t���[�`���ŘA�g���܂��B
 * MD.050           : ���Y�o�b�`���C���^�t�F�[�X<T_MD050_BPO_801>
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
 *  2016/07/01    1.0   S.Yamashita      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT VARCHAR2        -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                   OUT VARCHAR2        -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_batch_no               IN  VARCHAR2        -- 1.�o�b�`NO
   ,iv_whse_code              IN  VARCHAR2        -- 2.�q�ɃR�[�h
   ,iv_production_date_from   IN  VARCHAR2        -- 3.�����i������(FROM)
   ,iv_production_date_to     IN  VARCHAR2        -- 4.�����i������(TO)
   ,iv_routing                IN  VARCHAR2        -- 5.���C��No
  );
END XXCMN800014C;
/
