CREATE OR REPLACE PACKAGE XXCOI006A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A03C(spec)
 * Description      : �����݌Ɏ󕥁i�����j�����ɁA�����݌Ɏ󕥕\���쐬���܂��B
 * MD.050           : �����݌Ɏ󕥕\�쐬<MD050_COI_006_A03>
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
 *  2008/11/12    1.0   H.Sasaki         ���ō쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode             OUT VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_inventory_kbn    IN  VARCHAR2,         -- �y�K�{�z�I���敪�i1:�����A2:�����j
    iv_base_code        IN  VARCHAR2,         -- �y�C�Ӂz���_
    iv_exec_flag        IN  VARCHAR2          -- �y�K�{�z�N���t���O�i1:�R���J�����g�N���A2:������ԋ����m��j
  );
END XXCOI006A03C;
/
