CREATE OR REPLACE PACKAGE xxcmn820021c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN820021(spec)
 * Description      : �������ٕ\�쐬
 * MD.050/070       : �W�������}�X�^Issue1.0(T_MD050_BPO_820)
 *                    �������ٕ\�쐬Issue1.0(T_MD070_BPO_82B/T_MD070_BPO_82C)
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
 *  2008/01/10    1.0   Masayuki Ikeda   �V�K�쐬
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_output_type        IN     VARCHAR2         -- 01 : �o�͌`��
     ,iv_fiscal_ym          IN     VARCHAR2         -- 02 : �Ώ۔N��
     ,iv_prod_div           IN     VARCHAR2         -- 03 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 04 : �i�ڋ敪
     ,iv_dept_code          IN     VARCHAR2         -- 05 : ��������
     ,iv_crowd_code_01      IN     VARCHAR2         -- 06 : �Q�R�[�h�P
     ,iv_crowd_code_02      IN     VARCHAR2         -- 07 : �Q�R�[�h�Q
     ,iv_crowd_code_03      IN     VARCHAR2         -- 08 : �Q�R�[�h�R
     ,iv_item_code_01       IN     VARCHAR2         -- 09 : �i�ڃR�[�h�P
     ,iv_item_code_02       IN     VARCHAR2         -- 10 : �i�ڃR�[�h�Q
     ,iv_item_code_03       IN     VARCHAR2         -- 11 : �i�ڃR�[�h�R
     ,iv_item_code_04       IN     VARCHAR2         -- 12 : �i�ڃR�[�h�S
     ,iv_item_code_05       IN     VARCHAR2         -- 13 : �i�ڃR�[�h�T
     ,iv_vendor_id_01       IN     VARCHAR2         -- 14 : �����h�c�P
     ,iv_vendor_id_02       IN     VARCHAR2         -- 15 : �����h�c�Q
     ,iv_vendor_id_03       IN     VARCHAR2         -- 16 : �����h�c�R
     ,iv_vendor_id_04       IN     VARCHAR2         -- 17 : �����h�c�S
     ,iv_vendor_id_05       IN     VARCHAR2         -- 18 : �����h�c�T
    ) ;
END xxcmn820021c;
/
