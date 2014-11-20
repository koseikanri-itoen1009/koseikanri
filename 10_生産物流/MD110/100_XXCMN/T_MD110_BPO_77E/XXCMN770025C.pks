CREATE OR REPLACE PACKAGE xxcmn770025c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770025(spec)
 * Description      : �d�����ѕ\�쐬
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77E)
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
 *  2008/04/14    1.0   T.Endou          �V�K�쐬
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
      errbuf                OUT   VARCHAR2,  -- �G���[���b�Z�[�W
      retcode               OUT   VARCHAR2,  -- �G���[�R�[�h
      iv_proc_from          IN    VARCHAR2, -- 01 : �����N��(FROM)
      iv_proc_to            IN    VARCHAR2, -- 02 : �����N��(TO)
      iv_prod_div           IN    VARCHAR2, -- 03 : ���i�敪
      iv_item_div           IN    VARCHAR2, -- 04 : �i�ڋ敪
      iv_result_post        IN    VARCHAR2, -- 05 : ���ѕ���
      iv_party_code         IN    VARCHAR2, -- 06 : �d����
      iv_crowd_type         IN    VARCHAR2, -- 07 : �Q���
      iv_crowd_code         IN    VARCHAR2, -- 08 : �Q�R�[�h
      iv_acnt_crowd_code    IN    VARCHAR2  -- 09 : �o���Q�R�[�h
    );
--
END xxcmn770025c;
/
