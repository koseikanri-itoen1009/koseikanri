CREATE OR REPLACE PACKAGE xxpo780001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo780001c(spec)
 * Description      : �����Y�؏����i�L���x�����E�j
 * MD.050/070       : �����Y�؏����i�L���x�����E�jIssue1.0  (T_MD050_BPO_780)
 *                    �v�Z��                                (T_MD070_BPO_78A)
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
 *  2007/12/03    1.0   Masayuki Ikeda   �V�K�쐬
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_fiscal_ym          IN     VARCHAR2         --   01 : �Y�ؔN��
     ,iv_dept_code          IN     VARCHAR2         --   02 : �����Ǘ�����
     ,iv_vendor_code        IN     VARCHAR2         --   03 : �����
    ) ;
END xxpo780001c;
/
