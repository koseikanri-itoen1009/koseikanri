CREATE OR REPLACE PACKAGE xxwsh920002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920002C(spec)
 * Description      : ������������
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��������j(T_MD050_BPO_920)
 *                    ������������                    (T_MD070_BPO_92D)
 * Version          : 1.3
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
 *  2008/04/18    1.0   Tatsuya Kurata    main�V�K�쐬
 *  2008/06/03    1.1   Masao Hokkanji    �����e�X�g�s��Ή�
 *  2008/06/12    1.2   Masao Hokkanji    T_TE080_BPO920�s����ONo24�Ή�
 *  2008/06/13    1.3   Masao Hokkanji    ���o�����ύX�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_item_class         IN     VARCHAR2         -- 1.���i�敪
     ,iv_action_type        IN     VARCHAR2         -- 2.�������
     ,iv_block1             IN     VARCHAR2         -- 3.�u���b�N�P
     ,iv_block2             IN     VARCHAR2         -- 4.�u���b�N�Q
     ,iv_block3             IN     VARCHAR2         -- 5.�u���b�N�R
     ,iv_deliver_from_id    IN     VARCHAR2         -- 6.�o�Ɍ�
     ,iv_deliver_type       IN     VARCHAR2         -- 7.�o�Ɍ`��
     ,iv_deliver_date_from  IN     VARCHAR2         -- 8.�o�ɓ�From
     ,iv_deliver_date_to    IN     VARCHAR2         -- 9.�o�ɓ�To
    );
END xxwsh920002c;
/
