CREATE OR REPLACE PACKAGE APPS.XXCOS009A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A07C (spec)
 * Description      : �󒍈ꗗ�t�@�C���o��
 * MD.050           : �󒍈ꗗ�t�@�C���o�� MD050_COS_009_A07
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
 *  2010/06/23    1.0   S.Miyakoshi      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_order_source                 IN     VARCHAR2,         --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,         --   �[�i���_�R�[�h
    iv_output_type                  IN     VARCHAR2,         --   �o�͋敪
    iv_chain_code                   IN     VARCHAR2,         --   �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,         --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   �[�i��(�w�b�_)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2          --   �[�i��(�w�b�_)(TO)
  );
END XXCOS009A07C;
/
