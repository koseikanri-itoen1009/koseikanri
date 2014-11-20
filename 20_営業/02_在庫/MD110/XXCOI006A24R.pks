CREATE OR REPLACE PACKAGE XXCOI006A24R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI006A24R(spec)
 * Description      : �󕥎c���\�i�c�ƈ��ʌv�j
 * MD.050           : �󕥎c���\�i�c�ƈ��ʌv�j <MD050_COI_A24>
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
 *  2014/03/17    1.0   SCSK ����        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode            OUT VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_inventory_kbn   IN  VARCHAR2,     -- �I���敪
    iv_inventory_date  IN  VARCHAR2,     -- �I����
    iv_inventory_month IN  VARCHAR2,     -- �I����
    iv_base_code       IN  VARCHAR2      -- ���_
  );
END XXCOI006A24R;
/
