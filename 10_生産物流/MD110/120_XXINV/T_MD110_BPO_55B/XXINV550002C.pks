CREATE OR REPLACE PACKAGE XXINV550002C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550002C(spec)
 * Description      : �󕥑䒠�쐬
 * MD.050/070       : �݌�(���[)Draft2A (T_MD050_BPO_550)
 *                    �󕥑䒠Draft1A   (T_MD070_BPO_55B)
 * Version          : 1.37
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
 *  2008/02/07    1.0   Kazuo Kumamoto   �V�K�쐬
 *  2008/05/07    1.1   Kazuo Kumamoto   �����ύX�v��#33�Ή�
 *  2008/05/15    1.2   Kazuo Kumamoto   �����ύX�v��#93�Ή�
 *  2008/05/15    1.3   Kazuo Kumamoto   SQL�`���[�j���O
 *  2008/06/04    1.4   Takao Ohashi     �����e�X�g�s��C��
 *  2008/06/05    1.5   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�ׂ̏o�א���*-1)
 *  2008/06/05    1.6   Kazuo Kumamoto   SQL�`���[�j���O
 *  2008/06/05    1.7   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�ׂ̑����擾���@��ύX)
 *  2008/06/05    1.8   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�ׂ̎󕥋敪�A�h�I���}�X�^���o�����ύX)
 *  2008/06/09    1.9   Kazuo Kumamoto   �����e�X�g��Q�Ή�(���Y�̓��t�����ύX)
 *  2008/06/09    1.10  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�ׂ̎󕥋敪�A�h�I���}�X�^���o�����ǉ�)
 *  2008/06/23    1.11  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�P�ʂ̏o�͓��e�ύX)
 *  2008/07/01    1.12  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�p�����[�^.�i�ځE���i�敪�E�i�ڋ敪�g�ݍ��킹�`�F�b�N)
 *  2008/07/01    1.13  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�p�����[�^.�����u���b�N�E�q��/�ۊǑq�ɂ�OR�����Ƃ���)
 *  2008/07/02    1.14  Satoshi Yunba    �֑������Ή�
 *  2008/07/07    1.15 Yasuhisa Yamamoto �����e�X�g��Q�Ή�(�������т̎擾���ʂ𔭒����ׂ���擾����悤�ɕύX)
 *  2008/09/16    1.16  Hitomi Itou      T_TE080_BPO_550 �w�E31(�ϑ�����̏ꍇ������q�ɓ��ړ��̏ꍇ�A���o���Ȃ��B)
 *                                       T_TE080_BPO_550 �w�E28(�݌ɒ������я��̎���ԕi���擾(�����݌�)��ǉ�)
 *                                       T_TE080_BPO_540 �w�E44(����)
 *                                       �ύX�v��#171(����)
 *  2008/09/22    1.17  Hitomi Itou      T_TE080_BPO_550 �w�E28(�݌ɒ������я��̊O���o�������E����ԕi���擾(�����݌�)�̑����������ɕύX)
 *  2008/10/20    1.18  Takao Ohashi     T_S_492(�o�͂���Ȃ������敪�Ǝ��R�R�[�g�̑g�ݍ��킹���o�͂�����)
 *  2008/10/23    1.19  Takao Ohashi     �w�E442(�i�ڐU�֏��̎擾�����C��)
 *  2008/11/07    1.20  Hitomi Itou      �����e�X�g�w�E548�Ή�
 *  2008/11/17    1.21  Takao Ohashi     �w�E356�Ή�
 *  2008/11/20    1.22  Naoki Fukuda     �����e�X�g��Q696�Ή�
 *  2008/11/21    1.23  Natsuki Yoshida  �����e�X�g��Q687�Ή�
 *  2008/11/28    1.24  Hitomi Itou      �{�ԏ�Q#227�Ή�
 *  2008/12/02    1.25  Natsuki Yoshida  �{�ԏ�Q#327�Ή�
 *  2008/12/02    1.26  Takao Ohashi     �{�ԏ�Q#327�Ή�
 *  2008/12/03    1.27  Natsuki Yoshida  �{�ԏ�Q#371�Ή�
 *  2008/12/04    1.28  Hitomi Itou      �{�ԏ�Q#362�Ή�
 *  2008/12/18    1.29 Yasuhisa Yamamoto �{�ԏ�Q#732,#772�Ή�
 *  2008/12/24    1.30  Natsuki Yoshida  �{�ԏ�Q#842�Ή�(�����͑S�č폜)
 *  2008/12/29    1.31  Natsuki Yoshida  �{�ԏ�Q#809,#899�Ή�
 *  2008/12/30    1.32  Natsuki Yoshida  �{�ԏ�Q#705�Ή�
 *  2009/01/05    1.33  Akiyoshi Shiina  �{�ԏ�Q#916�Ή�
 *  2009/02/04    1.34 Yasuhisa Yamamoto �{�ԏ�Q#1120�Ή�
 *  2009/02/05    1.35 Yasuhisa Yamamoto �{�ԏ�Q#1120�Ή�(�ǉ��Ή�)
 *  2009/02/13    1.36 Yasuhisa Yamamoto �{�ԏ�Q#1189�Ή�
 *  2009/03/30    1.37  Akiyoshi Shiina  �{�ԏ�Q#1346�Ή�
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
    errbuf               OUT    VARCHAR2         --   �G���[���b�Z�[�W
   ,retcode              OUT    VARCHAR2         --   �G���[�R�[�h
   ,iv_ymd_from          IN     VARCHAR2         --    1. �N����_FROM
   ,iv_ymd_to            IN     VARCHAR2         --    2. �N����_TO
   ,iv_base_date         IN     VARCHAR2         --    3. ������^�����
   ,iv_inout_ctl         IN     VARCHAR2         --    4. ���o�ɋ敪
   ,iv_prod_div          IN     VARCHAR2         --    5. ���i�敪
   ,iv_unit_ctl          IN     VARCHAR2         --    6. �P�ʋ敪
   ,iv_wh_loc_ctl        IN     VARCHAR2         --    7. �q��/�ۊǑq�ɑI���敪
   ,iv_wh_code_01        IN     VARCHAR2         --    8. �q��/�ۊǑq�ɃR�[�h1
   ,iv_wh_code_02        IN     VARCHAR2         --    9. �q��/�ۊǑq�ɃR�[�h2
   ,iv_wh_code_03        IN     VARCHAR2         --   10. �q��/�ۊǑq�ɃR�[�h3
   ,iv_block_01          IN     VARCHAR2         --   11. �u���b�N1
   ,iv_block_02          IN     VARCHAR2         --   12. �u���b�N2
   ,iv_block_03          IN     VARCHAR2         --   13. �u���b�N3
   ,iv_item_div          IN     VARCHAR2         --   14. �i�ڋ敪
   ,iv_item_code_01      IN     VARCHAR2         --   15. �i�ڃR�[�h1
   ,iv_item_code_02      IN     VARCHAR2         --   16. �i�ڃR�[�h2
   ,iv_item_code_03      IN     VARCHAR2         --   17. �i�ڃR�[�h3
   ,iv_lot_no_01         IN     VARCHAR2         --   18. ���b�gNo1
   ,iv_lot_no_02         IN     VARCHAR2         --   19. ���b�gNo2
   ,iv_lot_no_03         IN     VARCHAR2         --   20. ���b�gNo3
   ,iv_mnfctr_date_01    IN     VARCHAR2         --   21. �����N����1
   ,iv_mnfctr_date_02    IN     VARCHAR2         --   22. �����N����2
   ,iv_mnfctr_date_03    IN     VARCHAR2         --   23. �����N����3
   ,iv_reason_code_01    IN     VARCHAR2         --   24. ���R�R�[�h1
   ,iv_reason_code_02    IN     VARCHAR2         --   25. ���R�R�[�h2
   ,iv_reason_code_03    IN     VARCHAR2         --   26. ���R�R�[�h3
   ,iv_symbol            IN     VARCHAR2         --   27. �ŗL�L��
  );
END XXINV550002C;
/
