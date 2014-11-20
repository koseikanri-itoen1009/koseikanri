CREATE OR REPLACE PACKAGE xxpo360002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360002c(spec)
 * Description      : �o�ɗ\��\
 * MD.050/070       : �L���x�����[Issue1.0 (T_MD050_BPO_360)
 *                    �L���x�����[Issue1.0 (T_MD070_BPO_36C)
 * Version          : 1.10
 *
 * Program List
 * -------------------- ------------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/03/12    1.0   hirofumi yamazato  �V�K�쐬
 *  2008/05/14    1.1   hirofumi yamazato  �s�ID3�Ή�
 *  2008/05/19    1.2   Y.Ishikawa         �O�����[�U�[���Ɍx���I���ɂȂ�
 *  2008/05/20    1.3   T.Endou            �Z�L�����e�B�O���q�ɂ̕s��Ή�
 *  2008/05/22    1.4   Y.Majikina         ���דK�p�̍ő咷���C��
 *  2008/06/10    1.5   Y.Ishikawa         ���b�g�}�X�^�ɓ������b�gNo�����݂���ꍇ�A
 *                                         2���׏o�͂����
 *  2008/06/17    1.6   I.Higa             xxpo_categories_v���g�p���Ȃ��悤�ɂ���
 *  2008/06/25    1.7   I.Higa             ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                         ����Ȃ����ۂւ̑Ή�
 *  2008/07/04    1.8   Y.Ishikawa         xxcmn_item_categories4_v���g�p���Ȃ��悤�ɂ���
 *  2009/03/30    1.9   A.Shiina           �{��#1346�Ή�
 *  2009/09/24    1.10  T.Yoshimoto        �{��#1523�Ή�
 ****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   ####################
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
      errbuf          OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode         OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_vend_code    IN     VARCHAR2         --   01 : �o�Ɍ�
     ,iv_dlv_f        IN     VARCHAR2         --   02 : �[����FROM
     ,iv_dlv_t        IN     VARCHAR2         --   03 : �[����TO
     ,iv_goods_class  IN     VARCHAR2         --   04 : ���i�敪
     ,iv_item_class   IN     VARCHAR2         --   05 : �i�ڋ敪
     ,iv_item_code    IN     VARCHAR2         --   06 : �i��
     ,iv_dept_code    IN     VARCHAR2         --   07 : ���ɑq��
     ,iv_seqrt_class  IN     VARCHAR2         --   08 : �Z�L�����e�B�敪
    ) ;
END xxpo360002c;
/
