CREATE OR REPLACE PACKAGE xxcmn770015c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770015(spec)
 * Description      : �d�����ѕ\�쐬
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77E)
 * Version          : 1.2
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
 *  2008/04/14    1.0   T.Endou          �V�K�쐬
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
  -- �p�����[�^�DALL
  dept_code_all       CONSTANT VARCHAR2(20) := 'ALL' ;   -- ALL�w��
--
  -- �v���O�������i�R���J�����g�E�e���v���[�g�j
  program_id_01       CONSTANT VARCHAR2(20) := 'XXCMN770051' ; -- �i�ڋ敪
  program_id_02       CONSTANT VARCHAR2(20) := 'XXCMN770052' ; -- �i�ڋ敪�E���ѕ���
  program_id_03       CONSTANT VARCHAR2(20) := 'XXCMN770053' ; -- �i�ڋ敪�E�d����
  program_id_04       CONSTANT VARCHAR2(20) := 'XXCMN770054' ; -- �i�ڋ敪�E�d����E���ѕ���
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_proc_from          IN     VARCHAR2         --   01 : �����N��(FROM)
     ,iv_proc_to            IN     VARCHAR2         --   02 : �����N��(TO)
     ,iv_prod_div           IN     VARCHAR2         --   03 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         --   04 : �i�ڋ敪
     ,iv_result_post        IN     VARCHAR2         --   05 : ���ѕ���
     ,iv_party_code         IN     VARCHAR2         --   06 : �d����
     ,iv_crowd_type         IN     VARCHAR2         --   07 : �Q���
     ,iv_crowd_code         IN     VARCHAR2         --   08 : �Q�R�[�h
     ,iv_acnt_crowd_code    IN     VARCHAR2         --   09 : �o���Q�R�[�h
    ) ;
END xxcmn770015c;
/
