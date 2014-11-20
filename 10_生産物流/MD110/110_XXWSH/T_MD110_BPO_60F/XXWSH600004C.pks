CREATE OR REPLACE PACKAGE xxwsh600004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH600004C(spec)
 * Description      : �g�g�s���o�ɔz�Ԋm���񒊏o����
 * MD.050           : T_MD050_BPO_601_�z�Ԕz���v��
 * MD.070           : T_MD070_BPO_60F_�g�g�s���o�ɔz�Ԋm���񒊏o����
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
 *  2008/05/02    1.0   M.Ikeda          �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- �G���[���b�Z�[�W #�Œ�#
     ,retcode             OUT NOCOPY  VARCHAR2    -- �G���[�R�[�h     #�Œ�#
     ,iv_dept_code        IN  VARCHAR2            -- 01 : ����
     ,iv_date_fix         IN  VARCHAR2            -- 02 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2            -- 03 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2            -- 04 : �m��ʒm���{����To
    ) ;
--
END xxwsh600004c ;
/
