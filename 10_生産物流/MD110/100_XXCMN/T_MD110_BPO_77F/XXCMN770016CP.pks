CREATE OR REPLACE PACKAGE xxcmn770016cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770016cp(spec)
 * Description      : �o�Ɏ��ѕ\(���̓p�^�[��)(�v���g)
 * MD.050/070       : �����Y����(�o��)Issue1.0 (T_MD050_BPO_770)
 *                    �����Y����(�o��)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/17    1.0   Y.Itou           �V�K�쐬
 *  2008/12/18    1.2   A.Shiina         �q�R���J�����g���N��������I��
 *
 *****************************************************************************************/
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �v���O�������i�R���J�����g�E�e���v���[�g�j
  gc_rtf_name_01     CONSTANT  VARCHAR2(20) := 'XXCMN770061'; -- �W�v:���ѕ���,�i�ڋ敪,�q��,�o�א�
  gc_rtf_name_02     CONSTANT  VARCHAR2(20) := 'XXCMN770062'; -- �W�v:���ѕ���,�i�ڋ敪,�q��
  gc_rtf_name_03     CONSTANT  VARCHAR2(20) := 'XXCMN770063'; -- �W�v:���ѕ���,�i�ڋ敪,�o�א�
  gc_rtf_name_04     CONSTANT  VARCHAR2(20) := 'XXCMN770064'; -- �W�v:���ѕ���,�i�ڋ敪
  gc_rtf_name_05     CONSTANT  VARCHAR2(20) := 'XXCMN770065'; -- �W�v:�i�ڋ敪,�q��,�o�א�
  gc_rtf_name_06     CONSTANT  VARCHAR2(20) := 'XXCMN770066'; -- �W�v:�i�ڋ敪,�q��
  gc_rtf_name_07     CONSTANT  VARCHAR2(20) := 'XXCMN770067'; -- �W�v:�i�ڋ敪,�o�א�
  gc_rtf_name_08     CONSTANT  VARCHAR2(20) := 'XXCMN770068'; -- �W�v:�i�ڋ敪
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf             OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode            OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_proc_from       IN    VARCHAR2  --   01 : �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : �����N��TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : �󕥋敪
     ,iv_prod_div        IN    VARCHAR2  --   04 : ���i�敪
     ,iv_item_div        IN    VARCHAR2  --   05 : �i�ڋ敪
     ,iv_result_post     IN    VARCHAR2  --   06 : ���ѕ���
     ,iv_whse_code       IN    VARCHAR2  --   07 : �q�ɃR�[�h
     ,iv_party_code      IN    VARCHAR2  --   08 : �o�א�R�[�h
     ,iv_crowd_type      IN    VARCHAR2  --   09 : �S���
     ,iv_crowd_code      IN    VARCHAR2  --   10 : �S�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : �o���Q�R�[�h
    ) ;
END xxcmn770016cp;
/
