CREATE OR REPLACE PACKAGE xxcmn770001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770001c(spec)
 * Description      : �󕥎c���\�i�T�j�����E���ށE�����i
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77A)
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
 *  2008/04/02    1.0   M.Inamine        �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  �Œ蕔 END   ###############################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                  OUT    VARCHAR2    -- �G���[���b�Z�[�W
     ,retcode                 OUT    VARCHAR2    -- �G���[�R�[�h
     ,iv_yyyymm               IN     VARCHAR2    -- 01 : �����N��
     ,iv_product_class        IN     VARCHAR2    -- 02 : ���i�敪
     ,iv_item_class           IN     VARCHAR2    -- 03 : �i�ڋ敪
     ,iv_report_type          IN     VARCHAR2    -- 04 : ���[���
     ,iv_whse_code            IN     VARCHAR2    -- 05 : �q�ɃR�[�h
     ,iv_group_type           IN     VARCHAR2    -- 06 : �Q���
     ,iv_group_code           IN     VARCHAR2    -- 07 : �Q�R�[�h
     ,iv_accounting_grp_code  IN     VARCHAR2);  -- 08 : �o���Q�R�[�h
END xxcmn770001c;
/