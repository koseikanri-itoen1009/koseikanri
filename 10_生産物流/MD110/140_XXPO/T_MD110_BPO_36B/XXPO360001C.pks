CREATE OR REPLACE PACKAGE xxpo360001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360001c(spec)
 * Description      : ������
 * MD.050/070       : �d���i���[�jIssue1.0(T_MD050_BPO_360)
 *                    �d���i���[�jIssue1.0(T_MD070_BPO_36B)
 * Version          : 1.15
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
 *  2008/03/14    1.0   C.Kinjo          �V�K�쐬
 *  2008/05/14    1.1   R.Tomoyose       �������ׂƎd����T�C�gID�̕R�t�����C��
 *                                       ���l���ڂ̒l��0�̏ꍇ�͒l���o�͂��Ȃ�(�u�����N�ɂ���)
 *  2008/05/19    1.2   Y.Ishikawa       ������ID�����݂��Ȃ��ꍇ�ł��o�͂���悤�ɕύX
 *  2008/05/20    1.3   T.Endou          �Z�L�����e�B�O���q�ɂ̕s��Ή�
 *  2008/05/20    1.4   T.Endou          ���o�Ɋ��Z�P�ʂ�����ꍇ�́A�d�����z�v�Z���@�~�X�C��
 *  2008/06/10    1.5   Y.Ishikawa       ���b�g�}�X�^�ɓ������b�gNo�����݂���ꍇ�A2���׏o�͂����
 *  2008/06/17    1.6   T.Ikehara        TEMP�̈�G���[����̂��߁Axxpo_categories_v��
 *                                       �g�p���Ȃ��悤�ɂ���
 *  2008/06/25    1.7   I.Higa           ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/06/27    1.8   R.Tomoyose       ���ׂ��ő�s�o�́i�U�s�o�́j�̎��ɁA
 *                                       ���v�����y�[�W�ɕ\������錻�ۂ��C��
 *  2008/10/21    1.9   T.Ohashi         �w�E382�Ή�
 *  2008/11/20    1.10  T.Ohashi         �w�E664�Ή�
 *  2009/03/30    1.11  A.Shiina         �{��#1346�Ή�
 *  2009/04/01    1.12  T.Yoshimoto      �{��#1363�Ή�
 *  2009/04/01    1.13  T.Yoshimoto      �{��#1363�Ή�(��)
 *  2009/09/15    1.14  T.Yoshimoto      �{��#1624�Ή�
 *  2009/09/24    1.15  T.Yoshimoto      �{��#1523�Ή�
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
