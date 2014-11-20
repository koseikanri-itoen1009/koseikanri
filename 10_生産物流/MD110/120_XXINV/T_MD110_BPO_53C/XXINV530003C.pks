CREATE OR REPLACE PACKAGE xxinv530003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV530003C (spec)
 * Description      : �I���\
 * MD.050/070       : �I��Issue1.0 (T_MD050_BPO_530)
                      �I���\Issue1.0 (T_MD070_BPO_530C)
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  main                       ���[���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-03-06    1.0   T.Ikehara        �V�K�쐬
 *  2008-05-02    1.1   T.Ikehara        �p�����[�^�F�i�ڃR�[�h��i��ID�ɕύX�Ή�
 *  2008-05-02    1.2   T.Ikehara        ���t�o�͌`���A�q�ɃR�[�h�����s��Ή�
 *  2008/06/03    1.3   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/24    1.4   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *
 *****************************************************************************************/
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    ov_errbuf             OUT     VARCHAR2,   -- �G���[�E���b�Z�[�W
    ov_retcode            OUT     VARCHAR2,   -- ���^�[���E�R�[�h
    iv_inventory_time     IN      VARCHAR2,   -- 1.�I���N���x
    iv_stock_name         IN      VARCHAR2,   -- 2.���`
    iv_report_post        IN      VARCHAR2,   -- 3.�񍐕���
    iv_warehouse_code     IN      VARCHAR2,   -- 4.�q�ɃR�[�h
    iv_distribution_block IN      VARCHAR2,   -- 5.�u���b�N
    iv_item_type          IN      VARCHAR2,   -- 6.�i�ڋ敪
    iv_item_code          IN      VARCHAR2);  -- 7.�i�ڃR�[�h
--
END xxinv530003c;
/
