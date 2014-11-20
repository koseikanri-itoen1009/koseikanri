CREATE OR REPLACE PACKAGE xxpo870003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo870003c(spec)
 * Description      : �����P�����֏���
 * MD.050           : �d���P���^�W�������}�X�^�o�^ Issue1.0 T_MD050_BPO_870
 * MD.070           : �d���P���^�W�������}�X�^�o�^ Issue1.0  T_MD070_BPO_870
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
 *  2008/03/10    1.0   Y.Ishikawa           main �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode            OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_date_type       IN     VARCHAR2,         --   ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN     VARCHAR2,         --   ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date        IN     VARCHAR2,         --   ���ԏI����(YYYY/MM/DD)
    iv_commodity_type  IN     VARCHAR2,         --   ���i�敪
    iv_item_type       IN     VARCHAR2,         --   �i�ڋ敪
    iv_item_code1      IN     VARCHAR2,         --   �i�ڃR�[�h1
    iv_item_code2      IN     VARCHAR2,         --   �i�ڃR�[�h2
    iv_item_code3      IN     VARCHAR2,         --   �i�ڃR�[�h3
    iv_customer_code1  IN     VARCHAR2,         --   �����R�[�h1
    iv_customer_code2  IN     VARCHAR2,         --   �����R�[�h2
    iv_customer_code3  IN     VARCHAR2          --   �����R�[�h3
  );
END xxpo870003c;
/
