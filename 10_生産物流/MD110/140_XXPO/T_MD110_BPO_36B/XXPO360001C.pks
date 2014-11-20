CREATE OR REPLACE PACKAGE xxpo360001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360001c(spec)
 * Description      : ������
 * MD.050/070       : �d���i���[�jIssue1.0(T_MD050_BPO_360)
 *                    �d���i���[�jIssue1.0(T_MD070_BPO_36B)
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
 *  2008/03/13    1.0   C.Kinjo          �V�K�쐬
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
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_site_use           IN     VARCHAR2         --   01 : �g�p�ړI
     ,iv_po_number          IN     VARCHAR2         --   02 : �����ԍ�
     ,iv_role_department    IN     VARCHAR2         --   03 : �S������
     ,iv_role_people        IN     VARCHAR2         --   04 : �S����
     ,iv_create_date_from   IN     VARCHAR2         --   05 : �쐬��FROM
     ,iv_create_date_to     IN     VARCHAR2         --   06 : �쐬��TO
     ,iv_vendor_code        IN     VARCHAR2         --   07 : �����
     ,iv_mediation          IN     VARCHAR2         --   08 : ������
     ,iv_delivery_date_from IN     VARCHAR2         --   09 : �[����FROM
     ,iv_delivery_date_to   IN     VARCHAR2         --   10 : �[����TO
     ,iv_delivery_to        IN     VARCHAR2         --   11 : �[����
     ,iv_product_type       IN     VARCHAR2         --   12 : ���i�敪
     ,iv_item_type          IN     VARCHAR2         --   13 : �i�ڋ敪
     ,iv_security_type      IN     VARCHAR2         --   14 : �Z�L�����e�B�敪
    ) ;
END xxpo360001c;
/
