CREATE OR REPLACE PACKAGE xxwsh620004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620004c(spec)
 * Description      : �q�ɕ��o�w����
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �q�ɕ��o�w����  T_MD070_BPO_62F
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
 *  2008/05/02    1.0   Yuki Komikado    �V�K�쐬
 *  2008/06/24    1.1   Masayoshi Uehara   �x���̏ꍇ�A�p�����[�^�z����/���ɐ�̃����[�V������
 *                                         vendor_site_code�ɕύX�B
 *  2008/07/02    1.2   Satoshi Yunba    �֑������Ή�
 *  2008/07/18    1.3   Hitomi Itou      ST�s�#465�Ή� �o�Ɍ��E�u���b�N�̒��o������ύX
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
     errbuf                    OUT    VARCHAR2         --   �G���[���b�Z�[�W
    ,retcode                   OUT    VARCHAR2         --   �G���[�R�[�h
    ,iv_biz_type               IN     VARCHAR2         --   01 : �Ɩ����
    ,iv_deliver_type           IN     VARCHAR2         --   02 : �o�Ɍ`��
    ,iv_block                  IN     VARCHAR2         --   03 : �u���b�N
    ,iv_deliver_from           IN     VARCHAR2         --   04 : �o�Ɍ�
    ,iv_deliver_to             IN     VARCHAR2         --   05 : �z����^���ɐ�
    ,iv_prod_div               IN     VARCHAR2         --   06 : ���i�敪
    ,iv_item_div               IN     VARCHAR2         --   07 : �i�ڋ敪
    ,iv_date                   IN     VARCHAR2         --   08 : �o�ɓ�
  );
END xxwsh620004c;
/
