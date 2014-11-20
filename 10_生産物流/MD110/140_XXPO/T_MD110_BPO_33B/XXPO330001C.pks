CREATE OR REPLACE PACKAGE xxpo330001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo330001c(SPEC)
 * Description      : �d���E�L���x���i�d����ԕi�j
 * MD.050/070       : �d���E�L���x���i�d����ԕi�jIssue2.0  (T_MD050_BPO_330)
 *                    �ԕi�w����                            (T_MD070_BPO_33B)
 * Version          : 1.6
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
 *  2008/01/21    1.0   Yusuke Tabata   �V�K�쐬
 *  2008/04/28    1.1   Yusuke Tabata   �����ύX#43�^TE080�s��Ή�
 *  2008/05/01    1.2   Yasuhisa Yamamoto TE080�s��Ή�(330_8)
 *  2008/05/02    1.3   Yasuhisa Yamamoto TE080�s��Ή�(330_10)
 *  2008/05/02    1.4   Yasuhisa Yamamoto TE080�s��Ή�(330_11)
 *  2008/06/30    1.5   Yohei  Takayama   ST�s�#92�Ή�
 *  2008/07/07    1.6   Satoshi Yunba     �֑������Ή�
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
     ,iv_rtn_number         IN     VARCHAR2         --   01 : �ԕi�ԍ�
     ,iv_dept_code          IN     VARCHAR2         --   02 : �S������
     ,iv_tantousya_code     IN     VARCHAR2         --   03 : �S����
     ,iv_creation_date_from IN     VARCHAR2         --   04 : �쐬����FROM
     ,iv_creation_date_to   IN     VARCHAR2         --   05 : �쐬����TO
     ,iv_vendor_code        IN     VARCHAR2         --   06 : �����
     ,iv_assen_code         IN     VARCHAR2         --   07 : ������
     ,iv_location_code      IN     VARCHAR2         --   08 : �[����
     ,iv_rtn_date_from      IN     VARCHAR2         --   09 : �ԕi��FROM
     ,iv_rtn_date_to        IN     VARCHAR2         --   10 : �ԕi��TO
     ,iv_prod_div           IN     VARCHAR2         --   11 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         --   12 : �i�ڋ敪
    ) ;
END xxpo330001c;
/
