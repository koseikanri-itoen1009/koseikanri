CREATE OR REPLACE PACKAGE xxpo380002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO380002C(spec)
 * Description      : �����˗���
 * MD.050/070       : �����˗��쐬Issue1.0  (T_MD050_BPO_380)
 *                    �����˗��쐬Issue1.0  (T_MD070_BPO_38B)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���[�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/04    1.0   Syogo Chinen      �V�K�쐬
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
  PROCEDURE main (
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_po_number          IN     VARCHAR2         --   01 : �����ԍ�
     ,iv_division_code      IN     VARCHAR2         --   02 : �˗�����
     ,iv_employee_number    IN     VARCHAR2         --   03 : �S����
     ,iv_location_code      IN     VARCHAR2         --   04 : ��������
     ,iv_creation_date_f    IN     VARCHAR2         --   05 : �쐬��FROM
     ,iv_creation_date_t    IN     VARCHAR2         --   06 : �쐬��TO
     ,iv_vendor_code        IN     VARCHAR2         --   07 : �����
     ,iv_promised_date_f    IN     VARCHAR2         --   08 : �[����FROM
     ,iv_promised_date_t    IN     VARCHAR2         --   09 : �[����TO
     ,iv_whse_code          IN     VARCHAR2         --   10 : �[����
     ,iv_prod_class_code    IN     VARCHAR2         --   11 : ���i�敪
     ,iv_item_class_code    IN     VARCHAR2         --   12 : �i�ڋ敪
    ) ;
END xxpo380002c;
/
