CREATE OR REPLACE PACKAGE xxpo360003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360003C(spec)
 * Description      : ���ɗ\��\
 * MD.050/070       : �L���x�����[Issue1.0 (T_MD050_BPO_360)
 *                    �L���x�����[Issue1.0 (T_MD070_BPO_36D)
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
 *  2008/03/10    1.0   T.Hokama         �V�K�쐬
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
     ,iv_rcpt_subinv_code   IN     VARCHAR2         --   01 : ���ɕۊǏꏊ�R�[�h
     ,iv_dlv_from           IN     VARCHAR2         --   02 : �[�i���i�e�q�n�l�j
     ,iv_dlv_to             IN     VARCHAR2         --   03 : �[�i���i�s�n�j
     ,iv_goods_class        IN     VARCHAR2         --   04 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   05 : �i�ڋ敪
     ,iv_item_code          IN     VARCHAR2         --   06 : �i�ڃR�[�h
     ,iv_ship_code_from     IN     VARCHAR2         --   07 : �o�Ɍ��R�[�h
     ,iv_seqrt_class        IN     VARCHAR2         --   08 : �Z�L�����e�B�敪
    ) ;
END xxpo360003c ;
/
