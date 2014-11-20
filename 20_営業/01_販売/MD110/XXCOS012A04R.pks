CREATE OR REPLACE PACKAGE APPS.XXCOS012A04R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS012A04R (spec)
 * Description      : �s�b�N���X�g�i�o�׌��ۊǏꏊ�E���i�ʁj
 * MD.050           : �s�b�N���X�g�i�o�׌��ۊǏꏊ�E���i�ʁj MD050_COS_012_A04
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
 * 2013/07/02    1.0   K.Kiriu          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT     VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_login_base_code        IN      VARCHAR2,         -- 1.���_
    iv_subinventory           IN      VARCHAR2,         -- 2.�o�׌��ۊǏꏊ
    iv_request_date_from      IN      VARCHAR2,         -- 3.�����iFrom�j
    iv_request_date_to        IN      VARCHAR2,         -- 4.�����iTo�j
    iv_bargain_class          IN      VARCHAR2,         -- 5.��ԓ����敪
    iv_sales_output_type      IN      VARCHAR2,         -- 6.����Ώۋ敪
    iv_edi_received_date      IN      VARCHAR2)         -- 7.EDI��M��
 ;
END XXCOS012A04R;
/
