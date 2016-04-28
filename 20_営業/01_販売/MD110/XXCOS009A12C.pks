CREATE OR REPLACE PACKAGE APPS.XXCOS009A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A12C (spec)
 * Description      : �[�i�m��f�[�^�_�E�����[�h
 * MD.050           : �[�i�m��f�[�^�_�E�����[�h <MD050_COS_009_A12>
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
 *  2016/03/14    1.0   S.Yamashita      �V�K�쐬[E_�{�ғ�_13436�Ή�]
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_chain_code                   IN     VARCHAR2         --   �`�F�[���X�R�[�h
   ,iv_delivery_base_code           IN     VARCHAR2         --   �[�i���_�R�[�h
   ,iv_received_date_from           IN     VARCHAR2         --   ��M��(FROM)
   ,iv_received_date_to             IN     VARCHAR2         --   ��M��(TO)
   ,iv_delivery_date_from           IN     VARCHAR2         --   �[�i��(�w�b�_)(FROM)
   ,iv_delivery_date_to             IN     VARCHAR2         --   �[�i��(�w�b�_)(TO)
  );
END XXCOS009A12C;
/
