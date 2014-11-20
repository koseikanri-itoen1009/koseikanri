CREATE OR REPLACE PACKAGE xxwsh600002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600002c(spec)
 * Description      : ���o�ɔz���v���񒊏o����
 * MD.050           : T_MD050_BPO_601_�z�Ԕz���v��
 * MD.070           : T_MD070_BPO_60E_���o�ɔz���v���񒊏o����
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
 *  2008/04/01    1.0   M.Ikeda          �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- �G���[���b�Z�[�W #�Œ�#
     ,retcode             OUT NOCOPY  VARCHAR2    -- �G���[�R�[�h     #�Œ�#
     ,iv_dept_code        IN  VARCHAR2            -- 01 : ����
     ,iv_fix_class        IN  VARCHAR2            -- 02 : �\��m��敪
     ,iv_date_cutoff      IN  VARCHAR2            -- 03 : ���ߎ��{��
     ,iv_cutoff_from      IN  VARCHAR2            -- 04 : ���ߎ��{����From
     ,iv_cutoff_to        IN  VARCHAR2            -- 05 : ���ߎ��{����To
     ,iv_date_fix         IN  VARCHAR2            -- 06 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2            -- 07 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2            -- 08 : �m��ʒm���{����To
    ) ;
--
END xxwsh600002c ;
/
