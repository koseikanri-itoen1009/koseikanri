create or replace PACKAGE XXCOI006A14R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A14C(spec)
 * Description      : �󕥎c���\�i�c�ƈ��j
 * MD.050           : �󕥎c���\�i�c�ƈ��j <MD050_COI_A14>
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
 *  2008/12/24    1.0   N.Abe            �V�K�쐬
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
    iv_base_code       IN  VARCHAR2,     -- ���_
    iv_business        IN  VARCHAR2      -- �c�ƈ�
  );
END XXCOI006A14R;
/
