CREATE OR REPLACE PACKAGE xxwsh620007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620007c(spec)
 * Description      : �q�ɕ��o�w�����i�z���斾�ׁj
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �q�ɕ��o�w�����i�z���斾�ׁj T_MD070_BPO_62I
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/05/14    1.0   Nozomi Kashiwagi   �V�K�쐬
 *  2008/06/24    1.1   Masayoshi Uehara   �x���̏ꍇ�A�p�����[�^�z����/���ɐ�̃����[�V������
 *                                         vendor_site_code�ɕύX�B
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1)
                          );
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  �Œ蕔 END   ###############################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                 OUT    VARCHAR2      -- �G���[���b�Z�[�W
    ,retcode                OUT    VARCHAR2      -- �G���[�R�[�h
    ,iv_biz_type            IN     VARCHAR2      -- 01:�Ɩ����        ���K�{
    ,iv_ship_type           IN     VARCHAR2      -- 02:�o�Ɍ`��
    ,iv_block               IN     VARCHAR2      -- 03:�u���b�N
    ,iv_shipped_cd          IN     VARCHAR2      -- 04:�o�Ɍ�
    ,iv_delivery_to         IN     VARCHAR2      -- 05:�z����^���ɐ�
    ,iv_prod_class          IN     VARCHAR2      -- 06:���i�敪        ���K�{
    ,iv_item_class          IN     VARCHAR2      -- 07:�i�ڋ敪
    ,iv_shipped_date        IN     VARCHAR2      -- 08:�o�ɓ�          ���K�{
  );
END xxwsh620007c;
/
