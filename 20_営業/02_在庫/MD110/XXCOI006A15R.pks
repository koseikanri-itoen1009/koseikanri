CREATE OR REPLACE PACKAGE XXCOI006A15R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A15R(spec)
 * Description      : �q�ɖ��ɓ����܂��͌����A�����̎󕥎c�������󕥎c���\�ɏo�͂��܂��B
 *                    �a���斈�Ɍ����̎󕥎c�������󕥎c���\�ɏo�͂��܂��B
 * MD.050           : �󕥎c���\(�q�ɁE�a����)    MD050_COI_006_A15
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
 *  2008/12/18    1.0   Sai.u            main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode            OUT VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_output_kbn      IN  VARCHAR2,     -- �o�͋敪
    iv_inventory_kbn   IN  VARCHAR2,     -- �I���敪
    iv_inventory_date  IN  VARCHAR2,     -- �I����
    iv_inventory_month IN  VARCHAR2,     -- �I����
    iv_base_code       IN  VARCHAR2,     -- ���_
    iv_warehouse       IN  VARCHAR2,     -- �q��
    iv_left_base       IN  VARCHAR2      -- �a����
  );
END XXCOI006A15R;
/
