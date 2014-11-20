CREATE OR REPLACE PACKAGE xxpo440003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440003(spec)
 * Description      : ���ɗ\��\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44K)
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
 *  2008/03/26    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/06/04    1.1 Yasuhisa Yamamoto  �����e�X�g�s����O#440_53
 *  2008/07/01    1.2   �Ŗ�             �����ύX�v��142
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
     ,iv_use_purpose        IN     VARCHAR2         -- 01 : �g�p�ړI
     ,iv_deliver_to_code    IN     VARCHAR2         -- 02 : �z����
     ,iv_date_from          IN     VARCHAR2         -- 03 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 04 : �o�ɓ�To
     ,iv_prod_div           IN     VARCHAR2         -- 05 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 06 : �i�ڋ敪
     ,iv_item_code          IN     VARCHAR2         -- 07 : �i��
     ,iv_locat_code         IN     VARCHAR2         -- 08 : �o�ɑq��
     ,iv_security_div       IN     VARCHAR2         -- 09 : �L���Z�L�����e�B�敪
    ) ;
--
END xxpo440003c ;
/
