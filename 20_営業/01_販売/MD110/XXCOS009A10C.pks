CREATE OR REPLACE PACKAGE APPS.XXCOS009A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A10C(spec)
 * Description      : �󒍈ꗗ���󒍃G���[���X�g���s
 * MD.050           : MD050_COS_009_A10_�󒍈ꗗ���󒍃G���[���X�g���s
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
 *  2012/12/20    1.0   K.Nakamura       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                      OUT VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    , retcode                     OUT VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    , iv_order_source             IN  VARCHAR2 -- �󒍃\�[�X
    , iv_delivery_base_code       IN  VARCHAR2 -- �[�i���_�R�[�h
    , iv_output_type              IN  VARCHAR2 -- �o�͋敪
    , iv_output_quantity_type     IN  VARCHAR2 -- �o�͐��ʋ敪
    , iv_request_type             IN  VARCHAR2 -- �Ĕ��s�敪
    , iv_edi_received_date_from   IN  VARCHAR2 -- �G���[���X�g�pEDI��M��(FROM)
    , iv_edi_received_date_to     IN  VARCHAR2 -- �G���[���X�g�pEDI��M��(TO)
  );
END XXCOS009A10C;
/
