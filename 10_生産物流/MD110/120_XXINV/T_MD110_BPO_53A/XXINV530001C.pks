CREATE OR REPLACE PACKAGE xxinv530001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv5300001(spec)
 * Description      : �I�����ʃC���^�[�t�F�[�X
 * MD.050           : �I��Issue1.0(T_MD050_BPO_530)
 * MD.070           : �I��Issue1.0(T_MD070_BPO_53A)
 * Version          : 1.0
 *
 * Program List
 *  -------------------------------------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------------------------------------------------------------------
 *  main                  P          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * -----------------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * -----------------------------------------------------------------------------------
 *  2008/03/14    1.0   M.Inamine        �V�K�쐬
 *
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT    VARCHAR2    -- �G���[���b�Z�[�W
   ,retcode               OUT    VARCHAR2    -- ���^�[���E�R�[�h  
   ,iv_report_post_code   IN     VARCHAR2    -- �񍐕���
   ,iv_whse_code          IN     VARCHAR2    -- �q�ɃR�[�h
   ,iv_item_type          IN     VARCHAR2);  -- �i�ڋ敪
--
END xxinv530001c;
/