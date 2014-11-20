CREATE OR REPLACE PACKAGE APPS.XXCOS009A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A11C (spec)
 * Description      : �󒍈ꗗ�t�@�C���o�́iEDI�p�j�i�{���m�F�p�j
 * MD.050           : �󒍈ꗗ�t�@�C���o�� <MD050_COS_009_A11>
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
 * 2012/12/26    1.0   K.Onotsuka      �V�K�쐬[E_�{�ғ�_08657�Ή�]
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_chain_code                   IN     VARCHAR2,         --   �`�F�[���X�R�[�h
    iv_delivery_base_code           IN     VARCHAR2,         --   �[�i���_�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,         --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   �[�i��(�w�b�_)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   �[�i��(�w�b�_)(TO)
    iv_order_source                 IN     VARCHAR2          --   �󒍃\�[�X
  );
END XXCOS009A11C;
/
