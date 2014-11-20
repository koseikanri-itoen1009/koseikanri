CREATE OR REPLACE PACKAGE XXINV550002C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550002C(spec)
 * Description      : �󕥑䒠�쐬
 * MD.050/070       : �݌�(���[)Draft2A (T_MD050_BPO_550)
 *                    �󕥑䒠Draft1A   (T_MD070_BPO_55B)
 * Version          : 1.11
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
